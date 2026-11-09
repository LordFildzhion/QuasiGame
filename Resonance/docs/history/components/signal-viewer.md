# The signal viewer — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/signal-viewer.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-the-signal-viewer"></a>


**Reworked 2026-08-13.** The multichannel time-series display used by the Configurator (two
instances, "Signal viewer" and "Signal viewer 2"), by `testApp/live_connection.qml` and by any
experiment that imports `Resonance.Plot`.

> **Ported to Qt 6, and shipping as the default** — inside `R:\dist\bin\quickStimulus.exe`,
> built from `R:\src` against Qt 6.11.2 / MSVC v143 14.44 / C++20. The Qt 5.15.2 build survives as
> the comparator in `R:\dist_Qt5\msvc64`. **This file is the one that cost the port almost
> nothing** — see the note under §1. Everything below is component-level and reads the same
> in both generations. Background: [qt5-to-qt6-transition.md](../migrations/qt5-to-qt6-transition.md).

---


<a id="history-2026-09-08-impedance---eeg-recovery-and-live-connectors"></a>

## 2026-09-08: impedance -> EEG recovery and live connectors

An electrode name alone is not enough to restore its display state: NVX136 uses the same names
for impedance (Ohm, 1.25 Hz) and EEG (V, normal acquisition rate). Previously the impedance
channel's automatically seeded filter bypass, step rendering and per-channel scale survived the
reroute into EEG. The filter controls and filter construction were working; ingestion skipped the
chain because the remembered channel was bypassed. `ChannelModel` now caches state by electrode
name and source kind, preserving each mode's settings separately. A saved channel entry also
carries `sourceKind`; older entries fall back to their saved group.

The common Stream connector's green/grey arrow now follows ready, disconnected, reconnecting,
rerouted and cleared inputs. `Core/Resonance/Parameters/stream.cpp` broadcasts these attributes
through `triggerUpdate` as well as notifying local QML, so selecting the service again is no
longer required. Both once and keep policies are covered by the real EventBus/QML regression test
`quickStimulus/tests/viewer_reconnect_test.cpp`, including the rendered arrow colour. It also
checks filtered sample values after two impedance/EEG round trips and retention of manual EEG
overrides. Build and deployed-runtime results are in `src/docs/qa/configurator-recovery-20260908`.

<a id="history-separately-packaged-services-and-configurator-delete-2026-09-08-follow-up"></a>

### Separately packaged services and Configurator Delete (2026-09-08 follow-up)

The core notification fix above only reaches services that load the updated library. Navigator's
private package still contained an older core and reproduced a green arrow after generator STOP.
The displayed Parameters panel now refreshes stream-bearing descriptions once per second, so an
older service's correct on-request status is reflected without selecting it again. Hidden or
minimized panels stop polling. The refresh neither resets unchanged editor values nor overwrites
an edit waiting to be sent; changing the selected service cancels that pending send.

Configurator's Settings menu also has **Delete terminates selected service**, remembered and off
by default. Enable it to send System > terminate with plain Delete while a service row is selected
and the service table has focus in the active Configurator window. It is not a global hotkey.
Stream rows, parameter editors, inactive windows, modifier keys and held-key repeats are excluded.


<a id="history-1-layout"></a>

## 1. Layout

```
Configurator.qml ─► StreamView.qml ─► PlotView.qml ──┬─ toolbar (Pane)
   (2 instances)     (connector +      (assembly)    ├─ channel gutter  ┐ same rows,
                      viewer +                       ├─ TimeSeriesReceiver ┘ by construction
                      message log)                   ├─ overlay: cursors, hover readout
                                                     ├─ vertical scrollbar (paging)
                                                     ├─ time ruler
                                                     ├─ event lane (decoded triggers)
                                                     ├─ ChannelPanel.qml  (selection, colours)
                                                     └─ PlotSettings.qml  (filters, groups)
```

| File | Contents |
|---|---|
| `quickStimulus/timeseriesreceiver.{hpp,cpp}` | Data path and renderer. Envelope ring buffer, filter chain, paging, painting. |
| `quickStimulus/channelmodel.{hpp,cpp}` | Per-channel and per-group state, as a `QAbstractListModel`. Selection lives here. |
| `quickStimulus/plotmath.{hpp,cpp}` | Axis ticks, robust range, decimation arithmetic. No Qt Quick — unit tested. |
| `quickStimulus/tests/plotmath_test.cpp` | 39 gtest cases. Target `test_PlotMath`. |
| `import/Resonance/Plot/PlotView.qml` | The assembly and the keyboard/mouse bindings. |
| `import/Resonance/Plot/ChannelPanel.qml` | Channel list, range selection, bulk edits. |
| `import/Resonance/Plot/PlotSettings.qml` | Filters, reference, per-group scales. |
| `import/Resonance/Plot/NumberField.qml` | Decimal entry. Controls 2 `SpinBox` is integer-only. |
| `import/Resonance/Plot/Settings.qml` | What persists, as JSON in a service parameter. |

**Qt Quick Controls 2 throughout.** The previous version mixed Controls 1 and 2; Controls 1 does
not exist in Qt 6, and this file was the largest single blocker to that migration.

**The migration happened on 2026-08/09, and the viewer walked across.** That is the return on the
2026-08-13 rework, and it is measurable: of the nine rows in the table above, seven are
**byte-identical** in `R:\src` and `R:\src_Qt5`. The whole cost of porting the viewer was

| file | what changed |
|---|---|
| `timeseriesreceiver.hpp` `.cpp` | `geometryChanged()` → Qt 6's `geometryChange()`, and four `static_cast<int>` on `size()` calls that now return `qsizetype` |
| `Plot/PlotView.qml` | one `Repeater` model clamped with `Math.max(0, …)`: during the first layout pass the pane can report a negative available width, and Qt 6's `Repeater` rejects a negative integer model |

— and nothing else. `ChannelPanel.qml`, `PlotSettings.qml`, `NumberField.qml`, `Settings.qml`,
`StreamView.qml`, `channelmodel.{hpp,cpp}`, `plotmath.{hpp,cpp}` and `tests/plotmath_test.cpp` did
not change a character. By contrast `Configurator.qml` and the Configurator's embedded
`recorder.qml` had to be reimplemented, because both still imported Qt Quick Controls 1
([architecture.md §9a](../migrations/framework-evolution.md); `R:\src\docs\PORTING_LOG.md`).

---


<a id="history-3-groups-one-stream-several-kinds-of-signal"></a>

## 3. Groups: one stream, several kinds of signal

An NVX stream carries EEG at ~1e-5 V, AUX at a few volts and a raw integer trigger, all in one
`Float64` block. A single amplitude scale can show exactly one of them.

A **group** carries the scale, the display unit and the filter policy for every channel in it.
Groups are derived in this order:

1. **Stream metadata** — `MetaData::channelProperty("kind")` and `("unit")`. `MetaData` is a
   free-form `QHash<QString, QList<QVariant>>`, so publishing these needed no framework change.
   `nvx` and `nvx136` now do (`NVXDataThread::describeChannels`, `Nvx136Driver::initializeEeg`).
2. **Channel-name heuristics** — `trig|marker|event|ttl`, `^aux|adc|ain|acc|photo`, `emg`, `ecg`,
   `eog`. A bare number stays in `default` rather than being guessed as EEG, because guessing EEG
   has consequences (a 3 Hz highpass).
3. **By hand** — select channels, type a group name.

Defaults per group, applied on connect:

| Group | Unit | Half-range | Scale | Filtered | Drawn as |
|---|---|---|---|---|---|
| EEG | µV (1e-6) | 100 | manual | yes | line |
| EMG | mV (1e-3) | 1 | manual | yes | line |
| ECG | mV | 2 | manual | yes | line |
| EOG | µV | 200 | manual | yes | line |
| AUX | V | 5 | **auto** | no | line |
| Trigger | — | 8 | manual | **no** | **bits** |
| default | — | 1 | **auto** | yes | line |

Verified against a live NVX-52: 48 EEG at ±100 µV, 4 AUX autoscaled in millivolts, 1 trigger as
bit lanes, all legible at once.

<a id="history-the-si-prefix-is-derived-never-chosen"></a>

### The SI prefix is derived, never chosen

A group carries a **base** unit — `V`, `Ohm`, or nothing — and its range is stored in base units.
The prefix comes from the magnitude, via `ChannelModel::siExponent()`, so the number shown always
lands in [1, 1000): a 1e-4 V scale reads **100 uV**, not 0.1 mV, and an AUX channel that autoscales
to 0.0496 V reads **49.6 mV**. People compare tick numbers, and a number below one is harder to
compare at a glance than a changed prefix.

There is no multiplier control. Type a number, pick the quantity, and the prefix follows.

The scale field's arrows step the **1-2-5 ladder** rather than by a fixed amount, so one control
spans the whole range: 100 uV → 200 → 500 → 1 mV → … → 50 V, with the prefix re-derived at each
step. A fixed increment is either far too coarse at 10 uV or far too fine at 50 V, which is what
made the fixed scale unusable outside EEG. Typing a large number works too — 5000 in mV becomes
5 V.

<a id="history--or-"></a>

### ± or +

The sign beside a fixed scale is a button. **±** runs the lane symmetrically about its centre;
**+** runs it from zero at the bottom to the value at the top. A quantity that cannot go negative —
an impedance, a resistance, a rectified envelope — spends half a symmetric lane on a region it
never visits and reads at half the resolution it could, and zero belongs at the bottom where a
reader expects it. Per group, and it round-trips through the saved state.

<a id="history-centres-are-per-channel-ranges-are-per-group"></a>

### Centres are per channel, ranges are per group

Range is shared across a group so deflections stay comparable between electrodes. The **centre is
not**: every channel sits on its own DC offset, and a group-wide centre parks any channel whose
offset differs from the measured one at the edge of its lane. `Fit` therefore writes a shared
range and a per-channel centre; `Centre` zero-means the data and clears both.

<a id="history-flat-has-to-be-relative"></a>

### "Flat" has to be relative

A disconnected electrode parked at 11 uV still wanders by a few femtovolts of quantisation noise.
Taking that literally scaled a lane to femtovolts and filled it with amplified nothing, so
`robustRange()` treats a span more than a million times below the signal's own level as flat.
`Fit` also rounds up the 1-2-5 ladder, so it lands on a scale a person would have typed.

<a id="history-autoscale-and-how-to-stop-it"></a>

### Autoscale, and how to stop it

`updateAutoScales()` runs once a second and is **asymmetric**: a larger range is taken immediately
(a clipped trace is useless), a smaller one only after it has held for five consecutive seconds.
Symmetric hysteresis is what makes an autoscaled display pump on every burst.

Two things it must do, and originally did not:

* **Tell the views.** `ChannelModel::notifyScalesChanged()` re-emits the affected roles. Without
  it the trace rescaled while the gutter's "±100 uV", the gridline spacing and the settings panel
  all kept reporting the previous scale — which is indistinguishable from an autoscale that cannot
  be switched off.
* **Report what it is actually on.** `groupList()` returns the live range for an autoscaled group,
  not the fixed value it would fall back to.

To stop it: set the group to *Fixed* in the setup panel, or press **Fit**, which does both.

---


<a id="history-4-storage-a-minmax-envelope-decimated-on-the-way-in"></a>

## 4. Storage: a min/max envelope, decimated on the way in

`m_min[ch]` and `m_max[ch]` hold the smallest and largest sample that fell into each slot.
Storing both is what lets a decimated buffer still show a spike — dropping samples would not.

```
decimation = ceil(samplingRate * duration / 16384), at least 1
slots      = ceil(samplingRate * duration / decimation)
```

At 250–1000 Hz the decimation is 1 and every sample is stored untouched. At 25 kHz over 3 s it is
5, and the toolbar shows `÷5` with a tooltip explaining what was traded. Cost stops following the
sampling rate: ~70 channels occupy about 9 MB whatever the rate.

**Slots, not samples, are the dirty unit.** Dirty tracking is a *count* of slots written since the
last repaint; the one or two strips to repaint are derived from the write position at paint time.
An incremental range accumulated as data arrives is one off-by-one away from a column of stale
pixels that never repaints.

---


<a id="history-5-painting"></a>

## 5. Painting

One image, painted by one object: background, grid and traces together, in the same strip. The
grid used to be a separate QML `Canvas` underneath, which forced the trace layer to be transparent
and let the two disagree about row height.

Per pixel column, the envelope becomes at most two points. Three things keep it affordable:

| | Effect |
|---|---|
| One column per pixel | At 25 kHz there are tens of slots behind each pixel; each does not need its own segment. |
| Sub-pixel spans collapse to one point | An envelope thinner than 0.8 px says the same thing with half the geometry. |
| Antialiasing off below a 24 px lane | Costs ~4x and buys nothing once a lane is a few pixels tall. |

**A change of time range carries the buffer across.** Both rings are uniform in time, so a slot's
age converts between them by the ratio of their slot durations: going coarser, several old slots
merge into one new one and their min/max combine, so a spike survives; going finer, the slots the
old data cannot fill stay NaN rather than being padded with a value nobody measured. Rebuilding
from empty instead meant the old picture was replaced one sample at a time as the sweep came round
— a flicker at 1 kHz, several blank seconds on a 1.25 Hz impedance stream, and the reason there was
an empty stretch sitting behind the write cursor after every settings change.

An **amplitude** change needs none of that: the data is untouched, so `scalesChanged` forces a full
repaint and the whole window redraws at the new scale at once.

**Measured, 70 channels at 25 kHz, full repaint of every row:** 202 ms before, **22.6 ms** after.
Full repaints only happen on a settings change; incremental strips are far cheaper (1.7 ms for 53
rows at 1 kHz). The toolbar shows the last full-repaint time and warns above ~33 ms.

---


<a id="history-6-filters"></a>

## 6. Filters

Chain per channel: highpass → lowpass → notch (plus harmonics). Concrete stages behind one virtual
call each, not nested `std::function`s — the old chain copied a whole filter object into every
closure, so rebuilding it for 70 channels moved megabytes.

* **A channel drawn as bits is never filtered**, whatever group it is in. Band-passing an integer
  word destroys the levels the bits are read from.
* **Non-finite samples pass through without entering the delay line.** One NaN used to poison an
  IIR channel permanently. Verified against `signalGenerator`'s `fixedNaNMeander`: 40% finite
  early, 50% finite 30 s later, where the old behaviour pinned it at 0% for good.
* **New filters are primed at the channel's last value**, so changing a corner frequency does not
  fire a step response the size of the DC level through the display.
* Order is capped at 16 with a warning above 8, and the cascade is `Iir::DirectFormI`.
* Notch harmonics (1–5) — mains hum on EMG is rarely only at the fundamental.

Changing a filter does **not** retroactively refilter what is on screen; the buffer holds filtered
data and refills over one window. The transient is what priming removes, not the refill.

---


<a id="history-7a-catch--auto-pause-on-a-level"></a>

## 7a. Catch — auto-pause on a level

An oscilloscope trigger, adapted to a scrolling viewer. The problem it solves is that on a live
display the interesting moment is already gone by the time a hand reaches **Hold**; the answer is
to acquire *around* the crossing rather than up to it.

Armed with a source channel, a level, an edge and a position, the viewer watches that one channel.
On the crossing it keeps acquiring — it does not stop there — until the window holds the requested
fraction in front of the event and the rest behind it, and only then freezes. A 2 s span at the
default 50% stops with one second of lead-in and one second of what followed.

**The level is tested per sample, not per slot.** At 25 kHz a slot spans many samples, so a
crossing resolved to the slot envelope would land up to a whole pixel late.

**The ring is rotated at the freeze.** This is the part that is not obvious. A slot's place on
screen is its place in the ring — the display sweeps and wraps, it does not scroll — so stopping
the right number of slots after the crossing captures both sides but leaves the crossing wherever
its slot happened to fall, with the write seam cutting the trace somewhere else. `alignCatchWindow`
rotates every channel's buffer so the window reads left to right, seamless, with the crossing at
the position that was asked for. One pass over the buffer, once, at the moment everything stops.
Writing then resumes at slot 0, which is where the oldest data now lives.

**It will not fire until the run-up exists.** Below `pre × slots` written since the buffer was
built, the test is skipped and only the comparison value is carried forward. Firing earlier
freezes on a window whose left-hand half was never acquired, which reads as a fault rather than as
a catch.

**It has no panel.** Everything is on the plot or implied by what is already selected, which is
the whole of its interface:

| | |
|---|---|
| Source | the selected channel. The toolbar button only arms with **exactly one** channel selected, and while armed it re-targets as the selection moves — so choosing what to catch on is the click you were making anyway. Switching it *off* is always allowed, or a stray click in the channel list would strand an armed catch with no way to cancel it |
| Level | the draggable amber line, drawn only across the row it applies to — a line spanning every lane would read as a threshold on all of them |
| Edge | **double-click the level line** to cycle rising → falling → either. The arrow on the line shows which is in force |
| Split | fixed at half. It was settable and earned nothing: wanting more lead-in means wanting a longer window, which the time range already does |

When the source is scrolled off the page, or the level is off that row's scale, the plot says so
rather than showing nothing.

`Run` re-arms, so it doubles as the oscilloscope's *single*. The level and edge persist; the armed
state deliberately does not — reopening a saved viewer into a display that pauses itself a second
later, for a reason recorded in a file nobody has looked at, is not a state worth restoring.

Named *catch* rather than *trigger* because these streams already carry trigger channels, and one
word meaning two things in the same window is worse than a slightly unusual one.

---


<a id="history-7b-the-head-map"></a>

## 7b. The head map

The same channels arranged on the scalp instead of on a time axis, switched with **Head** in the
toolbar or **H**. Built for impedance checking, which is the job a montage-shaped display is
really for: the question is *which* electrodes are bad, and a column of 64 numbers does not answer
it while a picture of a head does.

Positions come from the stream's own CED metadata — `theta` and `radius`, already published by any
driver given a `.ced` file — so nothing has to be configured in the viewer and the map follows
whatever montage the amplifier was started with. The toolbar button is disabled, with an
explanation, when the stream carries no positions.

**The head is drawn, not photographed.** The version this replaces laid electrodes over a bitmap
and carried a `/1750` scale factor and a 30-pixel offset to make the two line up, so positions
were right only at one window size and only for that image. The outline is now drawn from the same
polar convention as the electrodes, in `PlotMath::scalpPoint`, and the two agree by construction.
Six unit tests pin it down (Cz at the vertex, Fz up, C3 left, C4 right, Pz behind, P7/P8
mirrored), because an error here puts every electrode somewhere plausible but wrong — the map
still looks like a head.

**Fitted to the montage, not to the outline.** Electrodes below ear level — TP9, TP10 — have a
CED radius past 0.5 and belong outside the circle; `mks64_standard.ced` runs out to 0.742.
Fitting to the outline hung those electrodes off the widget.

**Discs are sized from the montage** unless a size is set by hand: room per electrode goes as
1/√count, so what suits 12 electrodes overlaps badly at 128.

**Channels the montage does not place are drawn in the empty band the head leaves below the
occipital row**, bottom-left, in the same colours and carrying the same readings — labelled with
the driver's own name where it has one and `#72` where it does not. A `.ced` describes electrodes
and a recording rarely stops there; dropping the rest left the map quietly showing fewer channels
than the amplifier was sending, which is the wrong way for a display to disagree with its stream.
Inside the map rather than in a reserved strip below it: a strip buys the same result by making the
head smaller, which is the wrong trade on a panel whose whole job is the head.

| | |
|---|---|
| Colour | four configurable thresholds in the channel's own displayed units, plus a fifth state |
| No reading | drawn **hollow**, not as the worst colour. An impedance the amplifier could not measure arrives as NaN, and painting that red would be a guess — an unconnected electrode must not be mistakable for a measured bad one |
| Value | averaged over a settable window, 1 s by default. The device reports a fresh figure a few times a second and consecutive readings differ by a kilohm or two |
| Click | selects the channel through the same `ChannelModel` as the trace view, so selection, colours and groups stay in step rather than being a parallel copy |

Names and readings both sit **inside** the disc. Outside, one electrode's label lands on its
neighbour's disc as soon as the montage gets dense — on a 64-channel cap every row overprinted the
row above. Readings are shrunk to fit rather than elided: a number rendered as `29…` is worse than
none, because it looks like a number and is not one.

<a id="history-a-background-picture-and-the-one-number-that-lines-it-up"></a>

### A background picture, and the one number that lines it up

A picture can go under the electrodes — a topomap, an anatomical drawing, a photo of the cap. Two
parameters, both in the Configurator and shared by **both** viewers because a rig has one cap:

| Parameter | Default | |
|---|---|---|
| **Head image** | — | a path. Absolute, or relative to `Plot/` — so `../Bricks/topomap64_full_s.png` reaches the montage pictures that ship beside the QML |
| **Head electrode spread** | 0.739 | how far the electrodes spread across it |
| **Head centre x / y** | 0.5006 / 0.4690 | where the head sits within the picture |

All three are `Double`s with a **0.005 step and four decimals**: they are calibration numbers
against a picture, and the difference between 0.735 and 0.740 is visible on a 64-electrode cap.
The defaults are the measured figures for `topomap64_full_s.png`, because that is the pairing the
rigs use and a default that is right for it beats a round number that is right for nothing.

**The picture is the reference and the electrodes move to fit**, not the other way round. The
picture is fitted to the panel and left alone; CED radius 0.5 lands at `spread` x half the
picture's displayed width. So `1.0` puts the ear-level circle across the whole picture, and a
topomap whose head fills two thirds of its image wants about `0.66`.

That is deliberately one number a person can drag until it looks right, rather than an exact
description of the picture's geometry that nobody has to hand. Turn on **Alignment circle over the
picture** while setting it and off afterwards.

The drawn circle, nose and ears are **not** drawn over a picture unless that box is ticked: the
picture already has a head in it, and a second one on top is clutter. Without a picture they are
always drawn — they are the display.

For `topomap64_full_s.png` with the `mks64_standard.ced` montage the answer is **0.739**, and it
was measured rather than guessed: the picture is 1750 px wide, its T7 and T8 labels are 1378 px
apart and its Fpz and Oz labels 1380 px apart, both of which are CED radius 0.53318, giving
1293 px per unit radius — 1293/1750 = 0.739 from two independent axes. Head centre sits at
(0.5006, 0.4731) of the picture, which is what the **Head x / Head y** fields are for.

Verified on the live NVX136 in impedance mode: T7, T8, Fpz and Oz all land 337.3 px from centre
where the picture puts them at 337.0.

<a id="history-fitting-the-panel"></a>

### Fitting the panel

The picture is fitted to the panel, but the *electrodes* are what has to fit. A montage runs past
the ear-level circle — TP9/TP10 at 0.66, an EMG pair at 0.74 — so at spread 0.739 the outermost
electrode sits at 0.55 of the picture's width from centre, not 0.5. Fit the picture to the panel
and those electrodes hang outside it and get clipped, which is exactly what happened when the
window was widened: the panel changed shape, the picture followed, and the overhang went with it.

The picture is therefore shrunk by whatever factor makes the widest electrode — disc included —
land inside the panel. Picture and electrodes scale by the same number, so the alignment is
untouched. `HeadView.geometryInfo()` reports panel and map size so this is asserted across a
resize rather than noticed later as a clipped head.

<a id="history-background"></a>

### Background

Both views take a background from a ladder of **nine greys, white to black** — one setting for the
traces, a separate one for the map. A short ladder rather than a colour picker: what a background
has to do is give the marks contrast, and the only axis that matters for that is how light it is.

The map defaults to **white** where the traces default to black, and the reason is the pictures:
the topomaps in `Bricks/` are black ink on a transparent ground, so on a black panel the picture
loads correctly and draws nothing you can see.

**The ink is derived from the paper.** The map carries a lot of small text — names, readings, the
legend — and a fixed light grey vanishes on white; so does the time ruler in the trace view. Both
compute a luminance from the chosen background and pick dark or light text from it, which is what
makes the background genuinely selectable rather than merely settable. The head's own wash follows
too: a near-black fill under the outline on a white page would read as a blob.

<a id="history-what-a-ced-number-means"></a>

### What a CED `Number` means

**The device's inputs, electrodes first and AUX immediately after.** On a 48 + 4 NVX, rows 1–48 are
electrodes and 49–52 the AUX inputs; on a 128 + 8 NVX136, 1–128 and 129–136. Not the output-stream
column — the mask is applied before the stream is assembled, so the numbering does not shift when
the enabled set changes or the mode does.

AUX is in that space because an EMG pair taped to the face is an electrode with a position like any
other, and the montage is the only thing that can say where. It is *past* the electrode count so the
two can never collide, which is the bug this replaces: a row meant for AUX 1 on a 64-channel cap was
row 65, and on a 128-channel device row 65 is a real electrode — so in impedance mode, where AUX
does not exist at all, `EMG1`/`EMG2`/`TRIG` were being read onto electrodes 65/66/67. Numbering past
the electrode count also makes impedance mode skip the AUX rows for free.

The trigger takes no montage entry under any numbering: a bitfield has no place on a head.

`mks128_standard.ced` already followed this — its EMG pair is at 129/130 — which is what the
convention was reverse-engineered from. `mks64_standard.ced` had them at 65/66 with a `TRIG` row at
67; it is now 1–64 plus 129/130, i.e. a 64-electrode cap on a **128-channel NVX136**. The AUX
numbering is therefore device-specific, which is the price of one file describing both the cap and
where its extra electrodes are plugged in.

<a id="history-impedance-is-not-eeg"></a>

### Impedance is not EEG

Both NVX drivers described their impedance outputs as `kind = "EEG"`. The viewer believed them,
put the channels in the EEG group, and **band-passed a DC level at 3–35 Hz**, which removes the
entire reading. They now publish `kind = "Impedance"` and `unit = "Ohm"`, and the viewer carries a
matching group default: 20 kOhm full scale, step rendering, filters off. See
[known-issues §13j](../incidents/README.md).

---


<a id="history-8-interaction"></a>

## 8. Interaction

| | |
|---|---|
| Click / Shift+click / Ctrl+click a name | select / range / add. Anchor stays put, so repeated shift-clicks grow one range. |
| **Space** | toggle the tick on every selected channel, as in the NVX channel dialogs |
| Double-click a name | solo, and again to restore |
| Right-click a name | hide, mark bad, bypass filter, draw as bits/steps/line, autoscale |
| Right-click the plot | the setup panel, **at the pointer** |
| Hover | crosshair plus the value under the pointer, in that row's units |
| Wheel / Ctrl+wheel / Shift+wheel | scroll rows / time zoom / amplitude zoom |
| P, F, C, S, M | hold, fit, channels, setup, measure. Freeze is **P**, not Space -- Space belongs to the ticks. |
| T, R | arm/disarm **catch**, re-arm it |
| Z, Esc | arm the zoom rectangle, cancel it |
| H | scalp map instead of traces |
| ←→ ↑↓, PgUp/PgDn, Home | time, amplitude, page, top |
| Ctrl+A | select every channel |
| Measure | two labelled handles, A and B, at the top of the plot; drag either. Each shows the time it sits on, the box between them reads Δt and 1/Δt, and each lane's gutter switches to the **peak-to-peak** between the cursors, with min/max/mean/RMS behind a tooltip. |

Cursor positions are held as a **fraction of the time window**, not as pixels. Pixels anchor a
cursor to the window rather than to the data: resizing slid them off the samples they had been
placed on, and narrowing far enough pushed them outside the plot entirely. As fractions they stay
on the same time point through any resize — verified at 1776 px and 1080 px, both reading A 1.050 s
/ B 1.950 s — and they are on screen by construction.

Only a **focused** field responds to the wheel. Scrolling a settings panel must not retune every
filter it passes over.

**Fit** is a one-shot, per group, and leaves the group *fixed* at what it found. It is the escape
hatch from a scale that is moving on its own, so it deliberately does not switch anything to
continuous autoscale. Per group rather than per channel, because channel-by-channel scaling makes
deflections incomparable between electrodes, which is most of what reading a montage is for.

Colours come from a six-swatch palette applied to the selection, or `Auto` to follow the group.
Both colour and width are keyed **by channel**, not by screen row — the old code indexed by row,
so hiding one channel recoloured every channel below it.

---


<a id="history-10-testing"></a>

## 10. Testing

* `test_PlotMath` — 39 cases over tick generation, robust range, autoscale hysteresis, decimation
  and the scalp projection, including the degenerate inputs that used to hang the grid loop and
  the near-flat range that produced a ±9 fV scale.
* A QML harness (`-l harness.qml`) drives a live viewer through connect, range-select, paging,
  autoscale, freeze, bit expansion and a filter-type switch, printing what it observes. Exercised
  against `signalGenerator` at 70 ch / 25 kHz, at 4 ch with NaN meander, at 8 ch for bit decoding,
  and against a live NVX-52.
* `catch.qml` checks the catch against the data rather than against a screenshot: after the freeze
  it reads the sample under the marker back out and asserts that it *is* the level, that the trace
  is going the right way through it, and that the marker sits where it was asked for. On a 2 Hz
  sine at 1 kHz: mark position 0.5000 against 0.5 requested, sample 24.87 against a level of
  24.00, rising — and the same on the falling edge and across repeated re-arms.
* `head.qml` checks the scalp map against the montage rather than against a screenshot: it reads
  the projected positions back out and asserts Cz on the vertex, Fz above it, C3/C4 mirrored left
  and right, Pz behind, and that the widest electrode lands inside the widget. `headcolor.qml`
  sweeps the thresholds past a known reading and asserts the colour the map resolves to for all
  five states, including "no reading". Both run against a `signalGenerator` carrying a real CED —
  the generator takes the montage as a plain-text `ced` parameter, so a config file can embed one.
* `qmllint` catches syntax but **not** type resolution — `Invalid alias target location` only
  showed up on load. Launch the QML before believing it. A new QML type also needs adding to
  `Plot/qmldir`, which fails the same way: *"HeadView is not a type"*, only at load.

⚠ **`test_PlotMath` is built in the Qt 6 tree but never registered with CTest.**
`R:\src\quickStimulus\CMakeLists.txt` declares the target and `R:\src\_build\tests\test_PlotMath.exe`
is produced, but only `test_ParameterFile`, `test_ParameterFileQml` and `test_StreamConnectorQml`
get an `add_test()` in that file — so `ctest` in the Qt 6 build does not run it, and a regression
in tick generation or the scalp projection would pass a green test run. Run it by hand until that is
fixed ([qt6-work-list.md](../migrations/qt6-work-list.md)).

⚠ **The QML harnesses named above no longer exist on disk.** `harness.qml`, `catch.qml`,
`head.qml` and `headcolor.qml` were session scratch files and are in neither tree, neither
distribution, nor `R:\config`. What they asserted is recorded here and nowhere else; re-creating
them is the only way to re-run those checks against the Qt 6 build. The Qt 6 tree's own QML smoke
harnesses are a different set and live in `R:\src\scripts\`
(`stream-connector-package-smoke.qml`, `parameter-file-package-smoke.qml` and others).

---


<a id="history-11-traps-this-rework-walked-into"></a>

## 11. Traps this rework walked into

Recorded because none of them announce themselves, and two produced *silent* misbehaviour rather
than an error.

These were reasoned about on Qt 5.15.2's Controls 2 and then met again, with real numbers, during
the Qt 6 port — the density findings in `R:\src\docs\PORTING_LOG.md` (18 px service rows in a
200 px pane, 18 px channel rows with 13 px check marks, 24 px bipolar rows) are the same fight over
the same background floor, settled by measurement against a Qt 5 side-by-side rather than by
argument. Read the two sets together.

**A Controls 2 `Pane`/`GroupBox` needs its child anchored.** The Control sizes an internal wrapper
to its available area and leaves the children inside that wrapper at their implicit size. An
unanchored `ColumnLayout` therefore collapses to its content and `Layout.fillHeight` has nothing
to distribute — the channel list got no height at all. `anchors.fill: parent` is correct here and
produces no warning either way, so the only signal is the layout being wrong.

**An item can be visible and still have no hit area.** The stream connector in `StreamView` sized
itself from `implicitHeight: layout.implicitHeight` where that layout filled the connector — a
circular binding. It painted fine and could not be clicked or dropped onto. It now carries an
explicit `Layout.preferredHeight`.

**Parameters with no `index` sort arbitrarily.** Two viewers × (stream + settings) all defaulting
to index 0 gave the "plot" tab a different order on each run. They are now 10/11 and 20/21.

**Controls 2 metrics are touch-sized, and the background sets the floor.** Reducing the font and
padding is not enough: the Default style's `ComboBox` background has `implicitHeight: 40`, which
floors the whole control. Replacing the background is what makes it compact.

**`Set-Content -Encoding utf8` from PowerShell double-encodes.** Rewriting a QML file that way
turned `±` into `Â±` and `·` into `Â·`, which then rendered as an elided `...`. Use
`[System.IO.File]::WriteAllText` with a BOM-less `UTF8Encoding`, or edit the file directly.

**Assigning a JS object to a gadget property fails silently.** The stream connector wrote
`target.desiredStream = {connections: […]}`, asking QML to convert a plain object into a
`StreamInfo` — which it cannot, and does not complain about. The connector accepted hover, lit its
clear button and did nothing. Everything now goes through `serialized`, which
`Parameters::Stream::setJson()` runs through `StreamInfo::fromJson()`. The Configurator's own
parameter panel had always worked only because its target is a proxy with no `desiredStream`
property, so it took that branch already.

**A Repeater model built from JS objects drops function properties.** The channel panel's buttons
carried their action as `{ text: …, f: function () { … } }`. The conversion to `QVariantMap` keeps
the text and discards the function, so every button rendered and none of them did anything.
Dispatch by name instead.

**Controls 2's Default style floors every control through its background.** `Button` has
`implicitWidth: 100`, `ComboBox` and `TextField` `implicitHeight: 40`. Reducing font and padding
changes nothing while those apply — five buttons in a row still overflowed a 285 px panel.
Replacing the background is what makes a control compact, and a Layout will not shrink an item
below its implicit width unless given `Layout.minimumWidth`.

**A Qt Quick Layout with nothing to stretch centres its content.** With no stream selected both
the plot and the message log are hidden, so `StreamView` had no fill-height item left and parked
the connector halfway down an empty panel. A trailing `Item { Layout.fillHeight: true }` fixes it.

**Committing a numeric field per keystroke destroys the field.** Where the value feeds a panel
that rebuilds from the model -- the per-group scales do -- applying on `textEdited` meant the
first character replaced the Repeater's model, destroyed the delegate and threw the user out of
the field. Typing 1000 took four click-type cycles. `NumberField` now commits only on Enter or on
losing focus (Enter also drops focus, so anything that renormalises on the way out, like the SI
prefix turning 1000 uV into 1 mV, happens immediately), and `PlotSettings` defers its refresh
while any field is being edited.

**Fractional widths rasterise unevenly.** The pause glyph was two 2.5 px bars; they landed on
different sub-pixel phases and came out 2 px and 3 px wide, visibly lopsided. Integer sizes at
integer offsets.

**An incremental strip renderer seams at every boundary, in one of two directions.** A perfectly
flat trace — a trigger line — is the only place this is visible, and it appears on every row at
once, which is what makes it read as a rendering fault rather than as data.

Four approaches, three of them wrong, and each wrong one trades the artifact for its opposite:

- *Too little coverage → a gap.* Starting the polyline one **slot** before the strip is not enough.
  Below one slot per pixel, one slot back is still inside the boundary column, so the segment that
  joins the two strips is never drawn.
- *Too much coverage → a bulge.* Widening the **clip** to let that join through makes neighbouring
  strips both paint the boundary pixels, and two antialiased strokes over the same pixels blend
  darker and wider.
- *Inventing the last pixel → destroyed waveform.* Overshooting the right-hand end by holding the
  previous `y` across the final column fills it, and on a flat line that is invisibly correct. On a
  steep sine it draws a horizontal stub where the trace was climbing, and clipped, the cycle comes
  out truncated. Flat lines and dense waveforms fail this code in opposite directions — a trigger
  line and a hard-driven AUX channel are both needed to check it, and the AUX case matters more,
  because most of a real recording is waves rather than flat.

What ships: **the strip starts a whole pixel column early, that column is re-cleared before it is
redrawn, and the clip stays tight.** Clearing first is what prevents the double-blend; redrawing
the column complete is what prevents the lost sliver; and nothing is extrapolated past the last
real sample, so no geometry is invented. The lookback is `2 × slotsPerColumn + 2` slots, which
covers the boundary column at any decimation.

Measure it, do not squint at it — though the detector has to measure the artifact you actually
have. Summing ink in a band around a flat trace catches gaps and bulges on flat lines (original:
6–10 bulges, 2–3 gaps; widened clip: 10–14 bulges, 1 gap; final: 0 and 0) but reports nothing at
all on a truncated sine, because the missing part is mid-slope rather than at the peak. That
artifact was found by cropping the same region out of a before and an after capture and putting
them side by side. Comparing an incremental repaint against a forced full repaint remains the way
to separate a rendering artifact from real signal.

**A GridLayout cannot be made to align across sections, and pinning the column does not save
you.** This took three attempts. A `GridLayout` negotiates column widths across *all* of its
children, and an item with `Layout.columnSpan: 2` contributes to both columns' size requests — so
one full-width row (a long checkbox label, a wrapped note) widens column 0 regardless of the
`Layout.maximumWidth` carried by every other cell in that column. Sections that had such a row
therefore settled on a different column width from sections that did not, and the entry boxes
drifted apart by tens of pixels between "Filters" and "Display".

`PlotSettings` has no grid at all now. Every row is an independent `RowLayout` whose first item is
pinned to exactly `labelColumnWidth` (minimum == maximum) and whose second fills the rest, so
nothing negotiates with anything and a full-width row is simply a row with one child.

Inside the value column, `NumberField` puts its stretch at the **end**. A leading stretch anchors
the entry box to the column's right edge, which is only the same between rows if every column is
the same — the very thing that had just gone wrong. Trailing slack pins the box, the unit and the
steppers to fixed offsets from the left of the column instead, and a fixed-width unit slot keeps
the steppers in line whether or not a row has one.
