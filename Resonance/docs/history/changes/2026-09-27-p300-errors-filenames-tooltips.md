# P300 error visibility, optional subject, filenames and classifier controls

2026-09-27. Active source `R:/src`, operator package `R:/dist`. Follows the [operator/pretraining change](2026-09-27-p300-operator-pretraining.md). [Current contract](../../components/p300.md). Evidence: `R:/src/_test-output/p300-movicom-review-20260927`.

The prior layout put scenario failures only inside the backup presentation controls. Those controls default hidden, so a refused Start could appear to do nothing. P300 now shows a red error banner independently of those controls, in windowed or fullscreen presentation. The Configurator error parameter remains available.

A blank subject is filled automatically: a selected personal model supplies its identity for typing; new calibration/group use defaults to `Anonymous`. Offline import can infer identity from the recording; legacy unidentified files use `Anonymous`. Explicit conflicting identities remain refused. The default is stored in the run/model, rather than only used as a filename label.

Recording names now append the stimulation mode to the filename template, with an additional training/typing phase for combined sessions. For example `Anonymous_session_Pretraining-Typing_training-0001.hdf5` and its separate `..._typing-0001.hdf5`. Windows-forbidden filename characters are replaced; directories, extensions, non-overwriting numbering and the operator's original template are preserved. `StimulusRecording::begin` accepts an optional filename override; other callers retain their existing naming behavior.

The classifier window no longer duplicates session mode, pretraining length, key pacing or backup-control visibility. Its first tab is **Calculation settings**. All classifier inputs and actions have wrapped hover tooltips. Each Available channels stream is a copy button for its space-separated channel names. Record inspection no longer jumps to the results tab after an earlier calculation; only a completed calculation does that. The previously undescribed photodiode-corner parameter now has a description.

## Verification

Native numerical/import checks passed, including blank-identity import and all retained group-reference fits. The overlapping-origin regression was run separately with its fixture path and passed. UI tests cover visible errors with controls hidden in windowed/fullscreen display, safe mode-bearing filenames, independent classifier controls, actual clipboard content and hover tooltip visibility. Recorded synthetic integration exercises full calibration with an empty subject, one-/two-letter adaptation, automatic model saving, separate phase filenames, key-paced typing, save-tail cancellation and failed calibration. Test logs, PNG captures and saved HDF/model checks are in the evidence folder.

Executed totals: native suite **11 passed / 1 fixture skip**, followed by the skipped origin test with its fixture supplied (**3 passed including setup/cleanup**); full UI/session suite **16 passed / 0 skipped** with eight recordings and three saved models audited. The final UI rerun after clearing a stale group-description label passed **15 / 1 optional-session skip**; the full recorded session had already passed. Initial test runs caught a test's wrong serialized dash/filename expectation and inspection's unwanted results-tab switch; these were corrected before deployment.

Only `dist/bin/P300.exe` was replaced after verifying P300 and Recorder were idle. P300 was relaunched with its original Movicom service configuration and every writable runtime parameter restored. The existing Movicom service was not stopped or reconfigured. The deployed binary matches the staged build; all seven participant recordings and three saved personal classifiers retain their original hashes. Deployment identity and preservation checks are in `deployment.json`.

The four real Movicom recordings were also inspected independently: [results and comparison with NVX](../investigations/p300-movicom-avtest2-20260927.md). These numerical replays do not operate either amplifier or change the deployed classifiers.
