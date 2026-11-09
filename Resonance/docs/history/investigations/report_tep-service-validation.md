# tepService — validation report — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/tepsound.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-tepservice--validation-report"></a>


**Run 2026-08-16, and §3 re-run 2026-08-18.** What was tested, how, and what came out. The module
is described in [tep-service.md](../components/tep.md); how to operate it is
[Tep-Operator-Guide.md](../../operators/legacy-tep.md).

**The headline:** every epoch the service produced from two real TMS-EEG recordings matches an
independent SciPy implementation of the same pipeline **to the precision the epoch file stores** —
**155 of 155 stimuli, 20,460,000 values, none lost**, with the worst deviation an order below the
float32 resolution of the signal and **exactly one value differing by one float32 ULP** (0.93 nV
at 18.09 mV). §3.2.

⚠ **§3 was regenerated on 2026-08-18 and the earlier figures no longer describe this build.** The
display band limit moved out of the per-epoch stage and into the continuous cascade
([tep-service.md §2.1](../components/tep.md)), so the epochs the service writes now carry it and the
2026-08-16 comparison was measuring an arrangement that had ceased to exist. It is regenerated
against the current one, with two controls, and the headline above is restored rather than
inherited. §3.5 is what the earlier numbers still mean.

⚠ **No amplifier and no stimulator were involved.** Everything below was driven by
`playbackService` replaying recorded sessions. §7 says what that does and does not establish.

---


<a id="history-1-what-was-under-test"></a>

## 1. What was under test

| | |
|---|---|
| Binary | `R:\dist\msvc64\bin\tepService.exe`, MSVC v142 x64, built 2026-08-16; **§3 re-run against the 2026-08-18 03:31 build** |
| Source | `R:\src\tepService` |
| Material | `N:\Projects_MSU\2025 - TEP\data - raw\tests\30 test Timofey sync phases\` — seven recordings, 67 channels at 25 kHz, 392–418 s each, 5.2–5.6 GB each. **Two were replayed in full**: `01_TP_M1_60MSO_single_REAL` (75 stimuli) and `06_TP_SMA_67MSO_SST_REAL` (80, in two conditions) |
| Settings | the defaults, which are the deployed rig's `TEP_visual_settings.json` SPEED block: window −100…300 ms, epoch rate 5000 Hz, artifact −5…+15 ms, continuous lowpass 2500 Hz, no highpass, no notch |

The recordings carry 64 EEG electrodes, an EMG pair, and the NVX trigger word. The TMS pulse is
bit 0 of that word; the word idles at `0xFFE6` because the input's low byte floats and the
mirrored output sits in the high byte, so it is never zero and only one bit is the stimulus.

---


<a id="history-2-unit-tests--test_teppipeline-47-of-47"></a>

## 2. Unit tests — `test_TepPipeline`, 47 of 47

Every expected value was produced by SciPy on the same input and pasted in at full precision.

| Suite | Cases | What it fixes in place |
|---|---|---|
| `Dsp` | 12 | Butterworth-2 lowpass and highpass coefficients at three cutoffs; notch coefficients; `sosfilt` output; state carried across block boundaries; channel independence; `uniform_filter1d`; `median_filter`; `percentile`; TKEO |
| `Pipeline` | 10 | window geometry; the epoch cut **exactly** at the trigger sample; decimation is subsampling; one bit is read and the rest of the word ignored; the resting level is adopted rather than assumed low; the refractory period; a window that opens before the stream did; both artifact spans; artifact interpolation is a straight line; **the result is independent of the transport block size** |
| `EpochProcessor` | 11 | baseline as mean and as median; CAR excluding named electrodes and with an empty exclusion list; re-reference from one electrode and from several averaged together; MEP is B − A; peak-to-peak inside the window and not outside it; slow-trend removal keeps a short response; the display lowpass matches SciPy per channel; the volt→µV/mV scaling |
| `EpochStoreAccumulator` | 7 | the cached running total is **bit-identical** to a full reduction through arrival, NaN runs, eviction, reject/un-reject, removal and reprocessing; the median still goes through the full reduction |
| `EpochStoreAddressing` | 2 | every public `number` is a **serial**, not a ring position; reject and remove take serials too |
| `DisplayLowpass` | 5 | the design differs at the input and decimated rates, and **matches SciPy at 250 Hz / 25 kHz**; a strided filter leaves the trailing channels untouched; the strided form equals the plain form at full width; a stride narrower than the filter does nothing |

The block-size test is the one worth calling out: the same 2000 stimulus is delivered at 1, 7,
64, 333 and 1024 samples per transport block, with the artifact stage and the filters live, and
every epoch comes out identical to within 1e-9. The NVX validation measured real block sizes
between 20 and 2500 for a requested 2500, so this is not a hypothetical.

⚠ **`DisplayLowpass.DesignAtTheRigsInputRateMatchesScipy` was added 2026-08-18 to close a real
gap.** The suite pinned 250 Hz at 5 kHz — the rate of the per-epoch placement the filter came
from — and 2500 Hz at 25 kHz, but after the move the display filter ran at 250 Hz / 25 kHz, which
nothing held down: the one test naming that operating point asserted only that it *differed* from
the decimated-rate design, and every wrong answer also differs. `tep_reference_pipeline.py` builds
the same design from the same specification, so an error would have been a **shared** one and §3
would have reported agreement while both implementations were wrong.

---


<a id="history-3-end-to-end--the-pipeline-against-scipy"></a>

## 3. End to end — the pipeline against SciPy

<a id="history-31-method"></a>

### 3.1 Method

1. `playbackSource.exe --file 01_TP_M1_60MSO_single_REAL.hdf5 --serviceName TEPREF --autoStart`
   replays the recording as a live `TEPREF`/`eeg` stream at 1× — 9,798,761 samples over 391.9 s.
2. `tepService.exe --signal TEPREF/eeg --montage mumeg_mks64.ced --autoStart` collects.
3. On `stop`, the service writes its epoch file.
4. `tep_reference_pipeline.py` — an independent NumPy/SciPy implementation written from the
   *specification*, not from the C++ — reads the **original** HDF5 and computes the same epochs:
   trigger edges on the raw word, artifact interpolation with `ndimage.uniform_filter1d`,
   `signal.butter` + `signal.sosfilt` over the continuous signal, **the display band limit over
   the leading 64 columns**, the window cut, `[::5]`.
5. The two are compared value by value.

The reference is a separate program with separate arithmetic; agreement is therefore evidence
rather than a shared bug. ⚠ **Except where both are written from the same specification** — the
filter *designs* are, so agreement between them says nothing about whether the design is right.
That is what §2's SciPy coefficient tests are for, and why the missing one had to be added before
this section meant anything.

⚠ The 2026-08-16 runs spoofed the playback as `NVX136`; the 2026-08-18 runs use `TEPREF`, so that
a replay cannot be mistaken for the operator's own amplifier by anything else on this machine. The
name reaches nothing the comparison depends on.

**The launch order is the part that matters**, and getting it wrong is what run 1 in §3.6 is. The
service has to be collecting before the replay starts, or it misses the opening stimuli and a
naive position-by-position comparison measures its own bookkeeping.
[`R:\config\tep_validation_run.ps1`](../../../tools/qa/tep_validation_run.ps1) is that sequence, so the
run can be repeated without reassembling it: it stages `env.bat` inline, starts the service, waits,
starts the replay with the raw path **quoted** (`Start-Process` does not quote `ArgumentList`
entries and these paths contain spaces), then runs the harness and reports.

⚠ **The comparison reads `h5["epochs"]`, which is the raw continuous output — before
`EpochProcessor`.** That is why the display band limit did not appear in it until 2026-08-18 and
does now: it used to be the first step of the per-epoch stage, which this file never sees, and it
is now the last step of the continuous one, which is exactly what this file is.

<a id="history-32-result--2026-08-18-the-current-arrangement"></a>

### 3.2 Result — 2026-08-18, the current arrangement

Both recordings replayed into the 2026-08-18 build, with the display band limit modelled in the
reference. Run 5 is the same recording as run 2, run 6 the same as run 3.

| | Run 5 — `01_TP_M1_60MSO_single` | Run 6 — `06_TP_SMA_67MSO_SST` |
|---|---|---|
| Triggers in the file | 75 | 80 |
| **Epochs the service produced / lost** | **75 / 0** | **80 / 0** |
| Alignment against the reference | **offset 0** | **offset 0** |
| Values compared | **9,900,000** | **10,560,000** |
| **Max absolute difference** | **3.7253e-09 V** | **1.1748e-08 V** |
| Mean absolute difference | 4.952e-10 V | 8.451e-10 V |
| Max relative difference | 5.957e-08 | 5.958e-08 |
| float32 resolution of this signal | 8.891e-09 V | 4.842e-08 V |
| **Values differing after rounding to float32** | **0 of 9,900,000** | **1 of 10,560,000** |
| Worst ULP distance | 0 | **1** |
| Worst channel / worst epoch | 51 / 56 | 24 / 0 |
| Playback | 391.9/391.9 s, 5070 blocks, late 0.48 ms mean / 2.39 ms max, **0 underruns** | 417.7/417.7 s, 5407 blocks, late 0.45 ms mean / 1.77 ms max, **0 underruns** |

**Together: 155 epochs, 20,460,000 values, one of them differing — by one float32 ULP.**

⚠ **That one value is worth being precise about, because the boolean is a knife edge.** It is
0.93 nV out at a sample of 18.09 mV — a value that lands almost exactly on a float32 rounding
boundary, where a float64 disagreement of well under half a spacing still rounds the two ways.
Run 3 reported "bit-identical: yes" at the *same* 1.1748e-08 V float64 deviation on the same
recording; nothing about the agreement changed, only which side of a boundary one sample fell.
The comparison now reports the mismatch **count** and the worst **ULP distance** alongside the
boolean, so a future run cannot read a flipped flag as a regression. Control B below is what a
real difference looks like: 9,599,422 values and 1,080,876 ULP.

Evidence: `run05_epochs.h5`, `run05_compare.json`, `run06_sst_epochs.h5`, `run06_sst_compare.json`
and the two `*_reference.npz`, in
`R:\tests\2026-08-18_build_network-isolation\tep-scipy-revalidation\`.

<a id="history-33-the-two-controls"></a>

### 3.3 The two controls

A single agreement number cannot distinguish "the reference models the pipeline" from "the
reference and the pipeline both skip the same stage". Two controls separate them.

**Control A — the rewrite is inert with the new stage off.** The edited script, run with
`--no-display-lowpass` against the **archived** `run02_epochs.h5` (the 2026-08-16 binary, the old
arrangement), reproduces `run02_compare.json` to the last digit:

| | 2026-08-16 `run02_compare.json` | 2026-08-18 rerun |
|---|---|---|
| Max absolute difference | 3.7252452789182655e-09 | **3.7252452789182655e-09** |
| Mean absolute difference | 4.949505691674788e-10 | **4.949505691674788e-10** |
| Max relative difference | 5.9584249432448095e-08 | **5.9584249432448095e-08** |
| Worst epoch | 13 | **13** |
| Values differing after float32 | 0 | **0 of 9,900,000** |

Every shared field agrees to the last digit, over a full recomputation — no cached reference — so
nothing about modelling the new stage disturbed the path that was already right. Evidence:
`control_nodisplay_compare.json`.

**Control B — the comparison is sensitive to the filter, and the filter reaches only the EEG.**
The *new* epochs compared against a reference **without** the display stage:

| | |
|---|---|
| Max absolute difference, **EEG columns 1–64** | **2.1486e-04 V** — 24,000× the float32 resolution |
| Max absolute difference, **EMG columns 65–66** | **9.3132e-10 V** — the float32 floor, i.e. untouched |
| Values differing after float32 | **9,599,422 of 9,900,000 — 97 %** |
| Worst ULP distance | **1,080,876** |

This is the decisive one. It says the display band limit is genuinely present in what the service
now writes — so §3.2's agreement is not two implementations agreeing to skip a stage — and that it
is confined to the EEG. The EMG pair is measured out to 450 Hz by `extractMep()`; had the filter
reached it, the second row would be of the same order as the first and every MEP number in this
report would have moved. Evidence: `run05_negative_control.json`.

<a id="history-34-cost-re-measured"></a>

### 3.4 Cost, re-measured

From the OS's own process accounting, over the same recording as §6b's run 2:

| | CPU | of one core |
|---|---|---|
| 2026-08-16 (§6b, run 2) | 125 s / 392 s | **34 %** |
| **2026-08-18 (run 5)** | **22.6 s / 507 s** | **4.5 %** |

Working set at the end of the run: **336 MB** for 75 epochs of 66 × 2000, with `epochBuffer` 500.
⚠ Caching the processed form beside the raw one roughly doubles per-epoch cost, so a session that
actually fills a 500-epoch buffer settles near 1 GB; lower `epochBuffer` if that matters more than
the averaging speed.

<a id="history-35-what-the-2026-08-16-numbers-still-mean"></a>

### 3.5 What the 2026-08-16 numbers still mean

They are not wrong, they are about a different pipeline. Runs 1–3 measured a build whose display
band limit sat in the per-epoch stage, where `h5["epochs"]` could not see it; the continuous
cascade they *did* measure — trigger detection, artifact interpolation, highpass/notch/lowpass,
the cut and the decimation — is unchanged and Control A re-derives it bit for bit. What they do
not establish is anything about the stage that moved.

<a id="history-36-the-original-result-2026-08-16"></a>

### 3.6 The original result, 2026-08-16

| | Run 1 | Run 2 |
|---|---|---|
| Service started | *after* the playback — the first 3 stimuli were missed | before the playback |
| Epochs the service produced | 72 | **75** |
| Triggers in the file | 75 | 75 |
| Alignment against the reference | offset 3 | **offset 0** — every trigger accounted for |
| Values compared | 9,504,000 | **9,900,000** |
| **Max absolute difference** | 3.7252e-09 V | **3.7252e-09 V** |
| Mean absolute difference | 4.95e-10 V | 4.95e-10 V |
| Max relative difference | 5.96e-08 | 5.96e-08 |
| float32 resolution of this signal | 8.90e-09 V | 8.90e-09 V |
| **Bit-identical after rounding to float32** | **yes** | **yes** |

The maximum deviation is *below* the resolution of the format the epoch file stores, so once the
reference is rounded to float32 the two arrays are equal element for element. There is no residual
difference to explain.

Run 1 is kept in the table because it is the interesting negative control: comparing the two
naively, position by position, gave a mean difference of 47 µV and a maximum of 1 mV. Nothing was
wrong — the service had simply started 15 seconds into the playback and missed three stimuli, so
epoch *n* was being compared against stimulus *n+3*. **A comparison that does not align on content
first measures its own bookkeeping.**

<a id="history-37-the-counters-run-2"></a>

### 3.7 The counters, run 2

| | |
|---|---|
| Triggers seen | 75 |
| Epochs produced | 75 |
| Lost (`starved` + `refused`) | **0** |
| Windows that opened before the stream did | 0 |
| Artifact spans skipped | 0 |
| Playback's own report | 5070 blocks, 391.9/391.9 s, lateness **0.42 ms mean / 1.49 ms max, 0 underruns** |

---


<a id="history-4-as-a-resonance-service"></a>

## 4. As a Resonance service

<a id="history-41-the-published-streams-taken-by-recorderservice"></a>

### 4.1 The published streams, taken by `recorderService`

`recorderService` was configured over the EventBus — one parameter at a time, per
[known-issues §16b](../incidents/README.md) — to record the TEP service's own `epochs` and `events`
streams, mid-session, for 90 seconds. Harness:
[`R:\config\tep_record_harness.qml`](../../../tools/qa/tep_record_harness.qml).

The resulting file, kept as `run02_recorded_streams.h5`:

| | |
|---|---|
| `epochs/data` | 34,000 rows × **66 channels**, float64 |
| `epochs/blocks` | **17 blocks, every one exactly 2000 samples** — one block is one epoch |
| `epochs/streamInfo` | `Float64`, `channels = 66`, `samplingRate = 5000` |
| `events/messages` | **17 records**, one per epoch, `n` running 49…65 without a gap |
| Epoch spacing | 5 s, matching the recording's stimulus interval |

An event record, as recorded:

```json
{"artifact":true,"channels":66,"n":50,"rejected":false,"samples":2000,"v":1,
 "mep":{"amplitudeMv":0.1395,"areaMvMs":0.5942,"baselineRmsMv":0.004430,
        "onsetMs":18.4,"peakMs":26.4,"troughMs":31}}
```

So the epochs and their measurements are on the wire, in step, and an ordinary Resonance consumer
takes both.

⚠ `epochs/data` has **34,001** rows for 34,000 recorded samples. The graduation file the playback
module validated against has the same one-row overhang (9,798,761 rows for 9,798,760 samples), so
this is `HDFRecorder`'s behaviour and not this module's. Worth chasing separately.

⚠ **A `ResonanceForeignDriver`-based Python consumer could not attach to any of the four streams**
— by name or otherwise — while `recorderService` attached to two of them at the same moment. This
is the client-path defect already recorded in STATUS.md ([change history](../changes/README.md)) for another service; it is not
specific to this one.

<a id="history-42-the-parameter-set"></a>

### 4.2 The parameter set

Driven with [`R:\config\tep_params_check.qml`](../../../tools/qa/tep_params_check.qml), which reads the
published description *and* instantiates the Configurator's own `ParametersView` against the live
service — so every parameter's editor is actually created.

| | |
|---|---|
| Parameters | **60** |
| Groups | `input` 11, `epoch` 8, `filter` 7, `processing` 10, `average` 6, `mep` 7, `session` 10, `window` 1 |
| Every name a stable ASCII key | ✅ |
| Every one carrying a group and an index | ✅ |
| Properly typed (not `String`) | **53 of 60** |
| Carrying a tooltip | **42 of 60** |
| `ParametersView` renders it | ✅ **8 tabs, in the service's own order**, `input` first |
| Result | **PASS** |

⚠ The screenshot this paragraph referenced (`04-parameters-view.png`) is not in `figures/tep/` and
was already missing before the 2026-08-18 reorganisation — the numbering runs 00–03, 05. The
measurement above stands on the harness output, not on the picture.

The remaining seven `String` parameters are the ones that genuinely are text — subject, condition,
operator, file name, montage path, and the two channel lists.

⚠ Rendering any service through `ParametersView` prints
`TwoWayBinding.js:17: TypeError: Cannot read property 'serialized' of undefined` — 11 times for
this service's 60 parameters. **It is not specific to this module**: the same harness pointed at
`recorderService` prints it twice for its 10 parameters. A pre-existing defect in the shipped QML,
recorded here because it will be seen.

<a id="history-43-discovery-and-the-configurator"></a>

### 4.3 Discovery and the Configurator

The Configurator, with TEP discovered beside the playback and the recorder (historical reference unavailable: `figures/tep/03-configurator.png`)

The Configurator finds `TEP` alongside `NVX136` (the playback) and `Recorder`, and its parameter
panel is §4.2.

---


<a id="history-5-the-console"></a>

## 5. The console

<a id="history-51-a-session-in-progress"></a>

### 5.1 A session in progress

70 epochs collected from the replayed recording, default settings.

The console mid-session (historical reference unavailable: `figures/tep/01-console-session.png`)

Everything in that picture is live: the scalp grid at each electrode's own position from the
`.ced` montage, the butterfly of all 64, the averaged MEP with its standard-deviation band, the
last five single trials, and the per-epoch table with amplitude, onset and pre-stimulus RMS.

**The warning strip is doing its job.** *"The MEP window opens at 10 ms, inside the interpolated
artifact span"* is true of the settings the rig actually ships: the artifact is interpolated to
+15 ms and the MEP is measured from +10 ms, so the first 5 ms of the response window is a straight
line the program drew. Nothing in the legacy said so.

<a id="history-52-a-processing-change-redraws-the-whole-session"></a>

### 5.2 A processing change redraws the whole session

The same 75 epochs, after `car` was set to `true` **over the EventBus** — not in the window:

The same session with the common average reference on (historical reference unavailable: `figures/tep/02-console-car.png`)

Two things this establishes:

1. **The epochs are kept raw and re-derived, not stored processed.** One parameter written from
   another process redrew all 75 epochs, the average and every plot. That is the property that
   lets an operator try a setting instead of committing to it before the session.
2. **The slow decay dominating the default view is common-mode.** It vanishes under a common
   average reference and the TEP waveforms appear underneath it — which identifies it as the TMS
   recharge artifact shared across electrodes, not as anything this module does to the signal.
   With no highpass filter in the default configuration, it is genuinely in the data.

---


<a id="history-6-condition-labels-from-a-marker-stream"></a>

## 6. Condition labels from a marker stream

The `06_TP_SMA_67MSO_SST_REAL` recording is a stop-signal task: 60 `animatedSingle1500_tms_0ms`
trials and 20 `animatedSingle1500_stop-200ms_tms_0ms` trials, delivered over 417.7 s. Replaying it
publishes both `eeg` and the original `stimuli` message stream, and the service was started with

```
tepService.exe --signal NVX136/eeg --markers NVX136/stimuli --montage …
```

so each epoch takes the label of the last stimulus message before its trigger.

| | |
|---|---|
| Duration | 417.7 s replayed at 1× |
| Stimulus messages in the recording | 80 |
| **Triggers seen / epochs produced / lost** | **80 / 80 / 0** |
| Epochs carrying a condition label | **80 of 80** |
| MEP amplitude | median 0.228 mV, range 0.042…1.199 mV |
| Playback | 5407 blocks, lateness 0.42 ms mean / 1.57 ms max, 0 underruns |

**And the same numeric check, on a second recording** (run 3, 2026-08-16 arrangement; §3.2 is the
current one):

| | |
|---|---|
| Values compared against the SciPy reference | **10,560,000** |
| Alignment offset | **0** |
| Max absolute difference | **1.175e-08 V**, against a float32 resolution of 4.842e-08 V |
| **Bit-identical after rounding to float32** | **yes** |

Two independent recordings, **155 epochs and 20,460,000 values**, every one of them matching.

⚠ The **80/80, 0 lost** and the label results in this section were measured on the 2026-08-16
build. The epoch count was re-established on the 2026-08-18 build in §3.2 (run 6, same recording);
the **condition labels were not** — run 6 was launched without `--markers`, so it exercises the
epoch path and says nothing new about labelling.

The `label` column carries the marker's text **verbatim** — here the whole JSON object the
stimulus program published. That is deliberate: the service does not know the schema of somebody
else's marker stream and guessing at one would silently mislabel a session. It is also cramped in
a narrow column, and shortening it sensibly is a thing to do once a rig's marker format is
agreed.

**The labels reach the epoch file.** A separate 80-second run of the same recording, saved and
reopened:

```
datasets: ['epochs', 'labels', 'mep', 'timestamps']
labels:   16, one per epoch
  11  {"stimulus": "animatedSingle1500_tms_0ms_nosounds.mkv"}
   5  {"stimulus": "animatedSingle1500_stop-200ms_tms_0ms_nosounds.mkv"}
```

Both conditions of the stop-signal task, in the proportion the protocol delivers them, in the same
file as the epochs they belong to. The legacy analysis kept trial order in a separate JSON and
`labels_for_epochs` contains code for "the sequence is one longer than the epochs, drop the first"
and "it is a different length, use the first N" — guesses that are not needed when the label
travels with the epoch.

---


<a id="history-6a-the-epoch-file-read-by-the-legacy-analysis--unmodified"></a>

## 6a. The epoch file, read by the legacy analysis — unmodified

`logic/mep_movement_detection.py` and `logic/mep_condition_analysis.py` are the lab's offline
scripts. They were run against `run02_epochs.h5` with **no edits at all**:

```
load_saved_epoch_file:   epochs (75, 66, 2000)   Fs 5000.0   time -100.0 .. 299.8 ms, 2000 points
prepare_emg_epochs:      emg (75, 2000), range -0.658 .. 0.679 mV
analyze_epoch_file:      75 epochs analysed
```

Shape, sampling rate, time base and the EMG extraction all resolve. The file is the same file.

⚠ **But the detector flags "movement" in 75 of 75 epochs, at −100.0 ms — the first sample.** That
is not the new file: it is a defect in the legacy analysis that the file makes visible.

`prepare_emg_epochs` band-passes **each epoch from zero initial state**, and the epochs carry a
DC offset (the EMG difference sits at −0.36…−0.50 mV, because the amplifier's inputs are
DC-coupled and neither pipeline high-passes by default). A step of that size into a 10–450 Hz
Butterworth produces a transient at the start of every epoch:

| | |
|---|---|
| Largest excursion in the first 20 samples, as the legacy filters it | **0.415 mV** |
| Largest excursion in the middle of the epoch — where the response is | 0.099 mV |
| Movement detected | **75 of 75**, median onset −100.0 ms |
| The same filter and the same detector, with the DC removed first | first 20 samples **0.004 mV**; **26 of 75** detected, median onset 197.5 ms |

So the startup transient is four times the largest real deflection, and the detector's valid
region includes everything before −8 ms, so it finds the transient first, every time. The legacy
pipeline's own epochs have the same offset — nothing about this is new — which means the number
this analysis has been producing is the artifact of a filter, not a measurement of a subject.

**The lab already knew the fix and did not apply it.** `R:\dist_legacy\TEP_visualization\notes`
reads, in full:

> Для ЭМГ: highpass 1 Hz — must have

and the shipped `SPEED_settings.json` has `"highpass": false`. Switching the continuous highpass
on at 1 Hz — the `preHighpass` parameter — removes the offset before the epoch is ever cut, and is
the recommendation this validation ends with.

---


<a id="history-6c-the-console-rework-2026-08-16"></a>

## 6c. The console rework, 2026-08-16

Ten changes from operator feedback on the first build. What could be checked without a mouse was;
what could not is named at the end.

| | Checked how | Result |
|---|---|---|
| Columns swapped — trials under the scalp grid, the three time courses in one column | screenshot | ✅ |
| Every divider movable, columns **and** rows | `SplitView` in both orientations, loads clean | ✅ renders; not dragged |
| CAR's legacy inside-out mode removed; CAR and re-reference are both "checkbox + channel list" | 2 new unit tests: an empty exclusion list averages everything; a three-electrode reference is averaged before subtraction | ✅ **33/33 as the suite stood then**; §2 is the current count |
| Tooltips moved to the row's label, fixed width, wrapping | screenshot | ✅ |
| Positive `Window from` accepted, and **not** warned about | `windowStart = +20`, `windowEnd = 50` over the EventBus | ✅ 150-sample epochs, no warning about the ordering |
| **The axis follows the content, not the request** | the epoch was shrunk to 20…50 ms while both TEP plots were asking for −10…100 ms | ✅ both axes relabelled to **20…50 ms** — before this the axis moved and the traces did not |
| Warnings and errors clear the instant their cause does | errors are keyed by cause, not latched | ✅ by construction; the montage message no longer outlives a mistyped path |
| MEP x-range controls; the last tick on each axis carries the unit | screenshot | ✅ `… 20 40 ms` |
| Single trials: ▼▲ at the measured peaks, the value beside each, threshold colouring | threshold driven to 0, to 5.0, and to 0.05 over the EventBus | ✅ at 0.05, trials of 0.204/0.132/0.451 mV drew strong and 0.022/0.029 mV drew plain |
| Multi-select with click / Ctrl / Shift / `Ctrl+A` / `Esc` | the selection *model* was driven by toggling `averaging` off, which selects the newest | ⚠ **the modifiers themselves are unexercised** — see below |

The epoch narrowed to 20…50 ms, with both plots asking for a wider range (historical reference unavailable: `figures/tep/05-console-clamped.png`)

⚠ **The mouse has not been used.** Every action in this report is a command line, a state
transition or an EventBus parameter write, because the desktop-automation grant for this session
was declined. The selection *pipeline* — selection → `averageOf` → the plots and the table's
highlight — is exercised end to end (the "epoch 50" screenshot shows the row highlighted and the
plot at `n = 1`); what is not exercised is Ctrl-click, Shift-click and `Ctrl+A` themselves.

One defect the rework's own checks found: **`in average` counted unrejected epochs rather than
contributing ones**, so after a window change the run bar read "in average 41" over a plot reading
"n = 3". It now reports what is actually in the average, and `status` gained a `contributing`
channel beside `accepted` so the two are distinguishable on the wire.

---


<a id="history-6b-cost"></a>

## 6b. Cost

Measured from the OS's own process accounting, on this machine, against a 67-channel 25 kHz
stream — 1.675 M samples a second, 13.4 MB/s off the wire:

| | |
|---|---|
| Run 2 (75 epochs over 392 s) | **125 s of CPU — 34 % of one core** |
| Run 3 (80 epochs over 418 s + 60 s idle) | **211 s of CPU — 44 % of one core** |
| **Run 5 (75 epochs, same recording as run 2), 2026-08-18** | **22.6 s of CPU — 4.5 % of one core** |

The difference between runs 2 and 3 was not noise: `EpochStore::average()` reprocessed every
contributing epoch whenever the average was invalidated, and the average is invalidated by each
new epoch. With `Average all` set that cost grew linearly with the session — 80 epochs of
66 channels × 2000 samples is 10.6 M samples of filtering per stimulus, so the longer run cost
more per second.

**Fixed 2026-08-18, in three parts**, and run 5 is the same recording as run 2 so the 34 % → 4.5 %
is directly comparable:

| | CPU |
|---|---|
| as measured in run 2 | ~99 % of one core at peak, all of it on the GUI thread |
| the continuous stage moved to a worker thread | 72 % |
| views repaint on a dirty flag rather than unconditionally at 10 Hz | 17 % |
| processed epochs cached and the total extended per arrival | **6 %** |

⚠ **None of that changed what is kept raw.** The store still holds raw epochs and still re-derives
the session when a processing setting changes (§5.2) — the cache is invalidated by exactly that
event. What was removed is re-deriving it when *nothing* changed.

⚠ **Memory is the price**: caching the processed form roughly doubles per-epoch cost, ~1.6 MB
against ~0.6 MB. Run 5's working set was **336 MB** for 75 epochs; a session that fills the rig's
500-epoch buffer settles near 1 GB.

---


<a id="history-7-what-this-does-and-does-not-establish"></a>

## 7. What this does and does not establish

**Established.** The pipeline computes what it says it computes, to the last bit the file can
hold, on real 25 kHz TMS-EEG data with real artifacts — not on a synthetic signal. The service
runs for the length of a session without losing an epoch, publishes streams an ordinary consumer
records, exposes a parameter set the Configurator renders, and re-derives a whole session from one
remote parameter write.

**Also established by the 2026-08-18 re-run**, and worth separating because it was open:

* **The threading change loses no epochs.** The continuous stage moved to a worker thread on
  2026-08-18 and the epoch count after it had only indirect evidence. Run 5 is **75 triggers →
  75 epochs → 0 lost**, against a recording whose trigger count is known independently, on the
  threaded build. That closes it without a synthetic harness.
* **The display band limit is where the module says it is, and covers what it says it covers.**
  §3.3 Control B, not inference.

⚠ **One thing the re-run showed that is easy to misread.** The harness counts blocks on
`epochs@TEP` and reported **72** while the epoch file held **75**: a consumer that attaches to the
stream a few seconds after collection starts misses the epochs published before it arrived. The
stream count is a lower bound on what the session collected, not a measure of it. Read the file, or
the service's own counters.

**Not established.**

* **No amplifier.** A playback delivers blocks on a schedule; a driver delivers them when USB
  does. Nothing here says how the service behaves across a driver restart, a mode switch, or a
  block-size change mid-session.
* **No stimulator, and no photodiode.** Every timing figure here is the *recording's* own clock.
  The absolute latency from a TMS pulse to the sample it lands on is a property of the rig, and
  measuring it needs hardware.
* **The `Epochs` input mode has not been driven by SPEED.** It is the parity path for a rig still
  running the old configuration, and only the code path has been exercised.
* **The console has not been operated by a person, and no mouse has touched it.** Every action in
  this report was a command line, a state transition or an EventBus parameter write — which is
  the stricter path for the *service* — but nobody has clicked a button, dragged a divider,
  Ctrl-clicked an epoch or right-clicked one to reject it. The desktop-automation grant was
  declined for this session, so none of that could be scripted either. §6c says which of the
  console changes that leaves unproven.
* **`mingw32` / `mingw64` have not compiled this module.**
* **The `average` stream was not recorded**, only `epochs` and `events`.

---


<a id="history-8-artifacts"></a>

## 8. Artifacts

Moved 2026-08-18 out of the distribution trees and into **`R:\tests\`**, organised by the build
that produced them — a distribution should not carry a gigabyte of results. Manifest:
[`R:\tests\`README.md`](../../../tests/README.md).

**2026-08-18 — §3.2 to §3.4** (`R:\tests\2026-08-18_build_network-isolation\tep-scipy-revalidation\`)

| File | |
|---|---|
| `run05_epochs.h5` | **75 epochs**, the current-arrangement comparison |
| `run05_reference.npz` | the SciPy reference **with** the display stage |
| `run05_compare.json` | §3.2 |
| `control_nodisplay_reference.npz` | the SciPy reference **without** it — serves both controls |
| `control_nodisplay_compare.json` | Control A: the archived `run02_epochs.h5` re-derived to the last digit |
| `run05_negative_control.json` | Control B: the new epochs against the no-display reference |
| `run06_sst_epochs.h5`, `run06_sst_compare.json` | **80 epochs**, the stop-signal recording |
| `run0*_harness.log`, `run0*_playback.err.log` | the live logs, including the playback's own lateness and underrun report |

**2026-08-16 — §3.6 onward** (`R:\tests\2026-08-16_build_tepservice\tep-scipy-validation\`)

| File | |
|---|---|
| `run01_epochs.h5` | 72 epochs, run 1 (service started late) |
| `run02_epochs.h5` | **75 epochs, run 2** — and the input to Control A |
| `run02_recorded_streams.h5` | what `recorderService` recorded from `epochs` and `events` |
| `run03_sst_epochs.h5` | **80 epochs, the stop-signal recording**, with condition labels |
| `run04_labels.h5` | the 16-epoch run that checked the labels reach the file |
| `run01_reference.npz`, `run03_reference.npz` | the SciPy reference epochs for both recordings, old arrangement |
| `run01_compare.json`, `run02_compare.json`, `run03_compare.json` | the comparison output quoted in §3.6 and §6 |

| Harness | |
|---|---|
| `R:\config\tep_reference_pipeline.py` | the independent NumPy/SciPy pipeline and the comparison. `--no-display-lowpass` reproduces the pre-2026-08-18 arrangement; `--params` overrides any setting; the output JSON now records the settings it ran under |
| `R:\config\tep_validation_run.ps1` | one end-to-end run — service, replay, harness, in the order §3.1 requires |
| `R:\config\tep_reference_rerun.qml` | the harness it drives: pins the epoch path, reports the settings the epochs were made under, waits for the replay to run dry, stops |
| `R:\config\tep_record_harness.qml` | configures `recorderService` onto this service's streams |
| `R:\config\tep_params_check.qml` | the parameter-shape check, and `ParametersView` against the live service |
| `R:\config\tep_settings_harness.qml` | drives settings over the EventBus, for §5.2 |

The distribution's `data\` folder was left as it was found: the epoch files above were moved out
of it, because a distribution root holds launchers, `bin\`, `qt\` and `data\` and `data\` is for
recordings, not for evidence.
