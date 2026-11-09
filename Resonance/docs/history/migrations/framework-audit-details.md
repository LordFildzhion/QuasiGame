# Framework audit details retained from the reference rewrite

Status: historical supplement. Added during the documentation preservation review, 2026-09-15.

Historical observations from the August–September 2026 audit. Counts, tree comparisons and measurements apply to their recorded dates. The five-file comparison below corrects a six-file claim in the transition narrative; it is not a claim that the two current cores remain identical.

[Current guidance](../../architecture/framework.md)

## 2026-09-02: five-file core comparison and corrected sixth-file claim

Provenance: original `arch_architecture.md` lines 6–37. The following is preserved source text.

**Status 2026-09-02 — this document is version-independent, and that is the point.** `R:\src` is
now the Qt 6.11.2 tree and `R:\dist` the Qt 6 distribution; the Qt 5.15.2 comparator is
`R:\src_Qt5` / `R:\dist_Qt5\msvc64`
([`build_qt5-to-qt6-transition.md`](qt5-to-qt6-transition.md)). **§1–§8 and §10–§11c describe
the framework, and the port changed none of them.** A full `diff -r` of the two cores on 2026-09-02
returns **five differing source files**, and it is worth naming all five because the list is the
whole argument:

| File | What differs |
|---|---|
| `Parameters/stream.hpp` | two `Q_PROPERTY` types namespace-qualified (`StreamInfo` → `Resonance::StreamInfo`) for Qt 6's moc |
| `internal/DiscoverURI.cpp` | `splitRef` → `split`, plus a new guard that drops a malformed `key=value` instead of indexing past it |
| `internal/ParseCED.cpp` | `splitRef`/`QStringRef` → `split`/`QString` |
| `ResonanceApp.cpp` | `QRegExp` → `QRegularExpression`; `QtWinExtras/QtWin` (gone in Qt 6) → `windows.h` + `shobjidl_core.h`; and the `TARGET_OS_WINDOWS` guard replaced by `_WIN32`, which is what neutralised [known-issues §3](../incidents/README.md) |
| `internal/HDFRecorder.cpp` | the **deliberate** row-count change — see §8 |

⚠ [`build_qt5-to-qt6-transition.md` §7](qt5-to-qt6-transition.md) names a sixth,
`QTextStream::setCodec` → `QStringConverter`. There is none: `setCodec`, `setEncoding` and
`QStringConverter` occur nowhere in either core. The five rows above are the list.

**Nothing on the wire path differs at all.** `jsonprotocol`, `StreamInfo`, `MetaData`,
`transmittabletype`, all of `TransmittableTypes/` and `Protocol/`, `blockStreaming`, the TCP sender
and receiver, `StreamPool`, `communicationlayer`, `servicediscovery`, `servicecontrol`, `recorder`,
`parameterapply` and every `Parameters/*.cpp` are byte-identical between the trees. That is exactly
why a Qt 5 service and a Qt 6 service discover and drive each other, in both directions, and it is
why the sections below need no version qualifier.

What *did* change is **§9 / §9a** (the QML layer — Controls 1 does not exist in Qt 6) and **§12**
(the build recipe). Both are marked.

⚠ `Core\docs\` — `service.md`, `parameters.md`, `services.md`, cited throughout §1, §4 and §6 —
was **not carried into the Qt 6 tree** and survives only at `R:\src_Qt5\Core\docs\`.

## Recorder extension and deliberate Qt 5/Qt 6 row-count change

Provenance: original `arch_architecture.md` lines 459–478. The following is preserved source text.

Extended 2026-08-12 for the standalone recorder: `Recorder` now owns its `InputStream`s, tracks
per-stream byte counts and rates (`streamStatus()`, `allStreamsPresent()`, `recordingSeconds()`,
`fileSize()`), takes a per-stream `reconnect` policy in `addStream()`, and can re-bind a
reconnected stream to the dataset it was already writing — so an outage is a gap in the
timestamps, not a second dataset. `recordLocalStream()` records a stream the process itself
produces; `setFlushInterval()` bounds how much a power loss can cost.

Relative and automatically generated HDF5 names resolve under `<distribution>\data`. `env.bat`
exports `RESONANCE_RECORD_PATH`, but that is now belt and braces rather than the mechanism:
`recordPath()` is `contentPath("data")`, so an executable started directly — with no environment
and a working directory of `bin` — still lands in `<distribution>\data`.

⚠ **The two generations do not write the same number of rows.** Qt 5's `HDFRecorder` creates every
numeric dataset at an initial extent of 1 and extends to `offset + samples + 1`, so **every Qt 5
recording ends with one all-zero row that was never written** — a fabricated falling edge on a
trigger channel, a reset on a counter. Qt 6 starts at 0 and extends to `offset + samples`, so the
row count is exactly the sum of the block sample counts and a Qt 6 file is **one row shorter** than
the Qt 5 file of the same data. Anything downstream that drops the last row to compensate now
discards one real sample per stream. The fix was deliberately **not** back-ported to `R:\src_Qt5`
([transition notes §7](qt5-to-qt6-transition.md)).

## QML registration delta and the formatter rationale

Provenance: original `arch_architecture.md` lines 491–521. The following is preserved source text.

**This is the one section with a version answer.** In the default tree (`R:\src`, `R:\dist`) the
whole QML layer is **Qt 6 / Qt Quick Controls 2** with versionless imports; in the comparator
(`R:\src_Qt5`, `R:\dist_Qt5\msvc64`) it is Qt 5.15 with Controls 1 at its centre. §9a records what
that conversion actually cost. Everything else below — the two artifacts, the `Plot/` split, the
abandoned scene-graph renderer — is the same in both. The registered type table very nearly is:
`resonanceqmlplugin.cpp` differs between the trees by **two lines**, the Qt 6 plugin registering one
extra type, `StreamDisplayFormatter` (`quickStimulus/resonanceqmlplugin.cpp:51`), so the Qt 6
registrations are a strict superset of the Qt 5 ones.

Two artifacts:

* **`quickStimulusPlugin.dll`** → installed to `bin/Resonance/` next to `qmldir`. This is the
  QML plugin, `import Resonance 3.0`.
* **`quickStimulus.exe`** → a thin QML runner. `--load <file.qml>` runs an arbitrary
  experiment; `--builtIn configurator|recorder|generator` runs one of the three apps compiled
  into `res.qrc`. The `.bat` launchers in the distro root are one-liners around this.

Types registered by `quickStimulus/resonanceqmlplugin.cpp` (all under `Resonance 3.0`):

| Category | Types |
|---|---|
| App/services | `ResonanceApp` (singleton), `ServiceLocator`, `ServiceControl` (uncreatable), `ServiceInspector`, `StreamInspector`, `ParameterInspector`, `Process` |
| Streams | `MessageSender`, `MessageReceiver`, `TimeSeriesSender`, `TimeSeriesReceiver`, `Recorder`, **`StreamDisplayFormatter`** *(Qt 6 only)* |
| Parameters | `Boolean`, `Integer`, `Double`, `String`, `MultiLine`, `Select`, `Stream`, `ChannelsList`, `Parameters` |
| State machine glue | `WaitForServices`, `SetParameters`, `ServiceStoped`, `ServiceChangedState`, `TimeoutTransitionPrecise`, `SCXMLServiceHelper` |
| Presentation | `Flicker` (SSVEP), `WindowControl`, `SerialPort` |

`StreamDisplayFormatter` turns either stream-info representation into the connector's operator-facing
text. It exists because a nested `QJsonValue` becomes an opaque V4 wrapper the moment it crosses a
QML function boundary in Qt 6, which is why connectors kept reading `>> Drag stream here <<` over a
live connection (`R:\src\docs\STREAM_CONNECTOR_LABEL.md`).

## Foreign-driver path-list failure and measured control

Provenance: original `arch_architecture.md` lines 681–705. The following is preserved source text.

⚠ **`RESONANCE_PATH` is a path *list*, and passing it to `add_dll_directory` raises.** `env.bat`
sets `RESONANCE_PATH=%CD%\bin;%CD%\qt\bin` (`R:\src\Core\Resonance\env.bat:5`, deployed as
`R:\dist\env.bat`) and uses it for one thing only — prepending both directories to `PATH`. **No C++
code in the tree reads the variable at all**; the ctypes wrapper is its only consumer, and it hands
the whole two-element string to `os.add_dll_directory()` as if it were one directory. Measured with
the distribution's own Python 3.12.1:

```
os.add_dll_directory(r'R:\dist\bin;R:\dist\qt\bin')  -> OSError [WinError 123]  (invalid name syntax)
os.add_dll_directory(r'R:\dist\bin')                 -> OK
```

The Qt 5 wrapper wrapped that call in a bare `try: … except: pass`, so the failure was silent and
harmless — the DLL was found through `PATH` anyway. **The Qt 6 wrapper does not**
(`ResonanceForeignDriver/resonance_foreign_driver.py:11-20`): it holds the returned handles
deliberately, so the call is unguarded and `Driver(...)` propagates the `OSError`. It then derives
`library = os.path.join(resonance_path, 'ResonanceForeignDriver.dll')` from the same list, which
would be a nonexistent path even if the directory call were guarded. `R:\dist\pygame_test.bat` and
`pyqt5_test.bat` both do `call env` and both demos construct `Driver` at module scope, so any host
launched that way meets it at the first `Driver(...)`.

**Set `RESONANCE_PATH` to a single directory for any Python host.** That is what the validated path
does — `R:\src\scripts\test-rfd-qt6.py:51` sets it to `<runtime>\bin` alone and assembles `PATH`
separately, which is why the 2026-08-28 end-to-end run passed
(`R:\src\docs\qa\rfd-qt6-final.log`).

## Device banner that expanded the Arduino window

Provenance: original `arch_architecture.md` lines 715–720. The following is preserved source text.

This is not a matter of taste. A service window that resizes itself when a device answers is one
that jumps under the operator's hands mid-session, and it fails in exactly the case that matters:
plug in a board with a longer banner and the layout moves. `arduinoTTL` shipped with its status
label in a row alongside the controls, and the board's identification string —
`arduinoTTL v2.3 out1=D9 mon1=D2 ch2=D3 idle1=HIGH` — made the window **942 px** wide where its
controls needed 662.

## Layout reductions and retained operator text

Provenance: original `arch_architecture.md` lines 733–761. The following is preserved source text.

**Capping the widgets is only half of it — the layout has to want to be narrow too.** Two habits
undo every cap above:

* **A stretch factor on a control.** `row->addWidget(combo, 1)` tells the layout the combo should
  absorb spare width, so a panel that could have been 210 px wide grows to whatever it is given,
  and two such panels side by side carry that straight into the window. Give the *space* the
  stretch — `addWidget(combo); addStretch();` — not the control.
* **A row that is too full.** A panel's minimum width is its widest row. In `arduinoTTL` that row
  was combo + field + checkbox on one line in each channel's onset group; moving the checkbox to
  its own line below cost 22 px of height and took **142 px** off the window.

A `QFormLayout` deserves its own mention: it stretches its field column, so a combo placed in one
grows with the panel however tightly `setMinimumContentsLength` is capped. Cap those by width.

Two corollaries worth stating separately, because both were got wrong once:

* **Nothing is lost by eliding.** The untruncated text stays reachable as a tooltip, and it is
  already on the `events` stream, which is where anything worth keeping belongs anyway.
* **A combo that truncates its own current value is worse than a wide one.** If the cap clips the
  selected item, shorten the item text — do not widen the box. `After an IN2 edge` became
  `After IN2`, and `Output, rests HIGH` became `Out, idle HIGH`. The unabbreviated wording still
  exists — it is what the `Select` parameter shows in the Configurator.
* **The target is a row you can point at, not a number.** "As wide as the presets row" is a
  statement a layout can satisfy and a reviewer can check at a glance. `arduinoTTL` went 942 → 694
  → **552 px**, and at 552 the presets row is what sets the width — every other row now fits
  inside it.

Applies to `eStim`, `arduinoTTL`, `feetStim` and `mStim`; `arduinoTTL`'s `elidinglabel.h` carries
the two helpers and is the place to copy from.

## Observed source-encoding symptom

Provenance: original `arch_architecture.md` lines 767–771. The following is preserved source text.

A UTF-8 source file without a BOM is read by MSVC in the system ANSI codepage. `tr("…")` survives
that — it goes through `QString::fromUtf8` at run time — but **`QStringLiteral("…")` is converted
at compile time and comes out as mojibake**, so the damage appears in some strings and not others
and looks like a font problem rather than a build setting. `arduinoTTL`'s diagram drew
`BNC2 (released вЂ" high-Z…` for exactly this reason while its group titles were fine.

## 2026-09-02: recipe omissions and test registration count

Provenance: original `arch_architecture.md` lines 969–985. The following is preserved source text.

   ⚠ Three things the old Qt 5 template here got away with omitting and this one must not: the
   components are **`Qt6`**; every Qt module used must be named in **both** `find_package` and
   `target_link_libraries` (`Qt6::Core` and friends — the template used to list none, though the
   real modules always did); and **`QStateMachine` moved out of Core into its own `StateMachine`
   module**, so a `ResonanceState`/`ResonanceTransition` graph now needs `Qt6::StateMachine` where
   Qt 5 needed nothing extra (`feetStim/CMakeLists.txt` is the worked example). Pin `6.11` in
   `find_package`, because the machine also carries Qt 5.15.2 under the same `C:\Qt515` root.
   ⚠ The tree is not consistent about that pin — counted 2026-09-02, ten of the eighteen module
   `CMakeLists.txt` that call `find_package(Qt6 …)` give the version and eight do not, and
   `SignalGenerator` is one of the eight, so copying the minimal template verbatim leaves the pin
   out.
   Wrap in `IF (WIN32 AND (CMAKE_SIZEOF_VOID_P EQUAL 4))` (or `8`) if it is arch-locked. If you add
   a GTest block, **finish it with `add_test(NAME … COMMAND …)`** — `SignalGenerator` and `feetStim`
   do, and it is easy to forget: counted 2026-09-02, `Core/Resonance/tests` registers **none of its
   seven** test targets and `quickStimulus` **three of its twelve**, so the framework every service
   links contributes nothing at all to a `ctest` total
   ([`arch_qt6-work-list.md`](qt6-work-list.md)).
