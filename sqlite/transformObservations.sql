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
-- Transform synthea observations.csv file into format compatible with Example Health.
--
-- Usage:
--   1. set working directory to Synthea project
--   2. run "sqlite3 < transformObservations.sql"
--
-- Input:  observations.csv, sh_patients.csv
-- Output: sh_observations.csv
--
-- Dependencies:
--   1. Tranform the patients.csv file first to get integer patient ids assigned.
--

-- Read input files

.mode csv
.import output/csv/observations.csv observations
.import output/csv/sh_patients.csv sh_patients

-- Open output file

.headers on
.output output/csv/sh_observations.csv

-- Transform CSV file.
--   * Join with the transformed patients CSV file to get the integer patient ids.
--   * Truncate columns.
--   * Remove zero-width space characters (x'E2808B') from description as they consume bytes from 75 byte limit.

SELECT PATIENTID,
       DATE(DATE) AS DATEOFOBSERVATION,
       CODE,
       SUBSTR(REPLACE(DESCRIPTION, x'E2808B', ''),1,75) AS DESCRIPTION,
       VALUE AS NUMERICVALUE,
       "" AS CHARACTERVALUE,
       SUBSTR(UNITS,1,22) AS UNITS
       FROM OBSERVATIONS 
       INNER JOIN SH_PATIENTS ON OBSERVATIONS.PATIENT = SH_PATIENTS.ID
       WHERE TYPE = 'numeric'

UNION ALL

SELECT PATIENTID,
       DATE(DATE) AS DATEOFOBSERVATION,
       CODE,
       SUBSTR(DESCRIPTION,1,75) AS DESCRIPTION,
       NULL AS NUMERICVALUE,
       SUBSTR(VALUE,1,30) AS CHARACTERVALUE,
       SUBSTR(UNITS,1,22) AS UNITS
       FROM OBSERVATIONS 
       INNER JOIN SH_PATIENTS ON OBSERVATIONS.PATIENT = SH_PATIENTS.ID
       WHERE TYPE = 'text';

.exit