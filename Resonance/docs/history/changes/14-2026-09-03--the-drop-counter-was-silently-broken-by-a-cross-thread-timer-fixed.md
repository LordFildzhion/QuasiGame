# 2026-09-03 — the drop counter was silently broken by a cross-thread timer. Fixed.

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-03--the-drop-counter-was-silently-broken-by-a-cross-thread-timer-fixed"></a>

### 2026-09-03 — the drop counter was silently broken by a cross-thread timer. Fixed.

**The status line never worked on a real acquisition, and the earlier entry here saying it did was
wrong.** The operator connected real electrodes, ran 5 kHz, and got: neoRec counting up to 33 402
lost samples, the same regular gaps visible in Resonance's own signal viewer, an HDF5 recording
full of NaN rows — and a status line reading a calm `running`.

<a id="history-the-bug"></a>

### The bug

`CommunicationLayer::reportDroppedSamples` started its throttle timer, and through `setStateInfo`
the description timer, **directly from the caller's thread**. `nvx` moves its runner to its own
`QThread` (`nvx/application.cpp:25`), and so do `actiChamp` and `KARDi2`. `QTimer::start()` from
another thread is a **no-op** that prints

```
QObject::startTimer: Timers cannot be started from another thread
```

and does nothing — to stderr, in a windowed service with no console, so on the rig it went
nowhere. Measured on the NVX-52 at 5 kHz: **415 of those warnings, one per block.** The count was
accumulating perfectly and never being broadcast. `stateInfo` was also written from one thread
while `sendDescription()` read it in another — a plain data race.

**Fixed in the framework, once, for every driver**: the figure is stored lock-free
(`QAtomicInteger`) and the work hops to the owning thread via `QMetaObject::invokeMethod(...,
Qt::QueuedConnection)`, with an atomic wake flag bounding the queued backlog to one outstanding
flush. `setStateInfo` carries the same guard.

**Verified on the device:** 415 cross-thread warnings → **0**, and the count now climbs live —
522, 1615, 2671, 3730 … **9 120 over 20 s** at 5 kHz / block 500, about 450 lost samples per
second, the same order as neoRec's number. The Configurator reads
`running, 3228 samples dropped` in red (`docs\qa\param-column\drop-02-running.png`).

⚠ **Anything else that touches a QTimer or `stateInfo` from a driver callback has this bug.** The
services thread their drivers; the framework objects do not move with them.

<a id="history--and-a-method-error-worth-not-repeating"></a>

### ⚠ And a method error worth not repeating

The previous entry concluded "the NVX is clean" from a delivered-rate measurement — 4999.21 Hz
against 5000 declared over 60 s. **That inference is invalid whenever the driver pads.**
`processAcquisitionBuffer` injects a NaN row for every sample a counter gap reports, so a lossy run
delivers the expected count *or more*: with electrodes attached the same settings measure
**5011.60 Hz**, above declared. A negative shortfall is the padding signature, not rounding. The
earlier "clean" runs had no electrodes attached. `scripts\nvx-rate-audit.qml` now prints
`AUDIT_PADDING_DETECTED` so this cannot be misread again.

The device really does drop at 5 kHz under real load, on both applications — that part is the
device or the USB link, not Resonance. What was ours was staying quiet about it.
[`arch_qt6-work-list.md` §3b](../migrations/qt6-work-list.md) carries the remaining work: the padding branch
still does not log, and `nvx::logic::missingSamples` still has no monotonicity guard.

<a id="history-checked-and-found-not-broken"></a>

### Checked and found NOT broken

A saved parameter file lists `channels_unipolar` *before* `samplingRate`, and changing the rate
rebuilds the channel list (52 entries at ≤5 kHz, 24 at 10 kHz, 8 at 50 kHz) — which looked like
guaranteed silent montage loss. Loading `params\nvx52_test34ch.json` into a service parked at
50 kHz returns `1 kHz, 34/52 ticked` with no refusals: `applyParameters` sequences the set rather
than walking it in file order. `scripts\nvx-config-order-probe.qml` is the standing proof.

---

