# 2026-09-24 — MPRAC lab follow-up and native P300

Scope: current Qt 6.11.2 source in `R:/src`, installed operator package `R:/dist`. Requested changes follow the user's lab trial. Standard Configurator/service identities remain in use. No physical amplifier was opened for this follow-up; earlier physical evidence remains in [the initial MPRAC record](2026-09-24-mprac.md).

## Delivered behavior

- Stimulus title drops “Studio”; pasted sequence edits immediately update the plan while the editor retains focus. Invalid intermediate sequences refuse Prepare. Realised trials use stable colours by stimulus ID; welcome/end/ISI remain grey.
- Subject labels show physical pixels, scaling and orientation. Placement sets the actual QScreen and its geometry, avoiding landscape/desktop-offset assumptions. Screen geometry/DPI changes refresh the options and stage. Software tests include 125% scaling; the user's mixed GPU/iGPU portrait rig is not available locally.
- Launchers discover/reuse idle services once, apply Recorder as well as presentation settings, and refuse active presentations/recordings. An installed task switch measured 0.985 seconds. Completion and manual Stop retain EEG acquisition; an impedance check is now explicit. Readiness subscribes to the restarted EEG publisher, fixing an intermittent retired-stream race.
- All strip icons display at 32 pixels, using standard NVX/Recorder artwork and content-specific presentation PNGs. All 14 raw columns remain in the upper viewer. ERP presets open the lower viewer at 48%, with Cut epochs and averaging. The generic “Epochs only” display setting keeps ingestion/cutting active.
- The supplied 1080p set replaces matching images by default; two flat replacement ZIPs are in the venue's `stimuli` folder. Supplied bytes are unchanged, including the 1921×1201 checkerboards in the 16:10 set.
- Native P300 supplies the 53 old parameter names/options and all six modes, plus ordinary recording/display/model settings. Calibration and feedback launchers use a 36-symbol 6×6 alphabet. SPEED retains the Python/MATLAB inference approach. No trained 12-channel model was supplied, and the old 30-channel clinic model is incompatible: feedback deliberately refuses without a compatible file.

## P300 corrections

Planner fixes include bounded unbiased shuffling, complete trial counts beyond one alphabet, target spacing across blocks, valid partial rows, working JumbledEach Typing, bounded invalid-plan rejection and one explicit next-letter key between trials. Image/background preflight refuses missing assets before recording. Single-stimulus mode retains the target-containing row/column flashes. Dynamic backgrounds retain one target image.

The native renderer retains the frame-driven Flicker approach on the basic render loop. Highlight cells retain layout positions through opacity rather than disappearing from Grid. A native UI test checks row/column positions, screen identity, full/windowed geometry and idle alphabet edits. The photodiode patch is dark while idle and respects its enable setting. Matrices fit smaller windows without clipping. This does not measure physical scanout/onset latency.

Inference waits for real EEG availability instead of merely moving an event timestamp, rejects missing optical edges/nonfinite epochs, preserves continuous filter state and channel-major MATLAB features, normalizes scores by cell exposure, rejects stale run/trial results and bounds retained history. Digital detection uses rising edges. Optional analogue `photo_polarity` supports falling voltage while preserving the old positive default. Host-stamped overlapping blocks are monotonized within the received endpoint; this does not recover an ADC clock.

SPEED graph replacement now disconnects the old input's destruction callbacks before deleting it. This fixes a false “Input stream closed” failure when preparing another run after an error. P300 detaches old result subscriptions and attaches the new publisher after preparation. Synthetic test models stay in test output, never in deployment.

## Photodiode analysis and playback scope

`src/_test-output/mprac-photo-threshold-analysis.json` records the analysis of untouched legacy voltages. Falling −1.95 V with 600 ms refractory detects 60 large, 60 medium, 61 small checker events and 80 button events. Small checkers have 63 raw crossings and one extra accepted event; only 59 software-marker matches. This selects one checker inversion polarity per pair. The threshold requires confirmation on the actual diode/display.

The original large recording contains host timestamp gaps; a first untouched replay produced accepted epochs plus legitimate gap refusals. To isolate detector/viewer behavior, the final test uses QA copies with unchanged voltages but uniform 1 kHz block timestamps. Originals are never rewritten. `mprac-erp-playback-20260924-153134/report.json` records 60 large-checker epochs and 9 epochs in a 45-second button prefix, no timestamp gaps/refusals, lower pane 389.76 pixels, epochs visible and sweep hidden. Windows contain 700 samples (−100 to +600 ms, half-open).

This verifies displayed Cut epochs. Exploratory recording of published epoch streams produced inconsistent subscriber counts and is not claimed as accepted here; normal raw EEG/events recording is tested separately. P300's lower optical monitor uses 50 ms refractory and averages all patch edges including hints, while classification uses flash/trial markers separately.

## Executed validation

- Normal build completed with the standard Qt 6/MSVC build script. `mprac-final-ctest.log`: seven selected targets passed (LaunchBar, ViewerReconnect, PlaybackSeek, TepExperiment, TepMedia, StimulusPresentation, P300Plan).
- `stimulus-final-test.txt` and `stimulus-125percent-test.txt`: 15 checks each, all passed. Sequence PNGs under `mprac-final-ui` were inspected: distinct trial colours and grey special rows.
- `p300-ui-ctest.log` / `p300-ui-test.txt`: planner and native UI tests passed; `p300-final-ui/p300-matrix.png` inspected. Classifier numerical tests: seven passed in `p300-classifier-tests.log`.
- Static presentation integration: all six schedules/markers, 14-channel raw files, completion/Stop and fault cleanup passed in `mprac-20260924-152358/report.json`.
- P300 integration uses native P300, SPEED and Recorder with a synthetic NVX fixture. All six modes, exact onset/offset counts, recorded classifier outputs, repeated runs, missing/incompatible model refusal, missing photodiode refusal and manual Stop pass. The final installed-build test is `p300-20260924-155550/report.json` with `p300-deployed-integration.log`; it uses private distribution Qt/Python and the final classifier bytes.
- Installed launchers: `mprac-standard-launchers-20260924-154652/report.json` verifies ordinary identities, no duplicate services, updated Recorder filename, retained EEG mode, 36-letter calibration/feedback presets and refusal without the trained MATLAB model. The final rerun `mprac-standard-launchers-20260924-155707/report.json` additionally verifies P300's lower epoch preset and passes; `mprac-final-launchers.log` records it.

## Deployment and remaining acceptance

Scoped non-deleting installation preserves replaced files under `R:/builds/mprac-followup-backup-20260924-154641`; `src/_test-output/mprac-followup-deployment.json` records before/after SHA-256 values. Final P300/preset fixes are in `mprac-followup-final-deployment.json`, with rollback under `R:/builds/mprac-followup-backup-20260924-155535`. No recordings or unrelated operator presets were replaced. The earlier full snapshot predates this follow-up and has not been overwritten.

Remaining external inputs: a trained MPRAC12 MATLAB classifier; optical/button measurements and useful EEG on the lab rig; mixed-adapter portrait/fullscreen verification. Moving inference inside P300 is feasible; the [P300 component plan](../../components/p300.md#future-in-service-classification-and-training) specifies numerical parity and separate validated training/model provenance before replacing SPEED.

Protocol files and Configurator parameter saves remain different: `.tep.json` owns experiment content/media references; the parameter JSON owns service settings and a protocol path. Saving parameters does not embed or save edits to the experiment/media.
