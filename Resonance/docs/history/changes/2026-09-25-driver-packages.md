# 2026-09-25 — unified device driver packages

Reorganized `R:/dist/driver` into eight package folders with a single shared `Install.bat` implementation. Each installer sits beside its INFs/CATs or the original vendor `setup.exe`; only original architecture subdirectories remain. Removed the extra Movicom `drivers` level and distributed SHA256SUMS file by archiving them outside `dist`. READMEs are short dated references with versions, essential constraints and official links; machine-specific provenance and checks stay here.

## Inputs and coverage

- `kardi2`: unchanged MCS 3.0.0.0 package dated 2013-10-10 from the KARDi2 SDK; also covers NVX 24/36/52. The 2025 NVX SDK contains an older 2010 build, so it is not duplicated.
- `nvx136`: unchanged Media Converter 3.4.5.0 package from the 2025 SDK, covering USB PIDs 0123/0124/0126. The older source-local INF covered only 0123.
- `movicom`: unchanged FTDI 2.12.36.20 x64 payload, flattened from its prior wrapper. License text remains in the signed INFs.
- `neuronSpectrum`: Neurosoft WinUSB 2.0.0.9 INF/catalog from DriverStore; Windows supplies WinUSB itself.
- `neurosoft-ezusb`: original Neuro-MS SDK EzUSB 1.1.6.13 package for eStim/Neuro-MS. Its ID overlap with WinUSB is explicit; no install-all script is provided.
- `ch340`: WCH 3.9.2024.09 x64 DriverStore payload, excluding generated PNF. The earlier Arduino rig evidence identifies VID 1A86/PID 7523.
- `arduino`: original Arduino, Arduino.org and Genuino INF/catalog pairs, using Windows USB serial; no generated PNF.
- `daqmx`: signed NI-DAQmx 26.5 online installer, copied unchanged as `setup.exe`. The local NI cache contains individual dependency packages, not a complete portable installation medium; no partial kernel-driver substitute is presented as DAQmx.

The official actiCHamp driver endpoint redirected to vendor login. No local package was available; the package index links the official driver page. No account was created and no vendor driver was installed or replaced on Windows.

## Ownership and deployment

`src/runtime-content/driver` now owns the packages. `scripts/install-device-driver.bat` owns the common installer. `scripts/copy-driver-packages.ps1` stages them without deleting operator content; the build's `stage_device_drivers` target and CMake `DeviceDrivers` component make package-only assembly reproducible. The deploy/validation scripts no longer depend on the retired KARDi2 tree or nested Movicom files.

The Movicom source diagnostic points to the new installer and its guide was condensed. The service was already running in the operator session, so its executable was not replaced; only this diagnostic-path text change is staged for a later normal service deployment. Acquisition code is unchanged. The running service's existing missing-driver message names the previous installer path; the packaged README and driver index name `Install.bat`.

Existing driver files and the service/guide are preserved under `src/_test-output/driver-packaging-20260925/backup`; retired wrappers/source payloads are in `retired`. A combined copy/delete command was rejected by automatic approval review without a specific reason. The completed migration used separately verified copying and reversible archival instead of deletion.

## Verification

Evidence root: `R:/src/_test-output/driver-packaging-20260925`.

- Build succeeded (`build.log`); no acquisition behavior changed.
- All 35 packaged non-catalog vendor payload files matched their signed catalogs or vendor executable signature (`payload-verification.json`). Catalog signature checks are recorded separately.
- Eight isolated installer cases passed, using a stub executable: INF/vendor success, restart-required propagation, error propagation, paths with spaces, missing payload and ARM rejection. These tests made no Windows driver installation calls (`installer-results.json`).
- The CMake `DeviceDrivers` component assembled an independent candidate (`install-component.log`). All eight packages / 62 files match between source, candidate, staging and distribution; the installer is identical in every folder. Ten deployed catalog signatures are valid. Equality, installer identity, portable README links and flat-layout checks are recorded in `package-layout-verification.json` and `deployed-signatures.json`.

Signature/content checks establish package integrity; they do not claim a fresh-PC installation or hardware test for every package.
