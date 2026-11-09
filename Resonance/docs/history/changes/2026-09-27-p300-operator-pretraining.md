# P300 operator window and automatic pretraining → typing

2026-09-27. Requested UI/session update, built and deployed to `R:/dist/bin/P300.exe`. [Current contract](../../components/p300.md), [P300TEST](../../how-to/p300test.md). Evidence: `R:/src/_test-output/p300-ui-pretraining-20260927`.

## Behavior

- Classifier setup is a separate nonmodal window with Setup and Validation and features tabs. It opens on the actual Configurator monitor; native Windows monitor handles map it to Qt's logical work area, including when Qt exposes friendly monitor names. Fallback prefers a non-subject display.
- Presentation backup controls default to hidden in windowed/fullscreen modes. F10 or the ordinary `showControls` parameter toggles Start/Stop/Next/Classifier/Hide controls. Key-paced typing defaults to on in the schema and P300TEST/MPRAC presets; Space starts the first and each subsequent letter. Training proceeds automatically.
- Feature curves have millisecond/amplitude axes, a grid and individual feature markers. Averaged features use actual sample-window centers; V/mV display as µV. No numerical classifier changes.
- New `Pretraining + Typing` mode uses `pretrainingLetters` (default 12), then types `stimSeq` letters. Full training needs at least three labelled letters; group adaptation supports the prior's configured lengths. Training letters are never appended to text.
- Successful complete training automatically closes its recording, calculates, saves a uniquely named portable classifier beside it, and starts a distinct typing recording. The exact requested accepted-letter count is required. Stop during the recording tail/calculation cancels continuation; calculation/import/save failure preserves the active model. Session/run markers keep phases explicit and files separately importable.
- The earlier [NVX overlapping-origin replay correction](../investigations/p300-nvx-avtest-20260927.md) is included in this deployment.

## Verification

Qt 6.11.2 / MSVC 14.44 x64. Native suite: **12 passed, 0 skipped**, including 705 group adaptation reference fits and the overlapping-origin regression. Plan suite: **8 passed**, including first/between-letter key waits and unchanged automatic training.

The final complete UI/integration run `session-final2` gives **14 passed, 0 skipped**. A private synthetic 8×1000 Hz EEG source and test-owned Recorder exercised full three-letter, one-letter-adapted and two-letter-adapted pretraining, each followed automatically by two typed letters. Keyboard tests verified no typing before the first key and exactly one letter per key; pretraining left the text empty. Three saved models and eight HDF5 recordings were inspected: training files contain no selected letters, typing files contain two each; the remaining files cover save-tail cancellation and training failure. The previously active model survived both failures. These are workflow tests with synthetic EEG, not new accuracy or hardware acceptance measurements.

After the last placement-only correction, the UI suite was rerun: **13 passed**, with the already-executed optional recorded-session case skipped. Production placement was then checked against the open Configurator: the classifier opens on its current primary `38GN950` display. Native placement logging and captured window bounds agree. Configurator was not relocated. The fallback-to-secondary behavior before native-handle mapping was diagnosed rather than accepted as a successful match. PNG captures of setup and feature results were inspected; an intermediate QML punctuation error was repaired before the passing final run.

Logs: [native](../../../src/_test-output/p300-ui-pretraining-20260927/native-tests.txt), [planner](../../../src/_test-output/p300-ui-pretraining-20260927/plan-tests.txt), [complete UI/integration](../../../src/_test-output/p300-ui-pretraining-20260927/session-final2/ui-tests.txt), [recording audit](../../../src/_test-output/p300-ui-pretraining-20260927/session-final2/completed.json), [placement rerun](../../../src/_test-output/p300-ui-pretraining-20260927/final-ui-tests.txt). [Feature capture](../../../src/_test-output/p300-ui-pretraining-20260927/final-ui/p300-classifier-results.png).

## Deployment and preservation

Only P300 was restarted after confirming P300 and Recorder idle. Operator parameters were captured and restored, including AVtest identity, optical settings and the existing personal classifier. Key pacing is enabled and presentation controls hidden as requested. Acquisition services were untouched. The classifier window was opened for review.

Source/deployed venue presets changed only the next-letter default; P300TEST's concise README was updated. The original executable and affected distribution files are backed up under the evidence root's `before`; raw AVtest recordings and the active personal model are unchanged. [Deployment identity and model fingerprint](../../../src/_test-output/p300-ui-pretraining-20260927/deployment.json). No QA models, recordings or scripts were added to the distribution.
