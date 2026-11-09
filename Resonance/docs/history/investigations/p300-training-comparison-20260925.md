# 2026-09-25 — MATLAB and Movicom P300 training comparison

Status: source audit and executed numerical comparison. No deployed service, classifier, original MATLAB script or raw recording changed. Current service owner: [P300](../../components/p300.md). Reusable comparison: [offline tools](../../../tools/reference-generation/p300/README.md).

## Sources and branches

The supplied scripts are actually under `W:/MATLAB/resonance_p300`: [p300_pipeline.m](W:/MATLAB/resonance_p300/p300_pipeline.m), [p300_classify.m](W:/MATLAB/resonance_p300/p300_classify.m), [FisherDA_s4.m](W:/MATLAB/resonance_p300/FisherDA_s4.m) and [p300_parseHDF_new.m](W:/MATLAB/resonance_p300/p300_parseHDF_new.m). The main script supports both online-compatible and offline processing:

- `bp_type="IIR"`, `bp_lag0=false`: Butterworth design and continuous causal `sosfilt`. This is the relevant online training branch.
- IIR with `bp_lag0=true`: forward/backward `filtfilt`; an offline branch.
- `bp_type="FIR"`: equiripple coefficients from `get_bandpassFIR`, followed by `filtfilt` regardless of `bp_lag0`. This branch is explicitly marked offline in the script.

The currently selected FIR/zero-phase settings do not define the script's whole capability. Likewise, the active background-image target override is an experiment-specific setting, not a requirement of its classifier. This comparison preserves the Movicom calibration's known target labels.

[P300Service::prepareClassifier](../../../src/P300/service.cpp) loads [p300/python/online_processing.py](../../../src/P300/python/online_processing.py) into SPEED. The deployed and source copies were byte-identical. That is the actual online processing implementation, not the MATLAB script. Movicom's comparison source is the [independently verified extracted classifier](../../../equipment/Movicom/classifier-reference/PIPELINE.md).

## Application: same broad operation, different model contracts

Both filter continuously, extract an event-aligned epoch, keep every Nth sample, calculate a linear score, average flash scores for each candidate cell and choose the largest average. Neither online path trains weights or provides calibrated probabilities. Filter state survives input blocks in both.

| Detail | Current Resonance/SPEED | Movicom reference |
|---|---|---|
| Filter | Model SOS or B/A, causal, zero initial state | 2047-tap FIR, 1–10 Hz; continuous causal computation with 1023-sample group-delay correction in sample labels |
| Availability | Wait for the aligned epoch and preceding flashes | Wait for epoch plus FIR lookahead; approximately 2.046 s extra at 500 Hz |
| Default feature example | MATLAB settings: 0–0.6 s, stride 10; channels/rate configurable | 0–1 s, stride 25 at 500 Hz, eight channels |
| Feature order | Channel-major: all retained times for channel 1, then channel 2 | Time-major: all channels at time 1, then time 2 |
| Epoch score | `x @ W` | `x @ w - bias`, with unit-length weights |
| Event origin | Host event time; bounded optical edge search when configured; one-sample lead | Stored/firmware-mapped event sample, rounded; compensated FIR labels |

Feature order is a reversible permutation, not a different learning principle. A fixed bias and positive weight normalization do not change the winning cell under exposure-normalized averaging: every cell's mean receives the same affine transformation. They do matter for score signs, thresholds and interpretation. MATLAB's scalar conversion from volts to microvolts similarly changes score scale if training and application units differ; it does not by itself change the winner under the current linear ranking rule.

The models are therefore not directly interchangeable. Filter definition/state, delay treatment, feature order, channels, sampling rate, units and epoch origin must match before comparing coefficients or scores.

## Fitting: a substantive difference

Let T and N be epoch-by-feature matrices and mT, mN their means. Both methods give the two classes equal aggregate weight, despite unequal class counts.

**MATLAB `FisherDA_s4`:** `M = T'T/nT + N'N/nN`; `lambda = alpha * mean(abs(diag(M)))`; `W = inverse(M + lambda*I) * (mT-mN)`. Default alpha is 0.01. These are **uncentered second moments**, not centered covariance matrices. There is no intercept or weight normalization. Equivalently, this solves class-balanced ridge least squares with target values +1 and −1 and no intercept. The Python port uses a linear solve instead of explicitly forming an inverse.

**Movicom:** form each class's centered covariance with divisor n−1; solve `(ST+SN)w = mT-mN`; normalize w; use the midpoint of the two projected means as bias. The historical implementation has the opposite initial sign and then orients target scores positive, producing this same direction. There is no ridge/shrinkage in the supplied trainer.

Changing window, channels, cutoffs or decimation is a parameter change. Centered covariance versus uncentered second moments changes the objective; enabling regularization also changes the fitted solution. Setting MATLAB alpha to zero does not reproduce Movicom. A common configurable implementation can express both, but they are not already the same formula with different settings.

## Validation is also different

The optional [FischerDA_movicom.m](W:/MATLAB/resonance_p300/FischerDA_movicom.m) now provides the same two-/three-input, single-column-output call shape as `FisherDA_s4`. Inputs remain features-by-epochs; feature order is preserved. It reproduces Movicom's centered, unregularized, unit-norm weights. `alpha` is accepted but ignored. Bias is omitted to preserve the single-output interface; it cancels in the existing mean-per-cell ranking, but would be required to reproduce Movicom's score-sign decisions. The original fitter and pipeline call sites were not changed. Native MATLAB verification passed against all 11 archived models (7,783 epochs; maximum weight error 7.65e-12), plus eight structural checks. [Results](../../../src/_test-output/movicom-matlab-20260925/verified/results.json).

MATLAB `p300_classify` supports resubstitution (`none`), held-out letter attempts (`letters`), progressively more cycles in both train/test (`cycles`), and full training cycles with progressively more held-out test cycles (`letter_cycle`). It scores **selected letters**. Here “letter” means one complete attempt identified by `seq`, not all attempts at a particular alphabet character. `p300_classifyCV` adds other split strategies but is not called by the named main script.

Movicom's historical check repeatedly holds out 5% of each class's **epochs** and reports score-sign accuracy. It is neither n-fold CV nor held-out letter accuracy. Its percentage cannot be compared directly with the MATLAB percentage. Neither supplied main path automatically searches epoch boundaries with nested validation.

## Executed tests

Native MATLAB R2023b ran the original fitter and CV functions after `W:/MATLAB/startup.m`. Python reproduced weights, scores, channel-major feature extraction, causal IIR and offline FIR output. The FIR designer remained MATLAB; a separate SciPy Butterworth design also matched the causal output. This verifies the relevant numerical core, not a complete port of the original HDF/event parser or UI.

All 11 available 6×6 calibration datasets were used. Each contributes the same first 11 complete letter attempts: **7,260 epochs and 121 letters**. The final attempt per recording was excluded from every variant because Movicom's delayed FIR lacks enough tail data for all its epochs. For each held-out letter, fit on the other ten; accumulate 1–5 cycles of its held-out flashes. Settings below were fixed before observing results. No parameter search was performed.

- **125 parity checks passed.** Maximum relative L2 error in MATLAB weights: 2.37×10⁻¹⁴; in extracted causal/offline features: 7.97×10⁻¹⁰. MATLAB and Python CV accuracy matched for all three held-out modes on all subjects. Filtering tolerance is sub-count (0.001 in the archive's stored ADC units), not 0.001 volts.
- **Current SPEED-engine replay:** 660 real-data epochs and 11 selections in 73-sample blocks; maximum score discrepancy 4.45×10⁻¹⁵ against the offline causal calculation. The harness explicitly moves the event anchor by one sample to cancel SPEED's one-sample lead. This establishes equal-epoch arithmetic, not equivalence of the legacy photodiode and host-time parsers.
- **Six structural tests passed:** independent least-squares formulation, translation sensitivity, channel permutation/unit scaling, bias cancellation, epoch boundaries/layout, and regularized collinearity handling.

Five-cycle held-out letter accuracy, on the same 121 attempts:

| Preprocessing | Movicom centered, no ridge | Centered, 1% ridge | MATLAB second moments, 1% ridge | Second moments, no ridge |
|---|---:|---:|---:|---:|
| Movicom FIR 1–10 Hz; 1 s; 20 feature samples/s | 110/121 (90.9%) | 111/121 (91.7%) | 113/121 (93.4%) | 108/121 (89.3%) |
| Causal IIR 1.5–10 Hz; 0.6 s; 50 feature samples/s | 103/121 (85.1%) | 110/121 (90.9%) | 113/121 (93.4%) | 94/121 (77.7%) |
| Offline FIR 1.5–10 Hz, forward/backward; 0.6 s; 50 feature samples/s | 103/121 (85.1%) | 112/121 (92.6%) | 112/121 (92.6%) | 102/121 (84.3%) |

The causal/offline settings use all eight available channels at 500 Hz, not the main script's selected 30-channel recording. All variants use the same archived event indices. Within a row, only the fitting rule changes. Between rows, filtering, window and feature density change together; the table does not isolate each of those effects.

The strongest conclusion is that regularization and preprocessing consistency deserve retention. The 113 versus 110 result is only three letters: on identical Movicom features, MATLAB alone gets eight right and Movicom alone gets five right. This does not establish a universal winner. These are within-recording held-out attempts, not a new-session or online spelling test. Continuous filtering also spans trial boundaries; future deployment estimates should use separate sessions/recordings or guarded temporal splits, especially for noncausal filtering. The play recordings were not assigned guessed intended targets.

## Model contract before production training

The online IIR branch is usable as a reference, but the current MATLAB exporter does not describe every preprocessing option that the research script can select. In particular, it omits sampling rate, arbitrary epoch start/offset, baseline and optional notch/zero-phase settings; `eeg_chans_inds=ch_clf` assumes `ch_eeg` is an identity selection. The offline FIR branch writes `sos=1`, which the current loader correctly rejects. This does not make the causal IIR branch incompatible.

The MATLAB parser detects/labels photodiode transitions globally and locates nearest events with ramp compensation; SPEED finds a configured rising/falling derivative or rising digital edge in a bounded window, then starts one sample earlier. These paths need an explicit shared onset convention. Rate defaults and the no-diode 60 Hz fallback also need explicit metadata rather than inference from a file's age. Preserve these as compatibility choices, not undocumented changes while fitting models.

A suitable common trainer should share alignment, channel/unit handling, continuous filtering, epoching, decimation, scoring and letter aggregation with online inference. Keep the two historical fitting rules selectable for regression, plus centered regularization for evaluation. Store the full processing contract in a versioned model. Choose filter/window/channel/regularization settings inside grouped inner validation and assess them on untouched outer trials or sessions; measure letter accuracy versus repetitions and processing latency. Retain the causal IIR configuration as the initial low-latency baseline and the delay-compensated Movicom FIR as a reference candidate. The offline zero-phase branch remains available for research, with its status explicit.

Evidence: [verified parity and decisions](../../../src/_test-output/p300-training-comparison-20260925/verified), [MATLAB outputs](../../../src/_test-output/p300-training-comparison-20260925/matlab-final), [input manifest](../../../src/_test-output/p300-training-comparison-20260925/inputs/inputs.json). Early harness attempts exposed MATLAB cell orientation/integer conversion and Windows NumPy integer-width issues; those failed attempts are retained separately and are not accepted results. The final oracle/comparison passed; no expected numerical values were replaced to force agreement.
