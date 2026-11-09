# P300 learning data parameter tuning

Date: 2026-09-25. Offline research only. No device, MATLAB session, service configuration or production model changed.

The user explicitly restricted tuning and testing to learning recordings with leave-one-letter-out cross-validation. No learning-to-play evaluation, play EEG, play predictions or intended play text were used. The separate [Word report](../../../outputs/p300-learn-tuning-20260925/p300-learn-tuning-report.docx) and [XLSX tables](../../../outputs/p300-learn-tuning-20260925/p300-learn-tuning-results.xlsx) retain the results.

## Protocol and scope

The same 623 complete 6×6 letters and 686 complete 3×3 letters from 49 recordings per matrix are used for every main-search configuration. All epochs of one letter are held out; all five cycles of the other eligible letters in the same recording train that fold. Models never pool participants or matrices. Parameter ranking uses equal-weight subject mean final-cycle accuracy, with pooled and earlier-cycle accuracy as tie breakers. These are selected CV maxima, not nested or independently validated estimates.

One fitter is fixed: class-wise centered covariances with n−1 denominators, equal class covariance sum, diagonal ridge proportional to its mean diagonal, and target-minus-non-target mean direction. This matches the current MATLAB centered convention and Mov1. All eight channels remain; no per-epoch baseline or feature standardization is introduced.

The staged search covers lower cutoffs 0.1–2 Hz, upper cutoffs 8–20 Hz, direct Butterworth bandpass prototype orders 2–4 (actual orders 4–8), separate HP orders 1–2 and LP orders 2–4, original-construction FIR lengths 511/1023/2047, epoch starts 0–200 ms, ends 400–1200 ms, ridge fractions 0.0001–0.3, and valid 20/25/50 Hz feature rates. Not every combination is crossed. The preserved stage configuration files are the authoritative tested lists.

Filtering is continuous and causal, from recording start, before epoch extraction. FIR alignment uses its explicit future-sample wait. IIR gets no scalar phase correction. The main search adds the same causal elliptic anti-alias stage: pass edge 0.4 times feature rate, stop edge at Nyquist, 0.1 dB ripple, 60 dB attenuation. Historical references preserve their original stride-only extraction. All selected finalists use 50 Hz features.

There are 936 distinct configurations in 6×6 and 968 in 3×3, 1,247,176 held-out classifier fits and 6,235,880 cumulative decisions. No extra letters were removed to accommodate 1.2-second windows.

## Main findings

- Best 6×6 FIR: 604/623 (96.95%), nominal 0.3–15 Hz, 1023 taps, 0–600 ms, 0.3% ridge. Best IIR: separate HP2/LP4, 0.3–15 Hz, 150–700 ms, 0.1% ridge, 598/623 (95.99%). Direct order-4 bandpass reaches 597/623 with 0.3–18 Hz, 100–700 ms, 0.3% ridge.
- Best 3×3 FIR: 653/686 (95.19%), nominal 0.3–12 Hz, 2047 taps, 100–600 ms, 1% ridge. Best IIR: separate HP2/LP4, 0.3–18 Hz, 100–600 ms, 1% ridge, 649/686 (94.61%). Direct order-8 bandpass reaches 647/686 with 1–10 Hz, 200–600 ms, 0.3% ridge.
- All paired subject bootstrap intervals comparing selected FIR and IIR families include zero. They are exploratory and not corrected for parameter selection. The six-letter 6×6 FIR advantage over separate HP/LP is concentrated in 2025; the other years' net differences cancel. There is no established universal FIR advantage.
- Required post-flash EEG availability is 1.622 versus 0.700 seconds for the selected 6×6 FIR versus IIR, and 2.646 versus 0.600 seconds for 3×3. Filter-only computation is approximately 0.101/0.160 ms per 25-sample block for the two FIRs versus 0.025 ms for IIR. These are local Python microbenchmarks, not a new native SPEED/TCP test.
- Original IIR has mean 14.00% spectral power above 10 Hz before stride-only reduction to 20 Hz, versus 0.30% for original FIR. Adding anti-alias filtering did not consistently improve fixed-setting CV and also changes phase/bandwidth. Aliasing alone does not explain the earlier gap.
- The original FIR designer's nominal low edge is not a Butterworth −3 dB edge. At nominal 0.1–12 Hz, the 2047-tap FIR has approximately −13.9 dB gain at 0.1 Hz. Earlier descriptions of `butter(4,[lo hi])` as an overall fourth-order bandpass were imprecise: it is eighth-order.

## Verification and reproduction

Evidence: [completed run](../../../src/_test-output/p300-learn-tuning-20260925/completed.json), [aggregation verification](../../../src/_test-output/p300-learn-tuning-20260925/aggregation-verification.json), [artifact checks](../../../src/_test-output/p300-learn-tuning-20260925/artifact-verification.json).

All 294 learning raw/event/parameter files match retained hashes. All 26,180 historical Mov1 reference predictions match exactly. Independent direct centered fits verify every one of the 3,927 finalist folds; maximum relative weight error is 9.4e-12. Independent aggregation checks all 93,296 recording/configuration combinations. Seven structural checks include causal anti-alias block continuity, stopband attenuation and refusal to open play labels. A distinct-output worker run verifies output routing. Final closure predictions are unchanged.

Startup sensitivity removes letters whose first flash precedes 30 seconds, then refits LOOCV on the remaining letters with frozen parameters. FIR/separate-IIR results become 557/577 versus 548/577 for 6×6 and 582/618 versus 581/618 for 3×3. This changes both fit and evaluation pools, so it is not a paired improvement estimate.

Runners: [tune_learn.py](../../../tools/reference-generation/p300/tune_learn.py) and [analyze_learn_tuning.py](../../../tools/reference-generation/p300/analyze_learn_tuning.py). Use the portable reference NumPy/SciPy runtime, six workers and single-thread BLAS. Exact stage plans, trial pool, per-recording predictions, final coefficients, filter diagnostics and source hashes remain in the evidence directory. Raw inputs are read-only. Native Word rendered the nine-page report after the packaged LibreOffice renderer reported that LibreOffice was unavailable; page PNGs were inspected. The five-sheet XLSX has 1,904 configuration rows, 14 selected results and 686 subject rows, with cached values reconciled and no formula errors.
