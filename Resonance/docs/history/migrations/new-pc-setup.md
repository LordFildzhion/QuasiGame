# Setting up a new PC to build Resonance — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../how-to/setup.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-setting-up-a-new-pc-to-build-resonance"></a>


**2026-09-05 additions:** DAQmx and FieldTrip are now native x64 Qt 6 targets. Building DAQmx
requires installed NI-DAQmx ANSI C development support (`include/NIDAQmx.h` and
`lib64/msvc/NIDAQmx.lib` under `Shared/ExternalCompilerSupport/C`; override `NIDAQMX_SDK_ROOT`
if needed). Running it requires the external x64 NI-DAQmx runtime and appropriate device support;
the self-contained Qt distribution does not contain the NI driver. MAX/configuration support
provides device configuration/simulation. Install Visual Studio before adding NI C support.
The installed API is 26.5.0; details are in [service_daqmx.md](../components/daqmx.md).
FieldTrip's official Qt-free server/demo tools require **MinGW-w64 GCC 13.1 x64**, selected from
`C:\Qt515\Tools\mingw1310_64\bin` (or CMake `FIELDTRIP_GCC`), with static winpthreads.
The FieldTrip service itself uses MSVC v143 and Qt 6. No Qt 5 kit is required by either port.
No active service remains unported: stimulusService followed on 2026-09-06 as the native Qt 6
Stimulus service. The latest full result is **34/34 enabled CTests passing**, with four
hardware/external tests disabled; see `R:\src\docs\VALIDATION.md`.
These additions supersede the older DAQmx, GCC 13.1 and test-count statements below.

**Written 2026-08-18**, from a measurement of the working build box (`ANATOLYHOME2024`,
Windows 11 Pro for Workstations 10.0.26200) rather than from memory. **Rewritten 2026-09-02**, the
day Qt 6 became the default; every version, path and assertion below was re-read off that machine
on that date.

> **The default toolchain is Qt 6.11.2 / MSVC v143 14.44 / C++20.** Sources `R:\src`, distribution
> `R:\dist`, build and deploy scripts `R:\src\scripts\`. **Qt 5.15.2 is still required** for the
> comparator and the legacy QML programs; since 2026-09-06 no service needs it. KARDi2 no longer requires a Qt 5
> island: its x64 Qt 6 service uses a small native x86 broker (§1.2). `R:\src_Qt5` also holds the
> git history (Appendix).
> Background: [qt5-to-qt6-transition.md](qt5-to-qt6-transition.md),
> [qt5-still-needed.md](qt5-still-needed.md).

This is the *install* document. [dev-environment-setup.md](dev-environment.md) is the older
and more discursive one — what is on this particular box and why — and still has useful background;
where the two disagree, this one was measured more recently. Build commands for the Qt 6 tree are
in §1.7 here and in `R:\src\docs\README.md`; the Qt 5 comparator's are in
[build-and-distro.md §5](and-distro.md#history-5-build-commands).

---


<a id="history--read-this-before-you-install-anything"></a>

## ⚠ Read this before you install anything

**The two source trees have opposite transfer problems, and only one of them can be cloned.**

| | `R:\src` — Qt 6, the default | `R:\src_Qt5` — the comparator |
|---|---|---|
| Git repository | ⚠ **none at all.** `R:\src\.git` does not exist | `R:\src_Qt5\.git` |
| Branch / HEAD | — | `feature/services-and-isolation`, `fae69c3`, `git describe` → `3.4.1-137-gfae69c3` |
| Pushed? | — | yes — local HEAD and `origin/feature/services-and-isolation` are the **same commit**, 0 ahead / 0 behind |
| Submodules | none — the copied Git indirection was removed deliberately, so `3dparty\thir` and `3dparty\qml-colors` are ordinary directories | five, all populated and pinned |
| Uncommitted work | everything | **14 changes**: 12 files under `neuroMS\` and `nvx136\`, the `scriptEngines/python` submodule, and the untracked `nvx136\tracer\` |

So the transfer procedure differs by tree:

* **`R:\src` must be copied as files.** A zip of the directory is the only supported transfer.
  There is no repository to clone and no remote that has ever seen this tree.
* **`R:\src_Qt5` can be cloned**, and this is a change from the 2026-08-18 measurement that used to
  stand here: on the old `feature/cmake-dual-build` branch the framework and nearly every module
  were *untracked*, so a clone got you a tree missing most of the product. On the current branch
  they are tracked — `git ls-files` counts 133 files under `Core`, 210 under `quickStimulus` and 44
  under `neuronSpectrum/sdk` — and the branch is pushed.

  ```bash
  git clone --recursive -b feature/services-and-isolation https://gitea.atedgeof.net/bcilab/Resonance
  ```

  ⚠ **A clone is still not a copy.** It reproduces `fae69c3` and nothing else; the 14 uncommitted
  changes are the live NVX-136 cold-start and Neuro-MS rig work and exist only in the working tree.
  Copying the directory remains the safer transfer.

⚠ **Delete the in-tree build directories after copying `R:\src`.** The Qt 6 tree builds *inside
itself* (§3), so a file copy also carries `_build`, `_build-kardi2-x32`, `_dist`, `_stage`,
`_test-output` and `_patches`. Every CMake cache in them is bound to the source path it was
configured at, and CMake refuses to reconfigure a cache whose source directory moved:

```bash
rm -rf R:/src/_build R:/src/_build-kardi2-x32
```

Two further consequences worth stating plainly:

* ⚠ **Everything here exists in one place.** `R:\src` has no version control standing behind it at
  all. `workpc-changes.md` (on the lab drive, `R:\docs\_notes\`) opens by describing what this has
  already cost once — a 2025 fix that shipped only as a compiled DLL and was silently reverted by
  every later build.
* ⚠ **The Python engine's edit is a working-tree edit.** `scriptEngines/python/pythonengine.cpp`
  carries local work — per-channel `channel_properties` metadata on declared streams — that lives
  in the *submodule* working tree in `R:\src_Qt5` and is therefore not covered by any commit. A
  routine `git submodule update` discards it. Verify it survived the copy in **both** trees:

  ```bash
  grep -c channel_properties R:/src/scriptEngines/python/pythonengine.cpp
  grep -c channel_properties R:/src_Qt5/scriptEngines/python/pythonengine.cpp
  ```

  Both must report 4. ⚠ The older guard documented here and in
  [known-issues §2e](../incidents/README.md) — `grep -n stdoutHook` — is **dead**: neither tree
  contains that identifier any more. The `stdout`-as-a-variable hazard was resolved differently, by
  constructing the class as an unnamed temporary (`py::class_<StdIOHook>(m, "stdout")` at
  `pythonengine.cpp:197`), so the old grep now reports failure on a healthy tree.

---


<a id="history-1-what-to-install-in-order"></a>

## 1. What to install, in order

Install in this order — later items depend on earlier ones being on disk. `build-qt6.ps1` and
`build-kardi2-x32.ps1` each open with a `foreach ($required in ...)` block that `throw`s on the
first missing prerequisite; that assertion list is the authority for this section, and everything
below was taken from it.

<a id="history-11-qt-6112--one-kit"></a>

### 1.1 Qt 6.11.2 — one kit

| | |
|---|---|
| Why | The whole framework. Every service is a Qt app. |
| Version | **6.11.2**, kit `msvc2022_64` |
| Here | `C:\Qt515\6.11.2\msvc2022_64` |
| Modules | Core, Gui, Widgets, Network, Qml, Quick, **QuickControls2**, **Multimedia**, **SerialPort**, **Scxml**, **StateMachine**, Test |
| Get it | Qt Online Installer — <https://www.qt.io/download-qt-installer> |

⚠ **Multimedia, Serial Port and SCXML are Additional Libraries** — not in a default selection, and
several modules will not configure without them. `Qt6::Scxml` and `Qt6::StateMachine` both come out
of the `qtscxml` repository (`modules\StateMachine.json` records `"repository": "qtscxml"`), so one
tick supplies both. QuickControls2 is part of `qtdeclarative` and arrives with the base kit.

⚠ **`WinExtras` does not exist in Qt 6 at all.** Nothing in the Qt 6 tree links it. The Qt 5 kit
still needs it — for the KARDi2 island, §1.2.

Install to **`C:\Qt515`**, not the installer's default. Yes, a Qt 6 kit under a directory named
`Qt515`: the root is unchanged from the Qt 5 era and every script and document hardcodes it.
`build-qt6.ps1:12` asserts the literal `C:\Qt515\6.11.2\msvc2022_64` and throws if it is absent.

The kit's own build metadata records **MSVC 19.44.35227.0** and **Windows SDK 10.0.26100** for
every module. That is where §1.4's toolset pin comes from — it matches the compiler the prebuilt
kit was made with, and it is not a matter of taste.

<a id="history-12-qt-5152-mingw81_32--mingw-81-32-bit--the-kardi2-island-not-optional"></a>

### 1.2 Qt 5.15.2 `mingw81_32` + MinGW 8.1 32-bit — the KARDi2 island, not optional

| | |
|---|---|
| Why | The vendor `KARDi2.dll` is PE32/i386 only. No x64 Qt 6 process can load it, so the service is rebuilt as a 32-bit Qt 5.15/MinGW island and shipped *inside* the Qt 6 distribution as `R:\dist\kardi2_x32\`. |
| Version | **5.15.2 exactly**, kit `mingw81_32` |
| Here | `C:\Qt515\5.15.2\mingw81_32` |
| Modules | Core, Gui, Widgets, Network, Test, **WinExtras** |
| Standard | C++17 — the island's own root sets `CMAKE_CXX_STANDARD 17` |

⚠ **This is part of the default build, not an extra.** `deploy-qt6.ps1` calls
`build-kardi2-x32.ps1` unless given `-SkipBuild`, and its prerequisite list then asserts that
`_build-kardi2-x32\runtime\bin\` holds `KARDi2.exe`, `KARDi2.dll`, `libResonance.dll` and
`Qt5Core.dll` before it will install anything — so `-SkipBuild` does not get you past a missing
island either. Skipping it does not give you a smaller Qt 6 distribution; it gives you a failed
deploy.

Detail on why the island exists and what it costs to maintain:
[qt5-still-needed.md §1](qt5-still-needed.md) and
[qt5-to-qt6-transition.md §6](qt5-to-qt6-transition.md).

<a id="history-13-mingw-81-cmake-and-ninja--from-the-same-installer"></a>

### 1.3 MinGW 8.1, CMake and Ninja — from the same installer

Under the Qt installer's *Tools* node:

| Component | Here | Notes |
|---|---|---|
| MinGW 8.1.0 32-bit | `C:\Qt515\Tools\mingw810_32` | the x86 island of §1.2. `build-kardi2-x32.ps1` asserts `bin\g++.exe` here |
| CMake | `C:\Qt515\Tools\CMake_64\bin` — **3.30.5** | ≥ 3.21 required; both build scripts invoke it by absolute path |
| Ninja | `C:\Qt515\Tools\Ninja` — **1.12.1** | the generator used throughout, likewise by absolute path |

Because the scripts use absolute paths, installing CMake or Ninja anywhere else does not work —
the assertion fires even if a newer one is on `PATH`.

⚠ MinGW 8.1.0 **64-bit** (`mingw810_64`) has **no role in the Qt 6 default**. It is needed only to
rebuild the Qt 5 MinGW comparator distributions (Appendix). `C:\Qt515\Tools\mingw1310_64` arrives
with Qt 6's own MinGW kit and nothing in this project uses it.

<a id="history-14-visual-studio-build-tools--with-the-v143-1444-toolset"></a>

### 1.4 Visual Studio Build Tools — **with the v143 14.44 toolset**

| | |
|---|---|
| Why | Every x64 binary in `R:\dist`, which is what the rigs will run. |
| Here | `C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools` |
| Toolsets present | `14.29.30133` (v142 — comparator only, Appendix), **`14.44.35207` (v143 — this is the one to use)**, `14.51.36231` (VS 2026's default, unused by this project) |
| Windows SDK | `10.0.26100` |
| Get it | <https://visualstudio.microsoft.com/downloads/> → *Tools for Visual Studio* → *Build Tools for Visual Studio* |

⚠ **The toolset is pinned, not defaulted.** `build-qt6.ps1:28` shells out to `cmd.exe` to
import the environment, in effect

```bat
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64 -vcvars_ver=14.44
```

and throws `vcvarsall failed to initialize MSVC 14.44.` if that toolset is not installed. The
reason is compatibility with the prebuilt kit (§1.1), not a defect in the newer compiler.

Components to tick in the Build Tools installer:

* **MSVC v143 — VS 2022 C++ x64/x86 build tools**, and specifically the **14.44** version, not only
  the latest. VS 2026 ships 14.51 by default and that is *not* what the scripts select.
* **C++/CLI support for v143 build tools** — supplies `mscoree.lib` and the .NET Framework 4.8
  targeting pack. Only `neuronSpectrum` and `neuroMS` need it, for their `/clr` bridges
  (`ns65bridge.cpp`, `nmsbridge.cpp`), and **without it they fail at *link* time only**, which is a
  confusing way to discover it is missing. On this box all three installed toolsets carry
  `msvcmrt.lib`, so the component was ticked more than once; a fresh machine needs it for whichever
  toolset it actually builds with.
* **Windows 11 SDK 10.0.26100** — the version the Qt kit was built against.

⚠ The warning that used to stand here — *"the default toolset cannot compile Qt 5.15.2 at all"*,
because MSVC 14.5x's STL removed `stdext::checked_array_iterator`
([known-issues §11a](../incidents/README.md)) — is a **Qt 5** fact. It is still true, and it applies
only to the comparator tree. It says nothing about Qt 6.11.2, which builds under v143 without it.

<a id="history-15-python-312"></a>

### 1.5 Python 3.12

| | |
|---|---|
| Why | `pythonEngine`/`SPEED` link against it, and every analysis harness in `R:\config` runs on it. |
| Version here | **3.12.10** |
| Here | `C:\Users\<user>\AppData\Local\Programs\Python\Python312` |
| Get it | <https://www.python.org/downloads/> |

⚠ **3.12 specifically**, and the build enforces it: `scriptEngines/python/CMakeLists.txt` calls
`find_package(Python 3.12 EXACT COMPONENTS Interpreter Development NumPy REQUIRED)`. The reference
box also has 3.14 and it is the `py` launcher's default; `build-qt6.ps1` sidesteps that by passing
`-DPython_ROOT_DIR` and `-DPython_EXECUTABLE` explicitly at the 3.12 install.

⚠ **`pybind11` comes from pip, not from Conan, in the Qt 6 tree.** `R:\src\conanfile.txt` requires
only `hdf5`, `boost`, `iir1` and `gtest`; `build-qt6.ps1` asserts that
`Python312\Lib\site-packages\pybind11\share\cmake\pybind11` exists and puts it on
`CMAKE_PREFIX_PATH`. Installed here: **pybind11 3.1.0**, **numpy 2.5.2**. That pairing also retires
the old NumPy-2 trap — it was the Conan-pinned `pybind11/2.11.1` in the Qt 5 tree that predated
NumPy 2 support ([dev-environment §B4](dev-environment.md)).

Packages needed **for the build**:

```bash
py -3.12 -m pip install pybind11 numpy
```

Packages needed for the analysis harnesses, not for the build:

```bash
py -3.12 -m pip install h5py pyserial
```

⚠ **Nothing to install for SPEED's runtime.** `SPEED` ships a private Python 3.12 interpreter,
vendored in the source tree at `R:\src\runtime-content\python\` (with NumPy 1.26.2, SciPy, h5py
3.10.0, mat73) and staged into `R:\dist\python\` plus `bin\python312.dll`. It is deliberately
independent of the machine-wide interpreter — `pythonEngine`'s CMake copies the vendored DLL beside
the host executables and fails configure if it is missing.

<a id="history-16-conan-2-and-its-one-profile"></a>

### 1.6 Conan 2 and its one profile

| | |
|---|---|
| Version here | **2.31.2** |
| Here | `%LOCALAPPDATA%\Programs\Python\Python312\Scripts\conan.exe` |
| Get it | `py -3.12 -m pip install conan`, or <https://conan.io/downloads> |

`build-qt6.ps1` resolves `conan.exe` from `PATH` and falls back to that exact path, so putting the
`Scripts` directory on `PATH` is optional.

⚠ **The Qt 6 profile is not in `%USERPROFILE%\.conan2\profiles\`.** It is versioned with the tree,
at **`R:\src\profiles\msvc-v143-release`**, and passed as both `-pr:h` and `-pr:b`. There is
nothing to create by hand — but if the file is missing the build script throws. For reference:

```ini
[settings]
os=Windows
arch=x86_64
build_type=Release
compiler=msvc
compiler.version=194
compiler.cppstd=20
compiler.runtime=dynamic
compiler.runtime_type=Release

[conf]
tools.cmake.cmaketoolchain:generator=Ninja
tools.microsoft.msbuild:vs_version=18
tools.build:jobs=1
```

`compiler.version=194` is the v143 14.4x family, `cppstd=20` matches the root `CMakeLists.txt`, and
`tools.build:jobs=1` is not a typo — see §3.

The KARDi2 island has its own profile, likewise in-tree, at
`R:\src\KARDi2\qt5-island\profiles\mingw-x86-release` (gcc 8, `arch=x86`, `exception=dwarf2`,
`cppstd=17`, with `mingw810_32` in `compiler_executables` and `[buildenv] PATH`).

Dependencies Conan fetches for the Qt 6 root (`R:\src\conanfile.txt`): **hdf5 1.13.1**,
**boost 1.78.0** (`header_only=True`), **iir1 1.9.0**, **gtest 1.15.0**. The island
(`KARDi2\qt5-island\conanfile.txt`) fetches hdf5, header-only boost and gtest. The first
`conan install` needs network; after that the cache (`%USERPROFILE%\.conan2\p`, **2.8 GB** here)
serves offline builds.

<a id="history-17-the-build-itself"></a>

### 1.7 The build itself

Nothing else to install. From a PowerShell window:

```powershell
R:\src\scripts\build-qt6.ps1                # x64 Qt 6 tree     -> R:\src\_build
R:\src\scripts\build-kardi2-x32.ps1         # x86 island        -> R:\src\_build-kardi2-x32
R:\src\scripts\deploy-qt6.ps1               # both, + windeployqt -> R:\dist
R:\src\scripts\validate-dist-qt6.ps1        # static + launch check of R:\dist
```

`deploy-qt6.ps1` runs both builds itself unless given `-SkipBuild`, and its `-Destination` defaults
to `R:\dist`. `validate-dist-qt6.ps1` asserts 65 required files, launches `nvx.exe` and
`quickStimulus.exe`, greps both processes' logs for error patterns and — when given
`-CapturePath` — screenshots the Configurator window, writing its evidence to `R:\src\docs\qa\`.
It does **not** run the unit tests.

<a id="history-18-net-framework-48"></a>

### 1.8 .NET Framework 4.8

Needed by the two `/clr` bridges (`neuronSpectrum`, `neuroMS`). The **runtime** is inbox on
Windows 11; the **targeting pack** arrives with the C++/CLI component in §1.4. If you need it
separately: <https://dotnet.microsoft.com/download/dotnet-framework/net48>.

<a id="history-19-nothing-to-install-for-intel-ipp"></a>

### 1.9 Nothing to install for Intel IPP

`neuronSpectrum` needs Intel IPP 8.1, and it is **vendored in the source tree**
(`R:\src\neuronSpectrum\sdk\ipp`, 14 DLLs) and staged into `bin\` by the build. No download. It is
not optional — the vendor SDK builds an impedance calculator inside `StartReadData`, so without IPP
the NS-65 cannot acquire at all ([known-issues §15f](../incidents/README.md)).

---


<a id="history-2-on-a-machine-that-only-runs-the-software"></a>

## 2. On a machine that only *runs* the software

**`R:\dist` needs nothing preinstalled.** `deploy-qt6.ps1` copies the exact **v143 14.44**
`Microsoft.VC143.CRT` DLLs app-locally into `R:\dist\qt\bin\` — `msvcp140*.dll`,
`vcruntime140.dll`, `vcruntime140_1.dll`, `concrt140.dll` — and `windeployqt --compiler-runtime`
also drops `vc_redist.x64.exe` there for the case where a machine-wide install is preferred. Qt,
the vendor DLLs, the QML, SPEED's private Python and the KARDi2 x86 island all travel inside the
distribution folder.

This is a change from the Qt 5 distribution, which shipped no runtime and relied on the target rig
having **the Visual C++ Redistributable (x64)** installed
([build-and-distro.md §5c](and-distro.md)). That requirement still applies to
`R:\dist_Qt5\msvc64`.

> **Both regressions that blocked `R:\dist` were closed on 2026-09-02** (the NVX-136 cold-start
> ladder and the Neuro-MS `standby` state). ⚠ No Qt 6 build has yet driven a physical device,
> so the first session with one is a bring-up: keep `R:\dist_Qt5\msvc64` available as the
> fallback.
> See [qt6-work-list.md §1](qt6-work-list.md).

---


<a id="history-3-rules-that-are-not-packages"></a>

## 3. Rules that are not packages

These cost more time than a missing install when they are not known.

| | |
|---|---|
| ⚠ **The Qt 6 tree builds *inside itself*** | `R:\src\_build`, `_build-kardi2-x32`, `_dist`, `_stage`, `_test-output`. The root `CMakeLists.txt` forces `CMAKE_INSTALL_PREFIX` to `${CMAKE_SOURCE_DIR}/_dist`. This **reverses** the old rule, which still governs the comparator: `R:\src_Qt5` builds to `R:\dist_Qt5\_build\<name>` and deploys to `R:\dist_Qt5\<name>`. |
| **A moved tree needs a clean configure** | Every cache under `_build` records its `CMAKE_HOME_DIRECTORY`. Copy or rename the tree and you must `rm -rf R:/src/_build R:/src/_build-kardi2-x32` before the next build; `deploy-qt6.ps1 -SkipBuild` fails on the same cache. |
| **Pass `-c tools.cmake.cmaketoolchain:user_presets=`** to `conan install` | Otherwise Conan writes `CMakeUserPresets.json` into the source directory. Both Qt 6 scripts already pass it; a hand-run `conan install` must too. |
| ⚠ **Cap parallelism at `-j6`** | The reference box throws WHEA hardware errors and random compiler ICEs above that ([known-issues §11b](../incidents/README.md)). Both build scripts end with `-- -j 6`. |
| ⚠ **Conan dependency builds are serial** | `tools.build:jobs=1`, in the profile *and* on the command line. MSVC 19.44 has been observed to ICE when Conan compiles several copies of `gtest-all.cc` concurrently. The project build itself stays at `-j6`. |
| **`chcp 65001` — now handled by the script** | `build-qt6.ps1` sets the console to UTF-8 itself (`chcp.com 65001` plus `[Console]::OutputEncoding`) before configuring or building. This is not cosmetic: this machine's OEM code page is 866, and at the default code page Ninja fails to string-match `cl.exe`'s localised `/showIncludes` prefix, records **zero** header dependencies, and a later header edit then produces a mixed-layout binary that links cleanly and faults at run time ([known-issues §11c](../incidents/README.md)). ⚠ A **hand-run** `cmake`/`ninja` outside the script still needs the `chcp 65001` from you. |
| **A compile is not a deploy** | [build-and-distro.md §7](and-distro.md#history-7-verifying-a-deploy) is the three-step verification, and it lists two traps that make a *working* build look broken. `validate-dist-qt6.ps1` is its mechanised form for `R:\dist`. |
| **`NoDefaultCurrentDirectoryInExePath`** | If set, a `.bat` launcher that says bare `call env` fails with "is not recognized". ✅ **Fixed in `R:\dist`** — its launchers say `call "%~dp0env.bat"`. ⚠ Still live in `R:\dist_Qt5\msvc64`, whose launchers say `call env`. |
| **Git Bash shadows `env.bat`** | Same seam, same fix: Git Bash's `PATH` resolves bare `call env` to `/usr/bin/env.exe`, so the environment is never set up. Affects `R:\dist_Qt5\msvc64` only. |

---


<a id="history-4-verification-checklist"></a>

## 4. Verification checklist

Run these in order on the new machine. Each one fails distinctly if the step above it is wrong.

```bat
:: 1. toolchain is visible
C:\Qt515\6.11.2\msvc2022_64\bin\qmake -query QT_VERSION   :: expect 6.11.2
C:\Qt515\Tools\CMake_64\bin\cmake --version               :: expect >= 3.21 (3.30.5 here)
C:\Qt515\Tools\Ninja\ninja --version                      :: 1.12.1 here
conan --version                                           :: 2.31.2 here
py -3.12 -c "import sys, pybind11, numpy; print(sys.version, pybind11.__version__, numpy.__version__)"

:: 2. the v143 14.44 toolset actually selects
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64 -vcvars_ver=14.44
cl                                        :: must print 19.44.xxxxx, NOT 19.29 and NOT 19.5x

:: 3. the x86 island's inputs are present
dir C:\Qt515\5.15.2\mingw81_32\bin\Qt5Core.dll
dir C:\Qt515\Tools\mingw810_32\bin\g++.exe

:: 4. the source tree arrived intact
dir R:\src\Core R:\src\quickStimulus R:\src\profiles\msvc-v143-release
dir R:\src\KARDi2\qt5-island\CMakeLists.txt
findstr /C:"channel_properties" R:\src\scriptEngines\python\pythonengine.cpp
```

Then the build (§1.7), and:

* **Configure** must report `The CXX compiler identification is MSVC 19.44.xxxxx`. `19.29` means
  the pin picked up the comparator's v142; `19.5x` means it did not pin at all.
* ⚠ **Do not compare the target count against the Qt 5 tree's 430** (a 2026-08-17 measurement,
  §A.4). The Qt 6 root builds 19
  subdirectories against a different module set, and no clean-configure figure has been re-measured
  since the rename. Treat whatever the first clean build reports as the new baseline, and record it
  here.
* **Unit tests** — CTest, from the build root. The last recorded full run passed **all 22 enabled
  tests**, with four physical/external tests disabled by design — but that figure is a sentence in
  `R:\src\docs\VALIDATION.md` (2026-08-29 actiChamp entry) and **no ctest log backs it**. The
  newest artefact, `qa\ctest-three-services-final.log`, records 20/20 enabled out of 24 registered;
  `qa\ctest-qt6-final.log` and `qa\ctest-speed-final.log` record 17/17. Treat 22 as a claim rather
  than as evidence ([qt6-work-list.md §4](qt6-work-list.md)).
  ⚠ Application-linked test targets need `R:\src\_build\runtime\bin` **and** the Qt 6 kit's `bin`
  on `PATH`, or they exit `0xC0000135` before printing anything.
  ⚠ `Core\Resonance`'s gtest suites are **built but never registered**:
  `Core/Resonance/tests/CMakeLists.txt:96` has `gtest_discover_tests(test_StreamInfo)` commented
  out, so a green CTest run does not mean those ran. Launch them by hand.
  ⚠ `test_RecorderPath` returns **2** unless `RESONANCE_RECORD_PATH` is set; that is an unmet
  precondition, not a failure.
* **Imports** — the §7.1 walk. ⚠ The old "exactly three unresolved" expectation (`MSVCR90.dll`,
  `nicaiu.dll`, `python312.dll`) does **not** transfer: EyeLink is now in the Qt 6 tree and ships
  its `MSVCR90.dll` app-locally, DAQmx is ported (its `nicaiu.dll` is the external NI runtime), and `python312.dll` ships in
  `R:\dist\bin\`. Re-measure rather than reuse the number.
* **Launch it.** `R:\dist\signalGenerator.bat` then `R:\dist\configurator.bat`; the window title
  must read `Configurator` and the two must establish a loopback TCP pair. Or run
  `validate-dist-qt6.ps1`, which does exactly this (and screenshots the window if you pass
  `-CapturePath`).

---


<a id="history-5-disk-and-time"></a>

## 5. Disk and time

Measured 2026-09-02.

| | |
|---|---|
| `C:\Qt515\6.11.2` | **5.7 GB** |
| `C:\Qt515\5.15.2` — all three kits | **1.8 GB** |
| `C:\Qt515\Tools` — three MinGW, CMake, Ninja, Qt Creator | **2.3 GB** |
| Conan cache (`%USERPROFILE%\.conan2\p`) | **2.8 GB** |
| One build directory | 3–6 GB |
| `R:\dist` as deployed | **496 MB**, 3 661 files |
| **Budget** | **~40 GB** |

⚠ No from-scratch Qt 6 build has been timed. The 2026-08-18 figure that stood here — roughly half
an hour at `-j6` on an i9-14900KF — was measured on the Qt 5 `msvc64` tree, and belongs to the
Appendix rather than to this section.

---


<a id="history-appendix--building-the-qt-5-comparator-tree"></a>

## Appendix — building the Qt 5 comparator tree

Needed only to rebuild `R:\src_Qt5` → `R:\dist_Qt5`. Nothing here is required to build or run
`R:\dist`, with the single exception of the 32-bit MinGW kit, which §1.2 already claims for the
KARDi2 island. Why the comparator cannot be retired:
[qt5-still-needed.md](qt5-still-needed.md).

<a id="history-a1-qt-5152--three-kits"></a>

### A.1 Qt 5.15.2 — three kits

| | |
|---|---|
| Version | **5.15.2 exactly.** The last Qt 5 with official prebuilt binaries, and the version the shipped 2024 rigs were built against. |
| Kits | `msvc2019_64`, `mingw81_64`, `mingw81_32` |
| Here | `C:\Qt515\5.15.2\{msvc2019_64,mingw81_64,mingw81_32}` |
| Modules | Core, Gui, Widgets, Network, Qml, Quick, **Scxml**, **SerialPort**, **WinExtras**, Test |
| Get it | Qt Online Installer. Tick *Archive* in the category filter, then *Qt 5.15.2* and the three kits. The archive host is <https://download.qt.io/archive/qt/5.15/5.15.2/>. |

⚠ **Scxml, SerialPort and WinExtras are easy to miss** — they are not in a default selection and
several modules will not configure without them.

Also install **MinGW 8.1.0 64-bit** (`C:\Qt515\Tools\mingw810_64`) from the *Tools* node, for the
`mingw64` distribution. The 32-bit compiler, CMake and Ninja are shared with §1.3.

<a id="history-a2-the-v142-toolset"></a>

### A.2 The v142 toolset

| | |
|---|---|
| Why | The `msvc64` comparator build. |
| Toolset | `14.29.30133` (v142), inside the same VS 2026 Build Tools install |

⚠ **VS 2026's default toolset cannot compile Qt 5.15.2 at all.** MSVC 14.5x's STL removed
`stdext::checked_array_iterator`, which Qt 5.15.2 uses unconditionally
([known-issues §11a](../incidents/README.md)). Select it explicitly:

```bat
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64 -vcvars_ver=14.29
```

Components: **MSVC v142 — VS 2019 C++ x64/x86 build tools** and **C++/CLI support for v142 build
tools**.

<a id="history-a3-the-three-conan-profiles"></a>

### A.3 The three Conan profiles

Unlike the Qt 6 profile, these live in `%USERPROFILE%\.conan2\profiles\` and must be created by
hand. **Their contents are load-bearing** — copy them exactly.

`msvc64`:

```ini
[settings]
os=Windows
arch=x86_64
build_type=Release
compiler=msvc
compiler.version=192
compiler.cppstd=17
compiler.runtime=dynamic
compiler.runtime_type=Release

[conf]
tools.cmake.cmaketoolchain:generator=Ninja
tools.microsoft.msbuild:vs_version=18
```

⚠ `compiler.version=192` (the v142 toolset) **and** `tools.microsoft.msbuild:vs_version=18` (the
VS 2026 installation that hosts it) look contradictory and are both required — that pair is how
Conan is told to use the older toolset inside the newer install
([known-issues §11a](../incidents/README.md)).

`mingw64`:

```ini
[settings]
os=Windows
arch=x86_64
build_type=Release
compiler=gcc
compiler.version=8
compiler.cppstd=17
compiler.libcxx=libstdc++11
compiler.threads=posix
compiler.exception=seh

[conf]
tools.cmake.cmaketoolchain:generator=Ninja
tools.build:compiler_executables={"c":"C:/Qt515/Tools/mingw810_64/bin/gcc.exe","cpp":"C:/Qt515/Tools/mingw810_64/bin/g++.exe"}

[buildenv]
PATH=+(path)C:/Qt515/Tools/mingw810_64/bin
```

`mingw32` — the same with `arch=x86`, `exception=dwarf2`, and `mingw810_32` in both paths.

The dependencies Conan fetches for the comparator (`R:\src_Qt5\conanfile.txt`): **boost 1.78.0**,
**hdf5 1.13.1**, **gtest 1.15.0**, **iir1 1.9.0**, **pybind11 2.11.1**. ⚠ Note the
`pybind11/2.11.1` pin — it predates NumPy 2 support, and that trap is a Qt 5-tree problem only
([dev-environment §B4](dev-environment.md)).

<a id="history-a4-the-rules-that-still-apply-there"></a>

### A.4 The rules that still apply there

* **Never build inside `R:\src_Qt5`.** Intermediates go to `R:\dist_Qt5\_build\<name>`,
  distributions to `R:\dist_Qt5\<name>`. The Qt 6 tree is the exception to this rule, not this one
  (§3).
* **Never put both MinGW `bin` directories on `PATH` at the same time.** That is the single most
  common cause of confusing "undefined reference" and "wrong architecture" errors on a dual-arch
  Windows build.
* A run-only rig for `R:\dist_Qt5\msvc64` still needs the **Visual C++ Redistributable (x64)**
  installed; that distribution ships no runtime of its own (§2).
* A full from-scratch `msvc64` build at `-j6` on an i9-14900KF takes roughly half an hour, most of
  it Qt-heavy translation units (2026-08-18 measurement).
* The dated Qt 5 build figures, kept here because §4 is now a Qt 6 section: a clean configure
  reached **430/430 targets** for the full tree (2026-08-17 measurement) — `test_NetworkMode` was
  added on 2026-08-18, so the figure is one higher and was never re-measured from a clean
  configure — and the unit tests were **11 gtest suites, 324 cases**, all passing as of 2026-08-18.
  Neither number transfers to the Qt 6 tree.
* Build commands: [build-and-distro.md §5](and-distro.md#history-5-build-commands).
