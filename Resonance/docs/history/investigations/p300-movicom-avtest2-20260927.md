# Movicom AVtest2 and NVX AVtest comparison

2026-09-27. Read-only analysis of the four `AVtest2_movicom-adapt-0001` through `0004.hdf5` recordings and the earlier NVX AVtest calibration/test in `R:/dist/data/P300TEST`. Eight channels in the same order: Cz, Pz, C3, C4, PO7, PO8, O1, O2; declared REF. [Numerical evidence](../../../src/_test-output/p300-movicom-review-20260927/analysis.json), [reproduction](../../../src/_test-output/p300-movicom-review-20260927/analyze.py), [earlier NVX check](p300-nvx-avtest-20260927.md). No raw file or deployed classifier was changed.

## Actual recording results

- Movicom `0001`: two complete training letters, used for group adaptation. The saved adapted classifier is reproduced exactly.
- Movicom `0002`: two complete typing selections, **МР**. The user reported no particular intended text; these remain unscored.
- Movicom `0003`: three complete training letters. The saved personal classifier is reproduced exactly. Whole-letter leave-one-out accuracy by cumulative cycle is **0/3, 3/3, 3/3, 3/3, 3/3**.
- Movicom `0004`: six complete typing selections. User-confirmed target **ПРИВЕТ**, online output **ПРИВЕТ**. Frozen-model accuracy by cycle is **4/6, 5/6, 6/6, 6/6, 6/6**; intermediate outputs ПРИВДШ, ПРИВЕШ, then ПРИВЕТ.

All **480** live Movicom flash scores and their epoch sample indices reproduce exactly offline: 120 in the two-letter test and 360 in the six-letter test. All eight final decisions match. Independent SciPy continuous filtering and feature extraction also agree with the native implementation to numerical precision. No test labels were used for fitting or choosing settings.

## Is synchronization responsible for weaker separation?

There is **no observed clock failure** in these recordings. Every EEG block after each processing origin has a valid matching firmware-clock record; sample ordinals are continuous, clock generation remains zero, and mapped timestamps increase. Median clock-fit RMS residual is **0.50–0.53 ms** across the four runs; the highest observed RMS is **0.65 ms**. Invalid records are confined to the expected pre-origin warmup. Effective rate is around **500.45 Hz**. These are clock-fit consistency measures, not optical onset accuracy.

NVX epochs use a measured photodiode crossing. Movicom epochs use the presentation timestamp mapped into the amplifier clock. Movicom firmware echo does **not** detect when the screen becomes bright; absolute display/command/analogue-path delay can therefore differ. A constant delay mainly translates a waveform; variable delay can blur an average. These recordings cannot separately identify those delays, and a fixed offset should not be inferred from a P300 peak.

The original plots compare **11 NVX training letters with only 2 or 3 Movicom letters**. To check that confound, the same fixed HP/LP recipe was fitted within each subject using only the first three NVX letters and the three-letter Movicom calibration. Their target order is identical. Five-cycle leave-one-letter-out accuracy is **2/3 NVX versus 3/3 Movicom**. With all 11 NVX letters it is 11/11. Combining the two Movicom calibrations gives five complete letters and **1/5, 3/5, 5/5, 5/5, 5/5**. These tiny samples do not rank amplifier performance; pooled Movicom results are retrospective diagnostics.

![Matched feature means](../../../src/_test-output/p300-movicom-review-20260927/matched-feature-means.png)

With equal three-letter averaging, central-channel target/nontarget differences are visibly larger for NVX; posterior differences are not uniformly smaller for Movicom. RMS target-minus-nontarget feature differences at Cz/Pz are **2.58/2.78 µV NVX versus 1.37/1.74 µV Movicom**. At O1/O2 they are **1.82/2.01 versus 2.57/3.05 µV**. These are descriptive feature averages, not independent-trial significance tests. Both recordings use the same causal 0.3–12 Hz HP/LP filter, anti-alias stage, 100–600 ms window, 40 ms means every 20 ms and ridge 0.003; native sample rates are 1000/500 Hz.

Signal variability also differs. After omitting the first ten seconds, continuously filtered posterior-channel SD is approximately **5.36–6.37 µV for NVX calibration versus 13.23–13.73 µV for the three-letter Movicom calibration**. This includes EEG activity, artifacts and electrode/reference effects; it is not an amplifier-noise measurement. All EEG values are finite, and no Movicom sample reaches either ADC rail. Raw 49–51 Hz RMS is substantial in both recordings and is actually larger in NVX (roughly 807–829 µV versus 436–458 µV); a blanket claim that Movicom is noisier is unsupported. The classifier's low-pass/anti-alias stages remove this out-of-band interference.

![Validation and signal variability](../../../src/_test-output/p300-movicom-review-20260927/comparison.png)

A diagnostic constant-offset sweep of +0/25/50/75/100 ms on the matched three-letter sets left final accuracy at 2/3 NVX and 3/3 Movicom for every offset. Some first-cycle outcomes changed. This does not identify a correct delay, and no deployed timing or model was altered.

**Conclusion:** Movicom delivered correct six-letter typing with intact synchronization. The data support differences in training amount, waveform shape and in-band variability; they do not support attributing the entire visual separation difference to synchronization. A useful next comparison would use equal 11–12-letter calibrations, comparable cap/reference/contact conditions and the same typing targets. Establishing absolute timing or amplifier gain/filter differences requires an independent known input or optical timing measurement, not this small classifier comparison alone.
