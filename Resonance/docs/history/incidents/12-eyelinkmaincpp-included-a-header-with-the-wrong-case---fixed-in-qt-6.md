# 6. `eyelink/main.cpp` included a header with the wrong case — ✅ fixed in Qt 6

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-6-eyelinkmaincpp-included-a-header-with-the-wrong-case---fixed-in-qt-6"></a>

### 6. `eyelink/main.cpp` included a header with the wrong case — ✅ fixed in Qt 6

The Qt 5 comparator still has this case error. The Qt 6 EyeLink port uses the correct
`<Resonance/ResonanceApp.hpp>` spelling and is present in `R:\src\eyelink` and `R:\dist\bin`.
`openBCI` remains `R:\src_Qt5` only. See [qt5-still-needed.md §3.5](../migrations/qt5-still-needed.md).

```cpp
#include <Resonance/resonanceapp.hpp>   // actual file: ResonanceApp.hpp
```

Compiles on Windows only because NTFS is case-insensitive. Harmless today; breaks instantly on
any cross-compile or case-sensitive filesystem. `openBCI/main.cpp` has the same problem *and*
the wrong extension (`resonanceapp.h`), which is one of the reasons that module is dead.

---

