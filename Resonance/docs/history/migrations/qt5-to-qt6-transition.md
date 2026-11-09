# Qt 5 → Qt 6 transition notes — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../decisions/qt6-default.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-qt-5--qt-6-transition-notes"></a>


**Written 2026-09-02, the day the trees swapped roles.** This is the decision record and the index.
It does not duplicate the porting detail — that stays in [`R:\src\docs\`](../../../src/docs/README.md),
written while the port was made.

> ## ⚠ Read this before you run anything
>
> **The two regressions that blocked `R:\dist` were closed on 2026-09-02** and the package was
> rebuilt and redeployed. `nvx136` was resynchronised from `R:\src_Qt5` and now matches the Qt 5
> build marker for marker — the falsified converter power-down is gone, `cold_start_pause_ms` is
> back. `neuroMS` carries **both** change sets: the Qt 5 `standby` state and
> `enteredOperatingState()`, merged with the Qt 6-only paired-pulse handshake fix.
> [`arch_qt6-work-list.md`](qt6-work-list.md) §1 has the evidence.
>
> ⚠ **What that does NOT mean is that Qt 6 has been on a rig.** No physical amplifier or
> stimulator has ever been driven by a Qt 6 build. The first session with an NVX-136, a Neuro-MS
> or any other device is a **bring-up**, not routine use: bring `R:\dist_Qt5\msvc64` as the
> fallback, and expect to compare against it. The NVX-136 cold start in particular is recorded as
> unproven on hardware in *both* generations
> ([`arch_known-issues.md`](../incidents/README.md) §24).
>
> Everything else in `R:\dist` — the Configurator, the recorder, playback, SignalGenerator, SPEED,
> tepSound, feetStim, arduinoTTL, mStim, eStim, KARDi2, actiChamp, Neuron-Spectrum — is at least as
> good as its Qt 5 predecessor, and in several cases repairs a defect the Qt 5 tree still ships.
>
> New on 2026-09-02: **`NVX136_2021.bat`**, an alternative NVX-136 service built from the 2021
> driver and the 2021 vendor SDK. It registers under the same service name, so it is a drop-in
> swap rather than a second service — run one or the other. See §4a.

---


<a id="history-1-the-one-paragraph-answer"></a>

## 1. The one-paragraph answer

**Qt 6.11.2 is the default.** The sources are `R:\src`, the distribution is `R:\dist`, and the
build/deploy/validate scripts are `R:\src\scripts\`. **Qt 5.15.2 lives on as the comparator**:
sources in `R:\src_Qt5`, distribution in `R:\dist_Qt5\msvc64`. The Qt 5 tree is not archived and
not frozen out of use — it is the only home of the remaining Qt 5 services, it holds the
git history, and every cross-generation parity script in the Qt 6 tree launches a binary out of it.
The two generations' services interoperate over the Resonance wire protocol, which did not change.
They must never share a process.


<a id="history-2-what-moved-on-2026-09-02"></a>

## 2. What moved, on 2026-09-02

| now | was | what it is |
|---|---|---|
| `R:\src` | `R:\srcQt6` | Qt 6.11.2 sources — **the default tree** |
| `R:\dist` | `R:\dist_Qt6` | Qt 6.11.2 distribution — **the default distro**. `bin\` is at its root |
| `R:\src_Qt5` | `R:\src` | Qt 5.15.2 sources — comparator and remaining legacy services |
| `R:\dist_Qt5` | `R:\dist` | Qt 5 distribution. The old `R:\dist\msvc64` is now `R:\dist_Qt5\msvc64` |

Untouched by the swap: `R:\dist_legacy`, `R:\dist_2026aug`, `R:\src_legacy`, `R:\src_git_branches`,
`R:\config`, `R:\tests`, `R:\docs`, `R:\equipment`.

⚠ **The distribution changed shape, not just name.** The Qt 5 distro nested the payload one level
down (`R:\dist\msvc64\bin\`) because it shipped several architectures side by side. The Qt 6 distro
has exactly one x64 payload, so `bin\`, `qt\`, `data\`, `params\`, `montages\`, `protocols\`,
`calib\`, `stimuli\` and the `.bat` launchers all sit at `R:\dist\` directly. The one nested tree is
`R:\dist\kardi2_x32\`, the 32-bit island (§6).

<a id="history-what-the-swap-already-fixed"></a>

### What the swap already fixed

* **All 92 harnesses in `R:\config`** were repointed at `R:\dist_Qt5\msvc64` and
  `R:\dist_Qt5\_build`, so the Qt 5 acceptance and oracle harnesses still run unchanged.
* **All 46 path-bearing files in `R:\src`** were repointed: the eight validation/capture scripts,
  the seven parity scripts, the six QML harnesses, two JSON configs, and the source comments.
* **The 16 git worktrees** under `R:\src_git_branches` now point at `R:\src_Qt5\.git`.
  `git worktree list` from `R:\src_Qt5` lists all of them healthy.
* **Operator content was copied into `R:\dist`** that the Qt 6 deployment had never provisioned:
  the four service `.ini` files, `bin\FrameLib\Frame1`, sixteen `params\*.json` presets,
  `montages\mumeg_mks64.ced`, and the ten-file `stimuli\` tree. See §8.
* **`build-qt6.ps1` now sets the console to UTF-8** before building — see §7, and
  [`arch_known-issues.md`](../incidents/README.md) §11c for why that is not cosmetic.

<a id="history-what-the-swap-broke-and-how-to-fix-it"></a>

### What the swap broke, and how to fix it

⚠ **Both CMake build trees are dead and must be deleted before the next configure.**
`R:\src\_build\CMakeCache.txt` records `CMAKE_HOME_DIRECTORY=R:/srcQt6`, and
`R:\src\_build\build.ninja` carries 1 174 absolute references to the old path. CMake refuses to
reconfigure a cache whose source directory has moved; `deploy-qt6.ps1 -SkipBuild` will fail on the
same cache. The next build must be a clean one:

```bash
rm -rf R:/src/_build R:/src/_build-kardi2-x32
```

then `R:\src\scripts\build-qt6.ps1` as usual (a full 203-step rebuild, plus the x86 island).
The **deployed** `R:\dist` is unaffected — it holds finished binaries and does not consult the cache.


<a id="history-3-toolchain-delta"></a>

## 3. Toolchain delta

| | Qt 5 (`R:\src_Qt5`) | Qt 6 (`R:\src`) |
|---|---|---|
| Qt | 5.15.2, `C:\Qt515\5.15.2\msvc2019_64` | **6.11.2**, `C:\Qt515\6.11.2\msvc2022_64` |
| Compiler | MSVC **v142** (VS 2026 Build Tools, toolset pinned) | MSVC **v143 14.44** / VC++ 19.44, pinned with `-vcvars_ver=14.44` |
| Windows SDK | as installed | 10.0.26100 |
| Standard | C++17 | **C++20** |
| Generator | Ninja | Ninja 1.12.1 |
| CMake | ≥ 3.21 | 3.30.5 |
| Dependencies | Conan 2 | Conan 2, profile `R:\src\profiles\msvc-v143-release` |
| Other architectures | MinGW 8.1 x86 and x64 both buildable | **x64 only**, plus the MinGW-8.1-x86 KARDi2 island |

Qt's package name *"MSVC 2022 64-bit"* denotes the v143 ABI family. It does not require the Visual
Studio IDE, and the newer Build Tools host is deliberately pinned to its installed v143/14.44
toolset rather than v145.

⚠ **There is no Qt 6 successor to the MinGW distributions.** `R:\dist_2026aug\mingw32` and
`mingw64` are archive-only. The old FieldTrip binary was x86-gated and exists in no x64
distribution; its newest binary is in `R:\dist_2026aug\mingw32\bin`. The old "two complete,
independent trees, meant to be run side by side" story in
[`build_and-distro.md`](and-distro.md) §1 was about x86 vs x64 and no longer describes the
default distribution.


<a id="history-4-what-crossed-and-what-did-not"></a>

## 4. What crossed, and what did not

**Ported — 21 executable files (20 applications plus the KARDi2 broker), 28 launchers at `R:\dist\`:**

`quickStimulus` (Configurator + Generator + legacy Recorder), `nvx`, `nvx136`, `actiChamp`,
`neuronSpectrum`, `neuroMS`, `SignalGenerator`, `recorderService`, `playbackService`,
`playbackSource`, `SPEED` (with a private Python 3.12.1 / NumPy 1.26.2 / SciPy 1.11.4 runtime),
`feetStim`, `arduinoTTL`, `mStim`, `eStim`, `tepSoundService`, `eyeLink`, `COMport`,
`latencyProbe`, `DAQmx`, `fieldtrip`, `stimulusService`, plus `KARDi2` through an x86 broker —
all on a Qt 6 `Core/Resonance`, with `scriptEngines/pythonEngine` and `ResonanceForeignDriver`.

**No active service is left unported.** `stimulusService` was the last, ported as the native x64
**Stimulus** service on 2026-09-06; DAQmx and FieldTrip took the same route on 2026-09-05 (NI
runtime/device support remains external). `tepService` is retired in favour of `tepSoundService`;
its Qt 5 binary remains only as a comparator. What the lab still depends on Qt 5 for — the 18
legacy `sp_*.qml` paradigms and the parity oracles — is in
[`arch_qt5-still-needed.md`](qt5-still-needed.md).

**In neither tree's active build:** `eyeTribe` (commented out of the Qt 5 root because it was never
brought to the current Resonance API), `openBCI` (Qbs only), and the `DemoApp` / `fileConverter` /
`SaveLib` / `Tests` / `Documentation` / `*.qbs` era.

**Deployed-only, source-less, and therefore not reproducible from either tree:**
`R:\dist_Qt5\msvc64\bin\emulator.exe` (2 127 872 bytes, 2025-07-24). `test-device-service-parity.py`
requires it. It is one of the concrete reasons `R:\dist_Qt5` cannot be deleted.


<a id="history-4a-nvx136_2021--the-other-driver-generation-as-a-swap"></a>

## 4a. `NVX136_2021` — the other driver generation, as a swap

Added 2026-09-02. `R:\dist\NVX136_2021.bat` starts an NVX-136 service built from the 2021 driver
and linked against the **2021** vendor SDK. It exists so the cold-start question can be
answered by comparison rather than by argument: the mainline driver makes nine device transactions
before `NVXStart`, the 2021 one makes four —
`NVXOpen → NVXSetSettings → NVXSetAuxGain → NVXSetPll → NVXStart → NVXGetProperty`.

Every source file in `R:\src\nvx136_2021` except `main.cpp` is **byte-identical** to
`R:\src_git_branches\feature-conan2\nvx136`. `main.cpp` differs only in the service name
(`NVX136_2021`) and in testing `--emulation` with `isSet()` rather than `value().isEmpty()`, which
is what makes it runnable without hardware at all. ⚠ **Do not "improve" anything in that
directory** — its value is that it is not the current driver.

⚠ **Both SDK generations ship a DLL called `NVX136.dll`**, and they have incompatible impedance
frame layout, hardware channel disable and trigger byte handling. The pairing is enforced by layout,
not by discipline: the 2021 executable installs into its own `bin\nvx136_2021\` with its own copy of
the 2021 DLL and the three bitstreams beside it, and Windows searches the application directory
before `PATH`. Verified on the deployed package — `nvx136.exe` loads
`R:\dist\bin\NVX136.dll` (md5 `4b4bdda0…`, 2025) and `nvx136_2021.exe` loads
`R:\dist\bin\nvx136_2021\NVX136.dll` (md5 `2c18ba10…`, 2021). That is also why
`NVX136_2021.bat` does `cd` into that directory before starting: launch it from anywhere else and
it binds the wrong DLL.

⚠ **Both executables register as `NVX136`, and that is deliberate.** Every saved parameter file,
harness, protocol and `ServiceControl` client that names `NVX136` drives whichever one is running,
so swapping generations is stop-one/start-the-other and nothing else on the rig changes. It also
means **RUN ONE OR THE OTHER, NEVER BOTH** — two services answering to one name on one bus is an
ambiguity, not a comparison. The launcher keeps the `_2021` suffix so the operator can still tell
them apart where the choice is made.

Both start from the **same shipped defaults** (§4b), which is the other half of what makes the
comparison readable. Full detail: `R:\src\nvx136_2021\README.md`, installed beside the executable.


<a id="history-4a-bis-nvx136_2021-is-now-a-row-for-row-panel-mirror-of-the-mainline"></a>

## 4a-bis. `nvx136_2021` is now a row-for-row panel mirror of the mainline

**2026-09-03.** A comparator that presents a different panel from the build it is compared against
is a second instrument, not a control. `nvx136_2021` published 13 parameters in four groups
(`default`, `adc`, `trigger`, `pulse`) where the mainline publishes 21 in three (`main`,
`hardware`, `trigger`). It now publishes the same 21, in the same groups, at the same indices, with
the same labels, descriptions and **option strings**.

⚠ **Option strings are part of the contract, not decoration.** `Parameters::Select` serialises its
option *label*, so `"1000 Hz (all channels)"` and `"1 kHz (all channels)"` are different values on
the wire — a saved parameter file could not load into both builds, which is most of what a
comparator is for. Four option lists were aligned (`samplingRate`, `mode`, `aux_gain`,
`adc_synchronization_source`) plus the runtime-generated `device` labels
(`"Device #0"` → `"Media converter #0"`).

Checked by `scripts\nvx136-parity-check.qml`, which asks both services over the bus and compares
name, group, index, label, type and option list row by row: **21/21, nothing only in one side.**

<a id="history--six-rows-are-present-and-disabled-and-that-is-the-design"></a>

### ⚠ Six rows are present and DISABLED, and that is the design

The user asked for parity "except for SDK". These are the exceptions, each greyed with its reason
in its own tooltip — and since "Hide disabled options" was removed on 2026-09-02 a disabled row
stays on screen and readable, which is exactly what is wanted here:

| parameter | why it is inert in the 2021 build |
|---|---|
| `device_mask` | the 2021 SDK has no `NVXGetDevices` / `NVXSetDevices` / `NVXSelectDevice` |
| `sync_pulse_period`, `sync_pulse_duration` | the 2021 SDK has no `NVXSyncPulseSetParam` |
| `power_save`, `active_shield_gain`, `disable_unused_channels` | the calls **do** exist in the 2021 SDK, but applying them would add a device transaction between `NVXOpen` and `NVXStart` |
| `cold_start_pause_ms` | the 2021 driver has no cold-start recovery to pause in — it has never needed one |
| `battery` | **not** an SDK limitation: `NVXGetVoltages` is in both. Left unwired only because no NVX-136 was available to test the extra device call, and this build's value is that it starts reliably |

⭐ **The third row is the important one.** This build exists because it **starts on the first
attempt** where the mainline needs a second, and the mainline's own driver names the mechanism:
*"Every call in this gap is a device transaction and the failing `NVXStart` times out on one."*
Wiring those three would lengthen exactly that gap. Panel parity is worth a lot; it is not worth
re-introducing the failure the comparator exists to isolate.

⚠ **The pre-change sources are preserved** at
`R:\src\_patches\nvx136_2021-working-20260903\`, with a `PROVENANCE.md` giving the restore command.
They are the last version proven on hardware to launch first-try. If tomorrow's lab session shows
the parity build no longer does, that directory is the control — and the parity change touches no
start/stop logic, only parameter declarations, which was confirmed by rebuilding the preserved
sources and getting identical state-machine behaviour from both.


<a id="history-4b-the-nvx-136-shipped-starting-point-moved-into-the-service"></a>

## 4b. The NVX-136 shipped starting point moved into the service

Added 2026-09-02. A fresh NVX-136 launch — either generation — now comes up on **1 kHz, block
50, the first 64 EEG channels plus the trigger, and `mks64_standard.ced`**. The values live in
`R:\src\nvx136\nvx136defaults.hpp` and are asserted by `test_Nvx136Defaults`.

They used to live in `params\nvx136_default64ch.json`, applied by `NVX136.bat` through
`--serviceConfig`. That had three problems and all three bit:

* it only worked for launches that went through the launcher. Started from the Configurator, from
  a harness or by double-clicking the exe, the service came up on bare code defaults — which is
  how the 2021 variant ended up with no channels selected while the mainline had 64;
* `--serviceConfig` is applied **after** the constructors, and `applyParameters` screens names
  against parameters that already exist, so a saved config cannot fill a channel list whose shape
  it has not seen;
* a selection is refused outright if its length does not match the device's channel count.

The preset is still installed in `params\` as an example to load by hand; it is no longer applied
automatically, and `NVX136.bat` no longer passes `--serviceConfig`. Verified on the deployed package
with `scripts/nvx136-defaults-probe.qml`, which reads the service off the bus rather than the
source: `1 kHz`, block `50`, 4581 bytes of CED, `65/137` channels.


<a id="history-5-where-qt-5-is-structurally-necessary"></a>

## 5. Where Qt 5 is structurally necessary

Short answer: **`R:\src_Qt5` and `R:\dist_Qt5` cannot be deleted.** Four independent reasons —
detail and severity in [`arch_qt5-still-needed.md`](qt5-still-needed.md):

1. ~~**KARDi2's vendor DLL is PE32/i386 only.**~~ Closed 2026-09-02: the x64 Qt 6 service talks
   to a small `/MT` x86 broker, so no Qt 5 runtime ships inside the Qt 6 distribution (§6).
2. ~~**The one active unported service**: `stimulusService`.~~ Closed 2026-09-06: Stimulus is
   native Qt 6, as DAQmx and FieldTrip have been since 2026-09-05. No active service remains on Qt 5.
3. **The 18 legacy `sp_*.qml` experiment programs** (28 899 lines, ~800 Qt Quick Controls 1
   instantiations) that non-TMS paradigms run through `quickStimulus --load`. Qt 6 ships no
   Controls 1 in any form, and these are QML loaded *into* the host process, so a mixed rig does
   not help. This is the single hardest blocker to ever retiring the Qt 5 distribution.
4. **Comparator and oracle dependencies**: seven parity scripts launch `R:\dist_Qt5\msvc64\bin\*.exe`
   as the reference generation, the MATLAB topoplot oracle CSVs live in `R:\dist_Qt5\_build\topo-ref`,
   and `emulator.exe` exists nowhere else.


<a id="history-6-kardi2--the-island-is-gone-an-x86-broker-replaced-it"></a>

## 6. KARDi2 — the island is gone; an x86 broker replaced it

**Superseded on 2026-09-02.** `R:\dist\kardi2_x32\` no longer exists, and neither does
`R:\src\KARDi2\qt5-island`'s role in the build. What replaced it:

| | Until 2026-09-02 | Now |
|---|---|---|
| Service | PE32 `KARDi2.exe`, Qt 5.15 / MinGW | **x64 `KARDi2.exe`, Qt 6.11.2 / MSVC**, in `bin\` like every other service |
| Resonance core | A **second, separately compiled** Qt 5 `libResonance.dll` | The one `Resonance.dll` every service uses |
| Vendor DLL access | In-process — the whole service had to be x86 because the DLL is | A **164 KiB x86 broker** process, `kardi2-broker-x86.exe`, over framed anonymous pipes |
| Qt DLLs in the distribution | Four x86 Qt 5.15 DLLs | **None.** The broker links `/MT` and imports only `KERNEL32.dll` |
| Launcher | `KARDi2.bat` entered a private environment island | `KARDi2.bat` is an ordinary service launcher |
| Build | `scripts\build-kardi2-x32.ps1`, a second Conan profile and toolchain | `scripts\build-qt6.ps1` builds the broker, then the tree |

This removes the whole second-core maintenance problem the old §6 described. `qt5-island` survives
only as `KARDi2\_legacy\qt5-island`, kept for reference, in **no** build.

⚠ **Two things the changeover nearly lost, both now handled, both worth knowing about:**

1. **The USB kernel driver is not a build output.** `driver\{amd64,i386}\McsUsb30.sys` used to reach
   the distribution as a passenger inside the island's `runtime\`. When the island went, the driver
   silently went with it and `R:\dist` shipped for a time with no way to enumerate a KARD on a
   fresh machine. `deploy-qt6.ps1` now stages it explicitly from `KARDi2\_legacy\3dparty\Driver`
   into `R:\dist\driver\kardi2\`, which is the only copy in the repository.
2. **The broker is a build INPUT to a target that cannot build it.** It is a different architecture,
   and one CMake configure produces one. `KARDi2/CMakeLists.txt` used to `message(FATAL_ERROR)` when
   it was missing — while being processed by `add_subdirectory` from the top-level configure, so a
   machine that had never run the island build got **zero binaries for the entire Qt 6 tree**, and
   the obvious recovery was circular. It now warns and `return()`s in-tree (fatal only in standalone
   mode), and `build-qt6.ps1` builds the broker in its own x86 environment before configuring.
   Proven by moving `KARDi2\_build-x86` aside and building from scratch.

Full architecture, protocol framing and the crash-safety gap: [`service_kardi2.md`](../components/kardi2.md).


<a id="history-6a--the-parameter-column-is-300-px-this-is-a-contract"></a>

## 6a. ⭐ The parameter column is 300 px. This is a contract.

**The Configurator's left-hand parameter column is 300 pixels wide, and every service's parameter
editors are designed to fit inside it.** Written down here so it stays decided:

* `Configurator.qml` — parameters pane, `SplitView.preferredWidth: 300` **and**
  `SplitView.minimumWidth: 300`. The pane may be dragged wider for comfort; it can never be
  narrower than the width the services were laid out against.
* `ParametersView.qml` — `labelColumnWidth: 130`, **pinned** (`preferredWidth` == `minimumWidth`
  == `maximumWidth`), and the scroll content's `implicitWidth` is `sv.availableWidth`, full stop.
  Controls get `Layout.fillWidth = true` and `Layout.minimumWidth = 0`, so they take the whole
  remainder and can shrink.
* The budget at 300 px: **130 px label column + 6 px spacing + ~46 px of editor chrome = 182 px of
  overhead**, leaving roughly **118 px of editor text**.

<a id="history--the-label-column-is-130-px-in-every-tab-of-every-service--2026-09-06"></a>

### ⭐ The label column is 130 px in every tab of every service — 2026-09-06

**Pinned, not capped.** Column 0 is exactly 130 px everywhere, so the editors in every service
start at the same x and are the same width. Before this, the column sized to each tab's own
labels: `SPEED`, whose labels are "Engine" and "Code", got a ~65 px column and unusually wide
editors, while `neuronSpectrum` got ~130 px and narrow ones. Every panel in the distribution had
its own geometry, and clicking between services made the controls jump.

⚠ **The cost is real and was the reason this was rejected the first time it was tried**: a tab
whose labels are all short now carries 130 px of column it does not need, and its controls are
correspondingly narrower. That trade was made deliberately on 2026-09-06 — consistency across
services is worth more than a few wider editors on the tabs with terse labels.

**A label that does not fit wraps to a second line.** It is not elided: a label nobody can read in
full is worse than a row two lines tall. Of the **276 labels in the distribution, 11 wrap** and
none needs a third line.

⚠ It was 24. Thirteen were shortened on 2026-09-06 — nine in `neuroMS`, two in `nvx`, one each in
`nvx136` and `latencyProbe` — and where the label had been carrying the only explanation, that
sentence moved into the description rather than being dropped. **Every one of the eleven that
remain is in a service under label parity** (`neuronSpectrum` 8, `tepSoundService` 2, `fieldtrip`
1), so they wrap by necessity, not by neglect.

| service | labels | widest | median | wraps |
|---|---|---|---|---|
| tepSoundService | 125 | 145 | 60 | 2 |
| neuroMS | 27 | 129 | 93 | — |
| neuronSpectrum | 27 | 237 | 102 | 8 |
| nvx136 | 20 | 124 | 83 | — |
| nvx | 13 | 123 | 57 | — |
| playbackService | 13 | 109 | 47 | — |
| latencyProbe | 12 | 118 | 82 | — |
| recorderService | 8 | 119 | 92 | — |
| COMport | 7 | 112 | 50 | — |
| DAQmx | 6 | 113 | 57 | — |
| SignalGenerator | 6 | 86 | 57 | — |
| SPEED | 5 | 122 | 56 | — |
| actiChamp | 5 | 106 | 57 | — |
| fieldtrip | 2 | 132 | 132 | 1 |

(estimated px at the default UI font; `scripts\measure-parameter-widths.qml` measures exactly)

**Writing a label: aim for 22 characters.** That is about 130 px. Past it the row grows a second
line, which is allowed but should be the exception — put the explanation in the description, which
is rendered as a wrapped tooltip and has no width problem. See
[architecture.md](framework-evolution.md#history-descriptions-tooltips--write-them-long-render-them-narrow).

⚠ **Do not reword labels in `neuronSpectrum`, `mStim` or `eStim` without checking parity.**
`scripts\test-neuron-mstim-estim-parity.py` compares **labels** between the Qt 5 and Qt 6 builds,
and the Qt 5 tree is frozen. A rewording on the Qt 6 side alone fails that gate. This is why the
long labels in those services were left to wrap rather than shortened.

Verified on 2026-09-06 by capturing `neuronSpectrum` (long labels), `neuroMS` (longest), and
`SPEED` (shortest) in `docs\qa\param-column\pinned-row*.png`: controls start at the same x in
all three, and the wrapped rows are legible.

**The rule for service authors: a long option is not a reason to be wider.** Text that does not fit
is elided in the row and shown in full in the drop-down popup — which is allowed to be wider than
the control, up to 420 px — and in the parameter's tooltip. Nothing about how wordy one service's
options happen to be may change the width of the panel every other service is drawn in.

What this replaced: `implicitWidth: Math.max(sv.availableWidth, layo.implicitWidth + 6)`, plus a
`ComboBox` that Qt sizes to its current item. One option — NVX's
`"10 kHz (select any 24 EEG channels)"`, 186 px of text on its own — set the width of a whole panel,
so **every service had its own effective width** depending on its wordiest string, and a horizontal
scroll bar appeared inside the panel. Three strings were also shortened at the source rather than
merely elided, because they were long by accident rather than by need:

| Service | Was | Now |
|---|---|---|
| KARDi2 | `"250\tHz"` — a tab, drawn as a wide gap: 94 px | `"250 Hz"`, 35 px |
| NVX | `"10 kHz (select any 24 EEG channels)"` | `"10 kHz (24 EEG max)"` |
| NVX | `"50 kHz (only 4 channels of Ch 1-8)"` | `"50 kHz (4 of Ch 1-8)"` |
| nvx136, actiChamp | `"250  Hz"` and friends, padded with extra spaces | single-spaced |

⚠ **`Parameters::Select` serialises its option LABEL, not its value.** Renaming an option is a wire
change: saved parameter files, and every QML harness that sends
`{ name: "samplingRate", serialized: "1000\tHz" }`, must be updated with it. Nine harnesses were
repointed alongside the KARDi2 change; no saved `.json` under `R:\dist\params` carried the old form.

Verified by `scripts\capture-parameter-column.ps1`, which starts the services and captures the
Configurator with each one selected; the images are in `docs\qa\param-column\`.


<a id="history-6b-hide-disabled-options-is-gone-parametervisible-replaced-it"></a>

## 6b. "Hide disabled options" is gone; `Parameter::visible` replaced it

The Configurator carried a **"Hide disabled options"** checkbox, **on by default**, which erased
every disabled parameter from the panel. It is removed. Greying out is the whole of the signal now.

It had to go because "cannot be changed right now" and "does not apply to you" are different
statements, and one switch was answering both. In KARDi2 it hid the **sampling rate** during
acquisition — a value an operator very much needs to be able to read while recording. In neuroMS it
emptied an entire hardware tab, which is why those parameters are held `readOnly` rather than
disabled (see `neuromsconfig.cpp`). Services were contorting their own state to work around a
client-side display switch.

**The replacement is `Parameters::Parameter::visible`** — a real property on the parameter, mirroring
`readOnly`, published on the wire as `"visible"` and defaulting to `true`. A client that does not
send the key is read as visible, so old and new generations mix safely. A service now says outright
which editors apply to the mode it is in:

```cpp
// nvx/application.cpp — the bipolar-pairs list is gated by the MODE, not by a disabled button.
connect(mode, &Parameters::Select::valueChanged, this, [this]() {
    const bool bipolar = mode->value() == ModeBipolar;
    channelsBipolar->setVisible(bipolar);
    channelsBipolar->setEnabled(bipolar);
    channelsUnipolar->setVisible(!bipolar);
    channelsUnipolar->setEnabled(mode->value() == ModeUnipolar);
});
```

Measured against the connected NVX-52 by `scripts\nvx-mode-visibility-probe.qml`:

| Mode | Bipolar pairs | Channels |
|---|---|---|
| Unipolar | hidden | visible, enabled |
| Bipolar | **visible, enabled** | hidden |
| Impedance | hidden | **visible, greyed** — you can read the montage, not change it |

⚠ `Parameter::setVisible` must `emit triggerUpdate()` as well as `visibleChanged()`. Without the
former the new value never leaves the process and no panel ever hears about it — the same trap
`setEnabled` and `setReadOnly` have.

⚠ `ChannelsList` and `BipolarChannelsList` painted every colour from a hard-coded hex literal, with
no palette or `enabled` awareness, so a disabled list rendered at full contrast while silently
swallowing clicks. That was survivable only while "Hide disabled options" removed them from sight
altogether. Both now carry `opacity: enabled ? 1.0 : 0.45`.


<a id="history-7-behaviour-and-api-changes-a-maintainer-will-hit"></a>

## 7. Behaviour and API changes a maintainer will hit

**Framework (`Core/Resonance`).** The port is remarkably small: five source files differ from the
Qt 5 core. `QRegExp` → `QRegularExpression` (a character class, no anchoring exposure),
`splitRef` → `split`, `QTextStream::setCodec` → `QStringConverter`, and a `Q_PROPERTY` type had to
be namespace-qualified for Qt 6's moc. **The whole wire path is byte-identical** — `jsonprotocol`,
`StreamInfo`, `MetaData`, `transmittabletype`, all of `TransmittableTypes/` and `Protocol/`,
`blockStreaming`, the TCP sender/receiver, `StreamPool`, `communicationlayer`, `servicediscovery`,
`servicecontrol`, `recorder`, `parameterapply`, every `Parameters/*.cpp`, and the vendored THIR.
That is why interop works.

⚠ **One deliberate format change: the HDF5 recorder.** The Qt 5 recorder creates every numeric
dataset with an initial extent of 1 and extends to `offset + samples + 1`, so **every Qt 5 recording
ends with one all-zero row that was never written** — a fabricated falling edge on a trigger
channel and a reset on a counter channel. The Qt 6 recorder starts at 0 and extends to
`offset + samples`, so the row count is exactly the sum of the block sample counts. A Qt 6 recording
is therefore **one row shorter** than the Qt 5 recording of the same data. Any analysis calibrated
on the old behaviour — anything that drops the last row to compensate — must be re-checked, or it
will now discard one real sample per stream. The fix has *not* been back-ported to `R:\src_Qt5`.

**QML and the Configurator.** Qt Quick Controls 1 → Controls 2 wholesale; the service tree
reimplemented on Qt 6 `TreeView` preserving the two-column name/recording behaviour; every parameter
editor reimplemented (file, numeric, choice, channel, bipolar, boolean, text, stream, action);
`Qt.labs.settings` → `QtCore.Settings`; Fusion style selected before application construction and a
fixed light palette forced, so the UI no longer flips with the Windows dark-mode setting. Measured
density decisions: 18 px service and channel rows, 13 px check marks with a solid 7 px inner square,
24 px bipolar rows, a 200 px default service pane, 760×600 minimum and 1200×850 default.

**Two Qt 6 behaviours found the hard way, in the field:**

* **QML `XMLHttpRequest` cannot write local files** in Qt 6 without `QML_XHR_ALLOW_FILE_WRITE`. The
  Configurator's parameter Save/Load ran on a synchronous `file://` PUT and silently did nothing.
  Replaced by checked C++ persistence with an atomic `QSaveFile` replacement and strict JSON
  validation. Full mechanism: `R:\src\docs\PARAMETER_FILE_PERSISTENCE.md`. ⚠ The Qt 5 tree still
  has the unchecked, non-atomic version.
* **A nested `QJsonValue` becomes an opaque V4 wrapper** once it crosses a QML JavaScript function
  boundary, even though a direct QML expression can read it. That made stream connectors keep
  showing `>> Drag stream here <<` over a live connection. Replaced by a registered C++
  `StreamDisplayFormatter`. Full mechanism: `R:\src\docs\STREAM_CONNECTOR_LABEL.md`.

**Multimedia.** `QAbstractVideoSurface` is gone; `tepSoundService` counts decoded frames at a
`QVideoSink` and attaches an explicit `QAudioOutput` (Qt 6 decodes without playing otherwise). The
Qt 6 bundled FFmpeg backend is pinned unless the operator overrides it; the Qt 5 Media
Foundation/DirectShow selector was not carried across. ⚠ The cue **onset contract** is the part of
this that is not yet proven equivalent — see [`arch_qt6-work-list.md`](qt6-work-list.md) §2.

**Build.** ⚠ `chcp 65001` **must** be in effect for both the CMake configure and the ninja build.
Ninja recognises a header dependency by string-matching `cl.exe`'s *localized* `/showIncludes`
prefix against the one CMake probed at configure time. This machine's OEM code page is 866, so a
build left at the default records **no header dependencies at all**, and a later header edit relinks
translation units compiled against two different class layouts — it links cleanly and faults at run
time. `build-qt6.ps1` now sets this itself. It does not apply to the MinGW x86 island: GCC writes
real `.d` files. [`arch_known-issues.md`](../incidents/README.md) §11c.

⚠ **The Qt 6 build happens inside the source tree** — `R:\src\_build`, `_build-kardi2-x32`, `_dist`,
`_stage`, `_test-output`, `_patches`. This reverses the standing "build output never goes in the
source tree" rule that `R:\dist\_build\<name>` was written for. It is deliberate (the port's root
`CMakeLists.txt` says *"Everything produced by this project stays below"* the source root) and it is
what keeps the two generations from sharing a cache. Stated here so it is not rediscovered.


<a id="history-8-operator-migration-checklist"></a>

## 8. Operator migration checklist

Before a rig runs off `R:\dist`:

| | |
|---|---|
| Service `.ini` files | **done 2026-09-02.** `arduinoTTL.ini`, `eStim.ini`, `feetStim.ini`, `mStim.ini` copied from the Qt 5 distro into `R:\dist\bin\`. ⚠ Without them the compiled defaults apply, and `feetStim` in particular would open COM4 and drive the real solenoid array instead of running the rig's emulator configuration. |
| feetStim frame library | **done.** `R:\dist\bin\FrameLib\Frame1` — the stimulation pattern itself. It exists in no source tree; the Qt 5 distro was its only copy. |
| Parameter presets | **done.** `R:\dist\params\` now holds all 19, including the nine `ns65-*.json` Neuron-Spectrum sets and `nvx136_64ch_8emg_25kHz.json` (the validated 25 kHz / 70-channel configuration). |
| Montages | **done.** `mumeg_mks64.ced` added — `R:\dist\montages\` now holds nine against the Qt 5 distro's three, so six are Qt 6-only. |
| Stimulus library | **done.** `R:\dist\stimuli\` (library.json, `mediacheck\`, two protocols) copied. Carried for parity at the time; since 2026-09-06 it is the native Qt 6 Stimulus service's own content ([service_stimulus-presentation.md](../components/stimulus-presentation.md)). |
| `bin\Resonance\**` and `resonance.cfg` | user-editable configuration in both distributions. ⚠ Do **not** carry a Qt 5 `bin\Resonance\*.qml` forward — Controls 1 QML will not load. |
| `RESONANCE_RECORD_PATH` | still set by the distribution's own `env.bat` to its `data\`. Launch through the `.bat` launchers, or recordings fall into whatever directory started the process. |
| Missing launchers | `epochDemo.bat` and `emulator.exe` do not exist in `R:\dist`. `stimulusService.bat` arrived with the port on 2026-09-06, DAQmx.bat and fieldtrip.bat on 2026-09-05. The retired `tepService.bat` remains in the comparator only. |
| Network mode | unchanged: `loopback` by default. A multi-PC rig needs `--networkMode lan` on **every** participating launcher, in both generations. [`arch_network-isolation.md`](network-isolation.md). |
| Deploy safety | ⚠ `deploy-qt6.ps1` overwrites `params\`, `protocols\`, `montages\` and `calib\` from source and takes **no** `bin.pre-*` rollback copy, unlike the visible Qt 5 practice. Take one by hand before deploying over a rig configuration. |


<a id="history-9-interop-rules"></a>

## 9. Interop rules

Verified in both directions, with isolated per-process Qt environments: the Qt 6 Configurator
discovers and fully drives running Qt 5.15 services (`nvx`, `SignalGenerator`, `recorderService`,
`playbackService`), and the Qt 5.15 Configurator discovers and drives the Qt 6 instances. Evidence:
`R:\src\docs\qa\qt6-configurator-discovers-qt5-services.png`,
`qt5-configurator-discovers-qt6-services.png`, `interop-qt5-nvx-qt6-configurator.png`.

Three rules:

1. **Process-level only.** Qt 5 and Qt 6 DLLs, plugins and `Resonance.dll` binaries must never be
   loaded into the same process. A Qt 6 application links the Qt 6 Resonance library and talks to a
   Qt 5 process over the protocol.
2. **Both generations must agree on network mode.** Loopback works for two processes on this PC.
   Across machines, every launcher on both sides needs `--networkMode lan`.
3. ⚠ **`env.bat` has no `setlocal`.** Qt 6 plugin and QML paths leak into any Qt 5 launcher run from
   the same console afterwards. Use a fresh console per generation.

⚠ One sharp exception to the mixed-rig story: the Qt 5 `stimulusService`'s `DeviceController`
launches amplifier `.bat` files **relative to its own distribution root**. A Qt 5 `stimulusService`
asked to start an amplifier will start the *Qt 5* one — a second, competing service against the
Qt 6 one already running. The Qt 6 Stimulus (2026-09-06) has no device orchestration, so it cannot
do this.


<a id="history-10-what-is-validated-and-what-is-not"></a>

## 10. What is validated, and what is not

The Qt 6 port carries its own evidence: `R:\src\docs\VALIDATION.md` for the record,
`R:\src\docs\qa\` for the artefacts, `R:\src\docs\PORTING_LOG.md` for the decisions. Read those for
detail. The boundary, stated here so it is not lost:

* **Software-level parity is well evidenced** for feetStim, arduinoTTL, mStim, eStim,
  Neuron-Spectrum, KARDi2 and SPEED — external scripts drove the Qt 5 and Qt 6 binaries through the
  same protocol and compared parameter contracts, transitions and live status shapes.
* **No physical amplifier or stimulator was driven under Qt 6.** Acquisition, impedance, trigger
  I/O, sustained throughput, stop/restart and unplug/replug remain laboratory acceptance work for
  every device. `R:\dist_Qt5\msvc64` stays the acceptance reference for live-amplifier throughput
  until that session happens. The exception is KARDi2 and arduinoTTL, which were run against real
  hardware on 2026-09-02 — `R:\src\docs\KARDI2NP_ARDUINOTTL_HARDWARE_VALIDATION_2026-09-02.md`.
* **There is no evidence that a Qt 6 recording is numerically identical to a Qt 5 one.** The
  closest thing is the SPEED filter round-trip (0.0838 % against the theoretical gain), which is a
  Qt-6-internal check, not a cross-generation one. Given the HDF5 row-count change in §7, an
  explicit comparison is owed.
* ⚠ **The Core/Resonance and quickStimulus unit-test corpora are built but never registered with
  CTest**, so the shared framework — the component everything else links — has zero coverage in the
  runs quoted as the port's evidence. [`arch_qt6-work-list.md`](qt6-work-list.md) §4.


<a id="history-11-where-the-documents-live-now"></a>

## 11. Where the documents live now

| | |
|---|---|
| [`arch_qt5-still-needed.md`](qt5-still-needed.md) | the gap list — every place Qt 5 is still required, and what each would cost to close |
| [`arch_qt6-work-list.md`](qt6-work-list.md) | the prioritised further-work list from the 2026-09-02 audit |
| `R:\src\docs\README.md` | the port's own scope, run and rebuild instructions |
| `R:\src\docs\PORTING_LOG.md` | every migration decision, dated |
| `R:\src\docs\VALIDATION.md` | the evidence record |
| `R:\src\docs\REMAINING_PORTS.md` | the port's own inventory of what it left behind |
| `R:\src\docs\qa\` | logs, parity JSON, screen captures |
| `R:\src_Qt5\docs\` | ⚠ a stale 2026-08-26 copy of **this** doc set. `R:\docs` is authoritative. Delete it. |

---


<a id="history-appendix--the-qt-5-comparator-in-practice"></a>

## Appendix — the Qt 5 comparator, in practice

**Running a Qt 5 service:** `R:\dist_Qt5\msvc64\<name>.bat`, exactly as before the rename.

**Comparing the two generations:** the parity scripts under `R:\src\scripts\` default to
`--reference R:\dist_Qt5\msvc64` and `--target R:\dist`, so they work unchanged:

```bash
py -3.12 R:/src/scripts/test-neuron-mstim-estim-parity.py
```

`test-device-service-parity.py`, `test-actichamp-parity.py`, `test-kardi2-parity.py`,
`test-speed-schema-parity.py`, `test-tepsound-parity.py` and
`R:\src\scripts\validate-qt5-interop.ps1` follow the same shape.

**Building the Qt 5 tree:** `R:\src_Qt5` still builds into `R:\dist_Qt5\_build\<name>` and deploys
to `R:\dist_Qt5\<name>` — the old convention, described in
[`build_and-distro.md`](and-distro.md). Nothing about it changed except the two path prefixes.

**Its git repository** is at `R:\src_Qt5\.git`, on branch `feature/services-and-isolation`, HEAD
`fae69c3`, with 14 uncommitted working-tree changes under `neuroMS/`, `nvx136/` and `scriptEngines/`.
⚠ Those 14 changes are the only record of what the Qt 6 snapshot was actually taken against, and
several of them are the rig-driven fixes the Qt 6 tree is still missing. Do not discard them.
`R:\src` has **no** repository at all — see [`arch_qt6-work-list.md`](qt6-work-list.md) §5.
