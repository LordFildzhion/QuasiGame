# 2026-09-04 — tepSound modes; COMport and latencyProbe on Qt 6

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-04--tepsound-modes-comport-and-latencyprobe-on-qt-6"></a>

### 2026-09-04 — tepSound modes; COMport and latencyProbe on Qt 6

`tepSoundService` now exposes three explicit Processing-tab modes. **No processing** runs only
the cue/stage/TTL presentation path and does not start the analysis worker. With that switch off,
**SOUND off** still performs continuous preprocessing, epoching and MEP measurement without
requiring a montage/lead field or producing a `clean` stream; **SOUND on** runs the full chain.
The live service accepted `presentationOnly=true`, started with no signal source or SOUND assets,
and returned to idle. The updated flowchart and control surface are recorded in
`R:\src\docs\qa\tepsound-processing-modes-qt6.png`.

`COMport` and `latencyProbe` are now native Qt 6 services in `R:\src` and `R:\dist`. Their live
Qt 5/Qt 6 parameter contracts match (7 and 12 parameters); every Qt 6 parameter has a tooltip.
COMport additionally fixes the inherited final-byte/reversed send-loop defect while retaining the
misspelled wire key `flowConrol` for saved-configuration compatibility. The complete Qt 6 suite
passes **31/31 enabled tests**; four physical/external tests remain disabled. The distribution
validator passes from the packaged Qt 6.11.2 runtime.

Three active Qt 5 services remain *(as of this entry; all three have been ported since — DAQmx and
fieldtrip on 2026-09-05, stimulusService on 2026-09-06)*: `stimulusService`, `DAQmx`, and `fieldtrip`. NI-DAQmx's current
release is 2026 Q3 and retains the ANSI C calls used locally; the later port should use its current
x64 headers/import library and needs NI hardware for acceptance. FieldTrip's local x86 gate is
artificial: upstream supports Win64 and supplies a standalone buffer plus sine-wave simulators,
making a hardware-free preservation port practical. See [DAQmx](../components/daqmx.md),
[FieldTrip](../components/fieldtrip.md), and [Qt 5 still needed](../migrations/qt5-still-needed.md).

---

