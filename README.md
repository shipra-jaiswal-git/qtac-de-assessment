# qtac-de-assessment
Solution for QTAC DE Assessment

**Approach:**

I chose Kimball dimensional modelling with SCD Type 2. The reason is it provides a simple and efficient star schema for reporting while preserving historical changes in dimensions to ensure accurate analysis over time.
Surrogate keys ensure the fact links to the correct historical version of dimension data.

**Data quality issues**

Applicant Table-
1.	Applicant_id = 1002 appears multiple times in applicants_update --pick the latest based on latest update date
2.	Last name and State changed for 1002 and 1005 so we need to implement SCD 2 to have the history
3.	date_of_birth is a critical one and help us to calculate age in downstream so must not be null.
4.	Missing phone – Mode of communication so ideally should not be null
5.	Missing atar_cutoff for courses --can create issue in defining the eligibility
Preferences Table – 
1.	Offer_Date - A validation can be put in if offer_status is not null then offer_date must be populated.
2.	Response - If offer_status is not null then response should also be not null (at least Pending state if not Accepted or Declined)
3.	If offer_status is 'Offered' and response is null then we can't calculate the outcome.
4.	Response_Date - Should be populated if Response is Accepted or Declined
			
Qualifications Table – 
1.	At least one of atar or gpa fields should be populated (depending on qualification type ).			
2.	referential Integrity--qualification.applicant_id = 9999 does not exist in applicants. 
Courses –
1.	Study mode few full lower case and few max case so we can make it uniform across.

**Validations could be done as below. Few things I have considered while implementation**

1.	State field can be validated against a list of valid state codes.
2.	Similarly, postcodes can be validated against auspost reference table (can be ingested separately)
3.	Can put a check on email format as well if it’s a valid email or not.
4.	Referential Integrity Check : In qualification, applicant_id = 9999 does not exist in applicants So ignored that while populating the Dim Qualification. This prevents orphan records and maintains data integrity.
5.	An applicant could have more than one qualification, so I have chosen the latest one based on year_completed for showing the Institution_Name.  

**Assumptions:**
1.	for Applicant_update I assumed its full dump so truncated the STG_Applicant in each load.
2.	If its delta so in that case we can append the data in STG_Applicant with extra column details like file name and Extract Date and in each load, process only the latest Extract Date data to Dim_Applicant

**Ingestion Flow:**

•	STG_Applicant + SCD2 logic → DIM_Applicants 

•	STG_Courses + SCD2 logic → DIM_Courses

•	STG_Qualifications → DIM_Qualifications

•	STG_Preferences + DIM_Applicants + DIM_Courses + DIM_Qualifications → FACT_Application

•	Final Outcome is derived from FACT_Application table joining with multiple dimensions.

