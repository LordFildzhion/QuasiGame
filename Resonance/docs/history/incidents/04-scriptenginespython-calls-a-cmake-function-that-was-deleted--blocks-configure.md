# 2. `scriptEngines/python` calls a CMake function that was deleted — blocks configure

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2-scriptenginespython-calls-a-cmake-function-that-was-deleted--blocks-configure"></a>

### 2. `scriptEngines/python` calls a CMake function that was deleted — blocks configure

**FIXED BY THE PORT.** `install_files_with_prefix` appears nowhere in `R:\src` — not the shim, not
the call. `R:\src\scriptEngines\python\CMakeLists.txt` calls
`install_target(${PROJECT_NAME} "bin/engines")` directly, which is exactly the "cleaner long-term
fix" proposed below, and it is possible there because the Qt 6 tree has no submodule pointer to
bump. The compat shim survives only in `R:\src_Qt5\CMakeLists.txt:88`.
The second-order pybind11 risk is closed with it: the Qt 6 `conanfile.txt` **drops the
`pybind11/2.11.1` requirement entirely** and `build-qt6.ps1` points CMake at the pip-installed
**pybind11 3.1.0** under Python 3.12, which supports the NumPy 2.5.2 on this machine. The shipped
SPEED runtime in `R:\dist\python` is a separate, pinned NumPy 1.26.2.

The branch tip cannot configure with `scriptEngines` enabled. This is a genuine bug on
`feature/conan2`, not submodule drift — confirmed against the pinned commits.

`scriptEngines/python/CMakeLists.txt` @ `e2eed717` line 12:

```cmake
install_files_with_prefix(${PROJECT_NAME} "bin/engines")
```

The top-level `CMakeLists.txt` defines only `install_target`, `install_files` and
`install_directory`. Configure dies with *"Unknown CMake command install_files_with_prefix"*.

**Root cause, from history:** commit **`bad97c0` "Support mingw32"** deleted
`install_files_with_prefix` from the top-level `CMakeLists.txt` and replaced it with
`install_target`, but never updated the `scriptEngines/python` submodule, which still calls the
old name.

**Timing (measured 2026-08-11):** the `distro-dual` binaries were linked **2024-10-05 23:02**;
`bad97c0` was committed **23:14:33** — twelve minutes later. So the function still existed at
build time and the CMake build worked; it broke immediately afterwards and nobody has run CMake
on the branch since. (An earlier note here guessed the build was QBS — it was not; see
[deployed-vs-repo.md](../migrations/deployed-vs-repo.md).) Note the *clean* engine commit `642bfc6` calls
`install_files_with_prefix` too, so that call was never the anomaly — only `stdout` (§2e) is.

The deleted function (recoverable with `git show bad97c0 -- CMakeLists.txt`):

```cmake
function(install_files_with_prefix CURRENT_PROJECT_NAME PREFIX)
    set_target_properties(${CURRENT_PROJECT_NAME} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/runtime/${PREFIX}
        LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/runtime/${PREFIX}
        ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/runtime/${PREFIX})
    ...
endfunction()
```

`install_target(T PREFIX)` is the direct successor — same `RUNTIME/LIBRARY_OUTPUT_DIRECTORY`
and the same `install(TARGETS …)`. The only thing it drops is `ARCHIVE_OUTPUT_DIRECTORY`, which
just means the import library (`libpythonEngine.dll.a`) lands in the build root instead of
`runtime/bin/engines`. Irrelevant — `SPEED` loads engines with `QLibrary`, so no import library
is ever needed.

**✅ Applied 2026-08-11 — compat shim.** `install_files_with_prefix` is back in the top-level
`CMakeLists.txt` as a thin wrapper over `install_target` (plus the `ARCHIVE_OUTPUT_DIRECTORY`
the original set), so the submodule stays pinned and untouched. The cleaner long-term fix is
still to change line 12 of `scriptEngines/python/CMakeLists.txt` to
`install_target(${PROJECT_NAME} "bin/engines")`, commit that to `Resonance-engine-python` and
bump the pointer — at which point the shim can be deleted.

Also note: the shipped `pythonEngine.dll` imports **`python312.dll`**, while the submodule asks
for `find_package(Python 3.11 …)` and `conanfile.txt` pins `pybind11/2.11.1`. pybind11 2.11 does
not support Python 3.13+, so Python 3.12 is the sweet spot — that is what is installed.

Second-order risk on the same pin: **pybind11 2.11.1 predates NumPy 2** (support landed in 2.12),
and the NumPy installed here is 2.5.2. If the engine fails to compile inside `pybind11/numpy.h`,
either `pip install "numpy<2"` into the 3.12 interpreter or bump the `pybind11` pin. Not yet
tested — `scriptEngines` has not been built.

---

