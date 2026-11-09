# Environment — ready, nothing left to install

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-environment--ready-nothing-left-to-install"></a>

### Environment — ready, nothing left to install

| | |
|---|---|
| Qt 5.15.2 | `C:\Qt515\5.15.2\{mingw81_32, mingw81_64, msvc2019_64}` |
| MinGW-w64 GCC 8.1 | `C:\Qt515\Tools\{mingw810_32, mingw810_64}` |
| MSVC | VS 2026 Build Tools, toolsets **14.29 (v142)** and 14.51 — **use v142** |
| C++/CLI | **"C++/CLI support for v142 build tools"**, added 2026-08-15 — brings `NETFXSDK\4.8` and `mscoree.lib`. Required by `neuronSpectrum`; without it that module fails at *link* time only |
| CMake / Ninja | 3.30.5 / 1.12.1, under `C:\Qt515\Tools` |
| Conan | 2.31.2, profiles `mingw32`, `mingw64`, `msvc64` |
| Python | 3.12.10 (+ pybind11, numpy, h5py) — `py -3.12` |
| .NET | Framework **4.8** runtime (inbox). No .NET Core/5+ SDK, and none needed |

