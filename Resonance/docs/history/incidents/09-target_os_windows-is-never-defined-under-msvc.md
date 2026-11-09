# 3. `TARGET_OS_WINDOWS` is never defined under MSVC

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-3-target_os_windows-is-never-defined-under-msvc"></a>

### 3. `TARGET_OS_WINDOWS` is never defined under MSVC

**FIXED BY THE PORT — in effect, not in the macro.** `R:\src\Core\Resonance\common.hpp:20` still
tests `__WIN32`/`__WIN64` and so is still never set under MSVC, but nothing in the Qt 6 tree reads
it any more. Both consequences below are gone: `QtWinExtras` does not exist in Qt 6 at all, and the
AppUserModelID call moved to `ResonanceApp.cpp:535`, guarded on `_WIN32` and calling
`SetCurrentProcessExplicitAppUserModelID` through `shell32` directly
(`Core/Resonance/CMakeLists.txt:138-140`). So the Qt 6 MSVC build *does* set the taskbar identity, and
the deployed `Resonance.dll` gains no Qt dependency for it. `DebugConsole.cpp:12` carries a comment
saying it uses `_WIN32` deliberately for exactly this reason. The KARDi2 x86 island still has the
Qt 5 shape (`KARDi2/qt5-island/Core/Resonance/ResonanceApp.cpp:11`), but it is compiled by MinGW
GCC, which *does* predefine `__WIN32`, so the block is live there.

`src/Core/Resonance/common.hpp:19`

```cpp
#if defined(__WIN32) || defined(__WIN64)
#define TARGET_OS_WINDOWS
#endif
```

MinGW GCC predefines `__WIN32`/`__WIN32__`. **MSVC predefines `_WIN32` / `_WIN64` only.**
So under MSVC the macro is never set and every guarded block silently vanishes:

* `ResonanceApp.cpp:9` — `#include <QtWinExtras/QtWin>`
* `ResonanceApp.cpp:291` — `QtWin::setCurrentProcessExplicitAppUserModelID(...)`

This is **observable in the shipped binaries**: `distro-dual\mingw32\bin\libResonance.dll`
imports `qt5winextras.dll`; `distro-dual\msvc\bin\Resonance.dll` does not. The MSVC build has
been shipping without the AppUserModelID call (which controls taskbar grouping / notification
identity) since forever, apparently unnoticed.

Fix is one line:
```cpp
#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32) || defined(__WIN64)
```
Do this deliberately though — turning the block back on under MSVC makes `Resonance.dll` newly
depend on `Qt5WinExtras.dll`, which must then be present in the deployed `qt\bin\`.

---

