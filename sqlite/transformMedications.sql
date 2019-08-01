--
-- Transform synthea medications.csv file into format compatible with Example Health.
--
-- Usage:
--   1. set working directory to Synthea project
--   2. run "sqlite3 < transformMedications.sql"
--
-- Input:  medications.csv, sh_patients.csv
-- Output: sh_medications.csv
--
-- Dependencies:
--   1. Tranform the patients.csv file first to get integer patient ids assigned.
--

-- Read input files

.mode csv
.import output/csv/medications.csv medications
.import output/csv/sh_patients.csv sh_patients

-- Open output file

.headers on
.output output/csv/sh_medications.csv

-- Transform CSV file.
--   * Join with the transformed patients CSV file to get the integer patient ids.
--   * Truncate columns.
--   * Set columns not produced by Synthea to blank.

SELECT PATIENTID,
       SUBSTR(DESCRIPTION,1,50) AS DRUGNAME,
       " " AS STRENGTH, 
       0 AS AMOUNT, 
       " " AS ROUTE, 
       " " AS FREQUENCY, 
       " " AS IDENTIFIER, 
       " " AS TYPE
       FROM MEDICATIONS 
       INNER JOIN SH_PATIENTS ON MEDICATIONS.PATIENT = SH_PATIENTS.ID
       WHERE STOP = '';

.exit