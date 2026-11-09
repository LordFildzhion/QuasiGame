# Viewer epoch work — live status — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../architecture/epochs.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-viewer-epoch-work--live-status"></a>


**2026-08-20.** Companion to [design_viewer-epochs.md](design_viewer-epochs.md). That file is the
design; this one is *where the work actually is*, written so a session picking this up cold — or
after a context compaction — loses nothing.

---


<a id="history-done-and-deployed"></a>

## Done and deployed

| | |
|---|---|
| **Stage 0** — the epoch metadata contract | ✅ four producers, proven live on six streams, 155 assertions |
| **Stage 1** — full-width epoch, negative time, butterfly | ✅ **deployed** |
| **Stage 3** — interpolated topoplot, EEGLAB-matched | ✅ **deployed** |
| **Stage 2** — head-shaped trace array | ✅ **deployed** |
| **Stage 4** — averaging (4 methods, per-condition, byte budget) + D1/D2 | ✅ **deployed** |
| **Stage 5** — viewer-side epoching off a trigger + the `plotN_markers` handler | ✅ **deployed**, alignment **0 samples** |
| **Stage 6** — the viewer PUBLISHES its epochs (running average + single filtered epochs) | ✅ **deployed**, round trip **0.0** worst sample difference |
| **Stage 0 debt** — honest generator `kind`, status-channel rule, tepSound anchor | ✅ **deployed** |
| **Final** — `numcontour`, `conv`, and uncapped retention with a 2 GB notice | ✅ **deployed**, contour levels **6.0e-14** vs EEGLAB, conv mask **0 of 40000** cells differ |
| **CED scalp trace palette** — a colour from where the electrode *is* | ✅ **deployed**, **7.35e-06** worst RGB component vs MATLAB through the running viewer |

**🏁 THE EPOCH PROJECT IS COMPLETE.** Every stage is built, proven against its oracle, deployed
and verified by launching the deployed tree. What was deliberately *not* done is listed in one
place — see **[What is NOT done](../../architecture/epochs.md)**. Nothing below
that line is a surprise waiting for the next reader.

All of it is live in `R:\dist\msvc64`, as is the republish fix (§21). Rollbacks, newest last:
`bin.pre-epochs-20260820-052729`, `bin.pre-stage2-20260820-082444`,
`bin.pre-stage4-20260820-104457`, `bin.pre-republish-20260820-131828`,
`bin.pre-stage5-20260820-152618`, `bin.pre-stage6-20260820-171558`,
**`bin.pre-final-20260820-191617`** ← roll back to this to undo the final stage,
**`bin.pre-ced-20260820-223359`** ← roll back to this to undo the CED scalp trace palette. That
backup also holds `quickStimulusPlugin.dll.inuse-20260820-223359`: a configurator launched from the
deployed tree by another session had the old plugin mapped, so it was **renamed aside** rather than
overwritten — a mapped DLL cannot be replaced but can be renamed, and the running process keeps its
handle. The file is the same bytes as the backup's own copy of the plugin and can be deleted once
nothing has it open.

⚠ Deploy with `robocopy … /E` and **never** `/MIR` or `/PURGE`. Six things live in the deployed
`bin\` that the build does not ship and that a mirroring copy would delete: `FrameLib\`,
`emulator.exe`, `arduinoTTL.ini`, `eStim.ini`, `feetStim.ini`, `mStim.ini`. (`params\`,
`montages\`, `calib\`, `protocols\` sit above `bin\` and are never in the copy's path at all.)

Test it yourself: **`R:\dist\msvc64\epochDemo.bat`** — starts a generator publishing only its epoch
lane (config `R:\config\epochdemo_generator.json`) plus the Configurator. Drag `epochs @ EPOCHDEMO`
onto a viewer; it switches to the epoch view by itself.

Evidence: `R:\dist\_build\stage1\`, `stage2\`, `stage3\` (screenshots + harness logs).
Contract harness: `R:\config\epoch_contract_check.qml` (+ `.ps1`).

Stage 2 numbers worth keeping: the trace array calls the **same** `topoLayout` the field does —
`plotrad=0.678218 squeezefac=0.737226 headCircle=0.339124`, identical to the topoplot's, so an
electrode does not move when the operator switches rendering. Paint 1.9 ms for 64 cells.


<a id="history-ced-scalp-trace-palette---built-proven-deployed-2026-08-20"></a>

## CED scalp trace palette — ✅ BUILT, PROVEN, DEPLOYED (2026-08-20)

A third colour rule beside `Colormap` (a signed reading → a colour) and the six-entry channel
palette (a channel *index* → a colour). This one turns **where the electrode is** into a colour, so
a trace's colour says which part of the scalp it came from and stays the same colour for that
electrode in every recording, every montage width and every viewer.

It is a transliteration of `tmsui.getChannelTraceColors` + `tmsui.eegCircularColorsFromXY2`
(`W:\MATLAB\tms\UI_LoadTransICA\+tmsui\`), the palette the operator's MATLAB prune UI draws its
channel traces in — so the two pictures are *the same picture*.

```
ang = atan2(y, x)                                  // 'ccw', no negation
hue = mod(ang/(2*pi) + 1 + rotateDeg/360, 1)       // rotateDeg = -120
r   = (hypot(x,y) - min r) / max(max r - min r, 1e-16)   // normalised ACROSS CHANNELS
sat = 0.25 + 0.75*r , then *0.8 ;  val = 0.85
rgb = hsv2rgb(hue, sat, val)
```

Which direction gets which hue, as MATLAB printed it: **+x nose → blue 240°**, **+y left ear →
pink-magenta 330°**, **−x inion → yellow 60°**, **−y right ear → green 150°**, running continuously
anticlockwise between them. Saturation is radial: Cz sits at 0.20, the rim at 0.80. Two electrodes
on opposite sides of the head are told apart by hue; an electrode and its neighbour towards the
vertex, by saturation. **An operator who sees a frontal channel drawn yellow is looking at a
montage whose theta convention is flipped, not at a re-tuned palette.**

The core is `R:\src\quickStimulus\cedpalette.{hpp,cpp}` — **Qt-free**, the same shape as
`topofield.cpp` and `colormap.cpp`, because the same object has to compile into the quickStimulus
plugin, into `tepSoundService` (whose butterfly plot wants this palette as its *default*), and into
a GTest target that needs no Qt DLL beside it. `test_CedPalette`, **16 cases**, asserted against
CSVs MATLAB itself wrote (`R:\dist\_build\topo-ref\ced_palette_*.csv`, from
`R:\config\ced_palette_probe.m`) — not against a second reading of the same formula.

<a id="history--three-things-that-were-measured-in-matlab-rather-than-reasoned-about"></a>

### ⭐ Three things that were MEASURED in MATLAB rather than reasoned about

1. **The closing round trip is just `sat *= 0.8`.** `getChannelTraceColors` ends with
   `hsv = rgb2hsv(rgb); hsv(:,2) *= 0.8; rgb = hsv2rgb(hsv)`. Over the real 64-channel palette that
   differs from folding 0.8 straight into the single `hsv2rgb` by **6.66e-16 per component**, 1.7e-13
   of one 8-bit level. So the round trip is not performed. The measurement is why, not the algebra.

2. **The hexcone `hsv2rgb` is bit-identical to MATLAB's** — worst component difference **exactly 0**
   over **219520** (h,s,v) triples including `h = 0`, `h = eps`, `h = 1-eps`
   (`R:\config\ced_palette_hsv_check.m`). MATLAB's own `hsv2rgb` is a vectorised index-matrix
   construction, not the textbook form, so this could not be assumed. It also **cannot come from
   Qt**: `QColor::fromHsvF` quantises to 16-bit and would put a floor of ~1.5e-5 under every
   assertion.

3. **EEGLAB's `readlocs` does NOT return the .ced file's X/Y verbatim.** It recomputes them from the
   spherical columns, `X = sph_radius*cos(sph_phi)*cos(sph_theta)`, matching that to 3.5e-17 while
   differing from the file's own printed X/Y by up to **5.5e-4**. Same family as
   `arch_known-issues.md` §23, one column over. It matters because hue is `atan2` of those numbers.

<a id="history--why-frompolar-exists-and-what-it-costs"></a>

### ⭐ Why `fromPolar()` exists, and what it costs

`Core/Resonance/internal/ParseCED.cpp` publishes **only `theta` and `radius`** per channel. X/Y/Z
and `sph_*` never reach a viewer, so no viewer can hand the palette readlocs' X/Y — it must rebuild
them, through the identity `PlotMath::scalpUnitVector` already carries:

```
sph_theta = -theta ,  sph_phi = (0.5 - radius)*180° ,  (x, y) = cos(phi)*(cos(th), sin(th))
```

That is EEGLAB's `topo2sph` then `sph2cart` on a **unit** sphere, where readlocs scales by the
file's own per-row `sph_radius`. The scale factor cancels out of the hue entirely and out of the
saturation up to the montage's own 1.1e-4 spread in `sph_radius`.

<a id="history--the-measured-agreement--through-the-running-viewer-not-the-unit-test"></a>

### ⭐ The measured agreement — through the RUNNING viewer, not the unit test

The unit test reads the oracle too, so it is not an independent check. The numbers below come from
`ChannelModel`'s `EffectiveColorRole` read out of a **connected, running** viewer — the whole path an
operator's picture takes: signalGenerator's mks64 montage → StreamInfo → ParseCED → `headPosition`
→ `rebuildScalpColors` → `CedPalette::fromPolar` → `QColor::fromRgbF` → the trace on screen.
Harness `R:\config\ced_palette_shot.{qml,ps1}`.

| compared against | worst per-component RGB | in 8-bit levels | electrode |
|---|---|---|---|
| MATLAB's own **theta/radius** path (`ced_palette_viewerpath_tep64.csv`) | **7.35e-06** | 0.0019 | CP5 (G) |
| MATLAB's **readlocs X/Y** path (`ced_palette_tepsound64.csv`) — what the prune UI draws | **3.909e-04** | 0.0997 | C3 (G) |

The first row is **below the read-back floor** — `QColor` keeps 16-bit integer channels, so 1.526e-5
is the finest difference a `QColor` can even express. Like for like, the viewer and MATLAB are
identical. The second row is the `readlocs` residual of §3 above and matches `cedpalette.hpp`'s
prediction of 3.97e-4 on **the same electrode**; the remainder is the same 16-bit quantisation. At
0.0997 of one 8-bit level it can never be a different pixel.

The four cardinal directions were read off the live model and land exactly where MATLAB put them:
`Fpz` hue 240.00° sat 0.8000, `T7` 330.00°, `Oz` 60.00°, `T8` 150.00°, `Cz` sat **0.2000** = the
vertex minimum. Both shipped montages (66-row Bricks, 64-row tepSound) give palettes differing by
**exactly 0**, because both files put their non-scalp rows last.

<a id="history--normalised-across-which-channels--the-one-decision-a-caller-cannot-avoid"></a>

### ⭐ Normalised across *which* channels — the one decision a caller cannot avoid

`min r` / `max r` are taken over the channels **passed in**, so the caller's choice of set changes
every saturation in the palette — the same hazard `TopoView` documents for `plotrad`. The rule this
tree uses, in `ChannelModel::effectiveColor` and later in `tepSoundService`, is **EEG by kind**, the
same screen `TopoView` and `EpochGridView` already apply. In readlocs' coordinates admitting mks64's
EMG rows (`sph_radius` 85 against the EEG rows' 0.09994) collapses the entire cap onto `satMin`; on
the unit sphere the same two channels change this montage's palette by exactly 0, but that is
mks64 being lucky, not a proof — `r = |cos((0.5 - radius)*pi)|` **peaks at radius 0.5** and is not
monotone, so a channel below the equator can become the new minimum on a montage laid out
differently.

<a id="history--a-channel-with-no-position-is-not-a-colour"></a>

### ⭐ A channel with no position is not a colour

MATLAB's function **errors** when the file holds fewer valid rows than channels asked for. A live
viewer cannot: montages are routinely partial and a trigger channel legitimately has no place on the
scalp. So the palette is **index-preserving** and a channel whose coordinates are not finite comes
back with `valid == false` and **no colour** — the same shape `Colormap::Sample` uses for a missing
reading. Callers fall back to the channel's existing colour and **say so**, which is the visible half
of the bargain. Both halves were photographed:

* **no montage at all** — `scalpColorCount=0 / scalpCandidateCount=64`, `hasHeadLayout=false`.
  Every trace keeps its palette colour, nothing goes grey, and the settings panel prints, in red,
  *"No montage on this stream. Every trace keeps its palette colour."*
* **fewer positions than channels** — 80-channel stream on the 64-row montage:
  `scalpColorCount=64 / 80`. The 64 placed electrodes are coloured by position, `Ch 65…Ch 80` stay
  on the palette, and the panel prints *"64 of 80 EEG channels have a position; the rest keep their
  palette colour."*

<a id="history-how-an-operator-turns-it-on"></a>

### How an operator turns it on

**Plot settings → Display → Trace colour → "Scalp position"** (the default is "Channel palette").
It is persisted in the viewer's existing settings blob as `trace_color_mode`, values `"palette"` /
`"scalp"`; **anything unrecognised, including a blob written before this key existed, reads as
`"palette"`**, so an existing configuration opens looking exactly as it did. Underneath the combo the
panel states the outcome — how many EEG channels were coloured, of how many offered — so a mode that
did nothing is never mistaken for a mode that was ignored.

⚠ In scalp mode the derived colour **outranks** a per-channel override for the channels the montage
placed. That is the point of the mode: the same electrode is the same colour everywhere, and an
override left over from an earlier session would make one trace an exception nobody could explain.
The override is stored, still decides for every channel the palette does *not* place, and reappears
on the way out of the mode.

<a id="history-the-evidence-shots-each-described-from-the-image"></a>

### The evidence shots, each described from the image

`R:\dist\_build\ced-palette\`

* **`ced-01-butterfly-palette-vs-scalp.png`** — one stream, two viewers, one instant, the same
  pinned ±150 µV scale. Left is the viewer's default: all 64 EEG channels share the one group
  colour, so the butterfly is a solid orange band. Right is the same butterfly in scalp mode —
  every trace individually coloured, and the channel-name column beside it is colour-coded to
  match, `T7` pink through `Fpz` blue to `Oz` yellow.
* **`ced-02-swatches-viewer-vs-matlab.png`** — ⭐ **the headline picture.** Two strips of 64
  swatches in montage order, `viewer` above `MATLAB`, separated by a visible gap and matched by
  electrode label. Column by column the two rows are the same colour; there is **no hue rotation,
  no mirrored hemisphere and no off-by-one** in the montage join. The third lane draws the
  difference at 2000× magnification and is completely empty, which at 7.3e-6 is the correct answer.
* **`ced-03-fallback-no-montage.png`** — the montage cleared at the producer. Channels are named
  `Ch 1…Ch 64`, the **Head** button is greyed out, and with the setting on "Scalp position" all 64
  traces are the plain palette orange. Degraded, not broken.
* **`ced-04-fallback-panel-says-so.png`** — the settings panel of that same stream, scrolled to
  Display: "Trace colour: **Scalp position**" with the red note under it.
* **`ced-05-partial-montage.png`** — 80-channel stream, 64-row montage. The label column shows
  `T7…TP8` in per-position colours and `Ch 65…Ch 80` all in the same palette orange; the butterfly
  is CED colours over an orange band of the 16 unplaced ones.
* **`ced-06-partial-panel-says-so.png`** — the same panel with the "64 of 80" note.
* **`deployed\`** — the first two shots taken again from the **deployed** tree
  `R:\dist\msvc64`, byte-identical numbers (`scalp=64/64`, worst 7.346537e-6 at CP5).

<a id="history-binding-loops"></a>

### Binding loops

**0**, across every run log of every mode (compare, fallback, partial, and the deployed-tree
verification). Zero QML warnings or type errors as well.

<a id="history-what-landed"></a>

### What landed

| file | what changed |
|---|---|
| `quickStimulus/cedpalette.{hpp,cpp}` | **new** — the Qt-free palette core, `fromCartesian` / `fromPolar` / `cartesianFromPolar` / `hsv2rgb` / `to8Bit` |
| `quickStimulus/tests/cedpalette_test.cpp` | **new** — 16 cases against MATLAB's own CSVs |
| `quickStimulus/channelmodel.{hpp,cpp}` | `traceColorMode`, `scalpColorCount`, `scalpCandidateCount`, `rebuildScalpColors()`, `kindOf()`; `effectiveColor()` consults the scalp palette first |
| `Resonance/Plot/Settings.qml` | `trace_color_mode`, persisted, defaulting to `"palette"` |
| `Resonance/Plot/PlotSettings.qml` | the Display → Trace colour combo and the two outcome notes |
| `Resonance/Plot/PlotView.qml`, `EpochView.qml` | one-way `Binding` from the setting to each view's own `ChannelModel` — the two viewers own separate models, so each needs its own |
| `Resonance/Plot/ChannelPanel.qml` | the swatch row says "Colour (EEG: from position)" while the mode is on |
| `quickStimulus/CMakeLists.txt` | `cedpalette.cpp` into the plugin; `test_CedPalette` target |
| `R:\config\ced_palette_shot.{qml,ps1}` | **new** — the live-viewer evidence harness |

**Build fix applied:** `tests/cedpalette_test.cpp` had no `main()` and failed to link
(`LNK2019: main`). Every sibling test in this tree carries its own `InitGoogleTest`/`RUN_ALL_TESTS`
rather than linking `gtest_main`, so the same four lines were added. Nothing else needed touching.

**Tests after the change:** `tests\` **588 in 19 executables, 0 failures** (baseline 572 in 18, plus
the 16 new `CedPalette` cases). `Core\Resonance\tests\`: `test_StreamInfo` 18, `test_SamplesCollector`
1, `test_NetworkMode` 10 — all pass; `test_RecorderPath` exits 2 without `RESONANCE_RECORD_PATH`,
pre-existing and env-gated.


<a id="history--what-is-not-done--the-whole-list-in-one-place"></a>

## ⚠ What is NOT done — the whole list, in one place

Gathered from every stage on 2026-08-20 so a reader arriving cold does not have to reconstruct it
from seven "still open" sections. **Nothing here is a bug that was hidden; each is a decision, and
the reason is given.** Ordered by how likely it is to bite.

<a id="history-things-a-user-could-hit"></a>

### Things a user could hit

1. **`plotN_trigger` is declared and deliberately unread** (Stage 5). Route B works in the core and
   is covered by test, but nothing in the viewer calls it: a cross-stream trigger can only be placed
   by comparing timestamps, and a continuous stream publishes no `epoch_stamp` to say what its own
   timestamps name. The slot exists so a hardware-trigger rig needs no configuration migration when
   it is wired up.
2. **The published epoch stream carries no condition LABEL** (Stage 6). By design: join on the
   trigger RTC against the recordable `plotN_markers` stream, or point the average at one bin. A
   consumer that expects a label field will not find one.
3. **Median and trimmed-mean averages have never been published live** (Stage 6). The round trip used
   `mean`. The method reaches the metadata as `epoch_average_method` and changing it republishes —
   that is covered by `test_EpochAnnounce`, but it has not been measured on the rig.
4. **A filter or reference change throws away the running average** (Stage 5). Correct — mixing pre-
   and post-filter epochs gives a stable, wrong answer — but heavier than it looks from the button,
   and it probably wants an explicit confirm.
5. **The display filter rides into viewer-cut epochs** (Stage 5). Deliberate — filter, then cut, as
   tepService does — but a viewer-cut epoch is filtered data and the group delay is real: **+20 ms**
   with the default 3–35 Hz Butterworth-4. Worth a caption or a panel note.
6. **A second viewer publishing under the same name** is refused by the process-wide registry and
   says so on its caption, but this was never exercised on the rig — the round trip used one
   publisher.
7. **`averageWindow` coalescing.** Dragging the "Last N" spinner republishes per distinct value.
   Bounded by operator clicks and visible on `publishRebuilds`; no timer was added pre-emptively,
   because an unmeasured mitigation is how a second source of truth gets introduced.

<a id="history-things-that-are-only-wrong-to-a-numerical-eye"></a>

### Things that are only wrong to a numerical eye

8. **The live montage is ~4e-5 off EEGLAB**, and the cause is now known and written down:
   `parseCED` reads the `.ced` file's five-decimal `theta`/`radius` columns where EEGLAB recomputes
   them from `sph_phi`. See `arch_known-issues.md` §23 — it includes the reproduction and the fix if
   anyone wants it. **This is the only remaining gap between the viewer and EEGLAB.**
9. **The marching-squares saddle convention is unproven against MATLAB** (final stage). EEGLAB's own
   field contains 0 saddle cells at its own levels, so MATLAB could not arbitrate it. A future field
   could differ in CONNECTIVITY inside one cell — never in level, never by crossing.
10. **shading `'interp'`** for the `conv` hull clamp is implemented but only the default `'flat'`
    branch is measured against MATLAB.
11. **The `conv` hull from a montage with channels outside `plotrad`** is untested: `topoplot.m`
    builds it from ALL channels, and on the reference EEG-only run the two sets coincide.
12. **The published average is the mean of float32 samples** (Stage 6). Against a float32-rounded
    source it differs by exactly 0.0; against the raw double source, by 2.3e-10.

<a id="history-things-that-are-the-frameworks-not-the-viewers"></a>

### Things that are the framework's, not the viewer's

13. **The republish wedge was closed by ARGUMENT, never reproduced** (§21). Four latent hazards whose
    signature matched the report were fixed, but none was ever *observed* to fire — and the wedge
    never reproduced before the fix either (320 republishes) or after (960). ⚠ Say this plainly: a
    proven fix for the gap and the churn, an **unproven** one for the wedge. The counters are in the
    shipped build to catch it if it returns; the first thing to check is still whether a
    `FATAL`/`Qt.quit()` precedes the last heartbeat.
14. **~30 generator parameters sit on the wrong `Dirty` flag, and the recommendation is to DELETE
    THE ENUM rather than fix them** — it no longer decides anything. `arch_known-issues.md` §22.
15. **`recorderService` slot resolution has a sharp edge** found during Stage 6 — see "A framework
    sharp edge found along the way" in the Stage 6 section. Not a Stage 6 defect, but it looks like
    one from the outside.
16. **`EpocherCounters::refused` is the REFRACTORY count alone**, not a total. `cutStatus()` and
    `cutCounters["refusedTotal"]` sum all eight reasons. Anything quoting `refused` as the total is
    wrong.
17. **The `kind` filter is written but barely exercised** (Stage 3, partially closed by the Stage 0
    debt). `signalGenerator`'s epoch lane now publishes honest `kind`, but the EMG exclusion on the
    demo stream still happens via the `.ced` `Number` column as well, so the two mechanisms have not
    been separated on a producer that disagrees with the montage.

<a id="history-test-coverage-gaps"></a>

### Test-coverage gaps

18. **No Qt-side automated tests for the epocher's viewer half.** The epocher core has 38; the tap,
    the door, the marker handler and the caption are covered only by the live harness, because the
    existing GTest targets link pure-logic files only.
19. **`test_RecorderPath` exits 2 unless `RESONANCE_RECORD_PATH` is set.** Pre-existing, env-gated,
    not a failure, and deliberately not in the 572 count.

<a id="history-two-follow-ups-the-final-stage-created"></a>

### Two follow-ups the final stage created

20. **`epoch_budget_mb` changed meaning without changing name.** It is now the notify threshold in
    MB, not a hard cap. It is honoured only where it looks like a threshold somebody set — 512 (the
    Stage 4 default) and anything under 16 MB (what a cap experiment left behind; the harnesses used
    to write 1.5) fall back to 2048. ✅ **Its `Settings.qml` doc comment was rewritten in this stage**
    — it had still described a hard cap ("the capacity the viewer reports is derived from this"),
    which was by then flatly wrong, and a stale comment on a key that changed meaning is worse than
    no comment. **What remains is the rename to `epoch_notify_mb`**, which would be cleaner and is
    safe: retention lives in the settings blob, where unknown keys are ignored on load and missing
    keys keep their default. Not done because it touches `EpochView.qml` as well and the value was
    already being screened correctly.
21. **`numcontour` as a VECTOR** is supported by the C++ API but not exposed on the QML control,
    which offers the scalar N only.

---


<a id="history-final-stage--numcontour-conv-uncapped-retention---built-proven-deployed-2026-08-20"></a>

## Final stage — `numcontour`, `conv`, uncapped retention — ✅ BUILT, PROVEN, DEPLOYED (2026-08-20)

**572 tests / 18 executables, 0 failures** (was 541/18). `test_TopoField` 21 → **43**;
`test_EpochStore` 26 → **35**. Core targets unchanged: `test_StreamInfo` 18,
`test_SamplesCollector` 1, `test_NetworkMode` 10 cases. (`test_RecorderPath` still exits 2 unless
`RESONANCE_RECORD_PATH` is set — pre-existing, env-gated, not a failure and not in the count.)
`ninja -t deps` reports `#deps N (VALID)` on `topoview.cpp.obj` (147), `epochreceiver.cpp.obj`
(289) and both test objects, so the header deps really were recorded. **The build was clean first
time — no fixes were needed.** No non-ASCII in any narrow string literal in the ten changed C++
files (checked with a literal-aware scanner, not a byte grep: comments legitimately contain ⚠ and
⭐, and a plain grep flags 320 lines that are all comments).

<a id="history--contour-levels-vs-eeglabs-own-levellist--the-failure-mode-this-project-already-paid-for"></a>

### ⭐ CONTOUR LEVELS vs EEGLAB'S OWN `LevelList` — the failure mode this project already paid for

MATLAB's `contour(...,N)` with a scalar N does **not** use `linspace(min,max,N)`. The rule was
**probed**, not inferred: `topoplot.m` was rewritten on the fly to `save()` the Contour object's own
`LevelList` at the `contour(Xi,Yi,ZiC,CONTOURNUM,'k')` call.

    level_k = zmin + k*(zmax - zmin)/(N + 1),   k = 1..N

i.e. `linspace(zmin, zmax, N+2)` with **both endpoints dropped**. `LevelStep` reads 0.2 on the
reference case and is a red herring — `LevelListMode` is `'manual'`, so `LevelStep` is stale.

⚠ **`zmin`/`zmax` are the finite values of the rmax-masked FIELD**, not the electrode readings and
not the colour `maplimits`. Biharmonic overshoot separates them: the readings are `rand` in [0,1]
and the field spans **[-0.010421, 1.217886]**. Two tests pin this, each with the cost of getting it
wrong measured rather than asserted:

| taking the levels from | worst level moves by | as a share of the field range |
|---|---|---|
| the electrode readings instead of the field | **0.178** | 14.5 % |
| the hull-masked field instead of the rmax-masked field | **0.153** | 12.5 % |

Measured, per N, by an independent probe that re-solves the field in C++ and diffs against
`contour_n*_levels.csv` (`R:\dist\_build\topo-ref\`):

| N | levels | max abs diff vs MATLAB |
|---|---|---|
| 0 | 0 (empty — 0 really means none, and MATLAB's lines file is 0 bytes) | 0 |
| 1 | 1 (the midpoint 0.603732275488571 — no off-by-one) | 1.91e-14 |
| 3 | 3 | 4.25e-14 |
| 5 | 5 | 4.86e-14 |
| 8 | 8 | 6.02e-14 |

**Worst level deviation over N = 0,1,3,5,8: 6.02e-14.** That residual is the C++ field re-solve
plus the CSV round trip; the shipped unit test, reading MATLAB's dumped grid instead of re-solving,
measures **7.33e-15**, and the rule error measured inside MATLAB is exactly **0.0**.

<a id="history--contour-geometry--a-distance-not-they-look-the-same"></a>

### ⭐ CONTOUR GEOMETRY — a distance, not "they look the same"

Every level of N = 1, 3, 5, 8 was chained into polylines and compared against MATLAB's own contour
matrix two ways: symmetric nearest-vertex Hausdorff over the vertex sets, and every MATLAB vertex
against the nearest C++ **segment**.

* **polyline COUNT and vertex TOTAL are equal at every one of the 17 levels tested.**
* **worst symmetric Hausdorff: 5.87e-12** (all of it on one level, `0.6037…`, common to N = 1/3/5)
* **worst MATLAB-vertex-to-C++-curve distance: 8.72e-13**
* an analytic cone on a 401×401 grid gives circles to **1.23e-05**, which is exactly the
  `h²/(8r)` chord error of linear edge interpolation — i.e. the residual is the method's, not a bug.

Two rules make that possible and neither is optional:

1. **The three-corner triangle rule.** A cell with exactly three finite corners is contoured as a
   TRIANGLE, the diagonal counting as an edge. Without it the isolines stop one cell short at the
   NaN rim (3–6 vertices per level, all at radius ≈0.4975 of rmax 0.5) and the outermost isoline
   visibly fails to close.
2. **The saddle convention** — resolved on the mean of the four corners. ⚠ **This is the one part
   NOT proved against MATLAB**, and the reason is measured: over EEGLAB's own levels for N = 1..12
   (78 levels) the reference field contains **0 saddle cells**, so MATLAB's vertex sets could never
   have discriminated. It is exercised instead on a synthetic egg-carton field that is nothing but
   saddles — 9 saddle cells, 720 segments, 7 polylines, and **0 proper crossings among 258 840
   segment pairs**. A future field could differ from EEGLAB in CONNECTIVITY inside one cell; never
   in level, never by crossing.

<a id="history--conv--eeglab-does-not-mask-the-field-and-reading-the-source-would-have-got-this-wrong"></a>

### ⭐ `conv` — EEGLAB DOES NOT MASK THE FIELD, AND READING THE SOURCE WOULD HAVE GOT THIS WRONG

Measured: `Zi`, `Xi` and `Yi` are **bit-identical** between `'conv','on'` and `'conv','off'` —
31064 finite of 40000 either way. The only NaN mask topoplot applies is the plotting circle. What
EEGLAB actually does is **draw over** the map: a BACKCOLOR patch at z = +1 whose inner boundary is
the spline hull, occluding the surface *and* the isolines.

The port masks for **display only**. `TopoField`, `sampleGrid()`, `fieldAt()` and `effectiveLimit()`
do not know `conv` exists, so flipping the switch cannot move the colour scale or an isoline.

* **conv-on mask vs MATLAB's own `inpolygon`: 0 of 40000 grid points differ** (24090 inside).
* plain-hull mask: **0 of 40000 differ** (22218 inside).
* spline hull: 195 points, max coordinate error **1.29e-15**; the 14 hull electrodes are
  TP9 FT9 AF7 Fp1 Fpz Fp2 AF8 FT10 TP10 PO8 O2 Oz O1 PO7, cnvfac 13, CIRCGRID 195.
* ⚠ **The start vertex is part of the specification.** The triple tiling leaves a duplicated knot at
  each seam so the spline stalls there; re-running the hull on all 63 rotations of the electrode
  array moves the curve by up to **0.0151 (3 % of rmax)**. The min-index start rule is not a detail.

**`conv off` leaves the field byte-identical to the shipped behaviour, established three ways:**

1. **Code path** — nothing in `TopoField`/`sampleGrid`/`fieldAt`/`effectiveLimit` references
   `m_conv`; with conv off `ensureMasks()` returns immediately and the pixel loop is the original.
2. **Against pre-stage ground truth** — the probe's C++ field diffs against `eegonly_Zi.csv`
   (dumped before this stage) at **2.767e-13**, and the NaN pattern differs in **0** cells. Same
   number as the 21 pre-existing `test_TopoField` cases, which all still pass unchanged.
3. **Live, digit for digit** — the running viewer's `sampleGrid(200)` vs EEGLAB's grid reports
   `max abs 4.1538e-5  relative 3.3817e-5  mask disagreements 0`, which is **character-identical to
   the Stage 2 harness logs taken before this stage existed**. (That 3.4e-5 is the *live metadata
   path*, not the contour work: theta/radius arrive over the stream as float32. Pre-existing,
   unchanged, and noted in `arch_known-issues.md`.)

Also observed and reproduced: with conv on, EEGLAB still draws **every** electrode marker and
label, hull ones and outside-hull ones alike, on top of the blanking patch. The switch limits the
field, not the montage. D2 holds — markers stay black, and so do the isolines.

<a id="history--how-much-of-the-map-is-extrapolation--and-a-correction-to-the-brief"></a>

### ⭐ HOW MUCH OF THE MAP IS EXTRAPOLATION — and a correction to the brief

Computed at runtime from the actual montage (`extrapolationReport()`), never hard-coded; all 13
statistics agree with MATLAB to worst relative **8.33e-17**.

| | |
|---|---|
| inside the plain electrode convex hull (interpolation) | **71.52 %** of the drawn disk |
| **outside it — EXTRAPOLATION with `conv off`** | **28.48 %** |
| what `conv on` leaves visible | 77.55 %, of which **7.77 %** is still outside the plain hull |
| radial extrapolated share of the visible radius | min 2.10 % / mean **15.93 %** / max 22.35 % |

⚠ **"About half the visible radius is extrapolation" does not hold on this montage.** Half is the
right number for a different quantity: **54.00 %** of the visible disk lies outside the *drawn head
circle*, and **52.73 %** of that skirt is extrapolated. The cleanest true statement is that the
hull's minimum radius (0.388250) is already **larger** than the head circle (0.339125), so
**inside the cartoon head there is no extrapolation at all** — every extrapolated pixel is skirt.

Operator-facing wording, D1-terse (the 28 % is computed per montage at runtime):
`conv off` → *"Off: 28% of the map area is extrapolated beyond the electrode hull."*
`conv on` → *"On: map limited to the electrode hull."*

<a id="history--retention--uncapped-never-self-evicting-with-a-2-gb-notice"></a>

### ⭐ RETENTION — uncapped, never self-evicting, with a 2 GB notice

`setUncapped()` grows the ring on demand and never evicts on its own. The 512 MB hard budget is
gone as the default but `setCapacity()`/`setByteBudget()` still give a hard cap if anyone wants one.
Threshold arithmetic is **`bytesResident() + 104 × capacity()`** — samples **plus** the ring's own
bookkeeping, empty slots included, exactly as the note below required.

Proven live on the deployed tree at 512 ch × 10 000 samples = **20 480 000 bytes/epoch**, with the
threshold left at its shipped 2048 MB default:

| | |
|---|---|
| what a 512 MB Stage 4 cap would have held at this shape | **26 epochs** |
| epochs actually held when the notice fired | **105**, `evicted = 0`, `evicting = false` |
| accounted at the crossing | **2050.79 MB** (2050.78 resident + 0.01 ring) |
| `thresholdCrossings` after the crossing and 400+ further epochs | **1** |
| ring growth 8 → 16 → 32 → 64 → 128 slots | `accumulatorRebuilds` stayed **1** throughout |
| after Flush | 8 slots, resident returned, `overThreshold = false`, crossings still **1** |

And at library level, over a run past the Stage 4 capacity at 64 ch × 500 (0.122 MB/epoch):

* 4794 epochs pushed; **at epoch 4194 — one past what 512 MB bought — `evicted = 0`**, capacity
  8192, `oldestSerial` still 0, serial 0 and serial 4793 both still resolvable.
* the fast-path average vs an **independent** full reduction computed outside the class:
  **0 of 32000 doubles differ bitwise**, max abs diff exactly **0**.
* growth with a **live** accumulator (average taken first, then five doublings): `rebuilds` 1 → 1,
  `evicted` 0, and the average over the original serials **0 of 500 doubles differ bitwise**.
* the crossing re-arms only after a flush: `clear()` returns the memory, sets `notifyArmed`, and a
  refill fires crossing **2** — while `thresholdCrossings` is a lifetime total that deliberately
  does not rewind, so a watcher polling it never sees the number go backwards.

**Worked numbers now asserted in `test_EpochStore`:** 2 GB is 16 777 epochs at 64 × 500 and **147**
at 73 ch × 25 kHz × 2 s (against the **36** a 512 MB cap bought). At the degenerate 2 ch × 4 shape,
six epochs are 192 B of samples against 832 B of empty ring — samples alone would read 5× under and
the notice would never fire. That is why the pricing includes the slots.

**`kMaxCapacity = 100000` is now load-bearing and is made visible rather than silent.** Growth
doubles up to the ceiling and clamps; a further epoch latches `ceilingReached`, is **taken**, and
the ring evicts its oldest exactly as a capped one would (refusing it would freeze the live view).
The bookkeeping at that point is **10 400 000 bytes (9.92 MB)** and is counted. It is reported three
ways — the `ceilingReached` property, a distinct `retentionCeilingReached(epochs)` signal with its
own wording, and `[100000-epoch ceiling reached]` in `status()`.

**The notice is a 24 px strip in the layout, not a dialog.** It pushes the plot down instead of
covering it and acquisition continues underneath. Text is D1-terse — *"2051 MB held, over the
2048 MB threshold. 105 epochs kept, none dropped."* — with **Flush** (primary) and **Keep**. Its
`visible` also requires `overThreshold || ceilingReached`, so a flush from anywhere (this button,
the toolbar Reset, a service) takes the strip with it rather than leaving it describing a store
that no longer matches.

<a id="history--stage-6-publishing-was-re-measured-and-is-undisturbed"></a>

### ⭐ Stage 6 publishing was re-measured and is undisturbed

`stage6_cutpublish.ps1 -TargetEpochs 110`. `TcpStreamSender: Ready` per phase:

| phase | Ready lines |
|---|---|
| startup | 1 |
| publish-on (two streams announced) | 2 |
| **publish-established** | **0** |
| **recording** | **0** |
| **epochs-done (111 viewer-cut epochs published)** | **0** |
| window-change (one genuine announcement change, two streams) | **2** |
| stopped | 0 |

**0.00 rebuilds per epoch in steady state over 111 epochs; 1 per stream per genuine announcement
change.** Round trip `RESULT PASS`, 29.67 MB recording written.

<a id="history-binding-loops-1"></a>

### Binding loops

**0** in every run log of this stage: the Stage 6 re-measurement, the topoplot harness (build tree
and deployed tree) and the retention harness (build tree and deployed tree). Five logs, five zeros.

<a id="history-the-evidence-shots-each-described-from-the-image-1"></a>

### The evidence shots, each described from the image

All in `R:\dist\_build\final\` (build tree) and `R:\dist\_build\final\deployed\` (deployed tree),
captured with `PrintWindow(hwnd, dc, 2)` under `QT_QUICK_BACKEND=software`. Every shot puts MATLAB's
own render of the **same 64 numbers** beside the C++ one, because a contour set at the wrong levels
looks perfectly plausible on its own.

* **`final-01-numcontour-0.png`** — neither side draws a single isoline. `contourCount=0`,
  `polylines=0 vertices=0`, level list empty. The colour fields match: dark red frontal-left around
  Fp1/AF7, a green wedge upper-right at Fp2/AF8, red again posterior-left at TP9/P7.
* **`final-02-numcontour-3.png`** — three isolines, black, on both sides. Same closed loops in the
  same places: one at F5, one at CPz, one at POz, one at P2. C++ reports 14 polylines / 2675
  vertices; the exact-arithmetic probe gives 14 / **2677** for these three levels, so the live
  render is two rim vertices short — the float32 metadata path again, not the contour code.
* **`final-03-numcontour-8.png`** — eight isolines. **44 polylines and 6174 vertices, which is the
  probe's total for N=8 exactly.** The dense line packing over the steep frontal-left gradient and
  the small closed ovals at FC4, P1, PO3 and Oz appear identically on both sides.
* **`final-04-conv-off.png`** — the field fills the whole disk on both sides, skirt included.
  Colour limit reads `1.21790e-6`.
* **`final-05-conv-on.png`** — both sides show the same scalloped, non-circular silhouette: a bulge
  at Fp1/AF7, a notch between Fpz and Fp2, indentations at T7/T8, scallops at O1/Oz/O2. The
  isolines stop at the hull on both. ⭐ **The colour limit still reads `1.21790e-6`, identical to
  the conv-off shot** — the switch did not move the scale, visibly and not just in a table. Our
  masked edge is a grid staircase where EEGLAB's is a vector patch boundary; sub-pixel at this size
  but a real difference in mechanism.
* **`final-06-eeglab-pair.png`** — the plain field beside `eeglab_topoplot_eegonly.png`. Same
  pattern everywhere; caption carries `finite 31064, max abs 4.1538e-5, relative 3.3817e-5, mask
  disagreements 0`. ⚠ MATLAB's side carries **six** isolines here because EEGLAB's `numcontour`
  default is 6 and ours is 0 — that difference is deliberate (see below) and this image is where it
  is most visible.
* **`final-07-retention-growing.png`** — `n = 60 of 60 received`, `1171.9 / 2048 MB`, not amber, no
  strip. 64 slots, 58 held, `evicted=0`, `crossings=0`. The caption states what a 512 MB cap would
  have held at this shape: 26. The ring is already **2.2× past Stage 4** with nothing dropped.
* **`final-08-retention-2gb-notice.png`** — ⭐ the amber-bordered strip reading *"2051 MB held, over
  the 2048 MB threshold. 105 epochs kept, none dropped."* with **Flush** and **Keep** on it, the
  status bar amber at `2070.3 / 2048 MB` and `n = 106 of 106 received`. The plot is pushed down, not
  covered, and the count moved 105 → 106 between the crossing and the shutter, which is acquisition
  carrying on underneath the notice.
* **`final-09-retention-flushed.png`** — after the strip's **own** Flush button was activated (the
  harness walks the item tree and emits `clicked()` on the shipped control, it does not reimplement
  the handler): strip gone, readout back to normal colour, `78.1 / 2048 MB`, 8 slots, resident
  39.06 MB, `over=false`, **`crossings=1`** — returned memory, re-armed notice, lifetime count kept.

<a id="history-deliberate-differences-from-eeglab-all-measured-none-accidental"></a>

### Deliberate differences from EEGLAB (all measured, none accidental)

1. **`numcontour` default is 0; EEGLAB's is 6.** The field view shipped without isolines and turning
   them on for everyone would change every map already on screen.
2. **`conv` is a display mask, not an occluding patch.** Same picture, different mechanism; confined
   to display so the field and colour scale cannot move. EEGLAB's patch also extends to 0.526250,
   outside our rmax = 0.5 field entirely — that part is inert and is not reproduced.
3. **The saddle convention is unproven** — see above.
4. **`convexHull` refuses collinear input** (returns empty) where the Python oracle returns a
   degenerate 2-vertex hull. MATLAB's `convhull()` errors on collinear input, so this is *closer* to
   MATLAB than the oracle.
5. **shading `'interp'`** (`rwidth = 0.035*1.3`) is implemented in `convRingRadii()` but the probe
   ran with the default `'flat'`, so only the flat branch is measured against MATLAB.
6. **The hull is built from the whole kind-selected montage**, not the contributing subset — which
   matches `topoplot.m:897`, where `allx`/`ally` are captured before the `pltchans` subsetting.
7. **Levels move with `gridscale`** — EEGLAB's own behaviour. `TopoPanel` pins `gridSize` at 200,
   which is what lands on EEGLAB's numbers; `setGridSize()` invalidates the contours.
8. **Validated against `contour()`, not `contourc()`** — they give the same levels but segment
   differently (2686 vs 2691 columns on N=3). `topoplot` calls `contour()`.
9. **`numcontour` as a VECTOR** is supported by the C++ API (`contourSegments` takes one level, so a
   caller passes its own list) but is not on the QML control, which offers the scalar N only.
10. **Isolines are drawn whenever `numContours > 0`, independently of `showField`** — that is
    EEGLAB's `'style','contour'`. Turning the colour off must not silently kill the isolines.

<a id="history-what-landed-1"></a>

### What landed

`topofield.{hpp,cpp}` — `contourLevels`, `fieldLevels`, `contourSegments`, `chainSegments`,
`convexHull`, `splineNotAKnot`, `convRingRadii`, `convHullPolygon`, `plainHullPolygon`,
`pointInPolygon`, `extrapolationReport`. All Qt-free, all in `test_TopoField`.
`topoview.{hpp,cpp}` — `numContours`, `conv`, `contourCount`, `extrapolatedFraction`,
`contourLevels()`, `contourPolylines()`, `convHull()`, `extrapolationInfo()`, and four dirty flags
keyed on GEOMETRY (`m_hullDirty`/`m_maskDirty`/`m_contourDirty`/`m_extrapDirty`) so a new epoch
never recomputes a 40000 × 195 point-in-polygon pass.
`epochbuffer.{hpp,cpp}` — `Retention{Count,Budget,Uncapped}`, `setUncapped()`,
`setNotifyThreshold()`, `bytesOverhead/bytesAccounted/overThreshold/notifyArmed/thresholdCrossings/
bytesAtCrossing/ceilingReached`, `bytesResident()` now O(1) with an independent-sum test holding it
honest, and `clear()` genuinely returning the memory.
`epochreceiver.{hpp,cpp}` — uncapped + 2 GB by default, `retentionSummary` as the single source the
strip/tooltip/status all quote, and `retentionThresholdCrossed` / `retentionCeilingReached`.
QML — `TopoPanel.qml` (Contours field, Hull checkbox), `Settings.qml` (`head_field_contours`,
`head_field_conv`), `EpochView.qml` (the readout's new meaning and the notice strip).
Harnesses — `R:\config\topo_final_shot.{qml,ps1}`, `retention_final_shot.{qml,ps1}`.

**One fix folded in along the way:** `Settings.qml`'s doc comment on `epoch_budget_mb` still
described a hard cap ("the capacity the viewer reports is derived from this"), which the retention
change made flatly wrong. Rewritten to describe the threshold, the 512/<16 screening and the
104-byte slot pricing. Comment only — rebuilt, full suite re-run (572/18/0), redeployed, and the
deployed tree re-verified to the same numbers.

**Reproduce any of it yourself:**

```
py -3.12 R:\config\topoplot_v4_reference.py            # SELFTEST PASS: field, contours, conv
R:\dist\_build\msvc64\tests\test_TopoField.exe          # 43, incl. every EEGLAB comparison
R:\dist\_build\msvc64\tests\test_EpochStore.exe         # 35, incl. Uncapped/NotifyThreshold/Ceiling
R:\config\topo_final_shot.ps1      -OutDir R:\dist\_build\final   # the six topoplot shots
R:\config\retention_final_shot.ps1 -OutDir R:\dist\_build\final   # the three retention shots
R:\config\stage6_cutpublish.ps1    -OutDir R:\dist\_build\final -TargetEpochs 110
```

Add `-Runtime R:\dist\msvc64` to any of the three `.ps1` harnesses to run the DEPLOYED tree instead
of the build tree; all three were run both ways and reported the same numbers.


<a id="history-stage-6---built-proven-deployed-2026-08-20"></a>

## Stage 6 — ✅ BUILT, PROVEN, DEPLOYED (2026-08-20)

**541 tests / 18 executables, 0 failures** (was 497/17). `test_EpochAnnounce` adds 32; the Stage 0
debt adds 12 (six in `test_SignalGenerator`, six in `test_TepSound`). Core targets unchanged:
`test_StreamInfo` 18, `test_SamplesCollector` 1, `test_NetworkMode` 10 cases. (`test_RecorderPath`
still exits 2 unless `RESONANCE_RECORD_PATH` is set — pre-existing, env-gated, not a failure.)
`ninja -t deps` reports `(VALID)` on every changed object, so the header deps really were recorded.

The viewer is now a producer. Two `Parameters::String` slots — `plotN_publishAverage` and
`plotN_publishEpochs`, declared at `parameter_index + 4` and `+ 5` — name the output streams, and
**the name IS the switch**: empty publishes nothing, which is the default, so a viewer never
silently starts producing. Everything else (`epoch_publish_counters`) is a settings-blob key.

<a id="history--the-round-trip--the-acceptance-test-and-it-is-a-file-not-a-screenshot"></a>

### ⭐ THE ROUND TRIP — the acceptance test, and it is a file, not a screenshot

`R:\config\stage6_roundtrip.{qml,ps1}` runs a generator, TWO viewers and a real `recorderService`
in four processes. Viewer A subscribes to the generator's epoch lane and publishes `rt_average` +
`rt_epochs`; viewer B is an **independent subscriber to A's published average**, over the network;
the recorder writes the generator's source epochs *and* both of A's streams to HDF5.
`R:\config\stage6_roundtrip.py` reads the file back.

| what | measured |
|---|---|
| ⭐ **worst absolute sample difference**, source epoch vs the viewer's republished epoch, matched on `created`, 129 blocks × 500 samples × 67 channels | **0.0 — bit-identical** |
| the average vs the epochs it is an average of (recovered algebraically from consecutive blocks) | 1.14e-13 abs, **5.7e-14 relative** |
| length invariant `(end-start)/1000*rate == samples` | **0.0 samples error**, on every channel of both streams |
| `window_start_ms` | present, **−100 on 69/69 and 67/67 channels** |
| `window_end_ms` | 400, exclusive |
| `epoch_kind` / `epoch_stamp` | `average`/`none` on the average, `trial`/`trigger` on the epochs |
| `unit`, `kind`, `name`, `theta`, `radius` | all survive; `theta`/`radius` `null` on Trigger and on the counters |
| `epoch_average_method` / `_scope` / `epoch_bin_scope` / `epoch_bin` | `mean` / `all` / `all` / empty |
| `n_contributing`, `n_received` | last two data columns, constant down each block, non-decreasing, `received >= contributing` always |

Reproduced identically on the **deployed** tree (`R:\dist\msvc64\data\stage6-roundtrip-001.h5`).

⚠ **The published average carries float32-quantised inputs, and that is Stage 4's byte budget,
not a Stage 6 defect.** `EpochBuffer`'s history ring stores epochs as `std::vector<float>`
(`epochbuffer.hpp:625`) while the accumulator and the wire are `double`. Against the float64
source the recovered epoch differs by 2.3e-10; against the source rounded to float32 exactly as the
ring stores it, by 1.1e-13. The three-way confirmation is that the **Trigger channel — small
integers, exactly representable in float32 — differs by exactly 0.0**. Worth one line in an
analysis note: an operator saving an average is saving the mean of float32 samples.

<a id="history--publish-once-send-many--the-number-that-would-have-caught-the-generator-defect"></a>

### ⭐ PUBLISH ONCE, SEND MANY — the number that would have caught the generator defect

`TcpStreamSender: Ready` lines in the viewer's own log, counted between harness phase markers.
The generator defect measured **4.02 rebuilds per parameter edit**; here:

| phase | Ready lines |
|---|---|
| startup (the process's own service description) | 1 |
| **publishing turned on** | **2** — one per new output stream, which is correct |
| **101 arriving epochs, 101 averages, 101 relayed epochs published** | **0** |
| **a genuine announcement change** (counters off: 69 → 67 channels) | **1** |

**0.00 rebuilds per epoch**, and **1.00 per genuine change.** Both halves matter: a stream that
never republishes is as broken as one that always does. `publishRebuilds` is on the epoch viewer's
own caption line, so an operator can see a port moving under their consumers — otherwise invisible
from the producing side.

The window is the other legitimate trigger, and it costs **one rebuild per stream**: moving
`epoch_cut_post_ms` 400 → 500 ms rebuilt both `cut_average` and `cut_epochs` exactly once each
(2 total), and the subscribed consumer followed to `-100..+500 ms` / 600 samples and kept receiving.

**No gap for a subscribed consumer**: viewer B received **101 of 101** average blocks while the
average was updating; worst run of consecutive silent seconds = **0**.

<a id="history--epoch_stage--proven-on-the-viewer-cut-path-where-the-viewer-actually-knows-it"></a>

### ⭐ `epoch_stage` — proven on the viewer-CUT path, where the viewer actually knows it

On the relay path `epoch_stage` is correctly **absent**: the generator declares none, and the
contract's word for "unknown" is an absent key. That left the one contract key whose value this
stage *computes* unexercised, so `R:\config\stage6_cutpublish.{qml,ps1,py}` runs the Stage 5 path
with the display filter deliberately **left on**. Result, out of the recorded file:

* `cut_epochs`: **32 `preprocessed` + 1 `raw`**, per channel — the EEG channels went through the
  3–35 Hz Butterworth-4 and the 50 Hz notch, the Trigger lane is drawn as bits and bypasses the
  chain and says so **in the same announcement**. A harness reading only entry 0 would never see it.
* `cut_average`: 34 `preprocessed` + 1 `raw` (the two counter channels inherit the stage).
* `epoch_stamp` `trigger` on the epochs, `none` on the average; average = running mean of the
  published epochs to **1.4e-14** relative.

This is what stops a downstream analysis silently inheriting the filter's measured +20 ms group
delay.

<a id="history--a-framework-sharp-edge-found-along-the-way--not-a-stage-6-defect-but-it-looks-like-one"></a>

### ⚠ A FRAMEWORK SHARP EDGE FOUND ALONG THE WAY — not a Stage 6 defect, but it looks like one

Two cut-path runs recorded **zero blocks** for `cut_epochs` while the viewer's own counter said 74
had been sent. An independent live consumer attached to the same stream received them throughout,
so the blocks were on the wire the whole time. The cause is **recorder slot resolution**: the
harness pressed `start` 3.6 s after setting the second slot, discovery had resolved `cut_average`
but not `cut_epochs` by then, and a slot that has not resolved when recording begins never picks
the stream up for the rest of the session. The file still gets a `streamInfo` group and a
placeholder row, **so it looks like a recorded stream**. Confirmed by a controlled run: ~12 s of
settle, consumer attached only after `start`, and `cut_epochs` recorded 44 blocks.
→ A recording harness must let every slot resolve *before* `start`. `siggen_record_harness.qml`
already spaces its slots for this reason; that spacing is not decoration.

<a id="history-the-evidence-shots-each-described-from-the-image-2"></a>

### The evidence shots, each described from the image

All in `R:\dist\_build\stage6\`, `PrintWindow(hwnd, dc, 2)`.

* **`s6-01-kindfilter.png`** — the OFF state. Viewer A on `epochs@RTGEN`, 67 rows, n = 12 of 12,
  `Pub avg` / `Pub epochs` **not** highlighted, `REBUILDS=0 sent avg=0 epochs=0`. Viewer B's panel
  is empty and reads "Drag stream here". This is what a viewer that has not been told to publish
  looks like: nothing on the network.
* **`s6-02-publishing-on.png`** — both publish buttons now green, status
  `average -> rt_average (5 sent), epochs -> rt_epochs (4 sent), 2 rebuilds`. Viewer B has just
  resolved and shows **69 rows** (67 + the two counters), captioned
  `epoch #3 · 69 ch × 500 · -100..+400 ms · average/t0=none`.
* **`s6-03-roundtrip-viewerB.png`** — ⭐ the round trip on screen. A's butterfly (n = 23 of 23) and
  B's are the same picture, drawn from two different sources: A from its own memory, B from the
  network. B's caption carries the metadata that arrived with it.
* **`s6-04-after-100-epochs.png`** — n = 156 of 156 and the average is visibly tighter than at
  n = 23; `rt_average (143 sent), rt_epochs (142 sent), 2 rebuilds`. **142 epochs published, still
  2 rebuilds** — the whole claim, in the caption of one picture.
* **`s6-05-announcement-change.png`** — counters off. A says `REBUILDS=3`; **viewer B's row count
  has moved 69 → 67**, it reconnected on its own and is receiving again (`epoch #154`). The
  republish is visible, and it happened once.
* **`s6-06-cut-published.png`** — the viewer-cut path: the continuous sweep with its trigger
  labels on top, the cut epoch view publishing below (`cut_average` 69 sent / `cut_epochs` 68 sent,
  2 rebuilds), and at the bottom the independent consumer of `cut_epochs` holding 43 epochs,
  captioned `trial/mixed/t0=trigger` — `mixed` being the collapsed reading of the two-valued
  per-channel `epoch_stage`, exactly as designed.
* **`s6-07-cut-window-change.png`** — the same three panels after the window moved: both now
  `-100..+500 ms`, 600 samples, axis out to 480 ms, consumer refilled and still receiving.
* **`s6-08-topo-kind-EEG.png`** / **`s6-09-topo-kind-EMG.png`** — the `kind` filter, below.

<a id="history--the-kind-filter-exercised-for-the-first-time"></a>

### ⭐ THE `kind` FILTER, EXERCISED FOR THE FIRST TIME

`R:\config\stage6_kindfilter_shot.{qml,ps1}`, over one 64 EEG + 2 EMG + 1 Trigger epoch stream
whose per-channel kinds the generator now publishes honestly (EEG 64, EMG 2, Trigger 1).

| `topo.kind` | channels passing | `plotrad` | `squeezefac` |
|---|---|---|---|
| `"EEG"` | **64 of 67** | **0.678218** | 0.737226 |
| `"EMG"` | **2 of 67** | **0.756412** | 0.661016 |

The pair is what proves it, and the second reading is the load-bearing one. `s6-08` is a full
64-electrode scalp map, every marker black (D2 held), captioned "64 of 67 channels". `s6-09` is the
same stream with the filter moved to EMG: **two black markers, EMG1 and EMG2, drawn above and
outside the head circle**, and the field politely refuses — "a scalp map needs at least 3
contributing channels, got 2" — rather than inventing one. So those two channels **do** carry
scalp positions; in `s6-08` they were kept off the head **by `kind`**, not for want of a position.
That is the filter working, and it could not have been shown before this stage.

⚠ **One correction to the brief.** The expected numbers 0.678 → 0.756 were described as the EMG
pair "inflating the head by 50%". They do not: 0.756412 / 0.678218 = **+11.53 %**, which is what
`topoview.hpp`'s own header has said all along ("two non-scalp channels stretch the montage by
11.5%"). The plotrad values are exactly as predicted — measured 0.678218 / 0.756412 against a
predicted 0.678215 / 0.756409, a 3e-6 difference; `topofield_test.cpp:312` pins 0.678215. Only the
percentage in the brief was wrong.

<a id="history-binding-loops-2"></a>

### Binding loops

**0**, in every run, on both the build tree and the deployed tree. Stage 5 took this 1800 → 0 and
it has stayed there.

<a id="history-what-landed-2"></a>

### What landed

`epochannounce.{hpp,cpp}` (new, Qt-free: the announcement struct, the NaN-equal equality guard,
`EpochPublishSpec`, `epochWindowEndMs`, `buildEpochAnnouncement`), `EpochOutputStream` added to
`timeseriessender.{hpp,cpp}` (publish/unpublish/sendInterleaved/sendChannelMajor, the process-wide
claimed-name registry, `canSend`'s three refusals including the zero-`created` trap),
`epochreceiver.{hpp,cpp}` (the publishing properties and the two streams; the average is sent from
the END of `refreshAverage()` and nowhere else, so the plot and the stream can never describe
different reductions), `timeseriesreceiver.{hpp,cpp}` (`cutStageList`), and the three QML files.

One build fix was needed: `tests/epochannounce_test.cpp` bound a reference into a **temporary**
announcement (`strings(buildEpochAnnouncement(spec), "unit")`), which dangles at the end of the
full expression and read a size of 0 — reporting a key as missing that is actually written. The
implementation was correct; the test now holds the announcement in a named local.

New harnesses, all reusable: `stage6_roundtrip.{qml,ps1,py}`, `stage6_cutpublish.{qml,ps1,py}`,
`stage6_kindfilter_shot.{qml,ps1}`.

<a id="history-still-open-after-stage-6"></a>

### Still open after Stage 6

* **A second viewer publishing under the same name** is refused by the process-wide registry and
  says so on its caption. Not exercised on the rig — the round trip used one publisher.
* **The `(epoch_kind, epoch_stage)` uniqueness rule** in `epoch_contract_check.qml` will report a
  collision for two publishing viewers in one Configurator, which share a service name. They are
  distinguished by stream NAME, which is how a consumer selects them. Not contorted around.
* **`averageWindow` coalescing.** Dragging the "Last N" spinner republishes per distinct value.
  Bounded by operator clicks and visible on `publishRebuilds`; no timer added pre-emptively,
  because an unmeasured mitigation is how a second source of truth gets introduced.
* **No condition LABEL on the published epoch stream** — by design; join on the trigger RTC against
  the recordable `plotN_markers` stream, or point the average at one bin.
* **Median / trimmed-mean averages have not been published on the rig.** The round trip used
  `mean`; the method reaches the metadata as `epoch_average_method` and a change to it republishes,
  which is tested in `test_EpochAnnounce` but not measured live.


<a id="history-stage-5---built-proven-deployed-2026-08-20"></a>

## Stage 5 — ✅ BUILT, PROVEN, DEPLOYED (2026-08-20)

**497 tests / 17 executables, 0 failures** (was 459/16; `test_Epocher` adds 38 — its original 37
plus one regression added below). Core targets unchanged: `test_StreamInfo` 18,
`test_SamplesCollector` 1, `test_NetworkMode` 10 cases.
Rollback: **`bin.pre-stage5-20260820-152618`**. Evidence: **`R:\dist\_build\stage5\`**.
Harnesses: `R:\config\epoch_cut_shot.qml` / `.ps1` (live camera + the label probe),
`R:\dist\_build\stage5\align_proof.cpp` (the offline proof).

<a id="history--the-alignment-is-zero-samples-proven-three-ways-and-twice-outside-the-epocher"></a>

### ⭐ THE ALIGNMENT IS ZERO SAMPLES, PROVEN THREE WAYS AND TWICE OUTSIDE THE EPOCHER

**Error: 0 samples = 0.000 ms.** Block size 100 samples = 100 ms, so the one-block bug this stage
was most at risk of would have shown as 100 (or 99) samples, not as a rounding wobble.

1. **Offline, against signalGenerator's own model** (`align_proof.cpp`, links `eegmodel.cpp`,
   `synth.cpp` and `announcement.cpp` straight into the test — none of which know the Epocher
   exists). Shape `gauss` is built with `zeroIndex = 0` (`eegmodel.cpp:242`) and the `n` that sets
   `m_trigWord` is the same `n` pushed onto `m_evokedActive` (`:320-324`), so the response PEAKS on
   the trigger sample by construction. Peak landed on `zeroSample()` exactly, at 1000 Hz/block 100
   **and** at 2048 Hz/block 173 (samples 1024, zeroSample 205 — nothing divides evenly).
2. **Offline, against the producer's own epoch-lane waveform.** Both lanes render the same
   `epochWaveform` from the same `epochShape`/`epochWidthMs`/`epochFreq` parameters
   (`service.cpp:1223-1226`). Post-stimulus worst difference **1.478e-08** (float32 ring
   precision; FLT_EPSILON is 1.192e-07), **best-fitting shift 0 samples**.
3. **Live, in the viewer, both sides on screen at once** (`cut-02-viewer-vs-producer.png`):
   viewer-cut peak at sample 100, producer-cut peak at sample 100, **both ERROR 0 samples**;
   post-stimulus worst |viewer − producer| **0.0000** over 400 points, **best-fitting shift 0**.
   Re-run against the **deployed** tree and reproduced identically.

**The stamp knob is load-bearing, and that is asserted rather than assumed.** Route A is immune to
`created` (its index is `base + n`): declaring the stream `first`, `last` or `Unknown` gives a
bit-identical epoch. Route B, which does use the stamp, is wrong by **exactly one block (±99
samples)** when the stamp is mis-declared, and REFUSES with `unusable-stamp` on
`TriggerInstant`/`Unknown` rather than returning a plausible number. If the mis-declared case were
*not* wrong, the correct cases would have been luck.

⚠ **Two measurement traps this proof had to climb out of, both of which first produced a
confident wrong number.** Recorded because they will catch the next person too:

* **Do not search for the peak on the trigger column.** The trigger word is an integer 1..255
  against ~50 µV of EEG, so it wins any magnitude search by four orders of magnitude — and it sits
  at t=0 *by construction*, because finding that edge is how the window was chosen. The first live
  measurement reported "peak at sample 100, ERROR 0" off channel 32, which is the Trigger channel:
  a perfectly circular result proving only that the epocher agrees with itself. The evoked
  response is the independent witness.
* **Do not compare the two sides through the display filter.** The viewer ships 3-35 Hz
  Butterworth-4 plus a 50 Hz notch ON by default (`Settings.qml:191-200`) and the epoch tap is
  deliberately *after* it, while the producer's epoch lane is not filtered by the viewer at all.
  Measured: the group delay moves the feature **+20 ms**, i.e. 20 samples, which reads exactly like
  an alignment bug and is not one. The harness switches the filter off for the comparison and says
  so in the caption. **This is a real property of the shipped feature, not a rig artefact — an
  operator checking latencies against a viewer-cut epoch is looking at filtered data.**

<a id="history--defect-found-and-fixed-viewer-cut-epochs-were-taking-the-previous-events-label"></a>

### 🐞 DEFECT FOUND AND FIXED: viewer-cut epochs were taking the PREVIOUS event's label

Found by the live rig, not by the unit tests, and it is exactly the failure mode this stage was
warned about: a per-condition average that is stable, repeatable, plausible and **wrong**.

A producer places its event at `floor((rtc - anchor) * rate)`, so the row the edge is FOUND on is
up to one full sample EARLIER than the instant that caused it, and `rtcForIndex()` faithfully
reports that earlier instant. Comparing it against the marker's own rtc at zero tolerance
therefore misses the marker belonging to this very trigger and silently takes the previous one.

**Measured before the fix: 19 of 23 epochs in the wrong condition** (`-LabelProbe`, allowance 0).
**After: 23 of 23 correct, zero wrong**, at the same strict allowance of 0.

⚠ **A bin RATIO cannot catch this, which is why the probe does not use one.** Every cyclic label
list keeps its ratio under a one-event shift — `left,right,left` shifted is still 2:1 — so the
headline per-condition shot would have looked perfect throughout. `epoch_cut_shot.ps1 -LabelProbe`
instead makes labels `target,standard` with codes 1,2 *in phase*, so only `target` events set bit
0 and every epoch that exists must be `target`: correct is 100% one bin, off-by-one is 100% the
other, and there is no ratio to interpret.

Fix: `Epocher::markerHorizon()` = `triggerRtc + markerAllowanceMs + one sample period`. The
allowance stays what it says it is (how late a PRODUCER may be); the sample period is the sample
grid's own precision, and the two add. Bounded on purpose — two samples late is still a visible
miss, not a wrong answer. Regression test:
`EpocherLabels.AMarkerInsideOneSampleOfTheTriggerStillClaimsIt`.

⚠ **Also worth knowing when configuring a rig:** with the generator's default *incrementing* code
the codes cycle 1,2,3 while `left,right,left` cycles in phase, so every `right` event carries code
2 — **bit 0 clear, no rising edge, not one `right` epoch ever cut**. 29 triggers for 47 events, all
of them `left`. The bins still looked populated because the labelling was picking up neighbouring
markers. A trigger bit and a condition label are independent choices and nothing warns you.

<a id="history-the-four-evidence-shots-each-described-from-the-image"></a>

### The four evidence shots, each described from the image

* `cut-01-known-truth-at-zero.png` — one viewer-cut epoch. Evoked peak at sample 100, t=0 is
  sample 100, **ERROR 0 samples**, measured on EEG channel 9 with trigger column 32 excluded. The
  trigger column itself reads 0 at sample 99 and 1 at sample 100. Sweep on the left with the `Cut`
  button green, epoch view beneath it, producer-cut lane on the right for comparison.
* `cut-02-viewer-vs-producer.png` — **the alignment proof as a picture.** Viewer-cut average
  (n=24, `origin=viewer`) beside producer-cut average (n=41, `origin=stream`); both peaks on
  sample 100, post-stimulus worst 0.0000, shift 0. The pre-stimulus halves differ by 0.9997 at
  t=−1 ms and that is *correct*: the epoch lane draws the full gaussian (σ=40 ms) across negative
  time while the continuous lane has not started, so the viewer-cut pre-stimulus max is exactly
  0.0000 — silent, as an evoked response must be before its stimulus.
* `cut-03-per-condition-markers.png` — per-condition binning from the REAL `stimuli` stream, not
  `nextLabel` poked by the harness. Viewer-cut `left` n=22 / `right` n=10; producer-cut `left`
  n=25 / `right` n=12; **zero unlabelled on either side**, `labelRule=rtc` on both. Two conditions,
  different n, each labelled, left panel showing `left` and right panel showing `right`.
* `cut-04-refusal-counted.png` — pre-stimulus window set to −600000 ms so the window opens long
  before the stream did: **9 triggers, 0 epochs, 9 refused `incomplete`**, `refusedTotal=9`, with
  the count in the viewer's own status line (`refused 11 (incomplete 11)`), the epoch panel empty
  — nothing padded, nothing emitted short — and the producer-cut side still working as a control.
  The `Cut` button is amber (watching) rather than green (producing).

<a id="history--binding-loop-1800-occurrences--0"></a>

### 🐞 Binding loop: 1800 occurrences → **0**

`PlotView.qml` `scaleBarLayer`. Was ~4.5 per parameter edit (1800 over 400 rounds in the
republish-fix logs). **Measured 0 in every Stage 5 run**, including the deployed-tree verification.
The closing link — `onHeightChanged: rebuild()` on the layer, whose own height is not an input to
`scaleBar()` at all — was removed and the two real inputs (`plot.onHeightChanged`,
`plot.onStackedChanged`) added to the existing `Connections`. That also fixes a latent defect: a
plot resize used to leave the bar at its old pixel length with a stale label.

<a id="history--capture-note-for-the-next-harness"></a>

### ⚠ Capture note for the next harness

`PrintWindow(hwnd, dc, 2)` returns TRUE and yields an **empty client area with a correct title
bar** on the default Qt Quick scene graph — the render thread draws into a GL surface `WM_PRINT`
never reaches. First Stage 5 run produced four identical 16 627-byte PNGs this way. Setting
`QT_QUICK_BACKEND=software` renders into a DIB that PrintWindow can read; slower, pixel-identical.
`epoch_cut_shot.ps1` sets it.

<a id="history-what-landed-the-wiring-itself"></a>

### What landed (the wiring itself)

* **The epocher core** (`epocher.{hpp,cpp}`, 37 GTests, written earlier in the stage) is now wired
  into the viewer. `TimeSeriesReceiver` owns an `Epocher`, taps the **undecimated post-filter,
  pre-baseline** sample inside its existing per-sample loop, and pushes one sample-major block per
  transport block along with the **untouched trigger column taken before re-referencing**.
* **Route A only.** The trigger is an edge on a lane *inside* the source stream, so its sample index
  is `base + n` exactly and no `created` interpretation enters the alignment. `plotN_trigger` is
  DECLARED (`StreamView.qml`, index `parameter_index + 3`) and deliberately unread — a cross-stream
  trigger can only be placed by comparing timestamps, and a continuous stream does not publish what
  its own timestamps name.
* **One door.** Viewer-cut epochs enter `EpochReceiver::takeViewerEpoch` → `EpochBuffer::addWithKey`,
  so the store, the average, all three renderings and every caption are unchanged. `beginViewerCut`
  inherits the continuous stream's per-channel metadata, or the head map and topoplot lose `kind`.
* **The caption says which kind.** `EpochReceiver::epochOrigin` is `"stream"` or `"viewer"` and
  leads both `status()` and `EpochView`'s caption as `producer-cut` / `viewer-cut`.
* **Refusals are counted and on screen.** `TimeSeriesReceiver::cutStatus()` is pushed into
  `EpochReceiver::setCutSummary` and appears in the caption itself, not only in a tooltip.
  ⚠ `EpocherCounters::refused` is the REFRACTORY count alone; the total is the sum of eight fields.
* **`plotN_markers` is now read.** A second `MessageReceiver` in `StreamView.qml` feeds a shared
  `MarkerLog` (lifted out of `Epocher` so one implementation serves both paths). A producer-cut
  epoch is labelled by comparing the marker's rtc against the epoch's TRIGGER INSTANT, recovered
  from `created` and the stream's declared `epoch_stamp`; `nextLabel` remains as the latch fallback
  for a stream whose stamp names nothing, and the caption says which rule is in force
  (`labels=rtc` / `labels=latch`).
* **`created` convention exposed**, never inferred: settings key `epoch_cut_stamp`, default
  "names the last sample" (the amplifier convention).
* **Both views on screen at once** while cutting (`StreamView.qml` `cutMode`) — the sweep is where
  the alignment is being checked against.

✅ **All of the above is now built, run and proven** — see the top of this section. The alignment
reference used was exactly the one this note called for: signalGenerator firing one scheduled event
into three places (`SignalGenerator/service.cpp:1503-1537`). `epoch_cut_shot.qml` is the harness
config that turns the continuous and epoch lanes on together; `epochdemo_generator.json` is left
alone as the Stage 1 demo.

<a id="history-still-open-after-stage-5"></a>

### Still open after Stage 5

* **`plotN_trigger` is declared and deliberately unread.** Route B works in the core and is proven
  by test, but nothing in the viewer calls it: a cross-stream trigger can only be placed by
  comparing timestamps, and a continuous stream publishes no `epoch_stamp` to say what its own
  timestamps name. The slot exists so a hardware-trigger rig needs no configuration migration.
* **The display filter rides into the epochs** (see the trap above). Deliberate — filter the
  stream, then cut, as tepService does — but it means a viewer-cut epoch is filtered data, and the
  group delay is real (+20 ms measured with the default 3-35 Hz Butterworth-4). Worth a caption or
  a panel note in a later pass.
* **A filter or reference change throws away the running average** (`resetCutting()` clears the
  sink). Correct — mixing pre- and post-filter epochs gives a stable, wrong answer — but heavier
  than it looks from the button, and probably wants an explicit confirm.
* **No Qt-side automated tests.** The epocher core has 38; the tap, the door, the marker handler
  and the caption are covered only by the live harness, because the existing GTest targets link
  pure-logic files only.
* **`EpocherCounters::refused` is the REFRACTORY count alone**, not a total. `cutStatus()` and
  `cutCounters["refusedTotal"]` sum all eight reasons. Anything reading these must not quote
  `refused` as the total.


<a id="history-stage-4--done-proven-deployed-2026-08-20"></a>

## Stage 4 — done, proven, deployed (2026-08-20)

448 tests across 16 executables, 0 failures (was 423/15; `test_EpochStore` adds 25).
*(Now **459/16** — the republish fix below added 11 to `test_SignalGenerator`, plus 6 to
`test_StreamInfo`, which is one of the Core targets and outside this count.)*
Evidence: **`R:\dist\_build\stage4\`** — twelve screenshots plus harness logs.
Harnesses: `R:\config\epoch_average_shot.qml` / `.ps1` (the camera),
`epoch_freeze_probe.qml` / `.ps1` (the bisection probe that found the stall below).

To re-measure the republish behaviour in one command — it is the only harness in this set that
needs a *pair* of viewers and a producer poked while running:

```powershell
# content-only edit: must show a flat ~periodMs/2 gap and ZERO streams rebuilt
R:\config\republish_gap_probe.ps1 -Republishes 400 -Tag check -OutDir R:\dist\_build\republish-fix `
    -GenName RFIXA -Poke epochAmplitude -Churn
# a republish that IS required: must show exactly ONE stream rebuilt and a flat ~1.2 s gap
R:\config\republish_gap_probe.ps1 -Republishes 960 -Tag checkS -OutDir R:\dist\_build\republish-fix `
    -GenName RFIXB -Poke epochChannels -PokeA 32 -PokeB 33 -SettleMs 800
R:\config\republish_verify.ps1 -Base <the base the runner printed> -OutDir R:\dist\_build\republish-fix
```

⚠ `-GenName` matters. Two harnesses on one host share the UDP 13370 discovery domain and the
service name is the only thing separating them.

**The reductions agree with numpy EXACTLY.** Six cases — odd n, even n, NaN holes, rejected
epochs, the n=10 trim boundary, and a case under eviction — reduced by `EpochBuffer` and again by
`numpy`/`scipy.stats.trim_mean` over the same float32 values: worst relative disagreement **0.0**
across all four methods and every point. Convention compared against: the percentage is the TOTAL
removed, half per end (MATLAB's), cut = `floor(n*percent/200)` = MATLAB's `'floor'` =
`scipy.stats.trim_mean(x, percent/200)`. At n=10 `TrimMean10` **is** the mean (cut 0); MATLAB's
DEFAULT `'round'` would have cut one per end, i.e. 20% for a setting that says 10%.
Harness: `…\scratchpad
umproof\proof.cpp` + `compare.py`.

**Noise reduction, measured rather than described.** Same view, same PINNED ±150 µV scale:
baseline RMS (−95…−5 ms, where the true signal is zero) **22.14 µV and 21.83 µV** for two single
epochs → **2.84 µV** for the mean of 61. Factor **7.75**, against √61 = **7.81** — 0.8%.

**Ingest cost on the GUI thread** (`EpochBuffer::add` = transpose + narrow to float32 + extend the
running total; the receiver's per-epoch work beyond it is O(1)):

| shape | B/epoch | cap @512 MB | add | mean, rebuild | mean, cached | median |
|---|---|---|---|---|---|---|
| 64 × 500 | 128 000 | 4194 | 0.040 ms | 6.0 ms | **0.08 ms** | 14.3 ms (n=200) |
| 64 × 701 | 179 456 | 2991 | 0.051 ms | 8.3 ms | 0.11 ms | 20.1 ms (n=200) |
| 64 × 2000 | 512 000 | 1048 | 0.133 ms | 11.9 ms | 0.30 ms | 26.3 ms (n=100) |
| **73 × 50000 @ 25 kHz** | 14 600 000 | **36** | **7.88 ms** (max 8.30) | 111 ms | 7.2 ms | **237 ms** (n=30) |

End to end in the live viewer at 64 × 500: **0.50 ms mean, 1.83 ms max** over 62 epochs, against a
4.9 ms paint. `rebuilds=1` throughout — the accumulator is built once and only ever extended.
⚠ The one number to watch is the **median at 25 kHz: 237 ms per recomputation**. It fits inside a
2 s stimulus interval but it is a visible hitch, and it is the case a worker thread would be for.

**🐞 Found while capturing — NOT in the averaging.** Changing any `epoch*` generator parameter
while a viewer is attached republishes the stream, and the epoch stream then goes quiet for tens
of seconds. Bisected with `epoch_freeze_probe.ps1`, which exonerates the store, the byte budget,
the bins, `frozen`, the pinned scale and the butterfly — all survive. The capture is therefore
taken in two runs (`-To 8`, then `-SkipTo outlier_setup -From 9`); the second is the only one that
needs a mid-run parameter change.

✅ **RESOLVED 2026-08-20 — fixed, built, re-measured, deployed. See
[known-issues §21](../incidents/README.md).**

The same probe that found it now reports, on the operator's own scenario (poke `epochAmplitude`,
`periodMs=300`, settings write-back on): **epoch gap median 38 215 ms → 250 ms, max 70 620 ms →
299 ms, slope +2699.9 ms per republish → −0.0001**, over **400** republishes instead of the 24 the
old build survived. The 250 ms that remains is the measurement floor — an epoch block only exists
every `periodMs`. `TcpStreamSender: Ready` fires **7 times in 400 rounds**, all at start-up: a
content-only edit no longer touches the wire at all. When a republish genuinely IS required
(`epochChannels` 32↔33, 960 rounds) **exactly one** stream is rebuilt instead of 4.02, the gap is
flat at the framework's own ~1.2 s reconnect, and the EEG stream never notices.
Data: `R:\dist\_build\republish-fix\`; summariser `R:\config\republish_verify.ps1`.
`epoch_freeze_probe.ps1` with every switch on still reports **SURVIVED**, and now shows the epoch
count *rising* across the amplitude change that used to freeze it (`received=20` → `received=24`).

Three things this note said were wrong:

1. **It is not a reconnect.** The reconnect is **0.2–2.0 s, median ~1.2 s**, identical on a
   continuous stream and an epoch stream, over 320 consecutive republishes. `isSimilar()` is not
   implicated. The remaining tens of seconds are the producer emitting nothing while the
   consumer holds an established socket to the current port.
2. **It is not a fixed 40–60 s.** It **grows by roughly the interval between republishes** —
   8.5 s at the first, 70.6 s at the twenty-fourth, no ceiling — and becomes *permanent* once
   republishes arrive faster than the run clock can pay off the debt (measured: dark for 570 s
   straight). 40–60 s was simply where that session happened to be.
3. **It is not epoch-specific.** One schedule feeds the trigger channel, the evoked response and
   the `stimuli` message lane as well, so all of those stop too while the continuous streams look
   perfectly healthy.

The cause was in `signalGenerator`, not in Core and not in Stage 4: `onApplyPending()` re-anchored
the run clock without rewinding the event schedule, and `publishAll()` rebuilt all five streams
for any parameter write, including ones that change no description at all.

⚠ **The cumulative GUI wedge did not reproduce** — not at 320 republishes, not with the gap grown
to 70 s, not in 12 shutdowns forced mid-reconnect; nothing accumulates but ~0.44 MB/republish of
still-unexplained private bytes. A hung *shutdown* is externally indistinguishable from a stalled
event loop, and a second agent session was concurrently killing `quickStimulus` by name on this
machine. Both are written up in §21.

⚠ **…and it still does not, after the fix** — 400 content-only rounds and **960 structural
rounds**, 3× the largest pre-fix run, heartbeat ticking end to end. So this is a proven fix for the
gap and for the churn, and an **unproven** one for the wedge: four latent hazards in `StreamPool`
that match the reported signature were closed (a direct `destroyed → cleanConnections` connection
into a non-recursive mutex, a missing re-entrancy guard, an uncoalesced cycle per state
transition, and a per-request attempt cap that was silently off), but nobody has yet made the
symptom appear on demand. **If the operator sees it again, the first thing to check is the tail of
the log for a `FATAL` or `Qt.quit()` immediately before the heartbeat stops** — that would make it
a hung teardown, not a stalled loop, and move the search to `ThreadCapsule::~ThreadCapsule()`.


<a id="history--the-topoplot-algorithm-is-solved--do-not-re-derive-it"></a>

## ⭐ The topoplot algorithm is SOLVED — do not re-derive it

**`R:\config\topoplot_v4_reference.py`** is a working reference verified against EEGLAB to **3e-13**.
Run it: `cd R:\config && py -3.12 topoplot_v4_reference.py` → `FIELD PASS` / `CONTOURS PASS` /
`CONV PASS` / `SELFTEST PASS`.

⭐ **As of 2026-08-20 it is COMPLETE**: the field (traps 1–5 below), `numcontour` (docstring note 6)
and `conv` (note 7). Two more traps join the five, and both were established by RUNNING EEGLAB, not
by reading it:

6. **MATLAB's contour levels are `linspace(zmin, zmax, N+2)` with BOTH endpoints dropped** — not
   `linspace(zmin, zmax, N)`, and not a "nice numbers" rule. `zmin`/`zmax` come from the FIELD
   after the rmax mask, not from the electrode readings (which would move the worst level by 0.178
   = 14.5 % of the range) and not from the colour limits.
7. **`'conv','on'` does not touch `Zi` at all.** EEGLAB draws an occluding BACKCOLOR patch over the
   surface. Masking the field instead draws the same picture, but the field must not change or the
   colour scale moves with the switch. The hull is the SPLINE-SMOOTHED one, and which hull vertex
   comes first is part of the specification — starting elsewhere moves the curve by 3 % of rmax.

Its docstring carries the five original traps, each of which yields a *plausible-looking but wrong*
scalp map:

1. EEGLAB's `topoplot` uses `griddata(...,'v4')` — 2-D **biharmonic** spline on projected x/y. **Not**
   a spherical spline. (An earlier plan to reuse `tepSoundService/spline.cpp` was wrong and dropped.)
2. The kernel is **not scale-invariant**; coordinates must be squeezed first.
3. `plotrad = max(0.5, min(1.0, maxRadius*1.02))` — omitting the `*1.02` = 7% field error.
4. Axis order swapped twice; **screen RIGHT = +y, UP = +x**. Getting it wrong = 82% error.
5. The field legitimately extends **beyond** the head circle (the "skirt").

Ground truth on disk, generated by running EEGLAB (`R:\config\topoplot_reference.m`,
`topoplot_outline.m`, `topoplot_contour_conv_probe.m`, `topoplot_contour_conv_check.m` — the last
two rewrite `topoplot.m` on the fly to `save()` the Contour object's own `LevelList`):
`R:\dist\_build\topo-ref\`
— `eegonly_*.csv` (64 EEG ch — **the target**), `eeglab_topoplot_eegonly.png` (**the orientation
arbiter**: Fpz top, Oz bottom, T7 left, T8 right), `kernelA_*`, the 66-ch cases, `outline_*`,
`contour_n{0,1,2,3,4,5,6,8}_{levels,lines}.csv` + `.png`, `conv_{on,off}_mask.csv`,
`conv_plainhull_mask.csv`, `conv_splinehull_poly.csv`, `conv_stats.csv`, `conv_radial_profile.csv`.
EEG-only numbers: plotrad **0.678215**, squeezefac **0.737229**, head circle **0.339125**.

MATLAB R2023b is on PATH; EEGLAB at `W:\MATLAB\eeglab2026.0.0`.


<a id="history-queued---empty-all-three-shipped-in-the-final-stage-2026-08-20"></a>

## Queued — ✅ EMPTY, all three shipped in the final stage (2026-08-20)

⏸ **POSTPONED to LAST, after every other stage** (operator, 2026-08-20 — "minor add-on"):
* ✅ **`numcontour` n** — n isolines over the field, 0 = none. Marching squares on the same grid.
  **DONE**: levels match MATLAB's own `LevelList` to 6.0e-14, vertex sets to 5.9e-12, same polyline
  count and vertex total at every level tested. Default 0.
* ✅ **`conv on|off`** — extrapolation limit. `off` fills the disk; `on` masks to the electrodes' convex
  hull (EEGLAB's spline-smoothed hull, `topoplot.m:1303-1325`). ~~⚠ With `conv off` on this montage,
  half the visible radius is extrapolation.~~ **DONE**, and that last sentence was wrong: it is
  **28.48 % of the map AREA**, and radially min 2.10 % / mean 15.93 % / max 22.35 %. "About half"
  is the right number for the *skirt outside the drawn head circle* (54.00 % of the disk, of which
  52.73 % is extrapolated), not for the visible radius. Inside the cartoon head there is **no**
  extrapolation at all — the hull's minimum radius 0.388250 already exceeds the head circle
  0.339125.
* ✅ **Retention becomes UNCAPPED with a 2 GB soft threshold** (operator, 2026-08-20). Replaces the
  512 MB hard ring Stage 4 ships with. See the section below — it is a behaviour change, not a
  constant change. **DONE**: 105 epochs held at 20.5 MB each with `evicted = 0` where a 512 MB cap
  would have kept 26; the notice fires once and re-arms only after a flush.

Done in Stage 3, with one gap still open:
* **EEG-only by `kind`** — the field takes channels whose `kind` metadata is EEG, never a channel
  number range. Including the EMG pair pushes plotrad 0.678218 → 0.756412 — **+11.53 %**, measured
  on the rig 2026-08-20. ⚠ An earlier note said "50%"; that compared against the rmax FLOOR of 0.5
  (0.756/0.5 = +51%), not against the EEG-only value, and is wrong for the question actually asked.
  ⚠ **The `kind` filter is written but NOT EXERCISED.** signalGenerator's epoch lane hardcodes
  `kind = Eeg` for every channel, so on the demo stream the EMG exclusion actually happens via the
  `.ced` file's `Number` column instead. The filter is therefore untested against a producer that
  disagrees with it. Fixing the generator is in the deferred Stage 0 batch.


<a id="history--retention-model-change--implemented-in-the-final-stage-2026-08-20"></a>

## ✅ Retention model change — IMPLEMENTED in the final stage, 2026-08-20

> **This section is operator-authored and is kept verbatim.** It is the specification the
> implementation was written against; nothing below has been deleted or reworded. What changed is
> the status line above and the check marks in **"Three things the implementation must handle"** at
> the end — all three were handled, and the numbers they demanded are in the
> [final-stage section](../../architecture/epochs.md).
> Every measurement the section predicted held on the rig: growth is lossless (`rebuilds` stayed 1
> across five doublings with a live accumulator), the 512 MB cap really does buy only 36 epochs at
> 73 ch × 25 kHz × 2 s where 2 GB buys 147, and the 104-byte slot cost really is what makes the
> notice fire on a toy stream.

**Operator, 2026-08-20:** *"If it is dynamically assigned, then it doesn't make sense to limit it so
stringently. Better make it uncapped with a liberal 2 GB threshold, at which the user is notified
that the buffer is >2 GB and then leave it to the user to flush it or keep going."*

**They are right, and for a sharper reason than the one given.** A byte budget only binds when epochs
actually arrive — Stage 4 allocates nothing up front and grows 0.122 MB per epoch at 64 ch × 500
(measured). So a low cap saves nothing on a short session; all it does is silently turn "every epoch
since the start" into "the last N" on a long one. And it is worst exactly where a budget was supposed
to help: at 73 ch × 25 kHz × 2 s, **512 MB buys 36 epochs**, which is below any usable ERP n.

<a id="history-what-ships-in-stage-4-the-thing-being-replaced"></a>

### What ships in Stage 4 (the thing being replaced)

`setByteBudget(bytes)` derives a FIXED capacity `bytes / bytesPerEpoch()` and the ring evicts from
then on. `evicting()` latches true so the panel can admit the average is no longer "all since start".

| shape | bytes/epoch | capacity @512 MB |
|---|---|---|
| 64 × 701 (tepSound) | 179 456 | 2991 |
| 64 × 2000 | 512 000 | 1048 |
| **73 × 50000** (25 kHz × 2 s) | 14 600 000 | **36** ← the case that breaks |
| 64 × 500 (epochDemo) | 128 000 | 4194 |

<a id="history-what-replaces-it"></a>

### What replaces it

Grow the ring on demand instead of pre-deriving a capacity; never evict on your own. At
`bytesResident() > 2 GB`, **notify and keep going** — the operator flushes (`clear()`/reset) or
accepts the cost. Eviction becomes something the operator chose, which is the only way
"all epochs since the start" stays an honest claim.

<a id="history--why-this-is-safe-to-defer--the-groundwork-is-already-in"></a>

### ✅ Why this is safe to defer — the groundwork is already in

Measured against the shipped store, not assumed:

* **Growing the ring is lossless.** Raising the budget 10 → 40 slots with 10 epochs held keeps every
  serial, evicts nothing, and does **not** invalidate the accumulator (`rebuilds` stays 1) — the mean
  comes out bit-identical across the resize. `applyCapacity()` already moves slots by serial rather
  than by position, so grow-on-demand is a call it already supports.
* **Shrinking already does the right thing** if the operator ever wants it: evicts oldest, counts it,
  invalidates and rebuilds, and the rebuilt fast path still matches an explicit reduction bit-for-bit.
* **No parameter-name hazard.** Retention lives in the settings blob, where unknown keys are ignored
  on load and missing keys keep their default — unlike a `Stream` parameter, whose name
  `applyParameters` screens once up front. So the key can change spelling and meaning later without
  stranding a saved configuration. (This is why `plotN_markers` had to be declared in Stage 4 and
  this does not.)

<a id="history--three-things-the-implementation-must-handle---all-three-handled"></a>

### ⚠ Three things the implementation must handle — ✅ all three handled

*(Status added 2026-08-20 after implementation; the three items themselves are unchanged.)*
1. ✅ Priced as `bytesResident() + 104 × capacity()`. The ceiling is latched, reported three ways,
   and its 10 400 000 bytes of bookkeeping are counted.
2. ✅ The readout now shows resident-vs-threshold (`1234.5 / 2048 MB`) or `… MB · cap N` when a hard
   cap is set, amber on `overThreshold || ceilingReached || evicting`. `contributing` vs `received`
   is untouched.
3. ✅ Non-modal 24 px strip with Flush and Keep; fires once per crossing, re-arms only after a flush.
   Measured: `thresholdCrossings` stayed at **1** across 400 further epochs past the crossing.

1. **`kMaxCapacity = 100000` becomes the real limit for small shapes.** A slot costs **104 bytes**
   even holding nothing, so 100 000 slots is 9.92 MB of bookkeeping — already 3× the sample data on a
   2 ch × 4 toy stream. Uncapped growth makes that ceiling load-bearing rather than theoretical;
   price the threshold against `bytesResident() + 104*capacity()`, not samples alone.
2. **The panel readout changes meaning.** Stage 4 shows capacity and an evicting flag; this shows
   resident-vs-threshold and a flush action. `contributing` vs `received` stays either way.
3. **The notification must not be modal or repeating.** It fires once per crossing, and re-arms only
   after a flush — an epoch-rate dialog during acquisition is worse than the memory.


<a id="history--defects-reported-by-the-operator--fixed-in-stage-4-deployed"></a>

## ✅ Defects reported by the operator — FIXED in Stage 4, deployed

Both seen on the deployed Stage 3 build, 2026-08-20. Neither is a field error.

**D1 — the tooltip content should not exist at all.** ⚠ Clarified by the operator; my first reading
of this was wrong. It is NOT a wrapping or width problem to be fixed with `ParameterToolTip`. The
text itself is the defect:

> "Half-range of the colour scale. Symmetric about zero by construction — a diverging map whose zero
> moved would be lying about which way the field points."

It appears with **no stream loaded and both viewers empty**; it is irrelevant to a line-drawing trace
view; and even on the topoplot, where the setting genuinely applies, the operator does not need it
and finds it distracting.

**Root cause is mine, and it is a pattern to correct everywhere, not one string.** I wrote
DESIGN RATIONALE into an operator-facing surface — prose justifying *why the design is what it is*,
which belongs in the source comment or the design doc, not on a control the operator hovers.
The tree's own rule says a description carries "what the setting does, when it takes effect, what the
device does if it is refused, and any measured number worth knowing" — not the reasoning behind it.

Fix: **delete this description**, and audit EVERY parameter and tooltip added in Stages 1-3 for the
same failing. Terse and factual, or nothing at all. A control whose purpose is obvious from its label
needs no description. Also check why a tooltip surfaces when no stream is loaded — a control that
does not currently apply should not be offering help about itself.

**D2 — electrode markers change colour against the field.** They currently switch between whitish and
black depending on the local field brightness (the derived-ink luma rule). The operator finds it
distracting and it is wrong here: that rule is for text on a settable PANEL background, not for
per-electrode marks over a continuous field, where it makes identical electrodes look different.
Fix: **all markers black, always.** No luma-derived switching on the discs or their labels. Applies
to `TopoView` and to anything Stage 2's trace array draws over the field.


<a id="history--standing-instruction-2026-08-20--run-to-completion-do-not-wait"></a>

## ⭐⭐ STANDING INSTRUCTION, 2026-08-20 — RUN TO COMPLETION, DO NOT WAIT

**Operator, verbatim:** *"fix the republish defect first, then all other stages NO PAUSING AND
WAITING hereafter, proceed to all stages and apply all fixes that needed"*

This supersedes the earlier deploy-and-await-feedback rhythm. **Still deploy after each stage** — the
operator wants to be able to test at any point — but do NOT stop for approval between stages, and do
not ask questions that can be answered by reading the tree or by making a defensible call. Fixes
discovered along the way are in scope by default, not deferred to a later ask.

Order, as instructed:

| # | work | est. |
|---|---|---|
| 1 | ✅ **republish/reconnect stall** — diagnosed, fixed, tested, **built, re-measured and deployed** ([§21](../incidents/README.md)). Not a reconnect and not epoch-specific: a schedule-anchor bug in `signalGenerator` plus a republish that was never needed. Gap median 38 215 → 250 ms over 400 republishes; one stream rebuilt per structural edit instead of four. **The GUI wedge still did not reproduce** (960 structural rounds) and the unexplained private-byte growth is still open — both in §21. | ✅ done |
| 2 | **Stage 5** — viewer-side epoching off a trigger, **plus the `plotN_markers` handler** (same shape, do them together) | 2–3 h |
| 3 | **Stage 6** — output stream of averaged/filtered epochs | 1–1.5 h |
| 4 | **deferred Stage 0 items + the signalGenerator `kind` fix** | 1 h |
| 5 | **`numcontour` / `conv`** + **uncapped retention with the 2 GB notify threshold** | 1.5–2.5 h |

Deploy to `R:\dist\msvc64` at the end of each, with a `bin.pre-<name>-<timestamp>` rollback.


<a id="history--standing-instruction-from-the-operator-2026-08-20"></a>

## ⭐ Standing instruction from the operator (2026-08-20)

**After every phase that produces something testable: DEPLOY to `R:\dist\msvc64`, then report an
updated ETA.** The point is to let the operator inject feedback early rather than at the end — the
EEGLAB correction (spherical spline → 2-D biharmonic) is exactly what that catches, and it was caught
because they were looking.

Deploy recipe, with the two things that must not be skipped:

```
robocopy R:\dist\_build\msvc64\runtime\bin R:\dist\msvc64\bin /E
```

1. **Back up first**: `cp -r bin bin.pre-<name>-<timestamp>` — that is the rollback.
2. **Check what user config would be overwritten**: `diff -rq` the deployed `bin\Resonance` against
   the built one. The `.ini` files, `params\`, `montages\`, `calib\`, `protocols\` and `FrameLib\`
   are NOT shipped by the build, so `/E` leaves them alone — but tuned QML or `.ced` files under
   `bin\Resonance\` would be clobbered, and they are user configuration
   ([build_deployed-vs-repo.md](../migrations/deployed-vs-repo.md)).
3. Verify by launching, not by copying: nothing running should hold a binary first.


<a id="history-remaining-stages"></a>

## Remaining stages

| stage | est. | state |
|---|---|---|
| 4 averaging (mean/median/trimmean10/20, per-condition, 512 MB ring) + D1/D2 | 2.5–3.5 h | ✅ **done, deployed** |
| 5 viewer-side epoching off a trigger + `plotN_markers` handler | 2–3 h | ✅ **done, proven, deployed** |
| 6 output stream of averaged epochs | 1–1.5 h | ✅ **done, proven, deployed** |
| deferred Stage 0 items + the generator `kind` fix | 1 h | ✅ **done, proven, deployed** |
| `numcontour` / `conv` + uncapped retention w/ 2 GB threshold | 1.5–2.5 h | ✅ **done, proven, deployed** |

**🏁 NONE REMAIN.** The estimates above are kept as a record of what was planned against what it
took; the ETA lines that used to sit here are gone because there is nothing left to estimate.

Deploy to `R:\dist\msvc64` after each stage — which is now history, but the rule and the six
`/MIR`-would-delete items at the top of this file still apply to anything that touches this tree.


<a id="history--two-things-stage-4-must-not-get-wrong--both-honoured-verified-in-the-shipped-build"></a>

## ✅ Two things Stage 4 must not get wrong — both honoured, verified in the shipped build

* **Median and trimmed mean cannot be computed incrementally.** An accumulator gives the mean and
  nothing else, so every contributing epoch has to be RETAINED. That is what the 512 MB budget buys:
  ~1000 epochs at 64 ch × 2000 samples, but only ~35 at an undecimated 73 ch × 25 kHz × 2 s. Derive
  capacity from bytes, never from an epoch count, and show it.
* **Once eviction starts, "all since the start" quietly becomes "the last N"** and the median changes
  meaning. Report `contributing` separately from `received` — tepService already does, for exactly
  this reason.
* **The averaging key is the triple `(window_start_ms, samples, rate)`**, not the length. Two epochs
  can share a length and differ in where zero sits; averaging those aligns the wrong samples while
  every length check passes.
* **`plotN_markers` must be DECLARED NOW** even if its handler lands later — `applyParameters`
  screens parameter names once up front, so a slot added later can never be restored from a saved
  configuration.

✅ **`plotN_markers` — HANDLER LANDED IN STAGE 5, RUN AND PROVEN.** `StreamView.qml` opens a
second `MessageReceiver` on the slot and feeds a shared `MarkerLog`; the label is chosen by
comparing rtcs, with `nextLabel` kept as the latch fallback. With no marker stream configured every
epoch still goes to the default bin, which is a real bin, so the average is correct with no markers.
Measured live off a real `stimuli` stream: viewer-cut `left` n=22 / `right` n=10, producer-cut
`left` n=25 / `right` n=12, **zero unlabelled on either side**, `labelRule=rtc` on both.
⚠ It shipped with a one-event labelling defect that the ratio shot could not see — see the Stage 5
section, and use `epoch_cut_shot.ps1 -LabelProbe` rather than a bin ratio to check this class of
thing, because a cyclic label list keeps its ratio under a shift.
Also new: `StreamView` now aliases `markerSource` and `triggerSource` alongside `source`, so a rig
can point the marker slot at a producer instead of poking `nextLabel` by hand.


<a id="history-the-stage-0-debt--closed"></a>

## The Stage 0 debt — CLOSED

All three items were taken once a consumer exercised them. **Built, proven and deployed
2026-08-20** — +12 tests, and the `kind` fix is measured above: `plotrad` **0.678218** with
the EEG filter on over 64 of 67 channels, **0.756412** with the filter moved to EMG over 2 of
67, with the EMG pair drawn outside the head circle so the exclusion is demonstrably by
`kind` and not for want of a scalp position.

**1. `signalGenerator`'s epoch lane published `kind = "EEG"` for every channel — fixed.**
`EpochLane` now takes a per-channel kind list, and `Service::applyEpoch()` derives BOTH that list
and the per-channel `kind` MetaData from one `ChannelPlan::epochLayout(eeg, emg, aux, trigger)`, so
what a consumer is told and what it is sent cannot disagree. Three new parameters —
`epochEmgChannels`, `epochAuxChannels`, `epochTrigger` — all defaulting to none, so every saved
configuration still describes the all-EEG lane it described before. Declared NOW, not later
(known-issues 16b).
⭐ The reason the viewer's EEG-only filter had never been exercised turned out to be deeper than
the hardcoded kind: `mks64_standard.ced` numbers its EMG rows **129 and 130**, so an index join
can never reach them and the EMG pair came out *unplaced* — excluded from a topoplot for want of a
position rather than by `kind`. Non-scalp channels are therefore now joined to the montage **by
label** (`montageRowForLabel`), which is what puts EMG1/EMG2 at radius 0.663 / 0.742, outside the
outermost electrode at 0.665, where only the `kind` filter can keep them out.
The assertion, **run and passed**: `R:\config\stage6_kindfilter_shot.ps1` (64 EEG + 2 EMG + a
trigger channel), plotrad **0.678218** at `kind="EEG"` and **0.756412** at `kind="EMG"` —
+11.53 %, not the +50 % the brief quoted. Shots `s6-08` / `s6-09`.

**2. The `status` channel count — re-measured, and documented as safe.** `tepSoundService` is now
36 (34 → 35 `averageWithheld` → 36 `anchorRejected`); `signalGenerator`'s is **18**, not 16. No
consumer in this tree reads a status channel by position: `Recorder`/`HDFRecorder::rebindStream()`
compares the returning connection header against the dataset it created and marks a differently
shaped stream `incompatible` in `streamStatus()`; `ChannelModel::setStateJson()` matches saved
channel state by NAME; the offline scripts read `streamInfo → perChannelProperties.name` out of the
file and do `names.index(...)`. The one case none of that covers is an analysis hardcoding a column
index **across two files made by two builds**, and the rule that makes that impossible is
**append only, never insert / reorder / rename**. Written down once in
`R:\src\tepSoundService\statuschannels.hpp` with the evidence, and **pinned by a test**
(`StatusStream.TheChannelListIsAppendOnly`) so an insertion fails and an append does not.

**3. `tepSoundService`'s newest-epoch anchor — now validates.** `SoundStore::reduce()` took
`chosen.back()`'s shape on trust; an epoch that could not contribute (empty `clean` during warm-up,
a zero channel count) still dictated the geometry every other epoch was then filtered against, so
the average came out **blank with nothing anywhere to say why** — and a zero channel count reached
the GFP loop's division. It now walks back to the newest epoch that can actually anchor and
reports the cost: `SoundAverage::anchorSkipped` / `anchorSerial`, the `anchorRejected` status
channel, and a rate-limited log line (grace, then a slow repeat — the ordinary occurrence is a
warm-up of a second or two). "No epoch could anchor" logs differently from "fell back to an older
one", because from outside the store they look identical.


<a id="history--build-rule-that-outranks-everything"></a>

## ⚠ Build rule that outranks everything

`R:\docs\arch_known-issues.md` §11c: the build environment **must** contain `chcp 65001` after
vcvarsall. Without it ninja records **no header dependencies at all** and a header edit produces a
mixed-layout binary that links cleanly and crashes at run time — with 165 unit tests still passing,
because the GTest targets link only the pure logic files. `VSLANG=1033` does **not** work here.
Also: build **`all`**, not named targets, or the QML never reaches `runtime/`.
