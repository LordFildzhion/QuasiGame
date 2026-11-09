# Questions for MCS regarding the NVX SDK and the NVX-52 — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../decisions/proposals/vendor-sdk-inquiries.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-questions-for-mcs-regarding-the-nvx-sdk-and-the-nvx-52"></a>


**Prepared 2026-08-18.** Every claim below is measured on our NVX-52 and reproducible from the
artifacts named. SDK references are to `NVXAPI 2.3.21648` (2025 kit):

```
R:\equipment\MCS_NVX_2025\NVX_SDK_2025-09-08\NVX\Dll\NVXAPI 2.3.21648\include\NVXAPI\NVX.h
```

User-manual references are to **EEG amplifiers NVX. User manual**, MCS.NX-UM-XX-EN Rev. 1.0 / 2025-03-04, supplied in the
same kit. **We read it in full before asking.** Several earlier questions are settled by it and
have been removed or reduced; where the manual and the SDK header disagree, the question stands
and the disagreement is now itself the question.

Where a question has a demonstration, it is one command or one file — nothing needs rebuilding.

---


<a id="history-1--5-khz-loses-107--of-samples-and-it-is-not-our-software"></a>

## 1. ⚠ 5 kHz loses 10.7 % of samples, and it is not our software

**The most important question, and the only one that blocks experiments.**

At 5 kHz the device delivers roughly **4.474 kframes/s instead of 5**, losing **10.717 %** of the
timeline as a highly regular pattern: **two or three missing samples about every twenty**, roughly
**250 gap events per second**. It is not random load.

What we have already ruled out:

| Ruled out | Evidence |
|---|---|
| Our driver | A raw SDK counter probe, no Resonance involved, shows the same 10.34 % counter-defined loss |
| SDK generation | Identical under **2.3.21648** (2025) and **2.3.18789** (2021) |
| Block size | 15-minute runs at blocks 50, 500 and 5000 each lost ~10.7169 % |
| Channel count | 20, 23, 24, 25, 32, 48 published EEG channels — loss unchanged, no 24→25 discontinuity |
| Host polling | Continuous retry through 75 ms did not recover the frames |
| **Our application entirely** | **Reproduced in your own recording application, at any channel count** |

**The manual specifies this rate.** §6 Specification, p.19: *"Sampling rate 250, 500, 1000, 2000,
5000 Hz (for all channels)"* — 5 kHz on **all** channels, with an upper cutoff of 1650 Hz quoted
for it. So this is not an undocumented limit being exceeded; it is a specified capability the unit
does not meet.

2 kHz is clean by contrast: 0 transport-missing rows in 1 799 926 measured rows over 15 minutes
(one-sided 95 % upper bound 1.664 missing rows per million).

**Questions**
1. Is this a known defect of this amplifier generation, and is there a firmware revision that
   fixes it?
2. What is the mechanism — USB scheduling, the 24-bit frame packer, an internal decimation stage?
3. The manual restricts channel count only at 10 kHz (≤24) and 50 kHz (≤4), and states 5 kHz is
   for all channels. Is there an unpublished restriction at 5 kHz, or is this unit faulty?
4. Our `McsUsb30` driver is **3.3.0.0 (2023)**, newer than the **3.0 (2012)** shipped in the 2025
   SDK. Which is correct for this device?

**Demonstration** — `docs/NVX2025-2kHz-5kHz-NaN-Boundary-Validation-2026-08-14.docx` and the
matching `.xlsx`; raw artifacts under `R:\dist_2026aug\_build\nvx-validation\boundary-2026-08-14`.

---


<a id="history-2-nvxsetout--what-does-the-value-argument-actually-mean"></a>

## 2. `NVXSetOut` — what does the value argument actually mean?

**SDK** — `NVX.h:490-496`:

```c
/*! Function to set state of output trigger
\param Id - device ID
\param State - state of output trigger (bits 0, 1)     <-- "bits 0, 1" implies a 2-bit field
*/
NVX_API int WINAPI NVXSetOut(int Id, unsigned char State);
```

**Manual** — §6, p.18: *"Synchronization channels 9 / 1"* for the NVX52, and §1, p.12: the 3.5 mm
stereo connector carries *"1 input and 1 output triggers"*. **One output line**, which agrees with
the device and with our measurement, and disagrees with the header.

**Device** — `NVXGetPossibility()` reports `OutTriggersCount == 1` (`NVX.h:187`) on our NVX-52.

**Measured** — only the exact value **1** raises the line. **0, 2 and 3 all leave it low.** Note
that 3 has bit 0 set, so this does not behave as a bit mask in any interpretation.

| `State` | line |
|---|---|
| 0 | low |
| **1** | **high** |
| 2 | low |
| **3** | **low** — although bit 0 is set |

**Questions**
1. Is `State` a bit mask, an enumeration, or a count?
2. Why does 3 not raise the line if bit 0 selects output 0?
3. Should the documentation read "bits 0, 1" only for models where `OutTriggersCount == 2`?

**Our code** — `src/nvx/nvxdatathread.cpp:731`, `NVXSetOut(m_deviceId, state & 0x03U)`.
We now expose the parameter as a checkbox rather than a 0..3 spin box because of this.

---


<a id="history-3-the-status-word-bit-layout-contradicts-the-device"></a>

## 3. The `Status` word bit layout contradicts the device

**SDK** — `NVX.h:108`, and identically at 116, 124 and 139:

```c
unsigned int Status; /*!< Digital inputs (bits 0 - 9) + output (bit 10) state + 21 MSB reserved */
```

but `NVX.h:132` — a different structure in the same header — says:

```c
unsigned int Status; /*!< Digital inputs (bits 0, 1) + output (bits 10, 11) state + 20 MSB reserved */
```

**Manual** — §6, p.18: *"Synchronization channels 9 / 1"*. §1, p.12: a DB-9F for *"up to 8 input
triggers"* plus the 3.5 mm stereo jack for *"1 input and 1 output"* — **9 inputs and 1 output**,
which is exactly what the device reports and exactly what we measured. The header, alone among the
three, describes ten inputs.

**Measured on the NVX-52**, with an external board driving known pins:

| | measured |
|---|---|
| Idle word | `0x0000EFFF` — every input rests **HIGH**, so an input edge is a bit going low |
| Input pins | bits 6, 7 and 8 for the three inputs we drove |
| **Output readback** | **bit 9**, not bit 10 |
| Bit 12 | never observed to move |

**The manual and our measurement agree; the SDK header is the outlier.** The questions are
therefore about the header rather than about the device.

**Questions**
1. Can `NVX.h`'s `Status` comment be corrected — it describes ten inputs where the manual, the
   device and measurement all say nine?
2. Is the output readback bit `InTriggersCount` (i.e. immediately above the inputs) rather than a
   fixed bit 10? That would explain bit 9 on a 9-input device and reconcile both comments.
3. What are bits 10-15 on this model?

---


<a id="history-4-trigger-input-detection-modes--what-is-guaranteed"></a>

## 4. Trigger input detection modes — what is guaranteed?

**SDK** — `NVX.h:68-70` and `NVX.h:471-477`:

```c
#define NVX_TRG_NORMAL (0) /* normal mode */
#define NVX_TRG_FRONT  (1) /* front detection */
#define NVX_TRG_REAR   (2) /* rear detection */
NVX_API int WINAPI NVXSetTriggersMode(int Id, unsigned int Mode);   /* only NVX24, NVX36, NVX52 */
```

**Manual** — §6, p.19 describes the synchronisation channels only as *"Synchronously with the
issued channel readings; Accuracy ±0.5 / reading"*. That describes **sampling**, and says nothing
about edge detection, latching, or a minimum pulse width. Our `REAR` measurement is far better
than synchronous sampling would allow, so the SDK exposes a capability the manual does not
describe at all.

**Measured**, driving a line that rests HIGH and pulses LOW:

| Mode | behaviour |
|---|---|
| `NVX_TRG_REAR` | **Latches.** Catches an isolated **20 µs** pulse **95.5 %** of the time, and is rate-independent — a 0.25-sample pulse at 250 Hz was caught 25/25 |
| `NVX_TRG_NORMAL` | Plain level sampling: catch fraction equals width ÷ sample period at every point tested |
| `NVX_TRG_FRONT` | **Catches nothing below 1 ms on this line — the bit does not move at all** |

**Questions**
1. What is the **guaranteed minimum input pulse width**? The manual quotes only ±0.5 reading of
   sampling accuracy, which would not catch a 20 µs pulse at all — yet `REAR` catches it 95.5 % of
   the time. Is that latching behaviour specified anywhere?
2. In `REAR` mode, when is the latch cleared — on each frame, or on read?
3. Is `FRONT` expected to be inert on a line that rests HIGH? "Front"/"rear" suggests rising/falling;
   is the naming referenced to the signal or to an internally inverted copy?
4. Do these modes apply to all input pins simultaneously?

---


<a id="history-5-is-the-status-word-valid-immediately-after-nvxstart"></a>

## 5. Is the `Status` word valid immediately after `NVXStart`?

**Measured** — the **first 14 frames after `NVXStart` read `Status == 0`**, i.e. every input low,
before the word settles to its `0x0000EFFF` resting value. A reader that takes the first frame as
the resting level therefore mis-detects every subsequent input as inactive.

**Question** — is there a defined number of frames after `NVXStart` before `Status` is valid, and
should we discard them?

---


<a id="history-6-does-the-bit-9-readback-follow-the-register-or-the-pin"></a>

## 6. Does the bit-9 readback follow the register or the pin?

A short question, and the only part of an earlier draft that survived scrutiny.

We briefly believed the NVX-52 mirrors its trigger input onto its output, and had prepared that as
a finding. **We withdrew it before this document reached you**: the effect turned out to be pickup
on a BNC connector that was not properly seated, and it vanished once the connector was reseated.
With the output path demonstrably working — ten commanded asserts arriving 10 of 10 in the same
run — 200 pulses into the trigger input produced no activity on the output whatsoever. We mention
it only so that, if mirroring is a documented feature of some models, you can tell us.

**The question that remains** — `NVXSetOut` sets the output register, and bit 9 of the `Status`
word reads back. Is that readback specified to reflect:

1. the register the host last wrote, or
2. the actual state of the output pin?

We would prefer (2), because software has no other way to confirm what a downstream device is
receiving. If it is (1), a driver cannot detect a stuck or loaded output at all.

**Questions**
1. Which of the two does bit 9 report?
2. Is input→output trigger mirroring a feature of any NVX model, and is it ever on by default?
3. Is `NVXSetMirrorTriggers` supported on the NVX-52, and what is its argument?


<a id="history-7-which-api-calls-are-legal-while-acquiring"></a>

## 7. Which API calls are legal while acquiring?

**Measured on the NVX136** — with impedance running, calling **`NVXGetVersion` after `NVXStart`
silently aborts the impedance measurement cycle**: every electrode reads `NVX_IMP_INVALID`
indefinitely. The same code with the version query moved **before** `NVXStart` converges normally
(16 → 56 → 106 → **129 of 129**). `NVXGetVersion` alone is enough to do it; `NVXGetData` in Normal
mode tolerates it.

| Sequence | electrodes measured |
|---|---|
| version + battery **after** `NVXStart` | **0 of 129**, indefinitely |
| version only, after `NVXStart` | **0 of 129**, indefinitely |
| version + battery **before** `NVXStart` | 129 of 129 |

**Questions**
1. Which calls are safe to make between `NVXStart` and `NVXStop`?
2. Is this documented anywhere, and does it apply to the NVX-52 as well?
3. Why does a read-only query abort a measurement cycle?

---


<a id="history-8-nvximpedancegetdata-buffer-size-contradicts-the-header"></a>

## 8. `NVXImpedanceGetData` buffer size contradicts the header

**SDK** — `nvx.h:490` (NVX136 kit) documents the destination buffer as *"N channels (equal
CountEeg field in t_NVXProperty) + 1 GND"*.

**Measured** — DLL 1.5.21743 **rejects exactly that**:

| buffer | result |
|---|---|
| 128 words (`CountEeg`) | `NVX_ERR_PARAM` (-2) |
| **129 words (`CountEeg + 1`, what the header documents)** | **`NVX_ERR_PARAM` (-2)** |

We also found GND is the **last** word, not the word immediately after the EEG block.

**Question** — what is the correct buffer size formula, and where does GND sit?

---


<a id="history-9-electrical-specification-of-the-trigger-lines--settled-by-the-manual"></a>

## 9. Electrical specification of the trigger lines — SETTLED by the manual

Left in only to record that we checked, and because one line of it validates a change we made.

**Manual** — §6 Specification, p.19:

| | |
|---|---|
| Input TTL levels | low `Uil > +0.8 V`, `Iil > −2.1 mA`; high `Uih > +3.5 V`, `Iih > −0.1 mA` |
| Output TTL levels | low `Uol < +0.4 V`, `Iol < −1.6 mA`; high `Uoh > +2.8 V`, `Ioh > 0.5 mA` |
| **Reset state** | ***"By default, output trigger channels are High."*** |
| Isolation | reinforced, 4000 V / 50 Hz for 1 min; *"The triggers are located on the PC side"* |

**The power-up state is documented, and matches what we see.** We had observed the output asserted
before any software wrote to it and treated it as a surprise; it is specified behaviour. Our driver
now drives the line to the operator's selected value at every Start rather than leaving it as
found, which is the right response to a documented high-by-default output.

**One residual question**
1. Is the output push-pull, or open-collector with a pull-up? The quoted `Ioh > 0.5 mA` suggests it
   sources current, but the manual does not say outright, and it decides what a receiver may
   present as a load.


<a id="history-10-the-once-per-second-read-cadence-requirement"></a>

## 10. The once-per-second read-cadence requirement

Our block-size testing found that delivery intervals crossing roughly **one second** produce
missing data, so we cap block size accordingly (block 1250+ at 1 kHz, 2666+ at 2 kHz).
⚠ **The failure is silent** — at 2 kHz, block 19000 had no NaNs but multi-second latency, and
block 20000 was the first data-losing case, with no SDK, queue or counter warning at either.

**Questions**
1. Where is the read-cadence requirement specified, and what is the exact limit?
2. Is there a status or error code that reports an overrun, rather than silently dropping frames?

---


<a id="history-appendix--what-works-well-for-balance"></a>

## Appendix — what works well, for balance

These are measured and we have no complaint about them:

* **Trigger input reliability is excellent.** 1000 pulses at 50 Hz into the input at 2 kHz:
  **1065 of 1065 edges recorded, zero lost** (5 probe + 1000 train + 60 echo).
* **The output is prompt.** A full loop — `NVXSetOut` release → external board detects → board
  echoes a pulse → NVX input latches it — completes with a **median of 0.000 ms and a maximum of
  1.5 ms** at 2 kHz, i.e. inside one 0.5 ms sample 77 % of the time.
* **`NVX_TRG_REAR` latching is genuinely good** — 20 µs pulses at 95.5 %, rate-independent.
* 1 kHz and 2 kHz acquisition are clean over 15-minute runs.

Evidence: `R:\tests\2026-08-18_build_tep-displayfilter\nvx-trigger-validation\nvx-trigger-validation-001.h5`, analysed by
`config/analyze_nvx_trigger_validation.py`.
