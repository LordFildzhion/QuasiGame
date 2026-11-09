# TEP legacy service and active shared pipeline

**Status:** `tepService` is a **retired Qt5 comparator**, not a Qt6 target or default distribution executable. Use [TepSound](tepsound.md) for current online TEP/MEP development. This page preserves the compatibility boundary and the still-active inherited arithmetic.

## Where to change code

Active inherited implementation is in [tepSoundService/shared/tepService](../../src/tepSoundService/shared/tepService): [dsp.cpp](../../src/tepSoundService/shared/tepService/dsp.cpp), [pipeline.cpp](../../src/tepSoundService/shared/tepService/pipeline.cpp), [epochprocessor.cpp](../../src/tepSoundService/shared/tepService/epochprocessor.cpp), [signalworker.cpp](../../src/tepSoundService/shared/tepService/signalworker.cpp). They compile into the active TepSound build.

The separate comparator is `R:/src_legacy/Qt5/tepService` and `R:/dist_legacy/Qt5/msvc64/tepService.bat`. Do not edit that tree expecting to change current TepSound. Generic epoch storage/timing rules are in [epochs](../architecture/epochs.md).

## Compatibility distinctions

| Legacy tepService feature | Current TepSound behavior |
|---|---|
| `inputMode=Epochs`, one epoch/block input | No equivalent inputMode parameter; current signal path is continuous |
| `artifactSpan=Legacy (start + end)` | Uses requested span; no legacy-span switch |
| artifactStart/End/Smoothing | blankFrom/To/Smoothing |
| epochLowpass/Hz | preLowpass/Hz |
| rereference/rereferenceChannels | car/carExcluded is not a blind one-to-one semantic replacement |
| artifact, baseline, baselineMethod, averaging, inputMode | No identical parameter IDs |
| Epoch-file `epochs` | Legacy contains uncleaned epochs; TepSound file `epochs` is SOUND-cleaned and `preproc` is pre-SOUND |

Saved legacy configurations therefore apply only partially and produce NoSuchParameter reports; migrate deliberately. “Needs legacy span” applies to reproducing an old **analysis**, not to the mere date of raw input. Do not claim every older recording requires the retired executable.

## Inherited numerical pipeline

1. Detect edges on the **raw trigger word** before interpolation/filtering.
2. Interpolate artifact span and smooth joins.
3. Apply continuous stateful highpass→notch→lowpass; the inherited display lowpass is a separate EEG-only continuous filter.
4. Cut window around trigger, then integer subsample.
5. Per epoch: EEG scaling/baseline/CAR/reference; EMG scaling/baseline/B−A/optional slow-trend removal; response-window peak-to-peak/onset/area/baseline RMS.

Artifact removal must precede filters; otherwise a large pulse artifact rings into the response. Continuous filters see each sample exactly once and avoid cut-epoch startup transients. NaNs must not poison delay lines.

The inherited display lowpass moved upstream of the cut and must leave trailing EMG channels untouched. Its changes affect **future epochs**, not stored ones. Legacy pre-epoched input necessarily retains its per-epoch filter/transient. Subsampling adds no anti-alias filter; configuration must band-limit before reduction.

Lookahead is `max(lastTouchedOffset, -firstTouchedOffset)+2` input samples. It is algorithmic latency, not a performance regression; expose it instead of relabelling epoch time.

## Historical numerical compatibility

Requested artifact endpoints are relative to trigger. The old Python span used `end = start + requestedEnd`: −5/+15ms therefore ended+10ms. Legacy mode deliberately reproduces that; current TepSound does not.

CAR exclusion means average **over all except** listed channels. The old inverted list computed a reference to the listed electrodes; reproduce that with an explicitly named reference operation if needed, not by restoring the bug.

DSP coefficients/filter outputs are pinned to SciPy-style designs, not the viewer's differently normalized iir1 package. The C++ filters initialize zero state; old Python's unit-step zi produces a different startup transient. Keep these distinctions in numerical comparisons.

Incremental mean accumulators add only. Eviction/rejection/removal rebuilds the cached sum; subtracting creates action-order-dependent rounding differences. Median/trimmed mean require full reductions. Rejected epochs are retained and marked, never silently deleted.

## Legacy interfaces retained for comparison

Legacy streams: epochs/average Float64; events Message JSON v1; status Float64, 18 lanes at 2 Hz. Epoch blocks use **trigger RTC**, not epoch-completion time. Legacy derived epoch files hold flattened float32 epochs with geometry attributes, timestamps, labels and MEP amplitude/onset/rejection. They are not the raw recorder file.

Legacy lifecycle idle→collecting⇄paused; Stop→idle. State-entry logic resets collection and performs save-on-stop for every invocation path. Reset/save/note are explicit Actions and must not fire when loading parameter descriptions.

## Validation and evidence

For **current** shared arithmetic use the TepSound tests and source map in [TepSound](tepsound.md); do not advertise legacy `test_TepPipeline` as a current top-level target. Its archived cases and the full SciPy/reference comparisons remain [numerical evidence](../history/components/tep.md#history-24-numbers-this-module-and-the-legacy-agree-on-exactly), with [end-to-end history](../history/components/tep.md#history-5-verified). Separate [test prerequisites](../how-to/test.md) from old measured counts.

The shared arithmetic is active; the retired GUI/operator behavior is comparator context. No legacy/current pipeline was executed in this documentation change.
