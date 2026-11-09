# MPRAC lab fixes r2 — 24 September 2026

Scope: the reported Configurator, StimulusPresentation and P300 lab issues. Current source
`R:/src`, Qt 6.11.2/MSVC v143; scoped deployment to `R:/dist`. Standard service names and views
are retained. No physical amplifier was opened for this round.

## Changes and diagnosis

- Discs now obtains the exact normalized Field circle/nose/ear polylines from
  `TopoView::headOutline()`. Field retains its prior geometry. Discs fitting additionally includes
  the contour so small central montages do not crop its nose/ears. The background-image path and
  user zoom remain explicit.
- The second standard viewer starts collapsed into a 28-pixel title line. Its arrow opens it;
  collapsing records the current divider size and reopening restores it. Side-by-side mode retains
  width analogously. Hidden controls do not stop the receiver, epoch cutter or publication.
- MPRAC PNGs use 12/1K for EEG, 12/Ω for impedance, a 3×3 selected-row P300 calibration matrix,
  and the same matrix below AB_ for typing. The strip points the impedance launcher to its new PNG.
- Shared automatic subject-screen selection chooses right of primary, then leftmost on its left,
  then any secondary, then primary. Named choices remain explicit. Primary placement is windowed
  even with a fullscreen preset; only secondary placement automatically becomes fullscreen.
  Old serialized default labels load through a compatibility selector. P300's lower controls are
  hidden whenever its actual window is fullscreen.

`refused (gap N)` is a continuity refusal, not an electrode amplitude/quality rejection.
The original cutter compared block creation timestamps at a half-sample tolerance. NVX creates
them when blocks arrive at the PC, so ordinary delivery jitter could mark every epoch as spanning
a gap. This is a demonstrated mechanism and consistent with the user's report; the exact failed
lab recording was not supplied for this round.

MPRAC now explicitly selects `epoch_cut_use_block_timestamps=false`, exposed as **Sample order
(padded gaps)** in the ordinary Cut settings. Strict timestamp checking remains the generic
default. Sample order requires a source that preserves positions and represents loss as missing
rows; NVX pads ordinary hardware-counter losses with NaNs. The cutter rejects windows containing
fully missing rows in either mode and resets trigger state at nonfinite input, avoiding artificial
edges. Partially missing EEG channels remain NaNs within accepted epochs. No acquisition driver,
wire format or sample values were altered.

This corrects the earlier follow-up's inference that old host-timestamp discontinuities were
necessarily actual lost samples. The earlier uniform-clock replay remains historical evidence;
the current replay uses the original recording and timestamps without writing to either.
Sample-order mode cannot recover an unrepresented loss or make host-timed external markers into
hardware timestamps. Its prerequisite is documented in the Cut UI and current viewer page.

Other refusal counters identify missing initial prehistory, expired history, stopping before
post-history arrives, refractory spacing, excluded codes, unusable external timestamp convention,
or pending-queue capacity. They are documented in the current viewer guide and patch instructions.

## Verification

- Builds via `scripts/build-qt6.ps1 -SkipConan` succeeded. Final staging log:
  `src/_test-output/labfixes-r2-build-outline-fit.log`.
- Six selected CTest targets passed: ViewerReconnect, ConfiguratorLiveStatus, NvxFrameLogic,
  StimulusPresentation, P300Plan and P300Ui. Log:
  `src/_test-output/labfixes-r2-ctest-verified.txt`.
- `test_Epocher`: 40/40; synthetic host jitter with only one finite EEG channel is accepted at
  the correct sample index; padded missing rows reject the overlapping epoch without invented
  trigger edges. Existing strict-timestamp tests also pass.
- `test_TopoField`: 43/43. ViewerReconnect: 7/7. Native-window head QA: 2/2; final PNG inspected at
  `src/_test-output/labfixes-r2-visual/head-outlines.png` with both complete matching contours.
- Configurator's real QML regression verifies default collapse, expansion, an adjusted 237-pixel
  height, collapse, and exact restoration. Screen regression covers right/left/above/portrait,
  negative coordinates, nonzero primary index, single screen and legacy default labels. P300 UI
  regression verifies controls hidden in fullscreen and restored when windowed.
- `test-mprac-erp-playback.py` reads the original `mp_checkersLarge01.hdf5` and
  `mp_buttonPress01.hdf5`. The ordinary lower viewer accepted all 60 large-checker epochs and nine
  button events in the 45-second checked prefix, zero gaps/refusals. Output:
  `src/_test-output/mprac-erp-playback-20260924-184223/report.json`.
- The installed standard launcher test passed at
  `src/_test-output/mprac-standard-launchers-20260924-184921/report.json`: standard service names,
  reuse and task switching, recording start/stop, retained EEG mode, 14 channels, Recorder names,
  P300 calibration/typing and false block-timestamp continuity readback. It used an explicit
  software NVX fixture, not a physical amplifier.
- An initial new layout test lacked the test engine's resource import path; adding it fixed the
  harness. A concurrent replay collided with Configurator's actual service identity during a UI
  test. Those were rerun serially and passed. No product workaround was added for that collision.

Mixed GPU/motherboard monitor outputs, actual optical timing and the user's exact one-channel
lab run still need lab confirmation. P300 feedback continues to require the user's compatible
trained 12-channel MATLAB classifier; no model was fabricated or included.

## Deployment and patch

Deployment copies changed files only, with before-image backups and SHA-256 manifests:
`src/_test-output/mprac-labfixes-r2-deployment.json` and
`src/_test-output/mprac-labfixes-r2-final-deployment.json`. No recordings or local classifier files
were copied or removed.

`builds/patch_mprac_labfixes_20260924_r2.zip` is cumulative over `resonance_20260924.zip`, also
applicable after `patch_mprac_p300_20260924.zip`. Contents sit directly at the dist root and use
stored ZIP entries. It includes the earlier MPRAC/P300 payload plus these corrections, current
documentation, installation instructions and a hash manifest. The adjacent verification JSON
records its exact payload count, byte size, SHA-256 and integrity results. Source/test files and
recordings are excluded; this is an update, not a standalone full runtime.
