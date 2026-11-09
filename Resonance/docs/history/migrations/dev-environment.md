# Development environment setup for this PC — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../how-to/setup.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-development-environment-setup-for-this-pc"></a>


**2026-09-05 update:** DAQmx and FieldTrip are ported. DAQmx uses the installed NI ANSI C SDK
and x64 system runtime (API 26.5.0); the NI runtime is an external dependency and is not bundled.
FieldTrip's service uses MSVC/Qt 6, while its official Qt-free x64 tools use MinGW-w64 GCC 13.1
with static winpthreads. See [service_daqmx.md](../components/daqmx.md),
[service_fieldtrip.md](../components/fieldtrip.md), and the additions in
[build_new-pc-setup.md](new-pc-setup.md) for current install requirements.

Machine surveyed 2026-08-11: `ANATOLYHOME2024`, Windows 11 Pro for Workstations 26200.
C: 212 GB free, R: 80 GB free. **Re-surveyed 2026-09-02**, the day Qt 6 became the default; the
Qt 6 rows, the two new §D0/§E0/§F0 sections and every path repointed at `R:\src_Qt5` /
`R:\dist_Qt5` were checked on that date.

> **The default toolchain on this box is now Qt 6.11.2 / MSVC v143 14.44 / C++20**, building
> `R:\src` into `R:\dist`. Qt 5.15.2 and the v142 toolset are still installed and still needed —
> for the `R:\src_Qt5` comparator, and for the 32-bit KARDi2 island that the *Qt 6* deployment
> itself contains. Which is which:
> [qt5-to-qt6-transition.md](qt5-to-qt6-transition.md),
> [qt5-still-needed.md](qt5-still-needed.md). The ordered install list for a *fresh* machine
> is [new-pc-setup.md](new-pc-setup.md); this file is the discursive companion — what is on
> this particular box, and why.

---


<a id="history-a-what-is-already-installed-verified-nothing-to-do"></a>

## A. What is already installed (verified, nothing to do)

| Component | Version | Location |
|---|---|---|
| **Qt (default)** | **6.11.2** | `C:\Qt515\6.11.2\msvc2022_64` — the kit `R:\src` builds against. `mingw_64` is also present and unused |
| Qt (comparator + x86 island) | **5.15.2** | `C:\Qt515\5.15.2\mingw81_32`, `C:\Qt515\5.15.2\mingw81_64`, `C:\Qt515\5.15.2\msvc2019_64` |
| MinGW-w64 GCC | **8.1.0** `i686-posix-dwarf` | `C:\Qt515\Tools\mingw810_32` — **still in the default build**, for the KARDi2 x86 island |
| MinGW-w64 GCC | **8.1.0** `x86_64-posix-seh` | `C:\Qt515\Tools\mingw810_64` — comparator only |
| MinGW-w64 GCC | **13.1.0** | `C:\Qt515\Tools\mingw1310_64` — arrived with Qt 6's MinGW kit, unused |
| CMake | **3.30.5** | `C:\Qt515\Tools\CMake_64\bin` |
| Ninja | **1.12.1** | `C:\Qt515\Tools\Ninja` |
| Qt Creator + QBS | qbs **3.3.1** | `C:\Qt515\Tools\QtCreator\bin` |
| Git | present | `C:\Program Files\Git\cmd` |
| Python | 3.14.5 (default) | `%LOCALAPPDATA%\Programs\Python\Python314` |
| VC++ redistributables | 14.50 x86/x64 | `C:\Qt515\vcredist\` |

The Qt 5 kits contain every module *that tree* needs — Core, Network, Widgets, Gui, Qml,
Quick, **Scxml**, **SerialPort**, **WinExtras**, Test. The Qt 6.11.2 kit is a full install and
covers everything `R:\src` links: Core, Gui, Widgets, Network, Qml, Quick, **QuickControls2**,
**Multimedia**, **SerialPort**, **Scxml**, **StateMachine**, Test. ⚠ There is no `WinExtras` in
Qt 6 and nothing in `R:\src` asks for one; the Qt 5 kit still needs it for the x86 island.

⚠ **QBS is dead weight in both trees.** 51 `.qbs` files survive in `R:\src_Qt5` and 29 rode along
into `R:\src` inside the ported modules, but neither tree has a QBS build any more — the Qt 6 root
is CMake-only. Qt Creator's qbs 3.3.1 is installed and unused.

Installed on **2026-08-11** as part of this setup:

| Component | Version | Location |
|---|---|---|
| Python | **3.12.10** | `%LOCALAPPDATA%\Programs\Python\Python312` (via `winget`, user scope) |
| Conan | **2.31.2** | `%LOCALAPPDATA%\Programs\Python\Python312\Scripts\conan.exe` |
| pybind11 (pip) | 3.1.0 | Python 3.12 site-packages |
| numpy (pip) | 2.5.2 | Python 3.12 site-packages |

Installed later, as the x64/MSVC and Neuron-Spectrum work needed them:

| Component | Version | When | Why |
|---|---|---|---|
| VS 2026 Build Tools | toolsets **14.29 (v142)** + 14.51 | 2026-08-11 | the `msvc64` distribution. Select v142 **when building the Qt 5 tree** — [known-issues §11a](../incidents/17-visual-studio-2026-cannot-compile-qt-5152--needs-the-v142-toolset.md#history-11a-visual-studio-2026-cannot-compile-qt-5152--needs-the-v142-toolset) |
| Qt 5.15.2 `msvc2019_64` | 5.15.2 | 2026-08-11 | the MSVC kit `R:\src_Qt5` → `R:\dist_Qt5\msvc64` is built against |
| **.NET Framework 4.8 SDK** + **C++/CLI support for v142** | NETFXSDK 4.8 | 2026-08-15 | `neuronSpectrum` — see [§B5](dev-environment.md#history-b5-net-framework-48-sdk--ccli--for-neuronspectrum-and-neuroms) |
| 7-Zip | present | — | unpacking the Intel IPP runtime the Neurosoft SDK needs |

Installed for the Qt 6 port — both directory timestamps read **2026-08-27**, the day the isolated
snapshot was taken:

| Component | Version | When | Why |
|---|---|---|---|
| **Qt 6.11.2 `msvc2022_64`** | 6.11.2 | 2026-08-27 | the kit `R:\src` → `R:\dist` is built against |
| **MSVC v143 toolset** | **14.44.35207** / VC++ 19.44 | 2026-08-27 | the compiler `build-qt6.ps1` pins with `-vcvars_ver=14.44`. The prebuilt Qt kit's own module metadata records `MSVC 19.44.35227.0` and Windows SDK `10.0.26100`, so the pin matches the kit rather than being a preference |
| Windows SDK | 10.0.26100 | — | the only SDK installed; it is what both toolsets use |

Three MSVC toolsets are therefore present side by side — `14.29.30133` (v142, comparator),
`14.44.35207` (v143, **default**) and `14.51.36231` (VS 2026's own default, used by neither tree).
All three carry `msvcmrt.lib`, so C++/CLI support was ticked for each.

**Still not installed:** conda, R, NI-DAQmx — see [section C](dev-environment.md#history-c-conditional-installs)
for whether you need each.

---


<a id="history-b-required---done"></a>

## B. Required — ✅ done

<a id="history-b1-python-312-64-bit---installed"></a>

### B1. Python 3.12 (64-bit) — ✅ installed

Two reasons it had to be 3.12 and not 3.14: Conan support, and the shipped
`pythonEngine.dll` links **`python312.dll`** — matching that keeps the script engine
binary-compatible with existing deployments.

```bat
winget install --id Python.Python.3.12 --exact --source winget --scope user
```

3.14 remains the default `python`; select 3.12 explicitly with `py -3.12`. Verified present:
`include\Python.h`, `libs\python312.lib`, `python312.dll` — everything `pythonEngine` needs.
The version here is **3.12.10**, and `build-qt6.ps1` reaches it by absolute path
(`-DPython_ROOT_DIR` / `-DPython_EXECUTABLE`) rather than through the `py` launcher, so the 3.14
default cannot leak in. The Qt 6 tree also *pins* it: `scriptEngines/python/CMakeLists.txt` calls
`find_package(Python 3.12 EXACT COMPONENTS Interpreter Development NumPy REQUIRED)`.

⚠ **This interpreter is a build-time dependency only.** `R:\dist` no longer borrows the machine's
Python at run time: `SPEED` ships a private 3.12 runtime vendored at
`R:\src\runtime-content\python\` (NumPy 1.26.2, SciPy, h5py 3.10.0, mat73), staged into
`R:\dist\python\` with a second copy of `python312.dll` in `R:\dist\bin\` where the embedded
interpreter's host executable looks for it.

> **Note — leftover packages from a previous Python 3.12.** `%APPDATA%\Python\Python312\site-packages`
> already contained matplotlib 3.10.9, scipy 1.17.1, nibabel 5.4.2, contourpy, fontTools and
> friends. User-scope packages survive an uninstall, so a Python 3.12 existed on this machine
> before — consistent with the shipped `pythonEngine.dll`. They are now visible to the new 3.12
> and are partially broken (their own dependencies are gone). Harmless for the Resonance build.
> Either `pip install --force-reinstall` them if that analysis stack is still wanted, or delete
> that directory to get a clean interpreter.

<a id="history-b2-conan-2---installed"></a>

### B2. Conan 2 — ✅ installed

```bash
py -3.12 -m pip install --upgrade "conan>=2.0,<3"
```

`%LOCALAPPDATA%\Programs\Python\Python312\Scripts` is **not** on `PATH`. Either add it, or
invoke Conan as `py -3.12 -m conans.conan` (that shim still works in Conan 2) or by full path.
✅ Nothing to do for the Qt 6 build: `build-qt6.ps1` and `build-kardi2-x32.ps1` look for `conan.exe`
on `PATH` and fall back to that exact `Scripts\conan.exe` path themselves.

Default profile created with `conan profile detect` (with `mingw810_64\bin` on `PATH` so it
finds a compiler). It is only a fallback — the explicit profiles in
[section D](dev-environment.md#history-d-conan-profiles) are what the builds use.

<a id="history-b3-source-trees---done-but-the-two-are-acquired-differently"></a>

### B3. Source trees — ✅ done, but the two are acquired differently

There are two, and only one of them has a repository.

**`R:\src` (Qt 6, the default tree) — ⚠ no git at all.** The 2026-08-27 snapshot deliberately
removed the copied Git indirection so the tree carries no hidden dependency on the Qt 5 one:
there is no `R:\src\.git`, no submodules, and `3dparty\thir` and `3dparty\qml-colors` are ordinary
directories. It is transferred as files, and nothing else. See
[qt6-work-list.md §5](qt6-work-list.md).

**`R:\src_Qt5` (the comparator) — a real clone**, re-acquired 2026-08-11 as `R:\src` — the zip
export it replaced was moved aside to `R:\_src_zipexport_old`, which has since been deleted and is
no longer on the drive — and renamed to `R:\src_Qt5` on 2026-09-02. All five submodules populated
and pinned to the commits the project expects — SHAs in
[known-issues.md §1](../incidents/03-empty-submodules---resolved-2026-08-11.md#history-1-empty-submodules---resolved-2026-08-11).

```bash
git clone --recursive -b feature/services-and-isolation https://gitea.atedgeof.net/bcilab/Resonance
```

⚠ The branch has moved on since this section was written. Work is now on
**`feature/services-and-isolation`**, HEAD `fae69c3`, `git describe` → `3.4.1-137-gfae69c3`, and
unlike the old `feature/cmake-dual-build` it **is pushed** — local HEAD and
`origin/feature/services-and-isolation` are the same commit, 0 ahead / 0 behind. The git identity
that used to be unset is now set (`anatoly_nerak <anatoly@anvmail.com>`).

⚠ The working tree still carries **14 uncommitted changes** — 12 files under `neuroMS\` and
`nvx136\`, the `scriptEngines/python` submodule, and the untracked `nvx136\tracer\`. They are the
rig-driven cold-start and stimulator fixes, they are the only record of what the Qt 6 snapshot was
taken against, and a clone does not have them. Do not discard them.

If the clone ever needs refreshing:
```bash
git -C R:/src_Qt5 pull && git -C R:/src_Qt5 submodule update --init --recursive
```

⚠ `git submodule update` discards the working-tree edit in `scriptEngines/python` — see §B4.

<a id="history-b4-scriptengines---resolved-in-both-trees-by-different-routes"></a>

### B4. `scriptEngines` — ✅ resolved in both trees, by different routes

The 2026-08-11 blocker was that `scriptEngines/python/CMakeLists.txt` called
`install_files_with_prefix()`, which commit `bad97c0` (Oct 2024) deleted from the top-level
`CMakeLists.txt`, so the branch tip could not configure with `scriptEngines` enabled. Full
diagnosis in
[known-issues.md §2](../incidents/04-scriptenginespython-calls-a-cmake-function-that-was-deleted--blocks-configure.md#history-2-scriptenginespython-calls-a-cmake-function-that-was-deleted--blocks-configure).
What was actually done:

* **`R:\src_Qt5` took the compat shim** — `install_files_with_prefix` is re-added at
  `R:\src_Qt5\CMakeLists.txt:88` as a wrapper, and the submodule stays pinned as-is.
* **`R:\src` took the proper fix** — its `scriptEngines/python/CMakeLists.txt` calls
  `install_target(${PROJECT_NAME} "bin/engines")`. The function `install_files_with_prefix` does
  not appear anywhere in the Qt 6 tree.

⚠ **`pythonengine.cpp` carries an uncommitted working-tree edit** in the Qt 5 submodule: per-channel
`channel_properties` metadata attached to declared streams, which is how an epoch window reaches
the viewer at all. It exists in both trees' files; a `git submodule update` in `R:\src_Qt5` would
discard the only committed-nowhere copy. Guard:

```bash
grep -c channel_properties R:/src/scriptEngines/python/pythonengine.cpp
grep -c channel_properties R:/src_Qt5/scriptEngines/python/pythonengine.cpp
```

Both must report 4. ⚠ The older guard, `grep -n stdoutHook`
([known-issues §2e](../incidents/README.md)), is **dead** — neither tree contains that identifier;
the `stdout`-as-a-variable hazard was resolved by constructing the class as an unnamed temporary
(`py::class_<StdIOHook>(m, "stdout")` at `pythonengine.cpp:197`).

The engine's Python-side dependencies are installed (`pybind11` 3.1.0, `numpy` 2.5.2 for 3.12).

> ⚠️ **NumPy 2 vs pybind11 — a Qt 5-tree problem only.** `R:\src_Qt5\conanfile.txt` pins
> `pybind11/2.11.1`, which predates NumPy 2; pybind11 only gained NumPy 2 support in 2.12. If the
> comparator's engine build errors inside `pybind11/numpy.h`, pin the interpreter side down
> instead of chasing it:
> ```bash
> py -3.12 -m pip install "numpy<2"
> ```
> or bump `pybind11` in that `conanfile.txt` to ≥ 2.12. There, CMake resolves
> `find_package(pybind11)` through the Conan toolchain, so the pip-installed pybind11 is *not*
> what gets used.
>
> ✅ **The Qt 6 tree does not have this problem.** `R:\src\conanfile.txt` does not require pybind11
> at all — `build-qt6.ps1` asserts
> `Python312\Lib\site-packages\pybind11\share\cmake\pybind11` and puts it on `CMAKE_PREFIX_PATH`,
> so the resolved package **is** the pip one, 3.1.0, which supports NumPy 2.5.2.

<a id="history-b5-net-framework-48-sdk--ccli--for-neuronspectrum-and-neuroms"></a>

### B5. .NET Framework 4.8 SDK + C++/CLI — for `neuronSpectrum` and `neuroMS`

The Neurosoft Neuron-Spectrum-6g SDK is **.NET Framework 4.8 managed code** — no C API, no
import library — so `neuronSpectrum/bridge/ns65bridge.cpp` is compiled `/clr`. `neuroMS` has the
same shape and the same reason: `neuroMS/bridge/nmsbridge.cpp`. Those two are the only mixed-mode
translation units in either tree; everything else stays ordinary native C++, and both crossed into
the Qt 6 port unchanged in this respect.

In the VS Installer → *Individual components*, tick the C++/CLI component **matching the toolset
you build with**:

> **C++/CLI support for v143 build tools** — for `R:\src` (the default)
> **C++/CLI support for v142 build tools (14.29)** — for `R:\src_Qt5`

Each pulls in `NETFXSDK\4.8`, and with it `mscoree.lib`. On this box all three installed toolsets
(`14.29.30133`, `14.44.35207`, `14.51.36231`) carry `msvcmrt.lib`, so the component is present for
each. Installed 2026-08-15 and verified:

| Check | Result |
|---|---|
| `mscoree.lib` | `C:\Program Files (x86)\Windows Kits\NETFXSDK\4.8\Lib\um\x64\mscoree.lib` |
| `vcvarsall x64 -vcvars_ver=14.29` | adds `NETFXSDK\4.8\lib\um\x64` to `LIB` automatically |
| v142 toolset | unchanged — `VCToolsVersion=14.29.30133` |
| Qt 5.15.2 under v142 | still compiles (`QVector`/`QList`/`QVarLengthArray`) |
| Qt 5.15.2 under 14.51 | still **fails** — [§11a](../incidents/17-visual-studio-2026-cannot-compile-qt-5152--needs-the-v142-toolset.md#history-11a-visual-studio-2026-cannot-compile-qt-5152--needs-the-v142-toolset) is unaffected, `-vcvars_ver=14.29` is still mandatory for that tree |
| Qt 6.11.2 under v143 14.44 | builds both `/clr` bridges — `nmsbridge.dll` and `ns65bridge.dll` are asserted by `deploy-qt6.ps1` and ship in `R:\dist\bin\` |

> **The symptom if this component is missing** is `LINK : fatal error LNK1104: cannot open
> file "MSCOREE.lib"` — and *only* at link time. `/clr` compilation succeeds without it, which
> makes it look like a project error rather than a missing SDK.
>
> It can be worked around without the installer: `mscoree.lib` is only an import library for
> `mscoree.dll`, so `lib /def:` over a two-line `.def` exporting `_CorDllMain` and
> `_CorExeMain` produces a working one — the same technique `nvx\generateLIB.bat` uses. That
> was used to prove the bridge before the component was installed; the real SDK library is
> what ships.

**Runtime, not build time:** the vendor SDK also needs the **Intel IPP 8.1** runtime.
`NeuroSoft.MathLib.IPPLibrary` P/Invokes `ipps-8.1.dll`, and the SDK constructs its
online-impedance calculator *unconditionally* inside `StartReadData` — so IPP is required for
**any** acquisition, even with impedance switched off. The DLLs are staged into the
distribution's `bin\` rather than installed; see `neuronSpectrum/CMakeLists.txt`. The vendor's
own installer (`R:\equipment\NeurosoftPrograms\Нейрон-Спектр.NET\IPP\ipp81_runtime_setup.exe`)
is NSIS and can be unpacked read-only with 7-Zip if the DLLs ever need re-extracting.

The device itself needs **no vendor kernel driver** — it binds to Microsoft's inbox **WinUSB**
(`USB\VID_ACCA&PID_8277`, Windows 8.1+).

---


<a id="history-c-conditional-installs"></a>

## C. Conditional installs

<a id="history-c1-msvc---installed-2026-08-11-extended-2026-08-27-this-section-is-now-history"></a>

### C1. MSVC — ✅ installed 2026-08-11, extended 2026-08-27 (this section is now history)

Both halves are in place and `R:\dist_Qt5\msvc64` is built from them:

1. **VS Build Tools**, workload *Desktop development with C++* — installed as **VS 2026**
   Build Tools at `C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools`, with the
   **v142 (14.29)** toolset added as an individual component. v142 is not optional *for that tree*:
   [known-issues §11a](../incidents/17-visual-studio-2026-cannot-compile-qt-5152--needs-the-v142-toolset.md#history-11a-visual-studio-2026-cannot-compile-qt-5152--needs-the-v142-toolset).
2. **Qt 5.15.2 `msvc2019_64`** — added through `C:\Qt515\MaintenanceTool.exe`
   → *Add or remove components* → `Qt 5.15.2` → **MSVC 2019 64-bit**. Requires a (free) Qt
   account; the archive component list is already registered in `C:\Qt515\components.xml`.

The original advice here was to skip MSVC and try MinGW x64 first. That was carried out and
answered — **both toolchains build the whole x64 tree**
([build-and-distro.md §4](../../how-to/build.md)).
MSVC is kept because the deployed rigs run MSVC binaries, and because `neuronSpectrum` needs
`/clr`, which MinGW cannot provide at all ([§B5](dev-environment.md#history-b5-net-framework-48-sdk--ccli--for-neuronspectrum-and-neuroms)).

**What 2026-08-27 added** (Qt 6): the **v143 14.44.35207** toolset in the same Build Tools install,
and the `Qt 6.11.2 msvc2022_64` kit through the same `MaintenanceTool.exe`. Neither replaced
anything. The Qt 6 build never uses the VS 2026 default (`14.51.36231`) — `build-qt6.ps1` pins
`-vcvars_ver=14.44` and throws if that toolset is absent.

⚠ **There is no Qt 6 successor to the MinGW distributions.** `mingw810_64` is now needed only to
rebuild the Qt 5 comparator; `mingw810_32` is still needed by the **default** build, for the
KARDi2 x86 island ([qt5-to-qt6-transition.md §6](qt5-to-qt6-transition.md)).

<a id="history-c2-ni-daqmx--only-to-run-the-daqmx-service"></a>

### C2. NI-DAQmx — only to *run* the `DAQmx` service

`DAQmx` **was ported on 2026-09-05** — native x64 Qt 6, `R:\dist\bin\DAQmx.exe`; the Qt 5 copy in
`R:\dist_Qt5\msvc64` is the comparator — see [service_daqmx.md](../components/daqmx.md). Building the Qt 6
module needs NI's ANSI C headers and import library ([new-pc-setup](new-pc-setup.md)); the
paragraphs below describe the Qt 5 module, which vendors them.

Compilation does **not** need it: `R:\src_Qt5\DAQmx\dll\include\*.h` and
`R:\src_Qt5\DAQmx\dll\x86_64\*.lib` are vendored. Running it on a machine with NI hardware needs
the **NI-DAQmx runtime** from ni.com (free, ~2 GB with the installer).

<a id="history-c3-r--only-if-you-resurrect-the-r-script-engine"></a>

### C3. R — only if you resurrect the R script engine

Not in either CMake build. `R:\src_Qt5\bat\speed.bat` shows it was once shipped 32-bit
(`R\bin\i386`). Needs R + `RInside`/`Rcpp` packages. Treat as a separate project.

<a id="history-c4-vendor-drivers-for-the-amplifiers"></a>

### C4. Vendor drivers for the amplifiers

Kernel drivers are vendored but **not** installed by the build, and both crossed into the Qt 6
tree, so the paths hold in either:
* NVX-136 uses a Cypress USB driver: `R:\src\nvx136\Driver\` (`MediaConverter.inf`, `cyusb.sys`).
* KARDi2 uses `R:\src\KARDi2\3dparty\Driver\McsUsb.inf` — and `deploy-qt6.ps1` stages **both**
  architectures below `R:\dist\kardi2_x32\driver\`.
Install these only on machines actually connected to the hardware.

**Neuron-Spectrum-65 needs none of this** — it binds to Microsoft's inbox **WinUSB** driver
(`USB\VID_ACCA&PID_8277`). What it does need at runtime is the Intel IPP 8.1 DLLs, which the
build stages into `bin\` rather than installing; see [§B5](dev-environment.md#history-b5-net-framework-48-sdk--ccli--for-neuronspectrum-and-neuroms).

---


<a id="history-d-conan-profiles"></a>

## D. Conan profiles

Conan is **2.31.2** here, at `%LOCALAPPDATA%\Programs\Python\Python312\Scripts\conan.exe`.

<a id="history-d0-the-two-qt-6-profiles-are-versioned-with-the-source-not-with-the-user---nothing-to-create"></a>

### D0. The two Qt 6 profiles are versioned with the source, not with the user — ✅ nothing to create

⚠ **The default build does not read `%USERPROFILE%\.conan2\profiles\` at all.** Both Qt 6 profiles
live in the tree and are passed to `conan install` as `-pr:h` and `-pr:b`:

| Profile | Path | Used by |
|---|---|---|
| `msvc-v143-release` | `R:\src\profiles\msvc-v143-release` | `build-qt6.ps1` — the x64 Qt 6 build |
| `mingw-x86-release` | `R:\src\KARDi2\qt5-island\profiles\mingw-x86-release` | `build-kardi2-x32.ps1` — the KARDi2 x86 island |

```ini
# R:\src\profiles\msvc-v143-release
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

`compiler.version=194` is the v143 14.4x family; `cppstd=20` matches
`R:\src\CMakeLists.txt`'s `CMAKE_CXX_STANDARD 20`. ⚠ `tools.build:jobs=1` is deliberate and is
also passed again on the command line: MSVC 19.44 has been observed to ICE when Conan compiles
several copies of `gtest-all.cc` concurrently. The **project** build stays at `-j6`.

The island profile is the old `mingw32` shape (gcc 8, `arch=x86`, `exception=dwarf2`, `cppstd=17`,
`mingw810_32` in `compiler_executables` and `[buildenv] PATH`) — identical in substance to the
`mingw32` profile printed below, just moved in-tree.

⚠ **The two trees request different dependency sets.** `R:\src\conanfile.txt` asks for
`hdf5/1.13.1`, `boost/1.78.0` (`header_only=True`), `iir1/1.9.0`, `gtest/1.15.0` — and **no
pybind11**, which the Qt 6 build takes from pip instead ([§B4](dev-environment.md#history-b4-scriptengines---resolved-in-both-trees-by-different-routes)).
`R:\src_Qt5\conanfile.txt` additionally requires `pybind11/2.11.1` and does *not* set
`header_only=True` on boost.

<a id="history-d1d3-the-qt-5-comparator-profiles---mingw32-and-mingw64-created"></a>

### D1–D3. The Qt 5 comparator profiles — ✅ `mingw32` and `mingw64` created

These three are for `R:\src_Qt5` only. They live in `%USERPROFILE%\.conan2\profiles\` and were
verified to parse with `conan profile show`. `msvc64` below is written out but **not** created —
add it only if you install VS Build Tools.

The `exception`/`threads` values were read off the compilers on this machine
(`i686-posix-dwarf`, `x86_64-posix-seh`) — getting them wrong produces silently
ABI-incompatible binaries.

`compiler.version` is **`8`, not `8.1`** — Conan 2 uses the major version only for gcc ≥ 5
(`conan profile detect` reports *"gcc>=5, using the major as version"*). Writing `8.1` yields
a settings-validation error.

**`mingw32`**
```ini
[settings]
os=Windows
arch=x86
build_type=Release
compiler=gcc
compiler.version=8
compiler.cppstd=17
compiler.libcxx=libstdc++11
compiler.threads=posix
compiler.exception=dwarf2

[conf]
tools.cmake.cmaketoolchain:generator=Ninja
tools.build:compiler_executables={"c":"C:/Qt515/Tools/mingw810_32/bin/gcc.exe","cpp":"C:/Qt515/Tools/mingw810_32/bin/g++.exe"}

[buildenv]
PATH=+(path)C:/Qt515/Tools/mingw810_32/bin
```

**`mingw64`**
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

**`msvc64`** (only if you installed VS Build Tools)
```ini
[settings]
os=Windows
arch=x86_64
build_type=Release
compiler=msvc
compiler.version=194
compiler.cppstd=17
compiler.runtime=dynamic

[conf]
tools.cmake.cmaketoolchain:generator=Ninja
```

<a id="history-a-note-on-cppstd"></a>

### A note on `cppstd`

`R:\src_Qt5`'s top-level `CMakeLists.txt` asks for **C++20**, but GCC 8.1 only has partial C++20
(`-std=c++2a`). The QBS files ask for C++17, and nothing in that code actually needs C++20 —
the newest constructs in use are `std::shared_mutex` and `std::atomic` (C++17). Keeping the three
comparator profiles on `cppstd=17` avoids ABI mismatches with the dependencies; if CMake's
`CXX_STANDARD 20` causes trouble under GCC 8.1, lower it to 17 in
`R:\src_Qt5\CMakeLists.txt:6` — it is a one-line change with no expected fallout.

⚠ **This reasoning does not carry to the Qt 6 tree.** `R:\src` is MSVC v143 / C++20 throughout and
its Conan profile says `compiler.cppstd=20`; there is no GCC in the picture except inside the x86
island, which is pinned to C++17 by its own root (`CMAKE_CXX_STANDARD 17`).

<a id="history-speed-up-build-boost-header-only---now-the-default-in-both-trees"></a>

### Speed-up: build Boost header-only — ✅ now the default in both trees

The project uses Boost **only** for headers (`boost/range/*`, `boost/preprocessor/*`,
`boost/endian/*`, `boost/shared_ptr.hpp` in `thir`) and links the header-only
`boost::boost` target. Compiling full Boost 1.78 from source takes a long time and is the most
likely place for the first build to fail.

`R:\src\conanfile.txt` now carries it in the recipe rather than leaving it to the command line:

```
[options]
boost/*:header_only=True
boost/*:without_stacktrace=True
boost/*:without_fiber=True
boost/*:without_math=True
boost/*:without_graph=True
```

`R:\src\KARDi2\qt5-island\conanfile.txt` does the same with just `header_only=True`.
⚠ `R:\src_Qt5\conanfile.txt` still keeps only the `without_*` options, so a comparator build
must pass `-o "boost/*:header_only=True"` on the command line as §E does.

---


<a id="history-e-full-first-run-sequence"></a>

## E. Full first-run sequence

Sections A–D are already done on this machine. What remains per build.

<a id="history-e0-the-default--qt-6-and-it-is-three-scripted-commands"></a>

### E0. The default — Qt 6, and it is three scripted commands

From a **PowerShell** window. Nothing to set on `PATH`: each script pins Qt, CMake, Ninja,
`vcvarsall` and the Conan profile by absolute path, asserts every one of them up front, and
`throw`s on the first that is missing.

```powershell
R:\src\scripts\build-qt6.ps1                # x64 Qt 6 tree       -> R:\src\_build
R:\src\scripts\build-kardi2-x32.ps1         # KARDi2 x86 island   -> R:\src\_build-kardi2-x32
R:\src\scripts\deploy-qt6.ps1               # both, + windeployqt -> R:\dist
R:\src\scripts\validate-dist-qt6.ps1        # static + launch check of R:\dist
```

`deploy-qt6.ps1` runs both builds itself unless given `-SkipBuild`, and both its `-Destination`
and the two validators' `-Distribution` default to `R:\dist`. Add `-SkipConan` to a build script
once the dependency cache is warm.

⚠ **The Qt 6 tree builds *inside itself*** — `_build`, `_build-kardi2-x32`, `_dist`, `_stage`,
`_test-output` are all under `R:\src`, and the root `CMakeLists.txt` forces `CMAKE_INSTALL_PREFIX`
to `${CMAKE_SOURCE_DIR}/_dist`. This is the opposite of the rule §E1 states for the comparator, and
it is deliberate. The consequence: **a copied or renamed tree must have its caches deleted** before
the next configure, because each records its own `CMAKE_HOME_DIRECTORY`:

```bash
rm -rf R:/src/_build R:/src/_build-kardi2-x32
```

⚠ **`build-qt6.ps1` sets `chcp 65001` itself** (plus `[Console]::OutputEncoding`) before
configuring and before building, and that is not cosmetic. This machine's OEM code page is 866; at
the default page Ninja cannot string-match `cl.exe`'s localised `/showIncludes` prefix against the
UTF-8 one CMake recorded at configure time, records **zero** header dependencies for every target,
and a later header edit then links translation units compiled against two different class layouts —
cleanly, and faulting at run time. See [known-issues §11c](../incidents/README.md). A **hand-run**
`cmake`/`ninja` outside the script still needs the `chcp 65001` from you.

<a id="history-e1-the-comparator--qt-5-from-a-cmdexe-window"></a>

### E1. The comparator — Qt 5, from a **cmd.exe** window

⚠ Every path below points **outside `R:\src_Qt5`** — that source tree stays clean. This is the old
rule, and it still governs the Qt 5 tree; §E0's in-tree layout is the exception, not the new norm.
The commands are unchanged from the 2026-08-11 sequence apart from the two renamed prefixes.

```bat
:: ---------- 32-bit (done, verified working) ----------
set PATH=C:\Qt515\Tools\mingw810_32\bin;C:\Qt515\Tools\CMake_64\bin;C:\Qt515\Tools\Ninja;%PATH%
cd /d R:\src_Qt5
conan install . -of R:\dist_Qt5\_build\mingw32 -pr:h mingw32 -pr:b mingw32 ^
      -s build_type=Release -o "boost/*:header_only=True" ^
      -c "tools.cmake.cmaketoolchain:user_presets=" --build=missing
cmake -S R:/src_Qt5 -B R:/dist_Qt5/_build/mingw32 -G Ninja -DCMAKE_BUILD_TYPE=Release ^
      -DCMAKE_TOOLCHAIN_FILE=R:/dist_Qt5/_build/mingw32/conan_toolchain.cmake ^
      -DCMAKE_PREFIX_PATH=C:/Qt515/5.15.2/mingw81_32
cmake --build R:/dist_Qt5/_build/mingw32
```

```bat
:: ---------- 64-bit ----------
set PATH=C:\Qt515\Tools\mingw810_64\bin;C:\Qt515\Tools\CMake_64\bin;C:\Qt515\Tools\Ninja;%PATH%
cd /d R:\src_Qt5
conan install . -of R:\dist_Qt5\_build\mingw64 -pr:h mingw64 -pr:b mingw64 ^
      -s build_type=Release -o "boost/*:header_only=True" ^
      -c "tools.cmake.cmaketoolchain:user_presets=" --build=missing
cmake -S R:/src_Qt5 -B R:/dist_Qt5/_build/mingw64 -G Ninja -DCMAKE_BUILD_TYPE=Release ^
      -DCMAKE_TOOLCHAIN_FILE=R:/dist_Qt5/_build/mingw64/conan_toolchain.cmake ^
      -DCMAKE_PREFIX_PATH=C:/Qt515/5.15.2/mingw81_64 ^
      -DPython_ROOT_DIR=C:/Users/Anatoly/AppData/Local/Programs/Python/Python312
cmake --build R:/dist_Qt5/_build/mingw64
```

The `msvc64` variant — the one that actually produced `R:\dist_Qt5\msvc64` — is in
[build-and-distro.md §5](and-distro.md#history-5-build-commands); it needs
`vcvarsall x64 -vcvars_ver=14.29` first (§B5) and the `msvc64` profile from
[section D](dev-environment.md#history-d-conan-profiles).

Then assemble and **verify** — see
[build-and-distro.md §6](and-distro.md#history-6-assembling-a-distro-tree) and
[§7](and-distro.md#history-7-verifying-a-deploy). A build is not done until it has been launched.

`-c "tools.cmake.cmaketoolchain:user_presets="` stops Conan writing `CMakeUserPresets.json`
into the source directory. Both Qt 6 scripts pass it too.

`conanfile.txt` has no `[layout]` section in either tree, so Conan writes `conan_toolchain.cmake`
and `*-config.cmake` straight into the `-of` folder, **not** into `build/Release/generators/`. If
you later add `[layout] cmake_layout`, the toolchain path in the `cmake -S ... -B ...` line has to
change accordingly.

Open the two shells separately, or reset `PATH` between them — **never put both MinGW `bin`
directories on `PATH` at the same time.** That is the single most common cause of confusing
"undefined reference" and "wrong architecture" errors on a dual-arch Windows build. ⚠ The Qt 6
scripts sidestep this by never touching `PATH`: `build-kardi2-x32.ps1` prepends `mingw810_32\bin`
to its own process environment only.

Expected products: `R:\dist_Qt5\_build\mingw32\runtime\` and `R:\dist_Qt5\_build\mingw64\runtime\`.
Assemble the distro from there per
[build-and-distro.md §6](and-distro.md#history-6-assembling-a-distro-tree).

---


<a id="history-f-verification-checklist"></a>

## F. Verification checklist

Checks 1–6 are cheap. **7–10 are the ones that actually matter** — a compile proves nothing
about whether the thing runs. Full procedure and pitfalls in
[build-and-distro.md §7](and-distro.md#history-7-verifying-a-deploy).

<a id="history-f0-qt-6--run-the-validator-scripts-first"></a>

### F0. Qt 6 — run the validator scripts first

`R:\src\scripts\validate-dist-qt6.ps1` asserts 65 required files under `R:\dist`, then launches
`nvx.exe` and `quickStimulus.exe` from a `PATH` that deliberately contains **no Qt installation
directory** — which is what makes it a real test of row 8 — greps both processes' logs for error
patterns and, when given `-CapturePath`, screenshots the Configurator window, writing its evidence
into `R:\src\docs\qa\`. It covers rows 6 and 8–10. It never touches the build tree (rows 1–5) and
it does **not** run the unit tests (row 7).
`validate-kardi2-x32.ps1` does the equivalent for the x86 island, including an `objdump -f`
architecture check on each staged binary with `C:\Qt515\Tools\mingw810_32\bin\objdump.exe` — that
proves the island is PE32/i386; it does not walk imports.
`validate-qt5-interop.ps1` runs `R:\dist_Qt5\msvc64\bin\nvx.exe` against `R:\dist\bin\quickStimulus.exe`
to prove the two generations still talk. Run those first; the table below is what to do by hand
when one of them fails and you need to know where.

| # | Check | Qt 6 expectation |
|---|---|---|
| 1 | Prerequisites | each build script's `foreach ($required …)` block passes rather than throwing |
| 2 | Conan resolves deps | `conan install` finishes without `ERROR:`; profile `R:\src\profiles\msvc-v143-release` |
| 3 | CMake configures | no `find_package` failures for **Qt6**, Boost, HDF5, iir, pybind11, Python 3.12 EXACT |
| 4 | Core links | `R:\src\_build\runtime\bin\Resonance.dll` exists |
| 5 | QML plugin | `R:\src\_build\runtime\bin\Resonance\quickStimulusPlugin.dll` + `qmldir`. ⚠ `windeployqt` does **not** find its indirect imports; `deploy-qt6.ps1` scans that DLL explicitly |
| 6 | Arch gating right | x64 `bin\` has 16 executables and **no** `KARDi2.exe`; the PE32 one lives only in `kardi2_x32\bin\` |
| 7 | Unit tests | CTest from the build root. ⚠ `VALIDATION.md`'s last entry claims **22/22 enabled**, four physical/external disabled by design, but **no ctest log backs that number**: the newest artefact, `qa\ctest-three-services-final.log`, records 20/20 enabled of 24 registered, and `qa\ctest-qt6-final.log` records 17/17 ([qt6-work-list.md §4](qt6-work-list.md)). ⚠ `Core\Resonance`'s seven gtest binaries are built but **never registered** (`Core/Resonance/tests/CMakeLists.txt:95-96`, `include(GoogleTest)` and `gtest_discover_tests` commented out), so a green run does not cover them |
| 8 | **All imports resolve** | recursive walk → `qt\plugins\platforms\qwindows.dll` present. ⚠ Do not reuse the Qt 5 tree's "exactly three unresolved" figure: EyeLink is now present and ships app-local `MSVCR90.dll`, DAQmx remains absent, and `python312.dll` ships in `R:\dist\bin\` |
| 9 | **It starts** | `R:\dist\signalGenerator.bat` → process alive, UDP **13370 on `127.0.0.1`** bound by its pid (`netstat -ano`, not `Get-NetUDPEndpoint`). ⚠ **No 13371**: the multicast socket is not created in the default `loopback` mode |
| 10 | **It works** | `+ R:\dist\configurator.bat` → window titled `Configurator`, established loopback TCP pair between the two pids |

<a id="history-f1-qt-5-comparator--the-original-checklist"></a>

### F1. Qt 5 comparator — the original checklist

Same ten checks against `R:\src_Qt5` → `R:\dist_Qt5`:

| # | Check | Command / expectation |
|---|---|---|
| 1 | Submodules non-empty | `R:\src_Qt5\3dparty\thir\thir\generate.hpp` exists |
| 2 | Conan resolves deps | `conan install` finishes without `ERROR:` |
| 3 | CMake configures | no `find_package` failures for Qt5, Boost, HDF5, iir |
| 4 | Core links | `_build\mingw32\runtime\bin\libResonance.dll` exists |
| 5 | QML plugin | `…\runtime\bin\Resonance\quickStimulusPlugin.dll` + `qmldir` |
| 6 | Arch gating right | x86 tree has `KARDi2.exe` and no `nvx*.exe`; x64 the reverse |
| 7 | Unit tests | `_build\mingw32\Core\Resonance\tests\test_StreamInfo.exe` → 9/9 green |
| 8 | **All imports resolve** | recursive `objdump -p` walk → zero unresolved; `qt\plugins\platforms\qwindows.dll` present |
| 9 | **It starts** | `signalGenerator.bat` → process alive, UDP **13370 on `127.0.0.1`** bound by its pid (`netstat -ano`, not `Get-NetUDPEndpoint`). ⚠ **No 13371** since 2026-08-18: the multicast socket is not created in the default `loopback` mode |
| 10 | **It works** | `+ configurator.bat` → window titled `Configurator`, established loopback TCP pair between the two pids |

Always run the same checks against `R:\dist_legacy\distro-dual\mingw32` as a control. Both
false failures encountered on 2026-08-11 (`NoDefaultCurrentDirectoryInExePath`, Git Bash's
`env.exe` shadowing `env.bat`) reproduce on the known-good 2024 build — and ⚠ both are still live
in `R:\dist_Qt5\msvc64`, whose launchers say bare `call env`. ✅ They do **not** reproduce against
`R:\dist`, whose launchers say `call "%~dp0env.bat"`.

---


<a id="history-g-day-to-day-development"></a>

## G. Day-to-day development

* **IDE:** Qt Creator is already installed (`C:\Qt515\Tools\QtCreator\bin\qtcreator.exe`) and
  opens `R:\src\CMakeLists.txt` directly. Configure one kit per Qt/compiler pair you actually
  build — Qt 6.11.2 `msvc2022_64` + v143 for the default, plus the Qt 5 pairs for the comparator
  and the x86 island — so you can switch with the kit selector. ⚠ A Qt Creator kit will not
  reproduce `build-qt6.ps1`: it does not pin `-vcvars_ver=14.44`, does not set the UTF-8 code page,
  and will configure into a directory of its own choosing. Treat the IDE as an editor and let the
  scripts do the builds. VS Code + the CMake Tools extension works equally well and is lighter.
* **Formatting:** run clang-format with `R:\src\.clang-format` on everything you touch. The two
  trees' copies are byte-identical, so one style covers both. Qt Creator ships a Beautifier plugin
  that can use it; otherwise `py -3.12 -m pip install clang-format` gives you a standalone binary.
* **Debug output:** services are built with `WIN32` (no console). Three ways to see it:
  **`--console`** on any service's command line, which opens a window carrying that service's
  output; the Configurator's **System → Show console**, in the parameter panel, which does the
  same to a service that is **already running**; and `R:\Dbgview.exe` (Sysinternals DebugView,
  already on the drive) — run it as admin to see every service at once, which is still the best
  option when the question is about several of them.
  See [architecture §11c](framework-evolution.md).
* **Debug builds:** on the Qt 5 tree, `-s build_type=Debug` + `-DCMAKE_BUILD_TYPE=Debug` and a
  separate build dir. On the Qt 6 tree, `build-qt6.ps1 -Configuration Debug` (or
  `RelWithDebInfo`) — ⚠ but it reuses the **same** `R:\src\_build` root for every configuration,
  so switching means a stale cache unless you delete it first. Watch out for the `nvx136` library
  path quirk documented in
  [known-issues](../incidents/10-nvx136-library-path-depends-on-cmake_build_type---fixed-2026-08-15.md#history-4-nvx136-library-path-depends-on-cmake_build_type---fixed-2026-08-15).
* **Network:** nothing to do. Since 2026-08-18 a service is **loopback-only by default** and
  needs no firewall hole at all. ⚠ The advice that stood here — "allow UDP 13370 and 13371
  and TCP 10000–20000" — was wrong in both halves even for `lan` mode: there is no 13371
  socket by default, and `portRangeBegin/End` are dead code, so the TCP ports are OS-assigned
  ephemerals that cannot be pinned. For a genuine multi-PC rig, set `networkMode: lan` and open
  UDP 13370/13371 plus the ephemeral range — [network-isolation.md](network-isolation.md).
