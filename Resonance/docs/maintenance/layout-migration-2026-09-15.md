# Workspace layout migration — 2026-09-15

Status: completed relocation and link/Git repair. The user requested a flat `builds` folder,
with package type expressed in its filename, and deferred any restructuring of `config`.
See the [workspace index](../../README.md) for current navigation and the
[verification receipt](layout-migration-2026-09-15.json) for machine-readable results.

## Move map

| Former path | Current location |
|---|---|
| `R:\src_Qt5` | [R:\src_legacy\Qt5](../../src_legacy/Qt5/) |
| `R:\dist_Qt5` | [R:\dist_legacy\Qt5](../../dist_legacy/Qt5/) |
| `R:\backup_docs_260615.zip` | [builds/backup_docs_260615.zip](../../builds/backup_docs_260615.zip) |
| `R:\resonance_20260905.zip` | [builds/resonance_20260905.zip](../../builds/resonance_20260905.zip) |
| `R:\resonance_20260906.zip` | [builds/resonance_20260906.zip](../../builds/resonance_20260906.zip) |
| `R:\resonance_20260907.zip` | [builds/resonance_20260907.zip](../../builds/resonance_20260907.zip) |
| `R:\resonance_20260905.verification.json` | [builds/resonance_20260905.verification.json](../../builds/resonance_20260905.verification.json) |
| `R:\aqtinstall.log` | [builds/backup_aqtinstall.log](../../builds/backup_aqtinstall.log) |
| `R:\patches\configurator-live-status-delete-20260908.zip` | [builds/patch_configurator-live-status-delete-20260908.zip](../../builds/patch_configurator-live-status-delete-20260908.zip) |
| `R:\patches\configurator-stream-recovery-20260908.zip` | [builds/patch_configurator-stream-recovery-20260908.zip](../../builds/patch_configurator-stream-recovery-20260908.zip) |
| `R:\patches\nvx136_2021_20260904\` | [builds/patch_nvx136_2021_20260904.zip](../../builds/patch_nvx136_2021_20260904.zip) |
| `R:\patches\nvx136_frame-layout_20260904\` | [builds/patch_nvx136_frame-layout_20260904.zip](../../builds/patch_nvx136_frame-layout_20260904.zip) |
| `R:\Dbgview.exe` | [tools/debug/Dbgview.exe](../../tools/debug/Dbgview.exe) |
| `R:\tmp\` | [tests/evidence/root-tmp-20260915/](../../tests/evidence/root-tmp-20260915/) |
| Test index filename with a leading literal backtick | [tests/README.md](../../tests/README.md) |

The documentation backup already had its `backup_` prefix when this migration started.
The two patch directories became stored ZIPs with their complete relative layout and all
58 payload files verified byte-for-byte before removal of the original directories.
Other ZIP files and the earlier verification JSON moved unchanged. Their original recorded
paths remain part of their dated evidence. `builds` has ten files and no subdirectories.
`Testing` and `utlis` were already absent when work began; the user had removed them.

## Git repair

The main Qt5 repository is now `R:\src_legacy\Qt5`. Its branch remains
`feature/services-and-isolation` at `fae69c34d48c3183d6eecaea1370d8e5633fd46b`.
Sixteen linked worktrees remain under `R:\src_legacy\src_git_branches` at their original
detached commits. Their registrations previously named nonexistent `R:\src_git_branches`
locations, and their `.git` pointers named the former main repository.

`git worktree repair` repaired both directions. Git connectivity passed. All 41 captured
repository states (main, 24 nested submodules, 16 linked worktrees) retained their HEAD,
branch/detached state, status, staged/unstaged binary diffs and refs. Existing modified and
untracked files were preserved. Comparing 23,130 file hashes found exactly the expected
32 worktree metadata edits and no other added, missing or changed files in those trees.
No remote update or commit was part of this relocation.

Git repair does not regenerate a CMake cache. The retained Qt5 build cache contains paths
from even earlier layouts; use a freshly configured comparator build when rebuilding it.
The moved runtime's launch environment derives paths from its own directory.

## Current consumers and historical references

Updated 216 absolute path references across 108 source/script/fixture/permission files. These edits
change relocation paths only. Of the 272 files in `config`, 86 contain such path repairs;
all filenames, directories and other content remain unchanged. Configuration classification
is a separate proposal. No configuration/tooling reorganization was performed.

Current documentation, entry routes and actionable links use the new locations. Historical
literal paths and commands remain dated evidence; use this move map before reusing them.
The root and legacy indexes explain current scope. The default search exclusions name
specific top-level/generated roots and do not hide live KARDi2 driver inputs just because
their source-local folder is named `_legacy`.

## Verification

- Primary moves: 13 entries, 18,388 file hashes identical immediately after relocation.
- Patch packaging: 58 payload files identical; both new ZIP integrity checks passed.
- Qt5 Git: 41 states preserved, all 16 worktree registrations repaired, connectivity passed.
- Consumer syntax: 29 modified Python files, 35 PowerShell files and eight JSON files parsed successfully.
- Rebuilt only `test_TopoField` and `test_CedPalette` in the active Qt6 build with MSVC 14.44.
  Ran with `TOPO_REF_DIR` unset, so the new default path was exercised: 43 + 16 tests passed,
  zero failures or skips. Existing oracle data remains at
  `R:\dist_legacy\Qt5\_build\topo-ref`; it was not regenerated.
- Examined 84 project/desktop shortcut files; none referenced the moved root locations.
- The documentation check and its exact final link count are recorded in the receipt.

The application distribution, operator Word publications and existing build archive contents
were not rewritten. No service, hardware acquisition, deployment or MATLAB job was run.
