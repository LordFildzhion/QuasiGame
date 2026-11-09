# Where Qt 5 is still necessary — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../architecture/legacy.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-where-qt-5-is-still-necessary"></a>


**Written 2026-09-02**, from a full read of both trees, both distributions and the lab session
evidence. This is the answer to *"can we delete `R:\src_Qt5` and `R:\dist_Qt5`?"* — **no**, and this
file says exactly why, item by item, with what each would cost to close.

Companion documents: [`build_qt5-to-qt6-transition.md`](qt5-to-qt6-transition.md) for the
layout and the migration rules, [`arch_qt6-work-list.md`](qt6-work-list.md) for defects in the
Qt 6 tree itself.

---


<a id="history-0-summary"></a>

## 0. Summary

Reasons Qt 5 must stay runnable. They are very different in weight. The permanent architecture
blocker and four former service gaps are now closed; the legacy paradigms and comparator/oracle
dependencies remain.

| # | what | can Qt 6 ever close it? | cost |
|---|---|---|---|
| 1 | ~~**KARDi2's PE32 vendor DLL**~~ | **Closed 2026-09-02** — the DLL is still PE32, but an x86 *broker* reaches it from an x64 Qt 6 service | done |
| 2 | **The 18 legacy `sp_*.qml` programs** | Only by retiring or rewriting them | weeks, or a decision |
| 3 | **Active service ports** | **Closed 2026-09-06** | Stimulus completes the native Qt 6 service list; legacy rig orchestration/paradigms remain a separate scope |
| 4 | **Comparator and oracle dependencies** | Partly | small, but nothing has been done |
| 5 | **`emulator.exe`** — a source-less binary | Only by re-vendoring or rewriting it | unknown |

Active C++ service ports are complete. Physical acceptance measurements remain necessary on each
Qt 6 laboratory rig; software acceptance does not replace them.

---


<a id="history-1-kardi2--the-permanent-one--closed-2026-09-02"></a>

## 1. ~~KARDi2 — the permanent one~~ — CLOSED 2026-09-02

**This entry was wrong about the conclusion, not about the constraint.**

The constraint is real and unchanged: `KARDi2.dll` and its import library are **PE32/i386 only**,
MCS ships no x64 build, and no x64 process can load it. What was wrong was the inference — that the
*service* therefore had to be x86, and therefore had to be Qt 5, because the Qt 6 kit here is x64.

It does not. A process boundary is enough. Since 2026-09-02 KARDi2 is an ordinary **x64 Qt 6
service** in `R:\dist\bin`, linked against the one shared `Resonance.dll`, and it reaches the vendor
DLL through **`kardi2-broker-x86.exe`** — a 164 KiB x86 helper, `/MT`, importing only
`KERNEL32.dll` — over framed anonymous pipes. `R:\dist\kardi2_x32\` no longer exists; neither does
any Qt 5 DLL anywhere in the Qt 6 distribution, nor the second Resonance core that island required.

Verified on the physical device (KARDi2-NP, serial 5321) the same day: enumeration through the
broker, 59 blocks / 1888 samples at 1000 Hz, live analog data on A1–A6, Sync Out commanded and read
back, clean return to `init`. Details in [`service_kardi2.md` §10](../components/kardi2.md).

⚠ **The same reasoning changes what "impossible" means here.** A PE32-only vendor DLL is no longer
a reason to keep a Qt 5 tree runnable; it is a reason to write a broker.

⚠ One thing the changeover cost, now restored: the vendor **USB kernel driver** reached the
distribution as a passenger inside the island and briefly vanished with it. `deploy-qt6.ps1` now
stages it explicitly into `R:\dist\driver\kardi2\` from `KARDi2\_legacy\3dparty\Driver`, which is
the only copy in the repository.

---


<a id="history-2-the-18-legacy-sp_qml-programs--the-hard-blocker"></a>

## 2. The 18 legacy `sp_*.qml` programs — the hard blocker

**This is the single reason the Qt 5 distribution cannot be demoted to reference-only.**

`R:\src_Qt5\stimulusService\legacy\` holds 44 files, **28 899 lines**: 18 `sp_*.qml` experiment
programs (the motor-imagery puzzle series, P300 for maglev control, music imagery, MEG-room and OPM
variants, two EyeLink variants, the Flappy-Bird classifier-feedback rig), 14 `StimulusList_*.js`
catalogues, and the `RecordEegImpedance*` / `StartNVX*` orchestration files.

They are **not services**. They are QML loaded *into* `quickStimulus` by `--load`. That is why a
mixed Qt 5 + Qt 6 rig does not help here: running one needs a live, launchable Qt 5
`quickStimulus.exe`, not a comparator sitting on disk.

**What blocks Qt 6 is a module-level absence, not an API rename.** Every one of the 18 opens with
`import QtQuick.Controls 1.2` and `import QtQuick.Controls.Styles 1.2`. Qt 6.11 ships
`QtQuick/Controls/{Basic,FluentWinUI3,Fusion,Imagine,Material,Universal,Windows}` — no Controls 1,
no Controls.Styles, in any form. Across the 18 files there are roughly 830 Controls-1 control
instantiations (Label 259, SpinBox 154, Button 126, CheckBox 82, TextField 69, GroupBox 53,
TextArea 51, ComboBox 18, ApplicationWindow 17). Controls 1 → Controls 2 is not a rename:
`SpinBox`, `ComboBox`, `GroupBox`, `TableView` and `ApplicationWindow` all changed API *and* the
whole styling model. Two secondary breaks in the same files: `import QtMultimedia 5.15` (Qt 6's QML
multimedia API is versionless and reshaped — `Audio` is gone, `VideoOutput.source` became
`videoSink`) and `import Qt.labs.settings 1.0`.

Everything else they use **is** available under Qt 6: `QtQml.StateMachine`, and every
`Resonance 3.0` / `Resonance.Plot 3.0` / `Resonance.Bricks 1.0` type — the Qt 6 `quickStimulus`
plugin registers a strict superset of the Qt 5 registrations (one added type,
`StreamDisplayFormatter`), and `--load` itself survives. Controls 1 is the whole of the blockage.

**Is the lab still using them?** This is the decision that was never taken.
`R:\dist_legacy\dist2025\stimulusPresentation.bat` and `stimulusPresentation52.bat` both
`quickStimulus.bat --load` an `sp_*.qml`; `impedanceChecker_128.bat`, `control.bat`,
`control_econoMI.bat` and `control_ponk.bat` load four more external QML files. No lab session in
`R:\tests\` since 2026-08-22 has run one — those were pure TMS — so the paradigms may be dormant.
But nothing in the tree retires them, and
[`service_stimulus-presentation.md`](../components/stimulus-presentation.md) still carries as its open
decision 3: *"Which rigs must keep working unchanged, and for how long"*.

**Two mutually exclusive routes, neither of them a day's work:**

* **Port the QML.** 18 files, ~830 controls, ~29 k lines with the styling rewritten — larger than
  tepSoundService's entire 9 695-line QML surface, with no unit tests, no protocol and no acceptance
  criterion. **Weeks**, and it buys forward a design
  [`service_stimulus-presentation.md`](../components/stimulus-presentation.md) §F1–F20 already condemns.
* **Extend the Qt 6 `stimulusService` instead.** The service port is now complete (§3.1); the
  legacy-specific Phases 3–5 remain separate work: the
  device plan / recorder / trigger path exercised on hardware, the `tools/sp2protocol.py` converter
  — which **does not exist**; Phase 5 is "not started" — and the 14 catalogues migrated.
  **One to two weeks of module work plus one lab session per paradigm family**, and it is the route
  the project already chose.

**Until one of those happens, or the paradigms are retired by decision, `R:\dist_Qt5\msvc64`
(or `dist2025`) must stay launchable.**

---


<a id="history-3-service-dispositions"></a>

## 3. Service dispositions

No active service target remains absent from `R:\dist`. Stimulus was completed on 2026-09-06;
DAQmx and FieldTrip on 2026-09-05; COMport and latencyProbe on 2026-09-04. tepService is retired
in favour of TepSound; MioStim was removed/replaced by eStim.

<a id="history-31-stimulusservice--ported-2026-09-06"></a>

### 3.1 `stimulusService` — ported 2026-09-06

Native x64 Qt 6, with the requested TepSound presentation feature set and a new ergonomic console.
Shares the corrected authoring, stage, response, media and trigger implementation with TepSound.
The new service intentionally omits epoching/visualization and the old Stimulus rig manager's
device/recorder orchestration. It imports old protocol content; configure acquisition/recording
in their own services. Complete software presentation/recording and Qt 5 contract readbacks passed;
physical timing acceptance remains. See [Stimulus](../components/stimulus-presentation.md).

This closes the service port, not the 18 Controls 1 applications discussed in §2. Those still need
their own rewrites or retirement decisions. The earlier 0.05 ms Qt 5 measurement is historical and
is not a measurement of this new media-capable Qt 6 implementation.

<a id="history-32-tepservice--retired"></a>

### 3.2 `tepService` — retired

`tepSoundService` is the active replacement. Its Processing tab now makes the replacement modes
explicit: **No processing** runs cue/trigger presentation only; **SOUND off** still performs
epoching, preprocessing and MEP measurement; **SOUND on** enables calibration, repair, cleaning,
averaging and classification. The old Qt 5 executable remains only for historical comparisons.

<a id="history-33-comport---ported-2026-09-04"></a>

### 3.3 `COMport` — ✅ ported 2026-09-04

A bidirectional serial ↔ Resonance bridge: incoming bytes become an output stream, blocks arriving
on an input `Parameters::Stream` are written to the port. Headless, 358 lines.

*Deployed:* the longest-lived of the eight — in `dist_Qt5\msvc64`, in `dist2025`, and in both arms of
the 2024 shipped dual-arch distribution at identical size.
*Lab dependence:* unproven but plausible — the lab's own inventory script carries it with a hardware
warning, *"generic COM stimulator !! holds a COM port exclusively"*. The four serial devices in
current use each own their port directly instead.
The Qt 6 port preserves all seven parameter keys/defaults and the `dataFromPort` Message stream,
adds descriptions/tooltips to every parameter, and repairs the old sender's dropped-final-byte /
reversed-loop defect. See [service_comport.md](../components/comport.md).

<a id="history-34-latencyprobe---ported-2026-09-04"></a>

### 3.4 `latencyProbe` — ✅ ported 2026-09-04

Measures how soon software can *act* on a sample — the number that bounds any closed-loop
experiment. Watches one bit of an amplifier's trigger word and, on a change, immediately commands
that same amplifier's trigger output, so an external board timestamping both edges on one clock
measures the whole loop with no cross-clock comparison. Deliberately amplifier-agnostic.

*Deployed:* current tree only — `latencyProbe.exe` (61 440 B) + `latencyProbe.bat`, dated
2026-08-19, the newest of the eight.
*Lab dependence:* it appears in **no** document under `R:\docs`, which is itself a finding — but
`R:\config` carries a complete toolkit: `latency_probe_harness.qml`, `analyze_latency_loop.py`,
`summarize_latency_sweep.py`, and it is in the rig inventory. ⚠ **Every latency figure in this
project was measured on Qt 5 binaries, and this is the only instrument that can re-measure them
under Qt 6.**
The Qt 6 port preserves the 11 settings plus the service-updated `status` parameter, state
transitions and `events` stream; every parameter now has a description/tool tip. Its existing external-loop
harness needs no porting. See [service_latency-probe.md](../components/latency-probe.md).

<a id="history-35-eyelink---ported-2026-09-04-physical-tracker-acceptance-remains"></a>

### 3.5 `eyeLink` — ✅ ported 2026-09-04; physical tracker acceptance remains

Publishes gaze from an SR Research EyeLink 1000/1000+ as a Resonance stream, runs the tracker's own
calibration, detects fixations and emits them as messages, writes an EDF on the host. Headless,
1 036 lines.

*Deployed:* now in `R:\dist` as well as `dist_Qt5\msvc64` and `dist2025`, with three vendor DLLs,
`FreeImage.dll`, and app-local `MSVCR90.dll`.
*Lab dependence:* low but not zero. The hardware has never been attached to either machine and the
module has never been exercised — but two production paradigms are written against it
(`sp_mipuzzleEYELINK_A.qml`, `_B.qml`, 2022), and it is the only eye tracker in the tree that builds.
*Qt 6 result:* QtWinExtras was removed, Win32 calls are explicitly Unicode, lifecycle/shutdown and
fixation filtering were repaired, and all 14 parameters plus the initial state and writable
fixation-time behaviour match the Qt 5 executable in hardware-free live testing. The three vendor
DLLs still import the VC++ 2008 runtime, but `MSVCR90.dll` now ships app-locally, so no global
redistributable is required. Full record: `R:\src\eyelink\README.md`.
⚠ *Still untested:* physical tracker discovery, calibration, live gaze/events, synchronization,
EDF recording/transfer, stop/start and reconnect. These are lab acceptance items, not port blockers.

<a id="history-36-daqmx--ported-2026-09-05-physical-acceptance-remains"></a>

### 3.6 `DAQmx` — ported 2026-09-05; physical acceptance remains

Native x64 Qt 6 service in `R:\src\DAQmx` and `R:\dist`. The six-parameter contract and Float64
data stream are preserved; setup/read/Done checks, unwind and deterministic shutdown are repaired.

NI-DAQmx 26.5.0 and ANSI C development support are installed. The build uses the current installed
header and AMD64 import library; System32/nicaiu.dll is an external dependency, never bundled.
No real/simulated devices were enumerated. Software parity/error recovery passed; acquisition
remains a known-device bench test. See [service_daqmx.md](../components/daqmx.md).

<a id="history-37-fieldtrip--ported-2026-09-05"></a>

### 3.7 `fieldtrip` — ported 2026-09-05

Native x64 Qt 6 service in `R:\src\fieldtrip` and `R:\dist`, with the current upstream client
definitions, asynchronous worker transport, reset/header replacement and deterministic shutdown.
The official x64 buffer/sine/demo tools provide hardware-free acceptance through recorderService.
The two-parameter/data-only contract remains compatible. See [service_fieldtrip.md](../components/fieldtrip.md).

<a id="history-below-the-line"></a>

### Below the line

`eyeTribe` (commented out of the Qt 5 root CMake because it was never brought to the current
Resonance API), `openBCI` (Qbs only, never in the CMake build), `DemoApp`, `fileConverter`,
`SaveLib`, `Tests`, `Documentation` and the whole `*.qbs` era. Dead or pre-3.0. **Port none of them.**

---


<a id="history-5-emulatorexe--a-binary-with-no-source"></a>

## 5. `emulator.exe` — a binary with no source

`R:\dist_Qt5\msvc64\bin\emulator.exe`, 2 127 872 bytes, dated 2025-07-24. It matches **no file and
no `add_executable` in either source tree**, and `test-device-service-parity.py` hard-requires it as
its default `--emulator`. It cannot be rebuilt, only copied. Until someone identifies what produced
it, `R:\dist_Qt5\msvc64\bin` is the only copy in existence and deleting that directory destroys it.

The same shape, less severely: `R:\dist_Qt5\msvc64\bin\FrameLib\Frame1` — feetStim's stimulation
pattern, 384 bytes, no source, no install rule. *(Now also copied into `R:\dist\bin\FrameLib\`.)*

---


<a id="history-6-what-is-not-a-reason-to-keep-qt-5"></a>

## 6. What is *not* a reason to keep Qt 5

Stated so the list above is not padded:

* **The wire protocol.** Unchanged, and verified interoperating in both directions. A Qt 5 service
  and a Qt 6 Configurator work together, and vice versa.
* **HDF5 recordings.** Readable by both — but see the trailing-zero-row change in
  [`build_qt5-to-qt6-transition.md`](qt5-to-qt6-transition.md) §7, which makes the two
  generations write files of different length for the same input.
* **Parameter JSON files.** Interchangeable; an unknown key is reported and every other entry
  applies. (The one real loss is `cold_start_pause_ms`, which the Qt 6 NVX-136 does not define —
  see [`arch_qt6-work-list.md`](qt6-work-list.md) §1.)
* **The MinGW distributions.** `R:\dist_2026aug\mingw32` and `mingw64` are archive-only and were
  already superseded before the Qt 6 work started. Their loss is not a Qt 6 regression.
* **Vendor SDKs.** Every one of them is a C or .NET boundary that crosses no Qt ABI. NVX, NVX136,
  actiChamp, Neuron-Spectrum, Neuro-MS, NI-DAQmx and EyeLink all cross the version boundary
  unchanged. KARDi2 is the sole exception, and it is an *architecture* exception.
