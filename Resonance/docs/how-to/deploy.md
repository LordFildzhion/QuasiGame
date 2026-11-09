# Assemble and verify a Qt 6 package

Status: current procedure. Scope: installing build outputs into a candidate or operator package. Authority: [deploy-qt6.ps1](../../src/scripts/deploy-qt6.ps1), CMake install rules, [env.bat](../../src/Core/Resonance/env.bat), and validation scripts; inspected 2026-09-15. No package was deployed for this documentation change.

## Choose the destination deliberately

The deployment script defaults to `R:/dist`, the operator package. For review or development, use a separate candidate destination explicitly:

```powershell
Set-Location R:/src
./scripts/deploy-qt6.ps1 -Destination 'R:/src/_dist'
```

It builds first unless `-SkipBuild` is supplied. With a current, compatible Release build already available:

```powershell
./scripts/deploy-qt6.ps1 -Destination 'R:/src/_dist' -SkipBuild
```

Do not use `-SkipBuild` as a substitute for checking source/build identity. The script packages Release and expects required service, bridge, broker, plugin and Python inputs. See [build](build.md) before changing the configuration.

## Understand overwrite and preservation behavior

`cmake --install` and this script copy/install files; they do not mirror-delete the destination. They also do not create a rollback copy. A non-deleting install can still overwrite an operator's edited file at an installed path, and can leave obsolete files behind.

Before updating an existing rig package, identify and preserve its operator changes: parameter sets, protocols, montages, calibration, stimuli, launcher configuration, local environment/configuration and deploy-only assets. Use a recoverable copy of the affected existing package/content. Stop services using binaries being replaced and complete device stop/release before process termination.

Never use `robocopy /MIR` for a rig deployment. If a manual copy is necessary, use non-deleting semantics such as `/E`, explicit source/destination paths, and the same content ownership review. Non-deleting copy alone does not protect same-name edited files. Removing retired binaries or content is a separate, explicit cleanup after checking their ownership and use.

## Package layout and assembly

| Location | Owned content |
|---|---|
| `bin/` | Services, Resonance.dll, native vendor/runtime DLLs, firmware and qt.conf |
| `bin/Resonance/` | quickStimulusPlugin and the Resonance QML module |
| `bin/engines/` | Python engine plugin |
| `bin/neuroMS/`, `bin/neuronSpectrum/` | Separate private managed SDK assemblies |
| `qt/bin`, `qt/plugins`, `qt/qml` | Private Qt deployment and app-local compiler runtime |
| `python/` | Bundled private CPython and packages; engine also needs its matching DLL/standard-library archive beside host executables |
| `params`, `protocols`, `montages`, `stimuli`, `calib` | Shipped defaults plus operator content; review same-name overwrites |
| `venues/MPRAC`, `venues/P300TEST`, `venues/BPRAC` | Standard-service venue presets, launchers, montages and icons; preserve operator edits |
| `data/` | Recording destination; not a build artifact |
| Root launchers, `icons/`, `launch/` | Environment/launch configuration, icons and generated shortcuts |
| `driver/` | Shared driver packages from `src/runtime-content/driver`; one `Install.bat` beside each package's INF/CAT files or vendor `setup.exe` |

The script first installs CMake outputs, explicitly stages the QtCore QML module used by built-in Recorder settings, runs `windeployqt` against executables and plugins, copies the pinned v143 CRT DLLs, copies device driver packages, and generates launch shortcuts.

The quickStimulus plugin must be scanned explicitly for its dependencies. The QtCore QML import is embedded in application resources and cannot be assumed discoverable from external QML alone. A package can have the main Qt DLLs and still fail to load one built-in application.

KARDi2 is a Qt 6 x64 service with `kardi2-broker-x86.exe` and the vendor `KARDi2.dll` beside it. There is no current Qt 5 island to copy. Its MCS USB package also covers NVX 24/36/52 and is maintained centrally, not copied from a retired service tree.

## Device driver packages

[Package index](../../src/runtime-content/driver/README.md) maps hardware to the supplied drivers. The common [installer](../../src/scripts/install-device-driver.bat) runs PnPUtil on adjacent INFs or the original adjacent `setup.exe`. It propagates failures and restart-required status without forcing a reboot. There is no recursive install-all entry point: Neurosoft WinUSB and EzUSB have overlapping device IDs and different service requirements.

The build's `stage_device_drivers` target refreshes packages independently of service linking. CMake's `DeviceDrivers` install component can assemble only these files. [copy-driver-packages.ps1](../../src/scripts/copy-driver-packages.ps1) supplies the identical installer to each folder and preserves unrelated destination content. Migrating an older layout requires separately archiving the retired `driver/movicom/drivers`, `Install-driver.cmd` and `SHA256SUMS.txt`; normal deployment never deletes operator content.

Package READMEs contain only update date, version, device/architecture compatibility, essential installation constraints and vendor reference links. Keep vendor architecture directories and signed files unchanged. Checksums, machine inventory and test evidence belong in dated history/evidence, not in the distribution's driver folders. NI-DAQmx is supplied as its vendor online installer, not an incomplete collection of kernel files.

## Runtime boundaries to preserve

The Neurosoft SDKs contain same-named unsigned assemblies with different bytes. Keep them in their private directories. Neuron-Spectrum's native IPP runtime has a different loading mechanism and stays in the native DLL search path. Do not flatten private SDK folders to simplify packaging.

The embedded Python DLL, standard-library archive and native packages must be a compatible bundled set. [Python engine CMake](../../src/scriptEngines/python/CMakeLists.txt) deliberately stages the private runtime instead of copying the developer installation's Python DLL. Preserve that pairing when updating runtime content.

The package carries its Qt/CRT runtime, but some hardware still requires Windows/vendor driver installation, NI-DAQmx runtime/device configuration, or .NET support. Use the component references in [source map](../architecture/source-map.md); do not describe the package as sufficient for every device on an otherwise empty PC.

`env.bat` establishes the package's Qt/plugin/Python search paths and content overrides. Root/content resolution also works from executable location; see [framework](../architecture/framework.md#content-paths-and-recording). Run cross-version comparisons in separate process environments to avoid mixing Qt 5/Qt 6 DLL paths. Shortcuts contain absolute paths: after moving a package, rerun its `tools/make-launcher-shortcuts.ps1 -Root <new-root>`.

## Verify the candidate

Review the script's scope before running it. Existing checks include:

- [validate-quickstimulus-builtins.ps1](../../src/scripts/validate-quickstimulus-builtins.ps1): starts the three built-in applications under a private-runtime search path; accepts `-Distribution`.
- [validate-dist-qt6.ps1](../../src/scripts/validate-dist-qt6.ps1): checks a package file inventory, starts NVX and Configurator, inspects loaded/runtime behavior and logs; accepts `-Distribution`. It force-stops its test processes during cleanup, so use it only when the launched amplifier process remains idle and the rig is not acquiring.
- [verify-daqmx-fieldtrip-package.py](../../src/scripts/verify-daqmx-fieldtrip-package.py): component-specific package checks; inspect its arguments and prerequisites.
- [validate-qt5-interop.ps1](../../src/scripts/validate-qt5-interop.ps1): deliberate mixed-version check, requiring a real comparator package. It is not required for every local edit.
- [capture-parameter-column.ps1](../../src/scripts/capture-parameter-column.ps1): starts services and captures the narrow-panel UI; select a small service subset with its `-Only` argument. It is an active UI harness, not a static file check.

Pass the candidate path, rather than relying on a script's live-package default. Some harnesses write evidence under `src/docs/qa`; inspect their output settings and preserve meaningful results under the owning task/report. A successful startup check does not verify hardware acquisition, all launchers, or every parameter combination. [Testing](test.md) explains evidence scope and cleanup.

Historical package provenance and earlier toolchain/layout decisions are in [deployment comparison history](../history/migrations/deployed-vs-repo.md) and [build history](../history/migrations/and-distro.md). Current packaging gaps belong in [issues](../issues/README.md).
