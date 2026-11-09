# Movicom and NVX: four-letter pretraining and ОПУС_ПЯТЬ!

2026-09-27. One participant, two separate amplifier sessions. Intended typing text supplied by the operator: `ОПУС_ПЯТЬ!`, ten selections including the original underscore and exclamation cells. Analysis uses each recording's original alphabet. Subsequent changes to the standard matrix do not relabel these recordings.

## Recordings and actual results

All inputs are under `R:/dist/data`, read-only. Movicom uses `Anonymous_p300_Pretraining-Typing_training-0004.hdf5` and `typing-0001.hdf5`; NVX uses `training-0005.hdf5` and `typing-0002.hdf5` with the same prefix. The respective classifiers are beside the training files as `.p300.json`. Every training file contains four complete letters (240 flashes); every typing file contains ten complete selections (600 flashes). Both calibrations used targets З, Х, Ё, Ф with five row/column cycles per letter.

Movicom produced **ГПУС_ПЯТЬ! — 9/10**. The first selection was Г instead of О: correct column, wrong row; intended О ranked fifth after five cycles. NVX produced **ОПУС_ПЯТЫ! — 9/10**. The ninth selection was Ы instead of Ь: correct row, wrong column; intended Ь ranked second.

Cumulative-cycle correct counts, each out of ten:

- Movicom: **4, 7, 8, 7, 9** after cycles 1–5.
- NVX: **4, 8, 9, 9, 9** after cycles 1–5.

NVX reached nine correct by cycle three in this recording. Ten selections do not validate an early-stopping rule or establish an amplifier accuracy ranking.

## Classifier reproduction and calibration usefulness

Native offline replay reproduced all **600 online scores exactly for each amplifier**, all onset sample indices and all ten final decisions. Both saved adapted models were recalculated from their source recordings with identical weights. Independent continuous SciPy filtering, feature averaging and centered ridge covariance calculations also passed numerical parity. No epochs were rejected. Files retain their original hashes.

The four-letter policies differ. Movicom uses 100% personal target contrast and 100% personal covariance; NVX uses 50% personal contrast and 25% personal covariance, with the remainder supplied by the Q group prior. Filter family/passband/window remain the same nominal 0.3–12 Hz causal HP/LP, anti-alias stage, 100–600 ms window, 40 ms means every 20 ms and ridge 0.003; sample rates and synchronization differ.

On the four calibration letters, personal leave-one-whole-letter-out correct counts were **2,3,4,4,4 / 4** for Movicom and **2,4,4,4,4 / 4** for NVX. Adaptation fitted on the other three letters gave **2,2,3,4,4 / 4** and **3,4,4,4,4 / 4**, respectively. These are four held-out letters only, not a robust population accuracy estimate.

Frozen comparisons used only the four pretraining letters for fitting and never tuned on typing. The original group models alone gave **2/10 Movicom** and **4/10 NVX**. A personal-only four-letter classifier gave **9/10 on both**, with the same final errors as the actual online models. Thus personal calibration substantially helped this participant; neither final error is explained by a failed automatic adaptation.

## Timing and signal checks

Across all four files, flash durations centered near 97.3 ms and within-letter onset intervals near 145.9 ms, consistent with 14/7 frames at 144 Hz. No within-letter onset interval exceeded 200 ms. These are recorded software presentation times, not independent optical duration measurements.

Movicom's firmware timeline remained valid in one generation throughout both imported runs. Median clock-fit RMS was 0.505 ms during pretraining and 0.529 ms during typing; these describe clock-fit consistency, not screen-light latency. There were no nonfinite EEG samples or exact ADC full-scale samples in either recording.

NVX found all **240 pretraining and 600 typing photodiode crossings**. Event-to-photo delays had medians **48.0 and 43.8 ms**; typing's full range was 32.4–57.0 ms. This includes display and EEG timestamp behavior. AUX1 had 154/400 nonfinite samples elsewhere, but no required edge was lost or bridged. EEG channels contained no nonfinite samples.

For typing, filtered posterior-channel standard deviations (PO7, PO8, O1, O2) were **17.5–18.6 µV on Movicom** versus **7.6–10.8 µV on NVX**. Cz/Pz/C3/C4 ranges were 10.2–14.0 and 11.8–12.9 µV. Larger ongoing variation is visible in the Movicom posterior channels, with marked O1 target/non-target differences between calibration and typing. These sequential sessions do not isolate electronic noise, electrode/contact changes, physiological variation or timing effects. Signal separation should not be equated with raw amplitude alone.

![Target-minus-other feature means, all eight channels](../../../src/_test-output/p300-opus-editing-20260927/response-comparison.png)

## NVX without the photodiode

Reprocessed the same continuous recordings with **unadjusted message timestamps**, no fixed latency offset. Filter coefficients, feature window, ridge, training targets and four-letter count remained fixed. The actual saved classifier was not replaced.

- **Photodiode for training and typing (actual): 9/10**, ОПУС_ПЯТЫ!; cycle counts 4,8,9,9,9.
- **Message timing for both training and typing, refitted with the same adaptation policy: 9/10**, ОПУС_ПЯТЫ!; cycle counts 5,7,9,9,9.
- **Message timing for both, personal-only four-letter fit: 9/10**, same final text and cycle counts 5,7,9,9,9. This avoids interpreting a change relative to the optical group prior as a pure timing effect.
- **Keep the photodiode-trained adapted classifier, switch only typing to messages: 4/10**, ОХЗС_!?ЖЫ!; cycle counts 4,5,5,4,4.
- The unchanged Q group prior used directly with message timing gave 1/10. Its source corpus was optically aligned; this is explicitly a mismatched-prior comparison, not a newly trained message-timing group model.

Message-timed epochs start **32–56 samples earlier** than the photodiode epochs in this 1000 Hz typing recording (median 43, 95th percentile 53). This changes classifier features, not merely plotted time labels. Relearning both phases accommodates the timing basis well enough to retain 9/10 here. The unchanged photodiode-trained model does not. This one session does not establish equivalent performance across monitors, timing variability or subjects. No offset/filter/window search was performed.

## Reproduction

Evidence: `R:/src/_test-output/p300-opus-editing-20260927/analysis.json`, `message-timing-comparison.json`, per-recording native outputs, feature arrays, source hashes and model reproductions. Scripts: `analyze.py`, `message_timing.py`, `plot.py`. All simulation models stay in evidence, outside the distribution's selectable classifier folders. The accompanying [matrix-editing change](../changes/2026-09-27-p300-text-editing.md) preserves the operator's actual NVX model.
