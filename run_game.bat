@echo off
setlocal
set "PROJECT_ROOT=%~dp0"
set "GAME_PY=%PROJECT_ROOT%Runtime\GameVenv\Scripts\python.exe"
if not exist "%GAME_PY%" (
  echo Game environment is missing. Run Install.bat first.
  pause
  exit /b 1
)
set "PYTHONHOME="
set "PYTHONPATH=%PROJECT_ROOT%"
set "PYTHONNOUSERSITE="
"%GAME_PY%" -m Integration.run_game %*
