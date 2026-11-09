# 7. C++20 is requested but GCC 8.1 only has partial support

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-7-c20-is-requested-but-gcc-81-only-has-partial-support"></a>

### 7. C++20 is requested but GCC 8.1 only has partial support

**QT 5 ONLY.** `R:\src\CMakeLists.txt:7` still asks for C++20, but it is compiled by MSVC v143
14.44, which has it in full. GCC 8.1 survives only in the KARDi2 x86 island, and
`R:\src\KARDi2\qt5-island\CMakeLists.txt:5` asks that half for **C++17** explicitly. So there is no
GCC-meets-C++20 gap left in the default tree. The advice below still applies to `R:\src_Qt5`, whose
root also sets 20 and whose 32- and 64-bit MinGW builds are both GCC 8.1.

`R:\src_Qt5\CMakeLists.txt:6` sets `CMAKE_CXX_STANDARD 20`; every `.qbs` file asks for C++14 or
C++17. Nothing in the sources actually needs C++20. CMake maps `20` to `-std=c++2a` for GCC 8,
so it usually works — but if you hit a wall, lowering that line to `17` is safe.

---

