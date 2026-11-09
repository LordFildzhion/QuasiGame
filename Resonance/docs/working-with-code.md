# Working with the code

Status: current shared guidance. Applies to the Resonance working trees on this machine.
These instructions use ordinary Markdown and file paths; they do not depend on an AI vendor.

## Establish the task context

1. Use the [task index](README.md) to find the component or shared contract.
2. Confirm the active source, dependent consumers, applicable configuration and validation route.
3. Inspect those source files before editing. Use a historical record when a regression or unusual
   constraint needs explanation; a previous session's plan is not authorization for this task.
4. Make the requested change and run the relevant checks. Report what changed, what was tested,
   and any remaining verification boundary. Update the current documentation it affects.

## Trees and ownership

- `R:\src` is the active Qt 6 / MSVC v143 / C++20 tree; `R:\dist` is its distribution, with
  `bin` directly below the root. Use [build](how-to/build.md) and [deploy](how-to/deploy.md).
- `R:\src_legacy\Qt5` and `R:\dist_legacy\Qt5\msvc64` are legacy/comparator locations.
  The [workspace index](../README.md) and [layout migration record](maintenance/layout-migration-2026-09-15.md)
  map current and former roots. A historical `R:\src` or `R:\dist\msvc64` path may predate
  the September 2 rename; later records can use the former `src_Qt5`/`dist_Qt5` names.
- The active source tree currently has no `.git`. Do not assume a clean checkout, a rollback
  commit or that compiled binaries include an unrecorded edit. Inspect existing work and keep
  changes reviewable. Record a revision when available, otherwise source path plus evidence/date
  and hashes where exact identity matters.
- Edit the owning source, not a similarly named retired copy. Build manifests establish whether
  a file is live. `_legacy` can still contain packaging inputs, notably KARDi2 driver assets.
- Some distribution files are operator configuration rather than reproducible build outputs.
  Preserve their ownership when deploying. Raw-recording directories, including
  `N:\Projects_MSU\2026 - FeetStim\data - raw`, are read-only inputs; put derived work elsewhere.

## Constraints to keep near every change

- Preserve serialized parameter IDs, labels used as serialized values, stream identity, units,
  channel meaning and wire layout unless the task explicitly changes the contract. See
  [framework](architecture/framework.md) and [epochs](architecture/epochs.md).
- Preserve measured device workarounds until their replacement has appropriate evidence.
  The voltage read whose result is discarded in [NVX136](components/nvx136.md) is required startup behavior.
- Stop an amplifier through its service before terminating it. Killing acquisition can leave a
  device wedged. Hardware tests, emulator tests that use a device path, and software-only tests
  have different prerequisites; use the component's validation route.
- Do not use `CreateDesktopW` or `SwitchDesktop` for UI testing. They can strand the operator's
  visible session. Existing message-based control and `PrintWindow` capture techniques are in
  [UI guidance](architecture/ui.md).
- Use the existing build script: it selects the toolchain, limits concurrency and runs
  `chcp 65001` after `vcvarsall` so Ninja records MSVC header dependencies. Keep non-ASCII out
  of narrow literals in targets without `/utf-8`; inspect the target's compiler options.
- Build, software verification, hardware acceptance and deployment are separate operations.
  `cmake --install` can overwrite configuration; the deploy script does not create a rollback.
  Never use `robocopy /MIR` on the distribution. Snapshots are made when requested.
- For destructive filesystem actions, name and verify the absolute target. On Windows, use
  native PowerShell operations with `-LiteralPath`; do not combine a directory change and a
  destructive relative command or switch shells to perform deletion.

## Documentation discipline

Keep the [initial route](README.md) short. Give each current fact one owning page and link to it.
Distinguish source inspection, software tests, physical measurements and hypotheses. Hardware
measurements retain their rig, build, mode and date. Preserve past changes and failed hypotheses
in [history](history/README.md); update current conclusions instead of appending contradictory
instructions. Illustrated Word manuals remain operator-facing publications.
