# Set up a development PC

Status: current procedure. Scope: building the full Windows x64 Qt 6 source tree. Authority: [build script](../../src/scripts/build-qt6.ps1), [Conan profile](../../src/profiles/msvc-v143-release), [dependencies](../../src/conanfile.txt), and module CMake checks; inspected 2026-09-15. This page does not claim a fresh-PC installation was rerun.

## 1. Keep the roots distinct

Use `R:/src` for active source and its `_build/` output. `R:/dist` is the operator's deployed package. Build/setup work should not overwrite that package. The Qt 5 source/package are separate legacy/comparison inputs; use [current status](../current.md) and [source map](../architecture/source-map.md) to identify them.

The build script currently pins local installation paths. On another PC, either provide the expected locations or deliberately adapt the script/profile as a reviewed configuration change. Do not assume that installing any recent Qt or MSVC release satisfies the pins.

## 2. Install the current build prerequisites

| Requirement | Expected configuration / source of truth |
|---|---|
| Qt | 6.11.2 MSVC x64 at `C:/Qt515/6.11.2/msvc2022_64`; install modules named by active CMake, including StateMachine, QML/Quick/Controls, Widgets, multimedia and device-related modules |
| CMake and Ninja | `C:/Qt515/Tools/CMake_64/bin/cmake.exe` and `C:/Qt515/Tools/Ninja/ninja.exe` |
| Visual Studio Build Tools | Script locates VS 18 BuildTools and explicitly initializes the archived v143 14.44 toolset with `-vcvars_ver=14.44`; do not substitute the installer's default toolset |
| Windows SDK / resources | C++ desktop build tools, Windows headers/libraries and resource compiler |
| C++/CLI and .NET | Matching MSVC C++/CLI support and .NET Framework 4.8 development/reference assemblies for the Neurosoft bridges |
| Python | x64 CPython 3.12 under `%LOCALAPPDATA%/Programs/Python/Python312`, with NumPy and pybind11 in that interpreter's site-packages |
| Conan | Conan 2, discoverable on PATH or in that Python installation's Scripts directory |
| NI-DAQmx | Installed ANSI C development SDK; default root `C:/Program Files (x86)/National Instruments/Shared/ExternalCompilerSupport/C`, including headers and `lib64/msvc` library |
| FieldTrip C tools | GCC found by CMake, with the current hint `C:/Qt515/Tools/mingw1310_64/bin`; used for the Qt-free upstream tools |

The current profile selects Windows x64, MSVC `compiler.version=194`, dynamic Release CRT, C++20, Ninja, and VS version 18. Read the profile rather than recreating it from a historical Qt 5 example.

Conan supplies the versions in [conanfile.txt](../../src/conanfile.txt): HDF5, Boost, iir1 and GoogleTest. The build script installs missing dependency packages. Keep its serial dependency-build setting and the separate project job cap; they address recorded compiler/build stability observations.

## 3. Preserve vendor inputs and architecture boundaries

- Keep vendored SDK headers, libraries, firmware and managed assemblies with their modules. Copying source while excluding all DLLs can remove required build/package inputs.
- KARDi2 requires its x86 vendor DLL and the broker source. The main script builds that broker automatically before the x64 service configuration. Qt 5/MinGW x86 is not a prerequisite for the current KARDi2 service.
- Neuro-MS and Neuron-Spectrum use native service code plus separate C++/CLI bridges. Their bridge targets use C++17 and `/clr`/asynchronous exception handling; do not apply the parent C++20 settings indiscriminately.
- Preserve private managed-assembly directories for the two Neurosoft SDKs. Same-named, unsigned assemblies have different contents. Neuron-Spectrum also needs its native Intel IPP runtime for acquisition even when impedance display is disabled.
- Device/runtime installation remains component-specific. The NI development SDK is a build requirement; NI runtime/device configuration is a deployment requirement. Packaging a vendor DLL does not install a kernel driver.

Use [DAQmx](../components/daqmx.md), [FieldTrip](../components/fieldtrip.md), [KARDi2](../components/kardi2.md), [Neuron-Spectrum](../components/neuron-spectrum.md), and [Neuro-MS](../components/neuroms.md) for their exact interfaces and device prerequisites.

## 4. Configure and verify

From PowerShell:

```powershell
Set-Location R:/src
./scripts/build-qt6.ps1
```

The script checks its tool paths, imports the correct compiler environment, sets the UTF-8 console code page, builds the broker, installs Conan dependencies, configures CMake and builds. Follow [build](build.md) for incremental work and troubleshooting. Its checks are not a complete fresh-PC preflight: module CMake performs further checks, including NI and vendor inputs. The old `assert-build-inputs.ps1` and `build-kardi2-x32.ps1` are not current runnable entrypoints.

After moving a source tree, inspect `_build/CMakeCache.txt` for its recorded source/compiler/toolchain before reusing it. An incompatible cache needs a deliberate rebuild; there is no standing instruction to delete today's cache merely because a historical document records a path rename.

List and select the appropriate [tests](test.md), then create a separate candidate package using [deploy](deploy.md). A successful compile or device-free smoke test does not qualify a physical rig.

## Legacy setup and evidence

Only install the older Qt 5 toolchains when a specific comparison or legacy task requires them. The previous machine inventory and setup experiments are retained in [development environment history](../history/migrations/dev-environment.md) and [new-PC setup history](../history/migrations/new-pc-setup.md). They describe dated configurations, not extra mandatory steps for this procedure. Track missing prerequisites or unverified platform claims in [issues](../issues/README.md).

