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
    AND a.is_current = 1

JOIN dbo.dim_courses c
    ON r.course_sk = c.course_sk

LEFT JOIN dbo.dim_qualifications q
    ON a.applicant_sk = q.applicant_sk   

WHERE r.rn = 1;