# History and evidence

Status: historical record collection. Start with the [current task index](../README.md) for
coding work, and open the history relevant to a change or regression.

## Find a record

- [Changes by recorded session](changes/README.md): the former running STATUS log, now split
  into addressable change records with original dates and evidence.
- [Incidents and defects](incidents/README.md): prior diagnoses, fixes, failed hypotheses and
  framework lessons. Historical OPEN/FIXED labels describe their recorded state.
- [Component history](components/README.md): service evolution and verification campaigns.
- [Migrations and design rationale](migrations/README.md): Qt 5/Qt 6, toolchains, packaging,
  source inventories, snapshot policy and preserved implementation decisions.
- [Investigations](investigations/README.md): full substantive session narratives and experiments.
- [Vendor correspondence](vendor-correspondence/README.md): SDK questions, proposals, translations
  and original Word correspondence.
- [Configuration-toolkit archive](../../tests/evidence/config-archive-20260915/README.md): original
  lab rounds, prompts, numerical-reference edition, patch, profile versions and recorded outputs.
  The [migration record](../maintenance/config-migration-2026-09-15.md) maps their former locations.

## Reading the record correctly

Keep the date, source tree, binary/SDK, configuration and rig with every measurement. Reports
can contain a claim and its later refutation; the current component/decision and
[issue registry](../issues/README.md) identify the applicable conclusion. A command or deadline
from a past task is not an instruction to execute it today.

In particular, NVX136's later voltage-read result supersedes the earlier GetVersion theory;
KARDi2's x64 service/broker supersedes its old Qt 5 island proposal; several NeuroMS reconnect
experiments were confounded by two services sharing one device. The earlier attempts remain
here because their observations and rejected hypotheses are useful regression evidence.

Original evidence paths in code spans remain as recorded even when old build artifacts moved
or disappeared. [Reference gaps](../maintenance/historical-reference-gaps.md) identifies unavailable
links and repaired relative paths without claiming the missing measurements were reproduced.

This is the reorganized history, not a backup of the previous docs directory. Current guides
were rewritten, historical sections retained here, and old filenames/entrypoints removed.
The [migration record](../maintenance/migration-2026-09-15.md) and section-level
[migration map](../maintenance/migration-map.json) account for the disposition of the old material.
The existing user backup is separate.
