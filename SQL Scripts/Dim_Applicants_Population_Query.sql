

BEGIN TRANSACTION;

-- Deduplicate source

IF OBJECT_ID('tempdb..#src') IS NOT NULL DROP TABLE #src;

WITH src_dedup AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY applicant_id
               ORDER BY updated_date DESC
           ) AS rn
    FROM dbo.STG_Applicants
)
SELECT *
INTO #src
FROM src_dedup
WHERE rn = 1;

--Identify changed records

IF OBJECT_ID('tempdb..#changed_records') IS NOT NULL DROP TABLE #changed_records;

SELECT s.*
INTO #changed_records
FROM #src s
JOIN dbo.DIM_Applicants tgt
  ON s.applicant_id = tgt.applicant_id
 AND tgt.is_current = 1
WHERE
       ISNULL(tgt.first_name,'') <> ISNULL(s.first_name,'')
    OR ISNULL(tgt.last_name,'')  <> ISNULL(s.last_name,'')
	OR ISNULL(tgt.date_of_birth,'1900-01-01')  <> ISNULL(s.date_of_birth,'1900-01-01')
    OR ISNULL(tgt.email,'')      <> ISNULL(s.email,'')
    OR ISNULL(tgt.phone,'')      <> ISNULL(s.phone,'')
    OR ISNULL(tgt.state,'')      <> ISNULL(s.state,'')
    OR ISNULL(tgt.postcode,'')   <> ISNULL(s.postcode,'')
    OR ISNULL(tgt.updated_date,'1900-01-01')
       <> ISNULL(s.updated_date,'1900-01-01');

-- Expire existing records 

UPDATE tgt
SET
    tgt.effective_end_date = src.updated_date,
    tgt.is_current = 0
FROM dbo.DIM_Applicants tgt
JOIN #changed_records src
  ON tgt.applicant_id = src.applicant_id
WHERE tgt.is_current = 1;

-- Insert new versions (changed records)

INSERT INTO dbo.DIM_Applicants (
    applicant_id,
    first_name,
    last_name,
    date_of_birth,
    email,
    phone,
    state,
    postcode,
    effective_start_date,
    effective_end_date,
    is_current,
    created_date,
    updated_date
)
SELECT
    applicant_id,
    first_name,
    last_name,
    date_of_birth,
    email,
    phone,
    state,
    postcode,
    updated_date,
    '9999-12-31',
    1,
    created_date,
    updated_date
FROM #changed_records;

-- Insert brand-new applicants

INSERT INTO dbo.DIM_Applicants (
    applicant_id,
    first_name,
    last_name,
    date_of_birth,
    email,
    phone,
    state,
    postcode,
    effective_start_date,
    effective_end_date,
    is_current,
    created_date,
    updated_date
)
SELECT
    s.applicant_id,
    s.first_name,
    s.last_name,
    s.date_of_birth,
    s.email,
    s.phone,
    s.state,
    s.postcode,
    s.updated_date,
    '9999-12-31',
    1,
    s.created_date,
    s.updated_date
FROM #src s
LEFT JOIN dbo.DIM_Applicants tgt
  ON s.applicant_id = tgt.applicant_id
WHERE tgt.applicant_id IS NULL;

-- Cleanup
--DROP TABLE #src;
--DROP TABLE #changed_records;

COMMIT;
