# 23. `parseCED` reads the `.ced` file's rounded `theta`/`radius`; EEGLAB recomputes them — open, ~4e-5 on the field

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-23-parseced-reads-the-ced-files-rounded-thetaradius-eeglab-recomputes-them--open-4e-5-on-the-field"></a>

### 23. `parseCED` reads the `.ced` file's rounded `theta`/`radius`; EEGLAB recomputes them — open, ~4e-5 on the field

**TRANSFERS UNCHANGED — still open in both trees.**
`R:\src\Core\Resonance\internal\ParseCED.cpp:110` reads `radius` straight from the file's rounded
column, exactly as the Qt 5 one does, so the ~4e-5 field discrepancy is the same in `R:\dist`. The
tepSound-only fix (`Tsd::readCed`) crossed with the service.

Found 2026-08-20 while closing the viewer epoch work, chasing a discrepancy that had been sitting
in the Stage 2 harness logs unexplained since 08:00 that morning.

**The symptom.** `test_TopoField` reproduces EEGLAB's own 200×200 grid to **2.77e-13**, and an
out-of-tree probe that re-solves the field in C++ from MATLAB's electrode dump agrees to the same
figure. But the LIVE viewer, taking its montage over the stream, reports
`max abs 4.1538e-5  relative 3.3817e-5  mask disagreements 0` — eight orders of magnitude worse.
It is **not** a regression: that string is character-identical across every run from Stage 2
(2026-08-20 07:14) to the final stage (19:18), on the build tree and on the deployed tree.

**The cause, measured and not inferred.** `mks64_standard.ced` carries `theta` and `radius` as
display columns rounded to five decimals:

```
Number  labels  theta     radius    X   Y      Z        sph_theta  sph_phi   sph_radius
1       T7      -90       0.53318   0   0.0994 -0.0104  90         -5.973    0.099943
2       TP9     -108.39   0.66492   …                   108.39     -29.685   0.099954
```

`Resonance::parseCED` (`Core/Resonance/internal/ParseCED.cpp:86`) reads those two columns directly.
**EEGLAB's `readlocs` does not** — it derives the polar coordinates from the spherical columns,
`radius = 0.5 - sph_phi/180`. Verified exactly on all 64 channels: `0.5 + 5.973/180` is
`0.533183333333333` and `0.5 + 29.685/180` is `0.664916666666667`, which are the values in MATLAB's
own dump to the last digit. The file's own `radius` column is up to **5.556e-06** away from that
(worst channel F3).

**Confirmed by reproducing it.** Feeding the same exact-arithmetic probe radii quantised to the
file's five decimals — the *only* change — moves the field error from **2.77e-13 to 4.05e-05** and
the contour-level error from 6.0e-14 to 2.0e-05. That is the same size and sign as the live 4.15e-5,
so the mechanism is settled. (The last ~3 % between 4.05e-5 and 4.15e-5 is not accounted for; only
`radius` was quantised in the experiment, and the generator's metadata pipeline may round again.)

**Why it is left open.** 3.4e-5 relative is far below anything visible on a scalp map or meaningful
against electrode placement error, and the fix is not local: preferring `sph_phi` would change
every montage's geometry slightly, including montages whose Cartesian columns are absent or
inconsistent with their polar ones. It is recorded because it is the *only* remaining gap between
the viewer and EEGLAB, and because anyone re-deriving the topoplot against `topo-ref` will hit
exactly this number and assume their port is wrong.

**If it is ever fixed:** derive `radius = 0.5 - sph_phi/180` and `theta = sph_theta` in `parseCED`
when the spherical columns are present and finite, fall back to the flat columns otherwise, and add
a `ParseCED_test` case pinning `0.533183333333333` for T7.

**2026-08-21 — fixed in tepSound only; `Resonance::parseCED` is still open.**
`Tsd::readCed` (`tepSoundService/calibration.cpp`) now recomputes `radius = 0.5 - sph_phi/180` when
the `sph_phi` column is present and parses to a finite number, and falls back to the file's own
`radius` column otherwise. Done because the tepSound scalp field (`TepTopoView`) solves the same
biharmonic kernel and had to be pinned against reference values; retrofitting the parser afterwards
would have meant re-pinning every one of them.

Measured consequence on `montages/mks64_standard.ced`: `plotrad` **0.678218 → 0.678215**,
`squeezefac` 0.737226 → 0.737229, drawn head circle **0.339124 → 0.339125** — and 0.339125 is the
figure `R:\config\topoplot_v4_reference.py` quotes for EEGLAB's own render, which is the
independent check that this is the right direction. `tests/topo_test.cpp` pins all four, plus T7 at
`0.533183333333333` and TP9 at `0.664916666666667`.

⚠ `theta` was deliberately NOT recomputed. On both `.ced` files in this tree it is written as
`-sph_theta` and agrees with it to **exactly 0.0** on all 64 rows, so there is nothing to recover —
and `readlocs`' sign convention is one more thing that could be wrong for a file this code has never
seen. The note above should read "derive `radius`", not "derive `radius` and `theta`".

**Still open:** `Core/Resonance/internal/ParseCED.cpp:87` reads `radius` straight from the column,
unchanged. It is shared by every service and the deployed viewer, so changing it moves the viewer's
head-map geometry and forces a whole-tree rebuild; it was left alone rather than folded into a
field-test build. In tepSound nothing but the topoplot is sensitive to it anyway — `theta`/`radius`
there reach only the grid layout (5.6e-06 of a unit radius), the CED trace palette (3.3e-06 in
radius, far below one 8-bit level, so the colours are byte-identical) and the new field. SOUND
itself uses `unitXyz` and the lead field and never touches these columns.

**2026-08-21, the number to decide on.** The two parsers were run against each other through
the whole biharmonic solve on `mks64_standard.ced`, 40 000 grid points: the rounded-column path
differs from the `sph_phi` path by **1.06e-09 V worst case, 0.0042 % of the field's own range**.
For scale, one 8-bit colour step on a ±50 µV scale is 0.39 µV — about 370 000× larger. The viewer
cannot render this difference, which is why `parseCED` stays open rather than triggering a
whole-tree rebuild.

---

