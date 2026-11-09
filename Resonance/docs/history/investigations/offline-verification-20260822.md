# Offline verification of the tepSound session of 2026-08-21 — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/tepsound.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-offline-verification-of-the-tepsound-session-of-2026-08-21"></a>


**Date of this work:** 2026-08-22, 01:20–02:00
**Binary verified:** `R:\dist\msvc64\bin\tepSoundService.exe`, 2026-08-21 05:17:33,
SHA256 `5168A090E3790E211B46362B8A0212651D4C14A388EF7AF61811CA2738CCEEF1` — the deployed build,
not a rebuild. No source was edited and nothing was rebuilt.
**Recordings:** opened read-only (`h5py` mode `'r'`) throughout. Nothing was written to, renamed in
or created inside the recordings directory. All output is in `R:\dist\_build\offline-verify\`.

---


<a id="history-1-verdict"></a>

## 1. Verdict

**The online output is internally exact and shows no sign of a defect. It cannot be re-derived
sample-by-sample, because the amplifier stream that fed it was never written to disk.**

Three separate statements, in decreasing strength:

1. **What the online file contains is arithmetically exact.** Every published average is the exact
   running mean of the published cleaned epochs — maximum absolute difference over all
   150 × 701 × 65 = 6.8 million values is **0.0**. Every cleaned epoch is exactly the SOUND
   operator applied to its own preprocessed epoch, to **1.29e-05 µV** (float32 ULP on a 50–77 µV
   signal, relative 2e-7). Baseline correction is exact to **3.4e-09 µV**. The
   `meanMepAmplitude` counter equals the mean of the 152 per-epoch amplitudes to all printed
   digits. There is no all-zero epoch and no NaN.
2. **The binary that produced it computes the pipeline correctly.** Replaying a recording from the
   same session, same rig and same cap through the same deployed binary and comparing every sample
   against an independent NumPy implementation: **58 of 64 channels agree to ≤ 3.5e-05 µV** across
   all 36 epochs; on the ten epochs before any repair is active the agreement is **1.9e-03 µV
   against a 33 861 µV signal — relative 5.7e-08**. Trigger count, epoch count, accept/reject
   decisions, warm-up size, retrain schedule and the bad-channel verdict all came out exactly as
   predicted.
3. **The online numbers themselves are not verifiable and never will be.** The offline run used
   *different trials* from a *different block* of the same session. It validates the machinery, not
   the numbers in `test_online_tepsound.hdf`.

**The TEP/EEG side is sound. The MEP side has two problems that make its amplitudes too small.**

* **The MEP measurement window ends before the MEP peaks** (§8.2). `mepTo` was 45 ms; the response
  peaks at **46.3 ms**. The configured window captures **59 %** of the peak-to-peak amplitude, and
  the per-epoch onsets pile up against the 45 ms edge in both runs. This is certain and measured.
* ~~**The configured MEP pair may be the wrong two electrodes**~~ (§8.1) — **CORRECTED
  2026-08-25, this bullet was wrong.** It read indices 64/65 (`?? 65`/`?? 66`) against "the sockets
  labelled `EMG1`/`EMG2` at indices 72/73". The operator has since stated the protocol: the EMG
  electrodes are plugged into **channels 65 and 66 of the EEG amplifier**, which is standard
  practice — they were never on AUX. Against his own `params\nvx136_64ch_8emg.json` (`Ch 1`…`Ch 72`
  + `AUX 1` + `AUX 2` + `Trigger` enabled) stream positions 65/66 are `Ch 65`/`Ch 66` and AUX 1/2
  are at 73/74. **The configured pair was correct.** The measured 1.9× difference between the two
  pairs is real but says nothing about an error — it compares the EMG electrodes against two AUX
  inputs carrying something else. The `?? 65` naming was a montage that stopped at 64 rows, since
  fixed by `mks64_emg2.ced` and the new `type` column.

Together with the window truncation the session's MEP amplitudes are low, by the window factor
alone.
**Both are recoverable without re-running the experiment** if the epoch file can be retrieved from
the experiment PC (§8.3). Nothing else found here would change the data.

---


<a id="history-2-the-two-files-and-how-they-align"></a>

## 2. The two files, and how they align

Both files carry Resonance RTC (ns since boot) and one wall-clock string, so the clocks cross-check
without assuming anything from the filenames.

| | RTC (s) | wall |
|---|---|---|
| `test_online_tepsound.hdf` `events[0]` "session started" | 815086.556223 | 2026-08-21T16:12:15.333 |
| `12_52MSO_TMS_BCI.hdf5` `annotations` "session" | 815390.509349 | 2026-08-21T16:17:19.287 |

ΔRTC = **303.953127 s**, Δwall = **303.954 s** → they agree to **0.9 ms** (the wall stamps have
1 ms resolution). Same machine, same boot, same RTC domain. There is no unknown offset.

```
814680.9  recorder for tepSound's own streams starts        16:05:29.6
815086.6  tepSound session STARTED                          16:12:15.333
815096.7  first trigger  (= arm + 10.103 s)
815385.1  last trigger (epoch 152)
815390.7  12_52MSO_TMS_BCI first EEG sample                  16:17:19.3
815429.4  tepSound session STOPPED                          16:17:58.095
815524.2  12_'s first TMS pulse
815662.4  12_'s last EEG sample                              ~16:21:51
```

**`12_52MSO_TMS_BCI.hdf5` is not the raw data tepSound was working on.** Its first sample is
5.6 s *after* the last online epoch; its first TMS pulse is 94.8 s after tepSound stopped. The
session and `12_` overlap for 38.7 s, and that overlap contains **0 of the 152 online epochs and
0 of `12_`'s 36 pulses**.

<a id="history-no-file-in-the-directory-is-the-right-one"></a>

### No file in the directory is the right one

Every sibling was opened and its RTC span and embedded original `D:` filename read
(`R:\dist\_build\offline-verify\scan_dir_final.txt`). Re-listed at 01:53 — the copy from the
experiment PC is still running and `08_52MSO_TMS_heel.hdf5` (01:11) and `10_p300_heel.hdf5` (01:29)
both appeared while this work was in progress.

| N: name | original D: name | wall | RTC span | rate | ch |
|---|---|---|---|---|---|
| 00_op_cl_eyes | 00_op_cl_eyes | 14:18:51 | 808282.4–808405.3 | 5 k | 75 |
| 01_force1 | 01_force1 | 14:23:48 | 808580.1–808884.5 | 5 k | 75 |
| 02_force2 | 02_force2 | 14:32:53 | 809125.0–809399.9 | 5 k | 75 |
| 03_site_heel_1 | 03_site_heel_1 | 14:40:32 | 809583.3–809766.5 | 5 k | 75 |
| 04_site_MT_1 | 04_site_MT_1 | 14:46:10 | 809922.1–810107.9 | 5 k | 75 |
| 05_site_heel_6 | 05_site_heel_6 | 14:51:17 | 810228.4–810415.7 | 5 k | 75 |
| 06_site_MT_6 | **06_site_heel_6** | 14:55:20 | 810471.9–810655.6 | 5 k | 75 |
| 07_52MSO_TMS_site | **07_site_heel_6** | 15:05:32 | 811083.5–811394.7 | 25 k | 75 |
| 08_52MSO_TMS_heel | **10_52MSO_TMS_heel** | 15:16:12 | 811723.6–812033.8 | 25 k | 75 |
| 09_p300_site | **12_52MSO_p300_site** | 15:29:42 | 812533.8–812917.0 | 5 k | 75 |
| 10_p300_heel | **10_52MSO_p300_heel** | 15:39:18 | 813109.6–813493.2 | 5 k | 75 |
| — | — | — | **GAP 813493.2 → 815390.7 = 31.6 min** | | |
| 12_52MSO_TMS_BCI | **13_52MSO_BCI** | 16:17:19 | 815390.7–815662.4 | 25 k | 75 |

The whole tepSound session (815086.6 → 815429.4) lies inside that gap. The N: names do **not**
match the D: names — the copy renumbered them — so filenames cannot be used to reason about order.

Replay was also ruled out as the input: `07_` and `08_` carry exactly 150 pulses over 311/310 s and
`12_` carries 36; the online run had 152 epochs over 288.4 s. None matches. The online file's own
header says `input: 75 channels at 25000 Hz` — it was the live amplifier.

---


<a id="history-3-settings-used-for-the-offline-run"></a>

## 3. Settings used for the offline run

Taken from the online file's own recorded pipeline description (`events[0]`), then **read back out
of the running offline service** with a parameter dump so the two could be compared field by field
(`R:\dist\_build\offline-verify\offline_params.txt`, screenshot `shots/01_settings_armed.png`).

Every line of the session's recorded pipeline is matched by the offline run:

| online `events[0]` says | offline parameters |
|---|---|
| input: 75 channels at 25000 Hz | run bar: `eeg · 75 ch · 25000 Hz` |
| trigger: bit 0 of channel 75, rising edge, refractory 500 ms | `triggerChannel 0` (= last), `triggerBit 0`, `triggerEdge Rising`, `refractoryMs 500` |
| blank: interpolate −0.2…1.3 ms, smooth 5 samples | `blankFrom -0.2`, `blankTo 1.3`, `blankSmoothing 5` |
| highpass Butterworth 2 @ 0.3 Hz / lowpass @ 2500 Hz | `preHighpass true/0.3`, `preLowpass true/2500` |
| guarded epoch −400…700 ms → 5500 @ 5000 Hz | `windowStart -200`, `windowEnd 500`, `guardMs 200`, `workRate 5000` |
| TMS interpolation −1…5 ms | `tmsInterpFrom -1`, `tmsInterpTo 5` |
| CAR: mean of all electrodes except none | `car true`, `carExcluded ""` |
| bad channels: 5 metrics, 2 passes, repair at most 25 % | all five `use*` true, `badPasses 2`, `maxBadFrac 0.25` |
| anti-alias EEGLAB FIR at 450 Hz | `antiAliasHz 450` |
| epoch −200…500 ms → 701 @ 1000 Hz | `outputRate 1000` |
| baseline −60…−10 ms | `baselineFrom -60`, `baselineTo -10` |
| SOUND λ 0.01, 5 iterations, cumulative, block 10, retrain 10 | `soundLambda 0.01`, `soundIterations 5`, `scheduleMode cumulative`, `warmupBlock 10`, `trainN 10`, `trainDn 10`, `soundTrainOn mean` |
| MEP: channel 66 − channel 65, 15…45 ms | `emgChannelA 65`, `emgChannelB 66`, `mepFrom 15`, `mepTo 45` |
| delivery: 700 ms after the pulse | `windowEnd 500` + `guardMs 200` |

**Note: every one of these is the deployed build's own default.** `blankTo` in particular already
defaults to 1.3 in this build (the A1 recommendation is in force), so no setting had to be forced to
reproduce the session.

The two settings the survey had to *infer* were confirmed directly from the live service:
`rejectPeakUv = 0` (accept everything) and `protectedChannels` includes Cz — the full list is
`Fz FCz Cz C1 C2 C3 C4 CP1 CP2 CP3 CP4 CPz P1 P2 Pz POz`. A third inference, `averageOf = cleaned`,
is confirmed by `averageSource = "online"` plus the exact numerical result in §5.

**Not recorded anywhere and still inferred:** the leadfield (`calib/mks64_leadfield.h5` — the only
one in the tree) and the software build (`test_online_tepsound.hdf` carries no version string).

<a id="history-trigger-polarity-verified-from-this-sessions-own-data--not-carried-over"></a>

### Trigger polarity, verified from this session's own data — not carried over

Independently, in Python, from `12_`'s trigger channel: only two words ever appear, idle
`0x0000FFFA` (6 788 878 samples) and `0x0000FFFB` (9 002). **bit 0 rests LOW and pulses HIGH**,
36 rising / 36 falling, pulse width 10.0000 ms median (10.0400 max). The service's own run bar
printed the same thing from the live stream: **`bit 0: rests low, 36↑ 36↓, pulses high 10.00 ms`**.

⇒ **`Rising` is correct for this rig, confirmed from this session.**
`report_trigger-validation.md` remains wrong here — do not "fix" the setting to match it.

---


<a id="history-4-the-offline-run"></a>

## 4. The offline run

```
tepSoundService.exe --serviceConfig <run config> --autoArm      (armed 12 s before playback)
playbackSource.exe  --file "…\12_52MSO_TMS_BCI.hdf5" --serviceName VERIFY --stream eeg --speed 1 --autoStart
```

**Speed 1.** Playback reported `271.9/271.9 s, 1986 blocks, late 0.51 ms mean / 2.58 ms max,
**0 underruns**` — the whole file, on time.

The IIR-settling trap did not apply: the console was armed 12 s before playback began and `12_`'s
first pulse is 133.7 s into the file, so the filters had 145 s of data before the first epoch. The
first ten epochs show no decaying transient (see §6).

⚠ **The first attempt (01:28) died: `playbackSource.exe` crashed with an access violation
(0xc0000005) inside `Qt5Network.dll` 90 s into the file.** See §8.

---


<a id="history-5-comparisons-with-a-number-for-each"></a>

## 5. Comparisons, with a number for each

<a id="history-51-triggers"></a>

### 5.1 Triggers

| | value |
|---|---|
| rising edges in `12_`, found independently in Python | **36** |
| triggers the service reported | **36** |
| refused by the 500 ms refractory | **0** (file's minimum ITI is 994.16 ms) |
| pulse width, Python / service run bar | 10.0000 ms / 10.00 ms |

**Count and identity: exact.** Timing of the *stamps* is another matter — see §6.3.

<a id="history-52-counters"></a>

### 5.2 Counters

| counter | online (152 ep) | offline (36 ep) | relation |
|---|---|---|---|
| triggers | 152 | 36 | different source data |
| epochs | 152 | 36 | = triggers, both |
| accepted | 152 | 36 | = epochs, both (`rejectPeakUv 0`) |
| in average | 142 | 26 | = epochs − 10 warm-up, both |
| rejected | 0 | 0 | identical |
| lost / starved / incomplete / artifactSkipped / droppedFrames | 0 | 0 | identical |
| models trained | 15 (0…14) | 3 (0…2) | = floor(n/10), both |
| trainEpochs (last) | 151 | 30 | cumulative, both |
| all-zero epochs | none | the 10 warm-up cleans only | as designed |

**Every structural relation the online run obeys, the offline run obeys.**

<a id="history-53-bad-channels"></a>

### 5.3 Bad channels

| | online | offline |
|---|---|---|
| worst | **FT9, badness 11.23–12.06 at every one of the 15 retrains, metric `neighbour`** | **FT9, badness 12.1576, metric `neighbour`** |
| repaired | yes, every retrain | yes (`flag = 1`) |
| others flagged | Fp1, Fp2, AF7, Fpz, AF3, TP9 (kurtosis, 1.15–9.53) | P7 1.59, F7 1.20, T7 1.12, T8 1.07 |
| protected-flagged | Cz (×2) | FCz |

**FT9 is the same electrode, at the same badness, by the same metric, in both runs.** After repair
its per-epoch σ falls from **2551.90 µV to 20.45 µV** (125×) and it sits at the median channel
level (~20 µV). Everything else flagged in either run sits at badness 1–2, i.e. just over
threshold, and comes and goes between calibrations in both. **Only FT9 is decisively bad.**

<a id="history-54-sample-level-agreement--the-offline-run-against-an-independent-numpy-implementation"></a>

### 5.4 Sample-level agreement — the offline run against an independent NumPy implementation

`R:\config\tepsound_reference_pipeline.py` + the `osound` package recompute the whole continuous
stage from the raw file, with no code shared with the service.

| quantity | worst absolute difference | where | relative |
|---|---|---|---|
| alignment of service epoch 1 to reference trigger 1 | **9.75e-04 µV** | — | 2.9e-08 |
| preproc, **epochs 1–10** (before any repair), all 64 channels | **1.93e-03 µV** | FT9, 33 861 µV signal | **5.7e-08** |
| preproc, **58 of 64 channels**, all 36 epochs | **≤ 3.5e-05 µV** | — | ~1e-07 |
| `clean` vs an independently computed `operator × preproc` | **1.30e-05 µV** | 269 184 values, 168.5 µV signal | **7.7e-08** |
| online `clean` vs `M × preproc`, M recovered per model block | **1.29e-05 µV** | model 12, 55.9 µV signal | 2.3e-07 |
| online published `average` vs running mean of published `clean` | **0.0** | all 150 blocks | exact |
| baseline of the final online average over −60…−10 ms | **3.41e-09 µV** | worst of 64 channels | — |

**Every number in this table is at or below one float32 ULP.** The continuous stage, TMS blanking,
both Butterworth filters, CAR, the anti-alias FIR, decimation, guard trim, baseline correction and
the SOUND application are all exact.

<a id="history-55-mep"></a>

### 5.5 MEP

| | online (152 ep) | offline (36 ep) |
|---|---|---|
| amplitude mV, mean | 0.193645 | 0.306144 |
| amplitude mV, median | 0.181265 | 0.104850 |
| amplitude mV, max | 0.653744 | 2.348070 |
| valid | 152 / 152 | 36 / 36 |
| onset present | 148 / 152 | 22 / 36 |
| onset ms, median | 43.00 | 43.90 |
| onset ms, min / max | 15.0 / 45.0 | 34.8 / 45.0 |
| average MEP p2p, 15–45 ms | 0.1841 mV | — |

The status counter `meanMepAmplitude = 0.193645 mV` equals the mean of the 152 per-epoch amplitudes
exactly — another internal cross-check that passes.

**The missing onsets are expected, not a fault.** An epoch with no supra-threshold deflection
reports no onset; `mep/onset_ms` is then NaN. `np.array_equal` fails on NaN ≠ NaN even when the NaN
mask and every finite value match, so that field must be compared as (mask, finite values).
`latency_ms` and `timestamps` likewise cannot match between an online and an offline run — they are
wall-clock properties of the run, not of the data.

<a id="history-56-the-two-averages"></a>

### 5.6 The two averages

Not a verification — different trials, different block, 26 vs 142 epochs — but worth recording.

| electrode | online, n = 142 | offline, n = 26 | difference |
|---|---|---|---|
| CPz | −48.80 µV @ 15 ms | −50.69 µV @ 16 ms | **−3.9 %** |
| Cz | −29.33 µV @ 15 ms | −29.88 µV @ 15 ms | **−1.8 %** |
| Pz | −46.72 µV @ 17 ms | −31.09 µV @ 17 ms | +33.5 % |
| P1 | −40.41 µV @ 17 ms | −23.62 µV @ 17 ms | +41.5 % |
| C4 | −10.55 µV @ 15 ms | −14.66 µV @ 15 ms | −39.0 % |
| C3 | −13.84 µV @ 92 ms | −19.73 µV @ 91 ms | −42.5 % |
| FCz | +23.08 µV @ 28 ms | −22.85 µV @ 100 ms | different peak wins |
| per-channel peak 15–150 ms, median | 23.29 µV | 20.32 µV | −12.8 % |

The early midline complex — the most reproducible part of a TEP — agrees to within 4 % at CPz and
2 % at Cz. Latencies match to one sample. Divergence grows with distance from the midline and with
latency, as expected from 26 vs 142 trials.

Late-window (200–300 ms) per-channel RMS: online 2.885 µV, offline 5.540 µV, ratio **1.92** against
the √(142/26) = 2.34 predicted by trial count alone — so the offline average is, if anything,
*quieter* than pure trial-count scaling predicts.

---


<a id="history-6-the-differences-classified"></a>

## 6. The differences, classified

The brief asks for each residual to be named rather than excused. There are four, and each has a
different cause.

<a id="history-61-a-single-channel-repair-difference--the-preproc-residual"></a>

### 6.1 A single-channel repair difference — the preproc residual

`max |service − reference| = 2.067e+04 µV`, which sounds alarming and is not.

* Under model −1 (epochs 1–10, no repair yet): **1.93e-03 µV over all 64 channels.**
* Under models 0, 1, 2: the difference is **entirely on channels the service repaired in that
  block**. Per channel, over all 36 epochs:

  | channel | max difference | status |
  |---|---|---|
  | FT9 | 2.067e+04 µV | repaired |
  | T7 | 427.7 µV | repaired |
  | T8 | 247.6 µV | repaired |
  | P7 | 178.7 µV | repaired |
  | F7 | 91.16 µV | repaired |
  | Fp2 | 86.82 µV | repaired during model 1 only |
  | **all other 58 channels** | **≤ 3.5e-05 µV** | — |

The reference implementation has no bad-channel repair stage. **This is a repair difference on
named channels, not an arithmetic difference.** Fp2 looks anomalous only because the epoch file
stores the *final* bad-channel report; Fp2 was in the repaired set for epochs 21–30 and out of it by
the end. Restricting to models −1, 0 and 2, every non-repaired channel agrees to ≤ 3e-05 µV.

<a id="history-62-not-reproducible-the-sound-operator"></a>

### 6.2 Not reproducible: the SOUND operator

The operator could **not** be independently re-derived, and this is a recording gap, not a
disagreement about arithmetic.

| training set fed to `osound.train_sound` | best channel | max \|diff\| vs service | relative |
|---|---|---|---|
| stored preproc 1…30 (what the reference harness assumes) | 58 | 0.9496 | 0.967 |
| stored preproc 11…30 (repaired epochs only) | 57 | 0.6422 | 0.654 |
| service's own answer | **22 (= C4)** | — | — |

The cause is visible in the sigmas: FT9's noise level comes out **1662.17 µV** when the warm-up
epochs (raw FT9, ~2.5 mV) are in the training set, **2.55 µV** when only repaired epochs are, and
the service reports **1.70 µV**. The service applies the *current* repair matrix to the whole
training block at calibration time; the epoch file stores each epoch's preproc as it was computed
at the time, and records only the final bad-channel report. **The training set the service used
cannot be reconstructed from what it writes.**

What can be said about the operator is that it is well-behaved: condition number **15.387**, sigmas
median **2.298** max **11.520**, convergence monotone
`[2.0647, 0.9950, 0.2264, 0.0949, 0.0140]`, reference channel C4, and applying it reproduces every
stored cleaned epoch to 1.3e-05 µV. Nothing about it looks wrong; it simply is not re-derivable.

**Same limitation applies to the online run**, whose 15 operators are equally unreconstructable —
though each one was recovered from the published (epochs, clean) pairs by least squares and shown to
predict the other epochs in its block to 1.3e-05 µV, so the operators were at least *stable and
consistently applied*.

<a id="history-63-an-alignment-difference--trigger-stamps-inherited-from-the-recording"></a>

### 6.3 An alignment difference — trigger stamps, inherited from the recording

Comparing the service's `timestamps` (relative to the first trigger) against the file's own bit-0
rising-edge sample indices:

* 33 of 36 triggers agree to within **20 ms**;
* trigger #10 is off by **+2137 ms** and #11 by **+763 ms**.

Those two sit in blocks whose *recorded* `created` stamps are off by **+2158.6 ms** and **+783.8 ms**
from their own sample counts. Across the whole file, 552 of 1986 blocks have a stamp error above
50 ms, ranging −198.1 to **+2592.8 ms**, while total drift over the file is only **−45.5 ms** — a
stall followed by a catch-up burst, so no samples are lost.

**Correlation between the recording's own block-stamp error and the service's trigger-time
discrepancy: 0.9992.** The service inherits the stamp; it does not create the error.

Two consequences worth writing down:

* **The epoch cut is by sample index and is exact** — epoch 1 matched the independent reference to
  9.75e-04 µV, and all 36 epochs were kept. Two service ITIs came out *below* the 500 ms refractory
  (37.5 ms and 286.0 ms) while zero file ITIs are, and yet nothing was refused — confirming the
  refractory gate runs on samples, not on stamps.
* **`timestamps` and the `epochs` stream's `created` field are good to only ±2.5 s on this rig.**
  This is why the online file's epoch stamps are non-monotonic (worst −112 ms) and why 30 of its
  151 inter-epoch gaps look shorter than the refractory that gated them. **Do not align these
  epochs to another stream by RTC.**

<a id="history-64-not-an-iir-settling-transient"></a>

### 6.4 Not an IIR settling transient

The known warm-up trap did not fire in either run.

* **Online:** armed at 16:12:15.333, first trigger at +10.103 s — exactly the recommended ≥10 s
  lead-in. No geometric decay across the first ten epochs.
* **Offline:** 145 s of data before the first pulse.

What the first ten epochs of the *online* run do show is FT9 **unrepaired** — per-epoch absmax
median 3078.5 µV for epochs 1–10 against 56.4 µV for epochs 11–152, while every other channel sits
at ~62 µV throughout — median 61.9 µV for epochs 1–10 against 59.7 µV for epochs 11–152, i.e. no
change at all. That is why the first ten are excluded from the average: no bad-channel model exists
before epoch 11, so FT9's ~3 mV artefact is uncorrected in them. It is not filter settling, and it
is by design.

The decisive test: a settling transient decays monotonically. The median-of-other-channels absmax
for online epochs 1–10 is `66.4, 64.3, 42.1, 64.4, 65.1, 65.1, 85.0, 64.1, 40.2, 40.7 µV` —
successive ratios `1.03, 1.53, 0.65, 0.99, 1.00, 0.77, 1.33, 1.60, 0.99`. **Not monotonic, no
decay, no transient.**

---


<a id="history-7-what-could-not-be-verified-and-why"></a>

## 7. What could not be verified, and why

1. **The online run's own numbers, sample by sample.** Its input was never recorded. This is not
   recoverable by any amount of analysis.
2. **The SOUND operator, in either run.** §6.2 — the training set is not recorded.
3. **Which channels were repaired in earlier blocks.** The epoch file stores only the final
   bad-channel report.
4. **That the deployed binary is byte-identical to the one the session ran.** The session ran from
   `D:/resonance_20260821/dist/msvc64` on the experiment PC, which was not reachable. The local
   binary's timestamp and behaviour are consistent with it but a hash comparison was not possible.
5. **Which physical electrode pair carried the MEP.** Nothing in either file records it. See §8.
6. **Transport latency.** `received` is 0 on every block and message of all five streams in
   `test_online_tepsound.hdf` (the raw file's blocks do carry it, median created + 3.65 ms), so
   latency cannot be recovered from that capture.

---


<a id="history-8-for-the-operator"></a>

## 8. For the operator

<a id="history-81-the-mep-pair-may-be-the-wrong-two-channels--this-can-change-a-number"></a>

### 8.1 The MEP pair may be the wrong two channels — this can change a number

tepSound was configured `MEP: channel 66 − channel 65` (1-based over the 75-channel stream) =
indices **64 and 65**, which in this rig's own metadata are the **unnamed `?? 65` / `?? 66`**
inputs. The channels the amplifier labels **`EMG1` / `EMG2` are indices 72 / 73** (1-based 73 / 74).

Measured on `12_` (36 pulses, TMS-locked average, baseline-corrected):

| pair | quiet σ (80–100 s) | average p2p 15–45 ms | per-epoch mean p2p |
|---|---|---|---|
| idx 65 − 64 (**as configured**) | 752 / 1256 µV | **0.2109 mV** | 0.3918 mV |
| idx 73 − 72 (**EMG1 / EMG2**) | 1602 / 1818 µV | **0.4013 mV** | 0.8794 mV |

The raw file's own channel metadata is unambiguous: idx 64 = `?? 65` and idx 65 = `?? 66`, both
`kind = EEG`; idx 72 = `EMG1` and idx 73 = `EMG2`, both `kind = AUX`. The configured pair is two
*unnamed EEG-kind* inputs.

Both carry EMG and both show a TMS-locked response, so the configured pair is not dead — but the
amplitudes differ by ~1.9×, and the session's `meanMepAmplitude` of 0.19364 mV came from the
configured pair. **If the electrodes were on the EMG1/EMG2 sockets, every MEP number from this
session is low by roughly a factor of two.** Nothing in the files records which pair was used.
This needs the operator, not more analysis.

<a id="history-82-the-mep-window-ends-before-the-mep-peaks--this-makes-every-mep-amplitude-too-small"></a>

### 8.2 The MEP window ends before the MEP peaks — this makes every MEP amplitude too small

`mepFrom 15`, `mepTo 45` was in force. On this subject and this muscle the MEP does not fit in it.

Measured on `12_`, 36 pulses, TMS-locked average of the **configured** pair, baseline −400…−50 ms:

| window | average p2p | peak |
|---|---|---|
| **15…45 ms (as configured)** | **0.2109 mV** | +0.2588 mV @ **45.0 ms** — the edge |
| 15…60 ms | 0.3594 mV | +0.3364 mV @ **46.3 ms** |
| 15…80 ms | 0.3594 mV | +0.3364 mV @ 46.3 ms |

**The true peak is at 46.3 ms, 1.3 ms outside the window. The configured window captures 59 % of
the peak-to-peak amplitude.**

The per-epoch onsets say the same thing. Online, of the 148 epochs that reported an onset, the
distribution is `min 15.0, p25 42.2, median 43.0, p75 43.4, p90 44.0, max 45.0` — piled against the
right edge, with 3 epochs reporting onset exactly at 45.0 ms. Offline: `min 34.8, median 43.9,
max 45.0`. A distribution that stops dead at the window edge is the window, not the physiology.

⇒ **`meanMepAmplitude = 0.19364 mV` for the session is a truncated measurement.** Widening
`mepTo` to 60–80 ms would fix it, and the epochs are all still on disk in
`tepsound_sub_cond_009.h5` if that can be recovered (§8.3), so the MEP amplitudes can be
recomputed without re-running the experiment.

⚠ This is **independent of** the channel-pair question in §8.1 and stacks with it. Taken together,
the session's MEP amplitudes could be low by a factor of roughly two to three. **The EEG/TEP side
is unaffected** — the window issue touches only the MEP channel.

<a id="history-83-please-copy-two-things-off-the-experiment-pc"></a>

### 8.3 Please copy two things off the experiment PC

* **`D:/resonance_20260821/dist/msvc64/data/tepsound_sub_cond_009.h5`** — tepSound's own epoch file
  from the session. It carries `preproc`, the cleaned epochs, the SOUND operator, sigmas,
  convergence and the bad-channel report. Far more of the session becomes checkable with it, even
  though the raw is gone.
* Anything in **`D:\2026 - feetStim\test\07TP_eeg_tms 2\`** whose annotation `wall` is between
  **16:05 and 16:18** — the D: numbers 08, 09 and 11 have not been copied. If one of them is the
  raw amplifier stream from the tepSound block, full sample-level verification becomes possible.

<a id="history-84-two-defects-observed-not-fixed-other-workflows-own-the-source-tonight"></a>

### 8.4 Two defects observed, not fixed (other workflows own the source tonight)

* **`playbackSource.exe` crashed with an access violation (0xc0000005) in `Qt5Network.dll`**
  90 s into the first replay attempt (WER 01:30:56, and three further crashes of other
  `playbackSource` instances at 01:31:54, 01:31:56 and 01:32:22, from a concurrent workflow).
  Its log also prints `QObject::startTimer: Timers can only be used with threads started with
  QThread` at startup. The crashes coincided with another workflow's services appearing and
  disappearing on the loopback discovery bus. **A service should not fault when a peer vanishes.**
  The retry on a quiet machine ran the full 271.9 s with 0 underruns.
* **A `--serviceConfig` written by PowerShell 5.1 is silently rejected.**
  `Get-Content | ConvertFrom-Json | … | ConvertTo-Json | Set-Content -Encoding utf8` produces a
  UTF-8-BOM file whose content is not the array intended, and the service logs
  `Error while reading config … at 1:5` and **carries on with defaults, armed, with no stream
  bound**. The run looks normal and measures nothing. `R:\config\tepsound_validation_run.ps1`
  builds its run config exactly this way. The config here is generated with Python instead
  (`R:\dist\_build\offline-verify\run\mkcfg.py`). ⚠ Worth checking whether earlier validation runs
  driven by that script actually loaded their configs.

<a id="history-85-one-thing-to-remember-about-this-rig"></a>

### 8.5 One thing to remember about this rig

RTC-derived instants are good to only **±2.5 s** on this amplifier (§6.3). Sample indices are
exact. Any analysis that aligns these epochs to another stream must do it by sample index.

---


<a id="history-9-artifacts"></a>

## 9. Artifacts

All in `R:\dist\_build\offline-verify\`.

**Run** — `run/verify12_config.json`, `run/mkcfg.py`, `run/replay12.ps1`, `run/stop.{qml,ps1}`,
`run/dump.{qml,ps1}`, `run/r2.svc.err.log`, `run/r2.pb.err.log`,
`run/replay12_epochs.h5` (the offline epoch file, 12.98 MB).

**Analysis** — `align_check.py`, `online_extract.py`, `online_internal.py`, `raw_triggers.py`,
`compare_triggers.py`, `trigger_detail.py`, `offline_analyse.py`, `diagnose_residual.py`,
`residual_class.py`, `residual_where.py`, `hump.py`, `mep_compare.py`, `scan_new.py`,
`make_figures.py`, `mep_window.py`, `verify_carried.py`, `shot.ps1`, with a `.txt` beside each
holding its output.

**Screenshots** (`shots/`, all `PrintWindow(hwnd, dc, 2)`) —
`01_settings_armed.png`, `02_runbar_end_0.png`, `03_after_stop_0.png`,
`04_average_online_vs_offline.png`, `05_counters.png`, `06_runbar_beside_counters.png`,
`07_head_array.png`, `08_butterfly.png`, `09_mep_average.png`, `10_badness.png`.

**Cached arrays** — `my_online_{epochs,clean,avg}.npy`, `offline_{clean,preproc,avg,operator}.npy`,
`ref_preproc.npy`, `raw12_rise_{samples,seconds}.npy`, `offline_params.txt`, `my_events.txt`.
