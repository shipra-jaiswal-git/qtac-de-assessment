--CREATE VIEW vw_applicant_summary AS
WITH ranked AS (
    SELECT
        f.applicant_sk,
        f.course_sk,
        f.preference_order,
        f.response,
        ROW_NUMBER() OVER (
            PARTITION BY f.applicant_sk
            ORDER BY f.preference_order ASC   -- lowest = highest preference
        ) AS rn
    FROM dbo.fact_application f
    WHERE f.response = 'Accepted'
)
,

latest_qualification AS (
    SELECT
        q.*,
        ROW_NUMBER() OVER (
            PARTITION BY q.applicant_sk
            ORDER BY q.year_completed DESC
        ) AS rn
    FROM dbo.dim_qualifications q
)


SELECT
    a.first_name + ' ' + a.last_name AS applicant_name,
    a.state,
    c.course_name,
    c.institution_name,
    q.qualification_type,
    q.atar_score

FROM ranked r

-- Pick highest accepted preference
JOIN dbo.dim_applicants a
    ON r.applicant_sk = a.applicant_sk

JOIN dbo.dim_courses c
    ON r.course_sk = c.course_sk

LEFT JOIN latest_qualification q
    ON a.applicant_sk = q.applicant_sk  
    AND q.rn = 1	

WHERE r.rn = 1;