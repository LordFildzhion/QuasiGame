# 2b. `scriptEngines` is x64-only — ✅ gated 2026-08-11

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2b-scriptengines-is-x64-only---gated-2026-08-11"></a>

### 2b. `scriptEngines` is x64-only — ✅ gated 2026-08-11

**TRANSFERS UNCHANGED.** The same `WIN32 AND CMAKE_SIZEOF_VOID_P EQUAL 8` guard is in
`R:\src\scriptEngines\CMakeLists.txt`, and the engine's own `CMakeLists.txt` repeats it. The
"watch out on the x64 build" warning below is now handled for you: `build-qt6.ps1` passes
`-DPython_ROOT_DIR` and `-DPython_EXECUTABLE` for Python 3.12 explicitly, and the engine asks for
`find_package(Python 3.12 EXACT …)`, so CMake cannot drift onto the machine default.

Discovered while configuring the 32-bit build:

```
CMake Error at .../pybind11/FindPythonLibsNew.cmake:191 (message):
  Python config failure: Python is 64-bit, chosen compiler is 32-bit
```

`pythonEngine` embeds CPython, so it needs an interpreter of matching bitness, and only a
64-bit Python is installed. This matches the evidence: the shipped distribution has
`bin/engines/pythonEngine.dll` **only** in `distro-dual\msvc` (x64), never in `mingw32`.

`scriptEngines/CMakeLists.txt` now carries the same arch guard the other locked modules use:

```cmake
IF (WIN32 AND (CMAKE_SIZEOF_VOID_P EQUAL 8))
    add_subdirectory(python)
ENDIF()
```

If a 32-bit Python engine is ever genuinely wanted, install a 32-bit CPython 3.12 and point
the x86 configure at it with `-DPython_ROOT_DIR=...`.

**Watch out on the x64 build:** CMake will pick the *default* interpreter, which on this
machine is **3.14**, not the 3.12 that pybind11 2.11.1 needs. Pass
`-DPython_ROOT_DIR=C:/Users/Anatoly/AppData/Local/Programs/Python/Python312` when configuring
build64.

---

