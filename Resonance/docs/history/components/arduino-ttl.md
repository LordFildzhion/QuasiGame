# `arduinoTTL` — the two-channel TTL generator as a Resonance service — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/arduino-ttl.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-arduinottl--the-two-channel-ttl-generator-as-a-resonance-service"></a>


**Added 2026-08-16.** Module: `R:\src\arduinoTTL`. Service name `arduinoTTL`, launcher
`arduinoTTL.bat`.

**Ported to Qt 6, 2026-09-02, and hardware-validated the same day.** `arduinoTTL` is in the default
Qt 6.11.2 distribution: `R:\dist\bin\arduinoTTL.exe`, launcher
`R:\dist\arduinoTTL.bat` (the Qt 6 distro has no `msvc64\` level — `bin\` is at its root). The
Qt 5.15.2 comparator is `R:\src_Qt5\arduinoTTL` → `R:\dist_Qt5\msvc64\bin\arduinoTTL.exe`. Link
targets are now `Qt6::Core Qt6::Gui Qt6::Widgets Qt6::SerialPort Qt6::Network Qt6::StateMachine`;
the last is new, because Qt 5 shipped `QStateMachine` inside `Qt5::Core`. ⚠ **§8's board section is
out of date on its own: this service has since been run against a real board, which reports
firmware v2.4.** See the 2026-09-02 box in §8.

⚠ **`arduinoTTL.ini` has no install rule.** It is read from
`QCoreApplication::applicationDirPath() + "/arduinoTTL.ini"` (`service.cpp:110`), and
`R:\src\arduinoTTL\CMakeLists.txt` installs the executable and `arduinoTTL.bat` and nothing else;
`deploy-qt6.ps1` copies no `.ini`. So the Qt 6 distribution had none until one was copied in from
`R:\dist_Qt5\msvc64\bin\` on 2026-09-02, and without it the compiled defaults in `settings.h` apply
instead of the rig's file: an **empty `portName`** rather than `COM4`, `showUi=true` rather than
the rig's headless `false`, the **UDP listener off** rather than bound on 5007, `edgePollMs = 0`
rather than 250, an empty live panel script, and — the only slot that differs — the factory
`preset7` `2=IN,FALL ; V1 ; P100@i2+50*` in place of the rig's role-less `V1 ; P100@i2+50*`. The
other eight slots in the rig's file are already the compiled scripts. ⚠ **A fresh deploy does not
reinstate it** — there is nothing to reinstate it with. Copy it by hand after every deploy.
[`build_qt5-to-qt6-transition.md`](../migrations/qt5-to-qt6-transition.md) §8.

The board is an ATmega328P with two BNC connectors, at
`N:\Projects_MSU\2026 - FeetStim\exe\SolenoidConfig\arduinoTTL`. BNC1 is the main output; BNC2 is
a second output or a trigger input. It has been driving the FeetStim rig from `feetStim`'s TTL
bench page, and its whole reason for existing is that **it times its own onsets** — neither the
PC nor the USB link puts jitter into a stimulus.

---


<a id="history-2-the-board-in-one-page"></a>

## 2. The board in one page

Wiring is **fixed**, and the firmware assumes exactly it:

* **D9 → BNC1 centre**, with **D2 wired to the same node** as a loopback that timestamps the edge
  which really left the pin, and a **5.6 kΩ pull-up to 5 V**.
* **D3 → BNC2 centre**, with no external bias at all.

Because of that pull-up, **BNC1 rests HIGH and fires by going LOW**. It is a property of the
wiring, not a setting, and it is what keeps the line safe while the board resets — which an
Arduino Nano does *every time* a host opens its serial port.

Protocol: 115200 8N1, one LF-terminated command per line. `P` pulse, `T` train, `W` gated PWM
wave, `FC`/`FA`/`FS` amplitude profile, `S` stop, `V0`/`V1` verbosity, `ID?`/`E?`/`2?` queries;
`<n>:` addresses a channel and no prefix means channel 1; `@<ms>` / `@o1[+ms]` / `@i2[+ms]`
choose when a run starts and `*` makes it a standing rule. Full table in
`R:\src\arduinoTTL\doc\firmware-README.md` §4.

---


<a id="history-3-the-boards-language-is-the-api"></a>

## 3. The board's language is the API

This service does not invent a second vocabulary. It builds board commands from its parameters
and reads board commands back into them, and **anything it cannot model is passed through
unchanged**. Type `XYZZY42` into the send box and the board gets `XYZZY42`; put it in a preset and
it survives the round trip and is sent in place.

That matters because the firmware is richer than any window: a service that forwarded only the
subset its own panels render would be a downgrade from a serial terminal.

<a id="history-presets-are-scripts"></a>

### Presets are scripts

A preset is a short script in that language, semicolon-separated:

```
2=OUT,LOW ; V1 ; 2:P10@o1+30* ; T20,1000,50
2=IN,FALL ; V1 ; P100@i2+50*
V1 ; FC ; FA0,100,300 ; FA100,100,200 ; FA100,0,300 ; FS200
```

Nine of them, held in nine **fixed** `String` parameters — which is what keeps a saved service
configuration loadable, for the same reason as
[`eStim`](estim.md) ([known-issues §16b](../incidents/README.md)).

**The order is the content, not formatting.** `@o1` waits for OUT1's *next* start, so channel 2
must be configured and armed before channel 1 is commanded; and a profile must be uploaded before
it can be played. `Preset::commands()` puts the role first, then verbosity, then the channel-2
run, then the `FC`/`FA` upload, then channel 1 — once, so no caller has to remember. feetStim's
own session log records an experiment lost to getting that backwards, and TESTS.md §6c is written
about the same trap.

The nine defaults are the firmware's own bench test plan, in its order, so a new rig's first nine
clicks walk the acceptance procedure with nothing typed.

<a id="history-an-edit-is-a-save-2026-08-17"></a>

### An edit is a save (2026-08-17)

**There is no commit step.** Editing any field writes the selected slot, and 300 ms after the edit
stops moving it also reaches `arduinoTTL.ini` and the board. The panels and the slot cannot
disagree, so there is nothing to mark dirty and nothing to forget to press.

The debounce is not cosmetic: `onFieldChanged` fires on every spin-box tick, and a hundred setups
on a 115200 link while someone drags a value is a stall, not a feature.

Shift-clicking a preset button still copies the panels into *that* slot — "and also put it in 7" —
which is the one thing auto-save cannot express.

<a id="history-setup-and-fire-are-separate-2026-08-17"></a>

### Setup and fire are separate (2026-08-17)

`Preset::setupCommands()` is the D3 role, the verbosity, the armed channel-2 run, the profile
upload and any passthrough. `Preset::fireCommand()` is the single line that starts channel 1.
Together they are `commands()`, in that order — a unit test asserts it, because a stimulus fired
against a board that never got its setup is a silent wrong answer, not a visible failure.

**A run is one command on the wire.** The setup is pushed when a board identifies itself, and
again 300 ms after an edit; `run()` re-sends it only if the board is not already holding those
exact lines. Repeating a stimulus therefore costs `P8000` and nothing else — everything after the
first line is delay between the operator's intent and the edge.

`m_setupOnBoard` is the belief, and it is emptied wherever the belief stops being safe: a fresh
identification, a disconnection, an edit that changes the lines.

**Send setup** — the button where *Save preset* used to be, the `sendSetup` action, the `sendSetup`
transition from `ready`, and the `setup` verb on the command stream — pushes unconditionally. It
is for what those triggers cannot see: a board that was power-cycled behind the service's back, or
one whose state you have reason to doubt. The transition is deliberately **not** offered from
`running`, because leaving that state stops both channels.

<a id="history-bidirectional-translation"></a>

### Bidirectional translation

| Direction | Where |
|---|---|
| panels → script | the window's **Script** box rewrites itself as the fields move, and the selected slot is written with it — no commit step |
| script → panels | selecting a slot loads it; typing a script and pressing Enter loads it (**loads — it never sends**); editing `presetN` in the Configurator loads it when that slot is selected; a digit `1`–`9` over the command stream or UDP loads *and* sends it |

---


<a id="history-4-streams"></a>

## 4. Streams

<a id="history-events--message--json"></a>

### `events` — Message / JSON

Every line in both directions, plus a typed record per board event. This is the point of the
whole service: **the board's own microsecond stamp for every edge**, in a stream a recorder
writes into the same HDF5 file as the EEG.

```json
{"type":"fire","channel":1,"deviceUs":59767992,"line":"FIRE 59767992","rtc":"57777433369600"}
{"type":"fire","channel":2,"deviceUs":59789079,"line":"2 FIRE 59789079","rtc":"57777454623700"}
{"type":"error","channel":1,"detail":"period<=width","line":"ERR period<=width"}
```

**Two clocks, deliberately both.** `deviceUs` is the board's `micros()` at the edge and is exact;
`rtc` is when the line reached this process and carries the USB latency (~1–3 ms). An analysis
wants the first; a recorder needs the second to place it beside the EEG. Publishing one without
the other would silently substitute a serial round trip for a hardware timestamp.

Record types: `command`, `fire`, `done`, `arm`, `drop`, `stopped`, `waveStart`, `waveEnd`,
`profileStart`, `profileEnd`, `edges`, `error`, `ch2Role`, `connection`, `preset`, `run`,
`problem`, `refused`, `udp`, `identity`, `in2`, `ack`/`nack`.

<a id="history-status--float64-17-named-channels-2-hz"></a>

### `status` — Float64, 17 named channels, 2 Hz

`connected`, `verified`, `emulated`, `firmware.major/minor`, `ch1.state` (0 idle / 1 armed /
2 running), `ch1.fires`, `ch2.state`, `ch2.fires`, `ch2.role`, `edges`, `in2`, `out2`, `miss1`,
`miss2`, `preset`, `udp.bound`.

The channel states are **inferred from the board's own replies** — `ARM` → armed, `FIRE`/`WSTART`/
`PSTART` → running, `DONE`/`WEND`/`PEND`/`STOP` → idle. That is exactly as much as any host can
know; the board volunteers nothing else.

<a id="history-command--input"></a>

### `command` — input

Board commands (semicolon or newline separated, passed through) or JSON:
`{"command":"send","text":…}`, `"fire"`, `"stop"`, `"connect"`, `"disconnect"`,
`{"command":"preset","slot":4,"action":"launch"}`. A lone digit `1`–`9` launches a preset, `0`
stops everything. It also accepts this service's own `command` records, so a recorded session
replays through [`playbackService`](playback.md) into the board unchanged.

An optional UDP listener takes the same grammar. **Off by default** and on port 5007 — nothing
here needs a bound port, and a rig that does not use it should not have one open.

---


<a id="history-5--input-edges-are-invisible-unless-something-is-armed-on-them"></a>

## 5. ⚠ Input edges are invisible unless something is armed on them

The firmware **counts** an IN2 edge but never announces one: `onIn2Edge()` bumps a counter and
returns. `E?` reports the count but not a timestamp for it.

So an input that nothing is armed on cannot be observed in real time, and polling `E?` (the
`edgePoll` parameter, off by default) gives you a count at the poll rate and no instant at all.

**If the moment matters, arm a run on `@i2` with a standing rule** — `P100@i2+50*` — and every
incoming edge then produces a `FIRE` carrying the board's own microsecond stamp. That is the only
way to get a hardware-timestamped record of an external trigger out of this board, and it is
worth knowing before an experiment rather than after.

---


<a id="history-6-the-emulated-board"></a>

## 6. The emulated board

`--emulation`, or the `emulate` parameter, runs the service against a software model of the
firmware instead of a serial port: both channels and their state machines, the `@when` triggers
including standing rules, the armed-versus-busy rules and their `DROP`, the D3 roles, the
profile, the counters, and every reply spelling.

It exists for the reason `neuroMS` carries a software stimulator — everything above the wire can
be verified today, and again after every later change, without booking the hardware. It is also
what made §8 possible.

⚠ **It models the protocol, not the physics.** It advances on a 1 ms Qt timer, so a `@o1+20`
offset measures 20.0–21.1 ms here where the real board is exact to microseconds. Nothing measured
in emulation is evidence about the real board's timing.

The **External edge** button is the one thing the real board cannot offer: an IN2 edge on demand,
so an `@i2` arrangement and its standing rule can be rehearsed at a desk with no function
generator.

---


<a id="history-7-what-was-changed-from-feetstims-triggerlink"></a>

## 7. What was changed from feetStim's `TriggerLink`

The command spellings and capability gates come across as they are. Three things did not.

**The handshake is asynchronous.** `TriggerLink::open()` blocks in `waitForReadyRead()` for up to
2.4 s, retrying `ID?`, because the two supported boards behave differently when the port opens —
a Nano is reset by DTR and reboots for ~1.5 s, an Xplained Mini answers at once. That is fine in a
dialog and wrong in a service: it would stall discovery, the EventBus and every stream for the
duration. Here the `ID?` is re-sent on a timer until an answer arrives.

**`sendChecked()` is gone** for the same reason — it blocked waiting for a reply so that a
refused channel-2 setup would not be mistaken for an installed one. Here every reply is parsed
asynchronously and an `ERR` is published on `events`, which is a better answer than a blocked
event loop: a caller that needs to know can watch the stream.

**`arduinoScale` is not supported.** `TriggerLink` accepts either board because feetStim can
trigger a frame from the force rig's board too. This service is about the generator; a board that
answers `arduinoScale` will identify itself and then refuse most of what is asked of it.

---


<a id="history-8-verified"></a>

## 8. Verified

**Unit — `test_ArduinoTtl`, 25/25.** The command grammar (every kind × every trigger round trip,
`@0` collapsing to "now" as the firmware does, `*` only on events, the deprecated `D<d>,<w>` form
modernised), every reply spelling from README §4c including the `2 ` prefix, every guard from
TESTS.md §12, the profile one-liner and its `FC`/`FA` upload, and the preset script — ordering,
round trip, and unknown commands surviving verbatim. All board-free and GUI-free by construction.

**Live — against the emulated board**, driven over UDP and read over the EventBus:

| | |
|---|---|
| Service | 53 parameters in five groups, **all 53 with tooltips**; `init` offers only `connect` |
| Handshake | `connect` → `arduinoTTL v2.3 out1=D9 mon1=D2 ch2=D3 idle1=HIGH`, then `ready` offers `start` and `disconnect` (⚠ **the emulator's** version string, and it matches no board yet seen: the TMS rig answered **v2.2** on 2026-08-22 and COM4 answered **v2.4** on 2026-09-02 — see the two boxes below §8) |
| Streams | `@`, `events`, `status`; 46 events and 12 `fire` records in 26 s; status **17 channels**, declared 2 Hz, **1.92 Hz** measured |
| Pulse | `P100` → `FIRE 55767453` → `DONE 55868007` — 100.55 ms |
| Train | `T5,200,20` → five `FIRE` records indexed 1…5, ~200 ms apart, then `DONE n=5` |
| **Standing rule** | `2:P30@o1+20*` then three separate `P50` shots: channel 2 fired **every time**, at +21.1, +20.0 and +20.1 ms, with no re-arming |
| Guards | `2:W200,30,1000` → `DROP` then `ERR ch1 only`; `T5,20,20` → `ERR period<=width`; `W0.1,50,1000` → `ERR hz` — the three from TESTS.md §12 |
| Wave | `W500,40,600` → `WSTART` → `WEND edges=300`, which is 500 Hz × 0.6 s |
| Counters | `E?` parsed into `edges`/`in2`/`out2`/`miss1`/`miss2` |
| Presets | digit `4` and `7` over UDP loaded and sent their scripts and moved the selected slot; preset 7 put BNC2 into `Input, falling edge` |
| Lifecycle | `!terminate` exits cleanly and writes `arduinoTTL.ini` with the live state and all nine presets as scripts |

⚠ **No board was attached.** Only a Bluetooth COM port was present on this machine. Everything
above is the emulator; §9 is the hardware bring-up.

<a id="history-qt-6-parity-2026-08-28"></a>

### Qt 6 parity, 2026-08-28

`test_ArduinoTtl` (25 cases) is registered with CTest in the Qt 6 tree and passed in the final
17/17 run (`R:\src\docs\qa\ctest-qt6-final.log`). One external protocol test then drove the Qt 5 and
the Qt 6 binary identically: 53 parameters, the complete operator help, the emulated firmware
identity, `OK P100`, `OK T3,80,10`, four `fire` events and the same 1×17 `status`. Evidence:
`qa/arduinottl-qt5-parity.log`, `qa/arduinottl-qt6-parity.log`, and the screen pair
`qa/arduinottl-qt5-reference.png` / `qa/arduinottl-qt6.png`; `R:\src\docs\VALIDATION.md`,
2026-08-28 section.

> ## ⭐ A REAL BOARD, 2026-08-22 — what it actually answered
>
> The first board this project has attached. `R:\tests\lab-session-20260822\REPORT.md`.
>
> * **The firmware is v2.2, not v2.3.** `ID?` → `arduinoTTL v2.2 out1=D9 mon1=D2 ch2=D3
>   idle1=HIGH`. **The pin map above is exactly right**; the grammar matched; one command does
>   not exist.
> * ⚠ **Channel 1 has no role command on v2.2.** `1=OUT,LOW` answers `ERR unknown`. **D9 is a
>   permanent output** and needs no role applied — which is why a sequence written as "give
>   channel 1 an output role, then pulse it" fails at the first line and works with that line
>   removed. `2=OUT,LOW` for channel 2 is unaffected and still emits one edge when applied.
> * **It is a Nano.** `--sniff 6` caught `arduinoTTL v2.2 ready` at **+1.478 s** after
>   port-open, i.e. the DTR reset in §9 step 2 is real on this rig.
> * **Channel-1→channel-2 dispatch gap: 0.838 ms median** (840, 832, 836, 840 µs) from one
>   write of `P1
2:P1
`, on the board's own microsecond clock. That is the dominant term in
>   the rig's 0.840 ms "command → pulse" figure — see `_notes/report_trigger-validation.md`.

> ## ⭐ A REAL BOARD UNDER Qt 6, 2026-09-02 — and the firmware moved again
>
> The **deployed Qt 6 service** was run against a physical board. The record is
> `R:\src\docs\KARDI2NP_ARDUINOTTL_HARDWARE_VALIDATION_2026-09-02.md`, which is the newest document
> in the project and is filed in the port's own doc set rather than here. Read it before planning
> §9. What it establishes:
>
> * **The board on COM4 reports firmware v2.4**, not the v2.3 the emulator claims and not the v2.2
>   §8's 2026-08-22 box measured. `ID?` → `arduinoTTL v2.4 out1=D9 mon1=D2 ch2=D3 idle1=HIGH`, so
>   **the pin map in §2 is confirmed a third time**. The service parses the v2.4 banner correctly.
>   ⚠ **Feature parity with v2.4 cannot be claimed**: the source tree, `doc/arduinoTTL.ino` and the
>   emulator are all still v2.3, and the v2.4 sketch or its changelog has not been supplied. This is
>   the most actionable open item on the module — until it lands, the emulator models a firmware
>   nobody is running.
> * **Opening COM4 reset the Nano without producing a BNC1 edge**, and the boot banner arrived as
>   `arduinoTTL v2.4 ready` — the §9 step 2 DTR reset, again, on this board.
> * **The deployed Qt 6 service completed its reset/handshake**, selected COM4, reported firmware
>   2.4 **through the `events` stream**, accepted `S ; 2=OFF ; 2? ; E? ; ID?`, and disconnected back
>   to `init` cleanly. A direct serial connection afterwards independently confirmed BNC1 stopped,
>   `CH2 OFF` and zero edges or misses — so the service's idea of the board and the board agreed.
> * **`E?` and the stop discipline held on real hardware.** Bare `S` answered `STOP` and parked BNC1
>   at its inactive HIGH; `2=OFF` released BNC2 to high impedance; `E?` reported zero OUT1, IN2 and
>   OUT2 edges and zero missed events.
> * **`test_ArduinoTtl` passed** in the same session.
> * **In a physical loop with a KARDi2-NP**, a ten-pulse BNC1 train (200 ms period, 50 ms active)
>   produced exactly ten falling and ten rising transitions on the amplifier's Trigger-1-In lane,
>   and five commanded amplifier output cycles produced exactly five rising edges at BNC2 — with
>   ten `FIRE` events plus one `DONE n=10` and no misses, recorded into the same HDF5 file as the
>   amplifier stream. That is the first end-to-end evidence that this service's event stream lands
>   correctly beside acquired data.
>
> ⚠ **What it does not establish.** No scope or logic analyser was used, so every static level and
> every edge here is a *software counter*, not an electrical measurement — §9 steps 3, 5, 6 and 8
> are untouched. On the Sync1 wiring the Arduino's IN2 counter also followed the *incoming* BNC1
> pulses, which the Sync2 run did not reproduce; the document treats that as a harness or port
> artefact needing a scope, not an `arduinoTTL` counting fault.

---


<a id="history-9-hardware-bring-up--what-to-do-when-a-board-is-available"></a>

## 9. Hardware bring-up — what to do when a board is available

The firmware's own `R:\src\arduinoTTL\doc\firmware-TESTS.md` is the test
plan, and the nine shipped presets are its steps in order. Do it **with BNC1 on a scope, not on
the stimulator** — every one of them produces real trigger edges.

⚠ **This list is no longer entirely outstanding.** The 2026-09-02 session in the §8 box did steps 1
and 2 on a real board under the deployed Qt 6 service, and demonstrated the counted parts of steps 4
and 7 through a physical loop to a KARDi2-NP. What it did **not** do is put an instrument on a wire:
every step below whose evidence is a voltage or a microsecond interval — 3, 5, 6, 8 — is untouched,
and so is step 9. Read that box first, then start here at step 3.

1. Flash the sketch. Check the wiring against §2 above, in particular that the **5.6 kΩ pull-up is
   fitted** — without it a board reset floats the stimulator's sync input.
2. `arduinoTTL.bat`, **Rescan**, pick the port, **Connect** (uncheck *Emulate* first). The status
   line should turn green with the version banner within a second or two on an Xplained Mini, or
   after the Nano's ~1.5 s reboot. **On the TMS rig this is `arduinoTTL v2.2 ready`, measured at
   +1.478 s — a Nano.** Do not treat a v2.2 banner as a wrong board. ⚠ Nor a **v2.4** one: that is
   what the board on COM4 answered on 2026-09-02. Two board revisions have now been seen on this
   bench, v2.2 and v2.4, and the emulator models neither — it is v2.3.
3. **Measure D9 to GND: it must read ≈5 V at rest.** If it rests LOW the polarity is inverted —
   stop, do not connect the stimulator.
4. **Preset 1** (`P500`). The meter should dip to ≈0 V for half a second, and the events stream
   should carry one `fire` and one `done` about 500 ms apart.
5. **Preset 2** (`P50@200`): `arm`, then a `fire` 200 ms later. Both ends are hardware-timestamped,
   so check `deviceUs` differs by 200 000 ± a few hundred — this is the claim the whole board
   exists to make and it is worth measuring once.
6. **Presets 3–6**, on the scope, per TESTS.md §4–§7. §5 is the interesting one: zoom to 10 µs/div
   and expect BNC2 to lag BNC1 by a consistent **5–15 µs**.
7. **Preset 7** (`@i2`) needs an external edge — a function generator, or a wire briefly touching
   BNC2 centre to GND.
8. **Presets 8 and 9**, the wave and the profile. Check `WEND edges=` against carrier × duration.
9. Only then onto the stimulator, and in Mode 1 before Mode 2 gating.

⚠ **Send `S` before disconnecting.** The transport does it on the way out, and `!terminate` runs
that path — `taskkill` does not.

---


<a id="history-10-traps"></a>

## 10. Traps

* **`testing::Test` has a private member `Run()`**, so inside a `TEST` body an unqualified `Run`
  used as a *type* resolves to it and the enum is hidden. `Run::Pulse` is fine (a qualified-id
  ignores non-type names); `const Run kinds[]` is not. Qualify it.
* The emulator stores an uploaded profile, so `transport.h` needs `profile.h` — a header that
  looks like it only needs the command grammar.
* `--emulation` is read with `isSet()`, not `value()`. An option that takes no value always
  answers an empty string, which is how the same flag came to do nothing on two drivers in this
  tree already ([known-issues §14e](../incidents/README.md)).
* `Double::setMinimum/setMaximum` and `Select::setIndex` do not emit `triggerUpdate`
  ([known-issues §17a](../incidents/README.md)); same `rebroadcast()` workaround as `eStim`.
* A preset **loads** when its script is typed and **fires** only on Fire or a digit. Its *setup*
  does go out on an edit — that is the point — but nothing that produces an edge does.
* ⚠ **The board does not tell you it stopped.** A bare `S` is
  `stopChannel(0, true); stopChannel(1, false)`, so **channel 2 is always stopped silently**, and
  channel 1's `STOP` is gated on verbose (`if(report && verbose)`, arduinoTTL.ino:642) — under
  `V0` there is no reply at all. The comment above the `verbose` flag claims `STOP` survives `V0`;
  the code disagrees, and the code is what runs. `stopAll()` therefore clears the service's own
  channel model rather than waiting to be told. Waiting is what left the service latched in
  `running` with the STOP button stuck until the next run reset the model as a side effect.
* ⚠ **`syncState()` emits `connectionChanged` before the machine has moved.** `performTransition`
  is queued and `QStateMachine` processes it on its own turn, so anything reading `stateName()`
  from that signal sees the state being *left*. Each state's `entered` signal re-emits it; without
  that, a status readout can sit on a state the service is no longer in.
