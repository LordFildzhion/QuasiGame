# tepSoundService — pre-experiment analysis and execution plan — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/tepsound.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-tepsoundservice--pre-experiment-analysis-and-execution-plan"></a>


**Status:** read-only analysis complete. Nothing was built, nothing was changed.
**Date:** 2026-08-20
**Scope:** `R:\src\tepSoundService` (~9.7k C++, ~2.2k QML), plus the shared sources it compiles from
`../tepService` and `../stimulusService`.
**Purpose:** the operator is about to run a real TMS experiment with a subject in the chair. This
document is the list of everything that could give them a wrong answer without them noticing, a
test plan for every control, a costing for the three requested features, and a replay plan against
the two reference recordings.

**The standard everything is judged against:** *an operator under time pressure must not be able to
get a wrong answer without noticing.* Findings are ranked by that and nothing else.

---


<a id="history-0-read-this-first--four-things-that-change-how-you-spend-the-budget"></a>

## 0. Read this first — four things that change how you spend the budget

<a id="history-01-this-experiment-is-externally-triggered-tepsound-is-a-watcher-not-a-presenter"></a>

### 0.1 This experiment is externally triggered. tepSound is a watcher, not a presenter.

Both reference recordings show an external system (`feetStim`) firing the peripheral stimulus on
**bit1** and the TMS pulse on **bit0** at a fixed +60.28 ms ISI. tepSound's job is to *see the TTL
edge and cut epochs*. It is not presenting cues and it is not firing the coil.

That single observation retires four of the loudest UI findings from the priority list. The entire
subject-stage / protocol-presentation subsystem is dead (§2, B1–B4) — and for **Arm-only operation
it does not matter**, because `Arm` runs the full analysis path without presenting anything
(`service.cpp:1369-1372`).

⇒ **Declare Arm-only the supported mode for this experiment.** Fix the stage bugs anyway (they are
about an hour, §2 B1–B4) so that `Start` cannot silently do nothing, but do not let the stage
subsystem consume the budget.

<a id="history-02-the-mojibake-concern-is-a-false-alarm-do-not-spend-a-day-on-it"></a>

### 0.2 The mojibake concern is a false alarm. Do not spend a day on it.

`R:\src\tepSoundService\CMakeLists.txt:11-14` already carries, ahead of `add_executable` and
applying to both targets:

```cmake
if(MSVC)
    add_compile_options(/utf-8)
endif()
```

Verified present. `tepService` has the same at its line 13. **`quickStimulus` does not**, which is
why the viewer produced `В±100 uV В· -100вЂ¦399 ms` and why tepSound will not. All 26 source files
decode as clean UTF-8. MinGW/GCC defaults to UTF-8 input, so that toolchain is fine too.

Both independent surveys reached this conclusion separately. **Treat the 84 non-ASCII characters as
a non-issue for the binary.** Two residual real risks, both small, both in §3 C-tier:
- **Glyph coverage**, not encoding: `EpochTable.qml:122` pins `font.family: "Consolas"`, which has
  no U+26A0 ⚠. A tofu box looks identical to mojibake and has a different cause.
- **The log path**: `qWarning()` goes to a console whose active code page here is CP1251. Narrow
  output of em-dashes and middots to *that* console is genuine mojibake.

<a id="history-03-the-parked-anchor-defect-is-genuinely-fixed--with-two-residual-gaps"></a>

### 0.3 The parked anchor defect is genuinely fixed — with two residual gaps

The parked defect ("the newest-epoch anchor is trusted, not validated") **was really fixed, and
fixed well.** `SoundStore::canAnchor()` (declared `soundstore.hpp:172`, defined
`soundstore.cpp:203-210`) validates the anchor, and `reduce()` walks backwards to the newest epoch
that passes, counting what it skipped (`soundstore.cpp:253-266`). `SoundAverage` gained
`anchorSkipped` / `anchorSerial`; the zero-channel division in the GFP loop is now unreachable.

**Two gaps remain, both worth carrying into the fix phase:**
1. `canAnchor` validates **shape but not finiteness**. A trace of the right length full of NaN — or,
   per A3 below, full of exact zeros from a stale operator — anchors happily and then dominates the
   average. Add an `isfinite` scan (and a not-all-zero check).
2. The diagnostic it produces is `qWarning()`-only (§2 B7), so the fix is **invisible to the
   operator it was written for**.

Cosmetic: the status channel is spelled `anchorRejected` (`statuschannels.hpp:101`) while the field
and every comment say `anchorSkipped`.

<a id="history-04-the-republish-churn-hole-that-bit-tepservice-is-not-present-here"></a>

### 0.4 The republish-churn hole that bit tepService is NOT present here

`tepService/service.cpp:1286-1290` ANDs each `...Ok` term with that stream's publish flag, so a flag
that is off makes the term false forever and both streams are torn down on every `reconfigure()` —
expensive, because `TcpStreamSender` listens on port 0 and every republish moves the port.

tepSound's predicate (`service_analysis.cpp:431-433`) has **no publish-flag term at all**. The flags
gate only the send, in `publishEpoch()` (`:890-893`) and `publishAverage()` (`:934`). Its `matches()`
is materially better than tepService's: it reads `window_start_ms`/`window_end_ms` back off the
stream metadata for **every** channel, not entry 0, because the MEP channel rides the guarded time
base and moves independently. **No work needed here.** Three residual republish triggers are noted
in §3 C-tier for awareness only.

---


<a id="history-1-tier-a--would-mislead-these-cost-a-session"></a>

## 1. TIER A — would mislead. These cost a session.

Ranked by *how likely it is to fire during this experiment × how invisible it is when it does.*
Every one of these produces a plausible-looking wrong answer.

---

<a id="history-a1-the-tms-blank-ends-03-ms-before-the-artefact-does--every-trial-both-files-at-defaults"></a>

### A1. The TMS blank ends ~0.3 ms before the artefact does — every trial, both files, at defaults

| | |
|---|---|
| **Where** | `service.cpp:441` (`blankFrom = -0.04`), `service.cpp:453` (`blankTo = +0.85`) |
| **Measured** | Artefact starts 0.000–0.040 ms after the bit0 rise; amplifier is at its ±0.44 V rail for ~0.6 ms; **last sample above 50 mV is at +1.12 to +1.16 ms in every trial of both files** |
| **Operator sees** | A clean epoch. The per-epoch `tmsInterp -1…+5 ms` ramp covers the residual afterwards. |
| **Wrongly concludes** | The blanking worked. |
| **What actually happens** | Samples from +0.85 to +1.16 ms carry 30–100 mV (30 000–100 000 µV) into the **continuous** highpass/notch/lowpass — which `service.cpp:434`'s own tooltip says is exactly the thing that must never happen ("a TMS artefact is volts against microvolts, and putting one through an IIR filter makes it ring for tens of milliseconds"). The ringing is in the continuous state, so it contaminates the *following* epochs, not this one, and `tmsInterp` hides the source. |
| **Fix** | Raise `blankTo` to **1.3 ms** for this rig. One default. Additionally: have the pipeline measure and report post-blank residual so this is discovered rather than inherited. |
| **Effort** | 15 min for the default; 2 h for the residual measurement + a warning. |

⚠ Also note `blankFrom = -0.04 ms` is exactly **one sample** of lead at 25 kHz, and the artefact
begins on the trigger sample itself in most trials. There is no margin at all. Suggest −0.2 ms.

**This is the top finding: it fires at defaults, on this data, on every single trial.**

---

<a id="history-a2-the-projects-own-nvx-rig-note-is-the-opposite-of-what-these-files-do"></a>

### A2. The project's own NVX rig note is the opposite of what these files do

| | |
|---|---|
| **Where** | `R:\docs\_notes\report_trigger-validation.md` §2 vs. the measured data; `service.cpp:306-312` (`triggerEdge`, **no `setDescription` — empty tooltip**) |
| **The note says** | idle word `0x0000EFFF`; "an input edge is a bit going **LOW**" |
| **The files say** | idle word **`0x0000FFFA`**; bit0 **rests LOW and pulses HIGH for exactly 10.00 ms** (250 samples; 3 of 257 pulses measure 10.04 ms = one-sample jitter) |
| **Operator sees** | If someone applies the written rule and sets `triggerEdge = Falling`: the same 150/107 epochs, a perfectly normal-looking average. |
| **Wrongly concludes** | Everything is fine. |
| **What actually happens** | Every epoch is cut **10.0 ms late**, silently. A 10 ms shift moves the entire early TEP complex. |
| **Worse variant** | bit1 is a *second real event line* — 150/107 falling edges, 50.2 ms wide, asserting **60.28 ms before** every bit0 rise (that is literally the `+60` in both filenames). `triggerBit = 1, Falling` yields a flawless average of the **peripheral sensory evoked potential** with the TMS artefact parked at +60 ms. Nothing in the UI would say which one you epoched. |
| **Fix** | (a) Add a `setDescription` to `triggerEdge` naming the per-rig hazard. (b) Add a **detected-polarity readout** to the run bar: resting level, edges seen, mean pulse width. (c) Amend `report_trigger-validation.md` to say the rule is per-rig. (d) Assert `triggerEdge == Rising` in the replay acceptance criteria. |
| **Effort** | 3 h including the readout. |

**Defaults are already correct** (`triggerChannel = 0` → last channel → index 72; `triggerBit = 0`;
`triggerEdge` index 0 = Rising, `Select::Select()` initialises `m_index(0)`). The danger is entirely
that a well-meaning workflow "corrects" them.

---

<a id="history-a3-any-mid-session-geometry-change-reshapes-a-stale-training-buffer-and-keeps-a-stale-model"></a>

### A3. Any mid-session geometry change reshapes a stale training buffer and keeps a stale model

Two defects with one trigger. **The trigger is a completely normal operator action: nudging a
window slider mid-session.**

**A3a — the training buffer survives the geometry change.**
`SoundPipeline::configure()` (`soundpipeline.cpp:21-119`) rewrites `m_geometry` including
`outputSamples`, and **never touches `m_train`**. Verified: `m_train.clear()` appears **only** at
`soundpipeline.cpp:129`, inside `reset()`, which is called only from `beginSession()`
(`service.cpp:1446`) and `resetSession()` (`service.cpp:1554`). `reconfigure()` calls
`m_sound.configure(...)` at `service_analysis.cpp:274` and nothing else.

So `snapshot()` (`soundpipeline.cpp:325-346`) stamps `s.samples = m_geometry.outputSamples` (**new**)
onto `m_train` vectors that are still `nCh × oldSamples`. Neither consumer validates length:
`trainSound()` checks only `epochs.empty() || nCh<2 || nT<2 || lfm.rows!=nCh` (`sound.cpp:325`) then
indexes `e.data() + c*nT` (`sound.cpp:336-338`); `analyseOnce()` checks only `times.size()==nT`
(`badchannels.cpp:253`) then indexes `epochs[e].data() + c*nT + mainFrom` (`badchannels.cpp:277-280`).

- `newSamples > oldSamples` → **heap read past the end of every training vector** (may crash, may not)
- `newSamples < oldSamples` → in-bounds but every channel row read at the wrong offset — a
  **channel-scrambled training block**

**A3b — the model survives too, and produces an all-zero "clean" that then anchors the average.**
`configure()` never clears `m_model` either. After an `eegChannels` change with a still-matching
montage, `m_model.valid` is true with a 64×64 operator while `n` differs. `process()` guards only on
validity (`soundpipeline.cpp:283`), assigns `out.clean` to `n*outputSamples` **zeros** at line 284,
then calls `applyOperator`, which bails silently on shape mismatch
(`if (op.rows <= 0 || op.cols != n) return;`, `linalg.cpp:48-49`) leaving the zeros. `out.clean` is
non-empty and exactly the right length, so `canAnchor()` accepts it, it **anchors the average**, and
`anchorSkipped` stays 0.

Note the inconsistency: the *display* path `SoundStore::traceOf()` **does** check
`m_model.operatorMatrix.rows != n` (`soundstore.cpp:160`), and `cleanWith()` does too
(`soundpipeline.cpp:374`). **Only the live per-epoch path does not.**

Same class from `multiply()`, which returns a **zero** matrix rather than an empty one on dimension
mismatch (`linalg.cpp:27-29`), so `rebuildSpatial()` can hand `process()` an all-zero `m_repairIca`
and the whole preprocessed epoch becomes zeros (`soundpipeline.cpp:257-261`).

| | |
|---|---|
| **Operator sees (a)** | A new `model N` in the console with a plausible sigma median and condition number; the traces look different. |
| **Wrongly concludes (a)** | The window change explains it. |
| **Operator sees (b)** | Perfectly flat traces at exactly 0 µV; epoch count still climbing; n still climbing. |
| **Wrongly concludes (b)** | The cap came off / the amplifier stopped. |
| **Fix** | Clear `m_train` and `m_model` in `configure()` whenever the geometry changed; add the same `operatorMatrix.rows != n` guard to the live `process()` path that `traceOf()` already has; make `multiply()` return empty (not zeros) on mismatch and have callers check; add finiteness + not-all-zero to `canAnchor()` (closes 0.3's residual gap 1). |
| **Effort** | 4 h. |

---

<a id="history-a4-stop--arm-keeps-the-previous-sessions-epochs-so-the-average-silently-spans-two-sessions"></a>

### A4. Stop → Arm keeps the previous session's epochs, so the average silently spans two sessions

| | |
|---|---|
| **Where** | `beginSession()` `service.cpp:1440-1471` (verified: resets `m_pipeline`, `m_sound`, `m_store.setModel(...)`, the worker and `m_counters` — but **never `m_store.clear()`**); `endSession()` `service.cpp:1473-1502` does not either |
| **Trigger** | The entirely normal sequence **"Stop, reposition the coil, Arm again."** |
| **Operator sees** | A running average that already has n≈80 the moment they re-arm, and keeps climbing. |
| **Wrongly concludes** | Collection resumed cleanly. |
| **What actually happens** | Old epochs — from a different coil position, a different filter warm-up, possibly a different subject state — keep contributing to `average()`, to `acceptedCount`, to the epoch table, and to the next `saveEpochs()`. Because `expandFileName` advances the `$$$` counter (`service_run.cpp:814-825`), they are **written a second time into a new file**. |
| **Recovery** | Only by pressing `Reset` — i.e. by A5, the most dangerous button in the program. |
| **Fix** | Clear the store in `beginSession()`, or (better) prompt: "keep 87 epochs from the previous session?" with keep/discard. Add a visible session boundary marker in the epoch table either way. |
| **Effort** | 2 h (clear-on-arm), 4 h (with the prompt + boundary marker). |

---

<a id="history-a5-reset-destroys-the-entire-session-on-one-click--no-confirmation-no-autosave-no-undo-live-mid-run"></a>

### A5. `Reset` destroys the entire session on one click — no confirmation, no autosave, no undo, live mid-run

| | |
|---|---|
| **Where** | `RunBar.qml:150-154` — verified: **there is no `enabled:` clause at all**, so it is live in every state including `running` |
| **What it does** | `resetSession()` (`service.cpp:1550-1571`): `m_store.clear()` (every stored epoch — preprocessed, cleaned, MEP, guarded), `m_log.clear()` (the whole epoch table), `m_selection.clear()`, `m_sound.reset()` (the trained operator **and** the channel report), `m_counters = {}`, worker reset |
| **Where it sits** | Immediately beside `Stop` and `Save`, in the same row, with identical styling |
| **Autosave does not protect you** | `m_autoSave` runs only from `endSession()` (`service.cpp:1496-1500`). **Reset does not save first.** |
| **Operator sees** | Everything gone. Instantly. |
| **Cost** | Every epoch since the last Stop, the noise model, and the log — with no file written. Then the SOUND warm-up (10 epochs) has to happen again, during which `clean` publishes nothing. |
| **Fix** | (a) Confirmation dialog naming the count: "Discard 87 epochs and the trained model?" (b) `enabled: runState === "idle"`. (c) Autosave before reset when there is anything to lose. (d) Move it out of the primary row, or style it as destructive. |
| **Effort** | **1 h. This is the cheapest large win in the document.** |

Classified Tier A rather than "obstruction" because the loss is instant, total, and irreversible —
the operator notices, but noticing does not help.

---

<a id="history-a6-typing-into-an-integer-setting-may-not-apply-it--and-definitely-stops-the-display-tracking"></a>

### A6. Typing into an integer setting may not apply it — and definitely stops the display tracking

| | |
|---|---|
| **Where** | `import/Resonance/TepSound/ParamControl.qml:70` and `:90` |

Verified source:

```qml
SpinBox {
    value: root.param !== null ? root.param.value : 0      // declarative binding
    onValueModified: if (root.param !== null) root.param.value = value
    contentItem: TextInput {
        text: parent.textFromValue(parent.value, parent.locale)
        onEditingFinished: parent.value = parent.valueFromText(text, parent.locale)   // ← direct assignment
    }
}
```

**Certain:** `parent.value = ...` is a direct assignment to `SpinBox.value`, which **permanently
destroys** the `value: root.param.value` binding. From that moment the box shows whatever was last
typed and no longer reflects the service — after a Configurator edit, a `--serviceConfig` apply, or
`reconfigure()` clamping the value.

**Uncertain and decisive:** whether the *parameter* is written at all. `onValueModified` is
documented as firing when the value is "interactively modified by the user"; a programmatic
`setValue` emits `valueChanged`, not `valueModified`. Qt 5.15's own default `SpinBox.qml`
(`C:\Qt515\5.15.2\msvc2019_64\qml\QtQuick\Controls.2\SpinBox.qml:64-76`) has **no such
`onEditingFinished` handler** — tepSound added it. I could not resolve from the shipped headers
whether Qt's internal commit path also runs and emits `valueModified`.

- **If it does not fire:** typing `250` into `Window to` shows 250 and **the service keeps 500**.
  Every integer setting in the pane would be un-typeable. That is a Tier-A-topping defect.
- **If it does fire:** the parameter is written and only the display goes stale (still Tier A —
  see A7).

⇒ **Test T-K1 (§4) must resolve this before anything else.** It is a five-minute test.

**Fix is correct in both worlds and is one line:**
```qml
onEditingFinished: if (root.param !== null) root.param.value = parent.valueFromText(text, parent.locale)
```
Assigning to `root.param.value` instead of `parent.value` writes the parameter *and* leaves the
binding intact, so the box re-reads the (possibly clamped) value the service actually adopted.

| **Effort** | 30 min for the fix; the test is what sets the priority. |

**Affected rows:** Window from, Window to, Guard, Epoch rate, Block size, Retrain every, Warm-up,
passes, Screen over, Average over, Keep epochs, Single MEPs, Seed.

---

<a id="history-a7-every-double-field-stops-tracking-its-parameter-after-the-first-edit"></a>

### A7. Every double field stops tracking its parameter after the first edit

| | |
|---|---|
| **Where** | `ParamControl.qml:101` declares `text: root.param.value.toFixed(root.decimals)`; `:125` assigns `text = root.param.value.toFixed(root.decimals)` inside `onEditingFinished` |

Here the parameter **is** written correctly (`root.param.value = v` at `:123`), then the `text`
binding is destroyed by the assignment on the next line. So the value applies, but the box no longer
follows the parameter.

**Operator sees** a number that is not necessarily in force. **Wrongly concludes** that what is on
screen is what the pipeline is using. Bites specifically after `reconfigure()` clamps a value, after
a Configurator edit, and after a `--serviceConfig` apply.

**Affected:** Blank from, Blank to, TMS interp ×2, Baseline from, Baseline to, Anti-alias, Reject
above (µV), Lambda, all five channel thresholds, Repair at most, Coil limit, MEP Measure from,
Measure to, Threshold, Trend window, Reject above (RMS). **That is most of the pane.** (The string
editor at `:144` does not assign to `text` and is safe.)

**Fix:** delete the `text = ...` line and let the binding restore itself, or restore the binding
explicitly. **Effort: 30 min, same pass as A6.**

---

<a id="history-a8-baseline-correction-silently-does-nothing-when-the-window-is-reversed--and-takes-mep-rejection-and-onset-with-it"></a>

### A8. Baseline correction silently does nothing when the window is reversed — and takes MEP rejection and onset with it

| | |
|---|---|
| **Where** | `soundpipeline.cpp:218-227`; `epochprocessor.cpp:65-66`, `:284-291`, `:297`; `service_analysis.cpp:705-709` |
| **Trigger** | The operator types `Baseline from -10` / `Baseline to -60`. Both spinboxes accept the full −5000…0 range (`service.cpp:601-620`) and **`baselineFrom` has no tooltip at all.** |

`bFrom` = first sample with `t >= baselineFromMs`; `bTo` = last with `t <= baselineToMs`. Reversed →
`bTo < bFrom` → the `if (bFrom >= 0 && bTo >= bFrom)` at `:227` is false and **no baseline is
subtracted**, silently.

The same reversal disables the EMG path: `applyBaseline()` returns early on
`m_baselineFrom >= m_baselineTo`, so the pre-stimulus RMS loop runs zero times, `n == 0`, and
`baselineRmsMv = NaN`. That NaN then:
- (a) makes `onsetMs` stay NaN (guarded at `:297`)
- (b) makes **pre-innervation rejection inoperative**, because `takeEpoch` requires
  `std::isfinite(stored.mepBaselineRmsMv)` before it will reject
- (c) is written into HDF5 unguarded (`soundstore.cpp:502`) and onto the status stream
  (`service_analysis.cpp:1111`)

`warnings()` covers the baseline overlapping the TMS interpolation (`service_run.cpp:856`) and the
baseline starting before the window opens (`:873`) but has **no check for `baselineFrom > baselineTo`
and none for the baseline falling entirely outside the epoch.**

**Operator sees** traces with a DC offset, an empty onset column, and an EMG rejection setting that
never fires. **Wrongly concludes** the subject is drifting.

**Fix:** add both checks to `warnings()`; refuse the reversed range at the parameter; give
`baselineFrom` a description. **Effort: 1.5 h.**

---

<a id="history-a9-phantom-epochs--refused-epochs-are-still-stored-counted-logged-and-reported-as-accepted"></a>

### A9. Phantom epochs — refused epochs are still stored, counted, logged and reported as "accepted"

| | |
|---|---|
| **Where** | `service_analysis.cpp:711-731`, `:740`, `:746-747`, `:1101`; `soundstore.cpp:98-104` |

`takeEpoch` is `if (soundEnable && isReady && process(...)) {...} else if (isReady) { if (process(...)) {...} }`.
When `process()` returns false (its documented reconfiguration race, `soundpipeline.hpp:142-143`) the
else branch calls it a second time and it fails again. `stored.samples` stays 0, `preproc`/`clean`
stay empty — but `m_store.add(std::move(stored))` runs **unconditionally** at `:740`, with
`publishEpoch` and `appendLog` at `:746-747`, and `m_counters` is untouched. When
`m_sound.isReady()` is false outright (a montage/lead-field error), *neither* branch runs and the
same empty epoch is stored.

The empty epoch is excluded from `reduce()` but **is** counted by `epochCount()` and by
`m_store.accepted()` — which is what the status stream publishes as `accepted`.

**Operator sees** "epochs 48" climbing on the run bar and the status stream's `accepted` climbing,
while "in average" reads 0 with a blank plot.

⚠ `soundpipeline.hpp:196` claims this case "is counted, not logged". **It is neither counted nor
logged anywhere.** (Self-admitted gap; see §3.)

**Fix:** do not store an epoch `process()` refused; add a counter and surface it. **Effort: 2 h.**

---

<a id="history-a10-two-different-numbers-are-both-called-accepted-and-the-optimistic-one-is-on-the-wire"></a>

### A10. Two different numbers are both called "accepted", and the optimistic one is on the wire

`acceptedCount()` (the console) is `m_store.average().contributing` (`service.hpp:170`) — epochs that
actually contributed. The status stream's `accepted` channel is `m_store.accepted()`
(`service_analysis.cpp:1101`) — every stored epoch not flagged `rejected`, **including the phantom
empty epochs of A9 and every warm-up epoch with no `clean`.**

A monitor watching the status stream and an operator watching the run bar will disagree, and the
stream's number is the optimistic one. **Fix: rename one, or make both mean "contributing".
Effort: 1 h.**

---

<a id="history-a11-n--on-the-butterfly-is-always-the-running-averages-n-even-when-the-panel-is-drawing-a-selection"></a>

### A11. "n =" on the butterfly is always the running average's n, even when the panel is drawing a selection

| | |
|---|---|
| **Where** | `Console.qml:220` reads `acceptedCount`; the panel draws `displayed()` (`service_run.cpp:519`), which is `averageOf(m_selection)` whenever `showAverage` is false |

Select three epochs: the middle panel's title correctly says `TEP · 3 epochs` (`Console.qml:49`), the
scalp grid's painted caption correctly says `n = 3` (`views.cpp:333`), and the butterfly **directly
beside them** says `n = 87`.

**Two numbers on one screen describing the same data, one of them wrong.** **Fix: bind it to
`displayed().contributing`. Effort: 15 min.**

---

<a id="history-a12-an-invalid-mep-is-displayed-and-written-as-0000--indistinguishable-from-a-real-zero"></a>

### A12. An invalid MEP is displayed and written as `0.000` — indistinguishable from a real zero

| | |
|---|---|
| **Where** | `service_analysis.cpp:1177-1179`; `EpochTable.qml:132`; `Console.qml:261`; `soundstore.cpp:499-501` |

`MepMetrics`' own header promises the opposite, verbatim: *"NaN where the window did not contain the
samples the measurement needs, never a zero — a zero amplitude is a finding, a missing one is not"*
(`epochprocessor.hpp:77-78`). Yet the struct defaults `amplitudeMv = 0.0` / `onsetMs = 0.0` and
`measure()` returns that default on all three early-return paths (`epochprocessor.cpp:238, 243, 269`).

The conflation reaches: `appendLog` (0.0 for both), the epoch table's `amplitude.toFixed(3)` →
`"0.000"`, the MEP panel header `"… mV last"`, and the HDF5 file — where `mepAmp[e] = epoch.mepValid
? epoch.mepAmplitudeMv : 0.0` and **there is no `mep/valid` dataset at all**, so the offline analysis
cannot recover the distinction either.

Note the onset column *does* render 0 as an em-dash (`EpochTable.qml:140`). **The two columns are
inconsistent with each other.**

**Operator sees** `0.000 mV`. **Wrongly concludes** the subject produced no response on that trial —
when in fact it was not measurable.

**Fix:** render non-finite/invalid as `—` everywhere; write a `mep/valid` dataset; stop substituting
0.0 in `appendLog`. **Effort: 2 h.**

---

<a id="history-a13-peak-rejection-is-measured-after-repair-and-car-so-a-huge-artefact-on-a-repaired-channel-cannot-trigger-it"></a>

### A13. Peak rejection is measured *after* repair and CAR, so a huge artefact on a repaired channel cannot trigger it

`soundpipeline.cpp:268-279` walks `filtered`, which by then has had `m_car` applied (`:250`) and
`m_repairIca` applied (`:259`). A spline-repaired channel's samples are by construction a smooth
combination of its neighbours — **whatever made it bad has already been replaced by the time `peakUv`
is measured.**

`rejectPeakUv`'s own description (`service.cpp:624-632`) describes catching a burst at ~4000 µV
against a 455 µV median. The case where the burst sits on a channel the detector has just flagged and
repaired is **exactly the one this ordering misses**. `peakUv` is also the only number written to the
file and the log for that trial.

**Fix:** measure the peak on the pre-repair, pre-CAR filtered epoch (or measure both and report
both). **Effort: 2 h.** ⚠ Relevant to file B, where FT9 is 33× the median.

---

<a id="history-a14-the-epoch-file-is-internally-inconsistent-after-any-mid-session-window-change-and-warm-up-epochs-are-unmarked-zeros"></a>

### A14. The epoch file is internally inconsistent after any mid-session window change, and warm-up epochs are unmarked zeros

| | |
|---|---|
| **Where** | `soundstore.cpp:461-463`, `:485-493`, `:467`, `:489-490`; `service_run.cpp:755-758` |

`SoundStore::save()` takes `nT` and `nCh` from `m_epochs.front()` — **the oldest epoch** — and then
clamps every epoch into that shape, silently truncating or zero-padding any epoch of a different
geometry. Meanwhile the file's `Fs`, `window_start_ms` and `window_end_ms` attributes come from the
**current** geometry. After a window change the array and its labels describe different things, and
nothing says so.

Separately, `clean` is zero-initialised at `:467` and only filled `if (from < epoch.clean.size())`, so
a warm-up epoch (collected before the first operator existed, `soundpipeline.cpp:290`) contributes a
block of **exact zeros** to the `epochs` dataset. No `cleaned` flag is written; `rejected` does not
mark them.

**The operator sees nothing** (and, per B7, does not even see "epochs written to …"). **The offline
analysis reads a misaligned epoch matrix labelled with the wrong window, containing unmarked zero
rows.**

**Fix:** refuse to save across mixed geometries (or write per-epoch geometry); write a `cleaned`
flag and a `mep/valid` dataset. **Effort: 3 h.**

---

<a id="history-a15-rawepochartifactapplied-is-set-true-even-when-the-blanking-was-skipped--and-nothing-reads-it"></a>

### A15. `RawEpoch::artifactApplied` is set true even when the blanking was skipped — and nothing reads it

`Pipeline::applyArtifacts()` sets `event.artifactDone = true` on **all three** paths: success
(`pipeline.cpp:331`), the "span reaches before the staging buffer" skip (`:292-293`) and the "span
does not fit" skip (`:300-303`) — the latter two each bumping `m_counters.artifactSkipped`.
`drainEvents` then computes `epoch.artifactApplied = m_settings.artifact && event.artifactDone`
(`:416`) — true in every case. `takeEpoch` never reads the field at all.

So an epoch whose multi-volt hardware artefact was **never interpolated out** is stored, filtered,
SOUND-cleaned, averaged and published exactly like a good one — and **it can land in the first
training block, poisoning the first noise model.**

`artifactSkipped` never crosses the thread either: `SignalWorker` forwards only
`triggers, refused, starved` (`signalworker.cpp:77-82`, `service.hpp:301`).

**Operator sees nothing at all. Wrongly concludes the model warmed up normally.**
**Fix:** set the flag only on the success path; forward the counter; reject or mark such epochs.
**Effort: 2 h** (shares the counter plumbing with B8).

---

<a id="history-a16-the-stimulator-interlock-fires-open-when-the-thing-it-gates-on-has-never-spoken"></a>

### A16. The stimulator interlock fires open when the thing it gates on has never spoken

`tmsBlocker()` returns an empty string (= permit) whenever `!m_tms.present`
(`service_run.cpp:332-336`). `m_tms.present` is set only inside `onTmsBlock`
(`service_analysis.cpp:650`) and reset by `onTmsStreamChanged` (`:607`).

So an operator who wires the neuroMS status stream and ticks **Require ready** gets **no gate at
all** if the neuroMS service is down, mis-named, or has not published yet. Every pulse fires.
Staleness *is* checked (`service_run.cpp:337-340`) but only once `present` has become true.

The run bar renders this as `stimulator: not watched` in dim grey (`RunBar.qml:104-106`), which reads
as *"you chose not to watch it"* rather than *"the interlock you enabled is inoperative."*

**Fix:** when `Require ready` is on and `!present`, **block** and show it in red. **Effort: 1 h.**
(Lower rank only because this experiment fires the coil externally.)

---

<a id="history-a17-sampleat-clamps-to-the-epoch-edge-instead-of-reporting-that-the-request-is-outside-it"></a>

### A17. `sampleAt()` clamps to the epoch edge instead of reporting that the request is outside it

`service_run.cpp:1000-1012` returns `max(0, min(samples-1, index))` on both time bases, and
`EpochProcessor::sampleAt` does the same (`epochprocessor.cpp:51-55`). So `measure()`'s window
silently extends to the last sample when `mepTo` exceeds the epoch, and the shaded "measurement
window" the MEP panel draws (`views.cpp:610-618`) shows the **clamped** span while the label beside
it says whatever the operator typed.

⚠ **This is inherited by any new time cursor (Feature 1):** dragging past the edge quietly pins to
the edge value while the readout keeps reporting the requested time.
**Fix: return a validity flag; grey the readout when clamped. Effort: 2 h.** Do this *before* the
topoplot lands.

---

<a id="history-a18-two-different-peak-to-peak-amplitudes-for-the-same-trial-on-adjacent-panels"></a>

### A18. Two different peak-to-peak amplitudes for the same trial, on adjacent panels

`EpochProcessor::measure()` computes it over `[sampleAt(mepFromMs), sampleAt(mepToMs)]` against
`m_settings.samples`, gated on `counted > 0` → `mepValid` (`epochprocessor.cpp:240-278`).
`TepTraceView::paintMepStrip()` recomputes it **independently** over the same nominal window but
bounded by `mep.size()` and gated only on `peakAt >= 0` (`views.cpp:690-708`), printing its own
number at `:773`. It ignores `mepValid` entirely.

So the single-trial strip can print a millivolt figure for a trial the table above it shows as
`0.000`. After a mid-session geometry change they also diverge, because stored MEPs are the old
length while `windowFrom/To` are computed against the new.
**Fix: one measurement, computed once, displayed twice. Effort: 1.5 h.**

---

<a id="history-a19-the-condition-label-is-read-at-delivery-time-not-latched-at-the-trigger"></a>

### A19. The condition label is read at delivery time, not latched at the trigger

`stored.label = m_presenting ? m_currentCue : m_pendingMarker` (`service_analysis.cpp:687`) is
evaluated inside `takeEpoch`, which runs `windowEnd + guard + processing` ms **after** the trigger.
`m_pendingMarker` is overwritten by every marker block (`:596`).

**Measured in the operator's own files:** the `stimuli` message arrives **101.1–120.9 ms before** its
bit0 rising edge (median 104.9 / 104.0 ms), and the minimum inter-trigger interval is **1537 ms**
(file 1) / **1543 ms** (file 2). So the next trial's label lands ~1432 ms after this trial's trigger,
while the default epoch tail is 500 + 200 = 700 ms — **732 ms of headroom.**

Raise `Window to` from 500 to ~1250 ms (the spinbox allows 5000, `service.cpp:384`) or the guard from
200 to ~950 and **every epoch is stamped with the next trial's condition.**

**Operator sees** a plausible condition on every row. **Wrongly concludes** the between-condition
contrast is real. **Fix is one line: capture the label into the `Tep::Event` at trigger time.
Effort: 1 h.** Ranked here rather than higher only because the defaults leave headroom — but the fix
is trivial and it is a landmine under a setting the operator is invited to change.

---

<a id="history-a20-with-average-of--current-model-epochs-that-cannot-be-re-cleaned-silently-contribute-their-online-clean"></a>

### A20. With `Average of = current model`, epochs that cannot be re-cleaned silently contribute their *online* clean

`SoundStore::traceOf()` (`soundstore.cpp:153-161`): `if (!m_model.valid || epoch.preproc.empty())
return epoch.clean...;` and `if (m_model.operatorMatrix.rows != n) return epoch.clean...;`

So the average the operator reads **to judge whether the noise model has settled** — the documented
purpose of the setting (`service.cpp:1155-1157`) — is a **mixture** of newest-model re-cleans and
whatever operator happened to be current when each epoch arrived. Nothing on screen distinguishes
them, and `contributing` counts them all.

**Fix: count and report the mixture ("62 of 87 re-cleaned"). Effort: 1.5 h.**

Related cost, not correctness: `invalidateModel()` drops every cached re-clean
(`soundstore.cpp:125-134`) at every calibration, so the next `average()` re-runs a 64×64 × 64×701
product for up to `epochBuffer` epochs **on the GUI thread** — ~575 MFLOP at 200 epochs, every
`trainDn` epochs.

---

<a id="history-a21-oncuepresented-pops-the-queue-by-position-and-never-checks-what-was-actually-presented"></a>

### A21. `onCuePresented` pops the queue by position and never checks what was actually presented

`service_run.cpp:200-207`: `cueId` and `marker` are `Q_UNUSED` and the handler does
`m_queued.takeFirst()` unconditionally. If the stage ever drops, reorders or coalesces a
presentation, the queue desynchronises and **every subsequent epoch carries the wrong `cueId`,
`marker`, `trialIndex`, `trigger` and `triggerAtMs`** — into `m_currentCue`, the `events` stream and
`m_trialIndex`. The two fields needed to detect it are already in the signal's arguments and are
explicitly discarded.

**Fix: compare and log a desync. Effort: 1 h.** Only reachable once the stage works (B1), so
schedule it with B1 or skip if Arm-only.

---

<a id="history-a22-nothing-checks-that-signal-channel-n-is-montage-electrode-n"></a>

### A22. Nothing checks that signal channel N is montage electrode N

`checkPairing()` (`calibration.cpp:174-234`) compares the montage against the lead field only;
`SoundPipeline::configure()` compares only channel **counts** (`soundpipeline.cpp:35-38`). The signal
stream's per-channel `name` metadata is never read — the TMS status stream's is
(`service_analysis.cpp:623-626`) but the signal stream's is not.

⚠ **Measured: both recordings carry `metaData = {}` on the `eeg` stream** — no channel names, no
units. So on playback there is nothing to check against even if the check existed.

**But I verified the order empirically** and it is correct — see §5.3. A cap wired in a different
order produces a well-formed SOUND operator, a well-formed spline repair and a well-formed topography
that are **wrong everywhere**. This is the same failure class `checkPairing` was written to prevent,
one link upstream.

**Fix: read and compare stream channel names when present; warn loudly when absent. Effort: 2 h.**

---

<a id="history-a23-a-failed-asset-load-leaves-the-names-from-the-old-montage-beside-the-positions-of-the-new-one"></a>

### A23. A failed asset load leaves the *names* from the old montage beside the *positions* of the new one

`loadCalibrationAssets()` (`service_analysis.cpp:91-139`) returns early on three paths — `readCed`
failure (`:108-110`), `readLeadfield` failure (`:114-117`), `checkPairing` mismatch (`:123-128`) — and
`m_channelNames = cal.labels` / `m_scalp` are assigned only at `:132-137`, **after all of them**. On
the second and third paths `m_calibration = cal` **is** assigned (`:115`, `:126`) with the new
montage's `unitXyz`.

Result: the ChannelTable, `resolveChannels()` (which resolves *CAR excluding* and *Protected* **by
name**, `service_run.cpp:775-798`), the grid labels and the HDF5 `channels/labels` all come from the
previous montage, while the detector and the repair matrix use the new montage's geometry. An error
*is* shown, but the names/positions disagreement is not.
**Fix: assign all-or-nothing. Effort: 1 h.**

---

<a id="history-a24-eegscale-and-emgscale-are-hard-coded-in-defiance-of-the-header-explaining-why-they-must-not-be"></a>

### A24. `eegScale` and `emgScale` are hard-coded, in defiance of the header explaining why they must not be

`service_analysis.cpp:229` fixes `ss.eegScale = 1e6`, and `reconfigure()` never sets
`epoch.emgScale` at all, so it stays at the struct default `1e3` (`epochprocessor.hpp:47`).

`epochprocessor.hpp:43-45` says verbatim: *"Settable because a source that already publishes
microvolts exists (a generator, a converted file) and silently multiplying it by a million produces a
plot nobody can read and no error at all."*

**tepSound exposes neither, so the exact failure the header names is not fixable from the console.**
A playback or generator source in µV gives traces 1e6× too large, with `rejectPeakUv`,
`mepRejectRms` and `mepThreshold` all meaningless.

ⓘ For **these two files it is correct**: the recordings are in volts (verified — quiet 1 s before the
first pulse gives median per-channel σ = 11.5 µV, and the amplifier rail is ±0.44 V), matching
`nvx136driver.cpp:452` (`unit = "V"`). So this is a latent trap, not an active one.
**Fix: expose both as parameters. Effort: 1 h.**

---

<a id="history-a25-one-nan-epoch-poisons-the-mep-average-permanently"></a>

### A25. One NaN epoch poisons the MEP average permanently

`EpochProcessor::extractMep()` returns a **full-length vector of NaN**, not an empty one, when the
EMG indices are out of range (`epochprocessor.cpp:193-194`, verified). `measure()` correctly reports
`valid = false`, but `takeEpoch` still stores the NaN trace verbatim (`service_analysis.cpp:698`).

`SoundStore::reduce()` sums MEP traces with **no finiteness guard at all** — verified at
`soundstore.cpp:348-351` and the SD pass at `:358-362` — so **a single NaN epoch makes `mep` and
`mepSd` NaN for every sample, for the rest of the session, for every later epoch.** The same hole
exists on the EEG side (`:291-297`, the median/trimmed branch at `:303-320`, the GFP loop at
`:325-337`), and `canAnchor()` does not check finiteness either (0.3, gap 1).

**Reachability:** `epoch.channels = geometry.signalChannels` = 72 for these files; `emgChannelB`
default 66 → index 65 < 72. **Not reachable at defaults on this data** — only via operator
mis-entry of an EMG channel above 72. Ranked last in Tier A for that reason, but the consequence is
permanent and total.

**Operator sees** the MEP average and single-trial strip go blank (the painters break the path on
non-finite values) and `0.000` in the MEP column. **Wrongly concludes** the subject stopped
responding / the coil moved.
**Fix: guard the accumulators; return empty rather than NaN-filled. Effort: 1.5 h** (shares with 0.3
gap 1).

---


<a id="history-2-tier-b--blocks-work-or-costs-time-but-the-operator-will-notice"></a>

## 2. TIER B — blocks work or costs time, but the operator will notice

Real defects. None of them produce a confidently wrong answer.

| # | Finding | Where | Effort |
|---|---|---|---|
| **B1** | **The subject stage is entirely dead.** `service.fullscreenParam` and `service.screenParam` are read by `StageWindow.qml:26, 36, 56` and **do not exist** in C++ — verified by grep across all 62 `Q_PROPERTY` declarations: the only occurrences anywhere in the tree are those three QML lines. `.value` on `undefined` throws a TypeError inside `placeOnNamedScreen()`, called from `Component.onCompleted:51` — **one line before `service.attachStage(stage)` at :52.** The exception aborts the handler, `m_stage` stays null forever. ⇒ no cue is ever shown, `triggerDue` is never connected so **the protocol never fires a pulse**, `onCuePresented` never fires so every epoch gets a blank label, and `finishRun('completed')` never fires so a run never ends by itself. *Operator sees:* Start goes green, trial pill frozen at `1 / N`, triggers 0, epochs 0, blank subject screen. *Concludes:* "the amplifier or the TTL box is broken." | `stage/StageWindow.qml:26,36,51-52,56` | 1 h |
| **B2** | **The subject screen never opens.** `m_showStage->setValue(true)` (`service.cpp:1028`) executes **before** the `connect(...)` at `:1029-1032` — verified. `Boolean::setValue` short-circuits on equality, and the constructor calls `setWindow()` for the console only. `m_stageEngine` is never created. The checkbox reads as checked and the window does not exist; the only way to open it is to uncheck and re-check. | `service.cpp:1026-1032` | 15 min |
| **B3** | **The default protocol never loads.** `m_protocolPath->setValue("protocols/tms-cue-block.json")` (`service.cpp:1011`) runs **before** the `connect(...)` at `:1012` — verified, and nothing else calls `loadProtocol()`. So `trialCount == 0`, `haveProtocol == false`, and **Start is disabled** with "no protocol loaded" — while the Protocol field beside it shows a valid path that *does* exist on disk (`protocols/tms-cue-block.json` confirmed present). A `--serviceConfig` carrying the same default path also produces no signal and no load. Recovery: edit the path to something else and back. | `service.cpp:1011-1012` | 15 min |
| **B4** | `fullscreen` and `screen` parameters have **no `connect` of any kind** (verified: `service.cpp:1035-1044` — `m_fullscreen` is `add()`ed with no connect; `m_screenName` likewise). Their only readers are the broken StageWindow lines. Typing a display name does nothing. `screen`'s description also claims "Empty uses the last screen" — `placeOnNamedScreen()` returns immediately when empty, leaving the window wherever Qt put it. The description is false even after B1 is fixed. | `service.cpp:1035-1044` | 30 min |
| **B5** | **`triggerBackend` defaults to Serial/COM3 and `beginSession()` opens the port on *Arm*, not just Start** — verified at `service.cpp:1440-1457` (`m_trigger.open()` inside `beginSession`) and `service.cpp:1062` (`setIndex(1)`). On a replay machine, or any rig without COM3, simply arming raises a red `trigger:` error unrelated to anything the operator did. | `service.cpp:1062`, `:1455` | 30 min (default → `None`, or open lazily) |
| **B6** | **Esc stops the run.** `Console.qml:56` is a window-scope `Shortcut`, dispatched by QShortcutMap **before** key delivery, so it pre-empts `EpochTable.qml:51-54` (documented in that file's own header as "Esc → back to the running average") **and** the Note dialog's close-on-Escape. An operator who selects three epochs and presses Esc to return to the average **stops the run.** | `Console.qml:56` | 30 min |
| **B7** | **`message(text, isError)` has zero consumers.** Verified: `grep -rn "onMessage\|message(" ui/ stage/ import/` returns **nothing**. Eight emitters are all dead: `setError` echo (`service.cpp:1593`), "pulse skipped" (`service_run.cpp:281`), "arm the session before pulsing" (`:307`), "pulse refused" (`:313`), "run completed" (`:366`), "note: …" (`:739`), **"epochs written to `<path>`" (`:765`)**, and "protected electrode over threshold" (`service_analysis.cpp:822`). ⇒ **Pressing Save produces no confirmation and no path anywhere on screen** — `RunBar.qml:158` ignores the returned path (verified). A run held by the stimulator gate shows only a red pill. The protected-electrode alarm — the entire reason that mechanism exists (`badchannels.hpp:35-38`) — goes nowhere. **One QML file's worth of work unblocks eight existing diagnostics.** | `service.hpp:294`, `RunBar.qml:156-159` | 3 h |
| **B8** | **`incomplete` and `artifactSkipped` never leave the worker thread.** `Pipeline::Counters` carries seven fields; `SignalWorker` emits three (`signalworker.cpp:77-82`) and `onWorkerCounters` accepts three (`service.hpp:301`). `incomplete` counts triggers whose window opened before the stream did — added specifically because *"'the first two stimuli are missing' is otherwise unexplainable"* — and `artifactSkipped` is A15. Both are exactly the numbers an operator needs. | `signalworker.cpp:77-82` | 2 h |
| **B9** | **`Save` has no tooltip** — the only button in the bar without one — and no feedback (B7). Indistinguishable from doing nothing. | `RunBar.qml:155-159` | 15 min (with B7) |
| **B10** | **Clicking any epoch-table row older than `epochBuffer` does nothing, silently.** `logLimit = 500` (`service.cpp:35`) but the store's default capacity is 200. Rows 201–500 render, look live, and are dead: `selectEpoch()` returns immediately when `m_store.at(serial) == nullptr` (`service_run.cpp:661-662`), `rejectEpoch()` returns false with no UI change. No greying, no message. | `service.cpp:35` vs `:1210` | 1 h |
| **B11** | **The `epochs` pill freezes at the buffer capacity.** It reads `m_store.count()`, bounded by `epochBuffer` (200). In a 300-trial session it reads "200" from trial 200 onward and never moves. `SoundStore::totalCollected()` exists (`soundstore.hpp:125`) and is exposed nowhere. ⓘ Not reachable in the replay (150/107 trials) but very reachable in a real session. | `RunBar.qml:69-72` | 30 min |
| **B12** | **The scalp grid cries "no montage" at the start of every session.** `layout()` sizes from `min(scalpPositions().size(), displayed().eegChannels)`; before the first epoch `displayed()` is default-constructed with `eegChannels == 0`, so `paint()` prints *"no montage — set a .ced file in Input"* (`views.cpp:256-258`) with a perfectly good 64-row .ced loaded. **The largest panel on screen tells the operator the montage failed, every single session.** They will hunt a problem that does not exist. | `views.cpp:205`, `:256-258` | 45 min |
| **B13** | **`P` fires a real TMS pulse from anywhere, ungated by run state** — unlike the Pulse button, which is enabled only in `armed`/`paused`. Verified `Console.qml:60`. Also `Space` calls `startRun()` bypassing the Start button's enable predicate. And the subject's own keyboard can stop the run and fire a pulse (`StageWindow.qml:174-177` → `keyPressed()`), once B1 is fixed. | `Console.qml:60`, `:52-55` | 1 h |
| **B14** | **A failed calibration retries on every epoch forever, and the error latches.** `onCalibrated()` returns early on `!result.valid` without calling `m_sound.apply()`, and `apply()` is the only thing that resets `m_sinceCalibration`. So `wantsCalibration()` stays true and `maybeCalibrate()` fires again on the very next epoch — forever. `setError` only re-emits when the *text* changes, so the operator sees one line once and never learns it is repeating. Meanwhile the previous model keeps cleaning and `modelSummary()` keeps reporting its id **with no staleness marker** — `sinceCalibration()` exists (`soundpipeline.hpp:210`) and is **read by nothing in the tree**. | `service_analysis.cpp:773-777` | 2 h |
| **B15** | **Changing `EEG channels` without retyping the montage path wedges the pipeline.** `loadCalibrationAssets()` passes `m_eegChannels->value()` as `readCed`'s row limit but is called only from the constructor and the `montage`/`leadfield` handlers; `eegChannels` triggers only `rebuild()`. Setting it to 32 leaves a 64-label calibration, `configure()` fails, `m_ready` stays false, and **every epoch becomes a phantom (A9)** — until the operator realises they must retype the montage path. The failure gives no hint of either route. | `service.cpp:258` vs `:341-344` | 45 min |
| **B16** | **`Reset` restarts epoch serial numbering at 1** while the `events` stream has already published `n: 1..N` for the previous set, with the same schema version and no session token. A recorder following `events` cannot tell trial 1 of session B from trial 1 of session A. | `soundstore.cpp:65-70` | 1 h |
| **B17** | **The `window` error can never be cleared.** `setError("window", ...)` at `service.cpp:1521`; there is **no** matching `clearError("window")` anywhere. `lastError()` joins every live key with `"  ·  "` into one elided line, so once that entry exists it consumes the visible width and every **later** error is elided off the right edge. Every other error key has a matching clear. | `service.cpp:1521` | 30 min |
| **B18** | **`lastError` never expires** — no dismiss control, no timestamp, no clear-on-state-change. A protocol parse error from before the session is still burning red an hour later, with newer errors appended after it and elided away. | `service.cpp:1581-1584` | 1 h (with B17) |
| **B19** | **The average-withholding and anchor reports are `qWarning()`-only.** `publishAverage()` builds a careful grace-then-slow-repeat report explaining that the average is suppressed because its length contradicts the announced window (`service_analysis.cpp:1000-1014`), and `reportAverageAnchor()` (`:1123-1170`) distinguishes the fallback case from total failure. Both go to a log nobody has open — and this is a **windowed** executable, so they need `QT_FORCE_STDERR_LOGGING` to exist at all. `averageWithheld` and `anchorRejected` reach the status stream and **no QML reads either.** *Operator sees:* the plot simply stops updating, with no reason. | `service_analysis.cpp:1000-1024`, `:1123-1170` | 2 h (with B7) |
| **B20** | **`refused` and `starved` are merged into one red "lost" pill** with no tooltip. `refused` is the refractory doing its job on a bouncing TTL — normal; `starved` is an epoch genuinely never analysed. Opposite diagnoses, opposite remedies, one number. (Both should be 0 on these files: min ITI 1537 ms vs a 500 ms refractory.) | `RunBar.qml:82-89` | 30 min |
| **B21** | **The rejected count is shown nowhere.** `m_store.count() - m_store.accepted()` is computed for the status stream and never surfaced. The gap between the two run-bar pills conflates rejections, warm-up epochs and geometry mismatches — three faults, one invisible subtraction. **And nothing shows *why* an epoch was rejected**: `StoredEpoch::rejectedByEmg` distinguishes the pre-innervation gate from an operator right-click, and `appendLog()` does not carry it into the row. ⇒ right-clicking an auto-rejected row **un-rejects it, putting a contaminated trial back into the average *and* the SOUND training set**, with no warning. | `service_analysis.cpp:1102`, `:1174-1187` | 2 h |
| **B22** | **`peak` (µV) is in the log row and has no column.** `rejectPeakUv`'s own tooltip promises *"Every epoch's peak is reported whether or not a threshold is set, so one can be chosen from a pilot session rather than guessed"* — the promise is unkept. Also missing from the table though present in the model: `model` (which operator cleaned it), `cleaned` (i.e. warm-up), `latency`. | `EpochTable.qml:71-76` | 1.5 h |
| **B23** | **Thirteen `Q_PROPERTY`s have zero QML consumers** (grep-verified): `processingLoad`, `droppedFrames`, `refreshRate`, `remainingMs`, `blockName`, `currentCue`, `sequenceStrip`, `protocolWarnings`, `protocolError`, `trainingCount`, `coilTemperature`, `stimulatorIntensity`, `revision`. During a run the operator gets `trial i / N` and nothing else. The expensive omissions for a real experiment: `droppedFrames`, `remainingMs`, `blockName`, `processingLoad`. | grep | 2 h for the useful four |
| **B24** | **Right-click reject is completely undiscoverable** — no context menu, no cursor change, no hint. Its only documentation is a comment table in `EpochTable.qml:14-22`. | `EpochTable.qml:169-172` | 30 min |
| **B25** | **`Seed → New` silently re-orders the whole remaining trial plan** with no confirmation, destroying the reproducibility its own description promises. The session header already published names a seed no longer in effect. | `SettingsPane.qml:270-273` | 30 min |
| **B26** | **`Keep epochs` lowered mid-session silently destroys epochs.** `setCapacity()` trims immediately; typing 20 instead of 200 destroys 180 epochs, and the table (capped at 500) keeps showing rows for the evicted ones. | `SettingsPane.qml:349-352` | 45 min |
| **B27** | **The one warning that matters at run time cannot appear at run time.** `warnings()`' last check — pulses closer together than the epoch tail, "the display will lag the subject" — is gated on `m_presenting && !m_plan.isEmpty()`, but `warnings` is `NOTIFY geometryChanged` and starting a run emits `runStateChanged`/`planChanged`/`progressChanged`, never `geometryChanged`. The warning appears only if some unrelated geometry change happens to fire afterwards. | `service_run.cpp:890-902`, `service.hpp:85` | 45 min |
| **B28** | **`averageWindow` is fully editable while `averageAll` is on, when it does nothing.** The operator can set it to 40, watch nothing change, and conclude the average is broken. | `SettingsPane.qml:344-348` | 15 min |
| **B29** | **`modelSummary()` lies when SOUND is deliberately off** — it returns "calibrating — 0 of 10 epochs" whenever `model.valid` is false, with no test of `soundEnable`. Displayed permanently in the SOUND panel header and the CAP panel note. Nothing is calibrating and nothing ever will. Relatedly, **the entire CHANNELS panel is inert when SOUND is off** (`maybeCalibrate()` returns at its first line) while every control stays enabled. | `service_run.cpp:532-539` | 45 min |
| **B30** | **Stale readouts that survive a Reset or a Stop:** the latency strip keeps saying "epoch ready 700 + 23.4 ms after the pulse" forever (`m_lastLatencyMs` never cleared); "last calibration N ms" survives Reset; "Pulses skipped" is cleared on entry to `running` but **not** to `armed`, so skipped pulses from the previous run read as new ones. | `service_analysis.cpp:738`; `service.cpp:1394` | 1 h |

---


<a id="history-3-tier-c--would-annoy-do-not-spend-experiment-budget-on-these"></a>

## 3. TIER C — would annoy. Do not spend experiment budget on these.

Listed for completeness so a later session does not rediscover them, **explicitly deprioritised.**

**Semantics and labelling**
- **`lastN` semantics: tepSound windows by POSITION.** `SoundStore::average()` (`soundstore.cpp:175-191`)
  takes `from = m_averageAll ? 0 : max(0, n - m_averageWindow)` over `m_epochs.size()` **including
  rejected**, then filters rejections *inside* the slice. With `Average over = 100` and 30 %
  rejection the average is over ~70 epochs. **tepService means "the last N ACCEPTED", and the viewer
  deliberately followed tepService — tepSound is the odd one out.** The UI says nothing: `averageWindow`
  and `averageAll` both have **no `setDescription` at all**, and the pane renders the empty string.
  ⓘ **Mitigated in practice:** both places that show the count show the *true* one (`Console.qml:220`
  → `acceptedCount`, and `views.cpp:329-333` → `data.contributing`). The operator can see n < 100;
  they just cannot tell whether that is by design. ⓘ Note `recentMeps()` in the *same class*
  genuinely means "the last N accepted" (`soundstore.cpp:370-385`) — two windows, one class, opposite
  meanings. **Decide and document; do not silently change semantics before an experiment.** (2 h)
- `maxBadFrac` displays as "0.25 of the cap" while `describePipeline()` renders the same number as
  "25 %". (`SettingsPane.qml:245-249`)
- MEP µV/mV: the ScaleBox suffix says "µV" while the plot axis says "mV" for one number.
  (`Console.qml:282-292` vs `views.cpp:391`)
- `service.cpp:213-216` says "64 EEG + 2 EMG + trigger" (67) while the real rig delivers **73**.
- `soundstore.hpp:19-21` documents the raw epoch as "66 channels × 5501 samples"; the data is 73
  columns / 72 signal channels and 5500 samples at defaults. `SoundGeometry::channels = 66` and
  `EpochSettings::channels = 66` are sized for a rig that no longer matches.

**D1 audit — operator tooltips are design rationale. Systematic, and genuinely low priority.**
Parameter `description`s render verbatim as 320 px hover tooltips. Representative offenders:
`rejectPeakUv` (`service.cpp:628-632`, a reference-data anecdote), `blankFrom` (`:434-436`,
implementation rationale), `tmsInterpFrom` (`:472-474`, matrix commutation), `preHighpass`
(`:501-507`), `leadfield` (`:352-355`), `windowEnd` (`:379-382`, advocacy for a default),
`excludeRepaired` (`:775-777`), `detectorEpochs` (`:895-900`, benchmarks in a tooltip),
`triggerBackend` (`:1054-1056`, project history), `keepGuarded` (`:1221-1223`), `autoSave`
(`:1255-1256`, pure rationale), `useKurtosis` (`:802-806`, editorial), `soundTrainOn` (`:707-710`),
`averageSource` (`:1152-1158`, *"This is the scientific product and the honest one"* — a value
judgement), `epochBuffer` (`:1204-1207`, memory arithmetic).
`service.cpp:1292-1293` (the `reset` action) is the counter-example of the right register.

**⭐ The operationally important half of D1 is not the verbosity — it is the 26 parameters with NO
description at all**, which render as an empty tooltip. In `service.cpp` line order: `emgChannelB`
271, **`triggerEdge` 306** (the single most consequential setting in the module — see A2), `blankTo`
445, `preHighpassHz` 512, `preNotchHz` 528, `preNotchWidth` 537, `preLowpassHz` 555, **`baselineFrom`
601** (see A8), `rejectFrom` 640, `rejectTo` 649, `mepTo` 936, `mepTrendWindow` 953, `mepStripCount`
993, `showStage` 1026, `fullscreen` 1035, `averageAll` 1177, **`averageWindow` 1183**, `trimFraction`
1192, `subject` 1228, `condition` 1232, `operator` 1236, `publishAverage` 1274, `showUi` 1279, `save`
1298, `note` 1305, `reloadProtocol` 1314.
⇒ **Write descriptions for `triggerEdge`, `baselineFrom`, `averageWindow`, `blankTo`, `rejectFrom`,
`rejectTo` (6 of 26). Leave the other 20 and leave the verbose ones alone.** (1.5 h)

**Tooltip mechanics** — `TepToolTip.qml:19-20` declares `delay: 550` / `timeout: 12000`, but
`TepField.qml:47` binds `visible:` directly, **bypassing both**. Tooltips appear instantly and never
time out, so dragging down the pane flashes a 320 px panel at every row. And `TepField.qml:14-16`
asserts its tooltip "is the only part of the row that is never itself interactive" — but it is
positioned at `x: caption.width; y: caption.height` with `fixedWidth: 320`, i.e. it starts exactly
where the control begins and is wider than the whole 330 px pane. **It covers the control it
describes.** The claim in the file is false. (1 h — worth doing, it is cheap and it affects every
hover.)

**D2 audit — no true violation exists today.** There is no continuous field anywhere in tepSound: no
topoplot, no heatmap, no interpolated surface. Every plot is line ink on a flat background. **The
rule has nothing yet to be violated against — which is exactly what Feature 1 changes.** Three
near-misses to fix *before* the topoplot lands:
- `views.cpp:744`: `markColor = strong ? m_strong : m_ink` — the MEP peak/trough triangles take
  their colour from the trial's classification, and the trace they mark takes the **same** colour
  from the same test (`:735`). For exactly the trials that matter (above threshold), the markers are
  the same green as the curve and effectively invisible. **This is the failure mode D2 exists to
  prevent, arrived at from the other direction.** (30 min)
- `views.cpp:275` and `views.cpp:500` hard-code the highlight pen as `QColor(0xf0,0xc0,0x60)` rather
  than a Theme token — the one ink in the plots QML cannot reach. Where a future topoplot's electrode
  marks would naturally inherit the wrong rule. **When Feature 1 lands, its electrode marks must be
  black regardless of Theme.** (30 min, fold into Feature 1)
- `ChannelTable.qml:133-139`: the threshold tick at `Theme.ink` opacity 0.5 over a `Theme.bad`
  (#D2635A) bar is barely readable.
✔ `StageWindow.qml:188-189` derives text colour from background by the 0.2126/0.7152/0.0722 luma
rule — **that is the sanctioned case and it is correct as written.**

**`readCed` — same §23 defect as `parseCED`, plus four silent skips.**
`calibration.cpp:94-96` reads the `.ced`'s **rounded** `theta`/`radius` columns; EEGLAB's `readlocs`
does not read `radius` at all, it recomputes `radius = 0.5 - sph_phi/180`. `sph_phi` appears nowhere
in `calibration.cpp` although the shipped montage carries it. Measured on
`montages/mks64_standard.ced` (tab-separated, CRLF, header `Number labels theta radius X Y Z
sph_theta sph_phi sph_radius`): T7 file 0.53318 vs computed 0.5331833 (Δ 3.3e-6); TP9 0.66492 vs
0.6649166 (Δ 3.3e-6). ~3–5e-6, smaller than §23's 4e-5 because this file carries more decimals.
⚠ **This matters much more for the requested topoplot than it does today**, because
`TopoPlot::topoLayout` derives `plotrad = max(rmax, min(1.0, max(radius)*1.02))` from these radii and
the biharmonic kernel `r²(ln r − 1)` is **not scale-invariant** — a rounded `max(radius)` shifts
`squeezefac` and therefore the **shape** of the field, not just its size.
⇒ **Recompute from `sph_phi` before Feature 1 lands. Three lines. Folded into Feature 1's cost.**
Four other silent behaviours worth the same pass: rows with too few tab fields are skipped without
comment (`:79-80`); an electrode at the origin is skipped without comment (`:85-86`) — either yields
a montage with fewer channels than expected, surfacing only as configure()'s count mismatch;
`parts[cLabel]` is indexed at `:87` with no bounds check of its own; and `limit` is
`m_eegChannels->value()`, so a 66-row `.ced` silently truncates to the first 64 rows **positionally
rather than by kind**.

**Performance / hygiene, none of it operator-visible**
- **U7:** under the default `cumulative` schedule the training deque is never trimmed (`process()`
  trims only when `scheduleMode == "sliding"`, `soundpipeline.cpp:299-305`). 180 KB per accepted
  epoch → 700 trials ≈ 125 MB, and `snapshot()` **copies the whole thing** every `trainDn` epochs.
  Worse: `process()` pushes to `m_train` **regardless of `m_soundEnable`**, because the SOUND-off
  branch still calls `process()` — so the buffer grows all session with nothing that will ever consume
  it, and that branch also computes and discards a full 64×64 × 64×701 product per epoch for nothing.
  ⓘ At 150/107 trials this is ~27 MB. Irrelevant for the replay; relevant for a long session.
- **U6:** `BadChannelDetector::m_looCache` grows without bound and is searched linearly
  (`badchannels.cpp:205-220`); cleared only by `configure()`.
- **U9:** the trainer's detector is configured through a queued call whose payload may be empty; if
  `m_calibration` is stale at that instant, `m_nCh = 0`, `isReady()` is false, and **no electrode is
  ever repaired for the rest of the session** with only the generic "No usable montage and lead
  field" warning to hint at it — and that warning disappears once the assets load.
- **S18:** `soundIterate()` does `w[k] = 1.0 / sigmas[j[k]]` (`sound.cpp:112-113`) and
  `soundOperator()` `w[i] = 1.0 / sigmasCh[i]` (`:197`) with no guard, while `ddwiener()`
  deliberately writes NaN into a sigma when `solveSpd` fails and a channel that is an exact linear
  combination of its neighbours gives residual exactly 0. The infinity **is** caught downstream by
  `isFinite()` at `:429`, so it is not silently wrong — it becomes B14's calibration storm.
- **S23:** the MEP channel on the published streams is truncated to the EEG's sample count
  (`service_analysis.cpp:849-863`) — 701 × 5 = −400…+300 ms, correctly declared by `mepWindowToMs`,
  but set `MEP to` above 300 and the console's number and the stream's trace describe different
  intervals.
- **Dead code:** `m_ica` is `///< reserved; identity until an offline ICA filter is supplied`, set to
  identity and never anything else — the `P_ica` term in the documented `M · P_ica · R · C` chain is
  dead weight costing one 64×64 multiply per calibration and per `rebuildSpatial()`.
  `truncateToSamples()` in `soundpipeline.cpp:11-13` is **never called**, while `configure()` uses
  `std::llround` for the same quantities `Pipeline::configure()` computes with `truncateToSamples`
  — two rounding conventions on one time base, one dead. `StatusPill.qml` is compiled into res.qrc,
  installed, exported in qmldir, and instantiated by nothing. `ParamControl`'s `kind: "action"`
  editor is never used by this console.
- **`statuschannels.hpp:42-45` self-admits** that the channel list and the value list in
  `publishStatus()` are positional with nothing to catch a mismatch, and that a short list is padded
  with zeros so *"a forgotten value is a channel that reads a plausible 0 for ever."* Currently
  correct (36 values against `kStatusChannelCount = 36`) — but `refused`, `incomplete` and
  `artifactSkipped` are absent from the list entirely. **Add a `static_assert`.** (30 min)
- **Three residual republish triggers** (0.4): `reconfigure()` falls back to `channels = 67,
  rate = 25000` when nothing is connected, so `describePipeline()` reports a phantom input — but
  `outChannels` stays 65 so the streams survive on these files; `matches()` uses `qFuzzyCompare` on
  the rate, which is relative and false for any pair involving 0 (safe today only because
  `outputSamples <= 0` substitutes `outRate = 1.0`); and `loadCalibrationAssets()` runs
  **synchronously** on the montage/leadfield handlers before the 50 ms coalescing timer, so a config
  load that writes both paths does two full `.ced` + HDF5 reads on the GUI thread.

---


<a id="history-4-ui-test-plan"></a>

## 4. UI TEST PLAN

**Executable by an agent driving the running service.** Every case states preconditions, the exact
action, the observable expectation, and *how* to observe it — because most of this service's
diagnostics never reach the screen (B7, B19).

<a id="history-40-harness-setup--mandatory-or-half-the-tests-observe-nothing"></a>

### 4.0 Harness setup — mandatory, or half the tests observe nothing

```bat
cd /d R:\dist\msvc64
call env.bat
cd bin
set QT_FORCE_STDERR_LOGGING=1
set QT_LOGGING_RULES=*.debug=true;qt.*.debug=false
```

Three observation channels, all needed:
1. **The screen** — via screenshot / the running window.
2. **stderr** — `qWarning()` output. **This is a WIN32 windowed executable**; without
   `QT_FORCE_STDERR_LOGGING=1` these lines do not exist. B19's entire diagnostic surface lives here.
3. **The status stream** — 36 channels (`statuschannels.hpp`). Subscribe with a recorder or a small
   consumer. `accepted`, `averageWithheld`, `anchorRejected` are only visible here.

⚠ **Set `triggerBackend = None` before arming** or every test is preceded by a spurious `trigger:`
COM3 error (B5).

<a id="history-41-priority-tests--run-these-first-they-gate-everything-else"></a>

### 4.1 Priority tests — run these first, they gate everything else

| ID | Action | Expected | How to tell | Fails ⇒ |
|---|---|---|---|---|
| **T-K1** ⭐ | Focus `Window to`, select all, type `250`, press **Tab**. Then read the value back from the Configurator (or `describePipeline()` in the PIPELINE panel, which is computed from the live parameter). | The pipeline description says the window ends at 250 ms. | PIPELINE panel text, **not** the spin box. | **A6 confirmed as "typing does not apply".** Escalate A6 to #1 overall. |
| **T-K2** | With T-K1 done, change `Window to` from the Configurator to `400`. | The console spin box shows **400**. | Screenshot. | A6 binding destruction confirmed. Expect this to FAIL. |
| **T-K3** | Same as T-K1/K2 for a double: `Baseline from`, type `-80`, Tab; then change it externally. | Value applies; box tracks. | PIPELINE panel + screenshot. | A7 confirmed (expect: applies, does not track). |
| **T-K4** ⭐ | Press **Start** with the service freshly launched. | Either the run proceeds, or Start is disabled with a stated reason. | Trial pill, triggers pill. | B3 confirmed: Start is disabled while a valid protocol path is displayed. |
| **T-K5** ⭐ | Fix nothing; check the subject window exists at launch with `Show subject screen` checked. | A stage window exists. | Window list. | B2 confirmed: checkbox checked, no window. |
| **T-K6** ⭐ | Uncheck then re-check `Show subject screen` → window appears → press Start with a protocol loaded. | Cues present, pulses fire, trial advances. | Trial pill advances; `triggerDue` fires. | B1 confirmed: TypeError in `placeOnNamedScreen`, `attachStage` never runs, run frozen at `1 / N`. Check stderr for the QML TypeError. |

<a id="history-42-run-bar--a1a17"></a>

### 4.2 Run bar — A1…A17

| ID | Control | Preconditions | Action | Must happen | Observe |
|---|---|---|---|---|---|
| RB-01 | Status dot A1 | — | Cycle idle → armed → running → paused → idle | Colour changes idle/tep/good/warn | Screenshot. ⚠ armed(blue) vs running(green) is **hue-only**, no label — note as a finding if indistinguishable at a glance |
| RB-02 | Input summary A3 | No stream | Observe | Red, `Theme.bad` | Screenshot |
| RB-03 | Input summary A3 | Playback connected | Observe | `Playback · 73 ch · 25000 Hz`, normal colour | Screenshot — ⚠ confirms the `· ` middot renders, closing the mojibake question visually |
| RB-04 | epochs pill A4 | Replay running | Watch to trial 210 (needs >200 trials; **not reachable on these files** — use a synthetic or set `epochBuffer = 20`) | Freezes at capacity | **B11.** With `epochBuffer=20`, pill must freeze at 20 while triggers climbs |
| RB-05 | in average A5 | Select 3 epochs | Observe | Shows the *running average's* n, not 3 | **A11** — cross-check against the grid caption which correctly says `n = 3` |
| RB-06 | triggers A6 | Replay file A complete | Observe | **exactly 150** | Pill |
| RB-07 | lost A7 | Replay complete | Observe | **0** | Pill. Any non-zero on these files is a real defect (min ITI 1537 ms ≫ 500 ms refractory) |
| RB-08 | model A8 | Before 10 epochs / after | Observe | `—` then `0`, incrementing every 10 | Pill |
| RB-09 | trial A9 | No protocol | Observe | `—` | Pill |
| RB-10 | stimulator A10 | `Require ready` ON, no neuroMS | Observe | ⚠ reads `not watched` in grey | **A16** — must read as *blocked*, not as *unwatched* |
| RB-11 | **Arm** | Input connected, idle | Click | State→armed; worker active; `session/started` on `events`; trigger port opened | State dot + `events` stream |
| RB-12 | **Arm** | No input | Observe | Disabled, tooltip = blockReason | Hover |
| RB-13 | **Pulse** | armed | Click | One pulse fired; `pulse/fired` event | `events` stream. ⚠ With `triggerBackend=None` nothing physical fires — verify the event only |
| RB-14 | **Pulse** | idle | Observe | Disabled | Screenshot |
| RB-15 | **Pulse** | armed, gate blocking | Click | Refusal **visible** | **B7** — expect nothing at all except the `Pulses skipped` counter buried in the tms tab; the `!m_engaged` path does not even increment that |
| RB-16 | **Start/Pause/Resume** | Protocol loaded | Click through | Text switches; state follows | Screenshot |
| RB-17 | **Stop** | running, autoSave ON | Click | Epoch file written; `session/stopped` | **File on disk.** ⚠ Nothing on screen says so (B7) |
| RB-18 | **Stop→Arm** ⭐ | 20 epochs collected, Stop, Arm | Observe `in average` | ⚠ Should be 0; **will be 20** | **A4** — the headline recoverability defect |
| RB-19 | **Reset** ⭐ | running, 20 epochs | Click | ⚠ No confirmation; everything gone; **no file written** | **A5** — verify no file appears in the epoch dir |
| RB-20 | **Reset** | — | Observe `enabled` | ⚠ Enabled in every state | **A5** |
| RB-21 | **Save** | epochCount > 0 | Click | A file appears; the path is shown | **B7/B9** — file appears, nothing on screen. Check the dir |
| RB-22 | **Save** | epochCount == 0 | Observe | Disabled | Screenshot |
| RB-23 | **Save** ×2 | Click twice | Two files, `$$$` counter advanced | Directory listing |
| RB-24 | **Save** | Remove `$$$` from `Epoch file`, click twice | ⚠ Second silently overwrites the first | Timestamps |
| RB-25 | **Note…** | any | Click, type, OK | `note` event published | `events` stream |

<a id="history-43-keyboard--b6-b13"></a>

### 4.3 Keyboard — B6, B13

| ID | Key | Context | Must happen | Fails ⇒ |
|---|---|---|---|---|
| KB-01 | Space | running | Pause | — |
| KB-02 | Space | focused CheckBox | ⚠ Toggles the checkbox, not the run | Window `Shortcut` steals it → finding |
| KB-03 | Space | focused TextField | Types a space | QQuickTextInput accepts ShortcutOverride — should pass |
| KB-04 | **Esc** ⭐ | 3 epochs selected, list focused | Should clear the selection | **B6** — will **stop the run** |
| KB-05 | **Esc** | Note dialog open | Should cancel the dialog | **B6** — will stop the run |
| KB-06 | N | any | Note dialog opens | — |
| KB-07 | A | any | `showAverage` toggles | — |
| KB-08 | Ctrl+A | any | Select all | — |
| KB-09 | **P** ⭐ | **idle** | Should refuse **visibly** | **B13** — fires the pulse path with no run-state gate; message is dead (B7) |

<a id="history-44-plot-panels--d-e-f-g"></a>

### 4.4 Plot panels — D, E, F, G

| ID | Action | Must happen | Fails ⇒ |
|---|---|---|---|
| PL-01 | Launch, before first epoch, look at the scalp grid | Shows "waiting" or empty | **B12** — shows *"no montage — set a .ced file in Input"* with a valid montage |
| PL-02 | Hover an electrode | Frame note shows its name | — |
| PL-03 | Click an electrode, move the pointer off the grid | The highlighted channel is identifiable | ⚠ Note is bound to `scalp.highlight` not `butterfly.highlight` → no readout; no way to clear except clicking empty space |
| PL-04 | `average`/`selected` button | Toggles; with empty selection auto-selects `lastSerial()` | — |
| PL-05 | µV ScaleBox (in the **scalp** panel) | ⚠ Also changes the **butterfly** | Cross-wiring — confirm and document |
| PL-06 | ms ScaleBoxes (in the **butterfly** panel) | ⚠ Also change the **scalp grid** | Cross-wiring |
| PL-07 | Set xMin > xMax | Should refuse | Nothing enforces min < max |
| PL-08 | `labels on/off` | Labels toggle | — |
| PL-09 | Type an amplitude, then switch `TepTraceView` away from Butterfly | ⚠ `setKind` silently rewrites amplitude to 0.5 if > 5 (`views.cpp:347-348`); the ScaleBox will not learn | Confirm — blocks Feature 3 |
| PL-10 | Drive a channel above the current amplitude | Over-range must be **distinguishable** from flat | ⚠ Hard-clamped to the panel edge (`views.cpp:302-303, 524, 565, 686`) — a saturated trace looks exactly like a flat one |
| PL-11 | MEP strip vs epoch table, same trial | The two amplitudes agree | **A18** |
| PL-12 | A trial with `mepValid == false` | Table shows `—` | **A12** — shows `0.000` |
| PL-13 | MEP panel µV box | Suffix matches the axis unit | ⚠ "µV" vs axis "mV" |

<a id="history-45-epoch-table--i"></a>

### 4.5 Epoch table — I

| ID | Action | Must happen | Fails ⇒ |
|---|---|---|---|
| ET-01 | Left-click a row | That epoch alone selected; `showAverage` false | — |
| ET-02 | Ctrl-click | Toggles | — |
| ET-03 | Shift-click | Range from anchor | — |
| ET-04 | Right-click | Toggles rejected; average updates | Undiscoverable (B24) but works |
| ET-05 | Right-click an **auto-rejected** row | Should warn before re-admitting | **B21** — silently returns a contaminated trial to the average *and* the SOUND training set |
| ET-06 | Click a row with serial ≤ `count − epochBuffer` | Should be greyed or say why | **B10** — renders live, does nothing |
| ET-07 | Arrow keys with the list focused | Move the selection | ⚠ No `highlight` delegate, nothing binds `currentIndex` — moves an invisible current item, changes nothing |
| ET-08 | Select 3 non-adjacent, note the anchor bar | Marks the epoch clicked first | ⚠ Marks `m_selection.first()` after `std::sort` — the **lowest serial** |
| ET-09 | Look for `peak`, `model`, `cleaned` columns | Present | **B22** — in the model, no column |

<a id="history-46-settings-pane--k1k57"></a>

### 4.6 Settings pane — K1…K57

Run **T-K1/K2/K3 first**; if A6 is confirmed, every integer row below is untestable by typing and
must be driven from the Configurator instead.

| ID | Rows | Action | Must happen |
|---|---|---|---|
| SP-01 | K1–K5 session | Set Subject/Condition; Save | Window title updates; filename expands `$subject`/`$condition`/`$$$` |
| SP-02 | K6–K9 epoch | Change each | Panel hint updates: `<N> samples · <R> Hz · ready <T> ms after the pulse`; PIPELINE panel updates |
| SP-03 ⭐ | K6/K7 **mid-session** | With 20 epochs and a valid model, change `Window to` | **Must clear the training buffer and the model.** ⚠ **A3** — watch for a new `model N` with a plausible summary, or all-zero traces. Also watch stderr for a crash |
| SP-04 | K10/K11 blank | Set `blankTo = 1.3` | PIPELINE reflects it; **A1** |
| SP-05 | K12 TMS interp | Two boxes, one label | ⚠ No indication which is which |
| SP-06 ⭐ | K15/K16 baseline | Set from `-10`, to `-60` | **Must warn or refuse.** ⚠ **A8** — silently no baseline, NaN RMS, dead MEP rejection, empty onset column |
| SP-07 | K18 reject | Set 400 | ⚠ The window it applies over (`rejectFrom`/`rejectTo`) is **not in this pane at all** |
| SP-08 | K19 SOUND off | Uncheck | ⚠ CHANNELS panel stays fully enabled and is inert (B29); `modelSummary` still says "calibrating" |
| SP-09 | K27–K35 channels | With SOUND on, file B | FT9 detected and repaired; CAP table populates |
| SP-10 | K34 `Repair at most` | Observe | ⚠ "0.25 of the cap" vs "25 %" in PIPELINE |
| SP-11 | K36 protocol | Type a bad path | `protocolError` set | ⚠ Displayed nowhere (B23); pane just says "no protocol" |
| SP-12 | K37 Seed **New** | Click mid-session | ⚠ No confirmation; plan re-ordered (B25) |
| SP-13 | K38/K39 stage | Toggle fullscreen, type a screen name | ⚠ Both inert (B4) |
| SP-14 | K44 Require ready | Tick with no neuroMS | ⚠ **A16** — no gate at all |
| SP-15 | K46 Pulses skipped | Arm after a run with skips | ⚠ Not cleared on entry to `armed` (B30) |
| SP-16 ⭐ | K47 `Average of` | Change it | Streams re-announced. **Confirm consumers reconnect** — `TcpStreamSender` is on port 0, the port moves. Nothing in the UI says so |
| SP-17 | K48/K49 | Choose "trimmed mean" | ⚠ `trimFraction` is Configurator-only |
| SP-18 | K49 `averageWindow` | Set 40 with `Average all` ON | ⚠ Editable, does nothing (B28) |
| SP-19 | K50 Keep epochs | With 100 epochs, set 20 | ⚠ Silently destroys 80; table still shows dead rows (B26) |
| SP-20 | K52–K57 MEP | Change threshold, strip count | Strip updates live |
| SP-21 | PIPELINE panel | Read the whole chain | ✔ The single best "is this configured right" surface — verify it matches every setting above |

<a id="history-47-tooltips-and-shared-bricks"></a>

### 4.7 Tooltips and shared bricks

| ID | Action | Must happen | Fails ⇒ |
|---|---|---|---|
| TT-01 | Hover `Montage` and `Protected` labels | ⚠ renders as `⚠` not `Р’В°` | Closes the mojibake question **visually**. Also checks Consolas glyph coverage |
| TT-02 | Hover `Trigger edge` | Explains Rising vs Falling | **A2/C** — empty tooltip |
| TT-03 | Hover `Baseline from` | Explains | **A8/C** — empty |
| TT-04 | Hover `Average over` | Says whether N counts accepted or positions | **C** — empty |
| TT-05 | Hover any row, wait 15 s | Tooltip times out | ⚠ `visible:` bound directly, bypassing `delay`/`timeout` |
| TT-06 | Hover a row and look at what the tooltip covers | Does not cover its own control | ⚠ Covers it; `TepField.qml:14-16` claims otherwise |
| TT-07 | ScaleBox: type-and-Tab, and mouse wheel | Both commit and clamp | — |

<a id="history-48-error-surface"></a>

### 4.8 Error surface

| ID | Action | Must happen | Fails ⇒ |
|---|---|---|---|
| ER-01 | Point `montage` at a missing file | Error visible; **clears** when fixed | — |
| ER-02 | Trigger the `window` error (bad QML load) | Error **clears** when resolved | **B17** — no `clearError("window")` exists; it latches for the process lifetime |
| ER-03 | Raise two errors | Both readable | **B18** — joined into one elided line; the newer is off the right edge |
| ER-04 | Provoke an average withhold (change `Average of` mid-flight) | A reason appears on screen | **B19** — `qWarning()` only; the plot just stops updating |
| ER-05 | Provoke an anchor fallback | Reported | **B19** — `qWarning()` + status channel, no QML reads it |

---


<a id="history-5-replay-test-plan"></a>

## 5. REPLAY TEST PLAN

<a id="history-51-the-two-recordings--measured-facts"></a>

### 5.1 The two recordings — measured facts

| | File A | File B |
|---|---|---|
| Path | `N:\…\06_Timofey_EP_TEP_MEP\11_TMS_48MSO_heel_+60.hdf5` | `N:\…\05_Anatoly_EP_TEP_MEP\12_TMS_metatarsus_+60_2.hdf5` |
| Size | 3,986,448,048 B | 2,920,613,720 B |
| `eeg` | Float64, **73 ch @ 25 000 Hz**, 3480 blocks, **6 805 960 samples = 272.238 s** | 2548 blocks, **4 983 360 samples = 199.334 s** |
| `stimuli` | 150 records | 107 records |
| `feetStim` | 150 records | 107 records |
| Conditions | 3 × 50 (`1!`/`3!`/`10!_Sf100_Gp50`) | 35/36/36 (`9!`/`7!`/`10!`) |
| Quiet σ (median) | 14.2 µV | 33.6 µV |
| ⚠ Bad electrode | none | **FT9 (index 4): σ = 1076.6 µV = 32× median, anticorrelated (−0.357) with its 3 nearest neighbours** |
| Dead AUX | **ch 68 and ch 70 are bit-exact constants** (0.404464 / 0.403975 V) | none |
| Single-epoch peak, 10–500 ms | median 436 / p90 651 / max 795 µV | **median 2296 / p90 3449 / max 4228 µV** |

⚠ `data` has one more row than `sum(blocks['samples'])` in both files — the known un-written tail
row. **Counts must come from `sum(blocks['samples'])`, not `data.shape[0]`.**

⚠ **Both files carry `metaData = {}` on the `eeg` stream** — no channel names, no units, no CED.
This is a genuinely empty MetaData from the producing driver, not a recorder limitation
(`HDFRecorder.cpp:107` and `StreamInfo.cpp:207` do persist it). See A22.

<a id="history-52-trigger--the-decisive-measurements"></a>

### 5.2 Trigger — the decisive measurements

**Idle word is `0x0000FFFA`, not `0x0000EFFF`.** Only bits 0, 1, 2 ever move; bits 3–15 rest HIGH.

| | File A | File B |
|---|---|---|
| bit0 rest | **LOW** | **LOW** |
| bit0 rising / falling | **150 / 150** | **107 / 107** |
| Pulse width | **10.00 ms (250 samples)**, 3 of 257 at 10.04 ms | same |
| First rise | 5.2916 s | 5.2737 s |
| Tail after last rise | 1.89 s | 3.66 s |
| ITI min / median / max | **1.5371** / 1.7607 / **2.0488 s** | **1.5434** / 1.8008 / **2.0487 s** |
| ITI shape | flat across twelve 42 ms bins — a uniform draw | same |
| Rises < 200 ms apart | **0** | **0** |
| Non-integral / NaN / zero values | **0** | **0** |
| `Status == 0` preamble | **none** — first 40 samples already `0xFFFA` | none |

**bit1** — a second real line: idles HIGH, low-pulses for **50.20 ms**, 150/107 falls, asserting a
fixed **60.28 ms before** every bit0 rise (the `+60` in both filenames). Sensory stimulus onset;
bit0 is the TMS pulse at ISI +60 ms.

**⚠ bit2 anomaly, file B only:** goes HIGH once at t = 197.3715 s and never returns — the last
1.96 s idle at `0xFFFE`. 1.70 s after the last bit0 rise, so it cannot corrupt any epoch, and
bit-masked detection ignores it. **But the trigger word is not constant across the file**, so any
check written as `word == idle` rather than `bit N of word` fires spuriously at the end of file B.

**Each NVX trap, checked:**
- "idle word is `0x0000EFFF`" — **false here** (`0x0000FFFA`)
- "an input edge is a bit going LOW" — **false for bit0** (rising), **true for bit1**. Both
  polarities in the same word.
- "the first ~14 frames carry `Status == 0`" — **does not occur**
- `pipeline.cpp:197-204` adopts the resting level from the first sample it sees, so the first block
  cannot fabricate an edge. **Confirmed safe.**
- `pipeline.cpp:18-28` maps NaN/≤0 to word 0 → bit0 reads LOW = these files' idle, so a hypothetical
  NaN gap cannot fabricate a rising edge **here**. ⚠ On an idle-HIGH rig with `Falling` it would —
  the comment at `:22-23` says a NaN gap "must not read as every bit set", but returning 0 on an
  active-low rig is precisely "every input asserted". **Wrong constant for the rig class, harmless
  for these files.**

<a id="history-53--channel-order--i-verified-it-and-it-is-correct"></a>

### 5.3 ⭐ Channel order — I verified it, and it is correct

This was the largest single risk (A22) and it is now retired **for these two files**.

Method: band-limit 1–40 Hz, CAR, take 5.2 s of quiet pre-stimulus data, correlate every channel
pair, and regress against geodesic distance from the `.ced` unit vectors.

| | File A | File B |
|---|---|---|
| corr(pair correlation, electrode distance) | **−0.724** | **−0.733** |
| "most-correlated partner is one of the 3 nearest electrodes" | **55 / 64** | **54 / 64** |
| Shuffled-order control (20 permutations) | 3.1 ± 2.0 | 2.9 ± 1.8 |

The handful of misses are 4th-neighbour ties (CP1↔C1, C3↔C1, Cz↔C2, AF3↔Fpz), not disorder.

⇒ **The recordings' EEG channels 0–63 are in `mks64_standard.ced` row order. The replay is spatially
meaningful.** ⚠ **Re-run this check on any new recording before trusting a head map from it.** It
costs one Python script and it is the only thing standing between a wrong montage and a confident
wrong answer.

<a id="history-54-the-commands"></a>

### 5.4 The commands

**Use `playbackSource.exe`, not `playbackService.exe` + `--serviceConfig`.** This is a hard blocker,
not a preference: `applyParameters` screens parameter names **once, up front**
(`communicationlayer.cpp:337-350`), building the `pending` set before applying anything.
`playbackService`'s per-stream parameters `play0`/`name0`/`service0` are created only by `rescan()`,
which runs only when `file` changes. So in a single config pass `file` is accepted and every stream
row is rejected with "this service has no parameter by that name". **A `--serviceConfig` can never
map the streams of the playback controller.**

**Terminal 1 — consumer:**
```bat
cd /d R:\dist\msvc64
call env.bat
cd bin
set QT_FORCE_STDERR_LOGGING=1
set QT_LOGGING_RULES=*.debug=true;qt.*.debug=false
tepSoundService.exe ^
  --signal  Playback/eeg ^
  --markers Playback/stimuli ^
  --montage montages/mks64_standard.ced ^
  --leadfield calib/mks64_leadfield.h5 ^
  --autoArm
```

**Terminal 2 — producer:**
```bat
cd /d R:\dist\msvc64
call env.bat
cd bin
playbackSource.exe --serviceName Playback ^
  --file "N:\Projects_MSU\2026 - FeetStim\data - raw\tests\06_Timofey_EP_TEP_MEP\11_TMS_48MSO_heel_+60.hdf5" ^
  --stream eeg --stream stimuli --speed 1 --autoStart
```
File B: identical with `--file "N:\Projects_MSU\2026 - FeetStim\data - raw\tests\05_Anatoly_EP_TEP_MEP\12_TMS_metatarsus_+60_2.hdf5"`.

**Why each flag:**
- `--serviceName Playback` — the default is **`"Playback source"`, with a space**
  (`sourcemain.cpp:111`). tepSound's `--signal` shorthand builds
  `discover:///?stream=%1&name=%2` by raw string interpolation with **no percent-encoding**
  (`main.cpp:95-98`), and `DiscoverURI` splits `url.query()` on `&`/`=`. **A name with no spaces
  makes the whole class of problem disappear.**
- `--stream eeg --stream stimuli` — with no `--stream`, every playable stream is published, adding
  `feetStim`.
- `--speed 1` — see the traps.
- `--autoStart` — defers 2000 ms so discovery announces first; tepSound's `--autoArm` fires at
  2500 ms, so tepSound arms 0.5 s **after** playback begins, losing at most 0.5 s of the 5.27 s
  lead-in. For an exact start, drop `--autoStart` and press Start on playbackSource once tepSound
  reads `armed`.

`--signal Playback/eeg` survives the producer starting later because
`Parameters::Stream::m_reconnect` defaults to **true** — the binding is by service name + stream
name.

**Every default is already correct for these files.** `triggerChannel = 0` → last channel → index
72 ✓; `triggerBit = 0` ✓; `triggerEdge` = **Rising** ✓ (and **must not be changed**);
`refractoryMs = 500` vs min ITI 1537 ms ✓; `eegChannels = 64` ✓; `emgChannelA/B = 65/66` (1-based)
→ indices 64,65 = the **AH pair, live in both files** ✓; `workRate/outputRate = 5000/1000`
(25000 ÷ 5 ÷ 5, whole numbers) ✓; `montage` = the 64-row file ✓.

**Two changes required for the replay:**
1. **`triggerBackend = None`** (default is Serial/COM3, opened on Arm — B5).
2. **Arm before playback starts.** `beginSession()` is what calls `setActive(true)` on the worker;
   **nothing is produced in `idle`.** Arm, not Start — `armed` runs the analysis without presenting.

Optionally for the first pass: **`blankTo = 1.3`** (A1). Run one pass at the default and one at 1.3
and compare, so the effect is measured rather than assumed.

<a id="history-55-traps"></a>

### 5.5 Traps

1. ⚠⚠ **`--speed` other than 1 corrupts something silently.**
   `player.cpp:575`: `publishedRate = job.scaleRate ? recordedRate * job.speed : recordedRate`.
   - `speed 1` — exact. **Use this for every measurement.**
   - `speed 2, scaleRate off` — waveform and ms windows stay correct, but `Pipeline::rtcForIndex`
     interpolates at the declared rate and anchors on the block's **last** sample, so **every
     trigger's RTC — the `created` field, i.e. the Stage 0 epoch contract — is wrong by up to a
     block, ≈39 ms.** Nothing on the wire says so.
   - `speed 2, scaleRate ON` — declared rate 50 000 Hz, so a "500 ms" window covers 1000 ms of
     recorded time. **The TEP appears at half its true latency.** `scaleEpochWindow`
     (`player.cpp:60-170`) fixes this for already-epoched streams and does nothing for a raw
     continuous one. **Never use scaleRate here.**
   ⇒ Speed > 1 is fine for a UI smoke test of the buttons and meaningless for anything about timing.
   **State the speed in the report.**
2. ⚠ **`--serviceConfig` lands in `afterExec()` (`ResonanceApp.cpp:592-597`), i.e. AFTER `main()`
   ran `setStream()`.** A config file **wins over `--signal`**; a stale or empty `signal` entry
   silently unbinds the stream you asked for. **Use the CLI flags alone.**
3. ⚠ **`--markers Playback/feetStim` would silently destroy every condition label.**
   `labelFromMarker` (`service_analysis.cpp:64-80`) recognises only `{"stimulus": …}` and
   `{"type":"cue", …}`. A `{"feetStim": …}` object matches neither, returns an empty string, and
   `onMarkerBlock` **assigns** it (`:596`, deliberately — "an offset record clears the label").
   **Bind `markers` to `stimuli`.**
4. ⚠ **`.bat` + `start` quoting.** `playbackSource.bat` ends in `start playbackSource %*`, and
   `start` treats a **quoted first token** as a window title. `--file "N:\…"` is safe;
   `"--file=N:\…"` is not — the path becomes a window title and the worker plays nothing.
   **Run the `.exe` directly after `call env.bat`.**
5. ⚠ **`--loop`.** Both files idle bit0 LOW at the last sample so a wrap fabricates no edge, but it
   splices 272 s onto 0 s with a discontinuity the continuous highpass rings on. **Do not loop for
   a measurement run.**
6. ⓘ **Read load is fine.** `hdfsource.cpp:390-418` reads one block's hyperslab per block — no 4 GB
   slurp. 1.14 MB × 12.8 blocks/s ≈ **14.6 MB/s**, and `N:` is DriveType 3 (local fixed disk,
   volume "NNCI"). **Read `logProgress()` (`sourceservice.cpp:344-353`) every 30 s — it prints
   mean/max lateness and underruns and is the only thing that says the emulation kept up.** Needs
   `QT_FORCE_STDERR_LOGGING=1`.
7. ⓘ **Block-stamp jitter is not a defect.** 293 of 3480 blocks (A) and 216 of 2548 (B) have a
   `created` gap disagreeing with their own sample count by more than 5 ms, spread −17.5 to
   +31.4 ms, while total drift over the whole file is only −46 ms / −30 ms. That is transport jitter
   in the stamp, not lost samples: **the epoch cut is by sample index and is exact**, but
   `rtcForIndex()` anchors on the block's `created`, so `triggerRtc` inherits up to ~±30 ms.
   **Write this into the acceptance criteria rather than treating a ±30 ms stamp as a bug.**

<a id="history-56--what-would-prove-tepsound-is-correct-not-merely-running"></a>

### 5.6 ⭐ What would prove tepSound is CORRECT, not merely running

**An average that looks like a TEP is not proof.** A 10 ms trigger shift, a scrambled montage, a
stale operator and a half-blanked artefact all produce plausible TEPs. Proof is *numerical agreement
with an independently computed reference*, plus *exact counts*.

**Gate 1 — counting. Every number is exact; any deviation is a real defect, not replay noise.**

| Quantity | File A | File B | Where to read it |
|---|---|---|---|
| `triggers` | **150** | **107** | run bar / status |
| `refused` | **0** | **0** | (min ITI 1537 ms ≫ 500 ms refractory) |
| `starved` | **0** | **0** | status |
| `incomplete` | **0** | **0** | ⚠ needs B8 to be visible at all |
| `artifactSkipped` | **0** | **0** | ⚠ needs B8 |
| epochs stored | **150** | **107** | run bar |
| `averageWithheld` | **0** | **0** | status ch |
| `anchorRejected` | **0** after warm-up | **0** | status ch 36 |
| epochs carrying a `clean` | **140** (150 − warm-up 10) | **97** | epoch table `cleaned` col (⚠ needs B22) |
| Retrains | 15 | 10 | `modelId` |
| Labels | 3 × 50, all matching `*!_sf100_gp50` | 35/36/36 | epoch table |
| Unlabelled epochs | **0** | **0** | epoch table |

**Gate 2 — timing.** With `triggerEdge = Rising`, the artefact must sit at **t = 0** in the epoch,
not t = −10 ms. Verify on the published `epochs` stream, not by eye on the average: the first
sample exceeding 50 mV must be within **one sample of 0.0 ms**.
⇒ **Deliberate negative control: run one pass with `triggerEdge = Falling` and confirm the whole
average shifts by exactly 10.0 ms.** If it does, A2 is demonstrated and the acceptance criterion is
meaningful. If nothing changes, the edge setting is not doing what it says.

**Gate 3 — amplitude, against an independent reference.** Reference values computed in Python (CAR,
blank −0.04…+1.2 ms, baseline −60…−10 ms, all epochs):

| | File A (150 ep) | File B (107 ep) |
|---|---|---|
| Per-channel peak in 15–150 ms, median | **24.35 µV** | **26.54 µV** |
| Max | **56.94 µV at Cz** (−56.9 @ 15 ms) | **888.9 µV at FT9** |
| CPz | −56.9 @ 15 ms | −74.6 @ 15 ms |
| Pz | −41.8 @ 16 ms | −43.1 @ 18 ms |
| FCz | +25.5 @ 28 ms | −23.0 @ 120 ms |
| C3 | −11.1 @ 87 ms | −48.0 @ 15 ms |
| C4 | +10.6 @ 36 ms | −25.8 @ 95 ms |
| Average MEP p2p (ch66 − ch65), 15–60 ms | **0.090 mV** | **0.422 mV** |

Record tepSound's published `average` stream and compare offline against
`R:\config\tepsound_reference_pipeline.py`. **Agreement to a few percent on the named channels and
latencies is the proof. "It drew something" is not.**
⚠ tepSound applies SOUND, which the reference does not — so compare against the **`epochs`
(preprocessed) stream** for the strict numerical match, and use `clean` to demonstrate that SOUND
*reduces* the residual rather than to match a number.

**Gate 4 — the bad channel.** File B **must** flag and repair **FT9** (index 4). This is the
acceptance test for the whole detector/repair path and file B is the only one that exercises it. If
FT9 is not flagged, `badChanEnable` is not doing its job — and FT9 at 33× the median will dominate
every scalp map and every common scale (relevant to Feature 3).

**Gate 5 — the file.** Open the written HDF5 and check: `Fs`, `window_start_ms`, `window_end_ms`
match the geometry actually used; the epoch array is 150 (or 107) × 64 × 701; no all-zero rows other
than the 10 warm-up epochs; labels present. **A14 predicts failures here after any mid-session
window change — so run one pass with a deliberate mid-session `Window to` change and confirm the
file is inconsistent.** That converts A14 from a code reading into a demonstrated defect.

**Gate 6 — negative controls.** Each should produce an obvious, *visible* failure. If any of them
looks normal, that is the finding:
1. `triggerBit = 1`, `Falling` → a clean 150-epoch average of the **sensory** EP with the TMS
   artefact at +60 ms. **Nothing in the UI will say which one you epoched.** ⇒ argues for A2's
   detected-polarity readout.
2. `emgChannelB = 99` → **A25**: NaN MEP poisons the average permanently.
3. Change `Window to` mid-run → **A3**: watch for a new model with a plausible summary, or all-zero
   traces, or a crash.
4. Stop → Arm → **A4**: `in average` should be 0 and will not be.

<a id="history-57-per-file-notes"></a>

### 5.7 Per-file notes

- **`rejectPeakUv` must not be carried between the two files.** Median single-epoch peak in the
  reject window is 436 µV (A) and 2296 µV (B). A threshold keeping most of A discards essentially
  all of B. **The default of 0 (accept everything) is correct — leave it.**
- **Both files' EEG sits around a ±0.44 V DC offset**, so the 0.3 Hz continuous highpass starts from
  zero state and rings for seconds. The first trigger is at ~5.28 s = only ~10 filter time
  constants, so **expect the first few epochs to carry residual drift into the first SOUND training
  block**, and `rejectPeakUv = 0` keeps none of them out. Consider discarding the first 2 epochs
  from training, or starting playback earlier.
- **Per condition:** A gives 3 × 50, B gives 36/36/35. `service.cpp:718-722` says the lab's study
  settles by ~40 trials. **50 is fine; 36 is just under.** Say so before anyone draws a conclusion
  from a per-condition contrast in B.
- **Delivery latency:** `windowEnd + guardMs` = 700 ms after each pulse before the epoch can exist.
  Against a 1537 ms min ITI that is 0.8 s of slack — the pipeline cannot fall behind. Raising
  `windowEnd` to 1000 ms makes the hold 1200 ms and the slack 0.34 s: **that is the knob that bites
  first**, and it is also A19's trigger.
- **File A's dead AUX channels (68, 70)** are outside the default EEG range and the default MEP
  pair, so they cost nothing — but they ride along in the 72-channel epoch and draw as two flat
  lines in anything plotting all signal channels. ⚠ The two sidecars disagree (Timofey TA = [69,71],
  Anatoly TA = [70,71]) precisely *because* 70 is dead in A. **Any per-muscle MEP comparison across
  the two files must not assume a shared AUX map**, and must check for a constant lead first —
  nothing in the service will.

---


<a id="history-6-the-three-requested-features--costed"></a>

## 6. THE THREE REQUESTED FEATURES — costed

<a id="history-61-feature-1--topoplot-driven-by-the-butterflys-time-cursor-switchable-against-a-head-shaped-trace-array"></a>

### 6.1 Feature 1 — topoplot driven by the butterfly's time cursor, switchable against a head-shaped trace array

**⭐ The head-shaped trace array already exists.** `TepGridView` (`views.cpp:173-334`) lays traces out
at `scalpPoint(theta, radius)` on the `.ced` polar coordinates — that *is* the head-shaped array.
**The "switchable against" half of the request is a toggle between it and a new `TepTopoView`, not
new code.** This roughly halves the feature.

**Share as-is — verified Qt-free (includes are `<string>`/`<vector>` only):**

| File | Lines | Contents |
|---|---|---|
| `R:\src\quickStimulus\topofield.hpp` / `.cpp` | 519 / 990 | `topoLayout`, `TopoField::solve/evaluate`, marching-squares contours, the `conv` hull. Matched to EEGLAB to **6e-14 on levels and 0/40000 on the mask** |
| `R:\src\quickStimulus\colormap.hpp` / `.cpp` | 254 / 224 | zero Qt |
| `R:\src\quickStimulus\plotmath.hpp` / `.cpp` | — | zero Qt; worth taking for the axis/tick helpers `views.cpp` re-implements (`niceStep`, `views.cpp:28-43`) |

**Must be rewritten, not ported:** `topoview.{hpp,cpp}` (747 + 1469) and `epochgridview.{hpp,cpp}`
(608 + 1370) are `QQuickPaintedItem`s bound to `channelmodel.hpp` and `epochreceiver.hpp` — the
viewer's entire data model, none of which exists in tepSound. **Budget them as new painted items in
`views.cpp` beside `TepGridView`/`TepTraceView`**, reading `m_service->displayed()`,
`scalpPositions()` and `channelNames()` directly, registered in `main.cpp:64-67` under
`Resonance.TepSoundPlots` exactly like the existing two. `TepPlotBase` (`views.cpp:51-167`) already
covers the shared paint/hover/geometry half.

**⭐ The CMake decision — recommend option 2.**

*Option 1 (cheapest, matches the tree's existing pattern).* `CMakeLists.txt:28-40` already references
`../tepService` and `../stimulusService` by path for exactly this reason ("One source of truth,
compiled twice" — verified in the file's own comment):

```cmake
set(QS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../quickStimulus)
list(APPEND SHARED_SOURCES
    ${QS_DIR}/topofield.cpp   ${QS_DIR}/topofield.hpp
    ${QS_DIR}/colormap.cpp    ${QS_DIR}/colormap.hpp
    ${QS_DIR}/cedpalette.cpp  ${QS_DIR}/cedpalette.hpp)
target_include_directories(${PROJECT_NAME} PRIVATE ${QS_DIR})
```
plus the same three in the `test_TepSound` `CORE_SOURCES` block (`CMakeLists.txt:96-108`) so the
field can be pinned without a window.

⚠ **Do not simply add `../quickStimulus` to `target_include_directories` without the explicit source
list** — `topoview`/`epochgridview` would then be one `#include` away from dragging `channelmodel`
in.

*Option 2 (recommended).* Promote the five Qt-free files into **`R:\src\plotcore\`** as
`add_library(plotcore STATIC ...)` and have both `quickStimulus` and `tepSoundService` link it.
Costs one directory and one `add_subdirectory`; removes the `../quickStimulus` include path
entirely. **Recommended because `cedpalette` is about to have three consumers**, and because the
tree already demonstrates that path-referenced sharing scales badly past two consumers.

**⚠ Which channels to feed it — resolved, and the montage question does not arise.**
tepSound's `.ced` has **64 rows**, `readCed` is already truncated to `eegChannels`
(`service_analysis.cpp:107`), and `m_scalp` (`:134-137`) holds exactly those 64 — the EEG set with
no EMG. So `topoLayout(theta.data(), radius.data(), 64)` gives the **EEG-only
`plotrad = 0.678218`, which is the correct one.** The +11.53 % inflation to 0.756412 is the 66-row
`Bricks` case (EMG1/EMG2 at numbers 129/130) and **cannot arise here.**

**⚠ Three prerequisites, all from the findings above:**
1. **Pass only contributing channels to `TopoField::solve`.** `topofield.hpp` warns that **one NaN
   makes the entire field NaN**. Exclude channels the bad-channel report flagged and draw those
   hollow **on top**. `report().bad` / `flaggedProtected` (`badchannels.hpp:122-123`) already give
   the set; feed it as `contributing` and let the LU cache key do its job. ⚠ **File B's FT9 makes
   this mandatory, not optional.**
2. **Fix `readCed` to recompute `radius = 0.5 − sph_phi/180` first** (§3). `plotrad` derives from
   `max(radius)` and the biharmonic kernel is not scale-invariant, so a rounded max shifts the
   **shape** of the field. Three lines.
3. **Fix A17 (`sampleAt` clamping) first.** The time cursor inherits it: dragged past the window
   edge it pins to the edge value while the readout keeps the requested time.

⚠ **D2:** the topoplot is the first continuous field in this service. **Its electrode marks must be
black, always** — not `Theme.accent`, not the hard-coded amber of `views.cpp:275/500`.

**Effort: 3–5 days.** Breakdown: CMake/plotcore 0.5 d; `TepTopoView` painted item 1.5–2 d; time
cursor + A17 0.5 d; toggle + controls 0.5 d; contributing-channel plumbing + hollow marks 0.5 d;
`readCed` fix + test pinning 0.5 d.

<a id="history-62-feature-2--ced-based-trace-colours-as-the-butterfly-default"></a>

### 6.2 Feature 2 — CED-based trace colours as the butterfly default

**What decides trace colour today: one colour for every channel.** `TepPlotBase::m_trace` is a
single `QColor`, bound once from QML as `traceColor: Theme.tep` (`Console.qml:176, 249, 326`).
`TepGridView::paint` builds `QPen tracePen(m_trace)` **once** at `views.cpp:273` and uses it for
every channel at `:312`; `paintButterfly` does the same at `:498`/`:532`. The only per-channel
variation is `m_highlight` with the hard-coded amber. **There is no per-channel colour array
anywhere, and the `.ced` is read only for positions and names, never for colour.**

`R:\src\quickStimulus\cedpalette.hpp` (being written in the other workflow) is Qt-free and its
`fromPolar(const double* thetaDeg, const double* radius, int n, const Options&)` →
`std::vector<Entry>` is an **exact match** for what tepSound already holds: `m_scalp[i] =
QPointF(theta, radius)`, already EEG-only and already in channel order.

**The change, ~30 lines:**
1. Add `QVector<QColor> m_traceColours` + `bool m_cedColours = true` to `TepPlotBase`, rebuilt on
   `TepSoundService::geometryChanged` (**the connection already exists**, `views.cpp:74`) by calling
   `CedPalette::fromPolar` over `m_service->scalpPositions()` and `to8Bit()` into `QColor`.
   ⚠ Better: build it in `loadCalibrationAssets()` beside `m_scalp` (`service_analysis.cpp:91`), so
   `views.cpp` stays Qt-only and the palette stays Qt-free.
2. Move the `QPen tracePen` construction **inside** the per-channel loop in `TepGridView::paint`
   (`views.cpp:279-313`) and `paintButterfly` (`:513-534`), indexing
   `m_traceColours.value(c, m_trace)` — **`m_trace` as fallback keeps the MEP views and any
   montage-less state working unchanged.**
3. Promote the literal amber highlight to a settable property (`Theme.accent`) so it still reads
   against 64 hues.
4. Expose `cedColours` as a `Q_PROPERTY` so the existing `labels on/off` toggle in the plot frame's
   `controls:` (`Console.qml:162-166`) can carry a matching `colours on/off`.

Add `cedpalette.{hpp,cpp}` to the CMake change from Feature 1 — **no separate CMake work.**

**Effort: 0.5 day**, plus a hard dependency on the other workflow landing `cedpalette`.

<a id="history-63-feature-3--auto-fit-bounded-to-15150-ms-common-scale-as-the-default"></a>

### 6.3 Feature 3 — auto-fit bounded to 15–150 ms, common scale, as the default

**⭐ The common scale already exists. Only the auto-fit is missing.**
`TepGridView::paint` computes **one** `yScale = (m_cellHeight/2)/m_amplitude` (`views.cpp:265`) for
every cell; `paintButterfly` computes **one** `yScale = halfHeight/m_amplitude` (`:496`) for all 64
traces. **Nothing is per-channel anywhere.** Requirement "common scale for all electrodes" is
already satisfied structurally; the auto-fit must produce a **scalar**, not a vector.

**There is no autoscaling anywhere in `views.cpp`.** `m_amplitude` is written only by hard-coded QML
literals and the three ScaleBox `onEdited` handlers. `setAmplitude` silently ignores `value <= 0`.

**The time interval is separate and also manual.** `xMinMs`/`xMaxMs` default to **−10 and +100 ms**
(`Console.qml:177-178, 250-251`). **The requested 15–150 ms is outside the current right edge**, so
the x-range must move too, not just the y.

**The change:**
1. Add `Q_PROPERTY(bool autoFit)`, `fitFromMs`, `fitToMs` to `TepPlotBase` (defaults true / 15 /
   150). When on, scan `data.eeg` over `[sampleAt(fitFromMs,false), sampleAt(fitToMs,false)]` across
   **all** channels for `max(fabs(v))`, skipping non-finite, and set `m_amplitude` with 1-2-5
   rounding (reuse `niceStep`, or `plotmath`'s if linked for Feature 1).
2. Recompute on the revision change, not every frame — hang it off `dataChanged`, which the service
   already coalesces at 10 Hz (`views.cpp:73`, `onViewTick` `service_analysis.cpp:1194-1209`).
3. Drive `scalp` and `butterfly` from the **same** computed amplitude, as the manual ScaleBox already
   does.
4. Turn the ScaleBox into a manual override that clears `autoFit`, **and show which mode is
   active** — otherwise an operator who types a value and sees it move has a control that appears
   not to work.
5. ⚠ **Change the clamp to a clip.** Both painters do
   `y = mid - max(-half, min(half, v*yScale))` (`views.cpp:302-303, 524, 565, 686`), which draws an
   over-range trace as a **flat line pinned to the panel edge** — visually identical to a saturated
   channel and to a genuinely flat one. **With auto-fit on, over-range is by definition an outlier
   worth seeing**: break the segment (as the `isfinite` branch already does at `:297-300`) or draw
   to a clipped path. **Do not flatten.**
6. ⚠ **`TepTraceView::setKind` silently rewrites `m_amplitude` to 0.5** when switching away from
   Butterfly if it was above 5 (`views.cpp:347-348`). An auto-fit must not fight that heuristic.

**⚠⚠ The blocking prerequisite, and it is measured, not hypothetical.**
**File B's FT9 peaks at 888.9 µV in the 15–150 ms average against a 26.5 µV per-channel median — 33×.**
A plain `max(|x|)` over channels puts the butterfly at ±889 µV and **flattens all 63 good traces to
invisibility.** ⇒ **The autofit must exclude channels the detector marked bad/repaired, or use a high
percentile (p95–p99) rather than the maximum.** Preferably both. This is the single design decision
that makes the feature useful rather than actively harmful.

**⚠ The scale-control wiring is the weak point for all three features.** Every ScaleBox holds a
hard-coded literal duplicating the C++ default (`value: 30` vs `m_amplitude = 30`; `-10`/`100` vs
`m_xMin`/`m_xMax`; `500` vs `amplitude: 0.5`) and **data flows one way, QML → C++, with no
back-channel.** Any feature that changes `amplitude` or the range from inside C++ — an auto-fit,
`setKind`'s existing snap, a time-cursor-driven topoplot — leaves the box showing a number that is
no longer true. ⇒ **Bind the three ScaleBoxes two-way before Feature 3** (`value: plot.amplitude` /
`onEdited: plot.amplitude = value`, which `setAmplitude`'s fuzzy-compare guard already makes
loop-safe), **and un-cross-wire the panels**: today the µV box lives in the scalp panel and drives
the butterfly, while the two ms boxes live in the butterfly panel and drive the scalp grid.

**Effort: 1 day**, plus 0.5 day for the two-way binding and un-cross-wiring (which Features 1 and 3
both need — count it once).

---


<a id="history-7--what-i-would-not-do-and-why"></a>

## 7. ⚠ WHAT I WOULD NOT DO, AND WHY

The operator wants to run an experiment. These are genuinely not worth the budget.

1. **Do not touch the 84 non-ASCII characters.** `/utf-8` is present and verified (§0.2). This was
   flagged as a day's work elsewhere and here it is **zero**. Do one screenshot of the `Montage` and
   `Protected` tooltips (test TT-01) to close it visually and move on.

2. **Do not rewrite the D1 tooltips.** 15 parameters carry design rationale, benchmarks and lab
   anecdotes. It is a real style violation and it costs the operator **nothing** — a verbose tooltip
   is not a wrong answer. **Write the 6 missing descriptions that matter** (`triggerEdge`,
   `baselineFrom`, `averageWindow`, `blankTo`, `rejectFrom`, `rejectTo`) and leave the other 20
   blanks and all 15 verbose ones alone. **1.5 h instead of 2 days.**

3. **Do not change the `lastN` semantics before the experiment.** tepSound windows by position;
   tepService and the viewer mean "last N accepted" (§3). Changing it now silently changes what every
   number on screen means, mid-programme, for a marginal consistency gain — and both places that
   display the count already show the **true** n. **Document it in the tooltip; align it after the
   experiment.**

4. **Do not fix the `m_ica` dead code, the unused `truncateToSamples`, `StatusPill.qml`, or the
   unused `action` editor.** Zero operator impact. One 64×64 multiply per calibration is not a cost.

5. **Do not fix U6 (unbounded `m_looCache`) or U7 (unbounded training deque) for this experiment.**
   At 150 and 107 trials the deque is ~27 MB and the cache is trivially small. They matter in a
   700-trial session. **Note them; do not spend now.** (The one exception worth 15 minutes: stop
   `process()` pushing to `m_train` when `soundEnable` is off — it is a one-line guard that also
   removes a wasted 64×64 × 64×701 product per epoch.)

6. **Do not build a general "which epochs were re-cleaned vs online-cleaned" UI (A20's full form).**
   Count it and print one string ("62 of 87 re-cleaned"). The full per-epoch provenance view is a
   day and answers a question the operator asks once.

7. **Do not promote to `R:\src\plotcore\` if the schedule is tight.** Option 1 (§6.1) works, matches
   what the tree already does twice, and is 20 minutes. Option 2 is better and costs half a day.
   **Take option 2 only if Features 1 and 2 are both being done in the same pass**, which is the
   likely case.

8. **Do not fix A21 (`onCuePresented` queue desync) unless the stage is being used.** It is
   unreachable in Arm-only operation, which is this experiment's mode (§0.1).

9. **Do not attempt a full 300-trial buffer-overflow test (RB-04) on these recordings.** They have
   150 and 107 trials. Set `epochBuffer = 20` and test the freeze behaviour in two minutes instead of
   synthesising a long recording.

10. **Do not "correct" the trigger polarity to match `report_trigger-validation.md`.** ⭐ The
    defaults are right and the document is wrong for this rig (A2, §5.2). **Amend the document, not
    the settings.** This is the single most expensive available mistake and it would look like
    diligence.

11. **Do not run the replay at any speed other than 1** for anything you intend to report a number
    from (§5.5 trap 1). Speed 2 is fine for pressing buttons and worthless for timing.

---


<a id="history-8-total-eta"></a>

## 8. TOTAL ETA

Estimates are working days for one engineer who knows this tree. **Uncertainty is stated per block,
not hidden in a single number.**

<a id="history-block-1--tier-a-fixes-the-ones-that-cost-a-session"></a>

### Block 1 — Tier A fixes (the ones that cost a session)

| Item | Effort | Confidence |
|---|---|---|
| A5 Reset confirmation + enable gate + autosave | 1 h | high |
| A1 `blankTo` default + residual measurement/warning | 2.5 h | high |
| A2 `triggerEdge` description + detected-polarity readout + doc amendment | 3 h | high |
| A6 + A7 ParamControl binding fix (both editors) | 1 h | high — **but see T-K1** |
| A4 Stop→Arm store handling | 2–4 h | medium (design choice: clear vs prompt) |
| A3 geometry-change invalidation + live-path shape guard + `multiply()` + `canAnchor` finiteness | 4 h | medium |
| A8 baseline reversal checks | 1.5 h | high |
| A9 phantom epochs | 2 h | high |
| A10 `accepted` disambiguation | 1 h | high |
| A11 butterfly `n =` | 15 min | high |
| A12 invalid-MEP rendering + `mep/valid` dataset | 2 h | high |
| A13 peak measured pre-repair | 2 h | medium |
| A14 epoch-file consistency + `cleaned` flag | 3 h | medium |
| A15 `artifactApplied` + counter | 2 h | high |
| A16 stimulator interlock | 1 h | high |
| A17 `sampleAt` validity flag | 2 h | high |
| A18 single MEP measurement | 1.5 h | high |
| A19 latch the label at trigger time | 1 h | high |
| A20 re-clean mixture count | 1.5 h | high |
| A22 stream channel-name check | 2 h | medium |
| A23 all-or-nothing asset load | 1 h | high |
| A24 expose `eegScale`/`emgScale` | 1 h | high |
| A25 finiteness guards in `reduce()` | 1.5 h | high |
| **Block 1 total** | **≈ 5 days** | **±1 day** |

<a id="history-block-2--tier-b-visible-but-expensive"></a>

### Block 2 — Tier B (visible but expensive)

| Group | Effort |
|---|---|
| B1–B4 stage + protocol wiring (**4 ★★★ findings for ~2 h of work** — do these) | 2 h |
| B7 + B9 + B19 message strip (**unblocks eight existing diagnostics**) | 3.5 h |
| B5, B6, B13 trigger default, Esc, keyboard gating | 2 h |
| B8 + B20 + B21 counter plumbing and separation | 4 h |
| B10–B12 buffer/table/grid honesty | 2.5 h |
| B14–B18 calibration retry, eegChannels wedge, serials, error lifetime | 5 h |
| B22–B30 columns, dead properties, stale readouts, misc | 8 h |
| **Block 2 total** | **≈ 3.5 days** (**±1 day**; B23's "useful four" could expand) |

<a id="history-block-3--testing"></a>

### Block 3 — testing

| Item | Effort |
|---|---|
| UI test plan execution (§4, ~90 cases) | 1 day |
| Replay both files, all six gates + four negative controls (§5) | 1 day |
| Offline numerical comparison against the reference pipeline | 0.5 day |
| **Block 3 total** | **≈ 2.5 days** ±0.5 |

<a id="history-block-4--features"></a>

### Block 4 — features

| Item | Effort |
|---|---|
| Shared scale-control rework (two-way binding, un-cross-wiring) — **prerequisite for 1 and 3** | 0.5 day |
| Feature 3 auto-fit (incl. the bad-channel exclusion) | 1 day |
| Feature 2 CED colours | 0.5 day (**blocked on `cedpalette` landing**) |
| Feature 1 topoplot + toggle (incl. CMake, `readCed` fix, contributing channels) | 3–5 days |
| **Block 4 total** | **5–7 days** (**±2 days** — Feature 1 dominates the variance) |

<a id="history-totals"></a>

### Totals

| Scenario | Days | What it buys |
|---|---|---|
| ⭐ **Minimum to run the experiment safely** | **1.5** | A5, A1, A2, A6/A7, A4, A11, A19, B1–B5, B7 — every "loses a session" defect and every dead control, plus the message strip. **Do this first regardless of what else is chosen.** |
| **+ full Tier A** | **5 ± 1** | No known path to a silently wrong answer |
| **+ Tier B** | **8.5 ± 2** | Nothing invisible, nothing inert |
| **+ testing** | **11 ± 2.5** | Demonstrated, not asserted |
| **+ all three features** | **16–18 ± 3** | Everything requested |

**Honest statement of uncertainty.** The three surveys are internally consistent and the ten claims
I re-verified in source all held (two with corrections: `/utf-8` is present, and A6 is more serious
than "stale display" if T-K1 fails). The variance is concentrated in three places:
1. **T-K1's outcome.** If typing does not commit integer parameters, that is a one-line fix but it
   invalidates any prior manual testing of this UI and forces a re-test of every integer row.
2. **Feature 1**, where "rewrite a `QQuickPaintedItem` against a different data model" is genuinely
   2–5 days depending on how much of `topoview.cpp`'s structure survives contact with
   `TepPlotBase`.
3. **A3 and A14**, where the right fix is a design decision (invalidate vs migrate; refuse vs
   per-epoch geometry) that could double either estimate.

Everything else is bounded. **"Fix all loose ends" is now a 5-day Tier A block plus a 3.5-day Tier B
block, not an unbounded request.**

---


<a id="history-9-recommended-order-of-execution"></a>

## 9. Recommended order of execution

1. **Run T-K1…T-K6** (§4.1). Six tests, under an hour, and they determine whether A6 is the top
   finding and confirm B1–B3 before anyone writes a line of code.
2. **The 1.5-day minimum block** (§8), in this order: A5 → B5 → B1–B4 → B7 → A6/A7 → A2 → A1 →
   A4 → A11 → A19.
3. **First replay pass, file A**, gates 1–3 (§5.6). Establishes that the counts and the timing are
   exact before any deeper fix is attempted.
4. **Rest of Tier A** (§8 Block 1).
5. **Replay pass, file B**, gates 1–6 including the bad-channel gate and all four negative controls.
6. **Tier B**, then re-run the UI plan.
7. **Features**, in the order 3 → 2 → 1 (cheapest first; Feature 1's prerequisites — A17 and the
   `readCed` fix — land with the earlier blocks).

⚠ **Do not start Feature 1 before A17 and the `readCed` `sph_phi` fix are in.** Both change what the
topoplot computes, and retrofitting them afterwards means re-pinning every reference value.

---


<a id="history-12-findings-left-open-after-the-click-through-added-2026-08-21-block-7"></a>

## §12. Findings left open after the click-through (added 2026-08-21, block 7)

§4's plan was executed control by control on a private desktop. 21 defects were found and 19 fixed;
the fixes and their proof screenshots are in
[tepsound-TASK.md](tepsound-TASK.md) under "Block 7". What follows is what was **not** fixed, so it
is not lost. None of it stops a session.

| id | finding | why it was left |
|---|---|---|
| **UI-01** | The message strip and the warnings strip appear and vanish, moving every control below them by 26–30 px. Controls move out from under the pointer mid-session. | Needs a decision, not a patch: reserving the height costs 26 px of plot on every session to spare a rare jump, and floating the strips over the work hides what is underneath. |
| **UI-02** | Electrode hit areas on the scalp grid are offset from the drawn labels — hovering a label often yields no name. | Clicking works, and since block 7 the clicked electrode is named on the butterfly caption, so this is a hover-only irritation. |
| **UI-03** | Attached tooltips wear Qt's default light chrome — dark text on white — against a dark console. `TepToolTip` is themed; the attached `ToolTip.text` on buttons, pills and plot notes is not. | One shared instance; one `background`/`contentItem` pair to replace. Cosmetic, readable as it is. |
| **UI-04** | The `Seed` spin box clips its own value (`48 211` runs under the `−` button); the `Protected` channel list scrolls its text out of view. | Both are content wider than a 330 px pane can show. The values are correct and reachable by widening the splitter. |
| **UI-05** | `armed` and `running` are told apart by the status dot's hue only — blue against green, no label — while every other state on the bar carries words. | |
| **UI-06** | A failed protocol load leaves the STIMULUS panel hint describing the **previous** protocol. The error itself is loud and correct. | Deliberate: clearing the loaded protocol on a failed load would be honest but would disarm a live session over a typo. |
| **B22** | The epoch table has no `peak`, `model` or `cleaned` column. | Carried from Tier B; a column addition, not a correctness fix. |
| **B28** | `Average all ☑` and the editable `100` beside it are both live at once; the check box silently wins. | Carried from Tier B. |
| **UI-07** | `blockReason` reads *"drag one onto Input"* and this console **has no Input panel**. It also names the Configurator, which does exist. | Half the sentence points at nothing. |
| **UI-08** | **`Trigger edge` is not in the settings pane**, and it is the decisive setting behind the amber polarity readout. The readout says what is wrong; the fix is one window away in the Configurator. | The operator instruction is in the operator section of tepsound-TASK.md. |
| **UI-09** | A tooltip on a **disabled** control is unreachable by construction — Qt Quick propagates `enabled` down the tree, so a `MouseArea` or `HoverHandler` inside a disabled `Button` is disabled too. The run bar works round it by writing both block reasons on the bar. | The general fix is a `blockedBy` property that keeps the button enabled-but-refusing, and every call site would have to migrate. |

<a id="history-ui-11--the-run-bar-still-clips-its-buttons-below-about-1150-px"></a>

### UI-11 — the run bar still clips its buttons below about 1150 px

Defect 1 of the click-through is fixed at the shipped 1680 px default and holds down to roughly
**1150 px**. Below that the buttons are clipped again: three of them gone by 980 px, six by 760 px.
`Layout.minimumWidth` on the button group is read back before a `RowLayout`'s own implicit width is
settled, so the engine shrinks the group like anything else and its children overflow into the
bar's clip.

⚠ **Two structural fixes were built and measured, and neither changed the rendered layout at all** —
a wrapper `Item` whose minimum bound to a sibling `Row`'s implicit width, and lifting the buttons
out of the layout into a `Row` anchored to the bar's right edge. In both cases the buttons still
rendered immediately after the block-reason text and ran off the right edge, as if they were still
inside the layout. RCC ran on every build, the generated `qrc_res.cpp` was deleted and regenerated
once to be certain, the QML disk cache was disabled for one run, and no QML warning was logged. The
discrepancy between source and result is unexplained and is the thing to start from if this is
picked up again.

Both attempts were rolled back. The console's own `SplitView` minimums put its usable floor near
1150 px, so the unfixed range is below the width at which the rest of the window works.

<a id="history-two-corrections-to-earlier-findings"></a>

### Two corrections to earlier findings

- **B13 (`P` does nothing) is withdrawn.** `P` is wired, reaches `manualPulse()`, and prints
  `arm the session before pulsing` in idle and `pulse N fired by hand …` when armed. What made it
  look dead was the UI driver injecting a virtual key with `wScan = 0`; Windows does not fill the
  scan code in, and Qt received no key event at all. `MapVirtualKeyW(vk, 0)` fixed the harness.
- **`test_NetworkMode` does not hang.** It is a QTest-style binary, not GTest, so
  `--gtest_list_tests` returns `Unknown option` — which is what read as a hang. Run plainly it
  finishes in about a second: `NetworkMode: 10 case(s) pass in loopback mode`.

<a id="history-one-new-finding-and-it-is-operator-facing"></a>

### One new finding, and it is operator-facing

**UI-10 — the console must be connected and settled before the first pulse.** The continuous drift
filter starts empty when tepSound connects to a stream. Connecting 3 s before the first trigger put
a **1758 µV** transient into epoch 0's `preproc` — against about 10 µV settled — and the bad-channel
detector reacted to it. It decays geometrically and is below 0.1 µV by the fourth epoch, so roughly
**10 s of stream before the first pulse** is enough. Written into the operator section of
tepsound-TASK.md.
