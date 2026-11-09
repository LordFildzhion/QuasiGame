# Make a runnable distribution snapshot

**Canonical vendor-neutral procedure.** Run only when the user requests a snapshot/archive/build ZIP. Finishing development, changing documentation or considering a risky action does not itself request one. This page documents the recipe; the documentation restructure created no archive.

## Scope and output

Produce `R:/builds/resonance_YYYYMMDD.zip`, using **stored/uncompressed ZIP entries**.

| Include | Exclude |
|---|---|
| Contents of `R:/dist` at archive root | Top-level `src`, `config`, Qt5/comparator/legacy trees |
| `R:/docs` merged into archive `docs/` | Rollback directories/files: `bin.pre-*`, `*.pre-*` |
| Existing `dist/docs` SDK/licence material | `__pycache__`, `stage6-*.h5`, `*.log`, `*.log.1`, `*.dmp` |

Expected root: `bin/`, `qt/`, `params/`, `env.bat`, launchers and `docs/`. There must be **no wrapping dist directory**. This is a runnable distribution, **not a source backup**. A source/config archive is a separately requested artifact.

This resolves the old procedure's inconsistent inclusion and verification tables. The current recipe changed on 2026-09-06, was refined on 09-07 and was reconciled against the repository's existing snapshot instructions and archive record on 2026-09-15. Earlier repository-shaped snapshots used a different layout; do not use their contents as today's checklist. [Historical snapshot record](../history/migrations/snapshot-series.md).

## Preconditions

1. Use the current distribution after any separately authorized build/deploy and its checks; snapshotting does not implicitly rebuild or deploy.
2. Ensure executable/Qt/launchers and rig assets expected for this package exist. Check [deployment](deploy.md) for driver/runtime dependencies and non-generated configuration.
3. Confirm `C:/Program Files/7-Zip/7z.exe` exists.
4. Choose the date and exact target. If that file already exists, stop before adding anything: resolve explicit overwrite or a distinct suffix. `7z a` otherwise updates an existing archive and can retain stale entries.
5. Check file-path collisions between `dist/docs` and repository `docs`. On the inspected tree dist/docs contains DAQmx and fieldtrip vendor material, but future merges must still be checked. Identical relative paths must be deliberately resolved; silently overwriting either set is not a merge policy.
6. For files being actively written, coordinate a stable capture or document its consistency limit. Do not silently stop an experiment to make an archive.

## Build the ZIP

The following PowerShell recipe uses two calls into one newly named ZIP. Replace the date. Run from a scratch script or terminal after the preconditions; this page does not execute it.

```powershell
$sevenZip = 'C:\Program Files\7-Zip\7z.exe'
$snapshotPath = 'R:\builds\resonance_YYYYMMDD.zip'
$snapshotExcludes = @(
    '-xr!bin.pre-*', '-xr!*.pre-*', '-xr!__pycache__',
    '-xr!stage6-*.h5', '-xr!*.log', '-xr!*.log.1', '-xr!*.dmp'
)
if (-not (Test-Path -LiteralPath $sevenZip -PathType Leaf)) {
    throw '7-Zip is unavailable.'
}
if (Test-Path -LiteralPath $snapshotPath) {
    throw 'Target already exists; choose an explicitly agreed replacement or suffix.'
}

Push-Location -LiteralPath 'R:\dist'
try {
    & $sevenZip a -tzip -mx0 -bb0 -bt $snapshotPath '*' @snapshotExcludes
    if ($LASTEXITCODE -ne 0) { throw 'Distribution archive step failed.' }
}
finally { Pop-Location }

Push-Location -LiteralPath 'R:\'
try {
    & $sevenZip a -tzip -mx0 -bb0 -bt $snapshotPath 'docs' @snapshotExcludes
    if ($LASTEXITCODE -ne 0) { throw 'Documentation merge step failed.' }
}
finally { Pop-Location }
```

The first call runs **inside dist with `*`**, which places its contents at root. Adding `dist` from R: would create the wrong wrapper directory. The second adds repository docs into the root docs folder. Exclusion switches are single-quoted argument strings; no shell needs to reinterpret `!` or wildcards.

On a failed step, do not report success or blindly reuse the partial archive. Diagnose it and use an explicitly chosen clean target/recovery before rerunning.

## Verify before reporting

Save/read the listing in scratch space, then verify all of the following:

```powershell
& $sevenZip t $snapshotPath
if ($LASTEXITCODE -ne 0) { throw 'Archive integrity check failed.' }
& $sevenZip l -slt $snapshotPath
if ($LASTEXITCODE -ne 0) { throw 'Archive listing failed.' }
```

- Integrity succeeds; record file/folder counts and final byte size.
- File entries use **Store**, not Deflate.
- Root contains expected bin/qt/env/launchers; no dist/src/config wrapper or comparator tree.
- Both repository `docs/README.md` and the distribution's `docs/DAQmx/` and `docs/fieldtrip/` material survive the merge.
- No entry matches the actual excluded file/directory name patterns. Check path components, not arbitrary substring hits in documentation text.
- Spot-check at least a service executable, QML resource, repository doc, vendor doc/licence and launcher.
- Open/check the resulting artifact as needed for the user's requested delivery; the stored ZIP layout itself does not install external NI/kernel drivers.

Report target path, date, size, integrity/Store result and **source/config not included**. Do not present an unverified/partial ZIP as a completed snapshot. No automatic schedule or vendor-specific assistant file owns this recipe; any assistant adapter should only route here.
