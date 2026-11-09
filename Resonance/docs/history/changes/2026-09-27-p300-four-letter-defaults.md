# Four-letter calibration recovery and shipped P300TEST defaults

2026-09-27. Current contracts: [P300](../../components/p300.md), [Movicom](../../components/movicom.md).

The reported four-letter Pretraining + Typing run completed acquisition but failed during automatic calculation: “No EEG stream matches the selected channels.” Standalone Movicom with an empty CED published CH1–CH8; the selected group model required Cz, Pz, C3, C4, PO7, PO8, O1, O2. The venue launcher previously supplied the montage, so otherwise equivalent standalone settings differed. Four letters themselves are supported and were not the cause.

## Changes

- Movicom embeds the user-confirmed `venues/P300TEST/montages/movicom8.ced`. Empty CED now supplies its electrode names and coordinates without an external path. Subsets retain physical input numbering. Explicit custom CED files retain precedence; partial custom files still use CH-number fallback for unlabelled inputs. Channel controls show physical numbers and built-in electrode names. REF/GND remain unsampled; voltage conversion, rate and sample order are unchanged. Firmware synchronization defaults on, remains switchable, and publication remains 25 samples per block.
- Fresh P300 uses the venue presentation defaults: fullscreen primary, 12 letters, five cycles, 3/1 target/same-element gaps, one-second pre/post-sequence periods, 60×60 top-right optical patch, keyboard pacing and hidden backup controls. Nominal 60-Hz frame timings are quantized once for the primary display at startup, giving 14/7 flash/blank frames at 143.998 Hz. Saved configurations override startup defaults; later monitor changes preserve frames. The initial NVX profile now initializes REF, the group prior and processing fields just as an explicit amplifier change does. Selecting Movicom selects its firmware profile and hides the optical patch. Automatic Training calculation is on; pretraining count still defaults to two and accepts arbitrary positive counts.
- Automatic calibration validates the first live EEG block against its required channels, units and sampling rate before emitting the processing origin or showing training flashes. Errors list available names. This uses the same strict channel mapper as offline import and native feedback. It does not infer an arbitrary montage from unnamed channels or change amplifier acquisition settings.

## Recovery

Read-only source: `R:/dist/data/Anonymous_p300_Pretraining-Typing_training-0003.hdf5`, SHA-256 `31ae6ad2f87915feb298e1d9ce17882af38e3836d4285d837c4958296e57b25f`. Four complete letters contain 240 flashes, 60 each, with a recorded completion event and firmware clock mappings. No epochs were rejected.

For this recovery only, a temporary copy of the group model used CH1–CH8 labels in the explicitly confirmed physical electrode order. Its coefficients/statistics were unchanged. Native adaptation read the original recording directly. The resulting model uses the canonical electrode labels for the newly shipped stream; provenance contains the explicit physical-input/recorded-label/electrode mapping and the original source fingerprint. The recording was not copied, relabelled or overwritten.

Independent continuous SciPy SOS filtering from the recorded processing origin, feature averaging and centered count-pooled ridge Fisher fitting reproduced the native features (relative error 1.46e-16) and weights (1.12e-12). The four-letter policy uses 100% personal mean contrast and covariance, retaining the selected filter/window/ridge recipe. These fit letters do not estimate held-out typing accuracy.

Recovered model: `R:/dist/calib/Anonymous-movicom-20260927-four-letter.p300.json`.

## Verification and deployment

Native build passed. All 28 Movicom software tests passed, including full/subset default montage, custom/partial montage and configuration defaults. All 20 P300 UI/workflow checks passed. The private synthetic Recorder workflow now includes four-, one- and five-letter adaptation followed by typing, cancellation during the save tail, and a mismatched-model refusal with zero flashes. Eight generated recordings and three models were audited. Native classifier tests passed (12 including suite setup/cleanup); the initially skipped overlapping-origin fixture was subsequently run separately and passed.

Both executables were selectively deployed and their hashes verified against the build. The recovered model was selected in Typing, pretraining count four retained, keyboard pacing enabled and P300 left idle. Recorder settings and raw recordings were preserved. Windows stopped enumerating the USB amplifier during deployment; its original serial was retained. After the operator reconnected it, Rescan/Start restored acquisition. An independent live subscriber verified the exact eight electrode names, physical inputs 1–8, 25-sample blocks, 5,500 finite samples per channel and 220 valid firmware-clock blocks. Clock RMS at the final snapshot was 0.528 ms (internal clock-fit consistency, not optical latency). The physical P300 window rectangle was [0,0,3840,1600], exactly the primary display. P300 and Recorder remained idle; no physical stimulation was started. Movicom was left acquiring.

Evidence: `R:/src/_test-output/p300-four-letter-defaults-20260927/`: original/current settings, fresh defaults, build/test logs, `managed-session/`, independent recovery, deployment hashes and physical verification. An initial deployment attempt closed its control socket too early for termination to complete; retaining it until process exit resolved this without forced acquisition termination. A subsequent unavailable-device wait was resolved by restoring the operator UI and saved serial while awaiting USB reconnection.
