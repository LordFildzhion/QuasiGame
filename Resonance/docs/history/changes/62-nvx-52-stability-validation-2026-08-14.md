# NVX-52 stability validation (2026-08-14)

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx52.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-nvx-52-stability-validation-2026-08-14"></a>

### NVX-52 stability validation (2026-08-14)

The isolated `msvc64-nvx2025` driver was exercised in 82 scripted acquisitions using all 48 EEG,
4 AUX, and trigger outputs. This included a 46-case streaming sweep, 32 full network/HDF cases,
15-minute reference-block recordings, and 10-minute low-latency recordings. All 36 HDF files open
and reconcile their block indexes, rows, channel metadata, configured rate, and creation timestamps.
No acquisition timed out or required a hard reset.

* **Approved default:** 1 kHz, requested block 100. The 15-minute recording produced 899,963
  measured rows at 999.96 Hz with zero missing rows and no queue/SDK/counter warnings.
* **Also data-clean:** directly tested 1 kHz blocks 25, 50, 250, and 500. Block 10 is clean but
  uses more CPU. Avoid 1-5 as inefficient; do not use 1,250 or larger because the SDK read interval
  approaches/crosses the vendor's once-per-second requirement.
* **5 kHz is not approved for experiments on this setup at any block.** Block 500 stayed
  operational for 15 minutes but 482,254/4,499,940 measured timeline rows (10.717%) were missing
  and represented as NaN. Block 50 reproduced 10.717% loss over 10 minutes.
* The 5 kHz fault is below Resonance: the same raw counter probe returned about 4.474 kframes/s
  with 10.34% counter-defined loss under both NVX API 2.3.21648 (2025) and 2.3.18789 (2021), and
  polling from continuous retry through 75 ms did not recover the frames.
* The installed `McsUsb30` driver is 3.3.0.0 (2023), newer than the 3.0 (2012) driver shipped in
  the 2025 SDK. Do not downgrade it without vendor direction.

Full conclusions: `R:\tests\2026-08-14_nvx2025-driver-campaign\NVX2025-Stability-and-Block-Size-Validation-2026-08-14.docx`.
Filterable results: `R:\tests\2026-08-14_nvx2025-driver-campaign\NVX2025-Stability-Test-Results-2026-08-14.xlsx`.
Raw JSON/HDF/log artifacts remain under `R:\dist\_build\nvx-validation`.

<a id="history-2-khz--5-khz-nan-boundary-extension-2026-08-14"></a>

### 2 kHz / 5 kHz NaN-boundary extension (2026-08-14)

A second recorded campaign tested 2 kHz, 5 kHz with fewer published electrodes, long block-size
runs, and deliberately unsafe edge conditions. All 66 HDF recordings from the combined boundary
set opened and reconciled independently; every acquisition ended through normal stop/close and no
hard reset was required.

* **Approved 2 kHz setting:** all 48 EEG + 4 AUX + trigger, block 200. The 15-minute recording
  contained 0 transport-missing rows in 1,799,926 measured rows (one-sided 95% upper bound:
  1.664 missing rows per million). Blocks 20–2000 were also clean in 45-second recorded screens,
  but only block 200 received the long qualification. Do not use block 2666 or larger: the measured
  delivery interval crossed the SDK's once-per-second read-cadence boundary.
* **No safe 5 kHz experimental block was found.** Fifteen-minute recordings at blocks 50, 500,
  and 5000 each lost approximately 10.7169% of the timeline, about 250 gap events per second.
  Block 500 remains useful for diagnostics only. The defect is a highly regular sequence of
  two- or three-sample holes approximately every 20 theoretical samples, not random recorder load.
* **The 24-channel explanation is false for 5 kHz.** Publishing 20, 23, 24, 25, 32, or 48 EEG
  channels left the loss unchanged; there is no 24→25 discontinuity. Grounded EEG29, EEG35,
  EEG40–42, and EEG48 were finite on every non-gap row. Both SDK generations specify the
  24-channel restriction for 10 kHz, while 5 kHz uses all channels.
* **Capacity failures are silent.** At 2 kHz, block 19000 had no transport NaNs but multi-second
  latency; block 20000 was the first missing-data case. At 5 kHz, block 21000 still had only the
  normal periodic 2–3-sample fault and block 22000 added a 526-sample overload burst. No SDK,
  queue, counter, or Qt warning announced either transition. These values locate capacity and are
  not usable operating settings.

Operator/technical report: `R:\tests\2026-08-14_nvx2025-driver-campaign\NVX2025-2kHz-5kHz-NaN-Boundary-Validation-2026-08-14.docx`.
Filterable evidence: `R:\tests\2026-08-14_nvx2025-driver-campaign\NVX2025-2kHz-5kHz-NaN-Boundary-Validation-2026-08-14.xlsx`.
Raw JSON/HDF/analysis/log artifacts: `R:\dist\_build\nvx-validation\boundary-2026-08-14`.
