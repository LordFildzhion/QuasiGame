# Documentation restructure — 2026-09-15

Status: documentation change record. User approved the structured migration and retained
illustrated Word manuals for operators. The existing user backup remains separate; no duplicate
original-docs directory or compatibility stubs are part of the new layout.

## Change

Replaced the flat prefixed layout and long mandatory reading sequence with a task router,
shared working rules, current state, architecture/contracts, component guides, procedures,
operator publications, issue/decision records and browsable history. The former STATUS and
known-issues logs became individually addressable historical records. Dated service changes,
audits, experiments and vendor correspondence remain available under topic history indexes.

Current guidance was reconciled with selected source and build manifests, including dynamic
parameter application, NVX136 startup, the KARDi2 broker, FieldTrip, current test registration and
runtime path ownership. No application source, binary, build, device state or deployment was
changed by the documentation work.

## Preservation

All 68 previous files are accounted for in the migration map: 57 Markdown documents and
11 Word documents. Each Markdown section has a recorded source range and disposition; original
historical sections retain their substantive text, measurements, failed hypotheses and corrections.
Additional preservation review recovered 20 historical ranges from sections otherwise rewritten
as current reference. The old navigation text was replaced by the new task routes.

The five illustrated operator manuals moved to `operators/manuals`; six vendor Word publications
moved to historical correspondence. All eleven remain byte-identical to their pre-migration files,
including embedded images. No Markdown copies of the operator manuals were published.

The [migration map](migration-map.json) stores original file/section identities, destinations,
source-content hashes and the additional preserved ranges. It stores provenance rather than
a duplicate original corpus. Historical unavailable evidence paths remain visible and are listed
in [reference gaps](historical-reference-gaps.md).

## Validation and future maintenance

Run [check-docs.py](check-docs.py) for local links/anchors, current-page reachability, required
routes and Word publication hashes. Representative routes cover a new service, a service bug,
framework/epoch changes, build/testing, deployment and regression investigation. These checks
read files only; no software or hardware acceptance was run for this change.

The previous prescribed README → STATUS → transition sequence contained 40,921 words.
The new initial route is README + working-with-code + optional current state; the checker reports
its actual size. This measures reading volume, not a claimed model-runtime speedup.

Future changes follow [maintenance rules](README.md). An intentional operator-manual revision
must update its recorded publication identity rather than silently defeating the hash check.
[Prompt examples](../how-to/ai-task-prompts.md) demonstrate the new routes without tying them
to one coding-agent vendor.
