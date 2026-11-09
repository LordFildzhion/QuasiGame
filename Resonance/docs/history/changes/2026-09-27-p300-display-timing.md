# P300 monitor selection, indicator position and timing conversions

2026-09-27. Built and deployed to `R:/dist/bin/P300.exe`; current contract in [P300](../../components/p300.md). Evidence and source backup: `R:/src/_test-output/p300-display-timing-20260927`.

- Moved `screen` from Session to the top of Visual, labelled **Subject monitor**. Automatic selection still uses the same shared right/left/secondary/primary logic as Stimulus. Named options now show physical resolution, reported refresh rate and scaling. Old saved names/labels without Hz remain accepted. Display geometry, scaling, refresh-rate and primary-monitor changes refresh the description and placement.
- Removed the one-parameter Scene group. **Indicator position** is now immediately after **Show trigger indicator**, followed by width and height. Existing serialized names and values remain compatible.
- Added read-only **Timing basis** (Hz and ms/frame) and live approximate millisecond equivalents directly below all eight frame-duration labels. Conversions update when duration or subject monitor changes. Repeat counts, cycle counts and stimulus-distance counts retain their own units. Scheduling remains in frames; no optical-latency measurement is implied.
- Renamed the checkbox to **Training: Movicom sync** and clarified its tooltip: training/pretraining aligns events with the amplifier's firmware-echo clock, requiring acquisition-side synchronization first. Typing takes its timing method from the loaded classifier and does not use this checkbox. Firmware synchronization is not screen-light detection.

## Verification and deployment

Native/offscreen UI suite: **16 passed, 0 failed**, with **one optional recorded-session test skipped** (no session workflow or classifier mathematics changed here). Added checks cover parameter grouping/order, old monitor-label compatibility, automatic placement, Hz reporting and frame-value conversion updates. Existing classifier, clipboard, error-banner and display-placement checks passed. Actual standard ParametersView captures at 330 px width were inspected:

![Timings](../../../src/_test-output/p300-display-timing-20260927/final-ui/p300-timings-parameters.png)

![Visual](../../../src/_test-output/p300-display-timing-20260927/final-ui/p300-visual-parameters.png)

Deployment waited for idle P300/Recorder, replaced only P300.exe and restored all operator parameters. The active selection remained **Primary (explicit)**; deployed readback reported **144.00 Hz / 6.945 ms per frame**, with the operator's 14-frame flash showing approximately **97.2 ms**. The original NVX adaptation preset command was retained. Raw recordings and saved personal classifiers were unchanged. `deployment.json` records binary identity and preservation checks. No amplifier acquisition or physical timing test was performed.
