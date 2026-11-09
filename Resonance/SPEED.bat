@echo off
call "%~dp0env.bat"
cd /d "%RESONANCE_DIR%\bin"
start "SPEED" SPEED.exe  --serviceConfig "%~dp0\params\speed_muclassifier.json" %*
