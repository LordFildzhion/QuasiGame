# DEC-003: Describe epochs without changing the positional wire record

**Status:** accepted; introduced and validated during the 2026-08-20 viewer work. **Source review:** 2026-09-15.

## Decision

Keep the existing `Float64` block format. Declare epoch geometry, kind, processing stage, timestamp meaning and units through per-channel metadata. The [epoch contract](../architecture/epochs.md) is the canonical field specification.

`window_start_ms` declares that the stream is epoched; the right edge is exclusive. An average uses `epoch_stamp = "none"` because its block creation time is not a trial's trigger. Preserve an unknown timestamp interpretation as unknown when relaying legacy producers.

Publish a stream once and send subsequent blocks on that stream. Recreate its announcement only when externally visible structure or analysis provenance changes. A new average value or contributing count is content, not a reason to move the TCP endpoint.

## Why

The wire record uses positional fields without field tags or a version byte. Adding a field would silently break existing readers. Metadata already supplies per-channel descriptions, including channels whose windows have different origins.

Republishing for every changing average count would disconnect viewers, recorders and downstream consumers at the stimulus rate. Where counters are requested, average publications therefore append `n_contributing` and `n_received` as constant AUX channels in the block data. The counters are recorded with the average they describe.

## Consequences

- All metadata lists match the announced channel count. Counter channels have no scalp position and must be excluded from EEG analyses.
- Average only epochs with compatible geometry; equal block length alone does not establish a shared time axis.
- Compare equivalent unknown coordinates consistently when comparing announcements: NaN coordinates must not force continual republishing.
- A real change of analysis method or provenance may require a new announcement. A changing sample value does not.

**Implementation evidence:** [`epochannounce.hpp`](../../src/quickStimulus/epochannounce.hpp), [`epochannounce.cpp`](../../src/quickStimulus/epochannounce.cpp), [`epochbuffer.hpp`](../../src/quickStimulus/epochbuffer.hpp), [`epochannounce_test.cpp`](../../src/quickStimulus/tests/epochannounce_test.cpp). Test registration remains TEST-001 in the [issue registry](../issues/README.md).

**History:** [design and rejected alternatives](../history/investigations/design_viewer-epochs.md), [staged validation and later corrections](../history/investigations/design_viewer-epochs-STATUS.md).
