# 2026-08-15 — KARDi2 audited and aligned to the 2020 SDK package

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-15--kardi2-audited-and-aligned-to-the-2020-sdk-package"></a>

### 2026-08-15 — KARDi2 audited and aligned to the 2020 SDK package

Full write-up: **[kardi2.md](../components/kardi2.md)**.

**`R:\equipment\MCS_KARDi2N_2020` is not a newer SDK.** Every header, the DLL, the test exe and
all six driver files are byte-identical to what `R:\src\KARDi2\3dparty` already held. The DLL is
PE32 i386 dated 2019-11-25. The package adds **two documents**, one of which matters: a 2023
supplement defining the trigger functions and the service-word bit layout. Both are now vendored
and the trees verified identical.

The real work was conforming the driver to the contract that package documents. The vendor's C++
header, its Delphi unit and its manual disagree on `K2Info`; the DLL settles it — every export is
`__stdcall` and `K2Info` is `ret 12`, i.e. **three** arguments.

| | |
|---|---|
| **`K2Info` was called with 2 of its 3 arguments** | 4-byte stack imbalance per call, in a loop over devices; `Size` came from stack garbage and the DLL rejects anything below 28. Undecorated exports meant MinGW's stdcall-fixup resolved it silently — the linker said `_K2Info@8`, now `_K2Info@12`. |
| **The `Driver` constructor never opened the device before querying it** | The DLL zeroes `Model` and `SerialNumber` on an unopened device, so the serial match could never succeed. |
| **The channel list was hardcoded to 12 channels** | The driver rejected any list that did not match the device, so the 3-channel KARDi2/4N and 9-channel KARDi2N **could never start**. |
| **`initialize()`'s result was discarded** | Every failure above still moved the service to `running` — no stream, no error, no log. |
| Plus 17 more | `K2SetDebugMode` declared `__cdecl` against a `__stdcall` export; a context-less lambda on the trigger stream (use-after-free) and duplicated on every reconfiguration; `1 << 31` UB making the cardio channel read −1; uninitialised `count` with `K2Read`'s result ignored; `startTimer(0)` spin at block 1; a dropped counter bit; partial frames discarded; the SDK driven from two threads; asynchronous device release on stop. |

Also corrected in the record: the sampling-rate list, the trigger bit numbers and the vendor
buffer sizes are all **fine** — disassembly shows `K2SetGain`/`K2GetVoltInBit` clamp to
`min(Size/4, 12)`, so the apparent overflow was not one.

**Verified:** builds clean under MinGW x86; the service launches, announces, joins discovery and
settles in `init`, identically to the shipped 2024 binary run as a control.
⚠ **Not verified: no KARDi2 hardware is attached.** Everything past enumeration is unexercised —
[kardi2.md §5](../components/kardi2.md) lists the four checks to run when a device is available.

**KARDi2 cannot be built for x64** — [kardi2.md §7](../components/kardi2.md). A 64-bit process cannot load a
32-bit DLL, and every one of the **20** `KARDi2.dll` copies on this drive is the same i386
binary. **MCS has confirmed no x64 build exists.** The *device* is x64-ready — `McsUsb30.sys`
ships amd64 and `McsUsb.inf` declares `[MCS.NTamd64]` — only the user-mode library was never
rebuilt.

