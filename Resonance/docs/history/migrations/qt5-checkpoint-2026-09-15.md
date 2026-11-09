# Legacy Qt5 commit preparation — 2026-09-15

Status: published to private Gitea on 2026-09-15.

## Published result

- Parent branch: `feature/services-and-isolation`, now at
  `14453fee17687293bbd191b7ca7eef4ca69f8640` in `bcilab/Resonance`.
- Six commits published: the five component commits below, plus `14453fe` — Host the
  Python engine on Gitea.
- Dependency: `333ae2cf054f832397a3e588f620be02cefc3d69` on `master` in the new private
  `bcilab/Resonance-engine-python` repository. Its upstream ancestry is retained.
- `.gitmodules` now points to that Gitea repository. A fresh clone retrieved the exact
  engine revision and confirmed the previous upstream revision is its ancestor.
- The parent push used `--recurse-submodules=check`. Both remote tips were verified and
  both working trees were clean. No force-push or rewrite of published history occurred.

The initial engine push to GitHub was denied after successful authentication because the
account lacked repository write access. The user identified their private Gitea account;
the dependency was hosted there and the parent URL updated before the parent push.
The application and engine source blobs remain identical to the validated checkpoint.

## Preparation history

Publication target corrected by the user: **`feature/services-and-isolation`** on Gitea.
The existing local branch was initially fast-forwarded to `15631cd`. At the user's request
for commits and short explanations matching the prior history, the unpublished combined
commit was then separated into five component commits:

- `b8aef3e` — Handle NeuroMS standby and transient status failures.
- `ebf5701` — Use the legacy NVX136 start sequence and bounded retry.
- `b42c639` — Add the NVX136 API tracer.
- `18e6c04` — Update the Python engine for per-channel metadata.
- `a96a166` — Record the Qt5 checkpoint and validation.

The five-commit preparation series ended at
`a96a1661961064914be424a35732f1d46a6cf416`, five commits ahead of the then-observed remote.
The original combined commit remains on `legacy/qt5-2026-09-15`. Every validated source blob
is identical; only the checkpoint document was corrected to name the publication destination
and component series. No published history changed.

The Qt5 source at `R:\src_legacy\Qt5` has a new branch `legacy/qt5-2026-09-15`:

- Initial combined parent commit, retained: `15631cd051db567e47c97e355bab99c29dcecf1d`.
- Python-engine submodule commit: `333ae2cf054f832397a3e588f620be02cefc3d69`.
- Parent base: `fae69c34d48c3183d6eecaea1370d8e5633fd46b`, the former local
  `feature/services-and-isolation` tip and the Gitea branch tip observed during preparation.

The checkpoint preserves the outstanding NeuroMS, NVX136, tracer and Python metadata changes.
Original implementations were retained; checkpoint documentation and Python-cache ignore rules
were added. Both working trees were clean afterwards.

Eight selected targets compiled in a fresh Qt 5.15.2/MSVC 14.29 build. All 63 pure-logic and
fake-SDK tests passed. No physical-device execution, vendor-emulator run or deployment occurred.
See the [source checkpoint record](../../../src_legacy/Qt5/docs/legacy-qt5-checkpoint-2026-09-15.md)
and its [validation receipt](../../../src_legacy/Qt5/docs/legacy-qt5-checkpoint-2026-09-15.validation.json).

The initial engine remote was GitHub. Its new revision needed an accessible submodule remote
before publication: the parent commit alone does not contain the engine's Git objects. This
dependency was resolved through the private Gitea repository described above.

This source checkpoint is distinct from the earlier
[workspace relocation and Git repair](../../maintenance/layout-migration-2026-09-15.md).
