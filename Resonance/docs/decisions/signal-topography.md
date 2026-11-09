# DEC-004: Match measured EEGLAB topography

**Status:** accepted; established during the 2026-08-20 viewer work. **Source review:** 2026-09-15.

## Decision

Use EEGLAB `topoplot` behavior as the numerical and orientation reference for signal scalp maps. The field uses two-dimensional biharmonic interpolation (`griddata` v4) on the projected, squeezed coordinates. The earlier plan to reuse a spherical spline was rejected after reference measurements.

Select EEG channels by `kind` metadata. Channel numbers and plausible-looking electrode positions do not establish that an input is EEG. Keep montage geometry separate from the currently contributing channel set, and exclude absent/invalid readings from the solve.

## Why

Wrong axis order, scaling or channel selection can produce a convincing scalp map with a materially different field. The kernel is not scale-invariant: coordinates must be squeezed before solving. The 2% padding outside the outermost electrode changes the interpolation, not merely its appearance. Labelled reference renders establish Fpz at the top, Oz at the bottom, T7 left and T8 right.

## Consequences

- The field can extend beyond the drawn head circle; clipping to that circle discards valid outer electrodes.
- `conv` limits displayed extrapolation. It must not change the computed field or its color scale; EEGLAB implements it by occluding the field and contours.
- A missing reading remains visibly unknown. A filled interpolated map is not evidence that every electrode was measured.
- Preserve numerical grids, labelled renders, generator versions and error metrics when changing this implementation. A screenshot alone cannot validate it.
- Rounded CED polar coordinates can differ slightly from EEGLAB coordinates recomputed from Cartesian values. That remaining precision issue is SCI-001; it does not justify silently changing all montage consumers.

**Implementation evidence:** [`topofield.hpp`](../../src/quickStimulus/topofield.hpp), [`topofield.cpp`](../../src/quickStimulus/topofield.cpp), [`topofield_test.cpp`](../../src/quickStimulus/tests/topofield_test.cpp). Reference generators are currently under `R:\config`; the test oracle defaults to `R:\dist_legacy\Qt5\_build\topo-ref`. Portability and missing historical viewer harnesses are TEST-002/003 in the [issue registry](../issues/README.md).

**History:** [viewer reference campaign](../history/investigations/design_viewer-epochs-STATUS.md), including the spherical-spline correction, field/contour comparisons, palette and retained evidence limits.
