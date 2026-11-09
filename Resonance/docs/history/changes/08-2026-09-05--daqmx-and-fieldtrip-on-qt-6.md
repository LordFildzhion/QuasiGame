# 2026-09-05 — DAQmx and FieldTrip on Qt 6

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-05--daqmx-and-fieldtrip-on-qt-6"></a>

### 2026-09-05 — DAQmx and FieldTrip on Qt 6

Both native x64 ports are implemented, deployed and software-validated. Complete Release rebuild
passed; all **33 enabled CTests passed**, with four hardware/external tests disabled. Both live
Qt 5/Qt 6 parameter/state comparisons passed, all **100** runtime binary hashes match deployment,
and packaged-Qt distribution validation and outside-directory launchers passed.

DAQmx uses the installed current NI SDK/runtime (26.5.0; System32 DLL 26.5.0f461), with no NI
driver bundled. No real/simulated devices were found; no NI acquisition was started. Hardware-free
configuration/setup/read/Done logic and no-device/error recovery passed. Physical acceptance remains.

FieldTrip received official synthetic sine data and recorderService recorded it before/after
header reset and server restart: 3200 × 16 at 512 Hz, 5088 × 3 at 256 Hz and 3360 × 16 at 512 Hz,
with zero counter gaps inside each recording. The service stays running and reconnects; consumers
use new files for changed shape and the QA foreign-driver reader was explicitly rebound. Stop/Start,
silent-peer timeout, official combined demo and clean exit passed. Metadata/events remain deferred.

**Only stimulusService remains an active unported service** *(ported the next day, 2026-09-06)*. tepService is retired; MioStim was
removed/replaced by eStim. See [DAQmx](../components/daqmx.md), [FieldTrip](../components/fieldtrip.md) and
`R:\src\docs\VALIDATION.md`; compact evidence and PNGs are in `R:\src\docs\qa`.

