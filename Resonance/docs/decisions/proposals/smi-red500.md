# PROP-001: SMI RED500 integration

**Status:** proposed; research dated 2026-09-14. No implementation or hardware acceptance follows from this record. **Full evidence:** [SMI investigation](../../history/investigations/smi-red500-assessment.md).

## Proposed direction

Implement a native Qt 6 UDP client to the existing iViewX application on the RED500 kit laptop. Use the documented `ET_` remote commands for control and samples. Keep tracker acquisition and the existing licensed software on that machine while Resonance receives a recordable stream.

The investigation identifies iViewX 2.8.43 on the kit and an x64 iViewX SDK 4.4.10. Those are dated package findings, not proof that every combination has been tested. The SDK remains useful as a comparison client; the proposed production boundary is the network protocol.

## Why this option

The kit already supplies tracking and calibration. A UDP adapter fits the existing service architecture and avoids making the current process load the SDK's old Visual C++ runtimes and installer-associated InpOut driver. Writing a tracker from camera frames would be a separate, much larger research project.

The alternative of embedding the vendor SDK is still possible if a bench comparison finds an essential function absent from the remote protocol. That choice should follow evidence, not a claim that the SDK cannot be used.

## Corrected hardware facts

The later inspection identifies an **Euresys Grablink frame grabber with a Pulnix TM-6740CL CameraLink camera**. Early uEye USB claims in the research narrative were withdrawn. The laptop was observed running Windows 7; 32-bit architecture was inferred, not independently established in that note. Preserve the installed machine until the license type and recovery procedure are known.

## Resolve before accepting a design

1. **Intended behavior:** passive recording or gaze-contingent presentation. The latter needs measured end-to-end latency and loss handling.
2. **Sample meaning:** establish pupil units, validity flags, whether zero means invalid, eye order, coordinate system and rate. Specify invalid values as NaN only after interpreting the vendor output.
3. **Time:** measure the `TU` clock, restart/reset behavior and monotonicity. Separate missing UDP packets from gaps already present at the tracker; record both where distinguishable.
4. **Calibration/control:** prove start/stop, calibration and validation command/reply behavior on the installed software; define the operator UI needed for it.
5. **Recovery:** identify the license mechanism and what restores the working acquisition laptop. The present evidence does not establish a transferable license.

Proposed acceptance: capture a timestamped vendor/client comparison with rates, units, valid/invalid examples, gaps, restart behavior and calibration results. A compatible first four `eyeData` channels can help reuse EyeLink consumers, but do not declare semantic compatibility before these checks.

Track future work under PROP-001 in the [issue registry](../../issues/README.md). The full investigation preserves package inventories, alternatives and corrections; this page records the current proposal only.
