@echo off
rem launchbar: hide -- started from the Configurator icon strip via launchbar.txt.
rem Keep this helper out of the separately generated launch\ shortcut collection.
call "%~dp0env.bat"
cd /d "%RESONANCE_DIR%\bin"
start "recorderService" recorderService.exe %*
