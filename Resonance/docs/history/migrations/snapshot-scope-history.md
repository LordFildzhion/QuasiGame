# Snapshot scope recorded in the 2026-09-02 documentation

Status: historical supplement. Added during the documentation preservation review, 2026-09-15.

Superseded procedure description, preserved as history. This source claimed an archive containing source and config; the current inspected snapshot skill and current how-to define a distribution-root package plus documentation instead. Do not execute the procedure below as the current snapshot policy. The recorded exclusion experiments and scope change remain useful evidence of how the documentation diverged.

[Current guidance](../../how-to/snapshot.md)

## Recorded scope change and exclusion semantics

Provenance: original `proc_snapshot-archive.md` lines 15–40. The following is preserved source text.

⚠ **The layout changed on 2026-09-02.** `src\` and `dist\` are now the **Qt 6** tree and
distribution — they were `srcQt6\` and `dist_Qt6\` — and `dist\` carries `bin\` at its root, with no
`msvc64\` level any more. The Qt 5 tree lives on as `src_Qt5\` / `dist_Qt5\msvc64\` and is
*deliberately not in the snapshot*; see [qt5-to-qt6-transition.md](qt5-to-qt6-transition.md).

| included | excluded | why excluded |
|---|---|---|
| `dist\` — the current **Qt 6** distro | `dist\bin.pre-*` | one ~103 MB copy of `bin` per deploy; local undo, not content |
| `docs\` | `src\_build\`, `src\KARDi2\_build-x86\`, `src\KARDi2\_build-x64\` | regenerable ninja objects |
| `src\` — the current **Qt 6** source | `src\_test-output\`, `src\_stage\`, `src\_dist\`, `src\_patches\` | QA captures, deployment staging, an empty install prefix, a zipped patch export |
| `config\` | `data\stage6-*.h5` | recordings written by test runs into a distro's output directory |
| | `src\KARDi2\_legacy\_retired-builds\`, `_previous-dist\` | 144 MB of rollback copies of the retired x86 island. ⚠ The **rest** of `_legacy` stays in: `_legacy\3dparty\Driver` is the only copy of the vendor USB kernel driver in the repository |

The artefact exclusions went from one pattern to nine — **eleven `-xr!` patterns in all** — because
the Qt 6 tree **builds inside itself**: `_build`, `_test-output`, `_stage`, `_dist`, `_patches`,
`KARDi2\_build-x86` and `KARDi2\_build-x64` are all children of `R:\src`, reversing the old "never
build inside the source tree" rule that sent intermediates to `R:\dist\_build`. A lone `-xr!_build`
catches one of them.

⚠ **`-xr!` matches a name exactly, not as a prefix.** `-xr!_build` does not catch `_build-x86` or
`_build-x64`; each needs its own switch. This is the same class of mistake as assuming `-xr!_dist`
covers `_previous-dist`, which it does not.

`config\` is in despite not being `dist`/`docs`/`src`: it holds the MATLAB oracles
(`topoplot_v4_reference.py` and the `topoplot_*.m` probes) and the test harnesses the docs reference
by path. Without it the documentation points at missing files.

## Recorded verification and the throwaway exclusion experiment

Provenance: original `proc_snapshot-archive.md` lines 119–134. The following is preserved source text.

An archive nobody checked is a backup nobody has. The skill requires, and the report must state:

1. `7z t` integrity, with folder and file counts;
2. `Method = Store` — not `Deflate`;
3. zero hits for each of the eight exclusion patterns
   (⚠ two known false positives on `_build`, re-checked 2026-09-02 and still exactly two:
   `config_build_check.cpp` under `src\3dparty\thir\boost\config\test\` and under
   `src\scriptEngines\R\boost\config\test\` — legitimate boost sources whose *names* contain the
   substring; check what a hit actually is before calling it a leak.
   `-xr!_dist` does **not** take the top-level `dist\` with it — `-xr!` matches whole names, and a
   throwaway archive built 2026-09-02 with `dist docs src -xr!_dist` kept `dist\bin\` and dropped
   `src\_dist\`, as intended — but the `dist\bin\` spot check below confirms it every time);
4. spot checks that expected paths are present — a binary from `dist\bin\`, a QML file from
   `dist\bin\Resonance\`, a doc, a source under `src\`, a config, and one file from `src\docs\qa\`;
5. the size and date, and what was excluded with its size — naming the Qt 5 comparator and the
   240 MB of recordings under `dist_Qt5\msvc64\data\` explicitly — so any of it can be asked back.
