# P300 with zero, one or two calibration letters

Date: 2026-09-27. Status: completed retrospective feasibility study. Research models only; the native service still uses its existing subject-specific model contract.

**Both approaches work in principle and transfer is measurable in our corpus. Two labelled letters are a much stronger starting point than a frozen group model. Q approaches full-calibration accuracy; Movicom still needs a fallback to longer calibration.**

[Results workbook](../../../outputs/p300-cross-subject-20260927/p300-cross-subject.xlsx) · [Frozen protocol](../../../src/_test-output/p300-cross-subject-20260926/protocol.json) · [Independent verification](../../../src/_test-output/p300-cross-subject-20260926/verification.json) · [Maintained runner](../../../tools/reference-generation/p300/cross_subject.py)

## Results

Five complete cycles per letter. Pooled letter accuracy with current causal IIR preprocessing and centered regularized Fisher. Every method scores the same eligible letters, starting with the third, so calibration letters never enter the reported test pool.

| Dataset | Subject groups | Test letters | Group, zero calibration | Group + 1 letter | Group + 2 letters | Only 2 letters, no group | Full within-subject LOLO reference |
|---|---:|---:|---:|---:|---:|---:|---:|
| Movicom 6×6 | 49 | 525 | 307/525 = 58.5% | 375/525 = 71.4% | 425/525 = 81.0% | 321/525 = 61.1% | 509/525 = 97.0% |
| Movicom 3×3 | 49 | 588 | 352/588 = 59.9% | 404/588 = 68.7% | 447/588 = 76.0% | 321/588 = 54.6% | 562/588 = 95.6% |
| Q 6×6 | 43 | 339 | 291/339 = 85.8% | 307/339 = 90.6% | 323/339 = 95.3% | 243/339 = 71.7% | 329/339 = 97.1% |

The full-calibration reference fits every other eligible letter, including later letters. It is a reference for available subject-specific information, not a sequential startup procedure. The two-letter-only control uses the identical first two letters and fitter without a group prior. One-letter-only accuracy is 44.6%, 39.8% and 49.9% respectively.

Individual variation matters. After two-letter adaptation, the number of subjects reaching at least 80% is 31/49 for Movicom 6×6, 27/49 for Movicom 3×3 and 41/43 for Q. Six Movicom subjects in each matrix and one Q subject remain below 50%. This is not yet a dependable universal replacement for calibration.

The paired subject-mean gain of two-letter adaptation over zero calibration is +22.2 percentage points for Movicom 6×6 (descriptive 95% subject-bootstrap interval +17.0 to +27.7), +16.2 for Movicom 3×3 (+10.2 to +22.3), and +9.6 for Q (+4.8 to +15.0). The workbook also gives cumulative cycles 1–5, raw versus normalized group pooling, subject results and confidence intervals. Intervals resample held-out subject outcomes; they do not repeat the full nested training or correct for all comparisons.

### Starting immediately

Zero-calibration weights require no target EEG, target covariance, resting recording or target-specific alignment. They can be applied to the first letter. The matched comparison above omits the first two letters only to give all modes identical test letters.

Scoring *all* eligible letters with the same frozen normalized group models gives Movicom 6×6 365/623 (58.6%), Movicom 3×3 413/686 (60.2%), and Q 365/425 (85.9%). On the first eligible letter alone: 27/49, 31/49 and 38/43 correct respectively. Q optical exclusions mean the first eligible letter is not always the first attempted letter. This extra view was computed after the primary run and did not select models or settings.

## Algorithm actually tested

The classifier remains centered Fisher/LDA. It learns the difference between target and nontarget EEG feature means and the within-class noise covariance. Pooling subjects does not require a different online scoring operation.

For each source subject `s`, calculate `delta_s = mean(target) - mean(nontarget)` and a count-pooled covariance:

```text
C_s = [(n_T - 1) Cov_T + (n_N - 1) Cov_N] / (n_T + n_N - 2)
v_s = trace(C_s) / number_of_features
delta_group = mean_s(delta_s / sqrt(v_s))
C_group = mean_s(C_s / v_s)
```

Class covariances use centered n−1 estimates. Subjects receive equal weight, and normalization prevents a source with large absolute signal amplitude from dominating. This is scalar normalization, not channel whitening or target-domain alignment. The new subject's zero-calibration signal needs no fitted scale because multiplying all cell scores by a positive scalar leaves their ordering unchanged. A raw, unnormalized pooling control was also evaluated.

With one or two labelled calibration letters, calculate the new subject's normalized `delta_target` and `C_target` from **only those letters**, then:

```text
delta = (1 - a) delta_group + a delta_target
C     = (1 - b) C_group     + b C_target
w     = inverse(C + alpha * trace(C)/p * I) * delta
```

The implementation solves this system using Cholesky factorization. Inference applies the linear weight to each flash feature vector and averages scores over flashes exposing each cell. All weights are frozen before evaluating later letters. No self-labelled updates or language model is involved.

One 6×6 letter supplies 60 flashes, including ten target responses. One 3×3 letter supplies 30 flashes, also including ten target responses. Two letters double these counts. That is useful information for a restrained update, but weak support for fitting a large independent covariance matrix. The group covariance provides the missing support.

The frozen adaptation grid contains `(a,b) = (0,0)`; `a` in 0.25, 0.5, 0.75, 1 crossed with `b` in 0, 0.25, 0.5; and `(1,1)`. The choice is made independently for one and two letters using source subjects only. Ties follow the predeclared order. With current preprocessing, two-letter selection chose `(0.5,0.5)` in 140/141 outer folds and `(0.75,0.5)` in one. This stability supports a simple prior-weighted update, but fixing 0.5/0.5 now would be a subsequent choice requiring separate validation.

## Validation and scope

141 learning recordings contain 1,734 eligible letters. The paired evaluation uses 1,452 later letters. Movicom has the same 49 year/subject identifiers in each matrix; Q has 43 identifiers. These are dataset-defined identities. The retained Movicom metadata does not establish whether anyone participated in multiple years; repeated real people across year IDs cannot be ruled out. There are not 141 established independent people.

For each outer test subject, train group statistics on every other subject in that dataset and matrix. For each inner source-subject validation, exclude both the outer subject and that inner subject from its group model. Adapt to the inner subject's first one or two eligible letters and evaluate only its later letters. Choose the blend by mean subject accuracy at cycle five, then apply it to the outer subject. All outer subjects' test labels are excluded from fitting and new parameter selection. The current study reads learning recordings only, enforced by the existing input audit hook.

Two preprocessing recipes were frozen before the new run:

- Historical preprocessing: original MATLAB causal Butterworth bandpass prototype order 4, 1.5–10 Hz, 0–600 ms epochs, 50 Hz point features, no added anti-alias filter, centered Fisher with 1% trace ridge. This is a historical *preprocessing* control, not the original uncentered Mat0 fitter.
- Current preprocessing: separate causal HP order 2 and LP order 4, 100–600 ms, 40 ms means every 20 ms, causal anti-alias lowpass. 6×6: 0.3–12 Hz and 0.3% ridge. 3×3: 0.1–18 Hz and 0.1% ridge. These settings were selected in earlier within-subject studies using this corpus, so current-recipe numbers retain prior selection optimism. Nested validation protects the new adaptation choices, not those earlier choices.

Historical-preprocessing zero / one-letter / two-letter results are 46.1 / 58.3 / 69.1% for Movicom 6×6, 52.2 / 59.4 / 68.7% for Movicom 3×3, and 84.7 / 90.3 / 91.2% for Q. The advantage of limited supervised adaptation is present without the recently optimized preprocessing.

Use the established eight channels, original acquisition references, timing and common eligibility pools. Native sample rates remain 500 Hz for Movicom and 1000 Hz for Q. Filtering is continuous, causal and zero-initialized per recording. No filtfilt, per-epoch filtering, target-wide normalization or unseen-subject spatial filter is fitted. Q uses the previously extracted photodiode timing; this is an offline replay and does not newly validate online optical detection.

This study does not pool Q with Movicom, does not test transfer between amplifiers, does not use play recordings, and does not reproduce a deep-learning or Riemannian paper. Matching electrode names alone does not guarantee matching reference, timing, noise or stimulus response.

Independent verification passed 1,692 weight comparisons (maximum relative difference 1.67e−12), 87,120 decisions reconstructed directly from flash scores, 14,520 full-calibration decisions, six complete independently recomputed inner selections, 20 block-size/future-sample causality checks, and all 210 aggregate rows. Raw input hashes were checked during extraction; corpus-index hashes remained unchanged. Numerical and visual checks also passed for the XLSX export.

## Relation to published work

- [Kindermans et al., 2014: Integrating dynamic stopping, transfer learning and language models in an adaptive zero-training ERP speller](https://biblio.ugent.be/publication/4425479) demonstrates visual ERP transfer combined with continuous unsupervised adaptation. It supports skipping a dedicated calibration session, but its adaptive results should not be described as those of a completely frozen source-only classifier.
- [Khazem et al., 2021: Minimizing subject-dependent calibration for BCI with Riemannian transfer learning](https://arxiv.org/abs/2111.12071) combines source and target class prototypes with a tunable weight and tests small target calibration sets. Its reported balanced epoch accuracy is not our letter-selection accuracy. It is a plausible next algorithmic comparator, not a prerequisite for the linear prior update tested here.
- [Li et al., 2025: Self-distillation with beta label smoothing-based cross-subject transfer learning for P300 classification](https://www.sciencedirect.com/science/article/pii/S0031320324008653) studies calibration-free neural-network generalization from other subjects. Its published performance is dataset- and protocol-specific; it is not an estimate for Resonance.
- [Optimization of transfer learning based on source sample selection in Euclidean space for P300-based brain-computer interfaces (2024)](https://www.frontiersin.org/journals/neuroscience/articles/10.3389/fnins.2024.1360709/full) uses target features for alignment/source selection and fine-tuning. That approach requires target data and should not be counted as strict zero-recording operation.

## Recommendation for Resonance

The best first extension is an optional **group prior plus brief supervised calibration**, with a frozen-group mode available for exploratory immediate use. Retain longer subject calibration when performance is inadequate. A failed or noisy first letter must not force adaptation away from a usable prior.

Training can remain offline: fit and version separate priors for validated montage/reference/timing configurations. Store group mean difference, covariance, preprocessing and training provenance. After one or two prompted letters, update the statistics, solve the same centered Fisher model, and save a subject-specific model. Native inference can continue using its existing feature extraction and linear cell scoring. Supporting this requires an explicit group-model scope and an adaptation path; merely bypassing the current subject-match guard is not sufficient.

Before deploying this as a standard mode, freeze the present method and evaluate it on each held-out subject's separate play recording, extend the calibration curve to 3, 4 and 6 letters, and test the poor-performing subjects explicitly. Keep all such tuning inside source-subject validation. Assess cross-year robustness and cross-amplifier transfer separately. Finally test first-letter operation and adaptation prospectively on the actual NVX/Movicom rig. Automatic confidence-based acceptance needs its own validation; a high score margin alone is not evidence of a correct letter.

## Reproduction

The run directory retains its original 20260926 name because planning began before midnight; completion was 2026-09-27. Use the private classifier-reference Python/NumPy/SciPy runtime and a new absolute output directory. Commands are `cross_subject.py plan`, `prepare --workers 4`, `run --workers 4`, with `--output RUN` on each, then `verify_cross_subject.py RUN`. The runner reuses the frozen eligibility file in `p300-learn-tuning-20260925/pool.json`; raw data are the retained corpus and Q subset, not deleted BPrac folders or external Q source HDF files.

Group models, fitted fold weights, inner accuracies and per-letter decisions are research evidence under the run directory. The two-sheet workbook contains all 210 aggregate setting/cycle results and 1,974 subject/setting records. No distribution models or hardware settings changed.
