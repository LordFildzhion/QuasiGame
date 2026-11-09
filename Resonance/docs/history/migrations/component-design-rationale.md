# Component replacement rationale and legacy acceptance scope

Status: historical supplement. Added during the documentation preservation review, 2026-09-15.

Historical design choices, predecessor defects and acceptance questions extracted from sections that became concise current contracts. Existing history pages retain the campaigns; this supplement preserves details that the section classifier would otherwise have omitted. References to a replacement or proposed capability describe the original generation, not automatic current parity.

[Current guidance](../../components/README.md)

## Arduino service origins

Provenance: original `service_arduino-ttl.md` lines 38–53. The following is preserved source text.

There was no PC-side program to port. The `arduinoTTL` directory holds a sketch and two
documents, and the host side lived inside `feetStim` as one page of a much larger application.
So this service takes:

| From | What |
|---|---|
| `feetStim/triggerlink.{h,cpp}` | the link, its capability gates and its command spellings — reworked, see §7 |
| `feetStim/mainwindow.cpp` (TTL bench page) | the fields and their order, because that is what the operators already use |
| `feetStim/pwmprofile.{h,cpp}` | the amplitude-profile one-liner `0_T200:100_H300_T200:0`, unchanged |
| `arduinoTTL.ino` | the protocol, faithfully enough that the sketch is the specification |

and adds the second channel as first-class controls, a timing diagram, presets, two output
streams, a command stream, and a software model of the firmware.

The sketch and both of its documents are **vendored in `doc/`**, so a later firmware change can
be diffed against the code that reads it.

## Why eStim moved state and coupled limits out of widgets

Provenance: original `service_estim.md` lines 44–62. The following is preserved source text.

The design decision everything else follows from: **every input writes a `Parameters::*` object,
and only that object talks to the hardware.**

```
 window  ─┐
 serial  ─┤
 UDP     ─┼──► CommandEngine ──► Parameters::* ──► device wrapper (vendor DLL)
 stream  ─┤                           │
 EventBus─┘                           └──► events / status streams
```

The standalone program kept its state in the widgets, which worked while the widgets were the
only way in. It grew a serial listener, then a UDP listener, and by the third input the rule
"the spin box is the value" was one feature away from breaking — the serial path could already
set combinations the UI refused, because the coupled limits were enforced in the widgets alone.

Here `MainWindow` holds **no state at all**. A spin box writes the parameter; the parameter
notifies the window, the Configurator and the events stream. This is also why the service reacts
to commands with no stimulator attached, which is what makes it testable without hardware.

## Why eStim kept one scanner and partial-token reporting

Provenance: original `service_estim.md` lines 91–98. The following is preserved source text.

**There is one scanner** (`tokens.h`), shared by the command engine and the preset translator.
The standalone had only the first, as a recursive `QTextStream >>` walk with no error reporting;
adding a second parser beside it would have meant two definitions of the language, and a preset
a client could type but the engine would read differently.

A token that cannot be read is **reported and skipped**, not fatal to its line: `F60 Q9 A4` sets
60 Hz and 4 mA and publishes two `problem` records. An operator who mistypes one token of nine
gets the other eight, and is told which one went.

## NeuroMS rejected COM-wrapper behavior

Provenance: original `service_neuroms.md` lines 81–94. The following is preserved source text.

### 2.1 Why not the COM wrapper

The SDK ships `NeuroMsAPI.dll` + `RegisterDLL`, which looks like the intended integration path.
It is a lossy and partly broken subset, so this driver binds straight to
`NeuroSoft.Hardware.Devices.NeuroMSX.dll` instead:

* `NeuroMsxAPI.NeuroMsx::Open()` accepts `TrigInOn`, `TrigOutWidth`, `InvertTrig` and
  `ShowStimNum` and **passes a null `TriggerSettings` to the device**, so trigger configuration
  is silently dropped. On this rig that would disable the TTL input the stimulator is fired
  from.
* `NeuroMsAPI.NeuroMS::OpenMS()` discards the SDK's return value and `return true;`
  unconditionally — a failed open reports success. That is `KARDi2` F4 again.
* Neither COM interface exposes a single callback, so **every pulse, every error and every
  front-panel action is invisible through them**.

## NeuroMS positive interval that accidentally selected simultaneous firing

Provenance: original `service_neuroms.md` lines 169–182. The following is preserved source text.

### 4.1 The interval ladder, and why zero is special

Read off the SDK's own front-panel knob handler: **0.1 ms steps below 100 ms, 1 ms steps at and
above it, maximum 999 ms**, with a deliberate dead zone between 0 and 1 ms — from zero the first
step up lands on 1 ms, and from 1 ms a step down lands back on zero.

That gap is not an accident, and the driver preserves it: on this machine **a zero interval
selects simultaneous firing of both blocks** and any non-zero interval selects paired-pulse. So
rounding a small positive request down to zero would not be a rounding error, it would be a
change of operating mode — both blocks discharging together at whatever the first was set to.
`quantiseIpiMicros()` therefore never maps a positive request to zero; zero is reachable only by
asking for exactly zero. There is a unit test named after this
(`Interval.NoPositiveRequestCanBecomeZero`), and it caught a real bug during development: a
40 µs request had been rounding to 0.

## NeuroMS SDK interpretations still requiring their own evidence

Provenance: original `service_neuroms.md` lines 1068–1084. The following is preserved source text.

Everything here is reasoned from the assembly, the vendor's three sample applications and the
`.docx` API notes — which document only `NeuroMsMono`'s single/paired-pulse subset and nothing
else. Listed in rough order of how much a wrong guess would cost:

1. **`StartStimulation(..., noPulse)` means sham.** §9.8.
2. **`PulseFrame` schedules against the device's own timeline.** The vendor's samples pass
   `0xFFFE` for "now", and `PulseSyncInf` reports `frame`/`offset` back. If a real frame number
   schedules a pulse, phase-locked closed-loop TMS becomes possible with device-side timing
   instead of Windows timer jitter. Untested, and not used by the driver.
3. **`MachineState.IPI` counts 0.1 ms.** §9.4.
4. **`CapVolt` scale.** §9.5.
5. **`Open` with an explicit `TriggerSettings` behaves as `OpenMS` does for the monophasic.**
   §9.2.
6. **The panel is routed through the host.** §9.3 — true in all three vendor samples, but they
   are all WinForms applications.
7. **`NMS_TreatStart` is `SetTreatMode` followed by a trigger.** Biphasic only, and there is no
   separate start entry point in the SDK. Irrelevant until an MSX arrives.

## Viewer split-pane growth, clipping and parameter divider repairs

Provenance: original `service_signal-viewer.md` lines 497–521. The following is preserved source text.

The Configurator's two viewers sit in a `SplitView` whose orientation is switchable from
**View → Viewers stacked / side by side**, persisted as the `viewer_layout` parameter. Side by
side is what a scalp map wants: the map is square, so stacked it gets a wide strip and wastes most
of it, while beside a trace view it fills its half. Head map on the left, traces on the right is
the arrangement the standalone `impedanceMeasure` tool had, and it is now two menu clicks in the
Configurator instead of a separate application.

**The second viewer is the one that flexes.** A `SplitView` expands exactly one item and leaves the
rest at the size they were last given, so only the expanding pane answers a change of window size.
With the *first* viewer expanding, a scalp map in the second never grew when the window was
widened, and narrowing pushed the second pane's right-hand edge off the window — the map centres on
its pane, so half of it ended up outside the screen and read as clipping. The fill policy is now on
viewer 2, viewer 1 carries a preferred size, and `HeadView` clips to its own bounds so nothing can
paint across its neighbour. The legend shrinks to fit rather than spilling.

The **Services / Parameters** divider in the left column is draggable too, which it was not:
`ParametersView` carried `anchors.top`/`anchors.bottom`, and anchoring an item inside a SplitView
drives its geometry directly so the split's own sizing never reaches it — the handle moved and
nothing followed. Services now has a preferred height, the parameters below take the slack as the
window grows, and the handle is nine pixels with a grip rather than the four unmarked pixels of
the stock style.

The montages and topomap pictures the rigs use — `mks64/128/256_standard.ced`, `mks2_emg.ced`,
`topomap*.png` — now live in `import/Resonance/Bricks/` in **source**. They had existed only in
the 2025 deployment and were never in git; see [deployed-vs-repo.md](deployed-vs-repo.md).

## Stacked rendering restored and scale references added

Provenance: original `service_signal-viewer.md` lines 527–552. The following is preserved source text.

**Display → Stack all channels on one axis** overlays every drawn row on a shared lane instead of
giving each its own. The lane layout answers "what is each channel doing"; stacked answers "how do
these channels compare", which is a different question — a latency between two traces, or one
electrode drifting away from the rest, is invisible when each has its own baseline. It was in the
pre-rework viewer as `drawStacked` and did not survive; this is it back.

Geometry goes through `laneHeight()` / `laneCentre()` so every consumer — traces, gridlines, the
catch level, the zoom rectangle, the hit test — agrees without each carrying its own copy of the
arithmetic. Two things change with it: the amplitude gridlines are drawn **once** rather than once
per row, since one axis needs one set; and the channel column becomes a plain list, because there
are no lanes to line names up with and a 60-row list at full lane height would show one name. The
hover readout picks the trace **nearest the pointer** rather than dividing the height by the row
count, which is the only way to identify a trace in an overlay.

### The amplitude axis, and the scale bar

`axisIsReadable` is true when one lane fills the plot — stacked, or a single drawn row — and two
things follow from it. Gridlines go from a 10 px minimum spacing to 45, and they get **numbers**
down the left with the unit written once at the top. Sixty lanes of tick labels is not an axis, it
is noise, so neither appears in a multichannel layout; there the gutter's `±100 uV` is the scale.

**Scale bar** (Display → Scale bar) is the other half: a bar of known amplitude in the corner, with
end caps, to compare deflections against — "that blink is about two of these". The *value* is
rounded to a 1-2-5 step near a quarter of the lane and the bar's height follows, rather than a tidy
bar labelled 13.7 uV; it comes out as 10 uV, 50 uV, 1 mV — the lengths people quote. It works in
every layout, including multichannel, where it is the only amplitude reference that costs no space.

## Legacy stimulus parity checklist: the original 28 capabilities

Provenance: original `service_stimulus-presentation.md` lines 404–451. The following is preserved source text.

This is the list the replacement has to satisfy. Everything here is implemented somewhere in the
legacy tree and is used.

**Presentation**

1. Show a picture full-screen on a chosen screen, from a catalogue keyed by integer code.
2. Show text instead of a picture, at a per-stimulus font size.
3. Show a blank/"empty" image between stimuli, selectable from a list.
4. Special-case stimulus classes with a *different duration* (`Особые стимулы`, given as a
   space-separated list of catalogue indices).
5. "Infinite" stimuli that wait for a keypress (Space/Esc/`` ` ``) instead of a timeout.
6. Typed subject input during an infinite stimulus, captured into the event stream.
7. Welcome and Bye screens with their own durations.
8. Play a video clip as a stimulus, seeking to a position encoded in the stimulus code.
9. Play a long media file on a second screen with per-trial seek (the music paradigm).
10. Fullscreen toggle for the subject window.

**Sequencing**

11. A sequence written as indices into a hand-picked stimulus subset (`"1 2 2 1"`).
12. Interactive selection of which catalogue entries take part, by clicking pictures.
13. Uniform-random ISI between `min` and `max`, drawn once per run at start.

**Devices**

14. Launch an amplifier service if discovery does not see it, and configure it (`device`, `mode`).
15. Switch between impedance and acquisition modes, both directions, mid-session.
16. Drive **two** amplifiers in lock-step (`NVX1`/`NVX2`).
17. Trigger pulses via a `trigger_state` parameter for cross-amplifier alignment.
18. COM-port stimulator: open at start, write an init string, map stimulus codes to command
    letters, write `-` on stimulus offset.
19. EyeLink: stop it when the run finishes.
20. Start/stop an `ffmpeg` screen or camera recording alongside.
21. Kill the amplifier services from the console (`stop` then `!terminate`).

**Data**

22. Publish every stimulus onset/offset as a `Message` on an `events` stream.
23. Record EEG + impedance + events into one HDF5 file, with `$$`-expanded run numbers.
24. Re-add streams under new names on every mode switch (`eeg_nvx1_1`, `eeg_nvx1_2`, …).
25. Stop recording automatically when the sequence ends.

**Monitoring**

26. Live impedance head map with operator-set green/yellow thresholds.
27. Live EEG trace view.
28. Every setting exposed as a Resonance parameter, so the Configurator can drive it and a
    `--serviceConfig` JSON can restore a session.

## Retired tepService predecessor mismatch and division of responsibilities

Provenance: original `service_tep.md` lines 88–117. The following is preserved source text.

Two things, which the legacy kept apart and which had to be configured to agree:

| | Legacy | Here |
|---|---|---|
| Epoching | `SPEED.exe` hosting `mulines.TEPs_plot.pipeline_tep`, reading `SPEED_settings.json` | `pipeline.{hpp,cpp}` |
| Display and analysis | `TEP_visualization` — PyQt5, ~200 KB of Python across `ui/`, `logic/`, `settings/` | `service.cpp` + `views.cpp` + the console QML |
| Settings | a JSON file each, written by the GUI, read by the other process at launch | one set of `Parameters::*`, visible to the Configurator |
| Recording | driven through a `Resonance-control` QML proxy that the app talked to over a Message stream | `recorderService`, or the module's own epoch file |

**The two settings files had to be kept in step by hand, and nothing checked that they were.**
`SPEED_settings.json` in the deployment says `window_start: -500, high_freq: 30`; the
`TEP_visual_settings.json` beside it says `-100` and `2500`; and `mulines/resources/SPEED_settings.json`,
which is the one the launcher actually passes, says `-500` and `2500` with an artifact window of
−0.04…0.85 ms. Three files, three different paradigms, and the epoch length the GUI drew its axes
from came from the one the pipeline was not reading.

That is the class of defect this module exists to remove: there is now one place a window length
is written down.

### What is deliberately not carried over

- **stimulus presentation** — `stimuli_control_panel.py`, the six video players, the survey. That
  is [stimulusService](../components/stimulus-presentation.md)'s job, and it is 90 KB of the legacy application;
- **amplifier orchestration** — launching `nvx136`, switching impedance, starting the recorder.
  Also stimulusService's, and the reason is that a rig with two programs both starting the
  amplifier is a rig with a race;
- **the offline analysis windows** — `mep_condition_analysis_window`, `mep_movement_detection_window`.
  These read a saved epoch file after the fact. The file this module writes is the same file, so
  they keep working; porting a post-hoc analysis into a live service would only make it harder to
  run twice.
