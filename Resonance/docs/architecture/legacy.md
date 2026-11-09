# Legacy and comparator scope

Status: current routing. Applies to the Qt 5 comparator and retained historical implementations.

Use `R:\src` for normal work. Use `R:\src_legacy\Qt5` only when the task names a legacy application,
comparison or backport. Preserve generation boundaries: separate CMake caches, Qt DLLs, plugin
paths, import paths and distributions. Wire interoperability does not permit loading both Qt
generations into one process.

## What remains relevant

- The 18 Controls 1 `sp_*.qml` paradigms in
  [src_legacy/Qt5/stimulusService/legacy](../../src_legacy/Qt5/stimulusService/legacy) remain legacy applications. The native Qt 6
  [Stimulus service](../components/stimulus-presentation.md) has its own current presentation
  workflow; do not infer complete paradigm parity from the fact that it builds.
- Qt 5 executables and captured results serve as comparators for rendering, DSP and file-format
  behavior. Preserve original test conditions and distinguish an intended change from a regression.
- `tepService` is retired; [TepSound](../components/tepsound.md) owns active analysis. The
  [legacy TEP operator record](../operators/legacy-tep.md) is historical guidance.
- The KARDi2 x86 vendor DLL and driver files remain live inputs even though older service
  sources are under `_legacy`. The shipped architecture is the [x64 service and x86 broker](../components/kardi2.md).
- NVX136's older DLL directory remains a test input after the `nvx136_2021` service retirement.
  Same-name vendor DLLs of different generations must stay isolated.
- Some deploy-only assets, including `emulator.exe`, have no equivalent source ownership in the
  active build. A directory name alone is insufficient reason to delete them.

Before a comparator build, inspect its own manifests and environment. The old Qt 5 toolchain
uses different compatibility constraints; [setup](../how-to/setup.md) routes to the relevant
historical configuration rather than assuming the current v143 recipe applies.

The retained distribution is `R:\dist_legacy\Qt5`, including `msvc64/` and the current
oracle location `_build/topo-ref/`. Historical records retain former `src_Qt5`/`dist_Qt5`
paths; the [layout migration record](../maintenance/layout-migration-2026-09-15.md) maps them.

See the [Qt 6 decision](../decisions/qt6-default.md), [migration records](../history/README.md)
and [code-local remaining-port record](../../src/docs/REMAINING_PORTS.md) for disposition and evidence.
