@echo off
rem ---------------------------------------------------------------------------------------------
rem The shipped starting point now lives in the SERVICE, not here: 1 kHz, block 50, the first 64
rem EEG channels plus the trigger, and mks64_standard.ced. See nvx136defaults.hpp.
rem
rem This launcher used to pass --serviceConfig params\nvx136_default64ch.json to get the channel
rem selection. That only ever worked for launches that went through this file -- a service started
rem from the Configurator, from a harness or by double-clicking the exe came up with nothing
rem selected -- and it could not survive a device reporting a different channel count, because
rem applyParameters refuses a selection whose length does not match the list. The preset is still
rem installed in params\ as an example to load by hand; it is no longer applied automatically.
rem ---------------------------------------------------------------------------------------------
call "%~dp0env.bat"
cd /d "%RESONANCE_DIR%\bin"
start "NVX136" nvx136.exe %*
