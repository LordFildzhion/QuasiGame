# Arduino TTL

**Status:** active Qt 6 service/executable `arduinoTTL`. It controls a two-channel ATmega328P generator and publishes board event timestamps. Firmware, host emulator and a connected board may be different versions.

## Change locations

The dedicated external **Nano TTL repeater** is a different firmware/project,
not this full generator. Its 2026-09-18 input-back-power / long-pulse incident
is tracked as [TTL-001](../issues/README.md#ttl-001); the
[investigation](../history/investigations/diode-trigger-viewer-20260918.md)
routes to the external project's current wiring and recovery guidance.

| Change | Source |
|---|---|
| Wire grammar, bidirectional panel translation | [ttlcommand.cpp](../../src/arduinoTTL/ttlcommand.cpp), [preset.cpp](../../src/arduinoTTL/preset.cpp), [profile.cpp](../../src/arduinoTTL/profile.cpp) |
| Serial handshake, capability gates, stop discipline | [transport.cpp](../../src/arduinoTTL/transport.cpp) |
| Emulated board/state timing | [board.cpp](../../src/arduinoTTL/board.cpp) |
| Parameters, setup cache, events and UDP | [service.cpp](../../src/arduinoTTL/service.cpp) |
| INI and UI | [settings.cpp](../../src/arduinoTTL/settings.cpp), [mainwindow.cpp](../../src/arduinoTTL/mainwindow.cpp), [ttldiagram.cpp](../../src/arduinoTTL/ttldiagram.cpp) |
| Protocol specification and tests | [firmware docs](../../src/arduinoTTL/doc), [ttl_test.cpp](../../src/arduinoTTL/tests/ttl_test.cpp), [CMake](../../src/arduinoTTL/CMakeLists.txt) |

The host link is derived from [feetStim](feetstim.md), but its handshake is asynchronous. Shared ancestry is not shared source ownership. Do not block discovery/streams with serial wait loops. The `arduinoScale` board is not a supported replacement generator.

## Electrical and wire contract

Fixed wiring: D9→BNC1 with D2 loopback on the same node and a 5.6 kΩ pull-up to 5 V; D3→BNC2 without external bias. BNC1 rests **HIGH**, fires LOW. The pull-up protects the idle level during DTR resets on serial open. Polarity is a wiring property.

115200 8N1, LF-terminated commands. `P` pulse, `T` train, `W` gated PWM, `FC/FA/FS` profile, `S` stop, `V0/V1` verbosity, `ID?/E?/2?` queries. No prefix means channel1; `2:` addresses channel2. Scheduling forms `@<ms>`, `@o1[+ms]`, `@i2[+ms]`; trailing `*` is a standing rule. Full syntax lives in [firmware-README](../../src/arduinoTTL/doc/firmware-README.md).

Unknown commands pass through unchanged: the GUI models a subset of firmware and must not restrict terminal capabilities.

## Preset/setup invariants

Nine fixed String presets contain semicolon-separated **scripts**, not opaque slot IDs. Their ordering is executable content:

1. Set channel2 role.
2. Set verbosity.
3. Arm channel2 run.
4. Upload profile.
5. Start channel1.

`@o1` waits for OUT1's **next** start; arming after that start loses the event. Upload profiles before use.

`setupCommands()` and `fireCommand()` compose into `commands()` in that order. Editing fields saves the selected slot immediately and debounces INI/setup transmission by 300 ms. Typing a script loads it; Fire or a command digit launches it. Setup can include channel2 role/arming effects; do not assume a configuration write is purely local.

The setup cache is invalidated by identification, disconnect and changed setup lines. Repeated runs send one fire command when the board is believed configured. Explicit `sendSetup`/`setup` pushes setup unconditionally and is offered from ready, not running: leaving running stops channels.

## Streams and clocks

- `events`: Message JSON containing raw lines and typed command/fire/done/arm/drop/stopped/wave/profile/edge/error/role/connection/preset/run/problem/refused/identity/ack records.
- `status`: Float64, 17 named lanes at 2 Hz: connected, verified, emulated, firmware major/minor, channel1/2 state and fires, channel2 role, edge/input/output counters, misses, selected preset, UDP bound.
- `command`: raw newline/semicolon-separated board commands or JSON send/fire/stop/connect/disconnect/preset/setup. Digits1–9 launch presets;0 stops. Own command records can be replayed directly and can actuate hardware.
- Optional UDP accepts the same grammar, disabled by default, default port5007.

Preserve **both clocks**: `deviceUs` is board `micros()` at its event; decimal-string `rtc` is host arrival and includes transport delay. They are not interchangeable or inherently synchronized.

IN2 edges are counted but not independently timestamped/reported by the documented firmware. `E?` polling supplies counts only. An armed `@i2` run yields a timestamped response `FIRE`; interpret that as its scheduled output response, including any configured offset, rather than inventing a raw input timestamp.

Channel state follows replies, but bare `S` can stop channel2 silently and suppress channel1 STOP under V0. `stopAll()` must clear the host model rather than wait forever for a reply. Queued state transitions require notification after actual state entry.

## Persistence and teardown

`arduinoTTL.ini` is beside the executable and is not supplied by build/install. Preserve rig port, UDP, polling and scripts through deploy. **`showUi` is a runtime switch; current settings code does not restore/persist it from INI.** The old INI-based headless warning is superseded.

Graceful disconnect/termination sends stop; force-killing bypasses cleanup. Confirm the physical board's role/idle behavior in hardware acceptance.

## Validation and evidence

Registered `test_ArduinoTtl` checks grammar/setup order and protocol emulator; see [test workflow](../how-to/test.md). Emulation uses a 1-ms Qt timer and models protocol, not microsecond electrical timing.

[2026-09-02 hardware record](../../src/docs/KARDI2NP_ARDUINOTTL_HARDWARE_VALIDATION_2026-09-02.md) observed firmware2.4, correct handshake/stop, counted ten pulses through KARDi2 and recorded events. The vendored sketch/emulator documented as2.3 does not establish feature parity with that board. No oscilloscope verified voltage or microsecond delays; Sync1 cross-counting needed electrical investigation. [Original detailed evidence and scope](../history/components/arduino-ttl.md#history-8-verified). This restructure ran no firmware, serial or hardware checks.
