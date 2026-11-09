# NVX136 cold-start `-3` — verdict, fix, and the cold-window lab ladder — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/nvx136.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-nvx136-cold-start--3--verdict-fix-and-the-cold-window-lab-ladder"></a>


**Investigated 2026-08-22, read-only. Inputs:** the source/lifecycle diff and the SDK/binary diff,
reconciled and re-verified against the disassembly of `R:\src\nvx136\sdk\x64\Release\NVX136.dll`
(1.5.21743) and the current driver.

**Acted on 2026-08-22, same day. §8 is the change list.** Sections 0–1 and 4 describe the tree
*before* that change, and their line numbers are historical: `nvx136driver.cpp:395` no longer holds
the version block.

**Built, tested and deployed 2026-08-23 — §9 is that record.** The tree now compiles, the whole suite
passes, and the changed service runs. ⚠ **None of that touches the bug.** There is no NVX136 on the
development machine, so **H1 remains a strong inference from the disassembly and the history, not a
proven mechanism, until the cold ladder runs at the rig.** What §9 adds is that the fix is
*shippable* — not that it is *right*.

> **Symptom.** On a freshly powered-on NVX136, `NVXStart` returns `-3` for every configuration.
> After the vendor tool (NeoRec) has opened the device once, Resonance starts and keeps working
> until the next power cycle.
>
> ```
> NVXSetMirrorTriggers is not supported by this NVX136; leaving the device default
> NVX136 DLL/driver versions: 281497876496384 844442110066834
> NVXStart failed (NVX136 error -3)
> ```

---


<a id="history-0-the-verdict-without-hedging"></a>

## 0. The verdict, without hedging

**The evidence decides it, and it is not the firmware, not the bitstream, and not the SDK swap.**

> ⭐ **`NVXGetVersion`, called at `nvx136driver.cpp:395` in the gap between the last configuration
> call and `NVXStart`, is the regression.** It performs two unsolicited device transactions that
> share the DLL's single command-response slot — and its module selection — with the very query
> `NVXStart` performs first. It returns `NVX_ERR_OK` whether or not those transactions worked, so
> nothing in the log betrays it. It did not exist in this position in any build that ever started
> cold.

The chain, every link measured:

1. **`-3` is `NVX_ERR_FAIL`, and from `NVXStart` it means exactly one thing.**
   `NVXStart` (`0x18013CA90`) is a wrapper: find the handle (`-1` if absent), call
   `NVXDeviceReal::Start()`, `return ok ? 0 : -3`. There is no other detail in it.
2. **`Start()` has five ways to return false** (`0x180147E90`), and the *first hardware action it
   takes* is `GetPll`:

   | gate | address | condition |
   |---|---|---|
   | A | `0x180147EAE` | `byte[this+0xD2D98D8] != 0` — already started (flag only, no I/O) |
   | **B** | `0x180147ECC` | ⭐ `call [vtbl+0x210]` = **`GetPll`**, non-zero ⇒ false |
   | C | `0x180147FB6` | UART-channel latch `byte[this+0xD3C9BF0] == 0` (set by `Open`) |
   | D | `0x180148078` | `SelectDeviceCmd(i)` false, for any enabled module |
   | E | `0x1801480AF` | `Msp430CmdCycle(0x81)` unanswered (timeout `0x369` = 873 ms) |

3. **The cold device was answering fine right up to the version call.** `NVXSetPll`
   (`nvx136driver.cpp:314`) returned `NVX_ERR_OK` — proven by the log, which shows neither
   `NVXSetPll failed` nor `NVXSetPll is not supported` and which *reaches* the mirror-trigger line
   80 lines later. And `SetPll` (`0x180147890`) **begins with `call [vtbl+0x210]`** at
   `0x1801478CA` — the identical `GetPll` call that is gate B. ⭐ **Gate B demonstrably worked on
   this cold device, ~90 lines of driver code before `NVXStart` failed on it.**
   Everything else in `configureCommon` also returned OK cold: `NVXSetSettings`,
   `NVXSetPowerSave`, `NVXGetProperty` x2, `NVXSetChannelsEnabled`, `NVXSetAuxGain`. So did the
   whole of `probe()` — the channel list populated, which is how the operator could select rates at
   all. **The cold MSP430 command channel was healthy.**
4. **Between that proof and the failure there is exactly one call that touches the device.**
   Source order in `initialize()`: `configureCommon()` ends at `NVXSetMirrorTriggers`
   (`:342`) → `NVXGetVersion` (`:395`) → `NVXStart` (`:404`). `NVXSetActiveShieldGain` and
   `NVXSyncPulseSetParam` are not called in this configuration; the impedance block is not entered.
   `NVXSetMirrorTriggers` returns `-5` **before any I/O** (see §4). ⭐ **`NVXGetVersion` is the only
   thing standing between a working `GetPll` and a failing `GetPll`.**
5. **What `NVXGetVersion` actually does** (`GetVersion@NVXDeviceReal`, `0x180143F20`):
   - `Dll` ← the DLL's own file-version resource. **No device I/O.**
   - `Driver` ← a cached dword at `[obj+0x4C]`, byte-swapped. **No device I/O.**
   - `Cypress` and `McFpga` ← a raw **`CmdSend(0)`**, then a poll of the shared response slot with a
     **50 ms deadline in 5 ms `Sleep` steps, retried up to 3 times** (`0x180143FC0`–`0x180144072`).
   - `Msp430` and `CbFpga` ← **`Msp430CmdCycle(0xFF, …, timeout 0x369 = 873 ms)`**
     (`0x180144124`) — the module-identification command, issued **without a preceding
     `SelectDeviceCmd`**.
   - ⭐ **`return 0` unconditionally** (`0x180144196`). A total device timeout still reports
     `NVX_ERR_OK`.
6. **The shared response slot is the collision surface.** Both `GetVersion` and `GetPll` poll the
   same three fields — `byte[this+0xD3C9B99]` (answering command id), `byte[this+0xD3C9B9A]`
   (length), `[this+0xD3C9B9B]` (payload), gated by `dword[this+0xD3C9BDC]`. `GetVersion` waits for
   id `0x00`; `GetPll` waits for id `0x11`; **each discards any response that is not its own**
   (`0x180144017`, `0x1801435B1`). A response that arrives after its requester gave up is therefore
   consumed by — or collides with — the next requester's. `GetVersion` gives up after 3 x 50 ms.
7. **This is already known in-tree to corrupt device state.** The comment at
   `nvx136driver.cpp:385-393` records that `NVXGetVersion` issued *after* `Start` permanently kills
   an impedance sweep — 0 of 129 electrodes ever report, with `NVXImpedanceGetData` still returning
   `NVX_ERR_OK`. That is the same shared-slot / module-selection interference, measured on the same
   DLL, by us.
8. **It is new in this position, and only here.**

   | tree | sequence around Start | cold |
   |---|---|---|
   | `R:\src_git_branches\develop\nvx136` | `NVXOpen` (ctor, **once**) → `GetVoltages` → `SetSettings` → **`Start`** → `GetProperty`. **No `NVXGetVersion` anywhere.** | known good |
   | `R:\src_legacy\nvx136_2025` | … → **`Start`** (`:386`) → `GetVersion` (`:395`) | untested |
   | `R:\src\nvx136` (current) | … → **`GetVersion` (`:395`)** → **`Start` (`:404`)** | **fails** |

**Two competing sub-mechanisms, same fix.** Either (a) cold, the converter answers `CmdSend(0)`
slower than 150 ms, `GetVersion` abandons it, and the late answer desynchronises the slot that
`GetPll` reads at gate B; or (b) the un-preceded `Msp430CmdCycle(0xFF)` leaves the MSP430 addressing
a different module, so gate B's `0x11` goes to the wrong place (gate D re-selects, gate B does not).
Both are deterministic cold, invisible warm, independent of rate/block/mode, and both are removed by
taking the call out of that gap.

**What is *not* the cause — closed, with the observable that closed it:**

| killed | why |
|---|---|
| Bitstream not found / CWD-relative lookup | `LoadFpgaFromFile` (`0x1801450E0`) is called **inside `Open`** (`0x1801457E5`); failure makes `Open` return false ⇒ `NVXOpen` returns **NULL** ⇒ `NVXStart(NULL)` = **`-1`**, not `-3`. The log reaches `NVXStart` and prints a non-zero `Driver`, so a real device object existed. **The `.bit` was found and loaded.** |
| Stale 2020 `NVX136R2/R3.bit` vs NeoRec's 2023 copies | Real (our gateware is 3.5 years older) but **not loaded on this unit**: `SetMirrorTriggers` returning `-5` means the capability byte at `+0xD2D98DA` is 0, and that byte is written **only** by `SetFpgaRevision`, **only** as 0 for revision 0 ⇒ the DLL loaded plain `NVX136.bit` — **byte-identical to NeoRec's**. Keep as a latent issue for R2/R3 boards; it is not this bug. |
| "The new SDK needs an extra call" | Both DLLs export the **same 67 symbols**; `Open`, `Start`, `LoadFpga`, `LoadFpgaFromFile`, `SetFpgaRevision`, `GetVersion`, `GetPll`, `SetPll` are instruction-identical. The "new SDK" is a **new header**, not a new API. |
| `NVXSetDevices` re-enabling a module | `SetDevices` is `Enabled = Present & requested`; `UartChannelEnable` always leaves `Present == Enabled`; so `configureDevices()`'s `if (enabled != devices.Enabled)` is **never true**. Dead code, not a cause. |
| Configuration (rate, block, mode, device index, parameter refusals, another process) | Ruled out at the rig, and confirmed here: **none of gates A–E reads any of them.** |

---


<a id="history-1-ranked-hypotheses"></a>

## 1. Ranked hypotheses

Ranked by (likelihood x cheapness). **HERE** = settleable on this machine or by reading a log.
**COLD** = needs a genuinely cold device.

<a id="history-h1--nvxgetversion-in-the-pre-start-gap--leading-and-the-evidence-is-direct"></a>

### H1 — `NVXGetVersion` in the pre-`Start` gap. ⭐ *Leading, and the evidence is direct.*
**Mechanism** §0 steps 4–6.
**For:** gate B proven working 90 lines earlier via `SetPll`; sole intervening device access; two
transactions with hard timeouts and a shared response slot; already measured in-tree to destroy
device state; absent from every build that ever started cold; returns OK regardless of failure.
**Against:** we cannot prove *here* that the cold converter is slower to answer `CmdSend(0)`.
**Decisive experiment — COLD, and nearly free:** ⭐ *print all six version fields.* `Cypress`,
`McFpga`, `Msp430` and `CbFpga` are written **only** on the success paths of the two device
transactions; `Dll` and `Driver` — the only two the lab has ever printed — need **no device I/O at
all**. So: **cold, if `Cypress`/`McFpga`/`Msp430`/`CbFpga` read 0, or `NVXGetVersion` takes
≥150 ms, H1 is confirmed outright, before a single `Start` is attempted.** Warm they should be
non-zero and the call should take a few ms. Second confirmation: the same run with the call removed
starts cold.

<a id="history-h2--a-timeout-margin-not-a-state-corruption-start-just-needs-a-retry-here-informed-cold-decided"></a>

### H2 — a timeout margin, not a state corruption: `Start` just needs a retry. HERE-informed, COLD-decided.
**Mechanism** every DLL wait loop is a hard 3 x 50 ms or `0x369` = 873 ms; a cold converter that is
merely slow fails the first attempt and succeeds the second.
**For:** cheapest possible fix; explains rate/mode independence.
**Against:** `SetPll` succeeded first time cold, so the channel was not slow at that moment.
**Decisive experiment — COLD:** retry `NVXStart` 3 x with 250 ms between and log each attempt's
return **and elapsed ms**. Success on attempt 2 or 3 ⇒ H2. Bundle with H1's build; costs nothing.

<a id="history-h3--one-of-the-added-configuration-calls-leaves-the-cold-device-in-a-state-start-rejects"></a>

### H3 — one of the added configuration calls leaves the cold device in a state `Start` rejects.
(`NVXSetPowerSave`, `NVXSetChannelsEnabled`, `NVXSetAuxGain`, `NVXSetPll`, `NVXGetProperty`-before-Start.)
**For:** all are new relative to `develop`; `SetChannelsEnabled` and `SetPowerSaveCmd` are among the
handful of functions whose bodies actually changed 1.4 → 1.5.
**Against:** every one of them returned `NVX_ERR_OK` cold, and `SetPll` in particular *proved* gate B
healthy after all of them had run.
**Decisive experiment — COLD:** stage 3 of the ladder (§6) — `Open`, `SetSettings`, `Start` only.

<a id="history-h4--the-double-bring-up-probe-opens-and-closes-the-device-then-initialize-opens-it-again"></a>

### H4 — the double bring-up: `probe()` opens and closes the device, then `initialize()` opens it again.
**Mechanism** `develop` opened **once in the constructor** and closed **once in the destructor**;
the current driver does `shutdown(); open(); …; shutdown()` in `probe()` and `shutdown(); open(); …`
in `initialize()`, so a cold device gets **at least two full FPGA loads and two
`UartChannelEnable`/`Disable` cycles** before the first `Start` — more if the operator touches rate
or mode, since `updateChannels()` re-probes.
**For:** the largest lifecycle regression in the rewrite; genuinely absent from every good build.
**Against:** `Close` does call `UartChannelDisable`, so it is nominally clean; and this would more
naturally fail at `Open` than at `Start`; and warm survives the same double open.
**Decisive experiment — COLD, needs its own power cycle:** ladder stage 4 (§6) — the minimal
sequence as the **first** `Open` of the window.

<a id="history-h5--genuine-cold-hardwarefirmware-condition-unrelated-to-our-code"></a>

### H5 — genuine cold hardware/firmware condition, unrelated to our code.
**Residual** if H1–H4 all fail cold. The `develop` sequence run against the **1.5** DLL as the very
first thing after power-on either starts (⇒ the DLL and hardware are exonerated and the fault is
definitively in our call sequence) or does not (⇒ vendor question, not a code change).
**Decisive experiment — COLD:** ladder stage 4.

<a id="history-h6--latent-not-this-bug-our-nvx136r2bit--nvx136r3bit-are-from-2020-neorecs-from-2023"></a>

### H6 — latent, not this bug: our `NVX136R2.bit` / `NVX136R3.bit` are from 2020, NeoRec's from 2023.
Irrelevant to a revision-0 board but a live risk the day an R2/R3 converter appears.
**Settle HERE:** copy NeoRec's two files into `R:\dist\msvc64\bin` and into
`R:\src\nvx136\sdk\firmware`. **Do not do it in the same build being used to test H1** — one
variable at a time.

<a id="history-h7--latent-abi-skew-nvx_devices_count_max-went-3--4-between-the-headers"></a>

### H7 — latent ABI skew: `NVX_DEVICES_COUNT_MAX` went 3 → 4 between the headers.
`t_NVXErrorStatus` grew 4 bytes. Anything still compiled against `Dll/include/nvx.h` overruns.
**Settle HERE, free:** confirm no translation unit reaches the old header. Cannot cause `-3`.

---


<a id="history-2-the-fix--written-2026-08-22-built-and-deployed-2026-08-23-still-unproven-on-hardware"></a>

## 2. The fix — written 2026-08-22, built and deployed 2026-08-23, still unproven on hardware

> ⭐ **Status.** Everything in §2, §3 and §5 below is implemented, **compiled, exercised against the
> vendor emulator and deployed to `R:\dist\msvc64`**, and §6's ladder exists as
> `R:\config\lab\nvx136_coldprobe.py`. Nothing has touched an NVX136 — there is no such hardware on
> the development machine. **H1 remains a strong inference
> from the disassembly and the history, not a proven mechanism, until the ladder runs.** See §8 for
> the change list.



**Change 1 (the fix). Take `NVXGetVersion` out of the acquisition path entirely.**
Delete the block at `nvx136driver.cpp:394-396`. Read the versions **once, at the end of
`probe()`, immediately before its `shutdown()`**, and cache the six values in the driver for the
config UI and the log.
*Why there:* not after `Start` (keeps the impedance-sweep fix the current placement was made for),
not adjacent to `Start` (nothing left in the gap), and in a code path whose only product is a
channel count — if the call does disturb the device, it costs a channel-list refresh, not a session.
*Alternative if `probe()` is inconvenient:* immediately after `NVXOpenEx` in `open()`. Slightly
worse — a disturbance there would surface as a failure in `SetSettings`/`GetProperty`, which is at
least a named, visible failure rather than a silent one.
*Risks:* (i) `McFpga`/`CbFpga` may only be meaningful after `Start` — unknown, and we must **not**
re-read after `Start` to find out; record the values seen and compare cold vs warm instead.
(ii) if H1 is wrong, this changes nothing and costs nothing.

**Change 2 (cheap insurance, independently testable). Retry `NVXStart`.**
Up to 3 attempts, 250 ms apart, `qInfo` per attempt with return code and elapsed ms. Gate A
("already started") is a flag check with no I/O, so a retry after a failed start is harmless.
*Risk:* masks a real fault — mitigated by logging every attempt, and by the fact that a warm start
never retries.

**Change 3 (diagnostics). §3 below.**

**Change 4 (follow-up, not now). Single open per service run.**
Restore `develop`'s lifetime: open once, reuse the handle for `probe()` and `initialize()`, close on
shutdown. This is the H4 fix and a real simplification, but it touches the whole driver lifecycle —
land it only after H1 is confirmed or refuted, and never in the same build.

**Not proposed:** shipping NeoRec's bitstreams in the H1 test build (H6 — separate change, separate
build), and anything to do with `NVXLoadFpga`, working directory, or the `.bit` search path (closed).

---


<a id="history-3-the-cold-start-diagnostic-the-service-should-emit"></a>

## 3. The cold-start diagnostic the service should emit

The lab's own complaint is that `NVXStart failed (NVX136 error -3)` reads like a configuration
fault. It is not one, and the driver can say so with certainty because **no gate in `Start()` reads
any configured value.**

**What to measure at the moment of failure**

1. **Elapsed ms of the failing `NVXStart`** — this is the only thing that separates the gates, and
   it costs one `QElapsedTimer`:

   | elapsed | gate | meaning |
   |---|---|---|
   | < 10 ms | A or C | the DLL believes the device is already started, or the UART channel latch is clear — `Open` did not complete properly |
   | ~50–200 ms | **B** | the PLL query (`0x11`) went unanswered — 3 x 50 ms |
   | ~870 ms, or a multiple | B or D/E | an `Msp430CmdCycle` timeout (`0x369`): `PllGetFrequency`, or the per-module select `0x81` |

2. **`NVXGetVoltages` immediately after the failure.** 16–32 ms on this converter and known to work
   (`readVoltages()`, `nvx136driver.cpp:773`). It is a live MSP430 round trip:
   *succeeds* ⇒ the command channel is alive and `-3` came from the PLL or module-select query
   specifically; *fails* ⇒ the channel is wedged, which is H1's signature.
3. **All six version fields** (§5) and **`NVXGetErrorStatus`** (`Samples`, `Crc`, `Counter`,
   `Devices[0..3]`) and the `t_NVXDevices` `Present`/`Enabled` masks.

**What it should say** — replacing the bare `NVXStart failed (NVX136 error -3)`:

```
NVXStart failed: NVX136 error -3 (NVX_ERR_FAIL), after 873 ms, on attempt 3 of 3.

This is NOT a configuration error. No sampling rate, block size, mode, channel
selection or device index can produce it: inside the SDK, Start() returns -3 only
when the media converter stops answering its control commands -- the PLL query, or
the per-module select. Every setting was accepted by the device moments earlier.

  elapsed 873 ms  -> an MSP430 command timed out (PLL frequency, or module select)
  NVXGetVoltages after the failure: FAILED (-3)   <- the control channel is wedged
  versions: dll 1.5.21743.0  driver 3.4.1.146  cypress 0.0.0.0
            mc-fpga 0.0.0.0  msp430 0.0.0.0  cb-fpga 0.0.0.0
            (zeros mean the device did not answer the version queries)
  devices: present 0x1  enabled 0x1
  error status: samples 0  crc 0  counter 0  devices 0/0/0/0

Most likely the amplifier has not been brought up since it was powered on.
Power-cycle the amplifier and try again. If it still fails, open the vendor tool
(NeoRec) once, close it, and start again -- and send this whole block.
```

Every line above is produced from calls the driver already links, and none of them needs hardware to
implement.

---


<a id="history-4-nvxsetmirrortriggers-is-not-supported--not-a-cause-but-the-best-free-readout-in-the-log"></a>

## 4. `NVXSetMirrorTriggers is not supported` — not a cause, but the best free readout in the log

`SetMirrorTriggers@NVXDeviceReal` (`0x180147700`) is:

```
cmp byte ptr [rcx+0D2D98DAh],0    ; FPGA-revision capability flag
mov r14d,0FFFFFFFDh
jne <do the work>
lea eax,[r14-2]                   ; = -5  NVX_ERR_SUPPORT
ret                               ; returns BEFORE any device I/O
```

**Zero side effects — it cannot leave the device half-configured**, and
`applyOptionalSetting` (`nvx136driver.cpp:47-62`) tolerates it correctly. The same flag gates
`GetMirrorTriggers`, `SyncPulseGetParam`, `SyncPulseSetParam`.

But that byte is written **only** by `SetFpgaRevision` (`0x180147580`), and only as 0 for
revision 0. So the message is a free, exact readout of **which bitstream the DLL chose**:

| message | revision | file loaded |
|---|---|---|
| present (`-5`) | 0 | `NVX136.bit` — identical to NeoRec's copy |
| absent (`0`) | 1 or 2 | `NVX136R2.bit` / `NVX136R3.bit` — **ours are from 2020, NeoRec's from 2023** |

⭐ **Worth capturing warm as well as cold.** If it is present warm too, the board is genuinely
revision 0 and H6 is irrelevant to it forever. If it is *absent* warm, revision detection itself
differs between cold and warm — which would be a finding in its own right.

---


<a id="history-5-the-version-print--implemented"></a>

## 5. The version print — implemented

> **Where it lives now.** The decoder is `nvx136::logic::decodeVersion` / `versionText` in
> `R:\src\nvx136\nvx136logic.h:23-63` — a header-only pure function, so it is unit-testable
> without Qt, the SDK or a device (`R:\src\nvx136\tests\logic_test.cpp`, target
> `test_Nvx136Logic`). The formatting and the two warnings are
> `Nvx136Driver::versionLine` / `logVersions`, `R:\src\nvx136\nvx136driver.cpp:125-162`.
>
> One deliberate change from the sketch below: the "device did not answer" warning fires on
> `!(cypress || mcFpga || msp430 || cbFpga)`, i.e. **all four** zero, not **any** of them. The
> four fields come from two different transactions, and a converter that answered one and not the
> other is a different and more interesting result than one that answered neither — an `any`
> test would collapse them into the same message.
>
> The Python ladder carries the same decoder, checked against the same two values
> (`nvx136_coldprobe.py`, `decode_version`), and its `--selftest` asserts both.



`t_NVXVersion` (`R:\src\nvx136\sdk\include\nvx.h:60-67`, `#pragma pack(push,1)`, unchanged from the
old header) is six `unsigned long long`: `Dll, Driver, Cypress, McFpga, Msp430, CbFpga`. Each packs
**four u16 fields, major first**:

```
value = (major << 48) | (minor << 32) | (build << 16) | revision
```

Verified against an independent source, not fitted to the story:

| raw | decoded | cross-check |
|---|---|---|
| `281497876496384` | **DLL 1.5.21743.0** | exactly the `FileVersion` resource of `sdk\x64\Release\NVX136.dll`, and the in-tree comment "Measured on DLL 1.5.21743" |
| `844442110066834` | **driver 3.4.1.146** | Cypress `cyusb.sys`; note our `Driver\` package ships **3.4.5.0**, i.e. the rig has an *older* one |

(It is **not** the little-endian 4xu16 reading — that gives the same digits in reverse field order.)

Replacing `nvx136driver.cpp:395-396`:

```cpp
static QString nvxVersion(unsigned long long v)
{
    return QStringLiteral("%1.%2.%3.%4")
            .arg((v >> 48) & 0xFFFFu).arg((v >> 32) & 0xFFFFu)
            .arg((v >> 16) & 0xFFFFu).arg( v        & 0xFFFFu);
}

t_NVXVersion version{};
QElapsedTimer versionTimer;
versionTimer.start();
NVXGetVersion(m_handle, &version);            // returns NVX_ERR_OK even on total timeout
const qint64 versionMs = versionTimer.elapsed();
qInfo().noquote() << QStringLiteral(
        "NVX136 versions: dll %1  driver %2  cypress %3  mc-fpga %4  msp430 %5  cb-fpga %6"
        "  (query took %7 ms)")
        .arg(nvxVersion(version.Dll), nvxVersion(version.Driver), nvxVersion(version.Cypress),
             nvxVersion(version.McFpga), nvxVersion(version.Msp430), nvxVersion(version.CbFpga))
        .arg(versionMs);
if (version.Cypress == 0 || version.McFpga == 0 || version.Msp430 == 0 || version.CbFpga == 0) {
    qWarning().noquote() << "NVX136 did not answer the on-device version queries "
                            "(zero fields above); the converter's control channel is not "
                            "responding normally. NVXGetVersion reports success regardless.";
}
```

⭐ **Print all six, and the elapsed time.** `Dll` and `Driver` — the only two ever printed — are
filled from the DLL's own resource and a cached dword, with **no device communication whatsoever**.
The four that mean something are the four that were missing. This one line is simultaneously the
display fix *and* the decisive instrument for H1.

---


<a id="history-6-the-cold-window-lab-ladder--rconfiglabnvx136_coldprobepy"></a>

## 6. The cold-window lab ladder — `R:\config\lab\nvx136_coldprobe.py`

> ⚠ **The cold window exists once per power cycle and closes at the first success.** Nothing else
> may touch the amplifier first — not NeoRec, not a previous Resonance run, not a warm reboot of
> the PC with the amplifier left on.
>
> ⭐ **A *failed* start does not warm the device** — the lab reproduced the identical cold failure
> twice. So a ladder of sequences can be run inside one power cycle, as long as none of them
> succeeds. Stop at the first success; that is the answer, and the window is over.
>
> ⚠ **SUPERSEDED IN PART, 2026-08-25.** The claim above was made about repeating one sequence
> *in place*. The 2026-08-24 field report says the cure is a **failed start followed by a
> re-open**, and every stage in the ladder is bracketed by its own `NVXOpenEx`/`NVXClose` — so
> stage N+1 *is* stage N's cure, and consecutive Start-attempting stages are not independent
> trials. This is not a contradiction of the sentence above so much as a case it did not
> consider. Consequences:
>
> * The ladder now runs a **`recovery` control stage** between `current` and `nogetversion`: the
>   same sequence as `current`, `NVXGetVersion` included, on a fresh open. If `recovery` starts,
>   the re-open is the cure and H1 is not implicated. Only if `recovery` fails and
>   `nogetversion` starts is H1 confirmed. The old ladder would have printed "H1 confirmed" for
>   the wrong reason and spent the only cold window there is.
> * **A competing hypothesis is not excluded and should be, at the bench.** The operator's cure
>   is a *second launch* — a new process, which unloads and reloads `NVX136.dll` and its
>   process-global device table. The in-process `NVXClose`/`NVXOpenEx` the driver now performs
>   does not. If the ladder gives up at 20 s on a converter that a second launch then starts,
>   that is the answer, and the fix is a different one.
> * **The recorded symptom in §1 still names NeoRec**, not a second Resonance launch, as the
>   cure. Both accounts are in this document and neither has been re-measured.

<a id="history-python-and-ctypes-not-a-c-console-tool"></a>

### Python and ctypes, not a C++ console tool

The plan above called for `nvx136coldprobe.exe`. What was written is a Python script driving the
same `R:\dist\msvc64\bin\NVX136.dll` through `ctypes`, and the reasons are practical rather than
stylistic:

* **It has already been run end to end.** `--emulation` drives the vendor emulator, and the whole
  ladder was executed on the development machine on 2026-08-22: `NVXOpenEx`, `NVXGetVersion`,
  `NVXGetVoltages`, `NVXSetSettings`, `NVXSetChannelsEnabled`, `NVXStart`, `NVXStop`, `NVXClose`
  all called, all structures round-tripped, `Dll` decoding to **1.5.21743.0** off a live call. A
  binary that cannot be built here would arrive at the lab unexercised.
* **It can be edited while the window is open.** No compiler on the lab PC, no build step, and
  the rest of `R:\config\lab\` is standard-library Python for exactly this reason.
* **The structure layouts are checked before anything opens.** `--selftest` verifies all seven
  `ctypes` structures against the byte sizes `nvx.h` compiles to and refuses to run on a mismatch,
  which is the one failure mode a hand-written FFI has and a C++ tool does not.

<a id="history-ordering-what-changed-from-the-plan-and-why"></a>

### Ordering: what changed from the plan, and why

The plan's step 0 (`--inspect`) opened with `NVXGetVersion`. That is the call under suspicion of
wedging the converter, so putting it first risks poisoning every later step in the same window —
the one resource that cannot be replaced. The ladder therefore splits it in two, and adds a
measurement that needs no `Start` at all:

| # | command | what it does | what a result means |
|---|---|---|---|
| **0** | `--stage=safe-inspect` | `OpenEx` → `GetVoltages` → **`GetPll`** → `GetDevices` → `GetProperty` → `GetMirrorTriggers` → `GetErrorStatus` → `GetVoltages` → `GetPll` → `Close`. **Read-only: no `GetVersion`, no `Start`, no writes.** | Cannot warm and cannot wedge, so it is free. ⭐ `GetPll` here is **gate B itself, measured cold, before anything has touched it** — the note argues gate B is healthy cold via `SetPll`; this measures it directly. Also the supply voltage and, from the `GetMirrorTriggers` return, the board revision. `GetMirrorTriggers` rather than `SetMirrorTriggers`: same capability gate, same `-5`, and it writes nothing. |
| **1** | `--stage=version` | `OpenEx` → `GetVoltages`/`GetPll` → **six-field `GetVersion` + elapsed** → `GetVoltages`/`GetPll` → `Close`. **Still no `Start`.** | ⭐ **The money shot, and it needs no `Start`.** Zeros in `Cypress`/`McFpga`/`Msp430`/`CbFpga`, or ≥150 ms, confirm H1's *premise*. And the repeat of `GetVoltages`/`GetPll` afterwards tests H1's *mechanism* end to end: **answering before the version query and not after is H1, measured, with no `Start` in the experiment at all.** |
| **2** | `--stage=current` | the exact current service sequence, `GetVersion` included, `Start` ×3 timed. **Nothing between `GetVersion` and `Start`** — not even a `GetVoltages`, because `GetPll` would read the very slot the experiment is about. | Reproduces cold. The elapsed ms of the failing `Start` names the gate (§3 table). Success on attempt 2 or 3 ⇒ **H2**, and the window closes. |
| **3** | `--stage=nogetversion` | identical, minus `NVXGetVersion` | ⭐ **success ⇒ H1 confirmed, stop here.** |
| **4** | `--stage=minimal` | `Open` → `GetVoltages` → `SetSettings` → `Start` ×3 (the `develop` sequence) | Success ⇒ **H3**. Failure ⇒ H3 dead. |
| **5** | *(power-cycle first — must be the window's first `Open`)* `--stage=minimal` | same, as the first open after power-on | Success ⇒ ⭐ **H4**. Failure ⇒ **H5**: vendor question, not a code change. |
| **6** | run **NeoRec** once, close it, then `--warm` | steps 0–2 warm | ⭐ The warm/cold delta. **Capture it even if the diagnosis already succeeded.** |

`--ladder` runs steps 0–3 in order and stops at the first successful start. Steps 4–6 are separate
invocations by definition.

Every stage brackets itself with `GetVoltages` (16–32 ms, known good) and `GetPll` (gate B), so
the transcript is a trace of the control channel's state rather than a single verdict: it says
*which call* the channel was alive before and dead after. Every call prints its name, return code
and elapsed ms. Everything printed is also written to `nvx136-cold-<stage>-<timestamp>.log` and
`.json` in the invocation directory — there is one window and the scrollback is not evidence.

The tool refuses to run if `nvx136.exe`, `NeoRec.exe` or `nvx.exe` is already running, chdirs to
the DLL's own directory so the `.bit` lookup inside `NVXOpenEx` cannot fail for a reason unrelated
to the investigation, and prints a verdict paragraph naming the hypothesis each result supports.

**Carry to the lab (build and stage before leaving):**

- A Resonance build with §2's changes 1–3. One build. ⚠ **Not yet built.**
- `R:\config\lab\nvx136_coldprobe.py`, which needs no build. Run `--selftest` on the lab PC first.

<a id="history-the-original-plan-kept-for-reference"></a>

### The original plan, kept for reference

The table below is superseded by the one above; the difference is the ordering argument and the
split of step 0 into `safe-inspect` + `version`.

| # | command | what it does | expected | what a result means |
|---|---|---|---|---|
| **0** | `nvx136coldprobe --inspect` | `OpenEx` → **six-field `GetVersion` + elapsed** → `GetVoltages` → `GetDevices` → `GetProperty` → `SetMirrorTriggers` (return only) → `GetErrorStatus` → `Close`. **No `Start`.** | — | ⭐ **The money shot.** `Cypress/McFpga/Msp430/CbFpga` = 0, or `GetVersion` ≥150 ms ⇒ **H1 confirmed before any Start.** Non-zero and fast ⇒ H1's premise is dead; go on knowing it. Also records the revision (mirror-trigger return) and the supply voltage. |
| **1** | `--stage=current` | the exact current sequence, `GetVersion` included, `Start` x3 with timings | `-3` | Reproduces cold. The **elapsed ms** of the failing `Start` names the gate (§3 table). If attempt 2 or 3 succeeds ⇒ **H2**, and the window closes. |
| **2** | `--stage=nogetversion` | identical, minus `NVXGetVersion` | ⭐ **success ⇒ H1 confirmed, stop here** | This is the whole trip. If it starts, the fix is §2 change 1 and nothing else. |
| **3** | `--stage=minimal` | `Open` → `GetVoltages` → `SetSettings` → `Start` x3 (the `develop` sequence) | — | Success ⇒ one of the added configuration calls is at fault ⇒ **H3**; cycle 2 bisects. Failure ⇒ H3 dead. |
| **4** | *(power-cycle first — must be the window's first `Open`)* `--stage=minimal` | same, but as the first open after power-on | — | Success ⇒ ⭐ **H4**: the repeated open/close is the culprit. Failure ⇒ **H5**: the `develop` sequence itself fails cold on the 1.5 DLL — the DLL/hardware is at fault, and the next step is a vendor question, not a code change. |
| **5** | run **NeoRec** once, close it, then repeat step 0 and step 1 warm | — | start OK | ⭐ The warm/cold delta of the six version fields, of `GetVersion`'s elapsed ms, and of the mirror-trigger return is the confirmation of whatever step 0–4 found. **Capture it even if the diagnosis already succeeded.** |

<a id="history-record-for-every-step"></a>

### Record for every step

Full stdout with per-call return codes and elapsed ms; the six version fields verbatim; the
mirror-trigger return; `GetVoltages` VDC; `GetErrorStatus` counters; `Present`/`Enabled` masks; and
the wall-clock time since the amplifier was powered on.

<a id="history-do-not-during-cycle-1"></a>

### Do not, during cycle 1

Open NeoRec; change the bitstreams; install a different Cypress driver; change the sampling rate or
block size (proven irrelevant, and each change re-probes the device); or run the service from a
different working directory *as an experiment* — the CWD question is closed (§0), and varying it now
only adds a confound.

<a id="history-if-the-ladder-finds-nothing-h5"></a>

### If the ladder finds nothing (H5)

Then the deliverable of the trip is: the step-0 numbers cold and warm, the failing `Start` elapsed
time, and the `develop`-sequence result. Those four facts turn "it does not start" into a specific
vendor question — *"on a cold NVX136 revision 0, `NVXStart` returns `-3` after N ms with
`Cypress/McFpga/Msp430/CbFpga` reading zero; what host-side initialisation does NeoRec perform that
`NVXOpenEx` does not?"* — which is worth far more than another guess.

---


<a id="history-7-files"></a>

## 7. Files

- `R:\src\nvx136\nvx136driver.cpp` — `:47-62` `applyOptionalSetting`; `:149` `NVXOpenEx`;
  `:151-171` `configureDevices` (dead code); `:314` `NVXSetPll`; `:342` `NVXSetMirrorTriggers`;
  **the version block moved out of `initialize()` — see §8**; `:773` `readVoltages`
- `R:\src\nvx136\nvx136config.cpp` — `:376` `probe()` from `updateChannels()`; `:456` `initialize()`
  from `start()` — the two opens per run
- `R:\src\nvx136\sdk\include\nvx.h` — `:33-38` error codes; `:44` `NVX_DEVICES_COUNT_MAX`;
  `:60-67` `t_NVXVersion`; `:144-149` `t_NVXErrorStatus`; `:185-200` `t_NVXVoltages`
- `R:\src_legacy\nvx136_2025\nvx136driver.cpp` — `:386` `Start`, `:395` `GetVersion` (pre-move order)
- `R:\src_git_branches\develop\nvx136\nvx136driver.cpp` — `:15-26` single open in the ctor, close in
  the dtor; `:17,19,91,93,97` the last sequence known to start cold
- `R:\dist\msvc64\bin\NVX136.dll` — byte-identical to `sdk\x64\Release\NVX136.dll`
  (md5 `4b4bdda0…`, 1 466 856 B); shipping is correct
- Disassembly and analysis scratch:
  `C:\Users\Anatoly\AppData\Local\Temp\claude\R--\1e4aa778-d1c1-40e9-ac52-f0088690d49c\scratchpad\`
  (`new.asm`, `old.asm`, `neo.asm`, `exp.py`, `xref.py`, `vt2.py`, `bit.py`)

---


<a id="history-8-what-was-written-2026-08-22--code-only-nothing-built-nothing-on-hardware"></a>

## 8. What was written, 2026-08-22 — code only, nothing built, nothing on hardware

⚠ **Status of the diagnosis itself is unchanged.** H1 is a strong inference from the disassembly,
from the fact that gate B is proven working ~90 lines earlier via `SetPll`, and from the history
(`develop` has no `NVXGetVersion` at all; `src_legacy` has it *after* `Start`; only current `src`
has it *before*). It is **not a proven mechanism**. The one premise that cannot be settled on this
machine — that a *cold* converter answers `CmdSend(0)` more slowly than a warm one — is exactly
what §6 step 1 tests, and it is untested. **There is no NVX136 on the development machine.**

<a id="history-the-fix--nvxgetversion-out-of-the-acquisition-path"></a>

### The fix — `NVXGetVersion` out of the acquisition path

| where | what |
|---|---|
| `R:\src\nvx136\nvx136driver.cpp:671-696` | The version block is **gone** from `initialize()`. The gap between the last configuration call and `NVXStart` is now empty, and the comment there records *both* measured reasons — the impedance-sweep kill (query after `Start`) and the cold-start suspicion (query before it) — so neither placement can be re-derived as "obviously fine". |
| `R:\src\nvx136\nvx136driver.cpp:319-336` | The query now runs at the **end of `probe()`**, after the channel count is already computed and immediately before `probe()`'s own `shutdown()`. |
| `R:\src\nvx136\nvx136driver.cpp:105-123` | `Nvx136Driver::readVersions()` — one timed `NVXGetVersion`, caches nothing, returns a `Versions`. |
| `R:\src\nvx136\nvx136driver.h:71-95` | `struct Versions` (six words + elapsed + return code + `deviceAnswered()`), cached in `m_versions`, exposed by `versions()`. |

**Why `probe()` and not `open()`.** `probe()`'s only product is a channel count and it closes the
device immediately afterwards, so a disturbance there costs a channel-list refresh rather than a
session. In `open()` a disturbance would surface as a failure in `SetSettings`/`GetProperty`
during acquisition setup — visible, but it would have cost the session.

**One change from the note's proposal: once per driver instance, not once per `probe()`.**
`probe()` runs again on every rate or mode change (`nvx136config.cpp:376`, `updateChannels()`), so
"at the end of `probe()`" would have meant re-issuing a device transaction that is *suspected of
wedging the converter* every time the operator touches a spinner. `if (!m_versions.queried)` makes
it once. The information is not lost — the values cannot change within a process — and the failure
path in §3 reads them again fresh.

**This satisfies both constraints.** Nothing in the gap before `Start`; nothing after `Start`; the
impedance-sweep fix the current placement was made for is preserved, because the query no longer
happens anywhere near `Start` in either direction.

<a id="history-the-version-formatter"></a>

### The version formatter

`R:\src\nvx136\nvx136logic.h:11-52` — `decodeVersion()` (`constexpr`) and `versionText()`, pure,
header-only, no Qt and no SDK. `R:\src\nvx136\nvx136driver.cpp:125-162` — `versionLine()` prints
all six fields plus the return code and elapsed ms; `logVersions()` adds two warnings: all four
on-device fields zero, and elapsed ≥ 150 ms.

<a id="history-nvxstart-retry"></a>

### `NVXStart` retry

`R:\src\nvx136\nvx136driver.cpp:496-538` — `startWithRetries()`, 3 attempts, 250 ms apart, one
`qInfo` per attempt with return code, error name and elapsed ms. Called from
`nvx136driver.cpp:700`.

**What a partial start can leave behind, and why three attempts is safe.** The DLL's own state is
untouched: `Start()`'s "already started" flag is set only on its success path, so a failed attempt
leaves nothing for the next one to trip over and the retry re-enters at the same first gate.
`NVXStop` is deliberately *not* called between attempts — the driver never set `m_started`, the
DLL never considered the device started, and stopping something that was never started is one more
command down the same suspect channel. What *can* be left behind is a partly started converter:
`Start()` issues the per-module start command to each enabled module in turn, so a timeout
part-way through means modules `0..k` took it and the rest did not, and those modules may stream
into a USB pipe the DLL has not armed. The next attempt re-sends the same command to all of them —
exactly what the SDK does itself — and the samples produced in between go away with the pipe.
Anything still half-started when the last attempt fails is cleared by the caller's `shutdown()`:
`NVXClose` drops the converter's UART channel entirely, which is a stronger reset than `NVXStop`.
Only `NVX_ERR_FAIL` is retried; `-1` and `-2` are deterministic. Cost: nothing on a warm start,
at most ~3.1 s on one that was going to fail anyway. Every attempt is logged, which is what stops
the retry from masking a real fault.

<a id="history-the-cold-device-diagnostic"></a>

### The cold-device diagnostic

`R:\src\nvx136\nvx136driver.cpp:540-654` — `reportStartFailure()`. States that it is not a
configuration error and why (no gate in `Start()` reads a configured value), reports the failing
`Start`'s elapsed ms and the gate that time points at, and probes the control channel.

**Call order inside the diagnostic is load-bearing**: `NVXGetVoltages` first — it is the live
MSP430 round trip and it must report the state the *failing `Start`* left, not one a later
diagnostic created — then `NVXGetErrorStatus`, `NVXGetDevices`, and `NVXGetVersion` **last**,
because that one is itself two device transactions. Acceptable only because the caller closes the
device immediately after. `m_lastError` carries the short form (with "this is not a configuration
error") to the config UI; the full block goes to the log.

<a id="history-tests"></a>

### Tests

`R:\src\nvx136\tests\logic_test.cpp`, target `test_Nvx136Logic`
(`R:\src\nvx136\CMakeLists.txt:73-89`) — a new gtest executable, **outside**
`NVX136_BUILD_EMULATION_TESTS` because it touches neither the SDK nor the device path and is safe
to run during an acquisition. 12 cases: the decoder against both measured values, against the
reversed-field-order misreading, field independence, `0 -> "0.0.0.0"`, a `static_assert` that it is
`constexpr`; plus the previously untested pure helpers in `nvx136logic.h` (frame layout, impedance
word counts, counter wrap, buffer sizing, poll interval, battery curve).

⚠ **This adds one executable to the baseline** — 21 → 22 — and its cases to the count.

**What needs hardware, and cannot be tested here:** the placement change itself (it is only
meaningful against a cold converter), the retry (a warm device starts first time), the whole
diagnostic block (it runs only on a failing `Start`), and every hypothesis H1–H5. The vendor
emulator starts on attempt 1 in every sequence, including the current one, so it cannot reproduce
the bug — it validates plumbing only.

<a id="history-the-ladder"></a>

### The ladder

`R:\config\lab\nvx136_coldprobe.py`, described in §6. Standard library only, ctypes against the
shipped `NVX136.dll`. **Exercised end to end on the development machine against the vendor
emulator on 2026-08-22** — all stages, all structures, `Dll` decoding to `1.5.21743.0` off a live
`NVXGetVersion`. `--selftest` (no device) checks the seven structure layouts against the sizes
`nvx.h` compiles to and the decoder against both measured values.

---


<a id="history-9-built-proved-and-deployed--2026-08-23"></a>

## 9. Built, proved and deployed — 2026-08-23

<a id="history-what-was-built"></a>

### What was built

`cmake --build R:/dist/_build/msvc64` (MSVC v142, `chcp 65001` after `vcvarsall`, `-j 6`, target
`all`) — **clean on the first attempt**, 232 steps, exit 0. `ninja -t deps` reports **642 dependency
entries, all `VALID`, none `STALE`**; the 40 entries with zero recorded dependencies are all empty
`mocs_compilation.cpp` / `qrc_*.cpp` autogen stubs, which genuinely have none.

That check is not a formality here. `nvx136driver.h` gained a `struct Versions`, so the class
layout changed — precisely the situation in which known-issues §11c produces a binary that links
cleanly and crashes at run time. Every object file that includes the header is newer than the
header, so it did not occur.

<a id="history-what-the-emulator-confirmed--plumbing-only"></a>

### What the emulator confirmed — plumbing only

`nvx136_driver_emulation_integration` runs the real driver against the vendor emulator. With the
change in place it prints, at probe time:

```
NVX136 device versions: dll 1.5.21743.0  driver 0.0.0.0  cypress 0.0.0.0  mc-fpga 0.0.0.0
                        msp430 0.0.0.0  cb-fpga 0.0.0.0  (NVXGetVersion returned 0 in 0 ms)
NVX136 did not answer the on-device version queries: cypress, mc-fpga, msp430 and cb-fpga all
read 0.0.0.0. NVXGetVersion reports success either way.
NVXStart attempt 1 of 3: returned 0 (NVX_ERR_OK) after 124 ms
```

Three things are confirmed by that, and only three:

1. **The version line is now readable.** `Dll` decodes to **1.5.21743.0** — the value §5 predicts
   from the raw `281497876496384` the lab saw. Confirmed three independent ways: the `constexpr`
   decoder's unit tests, an arithmetic cross-check outside the C++, and this live call through the
   real DLL.
2. **The all-four-zero warning fires, and is right to.** The emulator performs no device
   transactions, so `Cypress`/`McFpga`/`Msp430`/`CbFpga` are exactly the "device did not answer"
   case the warning exists for — while `NVXGetVersion` still returns `NVX_ERR_OK`. This is the
   mechanism §5 relies on, working.
3. **The retry logs its baseline on a warm start.** One attempt, 124 ms. That is the number a cold
   `Start` will be compared against.

⚠ **The emulator cannot reproduce the bug.** It starts on attempt 1 in every sequence. Nothing
above tests the placement change, the retry's recovery, the diagnostic block, or H1–H5.

<a id="history-a-pre-existing-race-in-nvx136_driver_emulation_integration-found-and-fixed"></a>

### A pre-existing race in `nvx136_driver_emulation_integration`, found and fixed

While using that test as evidence it was found to crash with an access violation (`0xC0000005`) at
teardown **about a third of the time**. Measured: with the version query present, 3 crashes in 6
runs; with it removed, 2 in 8. **It is timing-sensitive, not change-sensitive.**

That distinction is the reason this is written down. A single run proves nothing about this test in
either direction, and any edit that shifts when the first data block arrives moves the odds — which
is how an unrelated change ends up blamed for it. It was nearly blamed on the version query here.

The cause is in the test, not the driver. The lambda watching `Nvx136Driver::data` is attached with
`Qt::DirectConnection`, so it runs on the worker thread, and it captures three of the test
function's locals by reference. `WorkerSession session` is declared **first**, so it is destroyed
**last**: the semaphore and the two counters die while the driver's poll timer is still firing and
`processData()` is still emitting into them. Fix: stop the acquisition at the end of the test body,
while the captured objects are still alive, instead of leaving it to `~WorkerSession`
(`R:\src\nvx136\tests\driver_emulation_integration.cpp`). **12 of 12 runs pass afterwards**, with the
version query restored.

`STATUS.md`'s line that both emulator tests pass was true when written and true most times it was
checked. It was never reliably true.

<a id="history-the-service-runs"></a>

### The service runs

`nvx136.exe`, from both `R:\dist\_build\msvc64\runtime` and the deployed `R:\dist\msvc64`, starts,
announces, applies its `--serviceConfig`, and reports the expected `channels NOT APPLIED` refusal
with no device attached — which is what `NVX136.bat`'s own comment predicts. Zero `Binding loop`
messages in any log.

<a id="history-what-is-still-unproven-stated-plainly"></a>

### What is still unproven, stated plainly

**The cold-start fix is an untested inference.** What is established is that it compiles, that the
sequence is the one §2 intended, and that it does no harm warm. The sequence was checked
mechanically rather than by eye: `NVXGetVersion` appears at exactly one call site in the driver
(inside `readVersions()`), that function is reached from the end of `probe()` and from the
`NVXStart` failure path and nowhere else, and between the last configuration call and `NVXStart`
there is no call at all.

Whether any of that fixes the `-3` is decided by `nvx136_coldprobe.py` at the rig, on a converter
that has not yet been powered on — and by nothing before that.
