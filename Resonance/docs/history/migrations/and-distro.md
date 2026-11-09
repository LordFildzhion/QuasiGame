# Building Resonance and assembling a distribution — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../how-to/build.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-building-resonance-and-assembling-a-distribution"></a>


**Status, 2026-09-02: the default build is Qt 6.11.2 — `R:\src` → `R:\dist`, driven by three
PowerShell scripts, and that is §0 below.** Everything from §1 to §6 describes the **Qt 5.15.2
comparator** (`R:\src_Qt5` → `R:\dist_Qt5`), which is still built and still needed; its paths have
been corrected but nothing else about it changed. §7 applies to both generations. Background and
the full decision record: [`build_qt5-to-qt6-transition.md`](qt5-to-qt6-transition.md).

> **Both regressions that blocked `R:\dist` were closed on 2026-09-02** — the NVX-136 driver was
> resynchronised from `R:\src_Qt5` and the Neuro-MS `standby` state was merged with the Qt 6
> handshake fix ([`arch_qt6-work-list.md`](qt6-work-list.md) §1). ⚠ No Qt 6 build has yet
> driven a physical device, so the first session is a bring-up and
> `R:\dist_Qt5\msvc64` still from `R:\dist_Qt5\msvc64` until both land. That is a *runtime* caveat: the build and deploy
> procedure below is the current one regardless.

---


<a id="history-0-the-qt-6-route--build-deploy-validate"></a>

## 0. The Qt 6 route — build, deploy, validate

Three scripts, all in `R:\src\scripts\`, all requiring nothing on `PATH` beforehand: they locate
their own compiler, CMake, Ninja and Qt by absolute path and throw if any is missing.

```powershell
& R:\src\scripts\build-qt6.ps1                              # compile
& R:\src\scripts\deploy-qt6.ps1 -Destination R:\dist        # build + package
& R:\src\scripts\validate-dist-qt6.ps1 -Distribution R:\dist   # prove it runs
```

<a id="history-01-what-the-distribution-looks-like-now"></a>

### 0.1 What the distribution looks like now

⚠ **The shape changed, not just the name.** The Qt 5 distro nests its payload one level down
(`R:\dist_Qt5\msvc64\bin\`) because it shipped several architectures side by side. The Qt 6 distro
has exactly one x64 payload, so everything sits at the root:

```
R:\dist\                 3 661 files, 504 MB
├── *.bat                23 files: 20 service/built-in launchers, 2 python tests, env.bat
├── bin\                 16 service .exe, Resonance.dll, the vendor DLLs and firmware,
│   ├── qt.conf          [Paths] Prefix=../qt   ← moved here from qt\bin\
│   ├── Resonance\       quickStimulusPlugin.dll + qmldir + all QML
│   └── engines\         pythonEngine.dll
├── qt\                  bin\ (67 DLLs incl. the app-local CRT) plugins\ qml\ — no translations
├── python\              private CPython 3.12 runtime for SPEED/pythonEngine
├── data\ params\ montages\ protocols\ calib\ stimuli\ mulines\
└── driver\kardi2\       the vendor USB kernel driver — McsUsb.inf/.cat, amd64\ and i386\
```

⚠ **Build output lives *inside* the source tree**, which reverses the §5 rule below: `R:\src\_build`,
`_dist`, `_patches`, `_stage`, `_test-output` and `KARDi2\_build-x86` are all in-tree. The "never build
inside the source tree" rule still governs the Qt 5 comparator and only that.

⚠ **Both CMake caches under `R:\src` are bound to the pre-rename path (`R:\srcQt6`) and must be
deleted before the next configure.** CMake refuses to reconfigure a cache whose source directory
moved, and `deploy-qt6.ps1 -SkipBuild` fails on the same cache:

```bash
rm -rf R:/src/_build
```

The deployed `R:\dist` is unaffected — it holds finished binaries and never consults the cache.

<a id="history-02-build-qt6ps1--what-it-actually-does"></a>

### 0.2 `build-qt6.ps1` — what it actually does

`param([ValidateSet('Release','RelWithDebInfo','Debug')]$Configuration = 'Release', [switch]$SkipConan)`

1. **Fails fast on a missing prerequisite.** It hard-checks Qt 6.11.2 at
   `C:\Qt515\6.11.2\msvc2022_64`, `C:\Qt515\Tools\CMake_64\bin\cmake.exe`,
   `C:\Qt515\Tools\Ninja\ninja.exe`, the VS 2026 Build Tools `vcvarsall.bat` under
   `…\Microsoft Visual Studio\18\BuildTools\`, the Conan profile `R:\src\profiles\msvc-v143-release`,
   and a **user-local Python 3.12** (`%LOCALAPPDATA%\Programs\Python\Python312`) together with the
   `pybind11` CMake package inside its `site-packages`. pybind11 is *not* a Conan dependency in this
   tree — `R:\src\conanfile.txt` requires only `hdf5/1.13.1`, `boost/1.78.0` (header-only),
   `iir1/1.9.0` and `gtest/1.15.0`.
2. **Pins the toolset**: `vcvarsall.bat x64 -vcvars_ver=14.44`, imported by running `set` in a child
   `cmd` and copying every variable back. Three toolsets are installed side by side
   (14.29.30133 = v142, **14.44.35207 = v143, the one used**, 14.51.36231 = v145, VS 2026's
   default), and the `-vcvars_ver` switch is the only thing that chooses between them. Their
   redistributables sit beside them as `Microsoft.VC142/143/145.CRT` — which is why step 4 of §0.3
   matters.
3. **Sets the console to UTF-8** — `chcp.com 65001` plus `[Console]::OutputEncoding`. ⚠ This is not
   cosmetic. Ninja recognises a header dependency by string-matching `cl.exe`'s localized
   `/showIncludes` prefix against the one CMake probed at configure time; this machine's OEM code
   page is 866, so a build left at the default records **no header dependencies at all** and a later
   header edit links a mixed-layout binary that faults at run time. See
   [known-issues](../incidents/README.md) §11c.
4. **`conan install` into `R:\src\_build`** with `-c "tools.cmake.cmaketoolchain:user_presets="` and
   ⚠ `-c tools.build:jobs=1`. Dependency builds are deliberately **serial**: MSVC 19.44 has been
   observed to ICE when Conan compiles several copies of `gtest-all.cc` concurrently. The project
   build itself is still `-j 6`.
5. **Configures and builds**: `cmake -S R:\src -B R:\src\_build -G Ninja`, with
   `CMAKE_PREFIX_PATH` = the Qt 6 kit **plus** the pybind11 package, and `Python_ROOT_DIR` /
   `Python_EXECUTABLE` pinned to 3.12 so CMake does not pick a newer interpreter pybind11 cannot use
   — the same trap as the Qt 5 `-DPython_ROOT_DIR` flag in §5. Then `cmake --build … -- -j 6`.

⚠ **Step 4a, and it happens BEFORE the configure: the KARDi2 x86 broker.** `build-qt6.ps1` runs a
separate `cmake` + `ninja` for `KARDi2\broker` in its own `cmd.exe` under the **x86** MSVC
environment, producing `KARDi2\_build-x86\bin\kardi2-broker-x86.exe`. That binary is an *input* to
the `KARDi2` target — CMake installs and copies it — and this tree cannot build it as a target,
because one configure produces one architecture.

The order is load-bearing. `KARDi2/CMakeLists.txt` used to `message(FATAL_ERROR)` on a missing
broker while being processed by `add_subdirectory()`, so a machine that had never run the old island
build got **zero binaries for the whole tree** and the recovery was circular. It now warns and
returns in-tree, fatal only standalone. `scripts\build-kardi2-x32.ps1` is **deleted**;
`KARDi2\_legacy\qt5-island` is kept for reference and is in no build. See
[`service_kardi2.md` §10](../components/kardi2.md).

<a id="history-03-deploy-qt6ps1--what-it-actually-does"></a>

### 0.3 `deploy-qt6.ps1` — what it actually does

`param([string]$Destination = 'R:\dist', [switch]$SkipBuild)`

1. Runs `build-qt6.ps1` (with `-SkipConan` if a `conan_toolchain.cmake` is already there), unless
   `-SkipBuild`. That one script now covers the KARDi2 broker too.
2. **Asserts 26 named build outputs exist before touching the destination** — every service `.exe`,
   `nmsbridge.dll` and `ns65bridge.dll` (the two `/clr` bridges), `ActiChamp_x64.dll`,
   `engines\pythonEngine.dll`, `Resonance\quickStimulusPlugin.dll`, and KARDi2's `KARDi2.exe`,
   `KARDi2.dll` and `kardi2-broker-x86.exe`. A partial build cannot half-deploy. Asserting all
   three KARDi2 files is the point: the service is useless without its broker, and the broker binds
   the vendor DLL by directory.
3. `cmake --install R:\src\_build --prefix R:\dist --config Release`.
4. Re-imports the **same** `-vcvars_ver=14.44` environment, because `windeployqt` reads
   `VCINSTALLDIR` to find the matching redistributable and would otherwise ship v145's.
5. **Stages `qt\qml\QtCore` by hand first.** quickStimulus's built-in recorder uses the Qt 6
   `Settings` type from `QtCore`, but the application QML is embedded in a `.qrc`, so `windeployqt`
   never sees that import. The plugin is then handed to `windeployqt` as a scan target so its own
   `Qt6QmlCore` dependency is packaged too.
6. **`windeployqt` over 20 targets** — the 16 service executables plus
   `ResonanceForeignDriver.dll`, `engines\pythonEngine.dll`, `bin\Resonance\quickStimulusPlugin.dll`
   and `qtqmlcoreplugin.dll` — with `--release --force --compiler-runtime --no-translations
   --skip-plugin-types qmltooling,generic` and explicit `--libdir` / `--plugindir` /
   `--qml-deploy-dir` under `R:\dist\qt`. ⚠ The compiled QML plugin is scanned **explicitly**:
   `windeployqt` does not discover it from a `qmldir`, and without it the plugin's `Scxml` and
   `SerialPort` dependencies are silently absent.
7. **Copies the v143 14.44 `Microsoft.VC143.CRT` DLLs app-locally** into `qt\bin`, on top of the
   `vc_redist.x64.exe` that `--compiler-runtime` drops there. The package therefore starts on a
   machine where the redistributable was never installed — unlike the Qt 5 tree (§5c).
8. **Copies the x86 island** into `R:\dist\kardi2_x32\` and installs `KARDi2\KARDi2_Qt6.bat` as the
   root `R:\dist\KARDi2.bat`, a one-line shim that enters the island's own `env.bat` without ever
   putting Qt 5 on the Qt 6 `PATH`.

<a id="history-04--three-things-deploy-qt6ps1-does-not-do"></a>

### 0.4 ⚠ Three things `deploy-qt6.ps1` does *not* do

* **It takes no rollback copy.** There is no `bin.pre-<stamp>` step anywhere in the script, and
  `R:\dist` holds exactly one `bin\`. The Qt 5 tree visibly relied on the habit — ten
  `bin.pre-*` directories sit beside `R:\dist_Qt5\msvc64\bin`, all made by hand. **Copy `bin\`
  yourself before redeploying over a distribution a rig is using.**
* **It deletes nothing.** `cmake --install` and `Copy-Item -Force` overwrite; neither removes. A
  binary or QML file that was dropped from the build survives every subsequent redeploy.
* **It overwrites operator-editable content from source.** The install rules are:

  | Destination | Rule | What is rewritten |
  |---|---|---|
  | `params\` | `CMakeLists.txt:81`, from `runtime-content\params\` | `nvx52_test34ch.json`, `speed_feetStim.json` — **2 of the 19 files there** |
  | `montages\` | `CMakeLists.txt:79-80` (`*.ced` from `quickStimulus\import\Resonance\Bricks\`) **and** `tepSoundService\CMakeLists.txt:181` | the 8 `.ced` in `Bricks\`, plus tepSound's own `mks64_emg2.ced` / `mks64_standard.ced` under the same two names. Of the 9 in `R:\dist\montages\`, only `mumeg_mks64.ced` has no rule and survives |
  | `calib\` | `tepSoundService\CMakeLists.txt:182` | `mks64_leadfield.h5` |
  | `protocols\` | `tepSoundService\CMakeLists.txt:183` | `library.json`, `operator-demo.tep.json`, `tms-cue-block.json` |
  | `bin\qt.conf` | `CMakeLists.txt:82`, from `runtime-content\qt.conf` | the whole file |
  | `python\`, `mulines\` | `SPEED\CMakeLists.txt:25-26`, from `runtime-content\` | both trees wholesale — including the `mulines\src\mulines\*.py` analysis scripts |
  | `bin\Resonance\` | `quickStimulus\CMakeLists.txt:152`, `tepSoundService\CMakeLists.txt:176` | all QML, copied **from source**, not from the build tree |
  | `data\`, `stimuli\`, the other 17 `params\*.json` | **no rule** | created if absent, never provisioned, never touched |

  So `protocols\operator-demo.tep.json` — exactly the file an operator edits between sessions — is
  rewritten by every deploy, while the other seventeen `params\` presets beside it are never
  provisioned at all. Two classes of content with opposite update semantics and nothing in the tree
  marks which is which. **Back up `protocols\` and `calib\` before a redeploy.** Logged as a fix in
  [`arch_qt6-work-list.md`](qt6-work-list.md) §7.

<a id="history-05-the-three-validators"></a>

### 0.5 The three validators

All in `R:\src\scripts\`. Two take `-Distribution` and default it to `R:\dist`; the interop one
takes `-Qt5Distribution` (default `R:\dist_Qt5\msvc64`) and `-Qt6Distribution` (default `R:\dist`)
instead. All redirect the launched processes' stdout/stderr into `R:\src\docs\qa\`. They are the
mechanised form of §7 and do not replace it. (`validate-kardi2-x32.ps1` was the fourth; it checked
a 15-file island that no longer exists and is deleted — `validate-dist-qt6.ps1` asserts the three
KARDi2 files instead.)

| Script | What it proves |
|---|---|
| `validate-dist-qt6.ps1` | 65-entry file-completeness list, then launches `bin\nvx.exe` and `bin\quickStimulus.exe` with a `PATH` that deliberately contains **no Qt installation directory** — a pass proves the package resolves Qt, QML, plugins and the CRT from `R:\dist` alone. Fails on any of seven stderr patterns, including *any* `file:///…:line:col:` or `qrc:/…:line:col:` diagnostic. Reports the deployed Qt version read from `qt\bin\Qt6Core.dll`. `-CapturePath x.png` additionally sizes the window to 960×700, clicks the NVX service row and saves a screenshot. |
| `validate-quickstimulus-builtins.ps1` | Starts `quickStimulus --builtIn configurator\|generator\|recorder` and requires the three window titles `Configurator` / `Generator` / `Recorder`. This is the check that catches a missing `QtCore` Settings plugin — only the recorder uses it, so `validate-dist-qt6.ps1` alone would not notice. |
| `capture-parameter-column.ps1` | Starts the services and walks the Configurator's tree, capturing the window with each service selected, into `docs\qa\param-column\`. The visual acceptance test for the **300 px parameter-column contract** ([qt5-to-qt6-transition.md §6a](qt5-to-qt6-transition.md)): every service's editors must fit, nothing clipped, no horizontal scroll bar. ⚠ Pass `-Only` a handful of names — fifteen services announcing at once are not all discovered, and a row index computed against an incomplete tree selects the wrong service. |
| `validate-qt5-interop.ps1` | Starts `R:\dist_Qt5\msvc64\bin\nvx.exe`, then the Qt 6 Configurator, and requires `Configurator ready` plus **≥ 2** `Discovered StreamInfo` lines in the Qt 6 log. The cross-generation wire-protocol check; it is why `R:\dist_Qt5` cannot be deleted. |

⚠ Every one of these is pinned to this machine by absolute paths. They are procedures, not a
portable CI.

---

> ## Everything from here to §6 is the Qt 5 comparator
>
> `R:\src_Qt5` → `R:\dist_Qt5\<name>`. It is still built, and §7 at the end applies to both
> generations. What it says about the *reasoning* — why an architecture gate exists, why
> `neuronSpectrum` cannot be MinGW, what a distro tree must contain — is unchanged and is why this
> half was kept rather than deleted. What it says about *which tree the rigs run* is not: that is
> `R:\dist`, per §0.


<a id="history-1-why-there-are-two-architectures"></a>

## 1. Why there are two architectures

Not an aesthetic choice — three vendor DLLs shipped in 2024 **only as 32-bit binaries**:

| DLL | Module | Verified PE machine | Still 32-bit-only? |
|---|---|---|---|
| `KARDi2.dll` | `KARDi2` | x86-32 | **Yes.** `R:\dist\kardi2_x32\bin\KARDi2.dll` is machine `0x14c` |

⚠ **Two of the three are no longer a reason for a 32-bit tree.** `R:\src\eStim\dll_x64\` carries
64-bit `NsEzUSB.dll` and `ELECTROSTIM.dll` taken from Neurosoft's own shipping programs (their
import libraries were generated from the export tables with `lib.exe /def`, since the vendor ships
none). Both files are machine `0x8664` in `R:\dist\bin` *and* in `R:\dist_Qt5\msvc64\bin`, and the
x64 `mStim` / `eStim` services use the current 64-bit device libraries. Only `KARDi2.dll`
still forces a 32-bit process — which is why the Qt 6 distribution contains exactly one nested tree,
`R:\dist\kardi2_x32\` (§0.1), and no second full distribution.

Everything else the lab uses is x64-only in practice (`nvxmcs.dll`, `NVX136.dll`,
`ActiChamp_x64.dll`, `eyelink_core64.dll`, NI-DAQmx).

A Windows process cannot mix bitness, so the Qt 5 comparator ships **two complete, independent
trees**. That is fine architecturally, because services talk over TCP/UDP — a 32-bit `KARDi2.exe`
and a 64-bit `nvx136.exe` interoperate at runtime without either knowing the other's bitness. **The
two trees are meant to be run side by side, not chosen between.**

⚠ **That sentence is about x86 vs x64 and no longer describes the default distribution.** `R:\dist`
is a single x64 tree; the surviving 32-bit half is one service, staged as
`R:\dist\kardi2_x32\` and entered by a launcher rather than run as a parallel distribution. There is
no Qt 6 successor to `mingw32` / `mingw64`: both are archived under `R:\dist_2026aug\`, and
`mingw32` there holds the last built `fieldtrip.exe` (2026-08-15). `mingw64` never had it because
the local module is behind the 32-bit gate below. The identical reasoning still applies one level
down: the island and the host are two processes that find each other over the wire protocol, not one
process that loads both runtimes.

The arch gates live in each module's `CMakeLists.txt`:

```cmake
IF (WIN32 AND (CMAKE_SIZEOF_VOID_P EQUAL 4))   # historical 32-bit gate: KARDi2, fieldtrip
IF (WIN32 AND (CMAKE_SIZEOF_VOID_P EQUAL 8))   # 64-bit only: nvx, nvx136, actiChamp, eyelink,
                                               #              DAQmx, neuronSpectrum
```

Ungated (built in both): `Core/Resonance`, `SignalGenerator`, `SPEED`, `quickStimulus`,
`COMport`, `ResonanceForeignDriver`, `scriptEngines`.

<a id="history-a-second-gate-toolchain-not-architecture"></a>

### A second gate: toolchain, not architecture

`neuronSpectrum` adds `IF (MSVC)` inside the x64 gate. Its vendor SDK is .NET Framework 4.8
managed code, so one translation unit is compiled `/clr`, and **MinGW cannot produce a
mixed-mode image at all**. Under MinGW the module is skipped and the rest of the tree still
builds — the same shape as the arch gates, on a different axis. It also needs the
**C++/CLI support for v142 build tools** component for `mscoree.lib`
([dev-environment-setup §B5](dev-environment.md#history-b5-net-framework-48-sdk--ccli--for-neuronspectrum-and-neuroms)).

This is the first module that cannot exist in both trees for a reason other than a 32-bit
vendor DLL, and it is worth knowing when comparing `mingw64` against `msvc64`: a missing
`neuronSpectrum.exe` in a MinGW tree is correct, not a packaging failure.

The gate survived the port unchanged, and there are now **two** managed bridges rather than one:
`R:\dist\bin\ns65bridge.dll` (Neuron-Spectrum) and `R:\dist\bin\nmsbridge.dll` (Neuro-MS), both
listed by name in `deploy-qt6.ps1`'s precondition check. The C++/CLI build-tools component is
therefore still required — but for **v143**, not v142.

---


<a id="history-2-the-reference-distribution-rdist_legacydistro-dual"></a>

## 2. The reference distribution: `R:\dist_legacy\distro-dual`

Built 2024-10-05 (`nvx136.exe` refreshed 2025-10-01). Verified by reading PE headers and
import tables.

```
distro-dual\
├── mingw32\          x86-32, MinGW GCC 8.1 (dw2), imports msvcrt.dll
│   ├── *.bat         launchers (COMport, KARDi2, SPEED, fieldtrip,
│   │                 configurator, generator, recorder, quickStimulus, signalGenerator,
│   │                 pygame_test, pyqt5_test) + env.bat
│   ├── *.py          resonance_foreign_driver.py, pygame_test.py, pyqt5_test.py
│   ├── bin\
│   │   ├── libResonance.dll  libResonanceForeignDriver.dll
│   │   ├── COMport.exe KARDi2.exe SPEED.exe SignalGenerator.exe
│   │   ├── fieldtrip.exe quickStimulus.exe
│   │   ├── KARDi2.dll NsEzUSB.dll Electrostim.dll      (32-bit vendor DLLs)
│   │   └── Resonance\        quickStimulusPlugin.dll + qmldir + all QML
│   └── qt\           bin\ plugins\ qml\ translations\ phrasebooks\
│                     (+ libgcc_s_dw2-1.dll libstdc++-6.dll libwinpthread-1.dll)
└── msvc\             x64, MSVC (imports vcruntime140.dll, vcruntime140_1.dll, msvcp140.dll)
    ├── *.bat         COMport, DAQmx, NVX, NVX136, SPEED, actiChamp, eyeLink,
    │                 configurator, generator, recorder, quickStimulus, signalGenerator + env.bat
    ├── params\       saved service configs (NVX136-simulation.json), testparams.json
    ├── bin\
    │   ├── Resonance.dll  ResonanceForeignDriver.dll
    │   ├── COMport.exe DAQmx.exe SPEED.exe SignalGenerator.exe actiChamp.exe
    │   ├── eyeLink.exe nvx.exe nvx136.exe quickStimulus.exe
    │   ├── vendor: nvxmcs.dll NVX136.dll ActiChamp_x64.dll eyelink_*64.dll FreeImage.dll
    │   ├── firmware: ActiChamp.bit ActiChampX.bit NVX136.bit NVX136R2.bit NVX136R3.bit
    │   ├── engines\pythonEngine.dll        (links python312.dll)
    │   └── Resonance\  quickStimulusPlugin.dll + qmldir + all QML
    └── qt\           bin\ plugins\ qml\ translations\ phrasebooks\
```

**Naming tell:** MinGW prefixes shared libraries with `lib` (`libResonance.dll`), MSVC does not
(`Resonance.dll`). `quickStimulusPlugin.dll` is unprefixed in both because its CMake target sets
`PREFIX ""`.

<a id="history-runtime-contract"></a>

### Runtime contract

`env.bat` (identical in both trees):

```bat
@echo off
pushd .
cd /d "%~dp0"
set RESONANCE_DIR=%CD%
set RESONANCE_PATH=%CD%\bin;%CD%\qt\bin
set "RESONANCE_RECORD_PATH=%CD%\data"
if not exist "%RESONANCE_RECORD_PATH%\" mkdir "%RESONANCE_RECORD_PATH%"
set PYTHONHOME=%CD%\python
set PATH=%RESONANCE_PATH%;%PYTHONHOME%;%PATH%
popd
```

**Distribution requirement:** every assembled tree must contain an initially empty `data\`
directory at the same level as `bin\` and `qt\`. `env.bat` sets the absolute
`RESONANCE_RECORD_PATH` to that directory and creates it if an older or manually copied tree is
missing it. Every normal launcher inherits the value. Starting an `.exe` directly bypasses
`env.bat`; Resonance then falls back to the process's current working directory, so direct launch
is not an accepted deployment procedure for recording.

Every launcher is:

```bat
@echo off
call env
cd bin
start <Target> %*
```

except the three quickStimulus apps, which are `call quickStimulus --builtIn <configurator|recorder|generator>`.

`qt\bin\qt.conf` contains `Prefix=..`, which is what makes Qt find `qt\plugins` and `qt\qml`.

Note `PYTHONHOME=%CD%\python` — a `python\` folder is expected in the distro root for the
Python engine and the ctypes driver. It is **not present** in `distro-dual`; on those machines
Python came from a conda env (see `R:\dist_legacy\clinicP300\install_*.bat`, which installed
`resonance_mingw_32` / `resonance_mingw_64` from the `bcilab` Anaconda channel). Decide
explicitly which model you want going forward — embedded `python\` folder is simpler.

---


<a id="history-4-choosing-the-toolchain-for-each-branch"></a>

## 4. Choosing the toolchain for each branch

**The answer for the default tree is not in this table: it is Qt 6.11.2 `msvc2022_64` with MSVC
v143 14.44, x64 only, and `build-qt6.ps1` chooses it for you (§0.2).** What follows is the
comparator's decision, and the measurement underneath it — which is worth keeping, because it is the
only place the MinGW-vs-MSVC question was ever actually settled by experiment.

|  | 32-bit branch | 64-bit branch |
|---|---|---|
| **As shipped (2024)** | MinGW 8.1 (`mingw81_32`) | **MSVC** + Qt msvc kit |
| **What the CI scripts did** | MinGW 8.1 32 | MinGW 8.1 **64** (`mingw81_64`) |
| **Installed on this PC today** | ✅ `C:\Qt515\5.15.2\mingw81_32` — and still load-bearing: it builds the KARDi2 x86 island (§0.2) | ✅ `C:\Qt515\5.15.2\mingw81_64`, ✅ `C:\Qt515\5.15.2\msvc2019_64`, ✅ `C:\Qt515\6.11.2\msvc2022_64` |

**The 32-bit branch must be MinGW.** `KARDi2/CMakeLists.txt` links against `KARDi2.dll`
directly (`target_link_libraries(… KARDi2.dll)`), which only GNU `ld` supports.

**For the 64-bit branch you have a real choice:**

* **MinGW x64** — zero extra installs, matches the old CI, one toolchain to reason about.
  Risk: linking the MSVC-produced `.lib` import libraries (`nvxmcs.lib`, `NVX136.lib`,
  `ActiChamp_x64.lib`, `eyelink_*64.lib`, `NIDAQmx.lib`, `nisyscfg.lib`). On x64 there is no
  `__stdcall` name decoration, and GNU `ld` reads COFF import libraries, so plain C APIs
  normally link fine — but this is the thing to prove first.
* **MSVC x64** — reproduces the shipped tree exactly and is the vendor-native choice for the
  NI/Brain Products/SR Research SDKs. Costs: install VS 2022 Build Tools **and** add the
  Qt 5.15.2 `msvc2019_64` kit. Also note the codebase has never been fully MSVC-clean
  (see [known-issues](../incidents/09-target_os_windows-is-never-defined-under-msvc.md#history-3-target_os_windows-is-never-defined-under-msvc)).

<a id="history--answered-2026-08-11-why-the-x64-branch-was-msvc--and-it-is-not-the-vendor-libs"></a>

### ✅ Answered 2026-08-11: why the x64 branch was MSVC — and it is not the vendor libs

MinGW-w64 x64 **builds the entire tree**, including `nvx`, `nvx136`, `actiChamp` and `eyeLink`,
linking straight against the MSVC-produced import libraries (`nvxmcs.lib`, `NVX136.lib`,
`ActiChamp_x64.lib`, `eyelink_*64.lib`). GNU `ld` reads COFF import libs and x64 has no
`__stdcall` decoration, so the C APIs link without complaint. **That hypothesis was wrong.**

The actual blockers were two source-level MSVC assumptions, both now fixed:

**1. `DAQmx` was written against the MSVC spelling of NI's header.**
`DAQmx/dll/include/NIDAQmx.h:58` picks a different underlying type per compiler:

```c
#if ((defined(__GNUG__) || defined(__GNUC__)) && defined(__x86_64__))
	typedef signed int         int32;      // MinGW-w64 x64
#else
	typedef signed long        int32;      // MSVC x64
#endif
```

`driver.cpp` declared its callbacks with `long`/`unsigned long`, which equals `int32`/`uInt32`
**only under MSVC**. Under MinGW: *"invalid conversion from `long int (*)(...)` to
`DAQmxEveryNSamplesEventCallbackPtr`"*. Fixed by using NI's own `int32`/`uInt32`/`TaskHandle`
typedefs, which are correct under both compilers.

A second, subtler one in the same header: `int64` is spelled `__int64` and guarded only by
`__linux__`/`__APPLE__`. Under MinGW `__int64` comes from `<_mingw.h>`, so **`NIDAQmx.h` is not
self-contained** — including it first in `driver.hpp` fails with *"'__int64' does not name a
type"*. It has to come after a standard or Qt header.

**2. `scriptEngines/python` uses `stdout` as a variable name.**
`pythonengine.cpp:197` (submodule @ `e2eed71`, == master):

```cpp
py::class_<StdIOHook> stdout(m, "stdout");
stdout.def_static("write", …);
```

`stdout` is a `<stdio.h>` macro (`__acrt_iob_func(1)`), so this expands to nonsense. Renaming
the local to `stdoutHook` fixes it. Note the macro exists in MSVC's UCRT too, so it is unclear
how the shipped `pythonEngine.dll` was ever produced from this commit — see the open questions
in [known-issues.md](../incidents/README.md).

**Conclusion:** MSVC was very likely a path of least resistance around the DAQmx typedef
mismatch, not a hard requirement. With three small portability fixes the x64 branch builds,
deploys and runs under MinGW 8.1 — verified against the shipped MSVC tree.

Remaining reasons you might still want MSVC: smaller binaries (`Resonance.dll` 3.1 MB vs
5.8 MB), byte-compatibility with what is already deployed on the rigs, and vendor-native
support for the NI/Brain Products/SR Research SDKs.

---


<a id="history-5-build-commands"></a>

## 5. Build commands

**These are the Qt 5 comparator's commands.** The Qt 6 default is `build-qt6.ps1` — §0.2. The
dated build records in §5a–§5c below were written when this tree was `R:\src` → `R:\dist\<name>`;
those paths were correct on their dates and are now `R:\src_Qt5` → `R:\dist_Qt5\<name>`.

Prerequisites: submodules fetched, Conan 2 installed and profiles created — all covered in
[dev-environment-setup.md](dev-environment.md).

> ### 🚫 Never build inside `R:\src_Qt5`
> The comparator's source tree stays pristine — no `build*/`, no `CMakeUserPresets.json`, no stray
> artefacts. All compiled work lives under `R:\dist_Qt5`:
>
> | Path | Contents |
> |---|---|
> | `R:\dist_Qt5\_build\<name>\` | CMake binary dir — objects, cache, Conan generators, `runtime\` |
> | `R:\dist_Qt5\<name>\` | the assembled, runnable distribution |
>
> `<name>` mirrors the reference: `mingw32`, `mingw64`, `msvc`.
> Pass `-c "tools.cmake.cmaketoolchain:user_presets="` to `conan install`, otherwise Conan drops
> a `CMakeUserPresets.json` into the source directory.
>
> ⚠ **This rule does not apply to the Qt 6 tree, which builds inside itself on purpose** —
> `R:\src\_build`, `_build-kardi2-x32`, `_dist`, `_stage`, `_test-output`. The
> `user_presets=` flag is passed there too, for the same reason.

<a id="history-32-bit-mingw-81-x86"></a>

### 32-bit (MinGW 8.1 x86)

```bat
set QTDIR=C:\Qt515\5.15.2\mingw81_32
set PATH=C:\Qt515\Tools\mingw810_32\bin;C:\Qt515\Tools\CMake_64\bin;C:\Qt515\Tools\Ninja;%PATH%

cd /d R:\src_Qt5
conan install . -of R:\dist_Qt5\_build\mingw32 -pr:h mingw32 -pr:b mingw32 ^
      -s build_type=Release -o "boost/*:header_only=True" ^
      -c "tools.cmake.cmaketoolchain:user_presets=" --build=missing

cmake -S R:/src_Qt5 -B R:/dist_Qt5/_build/mingw32 -G Ninja ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DCMAKE_TOOLCHAIN_FILE=R:/dist_Qt5/_build/mingw32/conan_toolchain.cmake ^
      -DCMAKE_PREFIX_PATH=%QTDIR%

cmake --build R:/dist_Qt5/_build/mingw32
```

<a id="history-64-bit-mingw-81-x64"></a>

### 64-bit (MinGW 8.1 x64)

Identical with `mingw810_64`, `mingw81_64`, profile `mingw64`, dirs `…\mingw64`.
Add `-DPython_ROOT_DIR=C:/Users/Anatoly/AppData/Local/Programs/Python/Python312` — otherwise
CMake picks the default 3.14 interpreter, which pybind11 2.11.1 does not support.

<a id="history-64-bit-msvc-qt-5-tree-only--must-use-the-v142-toolset-not-vs-2026s-default"></a>

### 64-bit MSVC (Qt 5 tree only) — **must use the v142 toolset**, not VS 2026's default

⚠ This constraint is Qt 5.15.2's, not the project's. The Qt 6 tree compiles under **v143 14.44**
and would not build under v142 at all; do not carry this heading across to `R:\src`.

VS 2026's STL removed `stdext::checked_array_iterator`, which Qt 5.15.2 uses unconditionally, so
the default v14.51 toolset **cannot compile Qt 5.15.2 at all**
([known-issues §11a](../incidents/17-visual-studio-2026-cannot-compile-qt-5152--needs-the-v142-toolset.md#history-11a-visual-studio-2026-cannot-compile-qt-5152--needs-the-v142-toolset)).
Select v142 explicitly — it is also the exact toolset Qt's kit was built with:

```bat
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64 -vcvars_ver=14.29
set PATH=C:\Qt515\Tools\CMake_64\bin;C:\Qt515\Tools\Ninja;%PATH%

cd /d R:\src_Qt5
conan install . -of R:\dist_Qt5\_build\msvc64 -pr:h msvc64 -pr:b msvc64 ^
      -s build_type=Release -o "boost/*:header_only=True" ^
      -c "tools.cmake.cmaketoolchain:user_presets=" -c tools.build:jobs=6 --build=missing

cmake -S R:/src_Qt5 -B R:/dist_Qt5/_build/msvc64 -G Ninja -DCMAKE_BUILD_TYPE=Release ^
      -DCMAKE_TOOLCHAIN_FILE=R:/dist_Qt5/_build/msvc64/conan_toolchain.cmake ^
      -DCMAKE_PREFIX_PATH=C:/Qt515/5.15.2/msvc2019_64 ^
      -DPython_ROOT_DIR=C:/Users/Anatoly/AppData/Local/Programs/Python/Python312

cmake --build R:/dist_Qt5/_build/msvc64 -- -j 6
```

⚠ Run this from a console at `chcp 65001` as well — see
[known-issues](../incidents/README.md) §11c. `build-qt6.ps1` does it for the Qt 6 tree; nothing does
it for you here.

The `msvc64` profile needs `compiler.version=192` **and** `tools.microsoft.msbuild:vs_version=18`
— see [known-issues §11a](../incidents/17-visual-studio-2026-cannot-compile-qt-5152--needs-the-v142-toolset.md#history-11a-visual-studio-2026-cannot-compile-qt-5152--needs-the-v142-toolset).

Do **not** use the Visual Studio generator — see
[known-issues §4](../incidents/10-nvx136-library-path-depends-on-cmake_build_type---fixed-2026-08-15.md#history-4-nvx136-library-path-depends-on-cmake_build_type---fixed-2026-08-15).

<a id="history-result"></a>

### Result

The generated package tree must contain `runtime\data\` before assembly. The same requirement
applies to `deploy\data\` when `cmake --install` is used.

`R:\dist_Qt5\_build\<name>\runtime\` — a distro tree without `qt\`. Assemble it into
`R:\dist_Qt5\<name>\` per [§6](and-distro.md#history-6-assembling-a-distro-tree).

---


<a id="history-5c-x64-build--msvc-v142-2026-08-11"></a>

## 5c. x64 build — MSVC v142, 2026-08-11

`R:\dist\msvc64` builds, deploys and runs. **163/163 targets**, no errors, and it genuinely
imports `vcruntime140.dll` / `vcruntime140_1.dll` / `msvcp140.dll`.

Output is a near-exact match for the 2024 reference — **eight executables byte-identical in
size**:

| File | Built 2026 | Shipped 2024 |
|---|---|---|
| `actiChamp.exe` | 55 296 | 55 296 |
| `COMport.exe` | 49 664 | 49 664 |
| `DAQmx.exe` | 51 200 | 51 200 |
| `eyeLink.exe` | 80 896 | 80 896 |
| `nvx.exe` | 73 216 | 73 216 |
| `nvx136.exe` | 72 704 | 72 704 |
| `SignalGenerator.exe` | 38 400 | 38 400 |
| `SPEED.exe` | 61 952 | 61 952 |
| `Resonance.dll` | 3 083 776 | 3 092 992 |
| `quickStimulusPlugin.dll` | 345 088 | 360 960 |
| `pythonEngine.dll` | 182 272 | 198 144 |
| `ResonanceForeignDriver.dll` | 35 840 | 46 080 |

The four that differ are accounted for: post-2024 commits (`229d551` "Update NVX and foreign
driver"), the `stdout` fix in the Python engine, and the DAQmx typedef change.

Verified per [§7](and-distro.md#history-7-verifying-a-deploy): all imports resolve (266 modules; same three external
deps as the reference), `signalGenerator` + `configurator` launch, discovery establishes, and
`pythonEngine.dll` loads.

**Deployment note:** like the 2024 tree, this does **not** ship the VC++ runtime. Target machines
need `C:\Qt515\vcredist\vc14.50.35719_VC_redist.x64.exe` (or `vcruntime140*.dll` + `msvcp140.dll`
beside the exes). MinGW builds have no such dependency.

---


<a id="history-5b-x64-build--mingw-w64-2026-08-11"></a>

## 5b. x64 build — MinGW-w64, 2026-08-11

`R:\dist\mingw64` builds, deploys and runs. Every binary the reference `distro-dual\msvc` ships
is present (except `nvx136_o.exe`, an old backup copy), all x64. MinGW output is larger:
`libResonance.dll` 5.8 MB vs MSVC's 3.1 MB, `quickStimulusPlugin.dll` 937 KB vs 361 KB.

Three source fixes were required — see
[§4](../../how-to/build.md):
`DAQmx` callback types, `DAQmx` include order, and the `stdout` variable in the
`scriptEngines/python` submodule.

**GCC 8.1 ICE:** HDF5 x64 failed once with `internal compiler error` in `avx512vlintrin.h`
(`H5Pgcpl.c`), then succeeded on an immediate retry with no changes. The x86 HDF5 failure was
almost certainly the same thing. Nondeterministic compiler bug — **always retry once before
investigating an HDF5 failure.**

---


<a id="history-5a-first-green-build--x86-2026-08-11"></a>

## 5a. First green build — x86, 2026-08-11

The 32-bit branch builds clean: **154/154 targets**, no warnings-as-errors, no missing deps.
Both gtest suites pass (`test_StreamInfo` 9/9, `test_SamplesCollector` 1/1).

Three source changes were needed, all documented in [known-issues.md](../incidents/README.md):
the `install_files_with_prefix` compat shim (§2), the x64 gate on `scriptEngines` (§2b), and
removing the never-committed `Head.qml.bak` from `quickStimulus` (§2c).

Conan notes:
* `-o "boost/*:header_only=True"` works and is a large time saver — Boost resolves to the empty
  package id, nothing to compile.
* HDF5 1.13.1 is the only dependency built from source (~400 compile steps under MinGW 8.1).
  The first attempt died with `ninja: build stopped: subcommand failed` and no `error:` in the
  log; an immediate retry succeeded. Treat a lone HDF5 failure as flaky and just re-run before
  investigating.
* Everything else (zlib, gtest, iir1, pybind11) came from the Conan cache/remote as binaries.

<a id="history-output-vs-the-2024-reference-distribution"></a>

### Output vs. the 2024 reference distribution

`R:\dist\_build\mingw32\runtime\bin` contains exactly the same 13 files as
`distro-dual\mingw32\bin`, all x86-32. Sizes line up closely enough to be confident this is the
same build:

| File | Built 2026-08-11 | Shipped 2024-10-05 |
|---|---|---|
| `COMport.exe` | 127 168 | 127 168 |
| `fieldtrip.exe` | 168 358 | 168 358 |
| `KARDi2.exe` | 131 296 | 131 296 |
| `SignalGenerator.exe` | 110 140 | 110 140 |
| `SPEED.exe` | 144 404 | 144 404 |
| `quickStimulus.exe` | 94 728 | 94 216 |
| `quickStimulusPlugin.dll` | 945 072 | 944 048 |
| `libResonance.dll` | 6 584 236 | 6 580 939 |
| `libResonanceForeignDriver.dll` | 95 839 | 82 701 |

Six binaries are byte-identical in size. The `ResonanceForeignDriver` gap is expected — the
shipped one predates commit `229d551` *"Update NVX and foreign driver"*, which landed after
`bad97c0`.

**Notable:** this means the CMake build produces the same artifacts the QBS build did, despite
never having been run end-to-end before. The CMake port was closer to correct than its three
configure-time bugs suggested.

---


<a id="history-6-assembling-a-distro-tree"></a>

## 6. Assembling a distro tree

> ⚠ **Do not follow this recipe for the Qt 6 distribution.** It is the Qt 5 comparator's hand-rolled
> assembly. `deploy-qt6.ps1` (§0.3) does strictly more — it runs `windeployqt` over 20 targets
> including the compiled QML plugin, hand-stages `qt\qml\QtCore`, copies the v143 CRT app-locally
> and builds the `kardi2_x32` island — and a Qt 6 tree assembled by robocopy from the kit would
> start and then fail on the first QML import it cannot resolve. The `qt.conf` step below is also
> wrong for Qt 6: there is exactly one `qt.conf` in `R:\dist` and it is `bin\qt.conf` with
> `Prefix=../qt`, not `qt\bin\qt.conf` with `Prefix=..`.

`R:\dist\mingw32` was built this way on 2026-08-11 and **verified working** (see
[§7](and-distro.md#history-7-verifying-a-deploy)). That tree is now archived as `R:\dist_2026aug\mingw32`;
`R:\dist_Qt5` holds only `msvc64` and `_build`, so the paths below are a template rather than a
transcript.

```powershell
$qt="C:\Qt515\5.15.2\mingw81_32"; $mgw="C:\Qt515\Tools\mingw810_32\bin"; $out="R:\dist_Qt5\mingw32"

# 1. the built tree: launchers at root, binaries in bin\
robocopy "R:\dist_Qt5\_build\mingw32\runtime" $out /E

# 2. recording destination (normally already copied from runtime\)
mkdir "$out\data" -ErrorAction SilentlyContinue

# 3. Qt runtime — kit minus doc/ include/ lib/ mkspecs/
mkdir "$out\qt\bin"
copy "$qt\bin\*.dll" "$out\qt\bin"
robocopy "$qt\plugins"      "$out\qt\plugins"      /E /XF *.qmlc *.jsc
robocopy "$qt\qml"          "$out\qt\qml"          /E /XF *.qmlc *.jsc
robocopy "$qt\translations" "$out\qt\translations" /E
robocopy "$qt\phrasebooks"  "$out\qt\phrasebooks"  /E

# 4. MinGW runtime (x86 = dwarf2 unwinder; x64 would be libgcc_s_seh-1.dll)
copy "$mgw\libgcc_s_dw2-1.dll","$mgw\libstdc++-6.dll","$mgw\libwinpthread-1.dll" "$out\qt\bin"

# 5. qt.conf so Qt finds ..\plugins and ..\qml
"[Paths]`r`nPrefix=.." | Set-Content "$out\qt\bin\qt.conf" -Encoding ascii
```

Result: **1 333 files, 199.6 MB** (reference: 1 507 files, 201.4 MB — the 174-file delta is
stale `.qmlc`/`.jsc` caches, correctly excluded; Qt regenerates them).

Traps found while doing this:

* **Do not filter `*d.dll` as "debug twins".** The Qt 5.15.2 MinGW kit is release-only and has
  no debug DLLs, but that glob matches `Qt53DQuickScene2**D.dll**` and `Qt5Gamepa**d.dll**` —
  deleting them silently breaks Qt Quick. Kit `bin` has 63 DLLs, exactly matching the reference;
  copy them all.
* The Qt kit's `bin` already contains `libgcc_s_dw2-1.dll`, `libstdc++-6.dll` and
  `libwinpthread-1.dll`, so step 3 is belt-and-braces.
* **MSVC branch** would additionally need the VC++ redistributable —
  `C:\Qt515\vcredist\vc14.*_VC_redist.x64.exe` is already on disk — or `vcruntime140.dll`,
  `vcruntime140_1.dll`, `msvcp140.dll` shipped next to the exes. ⚠ Not so for Qt 6:
  `deploy-qt6.ps1` copies the v143 14.44 `Microsoft.VC143.CRT` DLLs into `R:\dist\qt\bin`
  app-locally, so that package needs no redistributable installed on the target.
* `env.bat` sets `PYTHONHOME=%CD%\python`, but no `python\` directory is shipped (the reference
  doesn't have one either). Harmless unless you use the Python engine or the ctypes driver.
  ⚠ Also not so for Qt 6: `R:\dist\python\` is a real private CPython 3.12 tree, and the Qt 6
  `env.bat` sets `PYTHONHOME`, `PYTHONNOUSERSITE` and `PYTHONPATH` **only if**
  `python\python312.zip` is present.
* Counting DLLs is a MinGW-kit technique and does not carry over. `R:\dist\qt\bin` holds 67 DLLs,
  but they were selected by `windeployqt` from the Qt 6 kit and then added to — the CRT DLLs and
  `vc_redist.x64.exe` are in there too. Compare against `validate-dist-qt6.ps1`'s explicit list,
  not against a kit directory.

`ci/copyQtFiles.py` implements roughly the same rule set for the old conda flow (classifying
files into `release`/`debug`/`develop`/`ignore` from `QT_PATH`, `DISTNAME`, `PREFIX`,
`RELEASE_TYPE`). Kept for reference; `windeployqt` would give a much slimmer tree if size ever
matters.

---


<a id="history-7-verifying-a-deploy"></a>

## 7. Verifying a deploy

**This section applies to both generations.** `R:\dist` has four scripts that mechanise most of it
(§0.5); `R:\dist_Qt5` has none, and the steps below are done by hand there.

**A compile is not a deploy, and a deploy is not verified until it has been launched.**
Do all three of these before calling a build done.

<a id="history-71-static--every-import-resolves"></a>

### 7.1 Static — every import resolves

Walk the import table of every `.exe`/`.dll` in `bin\` recursively with `objdump -p`, resolving
each name against `bin\`, `bin\Resonance\`, `qt\bin\`, then `SysWOW64`/`System32`
(skip `api-ms-win-*`/`ext-ms-*`, those are apisets). Anything unresolved is a missing DLL.

⚠ **Use an `objdump` of the right bitness.** `C:\Qt515\Tools\mingw810_32\bin\objdump.exe` reports
*"File format not recognized"* on every x64 binary in `R:\dist\bin` — a result that reads like a
corrupt file and is not one. `C:\Qt515\Tools\mingw810_64\bin\objdump.exe` reads them
(`file format pei-x86-64`), as does `dumpbin /dependents` from the v143 environment. The x86 tool
is still the correct one for `R:\dist\kardi2_x32\bin\`, where `validate-kardi2-x32.ps1` uses it to
assert `pei-i386` on all four island binaries.

Also assert `qt\plugins\platforms\qwindows.dll` exists — without it every GUI service aborts at
startup with *"could not find or load the Qt platform plugin"*. Still exactly right for `R:\dist`:
verified present there.

Also assert that `data\` exists at distribution root and that the packaged `env.bat` contains
`RESONANCE_RECORD_PATH=%CD%\data`. `bin\data`, `qt\data`, and a build-machine absolute path are
packaging failures. Also still exactly right for `R:\dist` — with the note that the Qt 6 `env.bat`
sets **six** content-path variables (`RESONANCE_RECORD_PATH`, `_PARAMS_`, `_PROTOCOLS_`,
`_STIMULI_`, `_MONTAGES_`, `_CALIB_`) plus `QT_PLUGIN_PATH` and `QML2_IMPORT_PATH`, and that none
of them is *required*: with nothing set, every binary derives the root from its own location
(`bin\..`), so a shortcut straight into `bin\` still lands in the right folders.

⚠ **The `qt.conf` assertion changed.** `R:\dist` has exactly one, at `bin\qt.conf`, and it reads
`Prefix=../qt` + `Plugins=plugins` + `Qml2Imports=qml` — not `qt\bin\qt.conf` with `Prefix=..` as
in the Qt 5 trees. `Qml2Imports` is the Qt **5** key; Qt 6's is `QmlImports`, so that line is inert
and works only because `Prefix=../qt` already makes `qml` the default. See
[`arch_qt6-work-list.md`](qt6-work-list.md) §7.

x86 result: 13 root binaries, **233 modules walked, zero unresolved**.

<a id="history-72-dynamic--it-actually-starts"></a>

### 7.2 Dynamic — it actually starts

```powershell
Start-Process cmd.exe -ArgumentList '/c','signalGenerator.bat' -WorkingDirectory $out
Start-Sleep 6
Get-Process SignalGenerator                    # must exist
netstat -ano -p UDP | Select-String ':13370'   # must list that pid on 127.0.0.1
```

Binding UDP 13370 proves Qt loaded and `CommunicationLayer` initialised — a missing DLL means
the process never appears at all.

⚠ **This check was wrong twice before 2026-08-18, and a healthy build failed it.**
There is no **13371** any more: the multicast socket is not created in the default `loopback`
mode, so requiring it fails a correct deployment. And `Get-NetUDPEndpoint` is the wrong
instrument — every service binds 13370 with `ShareAddress`, and it collapses a shared
endpoint to one row owned by whichever process bound first, reporting "no UDP endpoints" for
every other service. `netstat -ano` lists one row per pid. The address should read
**`127.0.0.1:13370`**, not `0.0.0.0` — see [network-isolation.md](network-isolation.md).

Add one more line to §7, because it is the single fact that decides whether the rig can talk to
anything: the service's own first log line, `Resonance network mode: loopback|lan ...`.
`R:\config\isolation_check.ps1` prints what each mode actually opens, all three in one run.

<a id="history-73-end-to-end--two-services-find-each-other"></a>

### 7.3 End-to-end — two services find each other

Start `signalGenerator.bat`, then `configurator.bat`, wait ~10 s, then check:

* `quickStimulus` is alive and `MainWindowTitle` is `Configurator` — proves the `qwindows`
  platform plugin, Qt Quick, **and** `quickStimulusPlugin.dll` all loaded (the QML imports
  `Resonance 3.0`; if the plugin is missing there is no window).
* An **established loopback TCP pair** exists between the two pids — proves UDP discovery,
  the EventBus connection and the protocol all work.

Verified 2026-08-11, `R:\dist\mingw32` vs the 2024 reference, identical behaviour:

⚠ **This table is a record of pre-`NetworkMode` binaries and is not a current checklist.**
The `discovery UDP 13370/13371` row in particular cannot be reproduced on a 2026-08-18 or later
build: there is no 13371 socket in the default `loopback` mode, and 13370 is on `127.0.0.1`.
Everything else in the table still holds.

| | x86 ref | **x86 new** | x64 ref (msvc) | **x64 new (mingw64)** |
|---|---|---|---|---|
| SignalGenerator | running | running | running | running |
| quickStimulus window | `Configurator` | `Configurator` | `Configurator` | `Configurator` |
| discovery UDP 13370/13371 | bound | bound | bound | bound |
| configurator ⇄ generator TCP | established | established | established | established |

x64 additionally: `libpythonEngine.dll` `LoadLibrary`s successfully with Python 3.12 on `PATH`
and exports all ten symbols `SPEED` resolves (`engineName`, `engineInitDefault`,
`engineCodeDefault`, `initializeEngine`, `prepareEngine`, `blockReceived`, `startEngine`,
`stopEngine`, `freeEngine`, `onTimer`).

**Unresolved imports are identical to the reference** on both branches — external runtime
dependencies, not packaging gaps:

| Missing DLL | Needed by | Comes from |
|---|---|---|
| `MSVCR90.dll` | `eyelink_w32_comp64.dll` | VC++ 2008 runtime used by the unchanged vendor DLL. The Qt 6 EyeLink `CMakeLists.txt` installs it app-locally to `R:\dist\bin`, beside `eyeLink.exe`; no global VC++ 2008 installation is required for this distribution. |
| `nicaiu.dll` | `DAQmx.exe` | NI-DAQmx driver package |
| `python312.dll` | `pythonEngine.dll` | Python 3.12 on `PATH` / `PYTHONHOME` |

<a id="history--two-traps-that-make-a-working-deploy-look-broken"></a>

### ⚠️ Two traps that make a *working* deploy look broken

Both of these produced false failures during the first attempt, and both fail on the
**known-good 2024 reference** too — always run the reference as a control before believing a
negative result.

1. **`NoDefaultCurrentDirectoryInExePath=1`** is set in the Git Bash environment. With it,
   `cmd /c signalGenerator.bat` reports *"is not recognized as an internal or external
   command"* even though the file is right there, because cmd refuses to search `.`.
   Clear it, or use an absolute path.
2. **Git Bash's `PATH` shadows `env.bat`.** The launchers say `call env`, which under a
   Git-Bash-inherited `PATH` resolves to `/usr/bin/env.exe` — so the environment is never set
   up and you get a dump of the environment instead. Test from a **clean, cmd-like environment**
   (`$env:PATH = "$env:SystemRoot\system32;$env:SystemRoot;…"`), which is what a double-click
   gives the user.
   ✅ Fixed in the Qt 6 launchers: `R:\dist\signalGenerator.bat` says
   `call "%~dp0env.bat"` and then `cd /d "%RESONANCE_DIR%\bin"`, so neither trap can fire.
   `R:\dist_Qt5\msvc64\signalGenerator.bat` still says bare `call env` and `cd bin`, so both still
   apply there.

Note also that `$p.Modules` from 64-bit PowerShell cannot enumerate a 32-bit process properly —
it reports ~7 modules and no `Qt5Core`. That is an artifact, not a missing DLL. It applies to
`R:\dist\kardi2_x32\bin\KARDi2.exe` exactly as it did to the whole `mingw32` tree.

<a id="history-74-the-mechanised-form-for-rdist"></a>

### 7.4 The mechanised form, for `R:\dist`

Each step above has a script (§0.5). They do not replace §7 — none of them walks the import graph,
and none of them checks the network mode — but a package that fails one of them is not worth
launching by hand.

| §7 step | Script |
|---|---|
| 7.1 static | `validate-dist-qt6.ps1` — a 65-entry explicit file list, not an import walk. `validate-kardi2-x32.ps1` adds the PE-machine assertions for the island. |
| 7.2 dynamic | `validate-dist-qt6.ps1` starts `nvx.exe` and `quickStimulus.exe` under a `PATH` that contains no Qt installation, and fails on any QML or platform-plugin diagnostic in stderr. |
| 7.3 end-to-end | `validate-qt5-interop.ps1` is the strongest version of this check: it pairs a **Qt 5** `nvx.exe` from `R:\dist_Qt5\msvc64` with the **Qt 6** Configurator and requires ≥ 2 `Discovered StreamInfo` lines. `validate-quickstimulus-builtins.ps1` covers the three built-in windows. |

⚠ Nothing in either distribution currently checks the `Resonance network mode:` first log line
automatically. `R:\config\isolation_check.ps1` remains the instrument, and it is still the single
fact that decides whether the rig can talk to anything.
