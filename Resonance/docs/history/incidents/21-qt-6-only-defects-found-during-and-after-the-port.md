# 25. Qt 6-only defects found during and after the port

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-25-qt-6-only-defects-found-during-and-after-the-port"></a>

### 25. Qt 6-only defects found during and after the port

**QT 6 ONLY throughout.** None of these can occur in `R:\src_Qt5` / `R:\dist_Qt5\msvc64`: each is
either a Qt 6 API change or something the port itself introduced. The first two are fixed and
deployed; the last three are open and ranked in [qt6-work-list.md](../migrations/qt6-work-list.md) — §8 for
25c, §7 for 25d and 25e.

<a id="history-25a-qml-xmlhttprequest-cannot-write-local-files-under-qt-6--parameter-save-failed-silently---fixed-2026-09-01"></a>

### 25a. QML `XMLHttpRequest` cannot write local files under Qt 6 — parameter Save failed silently — ✅ fixed 2026-09-01

`ParametersView.qml` saved a parameter set with a synchronous `XMLHttpRequest PUT` to a `file://`
URL and loaded it with `GET`. **Qt 6 does not permit QML `XMLHttpRequest` local-file writes by
default**, and the process never set `QML_XHR_ALLOW_FILE_WRITE` — so the PUT was refused. Three
independent things then made the refusal invisible: Save inspected no request status and had no
error callback, so a refused create or overwrite looked exactly like success; `PUT` gave no atomic
replacement, so a known-good hardware configuration could be truncated before the replacement
completed; and Load could not tell an open/read failure from valid content.

This is the shared delegate, so it was every Configurator-managed service at once — NVX136, NVX,
`recorderService`, `SignalGenerator`, `playbackService`, NeuroMS, SPEED, tepSound. It was reported
as NVX136 Save sometimes failing to create or replace its file — which reads as a driver fault and
is not one. NVX136's parameter definitions and driver were never involved.

⚠ **Setting `QML_XHR_ALLOW_FILE_WRITE` was rejected as the fix** — it hides the refusal and leaves
the unchecked, non-atomic write in place. Persistence moved into C++ instead
(`quickStimulus/parameterfile.cpp`, exposed as `saveParameterFile()` / `loadParameterFile()` on the
`ResonanceApp` QML singleton): serialise the whole array first, then `QSaveFile` with
`setDirectWriteFallback(false)`, so the old generation is replaced only when the new one commits;
and Load reports open/read errors and JSON parse location, requires an array root, and validates
every entry before any of it reaches a service. A malformed file that used to appear to load is now
refused **by name** in the UI. Regression cover: `test_ParameterFile` (8 disk-level cases, including
30 consecutive overwrite generations) and `test_ParameterFileQml`, which crosses the real
JavaScript→C++ boundary through the deployed plugin. Full write-up:
`R:\src\docs\PARAMETER_FILE_PERSISTENCE.md`.

<a id="history-25b-a-nested-qjsonvalue-becomes-an-opaque-v4-wrapper-across-a-qml-javascript-function-boundary---fixed-2026-09-01"></a>

### 25b. A nested `QJsonValue` becomes an opaque V4 wrapper across a QML JavaScript function boundary — ✅ fixed 2026-09-01

Every `Resonance__Parameters__Stream` row kept showing `>> Drag stream here <<` after a stream had
been dropped on it — in some cases while `activeStream` proved the connection was already live. The
parameter and the receiver were correct; only the text was wrong, which is the worst way for a
connector to fail, because the operator's evidence and the truth disagree.

**Under Qt 6.11 a nested `QJsonValue` is readable in a direct QML expression but is presented as an
opaque V4 wrapper once it crosses a QML JavaScript *function* boundary.** The row passed the nested
stream object through the helpers `desiredOf()` and `streamToStr()`; on the far side the formatter
saw neither `name` nor `connections` and returned an empty string, and the placeholder fallback was
then perfectly correct for that empty result.

⚠ **The general shape, and it is not confined to this delegate:** under Qt 6, *reading a nested JSON
value works and passing it to a function does not.* Anything in this tree that hands a
`QJsonValue`-backed object to a QML helper is suspect. Fixed by moving the formatting into C++ — a
registered `StreamDisplayFormatter` that accepts either a JSON/QVariant object or a typed
`StreamInfo` — and by observing both host signal sets (`serializedChanged`/`attributesChanged` from
the Configurator proxy, `jsonChanged`/`jsonAttributesChanged`/`streamChanged` from a live stream
parameter). Cover: `test_StreamConnectorQml`, five cases against the real delegate and plugin
offscreen. Full write-up: `R:\src\docs\STREAM_CONNECTOR_LABEL.md`.

<a id="history-25c--every-double-parameter-editor-lost-its-range-and-decimal-checking--open"></a>

### 25c. ⚠ Every `Double` parameter editor lost its range and decimal checking — open

`R:\src\quickStimulus\import\Resonance\Resonance__Parameters__Double.qml:15-20`:

```qml
validator: DoubleValidator {
    bottom: Math.min(parent.from, parent.to) / parent.factor
    top: Math.max(parent.from, parent.to) / parent.factor
    decimals: parent.decimals
    notation: DoubleValidator.StandardNotation
}
```

`DoubleValidator` is a `QObject`, not a `QQuickItem`, so it has **no `parent` property**. The name
therefore resolves outward through the component root — `self`, the `SpinBox` — to `self.parent`,
which is the **`ParamView` `Loader`** that `ParametersView.qml:114` creates. That Loader carries
`label`, `description`, `attributes`, `group`, `name`, `type`, `index`, `row`, `readOnly` and
`serialized`, and **none of `from`, `to`, `factor` or `decimals`**. All four reads are `undefined`,
so `bottom` and `top` evaluate to `NaN` and `decimals` is `undefined`.

Line 7 of the same file shows what the author meant: there `parent.attributes.decimals` is written
on the `SpinBox` root, where `parent` *is* the Loader and the property does exist. Inside the
validator the same word means something different.

**Port-introduced and never exercised.** The Qt 5 original has no validator at all — a Controls 1
`SpinBox` took `minimumValue`/`maximumValue`/`decimals` natively, and Controls 2's is integer-only,
which is why the port added the `factor` scaling and the validator with it.
⚠ Reasoned from the code, not measured — no one has typed an out-of-range value into a Qt 6 `Double`
editor and recorded what happens. **Fix: replace the four `parent.` with `self.`**; it is one line
and rebuilds nothing but the QML plugin.

<a id="history-25d-qtconf-still-uses-the-qt-5-key-qml2imports--open"></a>

### 25d. `qt.conf` still uses the Qt 5 key `Qml2Imports` — open

`R:\src\runtime-content\qt.conf`, deployed verbatim to `R:\dist\bin\qt.conf`:

```ini
[Paths]
Prefix=../qt
Plugins=plugins
Qml2Imports=qml
```

**Qt 6 renamed that key to `QmlImports`.** Measured rather than remembered: `R:\dist\qt\bin\Qt6Core.dll`
contains the string `QmlImports` and not `Qml2Imports`; `R:\dist_Qt5\msvc64\qt\bin\Qt5Core.dll`
contains `Qml2Imports` and not `QmlImports`. So the line is inert — Qt 6 reads the file, ignores
that entry, and falls back to its own default, which with `Prefix=../qt` is already `qml`. **The
value is right by coincidence, and the coincidence stops protecting it the moment the QML imports
move anywhere but `<Prefix>\qml`.**

It has not bitten because two other things also point at the same directory: `R:\dist\env.bat` exports
`QML2_IMPORT_PATH=%CD%\bin;%CD%\qt\qml`, and `Qt6Qml.dll` still honours `QML2_IMPORT_PATH` as well
as `QML_IMPORT_PATH` (both strings are present in it). ⚠ **A process started without `env.bat` —
a desktop shortcut straight into `bin\`, or a service launched by something other than its `.bat` —
gets nothing from this file.** That is exactly the launch route `resolveRootPath()` was rewritten to
survive (§19e), so it is not hypothetical.

<a id="history-25e--envbat-has-no-setlocal-so-qt-6-paths-leak-into-a-later-qt-5-launcher--open"></a>

### 25e. ⚠ `env.bat` has no `setlocal`, so Qt 6 paths leak into a later Qt 5 launcher — open

`R:\dist\env.bat` is `pushd` … `popd` with **no `setlocal`/`endlocal`**, so every variable it sets
outlives it in the calling console:

```bat
set "QT_PLUGIN_PATH=%CD%\qt\plugins"
set "QML2_IMPORT_PATH=%CD%\bin;%CD%\qt\qml"
```

Run a Qt 6 launcher from a `cmd` window and then a Qt 5 one from the *same* window, and the Qt 5
process inherits `QT_PLUGIN_PATH` and `QML2_IMPORT_PATH` pointing into `R:\dist\qt` — a **Qt 6**
plugin and QML tree. That is the one operational way the two generations can be made to meet inside
one process, which the transition notes say must never happen
([qt5-to-qt6-transition.md §9](../migrations/qt5-to-qt6-transition.md)), and it is invisible from the
launcher: the service either fails to find a platform plugin or refuses one built against the other
major version.

⚠ **The leak is one-directional, and only this way round — measured 2026-09-02.**
`R:\dist_Qt5\msvc64\env.bat` has no `setlocal` either, and it leaves behind `PATH` with the Qt 5
`bin;qt\bin` prepended plus the whole `RESONANCE_*` set pointing into `R:\dist_Qt5\msvc64`. But
everything it sets is a **subset** of what `R:\dist\env.bat` sets *unconditionally* — every one of
the same `RESONANCE_*` variables, plus `PYTHONHOME` and `PATH` — so running the Qt 5 launcher first
and a Qt 6 one after it overwrites every leaked value and prepends the Qt 6 `PATH` in front: a Qt 6
service still reads and writes inside `R:\dist`. The other order leaks precisely because the Qt 5
file has no
`QT_PLUGIN_PATH` / `QML2_IMPORT_PATH` line to overwrite the Qt 6 one with.

Double-clicking a `.bat` is safe — that console dies with it. **Mixed sessions belong in separate
consoles until both files carry `setlocal`**, and note that `setlocal` cannot simply be added on its
own: the launchers read `%RESONANCE_DIR%` back out of `env.bat` *after* it returns
(`cd /d "%RESONANCE_DIR%\bin"`), which an `endlocal` would discard.

---

