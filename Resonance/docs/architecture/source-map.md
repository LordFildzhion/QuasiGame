# Source map

Status: current navigation reference. Scope: active Qt 6 source and important legacy boundaries. Authority: [top-level CMake](../../src/CMakeLists.txt), each module's CMake, and [quickStimulus CMake](../../src/quickStimulus/CMakeLists.txt); inspected 2026-09-15.

## Roots and generated content

- `src/`: active source. Start here for ordinary code changes.
- `src/_build/`: CMake/Conan/Ninja output; `runtime/` contains the build staging tree. Do not edit staged copies to change source behavior.
- `dist/`: the deployed Qt 6 package. It combines installed binaries/content with operator-owned files; see [deploy](../how-to/deploy.md).
- `src_legacy/Qt5/`, `dist_legacy/Qt5/`: legacy source/package and comparison inputs. Their layout and toolchains differ.
- `docs/`: current engineering context, with dated history separately routed. Operator documents are maintained separately and are not an input requirement for coding tasks.

The [workspace index](../../README.md) routes configuration, evidence, archives and tools.
The [layout migration record](../maintenance/layout-migration-2026-09-15.md) maps historical root paths.

The CMake `add_subdirectory` list defines active modules. File counts and directory counts are not reliable substitutes. Check repository/Git boundaries before planning commits: a source copy and the legacy Git repository are not necessarily the same checkout.

## Framework and front end

| Area | Where to begin | What it owns |
|---|---|---|
| Framework | [Core/Resonance](../../src/Core/Resonance), [framework guide](framework.md) | Service identity, protocol, parameters, streams, state, recording |
| QML host and plugin | [quickStimulus/CMakeLists.txt](../../src/quickStimulus/CMakeLists.txt), [UI guide](ui.md) | Built-in Configurator/Generator/Recorder; Resonance QML types and editors |
| Signal viewer | [Viewer component](../components/signal-viewer.md), [quickStimulus](../../src/quickStimulus) | Streaming plots, channels, epochs, annotations, topography |
| Python embedding | [scriptEngines/CMakeLists.txt](../../src/scriptEngines/CMakeLists.txt) | Active x64 CPython engine; the retained R directory is not enabled here |
| Foreign interface | [ResonanceForeignDriver](../../src/ResonanceForeignDriver) | C/FFI access and the Python-facing Resonance interface |
| Icons and launchers | [icons/README.md](../../src/icons/README.md), [launcher generator](../../src/scripts/make-launcher-shortcuts.ps1) | Executable resources, icon files, portable launcher configuration |

## Services

| Task area | Source | Component context |
|---|---|---|
| Synthetic signal and timing | [SignalGenerator](../../src/SignalGenerator) | [Signal generator](../components/signal-generator.md) |
| HDF5 recording | [recorderService](../../src/recorderService) | [Recorder](../components/recorder.md) |
| HDF5 playback | [playbackService](../../src/playbackService) | [Playback](../components/playback.md) |
| NVX-52 acquisition | [nvx](../../src/nvx) | [NVX-52](../components/nvx52.md) |
| NVX-136 acquisition | [nvx136](../../src/nvx136) | [NVX-136](../components/nvx136.md) |
| Movicom eight-channel EEG | [movicom](../../src/movicom) | [Movicom](../components/movicom.md) |
| KARDi2 acquisition/broker | [KARDi2](../../src/KARDi2) | [KARDi2](../components/kardi2.md) |
| Neuron-Spectrum acquisition | [neuronSpectrum](../../src/neuronSpectrum) | [Neuron-Spectrum](../components/neuron-spectrum.md) |
| Magnetic stimulation | [neuroMS](../../src/neuroMS) | [Neuro-MS](../components/neuroms.md) |
| Electrical stimulation | [eStim](../../src/eStim), [mStim](../../src/mStim) | [eStim](../components/estim.md), [mStim](../components/mstim.md) |
| Foot stimulation | [feetStim](../../src/feetStim) | [feetStim](../components/feetstim.md) |
| Arduino timing/TTL | [arduinoTTL](../../src/arduinoTTL) | [Arduino TTL](../components/arduino-ttl.md) |
| TEP sound/experiment | [tepSoundService](../../src/tepSoundService) | [TepSound](../components/tepsound.md), [TEP](../components/tep.md) |
| Stimulus presentation | [stimulusService](../../src/stimulusService) | [Presentation](../components/stimulus-presentation.md) |
| Signal processing | [SPEED](../../src/SPEED) | Source configuration/logic and relevant algorithm reference |
| NI acquisition | [DAQmx](../../src/DAQmx) | [DAQmx](../components/daqmx.md) |
| FieldTrip buffer bridge | [fieldtrip](../../src/fieldtrip) | [FieldTrip](../components/fieldtrip.md) |
| Serial commands / latency | [COMport](../../src/COMport), [latencyProbe](../../src/latencyProbe) | [COMport](../components/comport.md), [latency probe](../components/latency-probe.md) |
| Other vendor devices | [actiChamp](../../src/actiChamp), [eyelink](../../src/eyelink) | Module configuration, driver, SDK and test source |

## Dependencies that a local edit can cross

- quickStimulus compiles spline/linear-algebra sources from `tepSoundService`. Changes there affect both the viewer plugin and TepSound and require their relevant tests; see the source list/comment in [quickStimulus CMake](../../src/quickStimulus/CMakeLists.txt).
- Neuro-MS and Neuron-Spectrum use separate C++/CLI bridges and private managed-assembly directories. Same assembly names do not mean interchangeable DLLs. [Setup](../how-to/setup.md) and [deploy](../how-to/deploy.md) describe the boundary.
- KARDi2's vendor DLL is x86. The main build creates a separate broker before configuring the Qt 6 x64 service; no Qt 5 island build is required.
- `quickStimulus/plotrender*` is retained legacy renderer source, excluded from the active Qt 6 target. `nvx136_2021/` is retained comparison source, excluded from the top-level build. Check CMake before editing either.
- Some oracle tests depend on artifacts in old build trees. A skipped comparison is not evidence of parity; [test](../how-to/test.md) owns this distinction.

For former module layouts and provenance, see [module history](../history/migrations/modules.md) and [branch inventory history](../history/migrations/branch-inventory.md). Current gaps belong in [issues](../issues/README.md).
