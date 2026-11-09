# 2026-08-18 — docs and test evidence reorganised

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-18--docs-and-test-evidence-reorganised"></a>

### 2026-08-18 — docs and test evidence reorganised

⚠ **Paths in older entries below are as they were written and many no longer resolve.** Two things
moved on 2026-08-18; both are pure moves, nothing was regenerated or deleted.

**1. Test evidence left `R:\docs` and `R:\dist` for `R:\tests`.** A distribution tree was carrying
~1.7 GB of results and the docs folder was carrying spreadsheets. 121 files now sit under
`R:\tests\<build>\<test>\`, filed by the build that produced them, because "does this number still
hold?" is always a question about a binary. Manifest: `R:\tests\`README.md`.

| Folder | |
|---|---|
| `source-recordings\` | the 3.8 GB TMS input file most playback and TEP work replays |
| `2026-08-14_nvx2025-driver-campaign\` | the NVX-2025 reports **and** their evidence workbooks, kept together |
| `2026-08-16_build_tepservice\` | the original SciPy validation, runs 01–04 |
| `2026-08-17_build_full-rebuild\` | module acceptance, the first TEP session, the trigger campaign |
| `2026-08-18_build_tep-displayfilter\` | TEP sessions, NS-65 sync, NVX trigger and mirror work |
| `2026-08-18_build_network-isolation\` | the SciPy re-validation, module acceptance, isolation checks, live NVX |

⚠ `R:\dist\msvc64\data\` is now **empty**, and `R:\dist\_build\` holds only the CMake binary
directory. ⚠ `R:\dist_2026aug\msvc64-lanIsolation\` — the snapshot taken at 08:44 — was **not**
touched, so it still holds its own copy of those recordings. Nothing moved here is the only copy.

**2. Every document was renamed to a prefix scheme** so a plain alphabetical listing reads in the
order someone needs things: `` `README ``/`` `STATUS `` on top, then `arch_`, `build_`, `guide_`,
`report_`, `service_`, with non-documentation (vendor questions, work logs) in `_notes\` and
screenshots in `figures\`. The scheme is documented at the top of
[`README.md`'s document list](README.md). **361 cross-references were rewritten and verified to
resolve**; the harnesses and generator scripts in `R:\config` that named a doc or a recording were
updated with them.

