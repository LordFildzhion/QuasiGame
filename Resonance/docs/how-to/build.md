# Build the Qt 6 tree

Status: current procedure. Scope: source compilation and build-runtime staging; deployment is separate. Authority: [build-qt6.ps1](../../src/scripts/build-qt6.ps1), [top-level CMake](../../src/CMakeLists.txt), and [Conan profile](../../src/profiles/msvc-v143-release); inspected 2026-09-15.

## Normal commands

After [setup](setup.md), run from PowerShell:

```powershell
Set-Location R:/src
./scripts/build-qt6.ps1
```

For source-only iteration with an existing compatible Conan toolchain/dependency set:

```powershell
./scripts/build-qt6.ps1 -SkipConan
```

The script also accepts `-Configuration Release|RelWithDebInfo|Debug`; Release is the default. It reuses one `_build/` directory, so a configuration/toolchain/dependency change requires compatible regenerated Conan inputs. Do not use `-SkipConan` to skip a necessary dependency/configuration update. The deployment script currently packages Release.

## What the script does

1. Resolves source/output paths from its own location and validates pinned tool paths.
2. Imports the x64 MSVC v143 14.44 environment and then sets console code page 65001.
3. Builds the Qt-free KARDi2 x86 broker in its separate compiler environment.
4. Runs Conan 2 with the versioned host/build profile unless skipped. Dependency compilation is serial.
5. Configures Ninja/CMake with the Conan toolchain, Qt and pybind11/Python paths.
6. Builds the project with `-j 6`.

The compiler encoding step is part of dependency correctness. On the recorded localized Windows environment, mismatched `/showIncludes` encoding made Ninja record no header dependencies, allowing incompatible object layouts after a header edit. Preserve UTF-8 code-page setup for both configure and build. Do not replace the script with an arbitrary shell's compiler environment.

Windows PowerShell 5.1 native stderr behavior is also accounted for: tools can write successful progress to stderr, so the script uses explicit exit-code checks. Retain those checks when modifying the build workflow.

## Find the output

| Location | Meaning |
|---|---|
| `src/_build/` | Conan/CMake/Ninja configuration, object files and test targets |
| `src/_build/runtime/bin/` | Staged service executables, framework and plugins |
| `src/_build/runtime/` | Build-stage launchers and runtime content |
| `src/KARDi2/_build-x86/bin/` | Separate vendor broker build output |
| `src/_dist/` | Default CMake install prefix; not the same as the live package |
| `dist/` | Default destination only when the deployment script is run |

`install_target`, `install_files`, and `install_directory` in the top-level CMake define runtime/install placement. Editing a staged copy does not change the source. The current top-level target list includes FieldTrip and DAQmx. It excludes the retained `nvx136_2021` comparator. Refer to [source map](../architecture/source-map.md) before assuming a directory is built.

## Targeted iteration

Once the correct MSVC/code-page environment is initialized in the current shell, CMake can build a selected target. For example, the QML staging target is:

```powershell
& 'C:/Qt515/Tools/CMake_64/bin/cmake.exe' --build 'R:/src/_build' --target quickStimulusQml -- -j 6
```

Use the normal build script when the environment is uncertain. A header or shared implementation change can affect multiple targets. quickStimulus and TepSound share spline/linear-algebra source; rebuilding only one executable is not sufficient coverage for that change. `quickStimulusQml` refreshes QML even when the C++ plugin does not relink; it does not update an existing deployed package.

## Investigate failures without erasing evidence

- Missing dependency: use the first CMake/script failure to identify the actual path/component; see [setup](setup.md).
- Wrong Qt/compiler: compare the script/profile and cache. Do not copy Qt 5 flags or automatically select the newest installed MSVC toolset.
- Unexpected stale behavior: identify the executable, plugin/QML paths, cache source root, and header dependencies before clearing caches.
- Compiler internal error: retain the failing command/log, respect the existing job limits, and consult the [build history](../history/migrations/and-distro.md) and [issue registry](../issues/README.md).
- Fresh tree skips KARDi2: verify the broker stage and vendor DLL inputs; a successful build missing a service is not a complete package.

Do not delete all build trees as a routine first step. If rebuilding an incompatible cache is necessary, resolve the exact disposable directory and preserve needed evidence/oracle data before removing it. Never include a deployment or source directory in that cleanup.

## Finish the code task

Run [tests appropriate to the change](test.md), reporting skipped or unavailable coverage separately. For packaging, follow [deploy](deploy.md). Compilation does not imply device acceptance, installed-driver readiness, or successful data acquisition. The dated [Qt migration record](../history/migrations/qt5-to-qt6-transition.md) explains older paths and toolchains; it is not part of every incremental build.

