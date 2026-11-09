# NVX-136 cold start — what was wrong, and how it was found — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/nvx136.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-nvx-136-cold-start--what-was-wrong-and-how-it-was-found"></a>


**2026-09-04.** The Qt 6 `nvx136` service could not start a freshly powered-on NVX-136 on the first
attempt. It does now. The cause was a single missing device read, and finding it took eliminating
five other candidates first.

---


<a id="history-1-the-symptom"></a>

## 1. The symptom

A cold converter — powered on, never started since — refused the first `NVXStart`:

```
NVXStart attempt 1 of 2: returned -3 (NVX_ERR_FAIL) after 3957 ms
NVX136 cold-start recovery 1 of 1: NVXStop 0 in 4 ms, NVXClose 0 in 163 ms, paused 500 ms,
                                   rescan (probe) ok in 3373 ms, paused 500 ms,
                                   reopen+reconfigure ok in 3266 ms
NVXStart attempt 2 of 2: returned -3 (NVX_ERR_FAIL) after 3954 ms
```

The operator's workaround was to launch, watch it fail, and launch again. The `nvx136_2021`
comparator — same rig, same amplifier, same procedure — started first time, every time.


<a id="history-2-what-exactly-failed"></a>

## 2. What exactly failed

`NVXStart` is the only call that failed, and everything around it was healthy:

| evidence, taken at the moment of failure | reading |
|---|---|
| `NVXStart` return | **-3, `NVX_ERR_FAIL`, after 3954 ms** |
| the SDK's own explanation | *"an MSP430 command timed out — the SDK waits 873 ms for the PLL frequency read and for each per-module select"* |
| `NVXGetVoltages` after the failure | **ok**, VDC 6.50 V, 28.5 °C — the control channel is answering |
| `NVXGetVersion` | returned 0; full firmware read back (driver 3.4.1.146, msp430 11.16.4.12 …) |
| devices | present `0x1`, enabled `0x1` — the module is there and enabled |
| error status | samples 0, crc 0, counter 0, devices 0/0/0/0 |
| every configuration call before it | accepted |

⚠ **So it was never a configuration error.** Inside the SDK, `Start()` fails only when the media
converter stops answering its control commands; no sampling rate, block size, mode, channel
selection or device index is read on that path. The converter was reachable and idle — it simply
was not ready to be started.


<a id="history-3-the-cause"></a>

## 3. The cause

`Nvx136Driver::open()` sent **nothing** between `NVXOpen` and the first configuration call.

The 2021 driver did — and it looks like an accident:

```cpp
handle = NVXOpen(deviceIndex);
t_NVXVoltages voltages;
NVXGetVoltages(handle, &voltages);      // result never used
```

A read whose result is discarded. It reads as dead code, it was almost certainly written as
leftover debugging, and the 2025 rewrite dropped it for exactly that reason. **That discarded read
is the entire difference.**

```
without it   NVXStart -3 (NVX_ERR_FAIL) after 3954 ms — twice, recovery cycle no help
with it      NVXStart  0 (NVX_ERR_OK)   after 1188–1210 ms — first attempt
```

<a id="history-proven-in-both-directions-and-narrowed-to-the-specific-call"></a>

### Proven in both directions, and narrowed to the specific call

Adding the read to the failing build is only half a proof. The other half is removing it from the
build that has never failed — run on 2026-09-04, on the same rig, power-cycled before each attempt:

| variant of `nvx136_2021` | sends between `NVXOpen` and first configuration call | cold start |
|---|---|---|
| working build | `NVXGetVersion`, then `NVXGetVoltages` | ✅ first try |
| **x1** | `NVXGetVersion` only | ❌ **`NVXStart` -3** |
| **x2** | nothing | ❌ **`NVXStart` -3** |

**x2 proves the causation**: take the read away and the build that always worked stops working.

⭐ **x1 is the more interesting result.** `NVXGetVersion` is a completed, successful device
transaction — in the x1 log it returns `0` and reads back real firmware (`driver 3.4.1.146`,
`msp430 11.16.4.12`, `cb-fpga 0.0.0.37`) — and it does **not** cure the cold start. So:

* it is **not** "any device transaction after open"; and
* it is **not** simple dwell. `NVXGetVersion` costs ~31 ms, `NVXGetVoltages` 16–32 ms. If ~30 ms of
  settling were the mechanism, x1 would have started.

**It is `NVXGetVoltages` specifically.** What that call does to the converter that a version query
does not is unknown — but note what the failing diagnostic says times out: *"an MSP430 command"*,
and reading supply rails is an MSP430 operation in a way that reading a version register need not
be.

⚠ Retries do not help. In x2 the operator pressed Start three times; each attempt opened the device
afresh and each failed identically. A fresh `NVXOpen` is not enough on its own — the read has to
happen.


<a id="history-4-the-two-builds-side-by-side"></a>

## 4. The two builds, side by side

Everything that differed, and whether it turned out to matter:

| | `nvx136_2021` (worked) | `nvx136` 2025 (failed) | mattered? |
|---|---|---|---|
| **read after `NVXOpen`** | **`NVXGetVoltages`, discarded** | **nothing** | ⭐ **YES — proven both directions** |
| vendor `NVX136.dll` | 1.4.19077 | 1.5.21743 | ❌ no |
| open call | `NVXOpen` | `NVXOpen` (legacy path) | ❌ no |
| `NVXGetVersion` | not called (until p4) | called in `probe()` | ❌ no |
| `NVXSetPowerSave` during probe | never sent | sent on every probe | ❌ no |
| `NVXStop` on a probe teardown | always sent | skipped | ❌ no |
| `NVXGetDevices`/`SetDevices`/`SelectDevice` | absent from the 2021 SDK | skipped under the legacy sequence | ❌ no |
| pre-`NVXStart` sequence | `Open → SetSettings → SetAuxGain → SetPll → Start` | identical under the legacy sequence | ❌ no |
| cold-start recovery ladder | none — never needed one | 2 attempts + a full recovery cycle | ❌ no (it never cured anything) |

⚠ The last row is worth dwelling on: an elaborate recovery mechanism — close, pause, re-open,
re-configure, retry — was built to work around this and **never once cured it**. 15 752 ms spent in
the start ladder, to fail anyway.


<a id="history-5-how-it-was-narrowed"></a>

## 5. How it was narrowed

Each row cost roughly a session, and the order matters: the DLL swap eliminated half the search
space in a single test.

| experiment | result | eliminated |
|---|---|---|
| 2021 code + **2021 DLL** | ✅ first try | *(the known-good baseline)* |
| 2021 code + **2025 DLL** (file swap, no rebuild) | ✅ first try | **the vendor DLL** |
| 2025 + p4-equivalents on the 2021 side | ✅ still first try | **the length of the pre-`NVXStart` gap** |
| 2025 + `NVXGetVersion` on the open handle | no change either way | **the version query** — which the source called *"the prime suspect"* |
| 2025 + q1 — probe skips `NVXSetPowerSave` | ❌ fails | that asymmetry |
| 2025 + q2 — `NVXStop` on probe teardown | ❌ fails, 3954 ms | that asymmetry |
| **2025 + q3 — `NVXGetVoltages` after `NVXOpen`** | ✅ **1210 ms, first try, twice** | — **found** |
| 2025 + q4 — q3 without q2 | ✅ **1188 ms, first try** | q2 was unnecessary |
| **2021 with the read removed (x2)** | ❌ **fails, 3 attempts** | — **causation confirmed** |
| **2021 with only `NVXGetVersion` (x1)** | ❌ **fails** | "any transaction" and "~30 ms of dwell" |

The DLL swap was free: the 2025 API is a strict superset of the 22 calls `nvx136_2021.exe` uses, and
Windows loads `NVX136.dll` from the executable's own directory — so it needed no rebuild, only a
file copy.


<a id="history-6-what-shipped"></a>

## 6. What shipped

`q4-minimal-cure`: the read, plus q1 (the probe honouring the legacy sequence, kept because it
removes a device transaction the working build never sent), minus q2. In `R:\dist` via
`deploy-qt6.ps1`, `validate-dist-qt6.ps1` PASS, 29/29 ctest.

⭐ **The cure is guarded by a test**, because a discarded read is precisely what the next reader
deletes — it has already been deleted once, and that is what caused all of this.

`Nvx136ColdStart.TheDiscardedVoltageReadHappensBeforeAnyConfiguration` asserts on **order, not on a
count**: the driver reads voltages again in its failure diagnostic and on the battery poll, so a
count-based test would pass with the cure removed and prove nothing. The fake SDK records
`setSettingsAtFirstVoltages`, and `0` means the read landed after `NVXOpen` and before any
configuration.

⚠ The guard was verified by deleting the call and watching it go red:

```
NVXGetVoltages was never called on the start path -- the cold-start cure has been
removed from Nvx136Driver::open()
```


<a id="history-7-what-to-take-from-this"></a>

## 7. What to take from this

* **A discarded return value is not the same as a call with no effect.** The read was dead by every
  static reading and load-bearing at runtime.
* **The failing diagnostic named the mechanism from the start** — *"an MSP430 command timed out"* —
  and it was read as a symptom rather than a clue for weeks.
* **The 2×2 was the cheapest test available and was run last.** Two variables had changed at once
  (our code and the vendor DLL) and only one was ever examined. Holding one constant cost one file
  copy.
* **A recovery mechanism that never succeeds is worse than none**: it spent 15 s per attempt and
  made the failure look like something the software was handling.


<a id="history-8-is-the-requirement-documented-no--and-there-is-nowhere-it-could-be"></a>

## 8. Is the requirement documented? No — and there is nowhere it could be

Checked on 2026-09-04 across both vendor packages, `R:\equipment\MCS_NVX_2021` and
`R:\equipment\MCS_NVX_2025`: **every file, not just the obvious ones.**

**`NVXGetVoltages` appears exactly four times in both SDKs combined** — and all four are the same
declaration in the same header, shipped twice per package:

```
NVX136/Dll/include/nvx.h:596       NVX_API int NVXGetVoltages(HANDLE hDevice, t_NVXVoltages *Voltages);
NVX136/Soft/Contest/nvx.h:596      (identical copy)
```

Its entire documentation is three lines: *"Function to get device voltages"*, the two parameters,
and the return. Nothing about when to call it, and nothing anywhere about needing to call it.

<a id="history-there-is-no-nvx136-programming-guide-at-all"></a>

### There is no NVX136 programming guide at all

Both kits ship a `Spec.txt` listing their own contents. The NVX136 kits list four folders — `Dll`,
`Driver`, `Soft\Contest`, `Soft\Test`. **No `Doc`.** The only `Doc` folders in either package
belong to the *other* product:

| document | product | mentions `NVXGetVoltages` |
|---|---|---|
| `4082-NVX-Руководство прикладного программиста.doc` (2021, ru) | NVX-24/36/52 | **0** |
| `4082e-NVX-Application programming guide.pdf` (2025, en) | NVX-24/36/52 | **0** |
| `EEG amplifier NVX136. User manual.pdf` | NVX136 — clinical/operator manual | **0** |
| `EEG amplifiers NVX. User manual.pdf` | NVX — clinical/operator manual | **0** |
| `MCScap PROFESSIONAL for NVX136. User Manual.pdf` | cap, not amplifier | **0** |

⚠ Both programming guides are for a **different API**: `NVXAPIInit`, `NVXGetId`, `int Id` handles,
`NVXStartImpedance`, `NVXSetDataMode`. That API has no `NVXGetVoltages`, no `NVXSetSettings`, no
`NVXSetPowerSave`. They cannot document an NVX136 call because they do not describe the NVX136.

**So for the NVX136 the header comments *are* the documentation.** There is no other prose.

<a id="history-the-vendors-own-example-does-not-do-it-either"></a>

### The vendor's own example does not do it either

`NVX136/Soft/Contest/NVXConsole.cpp` — MCS's own console sample, in both the 2021 and the 2025 kit —
goes straight from open to configuration:

```
NVXGetCount → NVXOpen → NVXSetSettings → NVXGetProperty → NVXStart
```

⭐ **That is exactly the sequence that fails on a cold converter.** The behaviour is not documented
by example either; following the vendor's sample verbatim reproduces the bug.

<a id="history-the-header-does-document-ordering--just-not-this-one"></a>

### The header does document ordering — just not this one

This is the part that makes the omission worth reporting rather than shrugging at. `nvx.h` carries
nine `Note:`/`Remarks` blocks, and three of them are *precisely* ordering constraints of the kind
that was missing:

| function | documented constraint |
|---|---|
| `NVXSetSettings` | *"call before NVXSetChannelsEnabled function"* |
| `NVXSetPowerSave` | *"call before NVXSetChannelsEnabled function"* |
| `NVXSetChannelsEnabled` | *"call only in stop mode; call after NVXSetPowerSave function"* |

`NVXImpedanceGetData` even documents device timing to the millisecond (*"~750 ms per 32
electrodes"*), and `NVXSetElectrodes` has a full `Warning (limitations) of using` section.

**`NVXOpen` and `NVXStart` have no `Note:` block at all.** The convention exists, the right place
exists, the entry was never written.

<a id="history-and-it-never-changed"></a>

### And it never changed

`NVX136/Dll/include/nvx.h` is **byte-identical** between the 2021 and the 2025 kit — `diff` reports
no difference — while the DLL went from 1.4.19077 to 1.5.21743. Three and a half years of firmware
and library work, zero documentation change.

<a id="history-verdict"></a>

### Verdict

⭐ **Not documented, in any form, anywhere in either SDK.** Not in the header, not in a guide (there
is none for this product), not in the user manuals, not in the sample code — and the sample code
actively demonstrates the failing order.

**Nothing here was missed by us.** The only way to find it was to diff two working/failing
implementations on real hardware.

Worth asking MCS for, in order of value:

1. A `Note:` on `NVXStart` or `NVXOpen` stating what must precede a first start on a
   freshly-powered converter — matching the convention already used on `NVXSetSettings`.
2. The same call added to `NVXConsole.cpp`, so the sample is correct.
3. The underlying reason: what `NVXGetVoltages` does that `NVXGetVersion` does not. The failing
   diagnostic names an **MSP430** command timing out, so an MSP430 initialisation ordering is the
   obvious hypothesis — but only MCS can confirm it, and the answer decides whether this is a
   documentation fix or a firmware/DLL fix.

⚠ Point 3 matters most. A discarded read is a workaround, not a contract. If the real cause is that
the media converter needs the MSP430 woken before `NVXStart`, that belongs inside `NVXOpen` — where
no caller can delete it.
