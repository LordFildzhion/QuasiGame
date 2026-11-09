@echo off
rem launchbar: hide -- with no --builtIn this IS the Configurator, which configurator.bat already
rem launches. The launch\ shortcuts (make-launcher-shortcuts.ps1) skip a file with this line.
call "%~dp0env.bat"
cd /d "%RESONANCE_DIR%\bin"
start "quickStimulus" quickStimulus.exe %*
