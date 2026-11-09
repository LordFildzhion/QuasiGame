# Resonance architecture — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../architecture/framework.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-4-streams"></a>

## 4. Streams

| Class | File | Role |
|---|---|---|
| `AbstractStream` | `Core/Resonance/AbstractStream.hpp` | Base; state machine `Connecting → Ready / Failed / Closed`, signals `ready/closed/failed/endOfLife/blockReceived/sendBlock`. |
| `OutputStream` | `outputstream.hpp` | Publishes a stream; owns a `ThreadCapsule` running a `TcpStreamSender`. |
| `InputStream` | `inputstream.hpp` | Subscribes; constructed with a `StreamInfo` describing *what to look for* and an optional discovery timeout. |
| `StreamInfo` | `StreamInfo.hpp` | Immutable, copy-on-write descriptor: `uid`, `name`, `connections` (list of `QUrl`), serialized type, `MetaData`. |
| `DataBlock` | `DataBlock.hpp` | Ref-counted payload + its `StreamInfo`. |
| `StreamPool` | `internal/StreamPool.hpp` | The matchmaker. Holds pending/established connections, runs a periodic `discoveryCycle()`, picks the transport for a `StreamInfo`. |

Stream lookup is URL-driven (documented in `Core/docs/parameters.md`):

* `tcp-ip://host:port` — direct connection. ⚠ Under the default `loopback` mode a
  non-loopback host is **refused**, both when candidates are built and again at the dial, so a
  stale URL in a saved configuration is logged and dropped rather than quietly connecting to
  another machine.
* `discover:///?stream=<name>&uid=<serviceUid>&name=<serviceName>` — resolved by discovery.

Connections in a `Parameters::Stream` value are tried **first to last** until one matches —
after any that the current network mode forbids have been removed from the list.

<a id="history-reconnection-is-by-name-2026-08-12"></a>

### Reconnection is by name (2026-08-12)

`Parameters::Stream` carries a `reconnect` flag — **in the value, not the attributes**, because
whether a connection should survive its producer restarting is the operator's choice and has to
be settable from a configurator. It defaults to **true**.

When set, the request is rewritten by `persistentStreamRequest()` (`servicediscovery.hpp`) into
`discover:///?stream=<name>&name=<service>`. A service uid is per-process so it changes on
relaunch, and the serialized type encodes channel count and sampling rate so it changes on
reconfiguration — the name pair is the only part stable across both, and it is what an operator
means by "the EEG stream from NVX". The function returns its input unchanged when the pair
cannot be determined, so callers can use it unconditionally.

<a id="history-isnull-vs-isempty"></a>

### `isNull()` vs `isEmpty()`

`StreamInfo::isNull()` is **pointer identity** against one shared default instance. A
`StreamInfo` that merely *describes* nothing — one built from an empty JSON object, say — is not
null. Use **`isEmpty()`** ("no name, no uid, no connection") for any "should I try to connect"
decision; using `isNull()` there attaches a phantom stream to a cleared connector.

<a id="history-transmittable-types"></a>

### Transmittable types

`transmittabletype.hpp` + `TransmittableTypes/`:

| Type | Payload |
|---|---|
| `Message` | timestamped UTF-8 string (events, markers) |
| `Int32` | multichannel int32 samples + `samplingRate`, `multiplier` |
| `Float64` | multichannel double samples + `samplingRate` |
| `EventBus` | the control channel (descriptions, parameter sets, transitions) |

They are registered at startup via `TransmittableType::registerType(&T::construct)`.
Downcast with `transmittable_type_cast<T>(block.info().type())` — returns `nullptr` on mismatch.

`SamplesCollector` (`SamplesCollector.hpp`) is the convenience helper drivers use: feed it
one sample at a time (`addSample({...})`) and it emits a `Float64` block every `blockSize`.

---


<a id="history-6-parameters"></a>

## 6. Parameters

`Core/Resonance/Parameters/` — base class `Parameter` (`parameter.hpp`), each with
`name` (unique), `group`, `index` (sort order), `label`, `enabled`, `readOnly`, `visible`, and a
JSON `serialized` value + read-only `attributes`.

Concrete types (all documented in `Core/docs/parameters.md`):
`Boolean`, `Integer`, `Double`, `String`, `MultiLine` (a.k.a. Text), `Select`, `File`,
`Stream`, `ChannelsList`, `BipolarChannelsList`, `Action`.

**Three flags, three different statements** — and keeping them distinct matters, because a client
used to be able to collapse them:

| Flag | Says | Rendered as |
|---|---|---|
| `enabled` | "you cannot change this right now" | greyed, still readable |
| `readOnly` | "this is the value; it is not yours to set" | normal colours, not editable |
| `visible` | "this does not apply to the mode I am in" | not drawn at all |

**`visible`** (added 2026-09-02, mirrors `readOnly`) exists because the Configurator used to carry
a **"Hide disabled options"** switch, on by default, that turned `enabled == false` into *erased*.
That made "temporarily unchangeable" and "inapplicable" render identically, and services distorted
their own state to work around it: KARDi2 lost its sampling-rate readout during acquisition, and
neuroMS holds a whole hardware tab `readOnly` rather than disabled precisely so the switch would
not empty it. The switch is gone. A service that wants an editor hidden now says so.

The canonical use is a mode selector that changes which editors apply — `nvx/application.cpp` gates
its bipolar-pairs list on `mode == ModeBipolar` and its unipolar list on the complement, so
Impedance mode shows the channel list **greyed** (readable, not settable) while Bipolar mode
replaces it outright.

⚠ **`setVisible` must `emit triggerUpdate()`**, exactly as `setEnabled` and `setReadOnly` do.
`visibleChanged()` alone is an in-process signal; without `triggerUpdate()` the new value never
reaches the wire and no client ever learns about it. On the wire the key is `"visible"`, and it is
**additive** — a client that does not receive the key reads the parameter as visible, so mixed
generations interoperate.

<a id="history-the-status-line--stateinfo-and-droppedsamples"></a>

### The status line — `stateInfo` and `droppedSamples`

A service publishes a `state` (its state-machine's current state name) and, alongside it, a
free-form JSON `stateInfo`. `stateInfo` existed on the wire from the beginning and nothing ever
filled it: `setState`'s `metaInfo` argument has exactly one caller, `ResonanceState::onEntry`,
which fires once on entry and passes nothing. Anything a service learns *while* it is in a state
had no way to reach a client.

`CommunicationLayer::setStateInfo(QJsonValue)` is that way in, and
**`reportDroppedSamples(quint64)`** is the first convention built on it: the `droppedSamples` key,
an integer, counted since acquisition started. A client renders
`running, 11231 samples dropped` beside the state and shows nothing when the key is absent or the
count is small. The *threshold* belongs to the client — the wire carries the truth and the panel
decides what is worth an operator's attention. It is 100 in the Configurator.

Three rules this shape is designed around:

* **Absent is not zero.** A service that does not count must not be rendered as one that counted
  nothing; both show no text, and neither claims a clean bill of health.
* **Entering a state clears it.** `ResonanceState::onEntry` resets `stateInfo` to null, and
  `setState` also resets the accumulator's bookkeeping — otherwise a second run that lost exactly
  as many samples as the first would compare equal and never publish.
* **It is throttled.** A description carries the whole parameter set to every connected client, so
  `reportDroppedSamples` coalesces to one broadcast a second. The *first* loss goes out
  immediately, because the moment something starts going wrong is the moment worth knowing.

Wired in `nvx`, `nvx136`, `actiChamp` and `KARDi2` — every driver in the tree with a hardware
sample counter. ⚠ On an NVX-52 the figure is currently enormous and correct-as-the-driver-sees-it;
see [`arch_qt6-work-list.md` §3b](qt6-work-list.md).

**`description`** (added 2026-08-15) is free text explaining what a parameter does. It travels
in the service description and a client renders it as a tooltip — the Configurator puts it on
both the label and the editor. The *service* supplies it, because the service is the only thing
that knows its own hardware; do not try to keep a table of explanations in the Configurator.

**Group tabs are ordered by the lowest `index` in each group**, and a service opens on its first
tab. So a driver that wants `main` before `hardware` before `trigger` numbers its parameters in
bands (10-99, 110-199, 210-299) — the same numbering that orders rows inside a tab. Tabs used to
be sorted alphabetically, with no way to say otherwise.

**`Action`** (added 2026-08-12, `Parameters/action.hpp`) is the odd one out: it has no value.
A client renders it as a button; `json()` is always null so a description re-broadcast cannot
re-fire it, and an invocation is recognised only by an explicit `{"invoke": true, …}` marker so
Save/Load cannot replay one. With a `prompt` attribute set, the client asks for a line of text
first and sends it with the RTC of the *click*. See
[recorder-service.md §6.2](../components/recorder.md#history-62-new-parameter-type-action).

Usage pattern from `src/SignalGenerator/main.cpp`:

```cpp
Parameters::Integer channels("channels", "default", 0);   // name, group, index
channels.setLabel("Channels");
channels.setValue(3);
channels.setMinimum(1); channels.setMaximum(999);
QObject::connect(&channels, &Parameters::Integer::valueChanged,
                 [&]{ gen.setChannels(channels.value()); });
app.comLayer()->addParameter(&channels);
```

Parameters are **not owned** by the CommunicationLayer — it watches `destroyed()`.
Stack-allocating them in `main()` (as `SignalGenerator` does) or heap-allocating them in a
Config object (as every driver does) are both fine.

<a id="history-who-notifies-whom-changed-2026-08-12"></a>

### Who notifies whom (changed 2026-08-12)

Three signals, three audiences — get these wrong and a service's own GUI silently disagrees with
every client:

| Signal | Who listens | Meaning |
|---|---|---|
| `valueChanged` | local bindings (a service's own QML) | the value moved |
| `jsonChanged` | local bindings on `serialized` | the serialised form moved |
| `triggerUpdate` | `CommunicationLayer` | **re-broadcast the description** (30 ms coalescing timer) |

`setJson()` — the *remote* path — emits `valueChanged` but **not** `triggerUpdate`;
`clientRequest` restarts the description timer itself, so adding it would only echo.

`setValue()` — the *local* path — emits all three. It used to emit nothing at all for `Integer`,
`Double`, `String` and `MultiLine`, which is why a value set by a service's own window never
reached the network. Guarded by an equality check, so a `valueChanged` handler that writes back
cannot loop.

Attribute setters that constrain what `setJson` will accept (`Integer::setMinimum/setMaximum`)
also emit `jsonAttributesChanged` + `triggerUpdate` — a client that has not been told the range
moved keeps offering values the service now refuses.

<a id="history-descriptions-tooltips--write-them-long-render-them-narrow"></a>

### Descriptions (tooltips) — write them long, render them narrow

`Parameter::setDescription()` is the operator-facing explanation, shown as a tooltip on both the
label and the control. It travels in the service description as `description`, so any client
gets it, and it is the right place for everything that does *not* fit in a label: what the
setting does, when it takes effect, what the device does if it is refused, and any measured
number worth knowing.

<a id="history--every-parameter-has-a-description-no-exceptions"></a>

### ⭐ Every parameter has a description. No exceptions.

A parameter without one is a control with no explanation anywhere in the product — the operator's
only recourse is to read the source. **All 294 parameters in the distribution have one** as of
2026-09-06; 45 did not, and were written that day.

**This is checked, not merely asked for:**

```
python scripts\audit-parameter-descriptions.py
```

It pairs every `x = new Parameters::T("wire", ...)` with an `x->setDescription(` in the same file
and exits non-zero if any parameter is unaccounted for. Run it after adding a parameter.

⚠ A read-only readout needs one too, and arguably needs it more: `Firmware` and `Error messages`
look like settings that refuse to accept input until the tooltip says they are readouts.

**Two more rules, because they trade against each other.**

1. **The label is short; the description carries the detail.** The parameter panel is a narrow
   dock. **Keep labels to about 22 characters** — that is the 130 px label column — and move the
   sentence into the description.

   `ParametersView.labelColumnWidth` **pins** the column to 130 px in every tab of every service,
   so a long label can no longer widen anything: it wraps to a second line instead. Wrapping is
   allowed and 11 of the 276 labels in the distribution do it, but a wrapped label is still a
   label nobody reads in full — it does not become more readable for being visible. The place for
   the sentence is the description.

2. **A tooltip is never wider than the parameter panel.** A stock Controls 2 `ToolTip` lays its
   text out on one line and grows to fit, so a three-sentence description becomes a strip across
   the whole application window, nowhere near the pointer. Use `ParameterToolTip` — it takes a
   `maximumWidth` and wraps into it. `ParametersView` passes its own width, so a tooltip stays
   inside the panel it belongs to. `ToolTip` has no maximum-width property of its own: the width
   has to be set *and* the content item told to wrap at it, which is the whole reason that
   wrapper exists.

Descriptions are plain text. Newlines survive, so a multi-mode parameter can put one line per
mode (`nvx`'s `mode` and `nvx136`'s `mode` both do).

---


<a id="history-9a-the-qt-6-qml-migration--what-it-actually-cost"></a>

## 9a. The Qt 6 QML migration — what it actually cost

**Done.** The plan that stood here was measured on 2026-08-19 against
`C:\Qt515\5.15.2\msvc2019_64\qml\QtQuick\Controls.2\` and executed between 2026-08-27 and
2026-09-02. Every decision is dated in **`R:\src\docs\PORTING_LOG.md`** ("QML and GUI migration",
plus the 2026-08-28 appearance-parity and shared-layout revisions); the evidence is
`R:\src\docs\VALIDATION.md` and the captures in `R:\src\docs\qa\`. The section is kept as a record
rather than deleted, because the *reason* each file was hard is still the reason to be careful near
it — and because the Qt 5 comparator still contains every original.

<a id="history-the-blocker-and-how-it-was-cleared"></a>

### The blocker, and how it was cleared

Qt Quick Controls **1 does not exist in Qt 6**, and **Qt 5.15.2 shipped no Controls 2 `TreeView`
and no Controls 2 `TableView`**. `TreeView` arrived in Qt **6.3** with a different API —
`TableView`-derived, a model adapter, one delegate per cell, no `TableViewColumn` at all. So the
Configurator's service tree could not be ported incrementally: on Qt 5.15 there was nothing to port
it *to*. It was rewritten against Qt 6's own `TreeView` at the move itself, exactly as predicted,
and that rewrite was the largest single item in the migration.

The coupling prediction held too. Controls 1 `ApplicationWindow.menuBar` accepted only a Controls 1
`MenuBar`, and `ParametersView` was a Controls 1 `GroupBox` holding a Controls 1 `TabView` — so the
menu bar, the tab host and the tree had to convert together or not at all. They converted together.
`TabView` did not become `TabBar` + `StackLayout` as guessed: `ParametersView.qml` now reimplements
the small tab API it needs over component descriptors, with a group selector standing in for the
tab bar (`ParametersView.qml:98`, `:858`), because the call sites insert and remove tabs at run
time and a renamed structure would not have carried that.

<a id="history-the-2026-08-19-inventory-and-what-each-file-became"></a>

### The 2026-08-19 inventory, and what each file became

Outcomes verified 2026-09-02 against `R:\src\quickStimulus\` and the deployed
`R:\dist\bin\Resonance\`. The Qt 5 original of every row is still at `R:\src_Qt5\quickStimulus\`.
The legacy `stimulusService/legacy/sp_*.qml` (18 files) are excluded, as they were then — an
archive of the experiment programs as found. ⚠ Those 18 are now the hardest single obstacle to ever
retiring `R:\dist_Qt5`: roughly 830 Controls 1 instantiations, loaded *into* the host process by
`quickStimulus --load`, so a mixed rig does not help
([`arch_qt5-still-needed.md`](qt5-still-needed.md)).

| File | Controls 1 it used | What it is now |
|---|---|---|
| `import/Resonance/Configurator.qml` | `TreeView`, `TableViewColumn`, `MenuBar`, `Menu`, `MenuItem`, `ExclusiveGroup`, `SplitView`, `GroupBox`, `Button`, `CheckBox`, `Label`, `TextField` | **Rewritten.** Qt 6 `TreeView` at `:482`, taking both columns from the `QAbstractItemModel`; Controls 2 `MenuBar` (`:20`) and `SplitView` (`:363`) |
| `import/Resonance/ParametersView.qml` | `TabView`, `ButtonStyle`, `GroupBox`, `ScrollView`, `Button`, `CheckBox`, `Label` | **Rewritten.** Tab API reimplemented over component descriptors + a group selector |
| `Resonance__Parameters__ChannelsList.qml` | `TableView` (root), `TableViewColumn`, `CheckBox` | **Rewritten** on a `ListView` (`:91`); 18 px rows, 13 px check marks |
| `Resonance__Parameters__BipolarChannelsList.qml` | `TableView` (root), `TableViewColumn`, `ComboBox` | **Rewritten**; 24 px rows |
| `Resonance__Parameters__Boolean.qml` | `CheckBox` | Controls 2, through the shared `SquareCheckBox` (solid inner square) |
| `Resonance__Parameters__Double.qml` | `SpinBox` | Controls 2 `SpinBox`. ⚠ It **is** integer-only, as predicted — but the fix was not `Plot/NumberField.qml`: it keeps a `Math.pow(10, decimals)` scaling factor with `textFromValue`/`valueFromText` and a `DoubleValidator`, so the parameter keeps a spin box's arrows |
| `Resonance__Parameters__Integer.qml` | `SpinBox` | Controls 2 `SpinBox` |
| `Resonance__Parameters__String.qml` | `TextField` | Controls 2 |
| `Resonance__Parameters__MultiLine.qml` | `TextArea` | Controls 2 — the dirty-flag guard of [known-issues §20](../incidents/README.md) is what this was written against |
| `Resonance__Parameters__Select.qml` | `ComboBox` | Controls 2. ⚠ The write-back is still on `onActivated`, never `onCurrentIndexChanged` |
| `Resonance__Parameters__File.qml` | `Button` | Controls 2 |
| `recorderService/ui.qml` | `ApplicationWindow`, `ButtonStyle`, `GroupBox`, `ScrollView`, `Button`, `CheckBox`, `SpinBox`, `TextField`, `Label` | Controls 2 |
| `recorderService/TipLabel.qml` | `Label` | Controls 2 |
| `playbackService/ui.qml` | `ApplicationWindow`, `GroupBox`, `ScrollView`, `Button`, `CheckBox`, `SpinBox`, `TextField`, `Label` | Controls 2 |
| `ParamTabView.qml` | `ScrollView` | Controls 2. Converted rather than retired, though still not in `qmldir` |
| `ParamView.qml` | *(imported Controls 1, used none of it)* | Controls 2; registered in `qmldir` |
| `Bricks/StimulusSelector.qml` | `TextField` | ⚠ **still Controls 1** — see below |
| `Plot/ComboBoxBinding.qml` | `ComboBox` (root) | ⚠ **still Controls 1** |
| `Configurator_normal.qml` | `ApplicationWindow`, `TreeView`, `TableViewColumn`, `SplitView`, `GroupBox`, `Button` | ⚠ **still Controls 1**; still dead |
| `SignalView.qml` | `SpinBox` | ⚠ **still Controls 1**; still not in `qmldir`, still written against a `TimeSeriesReceiver` API that no longer exists ([modules.md](modules.md)) |

⚠ **Four Controls 1 files were carried into the Qt 6 distribution unconverted and ship in
`R:\dist\bin\Resonance\`**: `Bricks/StimulusSelector.qml`, `Plot/ComboBoxBinding.qml`,
`Configurator_normal.qml` and `SignalView.qml`. Two of them are *registered types* —
`StimulusSelector` in `Bricks/qmldir`, `ComboBoxBinding` in `Plot/qmldir` — so an `import
Resonance.Bricks` or `Resonance.Plot` that names one gets a component whose
`import QtQuick.Controls 1.2`/`1.4` cannot resolve under Qt 6. Nothing in the shipped tree instantiates
any of the four (the only reference to `ComboBoxBinding` is `tests/UnitTests/tst_ComboBoxBinding.qml`),
so this is latent rather than live — but it is a trap for anyone writing new QML against
`Resonance.Bricks`, and the retire-the-dead-files step the old plan opened with was never taken.

<a id="history-the-density-finding-survived-contact-and-is-now-evidence"></a>

### The density finding survived contact, and is now evidence

**Controls 2 floors every control at 100×40 px through its *background***, and no amount of font or
padding tuning overrides it — replacing the background is what makes a control compact
([signal-viewer.md §11](../components/signal-viewer.md)). Budgeting for that, rather than for type
renames, was the right call: the shipped Qt 6 UI needed an explicit density pass, and the numbers it
landed on are worth copying. Service rows are **18 px** with no inter-row gap (Qt 5's Desktop
`TableViewStyle` baseline was 16 px; the extra two pixels are the Qt 6 font). The default service
pane is **200 px**, not 260, giving the difference back to the parameter editor. Channel rows are
18 px with 13 px check marks; bipolar rows 24 px. The window has a **760×600** practical minimum and
a **1200×850** default.

⚠ Two appearance decisions came out of the same pass and are load-bearing rather than cosmetic:
the **Fusion** Controls 2 style is selected *before* application construction
(`quickStimulus/main.cpp:27`), because the native Windows style produces hundreds of warnings and
omits pieces of the authored control backgrounds; and a **fixed light palette** is forced, so the
application no longer inherits the Windows dark colour scheme mid-session.

<a id="history-controls-2-shaped-is-not-the-same-as-ported"></a>

### Controls-2-shaped is not the same as ported

The signal viewer — `Plot/*` and `StreamView.qml` — was Controls 2 only before the move, which is
what the 2026-08-13 rework was largely for ([signal-viewer.md §1](../components/signal-viewer.md)), and it
crossed with the least work of anything here. ⚠ But `tepService`'s and `stimulusService`'s consoles,
listed here in 2026-08-19 as "already Qt 6-shaped", **were not ported by being Controls 2**: both
modules stayed on Qt 5 until they were re-done — `tepService` retired in favour of
`tepSoundService`, `stimulusService` rebuilt as the Qt 6 Stimulus service on 2026-09-06 with a new
console ([`arch_qt5-still-needed.md`](qt5-still-needed.md)). Their consoles being Controls 2
lowered the cost; it did not port them. Anything new should still be written Controls 2, and
nothing new should add a Controls 1 type.



<a id="history-11c-seeing-what-a-service-is-saying--the-debug-console"></a>

## 11c. Seeing what a service is saying — the debug console

Every service in this tree is a `WIN32` (windowed) binary, so `qDebug()`, `qWarning()` and QML
`console.log()` have nowhere to go. That is a deliberate packaging choice — a launcher must not
leave a terminal on screen for the length of a session — but it is also why several defects in
[known-issues.md](../incidents/README.md) were invisible for months: *"the message only reached
`qWarning`, and the service is windowed"*.

**`Core/Resonance/DebugConsole.hpp` is the framework's answer, and it applies to every service
without any of them knowing about it.** Three routes, one mechanism:

| | |
|---|---|
| `--console` on any service's command line | registered by `ResonanceApp` for **every** service, so it is honoured and documented in `--help` rather than aborting a service that never declared it |
| `!showConsole` / `!hideConsole` over the EventBus | what the Configurator's **System → Show console** sends — the menu beside a service's own transitions, where `!recordToFile=`, `!stopRecording` and `!terminate` already live. This is the one that matters in practice: the moment a console is wanted is never a moment when relaunching the service is acceptable, because relaunching destroys the state being investigated |
| `ResonanceApp::setDebugConsoleVisible()` | for a service whose own window offers the toggle; `ResonanceApp.debugConsoleVisible` in QML |

**It is one menu entry, not two**, and it says what it will do: *Show console* becomes *Hide console*
while the console is up. The label comes from the service's own description, so it is still right
when the console was opened by some other route. It is greyed out against a service that does not
publish `consoleControl`, rather than offering an action that would silently do nothing — and it
sits below *Stop recording* with a separator under it, because its neighbour is *Terminate* and
that one wedges an amplifier.

⚠ **The Configurator's own console is reached the same way**, by selecting `quickStimulus` in the
service tree: it lists itself. There is deliberately no second control in the application's menu
bar — one route, and the menu an entry lives in states its scope.

The current state travels in the service description as `consoleVisible`, with `consoleControl`
beside it saying the service understands the verbs at all — so a client can render a checkbox that
is right, and grey it out against a binary that predates the feature. Both keys are additive: the
wire record's `parameters` field is `ANY()`, i.e. free-form JSON.

⚠ **A console must not be able to kill the service it is reporting on.** Killing an amplifier
service mid-acquisition wedges the device until it is physically replugged
([§14f](../incidents/README.md)), and killing `neuroMS` leaves a stimulator charged. So on a console
this process allocated: `SC_CLOSE` is deleted from the system menu (which also disables Alt+F4);
`ENABLE_PROCESSED_INPUT` is cleared so **Ctrl+C never becomes a `CTRL_C_EVENT`** — stronger than
swallowing it, because handlers run last-registered-first and swallowing only stops the ones
registered *earlier*; and a close/logoff/shutdown event asks Qt to quit and waits, so `aboutToQuit`
— where services put their hardware-safe teardown — actually runs. **Untick the option to close
the window.**

⚠ Three Win32 facts this is built on, all measured here and all counter-intuitive enough to be
worth carrying:

* **`AllocConsole` resets the process's control-handler list.** A handler a service registered
  while it had no console — which is every service — is *not* in the list afterwards. A handler
  registration is likewise scoped to the console attached when it was made, so after a hide/show
  cycle an earlier registration is gone and Ctrl+C kills the process with `STATUS_CONTROL_C_EXIT`.
  Anything that re-attaches must re-register.
* **`FreeConsole()` alone does not close the window.** The `CONOUT$`/`CONIN$` handles opened when
  the console was attached keep it alive. The streams have to be pointed back at `NUL` first.
* **`AllocConsole()` installs the new console's handles as the process's standard handles** — so
  `GetStdHandle(STD_ERROR_HANDLE)` asked *afterwards* always answers "usable", while the CRT's
  `stderr` FILE*, fixed at start-up when there was no console, is still attached to nothing. The
  Win32 handle and the C stream are different objects and only the second is what `fprintf` writes
  through. Binding the streams must be unconditional on a console this process allocated; deciding
  it from the handle gives a console that opens, reports itself visible, and stays **permanently
  empty**. That shipped for one iteration and is the reason this bullet exists.

---


<a id="history-11d-design-rule-every-executable-carries-its-own-icon"></a>

## 11d. Design rule: every executable carries its own icon

**Added 2026-09-06.** A rig runs a dozen Resonance processes at once, and until now every one of
them sat on the taskbar behind the generic Windows executable glyph — the recorder, the playback
controller, the TEP·SOUND console and the Configurator were four identical white rectangles, told
apart only by hovering. Every executable in `R:\dist\bin` now embeds an icon, and every window a
service opens shows it.

**One visual language.** A rounded tile whose **colour is the family** — navy for the framework
runner, violet for operator applications, teal for sources and processing, blue for input devices,
orange for actuators, grey for bridges and helpers — and a **white glyph that is the job**: sliders
for the Configurator, the record ring, the play triangle (hollow for the playback *source*), a
monitor with a cue for stimulus presentation, a dashed TMS marker followed by an evoked potential
for TEP·SOUND, a heart with an ECG for KARDi2, the figure-8 coil for Neuro-MS, a bolt for eStim, a
pulse train for arduinoTTL. The EEG amplifiers share the topoplot-head glyph and differ by a badge
(`52`, `136`, `2021`, `NS`, `aC`), because at 16 px nothing else tells five amplifier drivers apart.
Masters, rendered `.ico` files, the tools and the full table are in **`R:\src\icons\`**
(`README.md` there; `preview.png` shows every icon at every taskbar size on both grounds).

**The mechanism is one CMake line.** `resonance_icon(<target> <icon>)`, after `install_target()`,
generates a `.rc` that embeds `icons\ico\<icon>.ico` under the resource name **`IDI_ICON1`**. That
is the name Qt's Windows platform plugin loads for every window class it registers
(`qwindowscontext.cpp`), so QML `ApplicationWindow`s and `QMainWindow`s alike get the icon with no
per-window code — and Explorer and Task Manager read the same resource. The `.ico` is an
`OBJECT_DEPENDS` of the generated `.rc`, so a re-rendered icon rebuilds the executable. The KARDi2
x86 broker is a separate Qt-free project and carries its own `broker\icon.rc` under the same name.

Three things sit on top of that, and each is there for a reason worth keeping:

* **`quickStimulus` sets its icon *and its taskbar identity* per built-in tool, before any window
  exists.** One executable runs the Configurator, the legacy recorder and the message sender, so
  `main.cpp` calls `QGuiApplication::setWindowIcon()` with the tool's own icon from `res.qrc`. ⚠
  The picture alone was not enough: Windows files taskbar buttons by the process's
  AppUserModelID, which `ResonanceApp::setServiceName()` derives from the service name — and the
  recorder and the message sender rename their service **from QML, after the window is already on
  screen**. Measured: the message sender landed in the Configurator's button, wearing the
  Configurator's icon. `main.cpp` therefore sets `Resonance.QuickStimulus.<Configurator |
  Recorder | MessageSender>.1` first; the two renamed tools compute the identical string later, so
  nothing moves, and the Configurator keeps its service name (it lists itself as `quickStimulus`)
  while no longer sharing a button with an experiment loaded with `-l`.
* **The debug console gets the service's icon too** (`DebugConsole.cpp`, on the console this
  process allocated), so a `--console` window on the taskbar says whose output it is. Classic
  conhost only — under a pseudoconsole host `GetConsoleWindow()` is a hidden window and the
  message is harmlessly lost.
* **The recorder's tray icon is deliberately *not* this icon.** It is a coloured dot whose colour
  is the recording state, and that is the tray's whole job.

⚠ A `Qt.Tool` window — the recorder's always-on-top status strip — never carries an icon and never
appears on the taskbar; that is Qt's window-class rule, not an omission. And a running service
holds its executable and `Resonance.dll` open, so a redeploy over it fails on those two files:
either stop the service first, or rename the locked files aside (Windows allows renaming a running
image) and let the install write fresh ones — the process keeps running on the renamed copy.

**Where the icons are read back out again (2026-09-07).** Two things use the embedded icons
beyond the window they belong to:

* **The Configurator's icon strip.** The right-hand part of its menu-bar row — always empty
  before — holds one button per line of `<root>\launchbar.txt`, a file the operator owns: which
  launchers, in what order, in which groups (a `[heading]` line starts one, drawn as a thin
  separator), with what tooltip, and optionally with what icon. By default a button wears the
  icon of the executable its launcher starts, read out of that executable's `IDI_ICON1` at run
  time (`quickStimulus\launchbar.cpp`, `LaunchBar.qml`); a line may instead name a `.ico` from
  `<root>\icons\` — every rendered icon ships there, `nvx136-25k.ico` included, for a second
  launcher with a 25 kHz preset — or an executable and one of its numbered groups
  (`bin\quickStimulus.exe,-102`). `launchbar-default.txt` is the shipped strip, overwritten by
  every deploy: general tools, then acquisition, then stimulation, in words an operator reads. It
  is copied to `launchbar.txt` when that file is missing and never touched afterwards, so a
  rig's edits survive every deploy. The file is watched and the strip follows a save;
  **View → Edit icon strip…** opens the folder with the file selected, **View → Show icon strip**
  hides the bar, and the choice is remembered with the Configurator's settings. A launcher named
  in the file but absent shows greyed out, with its path in the tooltip. A click runs the
  launcher through a hidden `cmd.exe` from the distribution root — what a double-click in
  Explorer does, minus the console flash.
* **The `launch\` shortcuts.** A `.bat` cannot carry an icon — Explorer draws the batch-file
  glyph for the extension, whatever the file says — so `scripts\make-launcher-shortcuts.ps1`
  writes `<root>\launch\<name>.lnk` for the same set of launchers, each wearing its executable's
  icon. The three quickStimulus built-ins use the numbered icon groups `resonance_icon()` embeds
  beside `IDI_ICON1` (`101=configurator 102=recorder 103=message-sender`, reached as
  `quickStimulus.exe,-101`); named resources sort before numbered ones, so the emblem stays the
  executable's own icon. Shortcuts hold absolute paths: `deploy-qt6.ps1` runs the script as its
  last step, and a copy ships in `tools\` to be re-run wherever the distribution is copied to.

---

