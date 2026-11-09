# 16. Framework traps found building `playbackService`, 2026-08-15

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-16-framework-traps-found-building-playbackservice-2026-08-15"></a>

### 16. Framework traps found building `playbackService`, 2026-08-15

**16a, 16b and 16c TRANSFER UNCHANGED** — the same framework, and 16b's fix
(`Core\Resonance\parameterapply.cpp`) crossed with it. **16d is UNKNOWN UNDER QT 6**; see there.

Full context in [playback-service.md §8](../components/playback.md). All three bite outside that
module; none is fixed, because each is a framework change with a blast radius wider than the
work that surfaced it.

<a id="history-16a-outputstreamready-fires-inside-the-constructor-on-the-main-thread--open"></a>

### 16a. `OutputStream::ready` fires inside the constructor on the main thread — open

`OutputStream`'s constructor posts to `StreamPool` with `Qt::AutoConnection`, and `StreamPool`
lives on the main thread. Build a stream *on* the main thread and the whole creation runs
synchronously inside the constructor: `transitionToReady()` has already emitted `ready()` before
the statement after `new` executes. A `connect` made afterwards attaches to a signal that has
been and gone.

The amplifier drivers do not hit it because they build their streams on a worker thread, where
the same `AutoConnection` is a queued one and the signal genuinely is deferred — which is
precisely why `connect(stream, &AbstractStream::ready, …)` after construction *looks* like a
working pattern. It cost a readiness handshake that waited forever.

**Check `state()` as well as connecting**, and re-announce with an explicit `sendDescription()`
rather than relying on a `ready` that may never arrive.

<a id="history-16b-applyparameters-screens-names-before-it-applies-anything--fixed-2026-08-22"></a>

### 16b. `applyParameters` screens names before it applies anything — FIXED 2026-08-22

`CommunicationLayer::applyParameters` decides which parameter names the service knows *once*, up
front, and rejects the rest permanently:

```cpp
for (const auto& entry : list) {
    if (d->parameters.contains(obj["name"].toString())) pending.append(obj);
    else { qDebug() << "Rejected parameter" << … ; everythingFits = false; }
}
```

A parameter that only comes into existence as a side effect of applying another one in the same
set is therefore never seen. That is exactly the `streamsCount` → `stream1…N` shape, so:

> **A saved `recorderService` configuration with more than one stream cannot be loaded back.**
> `--serviceConfig` (and the Configurator's Load) apply `fileName` and `streamsCount`, `stream2`
> is created by the second of those — and was already rejected. `SPEED`'s `inputsCount` →
> `input1…N` has the same shape.

The retry loop directly below exists for values that become *valid* later ("a channel list is
only valid once the device that defines it has been selected"), not for parameters that become
*present* later. Re-screening the rejected names at the top of each round would fix it, and the
loop already guarantees termination — but it changes behaviour for every service, so it is
recorded here rather than done in passing.

**Fixed 2026-08-22.** The screen now lives inside the retry loop, in
`Core/Resonance/parameterapply.cpp` (`applyParameterList`), which `CommunicationLayer` calls
from `applyParametersReported()`. A name the service does not have *yet* is retried; it is only
reported as unknown once a whole round has gone by without it appearing. Termination is still
bounded twice over (`progressed`, and the round counter against the entry count).

Measured on the operator's own reproducer, `R:\dist\msvc64\recorderService_testConfig.bat`:
three stream slots asked for, three filled. Before the fix, `stream2` and `stream3` were empty.

The second half of the same requirement — *“parameters that are silently not loaded can't
happen”* — is `ParameterApplyReport`: every entry that did not apply is named, with a reason
(`no-such-parameter` / `value-rejected` / `malformed-entry` / `reverted`) and the value that was
asked for. On the `--serviceConfig` path `ResonanceApp::loadConfig` attaches a debug console for
it, so a half-applied configuration is visible on a WIN32 service with no console. Over the
EventBus the same report is `qCritical()`-ed and also rides in the service description as
`parameterRefusals` (additive JSON; no thir layout changed). **No client reads
`parameterRefusals` yet** — that belongs to the parameter-list UI work.

Two total-silence cases in the same path were closed with it: a config file whose root is not a
JSON array used to print one line and then apply an empty array (no `return`), and an unreadable
or missing file used to be reported as a JSON parse error at 1:1. Both now name the real problem
and apply nothing.

Note that the ctypes bridge is still *not* an alternative — see [§15e](34-neuron-spectrum-findings-2026-08-15.md#history-15e-resonanceforeigndriversendparameterstoservice-applies-nothing--open).

<a id="history-16c-qvectorremovefirst-deep-copies-the-tail--beware-in-any-hot-path"></a>

### 16c. `QVector::removeFirst()` deep-copies the tail — beware in any hot path

Qt treats a type with no explicit `Q_DECLARE_TYPEINFO` as *static*, and `QVector::remove` shuffles
a static type's tail down by **copy assignment**. For a queue of elements each holding a
`std::vector`, popping the front deep-copies everything behind it.

Measured in the playback prefetch queue at 67 channels and 25 kHz: about 30 MB copied per pop, on
the thread that had to emit on time — 8.5 ms of added lateness per block, against 0.45 ms for the
identical code on a narrow stream. `std::deque::pop_front()` moves nothing.

The trap is that it is invisible until the elements are large: the same code measured clean on
every small stream it was developed against.

<a id="history-16d-qtimer-cannot-pace-anything-finer-than-156-ms-on-windows"></a>

### 16d. `QTimer` cannot pace anything finer than 15.6 ms on Windows

**UNKNOWN UNDER QT 6 as a mechanism; the mitigation carried over regardless.** The measurement below
is Qt 5's Windows dispatcher and nobody has repeated it against Qt 6.11's. What is certain is that
the fix crossed: `R:\src\playbackService\player.cpp:178-194` still resolves
`CreateWaitableTimerExW` at run time for `CREATE_WAITABLE_TIMER_HIGH_RESOLUTION`, so playback does
not depend on the answer. **`SignalGenerator` does not depend on it either**: it has its own
`pacer.cpp`, which resolves `CreateWaitableTimerExW` the same way and arms it with
`SetWaitableTimer` (`R:\src\SignalGenerator\pacer.cpp:41-47`, `:126`). Both trees carry it —
`pacer.hpp:19` records that the generator "ran on a `QTimer` until now". Nothing in the current
build paces output on a `QTimer`.

Not a defect, but it is not what `Qt::PreciseTimer` reads like it promises. Qt 5's Windows
dispatcher arms timers with `SetTimer`, so a `QTimer` fires on a `WM_TIMER` and is quantized to
the user-mode tick regardless of the system timer resolution — measured at 6.7 ms mean / 15.7 ms
max lateness, and unchanged by `timeBeginPeriod(1)`. A `QWaitCondition` deadline is no better.
A high-resolution waitable timer gives 0.48 ms. Table and reasoning in
[playback-service.md §6](../components/playback.md).

Relevant to anything that paces output — and the reason `SignalGenerator` was moved off `QTimer`
onto `pacer.cpp`. The jitter was invisible in its recordings only because it timestamps at send
time (`lane.hpp:13`), which is exactly the kind of accident that hides a pacing defect until
something downstream stamps at receive time instead.

---

