# Questions for MCS regarding the NVX136 SDK — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../decisions/proposals/vendor-sdk-inquiries.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-questions-for-mcs-regarding-the-nvx136-sdk"></a>


**Prepared 2026-08-18.** Every claim below is measured on our NVX136 media converter and
amplifier, and reproducible from the artifacts named. SDK references are to the NVX136 developer
kit of 29-06-2025:

```
R:\equipment\MCS_NVX_2025\NVX136_Dev Kit_29-06-2025\NVX136\Dll\include\nvx.h
```

User-manual references are to **EEG amplifier NVX136. User manual**,
MCS.NV136-UM-XX-en Rev. 2.0 / 2026-02-03, and to **NVX Application programming guide**, code
4082e Rev. 6, both from the same kit. **We read both in full before asking.** Where the manual
settles a point it is marked as settled and kept only for the record; where the manual and the
header disagree, the question stands and the disagreement is itself the question.

Everything here is already worked around in our driver — none of it blocks us today. We are
asking so that the workarounds can be replaced by documented behaviour, and so that the next
integrator does not have to rediscover the same things on hardware.

---


<a id="history-1--nvximpedancegetdata-neither-the-buffer-size-nor-the-word-layout-matches-the-header"></a>

## 1. ⚠ `NVXImpedanceGetData`: neither the buffer size nor the word layout matches the header

**The one that cost the most time**, because both halves fail silently or with an unattributed
error code.

**SDK** — `nvx.h:489-495`:

```c
\param Buffer - pointer to destination buffer values in Ohm
  for N channels (equal CountEeg field in t_NVXProperty) + 1 GND (ground).
NVX_API int NVXImpedanceGetData(HANDLE hDevice, unsigned int *Buffer, unsigned int Size);
```

**Measured**, DLL 1.5.21743, `CountEeg = 128`, `CountAux = 8`:

| Buffer offered | Result |
|---|---|
| 128 words (`CountEeg`) | `NVX_ERR_PARAM` (−2) |
| **129 words (`CountEeg + 1` — exactly what the header documents)** | **`NVX_ERR_PARAM` (−2)** |
| 137 words (`CountEeg + CountAux + 1`) | `NVX_ERR_OK`, and the DLL writes **all 137** |

**And the ground reading is not where the header implies.** Electrodes in water, ground
connected, lowest value per word index over eight sweeps:

| index | reading | what it is |
|---|---|---|
| 0…3 | 2.5 / 9.0 / 2.0 / 3.0 kOhm | electrodes in water |
| 126, 127 | 999 900 Ohm | unused electrode positions |
| **128** | 999 900 Ohm | **AUX 1** — where a reader following the header puts GND |
| 129…135 | 999 900 Ohm | AUX 2…8, exactly `CountAux` words |
| **136** | **0 Ohm, then 8000–8500 Ohm once settled** | **the real GND** |

So the wire format is `[EEG(0…CountEeg−1)][AUX(CountEeg…CountEeg+CountAux−1)][GND(CountEeg+CountAux)]`.
The required buffer size is not a quirk — **it is the layout**. A reader that follows the header
gets `NVX_ERR_PARAM` on every call; one that "fixes" only the size then publishes AUX 1 as
ground, permanently out of range, and never sees the real ground reading at all.

**Questions**
1. Can the header be corrected to `CountEeg + CountAux + 1`, with GND as the last word?
2. Is the AUX block guaranteed to carry no impedance, or is it meaningful on some configuration?
3. Is this layout the same on every NVX136 firmware, or does it follow `CountAux`?

**Our code** — `nvx136logic.h:64` `impedanceGndWord()`, `:81` `impedanceReadWords()`;
`nvx136driver.cpp:732`.

---


<a id="history-2--nvxgetversion-after-starting-impedance-silently-aborts-the-sweep"></a>

## 2. ⚠ `NVXGetVersion` after starting impedance silently aborts the sweep

**The most dangerous behaviour we found**, because the failure is indistinguishable from a cap
that is simply not connected.

With the buffer fixed, reads returned `NVX_ERR_OK` and **every electrode read
`NVX_IMP_INVALID` indefinitely**. The cause was a single read-only query issued after the start:

| Sequence, same hardware, otherwise identical | electrodes reporting |
|---|---|
| no version/battery query | 16 → 56 → 106 → **129 of 129** over ~5 s |
| version + battery **after** start | **0 of 129**, indefinitely |
| **version only, after start** | **0 of 129**, indefinitely |
| version + battery **before** start | 16 → 56 → 106 → **129 of 129** |

`NVXGetVersion` alone does it. Nothing reports the fault: the call returns OK, subsequent
`NVXImpedanceGetData` calls return OK, and the data is uniformly the "not connected" sentinel.
`NVXGetData` in normal acquisition mode tolerates the same query.

The **NVX Application programming guide** does state ordering rules for some functions —
`NVXSetTriggersMode` is documented *"Calling this function before function NVXStart"* (§1.6.3) —
but says nothing of the kind for the version query, and the NVX136 header does not either.

**Questions**
1. Which calls are legal between start and stop, in normal mode and in impedance mode?
2. Why does a read-only query abort a measurement cycle rather than being queued or refused?
3. Could such a call return an error instead of silently invalidating the sweep?

---


<a id="history-3-unconnected-electrodes-the-header-says-int_max-the-hardware-says-999-900-ohm"></a>

## 3. Unconnected electrodes: the header says `INT_MAX`, the hardware says 999 900 Ohm

**SDK** — `nvx.h:487`: *"if electrode not connect, value equal to `NVX_IMP_INVALID` (`INT_MAX`
from `<limits.h>`)"*, with the measuring range given as 0 Ohm to 120 kOhm (`nvx.h:483`).

**Measured** — unwired electrode positions read a steady **999 900 Ohm**, not `INT_MAX`.
`INT_MAX` does appear, but in a different situation: it is what every electrode reads when the
sweep has been aborted (§2 above).

That leaves us guessing at the meaning of three distinct values:

| value | what we currently assume it means |
|---|---|
| 0 | this electrode has not been swept yet — not a real reading |
| 999 900 Ohm | measured, and above the measuring range |
| `INT_MAX` (`NVX_IMP_INVALID`) | not measured / invalid |

**Questions**
1. Which value marks "over range" and which marks "invalid"? Our table above is inference.
2. Is 999 900 Ohm a documented sentinel? It appears nowhere in the header.
3. The NVX (non-136) programming guide §1.8.3 says values above 120 kOhm are returned as
   `INT_MAX`. Is the NVX136 convention deliberately different?

---


<a id="history-4--impedance-frames-are-published-mid-sweep-and-not-yet-measured-is-0-ohm"></a>

## 4. ⚠ Impedance frames are published mid-sweep, and "not yet measured" is 0 Ohm

The device needs roughly **750 ms per 32 electrodes**, so a full 128-electrode sweep takes about
3 s — but data is available far more often than that. Electrodes the current sweep has not
reached yet come back as **0 Ohm**.

**0 is not a sentinel; it is the best possible impedance.** A viewer colours it green. Seen in a
recording: an update mid-sweep read `0 0 0 0 0 0` for channels 1–6 while the previous update had
1.5–28.5 kOhm on the same electrodes. An operator watching the cap sees channels flash to
"perfect" every few seconds. Ground does the same, and being the last word takes longest to
appear — which is why its 0 Ohm first looked like a plausible ground-to-ground reading. It is
not: the real ground impedance on that cap is 8000–8500 Ohm.

**Questions**
1. Is there a way to know that a sweep has completed, or which electrodes the current frame
   actually contains — a counter, a flag, a per-word validity marker?
2. Is 0 Ohm intended as "not yet measured", and if so can it be distinguished from a genuine
   near-zero reading?
3. What is the guaranteed sweep cadence per electrode count?

*(We work around this by holding the last real reading per electrode and republishing it until
the device measures that electrode again. It works, but it is a guess about intent.)*

---


<a id="history-5-nvxsetmirrortriggers-is-undocumented-and-unsupported-on-our-converter"></a>

## 5. `NVXSetMirrorTriggers` is undocumented, and unsupported on our converter

**SDK** — `nvx.h:694-695`, declared with **no documentation block at all**:

```c
NVX_API int NVXGetMirrorTriggers(HANDLE hDevice, unsigned char *MirrorTriggers);
NVX_API int NVXSetMirrorTriggers(HANDLE hDevice, unsigned char *MirrorTriggers);
```

**Measured** — our media converter answers **`NVX_ERR_SUPPORT` (−5)** to `NVXSetMirrorTriggers`,
including when setting mirroring *off*, which is the state it is presumably already in.

This was a hard failure for us at first: the call was treated as fatal, so **every start failed**,
with the reason reaching only a log the operator never sees. It is now routed through a helper
that treats `NVX_ERR_SUPPORT` as a warning when the operator asked for the state the device is
already in, and still an error when they asked for the feature — acquiring silently without a
requested hardware setting would mean recording under conditions that are not the configured ones.

**Questions**
1. What does trigger mirroring do — does it repeat the trigger input on the trigger output?
2. What is the argument? It is `unsigned char *`, so presumably a bit mask over the 8 lines, but
   nothing says so.
3. Which devices support it? Is `NVX_ERR_SUPPORT` from the media converter expected?
4. Is it off by default?

**Our code** — `nvx136driver.cpp:341`.

---


<a id="history-6-battery-calls-block-for-275-s-and-then-fail"></a>

## 6. Battery calls block for 2.75 s and then fail

**Measured** — `NVXGetBatteryLevel` and `NVXGetBatteryParameters` both **block for ~2.75 s and
then return `NVX_ERR_FAIL` (−3)**, whether stopped or running, every time. Timed against the rest
of a start:

| call | time |
|---|---|
| `NVXOpenEx` | **3267 ms** |
| device/settings/PLL configuration, seven calls | ~280 ms total |
| `NVXStart` | 222–1136 ms |
| `NVXGetVersion` | 48–285 ms |
| **`NVXGetBatteryParameters`** | **2750 ms, then −3** |

`NVXGetVoltages` by contrast succeeds in **16–32 ms** and returns real data (6.16 V, 28.5 °C), so
we now derive a battery estimate from the open-circuit voltage instead. Removing the battery call
took our start from ~7.8 s to **5.0 s**.

The **user manual** documents a battery module (NVX136-ACC, 6 V 8 A·h) as part of the system, and
§5 instructs the operator to *"Check the battery charge in the Status Bar of the software"* — so
battery status is clearly expected to be available to an application.

**Questions**
1. Where is battery status meant to be read from? The amplifier module rather than the media
   converter?
2. Why do the battery calls block for 2.75 s before failing, rather than returning immediately?
3. Is `NVXGetVoltages` the intended source, and is there a published voltage-to-charge curve for
   the NVX136-ACC pack? Ours is interpolated from a generic 6 V sealed-lead-acid table and sags
   under load — we measured 53 % → 49 % over the first minute of acquisition on a resting pack.

---


<a id="history-7-nvxopenex-takes-33-seconds--is-that-expected"></a>

## 7. `NVXOpenEx` takes 3.3 seconds — is that expected?

**Measured** — consistently **~3267 ms**, and it dominates our start time. We assume it is the
media converter's firmware boot and have not tried to shorten it.

**Questions**
1. Is ~3.3 s the expected duration, and does it vary with anything we control?
2. Is there a way to keep the device open across acquisitions without reopening?

---


<a id="history-8-are-the-ratechannel-restrictions-enforced-by-the-sdk-or-by-the-host"></a>

## 8. Are the rate/channel restrictions enforced by the SDK or by the host?

**Manual** — §8 specification lists the sampling rates with their bandwidths, and restricts the
top one: **100 kHz only for 64 EEG channels**, 50 kHz, 25, 10, 5, 2, 1, 0.5, 0.25 kHz otherwise.

**Question** — is a request that violates this refused by the SDK with an error, or accepted and
silently degraded? We enforce it on our side and refuse the start, but we would rather rely on
the device if it already does so.

---


<a id="history-appendix--settled-by-the-manual-kept-for-the-record"></a>

## Appendix — settled by the manual, kept for the record

Points we had listed as questions and then answered ourselves by reading:

* **Trigger lines rest HIGH at power-up.** §8: *"TTL levels of the output synchronization
  channels are set programmatically by command from the PC. By default, output trigger channels
  are High."* Our driver now drives the line to the operator's selected value at start rather
  than leaving it as found.
* **8 input and 8 output trigger lines**, DB-9F in / DB-9M out, with full TTL levels given
  (input logic 1 at +2.0…+5.5 V, Schmitt hysteresis 0.3…1.2 V; output ≥3.8 V at −8 mA, ≤0.4 V at
  8 mA, total output current ≤±75 mA, transition ≤5 ns).
* ⚠ **The synchronization channels are NOT galvanically isolated from the PC** (§8, "Media
  converter"). This differs from the NVX-52, whose triggers carry reinforced isolation, and it is
  an operational constraint worth knowing rather than a question.
* **Impedance measuring range** 1–120 kOhm ±10 % at 30 Hz, and the header adds that the ground
  electrode and the REF electrode (first electrode of the first slot) must both be connected for
  any impedance measurement at all.


<a id="history-what-works-well-for-balance"></a>

## What works well, for balance

* Acquisition itself is solid: a ten-minute run at **25 kHz, 70 EEG channels + trigger, block
  2500** recorded cleanly through our stack, 13.6 MB/s off USB, with no gaps.
* `NVXGetVoltages` is fast and reliable, and made a good substitute for the battery API.
* Once the buffer and word layout were right, impedance converged fully — 129 of 129 electrodes,
  with ground reading a live 8000–8500 Ohm rather than a stuck maximum.

Evidence: `docs/arch_known-issues.md` §14c, §14h, §14i, §14j, §15a, §15b; probe sources under
`R:\dist_2026aug\_build\nvx136-verify`.
