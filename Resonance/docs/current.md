# Current state

2026-09-28 P300 offers optional adaptive Typing, off by default: minimum two scored cycles, normalized row/column lead 1.5, existing count as cap, complete-cycle stopping and full pending-epoch drain. Learning-only selection and separate typing replay support testing; human accuracy is unverified. Native/Python parity, private presentation/Recorder workflows, automatic pretraining handoff and MATLAB replay passed. [Contract](components/p300.md#adaptive-typing), [study](history/investigations/p300-adaptive-20260928.md), [deployment evidence](history/changes/2026-09-28-p300-adaptive.md).

2026-09-27 BPRAC now includes sectioned MATLAB 2026 rhythms/movement and P300 processing for legacy files and current NVX/Movicom HDF5. Old Python/saved-classifier results and native feature/model replay agree; whole-letter validation, descriptive ERPs, plot axes and optional XLSX/native model export passed. Original scripts/data remain unchanged. [Entry points](how-to/bprac.md#matlab-processing), [verification](history/changes/2026-09-27-bprac-matlab.md).

2026-09-27 BPRAC supplies three rhythms/movement tasks and P300 6×6/3×3 training/typing for SPRAC-style twelve-channel NVX and eight-channel Movicom. Method PDF, sbj12 event logs and MATLAB processing informed the presets. Four native classifier workflows and six stimulus recordings passed with private synthetic inputs (14 recordings; 19 UI checks). Existing services and reference data were not operated or modified. [Venue](how-to/bprac.md), [scope and evidence](history/changes/2026-09-27-bprac.md).

2026-09-27 MPRAC now ships a dedicated twelve-channel Q/NVX group P300 prior (POz substitutes for absent source Oz). Learning-only nested subject validation gives 380/425 without calibration and 324/339 after two labelled letters. Native 215-fit parity and twelve-channel pretraining/typing acceptance passed. Display and 60 Hz settings are preserved. [Recipe, results and limitations](history/investigations/p300-practicum12-20260927.md).

2026-09-27 MPRAC offline MATLAB analysis now has a separate `mp_pipeline_2026.m` with `_2026` helpers, retaining the original sections and files. Current/legacy HDF5 import, epoch bounds, optical/button matching, P300 labels and plot axes/counts are corrected. Full legacy/current pipelines and physical NVX recording imports passed; no new acquisition or figure exports were needed. [Entry point and reference](how-to/mprac.md#matlab-processing), [corrections and evidence](history/changes/2026-09-27-mprac-matlab-pipeline.md).

2026-09-27 MPRAC P300 is updated and selectively deployed: native 12-channel training/save/use/typing, selected-model retention and an optional two-letter group Pretraining + Typing launcher. Automatic display placement and the original top-left patch remain explicit; 6/3-frame flashes/gaps give 100/50 ms at the on-site 60 Hz display, without local-PC monitor settings. Deployed acceptance passed 21 UI checks and four synthetic recordings; physical on-site optical alignment and participant performance remain unmeasured. [Venue](how-to/mprac.md), [changes and exact verification scope](history/changes/2026-09-27-mprac-native-p300.md).

2026-09-27 P300 standard matrix now has space, comma and functional backspace, with recorded text edits. Updated defaults and P300TEST/MPRAC presets are deployed; 21 UI/workflow and nine planner tests passed. Latest four-letter pretraining sessions both scored 9/10 on ОПУС_ПЯТЬ!: Movicom ГПУС_ПЯТЬ!, NVX ОПУС_ПЯТЫ!. All 1,200 typing scores replay exactly. NVX message-timed calibration plus typing also gives 9/10; switching only typing on the optical model gives 4/10. [Change](history/changes/2026-09-27-p300-text-editing.md), [recording analysis and timing simulation](history/investigations/p300-opus-movicom-nvx-20260927.md).

2026-09-27 Movicom now embeds the confirmed eight-electrode montage (Cz/Pz/C3/C4/PO7/PO8/O1/O2), with firmware sync on by default. Fresh P300 defaults match P300TEST, including startup refresh-scaled timings and a fully initialized amplifier profile. Calibration checks live channels before flashes. The failed four-letter recording was intact; its 240 epochs produced a recovered classifier with independent numerical parity. [Contract](components/p300.md), [evidence](history/changes/2026-09-27-p300-four-letter-defaults.md).

2026-09-27 P300 fullscreen correction is deployed: the single Full screen checkbox immediately fills the selected monitor; obsolete primary/run-only gates are hidden and ignored. The user's 144 Hz setup now has the requested 14/7-frame flash/gap timing (97.2/48.6 ms), also saved in the troubleshooting JSON. Twenty UI/workflow checks passed; the actual fullscreen primary window was verified at 3840×1600. Acquisition and raw data were unchanged. [Evidence](history/changes/2026-09-27-p300-fullscreen-timing.md).

2026-09-27 P300: grey right-anchored in-field units, Same-element gap (default 1 intervening flash), and one editable Recording / Filename template are deployed. Actual Recorder paths remain in status after saving. Planner, numeric editing, 20 UI/workflow checks and shared panel tests passed. Operator values and raw recordings were preserved. The newest confirmed ИИ run used two calibration letters and scored 0/2; models/features/scores reproduce correctly, but group transfer is poor. [Change](history/changes/2026-09-27-p300-units-repeat-gap.md), [recording analysis](history/investigations/p300-short-calibration-20260927.md).

2026-09-27 P300 startup simplification is deployed: an Amplifier selector and explicit startup policy replace P300's hidden acquisition Stop/configure/Start behavior. Recording and P300 share their verified EEG subscription; the firmware clock joins after readiness. Positive pretraining counts are accepted, default two; exact existing blend anchors are preserved. Nineteen recorded UI checks passed, plus two combined runs on continuously running Movicom and exact replay parity for 48 epochs. P300 has its own icon and global Movicom follows NVX136. Fresh Movicom and shipped presets are verified at 25 samples (20 blocks/s); the existing 100-sample acquisition was not interrupted. [Contract](components/p300.md), [evidence](history/changes/2026-09-27-p300-startup-simplification.md).

2026-09-27 P300 paired timing/adaptation update is deployed: editable frames/ms columns, ordered Training / Typing / Pretraining + Typing, capitalized Recording, and Legacy SPEED options in Classifier. Combined mode now always adapts a group prior with two or three letters and automatically saves/uses it. Simulated transitions took 1.9–2.0 seconds without the configured extra three-second padding or acquisition restart. Eighteen recorded UI checks and the shared regressions passed; no new hardware test. [Contract](components/p300.md), [evidence](history/changes/2026-09-27-p300-dual-timing-adaptation.md).

2026-09-27 P300 display/timing update is deployed: Subject monitor is at the top of Visual with resolution/Hz/scaling choices; indicator position sits beside its size controls; frame durations show live approximate milliseconds using the selected display. The Movicom training-clock checkbox now explains that typing uses saved model timing. Operator settings were preserved; 16 UI checks passed. [Contract](components/p300.md), [evidence](history/changes/2026-09-27-p300-display-timing.md).

2026-09-27 P300 follow-up is deployed: errors remain visible with backup controls hidden; empty subject defaults automatically; recording filenames include stimulation mode and combined-session phase. Classifier settings no longer duplicate session controls; wrapped tooltips and click-to-copy channel names are verified. The unnamed-subject combined workflow passed. Movicom AVtest2 typed ПРИВЕТ 6/6, with exact live/recorded score parity and valid firmware clocks. [UI change](history/changes/2026-09-27-p300-errors-filenames-tooltips.md), [recording comparison](history/investigations/p300-movicom-avtest2-20260927.md).

2026-09-27 P300 operator/session update is deployed: separate Classifier window follows Configurator's monitor; presentation backup controls default hidden (F10 toggles); feature plots show time/amplitude axes; Pretraining + Typing automatically calculates/saves a classifier then opens typing; key pacing is on by default. Full/one-/two-letter paths, cancellation and failure passed recorded synthetic integration. AVtest settings/model were preserved; the prior origin-import correction is now deployed. [Contract](components/p300.md), [tests and deployment](history/changes/2026-09-27-p300-operator-pretraining.md).

2026-09-27 NVX cap check: AVtest full calibration gives 11/11 leave-one-letter-out from cycle 2; the separate ФОЖЕГОД recording gives 7/7 online, reached by cycle 3. Retrospective Q group / +1 / +2 final results are 4/7 / 7/7 / 7/7 on this one test. All required photodiode crossings were found. The overlapping-reception-block import correction reproduces all 420 live scores exactly and is included in the operator/session deployment above. [Evidence and exact scope](history/investigations/p300-nvx-avtest-20260927.md).

2026-09-27 P300: explicit group typing and 1/2-letter supervised adaptation (optional 3/4/6) are built and deployed in P300TEST. Frozen separate-play tests give group +2 accuracy 575/701 Movicom and 389/418 Q. Native 705-fit parity, 13 UI checks and six connected-device typing runs passed; NVX used physical AUX1 with synthetic EEG. One initial Movicom missing-sample refusal cleared on a fresh acquisition. Human cap accuracy remains prospective. [Contract](components/p300.md#group-typing-and-short-calibration), [results](history/investigations/p300-group-transfer-20260927.md), [change and exact test scope](history/changes/2026-09-27-p300-group-classifiers.md).

2026-09-26 P300TEST: [eight-channel venue](how-to/p300test.md) now sits beside MPRAC, with primary P300 presentation and secondary Configurator. Hub-connected NVX acquisition, physical AUX1 onset matching, native optical live/offline parity and the Movicom firmware-synchronized calibration→typing workflow passed. Synthetic EEG was used only for the disconnected NVX classifier-path test; human EEG/typing performance remains to be checked with the cap. [Changes and evidence](history/changes/2026-09-26-p300test.md).

2026-09-26 P300: native classifier calculation, whole-letter/recording validation, portable JSON models and native typing are integrated. Separate HP/LP IIR is the default training preset; selected FIR and direct-bandpass comparisons are available for 3×3 and 6×6. MATLAB/SPEED model use remains supported. Across 423 retained-corpus configurations, all 26,010 cycle decisions agree with the reference; native filter, recording, asynchronous replay and UI checks passed. Physical participant/photodiode acceptance remains outstanding. Optional Movicom firmware-echo synchronization is implemented and physically verified; see the entry below. [Current contract](components/p300.md), [implementation and acceptance](history/changes/2026-09-26-p300-native-classifier.md).

2026-09-26 Movicom synchronization: optional native D7 firmware exchanges now publish reproducible per-block clock mappings. Native P300 calibration/training/typing uses them with explicit invalid-clock refusal. Physical clock soak, restart/block-size tests and live/recorded sample-index and score parity passed. This establishes sample/host-clock behavior, not optical onset accuracy. [Current Movicom contract](components/movicom.md#p300-firmware-synchronization), [P300 usage](components/p300.md#optional-movicom-synchronization), [evidence](history/changes/2026-09-26-movicom-firmware-sync.md).

2026-09-25 driver packaging: [device packages](../src/runtime-content/driver/README.md) use flat per-package folders, one common `Install.bat`, and concise dated references. Shared MCS and Neurosoft drivers are included once; NI-DAQmx uses its vendor online installer. [Deployment ownership](how-to/deploy.md#device-driver-packages), [coverage and verification](history/changes/2026-09-25-driver-packages.md).

2026-09-25 Movicom implementation: [native x64 service](components/movicom.md) is built and deployed with the standard amplifier panel, eight REF inputs at nominal 500 Hz, CED/channel selection, diagnostics and offline FTDI driver files. Software regressions, 100 physical Start/Stop cycles, ten-minute Recorder/TCP equality and physical unplug/replug recovery passed. Startup retries allow up to twenty seconds for valid frames after USB returns; Stop remains available during that wait. Verified Stop/draining addresses observed firmware command misses; shared discovery and final-block closure defects have regression fixes. Known-input calibration and clean second-PC driver installation remain unverified. [Implementation evidence and exact revision scopes](history/changes/2026-09-25-movicom.md), [original reference investigation](history/investigations/movicom-20260925.md).

2026-09-24 lab fixes r2: Discs and Field share the head contour; the second viewer starts collapsed and restores its expanded size. MPRAC NVX epoch cutting uses sample order with explicit missing-row rejection, avoiding false refusals from PC timestamp jitter. Original-timestamp playback accepted 60 checker epochs and nine button events without gaps. Venue PNG icons now show 12/Ω and the requested P300 matrix symbols. Stimulus/P300 automatically prefer secondary monitors and keep primary windowed; P300 fullscreen hides its lower controls. [Evidence and patch scope](history/changes/2026-09-24-mprac-labfixes-r2.md).

2026-09-24 MPRAC follow-up: the [venue](how-to/mprac.md) supplies six static-image tasks plus native [P300](components/p300.md) calibration/feedback presets in the **standard Configurator**, with ordinary service names and views. Stimulus sequence edits are immediate, realised cues are coloured, display placement follows QScreen geometry/scaling, and task switching also updates Recorder. Supplied 1080p images are default with two replacement ZIP sets. Completion/Stop now retain EEG mode. All 14 raw channels remain above, with photodiode Cut epochs below for checker/button tasks. P300 retains 53 legacy parameters and SPEED/MATLAB inference; feedback requires an as-yet-unsupplied trained 12-channel model. Software tests use synthetic acquisition; usable EEG, optical/button timing, mixed-adapter lab display placement and P300 accuracy still require rig verification. Earlier physical NVX-52 serial 1219 tests had disconnected EEG and no diode, and used the superseded impedance cleanup. [Follow-up evidence](history/changes/2026-09-24-mprac-followup-p300.md), [earlier hardware evidence](history/changes/2026-09-24-mprac.md).

Status: current orientation. Source and documentation reconciled 2026-09-15; this review did
not rebuild, deploy, run tests or operate hardware. Follow component evidence for validation dates.

## Active implementation

- Default: `R:\src` and `R:\dist`, Qt 6.11.2, MSVC v143 14.44, C++20. The distribution has
  `bin\` at its root. [Setup](how-to/setup.md) and [build](how-to/build.md) own the commands.
- All active services in the reviewed module inventory have Qt 6 implementations. The remaining
  Qt 5 dependency is legacy Controls 1 paradigms and comparator/oracle use, not a blanket list
  of unported services. See [legacy scope](architecture/legacy.md).
- KARDi2 uses a Qt 6 x64 service plus a Qt-free x86 vendor broker. The earlier Qt 5/MinGW
  service-island scripts were removed. [Component](components/kardi2.md).
- `nvx136_2021` is retired from the default build. Its source/older SDK remains relevant to
  comparison tests. NVX136 startup requires the voltage read after open; the dated September 4
  report supports this on the observed hardware. [Component](components/nvx136.md).
- Shared presentation code serves Stimulus and TepSound. Retired `tepService` is a historical
  implementation; active analysis is in TepSound and shared source named by its CMake.
  [Stimulus](components/stimulus-presentation.md), [TepSound](components/tepsound.md).
- Dynamic parameter lookup/retry is implemented. Old claims that multi-stream configuration
  cannot be applied describe a repaired defect. [Framework](architecture/framework.md).
- Default networking is loopback. LAN participation is explicit; external device/FieldTrip
  connections have separate boundaries. [Network](architecture/network.md).

2026-09-18 UI update: mStim/eStim/feetStim window X now exits the service through normal cleanup; `showUi=false` remains hide-only. The Configurator's stock Recorder icon launches standalone `recorderService`. Built and deployed to `R:\dist`; see the [change and verification record](history/changes/2026-09-18-stim-window-close-recorder-launch.md) for the software checks and their scope.

2026-09-18 Configurator fixes: service cells retain their correct identity when an upstream stream returns, and new trigger-bit lanes appear immediately rather than on the next one-second tick. Built, regression-tested and deployed; [diagnosis and evidence](history/changes/2026-09-18-configurator-tree-trigger.md).

## Limits that affect coding work

- No usable Git repository is present in the active source root. Preserve existing work and
  record exact evidence where necessary.
- Test targets, CTest registrations and executed tests are different sets. Core has registration
  gaps; current counts should be derived from the build, not copied from old session totals.
- Software acceptance is not blanket hardware acceptance. In particular DAQmx's documented
  physical acceptance remains outstanding; device-specific measurements must retain their scope.
- Operator-edited configuration can differ from source. Rebuilding does not prove that the live
  distribution contains a change, and redeployment can overwrite operator assets.

The [issue registry](issues/README.md) owns unresolved work and historical reports that still
need rechecking. The [history index](history/README.md) preserves completed work, experiments,
previous states and corrections; it is not mandatory startup context.
