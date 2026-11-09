# `signalGenerator` — the synthetic signal source — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/signal-generator.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-signalgenerator--the-synthetic-signal-source"></a>


**Reworked 2026-08-17.** It was ~200 lines emitting one sine on every channel of one stream. It is
now four streams from one process, driven off one timeline, with a per-channel table, a life-like
EEG simulation, an event schedule and fault injection.

Read [architecture.md](../migrations/framework-evolution.md) first for what a service and a stream are.
Its module row is in [modules.md](../migrations/modules.md).

> **Ported to Qt 6, and shipping as the default.** `R:\dist\signalGenerator.bat` →
> `R:\dist\bin\SignalGenerator.exe`, built from `R:\src` against Qt 6.11.2 / MSVC v143 14.44 /
> C++20, registered at `add_subdirectory(SignalGenerator)` in `R:\src\CMakeLists.txt`. The
> Qt 5.15.2 build survives as the comparator in `R:\dist_Qt5\msvc64`.
> **The high-resolution pacing survived the port** — `pacer.{hpp,cpp}` is **byte-identical** in
> `R:\src` and `R:\src_Qt5` (§6). The 101 parameters, the channel table, the waveform library
> and the EEG model came across unchanged; every measured figure in §7 is still Qt 5-measured.
> Background: [qt5-to-qt6-transition.md](../migrations/qt5-to-qt6-transition.md).

---


<a id="history-1-why-one-process"></a>

## 1. Why one process

| | |
|---|---|
| `continuous` | `Float64`. A **channel table**: every channel its own waveform, kind, unit, time shift and fault. |
| `eeg` | `Float64`. The **life-like simulation**: spatially correlated 1/f, alpha, blinks, drift, mains, EMG, AUX and a trigger word. |
| `epochs` | `Float64`. **One block per event**, each a fixed window around it — the shape `tepService` publishes its own epochs in. |
| `stimuli` | `Message`. Markers, as text or JSON. |
| `status` | `Float64`, 16 named channels at 2 Hz — what the service is actually doing. |

A process may declare exactly one *service* (`Core/docs/service.md`), but a service may publish as
many *streams* as it likes; `tepService` publishes four. So this is one service with five streams,
and the reason it is not several processes is the timeline:

```
   Schedule ──┬─► stimuli      record stamped with the event's RTC
              ├─► continuous   trigger bits + evoked response at the event's sample
              ├─► eeg          the same, weighted by distance from a focus on the scalp
              └─► epochs       one block per event, stamped with the event's RTC
```

**A marker, a trigger bit-flip and an evoked bump are the same event, on the same sample.** Two
generator processes cannot do that, and it is what makes an epoching pipeline testable without an
amplifier, a stimulator or a subject. If you want streams that appear to come from *different*
services, run a second process with a different `--serviceName`; you lose the sample-accurate
alignment between them, which is the honest trade.


<a id="history-2-parameters--four-tabs-and-only-four"></a>

## 2. Parameters — four tabs, and only four

101 parameters in exactly four groups, each leading with its enable flag and its stream name:

| Group | Index band | Count | Leads with |
|---|---|---|---|
| `continuous` | 10–99 | 25 | `enabled`, `streamName`, `autoStart` |
| `eeg` | 210–299 | 38 | `eegEnabled`, `eegStreamName` |
| `epoched` | 410–499 | 14 | `epochEnabled`, `epochStreamName` |
| `messages` | 610–699 | 24 | `msgEnabled`, `msgStreamName` |

`ParametersView` orders tabs by the lowest index in each group, which is why the indices are
banded. The parameter panel is a narrow dock and more tabs than this do not fit it — the same
constraint that keeps labels to ~22 characters and puts the detail in a tooltip. 89 of the 101
carry one.

**Every original parameter name still exists and still means what it did** — `channels`,
`samplingRate`, `blockSize`, `amplitude`, `mode`, `fixedFrequency`, `minFrequency`,
`maxFrequency`, `stepBand`, `ced`, `streamName` — so the saved configurations in `R:\config`
(`pbtest_gen1.json`, `meta_gen.json`, …) and the harnesses that write them keep working.

<a id="history-autostart-and-the-old-behaviour"></a>

### `autoStart`, and the old behaviour

The service now has a state machine, which it never had:

```
init ──prepare──► armed ──start──► running
  └────start─────►  ┘              (both ──stop──► init)
```

`armed` is the point of it: **streams on the network, listening, emitting nothing**, indefinitely.
Point a recorder at them, start the recorder, *then* start the generator. Measured on a 20 s run
recording all five streams, that is the difference between 172 and **203** blocks (§7).

`autoStart` defaults **true**, so a bare launch publishes and starts emitting exactly as the old
generator did. It is read **when its timer fires, 750 ms after launch, never in the constructor**:
`--serviceConfig` is applied from `afterExec()`, on the first turn of the event loop, so nothing
read in a constructor can be configured by it. That is precisely how `recorderService`'s own
`autoStart` came to do nothing.


<a id="history-3-the-channel-table"></a>

## 3. The channel table

`channels` sets the row count; the `Channel table` action opens a window with one row per channel
and a column per setting — name, kind, unit, waveform, frequency, amplitude, offset, phase,
**shift ms**, duty, two waveform-specific parameters, noise, seed, and fault injection. It is its
own window rather than a control in the parameter panel because eighteen columns do not fit a
dock, and it carries bulk edits (apply a kind or a waveform to a selection, fill down, a **shift
ramp** and a **signature ramp**) because setting 128 rows one at a time is not usable.

Set `mode` to `Channel table` for it to take effect; the other four `mode` values are the original
canned layouts.

**The table is stored as one `MultiLine` parameter**, `channelPlan`, in a text form that
round-trips:

```
1-64  name=auto kind=EEG wave=noisepink amp=2e-5
65    name=EMG1 kind=EMG wave=noisewhite amp=5e-4
66    name=AUX1 kind=AUX wave=triangle freq=3 amp=2
67    name=TRG  kind=Trigger wave=bits p2=8
```

One parameter, not `channels` plus `channel1…channelN`, and that is not a style choice:
`applyParameters` decides which parameter names a service knows **before** it applies any of them,
so every row created as a side effect of applying the count is rejected and never retried
([known-issues §16b](../incidents/33-framework-traps-found-building-playbackservice-2026-08-15.md#history-16b-applyparameters-screens-names-before-it-applies-anything--fixed-2026-08-22)).
That is why a saved `recorderService` configuration with two streams cannot be loaded back. A
single parameter holding all the rows cannot have that problem — verified in §7 by loading a
six-channel plan from `--serviceConfig` in one go.

Identical consecutive rows collapse into a range on the way out, so 64 identical electrodes are
one line rather than 64.

<a id="history-the-one-implicit-rule"></a>

### The one implicit rule

**A channel whose kind is `Trigger` and whose waveform is `bits` is driven by the event
schedule** — the code goes into `trigEventMask`, held for `trigPulseMs`, with `trigNoiseMask` bits
flipping on their own at `trigNoiseHz`. Any other waveform on a trigger channel is left to its own
oscillator, so the table stays the final word on what a channel does.


<a id="history-4-the-waveform-library"></a>

## 4. The waveform library

27 waveforms, the standard function-generator repertoire plus what neurophysiology needs:

| | |
|---|---|
| Periodic | `sine` `square` (duty) `triangle` (symmetry) `ramp` `pulse` `halfsine` `staircase` `sinc` `gauss` `exprise` `expfall` |
| Swept / modulated | `chirp` (linear f0→f1) `am` `fm` `dampedsine` |
| Stochastic | `noisewhite` `noiseuniform` `noisepink` (1/f) `noisebrown` (1/f²) `randomwalk` `prbs` |
| Composite | `bandsum` (sum of sines) `cardiac` (PQRST) `arbitrary` (a shared table) `bits` `dc` `off` |

`p2` and `p3` mean something different per waveform, and the table labels them per row rather than
leaving two anonymous numbers.

**`shift` is honest about what it can do.** A deterministic waveform gets a real time shift. A
*stateful* one — any noise, the random walk, the PRBS — cannot be shifted without replaying its
whole history, so its shift is folded into the seed instead: a different realisation rather than
the same one delayed. That is what an operator wants from `shift` on a noise channel anyway, and
saying so is better than a shift that silently does nothing.

<a id="history-faults"></a>

### Faults

`defect` injects `nanruns`, `infruns`, `flat` (a disconnected electrode, which wanders at
quantisation scale rather than being perfectly still), or `clip`. `dperiod`/`dlen` are in samples,
so **`dperiod=20 dlen=3` reproduces the NVX 5 kHz fault** — "a highly regular sequence of two- or
three-sample holes approximately every 20 theoretical samples"
(STATUS ([change history](../changes/README.md)), the 2 kHz/5 kHz boundary campaign). `dropEvery` throws away whole blocks
without disturbing the sample clock, so the stream has a real transport gap in it.


<a id="history-5-the-eeg-simulation"></a>

## 5. The EEG simulation

The channel table builds a stream one independent channel at a time. That is the right tool for a
viewer or a channel-ordering bug and the wrong one for anything that cares what EEG *is*:
independent channels have no spatial structure, so a common-average reference removes nothing and
a topographic map is noise.

| Component | How | Where it is strongest |
|---|---|---|
| 1/f background | one pink source per electrode, mixed through the **Cholesky factor of `exp(-d/λ)`** | everywhere |
| alpha | 10 Hz with a slow burst envelope | posterior, by `((1-cos θ)/2)²` |
| mains | one common-mode sine with a per-channel gain spread | everywhere |
| drift | an Ornstein-Uhlenbeck process per electrode, **independent** | everywhere |
| blinks | `(t/τ)² e^(−t/τ)` at a Poisson rate | frontal, by `max(0, cos θ)³ · r` |
| evoked | an epoch shape, triggered by the schedule | around a named focus (C3, Cz, Fz, Oz, …) |

Distances come from the **stream's own CED montage**, so the simulation and the viewer's head map
describe the same electrodes — there is no second copy of the geometry to drift out of step. The
shipped 64-channel montage is compiled in as the default, so this lane produces a laid-out head
with nothing configured. A montage shorter than the channel count puts the remaining electrodes on
a ring: an approximate position is a smaller lie than no neighbours at all.

The mixing costs N² multiplies per sample; `correlated=false` turns it off, which is also the
right control condition when you want to know whether a result depends on the correlation.

⚠ **`driftAmp` defaults to 30 µV of independent wander with a 20 s time constant, and over a short
recording that dominates the variance.** Measured on the 20 s run in §7, raw pairwise correlations
between electrodes span −0.75…+0.61 — essentially one random slope per channel. After a 1 Hz high
pass they span 0.18…0.74 and fall off with distance exactly as designed. This is realistic (real
electrode drift *is* independent), but measure topography above the drift, as every real analysis
and the viewer's own display filter do.


<a id="history-6-pacing"></a>

## 6. Pacing

The old generator ran on a `QTimer`, which is recorded in
[known-issues §16d](../incidents/33-framework-traps-found-building-playbackservice-2026-08-15.md#history-16d-qtimer-cannot-pace-anything-finer-than-156-ms-on-windows) as
a defect of this module by name. ⚠ **The constraint is Windows', not Qt 5's, and moving to
Qt 6.11.2 did not lift it:** Qt's Windows dispatcher arms timers with `SetTimer`, so a
`QTimer` fires on a `WM_TIMER` and is quantized to the ~15.6 ms tick whatever `Qt::PreciseTimer`
suggests. At 25 kHz block 100 — 4 ms — that bunches every fourth block into one wake.

`pacer.{hpp,cpp}` is a `CREATE_WAITABLE_TIMER_HIGH_RESOLUTION` on its own thread, the same
mechanism and the same fallbacks as `playbackService`. Measured in §7: **0.377 ms mean, 0.853 ms
worst** lateness, and an inter-block interval of exactly 100.000000 ms.

**The pacing survived the port intact.** `pacer.hpp` and `pacer.cpp` are **byte-identical** in
`R:\src` and `R:\src_Qt5`, and `service.cpp` still starts the pacer on its own
`QThread::TimeCriticalPriority` thread. The only `QTimer`s left in the service are the status, apply
and `autoStart` timers, none of which paces a sample. The lateness figures above were measured under
Qt 5.15.2 and have **not** been re-measured under Qt 6.11.2 — what is established is that the
workaround is still there and still needed, not that the numbers are unchanged.

Blocks are **stamped with the instant they were scheduled for, not the instant they went out**.
The intended timeline is then exact, and the module's own lateness shows up honestly in
`received − created` instead of being hidden. The old generator stamped at send time, which is the
only reason its jitter never appeared in any recording made from it.

⚠ This is the **second** copy of that class in the tree. Promoting it to `Core/Resonance` would
suit any service that emits on a schedule; that is a framework change and was not done in passing.


<a id="history-7-verified"></a>

## 7. Verified

**68/68 unit tests** (`test_SignalGenerator`) — the waveform library asserted against closed-form
values, the plan's text round trip, the schedule's every pattern and code mode, the epoch shapes'
latencies, and the EEG model including that **a stream is bit-identical at block sizes of 7 and
1000**, that the electrode correlation follows `exp(-d/λ)`, and that a seed reproduces a session
exactly.

**56/56 live checks** against a 20 s recording of all five streams, made through
`recorderService` from the deployed `R:\dist\msvc64` — the tree now called
`R:\dist_Qt5\msvc64` — via `signalGenerator.bat`, and read back with h5py. Every
assertion is arithmetic on the samples:

⚠ **Measured 2026-08-17, against the pre-isolation `R:\dist\msvc64`** — the tree now
called `R:\dist_Qt5\msvc64`. It was replaced on 2026-08-18. The transport was re-exercised
on the new one — generator to viewer, to `recorderService` and to the Configurator's
embedded recorder, 0 NaN in both files
([network-isolation.md §8.1](../migrations/network-isolation.md)) — but the *signal* assertions below
(duty cycle, sigma, the electrode-distance correlation, the pacer's 100.000000 ms cadence) have
**not** been re-run. Nothing in the change touches sample generation; they are simply older than
the binary.

⚠ **And none of it has been re-run against the Qt 6 build.** What that build has is the
registered `test_SignalGenerator` — the waveform, schedule and channel-plan logic, built into
`R:\src\_build\tests\` and run by CTest — plus `R:\src\docs\VALIDATION.md`, "Generator,
recorder, and playback validation", where the synthetic three-channel `generated` stream was
published, recorded through `recorderService` and replayed. Every figure in the table below has
Qt 5 provenance.

| | |
|---|---|
| `generated` | 6 channels, names/kinds/units as configured; ch1 a 10 Hz sine at exactly 1e-4, ch2 20 Hz (**and not the same trace** — the old generator gave every channel identical samples); ch3 a square at a measured **25.25 %** duty; ch4 noise at σ = 5.007e-4 against 5e-4 asked; ch5 **15.00 % NaN, every one at `index % 20 < 3`** and 1.0 everywhere else |
| trigger | only 0/1/2, **41 pulses at a median 500-sample spacing, every one exactly 20 ms wide**, codes alternating with the labels |
| cadence | inter-block interval **median 100.000000 ms, max deviation 0.000000 ms** |
| `eeg` | 12 channels (8 EEG + 2 EMG + AUX + Trigger), electrodes named `T7 TP9 P7 CP5 …` from the montage with `theta`/`radius` published; σ = 21.6 µV; correlation falls off with distance (nearest half r = 0.504, farthest 0.305); the trigger carries the same codes on its own 500 Hz clock |
| `epochs` | 40 blocks of exactly 400 samples, **peak at sample 100** (the event), amplitude 6 × 50 µV as the TEP artifact defines, silent pre-stimulus, a negative N100 |
| `stimuli` | 41 messages, template expanded, labels cycling, **exactly 500.000000 ms apart** |
| `status` | 16 named channels, 200 blocks counted, 41 events, high-resolution pacer confirmed in use |

**Parameter shape**, through the real `ParametersView`: 101 parameters, four groups in the
intended order, each leading with enable + stream name, no legacy name missing, 91 typed, 89 with
tooltips.

**A saved configuration loads in full.** `--serviceConfig R:\config\siggen_config_roundtrip.json`
applied all ten parameters in one go — including a three-line channel plan — and the service
auto-started with `planStatus = ok` and the AUX and trigger rows intact. This is the claim in §3
being checked rather than asserted.

Harnesses: `R:\config\siggen_params_check.qml`, `siggen_record_harness.qml`,
`siggen_config_check.qml`, `siggen_config_roundtrip.json` — all four still present, and
tree-independent: they drive the service over the EventBus, so they work against either build.
⚠ The evidence HDFs were written to what was then `R:\dist\_build\siggen-verify\` — that
tree is now `R:\dist_Qt5\_build\`, and it no longer holds that directory. The recordings were not
preserved.

<a id="history-defects-this-rework-found-and-fixed"></a>

### Defects this rework found and fixed

Three in the old generator, all read out of `generator.cpp` and all confirmed by the tests:

| | |
|---|---|
| **`dirtySine` was bit-identical to `fixedSine`** | `case fixedSine: case dirtySine:` fell through. The mode had existed since the module did and had never differed by one sample. It now adds noise, as its name says. |
| **`fixedNaNMeander` emitted `+∞`, not NaN** | `amplitude / (bool)` is `amplitude/0.0` for half of every second. Same 1 Hz timing now, and actually NaN. |
| **Every channel carried identical samples** | A consumer that transposed, swapped or dropped a channel produced bit-identical output, so no 70-channel test could ever have caught one. `shiftStep` and `signatureStep` fix it, both defaulting to 0 so the original behaviour is exactly reproducible. |

And one introduced during this rework, caught by the recording rather than by a test:
**entering `running` republished the streams**, destroying the connections a recorder had just
made in `armed` and undoing the whole point of arming. 172 → **203** blocks on the same 20 s run.

<a id="history-not-verified"></a>

### Not verified

* ⚠ **Only MSVC, in both generations.** The Qt 5 build is `msvc64` alone — `mingw32` and
  `mingw64` never compiled this module — and the Qt 6 build is MSVC v143 14.44 alone. The comment
  at the top of `R:\src\SignalGenerator\CMakeLists.txt` still reads "it builds for mingw32,
  mingw64 and msvc64 alike"; that is stale in a file whose `find_package` line asks for Qt6.
* ⚠ **No high-rate run.** Everything here is 500 Hz and 1 kHz at blocks of 50 and 100. The pacing
  argument in §6 is about 4 ms blocks at 25 kHz, and that case was reasoned, not measured.
* ⚠ **The table window was driven programmatically**, not by hand: the plan was loaded from a
  config and the window rendered from it. Bulk edits, cell editing and the enum delegates were not
  clicked through.
* ⚠ **No consumer beyond `recorderService`.** The viewer's grouping, the head map and `tepService`
  were not pointed at these streams; the metadata they key on is asserted in the file instead.
* `Int32` remains unproduceable — the class has a header and a decoder but no `fromBinary`, and
  `HDFRecorder` handles only `Float64` and `Message`. Nothing here changes that.


<a id="history-8-traps-worth-carrying-elsewhere"></a>

## 8. Traps worth carrying elsewhere

* **`RESONANCE_RECORD_PATH` is not set by the shipped launchers on this machine — fixed in
  `R:\dist`, still true of `R:\dist_Qt5\msvc64`.** Every Qt 5 `.bat` writes `call env`, and this
  PC has `NoDefaultCurrentDirectoryInExePath` set, so the call does not resolve and the variable is
  never exported — recordings then land in the working directory (`bin\`) instead of `data\`.
  Two 2.5 MB files were written into `R:\dist\msvc64\bin` — now `R:\dist_Qt5\msvc64\bin`
  — during this session before it was spotted. All sixteen service launchers in `R:\dist` now write
  `call "%~dp0env.bat"` followed by `cd /d "%RESONANCE_DIR%\bin"`, so the trap is closed there;
  only `pygame_test.bat` and `pyqt5_test.bat` still carry the bare form.
* **`QVector` has no `assign()` in Qt 5**; `fill(value, size)` is the equivalent there. ⚠ **The
  trap inverts in the Qt 6 tree.** `QVector` is an alias for `QList` under Qt 6
  (`qcontainerfwd.h`: `template<typename T> using QVector = QList<T>;`) and `QList::assign` arrived
  in Qt 6.6, so on 6.11.2 the `std::vector` spelling compiles and does what it says. Reach for
  `fill()` only in code that must also build in `R:\src_Qt5`; the same inversion is written up in
  [estim.md](estim.md).
* **`ResonanceApp::instance()` returns a reference**, not a pointer, and
  `Parameters::Integer::value()` and friends are **not const** — which decides whether the methods
  that read them can be.
* **`PrintWindow(h, dc, 2)` captures a Qt window's own surface**; `Graphics.CopyFromScreen` grabs
  whatever is physically on the display at those coordinates, which on a multi-monitor machine is
  not necessarily the window you asked for.
