#!/bin/bash
# -----------------------------------------------------------------
# Generate patient data using Synthea and load into z/OS databases.
# Current directory must be where Synthea is installed.
# -----------------------------------------------------------------

if [ -d output/csv ]; then
  printf "\nERROR: The output/csv folder exists from a previous execution.  Please delete or rename it first.\n"
  exit 1
fi

NUMPATIENTS=$1
STATE=$2

scriptdir=`dirname ${BASH_SOURCE[0]}`
transforms=$scriptdir/sqlite
columndefs=$scriptdir/columndefs
jarfile=$scriptdir/target/loadutils-1.0.jar

if [ "$DATABASE_URL" = "" ]; then
  read -p "Enter database URL: " DATABASE_URL
fi

if [ "$DATABASE_USER" = "" ]; then
  read -p "Enter database userid: " DATABASE_USER
fi

if [ "$DATABASE_PASSWORD" = "" ]; then
  read -s -p "Enter database password: " DATABASE_PASSWORD
  printf "\n"
fi

if [ "$DATABASE_SCHEMA" = "" ]; then
  read -p "Enter database schema name: " DATABASE_SCHEMA
fi

now=$(date +"%T")
printf "\n$now: Generating data using Synthea\n"

./gradlew run -Params="[ '-p','$NUMPATIENTS', '$STATE' ]"

if [ ! -f output/csv/patients.csv ] || [ ! -f output/csv/medications.csv ] || [ ! -f output/csv/observations.csv ]; then
  printf "\nERROR: Synthea run did not create the expected csv files.  Check preceding messages.\n"
  exit 1
fi

now=$(date +"%T")
printf "\n$now: Getting information from z/OS tables\n"

java -cp $jarfile GetDBData output/csv/sh_variables.csv $DATABASE_URL $DATABASE_USER $DATABASE_PASSWORD $DATABASE_SCHEMA

if [ ! -f output/csv/sh_variables.csv ]; then
  printf "\nERROR: Problem obtaining data from database.  Check preceding messages.\n"
  exit 1
fi

now=$(date +"%T")
printf "\n$now: Transforming csv files\n"

sqlite3 < $transforms/transformPatients.sql
if [ ! -f output/csv/sh_patients.csv ] || [ ! -s output/csv/sh_patients.csv ]; then
  printf "\nERROR: Problem transforming patients CSV file.  Check preceding messages.\n"
  exit 1
fi

sqlite3 < $transforms/transformMedications.sql
if [ ! -f output/csv/sh_medications.csv ] || [ ! -s output/csv/sh_medications.csv ]; then
  printf "\nERROR: Problem transforming medications CSV file.  Check preceding messages.\n"
  exit 1
fi

sqlite3 < $transforms/transformObservations.sql
if [ ! -f output/csv/sh_observations.csv ] || [ ! -s output/csv/sh_observations.csv ]; then
  printf "\nERROR: Problem transforming observations CSV file.  Check preceding messages.\n"
  exit 1
fi

sqlite3 < $transforms/transformConditions.sql
if [ ! -f output/csv/sh_conditions.csv ] || [ ! -s output/csv/sh_conditions.csv ]; then
  printf "\nERROR: Problem transforming conditions CSV file.  Check preceding messages.\n"
  exit 1
fi

sqlite3 < $transforms/createAppointments.sql
if [ ! -f output/csv/sh_appointments.csv ] || [ ! -s output/csv/sh_appointments.csv ]; then
  printf "\nERROR: Problem transforming appointments CSV file.  Check preceding messages.\n"
  exit 1
fi

sqlite3 < $transforms/createUsers.sql
if [ ! -f output/csv/sh_users.csv ] || [ ! -s output/csv/sh_users.csv ]; then
  printf "\nERROR: Problem transforming users CSV file.  Check preceding messages.\n"
  exit 1
fi

now=$(date +"%T")
printf "\n$now: Loading z/OS tables\n"

java -cp $jarfile ZLoadFile output/csv/sh_patients.csv $columndefs/sh-patients-csvcolumns.txt $DATABASE_URL $DATABASE_USER $DATABASE_PASSWORD $DATABASE_SCHEMA.PATIENT
if [ $? -ge 8 ]; then
  printf "\nERROR: Problem loading patient data to z/OS database.  Check preceding messages.\n"
  exit 1
fi

java -cp $jarfile ZLoadFile output/csv/sh_medications.csv $columndefs/sh-medications-csvcolumns.txt $DATABASE_URL $DATABASE_USER $DATABASE_PASSWORD $DATABASE_SCHEMA.MEDICATION
if [ $? -ge 8 ]; then
  printf "\nERROR: Problem loading medications data to z/OS database.  Check preceding messages.\n"
  exit 1
fi

java -cp $jarfile ZLoadFile output/csv/sh_observations.csv $columndefs/sh-observations-csvcolumns.txt $DATABASE_URL $DATABASE_USER $DATABASE_PASSWORD $DATABASE_SCHEMA.OBSERVATIONS
if [ $? -ge 8 ]; then
  printf "\nERROR: Problem loading observations data to z/OS database.  Check preceding messages.\n"
  exit 1
fi

java -cp $jarfile ZLoadFile output/csv/sh_conditions.csv $columndefs/sh-conditions-csvcolumns.txt $DATABASE_URL $DATABASE_USER $DATABASE_PASSWORD $DATABASE_SCHEMA.CONDITIONS
if [ $? -ge 8 ]; then
  printf "\nERROR: Problem loading conditions data to z/OS database.  Check preceding messages.\n"
  exit 1
fi

java -cp $jarfile ZLoadFile output/csv/sh_appointments.csv $columndefs/sh-appointments-csvcolumns.txt $DATABASE_URL $DATABASE_USER $DATABASE_PASSWORD $DATABASE_SCHEMA.APPOINTMENTS
if [ $? -ge 8 ]; then
  printf "\nERROR: Problem loading appointments data to z/OS database.  Check preceding messages.\n"
  exit 1
fi

java -cp $jarfile ZLoadFile output/csv/sh_users.csv $columndefs/sh-users-csvcolumns.txt $DATABASE_URL $DATABASE_USER $DATABASE_PASSWORD $DATABASE_SCHEMA.USER
if [ $? -ge 8 ]; then
  printf "\nERROR: Problem loading users data to z/OS database.  Check preceding messages.\n"
  exit 1
fi

now=$(date +"%T")
printf "\n$now: Finished\n"
