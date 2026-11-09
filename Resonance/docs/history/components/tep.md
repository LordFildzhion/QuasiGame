# tepService — online TEP/MEP analysis, and the pipeline it is built on — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/tep.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-tepservice--online-tepmep-analysis-and-the-pipeline-it-is-built-on"></a>


**Written 2026-08-16.** Reference for `R:\src_Qt5\tepService` — the module that replaces
`R:\dist_legacy\TEP_visualization` (a PyQt application) together with the `SPEED` Python script
it depended on (`mulines.TEPs_plot.pipeline_tep`).

> ## Retired: `tepSoundService` is the active replacement
>
> **2026-09-04.** This Qt 5 application is retained only as a historical comparator. It will not
> be ported. `R:\dist` — the default distribution — holds neither `tepService.bat` nor
> `bin\tepService.exe`; the module's
> sources are in `R:\src_Qt5\tepService` and are registered by `add_subdirectory(tepService)` at
> `R:\src_Qt5\CMakeLists.txt:118`. To run it: **`R:\dist_Qt5\msvc64\tepService.bat`**. Why it did
> not cross and what porting it would cost — half a day, nothing blocking —
> [`arch_qt5-still-needed.md` §3.2](../migrations/qt5-still-needed.md).
>
> **§2, the pipeline, is not affected by any of that.** 1 917 of the module's C++ lines — `dsp`,
> `pipeline`, `epochprocessor`, `signalworker` — were copied byte-identically into
> `R:\src\tepSoundService\shared\tepService\` and compile under Qt 6.11 there today, verified by
> `md5sum` against `R:\src_Qt5\tepService\`. So §2 describes arithmetic that runs in the default
> distribution even though the module it was written for does not.
>
> **`tepSoundService` in `R:\dist` covers most of what §1–§4 describe** — `soundEnable` off makes
> it "an ordinary online TEP/MEP analyser", and its 136 parameters cover this module's 60 in every
> functional area. **Three things do not carry over, and each of them is a reason to start the
> Qt 5 launcher:**
>
> | | what only tepService has |
> |---|---|
> | **`inputMode` = `Epochs`** | consume a stream that already delivers one epoch per block, as SPEED's `epochs` output does — the parity path for a rig still on the old configuration. tepSound registers no `inputMode` parameter at all |
> | **`artifactSpan` = `Legacy (start + end)`** | reproduce the shipped Python's off-by-design artefact span (§2.3), which **every recording made before this service** carries. tepSound hard-codes `ArtifactSpan::Requested` in `service_analysis.cpp` and exposes no switch, so re-analysing a pre-2026 recording needs tepService |
> | **Parameter vocabulary** | 47 of this module's 60 parameter ids exist verbatim in tepSound; **13 do not.** `artifactStart`/`End`/`Smoothing` became `blankFrom`/`blankTo`/`blankSmoothing`, `epochLowpass[Hz]` became `preLowpass[Hz]`, `rereference`/`rereferenceChannels` became `car`/`carExcluded`; `artifact`, `baseline`, `baselineMethod`, `averaging` and `inputMode` have no counterpart. A saved tepService `--serviceConfig` file therefore loads **partially** into tepSound — the 13 come back as `NoSuchParameter` refusals in the apply report, not silently |
>
> ⚠ One more difference, independent of any port: in a **tepSound** epoch file the `epochs`
> dataset holds the SOUND-cleaned form, and `preproc` holds the pre-SOUND one — after channel
> repair and CAR, not raw (`soundstore.cpp`, `content` attribute); in a **tepService** file
> `epochs` is the uncleaned epoch. An offline script written against one reads different physics
> from the other.

Read [architecture.md](../migrations/framework-evolution.md) first for what a service is, and
[stimulus-presentation.md](stimulus-presentation.md) for the module this one is shaped after.
**§2 is the part to read before changing anything** — it is the pipeline, in order, with the
reason for each step's position.

---


<a id="history-0-state-of-play"></a>

## 0. State of play

| | |
|---|---|
| ✚ New module | `R:\src_Qt5\tepService` — `tepService.exe`, service name **`TEP`**, launcher `tepService.bat` |
| ✚ Brick library | `import/Resonance/Tep/` → `bin/Resonance/Tep/`, and a second copy in the qrc |
| ✚ Montage | `montages/mumeg_mks64.ced` — the lab's 64-electrode layout, previously only inside the Python tree |
| Registration | one line, `add_subdirectory(tepService)` in `R:\src_Qt5\CMakeLists.txt` |
| Outside the module | **nothing.** No framework change, no edit to any other module |
| Built | MSVC v142 x64, deployed to `R:\dist_Qt5\msvc64` (the tree that was `R:\dist\msvc64` when this was written). ⚠ `mingw32`/`mingw64` have not seen it |
| Qt 6 | **retired, not a port target.** `tepSoundService` is the active replacement; see the box above and [`arch_qt5-still-needed.md` §3.2](../migrations/qt5-still-needed.md) |

**Verified:** two real 25 kHz TMS-EEG recordings replayed end to end — **155 of 155 stimuli
produced an epoch, none lost, and of 20,460,000 values exactly one differs from an independent
SciPy implementation by one float32 ULP** (0.93 nV at 18.09 mV). `test_TepPipeline` is 47/47.
⚠ The comparison was **re-run on 2026-08-18** after the display band limit moved into the
continuous stage: the 2026-08-16 figures describe an arrangement that no longer exists. Details,
the two controls, and which claims are current:
`report_tep-service-validation.md` (on the lab drive, `R:\docs\_notes\`).

<a id="history-what-it-is-for"></a>

### What it is for

A TMS-EEG session produces one number an operator has to judge in the moment — *is this
recording going to be usable?* — and it is not visible in a raw trace. It needs the stimulus
artifact removed, the epoch cut around the pulse, forty of them averaged, and the EMG pair
differenced and measured. The legacy answered it with two processes, a Python environment and a
settings file passed between them by hand. This does it in one service, with every setting a
Resonance parameter.

```
   amplifier ──► tepService ──► epochs   ──► recorderService / a script / another service
   (nvx136)         │      ──► average
                    │      ──► events    (JSON: one record per epoch, with its MEP measured)
                    │      ──► status    (Float64, 18 named channels at 2 Hz)
                    └──────► console     (scalp grid · butterfly · MEP ± sd · single trials · log)
```

---


<a id="history-2-the-pipeline-in-order"></a>

## 2. The pipeline, in order

This is the part to be careful with. Each step is where it is for a reason, and moving one
changes the numbers.

```
  ┌─ continuous stage (pipeline.cpp) ───────────────────────────────────────────────┐
  │ 1. trigger edges          on the RAW trigger word, before anything is modified   │
  │ 2. artifact interpolation linear across the span, then a boxcar over the joins   │
  │ 3. highpass → notch → lowpass → display lowpass   stateful IIR, continuous       │
  │ 4. window cut             [windowStart, windowEnd] ms around the trigger          │
  │ 5. decimation             plain subsampling by an integer factor                  │
  └──────────────────────────────────────────────────────────────────────────────────┘
  ┌─ per-epoch stage (epochprocessor.cpp) ──────────────────────────────────────────┐
  │ 6. EEG:  ×1e6 → baseline → CAR → re-reference                                    │
  │ 7. EMG:  ×1e3 → baseline → difference (B − A) → slow-trend removal               │
  │ 8. measurement: peak-to-peak in the response window, onset, area, baseline RMS   │
  └──────────────────────────────────────────────────────────────────────────────────┘
```

<a id="history-21-why-the-order-is-what-it-is"></a>

### 2.1 Why the order is what it is

**Trigger edges come from the raw word, not from the interpolated or filtered signal.** The
interpolation is about to overwrite the samples around the pulse, and a filter would smear the
edge across several samples. Reading the edge first is the only way the epoch is anchored to the
sample the stimulator actually fired on. The legacy does the same
(`trigger = transform_channels(raw_signal, …)` while everything else runs off `interp_signal`).

**The artifact is removed before the filters, not after.** A TMS artifact is volts against
microvolts. Put that through a second-order IIR and it rings for tens of milliseconds — which is
exactly the interval the response is in. There is no filter setting that recovers from it, so the
artifact has to be gone before the first biquad sees it.

**The filters are continuous and stateful, not per-epoch.** Filtering an already-cut epoch gives
every epoch a startup transient at its left edge and an edge discontinuity at its right; running
one filter over the stream and cutting afterwards gives neither. It also means the filter has to
see every sample exactly once, in order, which is what most of `pipeline.cpp` is arranging.

⚠ **The display lowpass used to be the exception, and it no longer is (2026-08-18).** It was the
first step of the per-epoch stage — a filter on an already-cut epoch, which is precisely what the
paragraph above says not to do. It is now the last stage of the continuous cascade. Three
consequences, in order of how much they matter:

* **No epoch carries a filter transient any more.** That was the point.
* **Decimation is genuinely anti-aliased.** Before, subsampling to `outputRate` relied on the
  2500 Hz pre-lowpass sitting exactly at the decimated Nyquist, which is the marginal case; a
  250 Hz band limit ahead of it is not marginal at all.
* ⚠ **A change to the display cutoff now applies from the next epoch**, instead of re-deriving the
  epochs already collected. It is upstream of the cut, so the stored epochs were already filtered
  on the way in. Every genuinely per-epoch setting — baseline, CAR, re-reference — is still fully
  retroactive, which is what the store keeps raw epochs for.

**Epochs mode keeps the per-epoch filter**, because there is no continuous signal left to filter:
the block already *is* the epoch. That is the one place a left-edge transient is unavoidable
rather than chosen.

⚠ **This changes the numbers**, and both the reference implementation and the evidence had to be
regenerated before either meant anything again. Done 2026-08-18:
`tep_reference_pipeline.py` models the display stage, and the claim in
`report_tep-service-validation.md` §3 (on the lab drive, `R:\docs\_notes\`) is re-established against the new
arrangement — **155/155 epochs over both recordings, 20,460,000 values, one differing by one
float32 ULP**. **A comparison that still omits the display stage now fails on 97 % of the EEG
values, by up to 2.1e-04 V**, while the EMG pair still agrees to 9.3e-10 V — which is what says
the filter is present and is reaching only the channels it should.

⚠ **It is a second filter over the EEG columns, not a fourth section of the cascade above.** The
per-epoch filter it replaced ran over the EEG alone — `extractMep()` reads the epoch unfiltered —
so folding it into the main cascade band-limits the EMG pair, at −4.9 dB by 300 Hz, and every MEP
amplitude, baseline RMS and onset moves as a side effect of a *display* setting. That mistake was
made once already and shipped; `DisplayLowpass.StridedFilterLeavesTheTrailingChannelsUntouched`
exists to make it fail loudly.

**Decimation is subsampling** — `x[::5]`, no `scipy.decimate`, no anti-alias filter of its own.
That is legitimate *only* because the continuous lowpass has already band-limited the signal. A
configuration that decimates with the lowpass switched off, or with the lowpass above the new
Nyquist, aliases — and this module says so in the console rather than leaving it to be found in
the analysis.

<a id="history-22-the-look-ahead-and-why-the-output-lags"></a>

### 2.2 The look-ahead, and why the output lags

The artifact stage cannot emit a sample until it knows whether a trigger is about to arrive that
would rewrite it. So the pipeline holds back

```
hold = max(lastTouchedOffset, −firstTouchedOffset) + 2  samples
```

which at the rig's −5…+15 ms artifact and a 5-sample boxcar is **381 samples, 15.24 ms** at
25 kHz. That is a property of the algorithm, not of this implementation — the legacy holds the
same amount and calls it `_hold_size`. It is reported as `holdMs` in the console and in `status`.

<a id="history-23-one-compatibility-switch-and-one-defect-not-reproduced"></a>

### 2.3 One compatibility switch, and one defect not reproduced

<a id="history-artifactspan--the-interpolation-ends-in-the-wrong-place-in-the-legacy"></a>

#### `artifactSpan` — the interpolation ends in the wrong place in the legacy

`resonance/pipe_tep/interpolate_by_trigger.py` computes

```python
start_pos = trigger_idx + self._start_idx - 1
end_pos   = start_pos + self._end_idx + 1      # <- from start_pos, not from the trigger
```

so the far edge lands at `artifactStart + artifactEnd`, not at `artifactEnd`. At the rig's
−5 / +15 ms that means **the interpolation stops at +10 ms, not +15**, and the last 5 ms of the
artifact is filtered as signal. Every recording made before this module has that span.

`As requested` (default) interpolates −5…+15. `Legacy (start + end)` reproduces −5…+10. It is a
switch because the *span* is a parameter of the analysis: a recording processed with the narrower
one is not wrong, it is different, and reproducing it is a legitimate thing to want.

<a id="history-the-car-list-is-used-inside-out-in-the-legacy--and-that-is-not-reproduced"></a>

#### The CAR list is used inside-out in the legacy — and that is **not** reproduced

The window reads `CAR кроме:` — *CAR except* — and ships preloaded with FT9, FT10, TP9, TP10,
which is the set a lab would want left out of a common average. `DataProcessor.configure_car`
takes that same list as the set to average **over**:

```python
is_selected = np.array([ch in channels for ch in self.settings.channels])
W = np.eye(n) - (1/n_sel) * np.outer(np.ones(n), is_selected)
```

So the delivered configuration does not compute a common average reference at all. It
re-references every electrode to the mean of four temporal-mastoid electrodes.

This one has no compatibility mode. It is not a different choice of analysis, it is the code
disagreeing with its own label, and offering it as a setting would keep it alive and make
somebody choose it by accident. `car` + `carExcluded` is the mean over every electrode except the
ones listed, and nothing else. If an old result needs reproducing, `rereference` with those four
channels does exactly what the old code did, under a name that says so.

<a id="history-24-numbers-this-module-and-the-legacy-agree-on-exactly"></a>

### 2.4 Numbers this module and the legacy agree on exactly

`test_TepPipeline` is **47/47**, and every expected value in it was produced by SciPy on the same
input and pasted in at full precision:

| Check | Against |
|---|---|
| Butterworth 2 lowpass / highpass coefficients, four cutoffs | `scipy.signal.butter(2, …, output='sos')` |
| Notch coefficients | `scipy.signal.iirnotch` → `tf2sos` |
| Filter output over 10 samples | `scipy.signal.sosfilt` |
| Boxcar with edge replication | `scipy.ndimage.uniform_filter1d(size=5, mode='nearest')` |
| Running median | `scipy.ndimage.median_filter(size=5, mode='nearest')` |
| Percentiles | `numpy.percentile` |
| TKEO | `logic/mep_movement_detection.calculate_tkeo` |

⚠ **The fourth cutoff is 250 Hz at 25 kHz, and it was added on 2026-08-18 because it was missing.**
The suite pinned 250 Hz at 5 kHz — the rate of the per-epoch placement — and 2500 Hz at 25 kHz, but
the move left the display filter running at an operating point no test held down: the one test that
mentioned it asserted only that it *differed* from the decimated-rate design, which any wrong answer
also satisfies. `tep_reference_pipeline.py` builds the same design, so an error there would have
been a shared one and the end-to-end comparison would have agreed while both were wrong.

The filter designs are re-derived rather than taken from the `iir1` package the viewer links,
because `iir1` normalises differently and every comparison against a legacy recording would then
have been a negotiation. The prototype poles, the pre-warp constant (`4·tan(πWn/2)`, which is
SciPy's internal `fs = 2`) and the bilinear transform are written out in `dsp.cpp`.

⚠ **One deliberate numerical difference.** `resonance.pipe_tep.sosfilt` initialises its state with
`scipy.signal.sosfilt_zi`, which is the steady state for a **unit step** input, so it injects a
startup transient proportional to how far the real first sample is from 1.0. This module starts
from zero state. At the rig's 2500 Hz lowpass the difference decays with a ~0.06 ms time constant
and is immaterial by the first stimulus, tens of seconds into a session; it is recorded here
because it is the one place the two implementations are not identical by construction.

<a id="history-25-where-to-touch-it-when-improving-it"></a>

### 2.5 Where to touch it when improving it

Everything with a defensible right answer is in `dsp.cpp`, `pipeline.cpp` and
`epochprocessor.cpp`, none of which include a Qt type or a Resonance type. They are compiled into
`test_TepPipeline` as well as into the service, so a change to any of them can be checked without
a window, an amplifier or a network.

The three things most likely to be wanted next, and where they go:

1. **A better artifact model** (a decay fit, or a subspace method rather than a straight line) —
   `Pipeline::applyArtifacts`. The staging buffer already holds the whole span with margin, so a
   method needing more context needs only a larger `hold`;
2. **Per-epoch rejection on the EEG** (an amplitude criterion across electrodes, not only the EMG
   baseline RMS) — `EpochProcessor::process` produces the epoch; `TepService::takeEpoch` sets the
   flag. Rejected epochs are kept and marked, never dropped;
3. ~~**An incremental average.**~~ ✅ **Done 2026-08-18.** Processed epochs are cached beside the
   raw ones and a running total is extended per arrival, which took the service from 17 % of a
   core to 6 %. ⚠ The accumulator **only ever adds**: subtracting an epoch back out on eviction,
   rejection or removal drifts ~1e-15 relative from a fresh sum, which would make a displayed
   *and saved* average depend on the order of the operator's actions, so those paths rebuild from
   the cache instead. `EpochStoreAccumulator` is seven tests asserting the fast path is
   bit-identical to a full reduction; three of them caught the subtracting version.
   The median and trimmed mean still go through the full reduction and genuinely need the ring.

---


<a id="history-3-the-module"></a>

## 3. The module

```
R:\src_Qt5\tepService\
    main.cpp                    QApplication + ResonanceApp; --signal, --montage, --autoStart
    service.{hpp,cpp}           parameters, state machine, streams, the console's model
    pipeline.{hpp,cpp}          the continuous stage — §2
    signalworker.{hpp,cpp}      the worker thread the continuous stage runs on
    epochprocessor.{hpp,cpp}    the per-epoch stage — §2
    epochstore.{hpp,cpp}        the session: raw epochs, averages, the epoch file
    dsp.{hpp,cpp}               filter design and the numeric primitives
    views.{hpp,cpp}             TepGridView / TepTraceView, QQuickPaintedItem
    ui/                         Console.qml, RunBar.qml, SettingsPane.qml (in res.qrc)
    import/Resonance/Tep/       the brick library, installed to bin/Resonance/Tep
    montages/                   mumeg_mks64.ced
    tests/                      pipeline_test, epochstore_test, displaylowpass_test
                                → test_TepPipeline, 47 cases
    tepService.bat  CMakeLists.txt  res.qrc
```

⚠ Four of those pairs — `dsp`, `pipeline`, `epochprocessor`, `signalworker`, 1 917 of the module's
6 614 C++ lines — also exist as byte-identical copies at
`R:\src\tepSoundService\shared\tepService\`, where they are compiled by the Qt 6 build. **Edit
them here and they diverge.** The copy is deliberate: it keeps the Qt 6 tree independent of
`R:\src_Qt5` without importing an unported application.

<a id="history-31-streams"></a>

### 3.1 Streams

| Stream | Type | What is on it |
|---|---|---|
| `epochs` | Float64, *channels* × *epochSamples*, at the epoch rate | one block per epoch, in the amplifier's units, stamped with the **trigger's** RTC. The same shape SPEED published, so an existing consumer needs no change |
| `average` | Float64, same geometry | the running average, published when it moves. EEG in the electrode slots, the MEP in the first auxiliary slot, so one consumer reads both streams |
| `events` | Message, JSON `v: 1` | one record per epoch with its MEP measurement; plus session start/stop, notes and saves |
| `status` | Float64, **18 named channels** at 2 Hz | counters, rates, the last and mean MEP amplitude, and `processingLoad` |

An `events` record:

```json
{"v":1,"type":"epoch","n":41,"rtc":"5349385863600","samples":2000,"channels":66,
 "artifact":true,"rejected":false,
 "mep":{"amplitudeMv":0.387,"peakMs":21.2,"troughMs":26.0,"areaMvMs":2.91,
        "onsetMs":17.0,"baselineRmsMv":0.005}}
```

**The epoch block carries the trigger's RTC, not the moment the epoch finished being built.** The
build time is an artefact of the window length; the trigger time is what an analysis lines the
epoch up against. (The legacy stamped each epoch with its *last* sample —
`transform_window_to_channels` uses `wnd.timestamps[-1]` — so every epoch appeared 300 ms late.)

<a id="history-31a-the-epoch-file"></a>

### 3.1a The epoch file

Written by the service itself, not by `recorderService`, because it is a **derived** product in a
layout the lab's offline scripts already read (`logic/mep_movement_detection.load_saved_epoch_file`
and everything built on it). The recording proper is whatever `recorderService` wrote from the
streams.

| Dataset | |
|---|---|
| `epochs` | `[n_epochs × n_samples, n_channels]` float32, plus `Fs`, `n_epochs`, `n_samples`, `n_channels`, `window_start_ms`, `window_end_ms`, `source` as attributes — exactly what `epoch_record_buffer.py` wrote |
| `timestamps` | int64 nanoseconds, one per epoch, the **trigger's** RTC |
| `labels` | ✚ one per epoch: the condition, verbatim from the marker stream |
| `mep/amplitude_mV`, `mep/onset_ms`, `mep/rejected` | ✚ the measurements, in the same file as the epochs they were made from |

The last two are additions. The legacy kept trial order in a separate JSON, and
`mep_condition_analysis.labels_for_epochs` contains code for "the sequence is one longer than the
epochs, drop the first" and "it is a different length, use the first N" — guesses that stop being
necessary when the label travels with the epoch.

<a id="history-32-parameters"></a>

### 3.2 Parameters

**60 parameters in eight groups**, indices banded so the tab order is deliberate: `input` 10-99,
`epoch` 110-199, `filter` 210-299, `processing` 310-399, `average` 410-499, `mep` 510-599,
`session` 605-699, `window` 710. 53 of the 60 carry a real type rather than a `String` — the
other seven genuinely are text — and 42 carry a tooltip.

In the console those tooltips are attached to each row's **label**, not to its control: hovering a
spin box to read what it does puts the explanation over the thing you are about to drag, and over
the rows either side of it. `TepToolTip` fixes its own width and wraps into it, because a stock
Controls 2 `ToolTip` lays its text on one line and grows — a three-sentence description becomes a
strip across the whole window. That is the same trap `ParameterToolTip.qml` exists for in the
plugin.

Three are `Action`s (`reset`, `save`, `note`) rather than values, so a saved parameter set cannot
replay them on load.

The console binds to the parameter objects themselves through
`service.parameter("baselineFrom")` rather than duplicating them as properties, so the Configurator
and the console edit one object and there is nothing to reconcile.

<a id="history-33-states"></a>

### 3.3 States

```
idle ──start──► collecting ──pause──► paused
  ▲                 │                    │
  └────── stop ─────┴──── stop ──────────┘
                    ◄──── resume ────────┘
```

`collecting` resets the pipeline on entry, so an epoch can never be built half out of the previous
session's samples. `idle` writes the epoch file on the way in if `Save on stop` is set, so every
way of ending a session is the same way. Both happen on **state entry**, not in the invokable the
console's button calls — the Configurator, a script and the button therefore cannot diverge, which
is the defect the stimulus service's acceptance run found.

<a id="history-34-the-console"></a>

### 3.4 The console

One window, three columns, one persistent run bar, on the organising idea
[stimulus-presentation §5.7](stimulus-presentation.md) states: the operator should be able to
answer "is this session going to be usable?" without looking anywhere else.

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ ● TEP  eeg · 67 ch · 25000 Hz     epochs 72 · in average 72 · triggers 72 · lost 0    │
│                                            [Pause] [Stop] [Reset] [Save] [Note…]      │
│ ⚠ The MEP window opens at 10 ms, inside the interpolated artifact span.               │
├───────────────┬──────────────────────────────────────┬───────────────────────────────┤
│ SESSION       │  TEP · AVERAGE      [average][±30µV] │ MEP · AVERAGE ± SD            │
│ EPOCH         │      ┌── the scalp grid ──┐          │   ┌────────────────────┐      │
│ PROCESSING    │      │ one trace per       │          │   └────────────────────┘      │
│ AVERAGE       │      │ electrode, at its   │          │ MEP · SINGLE TRIALS           │
│ MEP           │      │ own place on the    │          │   ┌────────────────────┐      │
│ PIPELINE      │      └── head ─────────────┘          │   └────────────────────┘      │
│  (in order)   │  TEP · ALL ELECTRODES  (butterfly)    │  #  time  MEP mV onset rms    │
└───────────────┴──────────────────────────────────────┴───────────────────────────────┘
```

Design decisions worth keeping:

| Rule | Replaces |
|---|---|
| **The warning strip is above the work.** A configuration that will quietly produce a wrong answer — decimating with no anti-alias filter, a baseline window inside the artifact, a MEP window inside it — is stated before the session, not discovered in the analysis | nothing; the legacy had no such surface at all |
| **The pipeline panel lists the steps in order, from the live settings.** What is actually being computed is readable without opening a file | two settings files that disagreed |
| **The epoch table is live**, one line per epoch with its amplitude, onset, baseline RMS and condition; right-click rejects | `updateCounter.emit(self._n_epoch)` — a number |
| **Epochs are selectable**, with the modifiers every list uses — click, Ctrl-click, Shift-click, `Ctrl+A`, `Esc`. Several selected draws the average of exactly those, which is how two conditions get compared mid-session | nothing; the legacy could show the average or the newest, and that was all |
| **Every divider moves**, columns and rows both. What matters at the start of a session (the scalp map) is not what matters in the middle of one (the single trials) | a fixed 1850×900 layout |
| **A plot's axis is derived from the samples it actually drew**, never from the range asked for. Asking for a window wider than the epoch used to relabel the axis while the traces stayed put | — |
| **Rejecting is not deleting.** A rejected epoch stays in the file, marked | `delete_epoch(n)`, which removed it |
| Qt Quick Controls 2, compact metrics, backgrounds replaced to get under the 100×40 px floor | Qt Widgets at 1850×900 |

---


<a id="history-4-what-the-legacy-does-that-this-does-not-reproduce"></a>

## 4. What the legacy does that this does not reproduce

Recorded because each is a difference somebody will notice, not because each is a defect.

1. **Slow-trend removal was applied to one panel and not the other.** `plot_updater` removes a
   running median from the single-MEP display (`_mep_from_epoch_channels`) but the averaged MEP
   path (`calculate_avg_MEP_stats` → `get_emg_epochs`) does not. The two panels therefore drew
   different signals from the same epoch. Here it is one setting and both follow it.
2. **`RollingTrimMean` returned `None` when it had too few epochs to trim**, and the plots drew
   that as a gap. Here a trimmed mean of four epochs is the mean of four epochs.
3. **A trigger already high at connect was announced as a stimulus.** `bit_signal_to_event`
   initialises `self._prev = False`, so an NVX input reading 0xFF at start-up — which is what an
   unconnected one reads — produced an epoch at sample 0. This adopts the resting level from the
   first sample instead.
4. **Epochs of a different length were quietly mixed in.** `_current_length_epochs` filters by
   length, so changing the window mid-session silently reduced what the average was over, with no
   indication. Here the count that contributed is on the plot.
5. **The RNG-free parts of the display had no error surface at all.** A missing CED file, a
   channel name that did not resolve, a baseline window outside the epoch: all silent.

<a id="history-4a-and-one-the-validation-found-in-the-offline-analysis"></a>

### 4a. And one the validation found in the offline analysis

Not this module's, and not fixed here, but it changes what a past result means.

`mep_movement_detection.prepare_emg_epochs` band-passes **each epoch from zero initial state**,
and the epochs carry the amplifier's DC offset — about half a millivolt on the EMG difference,
because neither pipeline high-passes by default. A step of that size into a 10–450 Hz Butterworth
produces a transient at the start of every epoch four times larger than the real response, and
the TKEO detector's valid region includes everything before −8 ms. So it reports "movement at
−100 ms" in **every trial**: 75 of 75 measured. With the offset removed first, the same detector
on the same epochs finds movement in 26 of 75, with plausible onsets.

The lab's own `notes` file already says `Для ЭМГ: highpass 1 Hz — must have`, and the shipped
`SPEED_settings.json` has `"highpass": false`. Turning on `preHighpass` at 1 Hz removes the offset
before the epoch is cut. Numbers in
`report_tep-service-validation.md` §6a (on the lab drive, `R:\docs\_notes\`).

---


<a id="history-5-verified"></a>

## 5. Verified

Everything below was run on this machine on 2026-08-16, **on a Qt 5.15.2 / MSVC v142 build**. It
has not been re-run against a Qt 6 binary because there is no Qt 6 binary; when the module is
ported, the two-recording SciPy comparison is the acceptance to repeat, and its runner and
reference already exist: `R:\config\tep_validation_run.ps1` and
`R:\config\tep_reference_pipeline.py`.

<a id="history-51-unit--test_teppipeline-3333"></a>

### 5.1 Unit — `test_TepPipeline`, 33/33

Against SciPy, per §2.4, plus the pipeline's own arithmetic: window geometry, alignment of the
epoch to the trigger sample, decimation, one-bit trigger reading, the resting-level rule, the
refractory period, a window that opens before the stream did, the artifact span in both modes,
and **that the result does not depend on the transport block size** — checked at 1, 7, 64, 333 and
1024 samples per block, which is the range the NVX validation measured for a requested 2500.

<a id="history-52-end-to-end-against-two-real-recordings"></a>

### 5.2 End to end, against two real recordings

Full report, screenshots and artifacts: **`report_tep-service-validation.md` (on the lab drive, `R:\docs\_notes\`)**.

| | `01_TP_M1_60MSO_single_REAL` | `06_TP_SMA_67MSO_SST_REAL` |
|---|---|---|
| Replayed | 391.9 s, 5.25 GB, 1× | 417.7 s, 5.60 GB, 1× |
| Triggers / epochs / lost | **75 / 75 / 0** | **80 / 80 / 0** |
| Values compared against SciPy | 9,900,000 | 10,560,000 |
| Max absolute difference | 3.73e-09 V | 1.17e-08 V |
| float32 resolution of the signal | 8.90e-09 V | 4.84e-08 V |
| **Bit-identical after float32** | **yes** | **yes** |

Also: `recorderService` recording `epochs` and `events` (17 blocks of exactly 2000 samples, 17
matching event records); the Configurator's own `ParametersView` rendering all 60 parameters in
eight tabs; condition labels taken from a replayed marker stream and written into the epoch file;
and the legacy offline analysis (`logic/mep_movement_detection.py`) reading that epoch file
unmodified.

Cost: **34–44 % of one core** at 67 channels and 25 kHz, rising with the session because the
average is recomputed from raw epochs — §2.5.

---


<a id="history-6-not-verified"></a>

## 6. Not verified

Stated plainly, because §5 reads like completion:

* **No amplifier.** Everything was driven from `playbackService` replaying a recorded session.
  That is the stricter path for the *pipeline* — the samples are known in advance and can be
  checked — and says nothing about behaviour against a live driver's block cadence, a mid-session
  restart, or an impedance-mode switch.
* **The `Epochs` input mode has not been exercised against a real SPEED.** It is the parity path
  for a rig still running the old configuration, and it has been driven only by the code that
  reads a Float64 block, not by SPEED itself.
* **No marker stream has been attached.** The condition-label path is built and the field is in
  the epoch file; nothing has published a marker into it.
* **`mingw32` / `mingw64` have not seen this module.** A compile is not a build, and neither has
  even compiled it. ⚠ Historical: MinGW parity stopped being a goal at the Qt 6 move, and there
  are no `mingw32`/`mingw64` distributions any more — `R:\dist_Qt5\msvc64` is the only tree this
  module ships in.
* **Nothing here has been compiled by MSVC v143, let alone under Qt 6.** The module is not in the
  Qt 6 tree at all, so every number in §5 and every behaviour in §3 is a Qt 5.15.2 / v142
  statement. The exception is §2's arithmetic, which does run under Qt 6 — inside
  `tepSoundService`, from a byte-identical copy of the same four source pairs.
* **The console has not been operated by a person.** Everything was driven from the command line
  and the state machine; no one has dragged a stream onto it or typed into the panels.
