@echo off
setlocal
if /I "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto supported
if /I "%PROCESSOR_ARCHITEW6432%"=="AMD64" goto supported
echo This package requires Intel/AMD 64-bit Windows.
set "driverResult=1"
goto finish
:supported
if exist "%~dp0setup.exe" goto vendor
if not exist "%~dp0*.inf" goto missing
set "driverPnpUtil=%SystemRoot%\System32\pnputil.exe"
if exist "%SystemRoot%\Sysnative\pnputil.exe" set "driverPnpUtil=%SystemRoot%\Sysnative\pnputil.exe"
echo Installing this folder's driver package. Administrator rights are required.
"%driverPnpUtil%" /add-driver "%~dp0*.inf" /install
set "driverResult=%errorlevel%"
goto result
:vendor
start "" /wait "%~dp0setup.exe"
set "driverResult=%errorlevel%"
goto result
:missing
echo Driver files are missing.
set "driverResult=2"
goto finish
:result
if "%driverResult%"=="0" echo Installation completed.
if "%driverResult%"=="3010" echo Installation completed. Windows restart required.
if not "%driverResult%"=="0" if not "%driverResult%"=="3010" echo Installation failed. Code: %driverResult%
:finish
pause
exit /b %driverResult%
