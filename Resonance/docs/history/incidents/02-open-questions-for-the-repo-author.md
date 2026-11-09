# 0. Open questions for the repo author

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-0-open-questions-for-the-repo-author"></a>

### 0. Open questions for the repo author

**QT 5 ONLY — and both questions are now answered.** Question 2: `feature/conan2` is no longer the
tip. `R:\src_Qt5` HEAD is `fae69c3` *"Update documentation"* on **`feature/services-and-isolation`**,
with 14 uncommitted changes. And Qt 6 happened — not down `feature/cmake-qt6`, but as an isolated
re-port taken from that same commit on 2026-08-27 and promoted to `R:\src` on 2026-09-02
([transition notes](../migrations/qt5-to-qt6-transition.md)). Question 1 fell out of the same event: the Qt 6
tree is **MSVC v143 only**, and MinGW survives solely for the KARDi2 x86 island, which exists because
the vendor DLL is PE32/i386 — an architecture constraint, not a toolchain preference.
⚠ `R:\src` has no git repository at all (no `.git`, no `.gitmodules`), so "which branch" has no
answer there; the history lives only in `R:\src_Qt5`.

Short list, highest value first — the things that cannot be settled by reading the code.

*(A third question — "what was the Oct 2024 build made from, and is there unpushed work?" — was
dropped on 2026-08-11. PE timestamps against the commit log explained it completely; see
[deployed-vs-repo.md](../migrations/deployed-vs-repo.md). The build was CMake, `install_files_with_prefix`
still existed at build time, and `Head.qml.bak` was a stray working file, not lost work. Only
the `stdout` fix must have been local — and that is already reapplied.)*

1. **Is MSVC deliberate for the x64 branch, or historical?** MinGW-w64 8.1 now builds and runs
   the whole x64 tree (see [build-and-distro.md §4](../../how-to/build.md)),
   so it is not technically required. If MSVC is mandated by something invisible in the tree —
   compatibility with binaries already deployed on the rigs, a vendor support requirement,
   measured timing/latency behaviour — that should be recorded. Otherwise the dual build
   collapses to one toolchain.
   *Partially answered by the branches:* `feature/try-to-jump-to-qt6` carries
   `windows-x86_64-msvc2019_64` conan profiles (`compiler.version=193` — actually the VS 2022
   toolset, despite the filename), but they target a Conan-built Qt 6, not the Qt 5.15.2 kit the
   shipped distro uses. Intent, not recipe.
2. **Which branch is mainline, and is Qt 6 still the plan?** `feature/conan2` is the tip of
   everything — `develop` and `master` are 3–5 years stale and fully contained in it. Should
   work merge back to `develop`, or does `feature/conan2` become the new mainline? And is
   `feature/cmake-qt6` (2022, *"far from acceptable"*) still a live direction?

Lower value, answerable by testing: whether `fieldtrip` is 32-bit-only for a real reason (§ below).
`MSVCR90.dll` is now shipped app-locally for the Qt 6 EyeLink service.

---

