@echo off
setlocal
set "PROJECT_ROOT=%~dp0"
set "SPEED_ROOT=%PROJECT_ROOT%Resonance"
set "GAME_PY=%PROJECT_ROOT%Runtime\GameVenv\Scripts\python.exe"
if not exist "%PROJECT_ROOT%Runtime\setup_complete.txt" goto setup
if not exist "%GAME_PY%" goto setup
goto launch
:setup
call "%PROJECT_ROOT%Install.bat"
if errorlevel 1 exit /b 1
:launch
if not exist "%SPEED_ROOT%\bin\SPEED.exe" (
  echo SPEED.exe is missing.
  exit /b 1
)
if not exist "%SPEED_ROOT%\params\speed_two_hands.json" (
  echo The two-hand SPEED profile is missing.
  exit /b 1
)
start "SPEED EMG" "%PROJECT_ROOT%Start_SPEED_Internal.bat"
rem Keep the game environment separate from Resonance's embedded Python.
set "PYTHONHOME="
set "PYTHONPATH=%PROJECT_ROOT%"
set "PYTHONNOUSERSITE="
start "QuasiGame" /D "%PROJECT_ROOT%" "%GAME_PY%" -m Integration.run_game

echo.
echo SPEED and QuasiGame opened.
echo Connect the native LSL source in Resonance, select it in SPEED, then click Prepare and Start.
echo The first 2 seconds are used to estimate the resting EMG noise floor; keep both hands relaxed.
