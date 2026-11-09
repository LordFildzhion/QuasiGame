# 2026-08-15 — new module `playbackService`: a recorded session, replayed as live services

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-15--new-module-playbackservice-a-recorded-session-replayed-as-live-services"></a>

### 2026-08-15 — new module `playbackService`: a recorded session, replayed as live services

Full write-up: **[playback-service.md](../components/playback.md)**. Point it at an HDF5 file a
Resonance recorder wrote, tick the streams to replay, give each one a published name and the name
of the service it should appear to come from, pick a speed, press play. Consumers see ordinary
services publishing ordinary streams — a recorder's slots, a SPEED script's inputs, a viewer's
connector all resolve the playback without being touched.

**Two executables, and the reason is structural.** Discovery addresses a stream as (service name,
stream name) and a process may declare exactly one service, so "publish `eeg` as if from NVX136
*and* `stimuli` as if from quickStimulus" is necessarily two processes. `playbackService.exe` is
the controller (file, mapping, transport, window, `status` stream); it spawns one
`playbackSource.exe` per distinct service name and anchors them all to one instant on the
monotonic clock. `playbackSource.exe` is also a complete service on its own —
`playbackSource.bat --file x.h5 --serviceName NVX136 --autoStart` is a working one-liner.

Blocks carry the instant they were **scheduled** for, not the instant they went out, so a
re-recording of a playback reproduces the original's cadence exactly. `originRtc` and the loop
span are computed across every selected stream and shared by all workers, which is what keeps two
spoofed services in step. Pause, resume and a speed change are one operation — re-anchor.

**Verified against the graduation file** — `01_TP_M1_60MSO_single_REAL.hdf5`, **5.25 GB**, 67 ch @
25 kHz plus a stimulus message stream, replayed as `NVX136` + `quickStimulus` and re-recorded:

| | |
|---|---|
| Samples | **all 5,007,520 replayed samples bit-identical**, 0 blocks differing |
| Cadence | inter-block interval error **median and max 0.0000 ms**; span 200.1913 s → 200.1913 s, **0 ms drift** |
| Messages | payloads and spacing identical |
| Emission lateness | **0.445 ms mean, 4.7 ms max, 0 underruns** at 13.4 MB/s |
| NaN | 0 → 0. Memory: ~35 MB of read-ahead; the file is never loaded |

Also verified on a synthetic two-generator reference: bit-identical samples, x2 (32.2635 s of
source in 16.1317 s), x0.5, looping (2.43 laps at a consistent phase), pause/resume. Builds under
**all three toolchains**; deployed to `R:\dist\msvc64`.

Channel metadata round-trips: a 30-electrode `.ced` montage came back with identical names,
`theta` and `radius`, so a viewer labels and groups a replayed stream exactly as it did the
original. (The graduation file predates per-channel metadata and carries none — playback passes
through what is there and invents nothing.)

**`prepare` before `start`.** The transition sequence is
`idle → preparing → armed → playing ⇄ paused`, and `armed` is the point of it: the spoofed
services are on the network with their streams listening and nothing being emitted, indefinitely.
Point a recorder or a viewer at them, start the recorder, *then* press Play. Without it a
consumer spends its first discovery cycle attaching and loses up to ~0.8 s of the head; with it a
re-recording came back **complete** — 328/328 and 327/327 blocks, 11/11 messages, sample match at
row 0. `start` from `idle` still passes straight through `armed` in tens of milliseconds, which
is what `autoStart` uses. The file and the mapping are disabled while workers exist, since they
were spawned from that mapping.

⚠ **The one thing an operator will trip over** is not in this module at all:
**a saved `recorderService` configuration with more than one stream cannot be loaded back**, and
fails silently. `applyParameters` screens parameter names *before* applying anything, so
`stream2` — created by applying `streamsCount` in the same set — was already rejected when the
list was screened. `SPEED`'s `inputsCount` → `input1…N` is the same shape. Configure such a
service from the Configurator or a QML harness, one parameter at a time; the ctypes bridge is not
an alternative. Fixing it is ~10 lines in `communicationlayer.cpp` but changes behaviour for
every service, so it was not done in passing —
[known-issues §16b](../incidents/33-framework-traps-found-building-playbackservice-2026-08-15.md#history-16b-applyparameters-screens-names-before-it-applies-anything--fixed-2026-08-22),
[playback-service §7a.1](../components/playback.md).

Three more framework traps came out of this, all for whoever writes the next service rather than
for an operator: `OutputStream::ready` fires inside the constructor when the stream is built on
the main thread; `QVector::removeFirst()` deep-copies its tail (8.5 ms per block until found);
and `QTimer` cannot pace under the 15.6 ms Windows tick whatever `Qt::PreciseTimer` suggests.
[known-issues §16](../incidents/33-framework-traps-found-building-playbackservice-2026-08-15.md#history-16-framework-traps-found-building-playbackservice-2026-08-15).

