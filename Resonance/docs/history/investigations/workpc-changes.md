# Work-PC session log — source edits and debug notes — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../issues/README.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-work-pc-session-log--source-edits-and-debug-notes"></a>


**Started 2026-08-17.** This machine (`D:\Resonance2026`) has **no build environment**: no Qt
5.15.2 kit, no MinGW, no MSVC v142, no Conan. Nothing edited in `R\src` here can be compiled,
deployed or tested here.

**So this file is the deliverable.** Every source edit and every debug finding made on this
machine is recorded here, and nowhere else is authoritative — this tree is not a git repository
either, so there is no `git status` and no diff to fall back on.

> **Why this matters more than it sounds.** This project has already lost a fix to exactly this
> class of gap, in the other direction: the 2025-10-06 HDF5 chunking fix shipped only as a
> compiled `Resonance.dll`, was never committed, and every build made from source since silently
> carried the old behaviour back ([recorder-service.md §6.4](../components/recorder.md)). An
> **uncompiled source edit** is the mirror image — it looks done, and it is not. Neither the
> binary nor the source can be trusted to carry the change on its own; this log is what carries it.

---


<a id="history-how-to-read-this-file"></a>

## How to read this file

| Section | |
|---|---|
| [§1 Environment](../../issues/README.md) | what this PC has, and the path remap from the docs |
| [§2 Source edits](../../issues/README.md) | **every edit to `R\src`, none of it compiled** |
| [§3 Debug notes](../../issues/README.md) | what was observed running the deployed `msvc64` tree |
| [§4 Carry-forward](../../issues/README.md) | the checklist for whoever next has a toolchain |
| [§5 Home-PC verification](../../issues/README.md) | ⭐ **the checks actually run, on `ANATOLYHOME2024`** — what held, what did not |

Every §2 entry carries a **Proves it** line: the specific check that would confirm the fix once
it is compiled. An edit without one is a guess, and should be labelled as such.

---


<a id="history-1-environment--what-is-and-is-not-here"></a>

## 1. Environment — what is and is not here

Transferred as `R.zip` (376 MB) and `msvc64.zip` (567 MB), unpacked 2026-08-17 ~04:22.

| Docs say (home PC, `ANATOLYHOME2024`) | Here |
|---|---|
| `R:\src` | `D:\Resonance2026\R\src` |
| `R:\docs` | `D:\Resonance2026\R\docs` |
| `R:\config` | `D:\Resonance2026\R\config` — present, with all the test harnesses |
| `R:\dist\msvc64` | `D:\Resonance2026\msvc64` — **no `dist\` level** |
| `R:\dist\mingw32`, `R:\dist\mingw64` | **absent** |
| `R:\dist_legacy\*` (`dist2025`, `distro-dual`, `TEP_visualization`, …) | **absent** |
| `R:\equipment\*` (vendor SDKs, IPP installer) | **absent** |
| `R:\src_git_branches\*`, `R:\src\.git` | **absent — not a git repository** |
| `R:\dist\_build\*` (all evidence HDFs, validation artifacts) | **absent** |
| `N:\Projects_MSU\*` (recordings, legacy programs) | not checked — assume absent |

**What still works unchanged:** `msvc64\env.bat` derives everything from `%~dp0`, so
`RESONANCE_DIR`, `RESONANCE_PATH` and `RESONANCE_RECORD_PATH` follow the folder to `D:\`. The
distribution is self-relocating.

**What will not:** any absolute `R:\` path baked into a config — `R\config\*.json`,
`msvc64\params\*.json`, saved service configurations, `playbackService` file paths, the `ced`
and `head_image` parameters. Check for an absolute path before blaming a service.

⚠ **`call env` vs `call .\env`** — measured, and the answer is *not* the one the home PC had.
See [N1](../../issues/README.md).

<a id="history-what-is-deployed"></a>

### What is deployed

`msvc64\bin` carries the full current tree, newest binary **2026-08-17 04:04** — every module the
docs describe is present, including the ones added last: `arduinoTTL.exe`, `neuroMS.exe` +
`nmsbridge.dll`, `neuronSpectrum.exe` + `ns65bridge.dll`, `eStim.exe`, `feetStim.exe`,
`mStim.exe`, `tepService.exe`, `stimulusService.exe`, `playbackService.exe` + `playbackSource.exe`,
the reworked `SignalGenerator.exe`, `nvx.exe`, `nvx136.exe`, `recorderService.exe`.

Two deployment facts checked against the docs and both correct:

* **The private assembly directories are in place** — `bin\neuroMS\` and `bin\neuronSpectrum\`
  exist, and there are **no flat `NeuroSoft.*.dll` / `Neurosoft.*.dll` at the top of `bin\`**. That
  is the collision [neuroms.md §3](../components/neuroms.md) warns about, and this tree is on the right side of it.
* **Intel IPP 8.1 is staged in `bin\`** (14 `ipp*` DLLs, all CPU variants), which is native and
  belongs there rather than in a private directory. `neuronSpectrum` cannot acquire at all without
  it ([known-issues §15f](../incidents/README.md)).

`bin\Resonance\` carries `Plot\`, `Tep\`, `Stim\` and `Bricks\`, so the viewer, TEP and stimulus
brick libraries all deployed.

**`Resonance.dll` is not stale — ruled out by the author, 2026-08-17.** Its 08-16 09:54 timestamp
is older than several service exes (08-17), which reads like a framework/service mismatch from the
outside. It is not: that is simply when Core last needed building. Everything in `src` and in
`msvc64` is current **except `neuronSpectrum`**, whose deployed binary is behind source and has not
been redeployed. No NS-65 is attached (see [N2](../../issues/README.md)), so that gap
costs nothing today — but it will matter the moment one is, and it is the single component here
where the binary and the source disagree.

⚠ `msvc64\data\` still holds **18 evidence HDF5 files** from the home PC's test campaigns
(`t3-nvx136-0001.h5`, `t5-modes-0001.h5` at 34 MB, `diag-*`, `pbref-*`), ~50 MB total. Harmless,
but `data\` is for recordings and the home tree's own rule was to move evidence out of it. They
make it harder to spot a new recording.

---


<a id="history-2-source-edits--uncompiled"></a>

## 2. Source edits — UNCOMPILED

> ⚠ **Nothing in this section has been compiled, linked, deployed or run.** Every entry is
> source-only. Do not treat any of it as verified, and do not describe it as fixed.

<a id="history-e1--outputstreamclose-dereferences-a-null-aggregator"></a>

### E1 — `OutputStream::close()` dereferences a null aggregator

| | |
|---|---|
| File | `R\src\Core\Resonance\outputstream.cpp:38-40` (second instance at `:47-48`, `onStreamCreated()`) |
| Status | ⚠ **uncompiled — NOT YET APPLIED.** Recorded here as the carry-forward; the edit has not been made |
| Date | 2026-08-17 |
| Related | not in [known-issues.md](../incidents/README.md) — this is new |

**Was:**
```cpp
void OutputStream::close()
{
    if (!m_thread) { return; }
    auto stream = m_thread->contained<internal::OutputStreamAggregator>();
    Q_ASSERT(stream);
    stream->close();
}
```

**Proposed:**
```cpp
    auto stream = m_thread->contained<internal::OutputStreamAggregator>();
    if (!stream) { qWarning("OutputStream::close: aggregator already gone"); return; }
    stream->close();
```

**Why.** `close()` guards `m_thread` but not the object inside it. `ThreadCapsule::contained<T>()`
returns `nullptr` whenever its `QPointer` has been cleared or the `qobject_cast` fails, and
`Q_ASSERT` compiles to nothing in Release — so the next statement dispatches a virtual call through
null. `~OutputStream()` calls `close()`, so the window is teardown.

**Evidence this is real, not theoretical.** Three `APPCRASH` records for `quickStimulus.exe`
faulting inside `Resonance.dll` with `0xc0000005`: today 07:35:42 at fault offset `0x2d05c`, and
two on 14.08 at `0x2c75c`. The minidumps are in `C:\Users\meg_r\AppData\Local\CrashDumps`. With no
debugger on this PC, the address was resolved by parsing `Resonance.dll`'s `.pdata` exception
directory: RVA `0x2d05c` falls inside `RUNTIME_FUNCTION [0x2d000, 0x2d06c)`, whose exact export is
`?close@OutputStream@Resonance@@UEAAXXZ` — i.e. `close()+0x5c` — with `??1OutputStream…+0x21`
(`~OutputStream`) below it on the stack. A verifier re-derived this independently and confirmed the
exception record reads *access violation, read of `0x0000000000000000`*.

**Proves it:** after the fix, repeatedly attach and detach a viewer to a live stream in the
Configurator, close it, and confirm no new `quickStimulus.exe` entry appears under Application
Error. Until then this stays uncompiled.

⚠ **A guard silences a real teardown-ordering violation rather than explaining it.** Whatever
destroys the aggregator before the `OutputStream` still does so; the stream will then close
silently instead of crashing. Hence the `qWarning`. Do not treat the guard as the whole fix.

⚠ **This crash was REFUTED as an explanation for the reported visual bugs** — see
[N5](../../issues/README.md).

---

<a id="history-e2e4--configurator--parametersview-layout-applied-2026-08-17"></a>

### E2–E4 — Configurator / ParametersView layout, **APPLIED 2026-08-17**

| | |
|---|---|
| Files | `msvc64\bin\Resonance\{Configurator,ParametersView}.qml` **and** `R\src\quickStimulus\import\Resonance\{Configurator,ParametersView}.qml` |
| Status | ✅ **applied and live** — this QML is loaded from disk, not from a qrc, so it takes effect on the next `configurator.bat` with **no rebuild** |
| Backup | `msvc64\bin\Resonance\_backup-2026-08-17\` |

The deployed and source copies were **verified byte-identical (SHA-256) before editing**, so both
were updated from one edit and now match. That check matters: `bin\Resonance\**` is user-editable
configuration by design ([deployed-vs-repo.md](../migrations/deployed-vs-repo.md)), so it is entitled to diverge,
and overwriting a divergence would have destroyed rig configuration.

**E2 — `Layout.preferredWidth/Height` → `width`/`height` (`Configurator.qml`, 4 sites).**
A Qt Quick **Controls 1** `SplitView` is not a `QtQuick.Layouts` layout. Its `updateLayout()` reads
each non-filling child's **own** `width`/`height` clamped to `Layout.minimum*`/`maximum*`, and its
accepted attached-property list does not include `preferredWidth`/`preferredHeight` at all. So the
declared preferred sizes were **inert**: the left column fell back to its implicit ~252 px instead
of 300, and the viewer pane to its 80 px minimum instead of 300. At ~252 px the panel is below what
it was tuned for — [known-issues §14l](../incidents/README.md) records five buttons already overflowing a
285 px panel — hence `hardw…`, `teleme…`, `Hide disabled optio` and a horizontal scrollbar.
⚠ These must stay **plain values, not bindings**: `SplitView` writes `item.width` directly while a
divider is dragged, and a binding would snap the divider back on the next resize.

**E3 — broke a real binding loop (`ParametersView.qml:55`).**
`Item { implicitWidth: Math.max(sv.viewport.width - 6, layo.implicitWidth + 6) }` wrapped a
`GridLayout` that was `anchors.fill: parent` — the layout's width came from the Item and the Item's
width came from the layout. Qt reported it (`Binding loop detected for property "implicitWidth"`,
**41×** on a live Configurator) and broke it at an arbitrary iteration, leaving the tab content at a
width nobody chose. Now `implicitWidth` reads the viewport alone and the layout is anchored
left/top/right so nothing reads back.
⚠ **Behaviour change:** the `Math.max` allowed content *wider* than the viewport to scroll
horizontally. That is gone by design — the label column is already capped
(`labelColumnMaxWidth`) precisely so content cannot demand more than the panel. If some tab does
genuinely need more width it will now clip rather than scroll; watch for it.

**E4 — `options` before `index` (`Configurator.qml`, `viewer_layout`).**
QML applies constant property assignments in declaration order. `index: 1` ran while `m_options`
was still empty, so `Select::setIndex`'s guard `index >= m_options.length()` (1 >= 0) **silently
dropped it** and `m_index` stayed at its constructor value 0 — the Configurator could never start
side-by-side, which is the arrangement [signal-viewer.md §7c](../components/signal-viewer.md) says a scalp map
needs.
⚠ **The dropped index is real; the reordering is not a fix — measured 2026-08-17, see
[§5b](../../issues/README.md).** `options: [...]` is an array
literal and therefore a *binding*, evaluated in a later phase than the `index: 1` literal, so the
order of the two lines is irrelevant. `Component.onCompleted: index = 1` is what works.

**Proves it:** launch `configurator.bat`. Expect the left column at 300 px with `hardware` /
`telemetry` tab labels unclipped, no horizontal scrollbar on the parameter panel, no
`ParametersView.qml:55` binding-loop line in the DBWIN capture, and the two viewers side by side.

⚠ **The framework-level fix for E4 needs a build machine:** `Select::setIndex` should remember an
out-of-range request and re-apply it from `setOptions`, instead of dropping it. The same guard will
bite any other QML that sets `index` before `options` — and see
[N6](../../issues/README.md) for why that guard is now a
prime suspect elsewhere.

---

<a id="history-e5--every-dropdown-in-every-service-is-read-only-from-the-parameter-panel"></a>

### E5 — every dropdown in every service is read-only from the parameter panel

| | |
|---|---|
| File | `msvc64\bin\Resonance\Resonance__Parameters__Select.qml` + the source copy |
| Status | ⚠ **SUPERSEDED 2026-08-17 by [§5a](../../issues/README.md)** — the defect is real and the diagnosis below is right, but the *fix* recorded here is not. Read §5a before touching this file |
| Change | ~~one line: `root.status` → `paramControl.status`~~. The write-back now hangs on **`onActivated`**; the `status` guard and `_block` are both gone. §5a has the reasoning and a controlled before/after |
| ⚠ Carry-forward | **This must reach the repository.** It is applied to `msvc64\bin\Resonance\` *and* `R\src\quickStimulus\import\Resonance\`, but this tree has no `.git`, so it exists nowhere else. It is a one-line fix for a regression that disables every `Select` in every service — losing it would be the [recorder-service.md §6.4](../components/recorder.md) mistake again |
| Found by | the operator: *"the visual of parameter changes but it doesn't apply"* — exactly right |

> **History of this entry, kept deliberately.** It was first written up as ROOT CAUSE. That was
> premature: the fix went in and the symptom did not change. It was then nearly discarded, because
> the operator reported the same directory working at home — which would have made this
> environmental rather than a code defect. The operator then **re-checked the home machine and
> found it broken there too, having previously worked**. That makes it a **regression in the
> 2026-08-15…17 rework, present on both machines** — and puts the `root` → `paramControl` rename
> back as the prime suspect, since before that rename `root` *was* the Loader's id and this guard
> worked. Three reversals on one finding; the lesson is that "it works at home" is a memory of a
> build, not a property of a tree.
>
> The first attempt bundled **two** edits. The second (`_block = true`) was reverted on
> 2026-08-17 because it can swallow the operator's own click: `model` is
> `parent.attributes.options`, which is re-assigned on every description re-broadcast, so the
> first `currentIndexChanged` after any rebuild — quite possibly the user's — was being dropped.
> **Only the `root` → `paramControl` change is now active**, which isolates it as a single-variable
> experiment.

**Was** (lines 22 and 34):
```qml
    onModelChanged: {
        //_block = true;
    }
    ...
        if(root.status !== Loader.Ready) return;
```

**Now:** `_block = true;` uncommented, and `root.status` → `paramControl.status`.

**Why.** `ParametersView.qml:12` is `id: root` — the **GroupBox**, i.e. the parameter panel itself.
The `Loader` that instantiates each delegate is `id: paramControl` (`:83-86`), and it carries an
explicit comment saying it is *"Deliberately not `root`: that is the ParametersView itself"*. So the
Loader was renamed and **this one delegate was never updated**. A `GroupBox` has no `status`, so
`root.status` evaluates to `undefined`, `undefined !== Loader.Ready` is **always true**, and
`onCurrentIndexChanged` **returned before writing**. The ComboBox's own `currentIndex` had already
moved, so the panel showed the new value while the service never received it.

**Scope — this is tree-wide but delegate-specific.** `grep -n "root\." Resonance__Parameters__*.qml`
returns **exactly one hit**, this line. Every other delegate that writes `parent.serialized`
(`Integer`, `Double`, `String`, `MultiLine`, `File`, `ChannelsList`, `BipolarChannelsList`) is
unaffected. So: **every `Select` in every service was read-only from the parameter panel; nothing
else was.** That covers `viewer_layout`, `nvx`/`nvx136` `samplingRate` and `mode`, and every other
dropdown in the tree.

**Why `_block` had to be restored at the same time.** With only the `root` fix applied, rebuilding
a Select's model (which resets `currentIndex` to 0) would now be written **back to the service** as
a genuine operator choice. That would have converted "the sampling rate display reverts to 250 Hz"
into "the sampling rate *actually becomes* 250 Hz" — strictly worse. `_block` is what suppresses
the write caused by a model rebuild, and it had been commented out. Both edits are one fix.

**Proves it:** in the Configurator's parameter panel, set `viewer_layout` to *Side by side (1x2)*.
The viewers must rearrange, and re-selecting the service must show 1x2. Then set an NVX sampling
rate other than 250 Hz and confirm it neither reverts nor silently fails to apply.

⚠ **The backup in `_backup-2026-08-17\` for this file was taken AFTER the edit, not before.** The
original two lines are quoted verbatim above, so restoring is trivial, but do not trust that
particular backup as a pre-edit copy.

⚠ **The underlying fragility is unfixed:** a delegate loaded by a `Loader` resolves ids from the
enclosing document through the QML context chain, so renaming an id in `ParametersView.qml`
silently breaks delegates in other files with no error at load time. A self-contained
`Component.onCompleted`-based ready flag would remove the whole class; that is a larger change and
was not made here.

---

<a id="history-n6--three-symptoms-reported-by-the-operator-not-yet-diagnosed"></a>

### N6 — three symptoms reported by the operator, not yet diagnosed

Reported 2026-08-17. **None of these is addressed by E2–E4**, which are layout only.

**1. The NVX sampling rate reverts to 250 Hz shortly after another value is selected.**
This reframes the original report: it is a **revert**, not a menu stuck at one value. Three
established facts converge on it, and they should be tested together:
* `Select::setIndex` **silently rejects** an out-of-range index and leaves `m_index` at its previous
  value — 0 on a fresh object. If 250 Hz is index 0, a rebuilt options list lands exactly there.
* `Select::setIndex` does **not** emit `triggerUpdate` ([known-issues §17a](../incidents/README.md)), so a
  service-side selection is invisible to clients until something unrelated re-broadcasts.
* `Resonance__Parameters__Select.qml` writes `parent.serialized = currentIndex` back on
  `currentIndexChanged`, and its `_block` re-entrancy guard is **dead** — the only `_block = true`
  is commented out at line 22. Nothing damps a UI↔service echo.

⚠ **The "shortly after" is measurable and suggestive.** `nvx136`'s device probe was timed at
**3.457 s and 3.497 s** on this hardware. `Nvx136Config::updateChannels()` calls
`runner->probe(deviceIndex, selectedMode, rate, options)` — so changing the rate plausibly rebuilds
the options list ~3.5 s later and resets the index. **Test:** change the rate with the DBWIN capture
running and time the revert. If it lands at ~3.5 s, that is the path.

**2. Streams of closed or crashed processes persist in the Configurator.**
This is the symptom predicted by the finding rated only *possible* earlier, and it upgrades that
finding. `TcpStreamReceiver.cpp:79-95` caps a connect at 3 s but the wait is
**not interruptible and runs on the GUI thread** — the code's own comment says so. `StreamPool`
tries candidates one at a time. On this PC a stream advertises **four** addresses
(`10.0.85.2` VPN TAP first, `169.254.83.107` link-local, `192.168.1.64` real LAN, then the
hostname) where a single-NIC machine offers two, so each dead stream can freeze the GUI for ~12 s
instead of ~6. Stale streams are precisely the case that pays it.
⚠ **This makes the `resonance.cfg` fix worth doing** — it was dismissed earlier as free on a
single PC, which was true only while nothing was stale.

**3. `playbackService` does not play back.** Undiagnosed. Candidates, in order:
the file path; [known-issues §16b](../incidents/README.md) (a saved multi-stream config cannot be loaded
back, and playback's mapping is exactly that shape); the mandatory `prepare` before `start`
([playback-service.md §7a.2](../components/playback.md)); and the `QProcess` launch of
`playbackSource.exe` — note [stimulus-presentation.md](../components/stimulus-presentation.md) records that a
sibling module's launcher "had never worked" because `QProcess` cannot execute a `.bat` and
resolved the name against `PATH` rather than the distribution root.

⚠ **Re-validated end to end on the home PC 2026-08-17 and it does not reproduce —
[§5d](../../issues/README.md).** Every layer works, including
the Configurator's own double-click path. Three of the four candidates above are now **refuted**:
the `QProcess` launch resolves `playbackSource.exe` beside its own binary and deliberately not
through `PATH` (`service.cpp:47-54`, with a comment saying so); a missing file is reported in
`contents` and both `prepare` and `start` are refused; and the mapping is filled by the scan
rather than by a saved multi-stream config, so §16b is not on this path unless a config is loaded.
The remaining live candidates are the wrong path *unnoticed* in a clipped panel, and N6.2's
GUI-thread stall over four advertised addresses. §5d lists the three readings needed from that
machine to settle it.

<!-- Template — copy per edit:

<a id="history-e1--"></a>

### E1 — <one-line summary>

| | |
|---|---|
| File | `R\src\<module>\<file>:<line>` |
| Status | ⚠ **uncompiled** |
| Date | 2026-08-17 |
| Related | [known-issues §N](../incidents/README.md), [STATUS.md](../changes/README.md) |

**Was:**
```cpp
```

**Now:**
```cpp
```

**Why:** the defect, and how it manifests at the rig.

**Proves it:** the exact check that confirms this once built — a test name, a measurement with
its expected value, a log line. Not "it should work".

**Risk if wrong:** what breaks that did not before. Blast radius beyond this module.

-->

---


<a id="history-3-debug-notes--observed-on-the-deployed-binaries"></a>

## 3. Debug notes — observed on the deployed binaries

> Everything here is a measurement or an observation against `D:\Resonance2026\msvc64` **as
> shipped**. This is the half of today's work that *is* real evidence, because it runs the
> actual binary.

<a id="history-n1--the-call-env-trap-is-in-the-tooling-not-on-this-machine"></a>

### N1 — the `call env` trap is in the tooling, not on this machine

| | |
|---|---|
| Observed | 2026-08-17 |
| Against | environment, before launching anything |
| Hardware | none |
| Reproducible | yes — it is a static setting |

**What happened.** `NoDefaultCurrentDirectoryInExePath` read at all three scopes:

| Scope | Value |
|---|---|
| Machine | *(unset)* |
| User | *(unset)* |
| **Current process** | **`1`** |

**Reading — and the two halves point opposite ways.**

* **For an operator, the launchers are fine on this PC.** The variable is not set at machine or
  user scope, so a double-clicked `.bat` resolves `call env`, `env.bat` runs, and
  `RESONANCE_RECORD_PATH` is exported to `D:\Resonance2026\msvc64\data`. This is **not** the home
  PC's situation — there it was set persistently, which is why
  [known-issues §19e](../incidents/README.md) reports two recordings landing in `bin\`. That finding does
  not transfer to this machine, and assuming it did would mean chasing a bug that is not here.
* **For anything launched from this session, they are not.** The variable is `1` in the process
  I run commands in, inherited by both the Bash and PowerShell tools. A `.bat` started from here
  gets *the home PC's failure mode*: `env.bat` never runs and recordings go to `bin\`.

**Consequence for today's testing:** launch the `.bat` files with the variable cleared, or the
results are about my shell rather than about the software. This is precisely the false-failure
[build-and-distro.md §7](../migrations/and-distro.md#history-7-verifying-a-deploy) documents — it lists
`NoDefaultCurrentDirectoryInExePath` and Git Bash's `env.exe` shadowing `env.bat` as the two
traps that make a *working* deploy look broken, and notes both reproduce on the known-good 2024
reference.

```bash
cmd.exe /c "set NoDefaultCurrentDirectoryInExePath=&& cd /d D:\Resonance2026\msvc64 && signalGenerator.bat"
```

**Control:** not needed — this is a direct read of the environment, not an inference from a
failure.

**Open:** nothing. But **re-check after the first recording** that the file actually landed in
`data\` and not `bin\`; the variable being unset is the cause, the file's location is the proof.

---

<a id="history-n2--the-bench-on-this-pc-enumerated"></a>

### N2 — the bench on this PC, enumerated

| | |
|---|---|
| Observed | 2026-08-17 |
| Against | Windows PnP, before starting any service |
| Reproducible | yes |

**Attached, present and `OK`:**

| Device | Instance | Notes |
|---|---|---|
| **Neuro-MS MonoStim** | `USB\VID_ACCA&PID_8315\06990176` | ⚠ **A magnetic stimulator, and the monophasic family `0x8315` the driver was written for.** Serial 06990176 |
| **Media Converter** | `USB\VID_20F9&PID_0123`, class `McsClass` | the NVX136 media converter — discovery calls it `Media converter #0` |
| **MCS A-Stim R1.1** | `USB\VID_20F9&PID_0132&MI_00`, class `MEDIA` | ⚠ **appears nowhere in any document in `R\docs`.** MCS vendor id, but no module in the tree names it |
| USB-SERIAL CH340 | `COM8`, `VID_1A86&PID_7523` | the usual Arduino Nano clone bridge — candidate for `arduinoTTL` (COM4 at home) or `mStim` |
| Silicon Labs CP210x | `COM3`, `VID_10C4&PID_EA60` | second USB-serial; candidate for `feetStim`'s controller |
| Serial port | `COM1`, `ACPI\PNP0501` | motherboard legacy port |

**Not attached:** no Neuron-Spectrum-65 (`VID_ACCA&PID_8277`), no NVX-52, no KARDi2, no EyeLink,
no NI-DAQmx, no actiCHamp.

**Reading.** ⚠ **This is the first time a magnetic stimulator has been attached to this project.**
[neuroms.md §12](../components/neuroms.md) states plainly that no Neuro-MS had ever been connected to any
machine here, and the whole of that module — the `/clr` bridge, the three operating modes, the
panel mirroring, the seven inferences in §11, the twelve defects in §11a — is reasoned from the
assembly and the vendor's samples. [§9](../components/neuroms.md) is a step-by-step bring-up written for
exactly this moment, with a contingency per step.

⚠ **The purpose-built bring-up tooling did not transfer.** `R:\dist\lab-kit-neuroMS` (the
self-contained 14 MB folder with `nms_bringup`), and the test binaries `ns_bridge_smoke.exe`,
`nms_stream_check.exe` and `test_NeuroMsLogic.exe`, all live under `R:\dist\lab-kit-neuroMS` or
`R:\dist\_build\...\tests\` — **neither path is on this machine**, and by design the test
binaries are built outside `runtime\` so they never reach a distribution. So §9's first command,
`ns_bridge_smoke.exe --hardware`, cannot be run here. The bring-up would have to be driven
through `neuroMS.exe` and the Configurator instead, which is a different and less instrumented
path — §9.4 (the IPI raw word) and §9.5 (the capacitor scale) in particular are things only the
smoke test prints.

**Open — the A-Stim is unidentified.** `MCS A-Stim R1.1` is an MCS device on the same vendor id
as the NVX hardware, enumerating as a `MEDIA` class device, and no module, document or vendor SDK
in this tree mentions it. Worth establishing what it is before assuming anything discovers or
drives it.

---

<a id="history-n3--no-python-analysis-stack-the-py-harnesses-cannot-run"></a>

### N3 — no Python analysis stack; the `.py` harnesses cannot run

| | |
|---|---|
| Observed | 2026-08-17 |
| Reproducible | yes |

Three interpreters are installed — **3.12.7**, **3.13.12**, **3.14.3** — and **none of them has
`numpy` or `h5py`.**

**Consequence.** Every Python harness in `R\config` is currently unrunnable:
`analyze_trigger_recording.py`, `tep_reference_pipeline.py`, `trigger_bench.py`,
`nvx_trigger_probe.py`, `ns65_sync_bench.py`, `ttl_link.py`. That removes the whole
read-the-recording-back-and-check-it half of every campaign in `R\docs` — the HDF5 reconciliation,
the trigger-edge extraction, the SciPy reference pipeline.

The **QML** harnesses are unaffected: they run through the deployed
`quickStimulus.exe -l <file>.qml`, which is present.

`pip install numpy h5py` into 3.12 would restore it and needs network access — worth doing before
any test that ends in "and then read the file back", because otherwise a recording can be made
and not checked.

⚠ Note the pinned-pybind11/NumPy-2 caveat in
[known-issues §2](../incidents/README.md) applies only to *building* `pythonEngine`, which cannot happen
here anyway. For reading HDF5 files back, any recent numpy is fine.

**Resolved 2026-08-17:** `py -3.12 -m pip install numpy h5py pyserial` →
numpy 2.5.2, h5py 3.16.0, pyserial 3.5. The Python harnesses are runnable again.

---

<a id="history-n4--the-vc-runtime-is-present-and-current-not-the-cause"></a>

### N4 — the VC++ runtime is present and current; not the cause

| | |
|---|---|
| Observed | 2026-08-17 |
| Reproducible | yes — a registry and file-version read |

[build-and-distro.md §5c](../migrations/and-distro.md) warns that this distribution deliberately does not
ship the VC++ runtime and that a target machine needs it. That made a missing or old runtime the
leading hypothesis for machine-to-machine differences. **It is wrong.**

| | |
|---|---|
| Installed | `Microsoft Visual C++ v14 Redistributable (x64) — 14.51.36247` (plus the x86 pair, and a 2012 11.0.61030 pair) |
| `vcruntime140.dll` / `vcruntime140_1.dll` / `msvcp140.dll` / `msvcp140_1.dll` / `msvcp140_2.dll` / `concrt140.dll` | all present in `System32`, all **14.51.36247.0** |

**Reading.** 14.51.36247 is **newer** than the `vc14.50.35719` the docs name, and the v14 runtime
is backward-compatible across the line, so the v142 (14.29) binaries this tree ships are covered.
Nothing is missing and nothing needs installing. Two copies of `VC_redist.x64.exe` sit unused in
`C:\Users\meg_r\Downloads` (18,731,856 bytes, 08:13 and 08:14).

Note this is a *runtime* fact and says nothing about
[known-issues §11a](../incidents/README.md), which is a **compile-time** incompatibility — VS 2026's STL
removed `stdext::checked_array_iterator`, which Qt 5.15.2 uses unconditionally. That is why the
build needs the v142 toolset, and it does not bear on running the binaries.

**Both leading hypotheses are now dead** — this one, and the stale-`Resonance.dll` one ruled out
by the author above. The cause lies elsewhere.

---

<a id="history-n5--multi-agent-diagnosis-what-survived-and-what-did-not"></a>

### N5 — multi-agent diagnosis: what survived, and what did not

| | |
|---|---|
| Run | 2026-08-17 08:06–09:07, six investigators + adversarial verification |
| Completeness | ⚠ **partial** — 58 of 100 agents errored (two investigators lost their connection; verification and synthesis hit a session limit). The `paths` and `deploy-integrity` sweeps never reported |

⚠ **The run's own "6 confirmed / 25 refuted" tally is not meaningful.** Findings were scored by
majority vote of three verifiers, and dead verifiers count as absent votes — so a finding could be
"refuted" purely by having lost its reviewers. The verdicts below are the ones with real reasoning
behind them.

<a id="history--the-root-cause-of-the-nvx136-symptom-was-not-found"></a>

#### ⚠ THE ROOT CAUSE OF THE NVX136 SYMPTOM WAS NOT FOUND

Stated first because the rest reads like progress. What *is* established:

* **`nvx136` starts cleanly on this PC against the real device.** Two independent runs, no
  `--emulation`, the shipped `--serviceConfig`: reaches state `init`, device probe 3.457 s and
  3.497 s, config accepted silently. **Neither** of the `qWarning` texts at
  `nvx136config.cpp:379` (*"Unable to query NVX136 channels"*) or `:461` (*"Unable to start
  NVX136"*) appears. So the fault is not at startup.
* The follow-on claim — that it must therefore be in the Configurator's parameter binding or at
  Start — **was refuted**: both named locations were shown incapable of producing the symptom.

Reproducing it needs someone to drive the GUI. See the safety note below before doing that.

<a id="history-survived-verification"></a>

#### Survived verification

| | |
|---|---|
| **Service logging is solved** | A ~130-line ctypes DBWIN listener reimplements DebugView's protocol; stdlib only, unelevated, no install, no compiler. Captured 27k lines from `nvx136.exe`, `quickStimulus.exe` and `neuroMS.exe` at once |
| **The two log routes are mutually exclusive** | Proven by a 4-arm controlled experiment. Setting any of `QT_ASSUME_STDERR_HAS_CONSOLE` / `QT_FORCE_STDERR_LOGGING` / `QT_LOGGING_TO_CONSOLE` flips `shouldLogToStderr()` true, which switches `OutputDebugString` **off**. Arm A (no vars): 75 lines to DBWIN, 0 bytes to stderr. Arm B (vars set): 0 to DBWIN, 35 lines to stderr. If stderr is not genuinely redirected the service is silent on **both** |
| **Only one DBWIN capturer may run** | `DBWIN_DATA_READY` is auto-reset, so N listeners each get ~1/N of the traffic and none can tell. Demonstrated as a disjoint partition of one 3-message burst across two capture files. **A gap in a DBWIN capture is never evidence of silence** |
| **`R\config\*.log` are home-PC artifacts** | All five name `anatolyhome2024` / 100.64.100.6. Decisive proof, independent of reading IPs: every file in `R\config` has `CreationTime 2026-08-17 07:47:15` (the unpack) with `LastWriteTime` of 15–16 Aug — before it existed on this disk. Generalise the test: `CreationTime 07:47:15` + earlier `LastWriteTime` = carried in |
| **The crash is real and exactly localised** | [E1](../../issues/README.md) |

<a id="history-refuted--do-not-re-chase"></a>

#### Refuted — do not re-chase

* **The crash does not explain the visual bugs.** It is an exit-order fault; a verifier's reading
  is that it produces no visible symptom before the process is already going away. Real bug, wrong
  attribution.
* **The QML error mechanism was disproved.** The proposed source — `Resonance__Parameters__Select.qml`'s
  `model: parent.attributes.options` going negative — fails on timing: `Select.qml` is first loaded
  *after* the first TypeError fires. And `TwoWayBinding` is **checkbox-only**: the only file setting
  `otherProperty: 'serialized'` is `Resonance__Parameters__Boolean.qml`; `Select.qml` does not
  instantiate `TwoWayBinding` at all.
* **The deployed QML is byte-identical to source.** `Select.qml`, `TwoWayBinding.js` and
  `ParametersView.qml` all match `R\src\quickStimulus\import\Resonance\`. **No stale-QML shadowing.**
* **The QML errors are probably not new.** They are static defects in QML that shipped in the zip,
  so they very likely fired at home too — which makes them poor candidates for *"bugs I didn't have
  home"*, whatever else they are.

The errors themselves are real and continuous on the live Configurator: **135×** `TwoWayBinding.js:17`
TypeError, **175×** `Model size of -N is less than 0`, **41×** `ParametersView.qml:55` implicitWidth
binding loop, all from one PID. Their cause is open.

<a id="history--safety--raised-independently-by-several-verifiers"></a>

#### ⚠ Safety — raised independently by several verifiers

**`neuroMS.exe` (PID 10204, since 07:23) is running with a powered Neuro-MS TMS coil attached, and
the Configurator surfaces that service's transitions.** `Resonance__Parameters__Select.qml` writes
`parent.serialized = currentIndex` back to the service on `currentIndexChanged`, and its `_block`
re-entrancy guard is **dead** — the only `_block = true` is commented out at line 22. Do not drive
Configurator parameter widgets while a stimulator service is discoverable. Bring `neuroMS` to `init`
and close it from its own UI first; do not kill it from a shell.

<a id="history-housekeeping-left-by-the-investigation"></a>

#### Housekeeping left by the investigation

Leftover processes were created during this run — a DBWIN capturer, at least one Configurator, and
several short-lived `nvx136` instances under distinct `--serviceName` values. Census before
concluding anything about what is running, and remember two `nvx136` instances competing for one
USB device produce false failures.

<!-- Template — copy per finding:

<a id="history-n1--"></a>

### N1 — <one-line summary>

| | |
|---|---|
| Observed | 2026-08-17 |
| Against | `D:\Resonance2026\msvc64\bin\<exe>` |
| Hardware | none / NVX-52 / NVX136 / NS-65 / arduinoTTL COM4 |
| Reproducible | yes / intermittent (n of m) |

**What happened:** what was run, and what came out. Numbers, not impressions.

**Control run:** what was run to rule out the harness. *A negative result with no control is not
a result* — this tree has produced at least four false failures that reproduced on known-good
binaries (`known-issues §7`'s two `env.bat` traps, `neuron-spectrum.md §8`'s checker, and
`known-issues §14g`'s ctypes client).

**Reading:** what it means, and what it does not.

**Open:** what is still unexplained.

-->

---


<a id="history-4-carry-forward--what-the-build-machine-must-do"></a>

## 4. Carry-forward — what the build machine must do

For whoever next has a toolchain. Build commands are in
[build-and-distro.md §5](../migrations/and-distro.md#history-5-build-commands); the environment is
[dev-environment-setup.md](../migrations/dev-environment.md).

**Before building anything from this tree:**

1. **Re-apply the submodule patch.** `scriptEngines/python/pythonengine.cpp:197` renames `stdout`
   → `stdoutHook`, and that edit lives in the *submodule working tree* — a routine
   `git submodule update` discards it silently and the build breaks with no obvious cause
   ([known-issues §2e](../incidents/README.md)). Confirm it survived the transfer to `D:\` before
   assuming it is there.
2. **Nothing here is committed.** The home tree was on local branch `feature/cmake-dual-build`,
   never pushed, with `user.name`/`user.email` unset. This copy has no `.git` at all, so a
   transfer back has to be a file-level merge, not a pull.
3. **Cap parallelism at `-j6`** — the home machine threw WHEA hardware errors and random compiler
   ICEs at `-j32` ([known-issues §11b](../incidents/README.md)). Unknown whether this PC has the same
   problem; the cap costs little.
4. **A compile is not a build — launch it.**
   [build-and-distro.md §7](../migrations/and-distro.md#history-7-verifying-a-deploy) is the three-step
   verification, and §7's two traps produce false failures on *known-good* binaries.

**Then, per §2 entry:** run its **Proves it** check, and record the result back into this file
next to the edit. An edit whose check has not been run stays marked uncompiled.

**Deployment reminder** for anything touching `neuroMS` or `neuronSpectrum`: delete
`bin\NeuroSoft.*.dll` and `bin\Neurosoft.*.dll` before copying over an older tree —
`copy_if_different` never removes anything and CLR probing checks `bin\` before any resolver
([neuroms.md §3](../components/neuroms.md)).

---


<a id="history-5-home-pc-verification-2026-08-17"></a>

## 5. Home-PC verification, 2026-08-17

Run on **`ANATOLYHOME2024`** against `R:\dist\msvc64`, which is where a toolchain and the hardware
docs live. Everything below is a measurement against the deployed binaries, with a control where a
control is possible. Harnesses: `R:\config\select_apply_check.qml`,
`playback_viewer_check.qml`, `playback_controller_check.qml`, `playback_missingfile_check.qml`,
`playback_configurator_path_check.qml`, `configurator_select_check.qml`.

<a id="history-5a--the-select-defect-was-real-here-too-and-the-fix-is-not-the-one-liner"></a>

### 5a — the Select defect was real here too, and the fix is NOT the one-liner

**The home tree carried the identical broken file** — `R\src\...\Resonance__Parameters__Select.qml`
and `msvc64\bin\Resonance\` were byte-identical to each other (SHA-256
`1F48A0F0…DECAAC02`) and to what [E5](../../issues/README.md)
quotes. So the regression was on both machines, exactly as E5's history concluded.

⚠ **But `root.status` → `paramControl.status` is the wrong fix, and E5's own reasoning says why
without following it through.** Repairing the id lets the guard pass — and the thing it was
guarding is a write-back hung on `onCurrentIndexChanged`, which **cannot tell a person's choice
from a programmatic index change**. Qt's `ComboBox.qml` documents that changing `model` resets
`currentIndex` to 0, and `ParametersView` re-assigns `attributes` (hence `model`) on *every*
description re-broadcast. So the one-liner converts "the dropdown does nothing" into "every
re-broadcast silently sends index 0 to the service" — E5 predicts this in its own §"Why `_block`
had to be restored", then reaches for `_block`, which does not work either:

* `popupItems.onModelChanged` inside `ComboBox.qml` is bound to `model` when the base type is
  built, so it is notified **before** the `onModelChanged` handler in `Select.qml`. `_block = true`
  is therefore set *after* the spurious write it is meant to stop, and stays armed to swallow the
  **next** change — the operator's. That is the click-swallowing E5 observed and reverted for.

**What was applied instead:** the write-back moved to **`onActivated`**, which Qt emits only for a
user action — popup item, wheel, arrow keys, type-ahead — and never for a programmatic one
(`ComboBox.qml:340-342`; all four emission sites assign `currentIndex` before emitting, so reading
`currentIndex` in the handler is exact and avoids the deprecated injected `index`, which the
Loader also declares). `_block` is gone, and so is the `status` guard — which removes the
cross-document id dependency E5's last ⚠ warns about, since `activated` cannot fire during load.
A `Qt.callLater(syncFromService)` on `onModelChanged` re-asserts the service's value after the
rebuild, because that reset also **breaks the `currentIndex: remoteIndex()` binding** (it writes
`popup.__selectedIndex` directly).

**Proved, with a control** — the same harness, the same live service, the same emitted signal,
only the QML differing:

| | original file | fixed file |
|---|---|---|
| service took the operator's choice | ❌ `applied=false` | ✅ `applied=true` (`evokedFocus` → `rightmotor`) |
| after a description re-broadcast | widget and service never agreed | ✅ value held, widget re-synced, **no index-0 write** |

<a id="history-5b---e4-does-not-work-as-written-componentoncompleted-does"></a>

### 5b — ⚠ E4 does not work as written; `Component.onCompleted` does

E4 says to put `options` before `index` in `Configurator.qml`. **Measured: that changes nothing.**
`viewer_layout` still read back `"Stacked (2x1)"` with the two swapped.

The reason is a phase, not an order: `options: ["…", "…"]` is an **array literal**, which QML
compiles as a *binding* and evaluates in a later phase than a plain literal like `index: 1`. The
index is therefore applied against an empty option list however the two lines are arranged, and
`Select::setIndex` drops it (`select.cpp:131`). What works, with no rebuild:

```qml
options: ["Stacked (2x1)", "Side by side (1x2)"]
Component.onCompleted: index = 1
```

Verified: a freshly launched Configurator now reports `viewer_layout = "Side by side (1x2)"`.
A saved configuration still wins, since `--serviceConfig` is applied after every constructor.

⚠ **Also found: a `Select` cannot carry a sort index at all.** `Parameter` declares
`Q_PROPERTY(int index …)` for tab ordering and `Select` **re-declares** `index` for the selected
option (`select.hpp:12`), shadowing it. Every other parameter type orders itself with `index: 90`;
a `Select` cannot. Worth a framework fix alongside the `setIndex` one E4 proposes.

<a id="history-5c---e2s-premise-confirmed-binresonance-really-is-live-no-rebuild-needed"></a>

### 5c — ✅ E2's premise confirmed: `bin\Resonance\**` really is live, no rebuild needed

`--builtIn configurator` loads `qrc:/resonance/apps/configurator.qml`, which is compiled into the
exe — but that file is two lines, `import Resonance 3.0` / `Configurator{}`, so the window itself
comes from `bin\Resonance\Configurator.qml` **on disk**. Demonstrated rather than assumed: the 5b
edit took effect on the next launch with no rebuild.

<a id="history-5d---playbackservice-is-not-broken-n63-does-not-reproduce"></a>

### 5d — ⚠ playbackService is NOT broken. [N6.3](../../issues/README.md) does not reproduce

Every layer was exercised on `data\pbref-0003.h5` (the §7 reference file) and the real
`StreamView` — the same component the Configurator puts in its right-hand pane — with the
receiver read directly rather than the window eyeballed:

| Path | Result |
|---|---|
| `playbackSource.bat --autoStart` standalone → viewer | ✅ 4 ch @ 250 Hz, 60 `dataReceived`, four valid lanes (±70.71, RMS 50.000) |
| `Playback` controller: `file` → scan → `prepare` | ✅ `idle → armed`; slots filled `annotations`/`aux`/`eeg`, all `play=true` |
| viewer attached **at `armed`** | ✅ `sourceInfoEmpty=false`, `channels=4`, **`dataSoFar=0`** — published and listening, emitting nothing, exactly as §7a.2 claims |
| `start` → `playing` | ✅ 77 `dataReceived`, four valid lanes |
| **the Configurator's own double-click path** | ✅ works — see below |

**The `discover://` filter hypothesis is refuted.** `Configurator.qml`'s `streamFromCtrlObject()`
throws away every non-`discover://` connection when *Use service discovery URL for streams* is
ticked (the default), so a worker that advertised none would hand the viewer an empty connection
list. It advertises one: `StreamPool.cpp:44` appends
`discover:///?stream=eeg&name=PBC` to every published stream, the spoofed service appears in the
tree with all three streams, and the filtered JSON kept exactly that connection and carried data.

**A missing file is not silent either** — this was the leading hypothesis, since §1 warns that
absolute `R:\` and `N:\` paths do not survive the move, and
`R:\config\playback_service_4tep.json` does carry
`N:\Projects_MSU\2025 - TEP\…\01_TP_M1_60MSO_single_REAL.hdf5`. Pointed at a path that does not
exist, the service reports `contents = "No such file: …"`, drops every stream slot, and **refuses
both `prepare` and `start`**, staying in `idle`. Visible, and correctly refused.

⚠ **So the work-PC symptom is still unexplained, and it is environmental rather than a code
defect.** What differs there and could still produce it, in order:

1. **The wrong path, seen but not noticed.** `contents` is a read-only text in the parameter panel
   — and on that machine the panel was ~252 px wide with a clipping scrollbar and a 41× binding
   loop ([E2/E3](../../issues/README.md)). The message was
   probably there and unreadable. **Check `contents` first.**
2. **[N6.2](../../issues/README.md), the four advertised
   addresses.** This home run also advertised four (`100.64.100.6` Tailscale, `172.20.144.1`
   Hyper-V, the real LAN, the hostname) and still connected — but `TcpStreamReceiver` blocks the
   **GUI thread** up to 3 s per dead candidate, so on a machine whose first candidate is a VPN TAP
   the viewer can sit blank for 6–12 s. From the chair that is "nothing is playing back". Time it
   before concluding anything.
3. **`showUi`/window state**, if the operator was watching the module's own window rather than a
   viewer.

**What is needed from the work PC** to close this: the `Playback` service's `contents` and `state`
at the moment it looks dead, and whether `playbackSource.exe` appears in Task Manager while
`armed`. Those three answers separate all of the above.

<a id="history-5e--the-deployed-and-source-copies-are-in-step-again"></a>

### 5e — the deployed and source copies are in step again

`Resonance__Parameters__Select.qml` and `Configurator.qml` are byte-identical between
`R:\src\quickStimulus\import\Resonance\` and `R:\dist\msvc64\bin\Resonance\`. Genuine pre-edit
backups — taken *before* the edit, unlike the one E5 warns about — are in
`R:\dist\msvc64\bin\Resonance\_backup-2026-08-17-home\`.

⚠ **E2 and E3 are still NOT applied on the home tree.** They are layout-only and were out of scope
for this session; the two files above now differ from the work PC by exactly those edits.
