# Stimulus presentation — Qt 6 presentation studio and historical audit — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/stimulus-presentation.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-stimulus-presentation--qt-6-presentation-studio-and-historical-audit"></a>



<a id="history-current-service--2026-09-06"></a>

## Current service — 2026-09-06

`R:\dist\stimulusService.bat` launches the native x64 Qt 6.11.2 service **Stimulus**.
It is a functional extraction of TepSound's stimulus authoring and presentation path, with a
new operator console. It has no epoching, SOUND processing, analysis worker, plots or feedback
verdict overlay. Both services compile the same authoring, scheduler, stage, media and trigger
implementation; presentation corrections therefore reach `tepSoundService` as well.

The project uses MSVC v143 14.44 and C++20. CMake, deployment and distribution validation include
the executable, launcher and `protocols/stimulus-demo.tep.json`. The launcher resolves its own
directory and establishes the packaged Qt runtime through `env.bat`. The executable embeds the
dedicated stimulus icon required by [architecture §11d](../migrations/framework-evolution.md#history-11d-design-rule-every-executable-carries-its-own-icon).

<a id="history-first-use"></a>

### First use

1. Launch `R:\dist\stimulusService.bat`. The supplied demonstration uses text only and has no
   trigger outputs. The permanent transport bar shows the state, trial count and setup result.
2. In **Stimuli**, select a cue to edit its label, medium, text/file, duration, response rule,
   marker, repetitions and triggers. Welcome, Interval and End are separate rows. Duplicate and
   reorder controls act on the selection. **Preview selected cue** never sends triggers.
3. In **Sequence**, enter a sequence or generate it from repetitions and constraints. The realised
   order is visible. The seed controls reproducible order, duration, probability and offset draws.
4. In **Run setup**, choose the subject display, fullscreen mode, fixation, background and
   photodiode patch. Set session tags, trigger mappings and optional stimulator telemetry here.
   This page scrolls; the background pattern and full validation list are below the connections.
5. **Prepare** validates the document/media and opens its trigger connections. It may configure
   a serial board, so check the intended equipment first. Document and connection edits are locked
   until Stop. **Start** also prepares automatically. In the demo, focus the subject window and
   press Space to leave Welcome. A timed End row completes before the service returns to idle.
6. **Monitor** shows the current cue, progress and the latest 500 events. Its focused response pad
   accepts subject responses without commandeering keys typed in other editors. Use the subject
   screen itself when the operator console is not focused. Notes receive timestamps.
7. Save the experiment as `.tep.json`. **More → Pack media** copies referenced files into a
   companion folder with content hashes; Save afterwards to retain those new paths. Existing
   media is never overwritten. New/Open/Import/Exit protect unsaved work with a dialog.

The layout uses four task tabs with a permanent document/transport header, a persistent selected
cue editor, readable validation messages, the shared light palette, 130 px labels and solid-square
checkboxes. It is usable at 1000 × 650 and scrolls the longer setup sections. Ctrl+S saves, Ctrl+O
opens, Ctrl+Enter starts/resumes, Escape stops. Manual trigger is an explicit confirmed action.
Hiding the console keeps the service running; **Exit service** shuts it down.

<a id="history-presentation-capability-and-limits"></a>

### Presentation capability and limits

| Capability | Current behaviour |
|---|---|
| Text / image / blank | Frame-counted duration, text size, image fitting, fixation and photodiode patch |
| Video / audio | Qt 6 FFmpeg playback, muted preroll, seek-in point, media-length or authored duration; consecutive reuse seeks back |
| Responses | Timed, Space, any key, or response wait; key/text collection, Backspace and Enter submission, cue-relative software reaction time |
| Sequence | Seeded generator, pasted order, repetitions/constraints, duration jitter, Welcome/Interval/End |
| Cue triggers | None / Serial / Transition / Parameter / UDP; per-trigger target, code, probability, offset/jitter and separation |
| Background triggers | Existing seeded periodic pattern, cue gating and suppression reasons; actual beats are reported per cue |
| Interlocks | When a telemetry stream is nominated, missing/stale/nonfinite required readings refuse triggers; no stream means no telemetry gate |
| Pause / Stop | Pause freezes countdowns, scheduled triggers and media position. Stop clears queued/current cues, mutes media and closes wires |
| Recording | External `recorderService` records `Stimulus/events` and optionally `Stimulus/status`; start it and allow its slots to connect before Start |

The recorder stores presentation events and status, not a copy of the video/audio. Preserve the
experiment and media alongside a study. Qt decoding and display swaps are software milestones:
they do not establish photon, speaker or physical TTL onset. Media startup can extend the preceding
cue; the actual onset and decoder lag are published rather than replaced with an assumed time.
On this machine reported refresh was about 144 Hz. The software tests are not a new claim of the
historical Qt 5 0.05 ms measurement and do not certify timing on a laboratory rig.

FFmpeg audio-only onset uses the first decoded `QAudioBufferOutput` buffer. A deliberately selected
alternate Qt backend falls back to playback-position advancement and can be coarser. Decoder
failure refuses/stops presentation without reporting a successful media onset or its onset pulse.
Qt API references: [scene synchronisation](https://doc.qt.io/qt-6/qquickwindow.html#beforeSynchronizing),
[audio buffers](https://doc.qt.io/qt-6/qaudiobufferoutput.html).

<a id="history-contract-and-migration"></a>

### Contract and migration

The service identity remains **Stimulus**. Idle exposes `arm`, `prepare` (compatibility alias), and
`start`; armed exposes `start`/`stop`; running exposes `pause`/`stop`; paused exposes `resume`/`stop`.
Completion and failed preparation return to idle. `!terminate` follows normal service teardown.

All 21 parameters have labels and full Configurator descriptions. They use TepSound's names,
types, labels, groups, order and presentation defaults; the deliberate `protocol` default is the
new text demonstration. The parameters are `tmsStatus`, `protocol`, `seed`, `showStage`,
`fullscreen`, `screen`, `triggerBackend`, `triggerTarget`, `triggerInit`, `triggerMap`,
`triggerPulseMs`, `requireCharged`, `maxCoilTemp`, `tmsStaleMs`, `subject`, `condition`, `operator`,
`showUi`, `note`, `reloadProtocol`, and `pulse`. Backend order remains
`None, Serial, Transition, Parameter, UDP`; default None does not open a physical output.

`events` is a Resonance Message stream containing JSON session/run/plan/cue/pulse/response/note
records. Cue `rtc` equals the Resonance block's creation RTC. Pulse `dueRtc`/`frame` name the stage
boundary, while `sentRtc` records the later command dispatch; `fired` means the software accepted
the write, not that a physical edge was measured. Board timing reports `residualMs` separately.
`status` is Float64, eight channels at nominal 2 Hz: `engaged`, `running`, `paused`, `trial`,
`trials`, `droppedFrames`, `pulsesSkipped`, `triggerReady` (the manual connection's readiness).

This is deliberately TepSound's presentation feature set, not a drop-in implementation of the
old Stimulus rig manager. Old `stageScreen` becomes `screen`; `impedance`, `record`, `recordFile`
and `monitor_*` parameters do not exist. Start/configure amplifiers, recorder and analysis through
their own services. Import old protocol JSON to convert cues and schedule; inspect its warnings
and assign the intended trigger backend/target before saving `.tep.json`. Embedded legacy device
launch/orchestration is not carried across. The 18 Controls 1 `sp_*.qml` applications remain a
separate legacy project and still need Qt 5; this port does not make them load under Qt 6.

<a id="history-defects-found-and-repaired-in-both-active-services"></a>

### Defects found and repaired in both active services

- Stage visibility and photodiode updates now happen during `beforeSynchronizing`; onsets are
  announced before zero-offset pulses, using one swap timestamp. Preroll frames do not count as
  playback. Failed media does not generate an onset/pulse, and a stale render notification from
  a previous run cannot be attributed to the new one.
- End duration/response/triggers are honoured before a separate completion sentinel. Pause
  freezes pending triggers and media; repeated playback of one file starts at its seek-in point.
  Stop/reset clears stale layers and pending work, including when the window is hidden.
- Response conditions are actually applied; collected text supports editing/submission and
  reaction time starts at the presented cue. Auto-repeat is ignored on the subject screen.
- Failed loads retain the editable old document but block preparation until a valid load or New.
  Validation and authoring cannot re-enter one another through multimedia probe event loops.
  Preparing opens all required wires before the session/analysis worker becomes active.
- Trigger refusal is reported as failure, not success; a missing named wire has no fallback to a
  different output. Multiple background beats retain their own planned offsets. Board residual
  timing is carried into the serial command. Parameter-backend shutdown issues the pending LOW
  immediately and invalidates an earlier pulse timer.
- Invalid sequence constraints retain the previous valid value; the special Interval row can be
  read/edited/previewed; media packing is content checked and never deletes original media.
- TepSound accepts authored `.tep.json` through its protocol parameter/CLI. Its letter shortcuts
  no longer consume typed text or send P-trigger commands while a text editor has focus. Blank
  response choices now have readable display labels without changing their serialized strings.
- Pending text edits are committed before keyboard Start/Save and before selecting another cue.
  The trigger-map editor resynchronises with the parameter after an edit or external update.
  TepSound's row/problem selection also commits the old row before switching the editor's model.
- TepSound's QML windows now close before their service/model is destroyed; normal exit no longer
  re-evaluates the live console/stage bindings against a null service.
- Disconnecting the selected monitor stops a run and keeps a visible disconnected selection.
  Missing/nonfinite required stimulator telemetry fails closed rather than being treated as zero.

<a id="history-reproducible-software-validation"></a>

### Reproducible software validation

`R:\src\scripts\test-stimulus-presentation.py` launches deployed Stimulus and TepSound in separate
processes, presents generated text/PNG/440 Hz low-level WAV and the existing synthetic video
fixture, and uses only a loopback UDP echo peer. It records complete runs with `recorderService`,
checks cue/pulse order and timestamps from HDF5, End hold, repeated Start/Pause/Resume/Stop,
failed-load recovery, parameter locks and normal exits. It reads the Qt 5 contracts without
starting their presentation code, verifies the new 21-parameter TepSound subset, tests the launcher
from outside `R:\dist` with a Windows-only initial PATH, and hashes deployed binaries.

`test_StimulusPresentation` adds real Qt stage/media/controller tests for failure, queue reset,
onset-before-trigger ordering, pause/replay, authoring protection, safe packing, responses, failed
load recovery and rendering all console tabs. The complete Release build and all **34 enabled
CTest targets** pass; four existing physical/external tests remain disabled. The parameter audit
passes **315 parameters / zero missing descriptions**.

Evidence: `R:\src\docs\qa\stimulus-live-acceptance.json`, `stimulus-deployed-hashes.json`,
`stimulus-presentation-regression.txt`, `stimulus-ctest-release.log`, `stimulus-clean-release.log`,
and `stimulus-console-{1,2,3,4,compact}.png`. Detailed HDF5 fixtures stay in
`R:\src\_test-output\stimulus`, outside the distribution. Physical audio/photodiode/TTL onset,
serial hardware, remote amplifier commands, TMS interlocks on a real stimulator and monitor
hot-unplug still require operator acceptance. No physical trigger equipment was operated here.

---


<a id="history-historical-qt-5-audit-and-proposal-2026-08-to-2026-09-02"></a>

## Historical Qt 5 audit and proposal (2026-08 to 2026-09-02)

The sections below preserve the earlier measurements and legacy roadmap. Their unported status,
device orchestration and rig results describe the Qt 5 comparator; the current Qt 6 implementation
and its deliberately narrower presentation scope are documented above.


<a id="history-0-state-of-play--built-2026-08-16"></a>

## 0. State of play — built 2026-08-16

**Phase 0 and Phase 1 are done, built, deployed and measured.** The rest of this document is the
audit that led to them and the proposal for what follows; §6 carries the status of each phase.

| | |
|---|---|
| ✚ New module | `R:\src_Qt5\stimulusService` — `stimulusService.exe`, service name **`Stimulus`**, launcher `stimulusService.bat` |
| ✚ Brick library | `import/Resonance/Stim/` → `bin/Resonance/Stim/`, so `import Resonance.Stim 1.0` resolves from an ad-hoc `quickStimulus -l pilot.qml` too |
| ✚ Content | `stimuli/library.json` (one shared catalogue) + `stimuli/protocols/*.json` |
| ✚ Legacy, in git at last | `stimulusService/legacy/` — all 18 `sp_*.qml`, 15 `StimulusList_*.js` and the helper QML, with the four API breaks of §4.1 F1 repaired |
| Registration | one line, `add_subdirectory(stimulusService)` in `R:\src_Qt5\CMakeLists.txt` |
| Outside the module | one file: `quickStimulus/import/Resonance/Bricks/Head.qml`, repointed at `headValues()` |
| Built | MSVC v142 x64, deployed to `R:\dist_Qt5\msvc64` (the tree that was `R:\dist\msvc64` when this was written). ⚠ `mingw32`/`mingw64` have not seen it |
| Qt 6 | ~~⚠ **not ported.**~~ Ported 2026-09-06 as the native Stimulus service (the current sections above); the 18 legacy programs still cannot load under Qt 6 |

⚠ **The measurements below predate the 2026-08-18 rebuild**, and `stimulusService` was **not**
among the modules re-exercised in that acceptance ([network-isolation.md §8.1](../migrations/network-isolation.md)).
It opens no sockets of its own, so nothing in the isolation change reaches it directly — but it
has not been run on the current binary.

<a id="history-the-measurement-this-module-exists-for"></a>

### The measurement this module exists for

Nine trials of the acceptance protocol on a 144 Hz screen, driven over the EventBus and read back
off the `events` stream — every step's onset-to-onset interval against the duration the service
said it would deliver:

| | Legacy (`TimeoutTransitionPrecise`) | **`stimulusService`** |
|---|---|---|
| Mean lateness | 6.7 ms | **0.05 ms** |
| Worst case | 15.7 ms | **0.12 ms** |
| Dropped frames | not measurable — nothing counted them | **0** of 20 cue onsets |

The legacy figures are the `QTimer` measurements from
[known-issues §16d](../incidents/33-framework-traps-found-building-playbackservice-2026-08-15.md#history-16d-qtimer-cannot-pace-anything-finer-than-156-ms-on-windows);
the new ones are `R:\config\stim_acceptance.qml` against
`R:\config\stim_acceptance_protocol.json`. `test_StimulusSchedule` is **21/21**.

⚠ **This measures the software against itself.** It says the frame count is honoured and the
marker is stamped at the swap. It does *not* measure the constant offset between the swap and the
photons — one to two frames of compositor and panel latency, which only a photodiode can see. The
stage draws the patch (§5.4); the number is not taken yet.

<a id="history-the-test-campaign-2026-08-16"></a>

### The test campaign, 2026-08-16

Everything below was run on this PC against the hardware attached to it: a **Neuron-Spectrum-65**
and an **NVX136 media converter**. Both were released with `stop` → wait for `init` →
`!terminate` afterwards and both still enumerate `OK`.

| | What it proves | Result |
|---|---|---|
| **T1** legacy load | All 18 `sp_*.qml` load with zero QML errors. **With a control**: the *unfixed* copy still reports `Cannot assign to non-existent property "source"` at line 291, so the detector demonstrably catches the failure | **18/18** |
| **T2** recorder | `recorderService` configured over the EventBus, two slots filled, both streams in the file | events + `generated` (3001×3), **0 NaN** |
| **T3** NVX136 | Real amplifier: settings pinned, mode applied, waited for `running` *and* for the stream, recorded, stopped | `eeg` **4531×65, 0 NaN**, 12/12 trials |
| **T4** trigger | Hardware trigger codes read back out of the recorded trigger word | **12/12 pulses, codes in order** |
| **T5** modes | Impedance in and out on hardware; impedance **refused while recording**; pause/resume; stop mid-run → `idle` | **8/8** |
| **T7** NS-65 | A second amplifier on the *generic* profile, launched from absent by the service itself | `eeg` **11301×24, 0 NaN**, 9/9 trials |
| params | 20 parameters, 5 groups, every one an ASCII key with a type and an index; 13 carry tooltips | **PASS** |
| Configurator | The real Configurator renders the service | **zero QML errors** |
| **T6** toolchains | Builds under MinGW x86 **and** MinGW x64, not only MSVC | both **OK** — ⚠ historical: MinGW x64 parity stopped being a goal at the Qt 6 move, and MinGW x86 now serves only the KARDi2 island |
| unit | `test_StimulusSchedule` | **21/21** |

**Timing, measured out of the recordings rather than off the console:**

| | |
|---|---|
| Step error vs the duration the service said it would deliver | **mean −0.014 ms, max 0.192 ms** (n=25, generator) · **mean −0.016 ms, max 0.136 ms** (n=19, NS-65) |
| Dropped frames | **0** in every completed run |
| Block RTC == payload RTC | holds for every cue — the swap timestamp survives into the file |

**⚠ The number that matters for triggers.** Against the NVX136's own clock, the EventBus trigger
path lands **+57.5 ms after the marker, sd 7.3 ms, range +47 to +68 ms — 21.7 ms of spread**.
The codes and their order are exact; the *timing* is not, and that is the difference between
"the trigger works" and "the trigger is usable for an ERP". Use a TTL box on a COM port for
anything latency-sensitive; the service-mediated backends exist because two rigs depend on them.

Two measurement traps worth recording, because both produce a plausible wrong answer:

* **`created` timestamps a block's *last* sample, not its first** — `Float64::fromBinary` takes
  `RTC::now()` when the block is built, after its samples were collected. Reading it as the first
  sample put every trigger a whole block early and turned the number above into **+364 ms**.
* **The trigger word is a bitfield with a floating low byte.** The input reads `0xFF` with
  nothing wired to it and the mirrored output sits in the high byte, so looking for a rising edge
  from zero finds nothing at all. `0x04FF` is code 4.

<a id="history-eight-defects-the-campaign-found--none-of-which-reading-the-code-had"></a>

### Eight defects the campaign found — none of which reading the code had

| | |
|---|---|
| **The launcher had never worked** | `QProcess` cannot execute a `.bat` at all, and the name was resolved against `PATH` rather than the distribution root. It failed silently; the only symptom was a discovery wait expiring seconds later. T3 had *appeared* to exercise "launch if absent" only because `nvx136` happened to have been running for hours |
| **A remote `stop` left the recorder writing** | The teardown lived in the console's invokable, so a `stop` transition moved the state and nothing else — a 28 MB file still open and locked. Now on the way into `idle`, so every way of ending a session is the same way |
| **An always-on source waited forever** | `signalGenerator` has no state machine at all. Sending it `start` and waiting for `running` never returns. Whether a service must be started is now read from its own published transitions |
| **A pause was reported as 321 dropped frames** | The stage cannot tell a deliberate pause from a schedule that cannot keep up, and turned the one field that exists to be honest into a false alarm. It is told now — and the pause is recorded in the event stream, because a session with a pause in it is not the session the protocol describes |
| **One run produced two run records** | A completed run published `completed`, then fired `stop`, and the teardown published `stopped` for the same session |
| **The impedance check was unreachable** except from this service's own window — not from the Configurator, not from a script. Now an `Action`, which also cannot be replayed by loading a saved parameter set |
| **The generic discovery budget was 8 s**, too short for a launch of anything, let alone a driver that loads a .NET stack and a 59 MB signal runtime |
| **A refused prepare was silent** in a windowless service — the trigger port failing to open reached only a window nobody had open |

<a id="history-four-defects-the-acceptance-run-caught-that-reading-the-code-did-not"></a>

### Four defects the acceptance run caught, that reading the code did not

Recorded because each was silent, and three of them are shapes that recur in this tree:

| | |
|---|---|
| **Every cue was one frame too long** | A uniform **+6.94 ms** on a 144 Hz screen — exactly one frame. The countdown started after the frame that already showed the cue. A systematic bias, not jitter, and invisible without measuring against the requested duration rather than against a stopwatch |
| **`prepare` and `start` did nothing over the wire** | The work lived in the invokable the console button called, while the *transition* — the path a Configurator, a script and `--autoStart` all take — only moved the state. Both now do their work on the **state entry**, so no control path can diverge from another |
| **A readiness signal fired inside the state it was entering** | `DeviceController::ready()` completes synchronously when there is nothing to wait for, so it was emitted before the transition out of `preparing` existed. Now queued. Same shape as [known-issues §16a](../incidents/33-framework-traps-found-building-playbackservice-2026-08-15.md#history-16a-outputstreamready-fires-inside-the-constructor-on-the-main-thread--open) |
| **A fixed parameter default overrode the protocol** | `record` defaulted to true, so a protocol saying "do not record" hunted for a recorder that was never wanted. Loading a protocol now moves the parameter, which the operator may then override |

And two about the *harness*, not the product, both of which cost real time here:

* **`Parameters::File` stores a file's contents, not its path** — wrong type for "which protocol",
  and its `setText()`/`setBinary()` emit nothing, so even a local set notifies nobody. That is the
  silent-setter defect [§12a](../incidents/22-framework-defects-found-and-fixed-2026-08-12.md#history-12a-setvalue-notified-nobody) fixed for `Integer`,
  `Double`, `String` and `MultiLine` on 2026-08-12 and **still present on `File`**. The protocol
  reference is a `String`.
* **A running service holds its own `.exe`**, so a redeploy fails with access-denied — and with
  the copy's output redirected, several test rounds silently ran the *previous* binary. Stop the
  service, wait for the image to be released, and never hide a copy.

---

⚠ **Headline:** the legacy experiment GUIs **cannot run against `R:\src_Qt5` as it stands** — the
tree this was written against, then called `R:\src` — because the
2026-08-13 viewer rework removed three of the four APIs they are built on. Nothing was broken
carelessly; the old API was replaced by a better one and nobody re-pointed these files, because
they live in a distribution directory and not in git. This is
[deployed-vs-repo.md](../migrations/deployed-vs-repo.md)'s "the deployment drifts from the repo by design" trap,
in its most expensive form: **eighteen production experiment programs exist only outside version
control.** §5 lists the four breaks with file and line.

---


<a id="history-1-what-the-sp_-family-is"></a>

## 1. What the `sp_*` family is

**One program, copied eighteen times.** Not eighteen experiments — eighteen *snapshots of one
file*, each frozen at the moment somebody needed a different stimulus set.

Measured, not asserted. `diff sp_mipuzzleA.qml sp_mipuzzleB1.qml` is **one line**:

```diff
-import 'StimulusList_mipuzzleA1.js' as StimList
+import 'StimulusList_mipuzzleB1.js' as StimList
```

Same for `C1`. `A2`, `B2`, `C2`, `C2_male` and `D` add between 4 and 25 lines, all of them the
same two features (stop the video recorder on Stop; play a video clip for stimulus codes above
1000). The `EYELINK`, `MUMEG`, `quazi`, `maglev` and `OMPtest` branch differs by one checkbox and
by *deleting* the two-amplifier block. `wFlappy` adds a feedback game. That is the whole of the
variation across 560 KB of QML.

<a id="history-11-the-shared-skeleton"></a>

### 1.1 The shared skeleton

Every `sp_*.qml` is a single `ApplicationWindow` about 1 100 lines long, laid out like this:

```
┌─ operator window (1850x800) ─────────────────────────────────────────────┐
│ [Launch] [Stop rec] [EEG] [Impedance]  file:[______]  [(killNVX)]        │  ← device row
│ [ ]Fullscreen [Start stimulus] [Stop stimulus] [ ]EEG-first [ ]stop-rec  │  ← run row
│ ┌─ Stimuli settings ─┐ │ ┌ generated sequence ─┐ │ ┌─────────────┐       │
│ │ ISI min / max      │ │ │ Bricks.StimulusSelector│ Bricks.Head  │       │
│ │ duration / special │ │ │  (grid of images)    │ │ (impedance)  │       │
│ │ welcome / bye      │ │ │  [1 2 2 1 …]         │ └─────────────┘       │
│ ├─ Head settings ────┤ │ ├ Subject input ───────┤                        │
│ ├─ COM port settings ┤ │ │ TextArea (keystrokes)│                        │
│ └────────────────────┘ │ └──────────────────────┘                        │
│ ┌─ Plot.PlotView (EEG) ───────────────────────────────────────────────┐  │
│ └─────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
┌─ subject window (400x400, or fullscreen) ─┐
│  Bricks.StimulusDisplay  +  empty-image   │
└───────────────────────────────────────────┘
```

and one `QtQml.StateMachine` driving the trial loop:

```
welcome ──(welcomeDuration)──► stim ──(duration | specialDuration)──► rest
                                 ▲                                     │
             infStim ◄───────────┴─── (code in "infinite" set) ────────┤
                │ Space/Esc/`                                          │
                └──────────────────────────────────────────────────────┘
                                                    (seqId ≥ length) ──► byebye ──► finish
```

`finish` optionally switches the amplifier back to impedance mode and stops the recording.

<a id="history-12-the-five-axes-of-variation"></a>

### 1.2 The five axes of variation

| Axis | Values seen | Where it lives |
|---|---|---|
| Stimulus set | 15 different `StimulusList_*.js` | one `import` line |
| Amplifier wrapper | `RecordEegImpedance` (2×NVX), `…136` (NVX136), `…136wSpeed` (+SPEED), `…_4QZFM` (OPM) | one type name at the bottom of the file |
| Eye tracker | present / absent | one `Boolean` parameter + one checkbox + a `stop` on finish |
| Video | none / recorded via ffmpeg / played as stimulus | a commented-or-not `Video` block |
| Feedback | none / `FlappyBird2024` fed by a SPEED classifier stream | ~230 lines, `wFlappy` variants only |

<a id="history-13-the-eighteen-identified"></a>

### 1.3 The eighteen, identified

| File | Date | Stimulus set | Amplifier wrapper | What it is |
|---|---|---|---|---|
| `sp_mipuzzleA.qml` | 2021-06-23 | `mipuzzleA1` (45) | 2×NVX | Motor-imagery "puzzle" series — visual scene / eyes closed / tactile stim / hand-maze pictures / EOG calibration targets |
| `sp_mipuzzleA2.qml` | 2021-07-08 | `mipuzzleA2` | 2×NVX | A + stop the ffmpeg video recorder on Stop |
| `sp_mipuzzleB1.qml` | 2021-06-30 | `mipuzzleB1` | 2×NVX | A with another stimulus set |
| `sp_mipuzzleB2.qml` | 2021-07-08 | `mipuzzleB2` | 2×NVX | B1 + video-recorder stop |
| `sp_mipuzzleC1.qml` | 2021-07-07 | `mipuzzleC1` | 2×NVX | as B1 |
| `sp_mipuzzleC2.qml` | 2021-07-08 | `mipuzzleC2` (52) | 2×NVX | + **video-clip stimuli**: a code > 1000 is a seek position in seconds into `video_thumb.mp4` |
| `sp_mipuzzleC2_male.qml` | 2021-10-04 | `…C2_male` | 2×NVX | C2 with a male-actor clip set |
| `sp_mipuzzleD.qml` | 2022-08-10 | `mipuzzleD` (71) | 2×NVX | the largest hand/keyboard/text set |
| `sp_mipuzzleEYELINK_A.qml` | 2022-06-23 | `mipuzzleB1_eye` | NVX136 | same paradigm with an **EyeLink 1000**; the two-amplifier block is deleted |
| `sp_mipuzzleEYELINK_B.qml` | 2022-07-01 | `mipuzzleB1_eye` | NVX136 | as A |
| `sp_mipuzzleMUMEG_A.qml` | 2025-10-31 | `mumegA1` (41) | NVX136 | the puzzle paradigm run in an **MEG** room |
| `sp_quazi.qml` | 2022-07-01 | `quasi` (53) | NVX136 | "quasi-movement" paradigm; a percussion video clip |
| `sp_mimusic.qml` | 2025-10-31 | `mimusic` (81) | 2×NVX | **music imagery** — the stimulus is a seek position in a selectable music video on a second screen at `x: 2560`; adds a `Select` parameter for the file and a final trigger pulse pair |
| `sp_maglevP300.qml` | 2026-06-26 | `maglev` (39) | NVX136 | **P300** for a magnetic-levitation control task |
| `sp_OMPtest.qml` | 2024-03-11 | `mumegA1` | `…_4QZFM` | the same console driving four **QZFM OPM** sensors |
| `sp_OMPtest_wFlappy.qml` | 2024-03-19 | `mumegA1` | `…_4QZFM` | + the feedback game |
| `sp_GenericMI_wFlappy.qml` | 2024-03-19 | (generic) | `…136wSpeed` | **the most complete one** — motor imagery with online classifier feedback; the launcher in `dist2025` points here |
| `sp_testControls.qml` | 2022-12-25 | — | `…136` | a 300-line skeleton: the console with an empty state machine. Somebody's starting template |

⚠ `dist2025\stimulusPresentation52.bat` loads `sp_GenericMI_wFlappyNVX52.qml`, **which exists
nowhere on this drive**. The 52-channel launcher has been broken for as long as this copy is old.

<a id="history-14-the-supporting-cast"></a>

### 1.4 The supporting cast

| File(s) | What it is |
|---|---|
| `RecordEegImpedance.qml`, `…136.qml`, `…136wFeedback.qml`, `…136wSpeed.qml`, `…_4QZFM.qml` | The device orchestration state machine: open the HDF5 file, add the event stream, switch the amplifier between `Impedance` and `Normal`, add the data streams, emit a trigger pulse triple, and hold `running`. **This is where the recording lives.** |
| `StartBothNVX.qml`, `StartNVX136.qml`, `StartQZFM.qml` | Launch the amplifier `.exe` via `Process` if discovery does not already see it, then `rescan`/`device`/`mode`. |
| `StartSPEED4Flappy.qml` | Launches `SPEED4mulines1.bat`, waits 1 s + 3 s + 2 s, and calls the result configured. Every meaningful line inside it is commented out. |
| `StimulusList_*.js` × 15 | The stimulus catalogue: `{name, sname, code, img, col, row, text}` × 39–81 entries. Large commented-out regions are the real change history. |
| `FlappyBird.qml`, `FlappyBird_mod.qml`, `FlappyBird2024.qml` | The feedback game: a scrolling `Canvas` trace of one classifier channel, with target bars derived from the trial sequence. |
| `Bricks.StimulusDisplay`, `Bricks.StimulusSelector`, `Bricks.Head` | The only three components that are **in git**, under `quickStimulus/import/Resonance/Bricks/`. |
| `impedanceRecorder*.qml` × 8, `main.qml` (57 KB), `main — res.qml`, `main_tryFIX.qml` | The 2020 ancestors. `main.qml` is the monolith all of the above was cut out of. |
| `Pentagram.qml`, `StimGen.qml`, `TriggerLines.qml`, `Setup1.scxml`, `URI.js`, `doubleTrouble.qml` | 2020 experiments, orphaned. `Setup1.scxml` is the only use of the SCXML support in the plugin. |
| ~90 `.png`/`.bmp` | The stimulus images, referenced by relative path from the `.js` files. |

---


<a id="history-3-the-quickstimulus-qml-layer-today"></a>

## 3. The quickStimulus QML layer today

`quickStimulus.exe` is a thin QML runner (`--load <file.qml>`, or `--builtIn
configurator|recorder|generator`) plus `quickStimulusPlugin.dll`, which registers 30 types under
`import Resonance 3.0` (`resonanceqmlplugin.cpp:37`).

| Group | Types | State |
|---|---|---|
| App/service | `ResonanceApp` (singleton), `ServiceLocator`, `ServiceControl`, `ServiceInspector`, `StreamInspector`, `ParameterInspector`, `Process` | alive |
| Streams | `MessageSender`, `MessageReceiver`, `TimeSeriesSender`, `TimeSeriesReceiver`, `Recorder` | alive |
| Parameters | `Boolean`, `Integer`, `Double`, `String`, `MultiLine`, `Select`, `Stream`, `ChannelsList`, `Parameters` | alive; **`Action`, `File`, `BipolarChannelsList` have QML delegates but no registered type** |
| State machine | `WaitForServices`, `SetParameters`, `ServiceStoped`, `ServiceChangedState`, `TimeoutTransitionPrecise`, `SCXMLServiceHelper` | alive, **barely used** |
| Presentation | `Flicker`, `WindowControl`, `SerialPort` | alive, **`Flicker` unused by any shipped experiment** |
| Viewer | `Plot.PlotView`, `Plot.HeadView`, `Plot.Settings`, `ChannelPanel`, `PlotSettings` | alive, reworked 2026-08-13 |
| Bricks | `Bricks.StimulusDisplay`, `Bricks.StimulusSelector`, `Bricks.Head` | **`Head` is broken** (§5 F1) |
| Dead | `SignalView.qml`, `SignalPlot.qml`, `Configurator_normal.qml`, `ParamTabView.qml`, `plotrender.cpp` | present, not built or not referenced |

Two things worth knowing before building on it:

* **`Flicker` is the only frame-locked thing in the tree, and it is correct.** It counts frames
  in `updatePaintNode`, and stamps `Resonance::RTC::now()` inside a `frameSwapped` handler
  connected `Qt::DirectConnection` (`flicker.cpp:110-134`). That is exactly the right pattern for
  a visual-onset timestamp — and **no `sp_*` file uses it.**
* **`TimeoutTransitionPrecise` is a plain `QTimer`** with `Qt::PreciseTimer`
  (`timeouttransitionprecise.cpp:12`). Its name is a promise the platform does not keep — see F2.

---


<a id="history-4-findings"></a>

## 4. Findings

Severity is about consequence in a real session, not about how hard the fix is.

<a id="history-41-critical"></a>

### 4.1 Critical

**F1 — the whole `sp_*` family is dead against `R:\src_Qt5`** — the tree called `R:\src` when this
was written. Four breaks, all from the 2026-08-13/15 viewer rework:

| Legacy code | Where | Why it fails now |
|---|---|---|
| `TimeSeriesReceiver { source: param_impedance.stream }` | `sp_mipuzzleA.qml:288` | `TimeSeriesReceiver` has **no `source` property**; it takes `sourceInfo` (a `StreamInfo`), not an `InputStream*` |
| `Plot.PlotView { source: param_eeg.stream }` | `sp_mipuzzleA.qml:760` | same — `PlotView` exposes `sourceInfo` only (`PlotView.qml:21`) |
| `Plot.PlotView { settings: plot_settings_eeg }` | `sp_mipuzzleA.qml:766` | `settings` is now a **read-only alias to PlotView's own internal `Settings`** (`PlotView.qml:24`); assigning to it is an error |
| `Bricks.Head { signalSource: … }` | `sp_mipuzzleA.qml:736` | `Head.qml:28` reads `signalSource.lastValues`, a property that no longer exists → a JS TypeError **on every data block** |

Six of the eighteen (`EYELINK_*`, `MUMEG`, `quazi`, `maglev`, `OMPtest*`) already use
`sourceInfo` for the receiver, so they fail on three of the four rather than all four. None of
them runs.

⚠ **These files are not in git.** They exist in `R:\dist_legacy\stimulusPresentation` and in
scattered copies under `mipuzzle\`, `quasi\`, `test_this\`. A rebuilt distribution that replaces
a rig's tree takes the experiments with it.

**F2 — stimulus timing is quantised to the Windows tick, and the event marker does not
correspond to a frame.** Two independent problems, both invisible in the data:

* Every state duration is a `TimeoutTransitionPrecise`, i.e. a `QTimer`. Measured on this machine
  ([known-issues §16d](../incidents/33-framework-traps-found-building-playbackservice-2026-08-15.md#history-16d-qtimer-cannot-pace-anything-finer-than-156-ms-on-windows)):
  **6.7 ms mean, 15.7 ms max lateness**, unchanged by `timeBeginPeriod(1)`. A 400 ms stimulus is
  400–416 ms, varying trial to trial.
* The marker is sent from `onStimulusChanged` (`sp_mipuzzleA.qml:276-282`), which fires when the
  **QML property** changes — before layout, before render, before the swap. `MessageSender`
  stamps `RTC::now()` at that moment (`Message.cpp:51`). The picture reaches the subject's eye
  one to two frames later, and *the delay is not constant*: it depends on image decode, on
  whether the compositor was busy, and on the monitor.

For an ERP paradigm — and four of these are P300 or VEP — that is jitter added directly to the
component latency, on top of an unknown constant offset. It is the single most damaging finding
in this document, because nothing in the recording reveals it.

**F3 — recording orchestration is a chain of fixed sleeps.** `RecordEegImpedance136wSpeed.qml`
switches to impedance with `stop` → wait **7000 ms** → `start` → wait **3000 ms** → add streams.
The 2×NVX version uses 2000/750. These numbers were tuned against one amplifier on one PC. The
NVX136 `Start` was measured at **5.0 s** ([known-issues §14i](../incidents/README.md)) — so the 2000 ms
wait in `RecordEegImpedance.qml:106` has been racing the hardware for years and only ever worked
because the *next* wait absorbed it. `ServiceChangedState` and `WaitForServices` exist in the
plugin and are exactly the right tools; they are not used.

<a id="history-42-high"></a>

### 4.2 High

**F4 — eighteen copies, so a fix reaches one of them.** `stim_connection` is the proof: eight of
the eighteen are missing `enabled: false` on that `Connections` block, so in those eight **pressing
the `EEG` button starts the stimulus sequence**. The other ten were fixed. Nothing propagated.

**F5 — the parameter model is misused, so saved sessions are fragile.** Every setting is declared
as `Parameters::String` even when it is a number, so `sp_test.json` stores `"serialized": "35"`
for a percentage. Consequences: no range, no step, no validation, no unit; the Configurator draws
a text field for everything; all 30-odd parameters land in one `default` group.

Worse, **the parameter `name` — its wire identity — is a Russian UI label** (`'Индексы особых
стимулов'`). Editing the label to fix a typo silently orphans every saved configuration, because
`applyParameters` matches on `name`.

**F6 — absolute paths compiled into the experiment.** `D:\Resonance\...` in the launchers,
`R:\stimulusPresentation\video1.mp4`, `R:\VideoRecordings\`, `R:\mimusic\condaenv64\bin\`,
`"video=4K USB Camera"` as an ffmpeg device name. Moving a rig means editing QML.

**F7 — dead references that throw at the worst moment.** `sp_mipuzzleA.qml:944` calls
`video.start()` where `video` is inside a `/* … */` block — a `ReferenceError` the first time a
stimulus with code 444 appears, i.e. mid-session. (`Video` has `play()`, not `start()`, so it was
never right.) `sp_mipuzzleA.qml:1007` calls `stimSender.sendMessage(…)`; the id is `event_sender`.

**F8 — recording is done from inside the GUI process.** `Recorder {}` lives in
`RecordEegImpedance.qml`, so closing or crashing the experiment window takes the session with it.
[`recorderService`](recorder.md) was built precisely to end this and is not used here.

**F9 — Qt Quick Controls 1 throughout.** `import QtQuick.Controls 1.2` in every `sp_*` file and
in `StimulusSelector.qml`. Controls 1 does not exist in Qt 6; the viewer rework removed the
largest holdout ([signal-viewer.md §1](signal-viewer.md)), and this is the next one.

⚠ **2026-09-02: F9 is no longer a finding about future risk — it is the reason this whole family
stayed behind.** All 18 `sp_*.qml` also carry `import QtQuick.Controls.Styles 1.2`, and Qt 6.11.2
ships neither module, so none of the 18 loads under the Qt 6 `quickStimulus`. They are the one
item on the Qt 5 gap list with no cheap way out
([`arch_qt5-still-needed.md` §2](../migrations/qt5-still-needed.md)). `StimulusSelector.qml` is a separate
and smaller problem: it was copied into the Qt 6 tree unchanged and **installs into `R:\dist` with
its Controls 1 import intact**, where it cannot load — one of four such files, listed in
[`arch_qt6-work-list.md`](../migrations/qt6-work-list.md).

<a id="history-43-medium"></a>

### 4.3 Medium

**F10 — there is no experiment model.** No blocks, no conditions, no counterbalancing, no
practice phase, no per-trial response collection, no repeats, no "run trial 40 onwards after a
restart". A run is a flat list of indices typed into a text box, and the ISI randoms are drawn
once at `onStarted` (`sp_mipuzzleA.qml:865`) **with no seed recorded**, so a session cannot be
reproduced even by the person who ran it.

**F11 — no session metadata.** No subject id, no condition, no operator, no notes. The file name
is a free-text field, and what identifies a session is whatever somebody typed into it.

**F12 — no response collection worth the name.** Keystrokes during an infinite stimulus are sent
as `"32 :  "` strings on the event stream. There is no reaction time, no correctness, no response
window, no button box.

**F13 — the stimulus catalogue is JavaScript.** 15 `.js` files, each a `var listSource = [...]`
that a QML `import` evaluates. A typo is a load-time failure with a line number in a file the
experimenter did not know existed, and the edit history is preserved as commented-out blocks —
`StimulusList_mipuzzleA1.js` ships 45 entries of which **26 are commented out**.

**F14 — no validation and no error surface.** A missing image file draws nothing; a code in the
sequence that is not in the selection produces an empty `generated` array and a red square beside
the text field, and that is the whole of the feedback.

**F15 — `StimulusSelector` mutates its own model.** `generated` is a binding that reads
`selected` "as a hack to hook self to model change" (`StimulusSelector.qml:20`) and
`console.log`s the result on every re-evaluation. Selection is a plain JS array reassigned to
itself to force notification.

**F16 — triggers go over the network.** `nvx.sendParameter('trigger_state', true)` reaches the
amplifier through discovery, TCP and the EventBus, on a service that may be mid-`NVXGetData`.
It is used for cross-amplifier alignment, which is exactly the job that needs the *least* jitter.

**F17 — no way to see what happened.** No trial log in the UI, no progress indicator beyond the
picture on screen, no post-run summary, no count of delivered stimuli. The operator learns the
run finished because the Bye screen appears.

<a id="history-44-low-but-worth-fixing-while-nearby"></a>

### 4.4 Low, but worth fixing while nearby

* `import/Resonance/qmldir` lists `Resonance__Parameters__Text.qml`, which does not exist, and
  omits `Action`, `File` and `MultiLine`, which do. Harmless today only because `ParametersView`
  loads delegates by file URL (`ParametersView.qml:78`), not by type name.
* `Resonance__Parameters__Action.qml` is missing from `quickStimulus/CMakeLists.txt`'s source
  list; it ships only because `install_directory` copies the whole tree.
* `main.cpp:96-132` builds an immediately-invoked lambda around a `connect` that is commented
  out, catches QML warnings into a `wasErrors` flag, and then ignores it (`main.cpp:128-131`).
  A QML file with errors loads, prints "Warning rized", and runs half-initialised.
* Three `FlappyBird*.qml` differ by whitespace and one constant.
* `sp_*` windows carry hardcoded geometry (`width: 1850`, `x: 2560`) that assumes one rig's
  monitor layout.

---


<a id="history-5-what-the-replacement-should-be"></a>

## 5. What the replacement should be

<a id="history-51-a-service-not-a-script"></a>

### 5.1 A service, not a script

The legacy experiments are `.qml` files handed to a generic runner. That was the right call in
2020 and is the wrong one now, for three reasons the tree has since demonstrated:

* [`recorderService`](recorder.md) and [`playbackService`](playback.md) both show
  the shape that works — **one process, one service, parameters and a state machine visible to
  every client**, with its own window as a *view* rather than as the owner of the state.
* A `--load`ed file cannot be discovered, cannot be configured before it starts, and disappears
  from the Configurator's service list the moment it crashes.
* Eighteen copies of a program is what happens when the program is a file rather than a product.

So: **the paradigm becomes data, and the program becomes a service that reads it.**

<a id="history-52-proposed-layout-and-names"></a>

### 5.2 Proposed layout and names

Recommended — one new top-level module, mirroring `recorderService`/`playbackService`:

```
R:\src\stimulusService\
    main.cpp                       QApplication + ResonanceApp, --protocol, --autoStart
    service.{hpp,cpp}              parameters, state machine, event/status streams
    protocol.{hpp,cpp}             the protocol document: parse, validate, resolve assets
    schedule.{hpp,cpp}             blocks/trials/randomisation — pure arithmetic, unit tested
    stage.{hpp,cpp}                QQuickItem: frame-locked presentation + onset stamping
    triggerout.{hpp,cpp}           COM / parallel / service-parameter trigger backends
    ui/                            operator console QML (in res.qrc)
        Console.qml  RunBar.qml  ProtocolPane.qml  DevicePane.qml  TrialLog.qml
    stage/                         subject-window QML (in res.qrc)
        Stage.qml  ImageCue.qml  TextCue.qml  VideoCue.qml  AudioCue.qml
        FixationCross.qml  PhotodiodePatch.qml  FeedbackGauge.qml
    import/Resonance/Stim/         the public QML brick library — installed to bin/Resonance/Stim
        qmldir  StimulusDeck.qml  SequenceEditor.qml  CueLayer.qml  ProgressRibbon.qml
    protocols/                     shipped example protocols (JSON) — see §5.10
    tests/                         schedule_test.cpp, timing_probe.cpp, harness .qml files
    stimulusService.bat
    CMakeLists.txt
```

Two names to decide, and the alternatives:

| | Recommended | Alternatives | Why the recommendation |
|---|---|---|---|
| Module / executable | **`stimulusService`** → `stimulusService.exe`, service name **`Stimulus`** | `experimentService`, `paradigmService`, `presentationService` | Continues the legacy name operators already say ("stimulusPresentation"), and matches `recorderService` / `playbackService` exactly. `experiment` overclaims — this presents stimuli and marks events; it does not own the experiment |
| QML import | **`Resonance.Stim 1.0`** | `Resonance.Stimulus`, `Resonance.Experiment` | Short at the call site (`Stim.StimulusDeck`), parallel to the existing `Resonance.Plot` / `Resonance.Bricks` |

The brick library lives **inside the new module**, installed with `install_directory(… bin
import/Resonance)` into the same `bin/Resonance/` root the plugin already uses. So
`import Resonance.Stim 1.0` resolves with no change to `quickStimulus`, and an ad-hoc
`quickStimulus.exe -l my_experiment.qml` file can still use every brick — which keeps the escape
hatch the lab actually relies on for one-off pilots.

Only three small changes land outside the new directory:

1. `add_subdirectory(stimulusService)` in `R:\src\CMakeLists.txt`.
2. `quickStimulus`: new C++ types that are genuinely generic — `FrameClock`, and a fixed
   `Bricks/Head.qml` (or its retirement in favour of `Plot.HeadView`).
3. `Bricks/StimulusDisplay.qml` and `StimulusSelector.qml`: keep as-is for the legacy files,
   mark superseded in `Bricks/qmldir`.

<a id="history-53-the-protocol-is-a-document-not-a-program"></a>

### 5.3 The protocol is a document, not a program

One JSON file per paradigm replaces `StimulusList_*.js` **and** the eighteen `sp_*.qml`.

```jsonc
{
  "v": 1,
  "name": "miPuzzle A",
  "screen": { "background": "#000000", "fixation": "cross", "photodiode": "bottom-right" },

  "cues": {
    "scene":      { "kind": "image", "src": "img/rm6.png",  "label": "зрительная сцена" },
    "eyesClosed": { "kind": "image", "src": "img/ce.png",   "label": "закрытые глаза" },
    "beep":       { "kind": "audio", "src": "snd/440.wav" },
    "clip":       { "kind": "video", "src": "vid/thumb.mp4", "from": 12.5, "for": 4.0 },
    "typing":     { "kind": "text",  "text": "Наберите текст", "collect": "freeText" }
  },

  "trials": {
    "imagery":  { "cue": "scene",      "duration": 3000, "marker": 20, "trigger": 4 },
    "rest":     { "cue": "eyesClosed", "duration": 400,  "marker": 3 },
    "openEnded":{ "cue": "typing",     "until": "key:Space", "marker": 900 }
  },

  "blocks": [
    { "name": "practice", "repeat": 2,  "order": "fixed",    "trials": ["imagery", "rest"] },
    { "name": "main",     "repeat": 20, "order": "shuffled", "trials": ["imagery", "rest"],
      "isi": { "min": 800, "max": 1500, "distribution": "uniform" } }
  ],

  "welcome": { "cue": "welcomeScreen", "duration": 3000 },
  "goodbye": { "cue": "byeScreen",     "duration": 3000 }
}
```

What this buys, item by item against §4.3:

* **Assets resolve relative to the protocol file** — F6 gone. An absolute path is still accepted;
  a missing file is a *load-time* error with the offending key, not a blank screen (F14).
* **Blocks, repeats and orders exist** — F10 gone, and counterbalancing is a field rather than a
  new copy of the program.
* **The RNG seed is a parameter**, recorded in the session header. Re-running the same protocol
  with the same seed produces the same order.
* **`marker` and `trigger` are separate**: what goes on the event stream, and what goes on the
  hardware trigger line. Today the code doubles as both and as the image index.
* **`until`** generalises the "infinite stimulus" hack: `key:Space`, `response`, `timeout:8000`,
  `service:SPEED/state=ready`.
* **`collect`** generalises the subject-input `TextArea` into a typed response.
* Validation is one schema check with a line number, and the *editor* in the console writes it.

The 15 `.js` catalogues convert mechanically; §5.10.

<a id="history-54-timing--the-part-that-has-to-be-right"></a>

### 5.4 Timing — the part that has to be right

Four mechanisms, in the order they matter:

1. **The stage is frame-locked.** `Stage` is a `QQuickItem` that advances its cue schedule inside
   `updatePaintNode` and stamps `RTC::now()` in a `frameSwapped` handler connected
   `Qt::DirectConnection` — the pattern `Flicker` already proves (`flicker.cpp:110-134`).
   Durations are expressed in **frames** internally, derived from the screen's actual refresh
   rate, so a 400 ms cue at 60 Hz is 24 frames, every trial, instead of 400 ms ± 16.
2. **The marker carries the swap timestamp, not the property-change timestamp.**
   `MessageSender::sendMessage(text, timestamp)` already takes an explicit RTC
   (`messagesender.cpp:22`); the legacy code just never passes one.
3. **A photodiode patch** is a first-class option: a small high-contrast square in a screen
   corner that inverts with each cue, so the true photon time is *in the recording* on an AUX
   channel and the software's own estimate can be checked against it rather than trusted.
4. **Hardware trigger out**, in this order of preference: a parallel/USB-TTL line or the existing
   `COMport` service; the amplifier's own trigger input; and only as a last resort the
   `trigger_state` parameter the legacy files use (F16), which stays supported because two rigs
   depend on it.

Plus a **latency self-test** shipped in the module: run 500 cues against a photodiode into an AUX
channel and report the distribution of (photodiode edge − marker RTC). That number belongs in
this document once measured, exactly as the playback module's pacing table does
([playback-service.md §6](playback.md)).

⚠ Frame-locking bounds jitter to one frame; it does not remove the **constant** offset (typically
one to two frames of compositor and panel latency). Only the photodiode measures that, and only
the measurement makes an ERP latency defensible.

<a id="history-55-events-and-recording"></a>

### 5.5 Events and recording

One `Message` stream, JSON, `v: 1` — the schema convention `recorderService` and `neuroMS`
already use, so the analysis side has one shape to learn:

```json
{"v":1,"type":"session","protocol":"miPuzzle A","subject":"S07","seed":48211,
 "rtc":"620365234496600","wall":"2026-08-15T11:17:32.917","screen":{"hz":60.0,"size":[1920,1080]}}

{"v":1,"type":"cue","event":"onset","trial":41,"block":"main","cue":"scene",
 "marker":20,"rtc":"620371000112300","frame":143201,"lateFrames":0}

{"v":1,"type":"cue","event":"offset","trial":41,"marker":20,"rtc":"620371400118800"}

{"v":1,"type":"response","trial":41,"key":"Space","rtc":"620371233000000","rtMs":232.9}

{"v":1,"type":"run","event":"finished","trials":420,"droppedFrames":3}
```

* `lateFrames` and `droppedFrames` are the honesty fields: if a cue missed its frame, the
  recording says so instead of the analysis assuming it did not.
* The legacy plain-integer messages stay available behind a `markerFormat: "legacy"` option, so
  existing analysis scripts keep working during migration.

**Recording goes to [`recorderService`](recorder.md)**, not to an in-process `Recorder`
(F8). ⚠ It must be configured **one parameter at a time over the EventBus**, not from a saved
file — `applyParameters` screens names before applying, so a config that raises `streamsCount`
cannot fill the slots it just created
([known-issues §16b](../incidents/33-framework-traps-found-building-playbackservice-2026-08-15.md#history-16b-applyparameters-screens-names-before-it-applies-anything--fixed-2026-08-22)).
`ServiceControl::sendParameter` is the supported path and is what the playback harness does.

<a id="history-56-device-orchestration-without-sleeps"></a>

### 5.6 Device orchestration without sleeps

A small declarative device plan in the protocol, executed by waiting for observable state rather
than by counting seconds (F3):

```jsonc
"devices": [
  { "service": "NVX136", "role": "eeg",
    "launch": "NVX136.bat",
    "impedanceMode": { "mode": "Impedance" },
    "acquireMode":   { "mode": "Normal", "samplingRate": 1000, "blockSize": 100 } },
  { "service": "EyeLink", "role": "gaze", "stopOnFinish": true }
]
```

`WaitForServices`, `ServiceChangedState` and `SetParameters` are already registered in the plugin
and are exactly these primitives. The rule to hold to throughout: **wait for the state, with a
timeout that reports what it was waiting for** — never a bare sleep. And the tree's standing rule
survives unchanged: send `stop`, wait for `init`, only then `!terminate`
(STATUS.md ([change history](../changes/README.md))); killing an amplifier mid-acquisition wedges the device until it is
replugged.

<a id="history-57-the-operator-console"></a>

### 5.7 The operator console

One window, three columns, one persistent run bar. The organising idea is that **the operator
should be able to answer "is this session going to be usable?" without looking anywhere else** —
which today means the Configurator, the console and the subject screen at once.

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│  ● Stimulus   miPuzzle A   S07 · run 3        [ Impedance ] [ Prepare ] [▶ Start ]  │ run bar
│  ────────────────────────────────────────────────────────────────────────────────  │
│  block main · trial 41/420 ██████████░░░░░░░░  9:12 elapsed · 14:31 left            │
├──────────────────┬──────────────────────────────────┬──────────────────────────────┤
│ PROTOCOL         │ MONITOR                          │ SESSION                      │
│                  │                                  │                              │
│ ▸ miPuzzle A     │   ┌────────────┐  ┌───────────┐  │  subject   [S07________]     │
│   cues      12   │   │  head map  │  │  next cue │  │  condition [A ▾]             │
│   blocks     3   │   │ impedance  │  │  preview  │  │  operator  [AV_______]       │
│   trials   420   │   └────────────┘  └───────────┘  │  seed      [48211] [🎲]      │
│                  │   ┌──────────────────────────┐   │  file  data\S07_A_$$$$.h5    │
│ [sequence strip] │   │  EEG traces (PlotView)   │   │                              │
│  ▓▓░▓░░▓▓░▓░▓▓   │   └──────────────────────────┘   │  DEVICES                     │
│                  │                                  │  ● NVX136   running 1 kHz    │
│ [Edit] [Reload]  │   TRIAL LOG                      │  ● Recorder recording 412 MB │
│ [Validate ✓]     │   41 imagery  20  +0.3 ms  ⏎232  │  ○ EyeLink  not found        │
│                  │   40 rest      3  +0.0 ms        │  ● Trigger  COM3 open        │
└──────────────────┴──────────────────────────────────┴──────────────────────────────┘
```

Design rules, each answering a specific legacy failure:

| Rule | Replaces |
|---|---|
| **The run bar is always visible and always says what will happen next.** Start is disabled with a *reason* on hover, never silently | F4's start-by-accident, and the seven interlocked `enabled:` expressions in `sp_*.qml:451` |
| **Every device is a row with a state, not a button that might work.** Colour = discovered/running/absent | `(killNVX)` and the guesswork around it |
| **The trial log is live**, one line per trial, with the frame lateness and the response | F17 |
| **The sequence strip** shows the whole run as a coloured strip with a cursor: past, current, remaining, and where the blocks divide | the `"1 2 2 1"` text field |
| **Protocol errors appear in the protocol pane with the offending key**, before Start is offered | F14 |
| **Qt Quick Controls 2, compact metrics**, the same density work the viewer already did — replace the control *background* to get below the 40 px floor ([signal-viewer.md §11](signal-viewer.md)) | Controls 1, F9 |
| **One label column width for the whole app**, pinned min == max | the per-tab drift fixed in [known-issues §14l](../incidents/24-defects-found-and-fixed-2026-08-15.md#history-14l-the-parameter-panel-sized-its-label-column-per-tab---fixed-2026-08-15) |
| **Dark neutral console, subject screen strictly separate.** The console never determines what the subject sees; the stage is driven only by the protocol | the legacy console and subject window sharing one property (`stimulusPresentation.stimulus`) |

**Keyboard first**, because the operator's hands are often not on the mouse: `Space` start/pause,
`Esc` abort with confirmation, `I` impedance, `P` prepare, `←/→` step trial while paused,
`N` note (an annotation into the event stream, the `recorderService` gesture).

<a id="history-58-the-subject-stage"></a>

### 5.8 The subject stage

A separate window, and deliberately austere:

* **Screen and geometry are parameters**, not constants — pick the display by name, fullscreen by
  default, and refuse to start if the chosen screen is missing rather than opening at `x: 2560`
  on a one-monitor rig (F6).
* **Background luminance is set by the protocol**, and the fixation cross is a first-class cue —
  today "empty screen" is an image file called `empty.png`.
* **Images are pre-decoded and pre-uploaded** at Prepare, so the first frame of a cue is not the
  frame that decodes a 200 KB BMP. This alone removes a per-trial jitter source the legacy files
  have no defence against.
* **One cue layer per kind** — image, text, video, audio, and a `FeedbackGauge` for the online
  classifier — all switched by the same schedule, so adding sound to a paradigm is a protocol
  edit, not a new `sp_` copy.
* **The photodiode patch** is drawn by the stage itself, always in the same place, and excluded
  from any scaling.

<a id="history-59-parity-map--where-each-2-item-lands"></a>

### 5.9 Parity map — where each §2 item lands

| §2 | Capability | In the new module |
|---|---|---|
| 1–3 | image / text / blank cues | `ImageCue`, `TextCue`, protocol `screen.background` |
| 4 | per-class durations | per-*trial* `duration`; no index-list side channel |
| 5–6 | infinite cue + typed input | `until: "key:Space"` + `collect: "freeText"` → `response` event |
| 7 | welcome / bye | `welcome` / `goodbye` blocks |
| 8–9 | video-clip and second-screen media | `VideoCue` with `from`/`for`; screen chosen by parameter |
| 10 | fullscreen | stage parameter, default on |
| 11–12 | sequence and selection | `blocks` + the sequence strip and protocol editor |
| 13 | random ISI | `isi` with distribution **and a recorded seed** |
| 14–16 | launch/configure/two amplifiers | `devices[]`, state-driven, N amplifiers not 2 |
| 17 | trigger pulses | `triggerout` backends, TTL preferred |
| 18 | COM stimulator | `triggerout: serial` with a per-cue command map |
| 19 | EyeLink stop | `devices[].stopOnFinish` |
| 20 | ffmpeg video recording | `devices[].process`, arguments in the protocol |
| 21 | kill services | device row action, `stop` → wait `init` → `!terminate` |
| 22 | event stream | §5.5, JSON with RTC and frame number |
| 23–25 | HDF5 recording | delegated to `recorderService`, configured over the EventBus |
| 26 | impedance head map | `Plot.HeadView` — already better than `Bricks.Head`, and not broken |
| 27 | EEG traces | `Plot.PlotView` |
| 28 | parameters / saved config | typed parameters, ASCII names, grouped in index bands |

<a id="history-510-beyond-parity--what-is-worth-adding"></a>

### 5.10 Beyond parity — what is worth adding

Ordered by how much a session gains:

1. **Measured timing**, per §5.4: frame-locked onsets, swap-stamped markers, a photodiode option,
   and `lateFrames` in the record.
2. **Reproducible runs** — seed, protocol hash and asset checksums in the session header.
3. **Resume after a crash**, from the last completed trial.
4. **Pause / step / re-run trial** while paused, so a bad trial can be repeated instead of lost.
5. **A dry-run mode** that plays the whole protocol with no devices, at N× speed, for checking a
   paradigm before the subject arrives.
6. **A protocol editor in the console** — cue catalogue with thumbnails, drag to build blocks,
   live validation — so the experimenter never opens a `.js` file again.
7. **Response collection**: keys, mouse, button box, with reaction time relative to the *swap*.
8. **Live feedback as a component** (`FeedbackGauge`), fed by any Float64 stream — the Flappy
   game becomes one skin of it rather than 230 pasted lines.
9. **SSVEP via `Flicker`**, which already exists, is frame-exact, and has never been used.
10. **An `annotations` gesture** — one key, one line into the record — matching the recorder's.
11. **A session summary** written beside the HDF5: counts per condition, timing histogram,
    dropped frames, device states.
12. **Trigger-latency self-check** offered before every session, not just at commissioning.
13. **A tray/status strip** like `recorderService`'s, so a fullscreen stage does not hide whether
    the run is still alive.
14. **Localisation done properly** — Russian is the operator language and belongs in `.ts`
    translation files, not in parameter identities (F5).

<a id="history-511-migration"></a>

### 5.11 Migration

Nothing is thrown away, and no rig changes on the day of a deployment:

1. **A converter** (`tools/sp2protocol.py`) reads a `StimulusList_*.js` plus its `sp_*.qml` and
   emits a protocol JSON: catalogue entries become `cues`, the special/infinite index lists
   become per-trial durations and `until` clauses, the SpinBox defaults become block timings.
   All 15 catalogues are mechanical; the five feature axes (§1.2) are flags.
2. **The legacy files keep working** in parallel, because `quickStimulus -l` is untouched — but
   they need the four F1 fixes first, which is a ~10-line patch each and should be applied to
   the copies **in git**, not in a distribution.
3. **Bring the experiments into version control.** `R:\src\stimulusService\protocols\` for the
   converted ones, and a `legacy/` folder for the `sp_*.qml` as found, so that the drift
   [deployed-vs-repo.md](../migrations/deployed-vs-repo.md) warns about stops here.
   ⚠ **2026-09-02: done, but in the other tree.** The `legacy/` folder exists at
   `R:\src_Qt5\stimulusService\legacy\` (44 files, 28 899 lines) — and `R:\src_Qt5` holds the
   project's only git history (the checkouts under `R:\src_git_branches\` are worktrees of it).
   `R:\src`, the Qt 6 default tree, has **no** git, so putting a file there is not putting it
   into version control — [`arch_qt6-work-list.md` §5](../migrations/qt6-work-list.md).
4. **Validate against a recording**, not against a screenshot: replay a legacy session with
   [`playbackService`](playback.md), run the same protocol under the new module, and
   compare marker spacing and counts.

<a id="history-512-tests"></a>

### 5.12 Tests

The pattern the rest of the tree uses, and it applies cleanly here:

| Target | Needs | What it covers |
|---|---|---|
| `test_StimulusSchedule` | nothing | block expansion, repeats, shuffles with a fixed seed, ISI draw, `until` resolution, resume-from-trial arithmetic |
| `test_Protocol` | nothing | schema validation, asset resolution, every rejection message |
| `stimulus_timing_probe` | a screen | frames per cue against requested duration; run at 60/120/144 Hz |
| harness `.qml` | a running service | drive Prepare → Start → pause → abort through the real console and assert the event stream |
| photodiode acceptance | amplifier + photodiode | the number from §5.4, into this file |

`qmllint` does not resolve types — launch the QML before believing a lint pass
([signal-viewer.md §10](signal-viewer.md)).

---


<a id="history-6-phasing"></a>

## 6. Phasing

| Phase | Content | Status |
|---|---|---|
| **0** | Un-break the legacy: fix F1's four API breaks in the eighteen files, put them in git under `stimulusService/legacy/` | ✅ **done** — 44 files imported, fixes verified by diff against the originals |
| **1** | Module skeleton: `stimulusService.exe`, parameters, state machine, event stream, `Stage` with frame-locked timing, image/text/blank cues, seeded schedule | ✅ **done** — a protocol runs end to end, ±0.12 ms, 21/21 unit tests |
| **2** | Operator console: run bar, device pane, trial log, sequence strip, cue picker, monitor pane reusing the real `StreamView` | ✅ **done** — loads clean, no QML errors. ⚠ exercised by launching, **not** by an operator |
| **3** | Device plan, `recorderService` integration, trigger backends, photodiode + the measured latency number | ⏳ **written, unexercised** — no amplifier, recorder or COM port has been driven through it yet |
| **4** | Video/audio cues, responses, feedback gauge, `Flicker`/SSVEP | ⏳ responses and the `until` path are built and tested by schedule; video/audio/feedback are not |
| **5** | Protocol editor, converter, all 15 catalogues migrated, dry run, resume | ⏳ not started. The picker shows and previews the library; it does not yet write a protocol |

<a id="history-what-is-still-not-verified"></a>

### What is still not verified

Shorter than it was, and stated plainly because the rest of this section reads like completion:

* **No photodiode.** The stage draws the patch and the option works, but the constant offset
  between the swap and the light — one to two frames of compositor and panel latency — has not
  been measured. Everything above measures the software against the amplifier's clock, which
  bounds the *jitter* and says nothing about that offset.
* **The serial trigger backend has never fired.** This machine has one COM port and it is a
  Bluetooth modem. Only the two service-mediated backends were exercised, and the measured
  +57.5 ms is the reason the serial one exists.
* **The console has not been operated by a person.** Everything was driven over the EventBus,
  which is the stricter path — but no one has clicked the buttons, dragged a stream onto the
  monitor pane, or used the cue picker in anger.
* **A response trial (`until: "key:Space"`) has not been answered by a keypress.** The schedule
  side is unit-tested and the plan carries it; the input path is not exercised.
* **`nvx` (NVX-52) is untested** — it was not attached. Only `nvx136` and `neuronSpectrum` were.
* **The MinGW builds compile but were not deployed or launched.** A compile is not a build.
  ⚠ Historical, and it will stay unresolved: there are no MinGW x64 distributions any more, and
  `R:\dist_Qt5\msvc64` is the only tree this module ships in.
* **Nothing here has been compiled by MSVC v143 or run under Qt 6.** Every measurement in §0 and
  every result in the table above is a Qt 5.15.2 / v142 number. The 0.05 ms stage figure is the
  one that has to be re-earned first, because Qt 6's render loop is what it measures.
* **Video, audio and feedback cues do not exist yet** (Phase 4), nor does the protocol editor
  (Phase 5). The picker shows and previews the library; it does not write a protocol.

Phase 0 is worth doing first and separately whatever is decided about the rest: it is small, it
restores something that is currently broken, and it puts eighteen production programs under
version control.

---


<a id="history-7-decisions-needed-before-phase-1"></a>

## 7. Decisions needed before Phase 1

1. **Module and import names** — `stimulusService` / `Resonance.Stim`, or one of the
   alternatives in §5.2.
2. **Is `--load` support a requirement going forward?** Keeping it costs nothing and preserves
   the pilot workflow; dropping it would let the brick library be simpler.
3. **Which rigs must keep working unchanged**, and for how long — that decides whether the legacy
   marker format is the default or the option.
4. **Is a photodiode available**, on which rig? Without one, §5.4's constant offset stays an
   estimate and this document should say so.
5. **Qt 6.** Everything proposed here is Controls 2 and Qt 6-ready. If Qt 6 is a live direction
   (`questions-for-author.md` (on the lab drive, `R:\docs\_notes\`) Q2), the new module can be the first
   thing built to compile under both.

   ⚠ **2026-09-02 — decision 5 is closed.** Qt 6.11.2 is the default: `R:\src` and `R:\dist`. It
   is not a direction to choose, it is where the module gets built, and "compile under both" is
   no longer a requirement — `R:\src_Qt5` keeps the Qt 5 half. The proposal's Controls 2 claim
   survived contact with the real port: 52 % of the module's C++ compiles under Qt 6 today
   byte-identically, and its 1 620 QML lines are Controls 2 already. What the port produced that
   this proposal was written without is measured Controls 2 density. Controls 2 floors every
   control at 100×40 px through its *background* ([architecture.md §9a](../migrations/framework-evolution.md)),
   and the ported consoles land at 18 px service and channel rows, 13 px check marks, 24 px
   bipolar rows and a 200 px service pane against that floor
   ([`build_qt5-to-qt6-transition.md`](../migrations/qt5-to-qt6-transition.md)). §5.7's console layout
   should be checked against those numbers before it is built. Decision 3 — which rigs must keep
   working unchanged — is the one that is now load-bearing; see the box at the top of this
   document.
