# `neuronSpectrum` — the Neurosoft Neuron-Spectrum-65 driver — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/neuron-spectrum.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-neuronspectrum--the-neurosoft-neuron-spectrum-65-driver"></a>


**Added 2026-08-15.** Acquisition, impedance and front-panel control for the Neurosoft
Neuron-Spectrum-6g family, verified on an NS-65 (serial 22370366).

It is the fourth amplifier driver in the tree and the only one that does **not** link a C SDK,
because there isn't one. Read [§1](neuron-spectrum.md#history-1-the-fact-that-shapes-everything) before anything else.

**Ported to Qt 6, 2026-08-29, and current.** `neuronSpectrum.exe` and its `/clr` `ns65bridge.dll`
ship in the default distribution at `R:\dist\bin`, with the 14 managed assemblies in
`R:\dist\bin\neuronSpectrum\` (§3) and the 14 Intel IPP DLLs flat in `R:\dist\bin` (§7). Source is
`R:\src\neuronSpectrum`, built with Qt 6.11.2 and **MSVC v143 14.44**; the Qt 5 build survives as
the comparator in `R:\src_Qt5\neuronSpectrum` → `R:\dist_Qt5\msvc64`. Nothing about the vendor
stack changed: it is the same .NET Framework 4.8 managed SDK behind the same flat C ABI, and the
28-parameter control surface is byte-for-byte identical across the two generations (§10a). See
[qt5-to-qt6-transition.md](../migrations/qt5-to-qt6-transition.md).

---


<a id="history-1-the-fact-that-shapes-everything"></a>

## 1. The fact that shapes everything

**The vendor SDK is .NET Framework 4.8 managed code.** `NeuroSoft.Hardware.Devices.RegistratorEEG.dll`
and its eight dependencies are AnyCPU MSIL assemblies with XML documentation; the `Sources`
folder is C#; the USB layer is a C# WinUSB wrapper. There is no C API and no import library.

Resonance services are native Qt processes, so something has to cross that boundary. The choice
made here is a **mixed-mode bridge DLL with a flat C ABI**:

```
neuronSpectrum.exe   100% native Qt/Resonance  ── links ──►  ns65bridge.dll   (/clr)
                                                                  │
                                                                  └─► managed vendor SDK
                                                                        └─► WinUSB
```

`bridge/ns65bridge.h` is deliberately shaped like `NVX.h`/`nvx.h`: open by index, configure,
start, drain fixed-size frames, stop, close. That is why `neuronspectrumdriver.cpp` reads like
`nvx136driver.cpp` despite the completely different vendor stack — the strangeness is confined
to one translation unit.

**`bridge/ns65bridge.cpp` is the only `/clr` file in the tree.** It includes no Qt and no
Resonance headers.

<a id="history-two-clr-rules-that-are-not-stylistic"></a>

### Two `/clr` rules that are not stylistic

* **`<mutex>` does not exist in managed code.** MSVC removes `std::mutex` when `_M_CEE` is
  defined, so synchronisation is `SRWLOCK` — which also needs no runtime initialisation.
* **A mixed-mode DLL runs its native static initialisers under the loader lock.** Every global
  in that file is therefore POD and every buffer is allocated explicitly. No global has a
  constructor, by design.

<a id="history-build-requirements"></a>

### Build requirements

Gated `IF (WIN32 AND x64)` **and** `IF (MSVC)`. MinGW cannot produce a mixed-mode image at all,
so under MinGW the module is skipped and the rest of the tree still builds — the existing arch
gate, on a second axis.

Needs the Visual Studio **"C++/CLI support"** component **for whichever toolset you are building
with** — `v142` for the Qt 5 comparator tree, **`v143` for the default Qt 6 tree**. It is what
drags in `mscoree.lib`. Its absence produces `LINK : fatal error LNK1104: cannot open file
"MSCOREE.lib"` **at link time only** — `/clr` compilation succeeds without it, which makes it look
like a project error.
The tick-list is [dev-environment-setup §B5](../migrations/dev-environment.md), which carries both
component names and the `mscoree.lib` evidence.

⚠ **Get the toolset right or the component is silently the wrong one.** This is a four-place
agreement: §B5 above, [build_new-pc-setup.md](../migrations/new-pc-setup.md),
[build_and-distro.md](../migrations/and-distro.md) and [service_neuroms.md](neuroms.md), whose
`/clr` bridge needs exactly the same component. If any of them is read as the pre-2026-09-02 v142
instruction, a fresh machine installs the v142 component, builds the Qt 6 tree, and fails at link
time on `MSCOREE.lib`.
On this machine all three toolsets under
`C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\` — `14.29.30133`
(v142), `14.44.35207` (v143, the one the Qt 6 build pins with `-vcvars_ver=14.44`) and
`14.51.36231` — carry `include\msclr\` and `include\vcclr.h`, so C++/CLI is installed for each.
`mscoree.lib` itself comes from the .NET Framework 4.8 SDK the component pulls in, at
`C:\Program Files (x86)\Windows Kits\NETFXSDK\4.8\Lib\um\x64\`, and is shared by all of them.

⚠ The gate comment in `R:\src\neuronSpectrum\CMakeLists.txt:7` still names the **v142** component.
That is a stale comment in the source, not a build setting — the Qt 6 tree does build.

---


<a id="history-2-the-device"></a>

## 2. The device

| | |
|---|---|
| Enumeration | `USB\VID_ACCA&PID_8277`, serial in the instance id |
| Kernel driver | **Microsoft's inbox WinUSB** — nothing to install |
| Tested unit | NS-65, hw 3, CPLD cfg 2, interface 1.0, USB MCU firmware 262 |
| Sampling | **fixed 16 kHz.** There is no rate register |
| Channels | 48 configurable + 1 respiration/thermistor = **49** |
| Transport | isochronous USB, dual CRC, sample-numbered frames |

<a id="history-channel-model"></a>

### Channel model

| Group | Count | Panel | Mode |
|---|---|---|---|
| Head electrodes | 23 | Fp1/Fpz/Fp2 … O1/Oz/O2, A1/M1, A2/M2 | referential |
| CHIN | 3 | CHIN R/C/L | referential |
| EOG | 2 | EOG R/L | referential |
| X sockets | 11 | X1–X11 (PRESS, SNORE, BODY, THO, ABD, DC1–DC6) | **referential *or* DC — one switch for all eleven** |
| Differential pairs | 8 | ±1–±8 (ECG, LMs R, LMs L, …) | **differential *or* monopolar-to-ground — per channel** |
| COM | 1 | patient ground channel | — |
| Respiration | 1 | thermistor input | always delivered |

**The device is specified for 39 referential channels** (manual p.62, footnote 1):
*"28 референтных каналов и 11 каналов постоянного тока в режиме референтных каналов"* —
28 = 23 head + 3 CHIN + 2 EOG, and 11 = X1–X11 switched to referential. Verified: with all 39
ticked the stream comes up as **40 channels** (39 + Trigger).

**GND and REF are not channels.** They are the ground and reference electrodes; the device
produces no samples for them. They appear only in the impedance stream, which measures
electrodes.

**The ± pairs cannot be referential.** The manual offers them "дифференциальный или регистрации
сигналов постоянного тока (DC)" only. The SDK's `UseGndAsNegativeInput` ties the negative input
to ground, which gives monopolar recording **against GROUND at ±2.5 V** — a different reference
from the referential channels' REF/Cz/A1/A2, and *not* interchangeable with them. It exists for
DC sensors, not for extra electrodes.

---


<a id="history-3-layout"></a>

## 3. Layout

| File | Contents |
|---|---|
| `bridge/ns65bridge.h` | the flat C ABI — the contract, and the place to read first |
| `bridge/ns65bridge.cpp` | the only `/clr` translation unit; ring buffer, callbacks, error text |
| `bridge/CMakeLists.txt` | `/clr` flags scoped to this target (`/EHa`, C++17, no AUTOMOC) |
| `neuronspectrumlogic.h` | frame layout, gap arithmetic, rate ladder, decimation coefficients. No Qt — unit tested |
| `neuronspectrumchannels.h` | front-panel presentation order for the channel list |
| `neuronspectrumdriver.{h,cpp}` | the worker: open, configure, drain, decimate, gap-repair, publish |
| `neuronspectrumconfig.{h,cpp}` | parameters and the `init/scanning/running/error` machine |
| `main.cpp`, `neuronSpectrum.bat` | entry point and launcher |
| `sdk/lib` | vendor managed assemblies (4.0 MB), installed to **`bin/neuronSpectrum/`** — see the note below |
| `sdk/ipp` | Intel IPP 8.1 signal runtime (59 MB) — see [§7](neuron-spectrum.md#history-7-the-ipp-dependency) |
| `sdk/doc` | vendor XML API docs and readme (4.5 MB), reference only |
| `tests/` | see [§8](neuron-spectrum.md#history-8-tests) |

> ### ⚠ Changed 2026-08-15 — the assemblies moved out of `bin\`
>
> Adding the [Neuro-MS stimulator driver](neuroms.md) put a **second** Neurosoft SDK in the
> tree, and the two ship seven assemblies with **identical simple names, identical version
> `1.0.0.0`, no strong name and different bytes** (2023 builds here, 2016–2019 there). The CLR
> resolves an unsigned assembly by simple name from the probing path, so flat in `bin\` one
> driver's vendor stack would silently satisfy the other's — surfacing as a
> `MissingMethodException` inside a vendor call, on hardware, much later.
>
> Each driver's managed assemblies now live in their own `bin\<driver>\` directory, and each
> bridge installs an `AppDomain::AssemblyResolve` handler pinned to it. `NS_Initialize` grew
> that handler; nothing else in this module changed.
>
> **The Intel IPP runtime stays in `bin\`** — it is native and reached by P/Invoke, which uses
> `LoadLibrary`'s search order and knows nothing about CLR probing paths.
>
> **When redeploying over an existing tree, delete `bin\NeuroSoft.*.dll` and
> `bin\Neurosoft.*.dll` first.** `copy_if_different` never removes anything, and CLR probing
> checks the executable's directory *before* any resolve handler, so stale flat copies take
> precedence over both private directories.
>
> Verified: builds clean, and the resolver loads the stack from the private directory with
> nothing flat in `bin\`. **Not re-verified against the NS-65 itself** — that check is
> outstanding.

---


<a id="history-4-streams"></a>

## 4. Streams

| Name | Type | Contents |
|---|---|---|
| `eeg` | `Float64` | selected channels, volts, at the published rate, plus an optional `Trigger` lane |
| `impedance` | `Float64` | all 57 electrodes, ohms, refreshed every 2–250 s |
| `events` | `Message` | JSON, one per stimulus/sync event, with the offset quantised to one 16 kHz sample (62.5 us) |

Per-channel `name` / `kind` / `unit` metadata is published for every stream, so the signal
viewer groups EEG (µV) apart from AUX (V) and the trigger (bit lanes) without being told.
Channel names are the **device's own electrode labels** (`Fp2`, `A1/M1`, `X6 (DC1)`), not the
`Ch N` the NVX drivers have to invent.

<a id="history-triggers-are-events-not-a-channel"></a>

### Triggers are events, not a channel

Unlike NVX there is no trigger word in the frame. Stimuli arrive as `StimulusInfo { double
Offset; int Index }` with an offset **quantised to one 16 kHz sample — 62.5 us, not sub-sample**
(the SDK computes it as `samplesCount / 16000.0`, so two events inside one sample collapse into
one), indexed by `EventIndex` — flash, pattern, sync-in. So:

* the `Trigger` lane is **synthesised** — a bitfield latched for a couple of output samples,
  quantised to the sample the event fell in;
* the `events` stream carries the event's own absolute device sample, for anything that needs
  the real timing.

Both are published; use whichever suits. The sync input is now reachable — see
`report_trigger-validation.md` (on the lab drive, `R:\docs\_notes\`) — but ⚠ **the trigger lane is not group-delay
corrected**: the latch is placed on the output sample containing the event's raw input sample,
while the analog lanes for that sample are an anti-alias average centred ~22 input samples
earlier. Measure from the `events` stream, not the lane.

⚠ **A sporadic sync-in event loss is real**: two events in 444 across six sessions, at both 1 kHz
and 16 kHz. It loses a mark without disturbing the timing of the ones it keeps, and the trigger
lane is synthesised from the same events so it is not an independent check. Compare `events`
against your own stimulus log rather than assume the counts match.

<a id="history-the-sync-output"></a>

### The sync OUTPUT

This amplifier has **no host-arbitrary output line**. The SYNC OUT socket is wired to a
stimulator, so emitting a pulse means running one — and the module has to be powered for the
socket to do anything, which the driver does at Start. Powering it needs no lamp attached; it is a
control-unit operation, which is what makes the socket usable as a plain trigger output.

`Fire` emits `sync_out_count` pulses spaced `sync_out_period` apart; `0` means an endless train
that `Stop` ends. The emitted pulse is a fixed **100 µs** — `sync_out_flash` is the *lamp's* flash
duration, not the socket's pulse width, and the SDK exposes no setter for the latter at all.

Measured against a device with its own microsecond clock: at 200, 100 and 50 ms spacing the
**median interval error is 0.000 ms**, i.e. zero to the 62.5 µs quantum, with 36/36 pulses
delivered in each of two sessions.

---


<a id="history-5-sampling-and-decimation"></a>

## 5. Sampling and decimation

The device always converts at 16 kHz. Every rate the operator picks is decimation performed by
this driver, and only **exact divisors** are offered — 125, 250, 500, 1000, 2000, 4000, 8000,
16000 Hz — so an output sample never falls between two input samples. A rate that does not
divide is refused rather than silently resampled.

Two policies, because they are a real trade and the operator picks:

| | Behaviour |
|---|---|
| **Anti-alias average** (default) | `order` cascaded boxcars convolved into one direct FIR, then decimate. Nulls land exactly on multiples of the output rate, which is where aliasing folds from |
| **Drop samples** | every Nth sample kept. What the vendor application does. Bit-comparable with vendor recordings, and it folds everything above the new Nyquist into the band |

Expanded into a direct FIR rather than run as a CIC: a CIC's integrators run unbounded at the
input rate, and on a channel sitting at an electrode offset — which is every channel on this
device — the accumulator loses precision over a long recording. A direct FIR has bounded state,
no drift, and at these tap counts costs nothing.

**Measured** (20 s at 16 kHz as reference, 20 s each at 1 kHz, salt-water electrodes):

| Metric | Anti-alias | Drop |
|---|---|---|
| Energy at the 450 Hz alias line (median, 8 ch) | 1× | **3.7×** |
| (200–500 Hz)/(1–100 Hz) power ratio | 0.0065 | **0.0971** |

The reference carries ≈5.2 µV above the 500 Hz Nyquist, strongest at 550 and 650 Hz — which
fold to 450 and 350 Hz under ÷16. Compare within a capture, not across: these are separate
windows and salt-water electrodes drift.

<a id="history-gap-repair"></a>

### Gap repair

Every frame carries the device's own 64-bit sample number, and it is the only usable timeline —
`SynchronizationNumber` is a wrapping USB frame counter, not a clock.

Missing samples are filled at each channel's **last value** so that a NaN can never enter the
filter delay line (one NaN otherwise poisons an IIR channel for good —
[known-issues §13b](../incidents/README.md)), and any output window that contained missing input is
emitted as **NaN**. The gap is represented, not smeared.

**There is always exactly one gap, at start-up**: ~1100–1500 device samples about 0.19 s in, as
the device numbers samples before the host has drained the first URBs. Steady state is clean —
2.9 M frames over three minutes with no further gap.

---


<a id="history-6-impedance--read-this-before-using-it"></a>

## 6. Impedance — read this before using it

**The device refuses the SDK's offline impedance unit.** `ImpedanceUnit.Start()` reports

```
Module returned an error. Module: Amplifier. Long command: 4. Error: 101.
```

reproduced through the bridge and through raw PowerShell against the vendor assemblies, with
and without COM enabled, with the electrode mask fully set. `IsRun` goes true and every
electrode reports `IsMeasureOn`, but no measurement ever runs. Cause unknown — it needs Neurosoft.

**What works is online impedance**, which the SDK derives from the monitoring stream using its
own probe generator. This is also what the vendor application does by default: *"процесс
измерения импеданса запускается при старте регистрации или мониторинга ЭЭГ автоматически"*
(software manual p.36).

So **impedance is not a separate mode** in this driver. All three `mode` options acquire; they
differ only in what is published:

| Mode | `eeg` | `impedance` |
|---|---|---|
| Acquisition | ✅ | — |
| Acquisition + impedance | ✅ | ✅ |
| Impedance only | — | ✅ |

Measured on salt-water electrodes: **0.55–5.4 kΩ**, stable to ~2 % over three minutes,
polarisation ≈ 0. Specified range is 0–75 kΩ online (0–300 kΩ offline), ±3 kΩ absolute below
10 kΩ.

> ⚠ **Unmeasured electrodes publish NaN, not 0.** An electrode whose channel is not selected
> reading zero ohms looks like *perfect contact* — the most dangerous thing that stream could
> say. The same reasoning made the driver latch the SDK's asynchronous refusal so that a
> rejected measurement cannot return success.

The update interval is **seconds, 2–250**, enforced by the SDK: it accumulates the probe
response over several data portions, so no faster update exists however it is asked for.

---


<a id="history-7-the-ipp-dependency"></a>

## 7. The IPP dependency

`NeuroSoft.MathLib.IPPLibrary` P/Invokes `ipps-8.1.dll`, and the SDK constructs its
online-impedance calculator **unconditionally inside `StartReadData`** — before it checks
whether online impedance was even requested. So **Intel IPP 8.1 is required for any
acquisition**, impedance or not. Without it, `StartReadData` throws
*"Не удается загрузить DLL ipps-8.1.dll"*.

The DLLs are **staged into `bin/`, not installed**: `sdk/ipp` holds the dispatchers plus every
`ipps` CPU variant (14 files, 59 MB) so any x64 CPU generation resolves. Only three load on any
given machine — on the development machine `ipps-8.1.dll`, `ippcore-8.1.dll`, `ippsl9-8.1.dll`
(~5.7 MB). Trim the set if size matters more than portability across rigs.

They were extracted read-only with 7-Zip from the vendor's own NSIS installer at
`R:\equipment\NeurosoftPrograms\Нейрон-Спектр.NET\IPP\ipp81_runtime_setup.exe`.

**Unchanged in the Qt 6 distribution, and verified there.** `R:\dist\bin` holds all 14 `ipp*-8.1`
DLLs flat, `R:\dist\bin\neuronSpectrum\` holds the 14 managed assemblies plus
`NeuroSoft.Common.dll.config`, and there is **no flat `NeuroSoft.*` / `Neurosoft.*` in
`R:\dist\bin`** — so the §3 collision rule and the redeploy warning that goes with it both still
hold, on a tree with no `msvc64\` level in it.

---


<a id="history-8-tests"></a>

## 8. Tests

| Target | Needs | Registered |
|---|---|---|
| `test_NeuronSpectrumLogic` | nothing | ctest, always runs — **24 cases** |
| `ns65_bridge_smoke` | device connected and idle | ctest, `DISABLED`, label `hardware` |
| `ns65_stream_check` | a running service | not registered — a consumer, run by hand |
| `ns65_panel_probe` | a **person** at the device | never registered |

All build into `<build>/tests/`, outside `runtime/`, so nothing test-shaped reaches a
distribution.

`test_NeuronSpectrumLogic` covers the things a hardware test would not notice: the counter
surviving the 32-bit boundary, `missingSamples` not underflowing on a stall or restart, every
ladder rate dividing 16 kHz exactly, the filter's unit gain, and — the one that matters — that
the filter's spectral nulls sit exactly on multiples of the output rate, evaluated on the tap
set rather than asserted.

`ns65_stream_check` subscribes through Resonance's own `InputStream` and reports channel count,
metadata, measured rate, NaN counts and per-channel ranges; `--dump` writes raw samples for
offline analysis. It resolves the stream through `ServiceDiscovery` and prints what discovery
can see when it fails, because "timed out" says nothing about why.

> **Always run a control.** The first two "the stream does not resolve" results from
> `ns65_stream_check` were the *checker* being wrong, not the driver. Running it against
> `signalGenerator` failed identically, which is what exposed it. The driver had been
> publishing correctly the whole time.

---


<a id="history-9-the-front-panel"></a>

## 9. The front panel

The manual describes a mode-selection button cycling impedance → monitoring → recording. The
SDK shows what that actually is: `IControlModule` exposes `ButtonPushed` as an **event** plus a
separate `WorkModeLedState` (Off/Registration/Monitoring/Impedance). **The device switches
nothing itself** — it reports the press and the host decides what it means and lights the
matching LED.

So the button cannot be used to put the amplifier into a mode the software could not reach, and
it is not a route around the offline-impedance refusal. The driver counts presses and drives
the LED to mirror its own state: Ω while measuring impedance, ▷ while acquiring, off on stop.

Verified: three presses, three counted, LED under software control throughout.

---


<a id="history-10-verified-on-hardware"></a>

## 10. Verified on hardware

⚠ Everything in this section is **Qt 5 evidence**, measured 2026-08-15/17 against the tree that is
now `R:\src_Qt5` → `R:\dist_Qt5\msvc64`. It has **not** been repeated against the Qt 6 build; see
§10a for what the port did verify and what it deliberately did not.

Against the connected NS-65 with electrodes in saline:

| Check | Result |
|---|---|
| Discovery | `NeuronSpectrum` advertising `@ eeg events` (and `impedance` when enabled) |
| Stream | 24 ch @ 1 kHz, measured 998.6–1000.7 Hz, block 100, **0 NaN**, full metadata |
| Full montage | **40 channels** (39 referential + Trigger) @ 1 kHz, 0 NaN |
| Rate sweep | all eight rates, ±0.3 % (16 kHz +0.8 %), 0 NaN, exact block sizes |
| Bridge | 15 785–15 851 Hz, one start-up gap, **0 ring overflows** |
| Long run | 2.9 M frames over 3 min, impedance stable, clean stop |
| Impedance | 0.55–5.4 kΩ on 24 electrodes, NaN on unmeasured ones |
| Front panel | 3/3 button presses counted; LED control works |
| Lifecycle | repeated start/stop back to `init`; device re-enumerates `OK` |
| Unit tests | `test_NeuronSpectrumLogic` 24/24 |

Evidence: `R:\dist\_build\ns65-validation`, now `R:\dist_2026aug\_build\ns65-validation` (59 MB
16 kHz reference capture, both 1 kHz captures, button log).

**Both since verified on hardware** (2026-08-17, `report_trigger-validation.md` (on the lab drive, `R:\docs\_notes\`)).
The `events`/trigger path was driven from an arduinoTTL board — 8/8 in all four enable/invert
combinations, 40/40 on a train, edge located to one 16 kHz sample. HDF5 recording through
`recorderService` was exercised in four sessions at 1 kHz and 16 kHz; the ctypes limitation of
[known-issues §15e](../incidents/README.md) is real but is routed around by driving the services from a
QML harness over the EventBus rather than by ctypes.

⚠ Set `sync_in_inverted` **true** for any source that idles high and fires low, which is what the
manual specifies. It now defaults to true; anything recorded before 2026-08-17 was timestamped on
the pulse's trailing edge and is late by the stimulus width
(`report_trigger-validation.md` §6c (on the lab drive, `R:\docs\_notes\`)).


<a id="history-10a-what-the-qt-6-port-verified--2026-08-29"></a>

## 10a. What the Qt 6 port verified — 2026-08-29

**The service sources did not change.** `neuronspectrumconfig.cpp`, `neuronspectrumdriver.cpp`,
`neuronspectrumlogic.h`, `neuronspectrumchannels.h` and `bridge/ns65bridge.cpp` are byte-identical
between `R:\src_Qt5\neuronSpectrum` and `R:\src\neuronSpectrum`. The **entire** delta is two lines
of `CMakeLists.txt`: `find_package(Qt5 COMPONENTS Core REQUIRED)` became `find_package(Qt6 6.11
REQUIRED COMPONENTS Core StateMachine)`, and `Qt6::Core Qt6::StateMachine` were added to the link
line — the state machine moved out of QtCore in Qt 6. `bridge/CMakeLists.txt` is unchanged, so the
`/clr` flags (`/EHa`, C++17, no AUTOMOC) are the same ones. Everything in §1–§9 therefore describes
both builds without qualification, including the `sync_in_inverted` default of `true`.

| Check | Result |
|---|---|
| Build | `neuronSpectrum.exe` + `ns65bridge.dll` under Qt 6.11.2 / MSVC v143 14.44, with the full managed + IPP closure deployed |
| Registered tests | 20/20 enabled CTest cases passed. `ns65_bridge_smoke` stays `DISABLED` — it needs the physical device |
| Parameter contract | **28 parameters, identical to Qt 5**, SHA-256 `7c1cb2bd…6c5487`, driven by the same external controller against both binaries. Transition lists matched; a harmless write to `blockSize` was accepted and reflected by both |
| UI | Nothing to compare — the service is intentionally headless, and its parameter surface is the shared Configurator |
| Package | `validate-dist-qt6.ps1` passed with only the deployed Qt 6 runtime on `PATH`; **zero Qt 5 DLLs** in the package |

⚠ **Not repeated on hardware.** Physical acquisition, impedance, sync and trigger throughput on
the NS-65 remain lab acceptance tests; no acquisition was attempted during the port. §10's numbers
are still the only hardware evidence this driver has, and the argument that they transfer rests on
the byte-identity above rather than on a re-measurement. Full record:
`R:\src\docs\VALIDATION.md`, "2026-08-29 neuronSpectrum, mStim, and eStim validation"; parity
evidence in `R:\src\docs\qa\neuron-mstim-estim-parity.json`.

---


<a id="history-11-operating-notes"></a>

## 11. Operating notes

* **Stop before terminating.** The same rule as NVX: send `stop`, wait for `init`, then
  terminate. Any script driving it must stop it in a `finally` block.
* **Only one program can hold the device.** The vendor application and this service cannot run
  at once; `NS_Open` reports *"the device may be in use by another program"*.
* **Parameters cannot be set over the ctypes bridge** — `sendParametersToService` returns true
  and applies nothing. Use the Configurator, or `--serviceConfig <file>` at launch, which is
  what the whole validation campaign used.
* **The default montage is the 23 head electrodes.** Everything else is offered and unticked;
  the X sockets additionally need switching to referential mode on the Signal tab before they
  count as EEG.
* Parameter groups are ordered by their lowest index, so the bands are deliberate: `main`
  10–70, `signal` 110–180, `transport` 210–230. The Configurator opens on the first tab.
