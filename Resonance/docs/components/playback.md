# Playback

**Status:** active Qt6 controller `playbackService.exe` (identity `Playback`) and worker `playbackSource.exe`. It republishes recorded Float64/Message payloads as ordinary service streams.

## Change locations

| Change | Source |
|---|---|
| HDF enumeration, compatibility, payload/index reads | [hdfsource.cpp](../../src/playbackService/hdfsource.cpp) |
| Controller mapping/lifecycle/UI | [service.cpp](../../src/playbackService/service.cpp), [ui.qml](../../src/playbackService/ui.qml) |
| Interprocess job/control protocol | [playbackjob.cpp](../../src/playbackService/playbackjob.cpp) |
| Prefetch, pacing, scheduling, seek | [player.cpp](../../src/playbackService/player.cpp), [seekmath.hpp](../../src/playbackService/seekmath.hpp) |
| Worker entry and standalone actions | [sourceservice.cpp](../../src/playbackService/sourceservice.cpp), [sourcemain.cpp](../../src/playbackService/sourcemain.cpp) |
| Regression/build | [seekmath_test.cpp](../../src/playbackService/tests/seekmath_test.cpp), [CMake](../../src/playbackService/CMakeLists.txt) |

One process declares one service. The controller spawns one worker per distinct mapped service name so streams can impersonate multiple original producers. A controlled worker exposes no independent Start/Pause actions, preventing sibling desynchronization. Standalone workers expose start/pause/resume/stop.

## Parameters and preparation

Controller keys: `file`, `rescan`, `contents`, `defaultService`, `speed`, `loop`, `scaleRate`, `autoStart`, `showUi`; per-file-stream `play<i>`, `name<i>`, `service<i>`.

`idle → preparing → armed → playing ⇄ paused`; stop returns idle. File/mapping changes are disabled outside idle. Armed means streams are published and listening but no payload is emitted. For complete capture: **Prepare → attach/start consumers → confirm resolution → Play**. Starting directly from idle may outrun discovery and lose the beginning.

Recorded files normally retain resolved transport addresses, not original producing service names. Supply names explicitly. Avoid a spoofed (service name, stream name) pair already provided by a live driver; discovery has no arbitration. The collision scope is one host by default, or LAN when explicitly enabled.

## Timeline, threads and speed

For every selected stream:

```text
due(j) = startRtc + (created(j) - originRtc) / speed
```

The controller supplies one global origin and loop boundary to all workers. Each emits blocks stamped with **due time**, exposing lateness rather than hiding it in fresh send-time stamps. Pause/resume/speed changes re-anchor once in the controller without moving cursors; future-dated hold requests keep workers at the same source instant.

Worker threads:

- Reader owns the non-thread-safe HDF library/file and prefetches sample payloads.
- Pacer waits for due time.
- Main thread creates newly stamped blocks, emits and handles control.

Prefetch is capped per lane at64 blocks or32MiB. Do not pre-stamp queued DataBlocks: anchors can change. High-resolution Windows waitable timers have condition-variable fallbacks; generator has a separate implementation. Legacy timing measurements are not current Qt6 guarantees.

Default `scaleRate=false` retains original declared rates while delivery accelerates; viewer time windows fill faster. `scaleRate=true` multiplies declared rate (and apparent signal frequencies) at start, and defers speed changes until next start because rate is part of stream type. Run at1× for pipelines whose timers/filter frequencies assume physical real time.

## Seek contract

Seek changes cursors without republishing streams or ports. Target is **recording nanoseconds**, not wall elapsed. Each stream selects its first block at/after the target; late-start/early-end streams wait/skip normally. Right edge clamps to last block instead of ending the session. Return/display the actual clamped position.

Keep anchors signed `qint64`: deep slow seeks can map the notional file origin before host boot. Clamping such an anchor to0 makes the remaining file overdue and can burst it into consumers.

Seek is an input discontinuity. Publish a seek status event; do not reset consumers remotely. Epoch cutters can reject gap-straddling windows, but stateful filters may ring and a pipeline reset may discard its entire accumulated session. The operator/caller owns that tradeoff.

## File and replay constraints

- Read valid numeric count from block indices, not raw dataset shape; support current zero-extent and legacy spare-row/empty-record conventions. Fail when indices require more data than exists. See [recorder](recorder.md).
- Restore serialized type and per-channel metadata, with a timing adjustment when `scaleRate=true`: for each Float64 channel, divide `window_start_ms` by speed and rebuild `window_end_ms` from the original integer sample count at the new published rate. Preserve trigger-zero/sample alignment and sample count; simply dividing both endpoints can lose a sample through floating-point rounding. Keep absent metadata absent and property-list lengths unchanged; do not invent montage/kind information absent from older recordings.
- Play Float64 and Message. **Refuse EventBus** replay: recorded configuration/state commands must not reach a live bus. Even an ordinary recorded device command stream can actuate hardware if explicitly connected to a command input.
- Keep unreadable/unplayable streams listed with reasons.
- Re-recording preserves payloads and intended cadence, not absolute RTC, arrival time, UID, transport addresses or file bytes.
- Recorder's own `annotations` takes the first dataset name; a replayed stream with that name is de-duplicated. Rename it for clarity.
- Gaps and NaNs in the source remain gaps and NaNs; they are often the intended test input.
- Anchors are machine-local; LAN transport alone does not synchronize remote clocks.

## Validation and evidence

Registered `test_PlaybackSeek` covers seek arithmetic; use [test workflow](../how-to/test.md). [VALIDATION](../../src/docs/VALIDATION.md) contains Qt6 generator/recorder/playback integration. Validate arrays plus created-time **deltas**, stream metadata, block totals, cursor clamp, and no publisher recreation during seeks.

[Prior full replay/seek/timing evidence](../history/components/playback.md#history-7-verified) is mostly Qt5 provenance. Fine-block high-rate timing, many services/streams, remote hosts and multi-consumer fanout are not established by those runs. Playback end-to-end latency includes file/transport overhead and cannot stand in for ADC-to-output latency. Current framework supports scripted dynamic recorder slots; historical manual-only and ctypes workarounds are superseded. No replay/tests ran during this restructure.
