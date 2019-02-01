--
-- Create a users csv file for synthea patients.
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

-- Create users

CREATE TABLE USERS AS 
  SELECT PATIENTID,
         USERNAME,
         'pass' AS USERPASSWORD
         FROM SH_PATIENTS;

-- Open output file

.headers on
.output output/csv/sh_users.csv

-- Output table

SELECT * FROM USERS;