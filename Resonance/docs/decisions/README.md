# Decisions

Read a decision when changing the behavior it explains. Current contracts live in architecture and component pages; these records explain the accepted tradeoff and the alternatives that were rejected. A proposal is not an implementation instruction.

| ID | Accepted decision | Applies to |
|---|---|---|
| DEC-001 | [Qt 6 is the default tree](qt6-default.md) | Build, deployment, module selection |
| DEC-002 | [KARDi2 uses an x86 vendor broker](kardi2-broker.md) | Device integration, packaging, process lifecycle |
| DEC-003 | [Epoch semantics use metadata on the existing stream](epoch-metadata.md) | Producers, viewer, recorder, downstream analysis |
| DEC-004 | [Signal topography follows measured EEGLAB behavior](signal-topography.md) | Projection, interpolation, channel inclusion, scientific validation |

## Proposals and external questions

- [SMI RED500 integration](proposals/smi-red500.md): proposed UDP client; bench questions remain.
- [Movicom eight-channel EEG integration](proposals/movicom.md): native FTDI acquisition demonstrated; service implementation and calibration remain proposed.
- [Vendor SDK inquiry routing](proposals/vendor-sdk-inquiries.md): unresolved questions, correspondence status and evidence. This page does not authorize contacting anyone.
- [Issue registry](../issues/README.md): concrete work and historical reports requiring recheck.

When replacing an accepted decision, add a new decision, mark the old one superseded, and link both directions. Record the reason and evidence; do not overwrite the earlier rationale. Update the affected current contract in the same change. Dates below describe adoption or review, not a claim that a fresh hardware test was run.
