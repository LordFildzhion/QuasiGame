# P300 group inference and short supervised adaptation

2026-09-27. Implements the approved zero-calibration and short-calibration options for the upcoming P300TEST cap session. [Contract](../../components/p300.md#group-typing-and-short-calibration), [venue](../../how-to/p300test.md), [separate-play study](../investigations/p300-group-transfer-20260927.md).

## Change

Native version 2 group models contain normalized class-mean difference, centered count-pooled covariance, fixed processing/synchronization and source-selected adaptation policy. Group typing allows an explicitly named new participant; ordinary version 1 models still enforce their own subject. One/two-letter adaptation, with optional 3/4/6 lengths, uses only labelled complete calibration letters and produces a subject-scoped version 1 model. The panel freezes group processing settings, distinguishes fitting from validation, and retains explicit Save/Use. Automatic post-calibration calculation uses the same importer and worker. Missing/invalid labels, wrong units/rate/reference/matrix/timing, malformed priors, insufficient letters and cancellation do not silently replace the active model. Group fingerprints/provenance are saved in adapted models; native typing run events retain model identity.

P300TEST adds four launchers: 09 NVX group typing, 10 NVX short calibration, 11 Movicom group typing, 12 Movicom short calibration. Short calibration defaults to two letters and five cycles per letter; the panel also sets presentation length when selecting 1/3/4/6. Ordinary full-calibration presets explicitly reset calculation mode to subject. Ordinary typing preserves the saved/selected model. Q 6×6 1000 Hz, Movicom 6×6 500 Hz and Movicom 3×3 500 Hz priors are shipped under `classifier/`; the venue uses 6×6. Source cohorts and reference/timing limits are embedded and documented.

Affected native source: `P300/classifier.*`, `recordingimport.cpp`, `nativecontroller.*`, `service.cpp`, `ui/Classifier.qml`, tests. No amplifier or shared transport implementation changed. Research scripts stay under `tools/reference-generation/p300`; corpus data, test models and fixtures are not deployed.

## Software evidence

Evidence root: `R:/src/_test-output/p300-group-native-20260927`.

- Build: Qt 6.11.2 / MSVC 14.44 x64, targets P300, test_P300Classifier, test_P300Ui.
- Native classifier suite: **11 passed, none skipped**. All **705 adaptation fits over 141 subject fixtures** agree with Python within maximum relative weight error **2.5861963214637903e−12**, with identical cycle decisions. Includes malformed prior/scope/weights/policy refusal, old version-1 loading, missing identity/label/reference checks, cancellation and poisoned-future-letter invariance. Existing causal feature, variable-block, photo, availability and asynchronous recording replay checks pass.
- UI suite: **13 passed, none skipped**, using offscreen software rendering. Group option persistence, one/two-letter calculation, failed/cancelled replacement retaining the result, insufficient-calibration preflight and group identity/reference refusal pass. Existing full-calibration, screen, matrix and optical-patch checks remain passing. PNG captures were reviewed. The first QA launch lacked the offscreen plugin path; the corrected runtime was used. An initial new screenshot check lacked its output directory; the harness was repaired, then all tests rerun.
- Plan suite: **7 passed, none skipped**.
- Four deployed task presets applied and read back successfully. The standard NVX short-calibration preset was restored with blank subject and the shipped Q group model; both amplifiers were stopped. Synthetic stream addresses and QA model selections were removed from the live task.
- Separate-play numerical verification: **202,230 cycle decisions**, fixed model hashes unchanged. Workbook formulas/cached values checked after reopening, all three sheets rendered/reviewed. [Research evidence](../investigations/p300-group-transfer-20260927.md).

## Connected-device acceptance

Both paths ran zero-calibration, one-letter-adapted and two-letter-adapted native typing. Each run had one letter and two cycles, intentionally a short software/timing smoke test. Adapted QA models came from retained labelled recordings through the strict native importer; their noise/synthetic inputs do not establish physiological accuracy. Each path produced **72 flash scores and three decisions**. Offline replay of each newly saved recording reproduced exact onset sample indices, scores (maximum difference 0) and final choices.

**Movicom:** physical eight-channel device and firmware clock. First attempt stopped before presentation with `Missing samples`; diagnostics reported two CRC errors and at least eleven missing samples. Evidence retained in `movicom-first-attempt.json`. A fresh acquisition then passed all three modes. No missing-data or clock check was bypassed. This transient does not establish fault-free long-term acquisition; stop/restart is required after an invalid-clock refusal. Results: `movicom-live-results.json`, per-run manifests/HDF5/parity JSON.

**NVX:** physical connected NVX AUX1 and top-right 60×60 patch on the primary 144 Hz display. All **72 optical edges** were found. The eight EEG channels were explicitly replaced by synthetic signals through a test-only bridge, retaining actual AUX1, metadata and timing, as in the earlier disconnected-cap acceptance. Native group/adapted live/recorded parity passed. Results: `nvx-live-results.json`, per-run `SYNTHETIC_EEG` HDF5/manifests. The synthetic bridge is not distributed.

Human cap accuracy, physiological Q→NVX transfer and the new participant's benefit from adaptation remain prospective checks. Configurator remained on the secondary display. Current deployment is suitable for that experiment; the software results are not a guarantee of individual performance.

## Deployment

Targeted copy: staged `P300.exe` to `R:/dist/bin/P300.exe`, source P300TEST priors, four new presets/launchers, launcher helpers, launchbar and concise README. Existing affected files were backed up under the evidence root's `before` folder. Other binaries, MPRAC and general operator parameter files were not redeployed. Built/deployed P300 SHA-256 both: `174852044d11642e2ca212a0b6e4329763235a495c9e4a1b8f181f99143de72c`.
