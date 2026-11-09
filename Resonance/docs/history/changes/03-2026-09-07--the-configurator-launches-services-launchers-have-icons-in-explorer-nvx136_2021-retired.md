# 2026-09-07 — the Configurator launches services; launchers have icons in Explorer; NVX136_2021 retired

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-07--the-configurator-launches-services-launchers-have-icons-in-explorer-nvx136_2021-retired"></a>

### 2026-09-07 — the Configurator launches services; launchers have icons in Explorer; NVX136_2021 retired

⭐ **The Configurator's menu-bar row now carries an icon strip**, and the strip is a text file
the operator owns: `R:\dist\launchbar.txt` — one line per button, `launcher.bat | what it does |
icon`, `[heading]` lines starting the groups (a thin separator each), `#` comments. The shipped
version, `launchbar-default.txt`, lists 23 launchers in three groups — the general tools
(Configurator, Recorder, message sender, playback, signal generator, SPEED, latency probe), then
acquisition (NVX, NVX136, actiCHamp, Neuron-Spectrum, KARDi2, DAQmx, FieldTrip, EyeLink), then
stimulation (Stimulus, TEP·SOUND, Neuro-MS, mStim, eStim, feetStim, arduinoTTL, COMport) — each
with a one-sentence tooltip saying what the service does. It is copied to `launchbar.txt` when
that file is missing and never touched afterwards, so a rig keeps its own strip across deploys:
drop the launchers it never uses, add a copied `.bat` with a different preset (`NVX136_25K.bat`
with `icons\nvx136-25k.ico`). A button wears the icon of the executable its launcher starts,
read out of the executable at run time, unless its line names a `.ico` from the new
`R:\dist\icons\` (every rendered icon ships there) or an executable's numbered icon group. The
file is watched — the strip follows a save — and **View → Edit icon strip…** opens the folder
with it selected; **View → Show icon strip** hides the strip, remembered. A launcher named but
missing shows greyed out. A click runs the launcher through a hidden `cmd.exe` from the
distribution root: no console flash. Rule and mechanism: [architecture §11d](../migrations/framework-evolution.md).

**Icons reworked on the same day.** A seventh family, **purple**, for trigger and marker output
towards the stimulation side — arduinoTTL and COMport, which sit in the stimulation group now
(latencyProbe is a general instrument and moved to the general group). feetStim is a footprint
(ball, arch, heel, five toes) instead of a sole with dots; FieldTrip is its initials, `FT`, over
the trace it streams in, in acquisition blue, not a database cylinder. The EEG amplifiers carry
two large labels instead of a small badge: the model top-right (`52`, `136`, `NS`, `aC`) and the
default sampling rate bottom-right (`1K` for all four), each laid out for three characters with
equal margins to the tile's edges, and the head became a big half-head cut by the tile's left
edge — the ring, half the nose at the top, the right ear — so it is no longer a small blob
beside the numbers; `nvx136-25k.ico`
(`136` / `25K`) is rendered for a 25 kHz preset launcher and ships as a file only. The strip
draws its icons at **24 px** (was 20). The colour legend is in `R:\src\icons\README.md`.

**The parameter panel's order is deterministic now.** Two Configurators showed the plot tab in
two orders — "Viewer layout" and "Plot 1 stream" swapped, "Epoch cursor link" and "Plot 2
stream" swapped — because every QML `Parameters { }` container numbered its unindexed parameters
10, 20, 30 on its own, so the Configurator's two Selects tied with the two viewers' stream
entries and the tie fell to registration order, which differs between instances. The container
has `firstIndex` / `indexStep` now (the Configurator's uses 1, 1: Viewer layout, Epoch cursor
link, then viewer 1 at 10..15, viewer 2 at 20..25, head calibration at 90..93), it registers
its children once, at completion, and the panel's sort breaks equal indices by name, so no
service can flip again. Message sender is **teal** (a stream made by hand belongs with the
signal generator), latency probe closes the general group, the retired `nvx136-2021` icon was
re-rendered to the new layout, and **`/icons`** (`R:\.claude\skills\icons`) regenerates the set
and shows the preview sheet.

**Neuro-MS: two defects from the rig, fixed and packaged.** (1) Connecting no longer left the
machine in paired-pulse mode: the driver adopted the profile's 10 ms interval at connect and the
handshake re-applied it (`… reapplied delay 10 ms`). It adopts the intensities only now; `delay`
stays the service's — 0 ms, simultaneous, by default, and a paired-pulse configuration chosen
before connecting still survives. (2) Disconnecting from a stimulator that had been switched off
and unplugged froze the service and emptied its parameter panel in the Configurator: the vendor
teardown ran through a blocking cross-thread call and never returned — and the two frozen
services were later found at **13 GB of memory each**, writing to the SSD flat out: the vendor
stack's own threads carry on after the USB device is gone, and nothing on our side (all bridge
queues are fixed-size) or in the vendor API stops them. ⚠ **A lost stimulator therefore ends the
service now**, out loud and with exit code 3: the disconnect is queued with a 10 s watchdog, five
unanswered status reads drop the session through the new `NMS_Abandon()` without a vendor call,
either path ends the process 500 ms after its log line, and a memory guard ends it above 1 GB
(`NEUROMS_MEMORY_CEILING_MB`) whatever else is going on. `NEUROMS_EMU_UNPLUG_MS` /
`NEUROMS_EMU_CLOSE_HANG_MS` reproduce it offline; hardware not run. Two follow-ups from the rig the
same evening: the interval was *still* 10 ms on the machine, because the status poll's mirror
copied the machine's first real report into `delay` before the handshake wrote (the emulator had
dodged it by timing) — the mirror now leaves the interval alone until the service has written its
own once; and a Neuro-MS that answers `ERROR_BAD_COMMAND` after a USB re-plug (it wants a power
cycle) is a failed connect, not a lost machine — `error` state, an explanation, the service stays
up, the vendor's repeated error lines rate-limited; every self-exit also writes
`bin\neuroMS.last-exit.txt` and waits 6 s with a console on screen. A third round the same day:
the service connected in only **30–60 %** of attempts (`NMS_Open failed (bridge error -1)`, no
reason) — the bridge's own tidying call was wiping the explanation before the driver could read
it, a stimulator that has just been closed refuses an open until it has settled, and one refusal
was final. The reason now survives the cleanup, an open waits out a 1.2 s settle window after a
close, and the driver retries three times 700 ms apart, re-enumerating and matching **by serial**.
⚠ A failed connect also emptied the Stimulator list — the rescan it triggers landed in the window
where driver calls are skipped — so the *next* connect failed too; a skipped scan is re-run when
the driver is free. A fourth round closed the two faults that made: the retried open turned the
still-blocking connect into a **>10 s freeze** of the whole service, so the connect is queued and
watched (45 s) like the disconnect, with the Stimulator row reading `connecting…`; and five failed
status reads — 2.5 s of silence — were ending the service outright, which took a live session down
about a minute in. Five failures are a **question** now: the driver enumerates the bus once, and a
machine that is still on it is a **stall** that keeps the session for 30 s of retries rather than
disconnecting anything. Only a machine that is gone ends the process, and the memory guard now
disarms and closes first. A fifth round widened the open retry to **5 attempts with a growing
pause** after a *cold* start was reported opening only on the third try — the wait belongs to the
machine after the previous host lets go — added a deterministic release of the vendor's USB handle
in `NMS_Close()` (it is freed from a finalizer, so dropping the reference was not enough for a
reopen in the same process), and made a failed open name any other `neuroMS.exe` still running.
⭐ A sixth round made the service **write things down**, after a report that it had "randomly
disconnected (turned off) the device" with the console gone: `bin\neuroMS.log` takes every line
across runs (banner with pid, command line, vendor build and every `NEUROMS_*` set; rolls at
64 MB; `NEUROMS_LOG=off|<path>`, `NEUROMS_LOG_VERBOSE=1`), a **heartbeat** every 10 s records
state, mode, charger, intensities, interval, alarms and **private memory**, every disconnect logs
**the reason it was given**, and an unhandled exception writes a minidump. ⚠ And
**`NEUROMS_NEVER_SELF_DISCONNECT=1`** stops the service touching the connection on its own at
all — faults are reported, nothing is dropped, the operator decides — which is what an experiment
wants. **The log immediately paid for itself**: it measured a failed open at ~7 s inside the
vendor call plus as much again for the re-enumeration (~14 s per retry — the pauses were never
the cost), a successful one at ~3 s, and the machine becoming openable **45–50 s** after a
session whose charger had been armed or whose panel had been switched off, against 6–10 s
otherwise. The retry therefore runs to 8 attempts with a flat 500 ms pause and times every
phase; the connect watchdog is 240 s. ⚠ It also showed the .NET heap swinging to **363 MB**
during those attempts, one bad connect away from the 1024 MB memory guard: the ceiling is 2048 MB
now and must be exceeded on three consecutive samples. ⚠ The round after that removed a cascade
the asynchronous connect had introduced: a retried open owns the worker for up to two minutes, so
a skipped driver call was being read as a device fault (`Unable to charge` → `error` →
disconnect), and the disconnect watchdog was timing the *open* rather than the disconnect and
ending the process. A skipped call now retries instead of erroring, the watchdog is armed only
once the worker can reach the disconnect, and `cancelConnect()` lets a disconnect abort a retry
loop within one open call. The timings also settled the open question: the open is 13.1 s and the
re-enumeration 0.5 s, so `NEUROMS_OPEN_REFRESH=0` buys nothing. Nine emulator scenarios pass,
including the cascade reproduced end to end.

⭐ **Resolved: two services on one stimulator.** The log caught it — `another neuroMS.exe is
running (pid 14408)` — and that is the whole evening explained. The Qt 5 and Qt 6 builds have the
same executable name, both were running, and each held the device away from the other; switching
builds only swapped which one was locked out, which is why "Qt 5 broke too" and why a reboot
changed nothing. The duplicate-process check now runs **before the first open** and says that one
service per stimulator is the rule. ⚠ And the readiness poll is queued like the connect and the
disconnect: a single probe blocked the service for **53 s** while the USB link was erroring, which
is exactly the reported "wedged, no parameters" — a blocked main thread answers no discovery and
publishes no description, so the Configurator shows the service with an empty parameter pane.
Nothing on the main thread waits for the device any more.

⚠⚠⚠ **The wrong turn before that, kept for the record.** The Qt 5 build of 2026-08-28 reconnected instantly
once — and an hour later stopped connecting at all on the same machine, **surviving a reboot of
the PC**, while the Qt 6 build opened on its eighth attempt. So both builds are refused
identically: it is **not** a Qt 6 regression, the refused open is a consistent 13.00 s timeout
below our code, and it always gives in after a few attempts. The driver now retries **12** times,
logs the enumeration count between attempts (present-but-refusing versus dropping off the bus),
says plainly that Qt 5 is refused the same way, and doubles the memory ceiling while a connect is
in flight — a refused connect churns to **1.3 GB** inside the vendor stack. The decisive test if
it recurs is Neurosoft's own program. The two additions of that afternoon stay **off** regardless,
because neither was measured. A call-for-call diff of the two device-facing paths leaves exactly two differences, both
added on 2026-09-07 and both reasoned rather than measured: the settle sleep before the open, and
the forced `GC::Collect()` / `WaitForPendingFinalizers()` in `NMS_Close()` (the better suspect —
running the finalizer the instant Close returns can cut the machine's own power-down short).
**Both are off by default now**, so the shipped path is the Qt 5 one; `NEUROMS_OPEN_SETTLE_MS`
and `NEUROMS_CLOSE_GC=1` switch them back on for a controlled test. The lesson is recorded in
[service_neuroms.md](../components/neuroms.md): diff against the working comparator before adding a
mitigation.
Details in [service_neuroms.md](../components/neuroms.md). ⚠ For the lab machine that runs an older
copy of the distribution, the cumulative patch is
`R:\src\_patches\neuroms-interval-and-disconnect-20260907` (`bin\neuroMS.exe` +
`bin\nmsbridge.dll` + README); `R:\resonance_20260907.zip` was taken before these fixes and does
not carry them.

**Three smaller changes the strip surfaced.** `actiCHamp` gains a **1000 Hz** option and starts
on it, like the NVX drivers (10 kHz base, decimation 10; the two unused 1/2 kHz rows of the plan
table divided the 50 kHz base and would have mislabelled their frames — corrected, with a test
that every row divides down to its label). ⚠ The 1 kHz mode has not been run on a physical
actiCHamp. `eStim`, `feetStim` and `arduinoTTL` no longer persist `showUi` into their `.ini`:
closing a window still hides it for the run, but the next launch from a `.bat` starts with the
window again — the three had come up headless because someone had once closed the window, and
`R:\dist\bin\{eStim,feetStim,arduinoTTL}.ini` carried `showUi=false` (removed; copies kept as
`*.ini.pre-20260907`). The general group's order is Configurator, Recorder, playback, latency
probe, then the three stream makers SPEED, signal generator, message sender.

**Launchers have icons in Explorer — as shortcuts.** A `.bat` cannot carry an icon; Explorer
draws the batch-file glyph for the extension whatever the file says. So
`scripts\make-launcher-shortcuts.ps1` writes `R:\dist\launch\<name>.lnk` for the same 23
launchers, each pointing its icon at the executable it starts — the three quickStimulus
built-ins at the numbered icon groups `resonance_icon()` now embeds beside `IDI_ICON1`
(`101=configurator 102=recorder 103=message-sender`). `deploy-qt6.ps1` runs it last; a copy is
installed as `tools\make-launcher-shortcuts.ps1`, to be re-run wherever the distribution is
copied, because shortcuts hold absolute paths. `COMport.bat` and `latencyProbe.bat` were the two
launchers still relying on the current directory (`call env` / `cd bin`); they use `%~dp0` now,
like the rest.

**`nvx136_2021` is retired.** The cold-start comparison it was built for on 2026-09-02 is done
([qt6-work-list §1c](../migrations/qt6-work-list.md)), and it registered under the same service name as
`nvx136` — one mis-click from two services answering one name. Out of the root `CMakeLists.txt`,
`bin\nvx136_2021\` and `NVX136_2021.bat` removed from `R:\dist` and from the deploy and
validation scripts; the sources stay in `R:\src\nvx136_2021\` for reference, and
`bin.pre-20260906-1402-icons\nvx136_2021\` still holds the last binaries. `R:\dist\bin` holds
**24** executables (23 applications plus the KARDi2 broker); **30** launchers at the root.

**Docs brought up to date on the port state.** Every "only stimulusService remains unported" and
"DAQmx is not ported" left over in the README, the transition record, new-PC setup, the dev
environment, known issues, the snapshot procedure, the module audit and the architecture notes
now says what has been true since 2026-09-06: no active service is on Qt 5, and the comparator's
remaining jobs are the 18 legacy `sp_*.qml` paradigms and the parity oracles. Dated entries below
keep their wording, with a strike-through or a bracketed note where they have been overtaken.

Built clean; deployed with `cmake --install` (Qt closure unchanged); `validate-dist-qt6.ps1`
**PASS**, now asserting `launch\configurator.lnk`, `tools\make-launcher-shortcuts.ps1`,
`launchbar-default.txt` and `icons\nvx136-25k.ico`. Verified live: a fresh start creates
`launchbar.txt` from the shipped file and shows the 23 buttons in three groups with the
tooltips; a line added while the Configurator runs appears within a second (an `icons\` icon, a
numbered exe group, a missing launcher greyed out) and disappears when the file is restored;
Edit icon strip opens Explorer on the root with the file selected; `playbackService` started
from the strip and from its shortcut comes up visible and un-minimised with no console on
screen; the setting turned off in the registry keeps the strip hidden through a restart;
Explorer shows 23 distinct icons in `launch\`. ⚠ Rollback copy of the touched files:
`R:\dist\bin.pre-20260907-launchbar\`; `quickStimulus.exe.pre-20260907b` and
`Resonance\quickStimulusPlugin.dll.pre-20260907b` are what two Configurators left open during
the last install run on and can go once they are closed. **Snapshot `R:\resonance_20260907.zip`** (492 MB,
stored) taken at the end of the day to the 2026-09-06 recipe (distribution + docs, no source, no
config; `*.pre-*` rollback files excluded too). Observed on the way: `cmake --install` rewrites
`montages\mks64_standard.ced` on every deploy, because two byte-identical sources
(`quickStimulus\import\Resonance\Bricks\` and `tepSoundService\montages\`) install to the same
path with different timestamps — harmless, content never changes.

