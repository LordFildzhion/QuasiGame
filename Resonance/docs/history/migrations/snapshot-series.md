# Snapshot archives — `resonance_YYYYMMDD.zip` — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../how-to/snapshot.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-the-numbers-that-justify-the-exclusions"></a>

## The numbers that justify the exclusions

Re-measured 2026-09-02 against the current layout:

* A snapshot taken today carries about **960 MB** of directories — `dist\` 504 MB, `src\` minus its
  six in-tree artefact directories 373 MB, `config\` 79 MB, `docs\` 5 MB. Those are allocated sizes;
  the file bytes a stored zip actually holds total **929 MB**, and that is the figure to compare
  against the series below.
* Those directories are **~811 MB**: `_build` 571, `_test-output` 84, `_stage` 9, `_patches` 2,
  `_dist` 0, `KARDi2\_build-x86` 2, `KARDi2\_build-x64` 3, and 144 MB of retired-island rollback
  copies under `KARDi2\_legacy` (`_retired-builds` 111, `_previous-dist` 33). Keeping them would add three-quarters again to the archive,
  in objects a `cmake` run regenerates — and both CMake caches are bound to the pre-rename path and
  have to be deleted before the next configure anyway.
* `dist\` holds **two `bin.pre-*` copies** (~210 MB), taken by hand before the 2026-09-02 backport
  and defaults work — `deploy-qt6.ps1` itself still takes none, which is its own gap
  ([arch_qt6-work-list.md](qt6-work-list.md) §7). The `-xr!bin.pre-*` pattern is therefore
  earning its place again; check what it matches before assuming it matches nothing.

The original measurement, taken 2026-08-22 against what was then `dist\msvc64`, is still why the
rule exists: that tree was **2773 MB, of which 1843 MB was `bin.pre-*`** — two thirds undo history —
beside a **3265 MB** `dist\_build`; including both would have made a ~5.3 GB archive instead of
1066 MB. It is now `dist_Qt5\msvc64`: 1981 MB with **1042 MB in ten `bin.pre-*` copies** (53%), next
to a 6264 MB `dist_Qt5\_build`. None of it is in the archive.

⚠ **The Qt 5 comparator is out of the snapshot on purpose.** `src_Qt5\` (407 MB) and
`dist_Qt5\msvc64\` (1981 MB, 940 MB once the rollback copies come off) do not change, and the older
`resonance_2026*.zip` archives already hold that tree under its former names. It is not dead
weight — it is the only home of the legacy `sp_*.qml` paradigms and the parity oracles
([qt5-still-needed.md](qt5-still-needed.md)) and of the git history. If it is wanted, that is a
*separate* archive: offer it, name its size, do not fold it in silently.

⚠ **The evidence is not in the archive.** `src\_test-output\` (84 MB) holds the port's QA recordings
and captures, and the EEGLAB ground truth sits in `dist_Qt5\_build\topo-ref\` (16 MB), outside the
archive twice over. `src\docs\qa\` **is** included — it is where the parity screenshots and service
logs live. If the rest of the evidence is wanted it is a separate, smaller archive; ask for it by
name.

⚠ **`data\*.h5` other than `stage6-*` is kept deliberately.** That rule now only reaches
`dist\data\`, which holds three files (`autodump.1.h5`, `record-0001.h5`, `record-0002.h5`, ~3 MB).
The operator recordings the rule was written for — `latency-*`, `tep_sub_cond_*`,
`tepsound_sub_cond_*`, **16 files and 240 MB** — are in `dist_Qt5\msvc64\data\` and therefore fall
outside the archive along with the whole Qt 5 distro. Say so when reporting; do not let them go
quiet. `stage6-*.h5` likewise matches nothing inside the archive today, all seven being in
`dist_Qt5\msvc64\data\`; the pattern guards against them reappearing under `dist\data\`.


<a id="history-the-series-so-far"></a>

## The series so far

| archive | size | note |
|---|---|---|
| `resonance_20260817.zip` | 1017 MB | |
| `resonance_20260818.zip` | 1057 MB | |
| `resonance_20260819.zip` | 776 MB | |
| `resonance_20260819_20_inwork.zip` | 2645 MB | includes `_build` — why the rule exists |
| `resonance_20260821.zip` | 1055 MB | first built to this recipe |
| `resonance_20260822.zip` | 1066 MB | 1473 folders, 10913 files |
| `resonance_20260828.zip` | 1371 MB | the last before the rename, and the only four-tree one: `src` + `dist` (Qt 5) **and** `srcQt6` + `dist_Qt6`, beside `config` and `docs` |
| `resonance_qt6_20260828.zip` | 249 MB | port-only side series — `srcQt6` **and** `dist_Qt6`, not this recipe |
| `resonance_qt6_20260829.zip` | 805 MB | ″ |
| `resonance_distQt6_20260831.zip` | 493 MB | `dist_Qt6` alone; ″ |
| `resonance_distQt6_20260901.zip` | 493 MB | ″ |
| `resonance_20260905.zip` | 947 MB | the last repository-shaped one (`dist docs src config`) |
| `resonance_20260906.zip` | 491 MB | first to the 2026-09-06 recipe: `R:\dist`'s contents at the root, `R:\docs` merged into `docs\`; no `src`, no `config` |
| `resonance_20260907.zip` | 492 MB | ″ — with the icon strip, `launch\`, `icons\`, the retired `nvx136_2021` gone; `*.pre-*` rollback files excluded as well |

Top-level contents of the last five re-read from the archives themselves, 2026-09-02.

⚠ **The series breaks at 2026-09-02 and the sizes stop being comparable.** Archives up to
`resonance_20260828.zip` hold the Qt 5 tree under the names `src`/`dist`; everything from the next
one on holds the Qt 6 tree under those names, and the Qt 5 tree is in neither. Of the main series
only `resonance_20260828.zip` is still on `R:\` — the 2026-08-17 to 2026-08-22 archives have been
deleted; all four side-series archives are still there.

