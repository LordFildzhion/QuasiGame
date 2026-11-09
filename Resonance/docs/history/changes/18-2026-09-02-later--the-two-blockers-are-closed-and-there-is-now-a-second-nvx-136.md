# 2026-09-02 (later) — the two blockers are closed, and there is now a second NVX-136

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-02-later--the-two-blockers-are-closed-and-there-is-now-a-second-nvx-136"></a>

### 2026-09-02 (later) — the two blockers are closed, and there is now a second NVX-136

Both regressions that held `R:\dist` back were backported, and the package was rebuilt (241/241
targets, zero errors), retested (**25/25 enabled CTests**, four hardware/external disabled),
redeployed and revalidated. Evidence and the marker table:
[arch_qt6-work-list.md §1](../migrations/qt6-work-list.md).

| | |
|---|---|
| `nvx136` | resynchronised **wholesale** from `R:\src_Qt5`. Now byte-identical to the Qt 5 module apart from `find_package(Qt6 …)`, the location-independent `.bat`, and the Qt-5-only `tracer/`. The falsified converter power-down is gone; `cold_start_pause_ms`, the legacy pre-start sequence and the probe-based Rescan are back |
| `neuroMS` | **merged, not replaced** — the Qt 5 `standby` state, its `disconnect` transition, `enteredOperatingState()` and the `NMS_GetCapabilities` failure guard, plus the Qt 6-only paired-pulse handshake fix re-applied on top. The latent mode mismatch in that fix was resolved at the same time |
| `nvx136_2021` | **new.** A second NVX-136 service from the 2021 driver and the 2021 vendor SDK, in its own `bin\nvx136_2021\` |
| `.ced` loading | **fixed** — see below |

⚠ **What is still owed is the rig.** No Qt 6 build has ever driven a physical amplifier or
stimulator. The first session with any device is a bring-up: keep `R:\dist_Qt5\msvc64` alongside.

<a id="history-ced-files-did-not-load--reported-from-the-field-fixed-the-same-day"></a>

### `.ced` files did not load — reported from the field, fixed the same day

Electrode layouts silently never reached the amplifier. Neither nvx136 nor the CED parser was
responsible: the shared `Resonance__Parameters__File.qml` read the chosen file with
`XMLHttpRequest`, and **Qt 6 refuses GET on a local file** — by never advancing the request to
DONE, so the handler never ran. The filename appeared beside the button and the parameter stayed
empty. Same root cause as the parameter Save/Load repair, in a control that repair did not cover.

Replaced with checked C++ (`ParameterFile::read()` → `ResonanceApp.readFileContents()`), which
reports open/read errors, refuses a non-local URL and an empty file by name, and returns the value
already encoded the way `File::setJson()` expects. The QML now shows the error instead of failing
silently. Eight new tests, including one that crosses the real QML-to-C++ boundary against a shipped
montage. Measured on the packaged build: `CED_XHR_REACHED_DONE=false`, `CED_CPP_OK=true`.
⚠ `XMLHttpRequest` was this tree's habitual way to touch a file from QML and Qt 6 has now broken it
twice — worth a sweep.

<a id="history-two-build-scripts-could-never-have-run-from-a-clean-shell"></a>

### Two build scripts could never have run from a clean shell

`build-qt6.ps1`, `build-kardi2-x32.ps1` and `deploy-qt6.ps1` all set `$ErrorActionPreference =
'Stop'` and then call native tools guarded by explicit `$LASTEXITCODE` checks. In Windows
PowerShell 5.1 that combination turns **any** line a native tool writes to stderr into a
terminating error — and Conan 2 writes its whole progress log there, so the build died before
compiling anything with `conan.exe :` and no message. Separately, `vcvarsall` invokes `vswhere.exe`
by bare name and the VS Installer directory is on no machine PATH here (neither HKLM nor HKCU), so
it printed an error, succeeded anyway, and killed the script. Both fixed: the Installer directory is
prepended to PATH, and the native-tool sections decide on the exit code.

---

