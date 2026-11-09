# Maintaining repository context

Status: current documentation workflow. Applies to `R:\docs` and its source-documentation links.

## Content ownership

- `README.md` routes tasks; `working-with-code.md` contains common working constraints;
  `current.md` gives a short current orientation. Avoid growing these into session logs.
- Architecture pages own shared contracts. Component pages own component-specific behavior,
  source locations, dependencies, nonobvious constraints and validation routes.
- How-to pages own executable procedures with prerequisites and expected results.
- Issues own unresolved work. Each entry has a stable ID, status, scope, evidence and next step.
  A report awaiting reproduction is not automatically a confirmed current bug.
- Decisions own accepted rationale; proposals stay explicitly proposed until accepted.
- History owns dated changes, experiments, old approaches and evidence. Preserve results that
  were later disproved as well as successful fixes. Do not overwrite the past with the final story.
- Illustrated operator manuals remain DOCX with images. Maintain them for people; do not create
  parallel machine-readable copies or make agents read them as default context.

## When changing code

1. Update the owning current page when its behavior, commands, dependencies or limits change.
2. Link other pages to that owner rather than repeating volatile facts or test totals.
3. Record significant changes and diagnoses in a dated history page: trigger/problem, scope,
   change, reason, checks, result, remaining limitations and links to current guidance.
4. Retain the original experiment conditions, units, rejected hypotheses and evidence paths.
   If a conclusion is corrected, identify what supersedes it and why at the affected section.
5. Update the issue/decision disposition and affected links.

## Evidence language

Use precise labels: source inspected, software test executed, emulator test executed, hardware
measured, inferred, reported/unverified, superseded. Include a revision where available; the
active tree lacks Git metadata, so use source paths, dates and exact hashes when identity matters.
Do not call a source edit deployed or hardware-verified because it compiles. Captured test totals
are dated results; the current test inventory comes from manifests and discovery.

## Page shape

Use a descriptive title, short scope/status header and an early source/task route. Keep one
coherent topic per page; split when tasks need different context, not at an arbitrary word count.
Prefer relative Markdown links to repository content. Put machine-specific paths in setup or
scoped evidence. Use stable descriptive anchors; add an explicit HTML ID where a durable public
anchor is necessary. Images are PNG; exported tables are XLSX.

For a component, cover purpose, active source, interfaces, invariants, consumers, validation and
current limitations. Link to code for exhaustive generated schemas; keep the nonobvious contracts
in prose. A source symbol is more durable than a bare line number.

## Workspace layout and relocated evidence

The [workspace index](../../README.md) owns current root locations and the flat `builds/`
archive naming conventions. [Support-tool guidance](../how-to/support-tools.md) owns the routes
for maintained tools, current configuration examples, captured fixtures and historical experiments.
Record moves with an explicit old-to-new map; the [root layout migration](layout-migration-2026-09-15.md)
and [configuration-toolkit migration](config-migration-2026-09-15.md) provide the relocation records.

Update current facts and actionable link destinations after a move. Preserve historical literal
paths and command blocks as evidence, and route readers to the relocation record before reuse.
If a former directory is now a ZIP, link to that archive and retain the inner path in the text
or relocation record; do not invent an on-disk path into the ZIP. Existing full-build archives
retain their contents; moving them does not authorize changing their package layout.

## Validation

Run the read-only checker from PowerShell with a Python 3 interpreter:

```powershell
python R:\docs\maintenance\check-docs.py
```

It checks local Markdown links and anchors, required entrypoints, current-page reachability,
operator publication identity against the migration manifest, and initial reading size. It does
not execute code blocks, build software or touch hardware. Historical unavailable evidence is
listed separately; keep its original path as provenance rather than pretending the file exists.

[Migration record](migration-2026-09-15.md) explains this reorganization.
[Migration map](migration-map.json) accounts for every original file and section disposition.
It is an audit record, not a second current reference or a backup of the old docs.

<!-- local-only:start -->
## Local Git publication

For commits from the split authoring workspace, read [local commit rules](commit-rules.local.md). This local navigation block and rulebook are excluded from Gitea exports.
<!-- local-only:end -->
