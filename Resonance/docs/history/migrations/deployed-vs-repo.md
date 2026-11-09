# The live distribution vs. the repository — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../how-to/deploy.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-the-live-distribution-vs-the-repository"></a>


Analysis of `R:\dist_legacy\dist2025` — the tree actually in daily use — done 2026-08-11.
**Read this before replacing anything on a rig with a fresh build.**

⚠ **Two generations behind the current build line; still current as *archaeology*.** `dist2025` is
the deployment installed at work. The tree the lab runs today is `R:\dist_Qt5\msvc64` — what was
`R:\dist\msvc64` until the 2026-09-02 rename — and since 2026-09-02 the default distribution is
`R:\dist`, built against Qt 6.11.2; see
[qt5-to-qt6-transition.md](qt5-to-qt6-transition.md). Nothing below is rewritten for that and
nothing below needs to be: this is a forensic reading of one specific tree and its findings about
that tree stay true. What changed is which lessons transfer, and that is flagged where it arises.

⚠ **No Qt 6 build has yet driven a physical device,** so this is not the moment to move a rig
onto it wholesale — though the two regressions that blocked it were closed on 2026-09-02. Two regressions ride in the Qt 6 build — the NVX-136 cold-start ladder is a
generation behind the rig work, and the Neuro-MS state machine has no `standby` state. A session
with an NVX-136 or a Neuro-MS runs from `R:\dist_Qt5\msvc64` until both land; see
[qt6-work-list.md](qt6-work-list.md) §1.

---


<a id="history-what-dist2025-is"></a>

## What dist2025 is

**A copy of `distro-dual\msvc` with selective updates.** 21 of its 22 PE binaries are
**byte-identical** (SHA-256) to the 2024-10-05 MSVC tree. So:

* **x64 only, MSVC, Qt 5.15.2.** `qt\bin\Qt5Core.dll` is byte-identical to `distro-dual\msvc`'s.
  No `libgcc`/`libstdc++` anywhere — not a MinGW build.
* **The 32-bit half is not part of daily work.** `distro-dual` has both branches, but what is
  actually used is the x64 tree alone. The historical 32-bit branch matters only for archived
  compatibility checks.

What differs from `distro-dual\msvc`:

| Item | Linked | Note |
|---|---|---|
| `Resonance.dll` | **2025-10-06 23:12** | The only rebuilt Resonance component. 89% of bytes differ from the 2024 build — real code change, not a relink. |
| `nvx136.exe` | 2025-07-05 13:48 | Byte-identical to `distro-dual`'s (that tree got the same update). |
| `nvx136_beforefix.exe` | 2025-06-21 20:09 | Kept-around previous build. |
| `Resonance_dll_prior250710.zip` | — | Contains the 2024-10-05 `Resonance.dll`. The rollback kept when switching in July 2025. |
| `python\` | — | **Embedded CPython 3.12.1** — this is what satisfies `PYTHONHOME` in `env.bat`. Neither `distro-dual` tree has it. |
| `params\`, `impedanceMeasure\`, `mulines\` | — | 25 / 70 / 43 files of experiment configs and two side projects. `impedanceMeasure` is its own git repo (last commit 2021-06-09). |
| ~40 extra `.bat` / `.json` | 2025–2026 | Per-experiment launchers: `TEP_SPEED`, `econoMI`, `PonkSync Trainer`, `impedanceChecker_128`, `nvx136_8Ch_25kHz`, … |

`pythonEngine.dll` is **byte-identical to the 2024-10-05 build** — never rebuilt since.

<a id="history-the-2025-resonancedll-is-explained-by-pushed-source"></a>

### The 2025 `Resonance.dll` is explained by pushed source

It contains the string `"Discovery cycle done"`, added by commit `229d551` (2025-06-21), which
**is** on `feature/conan2`. Export count is unchanged (1412 both). So it is consistent with a
plain MSVC build of the pushed tip `1185960` (2025-07-05), compiled three months later. **No
unpushed C++ is needed to explain it.**

---


<a id="history-binresonance-is-user-editable--carry-it-forward-dont-diff-it"></a>

## `bin/Resonance/**` is user-editable — carry it forward, don't diff it

The QML under `bin/Resonance/` and the `.ced` montages in `bin/Resonance/Bricks/` are **plain
files loaded from disk at runtime**, next to `qmldir` — not baked into a `.qrc`. Users are
expected to edit them per rig: tweak the head display, add electrode montages. So the deployed
copies drift from the repo **by design**, and that drift is not a finding.

In `dist2025` the drift is substantial — `Head.qml` is 28 713 B against 4 784 B in the repo, and
there are four lab montages (`mks64/128/256_standard.ced`, `mks2_emg.ced`) plus
`topomap128_full*.png` and a `Head_old.qml` backup that were never in git. Fine and expected.

**Resolved for the data files (2026-08-15).** The montages and topomap pictures are now in source
at `import/Resonance/Bricks/` and listed in `quickStimulus/CMakeLists.txt`. They are what the rigs
actually run on and what the head map's background parameter points at, so leaving them in
whichever deployment happened to survive was the same trap as the HDF5 fix that shipped only as a
DLL. `Head.qml` itself is *not* carried across — it is superseded, see below.

**The first operational consequence:** when a freshly built tree replaces a working one, copy
`bin/Resonance/` across from the old deployment first, or the rig loses its montages and its
tuned head display. Treat that directory as configuration, not as build output.

⚠ **The second, since 2026-08-18:** `bin/resonance.cfg` is configuration too, and it is what
decides whether the rig talks to anything off the machine. There is none in any distribution on
this drive, and its absence now *selects* `loopback`. A rig that needs `lan` mode carries that
file, and replacing a tree without carrying it forward silently isolates the rig. It is also
per-directory: `<distro>\bin\` and a side tree like `kardi2_x32\bin\` are independent scopes,
so both need it. See [network-isolation.md](network-isolation.md).

⚠ **The third, since 2026-09-02: the carry-forward rule stops at the Qt 5 → Qt 6 boundary, for QML
only.** Moving a rig from `dist_Qt5\msvc64` to `R:\dist` is exactly the "replacing a deployment"
case this section warns about, and it is the one case where copying `bin\Resonance\` across
**breaks the target**. The Qt 6 package's QML was converted to Qt Quick Controls 2: its
`Configurator.qml` opens `import QtQuick` / `import QtQuick.Controls`, versionless, where the Qt 5
copy opens `import QtQuick 2.4` / `import QtQuick.Controls 1.4`. Counted 2026-09-02, **17 of the 75
QML files under `dist_Qt5\msvc64\bin\Resonance\` import Controls 1; only 4 of the 58 under
`dist\bin\Resonance\` do.** Controls 1 does not exist in Qt 6, so a carried-forward
`Configurator.qml` does not load at all.

Those four survivors are unconverted leftovers — each byte-identical to its `dist_Qt5\msvc64` copy —
and they split two and two. `SignalView.qml` and `Configurator_normal.qml` are registered in no
`qmldir`. `Bricks\StimulusSelector.qml` and `Plot\ComboBoxBinding.qml` **are** registered, at
`Bricks\qmldir:4` and `Plot\qmldir:14`. No QML file in the package instantiates either type, so
nothing loads them today, but they are declared types in a shipped Qt 6 package and the first thing
to reference one fails on the import.

**Data files still cross the boundary; QML does not.** The `.ced` montages in `Bricks\` are the same
eight files, byte-identical, in both distributions, and `bin\resonance.cfg` (if a rig has one) and
the per-experiment `.bat`/`.json` launchers carry forward unchanged. For QML, take the new package's
copy and re-apply the rig's edits to it rather than overwriting.

⚠ The **top-level `montages\`** directories differ, and the difference runs the opposite way from the
carry-forward instinct. `dist_Qt5\msvc64\montages\` holds three files, `dist\montages\` nine, and the
Qt 6 set contains all three Qt 5 names, so nothing is missing. But `mks64_standard.ced` is not the
same file: the `R:\dist` copy is 67 lines and carries `EMG1` and `EMG2`, the `dist_Qt5\msvc64` copy
is 65 lines and does not. `mumeg_mks64.ced` — the one the TEP operator procedure names on the command
line — and `mks64_emg2.ced` are byte-identical in both. In `R:\dist` the top-level `montages\` copy
matches `bin\Resonance\Bricks\` byte for byte; in the Qt 5 distro it is the older file. Copying the
Qt 5 `montages\` forward would therefore take two EMG channels back out. Compared 2026-09-02.

**Superseded for the head display (2026-08-15).** The scalp map is now part of the viewer itself
(`Plot/HeadView.qml`, [signal-viewer.md §7b](../components/signal-viewer.md)) and takes electrode positions from
the stream's CED metadata rather than from a file beside the QML. `Bricks/Head.qml` and its
`topomap*.png` backgrounds are no longer what the Configurator draws. The `.ced` montages in
`Bricks/` are still worth carrying forward — they are what gets loaded into a driver's `ced`
parameter — but the per-rig edits to `Head.qml` no longer need preserving.

(This also explains `Head.qml.bak` in `quickStimulus/CMakeLists.txt`
— [known-issues.md §2c](../incidents/README.md): someone editing `Head.qml` in place left a `.bak`
beside it and it got swept into the CMake source list by accident. A stray line, nothing more.)

---


<a id="history-how-distro-dual-was-actually-made--one-evening-cmake-2024-10-05"></a>

## How `distro-dual` was actually made — one evening, CMake, 2024-10-05

PE link timestamps against the commit log reconstruct it exactly:

| Time | Event |
|---|---|
| **23:02:42** | x64 build — `Resonance.dll` **and** `engines\pythonEngine.dll` |
| **23:14:33** | commit `bad97c0` "Support mingw32" — deletes `install_files_with_prefix`, adds the `.bat` launchers |
| **23:22:34** | x86 build — `libResonance.dll`; **ships no `engines\` directory at all** |

Build x64 → make the 32-bit build work → commit → build x86 with the Python engine dropped.
Exactly the sequence re-derived independently on 2026-08-11 (there is no 32-bit CPython, so
`scriptEngines` has to be gated to x64 — [known-issues.md §2b](../incidents/README.md)).

Three consequences:

* **The build system was CMake, not QBS.** The `.bat` launchers `distro-dual` ships are emitted
  by `install_files()`, a CMake function added in that very commit.
* **`install_files_with_prefix` was never the anomaly.** It still existed at 23:02, was deleted
  at 23:14, and the 23:22 build shipped no engines. Nobody has run CMake on the branch since,
  which is why the breakage went unnoticed for two years.
* **Only `stdout` is left unexplained** — the engine pointer has been at `e2eed71` since
  2023-12-22, so the non-compiling commit *was* pinned when `pythonEngine.dll` linked at
  23:02:42. It must have been fixed locally. Practically irrelevant now: the one-line rename is
  the only possible fix, it is applied, and the engine builds and loads with all ten exports.
