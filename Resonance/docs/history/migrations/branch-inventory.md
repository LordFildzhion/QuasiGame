# Branch inventory — `gitea.atedgeof.net/bcilab/Resonance` — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../architecture/source-map.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-branch-inventory--giteaatedgeofnetbcilabresonance"></a>


Surveyed 2026-08-11. All 17 branches checked out as git **worktrees** under
`R:\src_git_branches\<branch_with_underscores>\` — separate folders, one shared object store, then
`R:\src\.git` (no re-download, ~280 MB per tree avoided).

⚠ **The repository moved on 2026-09-02.** The only Resonance git history now lives in
`R:\src_Qt5\.git`, inside the **Qt 5 comparator** tree, and the 16 worktrees under
`R:\src_git_branches\` were repointed to it — each one's `.git` file reads
`gitdir: R:/src_Qt5/.git/worktrees/<name>`, and `git worktree list` from `R:\src_Qt5` shows all
sixteen beside `R:\src_Qt5` itself, checked 2026-09-02. (The seventeenth directory there,
`feature-conan2\`, is a plain copy with no `.git` and is not a worktree.) **`R:\src`, the live Qt 6
tree, is not under version control at all**: it carries a `.gitignore` and no `.git`, so the old
`git -C R:/src …` invocations now fail with *"not a git repository"*. See
[qt5-to-qt6-transition.md](qt5-to-qt6-transition.md).

```bash
git -C R:/src_Qt5 worktree list          # show them
git -C R:/src_Qt5 worktree remove <path> # drop one
```

---


<a id="history-the-short-version"></a>

## The short version

**`feature/conan2` is the tip of everything.** Ten of the sixteen other branches are fully
merged into it (0 commits ahead). Of the six that diverge, three collapse into one Qt6 line and
one contributes nothing.

⚠ **No longer the tip.** `feature/services-and-isolation` — created after this survey, on the
remote, its 52 unique commits running 2026-08-17 to 2026-08-26 — is **52 commits ahead of
`feature/conan2` and 0 behind**, and it is the branch the Qt 6 tree was snapshotted from. It is the
tip of the Qt 5 comparator today, and what `R:\src_Qt5` itself has checked out. The 2022 Qt6 line
below is *not* the Qt 6 tree's ancestry; see **Since the survey** at the end.

⚠ Two smaller drifts from the survey, both checked 2026-09-02. The remote carries **18** branches
now, not 17. And `origin/feature/conan2` has itself moved on — from `1185960` (2025-07-05) to
`2714246` *"Add forgotten HDF updates"* (2026-08-17, tz-lom) — one commit the local
`feature/conan2` ref does not have. Every ahead/behind figure below is still measured against that
local ref, as it was in August; `2714246` is already contained in `feature/services-and-isolation`,
so no count changes.

**Only four independent bodies of work exist outside `feature/conan2`:**

| | Branch | Unique commits | Date | Worth anything? |
|---|---|---|---|---|
| 1 | `feature/cmake-qt6` | 5 | 2022-06-11 | **Yes** — the Qt6 port, and the only place with MSVC conan profiles |
| 2 | `feature/new-parameter-display` | 5 | 2018-07-05 | Probably not — 2018 QML parameter UI, superseded |
| 3 | `feature/pythonEngine` | 3 | 2018-01-18 | No — original in-repo engine, replaced by the submodule |
| 4 | `feature/kardi2n` | 1 | 2021-02-23 | No — a merge commit only |

`feature/update-dependencies-versions` ⊂ `feature/try-to-jump-to-qt6` ⊂ `feature/cmake-qt6`,
verified with `git merge-base --is-ancestor`. Only the last one needs keeping.

---


<a id="history-full-table"></a>

## Full table

Ahead/behind are relative to `feature/conan2`.

| Branch | Last commit | Author | Ahead | Behind | What it is |
|---|---|---|---|---|---|
| **`feature/conan2`** | **2025-07-05** | tz-lom | — | — | **Current mainline.** CMake + Conan 2. Everything below is merged into it or older. |
| `feature/move_to_cmake` | 2023-12-19 | tz-lom | 0 | 12 | The CMake port itself. Fully absorbed. Its python-engine pointer is the *clean* one — see below. |
| `feature/cmake-qt6` | 2022-06-11 | tz-lom | 5 | 30 | Qt6 migration, furthest along. *"Everything except quickStimulus is Qt6"*, then *"Some progress (far from acceptable)"*. Conan 2 + `qtbase/6.2.2@qt/everywhere`. |
| `develop` | 2022-02-25 | tz-lom | 0 | 35 | Old mainline. Last commit literally *"completely-new-absolutely-broken-resonance"*. Dead. |
| `feature/try-to-jump-to-qt6` | 2022-02-13 | tz-lom | 2 | 36 | First Qt6 attempt. **Contains the MSVC 2019 conan profiles.** Subset of `cmake-qt6`. |
| `feature/update-dependencies-versions` | 2021-12-27 | logovo | 1 | 36 | One commit bumping `conanfile.txt`. Subset of both Qt6 branches. |
| `feature/reliable-ced-parser` | 2021-08-21 | Nuzhdin Yury | 0 | 54 | CED montage parser hardening. Merged — this is today's `internal/ParseCED.cpp`. |
| `feature/new-discovery-mechanism` | 2021-05-16 | tz-lom | 0 | 93 | The `StreamPool`/discovery rework. Merged. |
| `feature/kardi2n` | 2021-02-23 | tz-lom | 1 | 141 | KARDi2 driver. Its one unique commit is a merge that only touches `nvx136`. Nothing of value. |
| `master` | 2020-05-25 | Nuzhdin Yury | 0 | 210 | Stale by ~5 years. **Not the mainline** despite the name. |
| `feature/hdf5` | 2020-04-26 | Nuzhdin Yury | 0 | 213 | HDF5 recording. Merged — today's `internal/HDFRecorder.cpp`. |
| `feature/openbci_v2` | 2019-11-30 | Nuzhdin Yury | 0 | 248 | OpenBCI driver v2. Merged, but the `openBCI` module is dead in conan2 (broken include, no CMakeLists). |
| `feature/new-parameter-display` | 2018-07-05 | Nuzhdin Yury | 5 | 275 | QML parameter renderer rework. Never merged; the QML has moved on a lot since. |
| `feature/pythonEngine` | 2018-01-18 | Nuzhdin Yury | 3 | 329 | Original `pythonengine.cpp` **inside** the Resonance repo (282 lines). Superseded by the `Resonance-engine-python` submodule. |
| `feature/C_engine_protocol` | 2018-01-12 | tz-lom | 0 | 351 | The C ABI for script engines — today's `scriptengineinterface.hpp`. Merged. |
| `feature/Fieldtrip_support` | 2018-01-11 | tz-lom | 0 | 355 | FieldTrip buffer client. Merged. |
| `feature/scriptEngine` | 2017-09-07 | tz-lom | 0 | 373 | Original script-engine host (`SPEED`). Merged. |

Files on other branches that no longer exist on `conan2` are all removals, not lost work:
`eyegamesDll/` (renamed `ResonanceForeignDriver`), `actiChamp/actichampconfig.ui`,
`quickStimulus/import/Resonance/qmldir.bak`, and `installer/ResonanceInstaller.exe` — a 19 MB
**prebuilt binary** committed to the repo, no source. Good riddance.

---


<a id="history-what-the-branches-answered"></a>

## What the branches answered

<a id="history--the-msvc-question--featuretry-to-jump-to-qt6-has-the-profiles"></a>

### ✅ The MSVC question — `feature/try-to-jump-to-qt6` has the profiles

Two conan profiles exist nowhere else in the repo: `windows-x86_64-msvc2019_64` and
`windows-x86_64-msvc2019_64-debug`.

```ini
[settings]
    os=Windows
    arch=x86_64
    compiler=msvc
    compiler.version=193      # VS 2022 (17.x) toolset
    compiler.cppstd=17
    compiler.runtime=dynamic
    compiler.runtime_type=Release
    build_type=RelWithDebInfo
[env]
CONAN_CMAKE_GENERATOR=Ninja
```

Note the mismatch: the filename says **msvc2019** but `compiler.version=193` is the **VS 2022**
toolset. Also `cppstd=17`, not 20 — more evidence that the C++20 in the current
`CMakeLists.txt` is aspirational (see [known-issues.md §7](../incidents/README.md)).

These were written for a **Qt 6 built from source via Conan** (`qtbase/6.2.2@qt/everywhere`),
which is a different world from the prebuilt Qt 5.15.2 kit the shipped distro uses. So they
document a toolchain intent, not the recipe that produced `distro-dual\msvc`.

<a id="history--the-pythonengine-question--effectively-answered"></a>

### ✅ The pythonEngine question — effectively answered

The `stdout` bug was **introduced by the very commit `feature/conan2` pins**:

| Engine commit | Date | Pinned by | Has the `stdout` bug? |
|---|---|---|---|
| `642bfc6` *"Upgrade error message"* | 2023-12-19 | `feature/move_to_cmake` | **no** — compiles |
| `e2eed71` *"Support Conan2"* | 2023-12-22 | **`feature/conan2`** | **yes** — cannot compile |

`Resonance-engine-python` has **only a `master` branch** and `e2eed71` is its tip, so there is
no other commit the shipped DLL could have come from. That same commit also introduced the
`install_files_with_prefix()` call which Resonance later deleted
([known-issues.md §2](../incidents/README.md)). It looks like *"Support Conan2"* was written and pushed
without ever being compiled.

But the shipped DLL is real: `pythonEngine.dll` has a **PE link timestamp of 2024-10-05 23:02**,
the same minute as `Resonance.dll` and `SPEED.exe` in that tree. So it was genuinely built in
that session, from source that compiled.

**Conclusion: the Oct 2024 build was made from a working tree carrying local, uncommitted
changes.** That is the same pattern as `quickStimulus/CMakeLists.txt` referencing
`Head.qml.bak`, a file that `git log --all` shows was *never committed* — the author's working
tree contains state that was never pushed.

This reframes what to ask: not *"which commit?"* (there isn't one) but *"do you have
uncommitted local changes, and what else is in them?"*

---


<a id="history-maintenance-suggestion"></a>

## Maintenance suggestion

Thirteen of these branches are fully merged and 4–8 years stale. Deleting them would make the
repo legible. That is the owner's call, not something to do unasked.

⚠ **The 2026-08-11 advice that `feature/cmake-qt6` was "the only one worth preserving as a starting
point for a Qt6 effort" is spent.** The Qt 6 port happened in 2026 from a different branch by a
different route, and `feature/cmake-qt6` contributed nothing to it. It is archaeology like the rest.

---


<a id="history-since-the-survey--the-qt-6-trees-actual-provenance"></a>

## Since the survey — the Qt 6 tree's actual provenance

⚠ **None of the three 2022 Qt6 branches is an ancestor of the shipped Qt 6 tree.**
`feature/cmake-qt6`, `feature/try-to-jump-to-qt6` and `feature/update-dependencies-versions` were
abandoned in 2022 and never revived. Anyone reconstructing where `R:\src` came from should start
here instead.

| | |
|---|---|
| Snapshotted | **2026-08-27**, from what was then `R:\src` and is now `R:\src_Qt5` |
| Source commit | `fae69c34d48c3183d6eecaea1370d8e5633fd46b` |
| Source branch | `feature/services-and-isolation` — created after this survey, present on the remote, 52 ahead of `feature/conan2` and 0 behind |
| Later copies | **2026-08-28** — `nvx136`, `neuroMS`, `pythonEngine`, `ResonanceForeignDriver`, `feetStim`, `arduinoTTL`, `tepSoundService`; **2026-08-29** — `SPEED`, `neuronSpectrum`, `mStim`, `eStim`, `KARDi2`, `actiChamp`. Taken from the *working tree*, not from a commit, so the operator's uncommitted driver work crossed with them. |
| Destination | `R:\src`, with the copied submodule Git indirection removed so the tree has no hidden source dependency on the Qt 5 one |

Three consequences worth stating plainly:

* **The live tree is unversioned.** `R:\src` has no `.git`. Every Qt 6 change made since 2026-08-27
  exists in exactly one place, on a RAM-backed drive. `R:\src_Qt5` separately carries 14 uncommitted
  changes of its own, so neither tree is fully captured by the remote.
* **The 2026 port made the opposite dependency choice from the 2022 attempts,** and that is most of
  why it finished. The observation above — that the 2022 profiles targeted a **Qt 6 built from
  source via Conan** (`qtbase/6.2.2@qt/everywhere`) — is exactly the difference. `R:\src` builds
  against a **prebuilt Qt 6.11.2 kit** at `C:\Qt515\6.11.2\msvc2022_64`; its `conanfile.txt` asks
  Conan for `hdf5`, `boost` (header-only), `iir1` and `gtest` and for no part of Qt at all.
* **The `cppstd=17` question is closed.** The single Qt 6 profile is
  `R:\src\profiles\msvc-v143-release` — `compiler.version=194`, `compiler.cppstd=20` — and the
  tree's `CMAKE_CXX_STANDARD 20` is now real rather than aspirational everywhere except the KARDi2
  x86 island, which stays MinGW 8.1 / `CMAKE_CXX_STANDARD 17`
  (`R:\src\KARDi2\qt5-island\CMakeLists.txt:5`). The 2022 profiles' `cppstd=17` was a symptom of the
  source-built-Qt route, not of the language level the code needed.
