# Neuron-Spectrum

**Status:** active Qt6 x64 `neuronSpectrum.exe` with `ns65bridge.dll`; native service over the Neurosoft .NET Framework4.8 managed SDK. Tested hardware evidence concerns NS-65; do not assume every family member behaves identically.

## Change locations and deployment dependencies

| Change | Source |
|---|---|
| Flat C ABI and managed callbacks/ring/error handling | [ns65bridge.h](../../src/neuronSpectrum/bridge/ns65bridge.h), [ns65bridge.cpp](../../src/neuronSpectrum/bridge/ns65bridge.cpp) |
| Native worker/acquisition/gaps/decimation | [neuronspectrumdriver.cpp](../../src/neuronSpectrum/neuronspectrumdriver.cpp) |
| Pure arithmetic and FIR/rate ladder | [neuronspectrumlogic.h](../../src/neuronSpectrum/neuronspectrumlogic.h) |
| Parameters/state/channel presentation | [neuronspectrumconfig.cpp](../../src/neuronSpectrum/neuronspectrumconfig.cpp), [neuronspectrumchannels.h](../../src/neuronSpectrum/neuronspectrumchannels.h) |
| Build/tests | [CMake](../../src/neuronSpectrum/CMakeLists.txt), [bridge CMake](../../src/neuronSpectrum/bridge/CMakeLists.txt), [tests](../../src/neuronSpectrum/tests) |

The bridge is this module's only `/clr` translation unit, not the only bridge in the repository; NeuroMS has another. It includes no Qt/Resonance headers. Use MSVC x64 with C++/CLI for the selected toolset (current v143), plus .NET4.8 SDK/link support. Module-specific C++17/`/EHa`/no-AUTOMOC flags stay scoped to the bridge. In mixed-mode code use SRWLOCK instead of unavailable `std::mutex`; native globals stay POD and allocate explicitly to avoid loader-lock constructors.

Managed vendor assemblies belong in **bin/neuronSpectrum/** with its resolver. NeuroMS ships conflicting unsigned same-name/same-version assemblies; stale flat NeuroSoft DLLs override the private resolver. Follow [deploy](../how-to/deploy.md) for removal of only the obsolete flat managed copies. **Native Intel IPP8.1 remains flat in bin** for P/Invoke. It is needed even without requested impedance because the SDK initializes its impedance calculator unconditionally at StartReadData. Preserve CPU dispatcher variants needed by supported rigs; a subset that loads on one CPU is not a portable package.

NS65 uses inbox WinUSB with the [Neurosoft INF binding](../../src/runtime-content/driver/neuronSpectrum/README.md), unlike eStim/NeuroMS's EzUSB stack. The two packages cover overlapping IDs; install the required stack with other Neurosoft families disconnected.

## Device/channel contract

Hardware converts at fixed16000Hz; selectable published rates are exact divisors125/250/500/1000/2000/4000/8000/16000Hz, implemented in the host. No device rate register exists.

The48 configurable channels comprise23 head electrodes,3CHIN,2EOG,11X sockets,8 differential pairs and COM; respiration adds the49th. X1–X11 switch together between DC and referential. Differential pairs independently choose differential or monopolar-to-ground: they cannot become REF-referenced EEG. GND and REF electrodes have impedance values but no acquisition samples. Default montage selects23 head electrodes.

Preserve panel labels and metadata names/kinds/units; choosing all39 referential channels plus optional trigger produces40 published columns.

## Data, decimation and gap rules

`eeg`: Float64 selected channels in volts plus optional synthetic Trigger lane. `impedance`: Float64 all57 electrodes in ohms. `events`: Message JSON with device-sample event position.

Default anti-alias policy convolves cascaded boxcars into a bounded-state direct FIR, then decimates. Avoid unbounded CIC integrator precision loss under electrode DC offsets. Alternative “Drop samples” keeps every Nth sample for vendor-comparable output and permits aliasing.

Use the **64-bit device sample number**, not wrapping USB SynchronizationNumber, as the timeline. Fill missing input with last valid values internally so NaN never poisons filter state, but mark every affected output window NaN so loss remains visible. A documented start-up gap around0.19s was observed; “always exactly one” is a dated observation, not a universal hardware guarantee.

## Trigger and impedance boundaries

There is no raw trigger word in device frames. SDK events are quantized to one16kHz sample (62.5µs); multiple sub-sample events can collapse. The synthetic bitfield latches those events for output samples and is **not independent** evidence of event delivery. Its placement is not corrected for analog FIR group delay; use event device-sample positions for timing.

Prior hardware evidence observed sporadic sync-in event loss. Compare event counts with an independent stimulus log/edge record; do not infer completeness from the synthetic lane.

SYNC OUT runs the stimulator module; it is not an arbitrary host-held digital line. Start powers that module. Fire uses pulse count and period; count0 requests an endless train until Stop. The documented output pulse is fixed100µs; `sync_out_flash` controls the lamp, not socket width.

Offline impedance returned a vendor error on the tested device. Current driver uses **online impedance during acquisition**: mode changes publication, not whether sampling occurs.

| Mode | EEG published | Impedance published |
|---|---|---|
| Acquisition | yes | no |
| Acquisition + impedance | yes | yes |
| Impedance only | no | yes |

Refresh is2–250 **seconds**, not milliseconds. Unselected/unmeasured electrodes are NaN, never0Ω. Latch asynchronous refusal rather than reporting false success.

The front-panel button reports an event; the host decides behavior and LED state. It cannot unlock unsupported offline impedance. Stop before graceful termination; one application owns the USB device at a time.

## Validation and evidence

| Target | Prerequisite / execution |
|---|---|
| `test_NeuronSpectrumLogic` | Registered device-free CTest; counter/gap/rate/FIR invariants |
| `ns65_bridge_smoke` | Registered **disabled**, hardware label; device connected/idle |
| `ns65_stream_check` | Manual consumer of a running service; verify checker with generator control |
| `ns65_panel_probe` | Manual, person at the device; not routine CTest |

See [test workflow](../how-to/test.md). [Prior hardware observations](../history/components/neuron-spectrum.md#history-10-verified-on-hardware) and [Qt6 parity](../history/components/neuron-spectrum.md#history-10a-what-the-qt-6-port-verified--2026-08-29) have distinct provenance. Offline impedance/vendor cause, event loss, physical pulse behavior and unexercised recovery remain in [issues](../issues/README.md). The old claim that ctypes can never apply parameters is superseded by the framework fixes; verify application reports/readback using [framework](../architecture/framework.md).

No device, bridge smoke, acquisition or unit test ran for this documentation change.
