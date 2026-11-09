# Recorder

**Status:** active Qt 6 service/executable `recorderService`. Recording is owned by this process; Configurator, window, tray and status strip are views of one state. Illustrated DOCX manuals remain [operator material](../operators/README.md).

## Change locations and shared ownership

The Configurator's default Recorder icon launches `recorderService.bat`, which starts this standalone service. The older `recorder.bat` still explicitly launches the built-in quickStimulus recorder. Existing distributions keep operator-owned `launchbar.txt`; change its Recorder entry when applying this launcher update.

| Change | Source |
|---|---|
| Parameters, refusal gate, lifecycle, status, annotations, window/tray | [service.cpp](../../src/recorderService/service.cpp), [service.hpp](../../src/recorderService/service.hpp) |
| GUI lifetime/resources | [main.cpp](../../src/recorderService/main.cpp), [ui.qml](../../src/recorderService/ui.qml), [strip.qml](../../src/recorderService/strip.qml) |
| File layout, append/chunk/compression behavior | [HDFRecorder.cpp](../../src/Core/Resonance/internal/HDFRecorder.cpp) |
| Shared parameter/application semantics | [framework](../architecture/framework.md), [parameterapply.cpp](../../src/Core/Resonance/parameterapply.cpp) |
| Packaging | [CMakeLists.txt](../../src/recorderService/CMakeLists.txt) |

HDF/core changes affect the Configurator's embedded recorder and other `ResonanceApp` recording users, not only this executable. [Playback](playback.md) is a compatibility reader. Keep QApplication and `setQuitOnLastWindowClosed(false)`; hiding a recording window must not exit.

## Parameters and start contract

One group `default`: `annotate` Action, `fileName`, `streamsCount`, dynamic `stream1…N`, `flushSeconds`, `compression`0..9 (default0), `autoStart`, `showUi`, `showStrip`. `$$$$` expands to run number. Actions/transitions are `start`, `stop`, and framework `!terminate`.

Slots accept an address string or Stream JSON. Empty string clears; a scheme-less string is refused. A discover URL alone can supply the stream name. Use `StreamInfo::isEmpty()` for “nothing addressable,” not pointer-identity `isNull()`.

`autoStart` reads its value when the one-shot 2-s launch timer fires **after configuration applies**. It is not an immediate runtime start switch. Dynamic slots created by `streamsCount` can be applied in one configuration; the old manual-only advice is fixed.

A rejected configuration write leaves the previous value intact. Therefore the service tracks refusals for `fileName`, `streamsCount` and slots, and **refuses Start until each is reapplied successfully**. There is deliberately no bypass. Status exposes `canRecord`, `parameterRefusals` and actual `slots` with stream/address/empty/resolved, alongside recorded `streams`. Preserve this gate when changing application order or validation.

Slots cannot shrink while recording: the minimum count rises to the starting slot count. Added streams remain tracked by Recorder even if a UI reference is removed. Stop restores the minimum. The interface must not imply a removed row stops an existing dataset.

Use the distribution launcher/environment for `RESONANCE_RECORD_PATH=<distribution>/data`. Absolute file names select their explicit location. Without that override, current [ResonanceApp path resolution](../../src/Core/Resonance/ResonanceApp.cpp) uses a valid `RESONANCE_DIR`, otherwise the executable directory (or its parent when named `bin`), and creates/uses its `data` folder. Direct launch therefore does not default to the shell's working directory.

## HDF compatibility contract

The writer binary decides the format—not the Qt version of the reader, and not merely a “Qt6” label on an early file.

- Older Qt5 and pre-fix Qt6 files allocate a trailing zero numeric row and may allocate one empty index/message record.
- The current writer starts datasets at extent0 and appends exactly the supplied samples/records.
- **Authoritative sample count is the sum of block-index sample counts.** Read `data[:sum(blocks.samples)]`; never unconditionally drop the last row and never infer valid sample count from dataset shape.
- Active-low trigger lanes make a spare all-zero row look like spurious final events. Trigger polarity is lane/device-specific; do not assign one polarity to all lanes.
- Playback retains compatibility with both layouts and rejects an index requiring more sample rows than the dataset holds.

Numeric chunks aim at one second of samples, capped to the default ~1MiB per-dataset HDF cache. Larger chunks can cause repeated read-modify-write on partial append. Index/message chunks use1024/256 records. Compression is off by default; filter settings apply at **next file creation**, not to an existing dataset.

## Streams and timestamp semantics

Both published streams are version1 Message JSON; additive fields do not bump the schema version, so readers ignore unknown fields.

`status` is change-driven, not a periodic meter. Its signature covers file open/closed and per-stream state. Fields include state/event/file/bytes/seconds/allPresent/freeBytes/wall/streams plus refusal/slot details. Stream `rate` is integer bytes/sec. Publish final status **before closeFile** while file identity and totals still exist.

`annotations` is registered locally before data streams and recorded automatically. A session anchor pairs monotonic decimal-string RTC with wall time; RTC alone is not a date. Annotation RTC is captured when the dialog opens, not after text entry. An explicit Action invocation carries `{"invoke":true,...}`; its serialized value is null, so saving/loading descriptions must not annotate.

A client RTC is meaningful on the same host. Loopback is default; LAN deployments must not assume monotonic clocks are synchronized. Fallback host-arrival RTC does not establish cross-host click timing.

## Validation and evidence

No dedicated recorder module test target is registered in its CMake. Route shared parameter/path/HDF checks through [test](../how-to/test.md); inspect [RecorderPath_test.cpp](../../src/Core/Resonance/tests/RecorderPath_test.cpp). [VALIDATION](../../src/docs/VALIDATION.md) contains Qt6 generator→record→replay integration.

For functional acceptance check slot resolution/refusal recovery, delayed autoStart, preserved head/tail samples and block totals, compression next-file behavior, annotations and graceful close. Use a device-free generator where possible.

[Historical HDF comparison](../history/components/recorder.md#history-2a--the-last-sample-of-every-recording--a-dud-in-a-qt-5-file-gone-in-a-qt-6-one) preserves the before/after measured files. Prior GUI screenshots do not define current pixels. Selected source was inspected; this documentation change ran no recording or tests.
