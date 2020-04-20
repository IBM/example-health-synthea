------------------------------------------------------------------------------
-- Copyright 2019 IBM Corp. All Rights Reserved.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--       http://www.apache.org/licenses/LICENSE-2.0
--
--   Unless required by applicable law or agreed to in writing, software
--   distributed under the License is distributed on an "AS IS" BASIS,
--   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--   See the License for the specific language governing permissions and
--   limitations under the License.
------------------------------------------------------------------------------

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