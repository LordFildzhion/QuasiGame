# 2026-08-19 — new module `tepSoundService`: cue presentation, TMS triggering and online SOUND

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-19--new-module-tepsoundservice-cue-presentation-tms-triggering-and-online-sound"></a>

### 2026-08-19 — new module `tepSoundService`: cue presentation, TMS triggering and online SOUND

A spin-off of `tepService` for the TMS-EEG paradigm the lab is running: several kinds of picture
cue held for seconds each with a randomised gap, one TMS pulse delivered at a chosen offset **into**
each cue, and every pulse turned into a **SOUND-cleaned** TEP, an MEP amplitude and a cap report
before the next cue appears.

Full reference: **[service_tepsound.md](../components/tepsound.md)** — §3 is the pipeline in order, §5 the
measured performance, §6 the parameter guidance with a recommended and an edge value for every
setting that has one.

| | |
|---|---|
| Module | `R:\src\tepSoundService` — `tepSoundService.exe`, service `TepSound`, launcher `tepSoundService.bat` |
| Registration | one line in `R:\src\CMakeLists.txt` |
| Outside the module | **nothing**. Neither `tepService` nor `stimulusService` was edited |
| Built and deployed | MSVC v142 x64 → `R:\dist\msvc64`. ⚠ MinGW has not seen it |
| Tests | `test_TepSound`, **20/20** |

**Three of the four halves already existed and are referenced from their own directories rather
than copied** — `tepService`'s continuous stage, its MEP measurement, and `stimulusService`'s
frame-locked stage, protocol, schedule and trigger backends. The new half is the online SOUND
cleaner: per-channel noise estimation, a five-metric cap monitor, spherical-spline repair, and a
calibration schedule. It is a C++ port of `W:\MATLAB\tms\onlineSOUND\python`.

<a id="history-verified-against-two-real-recordings"></a>

### Verified against two real recordings

`13_01AV` (170 pulses) and `12_02NS` (169 pulses) from `…\compareSOUND\rawData`, replayed by
`playbackSource` as a live NVX136-shaped service and analysed by the deployed binary.

| | |
|---|---|
| Pulses / epochs / lost | **339 / 339 / 0** |
| `preproc` vs an independent reference | float32 storage precision — 5.0e-4 µV against a 15,140 µV signal, 1.6e-5 µV against 431 µV |
| SOUND operator | **4e-14 relative** — machine precision — and the reference channel identical on both |
| Legacy `{"stimulus": …}` marker stream | read; every epoch labelled |

⚠ The reference is **two** independent implementations, not one: the continuous stage against
`tep_reference_pipeline.py` (NumPy/SciPy) and the per-epoch stage against the `osound` package
(NumPy, itself validated against MATLAB). Runner and comparator:
`R:\config\tepsound_validation_run.ps1` and `R:\config\tepsound_reference_pipeline.py`.

<a id="history-two-design-departures-from-the-reference-implementation-both-because-they-were-measured"></a>

### Two design departures from the reference implementation, both because they were measured

**The SOUND training set is kept unrepaired.** The reference stores the fully spatially-processed
epoch and undoes the previous repair with `R_new · pinv(R_old)` when the flagged set moves. A repair
matrix is rank-deficient by construction, so its pseudo-inverse cannot restore what the repair
removed. Measured here: the fifth calibration produced a **sigma of 255 µV on a channel whose true
noise level was under one**, the operator after it made every epoch worse, the service refused it,
and there was **no operator at all for the remaining 120 epochs**. Keeping the unrepaired form gives
a condition number of 105 instead of 24,597 and sixteen good calibrations instead of five — and lets
the detector *un*-flag a channel, which it cannot when everything it repaired looks perfect.

**The repair is applied to the training block, not to every epoch.** A matrix commutes with an
average, so repairing the mean is the same answer and one product instead of N. Under a cumulative
schedule that is 58 ms of pure overhead removed at epoch 170, and it does not grow.

<a id="history-performance-measured-on-this-machine"></a>

### Performance, measured on this machine

| | |
|---|---|
| epoch tail (window right edge + guard) | **700 ms** |
| per-epoch processing, live, over 170 real epochs | **21.6 / 23.6 / 24.7 ms** median / p95 / max |
| → a cleaned epoch exists | **~722 ms after the pulse**, 0.25 % duty at this paradigm's 8.5 s spacing |
| calibration, on its own thread | 18.8 ms at 10 training epochs, 22.2 at 20, held there by `detectorEpochs` |

⚠ **87 % of the per-epoch cost is the MEP slow-trend removal** — a 500-sample running median over a
5500-sample trace. With it off the same epochs cost **2.9 ms**. It is on by default because the MEP
number is worth more than 19 ms at any plausible ISI, but that is where the time is.

Two optimisations inside the new code, both from the fact that spatial and temporal operators
commute: applying every spatial operator to the 701-sample trimmed epoch instead of the 5500-sample
guarded one (**3.98 ms → 0.34**), and fusing the anti-alias FIR with the decimation and the trim so
only surviving outputs are computed (**18.8 ms → 1.5**).

<a id="history-not-verified"></a>

### Not verified

No amplifier, no stimulator, no TTL box, no subject screen, no photodiode, and the console has not
been operated by a person. The stimulator gate has never held a real pulse and the serial trigger
has never fired. MinGW has not compiled the module. Two recordings of the ten available were
replayed. Stated in full in [service_tepsound.md §8](../components/tepsound.md).

