# 26. Windows PowerShell 5.1 turns any native-tool stderr into a terminating error

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-26-windows-powershell-51-turns-any-native-tool-stderr-into-a-terminating-error"></a>

### 26. Windows PowerShell 5.1 turns any native-tool stderr into a terminating error

**TRANSFERS UNCHANGED — it is a PowerShell property, not a Qt one.** With
`$ErrorActionPreference = 'Stop'`, Windows PowerShell 5.1 raises a terminating `NativeCommandError`
on **any** line a native command writes to stderr, whether or not the command succeeded. All three
Qt 6 scripts set `'Stop'` and then call native tools guarded by explicit `$LASTEXITCODE` checks —
so the guards were dead and the first stderr line won.

Two ways it actually bit, both on 2026-09-02:

* **Conan 2 writes its entire progress log to stderr.** `build-qt6.ps1` died before compiling
  anything, reporting `conan.exe :` and no message at all.
* **`vcvarsall.bat` invokes `vswhere.exe` by bare name**, and the VS Installer directory is on no
  machine PATH here (neither HKLM nor HKCU). It printed
  `'vswhere.exe' is not recognized as an internal or external command`, fell back, initialised the
  toolset correctly, exited 0 — and killed the script anyway.

⚠ **These scripts could not have run from a clean shell**, which matters for the claim that the
tree is reproducible on another machine. Fixed in `build-qt6.ps1`, `build-kardi2-x32.ps1` and
`deploy-qt6.ps1`: the VS Installer directory is prepended to PATH, and the native-tool sections drop
to `'Continue'` so the exit code decides — which is what the `$LASTEXITCODE` guards were written
to do.
