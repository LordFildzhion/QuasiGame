# feetStim

**Status:** active Qt 6 service/executable `feetStim`, implementing the UDP/BNC frame-control mode for two 15×6 solenoid arrays. Gait animation, tracing workflow and standalone latency bench are outside this service's scope.

## Change locations and dependencies

| Change | Source |
|---|---|
| Force composition, mask, monitor override, packet serialization | [frame.cpp](../../src/feetStim/frame.cpp), [frame.h](../../src/feetStim/frame.h) |
| Serial/named-pipe lockstep and release | [stimlink.cpp](../../src/feetStim/stimlink.cpp) |
| Frame files and selected-frame behavior | [library.cpp](../../src/feetStim/library.cpp), [service.cpp](../../src/feetStim/service.cpp) |
| UDP grammar and presets | [udpcommand.cpp](../../src/feetStim/udpcommand.cpp) |
| Direct TTL link and PWM profiles | [triggerlink.cpp](../../src/feetStim/triggerlink.cpp), [pwmprofile.cpp](../../src/feetStim/pwmprofile.cpp) |
| Rig geometry/INI/UI | [settings.cpp](../../src/feetStim/settings.cpp), [footshape.h](../../src/feetStim/footshape.h), [feetview.cpp](../../src/feetStim/feetview.cpp) |
| Regression/build route | [feetstim_test.cpp](../../src/feetStim/tests/feetstim_test.cpp), [CMake](../../src/feetStim/CMakeLists.txt) |

This service opens its TTL board directly. **Do not assign the same serial port to arduinoTTL simultaneously.**

## Device and lifecycle contract

57600-baud COM with `Ver?` handshake, or named-pipe server `\\.\pipe\Stimuljator` with the emulator as client; connect the service before starting the emulator.

One frame consists of two 96-byte packets, one per foot: `Stim/Fizi` + foot `1/2` +90 force bytes + checksum. Each request waits for `Ok` or `E1/E2/E3`; control commands follow the same lockstep.

States: `init → ready → armed`; connect/disconnect/arm/release. Armed means the controller holds a loaded frame until a BNC edge. **Stopping TTL does not release pressure.** Mode1 holds outputs after the first sync pulse until two zero packets—one complete frame—arrive. `releaseHold`, release/disconnect and destructor send that frame. Forced process death skips it.

## Force and frame invariants

Current [frame.cpp](../../src/feetStim/frame.cpp) is the source of truth for this ordering:

1. Convert stored per-point strength using the mode/command override.
2. Zero points outside the geometry mask.
3. Force monitoring solenoids full when anything in the frame is active.

Monitors intentionally override the mask, including outside a traced foot. Moving them earlier removes the measurement channel on trimmed frames. An Off point stays off through strength transformation; the explicit monitor override is separate. Frames are always stored per-point, even in fixed-strength mode. PWM gating requires Mode2 and a generator.

Arming the currently selected slot sends its **unsaved editor frame**. Other slots load disk content. External changes to the selected frame file require reselection to be picked up.

## Command and stream contract

UDP/raw Message grammar:

```text
[<N>] [!] [_G<action>] [_TMS<ms>] [_S<override>]
```

`_Sf90` fixed, `_Si` individual, `_Sis+10` shifted, `_Spwm50-<profile>` gated. `_Gp/_Gt/_Gw/_Gf/_Gs` generator actions may include board-timed `@<ms>`. A generator action implies `!`; without a frame number it acts on the armed frame and avoids reload. `_TMS` supplies a command-specific BNC2 offset. Preserve the existing reply grammar, byte-valued L/R arrays and error spellings.

Nine fixed presets are the same UDP lines. `command` accepts these or JSON send/arm/release/connect/preset and recorded command events. Replay is a hardware action.

- `events`: commands with source, device/TTL errors, release and `frameArmed` containing the **actual 90 sent bytes per foot after all transforms**. A slot number cannot reconstruct delivered force.
- TTL fire events retain board microseconds and host RTC; TMS records distinguish standing rule from one-shot.
- `status`: Float64,20 named lanes at2Hz: device connection/verification/emulation/version/mode/errors, sent frames, selected/armed/active/dirty state, strength, mask, TTL state, TMS, preset, UDP.

Default UDP5005 conflicts with eStim. Set distinct ports explicitly; a bind failure reports in the monitor while the service stays running.

## Rig assets

The window's X exits the service normally through the destructor, including zero-frame release, device/TTL link closure and settings save. Setting `showUi=false` only hides the window and leaves the service running.

`feetStim.ini` beside the executable carries serial/emulation/UDP/TTL settings, geometry and preserved unused standalone keys. Traced outlines use grid coordinates and PNG side files. Current `showUi` is runtime-only, not restored from INI.

`bin/FrameLib/Frame<slot+1>` contains frame payloads. Build/install does not reconstruct rig INI/frame/PNG assets. Do not remove them as generated files. Missing configuration can restore **real COM4 with emulator=false** and UDP5005 defaults; preserve explicit rig configuration during [deployment](../how-to/deploy.md). The old observation that a particular rig had untraced feet/factory presets is not a guarantee about another rig.

## Validation and evidence

Registered `test_FeetStim` covers pure frame/grammar/profile behavior; profile code includes Widgets, so that dependency is required even for the test. See [test route](../how-to/test.md).

[Previous verification](../history/components/feetstim.md#history-7-verified) and [physical acceptance](../history/components/feetstim.md#history-8-hardware-bring-up) separate host/emulator parity from physical handshake, release, strength, monitor/mask and TTL checks. Source inspection confirmed force ordering; this restructure ran no device/emulator/UDP commands.
