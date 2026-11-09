@echo off
rem launchbar: hide -- the worker needs arguments (below); playbackService.bat is the launcher an
rem operator wants, so the launch\ shortcuts skip this file (the Configurator's icon strip is
rem launchbar.txt, which does not list it either).
rem
rem One spoofed service replaying a recording, without the controller. Everything has to be
rem given on the command line, for example:
rem
rem   playbackSource.bat --file "R:\dist_Qt5\msvc64\data\session-0001.h5" --serviceName NVX136 --autoStart
rem   playbackSource.bat --file session.h5 --serviceName NVX --stream eeg --speed 2 --loop
rem
rem With no --stream it publishes every playable stream in the file under its recorded name.
rem
rem This is the playback WORKER, not the operator-facing module -- playbackService.bat is that,
rem and it starts these itself. Launched with no arguments there is nothing to play, so say so
rem rather than starting a service that immediately exits: `start` detaches the process, so the
rem exe's own refusal would go to a console nobody is looking at.
if "%~1"=="" (
    echo.
    echo playbackSource: nothing to play.
    echo.
    echo   This is the playback WORKER. Use playbackService.bat for the operator module --
    echo   choose a file, map the streams, press Prepare then Play.
    echo.
    echo   To replay a file with no controller, give it at least --file:
    echo.
    echo     playbackSource.bat --file session.h5 --serviceName NVX136 --autoStart
    echo     playbackSource.bat --file session.h5 --serviceName NVX --stream eeg --speed 2 --loop
    echo.
    pause
    exit /b 2
)
call "%~dp0env.bat"
cd /d "%RESONANCE_DIR%\bin"
start "playbackSource" playbackSource.exe %*
