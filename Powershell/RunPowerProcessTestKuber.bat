ECHO OFF
COLOR 9F
CLS
REM SET LOGTID=
echo %DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
SET STI=%CD%
SET LOGSTI=%STI%\LOG\
SET LOGFIL=%LOGSTI%DELLOG_%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%.txt
ECHO %STI% >> %LOGFIL%
Powershell.exe -executionpolicy Bypass -File  %STI%\ProcessTestKuber.ps1 
IF NOT %ERRORLEVEL%==1 (ECHO Processering fejlet >> %LOGFIL%) 