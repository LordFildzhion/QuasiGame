# Qt 6 — further work — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../issues/README.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-qt-6--further-work"></a>


**Written 2026-09-02**, from a 12-dimension audit of both trees and both distributions in which
every finding was independently re-verified against the files by a second reader. 199 findings were
raised; 1 was refuted outright and 30 were down-graded on verification. What survives is below,
ordered by *when it has to be done*, not by how interesting it is.

Companions: [`build_qt5-to-qt6-transition.md`](qt5-to-qt6-transition.md) for the layout and
migration rules; [`arch_qt5-still-needed.md`](qt5-still-needed.md) for the porting backlog.

---


<a id="history-1--two-confirmed-regressions--backported-rebuilt-and-deployed-2026-09-02"></a>

## 1. ✅ Two confirmed regressions — BACKPORTED, REBUILT AND DEPLOYED 2026-09-02

Both had the same cause: **`R:\src_Qt5` kept receiving rig-driven fixes after the Qt 6 snapshot was
taken, and neither reached the port.** In both cases the Qt 6 tree shipped a design the rig had
already falsified.

> ### ✅ What was done, and how it was checked
>
> **`nvx136` was resynchronised wholesale** from `R:\src_Qt5`: `nvx136driver.{h,cpp}`,
> `nvx136config.{h,cpp}` and the three affected test files were copied across. The module is now
> byte-identical to the Qt 5 one apart from its `find_package(Qt6 …)` line, the
> location-independent `NVX136.bat`, and the Qt-5-only `tracer/` diagnostic. Nothing was lost in
> the copy: neither tree's nvx136 uses a single Qt-5-removed API, so the sources are
> Qt-version-neutral.
>
> **`neuroMS` was merged, not replaced.** The Qt 5 `standby` state, its `disconnect` transition,
> the `enteredOperatingState()` signal and the `NMS_GetCapabilities`-failure guard came across;
> the Qt 6-only paired-pulse handshake fix was re-applied on top. The latent mismatch flagged
> below was resolved at the same time: `expectedIpiMicros` is now derived with the same
> `usesInterval(modeFor(caps.stimState, requested))` test the driver uses, so a single-block unit
> can no longer fail verification for the whole handshake budget after doing exactly as it was told.
>
> **Verified at the binary level**, against the Qt 5 build of the same source:
>
> | marker | new Qt 6 | Qt 5 reference | old Qt 6 |
> |---|---|---|---|
> | `pre-start sequence` | ✅ | ✅ | — |
> | `cold_start_pause_ms` | ✅ | ✅ | — |
> | `legacy -- skipped` | ✅ | ✅ | — |
> | `rescan (probe)` | ✅ | ✅ | — |
> | `converter power-cycle` (falsified) | — | — | ⚠ present |
> | `enteredOperatingState` | ✅ | ✅ | — |
> | `reapplied` / `differs from the requested` (Qt 6 handshake) | ✅ | — | ✅ |
> | `set the delay to 0 ms` (superseded) | — | ⚠ present | — |
>
> nvx136 matches the Qt 5 reference on every marker and the falsified mechanism is gone; neuroMS
> carries **both** change sets, which is the whole point of the merge.
>
> Build: 241/241 targets, zero errors. Tests: **25/25 enabled CTests pass**, four hardware/external
> tests disabled by design. Deployed to `R:\dist` after a `bin.pre-20260902-backport` rollback
> copy; `validate-dist-qt6.ps1`, `validate-quickstimulus-builtins.ps1` and
> `validate-qt5-interop.ps1` all PASS against the redeployed package.
>
> ⚠ **What is still owed is the rig.** No Qt 6 build has ever driven a physical amplifier or
> stimulator. The NVX-136 cold start is recorded as unproven on hardware in *both* generations
> ([`arch_known-issues.md`](../incidents/README.md) §24), and `NVX136_2021` (§1c) exists so that the
> next session can settle it by comparison.

The original findings are kept below, because the reasoning is what makes the fix checkable.

<a id="history-1a-nvx-136-cold-start--the-qt-6-driver-reinstates-three-falsified-hypotheses"></a>

### 1a. NVX-136 cold start — the Qt 6 driver reinstates three falsified hypotheses

`R:\src_Qt5\nvx136\nvx136driver.h:60-81` records, in the working tree, that **three cold-start
hypotheses have been falsified at the rig**: the reopen ladder, the converter power-down, and
`NVXSelectDevice`. The Qt 5 driver now performs only the four calls the working driver made before
`NVXStart` (`legacyStartSequence = true`, `nvx136driver.h:82`), defers `NVXGetProperty` /
`NVXSetChannelsEnabled` until after the start, drops `NVXGetDevices` / `NVXSetDevices` /
`NVXSelectDevice` from the pre-start gap, and uses `probe()` itself as the Rescan step.

`R:\src\nvx136\nvx136driver.cpp` (dated 2026-08-27, two days before the Qt 5 fix) still makes the
full nine-transaction pre-start sequence, calls `NVXSelectDevice`, and cures failures with
`powerCycleConverter()` — `NVXOpenEx(PowerDown)` + `NVXClose` at `:574-598`, called from the
recovery ladder at `:656`. That is the converter power-down by name.

Confirmed in the deployed binaries, not just the source: `R:\dist\bin\nvx136.exe` contains
`"converter power-cycle"` and none of `"pre-start sequence"`, `"NVXSelectDevice"` or
`"cold_start_pause_ms"`; `R:\dist_Qt5\msvc64\bin\nvx136.exe` is the mirror image.

**Consequence:** running the Qt 6 NVX-136 reintroduces the cold-start failure the last two weeks of
field work were spent eliminating, on the lab's primary amplifier.
**Fix:** resynchronise `nvx136driver.{h,cpp}` and `nvx136config.{h,cpp}` from `R:\src_Qt5`.
**Related, same re-copy:** the operator-settable `cold_start_pause_ms` parameter
(`Parameters::Integer`, group `hardware`, order 135, range 0…60 000, default 500) exists only in
Qt 5; the Qt 6 driver hard-codes `ColdStartRecoveryPauseMilliseconds = 500` at
`nvx136driver.cpp:49`. The parameter exists **because the pause is the last unexplained variable in
the cold start and the rig needs to sweep it** — the Qt 5 description says 500 ms "is known NOT to
be enough on a freshly powered-on amplifier". Without it the next lab session cannot produce that
measurement. (A Qt 5 parameter file still loads into the Qt 6 service; the unknown key is reported
and every other entry applies. Only that one value is ignored.)
⚠ **The Qt 6 nvx136 test suite asserts the falsified cure**, so it passes while modelling behaviour
the rig disproved. Re-copy the tests with the driver.

<a id="history-1b-neuro-ms--the-standby-state-is-missing-so-a-switched-off-stimulator-still-offers-charge"></a>

### 1b. Neuro-MS — the `standby` state is missing, so a switched-off stimulator still offers Charge

`R:\src_Qt5\neuroMS\neuromsconfig.cpp:396` creates a `standby` state; `:467-468` sends `ready`,
`charging` and `charged` there on `leftOperatingState()`; `:469` returns to `ready` on
`enteredOperatingState()`; `:471` gives standby its own `disconnect` transition. The comment above
it is explicit about why:

> ⚠ `ready` IS NOT THE RIGHT DESTINATION, and sending it there was the first attempt at this.
> Reported back from the rig 2026-08-26: it moved the problem rather than removing it, because
> `ready` offers **Charge**.

`R:\src\neuroMS\neuromsconfig.cpp:458` is that first attempt — `leftOperatingState()` → `ready`,
over `{charging, charged}` only, with the comment "`ready` is the honest destination". The Qt 6
driver has no `enteredOperatingState()` signal at all, so there is **no return path**: switch the
machine back on and the service does not move.

The Qt 6 in-code justification — that `updateParameterAvailability()` takes the buttons away — is
wrong. That function is byte-identical in both trees and only touches parameters plus the `fire`
Action; it never disables a `QStateMachine` transition, so `charge` stays offered on `ready`.

Confirmed in the binaries: `enteredOperatingState` appears twice in
`R:\dist_Qt5\msvc64\bin\neuroMS.exe` and zero times in `R:\dist\bin\neuroMS.exe`. The Qt 6 module
was copied from the Qt 5 working tree about **five hours** before the Qt 5 tree received the fix.

**Third hunk of the same fix, also missing:** on an `NMS_GetCapabilities` failure the Qt 5 driver
(`neuromsdriver.cpp:186-196`) computes whether it *could* stimulate before clearing `m_caps` and
emits `leftOperatingState()` if so. The Qt 6 driver (`:185-189`) clears capabilities and returns
silently, leaving the state machine in `charged` describing a device it has lost.

**Fix:** port `neuromsconfig.{h,cpp}` and `neuromsdriver.{h,cpp}` from `R:\src_Qt5`, then **re-apply
the Qt 6-only paired-pulse handshake fix on top** — the two changes touch adjacent code and must be
merged, not chosen between. The Qt 6 fix is real and worth keeping: the post-connect handshake used
to overwrite a requested paired-pulse interval with zero, silently converting paired to
simultaneous; it now re-applies and verifies the operator's quantised interval.

⚠ While merging, resolve one latent inconsistency the Qt 6 handshake introduced: `neuromsconfig.cpp:797`
computes `expectedIpiMicros` with **no mode test**, while `neuromsdriver.cpp:534` writes
`usesInterval(mode) ? quantiseIpiMicros(ipiMicros) : 0`. On a single-block unit with a non-zero
`delay` the echo can never match and the handshake retries to exhaustion. Apply the same
`usesInterval(modeFor(...))` test on both sides, or have the driver report its applied interval back
rather than recomputing it. ✅ Done — the first of the two options.

<a id="history-1c--new-2026-09-02-nvx136_2021-so-the-cold-start-can-be-settled-by-comparison"></a>

### 1c. ✅ New 2026-09-02: `NVX136_2021`, so the cold start can be settled by comparison

> **Retired 2026-09-07.** The comparison below is done and the comparator is out of the build and
> the distribution (`add_subdirectory` commented out, `bin\nvx136_2021\` and `NVX136_2021.bat`
> removed). `R:\src\nvx136_2021\` stays for reference. This section is kept as the record.

`R:\dist\NVX136_2021.bat` starts a **second** NVX-136 service built from the 2021 driver and linked
against the **2021** vendor SDK. The mainline driver makes nine device transactions before
`NVXStart`; this one makes four —
`NVXOpen → NVXSetSettings → NVXSetAuxGain → NVXSetPll → NVXStart → NVXGetProperty` — which is the
sequence the operator reports has never failed to start a cold amplifier.

`R:\src\nvx136_2021` is byte-identical to `R:\src_git_branches\feature-conan2\nvx136` except
`main.cpp`, which changes only the service name and the `--emulation` flag test. The mainline
driver's `legacyStartSequence` option reproduces the same *shape* at run time; this module is the
binary-level control — different executable, different DLL, no shared code path. If the mainline
driver in legacy mode still fails where this one starts, the cause is not the call sequence.

⚠ **Both SDK generations ship a file called `NVX136.dll`.** The pairing is enforced by layout: the
2021 executable installs into `bin\nvx136_2021\` with its own copy of the 2021 DLL and the three
bitstreams beside it, and Windows searches the application directory before `PATH`. Verified on the
deployed package with both services running at once — `nvx136.exe` loaded `R:\dist\bin\NVX136.dll`
(md5 `4b4bdda0…`) and `nvx136_2021.exe` loaded `R:\dist\bin\nvx136_2021\NVX136.dll`
(md5 `2c18ba10…`). Full detail in `R:\src\nvx136_2021\README.md`, installed beside the executable.

⚠ **Both register as `NVX136`, so RUN ONE OR THE OTHER, NEVER BOTH.** That is deliberate: every
saved parameter file, harness and protocol that names `NVX136` drives whichever one is running, so
swapping generations changes nothing else on the rig. Two services answering to one name on one bus
would be an ambiguity, not a comparison. Both also start from the same shipped defaults (⚠1e), which
is the other half of what makes a comparison readable.

---


<a id="history-1d--reported-and-fixed-2026-09-02-a-chosen-ced-never-reached-the-amplifier"></a>

## 1d. ✅ Reported and fixed 2026-09-02: a chosen `.ced` never reached the amplifier

Reported from the field: **electrode layouts did not load** under the Qt 6 nvx136. Nothing in
nvx136 was responsible, and neither was the CED parser — the failure was in the one shared
`Resonance__Parameters__File.qml` used by every `Parameters::File` in the tree (`ced` in `nvx`,
`nvx136`, `DAQmx`, `neuronSpectrum`; `ced`/`eegCed`/`epochCed` in `SignalGenerator`).

**Root cause — the same one as the parameter Save/Load repair, in a control that repair did not
cover.** The chooser read the selected file with `XMLHttpRequest` GET, carried over verbatim from
Qt 5. Qt 6 refuses that:

```
XMLHttpRequest: Using GET on a local file is disabled by default.
```

⚠ **And it refuses it by never advancing the request to DONE.** The `onreadystatechange` handler
therefore never ran: no callback, no error, no value. `fileName.text` was set *before* the request,
so the operator saw the filename they had picked appear beside the button while the parameter
stayed empty — a failure that looks exactly like success. Measured on the deployed build with
`scripts/ced-xhr-probe.qml`: `CED_XHR_REACHED_DONE=false`.

**Fix.** `ParameterFile::read()` in C++, exposed as `ResonanceApp.readFileContents(url, binary)`,
mirroring the `saveParameterFile`/`loadParameterFile` pattern. It reports open and read errors,
refuses a non-local URL, refuses an **empty** file by name (an empty layout is indistinguishable
downstream from the parameter never being set, which is the failure it replaced), and returns the
value already encoded the way `File::setJson()` expects. The QML now shows the error text beside
the filename instead of failing silently.

⚠ It also corrects a latent inversion: the old QML called `atob()` — which *decodes* base64 — on
bytes that were never encoded, for the binary case. It had never run, because every
`Parameters::File` in the tree is a text electrode layout.

**Coverage.** Seven new `ParameterFileRead` cases (text contents byte-exact including CRLF and
tabs, base64 round trip, native path as well as `file://` URL, missing file, empty file, non-local
URL, and a real shipped montage) plus `ParameterFileQml.ReadsAShippedMontageThroughTheRealSingleton`,
which crosses the actual QML-to-C++ boundary the chooser uses. Both run under CTest. On the
packaged build the probe reports `CED_CPP_OK=true`, 272 bytes, header row intact.

⚠ **Worth a sweep:** `XMLHttpRequest` was the tree's habitual way to touch a file from QML, and Qt 6
has now broken it twice in two different controls. `grep -rn XMLHttpRequest R:\src` before assuming
there is not a third.


<a id="history-1e--reported-and-fixed-2026-09-02-the-nvx-136-shipped-starting-point"></a>

## 1e. ✅ Reported and fixed 2026-09-02: the NVX-136 shipped starting point

Reported from the field: the mainline NVX-136 came up on 250 Hz with block 25 and no montage, and
only it had any channels selected — the 2021 variant had none. The defaults were in
`params\nvx136_default64ch.json`, applied by `NVX136.bat` via `--serviceConfig`, and that only ever
worked for launches that went through the launcher.

A fresh launch of **either** generation now comes up on **1 kHz, block 50, the first 64 EEG channels
plus the trigger, and `mks64_standard.ced`**, from `R:\src\nvx136\nvx136defaults.hpp` — shared
verbatim by both, because a comparison between two drivers that start from different settings says
nothing. Full reasoning in
[`build_qt5-to-qt6-transition.md`](qt5-to-qt6-transition.md) §4b.

Three implementation notes worth keeping:

* The rate is chosen **by value, not by index** (`selectByValue`). An index is a position in a list
  somebody will eventually reorder, and the failure would be silent: a different sampling rate.
* The channel selection is applied **once**, the first time the list has a shape. It cannot go in
  the constructor — there is no channel list until a device has been probed, and `setChannels()`
  resizes the selection to all-false — and it must not be re-applied on every refresh, or
  changing mode or rate would silently undo the operator's own ticks.
* The selection matches channels **by name**, so one default serves both generations even though
  they build their lists in different code, and an AUX channel cannot be ticked by landing in the
  first 64 slots.

`test_Nvx136Defaults` asserts the numbers themselves, so changing any of them has to be deliberate.
Verified on the deployed package with `scripts/nvx136-defaults-probe.qml`, which reads the service
off the bus rather than the source: `1 kHz`, block `50`, 4581 bytes of CED, `65/137` channels —
for both executables.


<a id="history-1f--reported-and-fixed-2026-09-02-channel-list-select--space-did-nothing"></a>

## 1f. ✅ Reported and fixed 2026-09-02: channel list, select + Space did nothing

Reported against `nvx136`, `nvx136_2021` **and** the regular `nvx` at once, which is the clue: all
three render `Parameters::ChannelsList` with the same shared
`quickStimulus/import/Resonance/Resonance__Parameters__ChannelsList.qml`.

**Root cause.** The Qt 5 editor was a Controls 1 `TableView` with a real selection model and its own
key handling. The Qt 6 rewrite hand-rolled the selection and put `Keys.onSpacePressed` on the
ListView — but nothing ever gave that list **active** focus. `focus: true` only sets focus within
the component's own scope, which is inert until something up the chain hands the scope active focus,
and a MouseArea does not take focus by design. So the row highlighted, the keystroke went elsewhere,
and the channel did not move.

**Fix.** Every path that selects a row now calls `forceActiveFocus()` on the list. Three things came
with it, because the original was inconsistent in a way that would have made the fix confusing:

* the arrow keys move the **selection**, not just an invisible `currentIndex`. Before, they walked a
  cursor nothing drew while Space kept toggling whatever the mouse had last selected — two
  different notions of "the current row" with only one of them visible;
* the current row is **drawn** while the list holds the keyboard, so the operator can see what the
  next keystroke will do;
* the list is reachable with Tab, and Ctrl+A selects every channel.

`test_ChannelsListQml` covers it with real mouse and key events through a real window: select then
Space, Space again to untick, arrows moving what Space acts on, Shift+arrow extending a range, and
the tick box still working with no keyboard at all. Six cases, all passing.


<a id="history-1g--found-while-fixing-1f-the-build-tree-ran-stale-qml"></a>

## 1g. ✅ Found while fixing 1f: the build tree ran stale QML

⚠ **`install_directory()`'s POST_BUILD copy only fires when the target RELINKS**, and editing a
`.qml` does not relink `quickStimulusPlugin`. So the staged copy under
`_build/runtime/bin/Resonance` silently stayed at whatever version was current the last time C++
changed. Measured during this work: the staged file was 5254 bytes against 9223 in source.

The build tree therefore ran QML that was no longer on disk, and a QML fix looked like it had done
nothing. `cmake --install` refreshed it, so the **deployed** package was correct and only the build
tree lied — which is the worse way round, because the build tree is what a test runs against.
This is the mechanism behind audit finding "the build runtime and the deployed package diverge"
(§7), and it is now closed for QML: a `quickStimulusQml ALL` target stages the directory on every
build with `copy_directory_if_different`.

---


<a id="history-2-before-a-qt-6-tms-eeg-session-presents-a-cue--the-onset-contract"></a>

## 2. Before a Qt 6 TMS-EEG session presents a cue — the onset contract

In this paradigm **the cue-onset timestamp is experimental data**, so these are changes to the data,
not to the code. Neither is proven wrong; neither is proven right.

* **The frame counter lost its "the output accepted the frame" gate.** Qt 5's `FrameRelay::present()`
  incremented only when the QML `VideoOutput`'s surface returned `true` — the count meant *the
  output took this frame*, so a surface that refused the format, or was never wired, produced no
  count and `StimulusStage` fell into its stall branch and stopped the run naming the cue. Qt 6
  increments on `frame.isValid()` alone, at the `QVideoSink`, upstream of anything
  `QQuickVideoOutput` decides (`videocue.cpp:328-333`). **A rendering-side refusal that Qt 5 turned
  into a loud stall now reads as a clean onset**: the trigger fires on schedule and the subject sees
  black while the record says the cue began. Nothing has observed this; it is structurally reachable,
  and the cost of it happening once is a silently mis-stamped session.
* **`setNotifyInterval(50)` was dropped with no replacement.** For an audio-only cue the onset the
  stage waits on is the first `positionChanged` past the start point — there are no frames to count.
  Qt 5 pinned that signal to a 50 ms cadence, bounding both the onset quantisation and how much
  sound leaks during preroll. Qt 6 removed the API and exposes no application-side control, so the
  granularity of a sound cue's measured onset is now **whatever the FFmpeg backend chooses**, and it
  is measured nowhere.
* ⚠ **No recorded Qt 6 run has ever constructed a `VideoCue`.** The QA launch that produced
  `tepsound-qt6.png` and the "zero media-backend errors" claim shows no `TepSound Qt 6 media
  backend:` line in its stderr, so it exercised none of the ported multimedia code. `test_TepMedia`
  proves FFmpeg decodes and that frames reach a sink the `VideoCue` owns — real and worth having —
  but it constructs a bare `QVideoSink` and bypasses `QQuickVideoOutput` entirely, which is the
  object whose sink is handed over at `stage/MediaLayer.qml:65`.

**Minimum before a subject sees a Qt 6 video cue:** one run with a media row loaded, the backend line
captured, and the stage's `videoOnset` lag values recorded — then a decision on whether to restore
the accepted-frame gate and how to bound the audio-onset cadence.

---


<a id="history-3--the-two-core-problem--closed-2026-09-02"></a>

## 3. ✅ The two-core problem — CLOSED 2026-09-02

`R:\src\KARDi2\qt5-island\Core\Resonance` was a private Qt 5 copy of the framework, compiled only
for the 32-bit island, and once `R:\src_Qt5` became a comparator it was the only maintained Qt 5
core and the only Qt 5 code that still shipped. It had drifted in both directions: 8 of its 125
files differed from the Qt 6 core, 3 from `R:\src_Qt5`'s, and nothing in the tree said which
differences were deliberate. One of the unreplayed ones was a **UDP-facing out-of-bounds read**.

**The island is gone and so is the second core.** KARDi2 is an x64 Qt 6 service linked against the
one shared `Resonance.dll`; only a 164 KiB x86 broker remains 32-bit, and it links no Resonance and
no Qt at all. `qt5-island` is preserved, out of every build, at `KARDi2\_legacy\qt5-island`.

⚠ **Do not delete `KARDi2\_legacy` as dead weight.** Its `3dparty\Driver` subtree is the only copy
of the vendor USB kernel driver in the repository, and `deploy-qt6.ps1` stages it into
`R:\dist\driver\kardi2\`. Removing the island had already silently dropped that driver from the
distribution once.

The remaining KARDi2 risk is **not** a core-drift risk; it is §3a.


<a id="history-3a--the-kardi2-broker-can-die-with-a-trigger-output-latched"></a>

## 3a. ⚠ The KARDi2 broker can die with a trigger output latched

F22 (`service_kardi2.md` §9.4) established that a Sync output is a **device-owned latch**: neither
`K2Stop` nor `K2Close` clears it, and restarting the process does not either. The service clears it
at five points — all of which run only in *orderly* teardown.

The broker introduces a path with no orderly teardown. It installs **no
`SetUnhandledExceptionFilter` and no `SetConsoleCtrlHandler`**, and it sets `SEM_NOGPFAULTERRORBOX`,
so a fault inside the vendor DLL is silent: the broker vanishes and the service sees a closed pipe.
`Config`'s own `m_broker->kill()` has the same shape. Either, with Sync Out asserted, leaves the
**physical trigger output driven** until some process opens the device and clears it.

**Fix:** a `SetUnhandledExceptionFilter` and a `SetConsoleCtrlHandler` in the broker that call
`K2SetTriggers(id, 0)` before dying, and a "clear triggers, then close" request that only escalates
to `kill()` on timeout. Until then this is the KARDi2 form of the standing rule that an amplifier
must be stopped before its service is terminated.


<a id="history-3b--nvx-52-drops-samples-at-5-khz-and-the-driver-pads-them-in-silence"></a>

## 3b. ⚠ NVX-52 drops samples at 5 kHz, and the driver pads them in silence

**Revised three times. The measurements below are the ones to trust; the two earlier readings of
this entry are recorded because the way they went wrong is instructive.**

* *v1:* "the counter is inoperative, the data is fine." Wrong — the data was not fine.
* *v2:* "acquisition corrupts its own stream, 80× inflation." True of what was measured, but it
  blamed the driver for a device state.
* *v3:* "clean after a replug." **Wrong, and wrong for a methodological reason worth naming.**
* *v4, this one:* the device really does drop at 5 kHz under load, the driver really does pad it,
  and until 2026-09-03 it did so **without telling anybody**.

<a id="history--the-method-error-because-it-will-catch-the-next-person-too"></a>

### ⚠ The method error, because it will catch the next person too

v3 concluded "clean" from a delivered-rate measurement: 4999.21 Hz against 5000 declared over 60 s,
so nothing could have been lost. **That inference is invalid whenever the driver pads.**
`processAcquisitionBuffer` injects a NaN row for every sample a counter gap says is missing, so a
lossy run delivers the *expected* count — or more. The clean-looking 60 s run had no electrodes
attached; with real electrodes the same settings drop ~450 samples/s and the delivered rate reads
**5011.60 Hz**, i.e. *above* declared. A negative shortfall is the padding signature.

The operator's evidence settled it: neoRec's counter climbing to 33 402, matching gaps visible in
Resonance's own signal viewer, and an HDF5 recording with full-width NaN rows in it.
`scripts\nvx-rate-audit.qml` now prints `AUDIT_PADDING_DETECTED` rather than letting an excess be
read as rounding.

<a id="history-what-is-actually-happening"></a>

### What is actually happening

At 5 kHz with 53 channels and electrodes connected, the device loses samples steadily — measured
**~450 per second**, 9 120 in a 20 s run. The counter sees the gaps correctly, and the driver pads
them, so the *timeline* stays honest and the recording is full of NaN rows where the data was lost.
That is the right repair. What was wrong was that nothing said it was happening.

⚠ **The warning and the damage are still on opposite branches.** A gap **above**
`MaxRepairableGap = 20000` is warned about and *not* padded; a gap of **1..20 000** is padded and
never logged. The status line (§3d) now covers the second case, but the log still does not.

<a id="history-still-to-do"></a>

### Still to do

1. **Warn on the padding**, not only on the rejection. The branch that alters the data must speak.
2. **Refuse to pad on a non-monotonic counter.** `nvx::logic::missingSamples` is
   `next - previous - 1U` with no guard, so a backwards counter yields ~4.29 billion and one bad
   forward word can inject up to 20 000 fabricated rows. Compare
   `actichamp::logic::missingSamples`, which is `delta > 1 ? delta - 1 : 0`.
3. **Find out why the device drops at 5 kHz at all.** It is not timer starvation: block size 1 at
   5 kHz — a 2 ms buffer against a ~15.6 ms Windows timer, the shape of KARDi2's F23 — survives,
   because `getNextBlock()` drains up to `MaxReadsPerTick = 64` buffers per tick. neoRec reports
   the same loss on the same hardware, which points at the device or the USB link rather than at
   either application.

`nvx/nvxdatathread.cpp` is byte-identical to `R:\src_Qt5`'s, so all of this ships in both
generations. `nvx136` has the identical structure and has not been measured.


<a id="history-3d--the-status-line-shows-dropped-samples--and-the-cross-thread-bug-that-made-it-lie"></a>

## 3d. ✅ The status line shows dropped samples — and the cross-thread bug that made it lie

Implemented 2026-09-02, **fixed 2026-09-03**. A service publishes its running loss total; the
Configurator renders `running, 9120 samples dropped` beside the state and nothing at all when the
count is absent or under 100.

* Framework: `CommunicationLayer::reportDroppedSamples(quint64)` → the `droppedSamples` key of
  `stateInfo`. Throttled to one description broadcast per second, first loss published
  immediately, cleared on every state entry.
* Wired: `nvx`, `nvx136`, `actiChamp`, `KARDi2`.
* Rendered: `ParametersView.qml`, floor 100, red when it speaks. `test_StatusLineQml` covers the
  boundary, the lifecycle and absent-is-not-zero.

<a id="history--the-bug-it-shipped-with-because-the-shape-of-it-will-recur"></a>

### ⚠ The bug it shipped with, because the shape of it will recur

The first version called `droppedThrottle.start()` and, through `setStateInfo()`,
`descriptionDelay.start()` **directly from the caller's thread**. But `nvx` moves its runner to its
own `QThread` (`nvx/application.cpp:25`), and so do `actiChamp` and `KARDi2` — so the caller is the
acquisition thread while the CommunicationLayer and its timers live in the main thread.

`QTimer::start()` from another thread is a **no-op**. It prints

```
QObject::startTimer: Timers cannot be started from another thread
```

to stderr and does nothing. Services are windowed WIN32 binaries with no console, so on the rig
that message went nowhere. The count accumulated perfectly and was never broadcast: measured on an
NVX-52 at 5 kHz, **415 of those warnings — one per block** — a recording visibly padded with NaN,
and a status line reading a calm `running` throughout. `stateInfo` was also being written from one
thread while `sendDescription()` read it in another, which is a plain data race.

**The fix is in the framework, not in each driver**: `reportDroppedSamples` stores the figure
lock-free (`QAtomicInteger`) and hops to the owning thread with `QMetaObject::invokeMethod(...,
Qt::QueuedConnection)`; an atomic wake flag bounds the queued backlog to one outstanding flush no
matter how often the driver reports. `setStateInfo` carries the same guard. Verified: the 415
warnings became 0, and the count now climbs live — 522, 1615, 2671 … 9120 over 20 s.

⚠ **Anything else that touches a QTimer or `stateInfo` from a driver callback has this bug.** The
services thread their drivers; the framework objects do not move with them.


<a id="history-3e--impedance-mode-is-not-labelled-as-impedance--fixed-and-confirmed-on-hardware"></a>

## 3e. ✅ Impedance mode is not labelled as impedance — FIXED and confirmed on hardware

**Reported 2026-09-04 and measured the same day. Fixed the same day and shipped as `p5-impedance-kind`
— `nvx136_2021` now calls `describeOutputs(..., impedance = true)` from `initializeImpedance`, and
`nvx136` guards the CED type with `!m_impedance`. Both are in `R:\dist`.**

✅ **Confirmed at the rig 2026-09-05**: impedance labels correct on both builds. Closed.

The diagnosis below is kept because it explains *why* the two builds needed different fixes.

It matters beyond an axis label. A consumer told a channel is EEG **band-passes** it, and a display
filter over what is essentially a DC level leaves nothing at all — so an impedance check drawn as
EEG shows a flat trace regardless of the electrode.

<a id="history-nvx136-2025-mainline--the-ced-montage-overwrites-the-driver"></a>

### `nvx136` (2025 mainline) — the CED montage overwrites the driver

The driver gets this right: `initImpedanceMode` sets `output.kind = "Impedance"` and
`output.unit = "Ohm"` for every channel. `describeOutputs` then throws the kind away:

```cpp
kinds.append(cedType.isEmpty() ? output.kind : cedType);   // nvx136driver.cpp:1240
```

`cedType` is the montage's `type` column, and `mks128_standard.ced` — the shipped default — carries
`type` = `EEG` on 128 rows and `EMG` on 2. The override exists for a good reason (a TMS montage puts
EMG on ordinary EEG inputs, and nothing in the frame can tell those apart), but it fires in
impedance mode too, where a montage row cannot possibly know that this reading is ohms.

⚠ **GND is the tell.** `output.montage = !isGround`, so GND takes no montage row and keeps its kind.
Measured on the emulated device with the default montage loaded:

```
IMP_channels=65
IMP_kind_tally={"EEG":64,"Impedance":1}     ← the 1 is GND
IMP_unit_tally={"Ohm":65}
IMP_first name=T7   kind=EEG        unit=Ohm    ← self-contradictory
IMP_last  name=GND  kind=Impedance  unit=Ohm
```

`kind=EEG` beside `unit=Ohm` is the signature: the unit survived because nothing overwrites it.

**Fix, when wanted:** let the CED type win only when the stream is not an impedance stream.
`describeOutputs` already knows — it is called from both paths — so it needs one flag, not a
redesign. Do **not** solve it by clearing `montage` for impedance electrodes: that is what supplies
their electrode **names**, and losing those would be a worse regression than the wrong kind.

<a id="history-nvx136_2021--no-kind-is-published-at-all"></a>

### `nvx136_2021` — no `kind` is published at all

Simpler and more total. `initializeImpedance` hands the stream only `addCEDinfo(ced)`, so what
reaches a consumer is the raw CED columns and nothing else:

```
IMP=FAIL the stream publishes NO 'kind' at all -- everything will default to EEG.
properties=["name","type","radius","theta"]
```

No `kind`, no `unit`. Note `type` is published **raw** — the CED column under its own name, which is
not the key any consumer reads.

⚠ This is the *same defect* the 2026-09-04 patch series fixed for the EEG path: `p1-trigger-type`
added `describeOutputs()` to `initializeEeg` only, and `initializeImpedance` was left alone.

**Fix, when wanted:** call the same `describeOutputs()` from `initializeImpedance`, with the
impedance flag the 2025 build will also need — the two builds should share the rule, not each grow
their own.

<a id="history-nvx-regular---not-broken"></a>

### `nvx` (regular) — ✅ NOT broken

Measured on the physical NVX-52, clean session, Impedance mode:

```
IMP_channels=48
IMP_kind_tally={"Impedance":48}
IMP_unit_tally={"Ohm":48}
```

48 of 48, correct kind and correct unit. It is structurally immune: `nvxdatathread.cpp` derives the
kind from the **mode** (`kinds.append(impedance ? "Impedance" : "EEG")`) and takes only the CED
**name**, never a CED `type`. So no montage can overwrite it.

⚠ **A first run against `nvx` did fail**, with `The device reported an invalid channel layout` —
and that is `NVXGetPossibility` answering `EegChannelsCount == 0`, i.e. the degraded-device state
described in §3b, not an impedance defect. It cleared after the device was left alone; a clean
session then gave the correct result above, and Unipolar in the same session gave
`{"EEG":32,"Trigger":1}`. **Do not read a single NVX failure as a code defect without re-testing on
a settled device** — that mistake has now been made twice in this file's history.

Harness: `scripts\impedance-kinds-probe.qml`.


<a id="history-3f--nvx-136-cold-start-solved--one-discarded-read-after-nvxopen"></a>

## 3f. ✅ NVX-136 cold start: SOLVED — one discarded read after NVXOpen

**2026-09-04. The 2×2 is closed, and it eliminates half the search space.**

| | 2021 DLL (1.4.19077) | 2025 DLL (1.5.21743) |
|---|---|---|
| **2021 code** | ✅ starts first try | ✅ **starts first try** ← the new datum |
| **2025 code** | not run, and no longer needed | ❌ fails first try |

The 2021 executable was run against the 2025 DLL by swapping the file — no rebuild, because the
2025 API is a strict superset of the 22 calls it uses. It cold-started on the first attempt, and
its log confirms which DLL answered:

```
dll 1.5.21743.0  driver 3.4.1.146  cypress 1.14.6.3  mc-fpga 0.0.0.18
msp430 11.16.4.12  cb-fpga 0.0.0.37   (NVXGetVersion returned 0)
```

**So the vendor DLL is not the cause. The difference is in our 2025 code.**

⚠ **`NVXGetVersion` is exonerated too, and that contradicts a comment in the source.**
`nvx136driver.cpp::probe()` calls the version query "the prime suspect for the cold-start -3", and
reasons at length about where to place it. But the run above issues `NVXGetVersion` on the open
handle — it is what produced those firmware numbers — and cold start was unaffected. That suspect
can be dropped.

<a id="history-what-is-actually-left-the-probe-session-not-the-start-sequence"></a>

### What is actually left: the probe session, not the start sequence

Both builds open a throwaway device session while populating the channel list, immediately before
the operator presses Start. `legacyStartSequence` was applied carefully to the **start** path and
**not to the probe path**, and that is where the three surviving differences are:

| | 2021 (starts first try) | 2025 (fails) |
|---|---|---|
| right after `NVXOpen` | `NVXGetVoltages` | *nothing* |
| power save | **never sent** | `NVXSetPowerSave` sent on **every probe**, unconditionally |
| probe teardown | `NVXStop` **then** `NVXClose` | `NVXClose` only — the Stop is deliberately skipped |

The start paths themselves have converged: under `legacyStartSequence` the 2025 executes
`NVXOpen → NVXSetSettings → NVXSetAuxGain → NVXSetPll → NVXStart`, which is the 2021 sequence.

⚠ **The power-save asymmetry is the standout**, because the code already knows the rule and applies
it in only one of the two places. `configureCommon` guards the call with
`if (!options.legacyStartSequence || options.powerSave)` and explains why — *"Every call in this gap
is a device transaction and the failing NVXStart times out on one"* — while `probe()` sends it with
no guard at all.

⚠ And a C++ trap that makes it easy to misread: it is written

```cpp
applyOptionalSetting(QStringLiteral("NVXSetPowerSave"), NVXSetPowerSave(m_handle, ...), !powerSave)
```

The device call is an **argument**, so it is evaluated — and sent — before `applyOptionalSetting`
runs. Only the error *handling* is optional, never the transaction. Anything scanning for "which
calls does the legacy path skip" by looking at the guards will miss this one.

The third row deserves attention for going the other way: the **working** build sends an *extra*
`NVXStop` on a probe that never started, and the failing one optimised it away with the comment
*"A probe never calls NVXStart, so it must not pay for a Stop"*. That is sound cost reasoning and
may still be the thing that leaves a cold converter unstartable.

<a id="history--answer-measured-on-hardware-2026-09-04"></a>

### ✅ ANSWER, measured on hardware 2026-09-04

**`NVXGetVoltages` immediately after `NVXOpen` is the cure.** Same rig, same power-cycle procedure:

| build | result |
|---|---|
| q1 (probe skips `NVXSetPowerSave`) | ❌ fails cold start |
| q2 (+ `NVXStop` on probe teardown) | ❌ fails cold start |
| **q3 (+ `NVXGetVoltages` after `NVXOpen`)** | ✅ **first try, confirmed twice** |

The timings say what is happening:

```
without the read   NVXStart returned -3 (NVX_ERR_FAIL) after 3954 ms, twice,
                   with a full recovery cycle in between that did not help
with the read      NVXStart returned 0 (NVX_ERR_OK) after 1210 ms, first attempt
```

Not a marginal pass: the failing start burns ~4 s and the succeeding one takes 1.2 s. A cold
converter needs a completed transaction — or the ~16-32 ms of dwell it costs — before it will
accept a start. The failing diagnostic named it and nobody read it that way: *"an MSP430 command
timed out -- the SDK waits 873 ms for the PLL frequency read and for each per-module select."*

⚠ **It was in the 2021 driver all along, and it looks like dead code**:

```cpp
handle = NVXOpen(deviceIndex);
t_NVXVoltages voltages;
NVXGetVoltages(handle, &voltages);      // result never used
```

That discarded read is the entire difference between a service that starts a cold amplifier and one
that needs a second attempt. It survived into the 2021 build by accident and was dropped from the
2025 rewrite as obviously pointless.

⚠ **What was eliminated first, each at the cost of a lab session:** the vendor DLL (the 2021
executable cold-starts fine against the 2025 DLL), `NVXGetVersion` (the code called it "the prime
suspect" — it is not), the length of the `NVXOpen`..`NVXStart` gap (p4 *added* three settings to the
working build without breaking it), `NVXSetPowerSave` in the probe (q1, no effect), and `NVXStop` on
a probe teardown (q2, no effect).

**Shipped as `q4-minimal-cure` = q3 minus q2, and confirmed on hardware**: `NVXStart` returned 0
after **1188 ms** on the first attempt with q2 dropped, so q2 contributed nothing — as well as
costing up to ~873 ms per Rescan on an unresponsive converter and breaking
`nvx136_cold_start_recovery_test`. It is gone. `R:\dist` carries the cure and validates PASS;
**29/29 ctest**.

⭐ **The cure is guarded by a test, because it will look like dead code to the next reader.**
`Nvx136ColdStart.TheDiscardedVoltageReadHappensBeforeAnyConfiguration` asserts on ORDER, not on a
count — the driver reads voltages again in its failure diagnostic and on the battery poll, so a
count would pass even with the cure removed. The fake SDK gained one field for it,
`setSettingsAtFirstVoltages`: 0 means the read landed after `NVXOpen` and before any configuration.

⚠ **The guard was verified by breaking it**: with the call deleted the test fails with *"NVXGetVoltages
was never called on the start path -- the cold-start cure has been removed from
Nvx136Driver::open()"*. A guard test that has never been seen red proves nothing.

✅ **Causation confirmed both directions, 2026-09-04.** Removing the read from `nvx136_2021` — the
build that had never failed — makes it fail (`x2`, three attempts, each a fresh `NVXOpen`). And
leaving only `NVXGetVersion` in its place also fails (`x1`), even though that is a completed
successful transaction returning real firmware data and costing a comparable ~31 ms.

So it is **`NVXGetVoltages` specifically** — not "any device transaction", and not ~30 ms of
settling time. What the call does to the converter that a version query does not is still unknown;
the failing diagnostic names an **MSP430** command timing out, and reading supply rails is an
MSP430 operation in a way that reading a version register need not be.

<a id="history-built-2026-09-04-the-q-series"></a>

### Built 2026-09-04: the q series

`R:\patches\nvx136_2021_20260904\q{1,2,3}-*` — cumulative, `bin\nvx136.exe` only, one hypothesis
each, for hardware bisection. Not yet tested on a cold NVX-136.

| # | change | ctest |
|---|---|---|
| q1 | `probe()` honours `legacyStartSequence` for `NVXSetPowerSave` | **28/28** |
| q2 | + `NVXStop` before `NVXClose` on a probe teardown | 27/28 ⚠ |
| q3 | + `NVXGetVoltages` right after `NVXOpen` | 27/28, inherited |

⚠ **q2 deliberately contradicts `nvx136_cold_start_recovery_test.GivingUpIsBounded`**, which asserts
`ladder.stop == 2` — it pins the very decision q2 questions ("a probe never calls NVXStart, so it
must not pay for a Stop"). The failure is the test working, not a defect. **The source tree is left
at q1**; q2 and q3 ship as binaries only, because rewriting a test expectation to match an untested
hypothesis destroys the evidence it exists to preserve. If q2 proves to be the cure, the expectation
is updated then, with hardware evidence behind it.

⚠ **A methodological trap that cost time here:** `nvx136_cold_start_recovery_test` links the driver
sources, so a targeted `--target nvx136` build leaves the TEST binary stale and ctest then reports
the *previous* revision's behaviour. It produced a confident and wrong bisection — q1 appeared to
break the test when q1 is clean. Always full-build before believing a ctest result about a driver
change.

<a id="history-proposed-next-step"></a>

### Proposed next step

A cumulative bisection series over `probe()` only, in the shape that worked for `nvx136_2021`:

1. honour `legacyStartSequence` for `NVXSetPowerSave` in `probe()` — one guard;
2. add `NVXStop` before `NVXClose` on a probe teardown;
3. add `NVXGetVoltages` immediately after `NVXOpen`.

Each is a few lines, each is independently reversible, and the first is the one the code's own
reasoning already argues for.

⚠ **Do not record through a swapped DLL.** The swap is a start-up test only: the 2021 code has
never been validated against 2025 firmware behaviour, and a mismatch there would be silent.


<a id="history-3g--sdk-contract-audit-one-real-violation-measured-and-fixed"></a>

## 3g. ✅ SDK-contract audit: one real violation, measured and fixed

Prompted 2026-09-04 by the question *"do we do everything else by the book?"* — fair, having just
told MCS their header documents ordering rules. `nvx.h` documents constraints on **9 of its 42
functions**. Checked all nine against `nvx136`, `nvx136_2021` and (for its own SDK) `nvx`.

| documented constraint | `nvx136` (2025) | `nvx136_2021` |
|---|---|---|
| `NVXSetSettings` — *call before `NVXSetChannelsEnabled`* | ✅ 534 → 606 | ✅ 299 → 434 |
| `NVXSetPowerSave` — *call before `NVXSetChannelsEnabled`* | ⚠ order fine; **skipped entirely** under the legacy sequence | ⚠ same — skipped when `power_save` is off |
| `NVXSetChannelsEnabled` — ***call only in stop mode*** | ✅ 606, before `NVXStart` | ❌ after `NVXStart` — **fixed, patch 6** |
| `NVXSetChannelsEnabled` — `Size` in **bytes** | ✅ `analogChannels * sizeof(bool)` | ⚠ passed the **count** — **fixed, patch 6** |
| `NVXSetActiveShieldGain` — *gain 1..100* | ✅ clamped in config **and** re-checked in the driver | ✅ same |
| `NVXGetVersion` — *NULL handle ⇒ only Dll valid* | ✅ never called with NULL | ✅ same |
| `NVXImpedanceSetMode` — *only `Splitter` is applied* | ✅ writes only `Splitter` | ✅ same |
| `t_NVXImpedanceMode` — *`Splitter == Splitters` ⇒ all electrodes* | ✅ exactly that | ✅ same |
| `NVXImpedanceGetData` — *`NVX_IMP_INVALID` ⇒ not connected* | ✅ → `NaN` | ⚠ → `+infinity` |
| `NVXImpedanceGetData` — *only in impedance mode* | ✅ mode-gated | ✅ mode-gated |
| `NVXSetElectrodes` — LED/analog-switch warnings | ✅ n/a, never called | ✅ n/a |

<a id="history--the-one-real-violation--and-it-is-worse-than-a-spec-breach"></a>

### ❌ The one real violation — and it is worse than a spec breach

`nvx136_2021` line 434 calls `NVXSetChannelsEnabled` **after** `NVXStart` (line 382). The header
says *"call only in stop mode"*. This arrived in **p3**, 2026-09-04, with `disable_unused_channels`
— and the code comment rationalises it: *"applied after NVXStart because it needs the device's own
channel counts, which only NVXGetProperty gives."* That is a reason it was convenient, not a reason
it is allowed. The 2025 build gets the same counts from a pre-`NVXStart` `NVXGetProperty` and has
no such problem.

⚠ **The second defect in the same block is the dangerous one.** `inputSampleSize` is fixed at line
389 from the property read *before* the call, and is never re-read. The 2025 driver states the
opposite behaviour outright:

> *The SDK keeps these property counts unchanged when channels are disabled, but compresses the
> disabled words out of `NVXGetData` frames.*

— which is why it re-reads the property and maintains `m_rawAnalogPhysical` as the wire-to-physical
map. **The two builds hold contradictory beliefs about the same DLL behaviour and only one can be
right.** If the 2025 comment is correct, then enabling `disable_unused_channels` on the 2021 build
parses every frame at the wrong stride — silent channel-shuffled data, not an error.

⭐ **Latent, not live: the parameter defaults to `false` in both builds**, so nothing shipped is
mis-parsing today. But it is a switch in the Configurator, and an operator can turn it on.

⚠ **And the failure is harder than "silently wrong data".** Measured 2026-09-04 on the vendor
emulator with the option ON and 69 of 137 channels selected, the p5 build does not mis-parse — it
never starts:

```
NVX136_2021: NVXSetChannelsEnabled failed with -3. Acquisition refused.
```

The SDK **enforces** its own documented rule: called after `NVXStart`, the request is simply
rejected, the driver's error path fires, and the service stays in `init`. So on the emulator the
wrong frame width never gets a chance to corrupt anything. Whether a real converter also refuses
is unknown — if it accepts, the stride defect is what bites instead. Either way the option was
unusable on that build.

<a id="history--measured-2026-09-04--the-frames-are-compressed-on-both-dll-generations"></a>

### ✅ MEASURED 2026-09-04 — the frames ARE compressed, on both DLL generations

`nvx136/tests/frame_layout_probe.cpp`, built twice (once per SDK) and run against the vendor
emulator. The stride is measured, not assumed: the trailing word of each frame is the sample
counter, so the probe reports every stride at which that word increments by exactly 1 across 16
consecutive frames. **Exactly one stride fit in each run** — no ambiguity to interpret away.

| DLL | analog inputs | left enabled | property afterwards | measured stride |
|---|---|---|---|---|
| 1.5.21743 (2025) | 136 | 136 | CountEeg 128, CountAux 8 | 138 words |
| 1.5.21743 (2025) | 136 | **68** | CountEeg 128, CountAux 8 | **70 words** |
| 1.4.19077 (2021) | 136 | 136 | CountEeg 128, CountAux 8 | 138 words |
| 1.4.19077 (2021) | 136 | **68** | CountEeg 128, CountAux 8 | **70 words** |

⭐ **The 2025 driver was right.** The property counts do not move, the disabled words are
compressed out of the frame, and `m_rawAnalogPhysical` is doing necessary work. The undated comment
turned out to be true — which is luck, not method, and is why it now cites this measurement.

⭐ **The two DLL generations behave identically here.** That contradicts `nvx136/CMakeLists.txt`,
which had claimed since 2026-09-02 that they differ in "hardware channel disable". On this axis
they do not, and the comment has been corrected.

⚠ This is the vendor **emulator**, not a converter. The same executables take
`NVX136_FRAME_PROBE_DEVICE=1` and drive real hardware; one lab run per generation confirms it
against the device. The emulator result is strong enough to fix the code on, not strong enough to
tell MCS anything.

<a id="history--fixed-2026-09-04--patch-6"></a>

### ✅ FIXED 2026-09-04 — patch 6

`nvx136_2021` now calls `NVXSetChannelsEnabled` **before** `NVXStart`, taking its channel counts
from an `NVXGetProperty` issued in stop mode, and keeps two separate widths: `physicalInputs` for
validating the selection against the device, `inputSampleSize` for what the wire actually carries.
`scaleFactors` is compressed to match the wire, because the conversion loop walks exactly
`scaleFactors.size()` words per frame. The `Size` argument is now in bytes.

⚠ The extra property read happens **only when the option is on**, so a default session sends
exactly what patch 2 sent between `NVXOpen` and `NVXStart`. The gap the cold-start failure lives in
is untouched.

**Verified before and after**, same harness (`scripts/nvx136-disabled-inputs-probe.qml`), same
emulated device, option ON, 69 of 137 channels selected:

| build | result |
|---|---|
| p5 (what the lab is running) | ❌ `NVXSetChannelsEnabled failed with -3. Acquisition refused.` — stuck in `init` for all six polls |
| patch 6 | ✅ `running` for the full six polls, **0** gap-spam lines, clean stop back to `init` |

The gap-spam count is the stride check: the driver derives sample gaps from the trailing word of
each frame, so a wrong frame width turns that word into channel data and floods the log with
*"More than N samples are missing between blocks"*. Zero lines means the width is right.

<a id="history--first-field-run-2026-09-05-it-crashed--and-turned-up-two-other-things"></a>

### ❌ First field run, 2026-09-05: it crashed — and turned up two other things

| test | result |
|---|---|
| frame probe, both DLLs | ❌ ran against the **emulator** — `NVX136_FRAME_PROBE_DEVICE` never reached the process, and the output stops after the first of two measurements. No hardware measurement yet. |
| option OFF | ✅ runs — **but the log says `dll 1.5.21743.0`** |
| option ON | ❌ **service crashes** |
| impedance labels | ✅ correct on both builds (§3e closed) |

**⚠ `nvx136_2021.exe` is bound to the 2025 DLL on the lab machine.** It should load 1.4.19077.
Windows searches the executable's own directory first, so this is not a launcher problem — the
2025 file is physically in `bin\nvx136_2021\`, left from `x-dll-swap-experiment\swap-in-2025-dll`
with `restore-2021-dll` never applied. **Every cold-start result from that build, including the x1
and x2 falsification runs, was measured against the 2025 library.** It does not overturn the
cold-start conclusion — if anything it strengthens it, since removing the read broke the build even
on the 2025 DLL — but the "2021 comparator" has not been comparing what it is meant to. Shipped as
`d0-restore-2021-dll`.

**❌ The crash is in the frame loop, and it was latent before patch 6.**

```cpp
while (in != tail)          // `in` advances by inputSampleSize each pass
```

A block that is not a whole number of frames steps *over* `tail`, never equals it, and reads until
the process faults. Worse, a wrong stride makes the trailing word garbage rather than the sample
counter, so `extraDistance()` returns something enormous and the gap `fill_n` writes hundreds of
megabytes past the end of `resultBuffer`.

⚠ **Both hazards predate patch 6.** What patch 6 did was change the frame width — which is
precisely the condition that turns them from latent into a fault. The 2025 driver has neither
problem: it iterates a computed sample count, clamps at `MaxOutputSamplesPerRead`, and sizes
`m_resultBuffer` to fit.

<a id="history--patch-7-t2-crash-guard--bound-it-and-make-it-answer-the-question"></a>

### ✅ Patch 7 (`t2-crash-guard`) — bound it, and make it answer the question

* the walk is bounded (`in + inputSampleSize <= tail`), and every write is clamped to the buffer;
* a block that is not a whole number of frames is **dropped with a diagnostic**, not parsed at a
  stride the device is not using;
* the first block that parses reports the frame width the device is really sending.

⭐ **The driver now settles the compression question itself**, which the emulator-only probe could
not. One line either way:

```
NVX136_2021: frame width 70 words (280 bytes), 14000 bytes read -- inputs are disabled and the
device IS compressing them out (uncompressed would be 138 words)
```

```
NVX136_2021: NVXGetData returned N bytes, which is not a whole number of M-byte frames (K words).
It IS a whole number of 552-byte frames (138 words), so this device does NOT compress disabled
channels out of the frame. Blocks are being dropped ...
```

That removes the power-cycle from the critical path: the open question is now answerable in a
warm-start session.

⚠ **No regression test guards this.** The cold-start cure has one; this does not, because
`nvx136_2021` has no test target at all — it is a frozen comparator due for retirement. If it
outlives that plan, the guard is worth adding.

<a id="history--nvx-initialises-its-api-contrary-to-the-guide"></a>

### ⚠ `nvx` initialises its API contrary to the guide

`application.cpp:33` calls `NVXAPIInit(nullptr)`. `4082e-NVX-Application programming guide.pdf`
is explicit:

> *At the beginning of working with the library, you need to call the NVXAPIInit function with a
> configuration line: `"<Configuration version=\"100\"></Configuration>"`.*

It returns `NVX_ERR_OK` with NULL and the service works, so this is undocumented behaviour we rely
on. ⚠ **The vendor gives no help here either**: `NVXAPIInit` appears in *no* sample program in
either SDK — `ConTest.cpp` and `ConTest2.cpp` are dated 2016 and never call it at all, despite the
guide saying it is required. Passing the documented string costs nothing and removes the question.

<a id="history-the-two-soft-spots"></a>

### The two soft spots

* **`NVXSetChannelsEnabled` with no preceding `NVXSetPowerSave`.** Both builds skip the power-save
  call when it would ask for the power-on default — deliberately, since every call in that gap is a
  device transaction and the cold-start failure timed out on one (§3f). The header's *"call after
  NVXSetPowerSave"* most likely constrains relative order when both are used, but strictly read it
  is a precondition. Leave it: the gap-minimising reason is measured and the risk is theoretical.
* **`NVX_IMP_INVALID` maps to `+infinity` in 2021 and `NaN` in 2025.** Both are "handled"; a
  viewer scaling an axis sees very different things. Unify on `NaN` when §3e is done.


<a id="history-3c--service-discovery-loses-services-when-many-announce-at-once"></a>

## 3c. ⚠ Service discovery loses services when many announce at once

Fifteen services started within a few seconds of each other: the Configurator's tree settled at
**six**, and a different six on each run, across four attempts with three explicit rescans and
twelve seconds of settling between them. With four services all four appear reliably; with one, one.

This was found while building `capture-parameter-column.ps1` and is **not** understood — it may be
UDP loss on the single 13370 announce port, a per-cycle cap in the discovery loop, or the tree
model. It has an obvious operational bite: a rig with a dozen services may silently present an
incomplete service list, and an operator has no way to tell an undiscovered service from a service
that failed to start.

**Fix:** instrument `resonance.discovery.cycle` against a controlled fan-out and find out whether
announcements are being dropped on the wire or after it. Until then, `capture-parameter-column.ps1`
takes `-Only`, and any harness that indexes services by row must launch a handful at a time.

---


<a id="history-4-test-and-evidence-gaps"></a>

## 4. Test and evidence gaps

The port's evidence is unusually good for the *services* and unusually thin for the *framework*.

* ⚠ **`Core/Resonance`'s seven gtest binaries are built and never registered with CTest.**
  `R:\src\Core\Resonance\tests\CMakeLists.txt:95-96` has `include(GoogleTest)` and
  `gtest_discover_tests(...)` **commented out**, and the file contains no `add_test` at all. So
  StreamInfo equality, the parameter-apply round trip, the stream-slot refusal semantics that caused
  the 2026-08-22 field bug, the CED montage parser, the record-path resolver and the loopback/LAN
  gate have **zero coverage in the runs quoted as the port's evidence**. The KARDi2 island's copy of
  the same directory registers all of them properly — copy that eleven-line block across and re-run.
* **Nine of twelve `quickStimulus` test executables** are likewise built and unregistered, so ctest
  never runs the epoch, topomap or colormap suites. **SPEED has no registered test at all**, yet
  VALIDATION.md's SPEED section cites a ctest log that contains no SPEED test.
* **The recorded evidence is stale.** `qa/ctest-qt6-final.log` is dated 2026-08-28, five days before
  the last change to `Core/Resonance`; `VALIDATION.md` has no 2026-09-02 section at all, so the
  three defects found that day are absent from it. The **deployed** `Resonance.dll` is newer than the
  source change, so the distribution is consistent — only the evidence is behind.
* **Five of the eight test totals quoted across the Qt 6 docs have no ctest log**; only three
  reconcile against an artefact.
* **`actiChamp` "parity" compares the Qt 6 service against itself** — no Qt 5 actiChamp ever
  answered, because the Qt 5 binary access-violates on start (§6). That is recorded honestly in
  `qa/actichamp-parity.json`, but the section reads stronger than it is.
* **tepSound's only cross-generation check is a sorted-parameter-name hash.**
* **No evidence anywhere that a Qt 6 recording is numerically equivalent to a Qt 5 one.** Given §6's
  row-count change, an explicit comparison is owed.
* ⚠ The MATLAB-oracle test data lives in `R:\dist_Qt5\_build\topo-ref` — a **build directory**, the
  one kind everyone treats as disposable — and those tests are not registered with CTest either, so
  they skip silently when it is cleaned. Move the CSVs somewhere durable and repoint
  `quickStimulus/tests/{cedpalette,topofield}_test.cpp` and `tepSoundService/tests/topo_test.cpp`.

---


<a id="history-5-version-control"></a>

## 5. Version control

**`R:\src` has no git repository.** `R:\src_Qt5` has the only history — branch
`feature/services-and-isolation`, HEAD `fae69c3`, with **14 uncommitted working-tree changes** under
`neuroMS/`, `nvx136/` and `scriptEngines/`. Those 14 changes are the only record of what the Qt 6
snapshot was taken against, and several of them are exactly the fixes §1 is about. **Commit them
before anything else.**

Then initialise the promoted tree. ⚠ Its `.gitignore` covers only `/_build/`, `/_dist/`,
`/_artifacts/` and `*.user`; a naive `git add -A` would commit ~240 MB of build output and QA scratch
from `_test-output` (84 MB), `_stage` (9 MB), `_patches` (1.5 MB), `KARDi2/_build-x86` (2 MB),
`KARDi2/_build-x64` (3 MB) and 144 MB of retired-island rollback copies under `KARDi2/_legacy`
(`_retired-builds` 111 MB, `_previous-dist` 33 MB). ⚠ `/_build/` and `/_dist/` are anchored to the
root, so they do **not** cover the KARDi2 ones, and a name pattern like `_build*` would not cover
`_retired-builds` either. Extend the ignore list first — and **do not ignore the rest of
`KARDi2/_legacy`**: `_legacy/3dparty/Driver` is the only copy of the vendor USB kernel driver in the
repository, and `deploy-qt6.ps1` stages it into the distribution.

---


<a id="history-6-back-ports-the-other-way--the-qt-5-comparator-carries-live-bugs"></a>

## 6. Back-ports the other way — the Qt 5 comparator carries live bugs

These were found and fixed during the port, in `R:\src` only. **`R:\dist_Qt5\msvc64` is what the lab
runs today**, so each is a live defect, and each also makes the comparator *unfaithful* for the
thing it is supposed to compare.

| what | where | why it matters |
|---|---|---|
| **HDF5 trailing zero row** | `Core/Resonance/internal/HDFRecorder.cpp`, five one-line changes | Every Qt 5 recording ends with an all-zero row that was never written — a fabricated falling edge on a trigger channel, a reset on a counter. **Proven Qt-5-portable: the identical change already compiles in the KARDi2 island's Qt 5 build.** Until it lands, Qt 5 is not a valid control for anything that counts samples. |
| **`DiscoverURI` out-of-bounds read** | `Core/Resonance/internal/DiscoverURI.cpp` | Indexes past the end of the split result on a malformed query — on a **UDP-facing** parser. |
| **actiChamp is fatally broken under Qt 5** | `R:\src_Qt5\actiChamp` | The x64 binary resolves `ActiChamp_x86`, never validates a function pointer, and exits `0xC0000005`. Its shipped `actiChamp.bat` independently contains `start signalGenerator`. Repaired only in the Qt 6 tree. |
| **`PYTHONHOME` points at a directory that does not exist** | `Core/Resonance/env.bat:29` | `R:\dist_Qt5\msvc64\python` is absent, yet `bin\engines\pythonEngine.dll` is deployed, so an embedded interpreter cannot locate its stdlib. The Qt 6 `env.bat` guards it with `if exist`. Backport the guard at minimum. |
| **SPEED unloads the engine DLL while its callbacks are live** | `R:\src_Qt5\SPEED` | And leaves six function pointers uninitialised. |
| **`ResonanceForeignDriver` send path calls a function that does not exist**, and inbound messages are decoded with the machine code page | `R:\src_Qt5\ResonanceForeignDriver` | Cyrillic metadata corrupts. |
| **Configurator parameter Save is unchecked and non-atomic** | `R:\src_Qt5\quickStimulus\import\Resonance\ParametersView.qml` | A refused create/overwrite looks identical to success. |
| **KARDi2 leaves a hardware trigger output latched, and drops samples at 4 kHz** | `R:\src_Qt5\KARDi2` | Verified on a physical model 1402: neither `K2Stop` nor `K2Close` clears the trigger latch, so Sync Out stays asserted and the next process inherits it. Not urgent — no `KARDi2.exe` is deployed in `dist_Qt5\msvc64` — but it must land before any Qt 5 KARDi2 is deployed. |
| **Neuro-MS post-connect handshake forces the inter-pulse delay to zero** | `R:\src_Qt5\neuroMS` | Silently converts paired-pulse to simultaneous. See §1b — this is the fix that must be *merged with*, not replaced by, the Qt 5 `standby` work. |

---


<a id="history-7-deployment-and-build-hygiene"></a>

## 7. Deployment and build hygiene

* ⚠ **`deploy-qt6.ps1` takes no rollback copy.** The Qt 5 distribution visibly relies on the habit —
  ten `bin.pre-*` directories sit beside `R:\dist_Qt5\msvc64\bin`. Add a pre-install `bin.pre-<stamp>`
  snapshot.
* ⚠ **It also overwrites operator-editable content.** `install(DIRECTORY …)` rules unconditionally
  rewrite `protocols\` (including `operator-demo.tep.json`, exactly the file an operator edits
  between sessions), `calib\`, `montages\` and two of the 19 `params\*.json` from source
  (`R:\src
untime-content\params\` holds exactly `nvx52_test34ch.json` and
  `speed_feetStim.json`; `nvx136_default64ch.json` is installed separately by nvx136). Meanwhile the four
  `.ini` files and everything else in `params\`, `stimuli\` and `data\` have **no** install rule and
  are never provisioned — so the distribution has two classes of content with opposite update
  semantics and nothing documents which is which. Change provisioning to copy-if-absent.
* **The build runtime and the deployed package can diverge.** Root `install()` rules have no
  `POST_BUILD` counterpart, and `install(DIRECTORY)` copies QML from *source* rather than from the
  build tree.
* **`pythonEngine`/`SPEED` compile against Python 3.12.10 but ship a 3.12.1 runtime**, violating an
  invariant the source itself declares and `FATAL_ERROR`s on elsewhere.
* **`validate-dist-qt6.ps1`'s completeness list omits four shipped binaries** — and should now also
  require the four `.ini` files, `bin\FrameLib\`, and the full 19-file `params\` set.
* **`deploy-qt6.ps1` silently reuses a stale Conan toolchain**, and nothing ever removes files from
  the destination.
* **`env.bat` has no `setlocal`**, so Qt 6 plugin and QML paths leak into any Qt 5 launcher run from
  the same console afterwards.
* **`runtime-content/qt.conf` uses the Qt 5 key `Qml2Imports`**, which Qt 6 does not recognise —
  the key is `QmlImports`. Harmless today only by coincidence (with `Prefix=../qt` the built-in
  default is already `qml`), and the coincidence stops protecting it the moment QML imports move.
* **Every build path is pinned to this machine** by absolute paths, a per-user Python and an unpinned
  Windows SDK. That is not new, but it is now the *default* tree's problem.

---


<a id="history-8-smaller-defects-worth-a-pass"></a>

## 8. Smaller defects, worth a pass

* **`Resonance__Parameters__Double.qml:15-21`** — the `DoubleValidator` reads `parent.from`,
  `parent.to`, `parent.factor`, `parent.decimals`. `DoubleValidator` is a `QObject` with no `parent`
  property, so the name resolves through the component root to `self.parent`, which is the
  `ParamView` **Loader** — and the Loader has none of those properties. `bottom` and `top` become
  `NaN` and `decimals` is `undefined`, so typed input in **every** `Parameters::Double` editor in
  every service is no longer range- or decimal-checked. The Qt 5 original had no validator at all
  (Controls 1 `SpinBox` took the range natively), so this is port-introduced and never exercised.
  **Fix: replace the four `parent.` with `self.`** — one line, no rebuild of anything but the plugin.
* **`actiChamp::stop()` can freeze the whole service.** It posts `delete runner` with
  `Qt::BlockingQueuedConnection` from the main thread, onto the worker thread that is sitting inside
  `champGetDataBlocking`. At 500 Hz with the maximum block size that is ~200 seconds of a dead
  service — and indefinite if the amplifier stalls or is unplugged. Qt 5's `stop()` was
  `runner->deleteLater()`, which posts and returns. Use a queued request plus a bounded wait, or the
  vendor's non-blocking `champGetData`.
* **actiChamp couples "is this channel published" to "is its scale non-zero"**, so a zero vendor
  resolution silently publishes zeros; it allocates a fresh output vector per acquired block; and its
  missing-sample counter never resets, so one gap warns on every block for the rest of the session.
* **Four QML files under `R:\src` still import `QtQuick.Controls 1.x`** — two are registered in a
  `qmldir` and all four install into `R:\dist`. `Resonance.Bricks\StimulusSelector.qml` is the live
  one.
* **Configurator keyboard navigation regressed**: arrow keys no longer open the parameters panel;
  channel-list arrows move an invisible current row while Space toggles the mouse-made selection;
  service-tree column widths are no longer user-resizable and the hand-drawn header is 4 px out of
  step with the data columns.
* **`resonance_foreign_driver.py` raises `OSError` under the `RESONANCE_PATH` the shipped `env.bat`
  sets.** `env.bat:5` sets a path **list** (`%CD%\bin;%CD%\qt\bin`); the wrapper passes it straight
  to `os.add_dll_directory()` and joins the library name onto it. Every QA harness overrides the
  variable with a single directory before importing, which is why it was never caught. A
  foreign-driver user's first action after `call env.bat` is a traceback. Split on `os.pathsep`.
* **KARDi2 records outside the distribution's `data\` folder under Qt 6.**
* **SPEED unloads the engine DLL without calling `freeEngine()` first on a re-load.**
* **`backendName()` reports the requested backend, not the chosen one**, while both backend plugins
  ship side by side; and about thirty lines of comment in the Qt 6 `videocue`/`mediaprobe` describe
  machinery that no longer exists.

---


<a id="history-9-porting-backlog"></a>

## 9. Porting backlog

No active service remains unported as of 2026-09-06. Stimulus is the final native Qt 6 service,
with TepSound presentation scope and shared corrections; DAQmx and FieldTrip were completed on
2026-09-05. COMport/latencyProbe are ported; tepService is retired; MioStim was removed/replaced.
Software validation is complete for the stimulus extraction. Physical onset/trigger acceptance
and device-specific laboratory checks remain. See [Stimulus](../components/stimulus-presentation.md).

The exception is the 18 legacy `sp_*.qml` programs, which Qt 6 cannot load at all. That is a
decision, not a task; see §2 of the same document.

---


<a id="history-10-documentation-still-owed"></a>

## 10. Documentation still owed

Done on 2026-09-02: this file, [`arch_qt5-still-needed.md`](qt5-still-needed.md),
[`build_qt5-to-qt6-transition.md`](qt5-to-qt6-transition.md), the entry points
(`` `README.md `` ([task index](../../README.md)), `` `STATUS.md `` ([change history](../changes/README.md))), the build documents, and the
path/toolchain corrections through the `service_` and `arch_` set.

Still owed:

* **The five `.docx` operator guides** carry `R:\dist\msvc64` in their datelines and cannot be
  corrected by any text pass — they need a hands-on Word session:
  `guide_recorder-operator.docx`, `guide_stimulus-presentation-operator.docx`,
  `guide_nvx-52-driver.docx`, `guide_nvx-136-driver.docx`, `guide_neuron-spectrum-65-driver.docx`.
* **`R:\src_Qt5\docs`** is a stale 2026-08-26 copy of this doc set, diverging from `R:\docs` in
  exactly three substantive files — each a *correction that reverses an earlier conclusion* (the
  falsified NVX136 cold-start rule, the neuroMS panel-off defects, the recorder dud-sample note).
  Anyone who finds that copy reads the superseded version of all three. ⚠ **It is git-tracked and
  committed**, so it is not simply deletable rubbish — it is the doc set as of that commit, and
  removing it is a commit someone has to make deliberately. **`R:\docs` is authoritative.** Decide:
  delete it in the repo, or add a one-line stub there pointing at `R:\docs`.
* **`R:\src\docs\VALIDATION.md`** needs a 2026-09-02 section and a refreshed ctest log (§4).
* **`latencyProbe` has no `service_` document at all**, despite a complete harness in `R:\config`.
