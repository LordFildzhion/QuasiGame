# 2026-08-15 — new driver: `neuronSpectrum` (Neurosoft Neuron-Spectrum-65)

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-15--new-driver-neuronspectrum-neurosoft-neuron-spectrum-65"></a>

### 2026-08-15 — new driver: `neuronSpectrum` (Neurosoft Neuron-Spectrum-65)

A fourth amplifier driver, in `R:\src\neuronSpectrum`, built into `R:\dist\msvc64` and verified
on the connected NS-65 (serial 22370366). Full reference:
**[neuron-spectrum.md](../components/neuron-spectrum.md)**.

**The thing to know before reading the code:** the vendor SDK is **.NET Framework 4.8 managed
code** — no C API, no import library. The module therefore carries the tree's only `/clr`
translation unit (`bridge/ns65bridge.cpp`), which presents a flat C ABI deliberately shaped
like `NVX.h` so that everything above it is ordinary native Qt. It is gated `IF(MSVC)` as well
as x64: MinGW cannot build a mixed-mode image, and skips the module cleanly.

| | |
|---|---|
| Vendor SDK | `neuronSpectrum\sdk\lib` — `NeuroSoft.Hardware.Devices.RegistratorEEG` 1.1.1.0 (2023-04) + 8 dependencies, 4.0 MB managed |
| Also staged | `sdk\ipp` — Intel IPP 8.1, 59 MB. **Not optional:** the SDK builds its impedance calculator unconditionally inside `StartReadData`, so IPP is needed for *any* acquisition |
| Kernel driver | none — Microsoft inbox **WinUSB** (`USB\VID_ACCA&PID_8277`) |
| New build requirement | **"C++/CLI support for v142 build tools"** (supplies `mscoree.lib`); see [dev-environment-setup §B5](../migrations/dev-environment.md#history-b5-net-framework-48-sdk--ccli--for-neuronspectrum-and-neuroms) |
| Streams | `eeg` (Float64), `impedance` (Float64, 57 electrodes), `events` (Message, stimulus offsets quantised to one 16 kHz sample — 62.5 us) |

**Device facts that shaped the design:** the amplifier converts at a **fixed 16 kHz** with no
rate register, so every rate offered is decimation in the driver (exact divisors only:
125…16000 Hz, anti-aliased by default, vendor-compatible sample-dropping as an option). There
is **no trigger word** in the frame — stimuli arrive as events whose offset is quantised to one
16 kHz sample (62.5 us, *not* sub-sample: the SDK computes `samplesCount / 16000.0`) — so the
trigger lane is synthesised and the offsets go out on `events`. The device is specified
for **39 referential channels** (28 head/CHIN/EOG + 11 X sockets switched to referential).

**Verified on hardware:**

| Check | Result |
|---|---|
| Stream | 24 ch @ 1 kHz, measured 998.6–1000.7 Hz, block 100, **0 NaN**, electrode-named metadata |
| Full montage | **40 channels** (39 referential + Trigger) @ 1 kHz, 0 NaN |
| Rate sweep | all eight rates within ±0.3 % (16 kHz +0.8 %), 0 NaN |
| Decimation | anti-alias leaves **15× less** high-band energy than dropping |
| Bridge | 15 785–15 851 Hz, one ~0.19 s start-up gap, **0 ring overflows** |
| Long run | 2.9 M frames over 3 min, clean stop, device re-enumerates `OK` |
| Impedance | **0.55–5.4 kΩ**, stable to ~2 % over 3 min |
| Front panel | 3/3 button presses counted; work-mode LED driven by the service |
| Unit tests | `test_NeuronSpectrumLogic` **24/24** |

⚠ **The offline impedance unit is refused by this amplifier** — *"Module: Amplifier. Long
command: 4. Error: 101"*. Online impedance (derived from the monitoring stream, which is what
the vendor application uses by default) works and is what the driver publishes. The refusal
arrives *asynchronously*, so a naive driver would report success and publish 57 electrodes at
0 Ω — which reads as perfect contact. Details and the rest of the SDK traps:
[known-issues §15](../incidents/34-neuron-spectrum-findings-2026-08-15.md#history-15-neuron-spectrum-findings-2026-08-15).

⚠ **Not yet exercised:** the `events`/trigger path (needs a pulse into the sync input) and HDF5
recording through `recorderService` — the ctypes bridge cannot configure the recorder
([known-issues §15e](../incidents/34-neuron-spectrum-findings-2026-08-15.md#history-15e-resonanceforeigndriversendparameterstoservice-applies-nothing--open)).
Use the Configurator or `--serviceConfig`.

⚠ `mingw32` / `mingw64` do not contain this module at all, by design.

