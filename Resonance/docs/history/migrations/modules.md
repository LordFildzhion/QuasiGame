# Module-by-module audit of `R:\src` and `R:\src_Qt5` — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../architecture/source-map.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-module-by-module-audit-of-rsrc-and-rsrc_qt5"></a>


**Updated 2026-09-07.** There are two source trees now. `R:\src` is the **Qt 6.11.2 default** —
MSVC v143 14.44, C++20, deployed to `R:\dist`. `R:\src_Qt5` is the **Qt 5.15.2 comparator**, and the
only home of the 18 legacy `sp_*.qml` paradigms, the retired `tepService`, the git history, and
the whole QBS era. Every active service has been native Qt 6 since 2026-09-06.
What moved and why is in [`build_qt5-to-qt6-transition.md`](qt5-to-qt6-transition.md); what
still depends on the comparator is in
[`arch_qt5-still-needed.md`](qt5-still-needed.md).

Every path below is `R:\src` unless the entry says otherwise. A module marked **Qt 5 only** exists
in `R:\src_Qt5` alone; its row says whether an executable is still deployed.

Legend for **Build**:
`CMake` = listed in the root `CMakeLists.txt` of the tree it lives in ·
`QBS only` = has a `.qbs` but is in no CMake build ·
`dead` = neither, or does not compile.

Legend for **Qt 6**:
**ported** = builds from `R:\src`, ships in `R:\dist\bin` ·
**Qt 5 only** = never crossed — see [`arch_qt5-still-needed.md`](qt5-still-needed.md) ·
**x86 island** = in `R:\src`, but compiled as a 32-bit Qt 5.15 / MinGW process *beside* the Qt 6
distribution, never inside it ·
**absent** = not in `R:\src` at all, and not intended to be ·
**Qt 6 only** = created by the port; exists in `R:\src` alone ·
**both** = present in both trees, but as different content — read the cell.

Legend for **Arch**: the guard at the top of the module's `CMakeLists.txt`.

`R:\src\CMakeLists.txt` carries **26** active `add_subdirectory()` lines; `R:\src_Qt5\CMakeLists.txt`
carries **28**, two of them commented out. `R:\dist\bin` holds **24** executable files (23
applications plus the KARDi2 x86 broker), including Stimulus added on 2026-09-06; the
`nvx136_2021` comparator was retired on 2026-09-07.
Three additional Qt-free x64 official FieldTrip tools live in `R:\dist\tools\fieldtrip`.
It also contains
`Resonance.dll`, `ResonanceForeignDriver.dll` and, one level down, `engines\pythonEngine.dll`;
`R:\dist_Qt5\msvc64\bin` holds
**23** executables — including comparator `DAQmx` and `stimulusService`, plus the retired
`tepService`, and `emulator.exe`, which has no source in either tree —
[`arch_qt5-still-needed.md`](qt5-still-needed.md) §5.

---


<a id="history-overview-table"></a>

## Overview table

| Directory | Kind | Build | Arch | Qt 6 | One-line purpose |
|---|---|---|---|---|---|
| `Core/Resonance` | shared lib | CMake | both | **ported** | **The framework.** `Resonance.dll`; the x86 island builds its own `libResonance.dll` |
| `Core/Resonance/tests` | gtest + plain | CMake | both | **ported** | 7 of 10 test files wired up in **both** trees; `ctest` still finds none of them |
| `SignalGenerator` | service | CMake | both | **ported** | **Reworked 2026-08-17.** Synthetic signal source: a per-channel table over 27 waveforms, a life-like EEG simulation, an epoch stream and a message stream, all driven off one event schedule. 101 parameters in four tabs. See [signal-generator.md](../components/signal-generator.md) |
| `SPEED` | service | CMake | both | **ported** | Script-engine host (Python/R). The Qt 6 build carries a private Python 3.12.1 / NumPy / SciPy runtime under `runtime-content\python` |
| `quickStimulus` | plugin + app | CMake | both | **ported** | QML runtime, Configurator/Recorder/Generator. Controls 2 in `R:\src` — bar four leftover files that still import Controls 1 and cannot load; Controls 1 throughout the comparator |
| `recorderService` | service | CMake | both | **ported** | **Added 2026-08-12.** Standalone HDF5 recorder — window + tray + status strip + status/annotation streams |
| `playbackService` | 2 services | CMake | both | **ported** | **Added 2026-08-15.** Replays a recorded HDF5 session as live services. `playbackService.exe` (controller, window) + `playbackSource.exe` (one spoofed service per process) |
| `tepSoundService` | service | CMake | any | **ported** | **Added 2026-08-19.** Cue presentation, TMS triggering and online SOUND cleaning in one service — four views, subject stage, experiment engine, LDA classifier. 136 parameters. See [tepsound.md](../components/tepsound.md) |
| `tepService` | service | CMake | both | **retired** | Its Qt 5 binary is retained only as a historical comparator. `tepSoundService` now covers presentation-only, epoching without SOUND, and full SOUND processing. See [tep-service.md](../components/tep.md) |
| `stimulusService` | service | CMake | **x64** | **ported** | TepSound presentation extraction with a four-tab studio, shared stage/media/trigger fixes and events/status; no analysis. See [Stimulus](../components/stimulus-presentation.md) |
| `latencyProbe` | service | CMake | both | **ported** | Closed-loop latency instrument: watches one trigger bit and immediately commands the same amplifier's trigger output, so an external board measures the whole loop on one clock. See [latencyProbe](../components/latency-probe.md) |
| `scriptEngines` | subdir | CMake | **x64** | **ported** | `add_subdirectory(python)` → `pythonEngine.dll`. Gated to x64 (no 32-bit CPython); `R` submodule (3 008 files) is QBS-only in both trees |
| `ResonanceForeignDriver` | shared lib | CMake | both | **ported** | C ABI + ctypes bridge for Python etc. |
| `COMport` | service | CMake | both | **ported** | Serial port ⇄ Resonance stream bridge. See [COMport](../components/comport.md) |
| `nvx` | driver | CMake | **x64** | **ported** | MCS NVX-16/24/24T/36/36T/52 amplifier. **Rewritten 2026-08-14** against NVX API 2.3.21648 |
| `nvx136` | driver | CMake | **x64** | **ported** | MCS NVX-136 amplifier (+ emulation mode). **Rewritten 2026-08-15** against NVX136 DLL 1.5.21743. ✅ Resynchronised from `R:\src_Qt5` on 2026-09-02, so the cold-start work is current again ([`arch_qt6-work-list.md`](qt6-work-list.md) §1). Shipped defaults now live in `nvx136defaults.hpp` — 1 kHz, block 50, 64 EEG + trigger, `mks64_standard.ced` |
| `nvx136_2021` | driver | ~~CMake~~ | **x64** | **retired 2026-09-07** | The **2021** NVX-136 driver and the **2021** vendor SDK as a separate executable, built 2026-09-02 so the cold start could be settled by comparison rather than argument ([qt6-work-list §1c](qt6-work-list.md)). That comparison is done, and the executable registered as **`NVX136`** — a drop-in swap that was one mis-click from two services answering one name. Out of the root `CMakeLists.txt`, `bin\nvx136_2021\` and `NVX136_2021.bat` removed from `R:\dist`; the sources stay for reference (`R:\src\nvx136_2021\README.md`). The 2021 SDK in `nvx136\Dll\` is still linked by nvx136's SDK probe test |
| `neuronSpectrum` | driver | CMake | **x64 + MSVC** | **ported** | Neurosoft Neuron-Spectrum-61…65. **Added 2026-08-15.** `/clr` bridge over a .NET 4.8 SDK |
| `actiChamp` | driver | CMake | **x64** | **ported** | Brain Products actiCHamp. Native Qt 6 x64 with a repaired loader and acquisition path — the Qt 5 executable asked `QLibrary` for `ActiChamp_x86` and called a null function pointer |
| `eyelink` | driver | CMake | **x64 + MSVC** | **ported** ⚠ | SR Research EyeLink 1000 / 1000+; hardware-free contract and fixation-logic parity passed, physical tracker validation remains |
| `DAQmx` | driver | CMake | **x64** | **ported** | NI analog input; installed current ANSI C SDK, external NI runtime, checked setup/read/Done and recovery; physical acceptance remains |
| `neuroMS` | driver | CMake | **x64 + MSVC** | **ported** ⚠ | **Added 2026-08-15.** Neurosoft Neuro-MS magnetic stimulator — the tree's only actuator. `/clr` bridge over the .NET SDK; see [neuroms.md](../components/neuroms.md). ⚠ The Qt 6 copy is missing the `standby` state — [`arch_qt6-work-list.md`](qt6-work-list.md) §1b |
| `KARDi2` | driver | CMake | **x64** | **ported** | KARDi2 ECG/polygraph. The vendor DLL is PE32/i386 only, but since 2026-09-02 that no longer forces the service to be x86: an x64 Qt 6 service talks to `kardi2-broker-x86.exe` over anonymous pipes. See [kardi2.md §10](../components/kardi2.md) |
| `KARDi2/broker` | x86 helper | CMake, own root | **x86** | **Qt 6 only** | The 164 KiB `kardi2-broker-x86.exe`: `/MT`, imports only `KERNEL32.dll`, the only process that loads the PE32 vendor DLL. Built by `scripts\build-qt6.ps1` **before** the tree's own configure, into `KARDi2\_build-x86`, because it is an input the tree cannot build as a target |
| `KARDi2/_legacy/qt5-island` | ~~private core~~ | — | — | **retired 2026-09-02** | The **second, private copy of `Core/Resonance`** the old x86 island needed. In no build, kept for reference. Its `3dparty/Driver` subtree is **not** dead weight: it is the only copy of the vendor USB kernel driver in the repository, and `deploy-qt6.ps1` stages it |
| `eStim` | driver | CMake | **x64** | **ported** | **Added 2026-08-16.** The same Neurosoft electrostimulator on the 64-bit vendor DLLs, with the standalone GUI ported in: 54 parameters, presets as command one-liners, `events` + `status` streams, and serial / UDP / stream / window all driving one set of state. See [estim-service.md](../components/estim.md) |
| `arduinoTTL` | driver | CMake | **any** | **ported** | **Added 2026-08-16.** Two-channel TTL pulse / gate generator on an ATmega328P, over a serial port — no vendor DLL, so no arch gate. Publishes the board's own microsecond stamp for every edge; carries a software model of the firmware for board-free testing. See [arduino-ttl-service.md](../components/arduino-ttl.md) |
| `feetStim` | driver | CMake | **any** | **ported** | **Added 2026-08-16.** Foot-sole solenoid stimulator: 2 × 90 solenoids over a 57600 COM port or the emulator's named pipe, a fifteen-frame library with per-point strength, and the rig's UDP grammar. Covers the UDP/BNC mode only — no gait animation, no latency bench, no tracing. See [feetstim-service.md](../components/feetstim.md) |
| `mStim` | driver | CMake | **any** | **ported** | **Added 2026-08-16.** Four-magnet maglev stimulator: an Arduino Nano and two L298N bridges over a COM port. The firmware keeps no library and no EEPROM, so a preset is literally a firmware definition line. See [mstim-service.md](../components/mstim.md) |
| `fieldtrip` | service | CMake | **x64** | **ported** | Current client definitions, asynchronous worker TCP, buffer reset/header replacement; official x64 server/demo recording acceptance. See [FieldTrip](../components/fieldtrip.md) |
| `eyetribe` | driver | QBS only | — | **absent** | The Eye Tribe tracker; *"was not upgraded to latest resonance"* |
| `openBCI` | driver | dead | — | **absent** | Broken include, never ported |
| `fileConverter` | tool | dead | — | **absent** | Legacy `.r2e`/Cap'n Proto reader, hardcoded paths |
| `SaveLib` | tool | dead | — | **absent** | `condition: false` in its qbs |
| `DemoApp` | sample | QBS only | — | **absent** | Minimal API demo, useful as a snippet source |
| `Tests` | tests | dead | — | **absent** | All references commented out |
| `Documentation` | docs | QBS only | — | **absent** | Doxygen/qdoc config |
| `3dparty` | submodules / plain dirs | — | — | **ported, reshaped** | `R:\src_Qt5`: `thir` (3 447 files), `qml-colors` (48), `access_private` (9), all git submodules. `R:\src`: `thir` (3 438) and `qml-colors` (47) only, as **plain directories** — the submodule indirection was deliberately removed, and `access_private` did not cross |
| `qbs`, `Core/install/qbs` | build infra | QBS | — | **absent** | QBS modules/imports (incl. git version stamping) |
| `Core/docs` | docs | — | — | **absent** | The Doxygen pages `service.md`, `parameters.md`, `services.md`. ⚠ In `R:\src_Qt5` only — they were not copied into the Qt 6 tree |
| `ci` | build infra | — | — | **absent** | Legacy conda/conan1 CI batch scripts |
| `bat` | scripts | — | — | **absent** | Old dev env helpers |
| `scripts` | build/QA infra | — | — | **Qt 6 only** | The build, deploy, validate, parity and QML-harness set: `build-qt6.ps1`, `deploy-qt6.ps1`, `validate-dist-qt6.ps1`, `capture-parameter-column.ps1`, six `test-*-parity.py`, and the capture scripts. `build-kardi2-x32.ps1` and `validate-kardi2-x32.ps1` were deleted with the island |
| `profiles` | build infra | — | — | **Qt 6 only** | One Conan profile, `msvc-v143-release`, in the tree. The comparator's `mingw32`/`mingw64`/`msvc64` profiles are not in either tree — they live in the user Conan home |
| `runtime-content` | payload | — | — | **Qt 6 only** | Deployment payload the build does not produce: `python\` (SPEED's private 3.12.1 runtime), `mulines\`, `params\`, `qt.conf` |
| `shared` | QML | — | — | **Qt 6 only** | One file, `SquareCheckBox.qml`, pulled by alias into `recorderService/res.qrc` and `playbackService/res.qrc` so the two services and the Configurator show the same compact check mark |
| `qt6LightPalette.hpp` | header | — | — | **Qt 6 only** | A single root-level header included by seven `main.cpp` files. Pins `Qt::ColorScheme::Light` and every neutral `QPalette` role, so the tools keep the compact light Qt 5 appearance whatever the Windows dark-mode setting says |
| `icons` | assets + tools | — | — | **Qt 6 only** | **Added 2026-09-06.** One icon per executable: `svg\` masters, `ico\` the ten-size files the build embeds, `preview.png`, and two tools (`gen_svgs.py` writes the masters from a shape table and a family palette, `render-icons.py` renders them through the Qt kit's `qml.exe` and packs the `.ico`). Wired in by `resonance_icon()` in the root `CMakeLists.txt` — one line per module. [architecture §11d](framework-evolution.md) |
| `docs` | docs | — | — | both | `R:\src\docs` is the port's own record (`PORTING_LOG.md`, `VALIDATION.md`, `REMAINING_PORTS.md`, `qa\`). ⚠ `R:\src_Qt5\docs` is a stale 2026-08-26 copy of `R:\docs` — `R:\docs` is authoritative |
| `_build`, `_dist`, `_stage`, `_patches`, `_test-output`, `KARDi2/_build-x86` | build output | — | — | **Qt 6 only** | ⚠ The Qt 6 tree builds **inside itself**, reversing the old "never build in the source tree" rule. The comparator still builds into `R:\dist_Qt5\_build\<name>`. The `_build` cache is bound to the pre-rename path and must be deleted before the next configure — [`build_qt5-to-qt6-transition.md`](qt5-to-qt6-transition.md) §2 |

---


<a id="history-core"></a>

## Core

<a id="history-coreresonance--the-framework-library"></a>

### `Core/Resonance` — the framework library
Target `Resonance`, `SHARED`. Compiled with `RESONANCE_EXPORTS RESONANCE_EXPOSE_PROTOCOL`.

`R:\src` links `Qt6::Core Qt6::Network Qt6::StateMachine boost::boost` (public), `HDF5::HDF5`
(private) and, on Windows, `user32 shell32` (private) — `shell32` supplies the explicit application
model ID that `QtWinExtras` used to set.
`R:\src_Qt5` links `Qt5::Core Qt5::Network boost::boost` (public), `HDF5::HDF5` (private),
`Qt5::WinExtras user32` (private, Windows).
`QStateMachine` moved out of `Qt5::Core` into its own Qt 6 module and `QtWinExtras` was removed;
those two are the whole of the framework's link-level delta.

Layout:

* Root `*.hpp/cpp` — public API (see [architecture.md](framework-evolution.md)).
* `internal/` — `TcpStreamSender/Receiver`, `StreamPool`, `OutputStreamAggregator`,
  `blockStreaming`, `DiscoverURI`, `HDFRecorder`, `ParseCED` (EEGLAB `.ced` electrode montages).
* `Parameters/` — 11 parameter types.
* `TransmittableTypes/` — `Message`, `Int32`, `Float64`, `EventBus`, `TimeSeriesHelper`.
* `Protocol/` — thir-based binary protocol codegen.
* ⚠ The Doxygen pages `service.md`, `parameters.md`, `services.md` are at `R:\src_Qt5\Core\docs\`
  and were **not** copied into the Qt 6 tree. Still worth reading; still only in the comparator.

Every `.cpp` on disk is listed in `CMakeLists.txt` — no dead files here.

⚠ **There WAS a third copy of this library, and it is now out of every build.**
`R:\src\KARDi2\_legacy\qt5-island\Core\Resonance` is a private, separately compiled Qt 5.15 build of
the same core, which existed only so the PE32 KARDi2 service could link something. Since 2026-09-02
KARDi2 is x64 and links the ordinary `Resonance.dll`, so this copy compiles nowhere and ships
nowhere. It is kept for reference, and it had already drifted in both
directions — some differences are genuine Qt 5 API requirements (`QRegExp`, `QtWinExtras`,
`splitRef`), the rest are unreplayed fixes, and nothing in the tree says which is which. See
[`arch_qt6-work-list.md`](qt6-work-list.md) §3.

<a id="history-coreresonancetests"></a>

### `Core/Resonance/tests`
**Both trees now build the same seven targets**: `test_StreamInfo`, `test_SamplesCollector`
(gtest + gmock), `test_ParameterApply`, `test_StreamParameter`, `test_ParseCED`, and two that are
plain `main()` programs rather than gtest — `test_RecorderPath` and `test_NetworkMode` (added
2026-08-18 — it takes the mode on its own command line, because `ResonanceApp` is a singleton and
one process can hold only one mode; run it three ways).
Present but **not wired up** in either tree: `OutputStreams_test.cpp` (needs the `access_private`
submodule, which does not exist in `R:\src` at all), `Parameters_test.cpp`, `ThreadCapsule_test.cpp`.
⚠ All seven link `Resonance.dll`, so `runtime\bin` must be on `PATH` or they exit `0xC0000135`
before printing anything.
⚠ `enable_testing()` is called and `gtest_discover_tests` is **still commented out** in both trees —
`ctest` finds nothing here. `quickStimulus` is barely better — 12 gtest targets, 3 of them
registered with `add_test()`. `KARDi2`'s `test_Kardi2Logic` registers itself.
Low-hanging fruit: add the missing three and re-enable discovery.

---


<a id="history-services"></a>

## Services

<a id="history-signalgenerator--the-synthetic-source-everything-else-is-tested-against"></a>

### `SignalGenerator` — the synthetic source everything else is tested against
**Ported to Qt 6.** **Reworked 2026-08-17.** Full reference:
**[signal-generator.md](../components/signal-generator.md)**.

`SignalGenerator.exe`, service name `signalGenerator`. Five streams from one process — a
`continuous` channel table, an `eeg` simulation, an `epochs` stream of one block per event, a
`stimuli` message stream and a `status` stream — all driven off **one event schedule**, so a
marker, a trigger bit and an evoked response land on the same sample. That alignment is the whole
reason it is one process rather than several.

The pure parts (`synth`, `channelplan`, `schedule`, `eegmodel`) carry no Resonance types, so they
compile into `test_SignalGenerator` as well as the service and can be asserted against closed-form
values — the same arrangement `tepService`'s pipeline uses.

Every original parameter name still works. Three long-standing defects were found and fixed in the
process: `dirtySine` was bit-identical to `fixedSine`, `fixedNaNMeander` emitted `+∞` rather than
NaN, and every channel carried identical samples — see
[signal-generator.md §7](../components/signal-generator.md).

<a id="history-speed--script-engine-host"></a>

### `SPEED` — script engine host
**Ported to Qt 6.** See [architecture.md §10](../../architecture/framework.md). Scans
`<exe>\engines\*.dll`. Note `application.hpp` defines `RESONANCE_EXPOSE_PROTOCOL` **before**
including anything — that pattern is required for anything touching `SerializedDataContainer`.

In the Qt 6 tree its Python runtime is no longer machine-wide: the exact packages the service needs
were reduced and copied to `R:\src\runtime-content\python`, so source and deployment depend on
neither the broken Qt 5 launcher path nor the machine's Python installation.

<a id="history-quickstimulus--qml-runtime--built-in-apps"></a>

### `quickStimulus` — QML runtime + built-in apps
**Ported to Qt 6.** Two CMake targets in one `CMakeLists.txt`:
* `quickStimulusPlugin` (SHARED, `PREFIX ""` so the file is `quickStimulusPlugin.dll`, not
  `libquickStimulusPlugin.dll` even under MinGW) → `runtime/bin/Resonance/`, plus the whole
  `import/Resonance/` directory copied next to it.
* `quickStimulus` (executable) → `runtime/bin/`.

Links `iir::iir_static` (Conan `iir1`) for on-screen filtering. Qt components in `R:\src`:
`Qt6::Core Gui Quick QuickControls2 Widgets Scxml SerialPort StateMachine`. The Qt 5 line asks for
`Qt5::Core Quick Widgets Scxml SerialPort`, so `Gui`, `QuickControls2` and `StateMachine` are the
three additions.

The **signal viewer** — `timeseriesreceiver`, `channelmodel`, `plotmath` and everything under
`import/Resonance/Plot/` — was reworked 2026-08-13. Full reference:
**[signal-viewer.md](../components/signal-viewer.md)**. It has always been Qt Quick Controls 2 only.
**`Configurator.qml` is Controls 2 in `R:\src`** (`import QtQuick.Controls`, versionless) **and
Controls 1.4 in `R:\src_Qt5`** — that conversion, and the Qt 6 `TreeView` reimplementation behind
it, are the largest single piece of the port.

⚠ **Four shipped QML files still import Qt Quick Controls 1, which Qt 6.11 does not have in any
form** — `C:\Qt515\6.11.2\msvc2022_64\qml\QtQuick\Controls` carries Basic, Fusion, Imagine,
Material, Universal, Windows and FluentWinUI3 and nothing else.
`import/Resonance/Bricks/StimulusSelector.qml` (Controls 1.2) and
`import/Resonance/Plot/ComboBoxBinding.qml` (Controls 1.4) are **registered types** in their
`qmldir` files and are deployed to `R:\dist\bin\Resonance\`; instantiating either fails at import.
`Configurator_normal.qml` and `SignalView.qml` (both Controls 1.4) are deployed but are in no
`qmldir`, so only an explicit file load reaches them.

**Sources on disk that are NOT in the CMake build** (legacy Qt-Widgets-era code, kept for
reference in both trees — do not assume they compile):
`channelreceiver.cpp`, `configwindow.cpp`, `datasource.cpp`, `dspfiltershelper.cpp`,
`graphline.cpp`, `graphlinenode.cpp`, `main_debug.cpp`, `selectableview.cpp`,
`servicesmodel.cpp`. Same for `SignalPlot.qml` (36 KB, not referenced by any qrc or qmldir) and
`SignalView.qml` (in the source list and shipped, but not in `qmldir` and written against a
`TimeSeriesReceiver` API that no longer exists). `main.qml`, `settings.qml`, `test.qml`,
`testApp/` and `speedTestApp/` are in the same category and all still carry Controls 1 imports.

`plotrender.cpp` / `plotrendershader.cpp` — the pre-Qt-5.8 `SignalPlot` scene-graph renderer — are
**compiled but never constructed** in `R:\src_Qt5`, and in `R:\src` they are **deliberately out of
the source list**: Qt 6 removed that shader API, so the files stay copied for archaeology and the
`CMakeLists.txt` comment says so. The live renderer in both trees is `TimeSeriesReceiver::paint`.

`tests/UnitTests` and `tests/IntegrationTests` are QML tests, QBS-only.

<a id="history-recorderservice--standalone-hdf5-recorder"></a>

### `recorderService` — standalone HDF5 recorder
**Ported to Qt 6.** **Added 2026-08-12.** Full reference:
**[recorder-service.md](../components/recorder.md)**.

Its only job is writing selected streams to a file, in its own process, so a session survives the
Configurator being closed or crashing. Four faces onto one set of `Parameters::*` objects — the
Configurator, its own QML window, a Windows tray icon, and a frameless always-on-top status
strip — plus two published streams (`status`, `annotations`) for automation.

`QApplication` rather than `QCoreApplication` (the tray needs a GUI event loop) with
`setQuitOnLastWindowClosed(false)`. QML engines are built lazily, so a recorder nobody looks at
never pays for one.

It drove five framework changes, all of which affect every other service:
`setValue` is now notifying; a new `Parameters::Action` type; `StreamInfo::isEmpty()`;
`Parameters::Stream::activeStream` as a property; and the `Recorder` extensions listed in
[architecture §8](../../architecture/framework.md).

⚠ The Qt 6 recorder writes **one row fewer** than the Qt 5 one for the same input: Qt 5 created
every numeric dataset at extent 1 and extended to `offset + samples + 1`, so every Qt 5 recording
ends with an all-zero row nothing ever wrote. Qt 6 writes exactly the sum of the block sample
counts. This is **not** back-ported to `R:\src_Qt5` — see
[`build_qt5-to-qt6-transition.md`](qt5-to-qt6-transition.md) §7.

<a id="history-playbackservice--replaying-a-recording-as-live-services"></a>

### `playbackService` — replaying a recording as live services
**Ported to Qt 6.** **Added 2026-08-15.** Full reference:
**[playback-service.md](../components/playback.md)**.

Two executables from one directory, because discovery addresses a stream as (service name,
stream name) and a process may declare only one service — so replaying a file whose streams
should appear to come from two different services needs two processes. `playbackService.exe` is
the operator-facing controller (file, mapping, transport, window, `status` stream); it spawns one
`playbackSource.exe` per distinct service name, hands each a shared origin and a shared start
anchor on the monotonic clock, and keeps them in step through pause, resume, speed changes and
looping. `playbackSource.exe` is also a complete service on its own.

`hdfsource.cpp` and `playbackjob.cpp` are compiled into both. `Core/Resonance` links HDF5
privately, so this module finds it with its own `find_package(HDF5)`.

Blocks carry the instant they were *scheduled* for rather than the instant they went out, which
is what makes a re-recording of a playback reproduce the original's cadence exactly. The pacing
deliberately does not use a `QTimer` — see [playback-service.md §6](../components/playback.md).

<a id="history-tepsoundservice--cues-tms-triggering-and-online-sound-in-one-service"></a>

### `tepSoundService` — cues, TMS triggering and online SOUND in one service
**Ported to Qt 6.** **Added 2026-08-19.** Full reference: **[tepsound.md](../components/tepsound.md)**.

`tepSoundService.exe`, service name `TepSound`. Four views (console, processing, feedback,
stimuli), a subject stage, an experiment engine, an LDA classifier and 136 parameters. Its numeric
core — `linalg`, `firws`, `spline`, `sound`, `badchannels`, `calibration`, `soundpipeline`,
`soundstore` — carries no Qt type, so all of it is testable without a window; `tests/` holds eleven
gtest files against MATLAB fixtures.

⚠ **This module is why the last two service ports were cheaper than they looked** — Stimulus
followed on 2026-09-06, compiling this module's presentation implementation. It does not
reach into its parents' directories: `R:\src\tepSoundService\shared\tepService\`
(`dsp`, `epochprocessor`, `pipeline`, `signalworker`) and
`R:\src\tepSoundService\shared\stimulusService\` (`protocol`, `schedule`, `stage`, `triggerline`,
`triggerout`) are **private copies that already compile under Qt 6.11**, referenced from
`CMakeLists.txt` as `TEP_DIR` and `STIM_DIR`. In `R:\src_Qt5` those same files are compiled out of
the parent modules' own directories. So a second copy of each has already crossed the version
boundary — but the copies now drift independently of `R:\src_Qt5`, which is a maintenance cost
nothing in the tree tracks.

`Qt6::Multimedia` is found `QUIET` and is optional on purpose: without it the service builds and
runs, video rows simply cannot be validated, and `canProbeMedia()` returns false so validation says
so out loud rather than passing them silently.

<a id="history-tepservice--retired-online-tepmep-analyser"></a>

### `tepService` — retired online TEP/MEP analyser
> **Replaced by `tepSoundService`.** The Qt 5 executable remains a comparator, not an active port
> target. `tepSoundService` now exposes three explicit modes: presentation only (no signal
> processing), epoching/MEP with SOUND disabled, and the full SOUND pipeline.

**Added 2026-08-16.** Full reference: **[tep-service.md](../components/tep.md)**; operator instructions
[Tep-Operator-Guide.md](../../operators/legacy-tep.md); evidence
`report_tep-service-validation.md` (on the lab drive, `R:\docs\_notes\`).

Replaces two things at once: `mulines.TEPs_plot.pipeline_tep`, the Python script `SPEED` hosted to
cut epochs around a TMS pulse, and `R:\dist_legacy\TEP_visualization`, the PyQt application that
consumed its output. Both are gone, along with the two settings files that had to be kept in step
by hand and were not.

`pipeline.cpp`, `epochprocessor.cpp` and `dsp.cpp` carry no Qt or Resonance type between them, so
they compile into `test_TepPipeline` as well as the service and can be exercised without a window,
an amplifier or a network. **Every filter design is re-derived from SciPy's own formulation
rather than taken from the `iir1` package the viewer links** — `iir1` normalises differently, and
every comparison against a legacy recording would then have been a negotiation. That is what makes
the validation's "bit-identical to SciPy" result meaningful.

Links HDF5 with its own `find_package(HDF5)` — `Core/Resonance` links it privately — the same
arrangement `playbackService` uses. `views.cpp` holds two `QQuickPaintedItem` plots registered
under `Resonance.TepPlots 1.0`; the QML brick library is a *file* module, `Resonance.Tep 1.0`,
installed to `bin/Resonance/Tep` and carried in the qrc as well.

<a id="history-stimulusservice"></a>

### `stimulusService`

**Ported 2026-09-06**, native x64 Qt 6.11.2: `R:\dist\stimulusService.bat` and
`bin\stimulusService.exe`. Identity **Stimulus**, 21 described presentation parameters, Message
`events` and eight-channel Float64 `status` at 2 Hz. It compiles TepSound's authoring/model,
sequence/trigger plan, stage and multimedia implementation, with a shared `presentation_run.inc`.
Its four-tab light console has no epoching, SOUND worker, analysis plots or feedback verdicts.
The dedicated executable icon follows architecture §11d. See
[Stimulus](../components/stimulus-presentation.md) for the UI, migration and software acceptance.
The Qt 5 rig manager and 18 legacy Controls 1 paradigms remain separate comparator material.

<a id="history-latencyprobe"></a>

### `latencyProbe`
> **Ported 2026-09-04.** `R:\src\latencyProbe` builds with Qt 6 Core/StateMachine and deploys as
> `R:\dist\bin\latencyProbe.exe`. Its 12-parameter contract and `events` stream are preserved;
> every parameter now has a Configurator tooltip. See [service_latency-probe.md](../components/latency-probe.md).

570 lines. Watches one bit of an amplifier's trigger word and, on a change, immediately commands
that same amplifier's trigger output, so an external board timestamping both edges on one clock
measures the whole loop with no cross-clock comparison. Deliberately amplifier-agnostic. Its
harness lives in `R:\config` (`latency_probe_harness.qml`, `analyze_latency_loop.py`,
`summarize_latency_sweep.py`) and needs no porting itself.

<a id="history-comport"></a>

### `COMport`
> **Ported 2026-09-04.** `R:\src\COMport` builds with Qt 6 Core/SerialPort/StateMachine and deploys
> as `R:\dist\bin\COMport.exe`. All seven parameters have Configurator tooltips. The port also
> fixes the Qt 5 sender's off-by-one/reversed-loop defect, which could drop the final byte or spin.
> See [service_comport.md](../components/comport.md).

Bridges a serial port to/from Resonance. Config exposes port, baud, data bits, parity,
stop bits, flow control **and an input `Parameters::Stream`** — so it is bidirectional:
incoming bytes become an output stream, blocks from the input stream get written to the port.
Uses `Qt6::SerialPort`; the obsolete unused `MainWindow.ui` did not cross.

<a id="history-resonanceforeigndriver"></a>

### `ResonanceForeignDriver`
**Ported to Qt 6.** `ResonanceForeignDriver.dll` + `resonance_foreign_driver.py`. Installs the
Python wrapper and the two demo scripts into the distro root. The old QBS name for this product was
`eyegamesDll` (`eyegamesDll.qbs` still sits in the module directory of **both** trees, unbuildable
in the Qt 6 one) — same source, older identity.

<a id="history-fieldtrip"></a>

### `fieldtrip`
> **Ported 2026-09-05**, in `R:\src\fieldtrip` and `R:\dist`. Native x64 Qt 6; the two-parameter,
> data-only `buffer` Float64 contract is preserved. The launchable historical Qt 5 comparator is
> `R:\dist_legacy\dist_2026aug\mingw32\bin\fieldtrip.exe`.

Uses current upstream request/wire definitions with native asynchronous Qt TCP. The selected
official C buffer/server/demo sources are built as separate x64 tools. Worker affinity, reset and
shape replacement, bounded decoding, reconnect and shutdown are repaired. See
[service_fieldtrip.md](../components/fieldtrip.md).

---


<a id="history-hardware-drivers"></a>

## Hardware drivers

All follow the same shape: `main.cpp` → `*Config` (parameters + `QStateMachine`) →
`*Driver`/`*Thread` (moved to a `QThread`, owns the `OutputStream`).

⚠ The vendor SDK trees below are byte-identical in both source trees: every one of them is a C or
.NET boundary that crosses no Qt ABI. `KARDi2` is the sole exception, and it is an **architecture**
exception, not a toolchain one.

| Module | Qt 6 | Vendor lib (in-tree) | Notes |
|---|---|---|---|
| `nvx` | **ported** | `nvx/sdk/x64/Release/nvxmcs.lib` + `.dll` (**API 2.3.21648, 2025**) + `sdk/include/NVX.h` + `sdk/PowerUp.conf` | `dll/x86_64/` still holds the superseded **2.1.8683 (2021)** DLL — same file name, incompatible; nothing in the build refers to it. `generateLIB.bat` + `libtool/lib.exe` regenerate the x86 import lib from a `.def`. `simulator.qml` and `ConfigurationWindow.ui` are leftovers. Frame arithmetic lives in `nvxframelogic.h` (`nvx::logic`) and is unit-tested by `test_NvxFrameLogic`; the hardware probes under `tests/` build outside `runtime\`. |
| `nvx136` | **ported** ⚠ | `nvx136/sdk/x64/Release/NVX136.lib` + `.dll` (**DLL 1.5.21743, 2025**) + `sdk/include/nvx.h` + `sdk/firmware/*.bit` | `Dll/` holds the **1.4.19077 (2021)** SDK — same file name, incompatible behaviour. ⚠ It is no longer dead: since 2026-09-02 the `nvx136_2021` target links it, and that target is the only thing that does. Ships 3 FPGA bitstreams (`NVX136.bit`, `R2`, `R3`) and a working `--emulation` switch. Cypress USB driver in `nvx136/Driver/`. Frame arithmetic lives in `nvx136logic.h` (`nvx136::logic`); the two vendor-emulator tests under `tests/` build outside `runtime\`. ✅ Resynchronised from `R:\src_Qt5` on 2026-09-02: the converter power-down and `NVXSelectDevice` are gone and `cold_start_pause_ms` is back, verified marker-for-marker against the Qt 5 binary. [`arch_qt6-work-list.md`](qt6-work-list.md) §1. |
| `neuronSpectrum` | **ported** | `neuronSpectrum/sdk/lib/*.dll` — **managed .NET Framework 4.8 assemblies, not a C SDK** (`NeuroSoft.Hardware.Devices.RegistratorEEG` 1.1.1.0, 2023-04) | The only driver with no linkable vendor library. `bridge/ns65bridge.cpp` is compiled `/clr` and is one of the two mixed-mode translation units in the tree; everything above it is native. ⚠ The `/clr` bridges mean a **C++/CLI component is still required — for v143 now, not v142.** Also stages the Intel IPP 8.1 runtime (`sdk/ipp`, 59 MB), which the SDK needs for **any** acquisition. No kernel driver — inbox WinUSB. Frame/rate/decimation arithmetic lives in `neuronspectrumlogic.h` and is unit-tested by `test_NeuronSpectrumLogic`. Full reference: [neuron-spectrum.md](../components/neuron-spectrum.md) |
| `actiChamp` | **ported** | `actiChamp/dll/ActiChamp_x64.lib` | Ships `ActiChamp.bit` / `ActiChampX.bit` + `.dll.ini`. x86 lib also present but the module is x64-gated. The Qt 6 port is a repair as well as a rebuild: the Qt 5 x64 executable asked `QLibrary` for `ActiChamp_x86`, checked no resolved symbol and called a null `champGetCount`, so it could not serve as a live reference. `README_QT6.md` in the module records the parameter/state contract it preserves. |
| `eyelink` | **ported** ⚠ | `eyelink/libs/x64/eyelink_core64.lib`, `eyelink_gdi_graphics64`, `eyelink_w32_comp64` | Ported 2026-09-04. QtWinExtras was removed, Win32 calls were made explicitly Unicode, shutdown/resource ownership and fixation filtering were repaired, and Qt 5/Qt 6 parameter/state parity passed without hardware. `FreeImage.dll` and the vendor DLLs' VC++ 2008 dependency `MSVCR90.dll` ship app-locally. ⚠ Tracker discovery, calibration, live samples/events, sync and EDF transfer still require a physical EyeLink. Full port record: `R:\src\eyelink\README.md`. |
| `DAQmx` | **ported** | Installed NI SDK: `Shared/ExternalCompilerSupport/C/include/NIDAQmx.h` and `lib64/msvc/NIDAQmx.lib` | NI API 26.5.0, x64 System32/nicaiu.dll loaded externally; no NI runtime bundled. No real/simulated devices found. Software parity/recovery tested; physical acquisition remains. See [DAQmx](../components/daqmx.md). |
| `KARDi2` | **x64 + an x86 broker** | `KARDi2/vendor/KARDi2.dll` | 32-bit vendor DLL, PE32/i386, no x64 build exists — but since 2026-09-02 that no longer forces the *service* to be x86. `KARDi2.exe` is an ordinary x64 Qt 6 service; `kardi2-broker-x86.exe` is the only process that loads the DLL, and they speak framed anonymous pipes. The module now **requires** `CMAKE_SIZEOF_VOID_P EQUAL 8`. Russian-language vendor docs in `3dparty/Doc/`. Service name is `KARDi2N`. Full reference: [kardi2.md §10](../components/kardi2.md) |
| `eStim` | **ported** | `eStim/dll_x64/NsEzUSB.lib`, `ELECTROSTIM.lib` | **64-bit** vendor DLLs, taken from Neurosoft's own shipping programs. The vendor ships no import libraries — these were generated from the export tables with `lib.exe /def` (the `.def` files are beside them). Exports are undecorated and x64 has one calling convention, so no `__stdcall`; the device handle is pointer-sized. Needs the `newezusb` kernel driver (its `AMD64.sys`), **not** WinUSB. |

<a id="history-not-built-in-either-tree"></a>

### Not built, in either tree
* `eyetribe` — has `CMakeLists.txt` but the top-level line is commented out with
  *"was not upgraded to latest resonance"*. Uses QtQuick + a `calibrate.qml`. `R:\src_Qt5` only.
* `openBCI` — `main.cpp` includes `<Resonance/resonanceapp.h>`, a file that does not exist in
  either tree. Never ported past the pre-3.0 API. No `CMakeLists.txt`. `R:\src_Qt5` only.

---


<a id="history-tooling--infra-directories"></a>

## Tooling / infra directories

* **`3dparty/`** — in `R:\src_Qt5`, three git submodules, all populated since the tree became a real
  clone: `thir` (3 447 files — required, the whole binary protocol), `qml-colors` (48 — required by
  `quickStimulus/res.qrc`), `access_private` (9 — only for a disabled test).
  Pinned SHAs in [known-issues.md §1](../incidents/README.md).
  ⚠ In `R:\src` they are **plain directories, not submodules** — the tree root carries no
  `.gitmodules` and neither directory carries a `.git` gitlink (the `.gitmodules` *inside* `thir` is
  that upstream project's own file), so the Qt 6 tree has no hidden source dependency on the Qt 5
  one. Only `thir` (3 438) and `qml-colors` (47) crossed; `access_private` did not.
* **`scripts/`** — ⚠ **`R:\src` only.** The Qt 6 build, deployment and QA surface, 38 files:
  `build-qt6.ps1`, `deploy-qt6.ps1`, `validate-dist-qt6.ps1`,
  `capture-parameter-column.ps1`, `validate-qt5-interop.ps1`, `validate-quickstimulus-builtins.ps1`,
  six `test-*-parity.py` cross-generation comparisons (with `validate-qt5-interop.ps1` these are
  the "seven parity scripts" of
  [`build_qt5-to-qt6-transition.md`](qt5-to-qt6-transition.md) §5), and the QML harnesses
  the ported services were exercised with. There is no equivalent in `R:\src_Qt5`; its build is the hand-run
  CMake/Conan sequence in [build_and-distro.md](and-distro.md).
* **`profiles/`** — ⚠ **`R:\src` only.** One Conan profile, `msvc-v143-release`. The Qt 5
  `msvc64` / `mingw64` / `mingw32` profiles live in the user Conan home and are documented in
  [build_dev-environment.md](dev-environment.md).
* **`runtime-content/`** — ⚠ **`R:\src` only.** Deployment payload the compiler does not produce:
  `python\` (SPEED's private Python 3.12.1 runtime), `mulines\`, `params\` and `qt.conf`.
* **`shared/`** — ⚠ **`R:\src` only.** One file, `SquareCheckBox.qml`, referenced by alias from
  `recorderService/res.qrc` and `playbackService/res.qrc`.
* **`ci/`** — ⚠ **`R:\src_Qt5` only.** The *legacy* release pipeline: `build_resonance.bat`
  (mingw_32) and `build_resonance_64.bat` (mingw_64) drive **QBS + Conan 1 + conda**, then
  `quick_conda_package.py` + `pack_resonance.bat` build a conda package and
  `anaconda upload` it to the `bcilab` channel. `copyQtFiles.py` filters a Qt kit down to a
  redistributable subset. `get_version.py` = `git describe --tags`.
  These scripts reference `c:\Qt\5.15.0\...` — a path that does not exist on this PC.
  **Reference only; do not run as-is.**
* **`qbs/`, `Core/install/qbs/`** — ⚠ **`R:\src_Qt5` only.** QBS modules. `git_version-module.qbs`
  generates `version.cpp` with build date / revision / branch. Neither CMake build has an
  equivalent (see known-issues). ⚠ The `.qbs` files *inside* modules did cross — `R:\src` carries 29
  of them, `R:\src_Qt5` 51 — but nothing in the Qt 6 tree can build them.
* **`bat/`** — ⚠ **`R:\src_Qt5` only.** `env.bat`, `runenv.bat`, `speed.bat` (the last one sets
  `R_HOME` and adds `R\bin\i386` to PATH — evidence the R engine was once shipped 32-bit).
* **`conaninfo/`** — `R:\src_Qt5` only; output directory for the Conan generator, gitignored.
* **`Documentation/`** — ⚠ **`R:\src_Qt5` only.** `Doxyfile` + `config.qdocconf`. QBS-only target.
* **`docs/`** — both, and they are different documents. `R:\src\docs` is the port's own record
  (`README.md`, `PORTING_LOG.md`, `VALIDATION.md`, `REMAINING_PORTS.md`,
  `PARAMETER_FILE_PERSISTENCE.md`, `STREAM_CONNECTOR_LABEL.md`, the 2026-09-02 KARDi2/arduinoTTL
  hardware validation, and `qa\`). ⚠ `R:\src_Qt5\docs` is a **stale 2026-08-26 copy of `R:\docs`**;
  `R:\docs` is authoritative.

---


<a id="history-dead--historical"></a>

## Dead / historical

All of these are in `R:\src_Qt5` only. Under Qt 6 they are not "dead modules in the tree" — they
are **absent**, which is a different claim: nothing in `R:\src` will ever try to build them.

| Path | Why it's dead |
|---|---|
| `fileConverter/converter.cpp` | Reads the abandoned `.r2e` format via Cap'n Proto; absolute paths from a 2015 dev machine; `filereader.h` isn't even in the tree. |
| `SaveLib/SaveLib.qbs` | `condition: false`; references a `../ComLib` directory that no longer exists. |
| `Tests/Tests.qbs` | All three references commented out. `Tests/gtest`, `Tests/Rengine` orphaned. |
| `conanfile.txt.bak` | Contains an **unresolved git merge conflict** between `master` and `feature/try-to-jump-to-qt6` — a 2022 attempt at the Qt 6 move that was abandoned in place. The move was finally made in 2026 by a different route: a fresh isolated tree, not a branch merge. Nothing in this file was reused. |
| `quickStimulus4Android.pro` | qmake project for an Android port; no supporting files remain. |

---


<a id="history-what-is-in-rsrc_qt5-and-not-in-rsrc"></a>

## What is in `R:\src_Qt5` and not in `R:\src`

The complete list, with the reason for each. Nothing here is an oversight of this document; every
line was checked against both trees on 2026-09-02.

| Directory | Why it did not cross |
|---|---|
| `stimulusService/legacy` | The 18 Controls 1 paradigms remain Qt 5-only; the standalone service is ported with TepSound presentation scope |
| `tepService` | Retired; `tepSoundService` is the active replacement |
| `eyetribe`, `openBCI` | Pre-3.0 API, out of both CMake builds already |
| `DemoApp`, `fileConverter`, `SaveLib`, `Tests`, `Documentation` | Utilities and examples from the QBS era |
| `qbs`, `Core/install/qbs`, `ci`, `bat`, `conaninfo` | QBS / Conan 1 / conda build infrastructure, superseded by `R:\src\scripts` |
| `Core/docs` | The three Doxygen pages. ⚠ No reason — they were simply not copied, and they are still worth reading |
| `3dparty/access_private` | Only ever needed by `OutputStreams_test.cpp`, which is wired up in neither tree |
| `conanfile.txt.bak`, `quickStimulus4Android.pro`, `Resonance.qbs`, `ResonanceApp.qbs`, `conan_install.sh` | Historical build files |
| `.git`, `.gitmodules` | ⚠ Deliberate: the Qt 6 tree has **no repository at all**, so it has no hidden source dependency on `R:\src_Qt5`. It also has no history — see [`arch_qt6-work-list.md`](qt6-work-list.md) §5. One artefact survived the copy: `R:\src\scriptEngines\R\.git` is still a gitlink reading `gitdir: ../../.git/modules/scriptEngines/R`, which resolves to nothing in `R:\src` — harmless, but any `git` command run inside that directory dies with `fatal: not a git repository: (NULL)` rather than reporting no repository |
