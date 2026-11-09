# 2026-09-18 — Configurator service identity and delayed trigger lanes

Status: fixed, tested and deployed to `R:\dist` on 2026-09-18.

## Service below NVX appeared as eeg

The reported sequence was NVX EEG present, stop (stream removed), then second start (stream returns), with eStim below NVX in the table. The real service kept its name. Qt 6.11.2 TreeView delegate reuse retained the removed EEG cell's `name` and `controller` roles when that cell was assigned to the following service. This affected stream/service interaction identity as well as text; rereading settings did not change the already-correct service model.

The regression loads the real Configurator, supplies isolated synthetic EventBus descriptions through ServiceControl, expands/selects EEG, removes it and inserts it again three times. It compares each loaded cell's name and service controller with the source model. The original deployed plugin/QML fails with `expected TreeFixtureEStim got eeg` and `wrong service controller`. Disabling `reuseItems` on this compact TreeView fixes that failure without resetting selection/expansion on each stream change. Both columns now receive ServiceLocator data-change notifications, fixing stale roles in the recording column too. Fixing column notifications alone did not fix delegate reuse; that intermediate test failure is retained.

## Pulses appeared behind the sweep cursor

Inspected the supplied four-second, 30-fps video using extracted PNG frames. Around 1.20 s the viewer still labels the lane Trig0; at 1.50 s it changes to Trig4 and reveals several already-arrived pulses. The write cursor had continued advancing throughout. Source inspection found active-bit lane discovery was performed only by the one-second maintenance tick.

The ingest path now accumulates changed trigger bits in its existing raw-sample edge scan and rebuilds lanes before announcing the advancing sweep. The periodic ring scan still removes inactive lanes after their edges leave the visible window. No acquisition buffer size, driver timing, sample data, filter delay or recording path was changed.

The regression delivers active-low bit-4 samples in consecutive blocks without an event-loop/timer turn. It asserts the correct lane immediately, paints the viewer into an image, and checks both high and low trace levels. It also covers a second bit and immediate reappearance after maintenance retires a bit. The old implementation fails; the fixed one passes.

## Verification and deployment

- Normal Qt 6 build (`src/scripts/build-qt6.ps1 -SkipConan`) succeeded.
- CTest suites `test_StreamConnectorQml`, `test_ViewerReconnect`, and `test_ConfiguratorLiveStatus` passed, including existing filter recovery, live status, pending-edit and Delete focus guards.
- Final synthetic tree fixture was also run against the original deployed plugin/QML and reproduced the wrong EEG/service identity.
- Updated only `dist/bin/Resonance/quickStimulusPlugin.dll` and `Configurator.qml`; deployed plugin hash matches the build.
- Saved the running Configurator's 18 parameters and restored them on restart. NVX PID 50380 and eStim PID 53792 remained running; no hardware transitions were sent. Final Configurator PID 43212 displayed the restored NVX viewer and correctly named service rows. Selection/expansion and historical display samples are transient and restart clears them.

The initial restart was hidden by the launch helper's startup flag; the standard Configurator batch launcher restored a visible window. Interrupting a helper that waited for descendants also stopped its newly launched Configurator, so the final launch uses a detached launcher. The saved parameter snapshot remained intact and the device services were unaffected. Tests establish the software behavior; no new stimulation sequence was run for hardware acceptance.

Local evidence, source/distribution backups, failing/passing logs, video frames and the saved Configurator parameters are under `R:\tests\evidence\configurator-tree-render-20260918`. Portable two-file overwrite patch: `R:\builds\patch_configurator-tree-trigger-20260918.zip`.
