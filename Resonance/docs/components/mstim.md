# mStim

**Status:** active Qt 6 service/executable `mStim`; four-magnet maglev controller with two- or four-magnet rig mode. Firmware and protocol notes live in [src/mStim/doc](../../src/mStim/doc).

## Change locations

| Change | Source |
|---|---|
| Pure compose/parse and limits | [stimulus.cpp](../../src/mStim/stimulus.cpp), [stimulus.h](../../src/mStim/stimulus.h) |
| Parameter/state/event/command interface | [service.cpp](../../src/mStim/service.cpp) |
| Persistent rig configuration | [config.cpp](../../src/mStim/config.cpp) |
| Serial pacing and reset/banner behavior | [seriallink.cpp](../../src/mStim/seriallink.cpp) |
| Operator editor/diagram | [mainwindow.cpp](../../src/mStim/mainwindow.cpp), [magnetdiagram.cpp](../../src/mStim/magnetdiagram.cpp) |
| Firmware and regression route | [firmware](../../src/mStim/doc/maglev_Resonance_newmode_Jul2026.ino), [tests](../../src/mStim/tests/mstim_test.cpp), [CMake](../../src/mStim/CMakeLists.txt) |

## Device and state contract

Arduino Nano, two L298N bridges, 115200-baud serial. The firmware has **no persistent library or EEPROM**. Opening the port toggles DTR and resets the board. Connection is not readiness: `ready` permits programming; `programmed` means the ordered program burst has been sent.

**Program all order:** parameters → `=d` default state → all 15 definitions → TTL arm. Arming references IDs that must already exist. A reset banner clears `programmed`; never silently reprogram/rearm after reset.

IDs `0` (all off) and `98` (apply default) are reserved. Presets are verbatim firmware definition lines. `stimulus.line` composes from fields and parses back into them; fifteen `preset<N>` entries cover device RAM capacity.

## Grammar and physical invariants

Examples are definitions, **not commands to execute during code review**:

```text
=1M1U50M2D100T150K1
=7M1U100M2OT50I150R4K0
=3M1U80M2D80T50,-150,100K2
=9Wd,d_T500:100,0_H200K0
=dM1OM2D30
!M1U50M2D50T100K0
```

- `U/D` describes motion, mapped to H-bridge pins by measured `M<n>_orient`; firmware defaults are only conventions.
- Omitted magnets are off. Do not assume their previous state survives.
- Always write terminal `K`, including `K0`; omission can retain an earlier kind. A5/A4 carry the 2-bit kind, A3 strobes ON phases.
- Sweep `d` is a **live** device-side reference to the current default. Do not bake it into a numeric preset.
- The default applies between packet pulses and after stimuli, not only on ID98.
- Timer1 controls the shared PWM carrier for M2/M3 (D10/D9); M1/M4 use fixed Timer2 carrier. Duties are independent. Read the device's snapped achievable frequency.
- TTL D2/INT0 edge and lockout (`TTL_input_edge`, `TTL_input_timeout`) remain terminal settings; arming must not override them.
- Composer rejects >220 characters. List ON intervals are ≤3000 ms, OFF intervals ≤10000 ms by position; parsing refusal leaves the base unchanged.
- Firmware **blocks during stimuli**. TTL edges during a pulse/packet/sweep are discarded. A serial `0` takes effect only afterward; it is not an immediate emergency stop.

[Detailed grammar and rationale](../history/components/mstim.md#history-2-the-grammar).

## Streams and persistence

The window's X exits the service normally, including the existing all-off/serial-close cleanup and configuration save. Setting `showUi=false` only hides the window and leaves the service running. The firmware's blocking-command limitation above still applies during shutdown.

`events` records lines both directions and typed launch/program/params/defaultState/allOff/connection/preset/reply/refused records. A launch carries the exact transmitted definition, ID and kind. `status` is Float64, 22 named lanes at 2 Hz: connection/programmed/magnet count/launches, edited stimulus, four powers/defaults, PWM, TTL arm/ID and preset.

`command` accepts raw firmware lines separated by newline/semicolon or JSON `send`, `launch`, `allOff`, `program`, `connect`, `disconnect`, `preset`. It accepts its own command records for replay; replay can actuate hardware.

`mStim.ini` beside the executable contains presets, orientations, defaults, TTL/port/UI settings. Build/deploy does **not** install rig-specific configuration. Preserve it through deployment; do not generalize the old observation that one machine's file held only default baud.

## Validation and current boundary

Registered `test_MStim` tests pure grammar, round trips, reserved IDs and limits; use [test workflow](../how-to/test.md). Prior host/Qt parity checks used a serial endpoint without magnets and do not establish device behavior. [Hardware acceptance and prior evidence](../history/components/mstim.md#history-6-hardware-bring-up) retain orientation/default/PWM/TTL checks. Physical acceptance remains required; no serial commands or tests were run for this documentation change.

2026-09-18 bench update: the connected August-2026 firmware executed real pulse
commands with stimulation outputs disconnected. Its direct active-high TTL on
NVX Trig5 coexisted with A1 → Nano active-low Trig4 at 2 kHz, all expected pulses
retained. Requested 100-ms mStim strobes measured 101–101.5 ms; loaded behavior
and precision timing remain unverified. See [dual-trigger acceptance](../history/components/mstim.md#dual-trigger-20260918).
The vendored July `.ino` is historical, not the connected firmware's source.
