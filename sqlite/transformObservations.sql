--
-- Transform synthea observations.csv file into format compatible with Summit Health.
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
       DATE AS DATEOFOBSERVATION,
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
       DATE AS DATEOFOBSERVATION,
       CODE,
       SUBSTR(DESCRIPTION,1,75) AS DESCRIPTION,
       NULL AS NUMERICVALUE,
       SUBSTR(VALUE,1,30) AS CHARACTERVALUE,
       SUBSTR(UNITS,1,22) AS UNITS
       FROM OBSERVATIONS 
       INNER JOIN SH_PATIENTS ON OBSERVATIONS.PATIENT = SH_PATIENTS.ID
       WHERE TYPE = 'text';

.exit