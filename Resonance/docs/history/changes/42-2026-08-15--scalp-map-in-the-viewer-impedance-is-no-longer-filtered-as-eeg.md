# 2026-08-15 — Scalp map in the viewer; impedance is no longer filtered as EEG

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-15--scalp-map-in-the-viewer-impedance-is-no-longer-filtered-as-eeg"></a>

### 2026-08-15 — Scalp map in the viewer; impedance is no longer filtered as EEG

The signal viewer gained a second way to present a stream: **a head map**, switched with `Head` in
the toolbar or `H`. Electrode positions come from the stream's own CED metadata, so nothing is
configured in the viewer and the map follows whatever montage the amplifier was started with. It
replaces the standalone `impedanceMeasure` application — the Configurator's two viewers now switch
between stacked and side by side from **View**, so a map on the left beside traces on the right
reproduces that tool's layout in two menu clicks. Full detail:
[signal-viewer.md §7b–7c](../components/signal-viewer.md).

⚠ **Impedance was being band-passed as if it were EEG.** Both NVX drivers described their
impedance outputs as `kind = "EEG"`, so the viewer put them in the EEG group and ran the 3–35 Hz
display filter over a DC level, which removes the entire reading. They now publish
`kind = "Impedance"` / `unit = "Ohm"` and the viewer carries a matching group default (20 kOhm,
step, unfiltered). [known-issues §13j](../incidents/README.md).

The head is **drawn** rather than laid over a bitmap. The old `Bricks/Head.qml` positioned
electrodes on a photo of a head and carried a `/1750` factor and a 30-pixel offset to make the two
line up, so it was correct at one window size and for one image. The projection now lives in
`PlotMath::scalpPoint` with six unit tests (Cz vertex, Fz up, C3/C4 mirrored, Pz behind), and the
outline is drawn from the same convention, so they agree by construction. The map is fitted to the
montage rather than to the outline — `mks64_standard.ced` runs out to radius 0.742 and TP9/TP10
belong outside the circle — and discs are sized from the electrode count, so 12 and 128 channels
are both readable without an adjustment.

**Verified** against a `signalGenerator` carrying real 12- and 64-channel montages: positions
checked numerically rather than by eye, all five colour states asserted including "no reading",
and the whole arrangement driven through the real Configurator — stream dragged in, layout
switched, left viewer turned into a map. 27 `test_PlotMath` cases pass.

⚠ **`neuroMS` does not compile** as of this session: `neuromsdriver.cpp:740` calls
`emit status(...)` where a local variable named `status` shadows the signal, so MSVC rejects it
(C2064). Both `neuroMS` files were edited at 06:33 today by someone else, so it was left alone —
the other targets were built individually.

