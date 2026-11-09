# Stimulus presentation

**Status:** active Qt6 x64 executable `stimulusService.exe`, identity **Stimulus**, with its standard authoring/presentation console. It shares TepSound's presentation path and has no analysis/SOUND worker. Optional generic recording settings coordinate already-open acquisition and Recorder services; they are disabled by default.

## Change locations and sibling impact

| Change | Source |
|---|---|
| Service identity/parameters/run integration | [service.cpp](../../src/stimulusService/service.cpp), [parameters.cpp](../../src/stimulusService/parameters.cpp), [service_run.cpp](../../src/stimulusService/service_run.cpp) |
| Authored document/model/sequence | [experiment.cpp](../../src/tepSoundService/experiment.cpp), [experiment.hpp](../../src/tepSoundService/experiment.hpp), [sequence.cpp](../../src/tepSoundService/sequence.cpp), [service_experiment.cpp](../../src/tepSoundService/service_experiment.cpp) |
| Validation, media facts/packing | [experimentcheck.cpp](../../src/tepSoundService/experimentcheck.cpp), [mediaprobe.cpp](../../src/tepSoundService/mediaprobe.cpp) |
| Realized trigger plan and media | [triggerplan.cpp](../../src/tepSoundService/triggerplan.cpp), [videocue.cpp](../../src/tepSoundService/videocue.cpp) |
| Stage, old-protocol importer support, wire backend | [shared/stimulusService](../../src/tepSoundService/shared/stimulusService) |
| Build/fixtures/GUI tests | [CMake](../../src/stimulusService/CMakeLists.txt), [presentation_test.cpp](../../src/stimulusService/tests/presentation_test.cpp), [demo](../../src/stimulusService/protocols/stimulus-demo.tep.json) |

Current CMake compiles the TepSound files above into `stimulusPresentation`; these are active shared implementation, despite their directory names. Changes must validate **both Stimulus and TepSound**. Retired Qt5 copies are comparators only.

## Authored document contract

`.tep.json` schema1 has stable stimulus IDs, numbered cue rows, a single inspectable sequence string, seed, screen settings, trigger specifications and media facts. Each row combines medium/content, duration, response, marker, repetitions and trigger list. Renumbering/reordering must preserve stable IDs and correctly rewrite sequence references.

Welcome0, End−1, background−2 and Interval−3 are distinct special rows. Interval is **outside the stimulus pool and sequence**; it is inserted between cues and must not be shuffled as another repeated stimulus. Welcome/end marker compatibility remains separate from these row numbers.

- Media: blank/text/image/video/audio. File use is not duration ownership: only video/audio accept media-length and seek-in behavior.
- Fixed/jittered durations share a min/max representation; collapsed ranges are fixed.
- Sequence modes pasted/shuffle/block-shuffle preserve constraints and seed. Unsatisfiable constraints refuse within a bounded solver budget. Balanced completed blocks do not guarantee balanced arbitrary prefixes.
- Trigger entries carry stable ID/label, backend/target/code, offset range, probability, minimum separation and optional serial board residual. Collision identity is **backend+target**, not code.
- Serial default minimum separation500ms follows2Hz telemetry visibility; other message paths default10ms. Faster values are explicit authored decisions, not implicit acceptance.
- Board-timed residual is serial-only and refuses incompatible existing `@`/standing-rule syntax. Other backends report frame quantization.
- Background pattern has its own phase across cues; suppressed beats keep their slots. Store lead-in/out in milliseconds, not variable-length “periods.” Per-row gating does not reset the clock.
- Media facts/hash checks identify changed/missing assets. Pack media copies content-checked files, never overwrites/deletes originals, and requires Save to retain changed references.
- Relative media paths resolve against the saved document's directory for validation, preview/run and packing. Save As rebases relative paths (including special rows and media-fact keys) to preserve their targets; a failed save leaves the original document unchanged. Absolute paths retain their meaning. Unsaved documents use the configured stimuli directory.

## Parameters, lifecycle and operator integration

Presentation parameters: tmsStatus, protocol, seed, showStage, fullscreen, screen, triggerBackend, triggerTarget, triggerInit, triggerMap, triggerPulseMs, requireCharged, maxCoilTemp, tmsStaleMs, subject, condition, operator, showUi, note, reloadProtocol, pulse. Backend order is **None, Serial, Transition, Parameter, UDP**; default None opens no physical output.

Optional `recording` parameters: `record` (default false), `recorderService` (Recorder), `recordFile`, `recordSource`, `acquisitionService` (default empty), `acquisitionBefore`, `acquisitionAfter`, and read-only `recordingStatus`. The two acquisition sets are JSON arrays of ordinary name/serialized parameter entries. Empty acquisitionService leaves acquisition under operator control. No service is launched or renamed. See [recording.cpp](../../src/stimulusService/recording.cpp).

Idle exposes arm/prepare(alias)/start; armed start/stop; running pause/stop; paused resume/stop. Start passes through preparing; Stop/completion pass through saving and return idle after recording cleanup. Prepare validates media/document and opens/configures all required wires **before activating a run**. It can touch a board. Lock document/connection edits until cleanup completes.

The four-tab console is a view of these objects. Sequence text updates the document and realised order on every edit; invalid intermediate text blocks preparation instead of leaving an old runnable sequence. Cue cards have stable per-stimulus colours; welcome/end/ISI are grey. The header is Presentation. Preview never sends triggers. Response capture respects focused editors, ignores subject key autorepeat, supports Backspace/Enter and measures software reaction time from presented onset. Hiding the console leaves service running; Exit closes QML windows before destroying service/model.

Subject-window visibility and fullscreen are applied together by the service. Changing fullscreen while `showStage=false` must leave the stage hidden, so opening a task preset exposes the operator console. Start/Preview explicitly show the subject window. `fullscreenDoesNotReopenHiddenStage` covers this ordering and visible fullscreen/windowed transitions.

Screen labels report physical pixels (`QScreen` geometry × devicePixelRatio), scaling and orientation; persisted values remain screen identities. Placement uses the chosen QScreen and its geometry, including portrait displays and mixed-DPI virtual desktop gaps. Geometry/DPI changes refresh placement. A `.tep.json` is the editable experiment; Configurator parameter JSON only points to it through `protocol`, alongside service settings. Neither format embeds media.

Failed loads retain the old editable document but **block Prepare** until corrected/New; media probe event loops must not re-enter authoring/validation. Import old protocol cues/schedules with explicit warnings; do not silently revive embedded legacy device orchestration. Removed legacy parameters include stageScreen (now screen), impedance and monitor_*. `record` and `recordFile` now have the explicit generic recording behavior described here; old embedded orchestration is not imported.

## Subject display

Without a saved named screen, automatic placement chooses a monitor to the right of primary, then the leftmost to its left, then any secondary, then primary. Selection and geometry use the shared `subjectdisplay.hpp` helper, also used by P300. Primary opens windowed even if a preset requests fullscreen; secondary displays follow the fullscreen setting. Old saved default-selection labels are accepted. Named screen selections remain explicit; disconnect detection retains its existing run-stop behavior.

## Timing, interlocks and teardown

With recording enabled, Start first validates the document, stops/configures/restarts the selected acquisition service with parameter readback, configures an idle Recorder for signal/events/status, and waits for correct connected slots plus fresh Float64 samples. It refuses to take over an active recording. Completion and Stop drain final events for 750 ms, stop Recorder, then apply/restart the optional after-acquisition set. Missing samples for 3 seconds, peer loss or recording loss stop the run; errors leave controlled acquisition stopped. Exit waits for cleanup. Pausing presentation leaves recording active. The [MPRAC venue](../how-to/mprac.md) leaves the after-acquisition set empty, retaining EEG mode after completion and Stop. The EEG readiness subscription is attached after acquisition restarts so it cannot retain the previous publisher.

Stage updates happen at beforeSynchronizing; announce onset before zero-offset pulses using a shared swap timestamp. Do not count preroll frames. Media errors/stale render notifications must not create successful onsets or pulses. Qt6 video sink delivery and first decoded audio buffer are **software milestones**, not photon/speaker onset. Alternate audio backends may fall back to coarser position updates. Media startup can extend the preceding cue; publish actual onset/decoder lag.

Pause freezes cue/trigger/media schedules. End duration/responses/triggers complete before the separate sentinel. Stop clears current/queued layers and scheduled work even when hidden, mutes media and closes wires. Parameter-backend shutdown writes pending LOW immediately and invalidates old timers. Missing named wire never falls back to another output; refusal is not “fired.”

Nominated telemetry gates match required channel names and fail closed on missing/stale/nonfinite readings. With no telemetry stream nominated there is **no gate**. Monitor disconnect stops a run and preserves visible disconnected selection.

## Streams and recording

`events`: Message JSON session/run/plan/cue/pulse/response/note. Cue RTC equals block creation RTC. Pulse dueRtc/frame denotes stage boundary, sentRtc later dispatch, residualMs board timing; **fired means software accepted the write**, not measured physical TTL.

`status`: Float64, 8 lanes at nominal 2 Hz: engaged, running, paused, trial, trials, droppedFrames, pulsesSkipped, triggerReady (manual connection). The existing [Recorder](recorder.md) writes these. Connect it before Start when managing recording manually; the optional recording settings connect it automatically. Run-start events include subject/condition/operator even if Prepare was performed before Recorder started. Preserve experiment/media separately—the recording does not embed them.

## Validation and current limits

Use registered `test_StimulusPresentation`, `test_TepExperiment`, and conditional `test_TepMedia` via [test workflow](../how-to/test.md). [test-stimulus-presentation.py](../../src/scripts/test-stimulus-presentation.py) provides deployed text/PNG/WAV/synthetic-video plus loopback-UDP/recorder acceptance; it launches processes and requires its stated fixtures. [Prior acceptance](../../src/docs/qa/stimulus-live-acceptance.json) documents previous runs, not this restructure.

Physical audio/photodiode/TTL timing, serial board paths, remote device commands, real TMS interlocks and hot-unplug need separate acceptance. Historical Qt5 timing figures and DOCX screenshots do not certify current physical onset. [Dated corrections](../history/components/stimulus-presentation.md#history-current-service--2026-09-06). The [MPRAC implementation record](../history/changes/2026-09-24-mprac.md) reports the September 24 software acceptance and real NVX recording/mode transitions. EEG inputs were invalid/disconnected and the photodiode was absent; it makes no physical timing or usable EEG claim.
