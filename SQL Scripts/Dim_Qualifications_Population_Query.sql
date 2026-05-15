MERGE dbo.[DIM_Qualifications] AS tgt
USING (
SELECT
    d.applicant_sk,
	s.qualification_id,
    s.qualification_type,
    s.institution_name,
    s.year_completed,
    s.gpa,
    s.atar_score,
    s.verified
FROM stg_qualifications s
JOIN dim_applicants d
    ON s.applicant_id = d.applicant_id
    AND d.is_current = 1
) src
ON tgt.qualification_id = src.qualification_id


WHEN MATCHED THEN
    UPDATE SET
		applicant_sk=src.applicant_sk,
        qualification_type = src.qualification_type,
        atar_score = src.atar_score,
		institution_name=src.institution_name,
		year_completed=src.year_completed,
		gpa=src.gpa,
		verified=src.verified
		
WHEN NOT MATCHED THEN
    INSERT (
        qualification_id,
        applicant_sk,
        qualification_type,
        atar_score,
		institution_name,
		year_completed,
		gpa,
		verified
    )
    VALUES (
        src.qualification_id,
        src.applicant_sk,
        src.qualification_type,
        src.atar_score,
		src.institution_name,
		src.year_completed,
		src.gpa,
		src.verified
    );
