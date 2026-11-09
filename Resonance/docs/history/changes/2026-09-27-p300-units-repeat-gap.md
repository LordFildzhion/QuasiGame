# P300 units, repeated-group spacing and recording filename

2026-09-27. Built and deployed to `R:/dist`; [current contract](../../components/p300.md).

- Numeric units moved from P300 setting labels into fixed grey left-anchored field labels; count becomes cycles. Frame/ms conversions and numeric editing remain intact. Shared Integer/Double decoration is opt-in metadata, so other services retain their existing labels and alignment.
- Timings gains Same-element gap, default 1. It prevents identical row/column flashes with fewer than N intervening flashes, including cycle boundaries within one letter. Target gap remains separate. Every group appears once per cycle. Infeasible repeated-cycle gaps fail with a clear message; bounded candidate attempts can reuse the preceding valid cycle. The restrictive limit necessarily repeats the same permutation. Seed and gap are recorded; randomness is reproducible, not guaranteed uniform.
- One editable Recording / Filename template replaces the two visible aliases. Legacy presets still load. P300 configures Recorder at Start with the composed subject/mode/phase template; recording status retains the actual resolved path after saving. Recorder's idle filename may still describe the preceding run.

## Verification

Native build passed. Planner: 9 tests, including 3,060 seeded spacing/matrix/target configurations of 20 cycles each, cycle balance, target spacing, determinism, defaults and impossible gaps. P300 UI/recording: 20 tests, no failures or skips. Real key input verifies Integer/Double edits, decimal input, remote updates during editing, clipboard exclusion, left unit placement and both frame/ms directions. Filename alias compatibility, one visible editor and actual saved-path existence are checked. Recorded synthetic integration verifies three-, one- and five-letter automatic adaptation, typing, cancellation and failure: eight HDF5 files and three models. Shared parameter/tab regressions: 2 tests passed. Narrow 330 px Main/Recording/Visual/Timings PNGs were visually inspected.

P300 and three QML files deployed with matching source/runtime hashes. Configurator reopened on the secondary display. Current operator values, Movicom state/settings, all existing P300TEST raw recordings and saved models were preserved. No acquisition or participant session was started for these UI changes.

Evidence: `R:/src/_test-output/p300-spacing-units-session-20260927`: build logs, `plan-tests.txt`, `parameters.log`, `managed-session-final/`, `deployment.json`, before/after descriptions. [Recording investigation](../investigations/p300-short-calibration-20260927.md).

## Follow-up: unit alignment correction

The user corrected the requested unit position to the **right**. Integer/Double and frame/ms decorations now anchor at the right, with values on the left and reserved padding preventing overlap. Three QML files were staged/deployed and Configurator reloaded on the secondary monitor, preserving its settings; P300 was not restarted or changed. Nineteen UI tests and two shared-panel tests passed, including input, remote-update, clipboard, conversion and right-edge placement assertions. The recorded-session test was intentionally omitted for this presentation-only correction. Narrow-panel PNGs were inspected. Current pretraining documentation now states the exact 2/3/4/6-letter policy from the deployed group files.

Evidence: `R:/src/_test-output/p300-right-units-20260927` (build, UI reports, PNGs, deployment and preserved settings).
