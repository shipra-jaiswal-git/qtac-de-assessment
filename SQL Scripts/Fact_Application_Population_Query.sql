--Assuming we are receiving delta in Preference

DELETE f
FROM dbo.fact_application f
where exists (SELECT 1 FROM dbo.stg_preferences s
    where f.preference_id = s.preference_id);


WITH cleaned AS (
    SELECT
        preference_id,
        applicant_id,
        course_code,
        preference_order,
        application_year,
        offer_status,
        TRY_CAST(offer_date AS DATE) AS offer_date,
        response,
        TRY_CAST(response_date AS DATE) AS response_date
    FROM dbo.stg_preferences
),

deduped AS (
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY preference_id  ORDER BY response_date DESC
               ) AS rn
        FROM cleaned
    ) x
    WHERE rn = 1
)

INSERT INTO Fact_Application (
    applicant_sk,
    course_sk,
	applicant_id,
	preference_order,
    application_year,
    offer_status,
    offer_date,
    response,
    response_date,
    preference_id,
    course_code,
    publish_date
)
SELECT
    a.applicant_sk,
    c.course_sk,
	d.applicant_id,
    d.preference_order,
    d.application_year,
    d.offer_status,
    d.offer_date,
    d.response,
    d.response_date,	
    d.preference_id,
    d.course_code,
    GETDATE()
FROM deduped d
JOIN dbo.dim_applicants a
    ON d.applicant_id = a.applicant_id
    AND a.is_current = 1
	-- coalesce(coalesce(d.response_date , d.offer_date),'9999-12-31') between a.effective_start_date and a.effective_end_date

JOIN dbo.dim_courses c
    ON d.course_code = c.course_code
	AND c.is_current = 1
	-- coalesce(coalesce(d.response_date , d.offer_date),'9999-12-31') between c.effective_start_date and c.effective_end_date