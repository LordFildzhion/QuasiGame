# 15. NVX136 impedance: two vendor-SDK traps — ✅ both fixed 2026-08-15

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-15-nvx136-impedance-two-vendor-sdk-traps---both-fixed-2026-08-15"></a>

### 15. NVX136 impedance: two vendor-SDK traps — ✅ both fixed 2026-08-15

**TRANSFERS UNCHANGED — vendor-SDK behaviour, and the fixes crossed.** `nvx136` was copied into the
Qt 6 tree from the current Qt 5 working tree on 2026-08-28 with its uncommitted hardware work
intact, so `impedanceGndWord()` and the widened read buffer are in `R:\src\nvx136` as well. Nothing
here touches Qt: it is what `NVX136.dll` does. See §24 for the one part of this driver where the two
trees have since **diverged**.

Impedance mode had never worked on hardware. Two independent causes, both in how the vendor DLL
behaves versus how its own header documents it. Found with a standalone probe
(`R:\dist\_build\nvx136-verify\`, sources in the session scratchpad) that replayed the driver's
call sequence one call at a time.

<a id="history-15a-nvximpedancegetdata-needs-a-bigger-buffer-than-its-header-says"></a>

### 15a. `NVXImpedanceGetData` needs a bigger buffer than its header says

The header (`nvx.h:490`) documents the destination buffer as *"N channels (equal CountEeg field
in t_NVXProperty) + 1 GND"*. DLL 1.5.21743 rejects exactly that:

| Buffer | Result |
|---|---|
| 128 words (`CountEeg`) | `NVX_ERR_PARAM` (-2) |
| **129 words (`CountEeg + 1`, i.e. what the header documents)** | **`NVX_ERR_PARAM` (-2)** |
| 137 words (`CountEeg + CountAux + 1`) | OK — and the DLL writes all 137 |

So the driver, which followed the documentation, failed on its first read every time and dropped
straight into the error state. `impedanceReadWords()` now sizes the read at
`CountEeg + CountAux + 1`; the published stream is still the documented EEG + GND, and the
AUX-width tail is read into and discarded.

<a id="history-15b-querying-the-device-after-nvxstart-silently-kills-the-impedance-sweep"></a>

### 15b. Querying the device after `NVXStart` silently kills the impedance sweep

With the buffer fixed, reads returned `NVX_ERR_OK` and every electrode read `NVX_IMP_INVALID`
forever — a *silent* failure, indistinguishable from 128 disconnected electrodes.

`initialize()` logged the DLL version and battery level immediately after `NVXStart`.
**`NVXGetVersion` after `NVXStart` aborts the impedance measurement cycle.** Measured, same
hardware, same sequence otherwise:

| | electrodes reporting |
|---|---|
| no version/battery query | 16 → 56 → 106 → **129 of 129** over ~5 s |
| version + battery after `NVXStart` | **0 of 129**, indefinitely |
| version only, after `NVXStart` | **0 of 129**, indefinitely |
| version + battery **before** `NVXStart` | 16 → 56 → 106 → **129 of 129** |

`NVXGetVersion` alone does it, so this is not the battery call failing (it returns -3 on this
converter, which is why no battery line ever appeared in the log). Both queries now run before
`NVXStart`, where they work in every mode.

**The general lesson:** on this SDK, a device query issued while acquisition is running is not
free. `NVXGetData` in Normal mode tolerates it; the impedance sweep does not. Neither the fault
nor the recovery is reported by any return code.

---

