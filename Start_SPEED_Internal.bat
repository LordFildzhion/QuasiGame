@echo off
setlocal
set "SPEED_ROOT=%~dp0Resonance"
if not exist "%SPEED_ROOT%\env.bat" (
    echo Missing Resonance environment: "%SPEED_ROOT%\env.bat"
    pause
    exit /b 1
)
if not exist "%SPEED_ROOT%\params\speed_two_hands.json" (
    echo Missing two-output SPEED profile.
    pause
    exit /b 1
)
call "%SPEED_ROOT%\env.bat"
if errorlevel 1 (
    echo Failed to load Resonance environment.
    pause
    exit /b 1
)
cd /d "%SPEED_ROOT%\bin"
"%SPEED_ROOT%\bin\SPEED.exe" --serviceConfig "%SPEED_ROOT%\params\speed_two_hands.json"
if errorlevel 1 (
    echo SPEED exited with error code %ERRORLEVEL%.
    pause
)
