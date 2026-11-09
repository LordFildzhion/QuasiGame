# 2026-08-17 — `neuroMS` prepared for its first hardware visit

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-17--neuroms-prepared-for-its-first-hardware-visit"></a>

### 2026-08-17 — `neuroMS` prepared for its first hardware visit

**Twelve defects fixed**, all found by an adversarial review aimed at "what breaks with a real
stimulator on the other end", and all invisible in emulation. Full table in
[neuroms.md §11a](../components/neuroms.md). The ones that were dangerous rather than merely wrong: disconnect
discharged only if the driver *believed* the device was charged; nothing discharged when the
process was killed; connecting overwrote whatever the operator had dialled into the machine;
the bridge's panel policy was fully permissive during `NMS_Open`, so a front-panel TRIG in that
window would have fired the coil; and panel mirroring re-entered the SDK from the SDK's own
callback thread, `StartStimulation` included. The worst one for a lab day was quieter: the error
buffer was cleared in 3 of 25 exports, so **every diagnostic pointed at the wrong thing**.

**New: `R:\dist\lab-kit-neuroMS`** — a self-contained 14 MB folder for the visit. `nms_bringup`
walks the bring-up in order, does the automated half, asks for the half only a person can judge,
and flushes a Markdown + JSON transcript after every step. Nothing that can discharge a coil is
behind a single keystroke; every step is skippable. Includes a printed testing guide (DOCX) with
a contingency for each failure. Verified end to end in emulation from a clean PATH.

The timing measurement can fire the pulses three ways — the `arduinoTTL` service over UDP, the
NVX136's own `triggerPulse` transition, or by hand — and reports the **spread**, not a single
offset.

