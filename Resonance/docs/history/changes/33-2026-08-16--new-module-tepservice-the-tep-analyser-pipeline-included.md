# 2026-08-16 — new module `tepService`: the TEP analyser, pipeline included

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-16--new-module-tepservice-the-tep-analyser-pipeline-included"></a>

### 2026-08-16 — new module `tepService`: the TEP analyser, pipeline included

Full write-up: **[tep-service.md](../components/tep.md)**; operator instructions
**[Tep-Operator-Guide.md](../../operators/legacy-tep.md)**; evidence
**`report_tep-service-validation.md` (on the lab drive, `R:\docs\_notes\`)**.

`R:\dist_legacy\TEP_visualization` — a PyQt application — and `mulines.TEPs_plot.pipeline_tep`,
the Python script `SPEED` hosted to cut its epochs, are now one Resonance service in
`R:\src\tepService`. Service name **`TEP`**, launcher `tepService.bat`.

**The reason the two had to become one is a settings file.** The rig ships three copies of the
epoching parameters — `dist2025\mulines\resources\SPEED_settings.json` (window −500…500 ms,
artifact −0.04…0.85 ms), `TEP_visualization\SPEED_settings.json` (−500…500, lowpass 30 Hz) and
`TEP_visualization\data\TEP_visual_settings.json` (−100…300, lowpass 2500) — and the one the GUI
drew its axes from was not the one the pipeline read. There is now one place a window length is
written down.

| | |
|---|---|
| Parameters | **60** in eight index-banded groups; 53 properly typed, 41 with tooltips |
| Streams out | `epochs` (Float64, one block per epoch, stamped with the **trigger's** RTC), `average`, `events` (Message/JSON with each epoch's MEP measured), `status` (Float64, 18 named channels at 2 Hz) |
| Streams in | `signal` — the raw amplifier stream; `markers` — optional, labels each epoch with its condition |
| Console | scalp grid at the electrodes' own positions, butterfly, averaged MEP ± sd, single-trial strip, per-epoch table with amplitude / onset / pre-stimulus RMS |
| Epoch file | the layout `logic/epoch_record_buffer.py` wrote, so the lab's offline scripts keep working |

**Verified: every epoch bit-identical to SciPy.** A 5.25 GB, 67-channel, 25 kHz TMS-EEG recording
replayed through `playbackService` at 1×; the service's 75 epochs compared against an independent
NumPy/SciPy implementation of the same pipeline reading the original file:

| | |
|---|---|
| Triggers in the file / epochs produced / lost | **75 / 75 / 0** |
| Values compared | **9,900,000** |
| Max absolute difference | **3.73e-09 V**, against a float32 resolution of 8.90e-09 V |
| Bit-identical after rounding to float32 | **yes** |

Plus `test_TepPipeline` **33/33** — every expected value produced by SciPy — including that an
epoch is identical at transport block sizes of 1, 7, 64, 333 and 1024 samples; `recorderService`
recording the `epochs` and `events` streams (17 blocks of exactly 2000 samples, 17 matching event
records); the Configurator's own `ParametersView` rendering all 60 parameters in eight tabs; and
condition labels taken from a replayed `stimuli` marker stream.

⚠ **Two defects found in the shipped Python.** `interpolate_by_trigger` computes its far edge
from the near one (`end_pos = start_pos + end_idx + 1`), so at the rig's −5 / +15 ms the
interpolation **stops at +10 ms**, not +15 — that one is a *choice of span*, so it is available
as an explicit setting and warned about when on. `configure_car` takes the list the window labels
`CAR кроме:` ("CAR except") as the set to average **over**, so the delivered configuration
re-references every electrode to the mean of FT9, FT10, TP9 and TP10 rather than excluding them —
that one is the code disagreeing with its own label, and is **not** reproduced at all. `CAR` here
is the mean over every electrode except the ones listed, and nothing else.

⚠ **No amplifier, no stimulator, no photodiode.** Everything was driven from playback, which is
the stricter path for the *pipeline* and says nothing about a live driver's block cadence, a
mid-session restart, or the absolute latency from a pulse to the sample it lands on.
⚠ `mingw32` / `mingw64` have not compiled this module.

