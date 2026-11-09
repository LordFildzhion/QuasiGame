# 2026-08-19 — every service takes `--console`, and can be given one while it is running

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-19--every-service-takes---console-and-can-be-given-one-while-it-is-running"></a>

### 2026-08-19 — every service takes `--console`, and can be given one while it is running

Full reference: **[architecture §11c](../migrations/framework-evolution.md)**. Until now exactly one binary in the
tree could show its own output — `quickStimulus`, via a `--console` flag and a Settings menu item
that only reached the Configurator's own process. Every other service was a `WIN32` binary whose
`qDebug()`/`qWarning()` went nowhere, and the two documented ways round that (`Dbgview.exe`,
`QT_FORCE_STDERR_LOGGING=1` plus a real redirect) both need setting up before the interesting
thing happens.

⚠ **Worse than absent: passing `--console` to any other service *killed* it.**
`QCommandLineParser::process()` exits on an option it does not know, and on a windowed binary the
complaint is a message box nobody is watching. Measured on the old build: `SPEED.exe --console` →
`SPEED: Unknown option 'console'.`, process gone.

`quickStimulus`'s implementation moved into the framework as `Core/Resonance/DebugConsole.{hpp,cpp}`
and its local copy was deleted, so there is one mechanism and three routes into it:

| | |
|---|---|
| `--console` | registered by `ResonanceApp` for **every** service, honoured before Qt has parsed anything, and documented in each service's `--help` |
| `!showConsole` / `!hideConsole` | EventBus verbs. **System → Show console** in the Configurator, on a service **already running** — which is the case that matters, since relaunching to add a flag destroys the state being investigated |
| `ResonanceApp::setDebugConsoleVisible()` | for a service's own window; `ResonanceApp.debugConsoleVisible` in QML |

The description carries `consoleVisible` and `consoleControl` (additive keys in an `ANY()` field,
so old clients ignore them), which is what lets one entry read *Show console* or *Hide console*
correctly whatever opened it, and grey itself out against a binary that predates the verbs.

**It lives in `System`, not in the application's menu bar**, and that was the operator's call
against a first version that put it in *Settings*. The reasons hold up: `System` is already the
menu of framework verbs for the selected service (`!recordToFile=`, `!stopRecording`,
`!terminate`), so the console belongs there by kind; it sits inside the panel that is already
showing one service, so nothing has to name which service is meant and it cannot re-target under
the operator when the tree selection moves; it is in `ParametersView`, so every embedder of that
component gets it — the Configurator and the five harnesses in `R:\config` — and not the
Configurator alone; and `ParametersView`'s menu is already Qt Quick Controls 2, where the
application menu bar is Controls 1, which does not exist in Qt 6. ⚠ A **separator** was added above
*Terminate* at the same time: the console entry is one an operator will use often and *Terminate*
wedges an amplifier until it is replugged, so they should not be adjacent. The Configurator's own
console is reached by selecting `quickStimulus` in the tree, which it lists — so there is no second
control anywhere.

**Two defects reported with the feature, both fixed.** *Unticking the option did not close the
window* — `FreeConsole()` alone never does, because the `CONOUT$`/`CONIN$` handles opened when the
console was attached keep it alive; the streams are pointed back at `NUL` first. And *closing the
window killed the application* — it now cannot be closed: `SC_CLOSE` is deleted from the system
menu, which disables Alt+F4 with it.

⚠ **The inherited attach policy was wrong and is gone.** `AttachConsole(ATTACH_PARENT_PROCESS)`
*succeeds* against the `cmd.exe` a launcher's `start` leaves behind — a console outlives its
creator while anything is attached — so `--console` through a `.bat` reported success and showed
the operator **nothing**. On Windows 11 the usual sanity check cannot see the difference either:
the console host is a pseudoconsole and `GetConsoleWindow()` is a hidden `PseudoConsoleWindow`
in both cases. Measured, then replaced: a service launched by `start` has no console at all, and a
process launched directly from a shell inherits one, so the *presence* of a console is itself the
discriminator and no guessing about parents is needed.

⚠ **One iteration shipped an empty console**, caught by the operator and worth recording because
the cause is a genuine Win32 asymmetry: `AllocConsole()` installs the new console's handles as the
process's standard handles, so a guard that asked `GetStdHandle(STD_ERROR_HANDLE)` *after*
allocating always saw "already usable" and skipped the `freopen` — while the CRT's `stderr` FILE*,
fixed at start-up when there was no console, was still attached to nothing. The window opened,
`consoleVisible` read true, and not one line ever appeared. The streams are now bound
unconditionally on a console this process allocated. ⚠ The check that caught it is the one that was
missing: the console's **screen buffer is now read back** — 19 lines against 0 before — rather than
inferring from the window existing.

⚠ **A console must not be able to kill the service it reports on** — this tree's standing rule is
that killing an amplifier mid-acquisition wedges the device until it is replugged
([§14f](../incidents/README.md)), and `neuroMS` would be left with charged capacitors. Adversarial
review found three ways it still could, all now closed and all counter-intuitive enough to be worth
recording:

* **`AllocConsole` resets the process's control-handler list.** A handler registered while the
  service had no console — which is every service, including `neuroMS`'s capacitor discharge — is
  not in the list afterwards. So close/logoff/shutdown asks Qt to quit and waits, and `aboutToQuit`
  (where that teardown actually hangs) runs.
* **A handler registration is scoped to the console attached when it was made.** After one
  hide/show cycle an earlier registration is gone; the first implementation latched "installed
  once" and left the second console with the X removed and no handler at all, so Ctrl+C killed the
  service with `STATUS_CONTROL_C_EXIT`. Re-applied on every attach now.
* **Swallowing Ctrl+C in a handler is not enough**, because handlers run last-registered-first and
  returning TRUE only stops the ones registered *earlier*. `ENABLE_PROCESSED_INPUT` is cleared
  instead, so the keystroke never becomes an event — which matters because Ctrl+C is also the
  console's copy shortcut, and an operator copying a log line is one missed selection away from
  stopping the rig.

**Verified on `R:\dist\msvc64`:** `SPEED.bat --console` gives a window titled *Resonance - SPEED
debug output* with its close button removed; `!hideConsole` closes it and the service lives;
`!showConsole` opens one on a service that started without it (`signalGenerator`, `Recorder`);
20 toggles, 0 state mismatches, no handle growth; Ctrl+Break into a **re-shown** console leaves the
service running, where the first implementation died; `-console` (single dash, which Qt reads as
`-c -o -n -s -o -l -e`) is refused by the raw scan too, so it cannot half-attach; 430/430 targets,
**15/15 unit suites**, Configurator loads with no QML errors, and the import table of every binary
is unchanged apart from `Resonance.dll` gaining `USER32.dll`.

Also: `configurator.bat`, `generator.bat` and `recorder.bat` pass `%*` — they were the three
launchers that swallowed their arguments, so `configurator.bat --console` did nothing.

**New: [architecture §9a](../migrations/framework-evolution.md) — the Qt 6 migration inventory**, written because
this work kept running into the question. Measured against the installed Qt rather than estimated:
**Qt 5.15.2 ships no Controls 2 `TreeView` and no Controls 2 `TableView`** — `TreeView` arrived in
Qt 6.3 with a different API — so the Configurator's service tree, `ParametersView`'s `TabView` and
the two channel-list parameter delegates **cannot be ported before the Qt 6 move**; there is
nothing to port them to. The Controls 1 usage is also structurally coupled: a Controls 1
`ApplicationWindow` accepts only a Controls 1 `MenuBar`, so the menu bar cannot move on its own.
§9a lists every remaining file, what it uses, and the order that costs least — four dead files to
retire first, then the two self-contained service windows, then eight of the ten parameter
delegates. ⚠ The delegates need density work as well as type renames: Controls 2 floors every
control at 100×40 px through its *background*.

