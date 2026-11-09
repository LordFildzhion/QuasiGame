# Diode-input trigger test and viewer artifact — 2026-09-18

**2026-09-22 new-board follow-up:** with the user's newly connected Nano repeater,
35/35 A1 pulses passed at 5/10/20/100 Hz, every LOW 3 ms (six NVX samples at
2 kHz), now observed at bit3. Independent raw-HDF5 analysis agreed. No Nano
serial access, reset, upload or power cycling; only one path tested. Test-owned
eStim/NVX services were cleanly released. The external project's
`HARDWARE-20260922.md` and `tests/20260922-newnano01/` retain evidence. This
does not establish firmware identity or close the historical back-power cause.
After the user changed the trigger input port, a second 35/35 campaign passed
on bit4 with the same 3 ms widths at 5/10/20/100 Hz; evidence is in the
external `tests/20260922-newnano02/`. Both tests were sequential, not simultaneous.

**Finalized repeater package / scope observation:** the user's later 2 us/div
photo during the rising-edge smoke test shows approximately **2–3 us**
input-rise to output-fall on the measured path. This is a visual single-capture
estimate, not a two-channel jitter/worst-case guarantee; probe points relative
to the diode were not independently documented. Photo and measurement limits
are retained in the external project's `evidence/scope-rising-edge-20260918.png`
and current `RISING-EDGE-20260918.md`.

Cleanup retained the previous root reports, `tests/`, `_flash/`, old
`_build/` and initial diagram under `history/20260918-development/` in that
external project. Historical literal paths below must be resolved through this
relocation. Current `README.md` and `WIRING-NANO.md` describe final wiring;
`wiring/TTLrepeater_sticker_30x15mm.png` is the 30 x 15 mm print label.
Firmware cleanup was comments only: three builds, three guard rejections,
nine design tests passed; rebuilt Nano HEX matched the flashed rising image
byte for byte. No reset, upload or firing during cleanup. The long-pulse
internal mechanism and separate viewer artifact are not closed by this work.

**Subsequent requested edge change:** dedicated repeater inputs D2/D3 changed
from falling to rising edge to follow the positive input pulse's onset. Built
(three targets, nine design/source tests), flashed COM4 with verification,
then recorded 5/5 active-LOW 3 ms pulses at 5 Hz through the existing NVX at
1 kHz, with settings restored and no amplifier restart. No microsecond latency
claim or back-power fault closure follows from this. External detailed record:
`N:\Projects_MSU\2026 - Passive movements\exe\MioStim\arduinoTTLrepeater\RISING-EDGE-20260918.md`.

**Latest user-reported correction:** Nano-only reset did not clear the fault;
powering off both eStim and Nano was necessary. The user also observed increased
delay with an oscilloscope, without supplying numbers/trace/reference edges.
Earlier successful read/reset recovery is not a universal remedy. A common
clock disturbance is plausible but unproved; Timer1-only prescaler corruption
does not readily explain both onset delay and width, and setup rewrites Timer1.
No hardware actions were taken for this update. The external fault record now
supersedes reset-only recovery advice; the investigation remains stopped.

## Latest finding — diode-free recurrence, preserve state for diagnosis

Subsequent non-resetting agent capture (`20260918-width-fault01` in the
external project's tests directory) confirmed **5/5 LOWs of 115 ms at 5 Hz,
3/5 LOWs of 114 ms at 10 Hz**, NVX at the user's current 1 kHz, with diode
present in the current measurement setup. eStim settings restored; no COM4,
power/firmware or NVX acquisition changes. This is a genuine recurrent raw-data
fault. Corrected multimeter readings: **Nano 5V and D9 both 4.67 V; D2 0.57 V;
stimulator side of diode 0.057 V**. Earlier 4.25 V was VIN, not VCC; the apparent
above-supply D9 anomaly is withdrawn. Source idle LOW contradicts the earlier
idle-HIGH assumption; forward diode drop alone does not identify the timing cause.

After the recovery tests below, the user reported that removing the input
diode brought **~100 ms pulses back**. This is user-reported reproduction,
not a new agent-captured recording. It strongly implicates the unprotected
D2/input back-power path; the exact voltage/reset/timer mechanism is not yet
measured. Earlier 420/420 acceptance does not cover the changed rig.

The user questioned the suggestion to reset before debugging. **Preserve the
faulty state for diagnosis: no reset, USB power interruption, reflash or COM4
opening (which can reset the Nano).** Keep stimulation outputs disconnected.
Supply and D2/D9 waveform measurements should precede recovery; instrument
access is not established. Restoring diodes and resetting is a separately
chosen recovery procedure, not a diagnostic proof or permanent firmware fix.
No further reset/firing was performed during this documentation update.

External wiring authority:
`N:\Projects_MSU\2026 - Passive movements\exe\MioStim\arduinoTTLrepeater\WIRING-NANO.md`,
with progression in `history/20260918-development/WIDTH-RECOVERY-20260918.md`.
Tracked as [TTL-001](../../issues/README.md#ttl-001). The viewer artifact is
separate from this real pulse-width/count fault.

## Earlier recovery evidence

Follow-up: a COM4 bootloader flash **read/reset, without programming**, restored
3.0–3.2 ms recorded LOW widths. Unchanged complete flash readback and the user's
confirmation of unchanged USB/wiring isolate recovery to the reset operation.
The diode-equipped path subsequently passed 420/420 pulses at 5/10/20/100 Hz,
NVX 5 kHz, including 35 after a user-performed ten-second USB unplug/reconnect
with no subsequent software reset. Root cause/prevention remain unproved;
this is not proof of a permanent firmware fix. Detailed evidence:
`N:\Projects_MSU\2026 - Passive movements\exe\MioStim\arduinoTTLrepeater\history\20260918-development\WIDTH-RECOVERY-20260918.md`.
The original 112 ms measurements below remain valid for the earlier state.

## Outcome

At the user's NVX setting of **5 kHz**, 20 A1 trains of five pulses at 5 Hz
produced **100/100 recorded LOW pulses on Trig4**, with no HIGH interruptions
inside them. The full 42.426-second recording contains exactly 100 LOW runs,
not merely 100 inside selected train windows. No trigger sample is nonfinite.

**A thin false vertical spike was independently reproduced in the deployed
viewer using these same clean samples.** It occurs with incremental painting
when multiple receive blocks accumulate between paints; forcing a full repaint
removes it. The symptom can therefore be a display artifact without a recorded
trigger event. This does not prove that every previously observed mark had the
same cause, nor exclude electrical glitches shorter than the 0.2 ms sampling
interval.

**Separate unresolved discrepancy:** measured LOW widths are 112.2–112.4 ms,
not the 3 ms verified in the earlier repeater test. This duration is in the raw
recording, not caused by the viewer. Do not call this a complete 3 ms repeater
acceptance pass. At that stage USB/firmware/wiring confirmation was pending;
it was subsequently supplied for the reset recovery above. The latest
diode-free recurrence is a later change of state.

No production code, firmware, or deployed binaries were changed in this
investigation. Viewer repair is a follow-up implementation task.

## Bench conditions and preservation

The user explicitly confirmed all stimulation outputs disconnected and
authorized the 100-pulse bench test. Attached to existing NVX/eStim services;
did not open/reset COM4, upload firmware, restart NVX, or fire mStim.

- NVX-52 serial 1219, all 32 analog channels plus trigger, 5 kHz, Level mode,
  block size 100, Unipolar; existing acquisition left running.
- A1: 5 Hz, five pulses, 200 us, 3 mA, biphasic anodic, zero interphase/prepulse.
- Temporarily disabled eStim UDP commands and selected Device 1 for the test.
  All eStim parameter values were restored and checked; service returned ready.
- 212130 samples; 561-sample LOW width in 42 pulses and 562 in 58 pulses.
  Within-train falling-edge intervals were 200.0 or 200.2 ms.
- Raw trigger words: 60687 and 60703; only bit 4 changes.
- A read-only post-test service description returned `stateInfo: null`.
  This is **not** a measured zero dropped-sample counter. Recorded trigger
  samples contain no NaNs; the NVX implementation represents repaired gaps
  with NaN rows, including the trigger column.

## Viewer reproduction

Diagnostic source/build script:
`R:\tests\evidence\diode-viewer-20260918\viewer_probe.cpp` and
`build-probe.ps1`. The probe loads the **deployed** QML plugin, not a newly
built candidate, and directly feeds two identical receivers the recorded
trigger samples. No actuator command stream is connected.

Geometry 843×630, duration 3 seconds, 5 kHz, 15000 ring slots, line width 1,
antialiasing enabled, grid disabled. Receive boundaries are preserved.
One receiver paints incrementally; the other forces full repaint before
each frame. Flat data neighborhoods exclude real transitions and the write
cursor; pixel scanning looks for ink between the HIGH and LOW levels.

- One block per paint: 2903 frames, no artifact detected.
- Two blocks per paint: 1452 frames, none.
- Five blocks per paint: 581 frames, none.
- Seventeen blocks per paint: 171 frames, **11 with a false spike in the
  incremental receiver, zero in the full-repaint receiver**.

This is one persistent artifact across 11 frames, not 11 electrical pulses.
At block 339 it is at x=492, inside an otherwise continuous LOW run. Both PNGs
were inspected. The previous paint ends near x=494; the next strip begins at
x=493, leaving the false ink at x=492 untouched until the next sweep. This
isolates the defect to incremental strip/envelope boundary rasterization.
The exact clearing/geometry correction still needs implementation and a
regression covering both trigger lanes and analog waveforms; do not prescribe
an unconditional full repaint as the final performance-safe fix.

## Evidence

External project folder:
`N:\Projects_MSU\2026 - Passive movements\exe\MioStim\arduinoTTLrepeater\tests\20260918-diode-run01`

- `capture.h5`: custom diagnostic HDF5 (not the standard Resonance playback
  schema); full 33-column stream, complete session plus per-train windows,
  block RTCs and lengths. SHA256:
  `2C6EE98817DB562FB267AB4C2023ADF3D1C24EA58F0FB514EC51455D65FBA46B`.
- `parameters-before.json`, `parameters-after.json`, `events.json`,
  `operations.jsonl`, `result.json`, `independent-analysis.json`.
- `all-20-trains.png`: raw sampled waveforms, all trains.
- `viewer-incremental-0.png` versus `viewer-full-0.png`: same samples/frame;
  false spike only in incremental image. Saved artifact images correspond to
  the final batch-17 replay.
- `trigger-blocks.bin`, `viewer-replay-batch1/2/5/17.json`,
  `nvx-state-after.json`. The earlier `viewer-replay.json` used a less sensitive
  detector and one paint per block; it does not contradict the later result.

Deployed `quickStimulusPlugin.dll` SHA256:
`1557EB37780C791348CBCFB6617CC1266DD862D6C4FD465F601016899DBFDC40`.
Deployed `nvx.exe` SHA256:
`490082DD032B9537F78DC753ED4BADBF71FD5B91042D92FAE76FCC7A1C1DE53B`.

## Diode scope and remaining checks

The agreed arrangement places a separate series diode on each connected
stimulator input to D2/D3, with cathode/band toward the stimulator and anode
toward Nano, using the Nano-side pull-up. The black band identifies the cathode
in the [Vishay 1N4148 datasheet](https://www.vishay.com/docs/81857/1n4148.pdf).
This is not galvanic isolation and does not establish protection for other
power paths. Do not blindly add the same arrangement to D9/D10, USB or ground;
the output interface and any actual reverse supply path must be checked first.

Software recording confirms event delivery in this configuration, not voltage
margins or removal of all phantom powering. Measure Nano 5 V with USB absent
and each external cable connected separately to identify remaining backfeed.
First reconcile the 112 ms width with the current power/wiring and loaded
firmware. A scope/logic analyzer remains necessary for microsecond latency,
input pulse shape and sub-sample glitches.
