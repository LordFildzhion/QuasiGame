# 11c. ⚠ Ninja records NO header dependencies on this machine — every header edit builds a mixed binary

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-11c--ninja-records-no-header-dependencies-on-this-machine--every-header-edit-builds-a-mixed-binary"></a>

### 11c. ⚠ Ninja records NO header dependencies on this machine — every header edit builds a mixed binary

**TRANSFERS UNCHANGED — and it is now HANDLED inside the Qt 6 build script.** The hazard is a
property of this machine (a Russian-localized `cl.exe` on an OEM cp866 console) and of
`deps = msvc`, so it followed the tree across: `R:\src\_build\CMakeFiles\rules.ninja:17` stores the
same UTF-8 `msvc_deps_prefix` bytes, and every compile rule there is `deps = msvc`. What is
different is that **`R:\src\scripts\build-qt6.ps1` does it for you**: lines 39–46 carry a nine-line
comment naming this section, then

```powershell
chcp.com 65001 | Out-Null
[Console]::OutputEncoding = [Text.Encoding]::UTF8
```

before Conan, before `cmake` configure and before `cmake --build`, so configure and build are both
at 65001 and the prefix matches. **Build through the script and the hazard cannot arise.** It comes
back the moment somebody drives `cmake`/`ninja` by hand from an ordinary console, so the rule below
is still the rule.

**And it is working, measured 2026-09-02:** `R:\src\_build\.ninja_deps` is **3.99 MB** and lists
real header names — `AbstractStream.hpp`, `DataBlock.hpp`, `DebugConsole.hpp`, `qglobal.h` and the
rest. On a tree with this defect that file holds nothing. So no Qt 6 incremental build has been at
risk.

⚠ **This paragraph described the KARDi2 x86 island, retired 2026-09-02.** `build-kardi2-x32.ps1`
(now deleted) set no codepage and did not
need one: that build is MinGW GCC, whose ninja rules are `deps = gcc` with a real `depfile = $DEP_FILE`
(`R:\src\_build-kardi2-x32\CMakeFiles\rules.ninja:26-27`, and 34 `.d` files on disk). GCC writes the
dependency list to a file; nothing is parsed out of console text, so there is no prefix to mismatch.

⚠ **Both Qt 6 CMake caches are bound to the pre-rename path** (`CMakeCache.txt:2` in each reads
`r:/srcQt6/_build…`) and must be deleted before the next configure:
`rm -rf R:/src/_build R:/src/_build-kardi2-x32`. That is a clean start, so it also puts every
object on the correct footing for this section.

**Found 2026-08-19, and it is the most damaging thing in this file.** It is silent, it has been true
for the entire life of `R:\dist\_build\msvc64`, and it produces binaries that crash rather than
binaries that fail to build.

**The mechanism.** CMake probes `cl /showIncludes`' prefix at configure time and writes it into
`<build>\CMakeFiles\rules.ninja` — `R:\dist_Qt5\_build\msvc64\…` for the comparator,
`R:\src\_build\…` for Qt 6:

```
# localized /showIncludes string
msvc_deps_prefix = Примечание: включение файла:
```

This MSVC is **localized to Russian**, and CMake stores that string as **UTF-8** while `cl.exe`
emits it to the console in the **OEM codepage** (cp866 here). The two never match. So ninja parses
**zero** `#include` lines out of the compiler output, records **no header dependencies for any
target**, and the unmatched lines leak into the build log — which is where the mojibake noise in
every build log on this machine comes from. The noise is not cosmetic; it is the symptom.

**Verified, decisively:**

```bash
touch R:/src/tepService/service.hpp && ninja -n tepService
# [1/3] Automatic MOC and UIC for target tepService
# [2/3] Building CXX object ...\tepService_autogen\mocs_compilation.cpp.obj
# [3/3] Linking CXX executable runtime\bin\tepService.exe
```

`service.cpp:1`, `views.cpp:2` and `main.cpp:1` all `#include "service.hpp"`. **None of them is
rebuilt.**

⚠ Both reproducers in this section name `R:/src/tepService`, which is what that path was on their
dates. `tepService` is retired and retained as a Qt 5 comparator, so to re-run either one today the source
is `R:\src_Qt5\tepService\service.hpp` and the build directory `R:\dist_Qt5\_build\msvc64`. Under
Qt 6 the same probe is any header in `R:\src` against `R:\src\_build`.

**What that does.** Adding a member to a class in a header shifts every later member's offset. The
translation units that were not recompiled keep reading the old layout, and the link succeeds — so
the failure surfaces at run time as an access violation at a plausible-looking address. Measured
here: four members added to `TepService`, and `tepService.exe` faulted `0xC0000005` at `+0x280AD` on
the first epoch it painted, **4 runs out of 4**, at an identical fault RVA — a `movsd xmm0,
qword ptr [rax+8]` reached through a member offset. A full recompile of the module made it vanish.

⚠ **The unit tests do not catch it and cannot.** The GTest targets link only the pure logic files
(`pipeline.cpp`, `epochprocessor.cpp`, `dsp.cpp`, …), which carry no service-class layout
dependency, so **138/138 passed against the broken binary**. A green test run says nothing about
this class of fault.

<a id="history--the-fix--one-line-chcp-65001-in-the-build-environment"></a>

### ✅ The fix — one line, `chcp 65001` in the build environment

⚠ **It is an ENCODING mismatch, not a language one, and the obvious fix does not work.**
`set VSLANG=1033` is the standard advice and was tried first: on this box `cl.exe` still emits
Russian, because the Russian pack is the only one installed. Measured — identical bytes with and
without it.

What actually differs is the **console codepage**. Measured on the same `/showIncludes` line:

| console | bytes emitted for `Примечание` |
|---|---|
| `chcp 65001` (UTF-8) | `d0 9f d1 80 d0 b8 …` |
| `chcp 866` (OEM, the default here) | `8f e0 a8 ac a5 e7 …` |
| **what `rules.ninja` stores** | **`d0 9f d1 80 d0 b8 …`** |

CMake probed and stored **UTF-8**; the build runs in **cp866**. So make the build speak UTF-8.

**Qt 6, the default tree — use the script, which already does this:**

```powershell
& R:\src\scripts\build-qt6.ps1
```

**Qt 5 comparator, by hand** (`-vcvars_ver=14.29` is v142, §11a; the build directory moved with the
tree and is now `R:\dist_Qt5\_build\msvc64`):

```bat
call "…\vcvarsall.bat" x64 -vcvars_ver=14.29
set PATH=C:\Qt515\Tools\CMake_64\bin;C:\Qt515\Tools\Ninja;%PATH%
chcp 65001 >nul
cmake --build R:/dist_Qt5/_build/msvc64 -- -j 6
```

No reconfigure, no language pack, no admin rights. **Verified end to end 2026-08-20:** after one
build under `chcp 65001`, `touch R:/src/tepService/service.hpp && ninja -n tepService` schedules
`main.cpp.obj`, `service.cpp.obj` **and** `views.cpp.obj` — 6 edges where it previously scheduled 3
— and the leaked `включение файла` lines disappear from the build log, which is what says the prefix
is now matching.

⚠ **Ninja records a TU's dependencies only when it compiles it.** Every object compiled before this
fix still has none, so the guarantee is per-target until each has been rebuilt once under
`chcp 65001`. **Do one full recompile** (`--clean-first`, or delete `<build>/*/CMakeFiles/*/*.obj`)
to put the whole tree on the correct footing; after that, ordinary incremental builds are sound.

**If for any reason the build is run without it,** the old operating rule applies: any change
touching a **header** must be followed by a **forced full recompile of the affected module**, or the
binary is not made of one consistent set of headers.

⚠ This retroactively weakens every "built and verified" claim in these documents where the change
touched a header and only an incremental build followed. It does not invalidate results from a
clean or full build.

---

