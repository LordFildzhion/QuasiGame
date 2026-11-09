@echo off
pushd .
cd /d "%~dp0"
set "RESONANCE_DIR=%CD%"
set "RESONANCE_PATH=%CD%\bin;%CD%\qt\bin"

rem ---------------------------------------------------------------------------------------------
rem Where each kind of content lives.
rem
rem Every launcher does "cd bin" before "start", so without these the process working directory is
rem <root>\bin and that is where Save and Load opened -- among the DLLs. Each variable overrides
rem one folder; the rule is the folder's own name, uppercased, between RESONANCE_ and _PATH. The
rem one exception is recordings: they live in data\ but the variable has been RESONANCE_RECORD_PATH
rem since long before the others existed.
rem
rem None of them is required. With nothing set, every Resonance binary derives <root> from its own
rem location (bin\..) and uses <root>\<folder>, so a desktop shortcut straight into bin\ that never
rem runs this file still lands in the right place. Set one only to move that folder elsewhere --
rem a data drive for recordings, a shared params\ on a network path.
rem ---------------------------------------------------------------------------------------------
set "RESONANCE_RECORD_PATH=%CD%\data"
set "RESONANCE_PARAMS_PATH=%CD%\params"
set "RESONANCE_PROTOCOLS_PATH=%CD%\protocols"
set "RESONANCE_STIMULI_PATH=%CD%\stimuli"
set "RESONANCE_MONTAGES_PATH=%CD%\montages"
set "RESONANCE_CALIB_PATH=%CD%\calib"
if not exist "%RESONANCE_RECORD_PATH%\" mkdir "%RESONANCE_RECORD_PATH%"
if not exist "%RESONANCE_PARAMS_PATH%\" mkdir "%RESONANCE_PARAMS_PATH%"
if not exist "%RESONANCE_MONTAGES_PATH%\" mkdir "%RESONANCE_MONTAGES_PATH%"

rem The Qt 6 runtime is private to this distribution. Explicit paths make the launchers
rem independent of whichever Qt version Qt Creator or another service put on the machine.
set "QT_PLUGIN_PATH=%CD%\qt\plugins"
set "QML2_IMPORT_PATH=%CD%\bin;%CD%\qt\qml"
if exist "%CD%\python\python312.zip" (
    set "PYTHONHOME=%CD%\python"
    set "PYTHONNOUSERSITE=1"
    set "PYTHONPATH=%CD%\python\Lib\site-packages;%CD%\mulines\src"
    set "PATH=%RESONANCE_PATH%;%CD%\python;%PATH%"
) else (
    set "PATH=%RESONANCE_PATH%;%PATH%"
)
popd
