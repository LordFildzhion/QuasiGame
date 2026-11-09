# 2026-08-15 — NVX136 25 kHz / 70-channel validation: clean

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-15--nvx136-25-khz--70-channel-validation-clean"></a>

### 2026-08-15 — NVX136 25 kHz / 70-channel validation: clean

Ten minutes at **25 kHz, 70 EEG + trigger (71 published), block 2500**, recorded through
`recorderService` with the signal viewer live on the same stream throughout.

| | |
|---|---|
| Recording | **15,003,481 rows × 71 channels**, 8.5 GB, over 599.94 s |
| Measured rate | **25,005.28 Hz** — +0.021 % of configured |
| **Missing data** | **none.** 0 NaN values of any kind: no transport gaps, no invalid electrodes. One-sided 95 % upper bound: **0.2 missing rows per million** |
| Blocks | 8,474; sizes 20–2500, median 1920, mean 1771. Arrival gap median 78 ms, max 113.5 ms (poll interval is 75 ms) |
| Data | EEG varying (σ ≈ 0.9 mV on floating inputs) and identical in character at the start, middle and end; only the trigger is constant |
| Lifecycle | ran the full 600 s and stopped cleanly to `init` |

**The viewer does not struggle.** All 71 rows on one page — every repaint a full repaint — over
41 consecutive 15-second windows:

| | |
|---|---|
| Full-repaint cost | **6.6–7.0 ms median**, p95 ≤ 10.3 ms, max 10.3 ms, against the 33 ms warning threshold |
| Frame rate | 12–16 fps, which is the *data* cadence: block 2500 at 25 kHz is ~10 blocks/s and the display repaints when data arrives |
| Storage | decimation ÷5 over the 3 s window, so 5 kHz stored as a min/max envelope — the mechanism from [signal-viewer.md §4](../components/signal-viewer.md) doing exactly what it is for |

CPU with all three running: `nvx136` 114 % of one core, `recorderService` 40 %, viewer 15 %.
The driver is the expensive one — 25 kHz × 136 analog words is 13.6 MB/s off USB and 14.2 MB/s
published — but nothing is close to saturated.

Note `block size is a target, not a promise`: a requested 2500 delivered a median of 1920 and a
range of 20–2500. That is the documented behaviour and it costs nothing here.

Artifacts: `R:\dist\msvc64\data\val-25k-70ch-0001.h5` (8.5 GB) and `smoke-25k-0001.h5` (566 MB,
a 40 s pre-check, also clean) — delete when no longer wanted.

