# 2026-09-02 — Qt 6 is the default; the trees swapped names

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-02--qt-6-is-the-default-the-trees-swapped-names"></a>

### 2026-09-02 — Qt 6 is the default; the trees swapped names

The Qt 6.11.2 port that ran from 2026-08-27 was promoted. `R:\srcQt6` → **`R:\src`**,
`R:\dist_Qt6` → **`R:\dist`**; the Qt 5 tree and distribution became **`R:\src_Qt5`** and
**`R:\dist_Qt5`**. Full record: **[build_qt5-to-qt6-transition.md](../migrations/qt5-to-qt6-transition.md)**.

| | |
|---|---|
| Toolchain | Qt **6.11.2** `msvc2022_64`, MSVC **v143 14.44**, Windows SDK 10.0.26100, C++20, CMake 3.30.5 + Ninja 1.12.1 + Conan 2 |
| Ported | **21 executable files** in `dist\bin` (20 applications plus the KARDi2 broker), 28 launchers; COMport and latencyProbe added 2026-09-04 — 25 executables by 2026-09-06 |
| Not ported | ~~`stimulusService`, `DAQmx`, `fieldtrip`~~ — all three ported since: DAQmx and fieldtrip on 2026-09-05, stimulusService on 2026-09-06 |
| Retired | `tepService` is replaced by `tepSoundService`. `eStim` fully replaces the legacy MioStim service (2020), which was limited to x32 architecture. |
| Architecture | **x64 throughout.** The only 32-bit binary in the distribution is `bin\kardi2-broker-x86.exe`, a 164 KiB helper for the PE32-only KARDi2 vendor DLL — it links `/MT` and imports only `KERNEL32.dll`. The Qt 5.15/MinGW island it replaced on 2026-09-02 is gone, and with it the last Qt 5 DLL in `R:\dist` |
| Interop | verified both directions; a Qt 6 Configurator drives Qt 5 services and vice versa. Never in one process |
| git | **only `R:\src_Qt5` has a repository.** `R:\src` has none |

<a id="history--rdist-is-not-yet-cleared-for-a-laboratory-session"></a>

### ⚠ `R:\dist` is NOT yet cleared for a laboratory session

Two confirmed regressions, both because `R:\src_Qt5` kept receiving rig-driven fixes after the
snapshot was taken. Both need a rebuild and redeploy. Full detail and the fix in
[arch_qt6-work-list.md §1](../migrations/qt6-work-list.md).

* **NVX-136 cold start.** The Qt 6 driver still calls `NVXSelectDevice` and cures failures with a
  converter power-down — two of the **three hypotheses the rig falsified** on 2026-08-26/28. It also
  lacks the operator-settable `cold_start_pause_ms` the next session needs in order to sweep the
  pause. Confirmed in the binaries: `R:\dist\bin\nvx136.exe` contains `"converter power-cycle"` and
  none of `"pre-start sequence"` / `"NVXSelectDevice"` / `"cold_start_pause_ms"`.
* **Neuro-MS `standby`.** The Qt 6 service is missing the `standby` state and the
  `enteredOperatingState()` signal, so a stimulator switched off at its own front panel lands in
  `ready` — **which still offers Charge** — and never returns when switched back on. That is the
  exact field complaint of 2026-08-26 that `standby` was created to answer. The Qt 6 tree does carry
  a real paired-pulse handshake fix the Qt 5 tree lacks, so the two must be **merged**, not chosen
  between.

**Until both land, a session with an NVX-136 or a Neuro-MS runs from `R:\dist_Qt5\msvc64`.**
Everything else in `R:\dist` is at least as good as its Qt 5 predecessor.

<a id="history-what-changed-behaviourally"></a>

### What changed behaviourally

* ⚠ **HDF5 recordings are one row shorter.** The Qt 5 recorder created every numeric dataset at
  extent 1 and extended to `offset + samples + 1`, so every Qt 5 file ends with an all-zero row that
  was never written — a fabricated falling edge on a trigger channel, a reset on a counter. Qt 6
  writes exactly the sum of the block sample counts. **Any analysis that dropped the last row to
  compensate now discards one real sample per stream.** The fix is *not* back-ported to `R:\src_Qt5`.
* **The whole wire path is byte-identical** — discovery, JSON protocol, stream announcements, TCP
  framing, parameter serialisation, THIR. That is why interop works. Only five source files in
  `Core/Resonance` differ from the Qt 5 core at all.
* **Configurator parameter Save/Load was rewritten in C++** with an atomic `QSaveFile` replacement
  and strict validation — Qt 6 refuses QML `XMLHttpRequest` local-file writes, so the old path
  silently did nothing. `R:\src_Qt5` still has the unchecked version.
* **Controls 1 → Controls 2 wholesale**, a Qt 6 `TreeView` service tree, `Qt.labs.settings` →
  `QtCore.Settings`, and a forced light Fusion palette so the UI no longer follows Windows dark mode.
* **`QAbstractVideoSurface` → `QVideoSink`** in tepSound, with the FFmpeg backend pinned. ⚠ The cue
  **onset contract** is the part not yet proven equivalent —
  [arch_qt6-work-list.md §2](../migrations/qt6-work-list.md).

<a id="history-deployment-content-restored-2026-09-02"></a>

### Deployment content restored 2026-09-02

`R:\dist` had never been provisioned with operator content the Qt 5 distro ships. Copied across:
the four service `.ini` files (⚠ without `feetStim.ini` the compiled default opens **COM4 and drives
the real solenoid array** instead of the rig's emulator configuration), `bin\FrameLib\Frame1`
(feetStim's stimulation pattern — it exists in no source tree), sixteen `params\*.json` presets
including the validated 25 kHz / 70-channel NVX-136 set and the nine `ns65-*` Neuron-Spectrum sets,
`montages\mumeg_mks64.ced`, and the `stimuli\` tree.

<a id="history-environment--what-is-installed-now"></a>

### Environment — what is installed now

| | |
|---|---|
| Qt 6.11.2 | `C:\Qt515\6.11.2\msvc2022_64` — the default kit |
| Qt 5.15.2 | `C:\Qt515\5.15.2\{mingw81_32, mingw81_64, msvc2019_64}` — comparator, plus `mingw81_32` for the KARDi2 island |
| MSVC | VS 2026 Build Tools; **v143 14.44** for Qt 6, **v142** for Qt 5 |
| Windows SDK | 10.0.26100 |
| Python | 3.12 for the build; a private 3.12.1 + NumPy 1.26.2 + SciPy 1.11.4 runtime ships inside `R:\dist\python` |

<a id="history-open-and-not-just-the-two-regressions"></a>

### Open, and not just the two regressions

`R:\src` is **not under version control**; `R:\src_Qt5` has 14 uncommitted changes that are the
only record of what the snapshot was taken against. `Core/Resonance`'s and quickStimulus's unit-test
corpora are **built but never registered with CTest**, so the shared framework has zero coverage in
the runs quoted as the port's evidence. Both CMake caches under `R:\src` are bound to the old path
and must be deleted before the next configure. Nine further items, including eight back-ports the
Qt 5 comparator still needs, are in [arch_qt6-work-list.md](../migrations/qt6-work-list.md).

---

