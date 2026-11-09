# 2026-08-17 — `R:\dist` rebuilt from scratch; msvc64 accepted on hardware

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-17--rdist-rebuilt-from-scratch-msvc64-accepted-on-hardware"></a>

### 2026-08-17 — `R:\dist` rebuilt from scratch; msvc64 accepted on hardware

The previous distribution tree is **`R:\dist_2026aug`**, untouched apart from the rename.
`R:\dist` is new and currently holds **only `msvc64`** — `mingw32`, `mingw64`, `kardi2_x32` and
`msvc64-nvx2025` were not rebuilt and live on only in the old tree.

**Build: 430/430 targets, zero errors**, MSVC **19.29.30159 (v142)** as required, Ninja, Release,
`-j6`. Conan resolved all six dependencies from cache. The fragile `stdout` → `stdoutHook`
submodule patch ([known-issues §2e](../incidents/README.md)) **survived** and was checked before building.
Assembled tree: **1647 files, 417 MB**.

| §7 check | Result |
|---|---|
| Imports (7.1) | 74 root binaries, **120 modules walked, 3 unresolved** — `MSVCR90` (EyeLink), `nicaiu` (DAQmx), `python312` (pythonEngine): the same three external deps as the 2024 reference |
| Packaging | `qwindows.dll` present; `data\` at root; no `bin\data` or `qt\data`; `env.bat` sets `%CD%\data` with no build path leaked |
| Dynamic (7.2) | generator + configurator start, UDP 13370/13371 bound |
| End-to-end (7.3) | `MainWindowTitle = Configurator`, **2 established loopback TCP pairs** to the generator |

**Carried forward from the old tree** (user configuration, not build output —
[deployed-vs-repo.md](../migrations/deployed-vs-repo.md)): `bin\{arduinoTTL,eStim,feetStim,mStim}.ini`,
`bin\emulator.exe` + `bin\FrameLib\`, and the nine `params\ns65-*.json` sets. `bin\Resonance\**`
needed nothing — source and deployment were already byte-identical.

**Module acceptance, all on the new tree:**

| Module | Result |
|---|---|
| **Select / combo boxes** | applies to a live service (`msgFormat` text→json), value held across a description re-broadcast, no index-0 write. `viewer_layout` now defaults to **Side by side (1x2)** |
| **recorderService** | `idle → recording → idle`; 1249 blocks / 3747 rows × 3 ch, **0 NaN**, std 7.07, inter-block **12.000 ms with zero jitter**. ⭐ `chunk=(250,3) compression=None` — the 2025 chunking fix is still in source, not regressed again |
| **playbackService + viewer** | `R:\tests\source-recordings\11_TMS_48MSO_heel_+60.hdf5`, 3.8 GB, **73 ch @ 25 kHz** + 2 message streams: scan → `armed` (published, `dataSoFar=0`) → `playing`, **73/73 lanes valid, none all-zero**, decimation ÷5, repaint **5.25 ms** |
| **NVX-52, live** | `init → running → init`; 33 ch @ 1 kHz, measured **1004.41 Hz**, 20 009 rows, 5.6 MB recorded, repaint 0.63 ms. Device left healthy (`stop` then `!terminate`, never killed) |

⚠ **The NVX recording is 32/33 channels fully NaN — only the Trigger is finite.** This is the
bench, not the build: **the old `R:\dist_2026aug` driver reproduces it exactly** (32/33 NaN,
1003.72 Hz) in a control run on the same hardware minutes later. Nothing is connected to the
electrode inputs. The 2026-08-14 campaign's finite set (Ch 1–20, 29) was measured with a subject
attached. **Re-run with electrodes connected before treating this as an acceptance of signal
quality** — everything proven here is transport, lifecycle and rate, not analogue front end.

Evidence: `R:\dist\msvc64\data\{newbuild-rec-0001,newbuild-nvx-0001,control-oldnvx-01}.h5`.
Harnesses: `R:\config\newbuild_{recorder,playback_big,nvx}_check.qml`.

⚠ Not exercised on this build: every module with no hardware attached
(`neuronSpectrum`, `neuroMS`, `eStim`, `feetStim`, `mStim`, `arduinoTTL`, `KARDi2`, `tepService`,
`stimulusService`, `SPEED`) — they compile and install, nothing more.

