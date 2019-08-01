--
-- Transform synthea conditions.csv file into format compatible with Example Health.
--
-- Usage:
--   1. set working directory to Synthea project
--   2. run "sqlite3 < transformConditions.sql"
--
-- Input:  conditions.csv, sh_patients.csv
-- Output: sh_conditions.csv
--
-- Dependencies:
--   1. Tranform the patients.csv file first to get integer patient ids assigned.
--

-- Read input files

.mode csv
.import output/csv/conditions.csv conditions
.import output/csv/sh_patients.csv sh_patients

-- Open output file

.headers on
.output output/csv/sh_conditions.csv

-- Transform CSV file.
--   * Join with the transformed patients CSV file to get the integer patient ids.

SELECT PATIENTID,
       START,
       STOP,
       CODE,
       SUBSTR(DESCRIPTION,1,75) AS DESCRIPTION
       FROM CONDITIONS 
       INNER JOIN SH_PATIENTS ON CONDITIONS.PATIENT = SH_PATIENTS.ID;

.exit