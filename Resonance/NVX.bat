@echo off
call "%~dp0env.bat"
cd /d "%RESONANCE_DIR%\bin"
start "NVX" nvx.exe %*
