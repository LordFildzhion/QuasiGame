# `mStim` — the four-magnet maglev stimulator as a Resonance service — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/mstim.md)

<a id="dual-trigger-20260918"></a>

## 2026-09-18: physical simultaneous-trigger acceptance

With user-confirmed disconnected stimulation outputs, the August-2026 mStim
firmware on COM14 executed M1 Up 20% / M2 Down 20% pulses (M3/M4 Off, default
all-Off, external input disarmed). Direct TTL strobes were recorded on NVX Trig5
alongside A1 → fresh Nano repeater → Trig4 at NVX 2 kHz, Level mode.
Ten mStim strobes and ten A1 pulses were retained in each concurrent condition
(A1 10/20/100 Hz); 6/6/9 A1 pulses respectively overlapped mStim HIGH.
No masking: all four idle/A1-only/mStim-only/both raw-word states were recorded.
Nano pulses measured 3.0 ms. mStim requested 100-ms strobes measured 101–101.5 ms,
and requested 150-ms spacing measured 151.5–152 ms; this timing discrepancy is
not diagnosed. No precision-onset or loaded-magnet acceptance is claimed.

mStim used direct serial control, not the Qt service/GUI. All outputs were
acknowledged OFF and external TTL disarmed at completion; A1 disconnected,
NVX stopped before process termination, eStim exited normally (0). No firmware,
application binary or deployed INI changed. COM14 reset the volatile library;
reconnect and Program all before normal use. Nano channel 2 remains untested.

Full report: `N:\Projects_MSU\2026 - Passive movements\exe\MioStim\arduinoTTLrepeater\DUAL-TRIGGERS-20260918.md`.
Raw data, independent analysis, PNG, serial transcript, executed script and logs:
the same project's `tests\20260918-dual-run01`. H5 SHA256:
`9436089c230f6bb680a5a5f83d6cd1167d02c72a998d4cdf7fb9a5c964893294`.
The H5 is custom QA format, not a standard Resonance playback recording.

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-mstim--the-four-magnet-maglev-stimulator-as-a-resonance-service"></a>


**Added 2026-08-16.** Module: `R:\src\mStim`. Service name `mStim`, launcher `mStim.bat`.
No architecture gate.

**Ported to Qt 6, 2026-09-02.** `mStim` is in the default Qt 6.11.2 distribution:
`R:\dist\bin\mStim.exe`, launcher `R:\dist\mStim.bat` (the Qt 6 distro has no
`msvc64\` level — `bin\` is at its root). The Qt 5.15.2 comparator is `R:\src_Qt5\mStim` →
`R:\dist_Qt5\msvc64\bin\mStim.exe`. The port changed nothing in this document: the static parameter
contract is byte-identical across the two generations and both publish the same 1×22 `status` —
see §5 and [`build_qt5-to-qt6-transition.md`](../migrations/qt5-to-qt6-transition.md). Link targets are now
`Qt6::Core Qt6::Gui Qt6::Widgets Qt6::SerialPort Qt6::StateMachine`; the last is new, because Qt 5
shipped `QStateMachine` inside `Qt5::Core`.

⚠ **Read the `mStim.ini` note in §3 before deploying to a rig.** The file has no install rule.

An Arduino Nano driving two L298N bridges and four magnets, over one COM port at 115200. Source
of the port: `N:\Projects_MSU\2026 - Passive movements\exe\MagStim\mStim` (5 353 lines), whose
firmware is vendored in `doc/`.

The rig runs with **two magnets** (M1 above the object, M2 below) or **four** (the second pair is
M4 above, M3 below). One selector scales the panels, the composed commands and the diagram.

---


<a id="history-2-the-grammar"></a>

## 2. The grammar

```
=1M1U50M2D100T150K1        stimulus 1: M1 up 50 %, M2 down 100 %, one 150 ms pulse, kind 1
=7M1U100M2OT50I150R4K0     a packet: four 50 ms pulses, 150 ms apart
=3M1U80M2D80T50,-150,100K2 an explicit ON/OFF list
=9Wd,d_T500:100,0_H200K0   a piecewise-linear sweep
=dM1OM2D30                 the default state
!M1U50M2D50T100K0          a one-shot: runs now, occupies no library slot
```

`U`/`D` speak in **motion** terms — U moves the object up — and which H-bridge pin that is comes
from the `M<n>_orient` parameter. A magnet the line does not mention is switched off by the
firmware itself, which is why a two-magnet definition is safe on a four-magnet rig.

The terminal `K` token is always written: an explicit `K0` also **clears** a kind mapped earlier,
where redefining without it would silently keep the old one. While a stimulus runs, A5/A4 carry
that 2-bit kind and A3 strobes the ON phases, so a recorder can tag which stimulus fired.

In a sweep, `d` is a **live reference** the device resolves at run time rather than a number this
program bakes in. The window's diagram shows the current default in its place and labels it `d`.

`stimulus.{h,cpp}` holds the whole of this — compose and parse, both directions, pure, with no
serial port and no widgets in sight, because a wrong token does not fail loudly: the magnets just
do something else.

---


<a id="history-3-parameters-and-presets"></a>

## 3. Parameters and presets

57 parameters in five groups — `device`, `stimulus`, `rig`, `presets`, `link` — every one with a
tooltip.

`stimulus.line` is the composed command, and writing it is the way back in: type a definition and
every field re-derives from it. The fifteen `preset<N>` parameters hold the same form, which is
also what `Program all` sends and what appears in the events stream. Fifteen is the device's own
RAM capacity, so every slot is programmable and addressable by number.

The `rig` group carries the things that are easy to get wrong and expensive to notice:

| | |
|---|---|
| `M<n>_orient` | which H-bridge pin means "up". The firmware defaults are **only a convention** — check every coil at low power, or every direction in every stimulus is inverted for that magnet |
| `M<n> default` | the resting drive: what `98` applies, what the gaps inside a packet fall back to, and what follows every stimulus. Sent as one debounced `=d` line |
| `PWM_timer1` | the shared carrier of D10/D9 = magnets 2 and 3. Magnets 1 and 4 sit on Timer2 at a fixed 31373 Hz; all four duties stay independent |
| TTL input | D2/INT0 fires a stimulus. Edge and lockout stay terminal-only (`TTL_input_edge`, `TTL_input_timeout`) and arming never overrides them |

<a id="history--mstimini--nothing-installs-it-2026-09-02"></a>

### ⚠ `mStim.ini` — nothing installs it (2026-09-02)

Where the fifteen definitions, the four orientations, `PWM_timer1`, the TTL arming and the last
port land across a restart: `QCoreApplication::applicationDirPath() + "/mStim.ini"`
(`service.cpp:64`), written by `Config::save()` into `[serial]`, `[params]`, `[background]`,
`[custom1…15]`, `[ttl]`, `[playback]`, `[app]` and `[shortcuts]`.

**No build or deploy step puts one there.** `R:\src\mStim\CMakeLists.txt` installs the executable
and `mStim.bat` and nothing else; `deploy-qt6.ps1` copies no `.ini`. So the Qt 6 distribution had
none until one was copied in from `R:\dist_Qt5\msvc64\bin\` on 2026-09-02, and ⚠ **a fresh deploy
does not reinstate it.**

The consolation, and it is a real one: `R:\dist\bin\mStim.ini` presently contains **only**
`[serial] baud=115200`, which is the compiled default anyway — the rig has never saved a library
from this service, so today nothing is lost by losing the file. That stops being true the moment an
operator programs the rig and it exits: §6 step 2 is a per-coil measurement, and `M<n>_orient` is
the value in this file that costs a bench session to re-derive and inverts every direction in every
stimulus if it is wrong. Check the file exists — and that it has more than two lines in it — before
a session. [`build_qt5-to-qt6-transition.md`](../migrations/qt5-to-qt6-transition.md) §8.

---


<a id="history-5-verified"></a>

## 5. Verified

**Unit — `test_MStim`, 21/21.** Composition of every pulse shape and both head forms, the
unlisted-magnet rule, the always-written `K` token, the reserved IDs being refused, the default
state and parameter lines, the TTL lines, the 220-character limit; parsing back with a round trip
for all four shapes including the sweep; whitespace tolerance; and that a refused line leaves the
base untouched rather than half-applied. The list form's limits (ON ≤ 3000 ms, OFF ≤ 10000 ms,
by position) and that a minus sign there is a hint, not data.

**Live — over the EventBus**, with a serial port open:

| | |
|---|---|
| Service | **57 parameters** in five groups, all 57 with tooltips; `init` offers only `connect` |
| Round trip | `stimulus.line` equalled `preset1` exactly — the editor was loaded from the slot and re-composed to the identical text |
| Library | all fifteen slots matched the definition grammar, with unique IDs and none reserved |
| `connect` | port opened, `connection ok:true` published, state → `ready` (offering `program`) |
| **`program`** | the ordered burst went out and was published line by line: `M1_orient:SU,M2_orient:SD,PWM_timer1:31373`, then `=dM1OM2D30`, then all fifteen definitions — including a list (`=3…T50,-150,100K0`), a packet (`=4…T50I150R4K0`) and a sweep (`=6Wd,d_T50:100,0_H50_T75:-100,0K0`). State → `programmed` |
| `disconnect` | back to `init` |
| Streams | `@`, `events`, `status`; status **22 channels** at 2 Hz |

⚠ **No maglev hardware was attached.** The port used for the live run was a Bluetooth serial port
with nothing on it, which exercises the whole host side — opening, the paced multi-line burst, the
states, the streams — and nothing of the device. §6 is the bring-up.

<a id="history-qt-6-parity-2026-08-29"></a>

### Qt 6 parity, 2026-08-29

One external controller drove the Qt 5 and the Qt 6 binary through the same protocol. The **static
contract matched exactly** — 57 parameters, SHA-256
`87c514df72fa583f202dc25a4235cd3538c55b81421325e2e7024de583d860f1` — as did the transition list, and
both generations published the same **1×22 `status`** shape. A write to the definition line was
accepted and reflected by both. `qa/mstim-qt5-reference.png` and `qa/mstim-qt6.png` show the same
panel and control structure at a common width, including the repaired compact rows.

Evidence: `R:\src\docs\VALIDATION.md` (2026-08-29 section),
`R:\src\docs\qa\neuron-mstim-estim-parity.json`, and the two scripts that produced it,
`R:\src\scripts\test-neuron-mstim-estim-parity.py` and
`R:\src\scripts\capture-neuron-mstim-estim-gui.ps1`.

⚠ **Still no maglev hardware, in either generation.** The serial controller, the magnets and the
TTL input remain lab acceptance work — §6 is unchanged and undone.

---


<a id="history-6-hardware-bring-up"></a>

## 6. Hardware bring-up

1. Connect the board, pick its port, **Connect**. Wait for the banner in the monitor: the port
   opening has just reset it.
2. **Before anything else, verify the orientations.** Set one magnet to ±20 % with a single 200 ms
   pulse and watch which way the object moves. If it is the wrong way, flip that magnet's
   `M<n>_orient` and re-send the parameters. Doing this after building a library means rebuilding
   the library.
3. Set the default state and check the resting force is what you expect — it is applied between
   pulses and after every stimulus, not just by `98`.
4. **Program all**, then fire a slot by number from the Send box. Confirm the `launch` event's
   line matches what the diagram drew.
5. Check `PWM_timer1`: the device snaps to the nearest achievable frequency and reports it with
   the resulting TOP, so read the reply rather than assuming the requested number.
6. Only then the TTL input: arm it and confirm an edge fires the expected stimulus. Edges arriving
   during a blocking pulse, packet or sweep are **discarded, never queued**.

⚠ **The firmware blocks while a pulse, packet or sweep runs**, so `0` sent mid-packet takes effect
only after it ends. A hardware power cut is the real emergency stop.

---


<a id="history-7-traps"></a>

## 7. Traps

* **Nothing survives a reset**, and opening the port causes one. If the board restarts mid-session
  the service notices its banner, clears `programmed` and says so — but it does not re-program
  automatically, because silently re-arming a TTL input is not something a service should decide.
* **`M<n>_orient` is a convention, not a measurement.** See §6 step 2.
* A magnet left out of a definition is off. That is the firmware's rule and this service relies on
  it rather than padding lines with `O` tokens.
* Lines are capped at 220 characters and the composer refuses a longer one rather than letting the
  device truncate it silently.
* `Double::setMinimum/setMaximum` and `Select::setIndex` do not emit `triggerUpdate`
  ([known-issues §17a](../incidents/README.md)); same `rebroadcast()` workaround as the other three.
