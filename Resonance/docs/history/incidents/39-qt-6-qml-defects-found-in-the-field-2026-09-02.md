# 25. Qt 6 QML defects found in the field, 2026-09-02

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-25-qt-6-qml-defects-found-in-the-field-2026-09-02"></a>

### 25. Qt 6 QML defects found in the field, 2026-09-02

**QT 6 ONLY.** Three defects reported from the rig in one day, all in QML the port rewrote, all
fixed the same day. They are grouped because two of them share a root cause and the third is why
neither was noticed sooner.

<a id="history-25a-xmlhttprequest-cannot-read-a-local-file--a-chosen-ced-never-reached-the-amplifier"></a>

### 25a. `XMLHttpRequest` cannot read a local file — a chosen `.ced` never reached the amplifier

Selecting an electrode layout appeared to work and did nothing. The filename appeared beside the
button; the parameter stayed empty; no error anywhere.

`Resonance__Parameters__File.qml` read the chosen file with `XMLHttpRequest` GET, carried over
verbatim from Qt 5. Qt 6 refuses that — *"XMLHttpRequest: Using GET on a local file is disabled
by default"* — and **refuses it by never advancing the request to DONE**, so the
`onreadystatechange` handler never ran at all. `fileName.text` was set before the request, which is
why the operator saw a filename and nothing else.

⚠ This is the **same root cause** as the parameter Save/Load repair
(`R:\src\docs\PARAMETER_FILE_PERSISTENCE.md`), in a control that repair did not cover.
`XMLHttpRequest` was this tree's habitual way to touch a file from QML and Qt 6 has now broken it
twice — `grep -rn XMLHttpRequest R:\src` before assuming there is not a third.

Fixed with checked C++: `ParameterFile::read()` exposed as `ResonanceApp.readFileContents()`. It
reports open and read errors, refuses a non-local URL, refuses an **empty** file by name, and
returns the value already encoded the way `File::setJson()` expects. The QML shows the error beside
the filename instead of failing silently. It also corrects a latent inversion: the old code called
`atob()` — which *decodes* base64 — on bytes that were never encoded, for the binary case.
That branch had never run, because every `Parameters::File` in the tree is a text montage.
Covered by seven `ParameterFileRead` cases and one QML-boundary test; demonstrated on the packaged
build by `scripts/ced-xhr-probe.qml`, which runs both paths side by side.

<a id="history-25b-the-channel-list-had-no-keyboard--select--space-did-nothing"></a>

### 25b. The channel list had no keyboard — select + Space did nothing

Reported against `nvx136`, `nvx136_2021` **and** the regular `nvx` at once, because all three render
`Parameters::ChannelsList` with one shared QML editor.

The Qt 5 editor was a Controls 1 `TableView` with a real selection model and its own key handling.
The Qt 6 rewrite hand-rolled the selection and put `Keys.onSpacePressed` on the ListView — but
nothing ever gave that list **active** focus. `focus: true` sets focus only within the component's
own scope, which is inert until something hands the scope active focus, and a MouseArea does not
take focus by design. The row highlighted, the keystroke went elsewhere.

Fixed by taking the keyboard on every path that selects a row. The arrow keys now move the
selection rather than an invisible `currentIndex`, the current row is drawn while the list holds
focus, Tab reaches the list and Ctrl+A selects all. `test_ChannelsListQml` drives real mouse and key
events through a real window.

<a id="history-25c--the-build-tree-ran-stale-qml-so-a-qml-fix-looked-like-it-had-done-nothing"></a>

### 25c. ⚠ The build tree ran stale QML, so a QML fix looked like it had done nothing

The reason 25b took three attempts to verify, and a trap for anyone testing QML from `_build`.

`install_directory()`'s POST_BUILD copy fires **only when the target relinks**. Editing a `.qml`
does not relink `quickStimulusPlugin`, so the staged copy under `_build/runtime/bin/Resonance`
stayed at whatever version was current the last time C++ changed. Measured while fixing 25b: the
staged file was **5254 bytes against 9223 in source**.

`cmake --install` refreshes it, so the **deployed package was always correct and only the build tree
lied** — the worse way round, because the build tree is what a test runs against. A
`quickStimulusQml ALL` target now stages the directory on every build with
`copy_directory_if_different`.

