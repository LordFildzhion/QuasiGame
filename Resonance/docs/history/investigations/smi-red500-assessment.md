# SMI RED500 — can Resonance have a service for it? — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../decisions/proposals/smi-red500.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-smi-red500--can-resonance-have-a-service-for-it"></a>


**Assessed 2026-09-14. Research only:** no code written, no hardware touched, no vendor binary
executed. Inputs: the Resonance docs and tree (`eyelink`, the legacy `eyetribe`, the UDP device
sockets, KARDi2's broker, FieldTrip's worker); SMI's manuals; and — the same day — **the copy of the
kit laptop at `R:\equipment\SMI_RED500\SMI_PC\`**, which settled most of the open questions (§1a).
"System Manual p. N" is a PDF page of the iView X 2.8 manual, byte-identical in
`SMI_PC\Desktop\SMI STUFF\IVewx setup CD\Manual\iViewX.pdf` and
`R:\equipment\SMI_RED500\manuals-public\`; "SDK 4.4 p. N" is
`SMI_PC\Program Files\SMI\iView X SDK\docs\iView X SDK Manual.pdf`.


<a id="history-0-the-answer"></a>

## 0. The answer

**Yes, and without an architectural blocker.** The RED500 is not driven by a DLL on the Resonance
PC at all: the tracker's camera hangs off the kit laptop, the laptop runs SMI's tracking server
**iView X 2.8.43**, and iView X is controlled — and streams gaze — over a **documented plain-text
UDP protocol** (the "remote command language", System Manual §11.3, pp. 497–535). SMI's SDK
reaches iView X over the same UDP link and the same configured ports.

**Recommended route:** a native Qt 6 x64 service on the Resonance PC that speaks that protocol
directly through a `QUdpSocket`. The laptop stays the tracking server. The laptop copy made a
second route real — **iView X SDK 4.4.10 with 64-bit DLLs is installed** — but it also showed what
that route would drag into the Resonance process (§1a.4, a kernel-driver installer among them), so
the SDK's best use is as the **reference to check the protocol implementation against** on the
bench, not as the implementation. The one substantial piece of new UI is a calibration/validation
target window, because in a two-PC setup the subject screen belongs to the Resonance PC.

**Replacing iView X altogether** — a Resonance service driving the RED500's camera itself — is
possible in principle, because that camera is a stock IDS uEye USB device; but it means writing an
eye tracker, on the order of months (§3a). The service contract is the same either way.

Rough size: a day of bench work with the laptop, **3–5 days** for the service with calibration,
one lab day for acceptance with EEG (§9).

⚠ **The highest risks are the laptop itself, not software** (§7.1–7.2): iView X's licence is bound
to that machine, and the RED500's camera driver on the SMI CD is **32-bit only** — the tracker
cannot simply move to a newer PC. Do not reinstall, upgrade or re-image that laptop.

---


<a id="history-1-what-the-system-is"></a>

## 1. What the system is

| | RED500 (System Manual pp. 179–181) |
|---|---|
| Tracking | remote, contact-free, dark pupil + corneal reflex, **binocular** |
| Sampling rate | **500 Hz** (the RED family offers 60/120/250/500 by model; set in iView X *Setup → Hardware → Advanced*) |
| Accuracy / precision | < 0.4° typical / 0.03° RMS |
| Operating distance, head box | 60–80 cm; 40 × 20 cm at 70 cm; head velocity up to 50 cm/s |
| Latency (vendor figures) | **< 4 ms end to end**, < 0.5 ms processing; blink recovery 4 ms, tracking recovery 90 ms |
| Gaze tracking range | 40° horizontal, 60° vertical |
| Hardware link | ET module → **USB to the dedicated, labelled port of the iView X workstation**; 19 V supply |
| Modes | *Monitor Integrated* (bar screwed under the stimulus monitor) or *Stand Alone* (foot, for TV/projection, geometry profile) |

**The intended layout is two PCs** (System Manual pp. 37–38, 183): the iView X workstation, and a
stimulus PC that drives the subject monitor and talks to iView X over Ethernet — *"highly
recommended … directly through a CAT 5 crossover cable"* (p. 74). In our case the stimulus PC is
the Resonance PC. iView X writes its own binary **IDF** on the laptop; the IDF Converter exports it
as tab-separated text, which FieldTrip already reads
(`R:\equipment\Fieldtrip_src\fileio-20260904\private\read_smi_txt.m`).

**The vendor is gone.** Apple bought SMI in June 2017 and support ended that year. Gaze
Intelligence (former SMI staff) lists downloads of **iView X 2.8.43** for the RED500/RED250/HED and
an **iView X SDK** for REDm/REDn/RED250mobile/RED500/RED250, without version numbers — the only
live source found. The laptop copy carries every installer anyway (§1a.1).


<a id="history-1a-what-the-kit-laptop-copy-shows"></a>

## 1a. What the kit-laptop copy shows

`R:\equipment\SMI_RED500\SMI_PC\` — `Desktop\`, `Downloads\` and `Program Files\SMI\` of the
laptop: **33 GB, 41 336 files**.

<a id="history-1a1-software-as-installed"></a>

### 1a.1 Software, as installed

| Component | Version | Where |
|---|---|---|
| **iView X** (tracking server) | **2.8 build 43**, 2014-08-18 — the last release | `Program Files\SMI\iView X\iView.exe` |
| **iView X SDK** | **4.4.10**, 2017-02-03 (release notes). 32- *and* 64-bit: `iViewXAPI(64).dll` + `.lib`, `include\iViewXAPI.h`, manual, examples (C++, C#, Python, MATLAB, E-Prime, Presentation, Unity) | `Program Files\SMI\iView X SDK\` |
| Experiment Suite 360° | Experiment Center 3.5.169, BeGaze 3.5.101 (Sentinel/HASP-licensed) | `Program Files\SMI\Experiment Suite 360\` |
| iTools 2.4.4 | installed: IDF Converter 3.0.16, IDF Event Detector 3.0.18, Remote Console 1.0.10. **WinCAL 1.4.11** and Remote Video are in the CD's iTools installer but not installed | `Program Files\SMI\iTools\`, `IVewx setup CD\Add-On\iTools\setup.exe` |
| Also | iView NG SDK (for REDn/glasses, not needed), File Transfer Server | |
| **Installers** | the **iView X 2.8.43 CD** (`iView X.msi`, RED/HED USB driver, iTools 2.4.4), the Experiment Suite 3.5 CD (+ HASP driver), `Setup_iViewX_SDK.exe` 4.2.63, `iViewNG-SDK.msi` | `Desktop\SMI STUFF\` |
| Manuals | iView X 2.4 and 2.8, SDK 4.2 and 4.4, Experiment Center 3.5, BeGaze 3.5 | `Desktop\SMI STUFF\SMI manuals\`, SDK `docs\` |

<a id="history-1a2-the-laptop"></a>

### 1a.2 The laptop

* **Windows 7** — every IDF header says `Operating System: 6.1`. **32-bit**, by inference: the SDK
  sits in `C:\Program Files\SMI` (SDK 4.4 p. 12 puts it in `Program Files (x86)` on 64-bit
  Windows), Firefox and Chrome shortcuts point into `C:\Program Files`, and the downloaded GPU
  driver, Anaconda, Python(x,y), PsychoPy and VS Code installers are all 32-bit builds.
* Computer name / IDF *System ID* **`IRX1070701-1534`**, user account `iView X`, a second drive
  `D:` labelled *Spare*.
* **The RED500 camera is an IDS uEye USB camera** — iView X's settings file is `ueye1220.set` and
  the CD's RED driver is IDS uEye **3.80.12 (2010), whose kernel drivers are PE32 only**
  (`Driver\HED4RED5\...\ueye_usb.sys`, folders `Win2000` and `XP_Vista_Win7`).

<a id="history-1a3-how-it-was-configured"></a>

### 1a.3 How it was configured

* **Last session (2024-04-18), `settings\network.set`: `127.0.0.1:4444` → `127.0.0.1:5555`** — the
  recent experiments ran on the laptop itself. `trigger.set` is all zero: **no TTL input is set up**.
* **A two-PC configuration already exists as a saved setup:** `bci_setup.ivs` (2016-11-07) and
  `bci_250.ivs` (2018-06-15) listen on **`192.168.0.2:4444`** and send to **`192.168.0.3:5555`**
  (decoded from the binary `.ivs`; `setup_2803_500.ivs` and `red_{60,120,250,500}Hz.ivs` are
  localhost). Loading one of them is the quickest way back to a stimulus-PC link.
* Calibration as used: **9-point, calibration area 1680 × 1050**, RED *Monitor Integrated* on a
  **22″ profile** (`redx\Planes.integrated.22.9p.red5.ini`: 474 × 297 mm, 20° tilt), head distance
  700 mm; a configuration entry in the setups is named `eizo`. The subject screen must stay at
  1680 × 1050 or be re-profiled.
* Where the experiments came from: shortcuts point to `C:\Users\iView X\Documents\SMI_BCI_Experiments`,
  `D:\Practice`, `C:\BCI_DEMO` and the lab's 2011–12 *Mind Controlled Browser* (which had an
  `iViewX_address` option) — **none of those folders was copied**. Calibration files named by a
  Python `time.time()` (`calib1528287107.5.cal`) and messages carrying Unix times point to Python
  scripts on the SDK.

<a id="history-1a4--what-the-64-bit-sdk-would-load-into-our-process"></a>

### 1a.4 ⚠ What the 64-bit SDK would load into our process

For iView X devices SDK 4.4 is a dispatcher over the old code line: *"for all other devices the
functionality of the iView X SDK version 3.6 is retained"* (SDK 4.4 p. 11), and
`iViewXAPIL64.dll`'s version resource is 3.7.10.0. Import tables, read with `pefile` (nothing was
loaded):

| DLL | Imports that matter |
|---|---|
| `iViewXAPI64.dll` | `KERNEL32`, `msvcrt` only — loads the back end with `LoadLibraryW` |
| `iViewXAPIL64.dll` (the iView X back end) | **`MSVCP120` / `MSVCR120`** (VC++ 2013), `JPEGCompression64.dll` → **`MSVCR90`** (VC++ 2008), **`inpoutx64.dll`**, `WS2_32`, `gdiplus` |
| `inpoutx64.dll` | carries a driver image as a `BIN` resource and imports `OpenSCManagerA` / `CreateServiceA` / `StartServiceA`; device `\\.\hwinterfacex64` |

That last row is **InpOut**, the LPT port-I/O library, statically imported for the SDK's
TTL-on-AOI feature. By InpOut's design it **installs its kernel driver when a process with admin
rights loads it**, and InpOut drivers are catalogued as vulnerable (`inpoutx64.sys` is in
LOLDrivers). A Resonance service linking the SDK would carry that. It is avoidable — a no-op
`inpoutx64.dll` beside the executable, or not linking the SDK at all — but it is exactly the kind of
side effect route A never has. (This PC already has the VC++ 2013 x64 runtime in `System32`; a lab
PC may not.)

<a id="history-1a5-what-the-recordings-say--measured-on-this-red500"></a>

### 1a.5 What the recordings say — measured on this RED500

175 IDF files (12 GB, 2019–2024, mostly December 2022 – March 2023) sit in the iView X folder,
~13 GB of IDF Converter exports and another 16 IDF files on the desktop. Seventeen exports were
scanned for timing and encoding:

| Sessions | Rate | Heuristic filter | iView X `Latency` column, median / p99 | Samples missing from the timeline | Gaze = 0 |
|---|---|---|---|---|---|
| 2024-04 practice, 7 files | 500 Hz | **off** | **0.71–0.88 / 1.19–1.82 ms** | 0.24–0.50 %; 2.4 % and 12.1 % in two files | 0.2–5.4 % |
| 2022–23 sessions, 10 files | 250 Hz | **on** | **9.18–9.29 / 9.75–10.8 ms** (one short file: p99 109 ms) | 0–9.2 % (the same short file: 64.6 %) | 0.1–20 % |

* **The heuristic filter costs ~8 ms of latency** (two samples at 250 Hz). Online use wants it
  off — *Setup → Tracking → Input Filter Eye*.
* **Sample period at 500 Hz is 2.000 ms with p1–p99 of 1.86–2.15 ms** of timestamp jitter.
* **The tracker itself leaves gaps** even with no network in the path; **a 136 ms gap is the
  longest in 7 of the 17 files** — a signature to watch for on the bench. The service's gap counter
  will count these too, so "dropped samples" will not read zero on a healthy link.
* **Lost gaze is written as `0.000`** (with raw and diameter zeroed for the lost eye) — the answer
  to §4.4 question 2, at least for the IDF.
* **Pupil diameter is labelled `[mm]` but reads median 11–20, max 36** — about three times a
  physiological pupil. Treat it as uncalibrated until checked against a known target (p. 365).
* **Left and right gaze were identical in 3 of 4 files checked** — consistent with the SDK's
  channel-averaging filter (`iV_ConfigureFilter(Average)`, which also affects IDF files). Binocular
  analysis needs it off.
* Every recording starts with **`# UTC: <unix s> <ms>`** — a wall-clock anchor on the tracker's µs
  timeline. The 2022–23 paradigm sent a message every ~533 ms of the form
  `[code], <unix time>.jgp` (1 092 in one 13-minute file).

⚠ **These are human-subject recordings** — S1–S29 plus files named by participants' first names,
and 1.1 GB of eye-region images from the 2017 calibration-quality recordings (`eyeImages\`). They
make `R:\equipment` hold research data; worth moving to wherever the lab keeps data and handling
read-only, like the raw recordings on `N:`.


<a id="history-2-what-resonance-already-has-that-applies"></a>

## 2. What Resonance already has that applies

* **`eyelink` — the contract to mirror.** Qt 6-ported, headless, `R:\src\eyelink`. Streams
  `eyeData` (Float64: `left.x left.y right.x right.y`), `eyeEvents` (JSON fixation/blink/saccade),
  `events` (gaze "clicks" as `x:y`); states `init → running`, `noDeviceFound`; transitions `start`,
  `stop`, `sync`. Its fixation-click logic is a pure, unit-tested header
  (`eyelinklogic.hpp`, `test_eyeLinkLogic`) that an SMI service can reuse unchanged. Keeping the
  same stream names and the same first four channels means a consumer written against EyeLink —
  a `sp_*EYELINK` paradigm, the Stimulus `devices[]` plan — needs no tracker-specific code.
  ⚠ Its calibration is a native Win32 full-screen window that SR Research's graphics DLL draws
  into (`init_expt_graphics` / `do_tracker_setup`); nothing of it transfers.
* **`eyetribe` — a network-protocol tracker, already tried once.** `R:\src_Qt5\eyetribe`, never
  ported, out of both builds: a TCP/JSON client to the Eye Tribe server on `127.0.0.1:6555` with a
  QML calibration window (`calibrate.qml`) that walks points and reports quality. Pre-3.0 API, so
  reference for the calibration flow only.
* **UDP device sockets** — `arduinoTTL`, `eStim`, `feetStim` each own a `QUdpSocket` command channel
  (`service.cpp` ~1738 / ~1863 / ~1674). [Network isolation §6](../migrations/network-isolation.md)
  records that `NetworkMode` deliberately does not govern a module's own device sockets.
* **FieldTrip** — the worked example of an asynchronous network client on a worker thread with
  connect/request deadlines, reconnect, and hardware-free acceptance against the upstream demo
  tools ([service_fieldtrip.md](../components/fieldtrip.md)).
* **KARDi2's x86 broker** — only relevant if the 32-bit SDK were ever the only option (§3, route C);
  with SDK 4.4.10 on disk it is not.
* **Framework conventions that fit exactly:** an explicit block `created` time (the KARDi2 driver
  passes one), `reportDroppedSamples()` for the status line, `setStateInfo()`, `Action` parameters,
  the description/label/icon/launcher rules of [architecture §6, §11d, §12](../migrations/framework-evolution.md).
* **No SMI code exists anywhere else on `R:\`.** Searched `dist_legacy`, `src_Qt5`, `src_legacy`,
  `src_git_branches`, `config`, `docs`, `tests`, `Testing`, `equipment`, `tmp`, `patches` for
  iView/SMI/RED500/BeGaze/IDF: only false positives (`StimuliView`, `IViewObject`) and the FieldTrip
  reader above. `R:\dist_legacy\Eyelines1` is EyeLink (EDF files, `eyelink_core.dll`), not SMI.
  Resonance has no LSL bridge either.


<a id="history-3-integration-routes"></a>

## 3. Integration routes

| Route | How | For | Against |
|---|---|---|---|
| **A. UDP remote protocol, native** ⭐ | Qt 6 service ⇄ iView X over UDP (`ET_*` text lines) | No vendor binary; any architecture; fully documented; parseable and testable offline; we choose the socket's interface and filter its source; the same shape as the tree's other UDP devices | We draw calibration targets ourselves (§5.3); units to confirm against the SDK (§4.4) |
| B. SDK 4.4.10, 64-bit, in process | Qt 6 service links `iViewXAPI64.lib` | **On disk.** SDK draws calibration/validation on the local primary/secondary display (`CalibrationStruct::visualization = 1`, blocking) or hands us points for our own window (`= 0`, non-blocking); RED tracking-monitor window; pupil documented in mm | ⚠ Pulls VC++ 2013 and 2008 runtimes and **InpOut's driver installer** into the service (§1a.4); for iView X it is the 3.6/3.7 code line; closed DLL, callbacks on SDK threads, `iV_Connect` blocks up to 3 s. **Best used as the bench reference for route A** |
| C. SDK, 32-bit, through a broker | x64 service + x86 helper, KARDi2 pattern | Isolates the vendor DLL in its own process | Two processes to replace a socket we can open ourselves. Not needed |
| D. Python prototype | raw-UDP client in Python publishing through `ResonanceForeignDriver` (`outputChannelsStream`, `outputMessageStream`) | Hours, not days; validated route (`scripts\test-rfd-qt6.py`); good for the bench day | Not a service: no parameters, no states, no configurability ([network-isolation §6](../migrations/network-isolation.md)) |
| E. Resonance on the laptop | Run services beside iView X | One box | ⚠ **Windows 7, 32-bit** (§1a.2): Qt 6 does not run there. Rejected |
| F. Our own tracker, no iView X | Qt 6 service drives the RED500's uEye camera through the IDS SDK and tracks the eyes itself | No laptop, no licence, raw eye images, per-frame hardware sync (§3a) | Building an eye tracker: months, accuracy is research; camera model and IR illumination still unknown |

<a id="history-3a-route-f--replace-iview-x-our-own-tracker-on-the-red500-hardware"></a>

### 3a. Route F — replace iView X: our own tracker on the RED500 hardware

*Added the same day, on the question "can't we substitute iView X with our own layer?"* Routes A–D
make the Resonance service a **client** of iView X, the way `fieldtrip` is a client of a buffer.
A true device driver — like `nvx136` — would drive the RED500 hardware itself. The laptop copy says
that is possible in principle, because the hardware is off the shelf; it also says iView X is not
a thin layer but **the whole eye tracker**.

**What the RED500 hardware is, from the copy** (settings, import tables and strings only — iView X's
EULA forbids decompiling or disassembling it, and nothing was):

* **A Pulnix TM-6740CL CameraLink camera on a Euresys Grablink frame grabber** — the active grabber
  setting (`settings\grablink.set`) and both 500 Hz setups (`red_500Hz.ivs`, `setup_2803_500.ivs`)
  wire `euresys\TM-6740CL_1250_FPS.cam`. ⚠ **Correcting the earlier read:** the `ueye*.set` /
  `SOFTWARE\IDS\uEye` strings and `default.xml`'s AVT Pike are iView X's support for *other* RED
  camera back-ends (RED-m / RED4); the 500 Hz path here is CameraLink, and only the Euresys `.cam`
  files carry a 500 fps mode. A native route therefore needs a **Euresys grabber and its
  driver** (modern eGrabber/MultiCam supports Windows 10/11), not a USB cable — the grabber card
  lives in the laptop.
* **Exposure and IR strobe are in the `.cam` file** (`TM-6740CL_500_FPS.bin.cam`, pure data):
  `FrameRate_mHz = 500000` (500 Hz), `Expose_us = 1790`, and **`StrobeMode = AUTO`, `StrobeCtl =
  TTL`, `StrobeLevel = PLSHIGH`** — the grabber pulses the IR illuminators over TTL, synced to each
  exposure. That answers "how are the LEDs driven" without touching code.
* **It streams a 344 × 80 px, 8-bit window at 500 Hz that moves across the sensor** — measured from
  SMI's own eye-image dumps (`iView X\eyeImages\`, 3 sessions of 2017, 37 770 frames: frame
  interval 1.999 ms median, p5–p95 1.94–2.07 ms; window origin x 220–720, y 230–782). Both eyes sit
  in that one window.
* **The optical/eye model is data, in `redx\red5.0.ini`:** `[Camera]` perspective transform
  (focal ≈ 2378 px, principal point 640, 512), `[Illumination] NoOfSpots = 2` at
  ±133.1 mm (a 266 mm-wide IR pair, 27.1 mm forward), `[EyeModel] CorneaRadius = 7.8`. This is the
  full geometry the gaze estimator uses — readable, not reverse-engineered.
* **Only the tracking algorithms are SMI's compiled code:** `SoftTracker.dll` / `RedXTracker.dll`
  (IPP 5.1, OpenCV 0.97) — the eye finder that places the window
  (`TrackingMonitor::CalculateEyeAOIs`), dark-pupil detection (`UseRED5PupilAlgo`) and
  **corneal-reflex pairs** (`StEyeAOICRPairsDetector` — the IDF's `CR1`/`CR2` per eye), feeding the
  geometry above and the filters of §1a.5.

**What replacing it would take:**

| Stage | Work | Unknowns |
|---|---|---|
| F1. Camera | Euresys grabber SDK (eGrabber) on the Resonance PC: open the TM-6740CL, 344 × 80 window at 500 Hz, move it live, grabber-controlled exposure and the TTL strobe from the `.cam`; a Resonance service streaming frames + per-frame grabber timestamps | whether the **Euresys grabber card** can move to a modern PC (or a current Coaxlink/Grablink equivalent is used); the grabber model in the laptop |
| F2. Features | pupil + two glints per eye at 500 Hz, the moving-window eye finder, blink/loss handling — reimplemented from the published dark-pupil / corneal-reflection literature, not from SMI's binary | robustness with glasses, lashes, head movement |
| F3. Gaze | calibration and gaze mapping with head-movement compensation, using the **known geometry already in hand** — two IR spots ±133.1 mm, cornea R = 7.8, camera focal ≈ 2378, screen planes (`Planes.integrated.22.9p.red5.ini`) | reaching SMI's 0.4° over the 40 × 20 cm head box is research, not porting |

Rough size: F1 one to two weeks (given the grabber card), F2 two to four, F3 three to six and
open-ended — **two to three months** to something usable in experiments, against one to one and a
half weeks for route A. Much of what looked like an unknown is already answered by the data files
above; none of it needed decompilation.

**What makes it tempting:** no Windows 7 laptop and no machine-bound licence; everything on the
Resonance PC; raw eye images for pupillometry; per-frame camera timestamps; and the camera's digital
output could mark frames on the EEG trigger input — **sub-millisecond gaze-to-EEG alignment** that
iView X never offered (§6).

**What makes it tractable:** while the laptop lives, iView X is a frame-by-frame oracle. Recording
an eye-image dump (`ET_EVB` with a duration, buffered, no loss) and an IDF at the same time gives
SMI's own pupil and glint coordinates (`L Raw X/Y`, `L CR1/CR2 X/Y`, in sensor pixels) for every
frame our detector sees.

⚠ **Before plugging the RED500 into another PC:** it re-enumerates under whatever uEye driver is
there and gets that driver's firmware uploaded. Do not let IDS tools change the camera ID, write its
EEPROM or update anything — iView X may depend on them — and plug it back into the laptop to check
iView X still finds it.

**On decompiling iView X.** The parts of iView X worth having are **data, not code**, and reading
them is not decompilation: the protocol (documented), the camera register/strobe config (`.cam`),
the optical and illumination geometry (`red5.*.ini`), the calibration coefficients (`.cal`), the
screen planes (`Planes.*.ini`). The only thing behind the compiled wall is the pixel-level
pupil/glint detection in `SoftTracker.dll` — IPP-5.1 / OpenCV-0.97 machine code that decompiles into
unusable pseudocode, and whose *method* (dark-pupil thresholding, corneal-reflection vector, two-
glint gaze estimation) is standard and better taken from the open literature. So a native tracker
does **not** hinge on disassembling SMI's binary; iView X is more useful kept **running** as a
frame-by-frame oracle (§below). Note too that SMI's copyright did not lapse with the company — the
assets went to Apple — and the EULA forbids decompilation; the interoperability work here doesn't
need to test that.

**Recommendation:** one service contract (§5.1), two back ends — **iView X over UDP now** (route A),
**native Euresys/Pulnix later** if the laptop's end of life or the sync benefit justifies months of
work. The first cheap step towards F is facts from the running laptop: the **Euresys grabber model**
(Device Manager / MultiCam), the Pulnix module's label, an export of the iView X install (the
`redx\` and `euresys\` folders are already in the copy), and confirming the IR strobe wiring at the
module. Recording an `ET_EVB` eye-image dump and an IDF together gives SMI's own per-frame pupil and
glint coordinates to validate a home-grown detector against.

**Prior art for A and B in one place:** the LSL app for SMI
(`github.com/labstreaminglayer/App-SMIEyetracker`) ships both — `Legacy-SDK/` sends `ET_STR`,
`ET_FRM "%ET %SX %SY %DX %DY %PX %PY %CX %CY"`, `ET_REC` and parses `ET_SPL` lines; `iViewX-SDK/`
uses `iV_Connect` + `iV_SetSampleCallback` and dates each sample as
`local_clock() − (iV_GetCurrentTimestamp − sample.timestamp)`. On the laptop, SDK 4.4's
`Examples\Python\DataStreaming` is the same pattern and picks `iViewXAPI64.dll` on 64-bit Python
(Python 2 syntax).


<a id="history-4-the-protocol-as-far-as-the-service-needs-it"></a>

## 4. The protocol, as far as the service needs it

<a id="history-41-link-setup-iview-x-side-system-manual-pp-7475-331332-342"></a>

### 4.1 Link setup (iView X side, System Manual pp. 74–75, 331–332, 342)

*Setup → Hardware → Communication*: **Remote = Ethernet**, tick **Accept Remote Commands** and
**Stream Data**; *Configure*: **Listen** = laptop IP : port (default **4444**), **Send UDP packets
to** = Resonance PC IP : port (default **5555**). Ports must mirror on our side. iView X has **two
remote interfaces** on different ports, so a Resonance service and, say, Experiment Center can be
attached at the same time. The laptop's saved `bci_*.ivs` setups already hold a two-PC pair
(`192.168.0.2` ⇄ `192.168.0.3`, §1a.3).

<a id="history-42-format"></a>

### 4.2 Format

ASCII; every command is `ET_` + three letters, blank-separated parameters, terminated by LF.
**`ET_REM` and `ET_INC` are processed in real time; everything else is queued — "a delay of 10 ms
or less may be possible"** (p. 501).

<a id="history-43-the-commands-a-service-would-use"></a>

### 4.3 The commands a service would use

| Purpose | Commands |
|---|---|
| Presence / identity | `ET_PNG` → `ET_PNG`; `ET_INF ver`, `ET_INF dev`; `ET_SRT` (sample rate); `ET_CFG` |
| Gaze stream | `ET_FRM "<format>"` then `ET_STR [rate]` (rate 1…sample rate) → one **`ET_SPL`** datagram per sample; `ET_EST` stops it |
| Calibration | `ET_CSZ w h` (calibration area = subject screen pixels); `ET_CAL n` (n = 2, 5, 9 or 13) → iView X answers `ET_CAL n`, `ET_CSZ`, one `ET_PNT i x y` per point, then `ET_CHG i` as each point becomes active; `ET_ACC` accepts, `ET_BRK` cancels, **`ET_FIN`** on success; `ET_CPA` (wait-for-valid-data, randomise, auto-accept, speed), `ET_LEV` (check level), `ET_DEF`. ⚠ **`ET_PNT` cannot *set* points on RED systems** (p. 517) — positions come from iView X |
| Validation | `ET_VLS` → one `ET_VLS <eye> rmsX rmsY rmsD devX° devY°` line per eye (`left`, `right`); `ET_VLX x y` for one point |
| Online fixations | `ET_FIX minDur_ms maxDisp_px` → `ET_FIX eye x y` at fixation start (≥ minDur late), `ET_EFX eye dur x y` at end; `ET_EFX` alone stops detection |
| IDF recording on the laptop | `ET_REC`, `ET_STP`, `ET_PSE`/`ET_CNT`, `ET_INC`, `ET_QRS`, `ET_CLR`, `ET_SAV "path" "description" "user" "OVR"` |
| Markers into the IDF | **`ET_REM "text"`** → `<timestamp> MSG <trial> text`, attached to the sample acquired right after the last character arrives (p. 521). A `.bmp/.jpg/.png/.avi` name becomes a BeGaze trial separator |

<a id="history-44-et_frm-specifiers-and-the-units-to-confirm-on-the-device"></a>

### 4.4 `ET_FRM` specifiers and the units to confirm on the device

`%TU` timestamp µs · `%TS` ms · `%SX %SY` gaze px · `%DX %DY` pupil diameter **px × 32** ·
`%PX %PY` pupil position px × 32 · `%CX %CY` corneal reflex px × 32 · `%EX %EY %EZ` **eye position
mm relative to the camera (RED series)** · `%ET` eye type `l|r|b`. **Binocular data doubles each
specifier, left first:** `ET_FRM "%ET %SX %SY"` → `ET_SPL b SXl SXr SYl SYr` (p. 515).

A service would set something like `ET_FRM "%TU %ET %SX %SY %DX %DY %EX %EY %EZ"`.

**Open questions, and what the laptop copy already answered:**
1. *Pupil units of `%DX`.* Open — and the IDF shows the "mm" this system writes is not
   physiological (§1a.5). Settle it by streaming the same seconds through the SDK
   (`EyeDataStruct::diam`, documented mm) and the raw protocol side by side.
2. *Gaze during a blink or track loss.* **`0.000` in the IDF** (§1a.5); confirm the stream does the
   same, then map to NaN, as `eyelink` does.
3. *Whether `%TU` is monotonic across `ET_STR`/`ET_EST` and recordings.* The IDF timeline is µs
   since iView X started (values from 0.5 × 10⁹ to 2.2 × 10¹⁰ µs seen); confirm across a stream
   restart.

<a id="history-45-a-tracker-in-software-twice-over"></a>

### 4.5 A tracker in software, twice over

* **iView X mouse mode** (p. 452: *Setup → Hardware*, tracker **Custom**, grabber **Mouse**) makes
  the real server emit samples, blinks and noise at a chosen rate with no camera — acceptance of
  the whole network path on the kit laptop without a subject.
* A **protocol emulator** (a few hundred lines of Python: `ET_PNG`, `ET_INF`, `ET_SRT`, `ET_FRM`,
  `ET_STR` at 500 Hz, the `ET_CAL` point walk) gives CI what FieldTrip's demo tools give its
  service — and can itself be checked against mouse mode once. The IDF exports (§1a.5) supply
  realistic sample streams to replay, gaps and zeros included.


<a id="history-5-a-sketch-of-the-service-proposal-not-a-design"></a>

## 5. A sketch of the service (proposal, not a design)

<a id="history-51-contract"></a>

### 5.1 Contract

* **Name** `smiRed` (`smiRed.exe`, `smiRed.bat`), blue input-device icon, a line in the
  acquisition group of `launchbar-default.txt`.
* **Streams**
  * `eyeData` — Float64 at the tracker's rate. Channels 0–3 exactly as EyeLink
    (`left.x left.y right.x right.y`, px), then `left.pupil right.pupil`, `left.eyeX … right.eyeZ`
    (mm), and **`tracker.us`** (the raw iView X timestamp — a double holds µs exactly to 2⁵³).
    Missing data (`0.000`) NaN.
  * `eyeEvents` — Message/JSON, EyeLink's vocabulary where it applies (`fixation_start`,
    `fixation_end`), plus `calibration_point`, `calibration_finished`, `calibration_cancelled`,
    `validation` (the `ET_VLS` numbers), `recording`.
  * `events` — the `x:y` fixation clicks, from `eyelink::logic`.
  * **input** `markers` — Message stream; every block is forwarded as `ET_REM`, so experiment
    markers land in the IDF on the tracker's own clock.
* **States** `init`, `connecting`, `running`, `calibrating`, `noTracker`; transitions `start`, `stop`,
  `calibrate`, `validate`.
* **Parameters** (every one with a description, labels ≤ 22 characters): tracker IP / listen port,
  local interface / receive port, stream rate, block size, fixation detection (duration,
  dispersion), the click parameters EyeLink has, IDF control (record on start, save path and
  subject on the laptop), calibration (points, auto-accept, speed, check level, colours, target
  size, monitor); read-only readouts of iView X version, device, sample rate, last validation.
* `stateInfo` carries link health; **`reportDroppedSamples()`** counts gaps in `%TU` (> 1.5 sample
  periods), which catches UDP loss and tracker drops alike — and will show the tracker's own
  0.2–0.5 % baseline (§1a.5).

<a id="history-52-threads-and-link"></a>

### 5.2 Threads and link

A worker `QObject` on a `QThread` owns the socket (bound to the NIC that faces the laptop, **not**
`Any`), parses `ET_SPL` without allocation, and **drops datagrams whose source is not the
configured iView X address**. `start` = `ET_PNG` with a deadline → `ET_INF`/`ET_SRT` → `ET_FRM` →
`ET_STR`; `stop` = `ET_EST` (+ `ET_STP`/`ET_SAV` if the service owns the IDF). Missing pings or a
silent stream move to `noTracker` and retry, as FieldTrip does; nothing on the main thread waits
for the tracker ([neuroMS lesson](../components/neuroms.md)).

<a id="history-53-calibration-window"></a>

### 5.3 Calibration window

A frameless full-screen window on the chosen monitor. `ET_CSZ` with that monitor's size, `ET_CAL
n`, draw the target at the `ET_PNT` position of each `ET_CHG`, optional accept key → `ET_ACC`, Esc
→ `ET_BRK`, close on `ET_FIN`; then `ET_VLS` and show the numbers. The eyetribe QML is the nearest
reference in the tree. **Until it exists**, calibration can be run on the second remote port by
**WinCAL 1.4.11** from the CD's iTools installer, or by Experiment Center 3.5 (it needs its HASP
dongle) — if either still installs on the Resonance PC's Windows (unknown).


<a id="history-6-timing-and-synchronisation-with-eeg"></a>

## 6. Timing and synchronisation with EEG

**What a gaze sample's time can be.** iView X dates samples on the laptop's clock (µs). This RED500
reports **0.7–0.9 ms** of internal latency at 500 Hz with the heuristic filter off, and ~9 ms at
250 Hz with it on (§1a.5, the IDF `Latency` column). The service receives samples over UDP and can
map tracker time onto the Resonance RTC with a minimum-delay estimator — offset ≈ min over a
sliding window of (RTC at receipt − tracker time) — which follows drift and dates each block's
`created` (its **last** sample, the tree's convention) at the tracker time plus the smallest
observed transport delay. On a direct cable that should be ~1 ms; ⚠ it has not been measured.

**Why that is not enough on its own.** EEG blocks are dated when the driver builds them, after the
SDK returns. Measured on this rig: an NVX trigger edge compared across two services' RTCs is
**+9.3 ms median, 16.7 ms spread**, while the same edge read from the recorded trigger channel is
exact to ±½ sample ([trigger validation §6](report_trigger-validation.md)). Comparing gaze
`created` against EEG `created` therefore inherits the EEG side's ±8 ms, however well the gaze is
dated.

**What to do instead:**
1. **Keep both clocks**, as `arduinoTTL` already does with `deviceUs` beside `rtc`
   ([service_arduino-ttl.md §4](../components/arduino-ttl.md)): `tracker.us` travels in `eyeData`, so
   any alignment can be redone offline.
2. **Fit, don't read.** Over a recording, the lower envelope of (block `created` − sample time)
   gives each stream's clock offset without the per-block delay scatter — for EEG with sample
   index × period, for gaze with `tracker.us`. What remains is each side's *minimum* latency, a
   constant.
3. **Measure the two constants once per rig with a common physical event.** EEG side: `arduinoTTL`
   pulses into the trigger input, placed to ±½ sample (the board's `deviceUs` is exact; its `rtc`
   carries ~1–3 ms of USB latency, so fit it the same way). Tracker side: record **vertical EOG**
   on the amplifier beside gaze — blinks and vertical saccades appear in both, and their
   cross-correlation gives the residual gaze-to-EEG offset in milliseconds with no extra hardware.
4. Put experiment events into the tracker as **`ET_REM`** (real time; ≤ 2 ms at 500 Hz) so the IDF
   on the laptop can be aligned with the HDF5 on the PC too.
5. A TTL *into* iView X (LPT or DIO card, ≥ 1.5 samples wide, logged in the IDF *Trigger* column,
   p. 489) is the strongest offline anchor — only if the laptop has such a port; none is
   configured today (§1a.3).


<a id="history-7-risks-and-traps"></a>

## 7. Risks and traps

1. ⚠ **Licence.** iView X is licensed to one computer (Sheriff licensing: `DLL\SlsApi.dll`, state in
   `iView X\5351-8621-2729-7641-5701\*.SLS`); a *Reusable* key survives reinstalling iView X on the
   same computer **only if the disk has not been reformatted or Windows reinstalled** (pp. 44–49).
   Copying those files does not move a licence. So: no OS reinstall, no disk swap, no **Terminate
   Licence** click; photograph *Help → License* before anything else. Experiment Center/BeGaze have
   their own Sentinel/HASP licence.
2. ⚠ **The tracker is tied to 32-bit Windows 7.** Its camera driver on the SMI CD is IDS uEye 3.80
   with **x86-only** kernel drivers (§1a.2). Moving the RED500 to a 64-bit PC would need a newer IDS
   driver under a 32-bit iView X and a new licence — unproven on both counts. Keep the laptop
   healthy; image its disk if that can be done without touching the installation.
3. **Network isolation gains a documented exception.** Resonance stays `loopback`; only this
   service's device socket faces the laptop, on a second NIC (or USB adapter) with static
   addresses. Bind to that interface, filter by source, and add the service to
   [network-isolation §6](../migrations/network-isolation.md). Windows Firewall on the lab PC (off on this
   one) needs an inbound UDP rule.
4. **UDP is lossy by design, and the tracker has gaps of its own** (§1a.5). A direct cable makes
   network loss rare; the `%TU` gap counter shows both kinds. The IDF on the laptop remains the
   record of what the tracker produced.
5. **Queued commands.** Everything except `ET_REM`/`ET_INC` may wait ~10 ms in iView X's queue —
   never use `ET_REC` or a calibration command as a timing marker.
6. **Filters change the data.** The heuristic filter adds ~8 ms at 250 Hz; channel averaging makes
   left and right gaze identical (§1a.5). Both are iView X/SDK settings the service should read
   back and report.
7. **Route B's side effects** — InpOut's driver installer and two old VC++ runtimes (§1a.4). If the
   SDK is ever linked, ship a no-op `inpoutx64.dll` and never run the service elevated.
8. **Units** — §4.4. **Calibration UI** — §5.3, the largest single item.
9. **No vendor.** Gaze Intelligence is the only download/support channel found. The laptop copy
   already preserves every installer, driver and manual (§1a.1).
10. **iView X quirks worth an operator note** (p. 537): changing the screen resolution while iView X
    runs freezes the laptop; background virus scanning is not supported.
11. **Participant data in `R:\equipment`** (§1a.5) — ~27 GB of recordings and eye images.


<a id="history-8-what-the-laptop-copy-settled-and-what-is-still-open"></a>

## 8. What the laptop copy settled, and what is still open

| Question | Status |
|---|---|
| Windows version and bitness | ✅ Windows 7 (IDF header); 32-bit by strong inference (§1a.2) |
| iView X version, setups, Communication settings | ✅ 2.8.43; localhost now, a saved two-PC pair in `bci_*.ivs` (§1a.3) |
| SDK version, 64-bit DLL, header, examples | ✅ 4.4.10, 32 + 64-bit, full `iViewXAPI.h` (§1a.1, §1a.4) |
| iTools / Experiment Center / BeGaze | ✅ versions in §1a.1; WinCAL on the CD, not installed |
| Earlier IDF files | ✅ 175 IDF + exports; units, loss and latency measured (§1a.5) |
| Monitor and mode | ✅ Monitor Integrated, 22″ profile, 1680 × 1050, profile named `eizo` |
| *Help → License* (licence type, expiry) | ❓ open — a photograph from the running laptop |
| Laptop ports: Ethernet speed, LPT/ExpressCard, spare USB | ❓ open — decides the cable and §6 step 5 |
| The experiment scripts (`C:\Users\iView X\Documents\SMI_BCI_Experiments`, `D:\Practice`, `C:\BCI_DEMO`) | ❓ not copied — they would show how the lab drove the tracker and sent markers |
| Pupil units, stream zeros, `%TU` across restarts | ❓ bench (§4.4) |
| Camera path for route F | ✅ Euresys Grablink + Pulnix TM-6740CL CameraLink, IR strobed over TTL, optics/illumination geometry in `red5.0.ini` (§3a) — open item is only the grabber card's portability |
| **What the tracker is for** | ❓ passive gaze/pupil recording beside EEG, gaze-contingent control (EyeLink-style fixation clicks), or both — decides whether §5.3 and the click stream are phase 1 or later |


<a id="history-9-plan-if-it-goes-ahead"></a>

## 9. Plan, if it goes ahead

| Phase | Where | Work | Done when |
|---|---|---|---|
| 0. Bench | kit laptop + this PC, no subject | photograph the licence; direct cable and static IPs (or load `bci_250.ivs` and give this PC `192.168.0.3`); heuristic filter off, averaging off; `ET_PNG`; capture `ET_SPL` at 500 Hz with a raw-UDP Python probe recorded through `recorderService` (route D); stream the same seconds through the SDK's Python example as the unit reference (**not elevated** — §1a.4); walk `ET_CAL` once; mouse mode for a no-subject run | a recording with the counted loss, the units written down, and SDK and protocol agreeing |
| 1. Service | this PC | Qt 6 `smiRed` per §5.1–5.2, emulator (replaying §1a.5 exports) + parser/clock-model tests, icon, launcher, description audit, docs page | emulator and mouse-mode acceptance through `recorderService`, Stop/Start, laptop unplugged and back |
| 2. Calibration | this PC + laptop | §5.3 window, validation readout, optional tracking-monitor view from `%EX %EY %EZ` | a calibration and `ET_VLS` result from a real subject |
| 3. Lab acceptance | rig with EEG | §6 alignment (arduinoTTL pulses, EOG cross-correlation), 30-minute run, loss count | a measured gaze-to-EEG offset and spread |

Estimates: phase 0 about a day; phases 1–2 **3–5 days**; phase 3 a lab day.

---


<a id="history-sources"></a>

## Sources

* The kit-laptop copy, `R:\equipment\SMI_RED500\SMI_PC\` — iView X 2.8.43 install and release notes;
  iView X SDK 4.4.10 (`docs\iView X SDK ReleaseNotes.txt`, `docs\iView X SDK Manual.pdf`,
  `include\iViewXAPI.h`, `bin\`); the iView X and Experiment Suite setup CDs; IDF exports under
  `Program Files\SMI\iView X\` and `Desktop\`
* SMI, *iView X System Manual*, IVX-2.8.38 (2014) — on the setup CD and in
  `R:\equipment\SMI_RED500\manuals-public\` (public copy at
  `https://tsgdoc.socsci.ru.nl/images/6/6f/IViewX.pdf`)
* SMI, *iView X SDK Manual* 3.1.0 (June 2012), public copy — superseded here by the 4.4 manual
* SMITE toolbox (Niehorster et al.), SDK 4.4.26 and `iViewXAPI64.dll`:
  `https://github.com/dcnieho/SMITE`, `iViewXAPI.m`
* LSL SMI app, raw-UDP and SDK variants: `https://github.com/labstreaminglayer/App-SMIEyetracker`
* Gaze Intelligence SMI downloads: `https://gazeintelligence.com/smi-software-download`
* LOLDrivers entry for `inpoutx64.sys`: `https://www.loldrivers.io/`
* Apple's acquisition of SMI, June 2017: `https://techcrunch.com/2017/06/26/apple-acquires-smi-eye-tracking-company/`
