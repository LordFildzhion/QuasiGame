# `recorderService` — the standalone recorder — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/recorder.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-recorderservice--the-standalone-recorder"></a>


**Added 2026-08-12.** A service whose only job is to write selected streams to an HDF5 file,
plus the framework changes it forced. For the operator-facing version see
**[Resonance-Recorder-Guide.docx](../../operators/manuals/recorder.docx)**.

> **Ported to Qt 6, and shipping as the default.** `R:\dist\recorderService.bat` →
> `R:\dist\bin\recorderService.exe`, built from `R:\src` against Qt 6.11.2 / MSVC v143 14.44 /
> C++20. The Qt 5.15.2 build survives as the comparator in `R:\dist_Qt5\msvc64`. Registration,
> parameters, transitions, the four faces and the published streams all behave as documented here;
> the faces were restyled for Controls 2 (§3), not redesigned.
> ⚠ **The file format did not.** A Qt 6 recording written since 2026-09-02 no longer carries
> the trailing all-zero sample; one written before it still does — read **§2a** before
> running any analysis that drops the last row.
> Background: [qt5-to-qt6-transition.md](../migrations/qt5-to-qt6-transition.md).

---


<a id="history-2a--the-last-sample-of-every-recording--a-dud-in-a-qt-5-file-gone-in-a-qt-6-one"></a>

## 2a. ⭐ The last sample of every recording — a dud in a Qt 5 file, gone in a Qt 6 one

⚠ **This changed on 2026-09-02, and which of the two halves below applies is decided by the
binary that wrote the file, not by the analysis reading it.** Both generations of recording are in
daily use and neither is going away, so any script that opens a `.h5` from this project has to
handle both.

<a id="history-qt-5-files--data-carries-one-row-more-than-the-block-index-accounts-for"></a>

### Qt 5 files — `data` carries one row more than the block index accounts for

Every `.h5` written by a Qt 5 build carries **one more sample in `<stream>/data` than the sum of
`<stream>/blocks.samples`**, and that extra sample is the **last** one. It reads all zeros.
`R:\src_Qt5\Core\Resonance\internal\HDFRecorder.cpp` creates every numeric dataset at extent 1
and extends it to `offset + samples + 1` on each append, so a tail row is always allocated and
never written.

Confirmed on the 2026-08-26 rig recordings, both files:

| file | `data` rows | Σ `blocks.samples` | difference | zero sample at |
|---|---|---|---|---|
| `record-0002.h5` | 1 902 361 | 1 902 360 | 1 | index 1 902 360 (the last) |
| `record-testNVXTMS-0001.h5` | 712 441 | 712 440 | 1 | index 712 440 (the last) |

The same initial extent of 1 applies to `blocks` and to `messages`, but only bites when a stream
recorded **nothing**: those datasets are appended *into* from index 0, so a stream with zero records
is indistinguishable by shape from one holding a single all-zero record.

**What it costs a reader who does not know.** The trigger word is a bitfield, and on the NVX
drivers it is **active-low** on the photodiode line — so an all-zero word means *every bit
asserted*. A naive edge detector run over the raw trigger channel therefore fires a spurious event
on every bit at the very end of every file. Anything scanning triggers must ignore the last sample:

```python
n = sum(blocks['samples'])      # not len(data)
trig = data[:n, -1]             # drop the dud
```

<a id="history-qt-6-files--data-is-exactly-the-sum-of-the-block-sample-counts"></a>

### Qt 6 files — `data` is exactly the sum of the block sample counts

`R:\src\Core\Resonance\internal\HDFRecorder.cpp` creates every numeric dataset at extent **0**
and extends to `offset + samples`; the block index and the message datasets start at 0 as well. A
recording written by the Qt 6 core therefore holds **exactly** Σ `blocks.samples` rows, with no
trailing zero row, and a stream that recorded nothing is an empty dataset rather than one blank
record.

Measured on this machine, either side of the build that landed it — `R:\dist\bin\Resonance.dll`
of 2026-09-02 01:01, byte-identical to the `_build\runtime\bin\Resonance.dll` the KARDi2
harness ran against. ⚠ The `record-0002.h5` below is **not** the rig file of the same name
above; it is a far shorter Qt 6 test recording that happens to carry the stock name.

| file | written | `data` rows | Σ `blocks.samples` | difference |
|---|---|---|---|---|
| `R:\dist\data\record-0002.h5` | 2026-08-28 15:16 | 1 891 | 1 890 | 1 |
| `R:\src\_test-output\kardi2-hardware\kardi2_sync1_hil_0001.h5` | 2026-09-02 00:57 | 6 270 | 6 269 | 1 |
| `...\kardi2_sync1_hil_0002.h5` | 2026-09-02 01:01 | 6 290 | 6 290 | **0** |
| `...\kardi2_4khz_soak_0002.h5` | 2026-09-02 01:08 | 239 952 | 239 952 | **0** |

The first two are Qt 6 recordings made *before* the change and still carry the dud: the last row of
`kardi2_sync1_hil_0001.h5` is all zeros, the last row of `_0002.h5` is not. Those two hardware files
are four minutes apart, from the same rig and the same harness — the only thing that differs is
the `Resonance.dll` in between.

⚠ **This is not back-ported.** `R:\src_Qt5` still writes `offset + samples + 1`, so every new
Qt 5 recording still has the dud — and a session with an NVX-136 or a Neuro-MS still runs from
`R:\dist_Qt5\msvc64` ([qt6-work-list.md](../migrations/qt6-work-list.md)). Both readings stay live.

<a id="history--any-analysis-that-drops-the-last-row-must-be-re-checked"></a>

### ⚠ Any analysis that drops the last row must be re-checked

This section used to say the dud was accepted and must not be "fixed", because changing it would
shift every analysis script by one sample. **It was changed at the port, and that shift is real.**
The operator's scripts were written against Qt 5 files and drop the final sample unconditionally;
run against a Qt 6 recording they discard a *real* sample — the last one, which on a trigger
lane is exactly where a closing pulse would sit.

The rule that holds in both generations is to take the count from the index and never from the
dataset shape:

```python
n = int(blocks['samples'].sum())   # authoritative in both generations
data = data[:n]                    # a no-op on a Qt 6 file, drops the dud on a Qt 5 one
```

`playbackService` already does exactly this and reads both generations unchanged
([playback-service.md §5](playback.md)): row counts come from the block index, trailing
all-zero index records are trimmed, and it fails only when the index claims *more* samples than
`data` holds — so a file with no spare row is accepted without comment.

⚠ Polarity is not the same on every line and must be read, not assumed. In the same 2026-08-26
recording the TMS Trig-Out idles **low** (`0xFFFE`, active-high) while the photodiode idles
**high** (`0xFFFF`, active-low). Take the modal value as idle and derive the sense from it;
assuming one polarity for both yields negative pulse widths, which is how this was noticed.


<a id="history-3-the-four-faces-and-why-they-do-not-drift"></a>

## 3. The four faces, and why they do not drift

There is exactly one copy of every setting: the `Parameters::*` object. The window binds to
those objects as QML context properties (`service.fileNameParam.value`, …), and the Configurator
drives the same objects over EventBus. Neither side keeps a copy, so there is nothing to
reconcile.

Making that work needed a framework change — see §6.1.

| Face | Toggle | Notes |
|---|---|---|
| Window | `showUi` (default **on**) | QML engine built lazily on first show. |
| Status strip | `showStrip` (default **on**) | Frameless `Qt.Tool` + `WindowStaysOnTopHint`. |
| Tray icon | always | Double-click = note, middle-click = raise window, right-click = menu. |
| Configurator | — | Renders the parameters; nothing recorder-specific in `quickStimulus`. |

⚠ The *principle* survived the Qt 6 port; the pixels did not. All four faces were reworked for
Controls 2; standalone windows now share a fixed light Fusion palette so their appearance no longer
flips with the Windows theme; checkboxes are a 13 px box with a solid 7 px inner square; the window
carries a 680 px minimum width. The Configurator's embedded `recorder.qml` was rewritten outright
— it still imported Qt Quick Controls 1.4, which Qt 6 does not provide, and failed before
creating a window. Any screenshot or pixel-level claim about this service that predates 2026-08-28
is of the Qt 5 build (`R:\src\docs\PORTING_LOG.md`, "2026-08-28 recorder repair").


<a id="history-4-parameters-and-transitions"></a>

## 4. Parameters and transitions

All in group `default` — the Configurator renders one tab per group, and eight parameters
across three tabs meant hunting for them.

| Name | Type | Notes |
|---|---|---|
| `annotate` | `Action` | index 5, so it sorts to the top. Prompts, then sends text + click RTC. |
| `fileName` | `String` | `$$$$` → run number, expanded by `HDFRecorder`. |
| `streamsCount` | `Integer` | Grows/shrinks the `stream1…N` slots. **Minimum is raised to the slot count while recording** (see §5). |
| `stream1 … streamN` | `Stream` | Source + keep/once. |
| `flushSeconds` | `Integer` | `Recorder::setFlushInterval`. |
| `autoStart` | `Boolean` | Fires `start` 2 s after launch, so discovery has found the sources first. Read *when the timer fires*, not in the constructor — a `--serviceConfig` is applied after every constructor has run, so reading it earlier meant a configured `autoStart` never fired ([§17b](../incidents/32-framework-findings-from-building-estim-2026-08-16.md#history-17b-recorderservice---serviceconfig-records-nothing-from-a-configured-stream---fixed-2026-08-16)). One-shot at launch: turning it on later configures the next launch. |
| `showUi`, `showStrip` | `Boolean` | Window visibility. |

A configured slot may address its source by `discover://` URL alone —
`{"desiredStream": {"connections": ["discover:///?stream=eeg&name=SignalGenerator"]}, "reconnect": true}`
— because `StreamInfo::fromJson()` takes the stream name out of the URL, exactly as the URL
constructor does. It did not until 2026-08-16, and a nameless slot then reached HDF5 with an
empty dataset name and recorded nothing at all. A stream the file refuses now reads
**`not recorded`** in `streamStatus` rather than showing green.

<a id="history--a-bare-address-string-is-a-valid-slot-value-and-a-refused-one-blocks-start"></a>

### ⭐ A bare address string is a valid slot value, and a refused one blocks `start`

`sendParameter("stream1", "discover:///?stream=eeg&name=NVX136")` — the exact form this
service's own slot tooltip tells an operator to type — **used to be refused**, and the refusal
was quiet in the way that matters: **a refused write leaves the slot holding its previous value.**

At the TMS lab on 2026-08-22 a harness re-pointed `stream1` at a 25 kHz trigger lane with a bare
string, the write bounced with
`stream1 NOT APPLIED — the parameter refused the value … (wrong type…)`, the slot still held
`NeuroMS/status` from an earlier configuration, and the recorder cheerfully recorded that: a 94 kB
file where 90 s of amplifier data was expected. Nothing crashed, no slot was empty, no rate was
zero. **Silently recording the wrong thing is the worst failure this service has**, because every
indicator it has says the run is healthy.

Both halves are fixed, and they cover each other:

1. **`Parameters::Stream` accepts the string form** (`Parameters/stream.cpp`). An empty string
   clears the slot; a string with no scheme is still refused, because it addresses nothing.
2. **The recorder refuses to start while any of its parameters stands refused.**
   `CommunicationLayer::parametersApplied` reports every apply; `RecorderService` keeps the
   refusals that name `fileName`, `streamsCount` or a `stream*` slot until that same parameter
   applies cleanly, and `startRecording()` declines and returns to `idle` while any is
   outstanding. The refusal is `qCritical()`d, published on `status` as
   `event: "recording_refused"` / `"parameter_refused"`, and shown as a red banner over the
   Record button — a Record button that silently does nothing would be a worse fault than the
   one being fixed.

   ⚠ **There is deliberately no override parameter.** The recovery is to send a value that
   applies. An override is exactly how a silently-wrong recording comes back.

The `status` payload gained two fields for this: `canRecord` (false while blocked),
`parameterRefusals` (name + sentence), and a `slots` array naming **what each slot is actually
pointed at** — `{slot, stream, address, empty, resolved}` — because the existing `streams` array
lists only sources the recorder has already taken up, so a slot pointed at the wrong service
looked identical to a correct one that had not resolved yet.

The distribution's `env.bat` sets `RESONANCE_RECORD_PATH` to `<distribution>\data`, beside
`bin\` and `qt\`. Automatic names and relative file names therefore stay in the dedicated data
folder when the service is launched through `recorderService.bat`. An absolute `fileName` still
selects the exact operator-provided location. Directly starting `bin\recorderService.exe` is not
the supported recording workflow because the fallback is its current working directory.

Transitions: `start`, `stop`. Plus the framework's `!terminate`.


<a id="history-6-framework-changes-this-drove"></a>

## 6. Framework changes this drove

All five came across into the Qt 6 core and are live in `R:\dist`: `Parameters/action.{hpp,cpp}`,
`StreamInfo::isEmpty()`, `HdfRecorders::rowsPerChunk()` and the `activeStream` `Q_PROPERTY` are all
present in `R:\src\Core\Resonance`. Only eight files differ between it and
`R:\src_Qt5\Core\Resonance` at all — in `Parameters/stream.hpp` the difference is nothing but
the fully-qualified `Resonance::StreamInfo` metatype name Qt 6 requires, and the one difference with
a behavioural consequence is `internal/HDFRecorder.cpp` (§2a).

<a id="history-61-setvalue-is-now-notifying"></a>

### 6.1 `setValue` is now notifying

`Integer`, `Double`, `String` and `MultiLine` had silent setters: they assigned `m_value` and
emitted nothing. Fine for construction-time initialisation, fatal for a service that has its own
GUI — a value set locally never reached any client, so the window and the Configurator disagreed
about the same parameter.

All of them now emit `valueChanged` + `jsonChanged` + `triggerUpdate` behind an equality guard;
`Boolean` gained the missing `triggerUpdate`. `Parameters::Stream` emits `triggerUpdate` when a
slot or its `reconnect` flag is set locally, and `Integer::setMinimum/setMaximum` emit
`jsonAttributesChanged` + `triggerUpdate` (bounds are part of the description, and `setJson`
enforces them — a client that has not been told the range moved keeps offering refused values).

**Blast radius:** `SPEED` sets `errorMessages`, `loadCode` and `code` from its own code. Those
now re-broadcast the description on change, which is correct but is new traffic on a previously
silent path. `descriptionDelay` coalesces at 30 ms, so a burst costs one message.

<a id="history-62-new-parameter-type-action"></a>

### 6.2 New parameter type: `Action`

`Core/Resonance/Parameters/action.{hpp,cpp}` — a valueless parameter a client renders as a
button, with optional `prompt` and `buttonText` attributes.

* `json()` is **always null**, so a description re-broadcast can never re-fire it.
* An invocation is recognised only by an explicit `{"invoke": true, …}` marker, so Save/Load
  cannot replay one. (Verified: sending the action `null` does not annotate.)
* The payload carries `rtc` as a **decimal string** — a nanosecond count does not survive a
  JavaScript number.

QML: `quickStimulus/import/Resonance/Resonance__Parameters__Action.qml`. `ParametersView`
resolves the delegate by class name, so nothing else needed changing.

`QML_ResonanceApp::rtcNow()` was added so the client can stamp the moment of the *click*.

<a id="history-63-streaminfoisempty"></a>

### 6.3 `StreamInfo::isEmpty()`

`isNull()` is pointer identity against one shared instance, so a `StreamInfo` built from an
empty JSON object was **not null** — it had an empty name, a null uid and no connections, but
every `isNull()` check downstream treated it as a real request and tried to connect it. Clearing
a connector therefore left a phantom stream attached.

Two fixes:

* `StreamInfo::fromJson()` returns the shared null when the object carries nothing addressable,
  so `toJson()`/`fromJson()` round-trips exactly.
* `isEmpty()` — "no name, no uid, no connection" — for the decision points:
  `Parameters::Stream::createNewStream/stream`, `RecorderService`, `SPEED::application`.

**Use `isEmpty()`, not `isNull()`, when deciding whether to attempt a connection.**

<a id="history-64-hdf5-chunking-and-compression-2026-08-15"></a>

### 6.4 HDF5 chunking and compression (2026-08-15)

**Restores a fix that existed only as a binary.** On 2025-10-06 Yuri sent a compiled
`Resonance.dll` — now `R:\dist_legacy\dist2025\bin\Resonance.dll`, dated 2025-10-07 — with the
message *"отключил дефлейт и поправил размер блока в хдф5"*. It was never committed; the last
commit on `feature/conan2` is 2025-07-05. Every build made from `R:\src` — the tree now called
`R:\src_Qt5` — since has silently had the old behaviour back.

What the old code did, at every dataset:

```cpp
hsize_t chunkSize[rank] = { 1, channels };   // one sample per chunk
dataProperties.setDeflate(9);                // always, maximum
```

At 25 kHz that is 25 000 chunks per second, each a separate filter invocation and B-tree entry,
each far too small for gzip to find anything — measured at **0.80x on the block index**, i.e.
compression made it larger. Measured on a 64-channel synthetic stream: 1 009 501 chunks of
512 bytes for one million samples.

Now, in `HdfRecorders::rowsPerChunk()`:

* **Chunk = one second of samples**, capped so a chunk still fits HDF5's default 1 MB
  per-dataset chunk cache. The cap is not optional — a chunk larger than the cache is
  read-modify-written on every partial append, which would be worse than what it replaced.
* **Compression off by default**, opt-in via `Recorder::setCompression(0..9)` and the
  recorder's `compression` parameter. Filters are fixed when a dataset is created, so the
  setting applies from the next `openFile()` and the UI disables it while recording.
* Index and event datasets get fixed chunks (1024 and 256 records) — they carry one record per
  *block*, not per sample.

Verified against his file. A 2-channel 5 kHz stream now produces `chunk=(5000, 2)`,
`filter=NONE` — identical to `test_acc3.hdf`. A 64-channel 5 kHz stream produces
`chunk=(2048, 64)`, the 1 MB cap doing its job. With `compression=6` the same 30.2 MB of samples
store in 0.5 MB.

<a id="history-65-parametersstreamactivestream-is-a-q_property"></a>

### 6.5 `Parameters::Stream::activeStream` is a Q_PROPERTY

So a view bound to a live `Stream` object can read the resolved connection directly instead of
digging it out of the serialised attributes, which only a configurator ever sees.


<a id="history-7-published-streams"></a>

## 7. Published streams

Two `Message` streams, both JSON, schema `v: 1`. Additive changes do not bump `v`; consumers
ignore fields they do not know.

<a id="history-status"></a>

### `status`

Deliberately **not on a timer.** `onRecorderStatusChanged` builds a signature (open/closed plus
each stream's state) and publishes only when it changes. Measured: 34 s of steady recording
produced **5** messages — started, three stream-state transitions, stopped.

```json
{"v":1,"type":"status","state":"recording","event":"streams_changed",
 "file":"session-0001.h5","bytes":260999,"seconds":15,"allPresent":true,
 "freeBytes":75644166144,"wall":"2026-08-12T09:48:45.878",
 "streams":[{"name":"generated","state":"recording","bytes":100694,
             "rate":6072,"reconnect":true}]}
```

`rate` is bytes/s as an integer — rounding baked into the wire format cannot be undone later.
`stopRecording()` publishes **before** `closeFile()` so the final message still carries the file
and its size.

<a id="history-annotations"></a>

### `annotations`

Recorded into the file via `recordLocalStream()`, registered before the data streams so the
session anchor is first in the file.

```json
{"v":1,"type":"session","file":"session-0001.h5",
 "rtc":"620365234496600","wall":"2026-08-12T11:17:32.917"}

{"v":1,"type":"annotation","by":"tray","text":"bad trial",
 "wall":"2026-08-12T11:17:53.624"}
```

The anchor exists because `RTC::now()` is monotonic with an arbitrary epoch
(QueryPerformanceCounter since boot) and cannot be turned back into a date on its own. Pairing
it with a wall clock once per file is what makes every timestamp in that file interpretable.

`by` is `tray`, `window` or `configurator`.


<a id="history-8-annotation-timestamping"></a>

## 8. Annotation timestamping

The RTC is taken when the input box *opens*, not when it is submitted, and travels with the text.

Verified end to end: dialog opened at 19:44:04.463, text typed over 19 s, service received it at
19:44:23.234 — and the recorded RTC resolves, against the session anchor, to 19:44:04.5.

For the Configurator path the client's own RTC is used. Same machine, same monotonic clock, so
it is exact; cross-machine it would be wrong, and the service falls back to `RTC::now()` when no
RTC is supplied. This was **the one place the design assumed a single host** — until
2026-08-18, when `NetworkMode::Loopback` became the framework-wide default and a single host
became the assumption everywhere ([network-isolation.md](../migrations/network-isolation.md)). The fallback
still matters for a rig deliberately put in `lan` mode.


<a id="history-9-verification-performed"></a>

## 9. Verification performed

⚠ **Measured against the `R:\dist\msvc64` of the time — the tree now called
`R:\dist_Qt5\msvc64` — which was replaced on 2026-08-18.** Both recorder paths were
re-exercised on that new tree — the standalone service and the Configurator's embedded
`Recorder`, from a generator and from a 73-channel playback, 0 NaN in every file
([network-isolation.md §8.1](../migrations/network-isolation.md)). The detailed figures below are the
original run.

⚠ **None of it has been re-run against the Qt 6 build.** What that build has is in
`R:\src\docs\VALIDATION.md`: "Generator, recorder, and playback validation" — configured
through the ordinary `--serviceConfig` path, driven through the ordinary `start`/`stop` transitions,
and producing a cleanly closed file — and "2026-08-28 final recorder/NVX136/NeuroMS validation",
which launches all three built-ins and checks their windows. The mirroring, heartbeat, slot-floor,
tray and annotation-RTC checks below have Qt 5 provenance only.

Against `signalGenerator` and a real NVX-52.

* Two-way mirroring, both directions, for text and numeric parameters.
* No heartbeat: 5 status messages in 34 s.
* Action invoked over the wire; `null` replay does not annotate.
* Slot floor: with 2 slots recording, `streamsCount` reports `minimum: 2` and a push of `0` is
  refused; released to `0` on stop.
* Middle-click on tray and on strip both restore and focus a minimised window.
* Annotations from tray and window land in the file with the click RTC.
* `keep` across a producer restart: one dataset spanning a ~40 s outage.
