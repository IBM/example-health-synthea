--
-- Create an appointments csv file for synthea patients.
--
-- Usage:
--   1. set working directory to Synthea project
--   2. run "sqlite3 < createUsers.sql"
--
-- Input:  sh_patients.csv
-- Output: sh_users.csv
--
-- Dependencies:
--   1. Tranform the patients.csv file first to get integer patient ids assigned.
--

-- Read input file

.mode csv
.import output/csv/sh_patients.csv sh_patients

-- Create dummy appointments

CREATE TABLE APPOINTMENTS AS 
  SELECT PATIENTID,
         FIRSTNAME,
         LASTNAME,
         DATE('now','+3 months') AS APPT_DATE,
         '08:00' AS APPT_TIME,
         'Primary Care Physician' AS MED_FIELD,
         'Example Health' AS OFF_NAME,
         '1 Main St' AS OFF_ADDR,
         CITY AS OFF_CITY,
         POSTCODE AS OFF_ZIP
         FROM SH_PATIENTS;

-- Open output file

.headers on
.output output/csv/sh_appointments.csv

-- Output table

SELECT * FROM APPOINTMENTS;