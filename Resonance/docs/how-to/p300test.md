# P300TEST venue

Current configuration, updated 2026-09-27. Source: [src/venues/P300TEST](../../src/venues/P300TEST); deployed beside MPRAC at `R:\dist\venues\P300TEST`. Entry: [01_Configurator.bat](../../dist/venues/P300TEST/01_Configurator.bat). The concise operator reference is [the venue README](../../src/venues/P300TEST/README.md).

## Acquisition and synchronization

Both amplifiers use the supplied Movicom montage order: Cz, Pz, C3, C4, PO7, PO8, O1, O2. NVX physical inputs 1–8 are EEG; 49 is Photodiode / AUX1 and is excluded from classifier features. NVX runs at 1000 Hz, block 100, without an appended trigger word. Movicom runs at nominal 500 Hz, block 25, with D7 firmware synchronization enabled. REF is the declared reference; change it if the physical reference differs.

The NVX native recipe uses an analogue rising threshold of −1.85 V on `Photodiode`, offset 0 ms, search length 100 ms. These values belong to this diode setup and must be checked if the optical hardware, monitor brightness or patch position changes. The observed crossing must have two adjacent finite samples: invalid samples are not interpolated, and no missing optical onset falls back to a presentation timestamp. Movicom recipes use the paired firmware clock stream; they do not claim optical synchronization.

Both recipes use the native default 6×6 HP/LP classifier described in [P300](../components/p300.md). Presets populate `trainingOptions`; subject and reference edits reach automatic calculation. Separate calibration and typing presets remain available. Applying typing preserves the selected classifier and subject; model checks still apply. Separate calibration uses explicit Save/Use after validation. Alternatively select **Pretraining + Typing**, set **Pretraining letters**, and Start: the classifier is automatically calculated, saved beside the calibration recording and used for a separate typing recording. Combined mode always adapts the selected group prior with any positive requested count, default two. Full personal calibration remains available in ordinary Training. The combined handoff automatically saves/uses the model and skips extra recording padding; key pacing still applies when enabled.

Standalone P300 now starts with the same presentation/timing defaults as this venue. Standalone Movicom embeds the eight-electrode montage and enables firmware sync by default; no venue launcher is needed to obtain these names. A custom CED still overrides the montage.

## Group options

Added 2026-09-27: `09_NVX_group_typing` and `11_Movicom_group_typing` select immediate group feedback; `10_NVX_short_calibration` and `12_Movicom_short_calibration` select two labelled letters and automatic group adaptation. Subject is optional (blank becomes Anonymous). The Classifier panel accepts any positive recorded-letter count. In combined mode, Pretraining letters controls presentation and fitting together. Save the adapted result and Use it, then apply ordinary typing (`05` / `08`), which retains the selected model. Group-typing presets deliberately select their shipped group model.

The `classifier/` folder contains Q 6×6 (43 subjects, 425 letters) at 1000 Hz, Movicom 6×6 (49 groups, 623 letters) and 3×3 (49 groups, 686 letters) at 500 Hz. The venue uses 6×6. Group statistics and length-specific blend weights were fitted on learning data only; recorded play was reserved for testing. Hardware/reference and timing differences mean new-cap accuracy still requires prospective testing. Full 12-letter calibration remains available. [Algorithm and separate-play results](../history/investigations/p300-group-transfer-20260927.md), [native/hardware evidence](../history/changes/2026-09-27-p300-group-classifiers.md).

## Display and service ownership

The launcher finds Windows primary/secondary monitor roles. Standard Configurator is placed inside the secondary work area. P300 selects `Primary (explicit)` and Full screen immediately fills that monitor. Untick Full screen to return to a window; the obsolete primary/run-only overrides are ignored. The separate Classifier window opens on Configurator's monitor. Backup presentation controls are hidden by default, including while idle; **F10** or **Presentation controls** toggles them. NVX's 60 × 60 patch is at the top-right corner. Movicom does not display an unused optical patch.

Presets contain 12 calibration/typing letters and five cycles per letter. The launcher converts the nominal 60 Hz timing values to integer frames at the primary's reported refresh rate. At 144 Hz the 100/50 ms flash/interval becomes 14/7 frames, approximately 97.2/48.6 ms; target hints and inter-letter intervals are converted too. Frame-swap timestamps and the measured photo sample remain distinct quantities.

**Press to type next letter** defaults to on in all P300TEST presets. Space starts each typing letter, including the first. Disable it explicitly for continuous automatic typing. Pretraining target letters proceed automatically.

Only ordinary services are used: `Configurator`, `NVX`, `Movicom`, `P300`, `Recorder`. Launchers are short-lived preset clients; they reuse their venue's services, refuse duplicates/another venue's instances and refuse changes during an active presentation or recording. Explicit EEG/impedance launcher actions configure acquisition. Task launchers apply the EEG preset/start only to a stopped amplifier and leave a running acquisition untouched, then prepare P300 without starting presentation. P300 Start owns Recorder start/save; its default is Use running amplifier, with optional Start if stopped. P300 never stops/reconfigures the amplifier on normal completion, cancellation or error. Legacy before/after acquisition JSON in older P300 presets is ignored.

Files are recorded under `dist/data/P300TEST`, with subject and amplifier/task names. Classifier files remain operator-owned. CMake stages/installs P300TEST beside MPRAC; redeployment must preserve operator edits. QA captures and synthetic fixtures stay outside the distribution.

## Verification scope

[2026-09-26 acceptance and evidence](../history/changes/2026-09-26-p300test.md) records the connected NVX/Movicom USB routes, display placement, optical tests, native live/offline parity and remaining human EEG checks. A successful hardware/processing test is not a measurement of P300 accuracy with the cap.
