@echo off
setlocal
set "ROOT=%~dp0"
call "%ROOT%env.bat"
cd /d "%ROOT%bin"
"%ROOT%bin\SPEED.exe" --serviceConfig "%ROOT%params\speed_two_hands.json"
