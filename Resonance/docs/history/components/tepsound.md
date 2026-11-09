# `tepSoundService` — cue presentation, TMS triggering and online SOUND in one service — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/tepsound.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-2026-09-06--presentation-audit-and-shared-corrections"></a>

## 2026-09-06 — presentation audit and shared corrections

The presentation implementation is now also compiled into the standalone **Stimulus** service.
Its operator guide, defect list and test boundaries are in
[Stimulus presentation](stimulus-presentation.md#history-current-service--2026-09-06).
`presentation_run.inc`, authoring/model/sequence/trigger-plan code, the stage and Qt media classes
are shared source; stimulusService compiles none of the epoching/SOUND/plot/feedback code.

Corrected here as well: premature End completion; paused triggers/media continuing; repeated
media not seeking back; preroll/failure mistaken for onset; zero-offset pulse attribution;
stale Stop/Start notifications; response gates/text collection; failed-load recovery; re-entrant
authoring during validation; Interval lookup; invalid constraint rollback; unsafe media packing;
board residual propagation and Parameter-trigger LOW on shutdown. Selected-display disappearance
and invalid required telemetry now refuse operation. `.tep.json` is accepted through the protocol
parameter and CLI. Letter shortcuts are disabled while typing in text editors, including P.
Selecting another cue or its validation problem commits the previous cue's pending text edit.
Shutdown destroys the QML windows while their service/model properties are still alive, avoiding
the previously observed null-model errors during normal process exit.

Live Qt 5/Qt 6 readback preserves all 135 existing parameter names/types/labels/groups/order;
`presentationOnly` remains the existing 136th Qt 6 parameter. The same synthetic presentation
document was run in deployed TepSound with `presentationOnly=true`, recorded and checked through
HDF5, including complete cue/pulse ordering, End hold, Pause/Resume, Stop/Start and bad-load recovery.
The full enabled CTest suite, including TepSound numerical tests, passes. This is software
validation; physical speaker/panel/trigger onset and real stimulator operation are not qualified.

**Added 2026-08-19.** Reference for `R:\src\tepSoundService` — the active replacement for
[`tepService`](tep.md). It presents cues, fires the stimulator and can run in one of three
explicit modes: presentation only, epoching/MEP without SOUND, or the full online SOUND pipeline.

Read [architecture.md](../migrations/framework-evolution.md) first for what a service is, [service_tep.md](tep.md)
§2 for the continuous pipeline this reuses, and
[service_stimulus-presentation.md](stimulus-presentation.md) §5.4 for why the stage counts
frames instead of milliseconds.

**§3 is the pipeline, in order** — read it before changing anything. **§6 is the parameter guidance,
with a recommended and an edge value for every setting that has one**, and every number in it was
measured rather than estimated.

> **Ported to Qt 6, and shipping as the default.** `R:\dist\tepSoundService.bat` →
> `R:\dist\bin\tepSoundService.exe`, built from `R:\src` against Qt 6.11.2 / MSVC v143 14.44 /
> C++20. The Qt 5.15.2 build survives as the comparator in `R:\dist_Qt5\msvc64`. The numeric core,
> the original 135 parameter names and the four-view console all came across; the explicit
> `presentationOnly` switch is the 136th parameter. The Qt 6 sources pass the
> same numeric reference cases; the only intentional parameter-surface difference is that new
> mode switch, and
> both consoles render at 1696x1019 with the same four views and no clipping
> (`R:\src\docs\VALIDATION.md`, "2026-08-28 tepSoundService validation").
> ⚠ **Two things did not come across unchanged: the multimedia layer (§8) and the
> provenance of every performance number in §5, which is still Qt 5.**
> The retired `tepService` executable exists only in the Qt 5 comparator, so every link below to
> [service_tep.md](tep.md) describes the historical module or the validated arithmetic
> shared into this Qt 6 service.
> Background: [qt5-to-qt6-transition.md](../migrations/qt5-to-qt6-transition.md).

---


<a id="history-0-state-of-play"></a>

## 0. State of play

| | |
|---|---|
| ✚ New module | `R:\src\tepSoundService` — `tepSoundService.exe`, service name **`TepSound`**, launcher `tepSoundService.bat` |
| ✚ Numeric core | `linalg` · `firws` · `spline` · `sound` · `badchannels` · `calibration` · `soundpipeline` · `soundstore` — no Qt in the arithmetic, so all of it is testable without a window |
| ✚ Calibration assets | `montages/mks64_standard.ced` + `calib/mks64_leadfield.h5` — **a pair**, see §2.1 |
| ✚ Protocols | `protocols/library.json`, `protocols/tms-cue-block.json` |
| ✚ Brick library | `import/Resonance/TepSound/` → `bin/Resonance/TepSound/` |
| Reused, not copied | `tepService`'s `dsp` / `pipeline` / `signalworker` / `epochprocessor`, and `stimulusService`'s `stage` / `protocol` / `schedule` / `triggerout`. In `R:\src_Qt5` they are compiled from the parent modules' own directories. Neither parent was ported, so in `R:\src` the same sources sit **byte-identical** under `tepSoundService\shared\tepService\` and `tepSoundService\shared\stimulusService\` — read every `tepService/…` and `stimulusService/…` path below that way in the Qt 6 tree |
| Registration | one line, `add_subdirectory(tepSoundService)` in `R:\src\CMakeLists.txt` |
| Outside the module | **nothing** — no framework change, and neither parent module was edited |
| Built | **Qt 6.11.2 / MSVC v143 14.44 x64, deployed to `R:\dist`.** The Qt 5.15.2 / v142 build is the comparator in `R:\dist_Qt5\msvc64`. ⚠ `mingw32`/`mingw64` have not seen it in either generation |

**Verified:** two real 25 kHz TMS-EEG recordings replayed end to end — **339 of 339 pulses produced
an epoch, none lost**; the preprocessed epoch matches an independent reference to **float32 storage
precision** (3.3e-8 and 3.8e-8 relative), the SOUND operator to **4e-14 relative** — machine
precision — and the reference channel exactly. The current `test_TepSound` executable passes
**69 tests in 23 suites**, including the MATLAB fixture comparisons and the explicit SOUND-off
mode. Details in §7.

<a id="history-what-it-is-for"></a>

### What it is for

`tepService` answers *"is this recording going to be usable?"*. This answers a harder question
that only becomes askable once the artefact is actually removed: **"is this TEP real, in this
condition, right now?"** — which needs the cue that produced it, the pulse that was delivered
into it, a cap that is known to be intact, and the artefact suppressed rather than merely
band-limited.

```
                          ┌──────── cues, 7 s each, 1.5–2 s apart ────────┐
   subject screen ◄───────┤  frame-locked stage, marker stamped at the swap│
                          └───────────────┬───────────────────────────────┘
                                          │ TTL at a chosen offset into the cue
   arduinoTTL BNC2 ◄───────────────────────┘        (gated on the stimulator)
        │
        └──► TMS ──► subject ──► nvx136 (64 EEG + EMG pair + trigger, 25 kHz)
                                     │
                                     ▼
   neuroMS status ──────────►  tepSoundService  ──► epochs   (before SOUND)
   (ready, coil °C)                  │           ──► clean    (after SOUND)
                                     │           ──► average
                                     │           ──► events   (JSON: epoch, model, cap, pulse, cue)
                                     │           ──► status   (Float64, 35 named channels at 2 Hz)
                                     └──────────► console (scalp grid · butterfly · MEP · cap · trials)
```

---


<a id="history-1-what-is-new-and-what-is-inherited"></a>

## 1. What is new, and what is inherited

Three of the four halves of this module already existed and are **referenced from their own
directories in `CMakeLists.txt`, not copied**. That is deliberate: `tepService`'s continuous stage
is validated to one float32 ULP against SciPy over two real recordings, and `stimulusService`'s
stage is measured at 0.05 ms mean cue lateness; forking either would mean a fix reaching one of
them, which is exactly the defect the stimulus audit found across eighteen copies of one
experiment program ([stimulus-presentation §4.2 F4](stimulus-presentation.md)).

| Half | Where it comes from | What it does here |
|---|---|---|
| the continuous stage | `tepService/pipeline.cpp` | trigger on the raw word, artefact interpolation before any filter, stateful band-limiting, guarded window, decimation to 5 kHz |
| the MEP | `tepService/epochprocessor.cpp` | EMG difference, slow-trend removal, peak-to-peak, onset, baseline RMS |
| presentation | `stimulusService/stage.cpp`, `protocol.cpp`, `schedule.cpp`, `triggerout.cpp` | frame-locked cues, the paradigm as a document, a seeded plan, TTL out |
| **the SOUND stage** | **new** | per-channel noise estimation, five-metric cap monitoring, spline repair, the cleaning operator and its schedule |

The new half is a C++ port of `W:\MATLAB\tms\onlineSOUND\python` (the `osound` package), which is
itself a NumPy port of the lab's MATLAB reference. §7 is the evidence that all three agree.

---


<a id="history-2-the-two-things-to-get-right-before-a-session"></a>

## 2. The two things to get right before a session

<a id="history-21-the-montage-and-the-lead-field-are-a-pair"></a>

### 2.1 The montage and the lead field are a pair

SOUND regularises against a forward model. That model is built from electrode positions, and the
asset shipped in `calib/` was built from `montages/mks64_standard.ced`.

⚠ The lab's other 64-electrode file — `montages\mumeg_mks64.ced` in both distributions,
`tepSoundService/testdata/` in `R:\src` and `tepService/montages/` in `R:\src_Qt5` — carries
**the same 64 labels in the same order** and different positions — up to 0.14 in
unit-vector distance, about eight degrees. Pairing one with the other's lead field produces a well-formed operator that is
wrong everywhere and complains nowhere.

So the service checks and **refuses** the pairing rather than warning about it
(`Calibration::checkPairing`), and there is a test for both directions
(`FixtureCalibration.TheOtherLabMontageIsRejectedAgainstThisLeadField`).

The lead field **cannot be regenerated here** and does not need to be. `tesa_sound` draws its 5000
dipoles with MATLAB's own RNG (`rng('default'); randn(3,N)`), a stream no other language
reproduces — and SOUND depends on the lead field *only* through its 64×64 Gram matrix, which is
what the asset carries. `Sound.TheGramRouteEqualsTheLeadFieldRoute` is the proof, and it is
checked against the lead-field route in the suite.

<a id="history-22-the-trigger-is-a-wire-not-a-message"></a>

### 2.2 The trigger is a wire, not a message

The pulse goes out on a TTL line the amplifier records. On this rig that is an **arduinoTTL board's
BNC2**, driven over a COM port: `2=OUT,LOW` when the port opens, `2:P1` per pulse. The board times
its own onset, so neither the PC nor the USB link puts jitter into the stimulus
([arduino-ttl.md](arduino-ttl.md)).

The two service-mediated backends (`Transition`, `Parameter`) are offered and are **not** good
enough for this: measured on this tree at **+57.5 ms after the marker, sd 7.3 ms, range +47 to
+68 ms**. They exist because two rigs depend on them.

> ### ⭐ The trigger wire's state is READABLE from outside the process
>
> `off` / `COM8 (not open)` / `COM8 open` used to be a line in this service's own console window
> and nowhere else — not a parameter, not an event, not a status channel. At the rig on
> 2026-08-22 that made a real question ("does a parameter edit while armed close the port?")
> impossible to test without driving the GUI by hand, so it went untested.
>
> It is now on **both** of the observable surfaces:
>
> * **`events`**, as `{"type":"trigger","event":"state","wire":"COM8 open","ready":true,
>   "open":true,"backend":"Serial","target":"COM8","engaged":true,"why":"armed","was":…}`.
>   Published on every change, at Arm, at Stop, and on reconfigure — `why` says which. `was`
>   carries the previous wire when it differed. **`why: "reconfigured WHILE ARMED"` is the one to
>   watch**: any parameter write re-runs `reconfigure()`, and `TriggerOut::configure()` closes an
>   open port whenever the backend or target names a different connection.
> * **`status`**, as `triggerOutReady` and `triggerOutBackend` (0 None, 1 Serial, 2 Transition,
>   3 Parameter). ⚠ `triggerOutReady` is 1 for backend `None` as well — there is nothing to be
>   unready — so read the pair together, never `triggerOutReady` alone.
>
> ⭐ **Settings confirmed on the TMS rig, 2026-08-22:** `triggerChannel 0`, `triggerBit 0`,
> `triggerEdge Rising`, from that session's own recording. And **do not "fix" `triggerChannel = 0`**:
> against a trigger-only amplifier the pipeline line correctly read `trigger: bit 0 of channel 1,
> rising edge` — 0 resolves to the last channel, which is what a trigger lane is.
>
> ⚠⚠ **THE TMS Trig-Out PULSE IS 120 µs AND THE NVX136 ONLY LEVEL-SAMPLES.** At 1 kHz a pulse
> is caught roughly 12 % of the time (the session saw **1 of 8**); at 25 kHz, **4 of 4**.
> **Record at 25 kHz for anything that counts or times triggers on that rig.** A short count on
> the trigger bit at 1 kHz means nothing — see [neuroMS §9.10](neuroms.md).

⚠ **The epoch is anchored to the amplifier's own trigger edge, not to any of the software
instants.** The service records three times per pulse — the frame the offset landed on (`dueRtc`),
the moment the command went out (`sentRtc`), and, in the recording, the edge itself — precisely so
that the difference between them is measurable rather than assumed.

<a id="history-23-the-stimulator-is-watched-and-it-can-hold-the-pulse"></a>

### 2.3 The stimulator is watched, and it can hold the pulse

Point **`input/tmsStatus`** (⚠ that is the parameter's full name — *not* `tms/tmsStatus`; the
only `tms/*` parameters are `maxCoilTemp`, `requireCharged` and `tmsStaleMs`) at
[`neuroMS`](neuroms.md)'s `status` stream and the run is gated on the machine being ready. Channels are matched **by name** from the stream's own metadata, so a driver
that grows a lane needs no change here — and cannot be misread as a fan speed.

The gate exists for one specific failure: **changing intensity mid-session re-charges the
capacitor, and an experiment that fires before it settles gets a pulse at the previous intensity**,
with nothing in the recording to say so. `neuroMS` derives a `ready` lane for exactly this. A held
pulse is recorded as `{"type":"pulse","event":"skipped","reason":…}` and counted on the console; it
is never silently delivered and never silently dropped.

⭐ **A HAND-FIRED pulse that is refused now says so on the stream too**, as
`{"type":"pulse","event":"refused","source":"manual","reason":…,"blocker":"interlock"|"notArmed",
"pulsesSkipped":n}`. It used to reach only the console, so from outside the process the entire
observable consequence of a refused Pulse press was `pulsesSkipped` ticking up — a count with no
reason, which at the rig on 2026-08-22 left *"no coil is attached"* and *"the stimulator is not
charged"* indistinguishable. `refused` is a **third** value of `event` beside `fired` and
`skipped`, and the distinction is real: `skipped` is a trial that lost its pulse, `refused` is an
operator's key press that was declined and belongs to no trial. Note that the `notArmed` case does
**not** increment `pulsesSkipped` — it never did — which is why the counter is carried in the
event.

With no status stream connected the gate passes everything — a rig that fires from the machine's
own front panel has nothing to gate on, and refusing every pulse there would be worse than useless.

---


<a id="history-3-the-pipeline-in-order"></a>

## 3. The pipeline, in order

The Processing tab exposes the mode selection directly. `No processing` is the strongest bypass;
when it is off, the separate `SOUND` checkbox selects the ordinary-epoching or full path.

```text
                    ┌─ No processing = ON ─► cue/stage/TTL only; analysis worker stopped
 cue + trigger ─────┤
                    └─ No processing = OFF ─► continuous preprocessing ─► epoch + MEP
                                                      │
                                      SOUND = OFF ────┴─► `epochs`; no calibration/repair/clean
                                      SOUND = ON  ───────► calibrate/repair/SOUND/average/classify
```

This distinction is functional, not just a hidden-output switch:

| mode | signal required | montage/lead field | epochs + MEP | SOUND/calibration | presentation/TTL |
|---|---|---|---|---|---|
| **No processing** | no | no | off | off | on |
| **Epoching (SOUND off)** | yes | no | on | off | on |
| **Full (SOUND on)** | yes | yes | on | on | on |

```
 ┌─ continuous stage — tepService/pipeline.cpp, unchanged ──────────────────────────────────┐
 │ 1. trigger edges          on the RAW trigger word, before anything is modified            │
 │ 2. blank the pulse        −0.04…0.85 ms interpolated + a 5-sample boxcar over the joins   │
 │ 3. highpass → lowpass     stateful IIR, continuous: 0.3 Hz drift, 2500 Hz anti-alias      │
 │ 4. guarded window cut     [windowStart − guard, windowEnd + guard] = −400…700 ms          │
 │ 5. decimation ×5          plain subsampling → 5 kHz                                       │
 └──────────────────────────────────────────────────────────────────────────────────────────┘
 ┌─ per-epoch stage — soundpipeline.cpp ────────────────────────────────────────────────────┐
 │ 6. scale ×1e6 → µV                                                       TEMPORAL         │
 │ 7. TMS interpolation      −1…5 ms, a two-point ramp                      TEMPORAL         │
 │ 8. anti-alias FIR 450 Hz + decimate ×5 + trim the guard                  TEMPORAL  (fused)│
 │ 9. baseline −60…−10 ms                                                   TEMPORAL         │
 │10. common average reference                                              SPATIAL          │
 │      └─► the SOUND TRAINING SET is taken here only when SOUND is ON                       │
 │11. channel repair (× ICA, if supplied) — identity when SOUND is OFF       SPATIAL          │
 │      = preproc, 64 × 701 at 1 kHz — published as `epochs`                                 │
 │12. SOUND ON only: clean = M · preproc                                    SPATIAL          │
 │      = published as `clean`                                                               │
 └──────────────────────────────────────────────────────────────────────────────────────────┘
 ┌─ calibration — every dN epochs, on a worker thread ──────────────────────────────────────┐
 │ a. five-metric cap report over the most recent `detectorEpochs` training epochs           │
 │ b. spherical-spline repair matrix R for whatever it flagged                               │
 │ c. SOUND: DDWiener → reference channel → 5 sigma sweeps → the 64×64 operator              │
 └──────────────────────────────────────────────────────────────────────────────────────────┘
 ┌─ presentation — stimulusService/stage.cpp ───────────────────────────────────────────────┐
 │ cue durations in FRAMES, onset stamped in a frameSwapped handler, trigger fired at a      │
 │ frame offset counted from the cue's own onset                                             │
 └──────────────────────────────────────────────────────────────────────────────────────────┘
```

<a id="history-31-why-the-order-is-what-it-is"></a>

### 3.1 Why the order is what it is

**The artefact is removed before any filter.** A TMS artefact is volts against microvolts; through
a second-order IIR it rings for tens of milliseconds, which is exactly the interval the response is
in. Step 2 is on the continuous signal for that reason, and step 7 removes the decay that survives
it over the window the offline pipeline uses.

**Every spatial operator is applied to the trimmed epoch, not to the guarded one.** Temporal
operators here are per channel and identical across channels; spatial operators are per time
sample; **they commute**. So the CAR, the repair, the ICA projection and the SOUND operator may be
applied at any point relative to the filtering — and applying them to 701 samples instead of 5500
costs an eighth as much. Measured: **3.98 ms became 0.34**.

**The anti-alias FIR is fused with the decimation and the trim.** A `valid`-mode convolution's
output at index *k* depends on inputs `k ± groupDelay` and on nothing else, so an output that is
going to be kept has the same value whether or not its neighbours were computed. Computing only
the 701 that survive costs **1.5 ms** where filtering the whole guarded epoch and throwing the
guard away costs **18.8 ms**. The service refuses rather than pads when the guard is too narrow for
the kernel, because that is an epoch-geometry mistake to report and not one to paper over.

**The guard is why no epoch carries a filter transient.** 200 ms either side is cut, filtered with
the epoch and thrown away afterwards. It only has to exceed the FIR group delay, which is 14.8 ms
for the default 450 Hz design at 5 kHz.

<a id="history-32-the-training-set-is-kept-unrepaired-and-that-is-a-departure"></a>

### 3.2 The training set is kept **unrepaired**, and that is a departure

The reference implementation stores the fully spatially-processed epoch and, when the flagged set
moves, tries to undo the previous repair with `R_new · pinv(R_old)`.

A repair matrix is rank-deficient by construction — a repaired channel is an exact linear
combination of its neighbours — so its pseudo-inverse **cannot restore what the repair removed**,
and the correction is applied afresh at every calibration.

⚠ **This was measured here, and it is not theoretical.** With a flagged set that moved between
calibrations, the fifth calibration produced a **sigma of 255 µV on a channel whose true noise
level was under one**; the operator after it made every epoch *worse* (cleaned RMS 119.6 µV against
a pre-SOUND 94.5 µV); the service refused it — *"the noise model did not converge to a usable
operator"* — and then had **no operator at all for the remaining 120 epochs**.

Keeping the unrepaired form removes the problem rather than correcting it: the repair is derived
from a block and applied to that same block, every time, with no history at all. With that change,
the same recording gives a condition number of **105** instead of 24,597, a maximum sigma of
**4.3 µV** instead of 255, and sixteen good calibrations instead of five.

It has a second benefit that matters more over a long session: **the detector sees data it can
*un*-flag a channel from.** It cannot, when every channel it has already repaired looks perfect.

<a id="history-33-the-repair-is-applied-to-the-block-not-to-every-epoch"></a>

### 3.3 The repair is applied to the block, not to every epoch

A matrix commutes with an average, so repairing the mean of the training set is the same answer as
repairing every epoch and then averaging — and it is one 64×64 product instead of N. Under a
cumulative schedule that is the difference between a calibration whose cost grows all session
(58 ms of pure overhead at epoch 170) and one whose cost does not.

<a id="history-34-the-warm-up-cannot-be-avoided-only-displayed"></a>

### 3.4 The warm-up cannot be avoided, only displayed

The noise model is estimated from data, and before the first pulse there is none. So the first
`warmupBlock` epochs are published on `epochs` and not on `clean`, and the console says
*"calibrating — 4 of 10 epochs"*.

What the console *can* do is set **Average of → current model**, which re-cleans every stored epoch
with the newest operator. The difference between that and **online** is the online-versus-static
deviation the offline study measures, and having both live is how an operator sees the noise model
settle instead of assuming it has.

<a id="history-35-an-average-is-an-average-of-one-geometry-and-it-is-the-newest-one"></a>

### 3.5 An average is an average of one geometry, and it is the newest one

Epochs of different lengths are never mixed: changing the epoch window mid-session changes what an
epoch *is*. `SoundStore::reduce()` takes its reference shape from the **newest** contributing epoch
and skips every epoch that does not match it — the same rule as `EpochStore::reduceOver()` in
`tepService`. So a window change costs the average its history: the first epoch collected at the
new window rebuilds it over that one epoch, `n` on the plot and `contributing` on `status` drop to
1, and it grows again from there.

⚠ Anchored the other way — on the oldest — the average would instead freeze at the geometry the
session was already in and skip every arriving epoch until the whole 200-epoch buffer had turned
over, while the console drew it against the new window's axis and the `average` stream withheld it
for being the wrong length. The anchor is what makes a window change cost one trial rather than a
session.

---


<a id="history-4-the-module"></a>

## 4. The module

```
R:\src\tepSoundService\
    main.cpp                    QApplication + ResonanceApp; --signal, --markers, --tmsStatus,
                                --protocol, --montage, --leadfield, --autoArm, --autoStart
    service.{hpp,cpp}           parameters, state machine, streams
    service_analysis.cpp        configuration, input, the epoch path, everything published
    service_run.cpp             protocol, plan, stage, trigger, the stimulator gate, queries
    soundtrainer.{hpp,cpp}      the calibration, on a thread of its own
    views.{hpp,cpp}             TepGridView / TepTraceView, QQuickPaintedItem
    linalg.{hpp,cpp}            Cholesky / LU / Gauss-Jordan / one-sided Jacobi SVD / pinv
    firws.{hpp,cpp}             EEGLAB pop_eegfiltnew + firfilt + the fused decimating apply
    spline.{hpp,cpp}            spherical splines: repair matrix, leave-one-out predictor
    sound.{hpp,cpp}             DDWiener, the sigma sweeps, the operator, the calibration
    badchannels.{hpp,cpp}       five metrics, one badness score, the report
    calibration.{hpp,cpp}       the .ced and lead-field readers, and the pairing check
    soundpipeline.{hpp,cpp}     the per-epoch chain, the training set, the schedule
    soundstore.{hpp,cpp}        the session, the averages, the epoch file
    ui/                         Console.qml, RunBar.qml, SettingsPane.qml, ChannelTable.qml
    stage/StageWindow.qml       the subject screen (stimulusService's file, unchanged)
    import/Resonance/TepSound/  the brick library
    montages/  calib/  protocols/
    tests/                      sound_test.cpp (20 cases), bench_test.cpp, fixtures.hpp
    tepSoundService.bat  CMakeLists.txt  res.qrc
```

<a id="history-41-streams"></a>

### 4.1 Streams

| Stream | Type | What is on it |
|---|---|---|
| `epochs` | Float64, 65 ch × 701 at 1 kHz | the **preprocessed** epoch — repaired, referenced, baselined, before SOUND — with the MEP in the first auxiliary slot |
| `clean` | Float64, same geometry | the same epoch after SOUND. Silent during the warm-up, because before the first operator there is nothing to publish |
| `average` | Float64, same geometry | the running average, published when it moves. Withheld — never padded, truncated or faked — while its length would contradict the window the stream declares, which is the interval between a window change and the first epoch collected at the new window. `averageWithheld` on `status` is 1 for exactly that interval, and the log names the two sample counts once it outlasts half a second |
| `events` | Message, JSON `v: 1` | one record per epoch, per model, per cap report, per pulse (fired, skipped **and** refused), per cue onset, per **trigger-wire state change**, plus session and run lifecycle |
| `status` | Float64, **42 named channels** at 2 Hz | counters, the model, the cap, the MEP, the stimulator, the trial, the two latency figures, `averageWithheld`, and — appended last — `triggerOutReady` / `triggerOutBackend`. ⚠ The list is **APPEND ONLY**; see `statuschannels.hpp` for why and for what every consumer does |

Both epoch streams carry the **trigger's** RTC, not the moment the epoch finished being built: the
build time is an artefact of the window length, and an analysis lines an epoch up against the
stimulus.

An `events` epoch record:

```json
{"v":1,"type":"epoch","n":41,"rtc":"5349385863600","samples":701,"channels":64,
 "rejected":false,"cleaned":true,"modelId":3,"peakUv":118.4,"latencyMs":21.7,"label":"cue_a",
 "mep":{"amplitudeMv":0.387,"onsetMs":17.0,"baselineRmsMv":0.005}}
```

and a model record, which is the one to watch:

```json
{"v":1,"type":"model","modelId":3,"trainEpochs":40,"bestChannel":"CP1",
 "sigmaMedian":0.35,"sigmaMax":4.30,"convergence":0.0083,"conditionNumber":105.0,
 "trainMs":13.1,"badChanMs":8.5}
```

<a id="history-42-the-epoch-file"></a>

### 4.2 The epoch file

Written by the service on the way into `idle`, in the layout the lab's offline scripts already
read, plus everything a comparison against the offline pipeline needs so that nothing has to be
re-run:

| Dataset | |
|---|---|
| `epochs` | `[n_epochs × n_samples, n_channels]` float32 — the **cleaned** form, with `Fs`, `n_epochs`, `n_samples`, `n_channels`, `window_start_ms`, `window_end_ms`, `source` as attributes |
| `preproc` | the same shape, before SOUND |
| `timestamps` · `labels` · `rejected` · `peak_uV` · `model_id` · `latency_ms` | one per epoch |
| `mep/amplitude_mV` · `mep/onset_ms` · `mep/baseline_rms_mV` | |
| `sound/operator` · `sound/sigmas` · `sound/convergence` | the last model, with `best_channel`, `train_epochs` and `condition_number` as attributes |
| `channels/labels` · `channels/badness` · `channels/flag` · `channels/incoherence` · `channels/dominant` | the last cap report |

⚠ **`latency_ms` is in the file on purpose.** "The pipeline kept up" should be a measurement in the
evidence, not a claim in a log nobody kept.

<a id="history-43-states"></a>

### 4.3 States

```
idle ──arm──► armed ──start──► running ⇄ paused
  ▲             │                 │         │
  └──── stop ───┴──── stop ───────┴─────────┘
        (also: start straight from idle, passing through armed)
```

**`armed` is a real state, not a formality: it is where the hotspot is found.** The analysis
collects, the MEP strip fills and the SOUND model warms up on hand-fired pulses (the `Pulse` button
or the `pulse` action), and nothing is presented to the subject.

Every state does its work on **entry**, so the Configurator, a script, `--autoStart` and the
console button cannot take different paths — the divergence the stimulus service's acceptance run
found the hard way.

Pausing stops **presenting**. It deliberately does not stop the continuous stage, which is built
around seeing every sample exactly once and in order: starving it would leave a gap in the filter
state, and the first epoch after resuming would carry the ring from that discontinuity.

---


<a id="history-5-performance-measured"></a>

## 5. Performance, measured

⚠ **Every number in this section was measured on the Qt 5 build and none of it has been
re-measured under Qt 6.11.2 / v143.** That matters more here than in most service references,
because **§6's parameter guidance is derived from these timings** — if a figure moved, the
recommended edge moved with it. What is known: the numeric core is Qt-free arithmetic and its Qt 6
build passes the same 230 reference cases, and the one substitution the port made — Qt 6
multimedia (§8) — does not sit in the per-epoch path. Treat the figures as a strong prior and
the parameter edges as unconfirmed until a Bench run is done against the Qt 6 binary.

Every number below is from this machine (ANATOLYHOME2024, MSVC v142 x64, Release), at the rig's
own shapes: 64 EEG + 2 EMG + trigger at 25 kHz, a guarded [−400, +700] ms epoch at 5 kHz, delivered
as [−200, +500] ms at 1 kHz. Reproduce against the Qt 5 comparator with

```bash
R:\dist_Qt5\_build\msvc64\tests\test_TepSound.exe --gtest_filter=Bench.*
```

and against the Qt 6 default with

```bash
R:\src\_build\tests\test_TepSound.exe --gtest_filter=Bench.*
```

⚠ `R:\src\_build` is a stale cache bound to the tree's pre-rename path and must be deleted and
re-configured before it will build again (`rm -rf R:/src/_build R:/src/_build-kardi2-x32`). The
executable already in it is from the last build under the old path and still runs.

<a id="history-51-what-an-operator-waits-for"></a>

### 5.1 What an operator waits for

| | |
|---|---|
| **epoch tail** — the window's right edge plus the guard | **700 ms** |
| **per-epoch processing**, live, median / p95 / max over 170 real epochs | **21.6 / 23.6 / 24.7 ms** |
| → a cleaned epoch exists | **~722 ms after the pulse** |
| duty cycle at this paradigm's 8.5 s pulse spacing | **0.25 %** |
| duty cycle at the reference data's 1.34 s spacing | **1.6 %** |

⚠ **87 % of that 21.6 ms is one setting.** The MEP slow-trend removal is a 500-sample running
median over a 5500-sample trace; with `Remove slow trend` off the same epochs cost **2.9 ms**
median (measured, not modelled: 170 epochs each way). It is on by default because the MEP number is
worth more than 19 ms at any plausible ISI — but if the epoch is wanted sooner, that is where the
time is, and shortening `Trend window` is proportionally cheaper.

<a id="history-52-the-per-epoch-chain-stage-by-stage"></a>

### 5.2 The per-epoch chain, stage by stage

| stage | cost | note |
|---|---|---|
| de-interleave + scale | 0.8 ms | 66 → 64 channels, sample-major to channel-major |
| TMS interpolation | 0.001 ms | a two-point ramp |
| anti-alias FIR + decimate + trim, fused | **1.5 ms** | 149 taps; 18.8 ms if the whole guarded epoch were filtered |
| baseline | <0.05 ms | |
| CAR + repair (two 64×64 products) | 0.38 ms | on 701 samples, not 5500 — §3.1 |
| SOUND apply (one 64×64 product) | **0.34 ms** | |
| **SOUND chain total** | **2.6 ms** | |
| MEP: difference + median detrend + measure | **19 ms** | §5.1 |

<a id="history-53-calibration-on-its-own-thread"></a>

### 5.3 Calibration, on its own thread

| training epochs | cap report | repair matrix | SOUND train | total |
|---|---|---|---|---|
| 10 | 5.7 ms | 0.9 ms | 12.2 ms | **18.8 ms** |
| 20 | 8.5 ms | 1.0 ms | 12.8 ms | **22.2 ms** |
| 40 | 15.0 ms | 1.0 ms | 13.1 ms | **29.0 ms** |
| 80 | 28.2 ms | 0.9 ms | 13.1 ms | **42.2 ms** |

The two halves scale differently, and that is why `Screen over` (`detectorEpochs`) exists. SOUND
trains on the trial average, so **its cost does not depend on how many epochs went into it** —
about 13 ms whether that is ten or a hundred. The cap report concatenates them, so its cost is
linear. Capping the report at 20 epochs holds a cumulative session's calibration at **~22 ms
forever** instead of letting it grow to 175 ms by epoch 500.

Cost of the noise-level refinement, which is the term an operator actually turns (20 epochs):

| iterations | 1 | 3 | **5** | 10 | 20 |
|---|---|---|---|---|---|
| | 8.2 ms | 10.6 ms | **12.9 ms** | 18.6 ms | 30.9 ms |

And `Train on`, whose cost surprises people: **mean 12.8 ms, concatenated 99.7 ms** at 20 epochs —
and the second grows linearly with the block where the first does not.

<a id="history-54-primitives"></a>

### 5.4 Primitives

| | |
|---|---|
| 64×64 operator × 64×701 epoch | 0.34 ms |
| fused FIR 149-tap + decimate ×5 | 1.49 ms |
| `firfilt` over the whole guarded epoch | 18.77 ms |
| DDWiener, 64 × 701 | 1.74 ms |
| spline repair matrix, 2 bad channels | 2.04 ms |
| leave-one-out predictor (once per montage) | 0.32 ms |
| 64×64 SVD (the condition number) | 2.70 ms |

<a id="history-55-memory"></a>

### 5.5 Memory

| | |
|---|---|
| one stored epoch | **~360 KB** — `preproc` and `clean`, 64 × 701 float32 each |
| `Keep epochs` = 200 (default) | ~72 MB |
| the SOUND training set, per epoch | 180 KB — bounded under `sliding`, **unbounded under `cumulative`** |
| `Keep raw epochs` on | **+1.45 MB per epoch**, 66 × 5501 float32 |

---


<a id="history-6-parameters--recommended-and-where-the-edges-are"></a>

## 6. Parameters — recommended, and where the edges are

Every "edge" below is a value that still works and says what it costs. A value outside the stated
range is either refused by the parameter's own limits or produces a console warning.

<a id="history-60-processing-mode"></a>

### 6.0 Processing mode

| Parameter | Recommended | Edge | Why |
|---|---|---|---|
| `presentationOnly` (`No processing`) | **off** for TEP/MEP work; **on** for cue/trigger-only sessions | — | On stops the analysis worker and removes all signal, epoch, MEP, average, classifier and SOUND work. It also removes the montage/lead-field dependency. |
| `soundEnable` (`SOUND`) | **on** for cleaned TEP; **off** for ordinary epoching/MEP | — | Off is modular: epochs, preprocessing, rejection and MEP stay active, while calibration, cap detection, repair, noise-model training and the `clean` stream stop. |

<a id="history-61-epoch-geometry--the-settings-that-decide-the-wait"></a>

### 6.1 Epoch geometry — the settings that decide the wait

| Parameter | Recommended | Edge | Why |
|---|---|---|---|
| `windowStart` | **−200 ms** | −100 … −500 | Must hold the baseline with room to spare. Shorter than −100 leaves no clean pre-stimulus interval; longer only costs memory |
| `windowEnd` | **500 ms** | **250 ms** for a fast console; 1000 for late components | ⚠ **This is the dominant term in the wait.** The TEP components of interest end by ~200 ms, so 250 costs nothing scientifically and saves a quarter of a second per trial |
| `guardMs` | **200 ms** | **50 ms** | Only has to exceed the FIR group delay, 14.8 ms at the default 450 Hz. 50 is ample; the service refuses a guard too narrow for the kernel rather than padding |
| `workRate` | **5000 Hz** | 25000 (no decimation) / 2500 | The MEP is measured here, so it sets the MEP's time resolution. Must divide the amplifier rate exactly |
| `outputRate` | **1000 Hz** | 500 … 5000 | Must divide `workRate` exactly. Above 1 kHz the epoch grows and every spatial product with it |
| `blankFrom` / `blankTo` | **−0.04 / 0.85 ms** | ±5 ms for a longer hardware spike | The *hardware* artefact only. Widening it widens the pipeline's look-ahead (`holdMs`) one-for-one |
| `tmsInterpFrom` / `tmsInterpTo` | **−1 / 5 ms** | to 10 ms | The TESA default. The earliest component this paradigm looks at is ~15 ms, so beyond 10 it starts costing signal |

**The combination that makes an epoch fastest**: `windowEnd` 250, `guardMs` 50, `Remove slow trend`
off → **~303 ms after the pulse** instead of 722, with no change to anything scientific except the
MEP detrend.

<a id="history-62-filters"></a>

### 6.2 Filters

| Parameter | Recommended | Edge | Why |
|---|---|---|---|
| `preHighpass` / `preHighpassHz` | **on, 0.3 Hz** | 0.1 … 1 Hz | The causal substitute for the offline centred 2 s median, which needs a second of future data. The per-epoch baseline removes anything constant across an epoch, so the two differ only far below 1 Hz |
| `preLowpass` / `preLowpassHz` | **on, 2500 Hz** | must stay above `workRate`/2 | The anti-alias filter for the drop to 5 kHz. ⚠ Switching it off while decimating is the one filter setting that silently corrupts a result — the console warns |
| `preNotch` | **off** | 50 Hz, width 1 | SOUND suppresses a mains component that the montage cannot explain anyway |
| `antiAliasHz` | **450 Hz** | must stay below `outputRate`/2 | The per-epoch FIR ahead of the drop to 1 kHz. At 450/1000 it is the reference pipeline's setting; the console warns at or above Nyquist |

<a id="history-63-sound"></a>

### 6.3 SOUND

| Parameter | Recommended | Edge | Why |
|---|---|---|---|
| `soundEnable` | **on** for SOUND; off for epoching without SOUND | — | With it off no montage, lead field or calibration is required, and `clean` remains empty. Use `presentationOnly` instead if no signal processing at all is wanted. |
| `soundLambda` | **0.01** | 0.003 … 0.05 | The published value. Larger suppresses more and smooths the topography; **below ~0.001 the operator starts to amplify the very channels the noise model just called noisy** — watch the condition number on the console, which should sit in the hundreds and not move much between calibrations |
| `soundIterations` | **5** | 3 … 10 | Linear in cost and the dominant calibration term. The convergence figure says whether more would buy anything: on real data it goes 2.6 → 0.008 over five sweeps, and once it is under a percent the answer is no |
| `soundTrainOn` | **mean** | concatenated | Mean is what the reference does and costs the same whatever the block size. Concatenated sees single-trial noise and costs **8× more at 20 epochs**, growing with the block |
| `scheduleMode` | **cumulative** | `sliding` for a drifting cap, `static` to reproduce an offline result | Cumulative keeps improving and stops moving — the lab's own study settles by ~40 trials. Sliding follows a cap that is drying out, at a noisier estimate. Static is the reproducible choice |
| `trainN` | **10** | 5 … 40 | Sliding block size, and the first cumulative block. Larger stabilises the estimate; smaller reaches a usable operator sooner |
| `trainDn` | **10** | 5 … 20 | Epochs between calibrations. On a worker thread an operator never sees the cost; below 5 the operator moves faster than the data justifies |
| `warmupBlock` | **10** | 5 … 20 | Below about 5 epochs the noise estimate is dominated by whatever the first few trials happened to contain |
| `excludeRepaired` | **on** | — | A repaired channel is an exact linear combination of its neighbours, so its residual is artificially tiny and it wins the reference-channel argmin every time — putting the reference on a channel carrying no independent signal |

<a id="history-64-the-cap"></a>

### 6.4 The cap

| Parameter | Recommended | Edge | Why |
|---|---|---|---|
| `badChanEnable` | **on** | — | ⚠ On the reference recording, repairing FT9 took the epoch peak distribution from a **median of 4230 µV to a median of 120 µV**. The amplitude criterion below is unusable without it |
| the five metrics | **all on** | kurtosis alone reproduces the offline pipeline | The offline screen is kurtosis alone and on this data it misses the channel that destabilises SOUND: kurtosis measures peakedness, not amplitude, and its `[50 300] ms` window excludes the early artefact where a stimulation-site electrode misbehaves |
| `kurtosisThreshold` | **5** | 3 … 8 | EEGLAB's own default, as \|z\| of the trimmed kurtosis |
| `amplitudeThreshold` | **5** | 3 … 8 | \|robust z\| of log₁₀(std) |
| `incoherenceThreshold` | **8** | 4 … 15 | σ / median(σ). Measured on the reference recording: a healthy cap sits at 1.5–2.6 and the bad channel at **200** — the metric separates by two orders of magnitude, so the threshold is not delicate |
| `neighbourThreshold` | **0.8** | 0.5 … 1.0 | 1 − corr with the spline prediction, also scored as a robust z, worse of the two wins |
| `flatlineThreshold` | **0.01** | 0.005 … 0.05 | std / median(std) below this is a dead electrode |
| `maxBadFrac` | **0.25** | 0.1 … 0.4 | More flagged than this and only the worst are repaired, with the report marked CAPPED — a strong signal that something is wrong with the recording as a whole |
| `badPasses` | **2** | 1 … 3 | A bad channel corrupts its neighbours' predictions; pass 2 re-scores with pass 1's flags excluded. Three has never changed an answer here |
| `detectorEpochs` | **20** | 10 … 40; 0 = every epoch | §5.3. The screen saturates; its cost does not |
| `protectedChannels` | the central ring | — | ⚠ **`C5`/`C6` sit next to the M1 hand knob and are deliberately not in the default list.** On the lab's own data `C5` is exactly the case this exists for — σ 19 µV against a 0.65 µV median, not a broken electrode but the one carrying the artefact SOUND is meant to suppress. Decide it per montage **before** going live |

<a id="history-65-rejection"></a>

### 6.5 Rejection

| Parameter | Recommended | Edge | Why |
|---|---|---|---|
| `rejectPeakUv` | **0 (off) until a pilot says otherwise** | ~2× the observed median peak | Every epoch's peak is reported whether or not a threshold is set, so one can be *chosen* rather than guessed. On the reference recording with repair on, the peak distribution is median 120 µV / p95 2885 / max 14,357 — so ~3000 is right there and **1500 rejected 162 of 170 epochs**, leaving the model untrainable. ⚠ A threshold set before the cap is repaired is a different number entirely (§6.4) |
| `rejectFrom` / `rejectTo` | **10 / 500 ms** | 15 / 300 | Must start after the interpolated TMS span or it measures a straight line |
| `mepRejectRms` | **0 (off)** | 0.02 … 0.05 mV | Pre-innervation is a finding about the session; a rejected epoch is kept and marked, never dropped |

<a id="history-66-presentation"></a>

### 6.6 Presentation

| Parameter | Recommended | Edge | Why |
|---|---|---|---|
| cue `duration` | **7000 ms** | ≥ 2000 | Below ~2 s the pulse lands in the cue's own onset transient rather than in a settled state |
| `triggerOffset` | **3500 ms** (the middle) | ≥ 700 after the onset, ≥ `tailMs` before the cue ends | Must clear the cue's own evoked response and leave the epoch's right edge inside the trial |
| `isi` | **1500–2000 ms**, randomised | ≥ 500 | Randomised so the subject cannot anticipate; drawn from a **recorded seed**, so a session can be reproduced |
| pulse-to-pulse spacing | **8.5–9.0 s** here | **> `tailMs`** (700 ms) | Below the tail the console is permanently a trial behind the subject. The service warns |
| `refractoryMs` | **500 ms** | just under the pairing interval for paired-pulse; 0 accepts every edge | Stops a bouncing TTL opening two overlapping epochs |
| `triggerBackend` | **Serial** (arduinoTTL BNC2) | `None` when the pulse comes from elsewhere | §2.2 |

<a id="history-67-memory-and-display"></a>

### 6.7 Memory and display

| Parameter | Recommended | Edge | Why |
|---|---|---|---|
| `epochBuffer` | **200** | 50 … 1000 | ~360 KB each, so 1000 is ~360 MB |
| `keepGuarded` | **off** | on for a pilot, with `epochBuffer` lowered to match | +1.45 MB per epoch. On, changing the baseline / CAR / anti-alias re-derives the whole session; off, they apply from the next epoch |
| `averageSource` | **online** | `current model` to watch the model settle | Online is what was actually published, and is the scientific product |
| `averageMethod` | **mean** | median for a session with a handful of ruined epochs | |

---


<a id="history-7-verified"></a>

## 7. Verified

<a id="history-71-unit--test_tepsound-69-tests--23-suites"></a>

### 7.1 Unit — `test_TepSound`, 69 tests / 23 suites

The original numerical core comprised nine self-contained invariants and eleven comparisons
against the MATLAB reference fixtures in
`…\compareSOUND\onlineSOUND_unitTest\reference\unit_test_fixtures.h5` and **skip** rather than fail
when the share is unreachable, so a build machine without it still builds green. The suite has
since grown to 69 tests covering the experiment document, media, presentation state, feedback,
rendering, and the modular processing modes as well.

| Check | Against | Agreement |
|---|---|---|
| FIR kernels, three designs | MATLAB `firws` | < 1e-13 |
| FIR application over 64 × 601 | MATLAB `firfiltEpochs` | < 1e-9 |
| spherical-spline repair matrix | EEGLAB `pop_interp` | < 1e-10 |
| DDWiener sigmas and prediction | MATLAB `ddWiener` | < 1e-9 |
| the SOUND operator, both routes | MATLAB `tesa_sound` | < 1e-9 relative |
| the calibration end to end — reference channel, sigmas, convergence, operator, cleaned output | MATLAB | exact channel, < 1e-5 relative |
| the kurtosis screen and its flagged set | EEGLAB `pop_rejchan` | exact set, z < 1e-3 |
| **the whole per-epoch chain** on three real guarded epochs | MATLAB `preprocessEpochs` + `applySound` | **< 5e-3 µV** (float32 storage) |
| the montage/lead-field pairing check, both directions | — | accepts the pair, rejects the other montage |

Plus the two facts the design rests on, asserted rather than assumed: `operatorFromGram` equals the
lead-field route, and the fused decimating FIR equals filter-then-decimate-then-trim.

<a id="history-72-end-to-end-against-a-real-recording"></a>

### 7.2 End to end, against a real recording

Two recordings from `…\compareSOUND\rawData` — `13_01AV_M1_AP_43MSO_offBCI.hdf5` (3.18 GB, 67
channels at 25 kHz, 236.9 s, **170 TMS pulses at a 1.21–1.51 s interval**) and
`12_02NS_M1_AP_54MSO_offBCI.hdf5` (3.19 GB, 169 pulses) — replayed by `playbackSource` as a live
`NVX136`-shaped service and analysed by the deployed binary.

```bash
R:\config\tepsound_validation_run.ps1 -Raw <recording> -Out <epochs.h5> -Speed 1
R:\config\tepsound_reference_pipeline.py <recording> <epochs.h5>
```

| Check | `13_01AV` (170 pulses) | `12_02NS` (169 pulses) |
|---|---|---|
| Pulses / epochs / lost | **170 / 170 / 0** | **169 / 169 / 0** |
| First epoch aligns to | the file's **first** trigger, 1.2e-4 µV | the file's **first** trigger, 3.7e-6 µV |
| **`preproc`** vs the reference | **max 5.0e-4 µV** against a 15,140 µV signal — **3.3e-8 relative**, i.e. float32 storage precision | **max 1.6e-5 µV** against 431 µV — 3.8e-8 relative |
| **SOUND operator** vs the reference | **4.1e-14 relative** — machine precision | **4.6e-14 relative** |
| **sigmas** vs the reference | max 5.7e-13 µV | max 1.7e-14 µV |
| Reference channel | **identical** | **identical** |
| **`clean`** vs operator × preproc | max 2.2e-5 µV over 6,729,600 values | max 2.6e-5 µV over 6,684,736 |
| Condition labels from the **legacy** `{"stimulus": …}` marker stream | 86 `hand` / 84 `rest`, all labelled | all labelled |

⚠ **The reference is genuinely independent, and it is two implementations rather than one.** The
continuous stage is checked against `R:\config\tep_reference_pipeline.py` — the NumPy/SciPy
re-implementation `tepService` was validated against — and the per-epoch stage against the `osound`
NumPy package, which is itself validated against MATLAB. An agreement here is agreement between
three implementations, not evidence of a shared bug.

<a id="history-73-an-operational-run"></a>

### 7.3 An operational run

The same recording with the settings an operator would actually use — five metrics on, cumulative
schedule, retrain every 10:

| | |
|---|---|
| Epochs / models / cleaned | 170 / **16** / 160 (10 warm-up) |
| Flagged | `FT9`, `Fp2`, `AF8` — no protected electrode over threshold |
| `FT9` incoherence | **200×** the montage median; every other channel between 1.5 and 1.8 |
| Noise model | σ median **0.346 µV**, max 4.30 µV; convergence 2.65 → **0.0083** over five sweeps; condition number **105** |
| 15–120 ms window, over the 160 cleaned epochs | pre-SOUND rms **34.3 µV** → cleaned **11.0 µV**; peak 249 µV → 154 µV |
| Condition averages | `hand` n=81, GFP peak 1.96 µV at 120 ms · `rest` n=79, GFP peak 2.95 µV at 28 ms |
| Live per-epoch processing | median **21.6 ms**, p95 23.6, max 24.7 |
| Errors | none |

---


<a id="history-8-not-verified"></a>

## 8. Not verified

Stated plainly, because §7 reads like completion.

* **No amplifier, no stimulator, no TTL box.** Everything was driven from `playbackService`
  replaying a recording. That is the stricter path for the *pipeline* — the samples are known in
  advance and can be checked — and says nothing about a live driver's block cadence, a mid-session
  restart, or an impedance-mode switch.
* **The stimulator gate has never held a real pulse.** `neuroMS` was not attached; the lane names
  it matches are read from `service_neuroms.md` §5 and from the driver's own channel table, and the
  gate has been exercised only with no stream connected (which passes everything, by design).
* **The trigger has never fired.** No COM port with an arduinoTTL board on it was available. The
  backend is `stimulusService`'s, unchanged, and its serial path is
  [also unexercised there](stimulus-presentation.md#history-what-is-still-not-verified).
* **No subject screen has shown a cue in this service.** The stage is `stimulusService`'s file
  compiled into this binary; the plan, the protocol and the queue are the same code, but no run has
  been presented. The `armed` path — which is what the analysis half needs — is what §7 exercised.
* **No photodiode**, so the constant offset between the swap and the light is inherited as an
  unmeasured one to two frames.
* **The console has not been operated by a person.** It loads clean and its bindings resolve;
  nobody has dragged a stream onto it or clicked through a session.
* **`mingw32` / `mingw64` have not seen this module**, in either generation. A compile is not a
  build, and neither has even compiled it.
* ⚠ **The Qt 6 frame counter no longer knows that the *output* accepted the frame.** Under Qt 5,
  `videocue.cpp` carried a `FrameRelay : QAbstractVideoSurface` whose `present()` forwarded to the
  real surface and incremented the counter **only when that call returned true** — the line the
  file said it existed for, because it let the stage say a video cue had begun and mean the picture
  rather than the intention. Qt 6 removed `QAbstractVideoSurface`; the relay is gone, and the
  counter is incremented from `QVideoSink::videoFrameChanged` on `frame.isValid()`. That is *a frame
  was delivered to the sink*, which is one step earlier than *a frame reached the output*. The Qt 6
  media suite proves a real H.264 frame does reach `QVideoSink`, but the onset stamp may now be
  early by up to a frame and nobody has measured it — and there is still no photodiode.
* ⚠ **`setNotifyInterval(50)` was dropped with no Qt 6 replacement, so an audio cue's onset
  granularity is backend-determined.** An audio row has no frames to count, so its onset is the
  first `QMediaPlayer::positionChanged` past the start position. Under Qt 5 that signal was pinned
  to a 50 ms notify interval. Qt 6 has no `setNotifyInterval`, and the deployed package carries two
  backends — `qt\plugins\multimedia\ffmpegmediaplugin.dll` and `windowsmediaplugin.dll`,
  chosen by `QT_MEDIA_BACKEND`, which nothing in `R:\dist\env.bat` sets — so the position
  cadence, and with it the audio onset resolution, is whatever the selected backend happens to do.
  `R:\src\docs\VALIDATION.md` lists audible level and latency among the lab acceptance tests
  still outstanding.
* **Two recordings of ten.** The numbers in §7.2 are from `13_01AV` and `12_02NS`; the operational
  run of §7.3 is `13_01AV` only, and the other eight files in `compareSOUND\rawData` have not been
  replayed.
* **The five-metric detector has been exercised, not calibrated.** Its thresholds are the reference
  implementation's, and on the one recording where they were watched they separated cleanly (§7.3).
  The tuning procedure — dump `to_rows()` over a pilot session, plot each metric's distribution and
  set each threshold so known-good channels sit under 0.5 — has not been run on this lab's caps.
