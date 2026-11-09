# Local commit and publication rules

**LOCAL ONLY — never commit or push this file or its contents to Gitea.**
Created on 2026-09-15, after Qt6 commits `dae0dc92566d3ba82be4573868f42f8c7fcb714a`
and `cbc9756e02e70915c764e207fe3f7bac35c651a2`. Applies to any coding agent working on this machine.

## Repository and authoring folders

- Gitea repository: `https://gitea.atedgeof.net/bcilab/Resonance.git`.
- Current Qt6 branch: `feature/qt6-transition`.
- Separate Git checkout: `C:\Users\Anatoly\Documents\Codex\2026-09-15\read-the-r-docs-in-full-2\work\qt6-transition-review\repository`.
- Authoring source: `R:\src`; shared documentation: `R:\docs`. Keep these folders where they are.
- Published Qt5 comparator: `R:\src_legacy\Qt5`, branch `feature/services-and-isolation`,
  checkpoint `14453fee17687293bbd191b7ca7eef4ca69f8640`. Do not use the old `develop`
  default as the Qt6 base or alter the Qt5 branch during Qt6 publication work.

Use the existing Qt6 checkout and its current branch history for later commits. The initial
one-off export scripts in this task's `work/qt6-transition-review` directory are historical
preparation tools, not safe repeatable synchronization commands; do not rerun them over a
populated checkout. Never hard-reset, clean, reinitialize or overwrite the authoring tree to
turn it into a Git checkout. A separate checkout may contain changes absent from the authoring
folders: inspect and reconcile both sides before copying anything.

## Preserve this mapping

| Local authoring input | Git path |
|---|---|
| `R:\src` source and packaging inputs | Repository root; no extra `src/` prefix |
| `R:\docs` | `docs/`, except this rulebook and marked local-only blocks |
| `R:\src\docs\*.md` | `docs/history/qt6-port/` |
| `R:\src\docs\qa` | `docs/qa/` |
| `R:\tools`, `R:\config` | `tools/`, `config/` |
| Required fixtures and retained written/visual test evidence | Corresponding `tests/` paths |

Adapt relative Markdown links to the Git layout. Retain historical dates, commands, rejected
hypotheses, original evidence and file provenance. Machine-specific paths in a historical record
describe that session. Current procedures must explain the corresponding checkout path.
Preserve source-local port records when merging shared documentation: do not overwrite a
same-named README or move active script output paths without inspecting consumers.

Operator DOCX files and their images remain operator publications; preserve the files as bytes
and do not replace them with machine-readable versions. Significant new changes go into the
owning current guide plus dated history. The snapshot manifest records original/export hashes;
ordinary Git source-text line-ending normalization is distinct from a content change.

## Included and excluded inputs

- Include active source, tests, maintained scripts, documentation, source-owned presets,
  firmware/vendor DLLs and driver assets required by build/deployment.
- Include the private Python runtime. `.pyd` files are native runtime modules, **not caches**.
  Ignore `.pyc` and `.pyo` explicitly; do not use `*.py[cod]`, which also excludes `.pyd`.
- THIR, qml-colors and the Python engine are tracked as actual files in this branch. Preserve
  their licences/origins and current Qt6 changes; do not replace them with old submodule pins.
  Omit obsolete nested `.git` pointers and `.gitmodules` from copied dependencies.
- Exclude the dormant `scriptEngines/R` tree. Keep it in Qt5 history, not this branch.
- Exclude generated `_build`, `_dist`, `_stage`, `_test-output`, `_patches`, `Testing/Temporary`,
  caches and the specifically ignored KARDi2 build folders. Never blanket-exclude `_legacy`:
  KARDi2's vendor driver and DLL there are live inputs.
- Keep `R:\builds`, installed distributions, separate legacy checkouts, equipment packages and
  large historical recordings outside the source snapshot. Do not inspect/rewrite build archive
  contents as part of committing source. Preserve external-recording references and manifests.
- `tepService` and `mioStim` are retired in Qt6; the active replacements are TepSound and eStim.
  `nvx136_2021` source is retained but outside the default build. Inspect CMake before classifying
  source as live or retired. Do not resurrect absent Qt5 services by overlaying trees.

## Prepare, validate and commit

1. Inspect the checkout branch, working changes, remotes, current Gitea branch tip and existing
   local changes. Never discard other work. Use the requested branch; do not push to `develop`
   or Qt5 merely because it is an inherited/default upstream.
2. Reconcile the selected authoring changes using the mapping above. Handle intended deletions
   explicitly; a copy-only overlay can leave retired files behind. Keep unrelated edits out.
3. Strip sections between `<!-- local-only:start -->` and `<!-- local-only:end -->` from exported
   entry pages. Exclude every file named `commit-rules.local.md` before copying or staging.
   Never reproduce this rulebook inside a tracked report, manifest, attachment or commit message.
4. Compare the intended file inventory with `git ls-files`. Nested ignore rules can hide real
   vendored project files; force-add only individually reviewed source inputs. Verify exact
   path case too: Windows can hide case-only differences. Retain binary/fixture hashes.
5. Review the complete staged paths and diff. Check for generated output, retired R, unexpected
   submodule entries, missing native runtime modules, secrets and the local rulebook. Confirm
   that all approved docs/history and operator publications are accounted for.
6. Run the smallest meaningful checks for the changes using the documented pinned Qt/MSVC
   environment. For a broad snapshot use the normal build script and maintained software checks.
   The QA runner supports this source-root checkout. Hardware tests and deployment need their
   own task authorization; a passing build is not hardware acceptance.
7. Run `python -B docs/maintenance/check-docs.py` in the checkout. Record source/build identity,
   actual executed counts, skips and remaining limits. Preserve failed investigations that
   explain the final result; do not copy an old passing total as new validation.
8. Write short behavior-focused commit titles and concise explanations of the change, reason
   and validation, following the existing repository style. Keep logical changes reviewable.
   Use a UTF-8 message file with `git commit -F`; avoid shell-constructed multiline bodies.

## Publish within the user's authorization

Commit or push only when authorized for the current task. If the request is only to review or
prepare, stop at that boundary. For an authorized Qt6 push, name the destination explicitly:

```powershell
git push -u origin HEAD:refs/heads/feature/qt6-transition
```

Use normal Git Credential Manager authentication; let the user log in when prompted. Never
put a password/token into a URL, source file, log, command argument or commit message. Do not
force-push or rewrite published history unless separately requested.

The checkout's `.gitignore` and `.git/info/exclude` exclude this filename. A local pre-push hook
also rejects it if it appears anywhere in outgoing commits. Keep that hook; do not bypass it.
Before pushing, inspect the outgoing tree/history and verify that this rulebook is untracked.
After pushing, verify Gitea's branch hash equals the intended local HEAD, and that Qt5's branch
is unchanged. Report commit hashes, short explanations and validation, without claiming deployment.

Keep this rulebook in the authoring docs at `R:\docs\maintenance\commit-rules.local.md`, outside
the prepared checkout. The ignore rules and hook protect against accidental copies. Local-only
navigation blocks added after publication are excluded from later exports by the rule above.
