# P300 fullscreen override and 144 Hz timing diagnosis

2026-09-27. [Current P300 contract](../../components/p300.md).

`R:/dist/params/why_not_working_p300.json` and the live service both selected the primary LG 38GN950 (3840×1600, 143.998 Hz), with fullscreen=true, allowPrimaryFullscreen=false and fullscreenOnRun=false. The first legacy override prevented fullscreen despite the checked control. The actual window remained 1100×1000 content. Both legacy fullscreen overrides are now hidden/ignored while remaining loadable. Full screen alone immediately controls the selected monitor on primary and secondary, including while idle. Other Stimulus service behavior is unchanged.

The timing conversion was correct. The file held six-frame flashes and three-frame blank intervals: 41.7/20.8 ms at 144 Hz. Read-only examination of `Anonymous_p300_Pretraining-Typing_training-0002.hdf5` found median software-event flash/gap durations 41.7128/20.7815 ms and onset intervals 62.4824 ms. This was faster than the previous 14/7 session because the standalone frame settings differ from the venue launcher's refresh-scaled settings. Older inspected runs contain timing outliers; the inspection does not attribute those to a particular cause or measure optical onset.

The user explicitly chose to restore 14/7 frames. Both flash limits and both gap limits were updated in the running service and saved troubleshooting file. At the reported 143.998 Hz these are 97.2236 and 48.6118 ms. Other operator settings were preserved; the original JSON is retained in evidence. Screen changes continue preserving frame counts; there is no hidden duration rescaling or change to recorded old data.

Native build passed. All 20 UI/workflow tests passed, including primary/secondary fullscreen geometry, immediate return to a window, hidden obsolete settings, contradictory legacy flags, frame/ms editing and eight recorded synthetic pretraining/typing/cancellation/failure files. The deployed executable hash matches the build. After restoring the user's settings, the native Windows P300 rectangle was verified as exactly [0,0,3840,1600], matching the primary display. Configurator remained on the secondary. P300 was idle; no physical presentation was started. Movicom and Recorder state/settings and every existing raw HDF5 file were unchanged.

Evidence: `R:/src/_test-output/p300-fullscreen-timing-20260927`: original setup, before/after descriptions and window geometry, read-only recording timing measurements, source backups, build, `managed-session/`, and deployment verification.
