# BPRAC EEG practicum

The [BPRAC venue](../../dist/venues/BPRAC/README.md) provides the rhythms/movement and P300 tasks from *ЭЭГ методичка (БП)* pp. 26–30, with the user's requested SPRAC-style twelve-channel NVX and established eight-channel Movicom setups. [Source](../../src/venues/BPRAC), [launcher](../../src/venues/BPRAC/tools/launch.py), [acceptance runner](../../src/scripts/test-bprac.py).

## Acquisition and displays

`02_NVX_12ch.bat` selects inputs 1–12 **Fz C3 Cz C4 P3 Pz P4 PO7 PO8 O1 Oz O2**, input 49 Photodiode and Trigger at 1000 Hz, unipolar REF. `02_Movicom_8ch.bat` selects **Cz Pz C3 C4 PO7 PO8 O1 O2**, 500 Hz, 25 samples per block and firmware synchronization. REF is the acquisition reference, not a ninth Movicom sample channel. Montages are supplied as CEDs and embedded in presets. NVX impedance is explicit; Movicom has no impedance mode.

Shared task launchers remember the last selected amplifier in `data/BPRAC/setup.json` (fresh default NVX). They open ordinary Configurator, Stimulus/P300, acquisition and Recorder services. Task switches preserve running EEG. Only explicit amplifier setup buttons reconfigure running acquisition; a transition out of NVX impedance selects EEG. Active presentation or recording cannot be repurposed. Completion and presentation Stop leave acquisition running.

Automatic subject-screen selection follows the shared right/left/secondary/primary policy, with no saved PC geometry. Fresh BPRAC Configurator uses its venue launch strip. Close a Configurator belonging to another venue before opening BPRAC if the BPRAC strip is required; an already open Configurator can still apply the presets through the BPRAC launchers. P300's backup controls default hidden, with separate classifier window and key-paced next letters. Classifier plotting, paired frame/ms fields, text editing and current native training are inherited from the shared P300 service.

## Protocols and reference reconciliation

| Task | Active condition / reference | Duration and count |
|---|---|---|
| Eyes | Closed eyes / count figures | 3 × 24 s per condition |
| Fingers | Repeated right-finger movement / count figures | 12 × 6 s per condition |
| Single movement | One right-finger movement then relax / count figures | 12 × 6 s per condition |
| P300 6×6 and 3×3 | Target training, then separate typing | 15 letters/selections × 5 cycles each |

Static tasks use 2 s blank intervals, a 5 s instruction cue and 1 s ending. Their ready-to-run balanced pair order is taken from the supplied `sbj12` event logs. Generate in the stimulus editor draws new balanced pairs; counts remain exact. The experimenter gives the verbal reopen-eyes cue, as in the guide. The single-movement cue is explicit text: the example launchers reuse the repeated-fingers image, while the available `rh1` image depicts the whole arm. Copied PNG assets remain byte-identical to the reference.

The guide's twelve 6-second counting segments and grouped closed-eye segments amount to 72 seconds per condition. `sbj12` and the processing script use three 24-second blocks of each instead; BPRAC follows that actual recording segmentation. Movement tasks exactly match the 24 logged cues. The example 6×6 learns 12 letters and types 16; 3×3 learns 15 and types 16. New defaults use the guide's 15 training letters and at least 15 typing selections.

The PDF's NVX list starts FCz and specifies 500 Hz; the explicit request for the SPRAC setup takes precedence (Fz, 1000 Hz). The PDF's purported eight-channel Movicom list contains nine names. The confirmed hardware montage and supplied processing `ch_names` determine the eight-channel order instead.

P300 6×6 retains the standard current alphabet with space/comma/backspace. 3×3 follows the reference `ОАЕ / ИНТ / РСЛ`. Both use row/column flashes. At 60 Hz, 7 flash frames / 4 gap frames give 116.7/66.7 ms, quantizing the reference 120/60 ms; eight target-hint blinks use 6-frame half-periods (5 Hz). Minimum intervening flash and target distance are both one, feasible in 3×3. Alternate matrix order between participants rather than always following filename order. The two-letter demonstration disables recording and training calculation.

## Classifiers and recording

Full subject training is the method default. NVX uses the twelve-channel .5–12 Hz HP/LP recipe, .003 ridge; Movicom 6×6 .3–12 Hz/.003; Movicom 3×3 .1–18 Hz/.001. All use 100–600 ms epochs, 40 ms means and 20 ms stride. NVX 3×3 uses the same NVX filter as a starting recipe; it does not claim dedicated 3×3 optimization. Compatible existing group models are available in the classifier settings for optional use (NVX 6×6, Movicom 6×6/3×3). There is no shipped twelve-channel NVX 3×3 prior.

NVX P300 uses recorded AUX1 analogue rising crossings, starting threshold −1.85 V and 0–100 ms search, with a top-left 10×13 patch. Check actual polarity, level and patch location on the rig. Movicom uses its D7 firmware-echo clock; that maps EEG samples to host time and does not measure panel light. Static rhythms/movement tasks record software presentation onsets; their top-left optical patch is also captured on NVX AUX1. Generic Stimulus does not enable P300 firmware timing or save a Movicom clock stream for these slow tasks.

Save and Use the trained native classifier before Typing. Switching presets remembers selected files by amplifier, matrix and subject and clears incompatible selections. It does not silently replace a missing subject model with a group model. The service performs final compatibility checks. `setup.json` stores paths only, not classifier contents. Keep the actual `.p300.json` files.

Recorder saves `data/BPRAC`: unfiltered EEG and channel metadata, Stimulus events/status, or P300 events/status/classified/photo_event/selected_letter plus Movicom sync when enabled. Filenames distinguish amplifier/task/matrix; P300 adds subject and stimulation mode. HDF5 events preserve the realized sequence and labels. Static markers: 1 counting, 2 active task, 0 interval, −1 instruction, −2 end. Old `.evt` group 1 maps to marker 1 and group 0 to marker 2; old `istarget` is not a reliable static-condition label. Intended typing text must be retained separately to score free typing.

## MATLAB processing

The venue ships [self-contained 2026 scripts](../../src/venues/BPRAC/MATLAB/README_2026.md), also copied beside the originals in ``W:\MATLAB\`msu_teaching\BPRAC_Processing\Processing``. The original scripts and raw recordings remain unchanged. MATLAB R2023b and Signal Processing Toolbox suffice; the supplied teaching environment uses `W:\MATLAB\startup.m`.

`motorTask_onGrayBox_2026.m` retains the section-based rhythms/movement workflow, with continuous channel-wise filtering and additive superlets, Welch PSD, paired band-power effects and optional regularized CSP. It accepts eight-channel legacy files and both current amplifier montages. Array/channel dimensions, condition labels, baseline units, bounds and peak indices are explicit; plots use actual frequency/time coordinates and correct power/PSD/CSP units. Scalp maps show measured electrode values. Raw p-values are labelled uncorrected.

`p300_pipeline_2026.m` implements fitting in MATLAB, not a Python wrapper. Old files select the exact Mov0 FIR and unregularized centered Fisher equations; new HDF5 selects current BPRAC causal SOS/count-pooled ridge recipes. It replays the recorded processing origin, native channel-major averaged features, optical onset matching or Movicom clock ledger, and can export a subject `.p300.json` for the service. Existing native group/adapted models can be replayed without refitting; group-prior estimation/adaptation is not implemented by this offline fitter. Existing legacy `.ld` weights can also be replayed.

Classifier validation holds out entire letters and rejects incomplete letters as units. This intentionally differs from the old fitter's acceptance of partial final letters and random per-epoch validation. The descriptive ERP branch is separate: continuous zero-phase .5–15 Hz, −200…800 ms, −200…0 ms baseline. Unknown typing targets remain unscored. Recorded or explicitly supplied alphabets determine cell text; repeated/missing/corrupt alphabets produce cell indices, not guessed letters. Space/comma/backspace are preserved.

All outputs remain in memory unless explicit new XLSX/model filenames are set. There are no automatic figure exports. [Corrections and numerical verification](../history/changes/2026-09-27-bprac-matlab.md).

## Verification

See the [change and acceptance record](../history/changes/2026-09-27-bprac.md). Synthetic tests exercise acquisition metadata, real Stimulus/Recorder integration and all four native P300 train/save/use/type combinations. They do not establish human EEG accuracy or physical optical/firmware timing on the eventual rig.
