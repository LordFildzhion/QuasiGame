# Signal viewer

Cut mode's **Sweep + epochs / Epochs only** control persists as `epoch_cut_show_sweep` in plot settings. Hiding the continuous trace does not stop ingestion or epoch cutting. The second viewer starts collapsed to its title line; its arrow expands it and restores the last height (or width in side-by-side mode). Collapsing hides controls/plots without stopping ingestion, cutting or publication. `viewer_secondary_percent` (0–90, default 0) sizes the expanded pane; MPRAC uses 48%. The expanded splitter remains draggable. All raw MPRAC channels stay above, EEG epochs below. See [MPRAC](../how-to/mprac.md) for the photodiode threshold and playback evidence.

**Status:** active Qt6 viewer inside `quickStimulus.exe` / Configurator and `Resonance.Plot`. It has two independent display instances; a viewer is not a separate acquisition service. For epoch-oriented input/storage, also read [epochs](../architecture/epochs.md).

## Change locations

| Change | Source |
|---|---|
| Sample ingestion, filters, envelope ring and strip painting | [timeseriesreceiver.cpp](../../src/quickStimulus/timeseriesreceiver.cpp) |
| Channel/group state, source-kind restoration and scales | [channelmodel.cpp](../../src/quickStimulus/channelmodel.cpp) |
| Pure ticks/range/projection/decimation | [plotmath.cpp](../../src/quickStimulus/plotmath.cpp) |
| UI assembly and interaction | [PlotView.qml](../../src/quickStimulus/import/Resonance/Plot/PlotView.qml), [ChannelPanel.qml](../../src/quickStimulus/import/Resonance/Plot/ChannelPanel.qml), [PlotSettings.qml](../../src/quickStimulus/import/Resonance/Plot/PlotSettings.qml) |
| Scalp layout and persisted options | [HeadView.qml](../../src/quickStimulus/import/Resonance/Plot/HeadView.qml), [Settings.qml](../../src/quickStimulus/import/Resonance/Plot/Settings.qml) |
| Reconnect tests | [viewer_reconnect_test.cpp](../../src/quickStimulus/tests/viewer_reconnect_test.cpp), [CMake](../../src/quickStimulus/CMakeLists.txt) |

Configurator/connector changes also depend on [framework](../architecture/framework.md) and [UI architecture](../architecture/ui.md). Shared montages/topomap PNG assets live in [Bricks](../../src/quickStimulus/import/Resonance/Bricks).

## Channels, rows and saved state

Rows are derived: line/step channels create one; bit channels create one per observed changing bit. Paging uses rows, not channel count. Gutter and painter must share drawn-row geometry; colours/selection/width belong to channels, not row indices.

The impedance disc map respects channel visibility for both positioned and off-montage channels. Hiding unused amplifier inputs therefore removes their discs as well as their traces. Bad-but-visible electrodes remain visible with the existing muted appearance.

New trigger-bit lanes are revealed while ingesting the block that contains their first edge, before the sweep cursor is announced. Reuse the raw per-sample edge scan; do not defer new lanes to the one-second maintenance timer. That timer retires bits whose transitions have left the visible buffer. Delaying initial lane discovery can leave a Trig0 placeholder while the cursor advances, then reveal several Trig4 pulses together behind it.

Derive groups from metadata kind/unit, then name heuristics, then manual overrides. Bare numeric names remain default rather than guessed EEG. Impedance uses Ohm, steps, filter bypass and a positive scale; it is not EEG.

State is cached by **channel name and source kind**, so an electrode returning from impedance to EEG recovers EEG filters/scales instead of carrying impedance bypass. Saved entries include sourceKind; old entries fall back to group. Preserve independent manually edited EEG settings across repeated mode changes.

Settings are JSON in the viewer's String parameter, coalesced500ms; unknown keys are ignored, missing keys retain defaults. Catch level/edge persist; **armed catch does not**.

## Scale and reference rules

Ranges use base units; SI prefix derives from magnitude. Step scales on1–2–5. A group shares range; each channel has its own DC centre. Fixed positive-only versus symmetric ranges remain explicit.

Fit is one-shot and leaves manual/fixed scale. Autoscale expands immediately but shrinks only after5 consecutive seconds; notify every affected role so gutter, ticks and controls agree with traces. Treat spans below roughly10^-6 of signal level as flat rather than amplifying quantization noise. Per-channel zoom overrides do not silently rescale its group.

Reference choices: none, single, common average, group average. Exclude bad channels, bit channels and bypassed channels from reference averages.

## Storage, filter and renderer invariants

Envelope slots retain **min and max**, preserving spikes rather than dropping samples:

```text
decimation = max(1, ceil(rate * duration / 16384))
slots = ceil(rate * duration / decimation)
```

Dirty state counts written slots; derive wrap strips at paint time. Merge min/max when transferring to coarser rings; finer slots with no measured source remain NaN. Amplitude changes repaint without touching data.

Filter chain is highpass→lowpass→notch/harmonics. Bit rendering always bypasses it. Nonfinite samples do not enter filter delay state; new filters prime from the last valid value. Order is capped16, warns above8. A filter edit affects arriving samples, **not historical samples already in the display buffer**.

Grid/background/traces share one painted image. Reduce geometry per pixel and collapse subpixel envelopes; avoid heavy antialiasing in narrow rows. Incremental strips start one pixel column early, re-clear it and keep clipping tight; use enough lookback for the current slots-per-column ratio. Never extrapolate beyond the last actual sample. Compare both flat trigger lanes and steep waveforms against full repaint; each exposes a different seam defect.

## Cut continuity and refused epochs

`epoch_cut_use_block_timestamps` defaults to **true**, preserving strict timestamp continuity checking. The Cut panel's **Continuity** selector also offers **Sample order (padded gaps)**. MPRAC sets this to false because NVX stamps completed blocks with PC arrival time, not exact hardware sample time; the old half-sample tolerance could reject every otherwise continuous epoch.

Sample-order mode requires an ordered source that preserves missing sample positions with NaNs. NVX pads ordinary hardware-counter losses this way. Whole missing rows refuse overlapping epochs in both modes. A missing individual electrode does not establish a stream gap. Nonfinite trigger samples reset edge state, avoiding invented edges at a hole. This mode cannot discover losses that a producer/transport fails to represent, and must not be selected indiscriminately for other sources. The explicit block-stamp convention still governs RTC labels and external marker matching; it does not move a same-stream photodiode edge.

`refused (gap N)` counts windows crossing detected discontinuities. Other refusal counters identify insufficient initial history, expired history, end-of-run truncation, refractory triggers, excluded codes, an unusable external timestamp, or a full pending queue. It is not an electrode-quality or amplitude-rejection count.

## Catch, zoom and map

Catch checks **each input sample**, not a decimated envelope slot. Require sufficient prehistory, collect post-trigger content, then rotate every ring at freeze so the event sits at the requested split without a wrap seam. Exactly one selected channel arms it; cancellation stays possible after selection changes. Run re-arms.

Zoom is one-shot, ignores small accidental drags, applies time span and only covered rows' amplitude overrides, then leaves manual scale. Cursor positions are fractions of the window, not pixels, so resizing preserves measurement points.

Discs and Field use the same circle/nose/ear contour, exposed by `TopoView::headOutline()` in units of head-circle radius. Their montage projections remain independent. Discs fitting includes both electrodes and the full contour, so a small central montage cannot crop the nose or ears at default zoom. Head positions use the stream's CED theta/radius convention. Fit to the widest electrode **including its disc**, not merely the nominal head circle. Electrodes past radius0.5 can be valid; unplaced channels remain visible in a labelled band rather than disappearing. No reading is hollow, not red or zero. Head and trace views share ChannelModel.

CED Number means **physical device input index**, before selection: electrode range, then AUX. It is not an output column. A64-electrode cap on NVX136 still numbers AUX at129 onward; a trigger word has no scalp position. Optional PNG background calibration (spread/centre) belongs to its exact image/montage pairing. Do not generalize historical0.739 calibration to arbitrary assets.

## UI and live connector constraints

Use serialized Stream values for QML gadget conversion, not assignment of an arbitrary JS object to desiredStream. Do not store function-valued JS properties in Repeater object models: QVariant conversion drops them. Numeric entries commit on Enter/focus loss; defer model refresh while editing. Only focused controls consume wheel edits.

Live stream arrows follow ready/disconnected/rerouted/reconnecting/clear via core notifications. Visible Parameters panels additionally refresh older service descriptions once/sec; hidden panels stop. Pending edits survive unchanged refresh and are cancelled when selection changes. Configurator Delete-to-terminate is opt-in and table-focus-only, not a global hotkey.

Shared row alignment, compact background metrics and constrained geometry rules are in [UI](../architecture/ui.md); preserve hit areas and avoid circular implicit-height bindings.

## Validation and evidence

**Open, reproduced 2026-09-18:** delayed/coalesced incremental redraw can leave
a thin false vertical spike in a flat trigger LOW. The same captured samples
render cleanly with a full repaint. See the [5 kHz diode-test reproduction,
binary identity and raw evidence](../history/investigations/diode-trigger-viewer-20260918.md).
No renderer fix was deployed by that diagnostic task.

Registered `test_ViewerReconnect` checks actual sample filtering and arrow colour across impedance↔EEG in once/keep policies, plus immediate trigger-lane discovery and painted high/low levels before a maintenance tick. `test_ConfiguratorLiveStatus` covers older-service refresh/edit isolation and service-table identity across stream removal/return. See [test workflow](../how-to/test.md) and the [2026-09-18 fix evidence](../history/changes/2026-09-18-configurator-tree-trigger.md).

**test_PlotMath is built but not registered with CTest** in current CMake; execute its built test binary explicitly after plotting math changes. It covers tick/range/hysteresis/decimation/scalp geometry. A green general CTest run alone does not cover it.

Old catch/head/headcolor/live-viewer scratch harnesses were not retained. [Historical rendering evidence](../history/components/signal-viewer.md#history-10-testing) states what they checked, not runnable commands. Current QA lives in [configurator-recovery-20260908](../../src/docs/qa/configurator-recovery-20260908). QML lint alone cannot establish runtime type registration or hit areas; load relevant UI during actual validation. No UI/build/test execution occurred in this documentation change.
