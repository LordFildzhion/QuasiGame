# 2026-08-15 — Viewer ergonomics: catch loses its panel, zoom gains one, head map takes a picture

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-15--viewer-ergonomics-catch-loses-its-panel-zoom-gains-one-head-map-takes-a-picture"></a>

### 2026-08-15 — Viewer ergonomics: catch loses its panel, zoom gains one, head map takes a picture

**Catch has no settings panel at all now.** The source is whatever single channel is selected —
the toolbar button only arms with exactly one selected, and re-targets as the selection moves — the
level is the draggable line, and the edge cycles rising/falling/either on **double-clicking that
line**, where the direction is actually visible. The split either side of the crossing is fixed at
half: it was settable and earned nothing, since wanting more lead-in means wanting a longer window
and the time range already does that. Four controls and a combo box became zero.

**Zoom** is a rubber band: drag a rectangle, its width becomes the time range and, within every
row it overlaps, the covered band becomes that channel's amplitude scale. Per row, not per group —
a rectangle over one trace means that trace. One rectangle per arming, because a mode that stays
on turns every later click into a zoom; a drag under ~6 px is ignored; the resulting span is shown
while dragging.

**The head map takes a background picture**, set per viewer through the Configurator's `head image`
parameter. Alignment is the whole problem and is solved by construction: the picture is scaled and
offset so that *its own head circle* lands on the drawn outline, described by three numbers about
the image (head centre x/y and radius, as fractions of the picture). The old display bridged the
same gap with a `/1750` factor and a 30-pixel offset and was correct at one window size for one
image. `HeadView.backdropInfo()` exposes the projected radii so this is asserted rather than
eyeballed — ratio 1.000000 and centres coincident to a millionth of a pixel, at 1200x800 and again
at 820x640.

**Verified:** 16 behavioural checks pass (catch follows the selection, edge cycles through all
three, the zoom rectangle produces exactly the range/centre/span computed from it, a stray click
does nothing, the picture stays aligned across a resize), plus 27 `test_PlotMath` cases.
[signal-viewer.md §7a–7b](../components/signal-viewer.md).

**Follow-up, same day.** The head picture became *one* pair of parameters for the whole
application — `head_image` and `head_scale`, at the bottom of the plot tab — rather than one per
viewer, and the geometry was inverted: the picture is now the reference, fitted to the panel and
left alone, and a single **spread** number moves the electrodes onto it. Describing the picture's
own circle was exact but asked for measurements nobody has; one number somebody drags until it
looks right is the thing they can actually do. Over a picture the drawn circle, nose and ears are
suppressed unless the alignment circle is asked for.

For `topomap64_full_s.png` + `mks64_standard.ced` the number is **0.739**, measured from the
picture rather than guessed — T7/T8 are 1378 px apart and Fpz/Oz 1380 px, both CED radius 0.53318,
giving 1293 px per unit radius on a 1750 px image from two independent axes.

**Verified on the live NVX136 in impedance mode** (66 ch, already running — attached read-only,
nothing about the device touched): T7, T8, Fpz and Oz land 337.3 px from centre where the picture
puts them at 337.0. Typing the spread into viewer 1's panel updated the shared parameter and
realigned viewer 2, so the round trip holds. The driver fix from earlier today is live on hardware:
the stream declares `kind = "Impedance"`, `unit = "Ohm"`, and the viewer groups it unfiltered at
20 kOhm with the legend in kOhm.

Also: the **Services / Parameters divider is draggable** — it never was, because `ParametersView`
was anchored inside the SplitView, which drives geometry directly and leaves the split's sizing
with nothing to do. And the lab montages and topomap pictures, which existed only in the 2025
deployment and were never committed, are now in `import/Resonance/Bricks/` in source.

**Calibration defaults and backgrounds (same day).** The three head-picture numbers — spread and
centre x/y — are now shared Configurator parameters with a 0.005 step and four decimals, defaulting
to the measured `topomap64_full_s.png` figures (0.739 / 0.5006 / 0.4690), so the shipped picture
and the shipped montage line up on connect with nothing to adjust. Disc size takes one decimal and
steps by 0.5 %.

Both views also take a **background from nine greys, white to black**, set separately for the
traces and for the map. The text is derived from it rather than fixed: a light grey legend is
invisible on white, so both compute a luminance and pick their ink from it — which is the
difference between a background that is selectable and one that is merely settable. The map
defaults to white where the traces default to black, because the shipped topomaps are black ink on
a transparent ground and on a black panel they load correctly and draw nothing visible.

⚠ **The dead band on the right: the last slot's bin was never drawn.** A slot is plotted at the
left edge of the bin it covers and the ink between slots is the joining segment, so the final slot
has no successor and the rightmost `xInc` is never painted. At 1 kHz that is a twentieth of a
pixel; on a 1.25 Hz impedance stream in a 3 s window it is **a quarter of the display**. The last
value is now held across its own bin, gated on a bin at least two pixels wide so the dense-waveform
path is bit-identical. Two earlier rounds went to the *clear* instead and were wrong about the
cause — one of them a regression of its own, also fixed.
[known-issues §13l–13m](../incidents/README.md).

**A change of time range now carries the buffer across** instead of rebuilding from empty. Slot ages
convert between the two rings by the ratio of their slot durations — coarser merges min/max so a
spike survives, finer leaves the unfillable slots NaN rather than padding them. Verified on the live
impedance stream: 20 s filled → shrink to 8 s keeps **50/50** coverage where it used to start from
nothing, and growing to 40 s keeps exactly the span it had. This is also what removed the blank
stretch behind the write cursor after a settings change. An amplitude change never needed it — the
data is untouched and `scalesChanged` already forced a full repaint.

**GND is in the Impedance group**, not one of its own: same measurement, same units, so it reads
against the same scale and thresholds. It still takes no montage entry, and that is now an explicit
`montage` flag on the output rather than something inferred from its kind — conflating "which group
does this belong to" with "does this take a montage row" is what put a montage row on the wrong
channel in the first place.

**Ohm is written Ω** in the viewer — display only, so the stream and any recording keep the ASCII
name the driver published. `kOhm` never fitted a gutter three characters wide.

**± / + per group.** The sign beside a fixed scale is a button now: **+** runs the lane from zero at
the bottom to the value at the top, which is what an impedance or any other one-sided quantity
wants — a symmetric lane spends half its height on a region the signal never visits. Verified on the
live impedance stream: zero at the lane bottom, full scale at the top, twice the pixels per ohm.

**CED numbering settled.** A `Number` is the device's input index, electrodes first and AUX
immediately after — 49–52 on a 48+4 NVX, 129–136 on a 128+8 NVX136 — and AUX now takes a montage
entry so an EMG pair can be positioned. Past the electrode count so the two cannot collide, which
is what put `EMG1`/`EMG2`/`TRIG` onto electrodes 65/66/67 in impedance mode. `mks128_standard.ced`
already followed this; `mks64_standard.ced` was renumbered to match and its `TRIG` row dropped.
Both drivers changed. [signal-viewer.md](../components/signal-viewer.md).

**Amplitude axis and scale bar.** When one lane fills the plot — stacked, or one row — gridlines
go from 10 px spacing to 45 and get numbers down the left with the unit at the top; in a
multichannel layout neither appears, because sixty lanes of tick labels is noise. A **scale bar**
(Display → Scale bar) gives a known length to compare deflections against in any layout, rounded
to a value people quote — 10 uV, 50 uV, 1 mV — with the bar's height following rather than a tidy
bar labelled 13.7 uV. **Stack** is a toolbar button beside Fit now, and `K`.

⚠ **The resize clipping had a second, larger cause** that a single-window test could not see: a
`SplitView` expands exactly one item, and with the *first* viewer expanding, narrowing the window
pushed the second pane's right-hand edge off the screen. The map centres on its pane, so half of it
was outside the window and looked clipped, and widening never grew it at all. Viewer 2 now carries
the fill policy, viewer 1 a preferred size, `HeadView` clips to its own bounds, and the legend
scales down instead of spilling across the neighbour. Verified in the real Configurator with
`config/configurator_test_impedanceView.json` at 1400 / 1100 / 980 / 920 px.

Also: off-montage channels moved *into* the map's empty lower band, bottom-left, instead of a
reserved strip that shrank the head. And **GND is ticked by default when the NVX136 enters
impedance mode** — the SDK measures every electrode against it, so a sweep without it is
meaningless, and it was a step to forget.

Two more fixes from using it: **the map no longer clips when the window is resized** — the picture
was fitted to the panel but a montage runs past the ear-level circle (TP9/TP10 at 0.66, EMG at
0.74), so at spread 0.739 the outermost electrode sits at 0.55 of the picture's width and hung
outside; the picture is now shrunk by whatever factor makes the widest electrode, disc included,
land inside. And **channels the montage does not place get a strip along the bottom** rather than
being dropped, labelled with the driver's name or `#72`, so the map stops quietly showing fewer
channels than the amplifier is sending. The legend is at twice its old size.

