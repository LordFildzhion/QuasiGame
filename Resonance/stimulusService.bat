@echo off
setlocal
call "%~dp0env.bat"
pushd "%~dp0"
"%~dp0bin\stimulusService.exe" %*
set "result=%errorlevel%"
popd
exit /b %result%
