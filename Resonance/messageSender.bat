@echo off
rem A hand-driven message sender: open a named message stream and publish text into it by
rem hand. For poking a protocol, a trigger path or a subscriber without wiring up a device.
rem
rem NOT a signal generator -- that is signalGenerator.bat / SignalGenerator.exe, in this same
rem directory. This launcher was called generator.bat until 2026-09-06.
call "%~dp0quickStimulus.bat" --builtIn messageSender %*
