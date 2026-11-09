# P300 paired timing fields and short group adaptation — 2026-09-27

Deployed to `R:/dist/bin/P300.exe` and the three affected Resonance QML files. Current behavior: [P300](../../components/p300.md).

Eight frame-duration parameters now use two editable columns with fixed frames/ms suffixes; ms edits round to the nearest whole frame. Monitor rate changes update the conversion; missing rate disables ms editing. Integer serialization and ordinary numeric editors are unchanged. Labels stay clean, mode order begins Training / Typing / Pretraining + Typing, Recording is capitalized, and the external SPEED service/stream are marked Legacy in Classifier.

Combined mode always adapts its selected group prior with two or three labelled letters (default two), even with a stale full-subject calculation preset. It automatically saves and uses the model and starts a separate typing recording. Failure, rejected letters and cancellation preserve the active model. The group recipe determines the required final EEG tail; extra recording padding is skipped between phases. Matching running acquisition is reused. Explicit next-letter pacing remains the default, including before the first typed letter; disabling it allows automatic typing.

## Evidence

Evidence root: `R:/src/_test-output/p300-dual-timing-adaptation-20260927`.

- Build: P300, its UI/planner tests, shared QML and affected Stimulus presentation target succeeded.
- Recorded integration: **18 UI tests passed**, no failures/skips; eight synthetic HDF5 recordings and three automatically saved models audited. Three- and two-letter group adaptation, key-paced and automatic typing, save-tail cancellation, and missing group-channel failure were exercised.
- With the private software NVX fixture and configured **3-second** recording padding, completed-training to typing-start gaps were **1973.5, 1907.6 and 1969.4 ms**. Five training attempts created five acquisitions; the three typing phases reused their matching running acquisitions. This measures software workflow timing, not new physical amplifier acceptance.
- Final ordinary UI suite: **17 passed**, one optional recorded-integration skip; paired-field keyboard edits, 144/60 Hz conversion, quantization, read-only/unknown-rate behavior and remote updates passed. Standard 330 px parameter-panel PNG inspected.
- Planner **8/8**, shared Stimulus presentation **16/16**, parameter-tab keyboard regression **2/2**, and status-line regression **8/8** passed. An initial standalone Stimulus test launch lacked the offscreen plugin path; rerun with the explicit test plugin path passed.
- Managed recording audit confirmed EEG, events, status and three classifier outputs, plus Recorder’s annotations group. Movicom synchronization recording is conditional in service code; no hardware run was performed for this change.

Deployment preserved writable P300 and Configurator settings, except the obsolete 12-letter pretraining default was changed to two. Configurator was relaunched with Qt geometry on the detected secondary display; P300 retained Primary (explicit). Raw recordings and participant model files were unchanged. Exact deployed hashes, parameters and launch arguments are in `deployment.json` and `operator-before/after.json`. The first deployment wait timed out after P300 exited; deployment resumed from the saved parameter snapshot and completed.

Desktop control was stopped by the user’s Escape key after deployment. No further desktop actions were taken, so final live-window visual inspection was not completed; source-native/offscreen verification and deployed service readbacks are the evidence above.
