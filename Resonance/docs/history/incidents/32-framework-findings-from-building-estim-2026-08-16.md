# 17. Framework findings from building `eStim`, 2026-08-16

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-17-framework-findings-from-building-estim-2026-08-16"></a>

### 17. Framework findings from building `eStim`, 2026-08-16

**Mixed. §17a TRANSFERS UNCHANGED — still open in both trees:**
`R:\src\Core\Resonance\Parameters\double.cpp:83-99` still emits only `minimumChanged` /
`maximumChanged`, and `select.cpp:126-138` only `valueChanged` + `jsonChanged`, so neither
re-broadcasts. **§17b and §17c TRANSFERS UNCHANGED — the fixes crossed**, including the string form
of `Parameters::Stream` and the recorder's fatal treatment of a refusal.

Context: [estim-service.md](../components/estim.md). Neither is in that module; both bite anyone else.

<a id="history-17a-double-and-select-do-not-re-broadcast-when-the-service-changes-them--open"></a>

### 17a. `Double` and `Select` do not re-broadcast when the service changes them — open

`CommunicationLayer` listens on `triggerUpdate` and nothing else.

| | emits `triggerUpdate` |
|---|---|
| `Integer::setMinimum` / `setMaximum` | ✅ |
| **`Double::setMinimum` / `setMaximum`** | ❌ — only the member is written, no signal at all |
| `Integer/Double/String/Boolean::setValue` | ✅ (since 2026-08-12) |
| **`Select::setIndex`** | ❌ — emits `valueChanged` and `jsonChanged`, but not `triggerUpdate` |

So a range a service narrows, or an option it selects on the operator's behalf, is **invisible to
every client** until something unrelated happens to re-broadcast the description. That matters
more than it sounds: `Double::setJson` *rejects* an out-of-range value rather than clamping it, so
a client working from a stale range is refused a value the service would accept — and a client
that never learns a cap was lifted goes on refusing to offer it.

`eStim` works around it by emitting the signal from outside:

```cpp
void rebroadcast(Parameters::Parameter* p) { if (p) emit p->triggerUpdate(); }
```

which is legal (Qt's `signals:` is `public`) and the same shape as `recorderService` emitting
`performTransition` on the communication layer. The fix is three lines in `double.cpp` and one in
`select.cpp`, but it changes broadcast behaviour for every service, so it was not done in passing.

<a id="history-17b-recorderservice---serviceconfig-records-nothing-from-a-configured-stream---fixed-2026-08-16"></a>

### 17b. `recorderService --serviceConfig` records nothing from a configured stream — ✅ fixed 2026-08-16

Two independent things, one of them a real bug and one a misreading of an empty dataset. Both
are settled; the second is the more useful lesson.

| `stream1` in the config | Was | Now |
|---|---|---|
| `desiredStream` with a `connections` URL and **no `name`** | slot reads back correctly over the bus, but **no dataset at all** — only the recorder's own `annotations` | records normally |
| the same plus `"name": "events"` | dataset created, stays empty | unchanged — see "the second row was never a bug" |

<a id="history-the-bug-two-constructors-of-streaminfo-disagreed-about-the-name"></a>

#### The bug: two constructors of `StreamInfo` disagreed about the name

`StreamInfo(const QUrl&)` parses a `discover://` URL and takes the stream name (and uid) out of
its query. **`StreamInfo::fromJson()` did not.** So one connector filled two ways produced two
different objects: a slot filled by *dragging* a stream is named, and the identical slot written
into a config file is not.

Nothing complained, because nothing downstream needs a name — until `RecorderService::startRecording()`
calls `addStream(desired, desired.name(), …)` and the empty name reaches HDF5:

```
H5Gcreate2(): unable to synchronously create group
  H5G__create_api_common(): name parameter cannot be an empty string
```

`createRecorderObject()` catches that, logs it at `qCDebug` (off by default), and returns null.
`HDFRecorder::addStream()` then returned `void`, so `Recorder` marked the stream bound and went
on reporting a healthy recording into a file that would never contain it. **Three separate
places each turned a hard failure into silence.**

Fixed at the root — `fromJson()` now derives name and uid from a `discover://` connection when
the JSON omits them, so the two constructors agree — plus the belt and braces that would have
made it self-diagnosing:

* `HDFRecorder::addStream()` returns `bool`; every failure in `createRecorderObject()` is logged
  at **`qWarning`**, not `qCDebug`, and an empty name is rejected by name rather than by HDF5.
* `Recorder::Tracked::unrecordable` — a stream the file refused now reads **`not recorded`** in
  `streamStatus`, turns the tray icon red and makes `allStreamsPresent()` false, instead of
  showing green.
* `Recorder::addStream()` names an otherwise unnameable stream `streamN` rather than passing an
  empty string on, and now **remembers the uniquified name** it handed out (it did not, so a
  third stream sharing a base name could be handed a name already in the file, and lose its
  group to the same swallowed exception). `recordLocalStream()` claims its name in the same
  namespace, so a slot called `annotations` is renamed rather than colliding with the recorder's
  own group.

⚠ **One knock-on, fixed in the same pass.** `CommunicationLayer::applyParameters()` re-checked
each parameter by comparing `param->json()` against the caller's text, to catch one parameter
reverting another. Once `Stream` normalises what it is given, that comparison fails for any
hand-written config — the value applies cleanly and is then reported *"Rejected parameter
stream1 - value does not fit"*. It now compares against what the parameter read back when it
accepted the value, which detects a genuine revert without demanding a byte-identical round trip.
Configurator-saved sets round-tripped exactly and never showed this; abbreviated hand-written
ones would have.

<a id="history-the-second-row-was-never-a-bug--the-producer-was-silent"></a>

#### The second row was never a bug — the producer was silent

Measured 2026-08-16 with a `MessageReceiver` subscribed to **the same stream over the same
window** as the recording:

| producer | window | receiver saw | file |
|---|---|---|---|
| `signalGenerator` @ 250 Hz | 8 s | — | 105 blocks, 2100 samples |
| `recorderService` `annotations`, 4 marks sent | 8 s | 4 | 4 records |
| `eStim` `events`, 4 parameter changes | 8 s | 4 | 4 records |
| **`eStim` `events`, idle** | 8 s | **0** | **1 row, `created=0`, empty message** |

An idle `eStim` publishes nothing: `publishEvent()` fires on a parameter change, a state change
or a command, and on nothing else. The last row is exactly what was reported as the unexplained
failure — and the independent receiver got nothing either, which is the control that settles it.

**What made it look like a fault** is [§14k](24-defects-found-and-fixed-2026-08-15.md#history-14k-every-hdf5-dataset-ends-in-one-all-zero-row--open):
every dataset is *created* at one row and the first block is written into row 0, so a stream that
delivers nothing leaves that uninitialised row visible. `shape == (1,)` with `created == 0` means
**zero records**, not one. Read `blocks`/`messages` counts, never `shape[0]`.

**When a recorded stream comes out empty, check the producer before the recorder** — subscribe a
`MessageReceiver` over the same window. Per-stream `bytes` and `rate` in the recorder's own
status say the same thing at a glance.

<a id="history-autostart-in-a-config-file-never-fired---fixed"></a>

#### `autoStart` in a config file never fired — ✅ fixed

`RecorderService`'s constructor read `m_autoStart->value()` and armed its 2 s timer *before*
`ResonanceApp` applied `--serviceConfig`: the config is applied from `afterExec()`, which is
queued onto the first turn of the event loop, i.e. after every service constructor has run. The
only thing that read the value ran before the only thing that could set it.

The timer is now armed unconditionally and the value read **when it fires**
(`considerAutoStart()`), which is after any configuration has landed. It is deliberately a
one-shot look at launch: turning the parameter on later configures the next launch, it does not
begin a recording under the operator. Verified end to end — a recorder launched with
`autoStart: true` and *no* `start` transition from anyone produced a 59-block, 1180-sample file.

**This shape is worth remembering: nothing a service reads in its constructor can be configured
by `--serviceConfig`.** Read it when it is used, or connect to `valueChanged`.

✅ `params\ns65-recorder.json` — shipped in **both** distributions, `R:\dist\params\` and
`R:\dist_Qt5\msvc64\params\` — uses the nameless shape *and* sets `autoStart: true`, so it needed
both fixes and had never worked. It needs no edit now — but it has still never been exercised
against an NS-65 (see STATUS ([change history](../changes/README.md))), under either generation.

<a id="history-17c--a-refused-stream-slot-went-on-recording-the-old-source---fixed-2026-08-22"></a>

### 17c. ⭐ A REFUSED stream slot went on recording the OLD source — ✅ fixed 2026-08-22

The same shape as 17b and the worse half of it: 17b recorded **nothing**, this recorded **the
wrong thing**, and an empty dataset is at least visible.

Found at the TMS lab, 2026-08-22. A harness re-pointed `stream1` at a 25 kHz trigger lane with

```qml
rec.sendParameter("stream1", "discover:///?stream=eeg&name=NVX136")
```

— the **bare address string**, which is exactly what `recorderService`'s own slot tooltip tells an
operator to type. `Parameters::Stream::setJson()` accepted only the full
`{"desiredStream":{…},"reconnect":bool}` object, so it returned `false`:

```
stream1 NOT APPLIED — the parameter refused the value "discover:///?stream=eeg&name=NVX136"
        (wrong type, out of range, unknown option or wrong length)
```

**And a refused write leaves the slot holding what it held before.** The slot still carried
`NeuroMS/status` from an earlier configuration, and the recorder recorded that: a 94 kB file
(`lab-latency-001.h5`) where 90 s of amplifier data was expected. Nothing crashed. No slot was
empty. No rate was zero. Every indicator the service has said the run was healthy, and the
mistake was only found by opening the file.

> **Silently recording the wrong thing is the worst class of defect in this project.** A missing
> recording is a lost session; a wrong one is a wrong result that may never be caught.

Fixed in two halves that cover each other, because neither is sufficient alone:

1. **`Parameters::Stream` accepts the string form** (`Core/Resonance/Parameters/stream.cpp`). An
   empty string clears the slot, as the ✕ in the recorder window does. A string with **no
   scheme** (`"NVX136/eeg"`) is still refused — it addresses nothing, and quietly turning it into
   a connection that can never resolve would be the same silent-wrong-thing in a new costume.
2. **The refusal became fatal at the recorder.** `CommunicationLayer::parametersApplied` is a new
   signal carrying every apply's report — needed because the report that already rides in the
   service description only ever describes the **last** apply, so a refusal is overwritten by the
   next single-parameter write before anything can act on it. `RecorderService` keeps refusals
   naming `fileName`, `streamsCount` or a `stream*` slot until that same parameter applies
   cleanly, and `startRecording()` declines and returns to `idle` while any is outstanding —
   `qCritical()`, an `event: "recording_refused"` on the status stream, and a red banner over the
   Record button.

   ⚠ **No override parameter, deliberately.** An override is exactly how a silently-wrong
   recording comes back. The recovery is to send a value that applies, or to set it by hand in
   the window (a local write does not pass through the apply path, so slots clear their own
   refusal on `jsonChanged`).

The status payload also gained `canRecord`, `parameterRefusals`, and a **`slots`** array naming
what each slot is *pointed at* — the existing `streams` array lists only sources the recorder has
already taken up, so a slot pointed at the wrong service looked identical to a correct one that
had not resolved yet.

⚠ **The general lesson, for every parameter type:** a `setJson` that returns `false` leaves the
old value in place, and no caller is told unless it reads `parameterRefusals` or the new signal.
Anything that acts on a parameter it set — opens a file, arms a device, starts a run — must
verify rather than assume. And a read-back is not free: `svc.parameters` read within ~1 s of
`sendParameter` returns the **stale** value, which is indistinguishable from a silent refusal.
Wait ~3 s. (`R:\config\lab\PowerGate.qml` is the same discipline applied to stimulator
intensity, where getting it wrong is a safety matter rather than a data one.)

Tests: `Core/Resonance/tests/StreamParameter_test.cpp` (`test_StreamParameter`, 11 cases),
including `ARefusedWriteLeavesThePreviousSourceInPlace`, which pins the behaviour the recorder's
refusal exists to compensate for.

---

