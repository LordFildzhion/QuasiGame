# 2026-08-13 session — signal viewer rework, built and verified

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-13-session--signal-viewer-rework-built-and-verified"></a>

### 2026-08-13 session — signal viewer rework, built and verified

Full reference: **[signal-viewer.md](../components/signal-viewer.md)**. Defects fixed:
[known-issues §13](../incidents/37-signal-viewer-defects-found-and-fixed-2026-08-13.md#history-13-signal-viewer-defects-found-and-fixed-2026-08-13).

The multichannel display was rebuilt around a **per-channel/per-group model**, which is what
unblocked everything else: range selection, independent colours and widths, per-group scales,
configurable autoscale and bitwise triggers were all previously impossible because the viewer had
exactly one scale, one colour list indexed by *screen row*, and no notion of what a channel was.

| Area | Change |
|---|---|
| ✚ New files | `quickStimulus/channelmodel.{hpp,cpp}`, `plotmath.{hpp,cpp}`, `tests/plotmath_test.cpp`; QML `Plot/{ChannelPanel,PlotSettings,NumberField}.qml` |
| Rewritten | `timeseriesreceiver.{hpp,cpp}`, `Plot/PlotView.qml`, `Plot/Settings.qml`, `StreamView.qml` |
| Drivers | `nvx/nvxdatathread.{h,cpp}`, `nvx136/nvx136driver.cpp` — publish per-channel `kind`/`unit` metadata |
| Qt 6 | The viewer is now **Qt Quick Controls 2 only**. It was the largest Controls 1 holdout. |

**Follow-up pass (same day)** after operator feedback: autoscale now notifies its views (the trace
was rescaling while every label kept the old number, which reads exactly like an autoscale that
cannot be switched off) and shrinks only after five steady seconds; SI prefixes are derived from
the scale rather than chosen, so AUX reads 49.6 mV and EEG 100 uV; Space toggles the ticks on the
selected channels as in the NVX dialogs and Freeze moved to P; the setup panel opens at the
pointer; the whole UI was re-densified; and the stream connector got its hit area back — it had
been sizing itself from a circular binding, so it painted but could not be clicked or dropped
onto. Traps in [signal-viewer.md §11](../components/signal-viewer.md#history-11-traps-this-rework-walked-into).

**Second follow-up** after a further round of operator feedback, this time verified by driving the
UI rather than only reading logs. The stream connector inside a viewer could be hovered but not
clicked or dropped onto — it was assigning a JS object to a `StreamInfo` property, which QML
discards silently. The channel panel's buttons were all dead for the mirror-image reason: their
actions were function values in a Repeater model, and that conversion drops functions. `Fit` on a
disconnected electrode collapsed the scale to **femtovolts**, and applied one group-wide centre to
channels with different DC offsets. Also: measurement now reports per-lane peak-to-peak (and
min/max/mean/RMS) rather than only an interval, the amplitude field steps the 1-2-5 ladder so a
fixed scale reaches from 10 uV to 50 V, Ctrl+A selects all, the time ruler lives inside the plot
column so it can no longer point at the wrong place, and the whole UI was rebuilt against
compact backgrounds — Controls 2 floors every control at 100x40 px through its *background*, which
no amount of font and padding tuning overrides.

**Third follow-up.** Movable channel gutter, `TrigN` lane names, measurement cursors anchored to
*time* rather than to pixels (a resize could previously push them out of existence), and two
rendering defects that only a specific signal reveals. The strip-boundary seam took four attempts:
a gap on flat lines, then bulges, then — from overshooting the last pixel by holding the previous
`y` — half-drawn cycles on a dense sine, which is far worse because most of a real recording is
waves. What ships re-clears the boundary column before redrawing it and extrapolates nothing.
Separately, `Centre` only shifted *newly arriving* samples, so the visible window stayed off-centre
for a full window duration; it now shifts what is already stored.

**New: catch — auto-pause on a level.** An oscilloscope trigger for a scrolling viewer. Arm it on a
channel, a level and an edge, and on the crossing the viewer keeps acquiring until the window holds
the run-up *and* the aftermath, then freezes with the event where you asked for it — 2 s span, one
second either side. The level is a draggable line on the plot as well as a number in Setup. Named
*catch* because these streams already carry trigger channels. Verified against the data rather than
a screenshot: mark position 0.5000 against 0.5 requested, and the sample read back out from under
the marker is the level, crossing the right way. See
[signal-viewer.md §7a](../components/signal-viewer.md#history-7a-catch--auto-pause-on-a-level).

**Measured:** full repaint of 70 channels at 25 kHz went from **202 ms to 22.6 ms**; 53 channels
at 1 kHz repaint in 1.7 ms. Input is stored as a min/max envelope decimated to ≤16384 slots, so
cost no longer follows the sampling rate and spikes are still visible.

**Verified on hardware.** Against a live NVX-52: 48 EEG at ±100 µV, 4 AUX autoscaled in volts and
the trigger as bit lanes, all readable at once — the case a single global scale could not show.
Also exercised against `signalGenerator` at 70 ch / 25 kHz, with NaN meander, and with a
bit-toggling source. `test_PlotMath` is 20/20.

⚠ `mingw32` / `mingw64` remain behind `msvc64`, now by this work as well.

