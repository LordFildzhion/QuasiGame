# 8. Two build systems, drifting apart

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-8-two-build-systems-drifting-apart"></a>

### 8. Two build systems, drifting apart

**QT 5 ONLY — QBS is not a second build system in the Qt 6 tree, it is dead weight.** ⚠ Not because
the `.qbs` files were dropped: **29 of them crossed**, against 51 in `R:\src_Qt5` — seven module
products (`SignalGenerator.qbs`, `quickStimulus.qbs`, `nvx.qbs`, `nvx136.qbs`, `actiChamp.qbs`,
`KARDi2.qbs`, `SPEED.qbs`) plus test, `3dparty` and `scriptEngines` files. What did *not* cross is
the pair that makes them a project: there is **no `Resonance.qbs` and no `ResonanceApp.qbs` anywhere
in `R:\src`**, and each of those seven opens `import "../ResonanceApp.qbs" as ResonanceApp`, an
import that now resolves to nothing. No root project file to load and no product that loads, so the
Qt 6 tree cannot be built by QBS. Treat the surviving `.qbs` files as §9 material: files that look
alive and are not. The drift described below is real history for `R:\src_Qt5`, where both systems
still exist.

`.qbs` files and `CMakeLists.txt` files coexist and **disagree**:

* `Resonance.qbs` still references products that no longer build (`eyegamesDll`, `eyetribe`,
  `fileConverter`, `openBCI`, `Tests`, `Documentation`).
* The QBS build stamps git version info; CMake does not (issue 5).
* QBS asks for C++14/17; CMake for C++20 (issue 7).

The shipped 2024 binaries were made with QBS + Conan 1 + conda
(`ci/build_resonance*.bat`); the current branch is called `feature-conan2` and is CMake-based.
Treat CMake as the source of truth and the `.qbs` files as read-only reference — but be aware
that "it built with QBS" is not evidence that it builds with CMake.

**Measured 2026-08-11:** the two configure-time blockers §2 and §2c are *CMake-only*. QBS globs
`import/Resonance/**` (so the missing `Head.qml.bak` never bites) and never calls
`install_files_with_prefix`. Only the `stdout` bug (§2e) is source-level and therefore common to
both. In other words the CMake port had **never been run from a clean checkout**, while the QBS
build kept working — which is why nobody noticed. Do not assume parity between the two in
either direction.

---

