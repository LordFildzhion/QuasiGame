# eStim

**Status:** active Qt 6 x64 service/executable `eStim`; replaces retired x86 MioStim. It controls Neurosoft electrical stimulators through the native vendor API.

## Change locations and dependencies

| Change | Source |
|---|---|
| Single parameter/state authority, clamps, transitions and streams | [service.cpp](../../src/eStim/service.cpp), [service.hpp](../../src/eStim/service.hpp) |
| Token scanner, command sequences, preset compose/parse | [tokens.cpp](../../src/eStim/tokens.cpp), [commandengine.cpp](../../src/eStim/commandengine.cpp), [preset.cpp](../../src/eStim/preset.cpp) |
| Device ABI/lifecycle | [miostim.cpp](../../src/eStim/miostim.cpp), [miostim.h](../../src/eStim/miostim.h) |
| Timing/coupled values | [params.cpp](../../src/eStim/params.cpp), [params.h](../../src/eStim/params.h) |
| Rig settings/UI | [settings.cpp](../../src/eStim/settings.cpp), [mainwindow.cpp](../../src/eStim/mainwindow.cpp), [pulsediagram.cpp](../../src/eStim/pulsediagram.cpp) |
| Build/grammar tests | [CMake](../../src/eStim/CMakeLists.txt), [preset_test.cpp](../../src/eStim/tests/preset_test.cpp) |

Native `NsEzUSB.dll`/`ELECTROSTIM.dll` are x64; generated import libraries derive from their exports. Device handle `NSDEV` is pointer-sized, not the old x86 `uint32_t`. Both architectures need the **newezusb kernel driver** providing `\\.\Ezusb-N`; WinUSB is not interchangeable.

## One state authority

Window, serial, UDP, stream and EventBus inputs write `Parameters::*`; parameters drive hardware and reflected UI/events/status. Do not add a widget-only validation/state path. State follows channel reality through guarded reconciliation; a remote transition into running with no active channel starts the selected launch target.

`init → ready → running`, connect/disconnect/start/stop; disconnect is available while running. Reopening an already selected device must be a no-op, because every completed train re-enters ready and revisits device selection.

## Command and preset contract

Uppercase targets stimulator1; lowercase targets2. Frequency is always **Hz on the wire**; Frequency/SOA is only a window display choice.

| Token | Meaning |
|---|---|
| F, D, A, N | Frequency Hz; whole-pulse duration µs; amplitude mA; pulse count |
| P | Waveform P/N/A/B/C or0–4 |
| I | Biphasic interphase µs |
| R, Y | Pre-pulse width µs and amplitude percent −50..50 |
| T1/T2/TB | Launch target |
| B/E | Begin/end |
| W | Non-blocking sequence wait in ms |

Bare tokens apply now; `=x<tokens>` defines a sequence, letter `x` runs it; `!<tokens>` one-shot; `@` lists; digits1–9 load/launch presets;0 or `-` stops. One scanner serves command and preset paths. Whitespace is optional. Unreadable tokens are reported and skipped while other valid tokens apply: do not mistake partial acceptance for an atomic transaction.

Nine String presets carry both panel values and launch target. Loading a preset parses from defaults (omitted means off); an incremental command parses from live values (omitted means unchanged). Optional inactive tokens are omitted. Single-mode output omits lowercase half/target. Current framework supports dynamic parameter application; the historic recorder manual-configuration workaround is superseded.

## Limits and timing

Enforce in parameter/device logic for **every input**, not only in widgets:

- Frequency ≤min(configured cap,40000Hz), because DAC period ≥25µs.
- Duration ≤period and configured cap; unlocked maximum51200µs.
- Biphasic interphase ≤duration−50µs; monophasic forces0.
- Pre-pulse ≤period−duration; percentage −50..50.
- Default amplitude cap7mA; unlocked maximum99mA. Parameter maximum tracks the live cap, so an out-of-range JSON write is refused rather than silently represented as delivered.
- Frequency changes recalculate dependent caps/values; publish every clamp with requested/applied values.
- Unlock is an ordinary remotely writable parameter; the UI padlock confirmation is not an access-control boundary.

The device gives **no per-pulse or completion feedback**. Train completion is inferred with a timer from `(N−1)/f + pulse`. `Timing::trainMs` must remain shared by diagram/status/event/completion logic. `trainStart` includes duration/spacing so downstream code can reconstruct expected timing; it does not prove actual pulse onsets.

Factory presets7–9 are **calibration-load** commands at1/10/99mA. Preserve their meaning and load-only boundary; they are not routine participant presets.

## Interfaces and persistence

Groups `main`, `device 1`, `device 2`, `presets`, `safety`, `link` use banded indices for tab order. Stable keys include suffixed frequency/duration/amplitude/amount/waveform/interphase/prePulse/prePulsePct, preset1–9, caps/unlocks, command input, serial/UDP/status interval.

`events` is versioned Message JSON with decimal-string `rtc`: command/source, parameters/line, trainStart/End, clamp, refused, preset, limit, lifecycle, problem and ack/nack. `status` is Float64,31 named lanes at default2Hz; changing interval recreates the stream because rate belongs to its description.

`command` accepts text or JSON send/start/stop/connect/disconnect/preset/set and the service's own command records. Acknowledgements identify refusal; absence is not success. Connecting replay can stimulate hardware.

Precedence: defaults → executable-adjacent `eStim.ini` → `--serviceConfig` → runtime writes. Legacy preset INI sections upgrade to line strings. Rig settings have no build/install rule; preserve them explicitly. Current settings code ignores/removes INI `showUi`. Setting `showUi=false` hides the window while the service stays alive; the window's X exits the service normally, including device stop/release and settings save. Default UDP5005 clashes with feetStim; configure distinct ports.

## Validation and evidence

Registered `test_EStimPreset` covers scanner/translation/timing and round trips; see [test workflow](../how-to/test.md). [Prior verification](../history/components/estim.md#history-12-verified), [hardware procedure](../history/components/estim.md#history-13-hardware-bring-up--what-to-do-when-a-stimulator-is-free) and [VALIDATION](../../src/docs/VALIDATION.md) distinguish host/Qt parity from calibration-load/device acceptance.

Parameter range refresh uses service `rebroadcast()` around framework setters that do not notify automatically; preserve visible live caps when changing them. The old claim that recorder `autoStart`/stream configurations require manual workaround is fixed in [framework](../architecture/framework.md) and [recorder](recorder.md). No stimulator commands or tests ran during this documentation change.
