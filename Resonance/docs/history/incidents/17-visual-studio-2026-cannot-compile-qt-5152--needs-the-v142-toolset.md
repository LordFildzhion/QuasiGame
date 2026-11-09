# 11a. Visual Studio 2026 cannot compile Qt 5.15.2 — needs the v142 toolset

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-11a-visual-studio-2026-cannot-compile-qt-5152--needs-the-v142-toolset"></a>

### 11a. Visual Studio 2026 cannot compile Qt 5.15.2 — needs the v142 toolset

**QT 5 ONLY — a comparator constraint since 2026-09-02.** It is a *Qt 5.15.2* header
incompatibility, not a VS 2026 defect, so it says nothing about the default tree.
`R:\src\scripts\build-qt6.ps1:28` pins **`-vcvars_ver=14.44`** — MSVC **v143** 14.44, the archived
VS 2022 17.14 toolset shipped inside VS 2026 Build Tools, not VS 2026's default v145 — against
Qt 6.11.2, and that combination builds the whole tree. What still needs v142 is **rebuilding
`R:\src_Qt5`**, and only that; the `compiler.version=192` + `vs_version=18` Conan pairing goes with
it. The Qt 6 profile is `R:\src\profiles\msvc-v143-release`.
⚠ The last paragraph below — "v143 would probably also work" — is about compiling **Qt 5.15.2** with
v143 and is still untested. The Qt 6 build does not test it: it never compiles a Qt 5 header.
⚠ Do not read this section as "the newer toolset is unusable". It is unusable *against Qt 5.15.2*.

**Hard blocker, found 2026-08-11.** Not ABI — a header incompatibility.

MSVC's STL **removed** `stdext::checked_array_iterator`. In
`…\VC\Tools\MSVC\14.51.36231\include\yvals_core.h` the removal is recorded in the past tense:

```cpp
// STL4043 was "stdext::checked_array_iterator, stdext::unchecked_array_iterator,
// and related factory functions are non-Standard extensions and will be removed"
```

(`_MSVC_STL_VERSION 145`, `_MSVC_STL_UPDATE 202604L`.)

Qt 5.15.2 — frozen in 2020 — uses it unconditionally for MSVC,
`QtCore/qcompilerdetection.h:105-106`:

```cpp
#  define QT_MAKE_UNCHECKED_ARRAY_ITERATOR(x)    stdext::make_unchecked_array_iterator(x)
#  define QT_MAKE_CHECKED_ARRAY_ITERATOR(x, N)   stdext::make_checked_array_iterator(x, size_t(N))
```

so `qvector.h`, `qlist.h` and `qvarlengtharray.h` fail with
`error C3861: 'stdext': identifier not found` before any project code is even reached.
There is **no `#ifndef` guard**, so `-DQT_MAKE_CHECKED_ARRAY_ITERATOR=...` cannot override it,
and `_SILENCE_*` macros do not help — the feature is gone, not deprecated.

**Fix — ✅ applied: install the v142 toolset alongside VS 2026.** In the VS Installer →
*Отдельные компоненты*:

> `MSVC версии 142 — средства сборки C++ для VS 2019 для x64/x86 (версия 14.29–16.11)`

v142's `<iterator>:1404` still has `checked_array_iterator` (STL 142, update 202105), and it is
the **exact toolset Qt's `msvc2019_64` kit was built with** (`qconfig.pri` → MSVC 19.26.28806),
so it removes the ABI question too. Then:

```bat
call "…\VC\Auxiliary\Build\vcvarsall.bat" x64 -vcvars_ver=14.29
```

Two things that bite when doing this:

* **`'vswhere.exe' is not recognized`** is printed by `vcvarsall.bat` and is **benign** — the
  environment still initialises (`VCToolsVersion=14.29.30133`, `cl.exe` resolves to v142).
  Don't chase it.
* **Conan must be told the IDE version separately.** With `compiler.version=192` it looks for a
  *Visual Studio 16* installation, which does not exist — the v142 toolset lives inside VS 18:

  ```
  ConanException: VS non-existing installation: Visual Studio 16.
  ```

  Add to the `msvc64` profile's `[conf]`:

  ```ini
  tools.microsoft.msbuild:vs_version=18
  ```

v143 (14.4x) would probably also work — its STL still had `stdext`, only deprecated — but v142
is the exact match and is what the shipped binaries were built against.

Patching Qt's `qcompilerdetection.h` to `(x)` (the non-MSVC definition) is the other option: one
line, functionally harmless — the wrapper only ever existed to silence MSVC's checked-iterator
warnings — but it modifies the Qt installation and leaves the v14.51-vs-v14.29 ABI question open.

---

