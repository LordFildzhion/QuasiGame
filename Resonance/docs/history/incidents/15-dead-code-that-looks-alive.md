# 9. Dead code that looks alive

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-9-dead-code-that-looks-alive"></a>

### 9. Dead code that looks alive

**TRANSFERS UNCHANGED, and the Qt 6 tree grew its own instances.** Two worth knowing: the 29
orphaned `.qbs` files (§8), and the sixteen QML files in `R:\src\quickStimulus` that still
`import QtQuick.Controls 1.x`. Twelve of those are ordinary dead code — `main.qml`, `settings.qml`,
`SignalPlot.qml`, `test.qml` and the `testApp\`, `testExperiment\` and `speedTestApp\` sets, none of
them in any build. The **four that are shipped** are the ones that matter:
`Configurator_normal.qml`, `SignalView.qml`, `Plot\ComboBoxBinding.qml` and
`Bricks\StimulusSelector.qml` are listed in `quickStimulus\CMakeLists.txt` (`:61`, `:81`, `:86`,
`:110`) and therefore **install into `R:\dist\bin\Resonance\`**, where Qt 6 cannot resolve that
import.
`StimulusSelector` and `ComboBoxBinding` are registered in their sub-module `qmldir`s, so they are
reachable by name, not only by path. Ranked in [qt6-work-list.md](../migrations/qt6-work-list.md) §8.
⚠ `conanfile.txt.bak` (below) exists only in `R:\src_Qt5`.

Files present, plausible-looking, but not in any build (full list in
[modules.md](../migrations/modules.md#history-dead--historical)). The trap is spending an hour fixing
`quickStimulus/datasource.cpp` before noticing it hasn't been compiled since ~2019. Before
editing anything, grep for its filename in the module's `CMakeLists.txt`.

`conanfile.txt.bak` contains a **raw, unresolved git merge conflict** (`<<<<<<< HEAD` markers)
between `master` and `feature/try-to-jump-to-qt6`. Delete it or leave it, but don't read it as
configuration.

---

