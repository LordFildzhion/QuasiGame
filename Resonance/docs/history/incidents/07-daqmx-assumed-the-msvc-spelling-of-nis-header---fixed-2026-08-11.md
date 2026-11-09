# 2d. `DAQmx` assumed the MSVC spelling of NI's header — ✅ fixed 2026-08-11

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2d-daqmx-assumed-the-msvc-spelling-of-nis-header---fixed-2026-08-11"></a>

### 2d. `DAQmx` assumed the MSVC spelling of NI's header — ✅ fixed 2026-08-11

**QT 5 ONLY.** `DAQmx` is one of three services not yet ported; its source and its
executable exist only in `R:\src_Qt5` and `R:\dist_Qt5\msvc64`. See
[qt5-still-needed.md §3.6](../migrations/qt5-still-needed.md). ⚠ The header trap below is not Qt-specific and
will apply verbatim the day the module is ported.

`NIDAQmx.h:58` typedefs `int32` as `signed int` for GCC-x64 but `signed long` otherwise, and
`driver.cpp` declared its callbacks with `long` — matching `DAQmxEveryNSamplesEventCallbackPtr`
only under MSVC. Now uses NI's own `int32`/`uInt32`/`TaskHandle`, correct under both.

Also: `NIDAQmx.h` spells 64-bit types `__int64`, guarded only for `__linux__`/`__APPLE__`. Under
MinGW that comes from `<_mingw.h>`, so **the header is not self-contained** — it must be
included *after* a standard or Qt header or you get *"'__int64' does not name a type"*.

Full write-up in
[build-and-distro.md §4](../../how-to/build.md).

---

