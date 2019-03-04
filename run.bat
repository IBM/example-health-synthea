@REM -----------------------------------------------------------------
@REM Generate patient data using Synthea and load into z/OS databases.
@REM Current directory must be where Synthea is installed.
@REM -----------------------------------------------------------------

@if exist output\csv goto existingOutputERROR

@SETLOCAL

@SET NUMPATIENTS=%1
@SET STATE=%~2

@SET scriptdir=%~dp0
@SET transforms=%scriptdir%sqlite
@SET columndefs=%scriptdir%columndefs
@SET jarfile=%scriptdir%target\loadutils-1.0.jar

@if "%DATABASE_URL%"=="" @set /p DATABASE_URL="Enter database URL: "
@if "%DATABASE_USER%"=="" @set /p DATABASE_USER="Enter database userid: "
@if "%DATABASE_PASSWORD%"=="" @set /p DATABASE_PASSWORD="Enter database password: "
@if "%DATABASE_SCHEMA%"=="" @set /p DATABASE_SCHEMA="Enter database schema name: "

@echo. && @echo %TIME%: Generating data using Synthea && @echo.

call ./gradlew.bat run -Params="[ '-p','%NUMPATIENTS%', '%STATE%' ]"
if not exist output\csv\patients.csv goto syntheaERROR
if not exist output\csv\medications.csv goto syntheaERROR
if not exist output\csv\observations.csv goto syntheaERROR

@echo. && @echo %TIME%: Getting information from z/OS tables && @echo.

java -cp %jarfile% GetDBData output/csv/sh_variables.csv %DATABASE_URL% %DATABASE_USER% %DATABASE_PASSWORD% %DATABASE_SCHEMA%
if not exist output\csv\sh_variables.csv goto getDBDataERROR

@echo. && @echo %TIME%: Transforming csv files && @echo.

sqlite3 < %transforms%\transformPatients.sql
if not exist output\csv\sh_patients.csv goto sqliteERROR

sqlite3 < %transforms%\transformMedications.sql
if not exist output\csv\sh_medications.csv goto sqliteERROR

sqlite3 < %transforms%\transformObservations.sql
if not exist output\csv\sh_observations.csv goto sqliteERROR

sqlite3 < %transforms%\transformConditions.sql
if not exist output\csv\sh_conditions.csv goto sqliteERROR

sqlite3 < %transforms%\createAppointments.sql
if not exist output\csv\sh_appointments.csv goto sqliteERROR

sqlite3 < %transforms%\createUsers.sql
if not exist output\csv\sh_users.csv goto sqliteERROR

@echo. && @echo %TIME%: Loading z/OS tables && @echo.

java -cp %jarfile% ZLoadFile output/csv/sh_patients.csv %columndefs%/sh-patients-csvcolumns.txt %DATABASE_URL% %DATABASE_USER% %DATABASE_PASSWORD% %DATABASE_SCHEMA%.PATIENT
if errorlevel 8 goto zloadERROR

java -cp %jarfile% ZLoadFile output/csv/sh_medications.csv %columndefs%/sh-medications-csvcolumns.txt %DATABASE_URL% %DATABASE_USER% %DATABASE_PASSWORD% %DATABASE_SCHEMA%.MEDICATION
if errorlevel 8 goto zloadERROR

java -cp %jarfile% ZLoadFile output/csv/sh_observations.csv %columndefs%/sh-observations-csvcolumns.txt %DATABASE_URL% %DATABASE_USER% %DATABASE_PASSWORD% %DATABASE_SCHEMA%.OBSERVATIONS
if errorlevel 8 goto zloadERROR

java -cp %jarfile% ZLoadFile output/csv/sh_conditions.csv %columndefs%/sh-conditions-csvcolumns.txt %DATABASE_URL% %DATABASE_USER% %DATABASE_PASSWORD% %DATABASE_SCHEMA%.CONDITIONS
if errorlevel 8 goto zloadERROR

java -cp %jarfile% ZLoadFile output/csv/sh_appointments.csv %columndefs%/sh-appointments-csvcolumns.txt %DATABASE_URL% %DATABASE_USER% %DATABASE_PASSWORD% %DATABASE_SCHEMA%.APPOINTMENTS
if errorlevel 8 goto zloadERROR

java -cp %jarfile% ZLoadFile output/csv/sh_users.csv %columndefs%/sh-users-csvcolumns.txt %DATABASE_URL% %DATABASE_USER% %DATABASE_PASSWORD% %DATABASE_SCHEMA%.USER
if errorlevel 8 goto zloadERROR

@echo. && @echo %TIME%: Finished && @echo.
goto end

:existingOutputERROR
@echo. && echo ERROR: The output/csv folder exists from a previous execution.  Please delete or rename it first.
goto end

:syntheaERROR
@echo. && echo ERROR: Synthea run did not create the expected csv files.  Check preceding messages.
goto end

:getDBDataERROR
@echo. && echo ERROR: Problem obtaining data from database.  Check preceding messages.
goto end

:sqliteERROR
@echo. && echo ERROR: Problem transforming CSV files.  Check preceding messages.
goto end

:zloadERROR
@echo. && echo ERROR: Problem loading data to z/OS database.  Check preceding messages.
goto end

:end