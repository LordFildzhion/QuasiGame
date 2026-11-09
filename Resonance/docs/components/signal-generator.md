# Signal generator

**Status:** active Qt 6 executable `SignalGenerator.exe`, service `signalGenerator`. Synthetic continuous/EEG/epoch/message lanes share one sample/event timeline. Use this component for repeatable pipeline, ordering and fault-injection work.

## Change locations

| Change | Source |
|---|---|
| Parameters, state machine, lane publication | [service.cpp](../../src/SignalGenerator/service.cpp), [lane.cpp](../../src/SignalGenerator/lane.cpp) |
| Waveforms and faults | [synth.cpp](../../src/SignalGenerator/synth.cpp) |
| Text channel table and round trip | [channelplan.cpp](../../src/SignalGenerator/channelplan.cpp), [channelwindow.cpp](../../src/SignalGenerator/channelwindow.cpp) |
| Spatial EEG model | [eegmodel.cpp](../../src/SignalGenerator/eegmodel.cpp) |
| Event timing and marker text | [schedule.cpp](../../src/SignalGenerator/schedule.cpp), [announcement.cpp](../../src/SignalGenerator/announcement.cpp) |
| Host pacing | [pacer.cpp](../../src/SignalGenerator/pacer.cpp) |
| Tests/build | [generator_test.cpp](../../src/SignalGenerator/tests/generator_test.cpp), [CMake](../../src/SignalGenerator/CMakeLists.txt) |

Consumers include [recorder](recorder.md), [playback](playback.md), [viewer](signal-viewer.md) and [TepSound](tepsound.md). A pacing implementation also exists in playback; changing one does not update the other.

## Interface and lifecycle

Four configurable lanes publish Float64 continuous data (default stream `generated`), Float64 `eeg`, Float64 `epochs` (one block/event), and Message `stimuli`; Float64 `status` has 18 named lanes at 2 Hz in current source. The last two, `republishes` and `applies`, expose stream churn; the historical 16-lane count predates them. Stream names are configurable.

Parameters are grouped `continuous`, `eeg`, `epoched`, `messages`, with index bands determining tab order. Retain original keys including `channels`, `samplingRate`, `blockSize`, `amplitude`, `mode`, frequency controls, `ced`, `streamName`.

`prepare` publishes streams in `armed` without samples; attach/start consumers before `start`. Entering running must **not republish** and sever these connections. Stop returns to init. `autoStart=true` is read by its 750-ms startup timer after service configuration applies, not in the constructor.

## Generation contracts

- Marker, trigger bit and evoked waveform denote the same scheduled event on each lane's sample clock. Separate generator processes lose this shared alignment.
- `channelPlan` is one round-trippable MultiLine parameter. Repeated identical rows collapse to ranges. Select `mode=Channel table` to use it.
- A `Trigger`-kind channel with `wave=bits` follows `trigEventMask`/`trigPulseMs` plus independent `trigNoiseMask`/`trigNoiseHz`. Other waveforms on trigger channels retain their own oscillator.
- `shift` is a real time shift for deterministic waveforms. For stateful noise/random-walk/PRBS it changes the seed, producing a different realization rather than a delayed identical trace.
- Waveforms: sine, square, triangle, ramp, pulse, halfsine, staircase, sinc, gauss, exprise, expfall, chirp, am, fm, dampedsine, noisewhite, noiseuniform, noisepink, noisebrown, randomwalk, prbs, bandsum, cardiac, arbitrary, bits, dc, off. `p2/p3` meanings depend on waveform.
- `defect` supports nanruns, infruns, flat and clip; period/length use **samples**. `dropEvery` discards whole blocks without shifting the sample clock. Use channel-specific shift/signature values to expose swapped/dropped columns.
- `channelPlan` remains useful as a compact stable schema. The old claim that dynamic parameters cannot load is superseded by [current framework application](../architecture/framework.md); do not reintroduce a manual-only recorder workaround.

## EEG model and timing constraints

The stream's CED montage drives both spatial simulation and published geometry. Background covariance uses a Cholesky factor of `exp(-distance/lambda)`; alpha is posterior, blinks frontal, mains common-mode and drift independent per electrode. The built-in default montage supports an unconfigured simulation; excess channels use ring fallback geometry. Correlated mixing is O(N²) per sample; `correlated=false` is a useful control.

Independent low-frequency drift can dominate short-window raw correlation. Assess spatial correlation above the chosen high-pass boundary rather than calling the model broken from an unfiltered short run.

High-resolution waitable-timer pacing lives on a dedicated thread, with platform fallbacks. Do not replace it with GUI/status QTimers when sub-tick block pacing matters. Blocks carry their **scheduled** RTC, so lateness remains visible in received-minus-created. Source continuity across the Qt port does not establish unchanged latency statistics.

## Validation and evidence

Registered `test_SignalGenerator` covers waveform values, channel-plan round trips, schedule patterns/codes, epoch shapes, seeded reproducibility, montage correlation and block-size independence. See [test workflow](../how-to/test.md). [VALIDATION](../../src/docs/VALIDATION.md) includes a Qt 6 generated→recorded→replayed route.

[Previous signal and cadence measurements](../history/components/signal-generator.md#history-7-verified) are explicitly Qt 5 provenance; high-rate Qt 6 pacing and manual bulk/cell editor acceptance are not implied. Historical HDF evidence was not retained. Int32 is not a supported generation/recording route. No test or live generator was run for this documentation change.
