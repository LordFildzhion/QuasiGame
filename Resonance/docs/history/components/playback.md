# `playbackService` — replaying a recording as live services — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/playback.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-playbackservice--replaying-a-recording-as-live-services"></a>


**Added 2026-08-15.** Point it at an HDF5 file a Resonance recorder wrote, choose which of its
streams to replay, what to publish them as and which service name each should appear to come
from, pick a speed, and press play. Consumers see ordinary Resonance services publishing
ordinary streams; nothing downstream has to know it is looking at a recording.

Read [architecture.md](../migrations/framework-evolution.md) first for what a service and a stream are, and
[recorder-service.md](recorder.md) for the file format this reads.

> **Ported to Qt 6, and shipping as the default.** `R:\dist\playbackService.bat` and
> `R:\dist\playbackSource.bat` → `R:\dist\bin\playbackService.exe` /
> `playbackSource.exe`, built from `R:\src` against Qt 6.11.2 / MSVC v143 14.44 / C++20. The
> Qt 5.15.2 build survives as the comparator in `R:\dist_Qt5\msvc64`.
> **The pacing survived the port intact** — `player.{hpp,cpp}`, `sourcemain.cpp` and
> `hdfsource.{hpp,cpp}` are **byte-identical** in `R:\src` and `R:\src_Qt5` (§6).
> ⚠ The recorder it reads has changed format underneath it — §5.
> Background: [qt5-to-qt6-transition.md](../migrations/qt5-to-qt6-transition.md).

---


<a id="history-2-what-the-operator-sets"></a>

## 2. What the operator sets

All in the `Playback` service's parameters, so the Configurator and the module's own window are
two views of one state.

| Group | Name | Meaning |
|---|---|---|
| `main` | `file` | Path to the recording. Setting it re-scans, which fills in the `streams` tab. |
| | `rescan` | Action. Read the file again. |
| | `contents` | Read-only summary of what the file holds. |
| | `defaultService` | Service name a newly scanned stream is given. |
| | `speed` | Multiple of the recorded rate. Live-adjustable while playing. |
| | `loop`, `scaleRate`, `autoStart`, `showUi` | |
| `streams` | `play<i>` / `name<i>` / `service<i>` | Per stream, in file order: replay it or not, the name to publish it under, and the service it should appear to come from. |

<a id="history-states-and-transitions"></a>

### States and transitions

```
idle ──prepare──► preparing ──(workers up)──► armed ──start──► playing ⇄ paused
  └────start─────► preparing ──(workers up)──► armed ──┘   (passed straight through)
        every state ──stop──► idle
```

| State | What is true |
|---|---|
| `idle` | Nothing running. The file and the mapping can be changed. |
| `preparing` | Workers being spawned; each opens the file and indexes it. Seconds on a 5 GB file. |
| **`armed`** | **The spoofed services are on the network with their streams published and listening, and nothing is being emitted.** |
| `playing` / `paused` | |

**`prepare` is what makes re-recording lossless.** A consumer needs a discovery cycle to find a
stream — around a second — while `start` from `idle` begins emitting a quarter of a second after
the workers come up. So the natural sequence loses the head of the recording to whoever was not
connected yet. Preparing first publishes the streams and then waits indefinitely: point a
recorder's slots at them, start the recorder, watch it attach, and only then press Play. Measured
end to end, that is the difference between 327 of 328 blocks and **all** of them (§7).

`start` straight from `idle` still works and still passes through `armed` in a few tens of
milliseconds — it is the same path with nobody waiting in the middle, and it is what `autoStart`
uses.

While anything other than `idle` is active the file and the mapping parameters are **disabled**,
in the window and in a Configurator alike: the workers were spawned from that mapping, so editing
it afterwards would change what is displayed without changing what is publishing.

`playbackSource` run on its own needs none of this — it publishes its streams the moment it
launches and sits there until something sends it `start`.

**The recording does not carry the name of the service that produced it.** `streamInfo/connections`
holds a resolved `tcp-ip://host:port` and nothing else, so the producing service name is not
recoverable from the file and has to be supplied. That is what `defaultService` and the per-stream
`service<i>` fields are for, and it is the one thing the operator cannot simply accept as-is.

Streams that share a service name share one worker process. Keeping the recorded stream names and
setting the service names to the ones the original session used is what makes every consumer
configured for that session — a recorder's slots, a SPEED script's inputs, a viewer's connector —
resolve the playback without being touched.


<a id="history-3-the-timeline"></a>

## 3. The timeline

Every block in a Resonance recording carries `created`, the RTC at which its producer made it.
That is the timeline being reproduced. With an anchor `startRtc` and a `speed`, block *j* of any
lane is due at

```
due(j) = startRtc + (created(j) - originRtc) / speed
```

and it is emitted **stamped with `due(j)`** rather than with the clock reading at the moment it
actually goes out. Two reasons:

* the intended timeline is then exact, so a re-recording of a playback reproduces the original
  file's block cadence to the nanosecond — measured, not asserted (§7);
* a consumer comparing `received` against `created` sees this module's own lateness honestly
  rather than having it hidden, which is how the figures in §7 were obtained at all.

`originRtc` is the earliest block across **every selected stream**, computed by the controller and
copied into every worker's job. A worker that computed its own would start its service at its own
first block and put the services out of step by whatever their producers differed by. The same
applies to the loop point: workers that wrapped at their own last block would drift a little
further apart on every lap.

**Pause, resume and a speed change are all the same operation** — re-anchor. The block cursor
never moves, so `startRtc' = resumeAt - alreadyPlayed / speed` continues exactly where the hold
left off. The controller does that arithmetic once and pushes one anchor to every worker, which
is why they stay together across a pause.

A **hold is issued for an instant**, a fixed lead-in ahead, not for "now", so every service stops
at the same point on the source timeline rather than wherever its own message happened to land.

<a id="history-speed"></a>

### Speed

Speed changes how fast blocks go out, not what is in them, and the declared sampling rate is
unchanged. That is the literal reading of "play at 2x": the same recording arriving twice as
fast, which re-records the original file unchanged in half the time.

`scaleRate` opts into the other reading, where the published rate is multiplied by the speed so
the stream reads as real-time at the new pace. It is fixed when playback starts, because the rate
is part of the stream's type and changing it mid-playback would force every consumer to
reconnect — so with `scaleRate` on, a speed change is deferred to the next start rather than
applied live.


<a id="history-5-reading-the-file"></a>

## 5. Reading the file

The layout is whatever `internal/HDFRecorder.cpp` writes — and since 2026-09-02 there are two
generations of that writer. **`hdfsource.cpp` reads both and did not have to change for it**: it is
byte-identical in `R:\src` and `R:\src_Qt5`. Two Qt 5-era quirks have to be absorbed, because both
look like real data:

* **`data` has one row too many — in a Qt 5 file.** Each append extends the dataset to
  `offset + samples + 1` and then writes `samples` rows, so a Qt 5 recording always ends with one
  uninitialised row. Row counts therefore come from the block index, never from the dataset shape.
  The Qt 6 writer extends to `offset + samples`, so a Qt 6 file holds exactly the sum
  ([recorder-service.md §2a](recorder.md)). Reading from the index is right either way,
  and the tolerance is one-sided by design: the reader fails only when the index claims **more**
  samples than `data` holds, so a file with no spare row is accepted without comment.
* **An empty index is one row, not none — in a Qt 5 file.** `blocks` and `messages` are created
  at size 1 and the first append writes *into* that row, so a stream that recorded nothing cannot be
  told from one that recorded a single all-zero block by shape alone. The `blocks` attribute settles
  it for Float64; for messages a leading all-zero record is dropped. The Qt 6 writer creates all
  three at size 0, so an empty stream is an empty dataset. Both paths stay in the reader for as long
  as Qt 5 recordings exist, which is indefinitely.

`streamInfo/temporary_as_json` is a full `StreamInfo::toJson()`, so one call to
`StreamInfo::fromJson()` restores the serialized type **and the per-channel metadata** — channel
names, kinds and units come back exactly as they were published, and a viewer groups the
replayed stream the way it grouped the original.

`Float64` and `Message` streams are playable. `EventBus` is listed and refused: republishing
recorded descriptions, parameter sets and transitions would drive live services from a dead
session. A stream that cannot be read at all is still listed, with the reason — an operator who
sees only two of three streams has no way to tell whether the third was ever recorded.


<a id="history-6-pacing-why-not-a-qtimer"></a>

## 6. Pacing: why not a QTimer

This is the part that took the measuring.

⚠ **This is a Windows constraint, not a Qt 5 one, and the Qt 6 port did not lift it.** Qt's
Windows event dispatcher arms timers with `SetTimer`, so a `QTimer` — `Qt::PreciseTimer`
or not — can only fire on a `WM_TIMER`, and those are quantized to the ~15.6 ms user-mode tick
however the system timer resolution is set. What is established under Qt 6.11.2 is that the
workaround is still in place and still needed: `player.{hpp,cpp}`, `sourcemain.cpp` and
`SignalGenerator`'s `pacer.{hpp,cpp}` are **byte-identical** in `R:\src` and `R:\src_Qt5`, so the
Qt 6 service paces on the same high-resolution waitable timer and never asks a `QTimer` for this.
The table itself was measured under Qt 5.15.2 and has **not** been re-measured under Qt 6.11.2 —
do not read "Qt 5" out of it and reach for a `QTimer` on the strength of the version having moved.

Measured on this machine with the resolution already at 1 ms:

| Waiting mechanism | Mean lateness | Max |
|---|---|---|
| `QTimer`, `Qt::PreciseTimer` | 6.7 ms | 15.7 ms |
| the same, plus `timeBeginPeriod(1)` | 6.7 ms | 15.6 ms |
| `QWaitCondition::wait(deadline)` on its own thread | 9.3 ms | 16.7 ms |
| **`CREATE_WAITABLE_TIMER_HIGH_RESOLUTION` on its own thread** | **0.48 ms** | **2.5 ms** |

Half a tick on average, exactly as the explanation predicts. On a recording whose blocks are
further apart than a tick that is merely untidy; on one with 4 ms blocks (25 kHz at block 100) it
would bunch every fourth block into one wake and the emulation would stop resembling the
amplifier it is standing in for.

So `Pacer` waits on a **high-resolution waitable timer** (Windows 10 1803+, the same mechanism a
modern `time.sleep` uses), on its own thread, and posts the wake-up to the player's thread where
the event loop picks it up on the next posted event rather than on the next tick. Anywhere else,
and on Windows too old for the flag, it falls back to the condition variable.

`timeBeginPeriod(1)` is still called for the life of a player process. It did not fix this on its
own, but it costs nothing and it helps everything else in the process.

`CreateWaitableTimerExW` is resolved with `GetProcAddress` rather than called directly: it is
declared only behind `_WIN32_WINNT >= 0x0600` and the toolchains disagree about the default —
MinGW 8.1 leaves it below Vista and the declaration disappears. Under Qt 6 this module is built by
MSVC v143 only, so the indirection is belt and braces here; MinGW 8.1 survives for the KARDi2 x86
island alone ([qt5-still-needed.md](../migrations/qt5-still-needed.md)), and the guard stays because it costs
one function pointer.

<a id="history-the-other-8-milliseconds"></a>

### The other 8 milliseconds

With the pacer in place a 4-channel stream paced at 0.4 ms while the 67-channel 25 kHz stream
still sat at 8.5 ms. The cause was **`QVector::removeFirst()` on the prefetch queue**.

Qt treats any type without an explicit `Q_DECLARE_TYPEINFO` as *static*, and `QVector::remove`
shuffles a static type's tail down by **copy assignment**. The queue elements each held a
`std::vector<double>` of one block's samples, so with ~30 blocks queued every pop deep-copied
about **thirty megabytes** — on the thread that is supposed to be emitting on time.

`std::deque::pop_front()` moves nothing. 8.5 ms → 0.45 ms, on the same file, with no other
change. It only shows up on a stream wide and fast enough for the queue to be worth megabytes,
which is why a narrow stream measured clean throughout.


<a id="history-7-verified"></a>

## 7. Verified

⚠ **Everything in §7 was measured on the Qt 5 build**, which was built under **all three
toolchains** — MSVC v142 x64, MinGW-w64 x64, MinGW x86 — and deployed to `R:\dist\msvc64`,
the tree now called `R:\dist_Qt5\msvc64`. The Qt 6 build is MSVC v143 14.44 only and
deploys to `R:\dist`; its own
evidence is `R:\src\docs\VALIDATION.md`, "Generator, recorder, and playback validation" — a
scan of a recorder-produced file, `idle -> preparing -> armed -> playing -> idle`, and 461 replayed
blocks counted by an independent `TimeSeriesReceiver` — plus the registered `test_PlaybackSeek`.
The fidelity figures below have not been re-measured under Qt 6.

<a id="history-synthetic-reference"></a>

### Synthetic reference

Two `signalGenerator` instances under different service names (`gen1`/`eeg` 4 ch @ 250 Hz,
`gen2`/`aux` 2 ch @ 100 Hz) plus ten operator annotations, recorded by `recorderService` into one
file. Replayed with `eeg` → service `gen1`, `aux` → service `gen2`, `annotations` → service
`notes`, and re-recorded.

| Check | Result |
|---|---|
| Samples | **bit-identical**, every replayed sample, both streams |
| Block sizes | reproduced exactly over 324 consecutive blocks |
| Block cadence | inter-block interval error **median, p95 and max all 0.0000 ms** |
| Cumulative drift | **0.000 ms** over 32.5 s |
| Messages | payloads identical, spacing identical |
| Two spoofed services | cross-stream offset unchanged |
| NaN | none introduced |
| **Channel metadata** | a 30-electrode `.ced` montage came back **identical** — names `F3, F4, FC5…`, `theta`, `radius` — so a viewer labels and groups a replayed stream exactly as it did the original |
| x2 | 32.2635 s of source in **16.1317 s** of wall time, 0.000 ms drift, samples identical |
| x0.5 | 19.9125 s of source in **39.8251 s**, 0.000 ms drift, samples identical |
| Loop | 2.43 laps, every one of 19,950 rows matching the original repeated, at a consistent phase |
| Pause / resume | `idle → preparing → armed → playing → paused → playing → idle`, cursor preserved |
| **Prepare, then connect, then play** | recorder slots showed live `tcp-ip://` connections **before** Play was sent; the recording then came back **complete** — 328/328 and 327/327 blocks, 11/11 messages, sample match at **row 0** |

<a id="history-the-graduation-file"></a>

### The graduation file

`N:\Projects_MSU\2025 - TEP\data - raw\tests\30 test Timofey sync phases\01_TP_M1_60MSO_single_REAL.hdf5`
— **5.25 GB**, `eeg` 67 channels @ 25 kHz (4,995 blocks, 9.8 M samples, 391.9 s) and `stimuli`
(75 messages), from two different producers. Replayed as `NVX136`/`eeg` and
`quickStimulus`/`stimuli` — two spoofed services — and re-recorded for 200 s.

| Check | Result |
|---|---|
| Samples | **all 5,007,520 replayed samples bit-identical**, 0 blocks differing |
| Block sizes | a contiguous run of the original's |
| Block cadence | interval error **median and max 0.0000 ms** |
| Span | original 200.1913 s → playback 200.1913 s, drift **0 ms** |
| Messages | 38 of 75 (the recorder joined 6 s in), payloads and spacing identical |
| NaN | 0 → 0 |
| Emission lateness | **0.445 ms mean, 4.7 ms max, 0 underruns** at 13.4 MB/s |
| Memory | ~35 MB of read-ahead; the file is never loaded |

Playing straight off the network share and playing from a local copy measure the same
(0.45 ms mean, 3.0–3.7 ms max), so the prefetcher absorbs SMB latency and a recording does not
have to be copied locally first.

**End to end**, `received - created` in the re-recording was median 13.3 ms / p95 25.7 ms against
the original session's median 2.5 ms / p95 3.5 ms. The module's own share of that is the 0.445 ms
above; the rest is transport of a 1 MB block to a consumer that is simultaneously writing
13.5 MB/s to disk, while this process reads another 13.4 MB/s. It is worth knowing, and it is not
the pacing.

For scale, the real NVX136 at this rate delivers blocks with arrival gaps of 78–113.5 ms against
a 75 ms poll (STATUS.md ([change history](../changes/README.md))) — the emulation is steadier than the amplifier it stands in
for.


<a id="history-7a-using-it-to-test-a-viewer-or-a-pipeline--what-to-expect"></a>

## 7a. Using it to test a viewer or a pipeline — what to expect

This module exists to drive the things downstream of an amplifier: the signal viewer, a SPEED
script, a recorder, or a chain of all three. What follows is what actually bites in that use,
in rough order of how soon.

<a id="history-7a1-configuring-a-recorder-with-more-than-one-stream-cannot-be-scripted"></a>

### 7a.1 Configuring a recorder with more than one stream cannot be scripted

**This is the one that will cost you time.** A saved parameter set — `--serviceConfig` on the
command line, or the Configurator's Load — that raises `recorderService`'s `streamsCount` to 2 or
more **cannot fill the slots it just created**, because `applyParameters` decides which parameter
names it knows before it applies anything, and `stream2` did not exist at that moment. It fails
*silently*: `fileName` and `streamsCount` are applied, `stream2…N` are rejected with a line in a
log no windowed service shows you, and you get a recorder that looks configured and records one
stream.

`SPEED`'s `inputsCount` → `input1…N` has exactly the same shape, so a multi-input pipeline is
affected too.

Three ways round it, in order of preference:

1. **Configure by hand in the Configurator.** This works — the Configurator sends one parameter
   at a time, so the slots exist by the time they are filled.
2. **Drive it from a QML harness**, which is the same path: `quickStimulus.exe -l harness.qml`
   with `ServiceLocator.findService("Recorder").sendParameter(…)`, one call per parameter, a
   beat apart. This is what the verification in §7 does, and it is the only scriptable option.
3. **Fix `CommunicationLayer::applyParameters`** to re-screen rejected names on each retry round.
   Around ten lines, and the loop it sits in already guarantees termination — but it changes
   behaviour for every service in the tree, so it was not done in passing.

The ctypes bridge is **not** an option: `sendParametersToService` returns true and applies
nothing ([known-issues §15e](../incidents/README.md)).

<a id="history-7a2-press-prepare-before-play-or-you-lose-the-head-of-the-recording"></a>

### 7a.2 Press Prepare before Play, or you lose the head of the recording

Pressing **Play** straight from idle spawns the workers and starts emitting a quarter of a second
later. A consumer needs a *discovery cycle* to find a stream — up to about a second — so anything
not already connected misses the beginning. Measured across the runs in §7, a recorder started
shortly before `start` lost between **0 and about 0.8 s**, varying run to run purely on where the
cycle happened to fall.

**Prepare** exists for exactly this. It publishes the spoofed services and their streams and then
waits: the streams are on the network, listening, emitting nothing, indefinitely.

The sequence for a lossless re-recording:

1. Choose the file, set the names and services, press **Prepare**. The state goes to `armed`.
2. Point your recorder's slots (or the viewer's connector, or SPEED's inputs) at the spoofed
   streams and **start the recorder**. Watch the slots go from waiting to connected — the
   recorder's own window shows this, and so does the Configurator.
3. Press **Play**.

Verified end to end: with Prepare, all 328 eeg blocks, all 327 aux blocks and all 11 messages
were recovered, the sample match starting at **row 0** of the original. Without it, the same run
lost between one and eight blocks per stream.

`loop` remains an alternative if you would rather not choreograph it — playback wraps with no
gap, so the second lap is complete regardless.

<a id="history-7a3-a-re-recording-is-not-a-copy-of-the-original-file"></a>

### 7a.3 A re-recording is not a copy of the original file

The **samples are bit-identical** and the **block cadence is exact** — that much is measured. But
the new file is not the old file:

| | |
|---|---|
| `created` | Reproduces the original's *spacing* exactly, but on today's clock. RTC is `QueryPerformanceCounter` since boot, so the absolute values differ by whatever the offset happens to be. Differences within a file are what carry meaning; absolute values never did. |
| `received` | Genuinely new — it is when your consumer got the block, on this machine, today. |
| `streamInfo/uid`, `connections` | The playback process's, not the original producer's. |
| `metaData` | **Identical.** Verified: a 30-electrode montage came back with the same channel names (`F3`, `F4`, `FC5`…), `theta` and `radius`. |
| Channel count, sampling rate, block sizes | Identical (unless `scaleRate` is on). |
| Length | However long you recorded for. |

So a re-recording is a faithful *replay* of the session, not a byte-copy of the file. If you
need to prove a pipeline is transparent, compare the sample arrays and the `created` deltas —
which is exactly what `compare.py`/`compare_big.py` in the session scratchpad do.

<a id="history-7a4-watch-the-stream-names-when-the-recorder-records-its-own"></a>

### 7a.4 Watch the stream names when the recorder records its own

`recorderService` always records its **own** `annotations` stream, and it registers that first. So
if you replay a recorded `annotations` stream *under the same name* and record it with
`recorderService`, the recorder's own takes the name and yours is de-duplicated to
**`annotations_1`**. Give it a different published name (`marks`, say) and the file stays
readable.

The same applies to any name collision between two spoofed services feeding one recorder.

<a id="history-7a5-speed-and-the-viewers-time-axis"></a>

### 7a.5 Speed and the viewer's time axis

At any speed other than 1, you have to choose which of two things stays true, and the
`scaleRate` parameter is that choice:

| `scaleRate` | What the consumer sees | Use it for |
|---|---|---|
| **off** (default) | Blocks arrive N times faster; the stream still declares its recorded rate. A viewer's 10 s window therefore fills in 10/N seconds and its time ruler reads N times slow. | **Re-recording.** The file that comes out is the original file, produced in 1/N of the time. |
| **on** | The declared rate is multiplied by N, so the viewer's time axis is right in wall-clock terms — but every frequency in the signal is multiplied by N too (10 Hz alpha reads as 20 Hz). | **Watching**, and any pipeline that derives its own timing from the declared rate. |

For a processing pipeline with real-time assumptions — anything using SPEED's `onTimer`, or a
filter whose corner frequencies are in Hz — **run at 1x**. Speed is a tool for getting through a
long file, not for testing a pipeline faster.

`scaleRate` is fixed when playback starts, because the rate is part of the stream's type and
changing it mid-flight would force every consumer to reconnect. With it on, a speed change is
deferred to the next start rather than applied live.

<a id="history-7a6-do-not-spoof-a-service-whose-real-driver-is-running"></a>

### 7a.6 Do not spoof a service whose real driver is running

Discovery matches on the service *name*. If you publish `eeg` as `NVX136` while a real
`nvx136.exe` is on the same machine, both answer, and a consumer attaches to whichever replies
first. There is no arbitration and no warning. Use distinct names (`NVX136-replay`) unless you
specifically want the substitution to be invisible, and when you do want that, make sure the
real driver is stopped.

⚠ **The subnet half of this warning no longer applies by default.** It used to read "or on
the same subnet, because discovery is LAN-wide", and that a replay was therefore visible to
other rigs. Since 2026-08-18 discovery is confined to one machine unless a rig is explicitly
put in `lan` mode ([network-isolation.md](../migrations/network-isolation.md)) — in which case the old
warning applies in full.

<a id="history-7a7-seek"></a>

### 7a.7 Seek

**Click anywhere on the progress bar to jump there, or drag along it to scrub.** It works while
playing, while paused and while armed; while the mouse is down the bar and the readout show the
point being pointed at, and one seek is issued on release. The readout is in **recording time** —
where you are in the file — at every speed.

What a seek is, and what it deliberately is not:

* It is a change of **cursor**, sent to the workers as one `SEEK <positionNs>` line. The published
  streams are announced once, in `Player::prepare()`, and a seek does not touch them. Re-preparing
  would re-`listen()` on port 0 and hand every consumer a different port.
* The target is in **recording nanoseconds** from the session origin, never wall-clock elapsed —
  the two differ by exactly `speed`, and `scaleRate` is off by default.
* Each stream lands on **the first block whose `created` is at or after the target**. A stream that
  does not begin until later has nothing to send yet and simply waits; one that ended earlier is
  skipped. Both are normal and silent.
* A drag to the right-hand edge is **clamped to the last block**, not to the end of the span:
  landing past every block ends the playback, and an ended playback stops the session and tears
  the workers down.
* Seeking **backwards while playing** is supported and needs no special case.

⚠ **A seek is a discontinuity in every consumer's input, and playback does not reset anyone.** The
viewer's epoch cutter detects the jump as a gap, refuses the epochs whose window straddles it and
recovers within one window — nothing to do. A **stateful filter does not**: a TEP pipeline's IIR
sections ring after a step, measured in this tree at 1758 µV decaying over ten epochs. The only
reset that exists (`Reset session`) also discards every epoch collected so far, so pressing it
remotely would be a worse failure than the transient. Playback therefore publishes
`event: "seek"` on its `status` stream and says so in the window; resetting a filtering consumer
is the operator's call.

Two details that are easy to get wrong and are settled in code:

* **`seekToFraction()` returns where the seek actually landed**, and the window quotes *that*.
  It is not `fraction * spanNs`: the clamp above moves it, so the right-hand edge of a 12:37.5
  recording lands at 12:37.0. Quoting the fraction put a time on screen the replay had not
  gone to.
* **The anchor is signed** (`qint64`, in both `Player` and `PlaybackService`, and on the control
  line). It is the clock reading that the recording's *origin* maps to, and `RTC::now()` on
  Windows is `QueryPerformanceCounter`-derived — it counts from boot. A seek to `T` at speed `s`
  needs `T/s` nanoseconds of it, so seeking deep into a recording at a slow speed places that
  (purely notional; nothing is ever emitted there) origin before the machine started. Clamping it
  to zero made every remaining block overdue and dumped the rest of the recording into the
  consumers at burst rate — and 0 also doubles as the controller's "not anchored yet" sentinel, so
  the bar froze. The condition is `T/speed > uptime`: at 0.05x on this file, any uptime under
  2 h 18 m; at 1x, seeking past 6:56 within 6:56 of booting. Signed arithmetic removes the case.
  qint64 holds 292 years of nanoseconds, so there is no wrap to trade for it.

**Measured** (2026-08-22, `test_online_tepsound.hdf` and `12_52MSO_TMS_BCI.hdf5`, MSVC64):

| | |
|---|---|
| bar and readout update after the mouse release | ≤ 1 ms |
| first epoch at a consumer, seeking to the epoched half of a 757 s file | 846–855 ms over three runs (0.25 s of that is the fixed lead-in, 0.60 s is recording time to the next epoch) |
| first block at a consumer, 4.08 GB / 75 ch / 25 kHz, five seeks | 278–396 ms in four of five |
| player-side worst block lateness across that run | 1.5 ms, 0 underruns |
| same click at speed 1 and speed 4 | targets agree to 65 ns; the epochs delivered agree to ≤ 10 ms of recording time |
| `TcpStreamSender: Ready` lines across every seek | 0 |

<a id="history-7a8-what-the-recording-does-not-contain-playback-cannot-invent"></a>

### 7a.8 What the recording does not contain, playback cannot invent

* **Files recorded before 2026-08-13 carry no per-channel metadata.** The graduation file's
  `metaData` is `{}`, so a viewer fed from it falls back to name heuristics and shows `Ch N`
  exactly as it would have during the original session. Playback passes through whatever is
  there and adds nothing. If you are testing viewer *grouping*, use a recording made by a driver
  that publishes metadata (`nvx`, `nvx136`, `neuronSpectrum`) or by `signalGenerator` with a
  `.ced` loaded.
* **The producing service's name is not in the file** — only a resolved `tcp-ip://host:port`.
  You have to supply it, which is what §2 is about.
* **`EventBus` streams are refused.** A recorded control channel cannot be replayed onto a live
  bus, by design.
* **Defects in the recording are reproduced faithfully**, including gaps and NaN runs. A file
  recorded during the NVX 5 kHz fault will replay that fault. That is usually the point.

<a id="history-7a9-timing-honestly"></a>

### 7a.9 Timing, honestly

Two different numbers, and they answer different questions:

* **Emission lateness** — how far past its scheduled instant a block actually left the player.
  **0.45 ms mean, under 5 ms worst case**, at 67 channels and 25 kHz. This is the module's own
  fidelity and it is what §6 was about.
* **End-to-end `received - created`** in a re-recording — median 13.3 ms at 25 kHz, against
  2.5 ms for the original live session. The extra is transport of a 1 MB block to a consumer
  writing 13.5 MB/s to disk while this process reads another 13.4 MB/s; it is not the pacing.

**If your pipeline measures its own latency, playback is not a valid stand-in for the amplifier**
at high data rates — you will measure the replay path as well. For everything else (correctness,
throughput, display, recording) it is faithful, and steadier than the hardware: the real NVX136
at this rate delivers with arrival gaps of 78–113.5 ms against a 75 ms poll.

⚠ **This used to say playback was the better synthetic source because the generator paced on a
`QTimer`. That stopped being true on 2026-08-17 and is not true in either tree today.**
`SignalGenerator` runs the same high-resolution pacer — `pacer.{hpp,cpp}` is that class, the
second copy of it in the tree — and measures 0.377 ms mean / 0.853 ms worst lateness
([signal-generator.md §6](signal-generator.md)). Choose between the two on what you need
in the samples, not on pacing.

<a id="history-7a10-not-exercised"></a>

### 7a.10 Not exercised

Stated so nobody assumes otherwise:

* **Two consumers on one spoofed stream.** The framework fans out through
  `OutputStreamAggregator` and there is no reason it would not work; it was not tested.
* **Playback across the network** to a consumer on another machine. Everything here was
  loopback. The shared start anchor is `QueryPerformanceCounter`-derived and therefore
  **machine-local** — workers on one host stay in step, but nothing here synchronises across
  hosts. ⚠ Since 2026-08-18 this is not merely untested but **refused** in the default mode:
  the stream server binds `127.0.0.1` and a remote address is never dialled. It needs
  `networkMode: lan` on both machines before it could even be attempted.
* **A file with more than a handful of streams**, or more than two spoofed services at once.
* **Very small blocks at a very high rate** — the 4 ms case §6 argues about was reasoned, not
  measured. Blocks of 1560–2000 samples at 25 kHz were.


<a id="history-8-traps-this-walked-into"></a>

## 8. Traps this walked into

Four framework-level things this module ran into. **Only the first affects an operator** — it is
§7a.1, repeated here for the record. The other three are for whoever writes the next service,
and each cost real debugging time here.

| | Who it bites | What it looks like |
|---|---|---|
| `applyParameters` screens names first | **operators**, today | A saved multi-stream recorder or SPEED config loads *half*, silently |
| `OutputStream::ready` fires in the constructor | anyone writing a service | A readiness handshake that waits forever |
| `QVector::removeFirst()` deep-copies its tail | anyone queueing containers | Milliseconds of latency that only appear on wide, fast streams |
| `QTimer` cannot pace under 15.6 ms | anything that emits on a schedule | `Qt::PreciseTimer` quietly not being precise |

**`applyParameters` decides what it knows before it applies anything**, so a parameter that only
comes into existence as a side effect of another one in the same set is rejected and never
retried. Full practical consequences and the three workarounds: **§7a.1**. It is in
`Core/Resonance/communicationlayer.cpp` and it affects `SPEED`'s inputs the same way, so it is
not a playback defect — it is why the test harness for this module configures the recorder over
the EventBus rather than from a file.

**`OutputStream::ready` has already fired by the time you can connect to it.** The constructor
posts to `StreamPool` with `Qt::AutoConnection`, and `StreamPool` lives on the main thread — so a
stream built *on* the main thread is created synchronously inside the constructor and `ready` is
emitted before the line after `new` runs. A `connect` made afterwards attaches to a signal that
has been and gone, and a readiness handshake built on it waits forever. The amplifier drivers
build their streams on a worker thread, where the same `AutoConnection` is a queued one and the
signal really is deferred, which is why the pattern they use looks like it should work. Check
`state()` as well as listening, and re-announce with an explicit `sendDescription()`.

**A `QVector` of anything holding a container is a copying queue**, because Qt treats a type
with no `Q_DECLARE_TYPEINFO` as static and shuffles a static type's tail down by copy assignment.
Cost here: 8.5 ms of added lateness per block, invisible on every small stream it was developed
against. See §6.

**`QTimer` cannot pace anything finer than the 15.6 ms Windows tick**, `Qt::PreciseTimer` or not,
and raising the system timer resolution does not change that. It is a property of Windows rather
than of a Qt version, and the move to Qt 6.11.2 did not change it. Table in §6.
`SignalGenerator` had the same jitter and now runs a copy of this module's pacer.

**`windows.h` needs `NOMINMAX`** or every `std::min<T>()` in the translation unit stops compiling,
and it needs it *before* the include rather than on the command line if the file is to be
self-contained. `CreateWaitableTimerExW` additionally has to be resolved with `GetProcAddress`,
because MinGW 8.1 hides its declaration behind a `_WIN32_WINNT` default neither tree sets. MinGW 8.1
now compiles only the KARDi2 x86 island; the indirection stays because it costs one function pointer.


<a id="history-9-operating-notes"></a>

## 9. Operating notes

* **Workers appear when playback is armed and disappear when it stops**, the way an amplifier's
  stream appears when the device is started. A consumer with `reconnect` on — the default —
  re-attaches by name across a stop and a fresh start.
* **A consumer needs a discovery cycle to attach**, which is about a second, while playback
  starts a quarter of a second after the workers report ready. Start the consumer first if the
  head of the recording matters; otherwise the first second or two is missed. There is no way
  around this that does not put dead air at the front of every playback.
* **Killing the controller kills the workers** — they exit when the control channel drops, so a
  crash cannot leave services behind advertising streams that will never carry anything.
* Nothing here touches hardware, so the standing rule about stopping an amplifier service before
  terminating it does not apply. A worker can be killed at any time.
* **Do not give a worker the controller's own service name** unless you mean it. Two services
  answering to `Playback` is legal and discovery will find both; it is only confusing.
