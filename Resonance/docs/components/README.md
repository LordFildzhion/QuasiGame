# Component routing

Open the component relevant to the change, then follow its source/test links. These pages hold current contracts; historical experiments and superseded designs are evidence to consult when needed. [Current state](../current.md), [source map](../architecture/source-map.md), [framework](../architecture/framework.md), [build](../how-to/build.md), [test](../how-to/test.md) and [issues](../issues/README.md) own cross-component facts.

## Acquisition and transport

| Task / component | Entry point | Important boundary |
|---|---|---|
| NVX-52 acquisition/trigger word | [NVX-52](nvx52.md) | Hardware rate/trigger behavior is device-specific |
| NVX136 acquisition/cold start | [NVX136](nvx136.md) | Required first voltage read and physical sample clock |
| Movicom eight-channel EEG | [Movicom](movicom.md) | Native x64 FTDI transport; fixed 500 Hz, REF inputs, no impedance/trigger controls |
| KARDi2 ECG/Sync | [KARDi2](kardi2.md) | x64 service, x86 broker, device-owned output latch |
| Neuron-Spectrum EEG/impedance | [Neuron-Spectrum](neuron-spectrum.md) | Managed bridge; 16 kHz source, host decimation, synthesized trigger |
| NI analog acquisition | [DAQmx](daqmx.md) | External installed NI runtime; physical acceptance separate |
| FieldTrip buffer | [FieldTrip](fieldtrip.md) | Header resets, reconnect namespace and consumer rebinding |
| Text serial bridge | [COMport](comport.md) | Local8-bit text, exact payload/terminators, stable flowConrol key |
| Trigger-response measurement | [Latency probe](latency-probe.md) | Host reaction time differs from physical closed-loop latency |

Other drivers/modules without a dedicated brief remain routed through [source map](../architecture/source-map.md); absence here is not retirement.

## Actuators

| Task / component | Entry point | Important boundary |
|---|---|---|
| Two-channel board pulse/train/PWM | [Arduino TTL](arduino-ttl.md) | Setup before fire, board vs host clocks, firmware version mismatch |
| Solenoid frame/force/geometry | [feetStim](feetstim.md) | Monitor-after-mask; Stop TTL does not release hold |
| Maglev stimulus library | [mStim](mstim.md) | Reset clears RAM; program before arm; firmware blocks serial stop |
| Neurosoft electrical stimulation | [eStim](estim.md) | One parameter authority, coupled limits, calibration-load presets |
| Neuro-MS TMS/telemetry | [NeuroMS](neuroms.md) | Adopt intensity/configure interval, readiness/standby, async shutdown |

Changes/tests that connect to these command paths can operate equipment. Each brief identifies software-only targets and physical acceptance. A saved/replayed Message stream can contain actuation commands even when EventBus replay is prohibited.

## Data, display and experiments

| Task / component | Entry point | Important boundary |
|---|---|---|
| Synthetic data, waveforms and faults | [Signal generator](signal-generator.md) | Shared event/sample timeline, deterministic seeds and pacing |
| HDF recording, slots and notes | [Recorder](recorder.md) | Refused parameters block Start; valid rows follow block index |
| Replay/seek/spoofed services | [Playback](playback.md) | Prepare→attach→Play; signed anchors; no EventBus replay |
| Continuous plotting, head map, reconnect | [Signal viewer](signal-viewer.md) | Name+source-kind state; envelope/filter/render invariants |
| Epoch timing/storage/label flow | [Epoch architecture](../architecture/epochs.md) | Continuous vs pre-epoched input and attribution clocks |
| Cue/media authoring and trigger scheduling | [Stimulus presentation](stimulus-presentation.md) | Shared TepSound implementation; software onset vs physical onset |
| Alphabet matrix calibration and feedback | [P300](p300.md) | Frame timing, SPEED inference, compatible trained MATLAB model required |
| SOUND/MEP/classifier/session products | [TepSound](tepsound.md) | Unrepaired training, geometry, model provenance and grouped CV |
| Reproduce retired TEP behavior | [Legacy TEP](tep.md) | Comparator only; active copied pipeline lives inside TepSound |

## Updating a component brief

The code change that modifies a contract should update its canonical page in the same change. Keep:

1. Active/legacy status and exact source/change locations.
2. Shared consumers affected by a change.
3. Wire/parameter/file/lifecycle invariants that are not obvious from a function name.
4. Runnable test target and prerequisites; separate code observation from earlier measured evidence.
5. Current limitations and links to their issue/evidence owner.

Do not treat a historical green test count, machine-local package inventory or screenshot as a timeless guarantee. Use names rather than positions for evolving telemetry, and verify serialized keys/Select labels before renaming. Detailed dated experiments stay in [history](../history/README.md); illustrated manuals stay in [operators](../operators/README.md).
