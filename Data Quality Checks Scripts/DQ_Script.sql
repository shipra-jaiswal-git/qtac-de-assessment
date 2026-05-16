
--Referential Integrity Check

SELECT q.*
FROM dbo.dim_qualifications q
LEFT JOIN dbo.dim_applicants a
    ON q.applicant_sk = a.applicant_sk
WHERE a.applicant_sk IS NULL;


--Email format

SELECT *
FROM dbo.dim_applicants
WHERE email NOT LIKE '%_@_%._%'
   OR email IS NULL
   
-- State code validation


SELECT *
FROM dbo.dim_applicants
WHERE state NOT IN ('NSW','VIC','QLD','WA','SA','TAS','ACT','NT')
   OR state IS NULL
   
-- Invalid application responses


SELECT *
FROM dbo.fact_application
WHERE response NOT IN ('Accepted','Declined','Pending','Not Offered');

--Response date < Offer Date


SELECT *
FROM dbo.fact_application
WHERE response_date < offer_date;


--SCD2 implementation check


SELECT applicant_id, COUNT(*)
FROM dbo.dim_applicants
WHERE is_current = 1
GROUP BY applicant_id
HAVING COUNT(*) > 1;







