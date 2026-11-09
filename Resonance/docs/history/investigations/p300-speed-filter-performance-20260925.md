# P300 FIR/IIR processing cost in native SPEED

Measured: 2026-09-25. Owning contract: [P300](../../components/p300.md). This is a device-free timing experiment on the local Intel Core i9-14900KF (24 cores, 32 logical processors), using the deployed `R:/dist/bin/SPEED.exe` and deployed P300 Python classifier.

Deliverable: [performance workbook](../../../outputs/p300-large-comparison-20260925/p300-speed-performance.xlsx). Raw per-run evidence, source hashes, library versions and summary: [p300-speed-filters-20260925](../../../src/_test-output/p300-speed-filters-20260925).

## Method

The maintained [speed_benchmark.py](../../../tools/reference-generation/p300/speed_benchmark.py) launches only its own uniquely named SPEED process and supplies actual R3 loopback TCP EEG and event streams. [speed_probe.py](../../../tools/reference-generation/p300/speed_probe.py) times the deployed classifier callback and filter calls without changing production files. An echo registered after the classifier measures delivery through the native TCP input, classifier graph and TCP output. The amplifier, P300 presentation UI and interactive MATLAB are not used.

Eight channels, 500 Hz, 25 samples per block (the Movicom default, 50 ms). The same recorded subject-09 EEG is used for each run. Filters are exactly the earlier comparison's 2,047-tap Movicom FIR (1–10 Hz) and native-MATLAB-derived four-section Butterworth IIR (1.5–10 Hz). Both operate continuously with retained state. The two layouts are 500 samples/stride 25 (1 second, 160 features) and 300 samples/stride 10 (0.6 second, 240 features).

Each run first processes 11 seconds of EEG at accelerated speed, filling the bounded history and warming the filter. It then replays 20 seconds in real time, with two synthetic 6×6 trials of 60 flashes each at 100 ms spacing. Fixed nonzero weights exercise scoring; this is not another accuracy comparison. The result request is timestamped at the final flash. Each configuration runs three times in alternating FIR/IIR order. Normal process priority, default Windows affinity and one BLAS thread. Host activity remains uncontrolled; percentiles are observations, not timing guarantees.

**FIR alignment is explicit and test-only.** The source adds 1,023 sample periods to FIR flash/request timestamps so SPEED extracts the delayed filtered waveform corresponding to the original epoch. This emulates the reference's FIR delay compensation. Current production SPEED does not infer or apply this shift from FIR coefficients. Loading the FIR coefficients alone would run the filter but extract different, uncorrected epochs. The test does not deploy FIR alignment support.

## Measured results

For the 1-second layout, mean filtering cost was **0.250 ms/block FIR versus 0.064 ms IIR** (3.89×). The full EEG classifier callback took **0.421 versus 0.218 ms** (1.94×). Including event callbacks, elapsed processing consumed **8.83 versus 4.63 ms per second of EEG**, or **0.88% versus 0.46%** of a serial processing-time budget. These are elapsed callback timings, not Task Manager CPU percentages. Windows process CPU-time counters were unsuitable for comparing these short periodic workloads: their readings varied widely and two active runs reported zero; raw values are retained in the workbook.

Loopback block delivery through SPEED had medians **0.935 versus 0.734 ms** and p99 **2.628 versus 2.440 ms**. The worst among all 4,800 timed blocks was 7.492 ms; none exceeded the 50 ms block period. The 0.6-second layout gave similar processing costs: 0.409 versus 0.202 ms for the EEG classifier callback, and 0.86% versus 0.43% elapsed processing budget.

Median result delivery after the final flash/request:

- **1-second epoch:** FIR 3.401 s, IIR 1.351 s; difference 2.050 s.
- **0.6-second epoch:** FIR 3.001 s, IIR 0.951 s; difference 2.050 s.

The important delay is FIR lookahead, not computation. Its symmetric kernel has a fixed 1,023/500 = **2.046 s** delay. The reference-compatible epoch needs that much additional EEG before it is available. The measured difference rounds to about 2.050 s because output is released on a 50 ms block boundary.

The current request gate also adds `(max(0, photo_offset) + photo_window + 5) / rate`. In this test, defaults `photo_offset=0`, `photo_window=150`, `rate=500` add **310 ms even when `which_photo=0`**. Epoch duration + FIR lookahead (when used) + this gate + the next EEG block + computation/transport explain the observed result times. The chosen event phase added about 40 ms of block waiting; another phase can differ by up to a block. No production timing behavior was changed.

IIR needs no additional lookahead buffer, but it is not zero-phase. Calculated group delay from its actual SOS is approximately 297 ms at 2 Hz, 134 ms at 3 Hz and 80 ms at 5 Hz. This shapes the waveform already used for causal training and inference; it is not another constant to add to the result-release timer. Neither USB acquisition latency nor physical screen onset/feedback latency was measured.

## Acceptance

All 12 native service runs passed: **4,800 timed EEG blocks, 1,440 flash scores and 24 letter results**, with 60 completed/zero invalid epochs per result. Every queue drained and the bounded history retained 5,000 samples. No SPEED errors or missing outputs. Each owned service exited; the pre-existing interactive MATLAB remained running. The workbook was recalculated, checked for formula errors and visually reviewed.
