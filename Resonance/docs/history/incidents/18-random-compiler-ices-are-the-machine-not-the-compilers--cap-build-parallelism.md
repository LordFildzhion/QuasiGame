# 11b. Random compiler ICEs are the machine, not the compilers — cap build parallelism

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-11b-random-compiler-ices-are-the-machine-not-the-compilers--cap-build-parallelism"></a>

### 11b. Random compiler ICEs are the machine, not the compilers — cap build parallelism

**TRANSFERS UNCHANGED — it is the machine, so the toolchain does not matter.** The Qt 6 build obeys
it: `build-qt6.ps1:85` is `--build $buildRoot -- -j 6`, and `build-kardi2-x32.ps1:52` the same. The
Conan half went *further* than `-j6`: `build-qt6.ps1:71` passes `-c 'tools.build:jobs=1'` because
MSVC 19.44 ICEd reproducibly compiling several copies of `gtest-all.cc` at once
(`R:\src\docs\PORTING_LOG.md`) — a fourth ICE, a third compiler, and the same shape as the three
below. Dependency builds are rare; the project build stays parallel.

Three internal compiler errors were hit while building the HDF5 dependency, **in a different
source file every time and across two different compilers**:

| Compiler | File | Error |
|---|---|---|
| GCC 8.1 (mingw64) | `H5Pgcpl.c` → `avx512vlintrin.h` | internal compiler error |
| MSVC 19.51 | `H5Dfill.c:311` | `fatal error C1001` |
| MSVC 19.51 | `H5Oalloc.c:228` | `fatal error C1001` |

Same-file determinism would mean a compiler bug; random files across two toolchains does not.
The Windows System log confirms it — **`Microsoft-Windows-WHEA-Logger` "corrected hardware
error"** events (Id 19/2) fire *during* these builds: 8 on the day of testing, and a burst of 86
on one day in June.

Machine: **i9-14900KF**, Gigabyte Z790 AORUS MASTER X, BIOS F11 (2025-12), **4 × 48 GB DDR5 at
5600 MT/s**, microcode **0x12F** — i.e. *newer* than Intel's 0x12B mitigation, so the
13th/14th-gen degradation patches are already applied.

**Reducing parallelism eliminated it.** Conan defaults to `-j32` on this CPU; at `-j6` the HDF5
build completed first try with **zero** WHEA events, and the subsequent Resonance build at `-j8`
produced no ICEs either.

Prime suspect is the memory controller: four dual-rank DDR5 DIMMs at 5600 MT/s is far above
Intel's 2-DIMM-per-channel rating for this platform. Worth testing at a lower memory speed.

**For builds, always cap jobs:**

```
conan install ... -c tools.build:jobs=6
cmake --build <dir> -- -j 6
```

This matters beyond convenience: silent bit-flips under load can corrupt a build without any
error at all. If ICEs recur at low `-j`, treat it as a hardware investigation, not a build one.

<a id="history-e-core-affinity-test-2026-08-11"></a>

### E-core affinity test (2026-08-11)

The full MSVC v142 build was run pinned to logical CPUs 16–31 — the **E-cores** on a 14900KF
(8 P-cores with HT occupy 0–15):

```bat
start /b /wait /affinity FFFF0000 cmd /c build.bat
```

Affinity was confirmed live on the running `cmake`/`conan`/`python` processes (`0xFFFF0000`);
child processes inherit it. Result: **163/163 targets, no ICEs, zero WHEA events.**

**But that run did not isolate the cause** — it changed *two* variables at once, `-j6` **and**
E-cores-only, and `-j6` on all cores had already been clean.

<a id="history-equal-thread-count-comparison-2026-08-11"></a>

### Equal-thread-count comparison (2026-08-11)

Same workload both times: a forced HDF5 rebuild
(`conan install … --build=hdf5/* -c tools.build:jobs=16`).

| Run | Affinity | Cores | `-j` | Duration | ICEs | WHEA |
|---|---|---|---|---|---|---|
| A | `FFFF0000` | 16 E-cores | 16 | 73 s | 0 | **0** |
| B | `0000FFFF` | 8 P-cores + HT | 16 | 47 s | 0 | **0** |

**Inconclusive — neither half reproduced the failure**, so nothing can be attributed to the
P-cores. (The 47 s / 73 s split does confirm the affinity masks took effect: without them both
runs would have used all 32 logical CPUs and taken similar time, and a ~1.5× P-over-E ratio is
what you would expect.)

What it *does* narrow down: every observed failure occurred at **`-j32`**, i.e. all 32 logical
CPUs saturated simultaneously. At `-j16` on either half, nothing. That points away from
"one core type is degraded" and toward something that only manifests at full-package load —
power delivery, thermals, or memory-controller saturation with 32 threads against four
dual-rank DIMMs at 5600 MT/s (well above the 2-DIMM-per-channel rating).

**To take this further, a reproducer is needed first:** confirm the failure returns on demand at
`-j32`, then bisect `-j24`/`-j20` for the threshold. Only with a reproducer does a P-vs-E split
become meaningful. Until then, `-j6` is the operating rule and this stays parked.

---

