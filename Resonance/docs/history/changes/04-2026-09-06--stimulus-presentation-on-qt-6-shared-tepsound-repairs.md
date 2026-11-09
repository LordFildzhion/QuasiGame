# 2026-09-06 — Stimulus presentation on Qt 6; shared TepSound repairs

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-06--stimulus-presentation-on-qt-6-shared-tepsound-repairs"></a>

### 2026-09-06 — Stimulus presentation on Qt 6; shared TepSound repairs

`R:\dist\stimulusService.bat` now launches **Stimulus**, a native x64 Qt 6.11.2 presentation
service extracted from TepSound. Text, PNG/image, audio, video, blank cues, seeded sequences,
responses, per-cue/background triggers and the subject screen are present; epoching, SOUND,
analysis plots and verdict overlays are absent. The new light console separates Stimuli,
Sequence, Run setup and Monitor, with permanent transport controls and an explicit selected-cue
editor. It follows the 130 px label/solid-square checkbox and executable-icon rules.

The audit repaired the active TepSound presentation path too: End completion, media preroll and
replay, pause/reset, failed-media onset, zero-offset pulse attribution, responses, bad-load
recovery, authoring re-entry, safe media packing, trigger refusal, board residuals and Parameter
LOW on shutdown. Both executables compile the same presentation implementation. TepSound retains
its numerical pipeline and original 135 parameter contracts plus the existing presentationOnly
switch. Typed letters in a TepSound editor no longer activate letter shortcuts, including P.

Clean Release rebuild passed. **34/34 enabled CTests pass; four physical/external tests remain
disabled.** The new presentation target reports **11/11 QtTest cases**, including GUI rendering.
All **315 registered parameters** have descriptions. Live deployed Qt6 Stimulus and TepSound each
presented the same synthetic mixed-media document through a loopback UDP mock and recorderService.
HDF5 checks retain all seven first-run cue onsets and six onset triggers, matching their frame/RTC
attribution; the End row held about **501 ms** for a 500 ms request. Stop/Start/Pause/Resume,
failed-load recovery, parameter locking and normal process exit passed. Live Qt5 contract reads
passed without starting its presentation code. The 21 Stimulus parameters match the corresponding
TepSound Qt6 names/types/labels/groups/order/configured values.

Packaged-Qt distribution validation and the launcher from outside `R:\dist` with a Windows-only
initial PATH pass. Both presentation executables are PE32+ AMD64; **83 build-runtime EXE/DLL files**
match their deployed SHA-256 hashes. Deployment now keeps identical runtime files, allowing the
operator's existing Configurator windows to remain open; changed locked files still fail.

**Timing boundary:** software presentation and decoding work; physical panel/speaker/TTL onset
was not measured. The final mixed-media recordings showed about 90–104 ms of extra delay entering audio and
14–45 ms across the subsequent media transitions; the actual onsets/lag are recorded.
Do not transfer the old Qt5 0.05 ms stage claim to these results. Physical serial outputs, remote
amplifier commands, real stimulator interlocks and monitor hot-unplug need operator acceptance.
No physical trigger equipment was operated.

No active service remains unported. The 18 Controls 1 legacy paradigms and old Stimulus rig
orchestration remain separate scope. tepService is retired; MioStim stays removed/replaced.
Guide and migration: [Stimulus](../components/stimulus-presentation.md),
[TepSound](../components/tepsound.md). Evidence is in `R:\src\docs\qa\stimulus-*`; HDF5 scratch recordings
are in `R:\src\_test-output\stimulus`. No new snapshot was requested for this follow-on port.

