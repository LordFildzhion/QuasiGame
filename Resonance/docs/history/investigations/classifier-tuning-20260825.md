# Classifier tuning — what was measured, what shipped, what did not — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/tepsound.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-classifier-tuning--what-was-measured-what-shipped-what-did-not"></a>


2026-08-25. Harness, tables and analysis: `R:\dist\_build\ldatune\`. Data: ten compareSOUND
recordings, five subjects, already extracted to `R:\dist\_build\ldaprobe\`.

Method: a 20-config sweep driving the **shipped** `lda.cpp`/`linalg.cpp` (not a re-implementation),
grouped 5-fold CV cut on the cue interval, five group-shuffle seeds averaged per cell. Selection
was then attacked by four independent hostile passes — leak hunt, channel identity, independent
re-scoring, statistics.


<a id="history-round-4--the-onlineoffline-gap-found-and-closed"></a>

## Round 4 — the online/offline gap, found and closed

Replaying `12_07IK` through the service gave AUC 0.741 against the offline harness's 0.775. That
gap was real and it had one cause.

<a id="history-the-decomposition"></a>

### The decomposition

The service's epoch file carries BOTH traces -- `/epochs` (SOUND-cleaned) and `/preproc`. Scoring
all three epoch sets through the SAME harness, the SAME CV scheme, the SAME feature spec and the
SAME grouping rule, so that ONLY the epochs differ:

| epoch set | n | CV AUC | CV acc |
|---|---|---|---|
| service `/epochs`, SOUND-cleaned "online" | 170 | **0.7071** | 67.8 |
| service `/preproc`, preprocessed | 170 | **0.7529** | 66.0 |
| offline reference tensor | 167 | **0.7522** | 68.5 |

The service's preprocessed trace reproduces the offline tensor to **0.0007**. The SOUND-cleaned
trace costs **0.046 AUC**. The classifier was never the difference; the trace it was fed was.

<a id="history-the-defect"></a>

### The defect

`classifierTrace()` called `SoundStore::traceOf()`, which switches on **the display's average
source**. So what the average plot happened to be showing decided what the classifier was fitted
on, and `preprocessed` was effectively unreachable for the classifier -- the two settings had
nothing to do with each other and were wired to the same knob.

Fixed: a `clfTrace` parameter of the classifier's own -- `preprocessed` (default), `online`,
`current model` -- read directly from `StoredEpoch`, with the display left alone. `spec.traceSource`
now names what the classifier actually read, so a saved model still refuses to be applied across a
cleaning change.

<a id="history-after-the-fix-on-the-same-replay"></a>

### After the fix, on the same replay

`AUC 0.765, 70.8 % +/- 4.2, 170 trials (85/85), 40 groups, gamma 0.060, from preprocessed`
against the offline 0.775 / 74.1 % on 167 trials. **Residual -0.010 AUC**, attributable to the
three trials the offline extraction rejected and to fold seeds.

A second gain came free: 170 trials retained instead of 162, and 40 groups instead of 38, because
`preproc` exists for epochs whose SOUND clean was still warming up and which the old path refused.

<a id="history--what-this-does-not-establish"></a>

### ⚠ What this does NOT establish

One recording. The direction is clear and the mechanism is plain -- SOUND removes channel-wise
noise to make an AVERAGE readable, and some of what it removes is discriminative -- but the SIZE
(0.046) is a single measurement. It decided a default; it is not a result to quote.


<a id="history-round-3--transition-trials-and-the-r-squared-map-at-full-resolution"></a>

## Round 3 — transition trials, and the r-squared map at full resolution

<a id="history-the-r-squared-map-per-channel-per-sample"></a>

### The r-squared map, per channel per sample

`r2plot.py` writes `r2_heatmap.png`, `r2_traces.png` and `r2_peaks.txt` to
`R:\dist\_build\ldatune\`. One r-squared vector of length 701 per channel: the squared
point-biserial correlation between that sample's value across trials and the 0/1 label. No binning
(the 25 ms rows in the round-2 table were display only).

Peaks, mean of ten recordings, floor 5.6 (x1000):

| channel | peak r2 x1000 | latency |
|---|---|---|
| CP3 | 63.7 | 119 ms |
| CP1 | 56.8 | 151 ms |
| C3 | 52.0 | 119 ms |
| C1 | 50.8 | 131 ms |
| Cz | 44.1 | 124 ms |
| P3 | 39.8 | 121 ms |

The top five are central and LEFT-lateralised, and every peak latency falls between 110 and 160 ms.
The bright block on the heatmap runs from about 40 to 200 ms.

<a id="history-the-upper-boundary-is-a-plateau-from-150-to-180"></a>

### The upper boundary is a plateau from 150 to 180

The heatmap suggested the earlier 150-vs-250 test had missed the interesting range. Filled in:

| feature window to | 150 | 160 | 180 | 200 | 220 | 250 |
|---|---|---|---|---|---|---|
| central 11, all trials | **0.6910** | 0.6867 | 0.6827 | 0.6774 | 0.6719 | 0.6604 |
| central 11, 40/class | 0.6442 | 0.6457 | **0.6461** | 0.6366 | 0.6303 | 0.6196 |
| left 11, 40/class | 0.6533 | 0.6561 | **0.6590** | 0.6538 | 0.6551 | 0.6496 |

Everything from 150 to 180 is within 0.006. **The shipped 150 was not moved** -- there is nothing
to gain and this exercise has already been burned once by acting on a difference that size.

<a id="history-removing-trials-adjacent-to-a-label-change--no-generalisation-benefit"></a>

### Removing trials adjacent to a label change — NO generalisation benefit

The proposal: `1 1 1 1 0 0 0 0` becomes `1 1 1 . . 0 0 0`, on the argument that around a condition
change the subject's state has not caught up with the cue. It costs 30 % of the trials.

⚠ **Removing them from the TEST set is not a measurement of the classifier.** It deletes the
hardest cases and raises AUC whether or not anything was learned. Measured all three ways, same
feature sets throughout, at 40 trials per class:

| config | keep all | drop from both | **drop from TRAINING only** |
|---|---|---|---|
| all 64 / component means | 0.5790 | 0.6253 | 0.5765 |
| central 11 / component means | 0.6266 | 0.6899 | 0.6308 |
| central 11 / 10 ms waveform | 0.6442 | 0.7189 | 0.6507 |
| left 11 / 10 ms waveform | 0.6533 | **0.7243** | 0.6630 |
| RMS top 8 / 10 ms waveform | 0.6375 | 0.6829 | 0.6321 |

Train-only, where the scored set is identical either way: **-0.005 to +0.010, 4-5 of 10 recordings,
p >= 0.754**. Nothing. The entire apparent +0.05 to +0.09 is the test set getting easier.

**But the drop-both column is not meaningless** -- it is the right number for a different question.
A feedback loop that REFUSES to act on a trial adjacent to a cue change would score 0.72 on the
trials it does act on, against 0.65 if it acts on everything. That is a real operating choice with
a real price: no feedback on ~30 % of trials. It is not a better classifier; it is a classifier
that declines the hard cases.

<a id="history-a-harness-bug-worth-recording"></a>

### A harness bug worth recording

`sweep2.cpp` took its `shipped5` baseline from `LdaFeatureSpec::defaultWindows()`. When that
function was changed to the 13-bin waveform, the baseline silently became the thing it was supposed
to be compared against -- two columns of identical numbers, and a +0.09 "transition removal" gain
that was partly the feature change. The baseline is now pinned to the literal five component means
and renamed `means5`. **A baseline read from a shipped default is not a baseline.**


<a id="history-round-2--the-operators-own-proposals-all-four-measured"></a>

## Round 2 — the operator's own proposals, all four measured

Four proposals, made after seeing round 1. Three confirmed and shipped; one confirmed but
not worth new machinery.

<a id="history-1-a-downsampled-waveform-instead-of-component-means--confirmed-shipped"></a>

### 1. A downsampled waveform instead of component means — CONFIRMED, SHIPPED

The argument: N100's latency moves, so a mean over 85-140 ms smears a peak that has shifted and
gives two trials whose peaks sit 30 ms apart the same number. Correct.

Equal 10 ms bins beat the five component means in **every** channel set and at **both** retention
settings — +0.036 (central 11), +0.047 (left 11), +0.059 (all 64) on all trials. Six independent
comparisons, all positive. That consistency is the evidence; no single one clears a sign test.

<a id="history-2-bin-width--10-ms-measured"></a>

### 2. Bin width — 10 ms, measured

left 11, 20-150 ms, all trials: 3 ms **0.6986**, 5 ms **0.7022**, 10 ms **0.7072**, 20 ms
**0.6884**. Same ordering at 40/class. Finer bins buy resolution the response does not have and
cost dimensions the trial count cannot afford.

<a id="history-3-nothing-past-150-ms--confirmed"></a>

### 3. Nothing past 150 ms — CONFIRMED

Point-biserial r-squared, per channel per sample, mean over ten recordings (x1000):

| window | r2 | | window | r2 |
|---|---|---|---|---|
| pre-stimulus floor | **5.6** | | 150-175 | 13.5 |
| 25-50 | 7.2 | | 175-200 | 9.8 |
| 50-75 | 9.8 | | 200-225 | 10.5 |
| 75-100 | 10.1 | | 225-250 | 8.9 |
| 100-125 | 15.2 | | 250-275 | **5.9** (floor) |
| **125-150** | **17.3** | | 275-500 | 4.7-8.8 (floor) |

The signal peaks at 100-150 and is back at the pre-stimulus floor by 250. Extending the features
from 20-150 to 20-250 **lost 0.022 AUC**. The shipped 85-140 window was clipping the peak.

⚠ The pre-stimulus floor of 5.6 is not zero: pooled point-biserial r-squared is inflated by
between-cue drift, since trials inside one cue share slow state. It is a constant offset, so
relative comparisons across time hold, but the absolute values are not effect sizes.

<a id="history-4-rms-channel-selection--works-but-does-not-beat-the-anatomical-prior"></a>

### 4. RMS channel selection — WORKS, but does not beat the anatomical prior

RMS of the evoked response over 25-100 ms, ranked, top N, **computed inside each fold on training
trials only** (`sweep2.cpp` has its own CV loop for exactly this reason).

| at d10_20_150 | all trials | 40/class |
|---|---|---|
| all 64 | 0.6721 | 0.6203 |
| RMS top 8 | 0.6833 | 0.6375 |
| central 11 (hand-picked) | 0.6910 | 0.6442 |
| left 11 | **0.7072** | **0.6533** |

RMS top-8 vs central 11: **-0.008, 5/10 recordings** — indistinguishable. vs all 64: +0.011 to
+0.017. So energy-ranked selection is **as good as the anatomical prior and better than the whole
cap**, which makes it a sound automatic fallback where the montage is unknown — but it is not an
improvement, so it did not earn new machinery in the service.

⚠ **Raw RMS ranks the broken electrode first.** On these recordings the top channel by evoked RMS
is FT9 (the 183.7 uV one), followed by Fp1, Fpz, Fp2, AF3, AF4 — ocular, not cortical. Energy is
energy. The selector only works with gross-outlier rejection ahead of it, which is what the
service's bad-channel detector already does.

<a id="history-left-lateralised-beats-bilateral"></a>

### Left-lateralised beats bilateral

`left11` (C5 C3 C1 Cz FC5 FC3 FC1 FCz CP5 CP3 CP1) beats the bilateral central set by **+0.016,
9/10 recordings, p = 0.021** — the most consistent single comparison in either round, and it
matches the independently-established fact that the coil was over LEFT M1 in all ten recordings.

**Not shipped as the default**, deliberately: it bakes in a hemisphere, and a wrong lateralisation
would be a regression. The gain (+0.016) is small against the waveform change (+0.036). Operators
stimulating one hemisphere consistently should lateralise `clfChannels` toward it by hand.


<a id="history-shipped"></a>

## Shipped

| change | evidence |
|---|---|
| features are a 13-bin 10 ms waveform, 20-150 ms, not five component means | +0.036 to +0.059 AUC, same direction in every channel set |
| `clfChannels` defaults to the central region and accepts electrode **names** | the region ranks at the 100th percentile of 500 random 11-channel subsets, exact p = 0.002, and stays ≥97.6th when any subject is dropped |
| bad channels excluded from the classifier's feature set | one bad electrode cost **0.018 AUC** at the rolling window |
| AUC is reported against its own null, not against 0.500 | the null is **0.490 ± 0.082** at this n, measured by 2000 label permutations |


<a id="history-deliberately-not-shipped"></a>

## Deliberately NOT shipped

**Per-class Ledoit-Wolf shrinkage.** It was recommended on the basis of a +0.033 AUC gain
attributed to pooled shrinkage under-regularising at p = 320, n = 80. Implemented and measured, it
gives **−0.007**, not +0.033:

| at 40 trials/class | all 64 | central 11 |
|---|---|---|
| pooled | 0.5772 | 0.6268 |
| per-class | 0.5707 | 0.6251 |

The *mechanism* was then tested directly by forcing the coefficient up and down around whatever
Ledoit-Wolf chose. More shrinkage is monotonically worse (floor 0.2 → 0.5659, 0.6 → 0.5605); less
is flat to slightly better (cap 0.005 → 0.5867). **Ledoit-Wolf sits on a plateau; shrinkage
intensity is not where the operating-point loss comes from.** The original figure came from
sklearn's LDA, whose difference from ours is evidently not the per-class grouping alone.

`ShrinkageMode` is kept, defaulting to `Pooled`, with the measurement in the header — so the next
person does not re-derive this.


<a id="history-not-done-and-why"></a>

## Not done, and why

* **The epoching program does not exist on disk.** A full-drive search for `median_peak_uv` returns
  only its ten output `.json` files. The CAR, baseline window, interpolation method and rejection
  rule behind `ldaprobe\` therefore cannot be read, only inferred. **Everything downstream of it is
  unauditable until it is rewritten as a script that lives in the repo.** Not attempted here.
* **Trial rejection uses a whole-recording statistic** — `reject_threshold_uv = 5.000 ×
  median_peak_uv` in all ten files. Label-blind, so it cannot manufacture AUC (permutation confirms
  it), but in `12_20FG` it becomes class-differential: **22.7 % of hand vs 35.3 % of rest dropped**,
  and that recording is the second-highest scorer in the sweep. Belongs to the same missing program.
* **Subject 01AV is on a different amplitude scale.** `median_peak_uv` 2510 and 2097 against
  30–299 for the other eight — 30–80×. This is the subject whose two sessions disagree by 0.28 AUC
  and who supplies most of the fragile operating-point gain. **Check the gain/units on those two
  recordings before trusting anything derived from them.** A data question, not a code one.


<a id="history-what-the-numbers-are-and-are-not"></a>

## What the numbers are, and are not

Quote: *the central region ranks 100th percentile of 500 random 11-channel subsets, p = 0.002.*
With a gain figure: **+0.037 AUC on all retained trials, subject-level 95 % CI [+0.004, +0.071]**.

Do **not** quote the operating-window gain (+0.050): its CI is [−0.029, +0.128], 5/10 recordings,
and 60 % of it is one session whose sibling goes the other way. Do not quote any p from
`hypotheses.py` — 28 tests, Bonferroni threshold 0.00179, and the smallest p an n = 10 exact sign
test can produce is 0.00195, so nothing in that family can clear correction whatever the data show.

Do not describe a subject as "below chance" at the rolling window. **0.490 is the null mean**;
P(worst of five subjects ≤ 0.490 under H0) = 0.97.


<a id="history-what-would-settle-it"></a>

## What would settle it

Powered from the observed deltas: **~35–40 recordings, ≈18–20 subjects × 2 sessions**. Two sessions
per subject genuinely count — the ICC of the paired delta across a subject's sessions is ~0 or
negative, so the recording is the right unit.

**More cues per session, not more pulses per cue.** At 40 trials/class the retained set is 20 cue
intervals, ten per class; the grouped CV correctly treats the cue as the unit, so the effective n
of every operating-point number here is 20, not 80.

Pre-register exactly two tests: the central region vs all 64 at the shipped intervals, one paired
test at the recording level; and the region's percentile against a fixed set of 500 random
11-subsets, the same 500 on every recording.


<a id="history-reality-check"></a>

## Reality check

At the operating point d′ goes 0.275 → 0.457, Wolpaw ITR 0.56 → 1.30 bits/min — 108 s down to 46 s
of stimulation per reliable bit. A 70 %-accuracy binary loop needs AUC 0.771. **This halves
stimulation time per bit; it does not make the feedback loop usable.**
