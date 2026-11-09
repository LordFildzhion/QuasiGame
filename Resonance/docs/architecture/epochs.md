# Epoch, timing and topography contracts

Status: current coding reference. Applies to the viewer and active TepSound consumers/producers.
Authority: [epoch announcement](../../src/quickStimulus/epochannounce.hpp),
[geometry/store](../../src/quickStimulus/epochbuffer.hpp), [cutting](../../src/quickStimulus/epocher.hpp),
[receiver](../../src/quickStimulus/epochreceiver.hpp) and their implementations/tests.

## Source routes

| Change | Primary files | Related checks |
|---|---|---|
| Window/sample arithmetic, retention, averaging | `quickStimulus/epochbuffer.*` | `test_EpochBuffer`, `test_EpochStore` |
| Trigger-to-epoch cutting and marker association | `quickStimulus/epocher.*` | `test_Epocher` |
| Published metadata, counters, announcement identity | `quickStimulus/epochannounce.*` | `test_EpochAnnounce` |
| Rendering, ingest and publication wiring | `quickStimulus/epochreceiver.*`, `epochgridview.*` | Numeric tests plus scoped UI/replay checks |
| Stimulus-frame attribution | `quickStimulus/stimulusattribution.*` | `test_StimulusAttribution` |
| Scalp interpolation and contours | `quickStimulus/topofield.*`, `topoview.*` | `test_TopoField` and recorded oracle comparisons |
| Online SOUND/TEP pipeline | `tepSoundService/soundpipeline.*`, `tepSoundService/shared/tepService/pipeline.*` | [TepSound validation](../components/tepsound.md) |

Paths in this table are relative to `R:\src`. [CMake](../../src/quickStimulus/CMakeLists.txt)
decides the consumers of shared code. These numeric test executables are not all registered
with CTest; use [testing](../how-to/test.md) to distinguish built from discoverable/executed tests.

## Transport and metadata

The Float64 transport record has positional fields. Adding a field such as an average count
would silently change framing for every producer/consumer; use the existing metadata/data
contract unless explicitly designing a protocol migration.

Per-channel metadata has exactly as many entries as the announced channel count:

- `window_start_ms`: its presence declares an epoched stream. Do not invent a known start when
  relaying a producer that did not provide one.
- `window_end_ms`: the **exclusive** right edge. For a known window,
  `(end - start) / 1000 * sampling_rate == delivered_samples`. Use `EpochGeometry` for snapping,
  zero sample and axis conversion rather than several slightly different arithmetic formulas.
- `epoch_kind`: `trial` or `average`; `epoch_stage`: `raw`, `preprocessed` or `cleaned` when known.
- `epoch_stamp`: `trigger`, `first`, `last` or `none`. Missing means unknown. An average uses
  `none`: its creation time is the publishing instant, not the time of a representative sample.
- Units use the existing ASCII vocabulary, including `V`, `mV`, `uV`, `Ohm` and `bitfield`.

Windows can genuinely differ by channel. TepSound's EEG and MEP channels can have different
start/end times while delivering equal sample counts. Preserve each channel's time base through
display, cursor sampling, averaging and republishing. A single modal window must not silently
replace them.

## Viewer-cut continuity

Same-stream trigger alignment uses sample indices. Continuity evidence is separate from the block's RTC stamp convention. `EpocherSettings::useBlockTimestamps=true` retains strict timestamp-gap checking; false uses received sample order and is only appropriate for sources that pad missing samples. Fully nonfinite rows are explicit gaps in either mode; partially missing channels remain per-point NaNs. Nonfinite trigger input never becomes a synthetic edge. MPRAC uses sample order for NVX host-stamped blocks. See [viewer settings, prerequisites and refusal reasons](../components/signal-viewer.md#cut-continuity-and-refused-epochs).

## Stream identity and publication

Publish once and send many blocks. A new average changes data, not the stream's TCP endpoint.
Only a changed announcement—identity, geometry or relevant provenance—requires republishing.
Use `announcementChanged`; equivalent NaN montage positions compare equal for this purpose.

Changing averaging method, scope or labeling provenance is a real semantic boundary and belongs
in the announcement. Counts that change every stimulus do not: `n_contributing` and `n_received`
can be appended as flat AUX channels with empty units and no scalp position. This keeps counts
with their samples in recordings without rebuilding the stream on every epoch.

Empty publication names mean disabled. Preserve this default. Re-announcing a source must not
erase valid viewer history merely because its identity is unchanged, and incompatible geometry
must not silently combine with the previous store.

## Cutting, attribution and averaging

- Detect edges on the raw trigger bitfield before interpolation, filtering or baseline removal.
  A filtered trigger column is no longer a bitfield.
- Distinguish sample-aligned edges from Message/RTC-trigger approximations. RTC is comparable
  across processes on one host; it is not automatically synchronized across machines. A schedule,
  transport arrival, screen swap and physical stimulus onset are different instants.
- Marker-based labeling and frame-based stimulus attribution are distinct rules. Preserve the
  chosen rule and perception-latency provenance; do not silently exchange them.
- The buffer retains individual trials for rejection, selection, median and trimmed means.
  An incoming average must not be treated as one equally weighted raw trial.
- Serial identity survives ring movement/eviction. Rejection retains evidence and affects
  contribution; a stored row index is not a stable epoch identity.
- Keep `received` distinct from the number actually contributing. Empty/default bins are valid
  bins, not an alias for all conditions. Do not mix incompatible rates, lengths or time bases.
- Nonfinite points need per-point valid contributions. No contributions means NaN, not a measured
  zero. Keep NaNs out of persistent filter delay state so one gap cannot poison a channel forever.
- Retention policy and memory reporting are explicit. `EpochReceiver` selects uncapped growth
  for the viewer and notifies at 2 GiB of accounted memory; the underlying `EpochBuffer` class
  defaults to a fixed eight-slot ring. Do not replace the viewer default with the earlier 512 MB
  policy. Uncapped growth still has a 100,000-slot ceiling, after which eviction is reported through
  `ceilingReached`. Preserve that notification and the distinction between received and retained
  epochs. Explicit count/byte-budget modes remain available.

## Topography

Use the accepted EEGLAB-style 2D biharmonic interpolation in `topofield`, not the abandoned
spherical-spline proposal. Electrode geometry, interpolation field, display mask and contour
levels have separate meanings. Excluded/nonfinite/unplaced channels do not enter the solve.
Use asymmetric test fields to detect left/right or nose mirroring; a symmetric recording can
make a wrong orientation appear correct. Field extrema, not just electrode extrema, affect
contour levels. Keep oracle inputs and tolerances with their measured comparison.

All renderings must consume the same selected epoch/average. Painter/delegate code must not
become a second owner of analysis state. Viewer display filtering can affect viewer-cut epochs;
record the stage instead of assuming everything shown is raw.

## Rationale and evidence

[Metadata decision](../decisions/epoch-metadata.md) and [topography decision](../decisions/signal-topography.md)
summarize accepted choices. Full [design evolution](../history/investigations/design_viewer-epochs.md)
and [implementation/verification history](../history/investigations/design_viewer-epochs-STATUS.md)
retain changes, rejected designs and measured results. [TepSound investigations](../history/investigations/tepsound-analysis.md)
are dated evidence. Use current source and the [issue registry](../issues/README.md) to establish
what remains unresolved today.
