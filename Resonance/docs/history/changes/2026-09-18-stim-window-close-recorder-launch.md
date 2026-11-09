# 2026-09-18 — Stimulation-window close and standalone Recorder launcher

Status: implemented, built and deployed to `R:\dist` on 2026-09-18.

## Changes

- mStim, eStim and feetStim now accept their main-window close event and call `QApplication::quit()`. Closing X exits the event loop and runs existing service destructors, preserving device stop/release, link closure and settings save. This does not add a force-kill path.
- `showUi=false` still hides the window without terminating the service; the application keeps `setQuitOnLastWindowClosed(false)` for this use. Parameter descriptions and lifecycle comments distinguish the two actions.
- The Configurator's shipped default Recorder entry now points to `recorderService.bat`, which launches `recorderService.exe`. The existing `R:\dist\launchbar.txt` received the same single-entry change. Its other operator entries were preserved. The older `recorder.bat` remains available for explicit built-in-recorder launches.
- The standalone launcher retains its `launchbar: hide` marker for the separate generated-shortcut collection; the explicit icon-strip entry still launches it.

## Verification

`src/scripts/build-qt6.ps1 -SkipConan` completed successfully. Existing hardware-free CTest suites `test_MStim`, `test_EStimPreset` and `test_FeetStim` passed (3/3).

The documentation checker passed: 223 Markdown files, 1862 local links, 11 unchanged Word publications, zero errors. Deployed executable hashes matched the build outputs; the live launchbar differed from its backup only in the intended Recorder entry.

New stimulation executables were tested from an isolated candidate directory with disposable INIs, serial auto-open disabled and eStim/feetStim UDP disabled. All remained disconnected in `init`. A QML harness toggled `showUi` false/true; all three processes survived and exposed their windows again. Direct X clicks on mStim and eStim removed the windows and processes. The feetStim close action was interrupted by the user's Escape stop of desktop automation: subsequent process inspection found it exited and its test INI saved, but the automation's click confirmation is unavailable. No further desktop input was sent. All three candidate INIs were saved by normal teardown; no stimulation/connect commands were issued. Physical-device shutdown was not exercised.

A separate QML harness used the deployed `LaunchBarModel`, located the standalone Recorder row and called the same `launch(row)` invoked by the icon. It reported `program recorderService` and launch success. Process inspection observed PID 51876 at `R:\dist\bin\recorderService.exe`. The harness discovered it in `idle` and sent `!terminate`; the process exited. No recording was started. This verifies the launcher path without an additional desktop click.

## Deployment and evidence

Copied only `bin/mStim.exe`, `bin/eStim.exe`, `bin/feetStim.exe`, `launchbar-default.txt` and `recorderService.bat`; updated only the Recorder line in the live `launchbar.txt`. Source/build and distribution use the same `Resonance.dll` SHA-256, so no shared DLL update was required. Existing rig INIs, frame libraries and presets were preserved.

Local evidence and rollback copies are under `R:\tests\evidence\stim-close-recorder-20260918`: `source-before`, `distribution-before`, `build.log`, `ctest.log`, `window-close-results.json`, `recorder-launch-results.json`, launcher logs and `deployed-sha256.json`. The first hidden-window probe could not obtain a visible main-window handle; later showUi toggling made the windows available for direct checks. An initial launcher harness error caused by the imported `String` type was fixed before the successful run.
