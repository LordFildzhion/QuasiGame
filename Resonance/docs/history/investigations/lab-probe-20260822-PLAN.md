# Lab probe, 2026-08-22 — plan — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../issues/README.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-lab-probe-2026-08-22--plan"></a>


What is being tested at the rig, in what order, what each test proves, what the numbers should be,
and how to tell the five different meanings of "the TMS did not fire" apart.

**Prompt for the lab session:** `R:\config\lab\LAB_PROMPT.md`
**Toolkit:** `R:\config\lab\` — copy the whole folder to the lab PC.

> ## ⭐ STATUS CHANGE, 2026-08-22 15:45 — the headline bug is FIXED
>
> The trip was planned to *diagnose* why tepSound could not fire the TMS. That diagnosis was
> completed by reading, the fix was written, byte-proved without a board, built and deployed, and
> the trip's Job 1 is now **verification against real hardware**. Full account:
> `field-bugs-20260822.md` § *Item 10*. Snapshot to carry: **`resonance_20260822b.zip`** — the
> earlier `resonance_20260822.zip` predates the fix.
>
> Sections 4, 5 and 10 below are annotated rather than rewritten: what the lab now *adds* is a
> confirmation and, if it still does not fire, a fault-tree branch. The plan's original reasoning
> is kept because it is what the fault tree is made of.

> ## ⭐ THE TRIP HAPPENED. CORRECTIONS FROM THE RIG, 2026-08-22
>
> Full account: `R:\tests\lab-session-20260822\REPORT.md`. **The trigger fix is CONFIRMED on
> hardware** — tepSound armed on COM8 and all three commanded pulses discharged the coil.
> Five assumptions in the plan below were wrong on this rig and are corrected here rather than
> silently edited out, because the plan is what the fault tree is made of:
>
> | the plan says | the rig says |
> |---|---|
> | the A16 parameter is `tms/tmsStatus` | it is **`input/tmsStatus`**. The only `tms/*` parameters are `maxCoilTemp`, `requireCharged`, `tmsStaleMs` |
> | firmware **v2.3** | **v2.2**. The pin map and grammar matched, with one difference: `1=OUT,LOW` answers `ERR unknown` — **channel 1 has no role command**, D9 is a permanent output |
> | the extra Arduino→NVX lead should go on **bit 3** | it was **already fitted, on bit 1**. The pair is **`--pair 1:0`**, never `3:0`. Verified with the TMS in standby: 4 channel-1 pulses → 4 rising / 4 falling on bit 1, resting HIGH, 1.480 ms wide |
> | idle word `0x0000FFFA` | **`0x0000FFFE`** with the TMS on, **`0x0000FFFF`** in standby. The difference is bit 2. **Bit 0's rest level tells you whether the stimulator is powered** |
> | — | ⚠ **`svc.parameters` read within ~1 s of `sendParameter` returns the STALE value**, indistinguishable from a silent refusal. Wait ~3 s before believing a read-back. It cost one wrong conclusion |
>
> ⭐⭐ **And the number that governs every trigger run on this rig: the TMS Trig-Out pulse is
> 120 µs wide** (median 0.120 ms = 3 samples at 25 kHz, min 0.080, sd 0.017) **and the NVX136
> driver has no edge-latch mode, only level sampling.** At 1 kHz a 120 µs pulse is caught ~12 %
> of the time — the session saw **1 of 8**; at 25 kHz, **4 of 4**. **Every trigger or latency
> campaign on this rig must run at 25 kHz. A null or short count on bit 0 at 1 kHz means nothing.**

---


<a id="history-1-what-the-trip-is-for"></a>

## 1. What the trip is for

Three things, in priority order.

1. **The headline bug — now: confirm the fix.** ~~tepSoundService cannot fire the TMS through the
   Arduino on COM8; manual operation of the same port can. Establish the cause at the byte level,
   and decide whether it is fixable by configuration there or needs a source change here.~~
   **Answered: it needed a source change, the change is made, and the build being carried contains
   it.** The lab's job is to **prove the coil actually fires** with the fixed service, and to
   confirm the four secondary fixes — the `ID?` handshake against a Nano's DTR reset, no port close
   on a parameter edit, `S` on Stop, and an unmapped code sending nothing. If it still does not
   fire, `LAB_PROMPT.md` §7.5 is a fault tree; the branch it lands on is the deliverable.
2. **Two latency numbers no other machine can produce.** NVX bit 0 says when the TMS really fired
   and bit 2 says when the subject screen really changed, both on the same 25 kHz clock:
   **command → pulse** and **cue → photons**.
3. **Open items that need hardware** — the A16 stimulator interlock, the photo-sensor path, and
   four smaller ones.

---


<a id="history-2-safety-envelope"></a>

## 2. Safety envelope

Fixed by the operator: coil not facing humans and away from equipment; **20 % intensity for all
testing, never raised**; Disconnect = off/standby = the resting state.

Imposed on top, and enforced in `safety.py` rather than in prose: never armed and unattended;
**≥ 3 s between pulses** with a per-run hard cap; coil temperature read and logged at the first and
last pulse of every run; **operator confirms the coil is clear before the first edge of every
session**, including the init string; every pulse ledgered with wall time, intensity and reason;
no trains; **amplifiers stopped before they are closed**; anything unexpected stops the session.

`safety.py` holds the 20 % ceiling, the 3 s floor (it sleeps it itself), the run cap, the
coil-clear gate, a JSON-lines pulse ledger `fsync`'d **before** each pulse leaves, and an exit
contract that parks the line and disconnects on every path including Ctrl-C. Every firing tool
imports it.

The init string `2=OUT,LOW` is treated as a **counted, ledgered pulse**, not a control write:
applying an output role sets the pin's idle level immediately and that is itself an edge into the
TMS trigger input. `--fire 3` therefore reports **4** edge-producing writes.

---


<a id="history-3-the-order-and-why-it-is-that-order"></a>

## 3. The order, and why it is that order

| Step | Fires? | What it decides |
|---|---|---|
| 1 inventory | no | which port, which display, what is already running, is COM8 free |
| 2 board identity | no | firmware version, and **Nano or Xplained Mini** — which decides whether round 2 needs one source change or two |
| 3 **headline experiment** | yes | the byte-level cause, and the config-vs-code verdict |
| 4 polarity from this session's data | yes (3 pulses) | `triggerBit` / `triggerEdge` for this rig, this session — every later number depends on it |
| 5 tepSound end to end | yes | does Arm open the port; does the newline config fix the init half; does a parameter edit close the port while armed |
| 6 **cue → photons** | **no** | the display path, with nothing at stake |
| 7 **command → pulse** | yes (5 pulses) | the stimulator's own trigger-to-discharge latency |
| 8 open items | mostly no | A16, coilTemp readout, playbackSource, the missing `python\` |
| 9 leave it safe | no | disconnected, stopped, closed, nothing running |

Rationale for the two orderings that matter:

* **The zero-pulse steps come first.** Step 6 measures the whole presentation path with a protocol
  that carries no `trigger` key anywhere, so the coil cannot discharge however the run goes.
* **Within step 3, the dangling-buffer probe runs before the terminated leg.** A terminated write
  executes whatever is sitting in the board's line buffer, and the evidence is then gone.

---


<a id="history-4-the-headline-bug--the-diagnosis-and-what-it-became"></a>

## 4. The headline bug — the diagnosis, and what it became

> ⭐ **All of §4 is now history, and it is kept because it is the fault tree.** Every defect named
> below was fixed on 2026-08-22 and deployed at 15:45 (`field-bugs-20260822.md` § *Item 10*):
>
> | § 4 finding | now |
> |---|---|
> | no terminator on any write | **fixed** — appended in `writeSerial()`, per line, never doubled |
> | init written into a Nano's DTR reset window | **fixed** — `ID?` handshake, 12 × 400 ms, banner restarts the count once; the Arm is refused if nothing answers |
> | `configure()` unconditionally closes the port | **fixed** — only a change of backend, target or baud closes it |
> | unmapped code sends one raw byte | **fixed** — sends nothing and reports an error; the parameter description was corrected to match |
> | `close()` never parks the line | **fixed** — `S\n` before close, on an identified board only |
> | ⚠ the init string can itself fire the TMS | **unchanged and unfixable — now stated to the operator** in the `triggerInit` description |
> | tepSound's `coilTemp` permanently 0.0 | **NOT fixed** — still open, still worth confirming at the rig |
>
> The **config-vs-code split** below is answered and obsolete: it needed code, and `mkconfig.py
> tepsound-lf` should not be used any more. What the lab adds is no longer a diagnosis; it is a
> discharge, three times, with three witnesses that agree.

<a id="history-established-by-reading-the-source-the-lab-confirms-does-not-rediscover"></a>

### Established by reading the source (the lab confirms, does not rediscover)

`TriggerOut::writeSerial()` (`R:\src\stimulusService\triggerout.cpp:115-122`) writes the string and
**appends no terminator**. Its only callers are the init on open (`:91`) and the per-pulse command
(`:137`). The arduinoTTL firmware executes a command **only** on `'\n'` or `'\r'`
(`R:\src\arduinoTTL\doc\arduinoTTL.ino:1219-1234`), and the board's own service **does** append one
(`R:\src\arduinoTTL\transport.cpp:83-89`).

So with the shipped defaults tepSound puts `2=OUT,LOW` (9 bytes) then `2:P1` (4 bytes each) on
COM8 with nothing between them, the board accumulates `2=OUT,LOW2:P12:P1…` in a 72-byte line
buffer, never executes a line, and drops the buffer as overlong at the 16th pulse. That fully
explains the symptom including "it works from the Arduino serial monitor" — the monitor sends
Enter.

Also established, and worth confirming as secondary findings:

* **Ruled out by code:** baud (115200 hard-coded both sides, `setSerialBaud()` has no callers) and
  CR-vs-LF (the firmware accepts either).
* **`triggerBackend` ships as `None`** (index 0), on which nothing is ever opened.
* **The port opens on Arm, not when the name is typed.** Before Arm, `COM8 (not open)` is correct.
* ⭐ **`configure()` unconditionally closes the port, and it is reached from `reconfigure()` on a
  50 ms coalescing timer fired by *any* parameter write.** So editing any tepSound parameter while
  armed silently closes the trigger port and nothing reopens it until Stop + Arm. This is very
  likely present in the operator's actual sequence.
* ⭐ **tepSound's `coilTemp` is permanently 0.0** — `service_analysis.cpp:808` reads a lane named
  `coilTemp`, and the neuroMS status stream publishes `coilTemp1`/`coilTemp2`. So the `maxCoilTemp`
  limb of the interlock can never fire, and every `pulse/fired` event and the run-bar summary
  report 0 °C.
* `TriggerOut::close()` never parks the line (no `S`), unlike the board's own service.
* An unmapped code sends a single raw byte, contradicting the parameter's own description.

<a id="history-the-config-vs-code-split--the-most-valuable-single-output"></a>

### The config-vs-code split — the most valuable single output

* `triggerInit` is a plain `Parameters::String` written verbatim on open, and a JSON config can
  carry a real newline. `mkconfig.py tepsound-lf` writes `"triggerInit": "2=OUT,LOW\n"`. **Verified
  against a live tepSoundService here** — the value survives the config path and reads back intact.
* `triggerMap` cannot be rescued: `setSerialCommands()` parses `(\d+)\s*=\s*(\S+)` and `\S+` is
  non-whitespace only.

⇒ **"the init line now works and pulses still do not" is a clean, decisive confirmation**, and the
verdict it produces is: init is config-fixable; the pulse path needs a source change here.

<a id="history-the-second-candidate-the-lab-must-separate"></a>

### The second candidate the lab must separate

If the board is an **Arduino Nano**, opening the port asserts DTR and resets it for ~1.5 s.
`TriggerOut::open()` writes the init immediately after `m_port.open()` with no delay and no
handshake, so on a Nano the init is swallowed **even after the terminator is fixed**. An Xplained
Mini is not reset. The board's own service never uses a fixed wait — it re-sends `ID?` every 400 ms
up to 12 times and restarts on the ready banner.

**Observable:** does a `arduinoTTL v2.2 ready` banner appear when a port is opened? (⭐ v2.2 on this rig, and `--sniff 6` caught it at +1.478 s — so it IS a Nano.) Banner ⇒ Nano ⇒
round 2 needs both fixes.

<a id="history-the-decisive-experiment"></a>

### The decisive experiment

The board is the sniffer. After a tepSound run, reopen COM8 **with DTR held de-asserted so the
board does not reset**, read 500 ms, then send one lone `"\n"`:

| result | meaning |
|---|---|
| `ERR syntax 2=OUT,HIGH\|OUT,LOW\|IN,FALL\|IN,RISE\|OFF` | ⭐ **the bytes were on the wire, unterminated. Cause confirmed at the byte level** |
| complete silence | nothing was ever written — pursue port-held / wrong-backend / port-closed-by-edit / not-flushed |
| a ready banner instead | the board reset; the probe is void, fall back to the `E?` `out2=` comparison |

Corroborated by the board's own `E?` counter: `out2=` must be **unchanged** across the whole
tepSound leg, and **+1 per pulse** across the terminated leg.

---


<a id="history-5-what-counts-as-a-negative-result--the-five-meanings-of-the-tms-did-not-fire"></a>

## 5. What counts as a negative result — the five meanings of "the TMS did not fire"

This is the part the plan exists for. Each has a different observable and a different consequence.

> ⭐ **Unchanged and now more useful, not less.** With the fix in, the expected outcome is that
> **none** of these five happens. Meaning #2 was the diagnosed cause and is the one that should now
> be **absent** — seeing it again means the lab PC is running the pre-fix distribution, which the
> build check in `LAB_PROMPT.md` §7.1 catches before any pulse. Meanings #1, #3, #4 and #5 were
> never code defects and are untouched by the fix; they are now the *likeliest* explanations for a
> rig that does not fire, so this table is where a negative result gets classified.

| # | meaning | how it is distinguished | consequence |
|---|---|---|---|
| **1** | **The command never left the host.** Port not open (wrong backend, never armed, held by another process, closed by a parameter edit), or written and never flushed | The wire string reads `off` or `COM8 (not open)`; Arm raises a Qt error whose text names it; `port_owner.py --deep` names any holder; **the dangling probe answers with silence** | Configuration or a startup-ordering bug. Possibly fixable at the lab |
| **2** | **The bytes arrived and the board never parsed them.** The line terminator, or the init lost in a DTR reset window | ⭐ **the dangling probe answers `ERR syntax …`**; `E?` `out2=` unchanged; `2?` answers `CH2 OFF`; a `2:P1` answers `ERR ch2 not an output` | **Source change here.** The expected result |
| **3** | **The board fired BNC2 and the stimulator did not discharge.** Not connected, not charged, `trigIn` disabled at open, interlock, front-panel power off, coil absent or over temperature | Board says `2 FIRE`/`2 DONE` and `out2=` increments, **but** NVX bit 0 shows no edge and `NeuroMS/events` has no `pulse` record. The neuroMS refusal reason names which | Rig state, not software. Fix on the spot and re-run |
| **4** | **It discharged and the amplifier did not see it.** Wrong bit, wrong polarity, wrong channel, a pulse narrower than one 40 µs sample (this driver has **no edge-latch mode**, only level sampling), or a cable off | `NeuroMS/events` has a `pulse` record and the operator heard it, but `trigger_scan.py` shows bit 0 never moving. ⚠ **An unwired NVX136 input rests HIGH and never moves — which is what a disconnected input looks like too** | Measurement setup. Re-check the bit table before believing any later number |
| **5** | **It fired, was seen, and the analysis missed it.** Wrong `triggerEdge`, epochs discarded because the SOUND stage was never ready, refractory, or the patch-inversion mistake on bit 2 | `trigger_scan.py` shows the edges but tepSound's counter does not move; or the epoch counter climbs while "in average" stays 0 | Analysis configuration. tepSound's trigger counter is upstream of SOUND, so a trigger finding survives a failing SOUND |

**Corollary for the report:** "the TMS did not fire" is not a finding. "The board answered
`ERR syntax` to a lone newline after tepSound's run, `out2=` was unchanged, and bit 0 never moved"
is meaning #2, and it is actionable.

⚠ One more negative result with its own trap: **a null on bit 2 is uninterpretable without the
photo-sensor calibration.** A blind sensor and a sensor that never saw a cue produce identical
data — a bit that rests HIGH and never moves.

---


<a id="history-6-the-numbers-and-what-they-should-be"></a>

## 6. The numbers, and what they should be

<a id="history-the-rule"></a>

### The rule

**A difference between two sample indices in one NVX recording is exact device time** — the index
comes from the amplifier's hardware frame counter, so it survives dropped samples.
**A host timestamp on this rig is worth ±2.5 s** — block `created` stamps have measured from
−45 ms to **+2593 ms** against their own sample counts; the samples are all there, the stamps are
not. Correlation between block-stamp error and the service's trigger-time discrepancy in an earlier
run: **0.9992** — the service inherits the error, it does not create it.

So every latency worth bringing home is a difference of two sample indices. `latency.py` prints
`REFERENCE INSTANT:` on every result and refuses an RTC-derived per-trial number unless forced.

<a id="history-expected-precision"></a>

### Expected precision

| term | value |
|---|---|
| sample period at 25 kHz | 40.0 µs |
| single-edge location | ±20 µs, sd 11.55 µs |
| two-edge difference | sd ≈ 16.3 µs, span 1–2 samples |
| **demonstrated on this rig's own data** | 150 trials, median +60.280 ms, min +60.240, max +60.320 — **span 80 µs = 2 samples** |

Dominant unknowns: the **TMS output pulse width** versus level sampling (measure it before trusting
any count), and the **photo-sensor's comparator threshold and hysteresis**, which will dominate
anything on bit 2.

Report everything as median / min / max / sd / n, **in ms and in samples** — the sample form shows
the quantisation directly.

<a id="history--the-one-wiring-change-worth-asking-for"></a>

### ⭐ The one wiring change worth asking for

**Bring the Arduino's own edge onto a spare NVX input, ideally bit 3.** ⭐ **Already fitted on this rig, on BIT 1 — use `--pair 1:0`.** Preferred route: use
**BNC1/D9**, unused on this rig, driven from the same command — it does not touch the wire that
fires the stimulator. Alternative: tee BNC2.

With it: `command → pulse` = bit3 → bit0, and `cue → photons` = bit3 → bit2, both exact.
Without it: only `bit0 → bit2` exists, which **conflates the serial path and the display path into
one number and cannot separate them.** `latency.py` says so on every run.

<a id="history-what-is-explicitly-not-measurable-here"></a>

### What is explicitly not measurable here

The absolute host→board leg — Qt, QSerialPort, USB-CDC, firmware parse. Its **jitter** is
measurable (a difference of intervals cancels the unknown constant); its **absolute value** is not,
and needs a scope. Report the jitter, name the constant as unmeasured, and do not add them.

<a id="history-cue--photons"></a>

### cue → photons

The stage emits the trigger **first, on the cue's own onset frame**, so with `triggerOffset = 0`
the Arduino edge and the photodiode change are two consequences of one frame swap.

Two shipped defects the lab protocols correct: the shipped `tms-cue-block.json` puts the patch
**`bottom-right`** while the sensor is **top-right**, and the patch is anchored to the stage
**window**, so `fullscreen` must be on or the measurement is void.

⚠ The patch **inverts** on every cue rather than pulsing — every cue is one transition, alternating
direction. `--edge both`, strict alternation enforced, breaks flagged not repaired.

Even with nothing firing, the bit-2-only run yields onset-to-onset intervals against the commanded
frame counts, the measured refresh period in samples (173.6 at 144 Hz, 416.7 at 60 Hz), dropped
frames, and onset jitter. **This path has never been measured in this project at all — any number
is new.**

---


<a id="history-7-open-items-the-lab-settles"></a>

## 7. Open items the lab settles

| Item | Expected |
|---|---|
| ⭐ **A16 interlock** — untestable here, no stimulator on this machine. **SETTLED at the rig: CONFIRMED, 3 cases + the control** | With **`input/tmsStatus`** (⚠ not `tms/tmsStatus`) nominated and `requireCharged` on: neuroMS **absent** or in `init` → blocked with *"the stimulator's status stream has not published…"*; `ready` not charged → *"the stimulator is not charged"*; `charged` → permitted; killed mid-session → *"the stimulator's status is N ms old"*. **Control:** with no stream nominated at all it permits, deliberately |
| **tepSound's coilTemp readout** | shows **0.0 °C** while neuroMS shows a real temperature. Confirms the lane-name bug |
| **The photo-sensor path** | never exercised in this project. Calibration first, then numbers |
| **`playbackSource.exe` standalone** | dies here with an access violation in `Qt5Network.dll`; workers under `playbackService` are fine. Does it reproduce? |
| **tepSound's post-seek transient** | unmeasured |
| **No `python\` directory** although `env.bat` sets `PYTHONHOME=%CD%\python` | does anything actually break? |
| **`params\speed_feetStim.json` → missing `mulines\resources\SPEED_settings.json`** | same question |

---


<a id="history-8-what-the-lab-pc-can-and-cannot-do"></a>

## 8. What the lab PC can and cannot do

The shipped zip unpacked, Python, **no compiler and no Qt SDK**.

**Can:** run every service and the Configurator; edit `params\`, `.ini`, `montages\`, `protocols\`,
`calib\`, `stimuli\`, `mulines\`, `.bat`, and **`bin\Resonance\*.qml`** (loose files read at
start-up); drive services over the EventBus from a QML harness under `quickStimulus -l file.qml`.

**Cannot:** edit **tepSoundService's own QML** — it is compiled into the exe through `res.qrc`, and
the service puts the compiled-in copy first on the import path, so `bin\Resonance\TepSound\*.qml`
on disk is shadowed and inert. Same for `tepService` and `stimulusService`. Anything needing a
tepSound QML or C++ change comes back here.

**Toolkit dependency posture:** stdlib only. `winserial.py` drives COM8 through `ctypes`/Win32
(pyserial not needed; the raw Win32 error is better evidence — 5 = held, 2 = absent), and
`h5read.py` falls back to `h5mini.py`, a stdlib HDF5 reader validated field-for-field against h5py
on a real recording. Offline wheels are included as the fast path.

Config files must be **generated with Python**: a PowerShell 5.1
`ConvertTo-Json | Set-Content -Encoding utf8` config gets a BOM and is silently rejected, and the
service then starts with every parameter at its default.

---


<a id="history-9--what-in-the-toolkit-is-untested-because-it-needs-hardware"></a>

## 9. ⚠ What in the toolkit is untested because it needs hardware

Built and tested on a machine with **no stimulator, no Arduino, no NVX136**.

**Verified here on real data:** `latency.py --pair 1:0` reproduced an independently measured
n = 150 / median +60.280 ms / span 2 samples; `trigger_scan.py` derived idle `0x0000FFFA` (⭐ this rig now reads `0x0000FFFE` / `0x0000FFFF`), bit 0
rests LOW, widths 250/251 samples, and the block-stamp anomaly, from the data alone; every refusal
path (bit never moved, reversed pair, empty window, non-bitfield column, RTC on a bad-stamp file);
`ttl_probe.py` open/configure/write/read/close against a real COM port, including short-write
detection, the coil-clear refusal, the 3 s floor, the line-buffer-overflow guard at 20 unterminated
pulses, and Win32 errors 2 and 5; `port_owner.py --deep` against a deliberately held port; all 5
QML harnesses pass `qmllint`; all 11 Python files compile; all 10 README smoke-test commands exit 0
with `h5py` and `pyserial` **absent**.

**Untested, needs the rig:** everything past opening the port — the board's replies, its firmware
version, Nano-vs-Xplained; the dangling-buffer probe's actual verdict; `--as-tepsound` vs
`--as-arduinottl` on a real board; **every neuroMS transition, parameter and status lane**; the A16
interlock; **bit 2 and the photo-sensor entirely**; both latency numbers. `latency.py --pair 1:0`
additionally assumes the extra BNC lead. ⭐ All of this except bit 2 and the photo-sensor was
exercised at the rig on 2026-08-22 — see the corrections block at the top.

---


<a id="history-10-what-comes-back-and-how-round-2-uses-it"></a>

## 10. What comes back, and how round 2 uses it

The lab session returns **text pasted into a chat here**. The report format is specified in
`LAB_PROMPT.md` §11 and is part of the deliverable: numbers with their reference instant and both
ends named, artefacts by full path, what was ruled out and how, what could not be tested and why,
and — for anything needing a code change — **the file and the observable behaviour, not a proposed
patch.**

<a id="history-round-2-by-branch"></a>

### Round 2, by branch

| What comes back | What happens here |
|---|---|
| ⭐ **The fixed service armed and the coil discharged three times, three witnesses agreeing** — the expected result | **Job 1 closes.** Record it in `field-bugs-20260822.md` § *Item 10* under "what still needs the rig", which currently lists every one of these as unverified. Nothing to build |
| **It fired, but the coil also discharged on Arm** | Expected — that is the init edge, and it is now documented in the `triggerInit` description. Record it as confirmation of the warning, not as a fault |
| **`2?` answers `CH2 OFF` after Arm on a Nano** | The handshake did not do its job. Look at whether `ID?` was answered at all: if the banner arrived but identity never did, the once-only count restart is too strict |
| **The wire string still flips to `(not open)` after a parameter edit** | The fix is not in that binary. Check `Trigger map`'s description first (§7.1 build check) before touching `configure()` again |
| ⚠ **An unmapped code produced a byte or a pulse** | **Safety regression — highest priority.** `pulse()` must return before any write; re-check `m_serialCommands.value(code).isEmpty()` |
| **Dangling probe answers `ERR syntax` on the fixed build** | The distribution is pre-fix. Not a code question — reship `resonance_20260822b.zip` |
| **Dangling probe silent but still no pulse** | The bytes never left. Re-open on `port held` / `backend None` / `not flushed`, using whichever observable the report names. These were never fixed because they are not code defects |
| **tepSound showed 0.0 °C beside a real neuroMS temperature** | Fix the lane name (`coilTemp` → `coilTemp1`), or publish an aliased lane in neuroMS. Restores the `maxCoilTemp` interlock limb, which is currently dead |
| **A16 behaved as expected in all five cases** | Close the item; record the evidence in the tepSound task notes |
| **A16 misbehaved** | Reopen `tmsBlocker()` with the exact refusal string the lab saw |
| **Photo-sensor calibrated and cue → photons measured** | First real display-latency number in this project. Also decides whether the shipped protocol's `bottom-right` default and `photodiodeSize` 0.06 should change |
| **Photo-sensor blind** | Rig fix, not a code fix. Nothing here to change |
| **Operator declined the extra wire** | Only the conflated number exists. Either accept it labelled as conflated, or make the wire the first ask of the next visit |

Then rebuild, re-zip, and go again. The kit is designed to be re-copied wholesale.
