# P300 factorial comparison

Date: 2026-09-25. Offline recorded-data study following the [native MATLAB and SPEED parity investigation](p300-training-comparison-20260925.md). No production or raw-data changes.

[Illustrated report](../../../outputs/p300-large-comparison-20260925/p300-simulation-report.docx) · [Full XLSX results](../../../outputs/p300-large-comparison-20260925/p300-algorithm-comparison.xlsx) · [Executed evidence](../../../src/_test-output/p300-large-comparison-20260925) · [Runners](../../../tools/reference-generation/p300/README.md)

## Design and definitions

Within-subject models only, separately for 6×6 and 3×3. BPrack2025 has recordings for sbj01 and sbj03–sbj12; sbj02 has presentation assets only. Cross-validation holds out a whole letter attempt and trains on all five cycles of that subject's other retained letters. Test scores accumulate one through five cycles. The common pools contain **121 letters for 6×6** and **154 for 3×3**, with 11 and 14 letters per subject respectively.

The full factorial crosses two filters, five fitters and two fixed feature layouts. Both filters receive both layouts: 1 second / 20 Hz (160 channel-major features) and 0.6 seconds / 50 Hz (240 features), from eight channels at 500 Hz. No window tuning or baseline subtraction.

FIR uses the original FFT-derived Movicom 2047-tap 1–10 Hz filter, causal computation and 1023-sample timing compensation, requiring 2.046 seconds of lookahead relative to compensated timestamps. IIR uses the earlier MATLAB-verified order-4 Butterworth 1.5–10 Hz SOS with zero initial state. These are existing configurations, not identical passbands. Neither branch uses filtfilt. Continuous filtering precedes epoching, with complete FIR context on both sides; retained CV letters have nonoverlapping FIR support. IIR retains continuous history. The final calibration letter is excluded from CV in every recording because complete FIR context is unavailable.

Class matrices contribute separately to their sum M; all solve `(M + lambda I) w = mean(target) - mean(other)`, where `lambda = alpha * mean(abs(diag(M)))`:

- **Mov0:** centered covariance, n−1 divisor, alpha 0, unit normalization and midpoint bias.
- **Mov1:** Mov0 with alpha 0.01.
- **Mat0:** uncentered second moments, n divisor, alpha 0.01, no bias or normalization.
- **Mat1:** Mat0 with alpha 0.
- **Mat2:** centering added to Mat0, retaining n divisor and alpha 0.01. This interpretation was stated before execution.

Mat2 and Mov1 are not exactly equivalent for unequal class sizes. All 5,500 matched CV predictions nevertheless agree. In the scored independent test, only one first-cycle prediction differs, and both answers are wrong; all final predictions agree.

## Results

At five cycles, the highest observed CV results are **115/121 (95.0%)** in 6×6 with FIR / 0.6 seconds / 50 Hz / Mat0, and **138/154 (89.6%)** in 3×3 with IIR / 1 second / 20 Hz, shared by Mov1, Mat0 and Mat2. Regularization improves final pooled accuracy in every matched comparison against its unregularized counterpart. Gains are largest in several 240-feature configurations. These are observed maxima, not nested selection or a universal winner.

The separate learning-to-play test trains once on each full valid learning pool, including usable epochs from the final partial-context letter. Weights freeze before play EEG is read, and filter state resets between recordings. Predictions cover all 182 complete 6×6 selections and 178 complete 3×3 selections. One unfinished 3×3 selection for sbj11 is omitted.

The user supplied intended **6×6** text. Subject 08 is excluded from independent-test scoring only. Subject 06 attempts 8 and 9 both target a space, explicitly confirmed as a retry. The final duplicate subject 11 was interpreted as subject 12; Latin E in subject 11 was normalized to Cyrillic Е. These mappings are explicit in `test-targets.json`; the scorer refuses length mismatches or targets outside the alphabet. No automatic spelling correction or edit-distance alignment.

The final independent test has **165 letters from 10 subjects**. FIR / 1 second / 20 Hz reaches **161/165 (97.6%)** with Mov1 or Mat2 versus **155/165 (93.9%)** with Mov0. Mov1 corrects six extra letters without losing any Mov0-correct letter in this configuration. Five subjects improve and five are unchanged. Original online settings, IIR / 0.6 seconds / 50 Hz / Mat0, score **152/165 (92.1%)**. The full matrices, repetitions and individual predictions are in the workbook.

Participant-mean improvement of Mov1 over Mov0 for FIR / 1 second is 3.64 percentage points, with exploratory 95% bootstrap interval +1.21 to +6.21 points. Intervals use 20,000 paired participant resamples, seed 93025, without multiplicity adjustment. Pooled letter accuracy and participant-mean accuracy are separately labeled because test letter counts vary. Alternative live feedback could alter later free-typing intentions: this scores recorded trajectories. Independent 3×3 accuracy remains unavailable because intended labels are unknown.

## Exceptions and verification

- **sbj05 3×3 learning:** backward sample-counter jump at raw index 91323 after the final flash. Only the contiguous prefix is used. CV retains 14 full letters; transfer uses 438 valid epochs and its stock refit differs from the archive. This is flagged, not forced to match.
- **sbj04 3×3 play:** missing `play.params`; contract corroborated by learning parameters, saved model, continuous counters and independent score reproduction.
- **Execution:** 5,500 CV fits and 440 transfer fits; 63,500 predictions across repetition levels before label exclusions; zero numerical warnings. All 4,840 prior individual predictions reproduced. Twenty-one of 22 full-training stock fits match archives, with the sbj05 exception above. Every archived play model reproduces its saved scores; maximum absolute error 2.91e−8 in stored score units.
- **Text:** all 360 complete selections reconstructed; all 339 available next-screen transitions match. Final selections rely on saved scores. Full key sequences preserve the `@` clear action independently of final displayed text.
- **Ten structural tests pass:** independent fitter definitions, centering and covariance divisor distinction, feature permutation, whole-letter exclusion, continuous filter history and epoch-boundary effects, cell averaging, text reconstruction, and refusal to auto-align test targets.

Evidence retains definitions recorded before CV, source hashes, audits, fitted weights, every prediction, labels and test results. `scored-transfer-initial` is an interim nine-subject result before the space retry was confirmed; **`scored-transfer` is authoritative**. This factorial study consumes the preceding native MATLAB oracle; it does not claim a new MATLAB execution for every fit. Report figures are Python-generated PNGs, with all six DOCX pages rendered and reviewed.
