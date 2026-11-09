# 2026-08-15 — new module `neuroMS`: the Neuro-MS magnetic stimulator

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-15--new-module-neuroms-the-neuro-ms-magnetic-stimulator"></a>

### 2026-08-15 — new module `neuroMS`: the Neuro-MS magnetic stimulator

Full write-up: **[neuroms.md](../components/neuroms.md)**. The first **actuator** in the tree — everything else
is a sensor — for a monophasic Neuro-MS with paired-pulse capability. The rig fires it from a TTL
and records that TTL, so the driver's job is to charge, discharge, set the two powers and the
delay, and report per firing what the coil actually delivered.

| | |
|---|---|
| Bridge | `bridge/nmsbridge.{h,cpp}`, the tree's second `/clr` component. Covers **all three device families** (monophasic `0x8315`, biphasic `0x8316`, quadripulse `0x8317`) so the MSX work is done in advance, plus a software stimulator for emulation |
| Streams | `events` (Message/JSON — per-pulse dI/dT, coil temperature, powers and delay in force; charger, coil, over-temperature, front-panel activity) and `status` (Float64, 28 named channels at 2 Hz) |
| States | `init → ready → charging → charged`, with `charge`/`discharge` as **transitions**, not a parameter a saved config could replay |
| Panel | Front-panel ARM / TRIG / knobs are mirrored **in the bridge**, on by default — while a program holds the device the panel is routed through the host, and without this the buttons on the machine stop working |
| Not used | The SDK's COM wrapper: it drops the trigger settings on open, reports success for a failed open, and exposes no callbacks at all |

⚠ **The two Neurosoft SDKs collide.** They ship seven assemblies with identical names, identical
version `1.0.0.0`, no strong name and different bytes. Each driver's managed assemblies now live
in `bin\<driver>\` with a private `AssemblyResolve` handler; **`neuronSpectrum` was repackaged the
same way** and needs re-checking on the NS-65. When redeploying over an older tree, delete
`bin\NeuroSoft.*.dll` first — CLR probing checks `bin\` before any resolver.

**Verified:** whole tree builds under MSVC v142 x64; 38 logic tests, 65 bridge checks, 24
wire-level acceptance checks; a recorded session reopens from HDF5 with 12 event records and 28
named status channels; assembly resolution works from the private directory.

⚠ **No magnetic stimulator has ever been attached to this PC** (only an NS-65 and a Neuro-MEP
*electrical* stimulator). Everything past enumeration is unexercised. **[neuroms.md §9](../components/neuroms.md)**
is a step-by-step hardware bring-up with a contingency for each failure, and §11 lists the seven
inferences that want confirming — the most important being whether opening the device leaves the
TTL trigger input working.

