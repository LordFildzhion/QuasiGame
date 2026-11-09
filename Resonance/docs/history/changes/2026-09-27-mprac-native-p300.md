# MPRAC P300 native workflow and portable 60 Hz presets — 2026-09-27

The request named SPRAC; inspection found only MPRAC/P300TEST. MPRAC was treated as the practicum venue and that assumption was stated. Changes are in `src/venues/MPRAC`, selectively deployed to `dist/venues/MPRAC`.

## Changes

- Training now calculates a native centered Fisher classifier on all 12 cap EEG channels, with continuous HP/LP 0.3–12 Hz, 100–600 ms averaged features and ridge 0.003. The Classifier window provides validation, Save and Use for typing. The feedback launcher retains the selected model instead of overwriting it with the absent `classifier/mprac12.mat`. It opens SPEED only for an explicitly selected legacy `.mat`.
- Added `08a_P300_pretraining_typing.bat` and its launch-strip entry. It adapts the installed Q eight-channel group model by name within the 12-channel montage, defaults to two calibration letters, saves/uses the result and continues to typing. Every raw EEG/AUX/Trigger column remains recorded. No synthetic or personal classifier is deployed.
- Explicit venue defaults include hidden presentation controls, Space pacing, same-element gap 1, REF, automatic training calculation, the new space/comma/backspace alphabet, and Use running amplifier. Removed obsolete acquisition JSON and the duplicate filename alias from these P300 presets.
- The legacy venue's Automatic subject-monitor policy is now explicit, preventing inheritance of P300TEST's primary-display default. Fullscreen, the top-left 10×13 patch, all Configurator settings, 10 selections and 10 cycles are retained. No monitor identities, geometry, current-PC refresh or Configurator placement code is copied.
- Explicit **60 Hz** timing: flash 6 frames/100 ms; gap 3/50 ms; pre/post 30/500 ms; attention pause 5/83.3 ms; attention half-cycle 8/133.3 ms. These original frame values already matched the requested 60 Hz durations; they override the service's startup refresh scaling. No frame rescaling occurs in the MPRAC launcher.
- Native optical defaults use Photodiode rising at −1.85 V within 0–100 ms, matching the Q group recipe. The independent lower viewer retains its older falling −1.95 V optical monitor. Patch-on polarity/threshold must be checked on the actual rig before calibration; this test does not establish optical suitability or group accuracy on the MPRAC cap.

## Evidence

`src/_test-output/mprac-p300-update-20260927` contains original affected source/deployed files, deployment hashes and isolated synthetic recordings. No running operator service was restarted or changed, no hardware was opened, and no raw subject recording was edited.

`scripts/test-mprac-p300.py` runs private 14-column EEG (12 named cap EEG + Photodiode + Trigger), Recorder and the real P300 UI/service implementation. Artificial rising optical crossings every 40 ms exercise extraction without claiming a real display response. Test-only overrides shorten letter/cycle and hint counts, disable fullscreen/key pacing and use isolated files; the venue's monitor and frame defaults are asserted before overrides. The existing UI tests cover key pacing and the other shared controls.

Source and deployed preset runs each passed **21 UI checks, zero failures**. The separate generic session-fixture test was skipped in this harness; the new MPRAC workflow ran instead. Deployed acceptance audited four recordings:

| Phase | Flashes | Decisions |
|---|---:|---:|
| Full personal training, four letters | 48 | 0 |
| Native 12-channel typing | 24 | 2 |
| Q-group pretraining, two letters | 24 | 0 |
| Automatically continued typing | 24 | 2 |

The source run's post-test audit initially expected the group name `eeg`; direct TCP requests name that Recorder slot `stream1`. The UI/recordings were successful. The audit was corrected for this explicit test transport and the entire deployed acceptance rerun passed (`deployed-acceptance/report.json`). All four files retain 14 raw columns. Personal training accepted four letters and saved a 12-channel optical model; combined training accepted two and saved an eight-channel optical adapted model. Four recorded typing results have matching text-edit events and no classifier errors. Synthetic predictions are unscored.

Launcher logic checks cover retained personal/native selection, no SPEED for native, SPEED for explicit MATLAB, stopped-amplifier configuration/start and no calls to a running amplifier. They use fake peers; standard-named batch launchers were not run against the operator's occupied services. The separate launcher harness was updated to the native expectations. The installed P300 executable matches the existing current build; this task changes venue content and test code, not production C++.

Owning references: [MPRAC setup](../../how-to/mprac.md), [venue README](../../../src/venues/MPRAC/README.md), [P300](../../components/p300.md).
