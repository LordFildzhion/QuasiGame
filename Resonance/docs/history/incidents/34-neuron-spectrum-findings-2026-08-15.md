# 15. Neuron-Spectrum findings, 2026-08-15

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-15-neuron-spectrum-findings-2026-08-15"></a>

### 15. Neuron-Spectrum findings, 2026-08-15

**TRANSFERS UNCHANGED, with one exception.** `neuronSpectrum` was ported on 2026-08-29: it links
Qt 6 Core/StateMachine while `ns65bridge.dll` stays a `/clr` native-C boundary to the same Neurosoft
managed assemblies — no Qt object crosses it — and the private Intel IPP 8.1 DLLs are installed
beside the service in `R:\dist\bin`. So 15a–15d, 15f and 15g are vendor-SDK behaviour and are
identical under both. ⚠ **§15e is the exception: FIXED BY THE PORT** — see there.

Everything here was found while building [`neuronSpectrum`](../components/neuron-spectrum.md). The first four
are in the vendor SDK and will bite anyone else who drives it; the last two are ours.

<a id="history-15a-the-offline-impedance-unit-is-refused-by-the-amplifier--open"></a>

### 15a. The offline impedance unit is refused by the amplifier — open

`ImpedanceUnit.Start()` answers, on the asynchronous error callback rather than by throwing:

```
Module returned an error. Module: Amplifier. Long command: 4. Error: 101.
```

`IsRun` then reads true and all 57 electrodes report `IsMeasureOn`, but no measurement ever
runs and every value stays 0. Reproduced through the bridge and through raw PowerShell against
the vendor assemblies, with and without the COM channel enabled, with `MeasuredElectrodesMask`
fully set, and after `SetConfig()`. Cause unknown — a question for Neurosoft.

**Online impedance works** and is what the driver uses; see
[neuron-spectrum §6](../components/neuron-spectrum.md#history-6-impedance--read-this-before-using-it). The dangerous
part was not the refusal but that it is *asynchronous*: `Start()` returns success, so a naive
driver publishes 57 electrodes at 0 Ω, which an operator reads as perfect contact. The bridge
now latches the error and fails the start with the device's own message.

<a id="history-15b-marshal_as-destroys-every-non-ascii-sdk-message---fixed"></a>

### 15b. `marshal_as<std::string>` destroys every non-ASCII SDK message — ✅ fixed

The vendor SDK reports in Russian. `msclr::interop::marshal_as<std::string>` converts through
the **ANSI code page**, so every diagnostic arrived as a row of question marks — exactly when
it mattered. Converting explicitly through `System::Text::Encoding::UTF8` is what made
everything else in this list diagnosable.

Note the second half of the trap: even with the bridge producing correct UTF-8, `qWarning()`
re-encodes to local 8-bit on the way to stderr, so a *service log* still shows mojibake. The
string in the `QString` is correct and reaches the Configurator intact; only the console
rendering is lossy.

<a id="history-15c-the-impedance-threshold-setters-cross-validate---fixed"></a>

### 15c. The impedance threshold setters cross-validate — ✅ fixed

`ThresholdLowValue` and `ThresholdHighValue` each reject a value that would cross the other,
*including transiently while only one has been written*. On a fresh device `High` is 0, so
writing `Low` first throws *"Нижний порог импеданса превышает верхний!"*. The vendor's own
example writes `High` first. The bridge now writes whichever can be written without crossing
the value already in place.

<a id="history-15d-impedanceunitstart-does-not-push-the-monitoring-configuration---fixed"></a>

### 15d. `ImpedanceUnit::Start` does not push the monitoring configuration — ✅ fixed

`StartReadData` calls `MonitoringConfig.SetConfig()` internally; `ImpedanceUnit.Start()` does
not. Without an explicit `SetConfig()` the unit starts and measures nothing. Related: the unit
measures the channels the configuration has *enabled*, so the channel selection has to be
applied first as well.

<a id="history-15e-resonanceforeigndriversendparameterstoservice-applies-nothing--open"></a>

### 15e. `ResonanceForeignDriver::sendParametersToService` applies nothing — open

**FIXED BY THE PORT — measured, 2026-08-28.** The Qt 6 `ResonanceForeignDriver` end-to-end test
changed `SignalGenerator`'s `periodMs` from **1000 to 4321** through `sendParametersToService`, read
it back, completed a stop/start round-trip, received a 3×3 float64 block and survived 200
`releaseString` round-trips: `"parameterBefore": 1000, "parameterAfter": 4321.0` in
`R:\src\docs\qa\rfd-qt6-final.log`, driven by `R:\src\scripts\test-rfd-qt6.py`, which fails the run
if the write is acknowledged and not applied. The exported function is unchanged, so the cause was
elsewhere in the Qt 5 build; it was never found, and it is not reproducible on the Qt 6 side.
⚠ Still open in `R:\dist_Qt5\msvc64`, and the *stream* half — [§14g](24-defects-found-and-fixed-2026-08-15.md#history-14g-a-resonanceforeigndriver-consumer-would-not-attach-to-the-nvx136-stream)
— is untested against an NVX136 under either.

`sendTransitionToService` works; `sendParametersToService` returns `true` and the target's
values do not change. Reproduced against `NeuronSpectrum` and `Recorder`, for `String`,
`Integer` and `Stream` parameters, with the payload in the `{"name":…, "serialized":…}` shape
`applyParameters` expects.

This extends [§14g](24-defects-found-and-fixed-2026-08-15.md#history-14g-a-resonanceforeigndriver-consumer-would-not-attach-to-the-nvx136-stream)
from streams to parameters: **the ctypes bridge is not a usable control path.** The supported
alternatives both work — the Configurator, and `--serviceConfig <file>` at launch, which is
what the whole Neuron-Spectrum validation campaign used. Root cause not yet found.

<a id="history-15f-intel-ipp-is-required-for-acquisition-not-just-for-impedance"></a>

### 15f. Intel IPP is required for acquisition, not just for impedance

The SDK constructs its online-impedance calculator **unconditionally** at the top of
`StartReadData`, before it checks the `onLineImpedance` flag, and that constructor calls into
`ipps-8.1.dll`. So a machine without Intel IPP 8.1 cannot acquire at all, with an error that
mentions impedance nowhere. Same shape as [§14c](24-defects-found-and-fixed-2026-08-15.md#history-14c-nvx136_2025-could-never-start-nvxsetmirrortriggers-is-not-supported---fixed):
an unconditional call to an optional subsystem making an unrelated feature impossible.

<a id="history-15g-the-front-panel-button-is-an-event-not-a-mode-switch"></a>

### 15g. The front-panel button is an event, not a mode switch

The hardware manual describes a button cycling impedance → monitoring → recording, which reads
as a device-side mode control. It is not: `IControlModule` exposes `ButtonPushed` as an event
and `WorkModeLedState` as a separate host-driven property. The device switches nothing and
lights nothing on its own. Pressing it cannot put the amplifier into a state the software could
not reach, and it is not a route around §15a.

---

