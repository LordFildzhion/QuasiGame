@echo off
rem Service name and stream name are given explicitly: discovery addresses a stream as
rem (service name, stream name), so two generators started with the stock names are
rem indistinguishable to a viewer or a recorder, which then attaches to whichever answered
rem first. To run a second generator, copy this file and change both names.
rem Anything passed on the command line still wins -- the last option on the line is used.
call "%~dp0env.bat"
cd /d "%RESONANCE_DIR%\bin"
start "signalGenerator" SignalGenerator.exe --serviceName signalGenerator --streamName generated %*
