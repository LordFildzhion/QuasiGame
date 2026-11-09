# DEC-001: Qt 6 is the default tree

**Status:** accepted; promoted 2026-09-02. **Source review:** 2026-09-15.

## Decision

Use `R:\src` and `R:\dist` for current development and deployment. These are the Qt 6 source and distribution. `R:\src_legacy\Qt5` and `R:\dist_legacy\Qt5\msvc64` are the retained Qt 5 comparator. Select the comparator explicitly when reproducing a historical result; the [layout migration record](../maintenance/layout-migration-2026-09-15.md) maps the former root names.

The current build uses C++20, Qt 6.11.2 for MSVC x64 and MSVC v143 14.44. Exact machine setup and commands belong in the build runbook. CMake and the current build script determine the active module graph; an old QBS product or source folder alone does not establish that a component is built.

## Why

The port now provides the active service stack on one framework/runtime. Keeping an implicit Qt 5 default would route edits, binary checks and deployment to the wrong tree. The final architectural dependency on a Qt 5 service disappeared with the [KARDi2 broker](kardi2-broker.md).

## Consequences

- Keep Qt 5 and Qt 6 plugins, QML imports and framework DLLs within their own processes. They can communicate through the established network protocol.
- Legacy `sp_*.qml` scripts using Controls 1 still need deliberate migration or the comparator. Qt 6 being the default does not prove those scripts work.
- Old absolute paths in experiment records retain their meaning at the experiment date. Consult the history context before using one as a command.
- `R:\src` currently has no Git metadata. Do not fabricate a commit or infer binary provenance from the directory name; see BUILD-001 in the [issue registry](../issues/README.md).

**Implementation evidence:** [`src/CMakeLists.txt`](../../src/CMakeLists.txt), [`scripts/build-qt6.ps1`](../../src/scripts/build-qt6.ps1), [`KARDi2/CMakeLists.txt`](../../src/KARDi2/CMakeLists.txt). These were inspected without building or deploying.

**History:** [Qt 5 to Qt 6 transition](../history/migrations/qt5-to-qt6-transition.md), including the tree promotion and superseded build islands.
