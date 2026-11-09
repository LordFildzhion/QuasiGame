# P300 group classifiers on separate play recordings

2026-09-27. Follows the [learning-only cross-subject study](p300-cross-subject-20260927.md). [XLSX results](../../../outputs/p300-group-transfer-20260927/p300-group-transfer.xlsx). This is a retrospective transfer experiment, not a cap-session accuracy claim.

## Protocol

The held participant is excluded from the group and from source-only adaptation-weight selection. Zero-, one- and two-letter weights are copied exactly from the previous frozen models. The 3/4/6-letter extension uses the same fixed current preprocessing and blend grid, with nested leave-source-subject-out selection on the remaining learning letters. All 282 dataset/recipe/subject model bundles are fitted and fingerprinted in a learning-only process before a separate process reads any play recording. No play-based fitting or selection occurs. Full subject models fit all eligible learning letters and provide the conventional learn→play reference.

Group statistics average source subjects equally after scalar trace normalization. Adaptation blends normalized target-minus-other means and centered count-pooled covariances, using only the requested labelled calibration prefix. Classification remains linear Fisher with trace ridge and candidate-cell exposure averaging. Current 6×6 preprocessing is separate second-order 0.3 Hz high-pass / fourth-order 12 Hz low-pass, causal zero initialization, elliptic anti-alias stage, 100–600 ms window and 40 ms means at 20 ms stride, ridge 0.003. Three-by-three uses 0.1–18 Hz and ridge 0.001. No epoch-by-epoch filtering or filtfilt.

Movicom: 701 confirmed 6×6 play selections in 41 year/subject groups, scored at their recorded 3/5-cycle endpoint. Q: 418 eligible selections in 43 subjects, eight cycles, intended text НАСТРОЕНИЕ. Original exclusions and confirmed targets are unchanged. Fifty 3×3 play recordings have predictions but no accuracy because targets are unknown. Other unlabelled 6×6 predictions remain in the numerical evidence. Different cycle endpoints prevent treating the two dataset accuracies as an amplifier comparison.

## Results with current preprocessing

| Calibration | Movicom 6×6 | Q 6×6 |
|---|---:|---:|
| Group, no subject recording | 435/701 — 62.1% | 347/418 — 83.0% |
| Group + 1 letter | 521/701 — 74.3% | 373/418 — 89.2% |
| Group + 2 letters | 575/701 — 82.0% | 389/418 — 93.1% |
| Group + 3 letters | 592/701 — 84.5% | 392/418 — 93.8% |
| Group + 4 letters | 604/701 — 86.2% | 394/418 — 94.3% |
| Group + 6 letters | 643/701 — 91.7% | 391/418 — 93.5% |
| Subject only, 1 letter | 304/701 — 43.4% | 215/418 — 51.4% |
| Subject only, 2 letters | 421/701 — 60.1% | 311/418 — 74.4% |
| Subject only, all learning | 662/701 — 94.4% | 399/418 — 95.5% |

Two-letter adaptation improves over immediate group use by 20.0 percentage points in Movicom and 10.0 in Q. It improves over fitting two letters alone by 21.97 and 18.66 points respectively. Four Movicom subjects remain below 50% after two letters; one after four and none after six. Q has none below 50% after two. These counts matter more for an individual first session than the pooled mean alone.

Historical preprocessing, with the same centered Fisher fitting, gives group 0/1/2 accuracies 52.6/65.0/75.0% in Movicom and 81.8/90.0/92.3% in Q. It is a preprocessing control, not historical uncentered Mat0. Full rows, cumulative cycle results, subject results and unscored 3×3 texts are in the workbook.

## Recommendation and deployed policy

Use **two-letter adaptation** as the initial short-calibration choice; retain immediate group typing for an explicit zero-calibration comparison. Longer calibration is an available fallback, especially for Movicom. Full calibration still performs better in this retrospective test. Do not infer the best calibration length for a new person from these aggregate play results or tune the deployed policy on them.

Deployment priors use all learning subjects from their own pool. Their blend policy is selected by learning-only leave-one-source-subject-out evaluation before play is read. The retrospective accuracy above uses excluded-subject priors, not those full-pool files. Mean/covariance target weights by calibration length:

| Prior | 1 | 2 | 3 | 4 | 6 |
|---|---|---|---|---|---|
| Movicom 6×6 | .25/.5 | .5/.5 | .75/.5 | 1/1 | 1/1 |
| Movicom 3×3 | .25/.25 | .5/.5 | .5/.5 | .5/.5 | .5/.5 |
| Q 6×6 | .25/.5 | .5/.5 | .5/.5 | .5/.25 | .5/.25 |

For the longer Movicom 6×6 cases, source-only selection sometimes prefers the subject-only limit; a 1/1 blend contains no group contribution. Q 1000 Hz and Movicom 500 Hz stay separate. Q→physical NVX and legacy-event→Movicom firmware timing are prospective deployment changes whose physiological transfer has not been measured. The eight electrodes match, but source reference equivalence is not established. Movicom year/subject identifiers may represent repeat people across years, and current preprocessing was selected earlier on these corpora; nested blend selection does not remove those limitations.

## Reproduction and verification

Maintained tools: [group_transfer.py](../../../tools/reference-generation/p300/group_transfer.py), [export_group.py](../../../tools/reference-generation/p300/export_group.py). Separate `fit` and `score` processes; `fit` inherits the learning-only file audit. Run evidence: `R:/src/_test-output/p300-group-transfer-20260927`, including protocol, immutable model hashes, every flash score/cycle decision, aggregates and subject summaries. Independent feature-average scoring reproduces all **202,230 cycle decisions**. Every frozen model hash remains unchanged after scoring.

Native adaptation reproduces **705 fits across 141 subjects** and their cycle decisions; maximum relative weight error **2.5862e−12**. [Native implementation, tests, connected-hardware scope and deployment](../changes/2026-09-27-p300-group-classifiers.md).
