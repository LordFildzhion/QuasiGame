# P300 finalist validation and separate recording transfer — 2026-09-26

Completed the three requested follow-up checks and learn→play evaluation. Settings remain frozen for transfer. No production processor, model, MATLAB file or hardware configuration changed.

[Illustrated report](../../../outputs/p300-pipeline-report-20260926/p300-selected-pipelines.docx), [XLSX tables](../../../outputs/p300-finalist-validation-20260926/p300-finalist-results.xlsx), [maintained commands](../../../tools/reference-generation/p300/README.md#finalist-validation-and-separate-recording-transfer).

## Separate recording transfer

Train within subject on the first learning recording, save weights before opening play, then apply unchanged settings and weights to the second recording with fresh zero filter state. Continuous filtering precedes epoch extraction. Play targets never enter fitting or parameter selection. Movicom training uses the historical context-safe labelled flash pool, including context-safe epochs from otherwise complete trials whose remaining tail lacks full FIR context; Q uses its original 425 whole eligible calibration letters. The numerical runner reproduces the original Movicom and MATLAB transfer choices exactly.

| Complete pipeline | Movicom 6×6 recorded endpoint | Q 6×6 five cycles | Q 6×6 eight cycles |
|---|---:|---:|---:|
| Stock Movicom / Mov0 | 650/701 | 352/418 | 386/418 |
| Stock MATLAB / Mat0 | 600/701 | 339/418 | 378/418 |
| Selected FIR / Best | 663/701 | 383/418 | 403/418 |
| Selected separate HP/LP / Best | 663/701 | 385/418 | 399/418 |
| Selected direct IIR / Best | 662/701 | 389/418 | 402/418 |

Movicom has 41 labelled 6×6 play recordings: 94 selections end after three cycles and 607 after five. The 607-letter five-cycle subset gives FIR 577, HP/LP 579, direct IIR 576, Mov0 564, Mat0 536. Keep unknown 6×6 predictions and all 816 usable 3×3 attempts unscored. All 100 original play recordings are replayed; no inferred targets.

Q has 43 pairs: rec-001 trains; the only second file tests, rec-002 for 42 subjects and rec-006 for sbj_24. All test files are eight-cycle typing. User confirmed the row-wise alphabet `АБВГДЕ / ЁЖЗИКЛ / МНОПРС / ТУФХЦЧ / ШЩЫЭЮЯ / 124567` and target `НАСТРОЕНИЕ`, cells `[13,0,17,18,16,14,5,13,9,5]`. Saved play `cur_target` fields are not reliable target labels and are ignored.

The self-contained [Q pool](../../../equipment/Movicom/classifier-reference/corpus-clinical8/README.md) now also retains exact eight-channel EEG, photo, block timing, all stimulus messages and settings from every second recording. All 430 attempts remain retained. The same per-flash optical lag, duration, uniqueness and ambiguity criteria exclude 12 whole letters, yielding 418 scored attempts. Excluded one-based attempts: sbj_27: 9; sbj_28: 8; sbj_32: 5; sbj_34: 3,4,5; sbj_35: 6; sbj_36: 1,4,8,9; sbj_41: 2. Play extraction permits recording-wide failure fractions above 5% so valid letters can still be retained; individual flash criteria were not relaxed. The calibration extractor's default 95% guard remains unchanged.

Q also crosses all four established profiles with Mov0, Mat0 and Best (12 configurations), plus direct IIR/Best. Eight-cycle correct counts by fitter Mov0/Mat0/Best: stock Movicom 386/378/389; stock MATLAB 389/378/399; selected FIR 388/383/403; selected HP/LP 400/376/399. Thus Best does not dominate every matched transfer cell. Presets were not changed after seeing this result.

HP/LP minus FIR paired subject-mean difference: Movicom −0.15 percentage points, 95% bootstrap interval −1.75 to +1.36; Q −0.93, interval −2.09 to 0.00. Twenty thousand subject resamples, seed 9262026; descriptive intervals without multiplicity correction. Pooled discordance is 11 versus 11 letters on Movicom and five favouring FIR versus one favouring HP/LP on Q. These are retrospective replay results, not an interactive experiment with changed feedback.

[Transfer evidence](../../../src/_test-output/p300-selected-transfer-20260926/completed.json): 1,059 independent solver checks; 82,927 decisions independently reconstructed from saved flash scores; 15,782 stock decisions match the earlier transfer run; 659 retained input hash checks; persisted weights unchanged after test. The unregularized Mov0 weights have maximum alternate-solver relative difference 0.000231; all resulting letter decisions agree. The workbook stores all 13,749 endpoint predictions and all subject/cycle aggregates; complete cumulative predictions and flash scores remain in JSON/NPZ.

## Complete selection across years

Each outer fold holds out one of 2021–2025, separately for 6×6 and 3×3. Rank the complete 5,400-setting joint filter/window/ridge grid using only other-year recordings. Keep the two highest-ranked distinct filter/window bases per family. Cross with six feature layouts and twenty covariance choices, then perform lower-ridge closure for training winners at the 0.001 boundary. Ranking uses subject-mean cycle five, pooled cycle five, mean earlier-cycle subject accuracy and fixed original order. Globally selected prior-winner controls are excluded.

Ten outer folds contain 4,460 unique matrix/configuration candidates including closure. Candidate predictions can be cached for all years, but only training-year scores choose settings. The selected setting is evaluated on the held year by within-recording whole-letter validation. Every classifier remains within subject.

| Family allowed during selection | 6×6 held-year correct / 623 | 3×3 held-year correct / 686 |
|---|---:|---:|
| FIR | 606 | 644 |
| Direct bandpass IIR | 598 | 640 |
| Separate HP/LP IIR | 595 | 644 |
| Any family | 606 | 644 |

Independent verification reranks all 40 choices with disjoint training/held years and recomputes all 3,927 unique chosen held-letter fits, including direct covariance-fit verification (maximum relative weight discrepancy 7.09e−10). The search space was informed by earlier exploratory analysis: this validates the complete core selection procedure, not an independently preregistered repetition of every historical research decision. Cross-year person identity is unknown.

## Initialization with the same folds

All 623/686 letters remain in exactly the same folds. Compare zero filter state with steady state for constant first-sample prehistory in both main and anti-alias filters. Reset once per recording. Six fixed matrix/family finalists, 7,854 fits, direct independent covariance checks. Zero predictions exactly reproduce the prior reference; analytical FIR steady state independently matches explicit constant prehistory.

All final correct totals remain unchanged: 6×6 FIR/BP/HP = 612/604/606; 3×3 = 657/654/655. For 3×3 HP/LP, two letters improve and two worsen. Earlier-cycle correct counts change from `[447,568,605,640,655]` to `[440,567,610,643,655]`. Thus initialization can change early decisions but provides no net five-cycle gain and does not account for the earlier ranking reversal after changing both training and evaluation pools.

[Year/startup evidence](../../../src/_test-output/p300-finalist-validation-20260926/completed.json) contains training/held IDs, every selected setting, full prediction caches, startup discordance and verifiers.

## Native SPEED replay

Independent test-only processor inside native x64 SPEED, uniquely named `SPEED_FINALIST_*` services with loopback R3 inputs. Fixtures use actual first two eligible calibration letters from 2025 sbj09 at both Movicom matrix sizes and Q sbj_09 at 1000 Hz. Weights fit within subject for numerical parity, not as an accuracy evaluation. Events are already aligned to source sample indices.

All three families × three datasets × block sizes 10,25,137 pass (27 accelerated runs), plus four paced 25-sample 6×6 FIR/HP replays at both rates. All 310 cumulative decisions match batch reference; each emits at the first native callback containing its required samples. Maximum relative signal/feature/score error is below 5e−13. Filter state carries across blocks and letters; feature means use a separate direct implementation.

| Rate and preset | Callback median ms | Callback p95 ms | Median decision arrival after last flash ms |
|---|---:|---:|---:|
| 500 Hz FIR | 0.447 | 0.940 | 1641.3 |
| 500 Hz HP/LP | 0.318 | 0.579 | 623.4 |
| 1000 Hz FIR | 0.617 | 1.030 | 1631.7 |
| 1000 Hz HP/LP | 0.430 | 0.766 | 618.9 |

The callback budgets are 50 and 25 ms. These timings include test-only retention of data arrays, so they are not a production CPU benchmark. Arrival includes loopback transport and sample-block completion. Full epoch availability uses the half-open extraction interval; the last required sample is one sample period before its nominal endpoint. FIR adds 1.022 s physical wait in 6×6, 2.046 s in 3×3, on top of the 600 ms epoch endpoint.

Initial harness attempts exposed a short control timeout, a stale output-file race on rerun and discovery reconnects to a single-client source. The final harness waits for a fresh completion event and supports header reconnects; the full 31-run matrix was completed after those corrections. Failed logs remain evidence. Only test-owned processes were terminated. [Native evidence](../../../src/_test-output/p300-finalist-speed-20260926/completed.json).

This proves stateful mathematical parity in the native host. It does not add the selected cascade, averaging, epoch start and FIR delay to the stock `online_processing.py` model contract. Live photodiode detection, display/amplifier timing and deployment acceptance remain separate work.

## Recommendation and artifacts

Retain centered, count-pooled Fisher with the frozen small ridge. Use separate HP/LP as the practical online candidate, FIR as the accuracy reference, and direct IIR as a declared additional comparator. Next work is production contract integration and prospective fixed-preset validation. Do not retune on these same play outcomes.

The updated report has eleven visually reviewed pages and eleven PNG figures; 61 displayed accuracy cells reconcile with numerical results. The XLSX has thirteen sheets, 13,749 endpoint predictions and 6,407 checked formula caches. Word rendered in a dedicated hidden instance after the packaged renderer reported missing LibreOffice; bundled Poppler produced the inspected PNGs. QA intermediates remain under `_test-output`, outside distribution.
