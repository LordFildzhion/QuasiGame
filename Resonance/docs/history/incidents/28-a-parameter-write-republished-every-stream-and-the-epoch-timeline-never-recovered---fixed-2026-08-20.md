# 21. A parameter write republished every stream, and the epoch timeline never recovered — ✅ fixed 2026-08-20

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-21-a-parameter-write-republished-every-stream-and-the-epoch-timeline-never-recovered---fixed-2026-08-20"></a>

### 21. A parameter write republished every stream, and the epoch timeline never recovered — ✅ fixed 2026-08-20

**TRANSFERS UNCHANGED — the whole fix crossed**, producer half and framework half: `announcement.hpp`,
`Service::m_scheduleRtc`, the `StreamInfo::operator==` repair, the `discover:///` candidate removal,
the coalesced discovery cycles and the `destroyed → cleanConnections` deadlock are all in
`R:\src\Core\Resonance` and `R:\src\SignalGenerator`. ⚠ The `-Runtime R:\dist\msvc64` and
`R:\dist\_build\…` paths in the evidence below are dated 2026-08-20 records; that tree is now
`R:\dist_Qt5\msvc64` and `R:\dist_Qt5\_build\…`. **None of it has been re-measured against `R:\dist`.**

Found while capturing Stage 4 of the viewer's epoch support, reported as *"the epoch stream
delivers nothing for 40-60 s while the viewer reconnects"*. Three of those words were wrong.

<a id="history-what-it-actually-was"></a>

### What it actually was

**It is not a reconnect.** The framework's republish-and-resubscribe path is fast and
framework-wide: **0.2-2.0 s, median ~1.2 s, identical on a continuous stream and an epoch stream**,
across 320 consecutive republishes with no trend
(`R:\dist\_build\stage4\republish\probe-wedgeB-20260820-112435.log`). That matches the figure
already recorded in STATUS ([change history](../changes/README.md)) §"stream reconnection … ~1-2 s". `StreamInfo::isSimilar()`
is not implicated: the producer destroys the `OutputStream`, so the port genuinely moves and the
stream genuinely *is* a different stream.

**It is not 40-60 s, and it is not a constant.** The gap grows **linearly with the number of
republishes**: 2700 ms per republish at `periodMs=300` / 1500 ms between edits, sd ~11 ms over 24
rounds — 8.5 s at the first, 70.6 s at the twenty-fourth, no ceiling
(`R:\dist\_build\stage4\faithful\probe-faithful-20260820-115507.log`). Every observed slope is a
whole multiple of `periodMs` (2700 = 9 × 300, 5100 = 17 × 300, 3000 = 5 × 600). In a 712 s run the
epoch stream went dark at t = 145 s and **never spoke again**, because each republish arrived
before the clock had paid off the previous one.

**It is not epoch-specific.** `Service::pumpEvents()` feeds the trigger channel, the evoked
response, the `stimuli` message lane *and* the epoch lane from one schedule, so after enough
republishes `signalGenerator` stops firing events at all — no triggers, no markers, no evoked
responses, no epochs — while its continuous streams look perfectly healthy. Silent and misleading.

<a id="history-two-defects-both-in-the-producer"></a>

### Two defects, both in the producer

**(a) `publishAll()` rebuilt every stream for every parameter write.**
`Service::onApplyPending()` computed a `Dirty` flag and never tested it, and each lane's
`publish()` began with `unpublish()` and then constructed a new `OutputStream` even when the
resulting description was byte-identical. `TcpStreamSender` listens on port **0**, so *every*
republish moves *every* port. Measured: **1287 `TcpStreamSender: Ready` lines over 320
republishes = 4.02 per republish** — one edit to `epochAmplitude`, an amplitude that appears in no
description any consumer ever reads, dropped every socket on `generated`, `eeg`, `epochs`,
`stimuli` and `status` at once.

**(b) The re-anchor moved the run clock but not the schedule cursor.** `onApplyPending()` did

```cpp
m_startRtc = RTC::now();   // lanes restart at sample 0 -- correct
m_eventHorizon = 0;
rearm();                   // ...but no m_schedule.reset(), and none is wanted
```

`Schedule::peek()` returns seconds **from the start of the run** and its cursor only ever moves
forward; `pumpEvents()` compared it against `horizonSec = (horizon - m_startRtc) / 1e9`, which had
just been set back to ~0. So after K events no further event could fire until wall time climbed
back to K × period. That is the whole of the growing gap, including its quantisation.

The control that proves it: poking `periodMs` instead republishes exactly the same streams, but
because `periodMs` is part of `ScheduleSettings`, `applySchedule()` calls `Schedule::configure()`,
which ends in `reset()`. Gap over 320 republishes: **median 1044 ms, max 1367 ms, flat**.

<a id="history-the-fix"></a>

### The fix

* `announcement.hpp` / `announcement.cpp` (new, pure, in `test_SignalGenerator`): an
  `Announcement` is exactly what reaches the wire — stream name, `Float64` channel count and
  sampling rate, per-channel `MetaData`. `announcementChanged()` is the republish predicate.
  This is the shape `TepService::reconfigure()` already used and `signalGenerator` never had.
* Every `Lane::publish()` now returns **true only when it actually rebuilt the stream**, and
  applies a content-only change in place — keeping the port, the sockets and the queue.
  `blockSize` is not announced, so it resizes the buffer and rebases the block cursor instead.
* `Service::publishAll()` returns the rebuild count; `onApplyPending()` **returns early when it is
  zero** and never touches the run clock.
* `Service::m_scheduleRtc` — the schedule's own origin, separate from the lanes' anchor. The lanes
  may be re-anchored freely; the schedule moves only when `configure()` rewinds its cursor.
* `PlanSource::configure()` and `EegModel::configure()` no longer discard events already pulled
  from the schedule. An event consumed for the look-ahead window can never be produced again.
* Instrumentation, kept in the shipped build: `republishes` and `applies` are now channels on the
  `status` stream (16 → 18 channels), and each republish logs which. **A healthy session leaves
  `republishes` near zero.**

<a id="history-the-framework-half--real-smaller-and-not-the-reported-symptom"></a>

### The framework half — real, smaller, and not the reported symptom

Fixed alongside, in Core, because they are what makes a *necessary* republish expensive:

* **`StreamInfo::operator==` was unusable for `discover://` requests.** It ended in
  `info.d->type->checkConnectionHeader(header)`, and the base `TransmittableType` returns `nullptr`
  from `asConnectionHeader()` and **`false` unconditionally** from `checkConnectionHeader()`. Two
  objects built from the *same* discover URL compared unequal unless they shared a private object.
  That silently disabled `StreamPool`'s one-attempt-per-request cap (`PendingConnection::
  requestedFor`) — and a viewer pane holds two to four `InputStream`s per producer stream, since
  `Parameters::Stream` keeps its own alongside the receiver's. Each opened its own thread and
  socket on every discovery cycle. The cap the comments at §12c describe was there, and off.
  Only the typeId-0 case changed; described streams still compare through their wire header.
* **Every connection attempt dialled one URL that cannot be dialled.** `outputStreamsInfo()`
  appends a `discover:///?stream=…&name=…` URL to each advertised stream, and
  `createPotentialConnections()` passed it through as a candidate. Host empty, so it cost an OS
  thread, a socket and a connect attempt per pending, and produced the misleading line
  `refusing to connect to "discover:///?stream=eeg&name=…" - this service is in loopback mode`,
  which blames the network mode for an unresolved URL reaching the dialer.
* **Discovery cycles are coalesced.** `openStream()` wires every attempt's `stateChanged` back
  into `discoveryCycle()`, and a cycle opens attempts. Those re-entries now go through a 0 ms
  single-shot, so every transition landing in one turn of the event loop costs one cycle. The
  synchronous pair in `discoverStream()` is deliberately *not* coalesced — that is what makes an
  already-pooled stream resolve inside the constructor instead of waiting a 1 s tick.
* **A self-deadlock removed.** `connect(stream, destroyed, this, &StreamPool::cleanConnections)`
  was an Auto (therefore *direct*) connection, and `cleanConnections()` takes the non-recursive
  `m_connectionsMutex` that `discoveryCycle()` and `processPending()` hold across their bodies.
  Now queued. Also a re-entrancy guard on `discoveryCycle()` itself: a nested event loop
  delivering a queued invoke mid-cycle would have blocked the GUI thread on a lock it already
  held — alive, timers dead, no fault address, no dump.
* **The unconditional `qDebug() << "Discovery cycle done"`** on that path is now
  `qCDebug(Logging::DiscoveryCycle())`, and carries counters: cycles run, attempts opened,
  attempts suppressed by the cap, undialable candidates skipped. In a WIN32 service with no
  console the old line went to `OutputDebugString`, which takes a system-wide mutex.

<a id="history-what-was-not-found"></a>

### What was NOT found

**The cumulative GUI wedge did not reproduce**, in three independent harnesses:
320 republishes at ~1.9 s each with the heartbeat delivering 4 beats per round throughout and a
worst timer lateness of 22 ms over the whole run; 24 republishes at the operator's cadence with the
gap grown to 70 s and the viewer-settings write-back firing every round; and 12 shutdowns forced
mid-reconnect. Nothing accumulates: threads 26 → 16, handles 625 → 606, TCP endpoints flat,
producer flat. The one quantity that grows is private bytes, **+0.64 MB per republish**, of which
about two thirds is the epoch store legitimately filling; **~0.44 MB/republish is unexplained and
still open**.

Two things worth checking before hunting it again:

* **A hung *shutdown* is externally indistinguishable from a stalled event loop.**
  `ThreadCapsule::~ThreadCapsule()` is an unbounded `quit(); wait();` and `StreamPool::~StreamPool()`
  waits up to 10 s per connection, against workers parked in `waitForConnected(3000)` or the
  1500 ms per-chunk read loop, none of which `quit()` interrupts. If the failing log has a
  `FATAL` or `Qt.quit()` line immediately *before* the heartbeat stops, the search moves there.
* **Two agent sessions were probing this machine concurrently**, and one cleared the field with a
  blanket `Stop-Process -Name quickStimulus|SignalGenerator` before each run. That killed three
  measured runs and looks exactly like the defect: process gone, no crash record, no WER event.
  Some of the original 4/4 long-run reproductions may be this.

<a id="history-proven-in-the-built-binaries--the-same-measurement-that-found-it-re-run"></a>

### Proven in the built binaries — the same measurement that found it, re-run

Built and re-measured 2026-08-20 with `republish_gap_probe.ps1`, unchanged except for a
`-DiscoveryLog` switch (the discovery-cycle counters it used to read for free are now behind
`resonance.discovery.cycle`). Summariser: `R:\config\republish_verify.ps1`. Data:
`R:\dist\_build\republish-fix\`.

**A. The operator's own scenario** — poke `epochAmplitude`, `periodMs=300`, 1500 ms between edits,
viewer-settings write-back ON. Before is 24 rounds because the gap had reached 70 s by then; after
is **400**.

| | before | after |
|---|---|---|
| epoch gap, median | **38 215 ms** | **250 ms** |
| epoch gap, max | **70 620 ms** | **299 ms** |
| epoch gap, slope | **+2699.9 ms per republish** | **−0.0001 ms per republish** |
| eeg gap, median | 426 ms | 63 ms |
| streams rebuilt per edit | **4.29** | **0.018** (7 lines, all at start-up) |
| verdict | SURVIVED 24 | **SURVIVED 400** |

The 197–299 ms that remains is not a gap at all: it is the floor of the measurement. The probe
times "edit → next epoch block", and at `periodMs=300` an epoch block exists only every 300 ms, so
a uniform 0–300 ms wait is the best any correct implementation can do. `TcpStreamSender: Ready`
fires **seven** times in 400 rounds — all of them during the harness's opening configuration. A
content-only edit now costs nothing on the wire.

**B. A republish that genuinely is required** — poke `epochChannels` 32↔33, which changes the
`Float64` header, so the epoch stream must move. 960 rounds, 800 ms apart.

* **Exactly one stream rebuilt per edit** — 960 rebuilds over 960 republishes, 967
  `TcpStreamSender: Ready` lines (the extra seven are start-up). Was 4.02. Only the lane whose
  announcement changed moves; the generator says so itself in the log,
  `republished 1 stream(s) … Total republishes 960 over 960 parameter applies`.
* Epoch gap **flat over the whole 32 minutes**: median 1220 ms, p90 1289 ms, max 2123 ms,
  slope **+0.0039 ms per republish**. That is the framework's own reconnect, quantised by
  StreamPool's 1 Hz discovery tick — the same figure measured *before* the fix on the control
  poke, which is the point: the framework was never the problem.
* Nothing accumulates. Per republish: threads **−0.009**, handles **−0.007**, TCP endpoints
  **+0.002**, private bytes **+0.164 MB** (was +0.643) — and 960 rounds × ~3 epochs × 64 kB is
  ~187 MB against 157 MB actually gained, so the epoch store now accounts for *all* of it.
  `pump=pumping` at all 1300 samples, 3887 heartbeats, worst timer lateness **21 ms**, reached by
  round 161 and never exceeded again.
* **The EEG stream never notices.** Its gap stays at 16–99 ms throughout, because its stream was
  not rebuilt. Before, every edit dropped every socket on all five streams.

And the framework half, counted in the viewer's own log rather than argued about:

| line in the consumer's log | before (320 rounds) | after (960 rounds) |
|---|---|---|
| `refusing to connect to "discover:///…" - this service is in loopback mode` | 227 = **0.71 per republish** | **0** |
| `TcpStreamReceiver: Failed to connect … timed out` | 810 = **2.531 per republish** | 955 = **0.995 per republish** |
| `QObject::connect(QObject, StreamPool): invalid nullptr parameter` | 2 (start-up) | 2 (start-up) — unchanged, does not grow |

And, from `StreamPool`'s own counters under `resonance.discovery.cycle` (60 structural
republishes, `republish_cycles.ps1`), the work one republish costs — the number the brief asked
for and nothing in the tree had ever counted:

| per republish | n=1 | n=12 | n=30 | n=54 |
|---|---|---|---|---|
| connection attempts **opened** (a thread and a socket each) | 1 | 1 | 1 | 1 |
| attempts **suppressed** by the per-request cap | 3 | 3 | 3 | 3 |
| undialable `discover://` candidates **skipped** | 12 | 12 | 12 | 12 |
| discovery cycles | 13 | 12 | 13 | 13 |
| GUI heartbeats | 6 | 4 | 4 | 5 |

Flat, and the two middle rows are the fixes reading back: **`suppressed=3` means the pane's four
`InputStream`s for one stream now share one attempt** instead of opening four, which is only
possible because `StreamInfo::operator==` can finally answer for a typeId-0 request; **`skipped=12`
is twelve threads, sockets and connect attempts per republish that are no longer started at all.**
Before, `suppressed` would have been 0 by construction.

The undialable `discover:///` candidate is gone outright, and wasted connect attempts fall by
about 2.5× — the per-request attempt cap doing the job it was written for, now that
`StreamInfo::operator==` can answer for a typeId-0 request. The one connect timeout that remains
per republish is the known-and-deliberately-unfixed 3 s `waitForConnected` burned on the port the
producer has just abandoned (the consumer's `ServiceControl` cache is one beat behind the socket
drop); it is bounded and self-healing, and fixing it properly means changing the order in which a
producer announces and closes, which is not a defect fix.

**C. The Stage 4 view, on the deployed tree.** `epoch_freeze_probe.ps1 -Runtime R:\dist\msvc64`
with every switch on reports **SURVIVED**, and its generator log carries **six**
`TcpStreamSender: Ready` lines — all at start-up, none after. The probe pins a manual scale,
toggles head mode and labels, cuts the byte budget to 1.5 MB and back to 512, resets, raises and
restores `epochAmplitude` while running, freezes, and switches averaging method twice. Every one
of those used to rebuild all five streams; together they now rebuild none, and the epoch count
*rises* across the amplitude change (`received=20` → `received=24`) instead of stalling.

**D. The wedge.** It never reproduced before the fix (320 republishes) and it does not now:
400 content rounds and **960 structural rounds — 3× the largest pre-fix run** — with the GUI
heartbeat ticking end to end, worst timer lateness 9 ms and 21 ms respectively, `pump=pumping`
at every one of ~1800 samples, and threads/handles/TCP endpoints flat or falling.
⚠ **Say this plainly: this is a proven fix for the gap and for the churn, and an unproven one for
the wedge.** Four latent hazards whose signature matches the report were closed — a direct
`destroyed → cleanConnections` connection into a non-recursive mutex, a missing re-entrancy guard
on `discoveryCycle()`, an uncoalesced cycle per attempt state transition, and a per-request
attempt cap that was silently off — but none of them was ever *observed* to fire. If the symptom
returns, the counters above are now in the shipped build to catch it, and the first thing to check
is still whether a `FATAL`/`Qt.quit()` precedes the last heartbeat.

Harnesses and evidence: `R:\config\republish_gap_probe.{qml,ps1}`, `republish_verify.ps1`,
`republish_report.ps1`, `republish_cycles.ps1`, `republish_quit_stress.ps1`,
`republish_scope_probe.{qml,ps1}`; `R:\dist\_build\stage4\republish\`,
`R:\dist\_build\stage4\faithful\`, `R:\dist\_build\repub\`, `R:\dist\_build\republish-fix\`.

Regression tests: `test_SignalGenerator` (`RepublishDecision`, `EpochGeometryTest`,
`ScheduleOrigin`) and `test_StreamInfo` (`StreamInfoEquality`). Suite after the fix: **459 tests
across the 16 executables in `tests\`, 0 failures** (was 448), plus `test_StreamInfo` 12 → 18.

---

