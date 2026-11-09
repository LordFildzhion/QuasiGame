# 13. Signal viewer defects found and fixed 2026-08-13

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-13-signal-viewer-defects-found-and-fixed-2026-08-13"></a>

### 13. Signal viewer defects found and fixed 2026-08-13

**TRANSFERS UNCHANGED — every fix crossed** with `quickStimulus` and the two NVX drivers
(`timeseriesreceiver.cpp`, `channelmodel.cpp`, `nvx\nvxdatathread.cpp`, `nvx136\nvx136driver.cpp`
are all in `R:\src`, with `kind = "Impedance"` published by both). ⚠ Three of the "Also worth
knowing" bullets are **QT 5 ONLY** — the anchored-item-inside-a-`SplitView` trap, the four-pixel
Controls 1 handle, and "a Controls 1 `SplitView` expands exactly one item". The Qt 6 Configurator
uses Controls 2 `SplitView` with its own handle and attachment semantics, and its default viewer
split was re-laid-out during the port. The MSVC narrow-literal trap, the `slots` keyword, the
`Connections`-`parent` trap and the detector lesson are version-independent.

Surfaced while reworking the display; full context in [signal-viewer.md](../components/signal-viewer.md).

<a id="history-13a-chebyshev-ii-low--and-high-pass-did-nothing"></a>

### 13a. Chebyshev II low- and high-pass did nothing

`timeseriesreceiver.cpp` passed `stopBandDb / samplingRate()` where `setupN` wants a stopband
attenuation **in dB** — 80/500 = 0.16 dB, i.e. no filtering. The band-stop call three lines below
passed it correctly, which is what made it obviously a slip rather than a misreading of the API.
Selecting Chebyshev II therefore silently disabled the low- and high-pass.

<a id="history-13b-one-nan-killed-a-channel-for-good"></a>

### 13b. One NaN killed a channel for good

The finite check on the filter input was commented out. A non-finite sample entering an IIR delay
line makes every subsequent output NaN for the life of the filter, so a single dropout took the
channel out until something happened to rebuild the filters. Reachable from
`signalGenerator`'s `fixedNaNMeander` mode and from NVX impedance mode, which emits `NAN` for
`INT_MAX`. Non-finite samples now pass through without entering the filter.

<a id="history-13c-the-amplitude-grid-could-hang-the-gui"></a>

### 13c. The amplitude grid could hang the GUI

`while (t < swimlane/2) { … t += s; }` with a fixed data-unit step and no minimum pixel spacing.
A small step against a large scale produced thousands of full-width strokes per row, and the label
overlay did a `measureText` + `fillText` for each. Tick generation now grows the step until
adjacent lines are at least 8–10 px apart, and refuses degenerate ranges instead of looping.
Regression-tested in `test_PlotMath`.

<a id="history-13d-colours-and-line-widths-were-indexed-by-screen-row"></a>

### 13d. Colours and line widths were indexed by screen row

`lineColor(ch)` was called with the *display row*, while the data came from
`buffer[visibleChannels[row]]`. Hiding one channel therefore recoloured every channel below it.
Per-channel appearance is now keyed by channel index.

<a id="history-13e-nvxdatathreadauxchannels-was-uninitialised-in-bipolar-mode"></a>

### 13e. `NVXDataThread::auxChannels` was uninitialised in bipolar mode

Set only in `initUnipolarMode`, never in `initBipolarMode`, and not in the constructor's
initialiser list. `getNextBlock()` reads it in both modes to decide whether a sample is scaled by
`eegScale` or `auxScale`, so bipolar acquisition scaled an indeterminate number of trailing
channels as AUX. Now has an in-class initialiser and is set explicitly in both modes.

<a id="history-13f-ced-montage-labels-were-handed-to-aux-and-trigger-channels"></a>

### 13f. CED montage labels were handed to AUX and trigger channels

`MetaData::addCEDinfo(ced, enabled)` distributes electrode labels across every enabled channel in
order, so on an NVX-52 the four AUX inputs and the trigger were named after whichever electrodes
fell at those positions — an AUX channel labelled `FCz`. The montage is now applied only to the
EEG channels; AUX and the trigger get their own names.

<a id="history-13g-centre-left-the-visible-window-off-centre-for-a-full-window-duration"></a>

### 13g. `Centre` left the visible window off-centre for a full window duration

`baselineChannels()` set each channel's baseline and stopped there, so the correction applied only
to samples that arrived *afterwards*. The stored buffer kept its old offset, and the trace stayed
visibly off its lane centre until the whole window had refilled — on a 10 s span, ten seconds of a
button that appeared not to work. `shiftStored()` now adds the same delta to every stored slot, so
the correction is visible on the frame it is asked for.

<a id="history-13h-the-measurement-cursors-were-anchored-to-pixels-not-to-time"></a>

### 13h. The measurement cursors were anchored to pixels, not to time

Cursor positions were stored as pixel offsets from the left of the window. Resizing the window slid
them off the samples they had been placed on, and narrowing it far enough pushed them outside the
plot entirely — a control that could be switched on and then lost. They are now fractions of the
time window, which keeps them on the same time point through any resize and on screen by
construction.

<a id="history-13i-the-incremental-strip-renderer-seamed-at-every-boundary"></a>

### 13i. The incremental strip renderer seamed at every boundary

Visible as breaks in a flat trigger line, and — after the first two fixes — as *half-drawn cycles*
on a dense waveform, which is the more damaging failure and the harder one to detect. Four
approaches, written up in
[signal-viewer.md §11](../components/signal-viewer.md#history-11-traps-this-rework-walked-into); the one that works
re-clears the boundary column before redrawing it and never extrapolates past the last real sample.

<a id="history-13j-both-nvx-drivers-described-impedance-channels-as-eeg-in-volts"></a>

### 13j. Both NVX drivers described impedance channels as EEG in volts

`nvx` published `kind = "EEG"`, `unit = "V"` for its impedance outputs, and `nvx136` published
`kind = "EEG"` with `unit = "Ohm"`. The unit was cosmetic; the *kind* was not. A viewer that
believes the channels are EEG puts them in the EEG group and applies the display filter chain, so
a 3–35 Hz band-pass ran over a DC level and removed the entire reading — the trace showed a
settling transient and then nothing.

Both now publish `kind = "Impedance"`, and `ChannelModel` carries a matching group default: 20 kOhm
full scale, step rendering, filters off. In `nvx136` the electrode test that lines the CED montage
up against the outputs had to stop being `kind == "EEG"` — impedance outputs are the same physical
electrodes — so it went through an `isElectrode()` helper.

<a id="history-13k-the-strip-renderer-cleared-one-slot-more-than-it-could-redraw"></a>

### 13k. The strip renderer cleared one slot more than it could redraw

A blank exactly one sample wide, travelling ahead of the write cursor. Slot *k* is plotted at
`k * xInc`, so the newest segment can only reach `to * xInc`; the strip was cleared to
`(to + 1) * xInc`, wiping a column that needed a sample which had not arrived. At 1 kHz a slot is a
fraction of a pixel and the gap is invisible; on a 1.25 Hz impedance stream a slot is twenty pixels
and it is the first thing you see.

The fix is the same principle as [§13i](37-signal-viewer-defects-found-and-fixed-2026-08-13.md#history-13i-the-incremental-strip-renderer-seamed-at-every-boundary):
**never extrapolate past the last real sample** — so clear only as far as the geometry reaches. The
next block extends the strip from exactly there, so the columns still tile, and until then that
column keeps the previous sweep's ink, which is what a sweep display is for. Verified afterwards on
a dense 2 Hz sine at 1 kHz: no gaps, no bulges through the cursor.

<a id="history-13l-and-then-cleared-one-column-too-few-on-a-full-repaint"></a>

### 13l. …and then cleared one column too few on a *full* repaint

The fix for [§13k](37-signal-viewer-defects-found-and-fixed-2026-08-13.md#history-13k-the-strip-renderer-cleared-one-slot-more-than-it-could-redraw) was right for
an incremental strip and wrong for a full one. A full repaint's region is the whole ring, so
stopping the clear at the last drawable point left the final slot's column holding whatever the old
settings had drawn — and on a two-slot window that column is *half the plot*. It showed up as dead
bands on the right after switching modes, each switch leaving another one.

The two cases are genuinely different and the code now says so. Incrementally there is a later
block coming to finish the join, and the previous sweep's ink is what should show meanwhile. On a
full repaint there is no later block and no ink worth keeping — a full repaint is asked for exactly
when what is on screen is wrong — so it clears the whole width.

The lesson is narrower than "never extrapolate": **the clear and the geometry may differ, and which
way they differ depends on whether anything will come along to finish the drawing.**

<a id="history-13m-the-last-slots-bin-was-never-drawn--the-real-dead-band"></a>

### 13m. The last slot's bin was never drawn — the real dead band

Two rounds were spent on the clear before looking at the geometry, and the clear was not the
problem. A slot is plotted at the **left edge** of the bin it covers, `s * xInc`, and the ink
between slots is the segment joining them — so the final slot has no successor and the rightmost
`xInc` of the plot is never covered at all.

At 1 kHz a bin is a twentieth of a pixel. On a **1.25 Hz impedance stream in a 3 s window there
are four bins**, and the uncovered one is a quarter of the display. That was the dead band, and it
was there before any of the clear changes.

The fix holds the last value across the bin it owns, gated on a bin at least two pixels wide so
that at ordinary rates the branch never runs and the dense-waveform path is bit-identical. This is
*not* the overshoot removed in [§13i](37-signal-viewer-defects-found-and-fixed-2026-08-13.md#history-13i-the-incremental-strip-renderer-seamed-at-every-boundary):
that invented a column for a sample which had not arrived; this covers the bin of a sample already
in hand, which is that sample's own time extent — and for a step trace it is simply what a step is.

**The lesson is about diagnosis, not rendering.** A blank region at the right edge has at least
three separate causes in this renderer — the clear overrunning, the clear stopping short, and the
last bin never being drawn — and they look identical. Measure which slot indices carry data and
where they land in pixels before changing any of them; "0 invalid slots of 3600" ruled out the
data and should have sent the search to the mapping immediately.

<a id="history-also-worth-knowing"></a>

### Also worth knowing

* **A pasted non-ASCII literal is not portable through MSVC.** `QStringLiteral("Ω")` in a UTF-8
  file without a BOM compiles to mojibake — MSVC reads narrow literals in the machine's ANSI
  codepage — and reached the screen as `kO©`. `QChar(0x03A9)` carries no encoding. QML files are
  unaffected: the engine reads them as UTF-8 at runtime, which is why `±`, `↑` and `≤` work there.
* **`slots` is a Qt keyword.** A parameter named `slots` expands to nothing, so `if (slots > 0)`
  becomes a syntax error pointing at the `>`. Cost one build round-trip.
* **Inside `Connections`, `parent` is the `Connections` object.** `function onXChanged() {
  parent.requestPaint() }` therefore threw *"Property 'requestPaint' of object QQuickRootItem is
  not a function"* on every emission, silently doing nothing. Reference the target by `id`.
* **An anchored item inside a `SplitView` cannot be resized by it.** `ParametersView` carried
  `anchors.top: servicesList.bottom` and `anchors.bottom: parent.bottom`, which drives its
  geometry directly; the split's own sizing never reached it, so the divider above could be
  dragged and nothing moved. No warning, and it looks like a layout that works. Also worth
  knowing that the stock handle is about four unmarked pixels — findable only if you know it is
  there, which is most of why it read as immovable.
* **A Controls 1 `SplitView` expands exactly one item.** With `Layout.fillWidth: true` on both
  children, switching the split from vertical to horizontal collapsed the second viewer to its
  minimum width instead of sharing the space. Only one item should carry the fill policy; the rest
  get a preferred size. An even split on a change of orientation has to be assigned imperatively
  in `onOrientationChanged`, not bound — SplitView writes the item's size directly while its
  divider is dragged, so a binding snaps the divider back on the next window resize.
* **A detector only finds the artifact it was written for.** The ink-sum measurement that proved
  the flat-line seams were gone reported zero problems on a picture full of truncated sine cycles,
  because the missing geometry was mid-slope rather than at the peak. Two consecutive "0 findings"
  results on an artifact that is plainly visible mean the detector is wrong, not the picture.
* **`qmllint` does not resolve types.** It passed a file whose `property alias x: item.Layout.foo`
  is illegal (an attached property is not a valid alias target); that only appeared as
  *"Invalid alias target location"* when the QML was actually loaded. Launch it before believing
  a lint pass.
* **A static `Q_INVOKABLE` is not callable from QML** on the registered type. It has to be a
  normal member called on an instance.

---

