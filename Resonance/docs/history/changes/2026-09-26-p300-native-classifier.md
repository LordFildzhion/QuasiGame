# Native P300 training and inference — 2026-09-26

The approved integration puts selected centered Fisher training and online application inside the native x64 P300 service. Existing MATLAB models retain their SPEED path. Current settings and model semantics are owned by [P300](../../components/p300.md).

## Implementation

- `classifier.cpp/.hpp`: versioned model, native filter designs, coefficient validation, continuous processing, feature extraction, centered count-pooled ridge fitting, whole-letter and whole-recording validation.
- `recordingimport.cpp/.hpp`: existing Resonance HDF5 reader, named-channel mapping, subject/reference/rate/unit checks, complete-cycle checks, rejection reasons and source provenance. Raw recordings remain read-only.
- `nativecontroller.cpp/.hpp`: separate calculation and inference workers, cancellation, model save/use, frozen-model evaluation, bounded live queues and result timing.
- `ui/Classifier.qml`: calibration selection, presets/custom parameters, progress/cancel, cycle accuracies and target/nontarget feature means. Configurator exposes the idle-only `classifier` action.
- `service.cpp`, `Plan.js`: native feedback routing, explicit cycle and processing-origin metadata, EEG loss refusal, calculated recording tail. Shared recording exposes the successfully closed file for **Use last calibration** and optional calculation after calibration.

No Python runtime is needed for native training or typing. The anti-alias coefficients are embedded in the executable. No research models or test recordings are installed into the operator package. The three selected native processing families are available for both matrix sizes; this does not convert historical MATLAB models into native JSON models.

## Numerical acceptance

Evidence: [native training test bundle](../../../src/_test-output/p300-native-training-20260926/), including its generators, source backup, build logs and [corpus parity summary](../../../src/_test-output/p300-native-training-20260926/corpus-parity/summary.json).

Native fitting was compared with independent SciPy Cholesky fitting on **423 configurations: 141 recordings × three selected pipelines**. Every whole-letter fold was fitted within its own recording. There are 1,734 distinct calibration letters, 5,202 fitted validation folds and **26,010 cycle decisions**. All decisions agree. Maximum relative final-weight discrepancy is **1.03 × 10⁻¹¹**. The native fitter received independently computed reference features for this corpus-wide check; native filtering was checked separately rather than calling this full-corpus raw-stream replay.

| Learning pool | HP/LP default | FIR reference | Direct bandpass |
|---|---:|---:|---:|
| Movicom 6×6, 49 recordings | 606/623 | 612/623 | 604/623 |
| Movicom 3×3, 49 recordings | 655/686 | 657/686 | 654/686 |
| Q 6×6, 43 recordings | 413/425 | 414/425 | 413/425 |

The values reproduce the selected reference pipelines; they are learning-set cross-validation, not new prospective typing results or an independent parameter-selection study.

Native causal filter/features agree with independent NumPy/SciPy oracles in all nine combinations (three families × Movicom 6×6 at 500 Hz / Movicom 3×3 at 500 Hz / Q 6×6 at 1000 Hz), each fed with 1-, 37- and 512-sample blocks. Relative feature tolerance is 10⁻⁸. The FIR uses the original positive-frequency FFT construction expressed as an analytic cosine sum, including Hamming window and mean removal; it is not replaced with `firwin`.

## Integration acceptance

- A retained 2025/sbj09/6×6 recording was represented as Resonance HDF5 with independently prepared events and source channel metadata. Import at 37- and 500-sample block sizes produced **bit-identical weights**. All 11 letter decisions match the reference; relative weight difference from the reference is 4.63 × 10⁻¹⁰.
- The same recording replayed through the asynchronous native worker; all 11 final decisions matched independent full-model predictions.
- The untouched 32-channel `Q:/P300Data/data - raw/sbj_01/Clin_matrix-rec-001.h5` imported and trained successfully with the eight named EEG channels. This check used explicit presentation timestamps; it is not a claim of equivalence to the study's separate optical detector.
- Decision availability tests cover IIR/FIR and 1/37/512-sample blocks. No selection is emitted before the complete final epoch exists. Analogue rising-threshold detection and missing-edge rejection are checked.
- Native model roundtrip and malformed-model refusals, whole-recording validation, wrong subject/reference/channel, duplicate recording, cancellation and retention of the preceding calculation passed.
- P300 UI tests passed offscreen, including background training, refusal to start presentation during calculation, cancellation preserving results, and panel rendering. [Panel](../../../src/_test-output/p300-native-training-20260926/p300-classifier.png), [results](../../../src/_test-output/p300-native-training-20260926/p300-classifier-results.png).
- P300 planning and shared Stimulus presentation regression tests passed. The seven existing MATLAB/SPEED Python classifier tests passed unchanged.
- The actual P300 executable, first staged and then deployed, completed a synthetic-EEG typing trial through TCP and the QML frame/event path: 12 flashes, native decision, then idle, without SPEED. Offscreen smoke checks borrowed the matching SDK offscreen platform plugin because the operator package intentionally ships only the normal Windows platform plugin. No live acquisition service or physical amplifier was used.

The native test target's retained-data routes use `P300_NATIVE_ORACLES=R:/src/_test-output/p300-native-training-20260926`; without that setting, the optional external-oracle/import/replay checks explicitly skip. The stored reference generators use only retained corpus data and existing NumPy/SciPy/HDF5 runtimes. They do not depend on the deleted BPrac directories.

## Scope and follow-up

This is software and recorded-data acceptance. A new human calibration/typing session and physical photodiode threshold acceptance were not performed. Other supported sample rates have embedded filter coefficients but did not receive the 500/1000 Hz corpus campaign. The operator must declare the actual EEG reference and subject when historical files lack that metadata. Native photodiode threshold detection and legacy MATLAB derivative detection remain separately identified. Optional Movicom firmware-echo synchronization remains planned; it is not exposed as an implemented native alignment option.

Package replacement is restricted to `dist/bin/P300.exe`; operator parameters, protocols, montages, calibration files and recordings are preserved. The previous executable is retained with this evidence bundle. Exact source/build/package identities and smoke-check results are stored in the bundle's deployment record.
