# 2026-08-14 — the 2025 NVX driver is now `nvx` (merged, built, verified)

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx52.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-14--the-2025-nvx-driver-is-now-nvx-merged-built-verified"></a>

### 2026-08-14 — the 2025 NVX driver is now `nvx` (merged, built, verified)

`R:\src\nvx2025` has been merged into **`R:\src\nvx`**. There is one `nvx.exe`, in `bin\`, with
service name `NVX` and launcher `NVX.bat` — the isolated `bin\nvx2025` tree was staging, and
`R:\dist\msvc64` is again the single distribution. `nvx136` is untouched: different device,
different vendor DLL.

| | |
|---|---|
| Vendor SDK | `nvx\sdk\` — NVX API **2.3.21648** (`NVX_SDK_2025-09-08`), header + `x64\Release\nvxmcs.{lib,dll}` + `PowerUp.conf`. SHA-256 of the staged DLL matches the vendor package. |
| Superseded | `nvx\dll\x86_64\` still holds the 2021 **2.1.8683** DLL. Nothing references it. **Never pair it with this exe** — same file name, incompatible behaviour. |
| Removed | `NVXMCS.h` (the old in-tree SDK header). `NVXInfo.*`, `nvxdatathread.*`, `application.*`, `main.cpp` replaced wholesale. |
| Added | `nvxframelogic.h` (namespace renamed `nvx2025::logic` → `nvx::logic`), `tests/`. |

**Shipping defaults** (`application.cpp`): **1 kHz**, **block 100**, **trigger bitfield on**,
**first 32 EEG channels ticked**. The channel default is applied once, the first time a device
supplies a channel list, so a rate change or a saved parameter set never overwrites an operator's
selection.

**Two changes on top of the validated `nvx2025` code:**

* `std::bit_cast` → `static_cast` for the unsigned→signed sample conversion, and `/W4
  /permissive-` guarded with `if(MSVC)`. Both were MSVC-only constructs that would have broken
  the `mingw64` build of the whole tree; the conversion is identical under C++20.
* **CED metadata is only applied when a CED file was actually supplied.** `parseCED()` names
  every channel it has no label for `"?? N"`, and `describeOutputs()` cannot tell that apart
  from a real electrode name — so the previous unconditional `addCEDinfo(ced->binary(), …)` in
  `Application::start()` relabelled every EEG channel `?? 1 … ?? 32` on a default launch. The
  `nvx2025` validation campaign never saw it because the probes drive `NVXDataThread` directly
  and never went through `Application`.

**Verified against the connected NVX-52 (serial 1219)** through `NVX.bat` in `R:\dist\msvc64`,
driven over the wire with `ResonanceForeignDriver`:

| Check | Result |
|---|---|
| Defaults as published | `1 kHz (all channels)`, block `100`, `addTrigger` true, 52 offered / **32 ticked** (Ch 1–Ch 32) |
| Stream | `eeg`, **33 channels**, 1000 Hz, measured **998.3 Hz** over 9.84 s |
| Metadata | 32 × `EEG`/`V` named `Ch 1…Ch 32`, plus `Trigger`/`bitfield` |
| With `mks64_standard.ced` | EEG named `T7, TP9, P7, …`; `theta`/`radius` on electrodes only; Trigger untouched |
| Empty electrodes | NaN, exactly on Ch 21–28, 30–32 — the same finite set (Ch 1–20, 29) the 2026-08-14 campaign measured |
| Transport | **0 rows fully NaN** in 12,023 recorded rows |
| Recording | `recorderService` → `R:\dist\msvc64\data\` via `RESONANCE_RECORD_PATH`, HDF reopened and reconciled |
| Lifecycle | `stop` returned the service to `init`, `!terminate` exited cleanly; no hard reset |

`test_NvxFrameLogic` 5/5. The hardware probes (`nvx_sdk_hardware_tests`,
`nvx_driver_hardware_integration`, `nvx_stability_probe`, `nvx_sdk_counter_probe`) build into
`<build>\tests\nvx\` — **outside `runtime\`**, so they are never packaged — and the ctest cases
are registered `DISABLED` with label `hardware`. Evidence HDFs:
`R:\dist\_build\nvx-merge-check\`.

⚠ **`R:\src\nvx2025` is now redundant** and still on disk. Leaving two copies of the driver is
the same trap the operator guide warns about; delete it once this build is accepted.

⚠ **`mingw32` / `mingw64` are further behind** — they have never seen the 2025 NVX driver.

*If the dates below are old, verify before trusting — check `git status` in `R:\src` and
`R:\dist`.*

---

