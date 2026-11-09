# Movicom short calibration: newest cap recordings

2026-09-27. Read-only analysis of `R:/dist/data/P300TEST`; no model tuning or replacement.

## Recorded sessions and confirmed targets

- `Anonymous_movicom-adapt_Pretraining-Typing_training-0005.hdf5`: **3** labelled letters, ЗХЁ. Its saved adapted model was used by `...typing-0001.hdf5` (15:48), output **МА**. The user does not remember the first target and thinks А was correct; no accuracy assigned.
- `...training-0006.hdf5`: **2** labelled letters, ЗХ. Its saved adapted model was used by `...typing-0002.hdf5` (15:49). Confirmed targets **ИИ**, output **ОЗ**, **0/2**. The most recent run did not contain three calibration letters.
- All these letters used five cycles, 60 row/column flashes. The recorded alphabet maps outputs correctly. Neither recent sequence contains an immediately repeated identical group. The new spacing option therefore does not explain or repair these particular failures.

## Processing checks

Both adapted models reproduce exactly from their own calibration recordings. Independent SciPy continuous filtering/feature extraction agrees with native features to less than 1.4e-16 relative error. Both typing recordings reproduce all 240 online epoch scores exactly, with identical sample indices and four final decisions. Subject, channels, REF label, model provenance and calibration counts match.

All EEG blocks after each processing origin have valid monotonic firmware-clock mappings, no missing sample ordinals and no clock-generation changes. Median fit RMS is 0.51–0.53 ms, maximum below 0.64 ms; measured rate about 500.5 Hz. No nonfinite or clipped EEG samples and no rejected letters. Within-letter onset intervals are about 145.9 ms. This verifies the host/sample mapping; firmware echo does not measure optical display latency. No evidence here identifies a synchronization implementation fault.

## Classification evidence

At five cycles, whole-letter cross-validation gives:

| Calibration recording | Frozen group | Personal LOLO | Adapted LOLO |
|---|---:|---:|---:|
| Earlier successful 3-letter AVtest2 calibration | 1/3 | 3/3 | 3/3 |
| New 3-letter calibration | 0/3 | 2/3 | 2/3 |
| Latest 2-letter calibration | 0/2 | 1/2 | 1/2 |

Each LOLO fold fits only the other letters (two or one in the new recordings), with the corresponding frozen adaptation policy. These are very small diagnostics, not stable accuracy estimates. The group result indicates poor transfer even though target-related responses remain visible.

Counterfactual fixed-model replay of the latest confirmed ИИ test: group alone predicts РС (0/2); the deployed two-letter adaptation predicts ОЗ (0/2); a personal classifier fitted only to its preceding two-letter calibration predicts ОИ (1/2). A personal model from the preceding three-letter calibration also predicts ОИ. The prior worsens the second selection, but removing it does not recover the first. No test labels were used for fitting or parameter selection. Other counterfactuals in numerical evidence that apply the later calibration to the earlier test are retrospective diagnostics only.

Posterior filtered standard deviation in the new three-letter calibration is 21.3–22.3 µV versus 13.2–13.7 µV in the earlier successful calibration. O1 median raw offset changed from about −14 to −91 mV, without clipping. These observations justify checking electrode/reference contact and session stability, but do not establish a hardware cause or identify a particular artifact. [Target/other feature curves](../../../src/_test-output/p300-spacing-units-session-20260927/calibration-responses.png) use identical continuous causal processing; the time coordinate is the center of each feature average.

## Meaning of the corpus result and next session

The [frozen separate-play study](p300-group-transfer-20260927.md) gave Movicom +2 letters **575/701 (82.0%)** and +3 **592/701 (84.5%)** across held-out groups. Four groups still scored below 50% after two calibration letters. Those pooled averages did not establish reliability for this cap session. The original study also explicitly left physical reference equivalence and legacy-event-to-firmware physiological transfer unverified.

For this participant/setup, use a longer personal calibration, e.g. 6–10 labelled letters, inspect held-out separation, then a new predefined typing word. The existing Movicom 6×6 policy uses the subject-only limit at 4 and 6 letters (mean/covariance weights 1/1), so six-letter Pretraining + Typing is already an automatic option. Do not change the population policy based on this two-letter test.

Evidence: `R:/src/_test-output/p300-spacing-units-session-20260927`: `analyze.py`, `analysis.json`, independently reproduced models/features, exact live parity, `confirmed-targets.json`, and PNG. Raw files remain untouched.
