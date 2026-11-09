# Configuration and support-tool migration — 2026-09-15

Status: completed, dated implementation record. Current task routes belong to
[support-tool guidance](../how-to/support-tools.md), the [tool index](../../tools/README.md)
and [configuration examples](../../config/README.md).

## Result and reason

The former `config/` mixed configurations, executables, test harnesses, logs, authoring scripts,
historical prompts and generated caches. All four approved steps are implemented: classify and
index, correct misleading material, validate and relocate useful Qt6 tooling, and consolidate
verified duplicates and caches. Coding agents can now select a small task-specific route and see
its evidence status before executing a tool. The routes and terminology are vendor agnostic.

| Location | Responsibility |
|---|---|
| `config/examples/` | Four minimal, source-reviewed current configuration examples |
| `tools/qa/` | Maintained Qt6 checks alongside explicitly unvalidated older harnesses |
| `tools/hardware/`, `tools/lab/` | Device tools and complete laboratory bundles, with execution boundaries |
| `tools/analysis/`, `tools/research/offline/`, `tools/reference-generation/` | Analysis and reference workflows |
| `tools/publications/` | Explicit publication CLIs, shared code and dated authoring editions |
| `tools/legacy/qt5/` | Historical Qt5 build helper requiring fresh cache configuration |
| `tests/fixtures/config/`, `tests/fixtures/topography/` | Captured configurations and independent numerical oracles |
| `tests/evidence/config-archive-20260915/` | Historical prompts, patches, logs and original revised profiles |

The [tool catalog](../../tools/tool-catalog.json) accounts for every one of the **272 original
files exactly once** and indexes 202 current entries. Its statuses distinguish executed software
checks, checked command interfaces, source-reviewed examples, hardware tools and tools awaiting
revalidation. Load the relevant guide first; the full catalog is an optional lookup.

## Moves, corrections and preservation

- **252 primary file moves** were checked against their original SHA-256 hashes immediately after
  relocation. Internal imports, QML companions, laboratory protocols and all 11 dependency wheels
  remain with their bundles. Current source, script, documentation and scoped permission references
  were updated to the new locations.
- Five identical NVX136 by-name profiles now share one canonical fixture,
  [nvx136_byname.json](../../tests/fixtures/config/nvx136_byname.json): **four duplicate aliases**
  were removed only after matching hashes. Its captured `NVX136_2025` service identity remains
  historical; it is not presented as a current default.
- **16 generated Python caches** were removed after verifying each companion source survived.
- **91 original topography/CED oracle files** moved from the Qt5 build tree to
  [the fixture bundle](../../tests/fixtures/topography/README.md), byte for byte. Existing numerical
  input formats remain intact; the fixtures were not regenerated.
- The loopback example was reduced to current supported settings. Two captured NVX136 profiles
  lost the retired `disable_unused_channels` field. Exact originals of all three revised profiles
  remain under the evidence archive's `history/profiles/` directory. Three new service examples
  use source-checked serialized parameter values and request no automatic start.
- Historical prompts, lab rounds, source patches and recorded outputs remain unchanged in the
  [evidence archive](../../tests/evidence/config-archive-20260915/README.md). Two mixed historical
  laboratory READMEs remain there as originals; short current indexes replace them at the tool
  locations. Four retained QML harnesses gained notes identifying obsolete claims without deleting
  the old rationale.
- Nine MATLAB reference scripts now load `W:\MATLAB\startup.m`. They were not executed.
- The distinct original configuration-folder DOCX remains in
  [vendor correspondence](../history/vendor-correspondence/README.md). Operator DOCX publications
  and their images were not converted or regenerated.

This record and its [machine-readable receipt](config-migration-2026-09-15.json) preserve old-to-new
dispositions, original hashes, semantic revisions and validation evidence. They complement the
[earlier documentation migration](migration-2026-09-15.md) and
[workspace/Qt5 Git repair](layout-migration-2026-09-15.md).

## Maintained Qt6 checks

After rebuilding the 12 selected native test targets, the new maintained runner passed
**212 GoogleTest cases with zero skipped, disabled or failed cases**, plus a synthetic
recorder/HDF5/playback integration. The roundtrip preserved **24 blocks, 384 rows and 3 channels**
exactly, including serialized type, absent metadata and block shapes. Created-time deltas differed
by **0 ns**. The integration used existing build-runtime application binaries; their hashes are
recorded separately from rebuilt test binaries.

The maintained groups cover parameters, epochs, reconnect behavior, independent numerical
oracles and recording/playback. An intentionally missing oracle directory correctly made the
runner fail even though the native executables returned zero after skipping comparisons.
Earlier failed harness-development attempts remain recorded with the corrected readiness and
subscription sequence.

See [scope and commands](../../tools/qa/QT6-CHECKS.md) and the
[dated result and raw evidence links](../../tools/qa/QT6-CHECKS-VALIDATION-2026-09-15.md).
All **90 older QA harnesses remain marked as needing revalidation**. These results do not establish
hardware acceptance, visual acceptance, deployment or coverage of every historical campaign.

## Publication tools

The 14 authoring entrypoints now require explicit inputs, output destinations and editions where
applicable. Help, imports and dry-runs do not render or write publications. Five duplicated Markdown
renderers share one implementation; seven dated recipes and original title/SDK/path metadata
retain their historical content. Output collisions are rejected.

All **seven Python safety tests and five crop checks passed**. Actual retained NVX136 inputs passed
manual preflight with 21 extracted keys; the shortened SDK questions passed PNG-input preflight.
Neuron-Spectrum and NVX-52 preflights correctly reported six and five missing historical diagram
PNGs respectively. No new DOCX, image or PDF was generated. Rendering quality remains outside
these CLI checks. See [the authoring guide](../../tools/publications/README.md).

## Integrity and practical limits

The final receipt embeds migration integrity checks, documentation/link checks, catalog accounting,
publication validation and the Qt6 summary. Original history, logs, binary dependencies, retained
profile/README originals, numerical oracles and Word publications were hash-checked. The ten
files in the flat `builds/` directory still match the previous layout receipt; their contents were
not unpacked or changed during this work.

Hardware and MATLAB workflows remain explicitly unexecuted. The four current examples are
source-reviewed templates, not validated device presets. Qt5 tooling retains a warning about
stale CMake caches. No live distribution deployment or Git history rewrite occurred.
