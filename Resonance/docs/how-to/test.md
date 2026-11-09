# Choose and run verification

Status: current test-navigation guide. Scope: software checks, package validation, and the boundary to intentional rig tests. Authority: module CMake registrations and linked scripts/source; inspected 2026-09-15. No test was executed as part of this documentation rewrite.

## Start with the behavior changed

Build in the environment described in [build](build.md). Then inspect the configured registrations without running them:

```powershell
& 'C:/Qt515/Tools/CMake_64/bin/ctest.exe' --test-dir 'R:/src/_build' --show-only=json-v1
```

Read the selected test's source and prerequisites, especially when it opens sockets, starts services, writes files, or imports a device SDK. Registration, compilation, execution, passing assertions and physical-device acceptance are different facts. Report which one was established.

| Changed behavior | Start with |
|---|---|
| Core StreamInfo, sample collection, parameter application/streams | [Core test CMake](../../src/Core/Resonance/tests/CMakeLists.txt) and its named test sources |
| Recording destination/path rules | [RecorderPath_test.cpp](../../src/Core/Resonance/tests/RecorderPath_test.cpp), then [recorder component](../components/recorder.md) |
| Network mode/predicates | [NetworkMode_test.cpp](../../src/Core/Resonance/tests/NetworkMode_test.cpp), then [network guide](../architecture/network.md) |
| Parameter files and QML bridge | `test_ParameterFile`, `test_ParameterFileQml` in [quickStimulus CMake](../../src/quickStimulus/CMakeLists.txt) |
| Reconnect, status and channel editors | `test_ViewerReconnect`, `test_ConfiguratorLiveStatus`, `test_StreamConnectorQml`, and channel/status QML tests in that CMake |
| Plot/epoch/topography arithmetic | The quickStimulus math/epoch test targets; inspect oracle prerequisites |
| Service logic or protocol parser | The component's `tests/` source and CMake; see [source map](../architecture/source-map.md) |
| Movicom protocol, lifecycle or native hardware | [Movicom verification routes](../components/movicom.md#verification-routes); `test_Movicom` is software-only, hardware helpers require an explicit serial |
| P300 training, models or native inference | `test_P300Classifier`, `test_P300Ui`, `test_P300Plan`; [P300 evidence and external-oracle prerequisites](../history/changes/2026-09-26-p300-native-classifier.md) |
| Added/changed parameter descriptions | [audit-parameter-descriptions.py](../../src/scripts/audit-parameter-descriptions.py) |
| Distribution assembly | [Deployment verification](deploy.md#verify-the-candidate) |

## Run selected registered checks

For example, after building and initializing the runtime DLL path in a disposable test shell:

```powershell
$env:PATH = 'R:/src/_build/runtime/bin;C:/Qt515/6.11.2/msvc2022_64/bin;' + $env:PATH
& 'C:/Qt515/Tools/CMake_64/bin/ctest.exe' --test-dir 'R:/src/_build' -R '^test_ParameterFile(Qml)?$' --output-on-failure
```

Use a regex/selection that matches the intended tests, and check that something actually ran. QML tests depend on the staged plugin/module; their CMake dependencies and compile definitions identify the import path. Do not diagnose an unstaged QML change as a test of the new source.

The description audit is a source inspection:

```powershell
Set-Location R:/src
python ./scripts/audit-parameter-descriptions.py
```

It checks the declaration/description patterns implemented by the script. It complements behavior tests; it does not prove that a tooltip's wording or a device operation is correct.

## Known registration and input gaps

At the 2026-09-15 inspection, Core builds seven test executables but registers none with CTest. They cover StreamInfo, SamplesCollector, ParameterApply, StreamParameter, ParseCED, RecorderPath and NetworkMode. Run relevant executables directly rather than treating a green CTest total as Core coverage. Their normal build location is `src/_build/Core/Resonance/tests/`; confirm the file exists and its runtime DLL dependencies before running.

quickStimulus registers the parameter-file and selected QML/UI integration checks, while several math/epoch executables are built without registration. [Its CMake](../../src/quickStimulus/CMakeLists.txt) is the authoritative inventory; the [issue registry](../issues/README.md) tracks this gap. Old test-count totals in historical reports are snapshots, not today's denominator.

Some CED/topography/math parity tests use old generated oracle data from build directories and skip when it is absent. Preserve input provenance and report skipped comparisons. Do not regenerate an oracle from the implementation being tested and then describe agreement as independent parity evidence.

`test_RecorderPath` requires `RESONANCE_RECORD_PATH` and creates/removes a test HDF5 file. Set it to a disposable directory under the build workspace, never the raw-recording store. `test_NetworkMode` constructs the framework and binds real sockets; default, `--networkMode loopback` and `--networkMode lan` are separate runs. The LAN variant deliberately exercises exposure outside loopback.

## Integration and hardware checks

The [support-tool guide](support-tools.md) routes the maintained Qt6 QA entrypoint, retained
diagnostic harnesses, independent numerical references and captured fixtures. Its catalog
distinguishes an executed software result from path/static checks and from rig-specific tools.
Use that route for the collection formerly mixed into `R:\config`; legacy `stage*` filenames
describe investigation stages, not a required test sequence.

The scripts directory contains package, mixed-Qt, service-parity and hardware harnesses. Names alone do not establish that a harness is device-free. Read its arguments, service startup, transitions, output paths and cleanup before running it. The [component page](../architecture/source-map.md#services) owns the appropriate service-specific acceptance procedure.

A hardware-labeled test can also be disabled. For example, Neuron-Spectrum's bridge smoke test is registered `DISABLED TRUE`; selecting `ctest -L hardware` does not by itself make that disabled test execute. Do not report it as tested because the label selection returned successfully.

For deliberate rig tests:

- Identify the exact executable/package, device, acquisition state and test-owned process IDs.
- Stop/release an amplifier before terminating its process. Do not kill every process sharing an executable name.
- Use disposable output paths. Raw human-subject recordings remain read-only.
- Keep source-only, emulator, integration and physical-device measurements separately identified. An emulator can validate software sequencing without proving the physical SDK/device contract.
- Inspect output timing, counts, metadata and refusals as well as process exit codes. For Qt 5 comparisons, account for its historical unwritten final HDF5 row; do not trim valid Qt 6 samples.

## Record the result

A useful verification note states the source/package identity, command/test selection, relevant inputs, observed result, and any skipped/disabled/unavailable checks. Attach a dated measured report when needed and update the owning [issue](../issues/README.md) or component. Repeat broader checks only when the change, failure or unresolved concern justifies them.
