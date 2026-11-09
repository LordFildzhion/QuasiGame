# tepSound work — the task, the ETA, and the calls I am making — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/tepsound.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-tepsound-work--the-task-the-eta-and-the-calls-i-am-making"></a>


**Handed over 2026-08-20, operator away.** Their words: *"I have to go now, but I want to be sure you
got the task and will perform it to completion, making task-related decisions using your best
judgement (priority - make a thorough job)."*

Companion to [tepsound-analysis.md](tepsound-analysis.md) (the ranked findings, written by the
analysis workflow) and [design_viewer-epochs-STATUS.md](design_viewer-epochs-STATUS.md) (the epoch
project, complete).

---


<a id="history--running-tepsound-for-this-experiment--read-this-first"></a>

## ⭐ RUNNING tepSound FOR THIS EXPERIMENT — read this first

Written 2026-08-21 for the session the operator is about to run. Everything below is measured on
the deployed build in `R:\dist\msvc64`, not inferred from the code.

<a id="history-order"></a>

### Order

1. Start the amplifier service. Wait until its streams are listed.
2. Start the console:
   `tepSoundService.exe --signal <amp>/eeg --markers <amp>/stimuli --montage montages/mks64_standard.ced --leadfield calib/mks64_leadfield.h5`
3. The run bar must read `eeg · 73 ch · 25000 Hz` in grey. Red `signal stream not connected` means
   the console found nothing; the reason is written on the bar beside the buttons.
4. ⚠ **Wait about 10 s before the first pulse.** The continuous drift filter starts empty when the
   console connects, and its settling transient goes into the first epochs. Measured: connecting
   3 s before the first trigger put a **1758 µV** artefact into epoch 0 that the bad-channel
   detector then reacted to. It decays below 0.1 µV within four epochs.
5. **Arm** collects and analyses without presenting anything — this is where the hotspot is found.
   Each hand-fired pulse says so on the message strip.
6. **Start** runs the protocol. **Pause** / **Resume** / **Stop**. Stop writes the epoch file when
   `Save on stop` is ticked, and puts the path on the message strip.

<a id="history-settings-that-are-proven-on-both-recordings--do-not-correct-them"></a>

### Settings that are proven on both recordings — do not "correct" them

| setting | value |
|---|---|
| Trigger channel | **0** |
| Trigger bit | **0** |
| Trigger edge | **Rising** |
| Blank from | **−0.20 ms** |
| Blank to | **1.30 ms** |

Arm-only is a supported way to run: nothing is presented and the coil is fired by hand.

<a id="history-the-polarity-readout-and-what-to-do-when-it-goes-amber"></a>

### The polarity readout, and what to do when it goes amber

It sits on the run bar between `triggers` and `lost`. In normal running it reads, in grey:

> `bit 0: rests low, 150↑ 150↓, pulses high 10.00 ms`

— the two counts equal the pulses delivered, and 10.00 ms is this rig's pulse width. Hovering it
shows the whole sentence if the bar is too narrow for it.

**Amber means the reason comes first:**

| what it says | what it means | what to do |
|---|---|---|
| `⚠ the selected edge ENDS the pulse — bit 0: …` | Every epoch is being cut **one pulse width (10 ms) late**. The trial count and the average both look normal; the whole early TEP has moved. | Change **Trigger edge** in the Configurator to the other edge. Do **not** change the bit. |
| `⚠ no epochs cut from it — bit 0: …` | The line is pulsing and nothing is being epoched from it. | Check **Trigger bit** first, then **Trigger edge**. |

<a id="history-reading-the-counters"></a>

### Reading the counters

`epochs` is everything stored. `accepted` is what is not marked rejected. `in average` is what the
picture is actually built from — it is smaller by the **ten warm-up epochs** the SOUND model needs
before it can clean anything. All three differing is normal. `lost` must stay 0.

<a id="history-keyboard"></a>

### Keyboard

`Space` start/pause · `Esc` clears the selection, or stops the run when nothing is selected ·
`P` one pulse · `A` average/single · `Ctrl+A` select all · `N` note.

<a id="history-the-epoch-table"></a>

### The epoch table

Left-click selects; `Ctrl`-click adds; `Shift`-click extends from the epoch you clicked first (it
carries the amber bar); `↑ ↓` step one at a time. **Right-click rejects or un-rejects** — it never
deletes.

<a id="history-two-controls-that-destroy-work-and-both-say-so"></a>

### Two controls that destroy work, and both say so

- **`Keep epochs`**, lowered, throws the oldest epochs away immediately. The message strip says how
  many and the table shrinks to match. There is no undo.
- **`Seed → New`** re-draws the cue order and every inter-stimulus interval of the session. The
  strip reports the new seed and the old one. Write the new one down.

**Reset** asks first, writes the epoch file, and then clears. **Save** can be pressed at any time;
each press writes a new numbered file and reports the path.

---


<a id="history-the-task-as-asked"></a>

## The task, as asked

| # | item | state |
|---|---|---|
| 1 | **Linked topoplot** — point at a time in one viewer, topoplot it in the other | ✅ **already existed**; operator found it and confirms it works. Nothing to do. |
| 2 | **CED-based electrode colouring**, per `W:\MATLAB\tms\UI_LoadTransICA\+tmsui\getChannelTraceColors.m` | ✅ **done**, block 6; on by default, toggled from the strip and from Settings · Display |
| 3 | **tepSound: critically analyse pipeline + UI, fix and straighten all loose ends** | ✅ analysis done; **all of Tier A** fixed, and 19 of the 21 UI defects the click-through found. Tier B/C remainder listed at the bottom of this file |
| 4 | **tepSound: thorough playback testing** against the two recordings, bit0 = epoch trigger | ✅ **done**, both recordings, speed 1, whole replay, re-gated on every build since |
| 5 | **tepSound: topoplot driven by the butterfly cursor, switchable vs head-shaped trace array**, reusing the viewer's code | ❌ **DEFERRED** under the 13 h budget — see below |
| 6 | **tepSound: CED colours by default in the butterfly** | ✅ **done**, block 6 |
| 7 | **tepSound: auto-fit bounded to 15–150 ms by default, common scale across electrodes** | ✅ **done**, block 6; p95 on a 1‑1.2‑1.5‑2‑2.5‑3‑4‑5‑6‑8‑10 ladder, bad and repaired channels excluded |
| 8 | **Every button in the tepSound UI tested for what it actually does** | ✅ **done** — every control clicked on a private desktop, 21 defects found, 19 fixed and re-verified by clicking. Block 7 |

The standard everything is judged against, from the operator: *"I will need to test in real
experiment - I want everything to be as frictionless as possible."* Not "the code is defensible" —
**an operator with a subject in the chair, under time pressure, must not be able to get a wrong
answer without noticing.**


<a id="history--budget-13-hours-hard-deadline-2026-08-21-1042-set-2026-08-20-2142"></a>

## ⏰ BUDGET: 13 HOURS HARD. Deadline **2026-08-21 10:42** (set 2026-08-20 21:42)

Operator, revising the estimate: *"trim eta to 13 hours. If you see that something takes longer, use
your best judgement to drop something non-essential that can be done later. Field testing is a
priority, so working build in 13 hours is paramount."*

⭐ **A WORKING, DEPLOYED, TESTED BUILD AT THE DEADLINE OUTRANKS FEATURE COMPLETENESS.** If a block
overruns, cut scope from the block, not from the testing. Never leave the tree mid-refactor — deploy
after every block so there is always something field-testable.

<a id="history-the-plan-that-fits"></a>

### The plan that fits

| # | block | est. | why it survived the cut |
|---|---|---|---|
| 1 | tepSound critical analysis (in flight) | 2–3 h | everything downstream is scoped by it |
| 2 | **tepSound fixes — the "would mislead" tier only** | 3–4 h | a wrong number with a subject in the chair costs a session |
| 3 | **Playback test on both recordings + every button exercised** | 3–4 h | this IS the field-readiness proof; the operator asked for it by name |
| 4 | **Auto-fit bounded 15–150 ms, common scale** | ~1 h | cheap, and a real friction fix: an autoscale dominated by the TMS artifact hides the TEP entirely |
| 5 | CED trace colours (in flight) | 1.5–2.5 h | already running; also lands the CMake plumbing block 6 would need |
| | **total** | **~10.5–13.5 h** | |

<a id="history--deferred-and-this-is-the-operators-own-feature-being-pushed--say-so-plainly"></a>

### ❌ DEFERRED, and this is the operator's own feature being pushed — say so plainly

**The tepSound topoplot + head-shaped trace array driven by the butterfly cursor.** 3–4 h, the single
largest block, and the only one that is a DISPLAY ADDITION rather than a correctness or friction fix.
Nothing about field-readiness depends on it: the butterfly, the fixes and the playback proof are what
make the service trustworthy on the day.

⚠ **It is being deferred cheaply, not abandoned.** Block 5 links the Qt-free cores
(`topofield.cpp`, `colormap.cpp`, the palette core) into tepSound's CMake target anyway, so when this
comes back it is painted items + QML registration beside `TepGridView`/`TepTraceView` — roughly 2 h,
not 4. **If blocks 1–4 land early, pull it back in before the deadline rather than sitting on slack.**

<a id="history-cut-order-if-things-overrun-further"></a>

### Cut order if things overrun further

Drop in this order, and say which was dropped:
1. the "would annoy" tier of loose ends — document instead of fixing;
2. CED colours in the *viewer* (keep them in tepSound, which is what was asked for);
3. depth of the second recording's playback test — one recording proven thoroughly beats two proven
   shallowly;
4. ⚠ **never** the button-by-button UI test or the deploy. Those are the deliverable.


<a id="history--calls-i-am-making-without-asking"></a>

## ⭐ Calls I am making without asking

Recorded so they can be overruled later rather than discovered later.

1. **Code sharing for the topoplot and head array**: link the **Qt-free cores** — `topofield.cpp`
   (v4 biharmonic field, `topoLayout`, marching-squares contours, the `conv` hull), `colormap.cpp`,
   and the new CED palette core — directly into tepSound's CMake target, and register new
   `QQuickPaintedItem`s beside the existing `TepGridView`/`TepTraceView` in `main.cpp`.
   **Not** duplicated, and not promoted into `Core` — Core is framework, these are analysis maths,
   and a shared-library move is a bigger change than this task warrants.
   ⚠ This is the concrete payoff of those files having no Qt types: they drop into another
   executable with no QML-plugin machinery.
2. **What tepSound feeds the field**: EEG channels only, by `kind` where the stream declares it,
   otherwise by the 64-row `tepSoundService/montages/mks64_standard.ced`. tepSound's montage has 64
   rows against the viewer's 66 — the two produce different `plotrad` (0.678218 vs 0.756412, +11.53%)
   and must not be assumed interchangeable.
3. **Auto-fit**: 15–150 ms and a common scale become the **default**, but the existing free-fit and
   whatever per-channel behaviour exists stay **reachable**. Changing a default is the ask; removing
   an option is not.
4. **CED colours**: default in the tepSound butterfly, an option in the viewer. Falls back visibly —
   never silently to grey — when the montage is missing or short.
5. **Scope of "all loose ends"**: everything the analysis ranks as *would mislead an operator*
   gets fixed. *Would annoy* gets fixed when cheap, documented when not. Padding the top of that list
   with cosmetics would hide the ones that cost a session.
6. **bit0 polarity is verified from the actual files, never assumed.** NVX inputs go **LOW** on an
   edge (idle word `0x0000EFFF`) and the first ~14 frames carry `Status == 0`, which reads as every
   input rising at once — assuming a rising edge would produce a confident, wrong, plausible result.
7. **Deploy after each block** to `R:\dist\msvc64` with a `bin.pre-<name>-<timestamp>` rollback, so
   the operator can test at any point without waiting for the whole task.


<a id="history-rules-carried-in-from-the-epoch-project"></a>

## Rules carried in from the epoch project

* Build with `chcp 65001` after vcvarsall, target `all`, `-j6`, MSVC v142 — without it ninja records
  no header deps and a header edit yields a binary that links and crashes.
* **No non-ASCII in narrow string literals** — this localized MSVC has no `/utf-8`.
  tepSound already has **33 known offenders** in `service.cpp`/`service_analysis.cpp`.
* **D1** — operator-facing text is terse and factual, never design rationale. The viewer was audited;
  **tepSound has not been.**
* **D2** — marks over a continuous field are black, always.
* `robocopy /E`, **never `/MIR`** — 6 deployed-only items would be destroyed.
* A `Stream` parameter cannot be declared later; `Binding loop` count must stay 0.
* Baseline to not regress: **572 tests / 18 executables, 0 failures**, plus the Core ones.


<a id="history--added-2026-08-20--the-shared-ced-palette-core-is-in-place-and-ready-to-link"></a>

## ✅ Added 2026-08-20 — the shared CED palette core is IN PLACE and ready to link

Block 5's core landed and is deployed. **Nothing else in this file has been changed.**

`R:\src\quickStimulus\cedpalette.{hpp,cpp}` is Qt-free in exactly the sense call #1 relies on — no
`QColor`, no `QVector`, no `<QtGlobal>` — so `tepSoundService`'s CMake target can add
`../quickStimulus/cedpalette.cpp` beside `topofield.cpp` and `colormap.cpp` and call it directly.
Entry points: `CedPalette::fromPolar(theta[], radius[], n)` for anything fed by a stream (ParseCED
publishes only theta/radius), `fromCartesian(x[], y[], n)` for anything fed readlocs' X/Y, both
returning one index-preserving `Entry { Rgb rgb; bool valid; }` per input channel. `to8Bit()` gives
an ARGB word. Defaults already are the MATLAB call, so item 6 — CED colours by default in the
tepSound butterfly — is a call to `fromPolar` over the EEG channels and a branch on `valid`.

Measured against MATLAB through the running viewer: worst per-component RGB **7.35e-06** (CP5) on
the theta/radius path, below `QColor`'s own 16-bit read-back floor; **3.909e-04** (C3) against the
`readlocs` X/Y path, which is the documented `sph_radius` residual and 0.0997 of one 8-bit level.
`test_CedPalette`, 16 cases against MATLAB's own CSVs, passes; tests are now **588 / 19 exes, 0
failures** against the 572 / 18 baseline in the rules above.

⚠ Call #2 still stands and matters here: use tepSound's own 64-row montage, and select by **kind**,
because `min r`/`max r` are normalised across the channels passed in — admitting the EMG rows in
readlocs' coordinates collapses the whole cap onto the minimum saturation.

Details, the three measured MATLAB facts and the evidence shots:
[design_viewer-epochs-STATUS.md](design_viewer-epochs-STATUS.md) § *CED scalp trace palette*.

---


<a id="history--added-2026-08-20-2350--the-minimum-safety-block-is-built-proven-on-real-data-and-deployed"></a>

## ✅ Added 2026-08-20 23:50 — the minimum safety block is BUILT, PROVEN ON REAL DATA, and DEPLOYED

**Nothing above this line has been changed.** Blocks 2 and 3 of the plan are done; block 3's replay
proof is below. Rollback: **`R:\dist\msvc64\bin.pre-tepsound-safety-20260820-233756`**.

<a id="history-build"></a>

### Build

`all`, MSVC v142, `-j6`, `chcp 65001` after vcvarsall. **0 errors**; the only warning is the
pre-existing `C4005 THIR_IS_CPP11` (x3). Header deps confirmed recorded — `ninja -t deps` gives
`#deps 510 (VALID)` for `service.cpp.obj`, `495 (VALID)` for `service_analysis.cpp.obj`,
`152 (VALID)` for `soundstore.cpp.obj`.

**Tests: 598 / 19 exes / 0 failures** in `tests\`, plus `test_StreamInfo` 18, `test_SamplesCollector`
1, `test_NetworkMode` 10, `test_RecorderPath` rc 0. Against the 572 / 18 baseline that is +16
(`test_CedPalette`, the concurrent workflow) and **+10 mine** — 4 pipeline, 4 store, 2 protocol. The
handover predicted +11; `sound_test.cpp` gained 4 anchor cases, not 5.

<a id="history--replay-proof--file-a-11_tms_48mso_heel_60hdf5-speed-1-full-2722-s"></a>

### ⭐ Replay proof — file A, `11_TMS_48MSO_heel_+60.hdf5`, speed 1, full 272.2 s

Producer clean throughout: **3630 blocks, late 0.41 ms mean / 1.59 ms max, 0 underruns.**

**Gate 1 — counting. Every number exact.** `epochs 150 · in average 140 · triggers 150 · lost 0 ·
model 14`. In the written file: `rejected 0/150`; all-zero epochs **0** in `preproc` and **exactly
the 10 warm-up** in the SOUND-cleaned array; labels **50 / 50 / 50** across `1!`/`3!`/`10!_sf100_gp50`
with **0 unlabelled** (A19); `model_id` spans -1 plus 0…13, i.e. **14 retrains** — the analysis's
"15" counted the -1 warm-up sentinel. `incomplete` and `artifactSkipped` are still not surfaced
(B8 undone), but both are provably 0: a skipped blank leaves the raw artefact in the epoch, and the
largest single-trial excursion anywhere in all 140 epochs is **208 µV**.

**Gate 2 — timing, via the deliberate negative control.** A second full pass with
`triggerEdge = Falling` (through `--serviceConfig`; the shipped default was **not** touched):

| | Rising (default) | Falling (control) |
|---|---|---|
| epochs / in average / triggers / lost / model | 150 / 140 / 150 / 0 / 14 | **150 / 140 / 150 / 0 / 14 — identical** |
| largest excursion anywhere in the epoch | **93.7 µV at +5.0 ms** | **177 883 µV = 178 mV at -9.0 ms** |
| trials showing it | — | **140 / 140, every one at -9 ms** |
| per-channel peak 15…150 ms, median | **24.29 µV** | **652.68 µV (27x inflated)** |

The wrong edge cuts one pulse width late, so the artefact falls outside the blank entirely. ⚠ **Every
count on the run bar is identical between a correct run and a session-losing one.** The only thing on
screen that distinguishes them is A2's new readout, which turns amber and says
`bit 0: rests low, 150↑ 150↓, pulses high 10.00 ms — the selected edge ENDS the pulse`.
(The -9 ms rather than -10 is the 25:1 decimation grid and the 450 Hz anti-alias group delay, not a
timing error; the pulse width measured on the raw file is 10.0035 ms.)

**Gate 3 — amplitude against the independent reference.** tepSound's `preproc` (pre-SOUND, after
repair and CAR) versus the analysis's own Python:

| | reference | tepSound | error |
|---|---|---|---|
| per-channel peak 15…150 ms, median | 24.35 µV | **24.27 µV** | **-0.3 %** |
| max | 56.94 µV at Cz | **61.45 µV at Cz** | +7.9 %, same channel |
| CPz | -56.9 @ 15 ms | **-58.48 @ 15.0 ms** | +2.8 %, latency exact |
| Pz | -41.8 @ 16 ms | **-43.72 @ 16.0 ms** | +4.6 %, latency exact |
| FCz | +25.5 @ 28 ms | **+27.21 @ 28.0 ms** | +6.7 %, latency exact |
| C3 | -11.1 @ 87 ms | **-12.06 @ 85.0 ms** | +8.6 %, 2 ms |
| MEP p2p 15…60 ms | 0.090 mV | **0.0997 mV median** | +10.8 % |

Latencies agree to the sample on four of six named channels. The few-percent amplitude spread is
expected: the reference blanked -0.04…+1.2 ms where tepSound now blanks -0.20…+1.30, and tepSound
repairs bad channels before CAR. **C4 disagrees** — reference +10.6 µV @ 36 ms, tepSound
-10.21 µV @ 15 ms; same magnitude, different peak picked on a low-amplitude channel. Worth one look
later, not a blocker.

**Gate 5 — the file.** `Fs 1000`, `window_start_ms -200`, `window_end_ms 500`, `n_epochs 150`,
`n_samples 701`, `n_channels 64`; `epochs` is 105 150 x 64. Consistent throughout.

<a id="history--a1-measured-on-the-raw-file-all-150-trials--the-fix-is-real-but-the-specs-magnitude-is-wrong"></a>

### ⭐ A1 measured on the raw file, all 150 trials — the fix is real but the spec's magnitude is wrong

⚠ **Raw units in these recordings are millivolts.** The analysis's own Gate 3 treats them as mV
(MEP 0.090 mV) while A1 treats them as volts, which is where "30–100 mV goes into the IIR chain"
comes from. Cross-checked against tepSound's own MEP column, which matches the reference with no
scaling. **The real numbers are ~250x smaller — and the finding still stands.**

| at the sample where interpolation hands back to raw data | median | p90 | max |
|---|---|---|---|
| **old** `blankTo 0.85` → hands back at **+0.880 ms** | **118.00 µV** | 127.02 | 130.85 |
| **new** `blankTo 1.30` → hands back at **+1.320 ms** | **4.84 µV** | 5.07 | 5.23 |

**150 / 150 trials over 100 µV before; 0 / 150 over 20 µV after — a 24x reduction on every trial.**
Raw artefact peak is 0.476 mV median. Decay profile (median worst channel): +0.85 ms 142.6 µV,
+1.00 ms 66.1 µV, +1.16 ms 31.6 µV, **+1.30 ms 5.3 µV**, +2.0 ms 1.9 µV. So 1.3 ms is exactly where
the residual reaches the quiet noise floor (sigma ≈ 7–14 µV) — the chosen value is right, not
arbitrary.

ⓘ **`blankFrom -0.2 ms` is precautionary, not corrective.** Measured leakage at the old -0.04 ms was
≤ 0.5 µV on this rig. It buys margin against trigger jitter; the `blankTo` change is the one that
mattered.

<a id="history--three-defects-found-in-a5s-own-dialog-while-proving-it-and-fixed"></a>

### ⭐ Three defects found in A5's own dialog while proving it, and fixed

Only visible by looking at the rendered pixels, which is why they survived the handover:

1. ⚠ **The confirmation's buttons came out in Russian** — `Отклонить` / `Отмена`. Controls 2's
   `standardButtons` uses Qt's translations and the system locale is Russian, so the single most
   destructive control in the program was labelled in a language nothing else in the service uses.
2. ⚠ **The question itself was invisible.** `Theme.ink` is `#E3E7EB`, a near-white for a dark panel,
   painted on Controls 2's default light dialog background. The *secondary* line read fine and the
   primary one did not.
3. **The Reset's "epochs written to …" notice was overwritten** by the generic "session reset" notice
   in the same turn of the event loop, so the file path — the only part the operator cannot
   reconstruct — never survived on the one-line strip.

Fixes: new `import/Resonance/TepSound/TepDialog.qml` (themed background + header) applied to all
three dialogs, each declaring its own English footer out of `TepButton`; `service.cpp` emits **one**
combined message and records `clearedEpochs`/`clearedTo` on the `session/reset` event to match
`session/started`. ⚠ **A new file under `import/Resonance/TepSound/` must also be added to
`res.qrc`** — the module is loaded from `qrc:/qml/…`, and without it the console fails to load while
the service itself runs on happily, headless.

<a id="history-deploy"></a>

### Deploy

`diff -rq` first; `robocopy /E`, never `/MIR`. All six deployed-only items verified present after:
`FrameLib\`, `emulator.exe`, `arduinoTTL.ini`, `eStim.ini`, `feetStim.ini`, `mStim.ini`.
Post-deploy `diff -rq` shows **no file differing**. Changed: `tepSoundService.exe`, `tepService.exe`,
`stimulusService.exe`, `ParamControl.qml`, `qmldir`, new `TepDialog.qml`.

⭐ **Verified by replaying the whole of file A again from `R:\dist\msvc64` itself.** Same counts,
0 underruns, and the written epoch file is **bit-identical** to the build-tree run — `preproc`,
`epochs`, `peak_uV`, `model_id`, `rejected` and `mep/amplitude_mV` all exactly equal. (`latency_ms`
differs, as it must: it is transport arrival latency.)

Evidence, with the run bar, butterfly, message strip, both Reset dialogs and the amber wrong-edge
readout: `R:\dist\_build\tepsound-safety\`.

<a id="history--file-b-confirmation-pass--12_tms_metatarsus_60_2hdf5-from-the-deployed-tree"></a>

### ⭐ File B confirmation pass — `12_TMS_metatarsus_+60_2.hdf5`, from the deployed tree

Run because it was cheap, not at the expense of anything. **2655 blocks, 0 underruns.**

`epochs 107 · in average 97 · triggers 107 · lost 0 · model 9`, readout
`bit 0: rests low, 107↑ 107↓, pulses high 10.00 ms` — every count matches the analysis's independent
measurement of this file. `rejected 0/107`; labels **35 / 36 / 36** across `9!`/`7!`/`10!_sf100_gp50`,
**0 unlabelled**; all-zero epochs 0 in `preproc`, exactly the 10 warm-up in the cleaned array.

**Gate 3 on the second file:** per-channel peak 15…150 ms median **26.95 µV** against the reference's
26.54 (+1.5 %). Pz **-42.78 @ 18 ms** vs -43.1 @ 18 (-0.7 %), C3 **-49.88 @ 15 ms** vs -48.0 @ 15
(+3.9 %), C4 **-27.00 @ 95 ms** vs -25.8 @ 95 (+4.7 %), CPz -64.53 @ 15 vs -74.6 @ 15, FCz
-26.89 @ 121 vs -23.0 @ 120. **Five of six named channels agree on latency exactly or within 1 ms.**

**Gate 4 — the bad electrode, and this is the only recording that tests it.** `CAP · BADNESS` flags
**FT9 at badness 10.82**, five times the next channel (FT7, 2.08), on the *neighbour* criterion —
which is the anticorrelation signature the analysis measured (-0.357 against its three nearest).
**The detector found it and the repair worked**: the reference, which does not repair, peaks at
888.9 µV on FT9; tepSound's repaired residual peaks at **101.77 µV**, 8.7x lower, and with warm-up
excluded FT9 is no longer the worst channel at all (CPz, 64.48 µV). ✅

<a id="history-still-not-done-and-the-eta"></a>

### Still not done, and the ETA

⚠ **Superseded.** The single consolidated list is **WHAT IS NOT DONE** at the bottom of this file.

Untouched, exactly as handed over: **B6, B8, B10–B30, A3, A8–A10, A12–A18, A20–A25, all of Tier C**,
and items 5–7 of the original task (topoplot, CED butterfly colours, bounded auto-fit). `B8` is the
one this replay actually wanted: `incomplete` and `artifactSkipped` had to be inferred from the epoch
data rather than read off the bar.

**Time used ~2 h of the 13. Deadline 2026-08-21 10:42; ~11 h remain.** The tree is at a clean point,
the deploy is field-testable now, and nothing is half-applied.

---


<a id="history-block-6--the-two-requested-features-built-gated-and-deployed-2026-08-21-0130"></a>

## Block 6 — the two requested features, built, gated and deployed (2026-08-21 ~01:30)

**Rollback: `bin.pre-tepsound-features-20260821-012139`.** Evidence in
`R:\dist\_build\tepsound-features\`.

<a id="history-build-1"></a>

### Build

`all` built clean on the first attempt, `chcp 65001` after vcvarsall. Header deps confirmed
`(VALID)` on every object touching a changed header — `service_analysis.cpp` 497 deps,
`views.cpp` 311, `soundstore.cpp` 152, `epochprocessor.cpp`, `protocol.cpp` 88. `tepService` and
`stimulusService` rebuilt with the shared headers, as required. No build fixes were needed.

**Tests: 639 / 19 executables / 0 failures** (was 598) — the +41 is the 14 `autofit_test.cpp` and
the 27 Tier-A tests. Core: `test_StreamInfo` 18, `test_SamplesCollector` 1.
⚠ `test_NetworkMode` hangs even on `--gtest_list_tests` in this session and produced no result; it
binds sockets and touches nothing in this change. Not counted, not a regression, but **unverified**.
⚠ `test_RecorderPath` still needs `RESONANCE_RECORD_PATH`; not in the count.

<a id="history-replay-gates--both-recordings-speed-1-on-the-new-build"></a>

### Replay gates — both recordings, speed 1, on the new build

| | file A expected | file A got | file B expected | file B got |
|---|---|---|---|---|
| epochs | 150 | **150** | 107 | **107** |
| accepted | 150 | **150** | 107 | **107** |
| in average | 140 | **140** | 97 | **97** |
| triggers | 150 | **150** | 107 | **107** |
| lost / refused / rejected | 0 | **0** | 0 | **0** |
| labels | 50/50/50 | **50/50/50** | 35/36/36 | **35/36/36** |
| unlabelled | 0 | **0** | 0 | **0** |
| median peak 15–150 ms | 24.27 µV | **24.27 µV** | 26.95 µV | **26.95 µV** |
| retrains | 15 | **15** | — | **11** |

**Not one count moved.** Polarity readout reads `bit 0: rests low, 150↑ 150↓, pulses high 10.00 ms`
(107↑ 107↓ on B), and goes **amber** on the `Falling` negative control. Playback kept up on every
run: 3630 / 2655 blocks, **0 underruns**, max lateness 1.54 ms.

**Gate 4 (file B only):** FT9 flagged at badness **10.82** on the *neighbour* criterion, 5.2× the
next channel (FT7, 2.08), and repaired — the unrepaired reference peaks at 888.9 µV, tepSound's
repaired residual at **101.77 µV**, and with warm-up excluded FT9 is no longer the worst channel.

**Gate 5:** written file is 150 (107) × 701 × 64, `Fs` 1000, window −200…500 ms, labels present,
all-zero rows exactly the 10 warm-up epochs and none in `preproc`.

**A12 is visible in the file:** `mep/onset_ms` carries **73 NaN and 0 zeros** on file A. Those 73
used to be written as `0.000`, indistinguishable from a real zero. New `mep/valid` dataset present.

<a id="history-feature-3--bounded-auto-fit-common-scale-default-on"></a>

### Feature 3 — bounded auto-fit, common scale, default on

The service reproduces `autofit.cpp` exactly: recomputing the p95 statistic offline from the written
average lands on the same ladder rung and the same over-range count as the caption in the UI.

| file A, SOUND-cleaned average, n=140 | p95 peak | scale | over |
|---|---|---|---|
| bound ON, 15–150 ms (shipped default) | 42.62 µV | **±50 µV** | 0 |
| bound OFF, −10…200 ms | 46.91 µV | ±50 µV | 1 |

⚠ **On file A the bound barely matters, and the honest reason is that A1 already fixed it.** With
`blankTo = 1.3` the artefact is gone before the fit ever sees it, and p95 discards the loudest 5 %.
On the *pre-SOUND* average the bound is still worth 1.67× of panel (±60 vs ±100 µV), and on file B
it is worth **2.5×** (±40 vs ±100 µV cleaned; ±60 vs ±200 µV pre-SOUND). The operator's stated
complaint is real and the bound fixes it — it is simply no longer catastrophic, because A1 landed
first.

**Where the feature earns its keep is the warm-up.** In file B's first 10 epochs the detector has
not run, nothing is excluded and FT9 is unrepaired at **1172.1 µV** against a 27.63 µV median:

- p95, as shipped → **±60 µV**, TEP legible
- a naive max-fit → **±1200 µV**, i.e. **20× more panel wasted** and the TEP invisible

That is the failure mode the feature exists to prevent, measured on real data rather than argued.

⚠ **Exclusion is a second line of defence, not the first.** On the settled file B average the
exclusion changes nothing (50.49 µV either way) because *repair* has already tamed FT9. It matters
in the warm-up window and for anything repair cannot fix. Both paths are covered by tests.

<a id="history-feature-2--ced-trace-colours-as-the-butterfly-default"></a>

### Feature 2 — CED trace colours as the butterfly default

Working on both recordings. The scalp grid and the butterfly show the expected spatial gradient —
frontal blue, left temporal pink/magenta, right temporal green, occipital yellow, vertex near-grey —
matching the four cardinals `cedpalette.hpp` predicts. `colours on` toggle present on the scalp
strip; the placement note reads how many of the EEG channels the montage placed.

<a id="history-known-cosmetic-defect-not-fixed"></a>

### Known cosmetic defect, not fixed

⚠ On the `Falling` control the amber polarity readout **elides its own reason**: it renders
`bit 0: rests low, 38↑ 38↓, pulses high 10.00 ms —…` and the explanation after the em-dash is cut
off at this window width. The colour still carries the warning, so the control is not silent, but
the sentence that says *why* is unreadable without hovering. Worth a fix; not worth the deadline.

<a id="history-deploy-1"></a>

### Deploy

`R:\dist\_build\msvc64\runtime` → `R:\dist\msvc64` with `robocopy /E` (never `/MIR`). All six
deploy-only items survived and were verified by name: `bin\FrameLib\`, `emulator.exe`,
`arduinoTTL.ini`, `eStim.ini`, `feetStim.ini`, `mStim.ini`. Post-deploy `diff -rq` is clean.

Delta was 2 executables (`tepSoundService.exe`, `tepService.exe`) and 3 QML module files
(`EpochTable.qml`, `ScaleBox.qml`, `StatPill.qml`). `RunBar.qml`, `Console.qml` and
`SettingsPane.qml` live in `ui/` and ride inside the executable via `res.qrc`, which is why they do
not appear as file diffs.

**Verified by replaying the whole of file A from `R:\dist\msvc64` itself.**
Same counts — `epochs 150 · accepted 150 · in average 140 · triggers 150 · lost 0 · model 14` — and
the written epoch file is **bit-identical** to the build-tree run: `preproc`, `epochs`, `peak_uV`,
`model_id`, `rejected`, `mep/amplitude_mV`, `mep/onset_ms`, `mep/valid`, `channels/badness`,
`channels/flag`, `sound/operator` and `labels` all exactly equal. `latency_ms` differs, as it must —
it is transport arrival latency, not a measurement of the data.

<a id="history-still-not-done"></a>

### Still not done

⚠ **Superseded.** The single consolidated list is **WHAT IS NOT DONE** at the bottom of this file.

- **Item 5, the topoplot / head-shaped trace array driven by the butterfly cursor** — still deferred,
  as planned. The CMake plumbing this block added makes it one more line.
- **Item 8, every button exercised** — *not* completed in this block. UI automation could not take
  the foreground in this session, so every interactive control was verified by reading rendered
  pixels of the state it was in, not by clicking it. The `scale auto` / `colours on` toggles, the
  two-way µV box and the Display panel are therefore **built and visible but not click-tested**.
- The `readCed` `radius = 0.5 − sph_phi/180` recomputation remains a Feature-1 prerequisite only.
- `loadCalibrationAssets()` early-return staleness is closed (A23), but `test_NetworkMode` is
  unverified in this session.


<a id="history-block-7--every-control-clicked-and-the-21-defects-that-found-2026-08-21-0415"></a>

## Block 7 — every control clicked, and the 21 defects that found (2026-08-21 ~04:15)

The Drive phase before this one solved the foreground problem and clicked every control. It ranked
21 defects. This block fixed 19 of them, rebuilt, re-gated both recordings, and deployed.

**Rollback: `bin.pre-tepsound-ui-20260821-041500`.**

<a id="history--the-foreground-problem-and-the-one-thing-the-drive-phases-driver-still-got-wrong"></a>

### ⭐ The foreground problem, and the one thing the Drive phase's driver still got wrong

The private-desktop technique (`CreateDesktopW` + `SetThreadDesktop` on a fresh thread +
`SwitchDesktop`, launching with `STARTUPINFOW.lpDesktop`) works exactly as documented and took the
foreground on the first attempt every time. But **clicks landed and keys did not**, and that is not
a Qt problem:

> `KeyVk` sent `INPUT.ki.wVk` with `wScan = 0`. Windows does not fill the scan code in for you.
> Qt received nothing at all — no key event, no shortcut. Adding
> `wScan = MapVirtualKeyW(vk, 0)` made every keyboard test work immediately.

⚠ **This is why `P` looked dead (B13).** `P` is wired, reaches `manualPulse()`, and now prints
`arm the session before pulsing` in idle and `pulse N fired by hand …` when armed. B13 was a
harness artefact, not a defect. `drv.ps1` is fixed.

<a id="history-what-was-fixed-in-the-drive-phases-own-ranking"></a>

### What was fixed, in the Drive phase's own ranking

| # | defect | fix | proof |
|---|---|---|---|
| 1 | `Save` and `Note…` clipped off the bar at the shipped 1680 px | the readouts now live in a clipped, scrolling lane with `Layout.minimumWidth: 0`; the button group carries `Layout.minimumWidth: implicitWidth` so the row overflows into the lane, never off the end | `01_launch_full.png` — all seven buttons at 1696 px, and `c90_1200.png` at 1200 px with the block reason up. ⚠ **Measured limit: it holds to about 1150 px and no further** — see below |
| 2 | `ScaleBox` stopped tracking after one edit | `commit()` re-binds with `Qt.binding` instead of assigning `field.text` | `c_17` → `c_18`: box read `120.0 µV`, `scale auto` snapped it back to `50.0 µV` |
| 3 | `xMin > xMax` blanked both plots as "waiting for the first epoch" | new `TepPlotBase::blankMessage()` distinguishes inverted range, no data, and a window outside the epoch; used by all three paint paths | `19_inverted.png` — both plots read `time range inverted — from 20 ms is not before to 10 ms` with 95 epochs in hand |
| 4 | a refused first keystroke merged the rest into the old number (`450` + `-10` = `10450 Hz`) | both numeric editors clear the field on the first printable key after focus, instead of relying on a selection surviving a refusal | `c20.png` — Anti-alias reads **10**, not 10450 |
| 5 | window `Shortcut` outranked the focused item: Esc stopped the run with the epoch list focused; Space paused the run instead of toggling a check box | Esc decides by **state** (clear the selection if there is one, else stop); Space is disabled while focus is on anything with `inputMethodHints` or `checked` | `c_16`: Esc returned the title to `TEP · AVERAGE`. `59/60/61/62`: click unticked `Save on stop`, Space re-ticked it, run bar unchanged |
| 6 | `Lambda` and every channel threshold rendered as **empty boxes** at the pane's 330 px | two causes. A `RowLayout` shrinks `fillWidth` children to `Layout.minimumWidth` (default **0**) — the editors now floor at 66 px. And a **growing panel hint** (`SOUND` gains `model 14 · 150 epochs · ref P2 · σ med …` once a model exists) pushed the panel's implicit width past the pane, and `ScrollView` then wrote that width onto its content item, destroying the `width: availableWidth` binding. The hint now elides and cannot widen; `contentWidth: availableWidth` pins the pane | `c41_pane.png` / `c63.png` — with the long hint present, `Lambda 0.0100`, `Iterations − 5 +`, all five thresholds and their units are visible |
| 7 | every `select` popup opened white and unstyled | `ComboBox.popup` and `delegate` themed; neither inherits from `background`/`contentItem` | `23_combo_open.png` |
| 8 | errors latched on the strip with no sign they were stale | errors still never auto-clear — an error on a timer is an error nobody saw — but the strip now says **`N min ago`** beside the stamp once the message is over a minute old | `13_run_end.png` — `1 min ago  history (8)` |
| 9 | `Pulse` was completely silent on success | `manualPulse()` emits a message naming the pulse number and the backend | `c05_strip.png` — `pulse 1 fired by hand — \`Trigger out\` is off, so nothing left this machine` |
| 10 | `fullscreen` inert | a restore guard on `onVisibilityChanged` | measured: stage window `3840×1600 @ 0,0` → `800×600 @ 1520,480` and back. ⚠ Honest note: the guard did **not** need to fire — Qt restored the geometry itself — so the earlier "inert" reading was not reproduced on this build |
| 11 | `cannot open protocols/nope.json: <Russian>` | `loadProtocol` answers the two causes worth telling apart in one language and drops the OS sentence | `65_badproto.png` — `cannot open protocols/nope.json — no such file` |
| 12 | `in average` tooltip contradicted the pill during a selection | the hint now describes the running average and points at the panel captions for what is drawn | text change only |
| 13 | anchor bar marked the lowest serial (ET-08); arrow keys moved nothing (ET-07) | `m_anchor` is its own member — `m_selection` is **sorted**, so reading the anchor back out of it returned the wrong end. Arrow keys move the selection from the anchor, Shift extends | `c14b.png` — clicked 100, shift-clicked 96, bar on **100**. `c15.png` — two Downs moved 100 → 98 |
| 14 | `Keep epochs` destroyed epochs silently and the table kept drawing them | the log and the selection are trimmed to the store and the loss is reported | `c25a.png` — `\`Keep epochs\` 20 — 85 older epochs dropped from the session, the table and the average`; `26_table_bottom.png` — the table now ends at 86 |
| 15 | `Seed → New` re-rolled with no message | reports the new seed and the old one | `28_seed.png` — `seed 1492293916 — the trial plan is re-drawn (was 48211)` |
| 16 | panel notes elided with no way to read them | hovering an elided `PlotFrame` note gives the whole string | `c58b.png` — `model 14 · 150 epochs · ref P2 · σ med 0.66 max 8.70 µV · κ 63.1 · conv 0.019` |
| 17 | the highlighted electrode was not named anywhere | the butterfly note names it **first**, so it survives eliding | `54_after_click.png` — `TEP · ALL ELECTRODES  Cz · n…` |
| 18 | `no montage — set a .ced file in Input`, with a valid `--montage`, pointing at a panel that does not exist | three states told apart: no grid yet, no montage, inverted range | `65_badproto.png` — `no electrode grid yet — it is placed from the first epoch` |
| 19 | MEP box said µV, its axis said mV | the box is mV, matching the axis | `03_connected.png` — `0.50 mV` |
| 20 | Esc out of the Note dialog left the typed text behind | `onRejected` clears the field — Escape rejects, and `Cancel` does not go through that path | `c11.png` — reopened empty after typing `STALE-TEXT` and pressing Esc |
| — | ⭐ **the brief's defect 1**: the amber polarity readout elided its own reason | the reason is built **first**, the measurement second, because the measurement is on the tooltip and the reason is not | `c47.png` — `⚠ the selected edge ENDS the pulse — bit 0: rests low, 30↑ 30↓, pulses high 10.00 ms` |

Also: attached tooltips share one instance whose timeout defaults to **never**, which is why one was
still on screen after fifteen seconds covering five rows. It is now 9 s. ⚠ `ToolTip` attaches to an
**Item**, never to a Window — put on `ApplicationWindow` it prints
`QML Console: ToolTip must be attached to an Item` and sets nothing.

<a id="history--the-briefs-defect-2-is-not-fixed-and-here-is-why-it-cannot-be-fixed-where-it-was-asked-for"></a>

### ⚠ The brief's defect 2 is NOT fixed, and here is why it cannot be fixed where it was asked for

**A tooltip on a disabled control is unreachable by construction.** Qt Quick propagates `enabled`
down the item tree, so a `MouseArea` or `HoverHandler` placed *inside* a disabled `Button` is itself
disabled and never sees hover. There is no arrangement of children that works.

The run bar already works round it by writing its two block reasons **on the bar**, which was
verified again this block. The general fix is a different pattern and was not attempted under the
budget: give `TepButton` a `blockedBy` string, keep the button `enabled` and hoverable, paint it
dead, refuse the click, and say why on the message strip. Every call site would have to migrate.

<a id="history--one-fix-went-only-part-of-the-way-and-two-attempts-to-finish-it-were-rolled-back"></a>

### ⚠ One fix went only part of the way, and two attempts to finish it were ROLLED BACK

Defect 1 is fixed **where it was found** — the shipped 1680 px default, verified at 1696 and again
at 1200 px with the block reason up, all seven buttons present. It is **not** fixed below about
**1150 px**: at 980 px `Reset`, `Save` and `Note…` are clipped again, and at 760 px only `Arm`
survives.

The cause is that `Layout.minimumWidth: buttons.implicitWidth` on the group itself is read back
before a `RowLayout`'s own implicit width is settled, so the engine shrinks the group like anything
else. Two structural fixes were built, compiled and measured:

1. a wrapper `Item` whose `Layout.minimumWidth` bound to a **sibling** `Row`'s implicit width — no
   self-reference, so the ordering should have been safe;
2. lifting the buttons out of the layout entirely into a `Row` anchored to the bar's right edge,
   with the `RowLayout` anchored to `buttonRow.left`.

**Neither changed the rendered layout by a single pixel at 980 px.** The buttons kept being
positioned immediately after the block-reason text and running off the right edge — which is what
being *inside* the layout looks like, even though the source had them outside it. RCC ran on every
build (checked in the logs, and the generated `qrc_res.cpp` was deleted and regenerated once to be
sure), the QML disk cache was disabled for one run to rule it out, and the service logged no QML
warning of any kind. The discrepancy between the source and the rendered result was not explained.

⭐ **Both were rolled back** rather than left half-applied, and `RunBar.qml` is byte-identical to the
version the gates were run against. The measured limit is written into the file's own comment and
into `tepsound-analysis.md` §12 as **UI-11**. The console's `SplitView` minimums put its usable floor
near 1150 px anyway, so the unfixed range is below the width at which the rest of the window works.

This is the "prefer rollback over artifact-trading" rule doing its job: two fixes, neither an
improvement, so the tree goes back to the state that was proven.

<a id="history-build-2"></a>

### Build

`cmake --build R:/dist/_build/msvc64 -- -j 6` with `chcp 65001` after `vcvarsall`, target **all**,
MSVC v142. Clean, no warnings beyond the pre-existing `THIR_IS_CPP11` redefinition. Nine builds in
this block; the last one is the one deployed.

**Tests: 639 / 19 executables / 0 failures**, unchanged, re-run on the final build. Plus
`test_StreamInfo` 18, `test_SamplesCollector` 1.

⚠ **`test_NetworkMode` does not hang.** It is a **QTest-style** binary, not GTest: `--gtest_list_tests`
returns `Unknown option 'gtest_list_tests'` immediately, which is what looked like a hang. Run plainly
it finishes in about a second and prints `NetworkMode: 10 case(s) pass in loopback mode`. That
question is closed.

⚠ Every fix in this block is **QML or Qt-object** code — layout, key routing, bindings, message
text, and one `QPainter` string. None of it is reachable from the Qt-free GTest pattern, so no new
tests were written. Saying that plainly is better than a test that proves nothing. The one piece
with real logic — `blankMessage()`'s three-way choice — is a two-comparison function whose inputs
are the two numbers in the boxes.

<a id="history--re-gate-both-recordings-speed-1-whole-replay"></a>

### ⭐ Re-gate, both recordings, speed 1, whole replay

| | expected | file A | expected | file B |
|---|---|---|---|---|
| epochs | 150 | **150** | 107 | **107** |
| accepted | 150 | **150** | 107 | **107** |
| in average | 140 | **140** | 97 | **97** |
| triggers | 150 | **150** | 107 | **107** |
| lost | 0 | **0** | 0 | **0** |
| labels | 50/50/50 | **50/50/50** | 35/36/36 | **35/36/36** |
| median peak 15–150 ms | 24.27 µV | **24.27 µV** | 26.95 µV | **26.95 µV** |
| model | 14 | **14** | — | **9** |

**Not one count moved**, and the written epoch files are **bit-identical** to the previous build's
on every dataset: `epochs`, `preproc`, `peak_uV`, `model_id`, `rejected`, `labels`,
`mep/amplitude_mV`, `mep/onset_ms`, `mep/valid`, `mep/baseline_rms_mV`, `channels/badness`,
`channels/flag`, `channels/incoherence`, `channels/dominant`, `sound/operator`, `sound/sigmas`,
`sound/convergence`. Only `latency_ms` and `timestamps` differ, as they must. File B's FT9 is again
repaired to **101.77 µV**, the worst channel in the file.

<a id="history--a-gate-number-moved-once-and-it-was-the-harness-not-the-code--worth-knowing"></a>

### ⚠ A gate number moved once, and it was the harness, not the code — worth knowing

The first re-gate produced **24.12 µV** instead of 24.27, and the diff was confined to the first ten
epochs' `preproc`, decaying geometrically: **1758 µV → 191 → 52 → 3.5 → 0.12 → 0.03 → 0.002 → 0**,
with epochs 8 and 9 bit-identical. That is an IIR filter settling, not a code change.

Cause: I started `playbackSource` **before** `tepSoundService`, so the console's continuous drift
filter had no history when the first trigger arrived. `replay.ps1` — the harness the earlier gates
used — starts the console first and waits 4 s. Repeating in that order reproduced 24.27 µV and a
**bit-identical** file.

⭐ **This is an operator-facing finding, not just a harness note**, and it is written into the
operator section at the top of this file: the console must be connected and settled before the first
pulse, or the first epochs carry a transient large enough for the bad-channel detector to react to.

<a id="history-deploy-2"></a>

### Deploy

`R:\dist\_build\msvc64\runtime\bin` → `R:\dist\msvc64\bin` with `robocopy /E` (never `/MIR`).
`ROBOCOPY_RC=3` — files copied, extras present, nothing deleted. All six deploy-only items verified
by name afterwards: `bin\FrameLib\`, `emulator.exe`, `arduinoTTL.ini`, `eStim.ini`, `feetStim.ini`,
`mStim.ini`. `diff -rq` against the build tree is clean apart from exactly those six.

Content delta was **one executable** (`tepSoundService.exe`) and **five QML bricks**
(`EpochTable.qml`, `Panel.qml`, `ParamControl.qml`, `PlotFrame.qml`, `ScaleBox.qml`). `RunBar.qml`,
`Console.qml` and `SettingsPane.qml` ride inside the executable via `res.qrc`.

**Verified by replaying the whole of file A from `R:\dist\msvc64` itself**: same counts
(`150 · 150 · 140 · 150 · 0`, model 14), and its epoch file is equal to the previous deployed
build's on every dataset except `latency_ms` and `timestamps`.

The tree was deployed **twice**: once with the block-7 fixes, and once more after the two run-bar
attempts were rolled back, so that the source, the build tree and `R:\dist\msvc64` all hold the same
code. The second deploy was re-gated the same way — `150 · 150 · 140 · 150 · 0`, model 14, labels
50/50/50, median **24.27 µV**, max **61.45 µV at Cz**, and **18 of 20 datasets bit-identical** to the
reference run (`latency_ms` and `timestamps` are the two that must differ). Evidence:
`92_final_bar.png`, `rec-DEP3-A`. One rollback point covers both: `bin.pre-tepsound-ui-20260821-041500`.

<a id="history-evidence"></a>

### Evidence

65 PNGs in `R:\dist\_build\tepsound-ui2\`; service logs in `R:\dist\_build\tepsound-features\`
(`tepsound-gateA2`, `tepsound-gateB2`, `tepsound-DEP2-A`, `tepsound-FALL2`, `tepsound-BADP`);
epoch files in `rec-gateA2`, `rec-gateB2`, `rec-DEP2-A`. Driver: `drv.ps1` in the session scratchpad
(now with the scan-code fix). The private desktop was switched back to `Default` and verified; no
service process was left running.


<a id="history-block-8--the-topoplot-built-proven-against-eeglab-gated-and-deployed-2026-08-21-0640"></a>

## Block 8 — the topoplot, built, proven against EEGLAB, gated and deployed (2026-08-21 ~06:40)

**Item 5 of the operator's own list is now IN.** A scalp field driven by the butterfly's time
cursor, switchable against the head-shaped trace array, reusing `topofield.cpp` and `colormap.cpp`
through the `QS_DIR` block rather than forking them.

<a id="history-the-prerequisite-went-in-first"></a>

### The prerequisite went in first

`Tsd::readCed` (`tepSoundService/calibration.cpp:89-128`) now recomputes
`radius = 0.5 - sph_phi/180`, which is what EEGLAB's `readlocs` does, and falls back to the file's
own `radius` column when there is no spherical block. `theta` is left as written: it is `-sph_theta`
and agrees to exactly 0.0 on all 64 rows of both montages in the tree.

⚠ **This moved a pinned number by design.** `plotrad` is **0.678215**, not the 0.678218 quoted in
earlier blocks. 0.678218 was the *rounded* column (`0.66492 x 1.02`); the exact value is
`0.664916666666667 x 1.02`. The oracle prints 0.678215 too. Do not "fix" it back.

⚠ **`Resonance::parseCED` still reads the rounded column and was deliberately left alone.** It is a
Core file that every module in the tree links; changing it rebuilds the signal viewer, the recorder
and every amplifier service. Measured worth: **1.06e-9 V worst-case on the field, 0.0042 % of its
own range.** tepSound reads its montage through its own `readCed`, so the console gets the corrected
geometry either way. `arch_known-issues.md` §23 carries the recipe if it is ever wanted.

<a id="history-what-is-on-screen"></a>

### What is on screen

- `TepTopoView` (`views.hpp:343`, `views.cpp:1088-1460`), registered beside `TepGridView` at
  `main.cpp:67` under `Resonance.TepSoundPlots`.
- The toggle is `Console.qml:75 property bool scalpField`, **false by default** — the panel comes up
  showing the trace array it has always shown. The button reads `field` or `traces`, i.e. the mode
  it is in.
- The cursor is `window.cursorMs`, written by a press/drag MouseArea over the butterfly that is
  `enabled: window.scalpField`. **The traces-mode panel is byte-for-byte unchanged: toggling to the
  field and back leaves 0 of 539 400 panel pixels different.**
- Colour limit = the same `amplitude` the traces use, as a half-range about zero. Typing a number in
  the ScaleBox turns the auto-fit off and sets scalp, butterfly and topo together.
- Channels: `min(scalpPositions().size(), displayed().eegChannels)` — 64 on the shipped montage, no
  EMG. Excluded / non-finite / unplaced channels are left **out of the solve** and drawn **hollow**.
- Contours and the `conv` hull were **not** added; they were not asked for. A colourbar was.

<a id="history--the-field-is-right-and-here-is-what-that-rests-on"></a>

### ⭐ The field is right, and here is what that rests on

Not "it looks like a scalp map". Three independent measurements:

**1. Against the EEGLAB oracle, on 40 000 grid points.** A harness linked against the *shipping*
`topofield.cpp.obj` and `calibration.cpp.obj` was compared with `R:\config\topoplot_v4_reference.py`
on byte-identical inputs:

| | |
|---|---|
| worst absolute difference | **9.32e-18 V** (3.7e-13 of the field's range) |
| RMS difference | 2.22e-18 V |
| the same field transposed | 95.2 % of range |
| ear-mirrored / nose-mirrored | 123.1 % / 87.0 % |

The layout agrees exactly: `plotrad` **0.678215**, `squeezefac` **0.737229344676836**,
head-circle radius **0.339125498551344**, `outlineScale` 0.678250997102689 — every digit the oracle
prints. The interpolant passes through every electrode to **5.1e-18 V**.

**2. Against the oracle again, through the SCREEN.** Every pixel of the rendered disc was inverted
back through the shipping colour ramp to microvolts and compared with the oracle's field for the
same latency, scale and contributing set — so orientation, latency, scale and colour are all tested
at once. Five cursor positions on file A, ~230 000 pixels each:

| cursor | median &#124;screen − oracle&#124; | p95 | as % of the ±50 µV scale |
|---|---|---|---|
| 8.0 ms | 0.108 µV | 0.637 | 0.22 % |
| 14.0 ms | 0.168 µV | 0.753 | 0.34 % |
| 30.0 ms | 0.142 µV | 0.360 | 0.28 % |
| 60.0 ms | 0.168 µV | 0.443 | 0.34 % |
| 100.0 ms | 0.072 µV | 0.195 | 0.14 % |

The residual is the render path, not the maths: `TepTopoView` solves into a 220 px image and lets
`QPainter` scale it onto a 569 px disc.

**3. Orientation, from pixel positions.** The disc's centre and radius are found from the image
alone, each electrode's screen position is computed from that, and the colour there is read back:

| | recorded | read off the pixels |
|---|---|---|
| Fpz, top (dy −223.7 px) | +10.09 µV | +12.75 µV |
| Oz, bottom (dy +223.7 px) | +6.78 µV | +6.68 µV |
| T7, **left** (dx −223.7 px) | **+14.24 µV** | **+14.22 µV** |
| T8, **right** (dx +223.7 px) | **+4.82 µV** | **+4.82 µV** |
| Cz, centre | −32.69 µV | −33.09 µV |

⚠ **The left/right test needs a lateralised field to mean anything.** At 30 and 100 ms this TEP is
near-midline-symmetric and a mirror costs only 1.2–1.4 % — which says the *data* is symmetric, not
that the map is right. **+8.0 ms** is the latency of maximum left-minus-right contrast in this
recording (FT7 +16.27 vs FT8 +5.48, C5 +10.87 vs C6 −3.71), and there a mirror costs **12.19 %,
56× the true map's 0.22 %**. Nose-mirroring is rejected hardest at 14 ms (75.6 % against 0.34 %,
225×), transposition at 14 ms too (53.6 %). Every wrong orientation is decisively rejected by at
least one latency and the true one is correct at all five.

<a id="history-d2--every-mark-over-the-field-is-black"></a>

### D2 — every mark over the field is black

Read from the pixels, at the hottest and the coldest electrode of every capture: the darkest pixel
inside the mark is `rgb(0,0,0)` in all ten cases. `D2-hot-FCz.png` and `D2-cold-PO7.png` show the
same black disc, label and head-circle arc over saturated orange and over saturated blue. The one
non-black stroke is the field's outer boundary, which is panel ink because it is the edge between
the map and the paper.

<a id="history-the-hollow-rule-confirmed-on-both-recordings"></a>

### The hollow rule, confirmed on both recordings

File A excludes 5 (FC1, Fp2, FC3, Fp1, Fpz) and draws exactly those 5 hollow; file B excludes 8
(FT9, FT7, TP9, CPz, TP10, O1, PO7, T7) and draws exactly those 8 hollow. The caption states
`59 of 64 electrodes · 5 excluded` and `56 of 64 · 8 excluded`. Every hollow ring is on the badness
table and no other electrode is hollow.

<a id="history--the-field-during-a-live-run-which-nobody-had-watched-before"></a>

### ⭐ The field DURING a live run, which nobody had watched before

The handover flagged two things as unexercised: what the field does when `scale auto` is on and the
fit republishes the amplitude mid-drag, and whether 64 labels stay legible at the default window
width. Both were driven on the **deployed** build against a live replay of file A:

- The field was switched on at ~70 epochs and the butterfly cursor was dragged **across the full
  width eight times** while epochs kept arriving and the bounded auto-fit kept republishing.
  No crash, no stall, no torn frame; 16 threads and 529 handles throughout.
- The contributing set **changes live and the picture follows**: the caption went from
  `59 of 64 electrodes · 5 excluded · n = 140` on the settled average to
  `61 of 64 · 3 excluded · n = 121` mid-run as the badness table evolved, and exactly the three
  named channels (FC1, AF7, FC3) were the hollow ones.
- ⭐ **The run bar finished 150 / 150 / 140 / 150 / 0, model 14, `150↑ 150↓`** — identical to a run
  with nobody touching the console. **Having the field up and dragging the cursor costs the
  acquisition nothing.**
- Labels: all 64 render without collision at the default 1696 px window; the crowding is at the rim
  (FT9/TP9/FT10/TP10 sit outside the head circle and their text clears it). Legible, not cramped.

⚠ **One friction, and it is the harness's not the product's.** The message strip appears and clears
on its own timer and shifts the control row by 26 px, so a scripted click at a fixed Y is a coin
flip. `tofield.ps1` in the scratchpad clicks, counts saturated panel pixels to check the toggle
actually took, and retries at the other Y. Worth reusing.

<a id="history-build-3"></a>

### Build

`all`, MSVC v142, `chcp 65001` after vcvarsall. Clean. `ninja -t deps` **(VALID)** on
`views.cpp.obj` (#deps 314), `main.cpp.obj` (#deps 324) and `calibration.cpp.obj` (#deps 147) — the
§11c mixed-layout trap did not fire. **No build fix was needed; nothing was broken to repair.**

**647 tests / 19 executables / 0 failures**, against the 639 / 19 baseline: +8, all in
`test_TepSound` (60 → 68). Plus `test_StreamInfo` 18, `test_SamplesCollector` 1, `test_NetworkMode`
10 in loopback, all rc 0.

⚠ **Test binaries exit silently under the Bash tool** even with Qt on `PATH` — its PATH translation
does not reach the child. Run them from PowerShell; the failure looks exactly like "0 tests".

<a id="history--re-gate-both-recordings-speed-1-whole-replay-1"></a>

### ⭐ Re-gate, both recordings, speed 1, whole replay

| | expected | file A got | expected | file B got |
|---|---|---|---|---|
| epochs / accepted / in average / triggers / lost | 150/150/140/150/0 | **identical** | 107/107/97/107/0 | **identical** |
| trigger readout | 150↑ 150↓ | **identical** | 107↑ 107↓ | **identical** |
| labels | 50/50/50 | **50/50/50**, 0 blank | 35/36/36 | **35/36/36**, 0 blank |
| median per-channel peak 15…150 ms | 24.27 µV | **24.27 µV** | 26.95 µV | **26.95 µV** |
| FT9 | — | — | flagged 10.82, repaired 101.77 µV | **10.82 / 101.77 µV** |

Also identical to the reference: `rejected 0`, model 14 / 9, all-zero epochs 0 in `preproc` and
exactly the 10 warm-up in the cleaned array, largest excursion **93.75 µV at +5.0 ms** on file A,
and file B's named channels (Pz −42.78 @ 18, C3 −49.88 @ 15, C4 −27.00 @ 95, CPz −64.53 @ 15,
FCz −26.89 @ 121). Producers clean: 3630 and 2655 blocks, **0 underruns**.

**Not one gate number moved.**

<a id="history-deploy-3"></a>

### Deploy

Rollback point **`bin.pre-tepsound-topo-20260821-062725`** (181 files). `robocopy /E`, never `/MIR`.

⚠ **`/MIR` would now destroy 15 items, not 6.** The six known ones — `bin\FrameLib\`,
`bin\emulator.exe`, `bin\arduinoTTL.ini`, `bin\eStim.ini`, `bin\feetStim.ini`, `bin\mStim.ini` —
**plus 9 `params\ns65-*.json`**. All 15 verified present after the copy; robocopy reported them as
24 Extra files across 16 Extra dirs and left them alone.

Content-wise the deploy was **one binary**: `diff -rq` before the copy found `tepSoundService.exe`
as the only differing file in the whole tree.

**Verified by launching the deployed tree and re-running file A's gate.** Identical run bar,
identical caption, identical badness table, median **24.27 µV**, and **18 of 20 datasets
bit-identical** to the pre-deploy run (`latency_ms` and `timestamps` are the two that must differ;
`mep/onset_ms` only fails `array_equal` because NaN ≠ NaN, and its NaN mask and finite values match
exactly). The topoplot rendered by the deployed build is **pixel-identical** to the one from the
build tree: 0 of 483 000 pixels differ.

<a id="history-evidence-1"></a>

### Evidence

`R:\dist\_build\tepsound-topo\` — the field at 8/14/30/60/100 ms with captions, both toggle
states, the D2 crops, the hollow-electrode crop, file B's field, the deployed-build field, both run
bars, service logs and the three epoch files (`rec-TOPO-A`, `rec-TOPO-B`, `rec-DEP-A`). Layout and
grid dumps in `cpp_layout.csv`, `cpp_grid.csv`, `cpp_ramp.csv`. No service process was left running.


<a id="history--what-is-not-done--the-single-list-gathered-from-every-block"></a>

## ⭐ WHAT IS NOT DONE — the single list, gathered from every block

Written at the end of the last scheduled block before the operator returns. Nothing here stops a
session; everything here is either a display addition or a friction the operator can work around
once they know about it.

<a id="history-the-operators-own-feature---now-done"></a>

### The operator's own feature — ✅ NOW DONE

1. **Item 5 — the topoplot driven by the butterfly cursor, switchable against the head-shaped
   trace array — LANDED in Block 8** and deployed. Proven against the EEGLAB oracle to 9.3e-18 V
   on the grid and to a median 0.07–0.17 µV through the rendered pixels at five cursor latencies,
   with orientation established from pixel positions rather than by eye. Rollback point
   `bin.pre-tepsound-topo-20260821-062725`.
2. **Its prerequisite, the `readCed` `radius = 0.5 − sph_phi/180` recomputation — DONE** in
   `tepSoundService/calibration.cpp`. `plotrad` is consequently **0.678215**, not the 0.678218 that
   earlier blocks quote from the rounded column.
   ⚠ **Still open, and deliberately: `Resonance::parseCED` in Core.** It reads the rounded column
   and the signal viewer inherits the same 1.06e-9 V (0.0042 % of range) error. Fixing it means
   rebuilding every module in the tree for a difference invisible on a scalp map; `arch_known-issues.md`
   §23 carries the recipe.
3. **Not asked for, not added:** the isocontours and the `conv` spline hull. Both are already
   implemented and tested in `topofield.cpp`; wiring either one into `TepTopoView` is a small job if
   the operator ever wants them.

<a id="history-tier-b-and-tier-c-of-the-analysis"></a>

### Tier B and Tier C of the analysis

3. **Tier B and Tier C loose ends in `tepsound-analysis.md` are not all closed.** Block 7 closed
   B6, B12, B13 (which was a harness artefact), B19, B24's discoverability partly, B25, B26, ET-07,
   ET-08, PL-13, TT-05 and TT-06's worst case. Still open, and each is one line in the analysis:
   - **B22** — the epoch table has no `peak`, `model` or `cleaned` column.
   - **B28** — `Average all ☑` and the editable `100` beside it are both live at once; the check box
     silently wins.
   - the `blockReason` text says *"drag one onto Input"* and there **is no Input panel** in this
     console. It also names the Configurator, which does exist, so it is not a dead end — but the
     first half of the sentence points at nothing.
   - **`Trigger edge` is not in the settings pane at all**, and it is the decisive setting behind the
     amber polarity readout. The readout tells the operator what is wrong; the fix is one window
     away in the Configurator.

<a id="history-not-finished-and-rolled-back-rather-than-left-half-done"></a>

### Not finished, and rolled back rather than left half-done

5. ⚠ **The run bar still clips its buttons below about 1150 px.** Fixed where it was found — the
   shipped 1680 px default, and verified again at 1200 px with a block reason up — but at 980 px
   `Reset`, `Save` and `Note…` are gone again and at 760 px only `Arm` survives. Two structural
   fixes were built and measured and **neither changed the rendered layout by a pixel**, for
   reasons that were not explained; both were rolled back so the tree matches what the gates
   proved. `tepsound-analysis.md` §12 UI-11 has the detail and the place to start. The console's
   own `SplitView` minimums put its usable floor near 1150 px, so this is below the width at which
   the rest of the window works.

<a id="history-cosmetic-and-now-measured-rather-than-guessed"></a>

### Cosmetic, and now measured rather than guessed

6. **The strips shift the whole layout.** The message strip and the warnings strip appear and vanish,
   moving every control below them by 26–30 px. Controls move out from under the pointer mid-session.
   Not fixed: reserving the height permanently costs 26 px of plot on every session to spare a rare
   jump, and floating the strips over the work hides what is underneath. It needs a decision, not a
   patch.
7. **Electrode hit areas are offset from the drawn labels.** Hovering directly on a label often
   yields no name; the band that answers is above or below the ink. Clicking works, and the clicked
   electrode is now named on the butterfly, so this is a hover-only irritation.
8. **Attached tooltips wear Qt's default light chrome** — dark text on white — against a dark
   console. `TepToolTip` is themed; the attached `ToolTip.text` used on buttons, pills and plot
   notes is not. One shared instance, one `background`/`contentItem` pair to replace.
9. **The `Seed` spin box clips its own value** (`48 211` runs under the `−` button) and the
   `Protected` channel list scrolls its text out of view. Both are string/number fields narrower than
   their content in a 330 px pane.
10. **`armed` and `running` are distinguished by the status dot's hue only** — blue against green,
   with no label. Every other state on the bar carries words.
11. **A failed protocol load leaves the STIMULUS panel hint describing the previous protocol.** The
    error is loud and correct; the hint beside it is stale. Clearing the loaded protocol on a failed
    load would be honest but would also disarm a live session over a typo, so it was left alone
    deliberately.

<a id="history-verification-not-carried-out"></a>

### Verification not carried out

12. **The 9 s tooltip timeout is set but was not timed.** It is a single property assignment,
    verified to run without the `must be attached to an Item` warning; nobody held a stopwatch to it.
13. **`--autoArm` was used for both gates**, so the `Arm` button's own path was exercised
    interactively in the earlier session rather than inside the gated runs.
14. **`fullscreen` was verified to work, but the guard added for it did not fire** — Qt restored the
    window geometry on its own. The earlier "inert" reading was not reproduced. If it returns, the
    guard is already in `StageWindow.qml`.
15. **The stimulator interlock path (A16) is still untestable here** — it needs a neuroMS stream.
    `stimulator not watched` is the correct reading with no stream nominated, and that is all this
    rig can show.
