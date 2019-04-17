@echo off
REM Don't remove the echo off above or the UDSAgent.log wilget silly comments
REM Note that you can use this script for any DB where the DB can be programatically quiesced.   
REM Just change syntax in thaw/freeze/abort section to make it relevant and any customize data in the section below.

REM THE SECTION BELOW NEEDS CUSTOMIZATION
REM THE INFO BELOW IS FAIRLY SELF APPARENT, SHAME ON ME FOR MAKING YOU ENTER A PASSWORD IN THE CLEAR
@set DATABASE=MaxDB
@set USERNAME=DBADMIN
@set PASSWORD=Passw0rd9
@set "PATH=C:\Program Files\sdb\MaxDB\pgm"
REM THE SECTION ABOVE NEEDS CUSTOMIZATION

REM  This is where the script is driven by the connector supplying one parm,   you can use this for testing the script
set TASK=%1
if %TASK% equ init goto :handle_init
if %TASK% equ fini goto :handle_fini
if %TASK% equ freeze goto :handle_freeze
if %TASK% equ thaw goto :handle_thaw
if %TASK% equ abort goto :handle_abort
echo Invalid task was given for the script to run, use init, fini, freeze, thaw or abort
goto :dirtyexit

:handle_init
echo Got an init command.  Nothing to do
goto :cleanexit

:handle_fini
echo Got an fini command.  Nothing to do
goto :cleanexit

:handle_freeze
echo ------------------------------------------ 
echo About to freeze %DATABASE% due to freeze request
echo ***** log active state 
dbmcli.exe -d %DATABASE% -u %USERNAME%,%PASSWORD% -uUTL -c show active
IF %errorlevel% NEQ 0 GOTO :dirtyexit
echo ***** issue suspend 
dbmcli.exe -d %DATABASE% -u %USERNAME%,%PASSWORD% -uUTL -c util_execute suspend logwriter 
IF %errorlevel% NEQ 0 GOTO :dirtyexit
echo ***** log active state after suspend 
dbmcli.exe -d %DATABASE% -u %USERNAME%,%PASSWORD% -uUTL -c show active
IF %ERRORLEVEL% EQU 0 GOTO cleanexit
exit /B 1

:handle_thaw
echo ------------------------------------------ 
echo About to thaw %DATABASE% due to thaw request
echo ***** log active state 
dbmcli.exe -d %DATABASE% -u %USERNAME%,%PASSWORD% -uUTL -c show active 
echo ***** issue resume 
dbmcli.exe -d %DATABASE% -u %USERNAME%,%PASSWORD% -uUTL -c util_execute resume logwriter 
IF %errorlevel% NEQ 0 GOTO :dirtyexit
echo ***** log active state after resume 
dbmcli.exe -d %DATABASE% -u %USERNAME%,%PASSWORD% -uUTL -c show active 
IF %ERRORLEVEL% EQU 0 GOTO cleanexit
exit /B 1


:handle_abort
echo ------------------------------------------ 
echo About to thaw %DATABASE% due to abort
echo Date and time: %date% %time% 
echo ***** log active state 
dbmcli.exe -d %DATABASE% -u %USERNAME%,%PASSWORD% -uUTL -c show active 
echo ***** issue resume 
dbmcli.exe -d %DATABASE% -u %USERNAME%,%PASSWORD% -uUTL -c util_execute resume logwriter 
echo ***** log active state after resume 
dbmcli.exe -d %DATABASE% -u %USERNAME%,%PASSWORD% -uUTL -c show active 
IF %ERRORLEVEL% EQU 0 GOTO cleanexit
exit /B 1

:cleanexit
exit /B 0

:dirtyexit
exit /B 1
