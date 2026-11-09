# 2026-08-15 — the 2025 NVX136 driver is now `nvx136` (merged, built, verified)

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-15--the-2025-nvx136-driver-is-now-nvx136-merged-built-verified"></a>

### 2026-08-15 — the 2025 NVX136 driver is now `nvx136` (merged, built, verified)

`R:\src\nvx136_2025` has been merged into **`R:\src\nvx136`**, the same way `nvx2025` was merged
into `nvx` the day before. There is one `nvx136.exe`, in `bin\`, service name `NVX136`, launcher
`NVX136.bat`. **The staging distribution is now entirely redundant** — `R:\dist\msvc64-nvx2025`
and `R:\dist\_build\msvc64-nvx2025` hold nothing that `R:\dist\msvc64` does not, and
`module-overlay.cmake` there has been emptied so a reconfigure cannot resurrect a second copy.

| | |
|---|---|
| Vendor SDK | `nvx136\sdk\` — NVX136 DLL **1.5.21743** (`NVX136_Dev Kit_29-06-2025`), header, and the three FPGA bitstreams. Staged DLL SHA-256 matches the vendor package; the `.bit` files are byte-identical to the 2021 ones. |
| Superseded | `nvx136\Dll\` still holds the **1.4.19077 (2021)** SDK. Nothing references it. Same-name, incompatible — never pair it with this exe. |
| Added | `nvx136logic.h` (namespace renamed `nvx136_2025::logic` → `nvx136::logic`), `tests/`. |
| Fixed by the merge | [known-issues §4](../incidents/10-nvx136-library-path-depends-on-cmake_build_type---fixed-2026-08-15.md#history-4-nvx136-library-path-depends-on-cmake_build_type---fixed-2026-08-15): the library path no longer contains `${CMAKE_BUILD_TYPE}`, so a multi-config generator or `RelWithDebInfo` can no longer fail the link and silently install no DLL. |

As with `nvx`: `std::bit_cast` → `static_cast` and `/W4 /permissive-` guarded with `if(MSVC)`,
so the module does not break a MinGW build of the tree.

**Verified on the physical media converter, from `R:\dist\msvc64`:**

| Check | Result |
|---|---|
| Discovery | `Media converter #0`; parameter groups `default`, `hardware`, `adc`, `sync`, `trigger` |
| Channels | 137 offered (128 EEG + 8 AUX + Trigger) |
| Lifecycle | 3 clean start/stop cycles, each back to `init`; no hard reset |
| Recording | 4,993 rows × **33 channels** at 250 Hz, **0 NaN**, 255 blocks / 4,992 samples reconciled |
| Metadata | `Ch 1…Ch 32` + `Trigger`; kinds EEG/Trigger, units V/bitfield |
| Emulator tests | `nvx136_sdk_emulation_tests` and `nvx136_driver_emulation_integration` both pass |

Evidence HDFs: `R:\dist\_build\nvx136-verify\`. The tests build into `<build>\tests\nvx136\`,
outside `runtime\`, so nothing test-shaped reaches a distribution.

⚠ **Channels default to none selected**, so a bare Start fails with *"At least one output
channel must be selected"*. `nvx` got a 32-channel default on request; `nvx136` did not, because
picking 32 of 128 is a guess. Decide a default if operators keep hitting it.

