# 5. `GeneratedBuildInfo` is broken in the CMake build

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-5-generatedbuildinfo-is-broken-in-the-cmake-build"></a>

### 5. `GeneratedBuildInfo` is broken in the CMake build

**TRANSFERS UNCHANGED.** `R:\src\Core\Resonance\GeneratedBuildInfo.hpp` is the same three
zero-initialised statics, and there is no generated `version.cpp` anywhere in the Qt 6 tree, so
`--version` still prints empty build/branch/date. ⚠ It matters *more* now, not less: with two
distributions on one machine and no git in `R:\src`, a binary cannot say which tree or which day it
came from. See [qt6-work-list.md](../migrations/qt6-work-list.md) §5.

`src/Core/Resonance/GeneratedBuildInfo.hpp`

```cpp
namespace Resonance { namespace GeneratedBuildInfo {
static const char *Date;
static const char *Revision;
static const char *Branch;
}}
```

These are **declarations of zero-initialised statics**, not `extern` declarations. The QBS build
supplied real values through `qbs/modules/git_version/git_version-module.qbs`, which generated a
`version.cpp` — but even there, `ResonanceApp.cpp` includes this header and gets its own
null copies.

Result: `--version` prints empty build/branch/date (`ResonanceApp.cpp:193-195`). No crash —
`QString::arg(const char*)` on `nullptr` yields an empty string — but the version info is
useless, and GCC will warn about unused statics in every TU that includes the header.

Fix: make them `extern const char* const` and generate a `version.cpp` from CMake with
`execute_process(git describe --tags --dirty)` + `configure_file`. Cheap, and it makes
deployed binaries traceable — which matters a lot for a lab tool that ships to several rigs.

---

