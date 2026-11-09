# 2026-08-18 — the TEP SciPy comparison regenerated; the module's headline claim is current again

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-18--the-tep-scipy-comparison-regenerated-the-modules-headline-claim-is-current-again"></a>

### 2026-08-18 — the TEP SciPy comparison regenerated; the module's headline claim is current again

**The stale evidence is no longer stale.** Moving the display band limit into the continuous stage
changed what `h5["epochs"]` contains, so `tep_reference_pipeline.py` and
`report_tep-service-validation.md` (on the lab drive, `R:\docs\_notes\`) were describing an arrangement that had
ceased to exist and the module's "bit-identical to SciPy" claim was unsupported. Both recordings
were replayed into the **2026-08-18 03:31 build** and compared again.

| | Run 5 — `01_TP_M1_60MSO_single` | Run 6 — `06_TP_SMA_67MSO_SST` |
|---|---|---|
| Triggers / epochs / **lost** | 75 / 75 / **0** | 80 / 80 / **0** |
| Alignment offset | 0 | 0 |
| Values compared | 9,900,000 | 10,560,000 |
| Max absolute difference | 3.7253e-09 V | 1.1748e-08 V |
| float32 resolution of the signal | 8.891e-09 V | 4.842e-08 V |
| **Values differing after float32** | **0** | **1**, by **one ULP** |

**155 epochs, 20,460,000 values, one of them 0.93 nV out at 18.09 mV** — a sample sitting on a
float32 rounding boundary. ⚠ Run 3 reported "bit-identical: yes" at the *same* 1.1748e-08 V float64
deviation on that same recording, so the boolean flipped while the agreement did not. The
comparison now reports the mismatch **count** and worst **ULP distance** beside it, precisely so a
future run cannot read that as a regression.

**Two controls, because one agreement number cannot tell "the reference models the pipeline" from
"both skip the same stage".**

* **A — the rewrite is inert with the new stage off.** Run with `--no-display-lowpass` against the
  archived `run02_epochs.h5` (old binary, old arrangement), full recomputation, no cache: every
  field of `run02_compare.json` reproduced **to the last digit** — 3.7252452789182655e-09,
  worst epoch 13.
* **B — the comparison is sensitive to the filter, and the filter reaches only the EEG.** The new
  epochs against a reference *without* the display stage: **97 % of values differ, up to
  2.1486e-04 V and 1,080,876 ULP on the EEG — while the EMG pair still agrees to 9.3132e-10 V.**
  That is the check that says the band limit is genuinely present and is not touching the pair
  `extractMep()` measures out to 450 Hz.

⚠ **A gap in the unit tests, found while doing this and closed.** The suite pinned
`butterworth2(250, 5000)` — the rate of the per-epoch placement — and `butterworth2(2500, 25000)`,
but after the move the display filter runs at **250 Hz / 25 kHz**, which nothing held down: the one
test naming that operating point asserted only that it *differed* from the decimated-rate design,
and every wrong answer differs too. The reference script builds the same design from the same
specification, so an error would have been a **shared** one and §3 would have reported agreement
while both implementations were wrong. `DisplayLowpass.DesignAtTheRigsInputRateMatchesScipy` pins
it against SciPy. **`test_TepPipeline` is now 47/47.**

**⭐ This also closes an open verification.** The epoch count after the threading rework had only
indirect evidence. Run 5 and run 6 are **75/75 and 80/80 against recordings whose trigger count is
known independently**, on the threaded build — better than the synthetic
`tep_epoch_flow_check.qml`, which is therefore no longer needed for this question.

**Cost, re-measured on the same recording as the old §6b:** tepService took **22.6 s of CPU over
507 s — 4.5 % of one core**, against the **34 %** measured for run 2 on 2026-08-16. Working set
336 MB for 75 epochs at `epochBuffer` 500.

⚠ **One thing that is easy to misread.** The harness counts blocks on `epochs@TEP` and reported
**72** while the epoch file held **75**: a consumer attaching a few seconds after collection starts
misses what was published before it arrived. The stream count is a lower bound, not a measurement.

New: `R:\config\tep_validation_run.ps1` — the whole run as one
command, because the launch order is the part that goes wrong (the service must be collecting
before the replay starts) and this is now the third time it has had to be reassembled by hand. Its
one non-obvious line is the raw path in quotes: `Start-Process` does not quote `ArgumentList`
entries, and these paths contain spaces, which reads as `No such file: N:\Projects_MSU\2025`.

Evidence under `R:\tests\2026-08-18_build_network-isolation\tep-scipy-revalidation\`; the
2026-08-16 set is under `R:\tests\2026-08-16_build_tepservice\tep-scipy-validation\` and is
still the input to control A.

