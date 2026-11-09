# `eStim` — the Neurosoft electrostimulator as a Resonance service — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/estim.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-estim--the-neurosoft-electrostimulator-as-a-resonance-service"></a>


**Added 2026-08-16.** Module: `R:\src\eStim`. Service name `eStim`, launcher `eStim.bat`,
x64 only.

**Ported to Qt 6, 2026-09-02.** `eStim` is in the default Qt 6.11.2 distribution:
`R:\dist\bin\eStim.exe`, launcher `R:\dist\eStim.bat` (the Qt 6 distro has no
`msvc64\` level — `bin\` is at its root). The Qt 5.15.2 comparator is `R:\src_Qt5\eStim` →
`R:\dist_Qt5\msvc64\bin\eStim.exe`. Nothing below changed in the port: the static parameter
contract is byte-identical across the two generations and both publish the same 1×31 `status` —
see §12 and [`build_qt5-to-qt6-transition.md`](../migrations/qt5-to-qt6-transition.md).

⚠ **Read §10 before deploying to a rig.** `eStim.ini` has no install rule, so a fresh Qt 6 deploy
starts from compiled defaults — and the six working preset slots this rig actually uses, its
selected slot and its last panel state go with the file.

It is the second **actuator** in the tree, after [`neuroMS`](neuroms.md), and it is a port rather
than a new driver: the standalone `eStim` GUI has been driving this hardware at the rig, and its
window, command language and vendor-DLL wrapper come across as they are. What changes is where the
state lives.

---


<a id="history-4-presets-are-one-liners"></a>

## 4. Presets are one-liners

A preset is a snapshot of both panels plus a launch target. The standalone kept each one in
eighteen INI keys. Here it is **one line of the command language**, which is what lets it be a
single Resonance `String` parameter:

```
preset1 = F110 D200 A3 N5 PB f10 d200 a3 n5 pb TB
preset7 = F20 D200 A1 N1000 PP f20 d200 a1 n1000 pp T1
```

Two consequences, both deliberate.

**A saved service configuration loads back.** `CommunicationLayer::applyParameters` screens
parameter *names* once, up front, and rejects the rest permanently — so a parameter that only
comes into existence as a side effect of applying another one in the same set is never seen
([known-issues §16b](../incidents/33-framework-traps-found-building-playbackservice-2026-08-15.md#history-16b-applyparameters-screens-names-before-it-applies-anything--fixed-2026-08-22),
which is why a multi-stream `recorderService` configuration cannot be reloaded). Nine **fixed**
`String` parameters have no such side effect: the set that was saved is exactly the set that
exists on load. A `presetCount` → `preset1…N` shape would have walked straight into it.

**The Configurator can edit a preset.** A text field a client can read, type into and copy is
worth more than eighteen spin boxes it would have to render, and it is diffable, pasteable into a
lab notebook, and sendable over the command stream verbatim.

<a id="history-bidirectional-translation"></a>

### Bidirectional translation

| Direction | Where |
|---|---|
| panels → line | the window's **Line** box rewrites itself on every parameter change; **Save preset** commits it to the selected slot; every `parameters` record on the events stream carries the line too |
| line → panels | selecting a slot loads it; typing into the Line box and pressing Enter loads it; editing the `presetN` parameter in the Configurator loads it when that slot is the selected one; a digit `1`–`9` over any input loads and launches it |

**Optional tokens are omitted when inactive rather than written as zero.** An interphase belongs
to a biphasic shape; a pre-pulse at 0 % occupies no time whatever its width. A line that says
nothing about them means "none", and parsing one back gives exactly that. In single-stimulator
mode the lower-case half and the `T` token are omitted entirely, so a preset reads
`F10 D200 A3 N5 PB`.

**Parsing takes a base.** Loading a preset passes defaults, so an omitted token means "off";
applying a *command* passes the live values, so `A2` changes the amplitude and nothing else. Same
text, two readings, and which one is meant is the caller's business rather than the grammar's.

Copying a preset — the drag-and-drop between slot buttons — is copying one string. That is the
whole reason the form is worth having.

<a id="history-slots-7-8-9"></a>

### Slots 7, 8, 9

Pre-loaded with the three amplitude points of the Neurosoft acceptance procedure: **1 / 10 /
99 mA** at 200 µs, 20 Hz, monophasic anodic, 1000 pulses, launching on stimulator 1 (the second
unit is a 10 mA device, so 99 mA does not apply to it).

⚠ These deliver **real current up to ~99 mA**. Use them only with the calibration test load
(`Rн = 1 kΩ ±1 %` per the vendor's ТС document), never with electrodes on a person. Preset 8 and
9 need the amplitude padlock lifted first, or they clamp to the 7 mA safe cap.

---


<a id="history-8-safety-and-the-coupled-limits"></a>

## 8. Safety and the coupled limits

Enforced in `clampToLimits()`, which knows nothing about widgets — so a value arriving over the
command stream is held to the same rules as one typed into the window. The standalone enforced
them in the spin boxes alone.

| Rule | Why |
|---|---|
| frequency ≤ min(`frequencyMax`, **40 kHz**) | one 25 µs DAC sample per period is the device's physical limit; an old ini carrying 100000 is capped on load |
| duration ≤ min(cap, **period**) | duty cycle cannot exceed 100 % |
| interphase ≤ duration − 50 µs | leaves at least one DAC sample in each phase; forced to 0 for a monophasic shape |
| pre-pulse ≤ period − duration | it lives inside the gap before the pulse |
| pre-pulse % ∈ −50…50 | |
| amplitude ≤ `amplitudeMax` (7 mA) unless unlocked; 99 mA unlocked | 99 mA is the 12-bit DAC ceiling |
| duration ≤ 51200 µs unlocked | 2048 DAC samples — the largest waveform the vendor DLL accepts |

Raising the frequency shortens the period, which auto-shrinks the duration and pre-pulse caps and
pulls the values down to fit. **Every clamp is published** on `events` with what was requested and
what was applied.

**Amplitude above the cap is refused, not reduced.** `Parameters::Double::setJson` rejects an
out-of-range value, so a client that asks for 9 mA against a 7 mA cap is told no rather than
being left believing it delivered 9. This is why the parameter's `maximum` has to track the live
cap; a stale range makes the service refuse a value it would happily accept.

`unlockAmplitude` is an ordinary parameter — any client may set it. The padlock in the window
still asks for confirmation, because that is a UI affordance rather than a policy gate, and every
change goes onto `events` either way.

---


<a id="history-9-the-window"></a>

## 9. The window

The standalone window, with its state removed. Same Fusion styling, green start / red stop, the
console-coloured command monitor, the nine preset buttons with drag-to-copy, the padlocks, the
Frequency/SOA label-button, the full-width pulse schematic.

Three differences:

* **A Line box** under the presets shows the panels as a one-liner, live, and accepts one typed
  back. It is the translation made visible.
* **Shift-click a preset button stores into that slot.** Without it, aiming a Save at a slot
  other than the selected one means first clicking it — which loads it, and destroys the panels
  you were trying to save. The standalone had that wart.
* **Closing the window clears `showUi`** rather than quitting. The service goes on running
  headless; `showUi` brings it back, from the Configurator. Since 2026-09-07 the switch is no
  longer written to the ini (the same change in feetStim and arduinoTTL): every launch starts
  with the window, because a launch from a `.bat` that came up headless read as "did not
  start" to an operator.

The pulse diagram now takes a `DeviceParams` and derives every printed figure through `Timing`,
so the duty cycle and train length drawn on screen are literally the same numbers on the `status`
stream and in an `events` record. They used to be computed in the paint routine, where nothing
else could reach them.

Keyboard shortcuts are unchanged and still remappable in the ini (device 1 = `Ctrl+…`, device 2 =
`Alt+…`).

---


<a id="history-10-estimini"></a>

## 10. `eStim.ini`

Next to the executable — `<distribution>\bin\eStim.ini`. Every value in it is also a parameter;
the file exists for the two things the network cannot do: remember what the rig was set to across
a restart with nobody watching, and carry the keyboard map, which belongs to the operator's
control keyboard rather than to any session.

Precedence: defaults → this file → `--serviceConfig` → whatever a client sets at runtime. The
file is read in the constructor, which is before `ResonanceApp` applies a service configuration,
so a saved configuration always wins and nothing has to be reconciled.

**A file written by the standalone program is read and converted.** Its eighteen-keys-per-preset
sections become `line=` and are never written back in the old form, so a rig file upgrades in
place the first time the service exits. Verified against the rig's own
`dist_x64\eStim.ini`: all nine presets migrated, including the three calibration slots, and
`freqMax=100000` was capped to 40000.

<a id="history--nothing-installs-this-file-2026-09-02"></a>

### ⚠ Nothing installs this file (2026-09-02)

The path is `QCoreApplication::applicationDirPath() + "/eStim.ini"` (`service.cpp:79`) and **no
build or deploy step puts one there.** `R:\src\eStim\CMakeLists.txt` installs the executable, the
two vendor DLLs and `eStim.bat` and nothing else; `deploy-qt6.ps1` copies no `.ini`; the only
`.ini` any install rule in the tree mentions is `actiChamp/dll/ActiChamp_x64.dll.ini`. So the Qt 6
distribution had **no `eStim.ini` at all** until one was copied in from `R:\dist_Qt5\msvc64\bin\`
on 2026-09-02, and until then the compiled defaults in `settings.h` were what a launch would have
used: UDP enabled on 5005, serial 9600 with `autoOpen=false`, single-stimulator mode, and
`Settings::defaultPreset()` — six default working slots (`F10 D200 A3 N5 PB … T1`) and the three
calibration lines — in place of the rig's.

`R:\dist\bin\eStim.ini` is correct now, byte for byte the Qt 5 distribution's. ⚠ **A fresh deploy
does not reinstate it** — there is no install rule to reinstate it *with*. What a missing file
would cost is narrower than it looks, and worth stating exactly, because the reassuring half is as
useful as the alarming one. Lost: `preset1`–`preset6`, the rig's working slots — five of them at
110 Hz, all six launching `TB`, against a factory `F10 … T1` — `selectedPreset=6`, and the last
panel state, device 1 at 20 Hz, 200 µs, **7 mA**, 1000 pulses, monophasic anodic, which is the
calibration-load setup. Not lost, because the file merely restates the compiled default:
`[limits]` (`freqMax=40000` and `amplitudeMax=7` *are* the `SafetyLimits` members), the whole
`[shortcuts]` map (identical to `defaultShortcuts()`, key for key), `[serial]`, `[udp]`, and
slots 7–9, the three calibration lines the code itself ships. Copy it by hand after every deploy,
and check it is there before a session:
[`build_qt5-to-qt6-transition.md`](../migrations/qt5-to-qt6-transition.md) §8.

---


<a id="history-11-building"></a>

## 11. Building

Nothing special — it is in the top-level `CMakeLists.txt` and builds with the tree. The whole tree
is `R:\src\scripts\build-qt6.ps1`; this module alone:

```bat
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64 -vcvars_ver=14.44
chcp 65001
set PATH=C:\Qt515\Tools\CMake_64\bin;C:\Qt515\Tools\Ninja;%PATH%
cmake --build R:/src/_build --target eStim test_EStimPreset -- -j 6
```

⚠ **The existing cache is stale.** `R:\src\_build\CMakeCache.txt` still records
`For build in directory: r:/srcQt6/_build` and an install prefix of `R:/srcQt6/_dist` — it was
written before the 2026-09-02 rename. Delete `R:\src\_build` (and `R:\src\_build-kardi2-x32`, which
has the same problem) and let `build-qt6.ps1` configure again before the command above will work.

⚠ **`chcp 65001` is not optional**, for the configure and the build alike: without it ninja records
no header dependencies at all on this machine, and a later header edit then links translation units
compiled against two different class layouts ([known-issues §11c](../incidents/README.md)).
`build-qt6.ps1` sets it itself. Note also that the Qt 6 build tree lives **inside** the source tree
— `R:\src\_build` — reversing the `R:\dist\_build\<name>` rule the Qt 5 tree was written for.

The x64 gate is unchanged: `IF (WIN32 AND (CMAKE_SIZEOF_VOID_P EQUAL 8))` wraps the whole file, so a
32-bit configuration skips the module. Link targets are now `Qt6::Core Qt6::Gui Qt6::Widgets
Qt6::SerialPort Qt6::Network Qt6::StateMachine` — the last is new, because Qt 5 shipped
`QStateMachine` inside `Qt5::Core` and Qt 6 moved it into a module of its own. Deploy is
`R:\src\scripts\deploy-qt6.ps1`; the two vendor DLLs come across unchanged, installed to `bin\` by
the module's own `install_files` rule.

Building the Qt 5 comparator instead: `R:\src_Qt5\eStim`, `-vcvars_ver=14.29`, into
`R:\dist_Qt5\_build\msvc64` — [`build_qt5-to-qt6-transition.md`](../migrations/qt5-to-qt6-transition.md),
appendix.

---


<a id="history-12-verified"></a>

## 12. Verified

**Unit — `test_EStimPreset`, 23/23.** The scanner (case selects the device, whitespace optional,
negatives and fractions, unknown letters reported, missing numbers reported), the one-liner round
trip, the omission rules, base-relative parsing, every waveform and target code, the timing maths
and every clamp. All hardware-free and Qt-GUI-free by construction, because the scanner, the
translator and the couplings live in files that know nothing about a device, a widget or a
stream.

**Live — 39 checks against the running service**, reading over the EventBus and writing over the
UDP listener:

| | |
|---|---|
| Legacy ini | all nine presets converted; `preset1` → `F110 D200 A3 N5 PB f10 d200 a3 n5 pb TB` |
| Safety | `freqMax=100000` capped to 40000; `amplitude1.maximum` = 7 |
| Commands | `F55`, `A2.5`, `N100`, `PN`, lower-case `f30a1.5` → stimulator 2, chained `F20D300A3N7PB` |
| Refusal | `A9` against a 7 mA cap left 7 |
| Couplings | at 1 kHz the duration clamped to 1000 µs and its `maximum` followed; `I900` on a 200 µs pulse clamped to 150; a monophasic waveform zeroed it |
| Presets | digit `1` and `7` loaded their lines into the panels and moved the selected slot |
| Sequences | `=sF44A2D250N9PC` then `s` |
| State | `init` offers only `connect`; a start with no stimulator was refused and left the state alone |
| Bad input | `F60 Q9 A4` applied both good tokens and reported two problems |

**Streams — through the real QML plugin** (`quickStimulus.exe -l R:\config\estim_stream_harness.qml`):

| | |
|---|---|
| Announced | `@`, `events`, `status`; `discover:///?stream=events&name=eStim` resolves |
| `events` | 33 records in 22 s, covering `command`, `parameters`, `preset` load/launch, `refused`, `clamp` (9 → 7 mA), `problem` |
| `status` | **31 channels**, declared 2 Hz, 42 blocks in 22 s = **1.91 Hz** measured |
| Both translation directions | `parameters` records carry `line: "F40 D250 A2 N30 PB I40 R100 Y25"` (panels → line); the `preset` load record carries the stored line that produced the panels (line → panels) |

**Lifecycle:** `!terminate` over the bus exits cleanly and writes `eStim.ini` in the new format.

⚠ **No stimulator was attached.** The user's own standalone `eStim` was running from `N:\` for
the whole session and was left alone, so the vendor DLL's handle was never available and nothing
past enumeration is exercised: no device open, no current delivered, no train timed against a
scope. §13 is the hardware bring-up.

<a id="history-qt-6-parity-2026-08-29"></a>

### Qt 6 parity, 2026-08-29

One external controller drove the Qt 5 and the Qt 6 binary through the same protocol. The **static
contract matched exactly** — 54 parameters, SHA-256
`b84f73265ecc2cde64431813b933e04c1a767b3b3b4e0a9e96569e825ea4bf2f` — as did the transition list, and
both generations published the same **1×31 `status`** shape. A write to the frequency was accepted
and reflected by both. `qa/estim-qt5-reference.png` and `qa/estim-qt6.png` show the same panel and
control structure at a common width, with the Qt 6 solid-square checked state.

Evidence: `R:\src\docs\VALIDATION.md` (2026-08-29 section),
`R:\src\docs\qa\neuron-mstim-estim-parity.json`, and the script that produced it,
`R:\src\scripts\test-neuron-mstim-estim-parity.py`.

⚠ **Still no stimulator, in either generation.** USB discovery, the interlocks and a real pulse
remain lab acceptance work — §13 is unchanged and undone.

---


<a id="history-13-hardware-bring-up--what-to-do-when-a-stimulator-is-free"></a>

## 13. Hardware bring-up — what to do when a stimulator is free

Run these in order. Everything up to step 4 is currentless.

1. **Close the standalone `eStim`** and any other program holding the device. Check the driver is
   *Neurosoft Generic USB Driver* / `newezusb`, **not** WinUSB.
2. `eStim.bat`, then **Rescan**. The device list should offer `A1` (the 100 mA unit, USB PID
   `0x8300`) and/or `B1` (10 mA, `0x8302`). Nothing is opened until one is selected.
3. **Select `A1`.** Expect an `events` record `{"type":"device","action":"open","ok":true}` and
   the state to move `init` → `ready`. If `ok` is false the handle was refused — something else
   still holds it.
4. **Into the 1 kΩ calibration load, with a scope.** Preset 7 (1 mA, 200 µs, 20 Hz, 1000 pulses),
   Start. Expect 1 V across the load, 200 ± 5 µs wide, 50 ± 2.5 ms apart. Compare against
   `docs/calibration-presets.md` in the standalone tree for the full ТС tolerances.
5. **Check the train timer.** Preset 7 is 1000 pulses at 20 Hz ≈ 50 s. The state should return to
   `ready` on its own within ~50 s and publish `trainEnd` with `reason: "completed"`. If it
   returns early or late, the computed `trainMs` and the device disagree — that is the one number
   in this module that no test could check without hardware.
6. **Stop mid-train**, and confirm `trainEnd` with `reason: "stopped"` and that the output really
   ceases.
7. Only then, presets 8 and 9 (10 and 99 mA) with the padlock lifted, still into the load.
8. **Two stimulators**: `singleMode=false`, select both, check `TB` launches both and that the
   two channels are independent.

⚠ **Send `stop` before terminating**, as with every device service in this tree. A train left
running while the handle is released keeps firing; the destructor stops and powers down each
device, but only if it gets to run — `!terminate` does, `taskkill` does not.

---


<a id="history-14-traps-and-open-items"></a>

## 14. Traps and open items

**Found in the framework, not in this module** — both are recorded in
[known-issues §17](../incidents/README.md):

* `Parameters::Double::setMinimum`/`setMaximum` do **not** emit `triggerUpdate`, where
  `Integer`'s do, and `Select::setIndex` does not either. A range this service narrows, or an
  option it selects on the operator's behalf, is invisible to a Configurator until something
  unrelated re-broadcasts. Worked around by emitting `triggerUpdate()` from outside (`rebroadcast()`
  in `service.cpp`) — the same shape as `recorderService` emitting `performTransition` on the
  communication layer.
* `recorderService --serviceConfig` did not record a configured stream in this session, for
  `eStim` and for a `signalGenerator` control alike. A `desiredStream` with **no `name`** creates
  no dataset at all; adding `"name": "events"` creates the dataset but no messages land, while a
  QML `MessageReceiver` on the same stream receives them fine. `autoStart` in a config file also
  never fires, because the constructor reads it before the configuration is applied. Configure a
  recorder **from the Configurator** until this is chased down.

**In this module:**

* A ranged-`for` over a braced list of *different* `Parameter` subclasses does not compile —
  there is no common type to deduce. Use a `Parameter* const array[]`.
* `QVector::assign` arrived in Qt 6.6, so it **is** available in the default tree (Qt 6.11.2 defines
  `QList::assign` in `qlist.h`, and `QVector` is an alias for `QList`) and is **not** available in
  the Qt 5.15 comparator. ⚠ `service.cpp:844` still carries both the Qt 5 workaround and a comment
  reading "this tree is Qt 5.15" — the workaround is harmless and compiles in both generations, the
  comment is now false about the tree it sits in.
* `--version` / `--help` on a `WIN32` Qt app put `QCommandLineParser`'s output in a **message
  box**, which blocks a script waiting on the process.
* Presets default to the two-stimulator form even in single mode. Harmless — the lower-case half
  is ignored — but slightly noisy in the ini.
* The `data\` recordings and `R:\config\estim_stream_harness.qml` from the verification runs: the
  harness is worth keeping, the HDF5 evidence was deleted.
