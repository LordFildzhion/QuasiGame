# `feetStim` — the foot-sole solenoid stimulator as a Resonance service — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/feetstim.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-feetstim--the-foot-sole-solenoid-stimulator-as-a-resonance-service"></a>


**Added 2026-08-16.** Module: `R:\src\feetStim`. Service name `feetStim`, launcher
`feetStim.bat`. No architecture gate.

**Ported to Qt 6, 2026-09-02.** `feetStim` is in the default Qt 6.11.2 distribution:
`R:\dist\bin\feetStim.exe`, launcher `R:\dist\feetStim.bat` (the Qt 6 distro has no
`msvc64\` level — `bin\` is at its root). The Qt 5.15.2 comparator is `R:\src_Qt5\feetStim` →
`R:\dist_Qt5\msvc64\bin\feetStim.exe`. Nothing below changed in the port — see §7 and
[`build_qt5-to-qt6-transition.md`](../migrations/qt5-to-qt6-transition.md). Link targets are now
`Qt6::Core Qt6::Gui Qt6::Widgets Qt6::SerialPort Qt6::Network Qt6::StateMachine`; the last is new,
because Qt 5 shipped `QStateMachine` inside `Qt5::Core`.

> ## ⚠ Two files this service needs, and no build rule installs either
>
> This is the sharpest transition hazard in the service set, because both failures are silent and
> one of them **drives real hardware**.
>
> **`feetStim.ini`.** Read from `QCoreApplication::applicationDirPath() + "/feetStim.ini"`
> (`settings.cpp:12`). `R:\src\feetStim\CMakeLists.txt` installs the executable and `feetStim.bat`
> and nothing else; `deploy-qt6.ps1` copies no `.ini`. So the Qt 6 distribution had none until one
> was copied in from `R:\dist_Qt5\msvc64\bin\` on 2026-09-02 — and without it the **compiled
> defaults in `settings.h` apply**: `portName = "COM4"` with `emulator = false`, so the service
> opens a real serial port and drives the real solenoid array instead of the rig's emulator
> configuration (`[serial] emulator=true, port=None`); and `udpPort = 5005`, so it binds the port
> `eStim` also defaults to, rather than the rig's `5008`.
>
> The rest of that file is thinner than it looks, and it is worth knowing which half is which:
> measured against `settings.h`, this copy differs from the compiled defaults in exactly four
> values — `emulator`, `port`, `ttlPort` and the UDP port. Its nine presets are the factory nine,
> its PWM profile is the compiled one, its extents are the full 6 × 15 grid, and
> `[foot.left]`/`[foot.right]` are **empty**: no foot has been traced into this copy. A rig that
> has traced its feet therefore has something to preserve that this one does not.
>
> **`bin\FrameLib\Frame1`** — the stimulation pattern itself, 384 bytes. `library.cpp`'s
> `defaultDirectory()` is `applicationDirPath() + "/FrameLib"` and `framePath()` appends
> `Frame<slot+1>`. This file **exists in no source tree** — not in `R:\src\feetStim`, not in
> `R:\src_Qt5\feetStim` — and no install rule produces it. The only copies on this machine are in
> distribution trees: `R:\dist_Qt5\msvc64\bin\FrameLib\Frame1`, the same bytes in the archived
> `R:\dist_2026aug`, and, since 2026-09-02, `R:\dist\bin\FrameLib\Frame1`. It was copied from the
> Qt 5 distribution; it cannot be rebuilt, only copied.
>
> ⚠ **A fresh deploy reinstates neither**, because there is nothing to reinstate them *with*. Copy
> both by hand after every deploy and check them before a session.
> [`build_qt5-to-qt6-transition.md`](../migrations/qt5-to-qt6-transition.md) §8;
> [`arch_qt5-still-needed.md`](../migrations/qt5-still-needed.md) §5.

Two feet of **15 × 6 = 90 solenoids** each that press on the patient's soles. Source of the port:
`N:\Projects_MSU\2026 - FeetStim\exe\SolenoidConfig\feetStim` (9 730 lines, three operating
modes).

---


<a id="history-1-scope--what-is-here-and-what-is-not"></a>

## 1. Scope — what is here and what is not

The standalone program has three modes. **This service is the UDP/BNC one**, which is its default
and the one an experiment uses:

| In | Out |
|---|---|
| The device link — COM 57600 or the named-pipe emulator, full lockstep protocol | The **gait animation**: six built-in algorithms, the sliders, the session timer |
| The **frame library** — fifteen frames, per-point strength, load / save / copy / trim | The **latency bench** — the UDP→`Ok` repetition runs, the CSV export, the signal-path diagram |
| The interactive feet, with the traced outlines and photos | The **plantograph tracing dialog** — scan, rotate, magnetic-snap outline |
| The strength modes and every `_S` override | |
| The geometry mask and the monitoring solenoids | |
| The full **UDP command grammar** | |
| The **TTL generator**, on its own port | |

Those exclusions were chosen deliberately (see the decision record in this session): the gait
patterns and the latency bench are not what a Resonance experiment drives, and tracing is a
once-per-subject job with a scanner rather than something an experiment service should own.

**The traced feet are not lost.** The outlines live in `feetStim.ini` in grid coordinates with the
photos as PNG side files, and this service **reads the same file** — a rig that has already traced
its feet keeps them, and the geometry mask keeps working. Keys this service does not use are
written back untouched, so opening the rig in one program and then the other cannot quietly lose
the other's settings.

**The TTL board is opened directly**, as the standalone does, rather than delegated to the
[`arduinoTTL`](arduino-ttl.md) service. ⚠ Do not point both at the same port: the second
one to open it gets nothing.

---


<a id="history-2-the-device"></a>

## 2. The device

A strict request/reply lockstep. Each frame is two 96-byte packets, one per foot:
`"Stim"`/`"Fizi"` + `'1'`/`'2'` + 90 force bytes + checksum, each answered `Ok` or `E1`/`E2`/`E3`.
Control commands share the discipline: `Ver?`, `SolOff?`/`SolOffPPTT`, `Mod1`/`Mod2`.

Two transports, exactly as in the original: a **COM port at 57600**, with the `Ver?` handshake
refusing a port where nothing answers; or the **named pipe** `\\.\pipe\Stimuljator`, where this
service is the *server* and `emulator.exe` is the client — so connect here first, then start the
emulator.

⚠ **Stopping the trigger does not switch the solenoids off.** In Mode 1 all 180 stay active after
the first sync pulse, holding whatever the last packet carried, and release only on **two zero
packets — one per foot, i.e. exactly one frame**. That is what `releaseHold` sends, what the
`release` transition sends, and what the destructor sends before closing the port. A service that
merely closed the link would leave the patient pressed.

---


<a id="history-3-the-send-path--the-part-that-decides-what-the-patient-feels"></a>

## 3. The send path — the part that decides what the patient feels

Three steps, in this order, in `frame.cpp`:

1. **strength** — each stored per-point level through the mode or the command's override, then to
   a device byte;
2. **geometry mask** — points outside the foot extent zeroed;
3. **monitoring solenoids** — forced to full whenever anything else in the frame is active.

**Monitors come after the mask on purpose.** A sensor solenoid marked outside the traced extent
must still fire, or the accelerometer on it stops recording exactly when the frame is trimmed.
Swapping those two steps loses the recording channel on precisely the frames that matter, and
nothing would say so.

One invariant holds across every mode and override: **an Off point stays off**. A mode changes how
hard a point presses, never whether a point nobody drew presses at all.

| Strength mode | What is sent |
|---|---|
| One level for all | every active point at the fixed level; a *send-time* step, so the drawn levels survive and the mode acts as a mask |
| Per point | each point at its own stored level |
| Per point + PWM gate | per-point levels, with the whole frame gated by the profile — needs Mode 2 and a generator |

Frames are **always stored per point**, whatever the mode says.

---


<a id="history-4-the-udp-grammar-unchanged"></a>

## 4. The UDP grammar, unchanged

The rig's experiment software already speaks it, so it is the same parser, on the same default
port 5005, with the same replies:

```
[<N>] [!] [_G<action>] [_TMS<ms>] [_S<override>]
```

`_Sf90` fixed · `_Si` individual · `_Sis+10` shifted · `_Spwm50-<profile>` gated ·
`_Gp/_Gt/_Gw/_Gf/_Gs` generator actions, each with an optional `@<ms>` board-timed onset ·
`_TMS<ms>` a one-shot BNC2 offset for that command. A `_G` implies `!`; a frame number is optional
when a `_G` is present, and the action then applies to whatever is already armed — which skips the
~34 ms reload.

The reply is the rig's, byte for byte:

```
FRAME=1;STRENGTH=individual:+10;UNITS=byte;L=153,0,…(90);R=…(90)
FRAME=1;STRENGTH=pwm;UNITS=byte;PWM=50Hz:0_T200:100_H300_T200:0;L=…;R=…
ERR=номер кадра вне диапазона 1–15;MSG=20
```

⚠ **Port 5005 is shared with `eStim`.** Both programs default to it and the originals already
document the clash. Whichever binds first wins; the loser says so in its monitor and keeps
running. Give one of them another port.

That is exactly what the rig did: `R:\dist\bin\feetStim.ini` carries `[udp] port=5008`. ⚠ Lose the
file and the compiled default 5005 comes back, and with it the clash — see the box at the top.

<a id="history-presets-are-udp-command-lines"></a>

### Presets are UDP command lines

Nine slots, each one line of that grammar — `7!`, `3!_Sis+10`, `7_Gp20@200`, `_Gs`. Launching one
runs it exactly as if it had arrived over UDP, so a preset is documentation of the protocol as
much as a stored setting, and it is testable by pasting it into a UDP client. Nine **fixed**
`String` parameters, so a saved service configuration reloads
([known-issues §16b](../incidents/README.md)).

---


<a id="history-5-streams"></a>

## 5. Streams

<a id="history-events--message--json"></a>

### `events` — Message / JSON

The record of the session. Every UDP or stream command with its source, every device error, the
generator's every line, and — the one that matters —

```json
{"type":"frameArmed","slot":1,"sent":true,"strength":"individual:+10","masked":false,
 "L":[153,0,0,…],"R":[…]}
```

**the 90 force bytes per foot exactly as they went to the controller**, after the strength mode,
the mask and the monitoring override. Reconstructing that afterwards from the slot number is not
possible: the same frame sends differently under a different mode or a `_S` override. A recording
that carried only "frame 7 fired" would not say what the patient received.

Also: `fire` records carry the generator's own microsecond stamp for the TTL edge next to the host
RTC, `tms` records the standing rule and each one-shot, `deviceError` the `E1`/`E2`/`E3` codes,
`release` the zero frame.

<a id="history-status--float64-20-named-channels-2-hz"></a>

### `status` — Float64, 20 named channels, 2 Hz

`device.open/verified/emulator/version/triggerMode/errors`, `frames.sent`,
`frame.selected/armed/activePoints/dirty`, `strength.mode/fixed`, `mask.outside`,
`ttl.open/verified`, `tms.enabled/offset`, `preset`, `udp.bound`.

<a id="history-command--input"></a>

### `command` — input

UDP grammar lines, or JSON: `{"command":"send","text":"7!_Sis+10"}`, `"arm"`, `"release"`,
`"connect"`, `"preset"`. It accepts this service's own `command` records back, so a recorded
session replays into the rig unchanged.

---


<a id="history-7-verified"></a>

## 7. Verified

**Unit — `test_FeetStim`, 21/21.** The strength modes and every override (including that an Off
point survives all of them, and that a shift clamps at both ends), the geometry mask as a
reversible filter, **the monitor-after-mask ordering**, the empty-frame case where monitors must
stay silent, `trim` and its idempotence, the frame file format at v105 and v102, a missing file
loading as an empty frame, and the UDP grammar against every example in the rig's own
documentation. No device, no pipe, no window.

**Live — against the real `emulator.exe`**, over the named pipe, driven by UDP and read over the
EventBus:

| | |
|---|---|
| Service | 45 parameters in five groups, **all 45 with tooltips**; `init` offers only `connect` |
| Link | `connect` created the pipe, `emulator.exe` joined, `ready` offered `arm` and `disconnect` |
| Reply | `FRAME=1;STRENGTH=fixed:90;UNITS=byte;L=…;R=…` with **exactly 90 bytes per foot** |
| **Send path, on a real frame** (50 / 100 / 70 %) | fixed 90 → `230,230,230`; `_Sf60` → `153,153,153`; `_Si` → `128,255,179`; `_Sis+10` → `153,255,204` — the shift clamping at the top |
| PWM | `_Spwm50-0_T200:100_H300_T200:0` → `STRENGTH=pwm;PWM=50Hz:0_T200:100_H300_T200:0` |
| Generator absent | `_Gp20` answered `TTLERR=the TTL generator is not connected`, not silence |
| Refusal | frame 20 → `ERR=номер кадра вне диапазона 1–15;MSG=20`, in UTF-8 |
| States | `arm` → `armed`, `release` → `ready` |
| Streams | `@`, `events`, `status`; `frameArmed` records carry the full `L`/`R` arrays; status 20 channels at 2 Hz |

⚠ **No stimulator hardware was attached** — the controller was `emulator.exe` throughout, and no
TTL board was present either. The wire protocol, the frame arithmetic and the whole command path
are exercised; what is not is a real controller's timing and its `E1`/`E2`/`E3` behaviour, and the
generator half beyond its refusal. §8 is the bring-up.

<a id="history-qt-6-parity-2026-08-28"></a>

### Qt 6 parity, 2026-08-28

`test_FeetStim` (21 cases) is registered with CTest in the Qt 6 tree and passed in the final
17/17 run (`R:\src\docs\qa\ctest-qt6-final.log`). One external protocol test then drove the Qt 5
and the Qt 6 binary identically: 45 parameters, the complete operator help, the exact `1!_Sf60`
response, **90 values per foot** with first values `[153,153,153]`, event delivery, and the same
1×20 `status`. Evidence: `qa/feetstim-qt5-parity.log`, `qa/feetstim-qt6-parity.log`, and the screen
pair `qa/feetstim-qt5-reference.png` / `qa/feetstim-qt6.png`;
`R:\src\docs\VALIDATION.md`, 2026-08-28 section.

⚠ **`emulator.exe` is not in `R:\dist`, and that is not an oversight you can fix.** The named-pipe
controller emulator this whole section was verified against is `R:\dist_Qt5\msvc64\bin\emulator.exe`
— 2 127 872 bytes, dated 2025-07-24, matching **no source file and no `add_executable` in either
tree**. It cannot be rebuilt, only copied. The Qt 6 tree's own device-parity script,
`R:\src\scripts\test-device-service-parity.py`, therefore defaults to
`--emulator R:\dist_Qt5\msvc64\bin\emulator.exe` and launches the Qt 5 binary to test the Qt 6
service. A reader looking for `emulator.exe` beside `feetStim.exe` in `R:\dist\bin` will not find
it: run it from the Qt 5 distribution. [`arch_qt5-still-needed.md`](../migrations/qt5-still-needed.md) §5.

⚠ **Still no solenoid hardware, in either generation.** §8 is unchanged and undone.

---


<a id="history-8-hardware-bring-up"></a>

## 8. Hardware bring-up

1. **With the BNC unplugged from anything that matters**, connect the controller on its COM port.
   The `Ver?` handshake should fill the device line; a `Ver 10.xx` is QuickPush hardware and
   enables the Mode1/Mode2 selection.
2. Check the overheat figures read back into the two fields on connect. They describe the device,
   not the last thing typed.
3. Draw a couple of points on frame 1, Save, then **Arm**. Nothing should move: arming does not
   fire. Check the `frameArmed` event's `L`/`R` against what you drew.
4. **Release hold** and confirm the solenoids drop. Then arm again and apply the BNC edge — that
   is the step that stimulates.
5. Try `_Sf50` and `_Si` on the same frame and confirm the force really differs. This is the
   easiest thing on the rig to get subtly wrong and the hardest to notice.
6. Turn the geometry mask on with a small extent and confirm the out-of-extent points stop firing
   **and a marked monitoring solenoid does not**.
7. Only then the generator: connect it on its own port, check `TTL=` appears in replies, and
   finally the TMS standing rule on BNC2.

⚠ **Release the hold before disconnecting.** The destructor does it and so does the `disconnect`
transition; `taskkill` does not.

---


<a id="history-9-traps"></a>

## 9. Traps

* **Port 5005 is shared with `eStim`** — see §4.
* **The frame on screen wins for the selected slot.** Arming the slot being shown sends the
  unsaved edit, because the operator drew it and pressed Arm; arming any other slot loads from
  disk. That also means a frame file written on disk while the service is running is not picked up
  for the selected slot until it is re-selected.
* **Monitors after the mask** — §3. It is the one ordering in this module that is easy to
  "tidy" into a bug.
* `pwmprofile.cpp` carries the profile dialog as well as the parser, so even the test binary needs
  `Qt6::Widgets` (`Qt5::Widgets` in the comparator tree).
* `Double::setMinimum/setMaximum` and `Select::setIndex` do not emit `triggerUpdate`
  ([known-issues §17a](../incidents/README.md)); same `rebroadcast()` workaround as the other two
  modules.
