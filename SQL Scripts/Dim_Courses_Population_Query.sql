BEGIN TRANSACTION;

-- Deduplicate source

IF OBJECT_ID('tempdb..#src') IS NOT NULL DROP TABLE #src;

WITH src_dedup AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY course_code  
               ORDER BY course_code DESC
           ) AS rn
    FROM dbo.STG_Courses
)
SELECT *
INTO #src
FROM src_dedup
WHERE rn = 1;


-- Identify changed records

IF OBJECT_ID('tempdb..#changed_records') IS NOT NULL DROP TABLE #changed_records;

SELECT s.*
INTO #changed_records
FROM #src s
JOIN dbo.DIM_Courses tgt
  ON s.course_code = tgt.course_code 
 AND tgt.is_current = 1
WHERE
       ISNULL(tgt.course_name,'')      <> ISNULL(s.course_name,'')
    OR ISNULL(tgt.institution_name,'') <> ISNULL(s.institution_name,'')
    OR ISNULL(tgt.institution_code,'') <> ISNULL(s.institution_code,'')
    OR ISNULL(tgt.campus,'')           <> ISNULL(s.campus,'')
    OR ISNULL(tgt.study_mode,'')       <> ISNULL(s.study_mode,'')
    OR ISNULL(tgt.duration_years,0)    <> ISNULL(s.duration_years,0)
    OR ISNULL(tgt.atar_cutoff,0)       <> ISNULL(s.atar_cutoff,0)
	OR ISNULL(tgt.csp_available,0)       <> ISNULL(s.csp_available,0)
    OR ISNULL(tgt.active_flag,0)       <> ISNULL(s.active_flag,0)
 ;


-- Step 3: Expire existing records

UPDATE tgt
SET
    tgt.effective_end_date = GETDATE(),
    tgt.is_current = 0
FROM dbo.DIM_Courses tgt
JOIN #changed_records src
  ON tgt.course_code = src.course_code  
WHERE tgt.is_current = 1;


-- Insert new versions

INSERT INTO dbo.DIM_Courses (
    course_code,
    course_name,
    institution_name,
	institution_code,
    campus,
    study_mode,
    duration_years,
    atar_cutoff,
	csp_available,
    active_flag,
    effective_start_date,
    effective_end_date,
    is_current
)
SELECT
    course_code,
    course_name,
    institution_name,
	institution_code,
    campus,
    study_mode,
    duration_years,
    atar_cutoff,
	csp_available,
    active_flag,
    GETDATE(),
    '9999-12-31',
	1    
FROM #changed_records;


--Insert new courses

INSERT INTO dbo.DIM_Courses (
    course_code,
    course_name,
    institution_name,
	institution_code,
    campus,
    study_mode,
    duration_years,
    atar_cutoff,
	csp_available,
    active_flag,
    effective_start_date,
    effective_end_date,
    is_current
)
SELECT
    s.course_code,
    s.course_name,
    s.institution_name,
    s.institution_code,
    s.campus,
    s.study_mode,
    s.duration_years,
    s.atar_cutoff,
	s.csp_available,
    s.active_flag,
    GETDATE(),
    '9999-12-31',
    1
FROM #src s
LEFT JOIN dbo.DIM_Courses tgt
  ON s.course_code = tgt.course_code  
WHERE tgt.course_code IS NULL;
COMMIT;
