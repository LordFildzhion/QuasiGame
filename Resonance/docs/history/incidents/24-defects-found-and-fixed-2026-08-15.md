# 14. Defects found and fixed 2026-08-15

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-14-defects-found-and-fixed-2026-08-15"></a>

### 14. Defects found and fixed 2026-08-15

**Mixed — the driver and framework fixes transfer, three entries do not.** All of 14a–14f, 14h–14j
and 14d-bis crossed with their modules. The three exceptions:

* **§14k — FIXED BY THE PORT.** The all-zero final row is gone from Qt 6 recordings; see the entry.
* **§14l — QT 5 ONLY.** The Controls 1 `TableView` delegates and the `TabView` layout it repairs do
  not exist under Qt 6. The *principle* survived the port and is now evidence rather than advice:
  `ParametersView.qml:28` in the Qt 6 tree still carries the 130 px column — as
  `labelColumnWidth`, pinned since 2026-09-06.
* **§14g — UNKNOWN UNDER QT 6.** See the entry.

<a id="history-14a-signalgenerator-stops-producing-data-at-midnight---fixed"></a>

### 14a. `signalGenerator` stops producing data at midnight — ✅ fixed

`SignalGenerator/generator.cpp` paced its next block with **`QTime`**, which is a *time of day*
and wraps at 24 h:

```cpp
int lag = last.msecsTo(now) - msecs;   // last = 23:59:59.988, now = 00:00:00.000
late = late + lag;                     // -> late == -86,400,000
timer.setInterval(qMax(0, msecs - late));   // -> ~24 hours
```

The timer is single-shot, so nothing restarts it. The process stays up, the stream stays
published and the service keeps answering parameter reads — it simply never emits another
block again that day. **It looks exactly like a running generator producing nothing**, and it
only happens to whoever leaves a generator running across midnight.

Reproduced 2026-08-15: a generator started 23:57 had emitted **0 blocks** an hour later, while
one started at 00:54 ran at 252.6 Hz. Fixed by measuring with `QElapsedTimer` (monotonic) and
bounding the catch-up correction to ±1 s so a long stall or a resume-from-sleep cannot buy an
unbounded burst either.

<a id="history-14b-two-generators-are-indistinguishable-to-a-consumer---mitigated"></a>

### 14b. Two generators are indistinguishable to a consumer — ✅ mitigated

Discovery addresses a stream as (service name, stream name), and both defaulted to
`signalGenerator` / `generated` with no way to set them from the launcher. Two generators on
one machine are then the same address, and a viewer or recorder attaches to whichever answers
first. `SignalGenerator` now takes **`--streamName`** (`--serviceName` was always available
from `ResonanceApp`), and `signalGenerator.bat` passes both explicitly so copying the launcher
is enough to run a second one.

<a id="history-14c-nvx136_2025-could-never-start-nvxsetmirrortriggers-is-not-supported---fixed"></a>

### 14c. NVX136_2025 could never start: `NVXSetMirrorTriggers` is not supported — ✅ fixed

`Nvx136Driver::configureCommon()` called `NVXSetMirrorTriggers` unconditionally and treated any
non-zero return as fatal. The connected media converter answers **`NVX_ERR_SUPPORT` (-5)** —
"function is not supported" — so **every** start failed, including with mirroring off, which is
the default. The service went straight to `error` with no operator-visible reason (the message
only reached `qWarning`, and the service is windowed).

Now routed through `applyOptionalSetting()`: `NVX_ERR_SUPPORT` is a warning when the operator
asked for the state the device is already in (mirroring off, internal PLL, power save off) and
still an error when they asked for the feature — silently acquiring without a requested
hardware setting would mean recording under conditions that are not the configured ones.
Applied to `NVXSetMirrorTriggers`, `NVXSetPll` and `NVXSetPowerSave` (the last one in `probe()`
as well, where a failure emptied the channel list instead).

> ⚠ **2026-08-25: `NVXSetMirrorTriggers` is gone entirely.** The call, the `mirror_triggers`
> parameter and `HardwareOptions::mirrorTriggers` were removed rather than tolerated. The
> workaround above still stands for `NVXSetPll` and `NVXSetPowerSave`. `params\*.json` files
> that still carry a `mirror_triggers` key are not a problem: `--serviceConfig` reports
> `mirror_triggers NOT APPLIED - this service has no parameter by that name` and starts
> normally.

<a id="history-14d-nvx136_2025-did-not-re-announce-when-its-publisher-became-ready---fixed"></a>

### 14d. NVX136_2025 did not re-announce when its publisher became ready — ✅ fixed

The same race `R:\tests\2026-08-14_nvx2025-driver-campaign\NVX-NVX136-2025-Operator-Change-and-Acceptance-Guide.docx`
describes for NVX2025, never applied to NVX136: the driver builds the stream on its worker
thread while the publisher is created asynchronously on the main thread, so the service can
reach `running` and broadcast a description that contains no `eeg` stream. A consumer resolving
by name never learns about it, because nothing else makes the service re-describe. Observed as
acquisition running with the viewer empty on some starts and not others. `Nvx136Config::start()`
now connects `OutputStream::ready` to `sendDescription()` and covers the reverse race.

<a id="history-14d-bis-nvx136_2025-also-named-every-eeg-channel--n---fixed"></a>

### 14d-bis. NVX136_2025 also named every EEG channel `?? N` — ✅ fixed

`Nvx136Driver::createStream()` called `addCEDinfo(ced, cedMask)` unconditionally, so with no CED
file loaded every EEG output came out `?? 1 … ?? 32` — exactly [§12h](36-parseced-on-an-empty-file-relabels-every-channel--n---fixed-in-nvx-2026-08-14.md#history-12h-parseced-on-an-empty-file-relabels-every-channel--n---fixed-in-nvx-2026-08-14)
in the other driver. Caught in the first successful NVX136 recording. Now guarded on
`!ced.isEmpty()`.

All of 14c–14e were verified on the physical media converter: three clean start/stop cycles and
a 4,921-row recording at 250 Hz with 0 NaN and correct `Ch N` / `Trigger` metadata. Details in
STATUS.md ([change history](../changes/README.md)).

<a id="history-14h-nvx136-impedance-gnd-is-the-last-word-not-the-word-after-the-eeg-block---fixed-2026-08-15"></a>

### 14h. NVX136 impedance: GND is the **last** word, not the word after the EEG block — ✅ fixed 2026-08-15

Measured 2026-08-15 on the physical converter, electrodes in water, ground connected. Lowest
value seen per word index over eight scan cycles, `CountEeg=128`, `CountAux=8`:

| index | reading | what it is |
|---|---|---|
| 0…3 | 2.5 / 9.0 / 2.0 / 3.0 kOhm | electrodes in water |
| 126, 127 | 999 900 Ohm | unused electrode positions |
| **128** | **999 900 Ohm** | **AUX 1** — this is where the driver currently reads GND |
| 129…135 | 999 900 Ohm | AUX 2…8 (exactly `CountAux` words) |
| **136** | **0 Ohm** | **GND** |

So the wire format is `[EEG(0 … CountEeg−1), AUX(CountEeg … CountEeg+CountAux−1), GND(CountEeg+CountAux)]`,
and the header's *"N channels (equal CountEeg field) + 1 GND"* is simply wrong. The DLL actively
writes index 136 (it is not left as fill), and the eight words before it read exactly the
unconnected value — which is also why 137 words is the smallest buffer `NVXImpedanceGetData`
accepts. **The required buffer size is not a quirk; it is the layout.**

Consequence today: `Nvx136Driver::initializeImpedance()` maps GND to `word == m_eegChannels`
(128), so the operator sees AUX 1 labelled GND, permanently reading out of range, while the real
ground reading at 136 is never published. Every EEG channel is correct.

**Fixed:** `impedanceGndWord(eeg, aux)` replaces `impedanceWords(eeg)`, the read buffer covers
the AUX words, and the selection index is no longer assumed to equal the word index. The AUX
words carry no impedance and are not published.

Confirmed after the fix, through a recording: GND reads **0 / 8500 / 9000 Ohm** across updates —
a live measurement rather than a stuck maximum — while 64 electrodes read 1.5–28.5 kOhm and the
64 unwired positions read 999900.

<a id="history-14l-the-parameter-panel-sized-its-label-column-per-tab---fixed-2026-08-15"></a>

### 14l. The parameter panel sized its label column per tab — ✅ fixed 2026-08-15

**QT 5 ONLY as written, but the conclusion survived the port as evidence.** Controls 1 `TabView`,
`TableView` and `TableViewColumn` are gone in Qt 6; `ParametersView.qml` was reimplemented on
Controls 2 with a local tab-descriptor API, and the channel and bipolar lists were rewritten. The
cap, however, was kept deliberately: `R:\src\quickStimulus\import\Resonance\ParametersView.qml:28`
is still `property int labelColumnMaxWidth: 130`, applied at `:177`. ⚠ Controls 2 brought its own
version of the same problem — it floors every control at 100×40 px through its *background* — which
is why the Qt 6 port had to set explicit 18 px service and channel rows and 24 px bipolar rows
(`R:\src\docs\PORTING_LOG.md`).

`ParametersView.qml` lays each tab out as its own two-column `GridLayout`, and a GridLayout
sizes its columns from its own children. So every tab picked a different label width: the entry
boxes started at a different x on each one, and a single long label — `Disable unselected analog
channels in hardware`, 46 characters — widened that tab past the dock and clipped every control
on it. Two independent layouts cannot be made to agree by negotiation; this is the same lesson
as [signal-viewer.md §11](../components/signal-viewer.md#history-11-traps-this-rework-walked-into), where the fix was
to stop negotiating.

What has to match across tabs is the **total**, not each column: label + control should fill the
panel and stop there. That happens on its own — the layout fills the viewport and the controls
carry `fillWidth` — *unless* some tab's content forces the layout wider than the panel, in which
case that tab alone overflows. So column 0 was **capped**, not pinned
(`ParametersView.labelColumnMaxWidth`, 130 px): a tab of short labels still got a narrow label
column and correspondingly wide controls, and a tab with longer ones stopped at the cap and wrapped
instead of eating the control side. Pinning it to a fixed width was the first attempt and was
rejected then — it made the main tab's controls needlessly narrow.

⚠ **SUPERSEDED 2026-09-06: the column is now PINNED after all** (`labelColumnWidth`, 130 px). The
objection above is still true and was accepted as the price. What it missed is that "capped" makes
the geometry *per tab and per service*, so the operator sees the controls jump every time they
select a different service — which reads as broken even though each panel is individually fine.
Uniformity won. See
[qt5-to-qt6-transition.md section 6a](../migrations/qt5-to-qt6-transition.md#history-6a--the-parameter-column-is-300-px-this-is-a-contract).

Two `Controls 1 TableView` delegates were a second cause: `ChannelsList` and
`BipolarChannelsList` inherit a 200x150 default, and the 200 alone pushed the panel past the
dock. Both now ask for 120 wide and let `Layout.fillWidth` do the rest. Height went to 200 —
the channel list is where operators spend the most time and eight visible rows out of 128 is a
lot of scrolling.

A third, inside the channel list: `TableViewColumn` defaults to 160, so the "Channel name"
column plus the 30 px tick column was wider than the panel could give it. The table grew a
**horizontal scrollbar, and that scrollbar then ate a row's worth of the height**. The name
column is now `viewport.width - 30`, so it always fits and the scrollbar is gone.

Tooltips had the mirror-image problem — no width at all. See
[architecture.md, "Descriptions (tooltips)"](../migrations/framework-evolution.md#history-descriptions-tooltips--write-them-long-render-them-narrow)
for the policy and `ParameterToolTip.qml` for the mechanism.

Labels in both drivers were shortened to fit the pinned column; the detail moved into the
tooltips, which already carried it. Longest label per tab is now `nvx` main 17, `nvx136` main
15, hardware 22, trigger 18 — down from 30, 15, 46 and 39.

<a id="history-14k-every-hdf5-dataset-ends-in-one-all-zero-row--open"></a>

### 14k. Every HDF5 dataset ends in one all-zero row — OPEN

**FIXED BY THE PORT — and it changes what a Qt 6 recording looks like, so read this before comparing
files across the two trees.** Both halves are gone in `R:\src\Core\Resonance\internal\HDFRecorder.cpp`:

| | Qt 5 (`R:\src_Qt5`) | Qt 6 (`R:\src`) |
|---|---|---|
| numeric `data` created at | 1 row (`:159`) | **0 rows** (`:163`) |
| numeric `data` extended to | `offset + samples + 1` (`:216`) | **`offset + samples`** (`:220`) |
| `messages` created at | 1 row (`:297`, `:403`) | **0 rows** (`:300`) |

So a Qt 6 recording has `rows == sum(blocks.samples)` exactly, and a stream that delivered nothing
has `shape == (0,)` rather than one uninitialised row. The Qt 6 source comment gives the reason the
phantom row was worth removing rather than tolerating: besides being the wrong sample count, it
**fabricated a trigger edge and a counter reset** for any consumer that read the whole dataset.

⚠ **A Qt 6 file is one row shorter than a Qt 5 file of the same recording.** That is not a dropped
sample. ⚠ **This was deliberately NOT back-ported to `R:\src_Qt5`**, so every comparator recording
still carries the phantom row and the advice below still applies to it. Analysis code that
reconciles against `blocks.samples` — which is what everything in this tree already does — is
correct on both.

`HDFRecorder` pre-extends the dataset by a row it never fills, so the last row of every dataset
is zeros and `rows == sum(blocks.samples) + 1`. Confirmed on both stream types: a 74-block
impedance file has 75 rows, and the 2,499,840-sample 25 kHz file has 2,499,841.

Harmless for a 2.5-million-row EEG recording, misleading for a 74-row impedance one — a whole
cap of 0 Ohm reads as perfect electrodes. Anything analysing a recording should trust
`blocks.samples`, not `data.shape[0]`.

Message and EventBus datasets have the same shape for a different reason: they are *created* at
one row and the first record is written into row 0, so they carry no phantom row once anything
arrives — but a stream that delivers **nothing** leaves that uninitialised row on show, and
`shape == (1,)` with `created == 0` reads as one record when it is none. That cost a debugging
session; see [§17b](32-framework-findings-from-building-estim-2026-08-16.md#history-17b-recorderservice---serviceconfig-records-nothing-from-a-configured-stream---fixed-2026-08-16).

<a id="history-14j-nvx136-impedance-publishes-partially-swept-frames-as-zeros---fixed-2026-08-15"></a>

### 14j. NVX136 impedance publishes partially-swept frames as zeros — ✅ fixed 2026-08-15

The vendor needs ~750 ms per 32 electrodes, so a full 128-electrode sweep takes about 3 s, but
the driver publishes every 800 ms. Electrodes the current sweep has not reached yet come back as
**0 Ohm**, and 0 is not a sentinel — it is the best possible impedance. A viewer colours it
green. Seen directly in a recording: an update mid-sweep read `0 0 0 0 0 0` for Ch 1–6 while the
previous update had 1.5–28.5 kOhm on the same electrodes.

An operator watching the cap therefore sees channels flash to "perfect" every few seconds. GND
does the same and simply takes longer to appear, being the last word in the frame — which is why
its "0 Ohm" first looked like a plausible ground-to-ground reading. **It is not: the real ground
impedance on this cap is 8000–8500 Ohm.**

**Fixed** by holding the last real reading per output and republishing it until the device
measures that electrode again, still at the 800 ms cadence. A value replaces the hold, and so
does `NVX_IMP_INVALID` — that is a measurement, meaning out of range, and becomes NaN. Only 0 is
treated as "not measured yet". Before the first reading a channel is NaN, which the viewer draws
as no reading, rather than 0, which it would draw as perfect.

Verified in a recording: **not one 0 anywhere in the driver's output** across 74 updates, the
"no reading yet" count decaying 113 → 76 → 29 → 2 → 0 as the sweep fills in, and GND settling at
8000–8500 Ohm. (The all-zero final row of the file is §14k, not the driver.)

<a id="history-14i-nvx136-start-pays-275-s-for-a-battery-reading-the-device-does-not-have---fixed-2026-08-15"></a>

### 14i. NVX136 start pays 2.75 s for a battery reading the device does not have — ✅ fixed 2026-08-15

`Nvx136Driver::initialize()` calls `NVXGetBatteryParameters` after `NVXStart` and logs the
result. Measured on this converter, both battery calls **block for ~2.75 s and then fail with
`NVX_ERR_FAIL` (−3)**, stopped or running, every time.

Where a Start actually goes, timed in the driver's own call order:

| call | time |
|---|---|
| `NVXOpenEx` | **3267 ms** |
| `NVXGetDevices`/`SetDevices`/`SetSettings`/`SetPowerSave`/`SetChannelsEnabled`/`SetAuxGain`/`SetPll` | ~280 ms total |
| `NVXStart` | 222–1136 ms |
| `NVXGetVersion` | 48–285 ms |
| **`NVXGetBatteryParameters`** | **2750 ms — ours to remove** |
| first data after `NVXStart` | 0 ms (already queued) |

So the several-second Start is genuine SDK/hardware — `NVXOpenEx` alone is 3.3 s, presumably the
media converter's firmware boot — **plus** ~2.8 s the driver adds for nothing. Nothing in
Resonance sleeps or polls on that path.

`NVXGetVoltages` by contrast succeeds in 16–32 ms and returns real data (VDC 6.16 V, 28.5 °C).

**Fixed:** the battery call is gone — Start measured at **5.0 s**, down from ~7.8 s. In its place
a read-only **`Battery`** parameter (group `hardware`) polls `NVXGetVoltages` every 10 s while
running and reads e.g. `49% (6.10 V, 25.9 °C)`. The percentage is interpolated from the
open-circuit voltage table for a 6 V sealed lead-acid pack (`batteryPercent()` in
`nvx136logic.h`) and clamped to 0–100; it is an estimate, and it sags under load — measured
53% → 49% over the first minute of acquisition on a resting pack.

The field is **never blanked**: a poll that lands between Stop and the device closing, or one
the SDK refuses, is ignored rather than written, and the last reading survives Stop — taking a
fresh one would mean reopening the device at 3.3 s a go. It only reads empty before the first
successful poll.

**Polling it does not disturb acquisition** — 100 s at 25 kHz × 71 channels with the 10 s poll
running: 2,499,841 rows, **0 NaN, 0 gaps**, 25,005.41 Hz, worst block arrival gap 93.9 ms
against 113.5 ms on the ten-minute run that had no polling at all. Note the call runs on the
acquisition worker, so poll it slowly; do not put it near the read loop.

**Trap while doing this:** `QStringLiteral("%1 V, %2 °C")` rendered as `27.3 В°C`. This tree is
UTF-8 and MSVC without `/utf-8` reads narrow literals in the system codepage. Non-ASCII belongs
in a `QChar`, not in a source literal — `.arg(QChar(0x00B0))` round-trips correctly through the
description and reaches the Configurator as `°`. Adding `/utf-8` to the whole tree would be the
general fix; it has not been tried, and it would change how every existing literal is read.

<a id="history-14g-a-resonanceforeigndriver-consumer-would-not-attach-to-the-nvx136-stream"></a>

### 14g. A `ResonanceForeignDriver` consumer would not attach to the NVX136 stream

**UNKNOWN UNDER QT 6.** The Qt 6 `ResonanceForeignDriver` was reworked — it loads its exact
app-local DLL, keeps the DLL-directory handles alive, and its output path now validates and sends
contiguous `[samples, channels]` float64 — and its end-to-end test *did* attach and receive a 3×3
block (`R:\src\docs\qa\rfd-qt6-final.log`, 2026-08-28). But that was **`SignalGenerator`**, which
attached fine under Qt 5 too. The combination this entry is about, RFD against the **NVX136**
stream, needs hardware and has not been run under Qt 6. Treat it as live in both trees. The related
§15e *is* resolved — see there.

Repeatedly, and misleadingly: the service was `running`, its publisher was listening, and a
Python client built on `inputDataStream()` + `loadConfig()` never resolved the stream — by name
*or* by explicit `tcp-ip://`. `activeStream` stayed empty. The identical client attached to
`nvx` and `signalGenerator` without trouble, and `recorderService` recorded from the NVX136
stream every time.

So the driver was fine and the client was not. This produced several false "running but no
data" readings and cost most of a debugging session. **Check whether a driver streams with
`recorderService` or the Configurator, not with the ctypes bridge** — and treat an empty
`activeStream` on that path as an unexplained client failure rather than evidence about the
producer. Root cause in the bridge is not yet found.

<a id="history-14e---emulation-never-worked-on-either-nvx136-service---fixed-in-nvx136_2025"></a>

### 14e. `--emulation` never worked on either NVX136 service — ✅ fixed in nvx136_2025

`QCommandLineOption("emulation", …)` takes no value, so `parser->value(emulation)` is always
empty and `!isEmpty()` is always false. Now `parser->isSet(emulation)`, in `nvx136` as well
since the 2025 driver was merged into it.

<a id="history-14f-a-crashed-consumer-left-the-nvx136-service-unkillable"></a>

### 14f. A crashed consumer left the NVX136 service unkillable

A test client exited while acquisition was running. The service stopped answering discovery,
dropped to two threads, and then could not be terminated at all — `Stop-Process -Force` and
`taskkill /F /T` both failed, because the remaining thread is blocked inside a kernel-mode USB
driver call. Only a physical replug of the media converter releases it.

This is the same hazard as
STATUS.md's "always STOP an amplifier service before terminating it" ([change history](../changes/README.md)), reached from
the other direction. **Send `stop`, wait for `init`, then `!terminate`** — and make any script
that drives an amplifier stop it in a `finally` block.

---

