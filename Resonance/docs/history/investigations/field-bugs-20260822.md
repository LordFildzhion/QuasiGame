# Field bugs from the 2026-08-21 experiment — what was wrong, what changed, what to do — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../issues/README.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-field-bugs-from-the-2026-08-21-experiment--what-was-wrong-what-changed-what-to-do"></a>


**Written 2026-08-22, after the overnight block.** Covers items 1, 2, 3, 4, 5 and 7 of the field
list. Built, tested and deployed to `R:\dist\msvc64`. Backups of the previous binaries:
`R:\dist\msvc64\bin.pre-streamcontract-20260822-025541` (items 1, 5, 7) and
`R:\dist\msvc64\bin.pre-seek-20260822-041404` (item 4, and the last tree carrying both of the
item 3 / item 2 defects).

Screenshots of every proof below: `R:\dist\_build\stream-contract\` (items 1, 5, 7),
`R:\dist\_build\seek\` (item 4), `R:\dist\_build\param-ui2\` (items 3 and 2 as first measured) and
`R:\dist\_build\param-ui\` (items 3 and 2 re-proved by mouse on the shipped build, plus the
parameter-panel tidy-up).

**Parameter-panel changes deployed 2026-08-22 11:53**; rollback
`R:\dist\msvc64\bin.pre-paramui-20260822-115315`.

**Post-lab block deployed 2026-08-23** — items 11–15 below, from the 2026-08-22 TMS session
(`R:\tests\lab-session-20260822\REPORT.md`). Rollback
`R:\dist\msvc64\bin.pre-postlab-20260822-210213`. See the last section of this file.

---


<a id="history-at-a-glance"></a>

## At a glance

| # | Symptom | Cause | State |
|---|---|---|---|
| 1 | `--serviceConfig` loads 1 of 3 stream slots | `applyParameters` screened parameter names **once, before applying anything**, so slots created by `streamsCount` were rejected before they existed | **Fixed in code.** Reproducer now fills all three |
| 5 | SPEED epochs draw as a scrolling strip | `SPEED.exe` had no way to attach per-channel MetaData to a stream, so no SPEED stream has ever carried `window_start_ms` | **Fixed in code + a script change you must make.** Instructions below, verified end to end |
| 7 | `test_online_tepsound.hdf` will not replay as epochs | Nothing was lost. Every key is in the file. The first epoch is due **415.8 s** into the replay because `status` starts at 0 s and the replay clock starts at the earliest ticked stream | **Not a code bug — an operating recipe.** The playback window now shows each stream's start offset so it cannot happen unnoticed |
| 4 | No way to skip past a dead lead-in or a slow first half | Playback had no seek at all | **Built.** Click or drag the progress bar to jump to any time and carry on. This is the *other* answer to item 7 |
| 3 | Ghost checkmarks appear further down the channel list after scrolling | A Controls 1 `CheckBox` assigns its own `checked` on release, which destroys the binding on that delegate; the table then recycles that frozen delegate onto other channels | **Fixed, shipped and click-tested. The selection itself was never wrong** — measured, see below. Nothing was ever recorded from the wrong channels |
| 2 | "N parameters were rejected" after loading a file that was just saved | The Load check compared the file against the service's description 700 ms later and counted **any** difference as a rejection — including a value the service had written to itself in that window | **Fixed, shipped and click-tested.** Reproduced on demand, then made silent. A real refusal is now named, one line per parameter |
| 10 | tepSound cannot fire the TMS; manual operation of the same COM port can | `TriggerOut::writeSerial()` sent the command bytes and **no line terminator**, so the board — which executes a line only on `
`/`
` — never executed anything. Plus four more defects in the same path | **Fixed in code, byte-proved without a board, deployed. ⚠ Never yet tested against a real stimulator** — see the lab prompt |

Six items, **five unrelated causes**. Item 1 is a parameter-resolution failure. Item 5 is a
missing capability. Item 7 is neither — it is a replay-clock effect that was invisible because
nothing displayed it. Item 4 is the feature that makes item 7 survivable even when you do not
notice it in advance. Items 3 and 2 are both in the parameter panel and both were **display**
faults over a correct state — but they are not the same fault, and neither causes the other; that
was tested, not assumed. They were measured separately; none of them explains another.

---


<a id="history-item-1----serviceconfig-loaded-an-incomplete-parameter-set"></a>

## Item 1 — `--serviceConfig` loaded an incomplete parameter set

<a id="history-what-was-wrong"></a>

### What was wrong

`CommunicationLayer::applyParameters` split the parameter set into "mine" and "not mine" **once,
before applying a single entry**, and dropped the second half permanently. `stream2` and
`stream3` do not exist until `streamsCount` is applied — which happens later in the same file —
so they were rejected before they could ever be found. A manual load worked only because the
first load had already created the slots.

The refusal was a `qDebug()` line. Services are WIN32 binaries with no console attached, so
nothing reached you at all.

<a id="history-what-changed"></a>

### What changed

* The name check now runs **inside** the retry loop. A name the service does not have *yet* is
  retried; it is reported as unknown only after a whole round has gone by without it appearing.
  This fixes every service with the same shape — `recorderService` (`streamsCount`), `SPEED`
  (`inputsCount`), `stimulusService`'s device slots.
* Every entry that does not apply is now **named, with a reason**: `no-such-parameter`,
  `value-rejected`, `malformed-entry`, `reverted`, plus the value that was asked for.
* On `--serviceConfig`, a partial apply **opens a debug console by itself** and prints the list.
  A clean load still opens nothing, so a normal run looks exactly as it did.
* Two cases that used to be completely silent now fail loudly: a config file whose root is not a
  JSON array (used to apply nothing and report success), and a missing or unreadable file (used
  to be reported as a JSON parse error at line 1).
* A stream slot's attributes now carry `requested` / `resolved` / `waitingFor`, so a slot that is
  configured but waiting for its producer is distinguishable from a slot nobody ever set.

<a id="history-proof"></a>

### Proof

`R:\dist\msvc64\recorderService_testConfig.bat`, run on the deployed tree:

* `00-item1-recorder-ui-BEFORE-old-build.png` — the old binary. Stream 1 filled, **Stream 2 and
  Stream 3 grey and empty** (`discover:///?stream=NA…`). This is what you reported.
* `07-deployed-testconfig-bat.png` — the deployed new binary, same `.bat`, same JSON. **All three
  slots filled**: `…=eeg&name=NVX136`, `…muli&name=TEP_visual`, `…tim&name=TEP_visual`.
* `01-item1-refusals-console.png` — a config deliberately containing four unapplicable entries.
  A console opens by itself and reads:

  ```
  Configuration file "...\recorder_settings_badparams.json" was only PARTLY applied
      -- 4 of 15 parameters were NOT applied: <entry 14>, samplingRateOverride,
         streamsCount, compression
     <entry 14> NOT APPLIED - not a parameter object, or it carries no name ("flushSeconds = 10")
     samplingRateOverride NOT APPLIED - this service has no parameter by that name (asked for 512)
     streamsCount NOT APPLIED - the parameter refused the value 999 (wrong type, out of range, ...)
     compression NOT APPLIED - the parameter refused the value "maximum, please" (...)
     the service is running with those parameters at their defaults, NOT at the values in the file
  ```

<a id="history-what-you-must-do-differently"></a>

### What you must do differently

Nothing. Load configurations as before. **If a console window appears when a service starts, read
it** — it is the list of parameters that did not take, and the service is running with those at
their defaults.

<a id="history-still-open"></a>

### Still open

~~The Configurator's own "Load" gets the same report but no client displays it yet.~~ **Closed
with item 2, below.** The Configurator now shows the same list under its Load button, one line
per refusal.

---


<a id="history-item-7--replaying-test_online_tepsoundhdf-as-epochs"></a>

## Item 7 — replaying `test_online_tepsound.hdf` as epochs

<a id="history-what-was-wrong-nothing-in-the-file-or-in-the-code"></a>

### What was wrong: nothing, in the file or in the code

The recording is intact. `epochs`, `clean` and `average` all carry the full per-channel epoch
declaration — `window_start_ms` (−200 for the 64 EEG channels, −400 for MEP), `window_end_ms`
(+501 / +301), `epoch_kind`, `epoch_stage`, `epoch_stamp`, `unit`, and the electrode names. The
length invariant holds exactly on every channel: 701 samples at 1000 Hz.

The problem is the **replay clock**. It starts at the earliest first block among the streams you
ticked, and after a scan **every stream is ticked**. In this file the streams do not start
together:

| stream | starts at | runs for | blocks |
|---|---|---|---|
| `status` | **+0.0 s** | 757.5 s | 1515 |
| `events` | +405.7 s | 342.8 s | 186 |
| **`epochs`** | **+415.8 s** | 289.1 s | 152 |
| `clean` | +429.8 s | 275.1 s | 142 |
| `average` | +430.7 s | 275.1 s | 150 |

With `status` ticked, the first epoch is due **6 min 56 s** into the replay — the "long empty wait
in the first half". Measured: 240 blocks in the first 120 s, all of them `status` at 2 Hz, and the
epoch panel reading `waiting for the first epoch` the whole time.

The viewer was never at fault. It said `waiting for the first epoch`, with the shape it had
accepted, for the whole dead period.

<a id="history-what-changed-1"></a>

### What changed

The playback window's stream list used to print `106.6 s` for `epochs` — that is *sample count ÷
rate*, a number about something else entirely. It now prints where the stream sits on the session
timeline:

```
epochs   Float64  65 ch @ 1000 Hz  152 blocks  106552 samples  starts at +415.8 s, runs 289.1 s
status   Float64  40 ch @ 2 Hz    1515 blocks    1515 samples  starts at +0.0 s,   runs 757.5 s
```

and `prepare` logs a warning naming any ticked stream that will not begin for more than two
seconds. ⚠ That warning is a log line, not an on-screen one — **the start offsets in the stream
list are the surface you should read.**

<a id="history-the-recipe--do-this-to-replay-any-recorded-session-as-epochs"></a>

### The recipe — do this to replay any recorded session as epochs

1. Open the file in `playbackService`.
2. On the stream list, **untick `status` and `events`.** Leave `epochs` (and `clean` / `average`
   if you want them). This alone moves the first epoch from +415.8 s to +0.0 s.
3. Leave **Scale declared rate OFF** (the default). At any other setting every RTC-to-sample
   conversion is off by the speed factor.
4. `Prepare`, point a plot at `discover:///?stream=epochs&name=<the service name shown>`, `Start`.
5. Read the start offsets in the stream list before you press anything. **The stream you care
   about must start at or near +0.0 s once the others are unticked.**

⭐ **There are now two ways out of this wait, and you can use either.** Unticking `status` moves
the replay's zero, so the recording *starts* at the first epoch. **Seeking** (item 4, below)
leaves every stream ticked and jumps the replay to wherever you click. Untick when you want the
whole epoched part from its own beginning; seek when you want to keep `status` and `events` in
the replay, or when you only notice the dead lead-in after pressing Play.

<a id="history-proof-1"></a>

### Proof

* `05-item7-playback-contents-leadin.png` — the playback window with the new start offsets and
  only `epochs` ticked. Transport at 01:38.8 / 04:49.1, 58 blocks, late 1.7 ms mean.
* `06-item7-real-file-epochs-average.png` — the real recording, replayed at **speed 1**, drawn as
  epochs: butterfly average over **129 epochs**, latency axis −200 … +501 ms, the t=0 marker at
  the stimulus, a flat pre-stimulus baseline, the artefact complex at 0–20 ms, a clear positivity
  at +25…50 ms and the N100 trough at +100…150 ms. Caption:
  `producer-cut · average, n = 129 mean · 65 ch · 1000 Hz · 701 samples · -200 .. +501 ms ·
  channels declare different windows · trial/preprocessed/t0=trigger`.
  The full run delivered **152 of 152 blocks with 0 underruns**.

`channels declare different windows` is correct and not a warning: the MEP channel really is
−400…+301 while the 64 EEG channels are −200…+501.

The recording was opened read-only throughout and is byte-for-byte unchanged
(163,520,592 bytes, 2026-08-22 00:48:51).

---


<a id="history-item-4--seek-in-playback"></a>

## Item 4 — seek in playback

> *"Playback — some files are too long or have a dead half due to operator slowness. I would like
> to be able to 'scroll' to any time in the file by pressing on progress bar area in playback gui
> and go to that time and then proceed with playback."*

<a id="history-how-to-use-it"></a>

### How to use it

**Click anywhere on the progress bar. Playback jumps to that time and carries on.** Press and
drag to scrub: while the mouse is down the bar and the time readout follow your finger, and the
jump happens once, when you let go.

* Works while **playing**, while **paused** and while **armed** (after Prepare, before Play). In
  `armed` and `paused` the position is simply held — press Play or Resume and it starts there.
* Disabled while **idle** and while **preparing**: there is nothing to move yet. The bar still
  shows the file's length as soon as it has been scanned, so you can read `12:37.5` before you
  press anything.
* The readout is **recording time** — where you are in the file — at every speed. Not wall time.
* Backwards is the same as forwards. Dragging to the far right lands one block short of the end,
  plays it, and then the recording finishes normally.
* One line appears under the bar for eight seconds: `Seeked to 06:55.2. Reset any filtering
  consumer.` It names where the seek actually landed.

⚠ **"Reset any filtering consumer" is not decoration.** A seek is a discontinuity in every
consumer's input.

* The **viewer's epoch cutter needs nothing from you.** It sees the jump as a gap, refuses the
  epochs whose window straddles it, and is back to normal within one epoch window. Playback
  deliberately does not tell it anything: it is still assembling epochs, and a reset would throw
  them away.
* An **IIR filter does not recover on its own.** `tepService` / `tepSoundService` carry filter
  state across blocks, and a step in the input rings — measured in this project at 1758 µV
  decaying over ten epochs. If you seek during a run whose numbers matter, press **Reset session**
  on that service afterwards. Playback will not press it for you, because Reset session also
  discards every epoch collected so far and doing that silently because someone clicked a
  scrollbar would be worse than the transient.
* A service that wants to react on its own can subscribe to playback's `status` stream: a seek
  publishes `{"event":"seek", "positionNs": …}` immediately.

<a id="history-proof--the-operators-own-file-the-configuration-that-failed"></a>

### Proof — the operator's own file, the configuration that failed

`test_online_tepsound.hdf`, **all five streams ticked** — the exact setup that produced the
6 min 56 s dead wait in item 7. Play, wait 12 s (`EPOCHS: 0 blocks`), then one click at 54.8 % of
the bar:

| | |
|---|---|
| seek target | **415.208 s** of recording time |
| bar and readout update | **≤ 1 ms** after the mouse release (`00:11.3` → `06:55.4`) |
| **first epoch at a real consumer** | **851 ms** after the mouse release |
| the same wait without seeking | **415.8 s** |

Three independent runs: 851 ms, 855 ms, 846 ms. The last of those is from the **deployed** tree in
`R:\dist\msvc64`.

**They are the right epochs, not an approximation.** The seek lands on the first block in file
order whose `created` is at or after the target — here block 0 of `epochs`, whose stamp is
`+415.803 s`, i.e. 0.595 s past the target. Checked against the file over the whole 46 s that
followed: **213 of 213 status samples** agree with the block schedule the file itself carries. A
cursor one block out would have disagreed with **169 of 213**. The `epochs` index in this file is
not sorted — six pairs are stamped out of order, worst case 112 ms — and the replay reproduces
those inversions exactly as recorded (two epochs arriving 2 ms apart with the later stamp first).

Backwards, and while playing: seeks to 75.7 s, 226.6 s, 454.5 s, 545.8 s, 605.6 s all landed and
the run continued. `underruns = 0` throughout.

⚠ **No consumer was ever disconnected.** `TcpStreamSender: Ready` — the line a stream prints when
it starts listening on a fresh port — appeared **9 times at startup and Prepare and 0 times
across every seek**. That is the whole point of doing this as a control line rather than a
stop-and-restart: a republish would move every port and drop every viewer.

<a id="history-proof--it-does-not-care-how-big-the-file-is"></a>

### Proof — it does not care how big the file is

`12_52MSO_TMS_BCI.hdf5`, 4.08 GB, 75 channels at 25 kHz, five seeks in a row
(80 % → 20 % → 95 % → 5 % → 55 %):

| | |
|---|---|
| controller publishes the new position | **0–1 ms** after the mouse release |
| first block at the new position, at a consumer | **278–396 ms** in 4 of 5 seeks (250 ms of that is the fixed lead-in every play has) |
| worst block lateness across the whole run | **1.5 ms** |
| underruns | **0** |

A seek needs no scan of the file: the block index is read once when the file is opened (64 KB for
this recording) and every block is already a random-access read. The one slow seek (1.4 s) was the
consumer falling behind — 75 channels at 25 kHz through a plotting widget — not the player, which
never exceeded 1.5 ms of lateness.

<a id="history-proof--exact-at-speed--1"></a>

### Proof — exact at speed ≠ 1

This is where an implementation that worked in elapsed wall-clock time would quietly land in the
wrong place, because **Scale declared rate is off by default**. Same click (54.8 %), speed 1 and
speed 4:

| | speed 1 | speed 4 |
|---|---|---|
| seek target, recording time | 415.207793 s | **415.207858 s** |
| first epoch | 415.813 s | **415.812 s** |
| next four epochs | 417.269 / 418.633 / 419.946 / 421.293 s | **417.276 / 418.640 / 419.944 / 421.300 s** |
| wall-clock delay to the first epoch | 855 ms | **401 ms** — exactly a quarter of the recording-time gap, plus the same lead-in |

The two targets differ by **65 nanoseconds**, which is clock quantisation. The seek is expressed
in recording time from end to end; speed enters the arithmetic in exactly one place.

<a id="history-also-fixed-while-in-the-file"></a>

### Also fixed while in the file

* **The mojibake em dash.** `playbackService` was compiled without `/utf-8`, so
  `test_online_tepsound.hdf вЂ" 5 of 5 streams can be played back`. There were **four** such
  strings, not one — the other three are the parameter labels `— play`, `— publish as`,
  `— from service`, which mojibake three times per stream in the Configurator as well. All four
  are now ASCII dashes, and both targets compile with `/utf-8` so the next one typed cannot
  regress.
* **The progress bar and the stream list now count from the same zero.** The list quoted
  `starts at +415.8 s` against the earliest *playable* stream while the bar counted from the
  earliest *ticked* one. Untick `status` and those are different origins: the row still said
  +415.8 s for epochs that were now at +10.1 s on the bar, so seeking to what the list said would
  land you 6.8 minutes past the data.
* **A slow seek on a freshly-booted machine no longer floods the consumers.** The replay anchor is
  the clock reading that the recording's origin maps to, and `RTC::now()` on Windows counts from
  boot. Seeking to 415.8 s at speed 0.05 asks for 8316 s of a clock that may only have 4200 s in
  it — the origin lands before the machine started. That was clamped to zero, which made every
  remaining block overdue and dumped the rest of the recording at burst rate; the anchor is now
  signed, so the case does not arise. At speed 1 it needed only that you seek past 6:56 within
  6:56 of booting.

<a id="history-known-and-left-alone"></a>

### Known and left alone

* The `Seeked to …` line rounds to a tenth of a second and names the landing point, but the bar's
  own readout can sit up to one lead-in (250 ms of wall time, so 1 s of recording time at speed 4)
  behind it for the moment between the click and playback reaching the target. That is honest —
  the replay really is a lead-in short of the target for that instant.
* Clicking the very last pixel of the bar plays the final block and then ends the session, which
  returns the window to `Stopped`. That is what asking to go to the end means; the clamp exists so
  that a pixel past the end still plays something instead of tearing the workers down with nothing
  emitted.
* There is no keyboard seek and no "type a time" box.

---


<a id="history-item-5--speed-epochs-shown-as-a-concatenated-strip"></a>

## Item 5 — SPEED epochs shown as a concatenated strip

<a id="history-what-was-wrong-1"></a>

### What was wrong

An epoch stream declares itself through **per-channel MetaData** announced with the stream. The
presence of `window_start_ms` *is* the statement "this stream is epoched"; without it the viewer
treats the stream as continuous, which is the scrolling strip you saw.

`SPEED.exe` had **no way to attach MetaData to a stream at all** — the script-engine interface had
no parameter for it and `SPEED` passed an empty MetaData every time. No SPEED stream, from any
script, has ever carried an epoch declaration. There was no line in the colleague's script to fix.

<a id="history-what-changed-2"></a>

### What changed

* The script-engine interface gained `declareStreamWithMetaData` (appended to the end of the
  struct, guarded by `structSize`; the old entry point is untouched).
* `SPEED.exe` implements it, and **validates** what it is given: a per-channel list whose length
  does not match the channel count is dropped and named in the service's *Error messages* box,
  because a list of the wrong length is treated as an absent key by every consumer — a
  half-declaration is worse than none.
* `pythonEngine.dll` reads a `channel_properties` dict off the output SI object and passes it
  through. If the JSON cannot be built, or if an old `SPEED.exe` is sitting next to a new engine,
  it says so in *Error messages* instead of dropping it.

**No change to the `resonance` Python package is needed.** The script attaches the dictionary to
the SI object itself.

⚠ `SPEED.exe` and `bin\engines\*.dll` must be deployed **together**. They were, tonight.

<a id="history-proof-2"></a>

### Proof

* `04-item5-WAS-no-metadata-strip.png` — a script that publishes 701-sample epochs with no
  `channel_properties`. Mode reads **`Auto · sweep`**, x-axis in **seconds** (0.0 … 3.0 s), the
  epochs visibly concatenated end to end. Exactly your symptom.
* `03-item5-speed-epochs-viewer.png` — the **same script** with the six-key dictionary added.
  Mode reads **`Auto · epoch`**, x-axis in **milliseconds** (−200 … +501), t=0 marker at the
  stimulus, each channel showing its response. Caption:
  `producer-cut · epoch #6302 · 8 ch · 1000 Hz · 701 samples · -200 .. +501 ms ·
  trial/preprocessed/t0=none`. 998 epochs received, **0 rejected**.
* `08-item5-wrong-rate-warning.png` — the same again with the declared sampling rate left at the
  input rate. The viewer accepts it and **says it is wrong**: axis −200 … −172 ms, and
  `⚠ declared window disagrees with the delivered length`. This is why point 2 below is not
  optional.

Both runs were made with the **deployed** `R:\dist\msvc64\bin\SPEED.exe` and
`bin\engines\pythonEngine.dll`.

---

<a id="history--for-the-colleague--speed-epoch-output-was--supposed-to-be"></a>

# ▶ FOR THE COLLEAGUE — SPEED epoch output: WAS → SUPPOSED TO BE

*Everything below stands on its own and can be forwarded verbatim.*


<a id="history-1-what-makes-a-stream-epoched"></a>

## 1. What makes a stream "epoched"

A Resonance data block carries only `(created, received, samples, data)`. There is **no epoch t0,
no time vector and no offset on the wire**. The entire epoch declaration travels in the stream's
**per-channel MetaData**, announced once when the stream is created.

⭐ **The presence of `window_start_ms` IS the declaration "this stream is epoched."** Nothing else
is consulted — not the stream's name, not the block length, not the cadence. Without it the
viewer draws a continuous scrolling strip.

| key | type | required | meaning |
|---|---|---|---|
| `window_start_ms` | number | **yes** | where the window opens relative to the stimulus. **Negative** for a pre-stimulus window. `0` is legal. |
| `window_end_ms` | number | yes | the **exclusive** right edge |
| `epoch_kind` | string | yes | `"trial"` or `"average"` |
| `epoch_stamp` | string | yes | what the block's timestamp means: `"trigger"` / `"first"` / `"last"` / `"none"` |
| `epoch_stage` | string | optional | `"raw"` / `"preprocessed"` / `"cleaned"` |
| `unit` | string | yes | ASCII only: `V` `mV` `uV` `Ohm` `bitfield` `""`. **`µV` with a real µ is rejected — write `uV`.** |

⚠ **Every list must be exactly `channels` long** — one value per channel, never one value for the
stream. A list of the wrong length is treated **exactly like the key being absent**. SPEED will
now drop such a list and name it in its *Error messages* box rather than shipping it.

⚠ **The length invariant**, checked to 1e-6 samples:

```
(window_end_ms - window_start_ms) / 1000 * samplingRate  ==  samples per block
```

`samplingRate` is the rate of the samples you actually send — **after** any resampling.


<a id="history-2-was--supposed-to-be"></a>

## 2. WAS → SUPPOSED TO BE

Script: `R:\dist\msvc64\mulines\src\mulines\feetStim_TEPs_plot.py`, function
`pipeline_tep_feetStim`, at the end (currently lines 183–188).

| # | WAS | SUPPOSED TO BE |
|---|---|---|
| 1 | the `epochs` stream is announced with **empty MetaData** | announced with the six per-channel lists, each `channels` long |
| 2 | `samplingRate` is the **input** rate — 25 000 Hz — because `transform_window_to_channels` copies `input.SI.samplingRate`, while the data has been resampled to `params["Fs"]` | `samplingRate` = `params["Fs"]`, the rate of the samples actually sent. **Without this the ruler is wrong by the decimation factor and the viewer reports `declared window disagrees with the delivered length`.** |
| 3 | no `window_start_ms` | `[float(params["window_start"])] * n` |
| 4 | no `window_end_ms` | `[float(params["window_end"])] * n` |
| 5 | no `epoch_kind` | `["trial"] * n` |
| 6 | no `epoch_stamp` | `["none"] * n` — **not `"trigger"`**: the engine stamps every outgoing block with the queue-flush instant, so the timestamp has no relation to the stimulus |
| 7 | no `unit` | `["uV"] * n` — plain ASCII `u`, never `µ` |
| 8 | two streams, `epochs` and `epochs_output` | declare both, or settle on one name. `epochs_output` is not recognised as an epoch-shaped name by the contract checker, so a missing declaration on it passes unnoticed |


<a id="history-3-the-change"></a>

## 3. The change

Insert this immediately before the two `createOutput` calls, and delete nothing else:

```python
    n = n_ch - 1
    Fs_out = params["Fs"] if params["resampling"] else params["Fs_orig"]

    def declare_epochs(node, stage):
        # (2) the rate of the samples actually sent, not the input rate
        node.SI._samplingRate = Fs_out
        # (1, 3-7) the epoch declaration -- one value PER CHANNEL
        node.SI.channel_properties = {
            "window_start_ms": [float(params["window_start"])] * n,
            "window_end_ms":   [float(params["window_end"])]   * n,
            "epoch_kind":      ["trial"] * n,
            "epoch_stamp":     ["none"]  * n,
            "epoch_stage":     [stage]   * n,
            "unit":            ["uV"]    * n,
        }

    declare_epochs(epochs, "preprocessed")
    declare_epochs(epochs_output, "cleaned")

    resonance.createOutput(epochs_output, "epochs_output")
    resonance.createOutput(epochs, "epochs")
```

That is the whole change. Nothing in the `resonance` package needs editing or reinstalling.

⚠ `node.SI._samplingRate = Fs_out` writes a private attribute deliberately: the same SI object is
held by the processor and by the execution plan, so it has to be repaired in place rather than
replaced. Verified working on the deployed binaries.


<a id="history-4-worked-example--your-current-settings"></a>

## 4. Worked example — your current settings

`R:\dist_legacy\dist2025\mulines\resources\SPEED_settings.json` is
`window_start = -500`, `window_end = 500`, `Fs_orig = 25000`, `Fs = 5000`:

```
n              = n_ch - 1                          = 72   (73 channels, minus the trigger)
length @25 kHz = int((500 - (-500)) * 25000/1000)  = 25000 samples
after resample = 25000 * 5000/25000                =  5000 samples
declared rate  = 5000                                       <-- NOT 25000

invariant:  (500 - (-500)) / 1000 * 5000 = 5000  ==  5000   OK
```

With the rate left at 25 000 the same arithmetic wants 25 000 samples against 5 000 delivered —
off by exactly the decimation factor, which is what the viewer complains about.

For the window in the script's docstring (`-300 … +500`, `Fs = 1000`):

```
length @25 kHz = int(800 * 25) = 20000  ->  after resample = 800 samples
declared rate  = 1000
invariant:  (500 - (-300)) / 1000 * 1000 = 800  ==  800     OK
```


<a id="history-5-before-you-can-run-it--two-things-are-missing-from-rdistmsvc64"></a>

## 5. Before you can run it — two things are missing from `R:\dist\msvc64`

Neither is a bug in the fix; they are gaps in that distro directory.

1. **There is no Python in it.** `env.bat` sets `PYTHONHOME=%CD%\python` and that directory does
   not exist, so `SPEED.exe` cannot load `engines\pythonEngine.dll` (it needs `python312.dll`).
   ```
   robocopy "R:\dist_legacy\dist2025\python" "R:\dist\msvc64\python" /E
   ```
   (474 MB. Nothing is overwritten.)
2. **`mulines\resources\SPEED_settings.json` is not there either**, although
   `params\speed_feetStim.json` points at it.
   ```
   robocopy "R:\dist_legacy\dist2025\mulines\resources" "R:\dist\msvc64\mulines\resources" /E
   ```

⚠ **Do not run the fixed script against `R:\dist_legacy\dist2025\bin\SPEED.exe`.** That is the old
binary, which cannot carry MetaData at all. Use `R:\dist\msvc64\bin\SPEED.exe` with
`bin\engines\pythonEngine.dll` from the same directory.


<a id="history-6-acceptance-test"></a>

## 6. Acceptance test

```powershell
cd R:\config
.\epoch_contract_check.ps1 -NoGenerator -Collect 10000 -Verbose
```

It connects to every discovered stream and asserts the six keys, the list lengths against the
connected stream's own channel count, the length invariant against a block that actually arrived,
the legal enum values, and `unit` byte for byte. Exit code **0** iff it prints
`VERDICT epochContractHolds=true`.

⚠ It runs the freshly built tree `R:\dist\_build\msvc64\runtime`, not `R:\dist\msvc64`.

**Useful before you change anything:** with SPEED running today the harness already prints
`warn: undeclared epoch-shaped name SPEED/epochs -- no window_start_ms`. That one line is the
whole bug.


<a id="history-7-two-alternatives-that-need-no-script-change-at-all"></a>

## 7. Two alternatives that need no script change at all

* **Let the viewer cut the epochs.** SPEED already publishes `interp_signal` — all 73 channels
  including the trigger, at 25 kHz, artefact already interpolated. Point a plot at it, turn on
  epoch cut, pick the trigger lane (last channel, bit = `params["bit"]`, rising edge), pre 300 ms
  / post 500 ms. The viewer computes t0 itself, so the ruler is right in real milliseconds.
* **Use `tepService` instead.** It is a general-purpose epoch cutter that already emits the full
  declaration, and it is close to a superset of this script: trigger channel/bit/edge/refractory,
  window and output rate, artefact interpolation, high-pass / notch / low-pass, epoch low-pass,
  baseline, CAR with exclusions, re-reference, averaging. Point it at `SPEED/interp_signal` or
  straight at the NVX.

---


<a id="history-item-3--ghost-checkmarks-in-the-channel-list"></a>

## Item 3 — ghost checkmarks in the channel list

<a id="history--the-selection-was-never-wrong"></a>

### ⭐ The selection was never wrong

The first thing measured, before anything was changed: with ghosts on screen, read the parameter
back off the EventBus and compare it, row by row, against what the delegate is actually drawing.

On the build you ran in the lab (`bin.pre-seek-20260822-041404`), 137 channels, ticking Ch 1 and
Ch 3 and then scrolling down:

    row=54  drawn=true  model=false  service=false
    row=60  drawn=true  model=false  service=false

**Drawn true, model false, service false.** The tick was in the pixels only. The channel list the
service held — and therefore the channel list every recording used — was correct throughout.
83 of 98 checked steps disagreed on the pixels; **not one** disagreed on the value. No recording
made through this UI selected the wrong channels.

That is also why re-opening the service cleared the ghosts: reloading rebuilt the delegates, and
the value they were rebuilt from had been right all along.

<a id="history-what-was-wrong-2"></a>

### What was wrong

The tick column was `CheckBox { checked: styleData.value }`. A Controls 1 `CheckBox` **assigns**
its own `checked` on release, and an assignment destroys the binding on that instance for good.
Qt's `BasicTableView.qml` pools and reuses row items while scrolling — its own comment is "We
recycle instantiated row items to speed up list scrolling" — and on reuse it rebinds `rowIndex`,
`itemModel` and `itemModelData`, but not a column delegate's now-dead `checked`.

So after N clicks exactly N delegates were frozen, and each drew its frozen tick against whatever
channel it was next recycled onto. Two clicks, two ghosts — which is exactly what you saw.

<a id="history-what-changed-3"></a>

### What changed

`Resonance__Parameters__ChannelsList.qml`. The tick is now read from the parameter by every
delegate, indexed by its own `styleData.row`; both are properties the view re-binds on reuse. The
`CheckBox` is display only — a `MouseArea` covers it, so the control's own release handler never
runs and cannot destroy the binding. Clicking asks the parameter to change and redraws from it.

<a id="history-proof-3"></a>

### Proof

| what | measured |
|---|---|
| Old delegate, same harness, same service | **83 of 98 steps show ghosts**, verdict FAIL |
| New delegate, deployed build | **0 of 98 steps**, 3625 delegate checks, 137 distinct rows, verdict PASS |
| Exercised | scroll down and back, resize narrow/short/restore, a full model reset via a channel-count change, tick and untick in the middle of the list |
| Real mouse, deployed build | ticked Ch 1 and Ch 3, scrolled through Ch 46-56 and Ch 91-101 — no ghost. Read back at that moment: `selected=["1:Ch 1","3:Ch 3"]` |

Screenshots: `z_p04_ticked_ch1_ch3.png`, `z_p05_scroll_2.png`, `z_p05_scroll_4.png`.

<a id="history-re-proved-by-real-mouse-on-the-shipped-build"></a>

#### Re-proved by real mouse on the shipped build

Repeated end to end after the parameter-panel changes, driving the real Configurator with real
wheel and real clicks, and reading the drawn ticks back out of the captured pixels at every step:

| what | measured |
|---|---|
| Ticked at the top, swept the whole list | Ch 1 + Ch 3 ticked, then **52 wheel steps** down to `Trigger` (the last of 137 rows) and back. Ticks drawn **only** at rows 0 and 2, and only while the top of the list is in view. Zero ghosts. |
| Ticked deep in the list, where recycled delegates live | Ch 47, Ch 50, Ch 54 ticked by mouse at scroll offset ~46 — **the same band the pre-fix build first ghosted in, row 54** — then **52 more wheel steps** both ways. On the way back the three ticks reappear at rows 3, 6 and 10: gaps of 3 and 4, exactly matching 47/50/54. |
| Model, read from a separate process while those ticks were on screen | `selectedCount=5`, `selected=["1:Ch 1","3:Ch 3","47:Ch 47","50:Ch 50","54:Ch 54"]` — exactly the five clicked, no more, no fewer |
| Resize, the other recycling route | shrunk to 820x640 and restored with the ticked band on screen: ticks still on Ch 47, Ch 50, Ch 54 (`param-ui\f02_band_after_resize.png`) |
| Instrumented harness, rebuilt code | 98 steps, **3625 delegate checks, 137 distinct rows, 0 failures** |
| Repeated against the **deployed** tree after deploying | 44 more wheel steps, ticks only at rows 0 and 2, model `["1:Ch 1","3:Ch 3"]` |

Screenshots: `param-ui\a04_list_ticked_1_3.png`, `c02_mid_ticked.png`, `f02_band_after_resize.png`,
`b_bottom_zoom.png`.

<a id="history-what-you-must-do-differently-1"></a>

### What you must do differently

Nothing. Past recordings do not need re-checking.

---


<a id="history-item-2--n-parameters-were-rejected-after-loading-a-file-you-just-saved"></a>

## Item 2 — "N parameters were rejected" after loading a file you just saved

<a id="history-what-was-wrong-3"></a>

### What was wrong

`Load` sent the file, waited 700 ms, then compared the file against the service's description and
counted **every** difference as a rejection. That is not a rejection test. A service is free to
write its own parameters, and nvx136 does: `battery` is refreshed on a 10 s poll while running
(`nvx136config.cpp:209`). If a poll lands inside that 700 ms window, one parameter reads back
different from the file and the banner claims it was rejected — while everything, including the
channel selection, applied correctly.

That is why it could not be reproduced on demand: it needs a poll to land in a 0.7 s window, so it
fires on roughly one load in fifteen, and never at the bench where the amplifier is not running.

<a id="history-reproduced-then-made-silent"></a>

### Reproduced, then made silent

Driven against nvx136 on the deployed build, the old check running in a control harness beside it:

| sequence | old check | new check |
|---|---|---|
| save → load, nothing changed | silent | silent |
| save → **change the number of ticked channels** → load | silent | silent |
| the same, repeated, and sampled at 100/300/700/1500/3000 ms | silent at every delay | silent |
| load, with the service writing `battery` 200 ms into the window | **"1 parameters were rejected — they do not fit this service"** | silent — correctly |
| load a file with a genuinely bad value | "1 parameters were rejected" — no name, no reason | names the parameter, the value and the reason |

⚠ Worth being precise about, because it changes what to look for: **the channel selection itself
never triggered it.** Changing the number of checkmarks and reloading is silent on both the old
and the new check, at every delay tested. The warning you saw was about some other parameter —
on that rig, almost certainly `battery`.

<a id="history-what-changed-4"></a>

### What changed

`ParametersView.qml`. The comparison is gone. The service now reports what it refused and why, in
its own description (`parameterRefusals`, filled by `parameterapply.cpp`), and the panel displays
that list verbatim under the Load button — one line per refusal, naming the parameter, the value
and the reason. Against a service too old to report refusals, only unknown **names** are checked,
and the banner says so rather than letting an empty list read as a clean load. A file that cannot
be parsed now says so too; it used to load silently and do nothing.

The banner no longer erases itself after eight seconds. It clears on the next Load, or on a click.

<a id="history-proof-4"></a>

### Proof

Real mouse, deployed build, your exact sequence — save, tick three more channels, load the saved
file: the selection returns to Ch 1 and Ch 3 and **no banner appears**
(`p14_after_change.png` → `p20_after_load_6s.png`).

A file with four genuine faults in it produces:

    Load: 4 parameters were not applied
    mode NOT APPLIED - the parameter refused the value "Bogus" (wrong type, out of range, ...)
    adc_synchronization_frequency NOT APPLIED - the parameter refused the value 99 (...)
    channels NOT APPLIED - the parameter refused the value [true,false,true] (...)
    no_such_knob NOT APPLIED - this service has no parameter by that name (asked for 123)

(`z_p22_banner.png`, still on screen 15 s later.)

<a id="history-re-proved-on-the-shipped-build"></a>

#### Re-proved on the shipped build

Driven again after the parameter-panel changes, with the file saved through the dialog rather than
written by hand:

* Saved nvx136's parameters from the panel — the file carries `channels` = `[1,3,47,50,54]`,
  matching the five ticks that were on screen.
* Ticked three more (Ch 2, Ch 4, Ch 5 — eight in total, a different **number** of checkmarks, which
  is the condition you described), then loaded the file back.
* **No banner, at 0.4 s, 0.9 s, 1.6 s, 3 s or 6 s.** The selection returned to exactly
  `["1:Ch 1","3:Ch 3","47:Ch 47","50:Ch 50","54:Ch 54"]`, read back from a separate process.
  Screenshots `param-ui\j01_changed_8ticks.png` → `param-ui\m_load_t3000.png`.
* A file with five deliberate faults — an impossible sampling rate, a negative block size, a mode
  that does not exist, a non-numeric gain, and a parameter this service has never heard of —
  produced a banner naming **all five with reasons**, within 2 s, still on screen at 15 s, and
  cleared by a click. The legal parameters in that same file applied; the five refused ones kept
  their old values (`Sampling rate` stayed 250 Hz, `Block size` 25, `Mode` Normal).
  Screenshot `param-ui\n02_bad_load_6s.png`.

So both halves hold: a silent load means everything went in, and a real refusal is named on screen.

<a id="history-what-you-must-do-differently-2"></a>

### What you must do differently

Trust the banner now. If it is silent the whole file went in; if it is not, it names every part
that did not and why.

---


<a id="history-also-settled-in-the-same-pass"></a>

## Also settled in the same pass

* **The Configurator no longer dies on tepSound's parameters.** The `TwoWayBinding.js` guard used
  `Object.keys(o).indexOf(prop)` as a truth test, which returns -1 (truthy) when the property is
  **absent** and 0 (falsy) when it is the **first** key — so it blocked legal captures and passed
  illegal ones. It threw 46 times per tepSound panel and killed the window in about two
  interactions. Measured on the deployed build: 12 tab clicks, then 6 rounds of switching between
  NVX136 and TepSound with edits in between — **0 errors, window alive**. Re-measured on the
  shipped build, harder: all **13** tepSound groups clicked in turn, then **8** rounds of
  NVX136 ↔ TepSound switching with four group changes and two channel toggles in each — roughly
  **64 interactions, window alive, 0 `TwoWayBinding` errors, 0 `TypeError`, 0 binding loops**
  in the whole session log.
* **A stream that fails the epoch test now says so.** The viewer's mode button reads
  `Auto · sweep`, and its tooltip states that a declaration was looked for, was not found, and
  which of the five exits the test took (`StreamView.qml:251`, `:331`, `:674`).
* **`parameterRefusals` is displayed.** Written by `parameterapply.cpp`, published in
  `communicationlayer.cpp:228`, exposed as `ServiceControl::parameterRefusals` /
  `parameterRefusalsSupported` (`servicecontrol.hpp:44`, `:52`), read by
  `ParametersView.qml:454`. The item-1 gap is closed.

<a id="history-the-three-loose-ends-in-the-parameter-panel--now-built-deployed-and-driven"></a>

### The three loose ends in the parameter panel — now built, deployed and driven

These landed after the build the rest of this note was measured on. They have since been built,
click-tested and deployed. Two hold; the third was a wrong guess and was rolled back.

* **`Binding loop detected for property "implicitWidth"` — cut. CONFIRMED.** Same harness, same
  service, before and after: **1 binding-loop warning → 0**, and 0 across a whole driven
  Configurator session. A tab's content item measured
  itself from `sv.viewport.width`, and the viewport is what is left of the ScrollView after the
  scroll bars that the content's own width and height ask for. It now measures from `sv.width`,
  which the panel sets and the content cannot answer back
  (`ParametersView.qml:74`, `:78`). The scroll-bar allowance is a constant, `__chrome: 28`,
  because every exact measurement of it is downstream of the property being computed; it assumes
  the vertical bar is there, so a tab with no vertical bar ends a few pixels short of the right
  edge rather than growing a horizontal bar it does not need.
* **Twelve unlabelled tabs — replaced. CONFIRMED on screen.** tepSound has thirteen groups; they
  now draw as three wrapped rows — `input epoch filter processing sound` / `channels mep stimulus
  tms average` / `session window display` — every one legible, the current one highlighted. The
  "before" capture shows thirteen empty cells with no text at all. All thirteen were clicked in
  turn and each opened its group. Before: `param-ui2\p06_tepsound_params.png`; after:
  `param-ui\g02_tepsound_params.png`, `param-ui\h13_tab_display.png`.
  A Controls 1 tab bar divides the panel between its tabs
  instead of sizing each to its title (both the Base and the Desktop style cap a tab at
  `availableWidth / count`), so twelve groups in a 300 px dock got 24 px each. The bar is now
  hidden (`tabsVisible: false`) and the groups are drawn as a wrapping row of buttons above it,
  each as wide as its own name (`ParametersView.qml:815`, tab list at `:169`). Every group is
  readable at any pane width and still one click away; the cost is one row of height per three or
  four groups, and only for a service that has that many.
  ⚠ The button row is rebuilt by assigning a fresh array of titles, never by a `Repeater` over
  `tabs.count` — inserting a group in the middle changes the count by one, so a count-driven
  Repeater would leave every delegate past the insertion point holding the title it was built
  with. That is the same failure as the ghost checkmarks, one control up.
* **`Model size of -125 is less than 0` — the guessed fix was WRONG and has been rolled back. The
  real source is a defect inside Qt, not in this code.** The clamp on the catch-level dashed line
  (`Plot/PlotView.qml`) was a guess, and the measurement killed it: the warning survived the
  rebuild **with the identical values** (-117, -124, -125, -127), and it fires in a harness that
  never instantiates `PlotView` at all. `Plot/PlotView.qml` is therefore back to its original
  `Math.ceil(catchLayer.width / 10)`; nothing in this repository was changed for this warning.

  The source is `QtQuick/Controls/Private/BasicTableView.qml`, in the `rowfiller` that paints
  alternating stripes below the last row:

      height: listView.model && listView.model.count ? (viewport.height - listView.contentHeight) : 0
      property int paddedRowCount: rowHeight != 0 ? height/rowHeight : 0
      Repeater { model: visible ? parent.paddedRowCount : 0 }

  When the content is taller than the viewport — which for a 137-channel list is always — that
  height is negative, and the negative row count goes straight into a `Repeater`. The arithmetic
  matches the observed numbers exactly: 192 px viewport − 2192 px content = −2000, ÷ 16 px rows =
  **−125**. It is emitted with no `file:line` prefix because a `Repeater`'s internal delegate
  model has no QML source location, which is what made it look like it came from this code.

  **Harmless and not worth chasing further:** the stripes below the last row are the only thing
  affected, there is no such region when the content overflows, and no wrong drawing was ever
  traced to it. Silencing it would mean either vendoring a patched copy of a Qt file or turning
  off `alternatingRowColors`, and neither is worth it for console noise in someone else's file.

---


<a id="history-what-was-not-done"></a>

## What was NOT done

* ~~**No client shows `parameterRefusals` yet.**~~ — **done with item 2.** The Configurator's
  Load now names every refusal under the button.
* **The `resonance` Python package was not touched.** `transform_window_to_channels` still copies
  the input sampling rate; the script works around it in one line. A proper fix belongs in a wheel
  release, which is versioned outside this repository.
* **`R:\dist\msvc64\python` and `mulines\resources` were not created.** The two `robocopy` lines
  are in §5 above; 474 MB of someone else's distro was not added to yours unasked.
* ~~**The playback window shows a mojibake em dash**~~ — **fixed with item 4**, at all four sites.
  See "Also fixed while in the file" above.
* **`playbackSource.exe` run standalone still crashes** (access violation in `Qt5Network.dll`,
  5 of 5 runs). Workers started by `playbackService` are unaffected. Unchanged from the earlier
  report; the seek work did not touch networking or discovery, and did not make it better or
  worse. `playbackService` and the workers it spawns are what the operator uses, and they are
  unaffected.
* **No seek for `playbackSource.exe` standalone.** Seek is reachable only from the playback
  window and only through the controller. A standalone seek would be a `position` parameter
  beside `speed`; out of scope for the reported complaint, which is about the GUI.
* **`tepSoundService`'s own post-seek transient was not measured.** The epoch cutter and
  `tepService`'s IIR chain were traced; `tepSoundService`'s ingest path was not. Watch it the
  first time you seek during a run that matters.


<a id="history-build-and-test-state"></a>

## Build and test state

* Built `all`, MSVC v142, `-j6`, `chcp 65001` after `vcvarsall`. `ninja -t deps`: **621 entries,
  all VALID, 0 stale or missing**.
* **662 tests / 20 executables / 0 failures** after item 4 (was 647 / 19 / 0). The new executable
  is **`test_PlaybackSeek`, 15 cases**, covering time→cursor on an unsorted index, the clamps, and
  the anchor round trip from 0.05x to 10x.
* Core: `test_StreamInfo` 18, `test_SamplesCollector` 1, `test_NetworkMode` 10,
  `test_RecorderPath` pass (needs `RESONANCE_RECORD_PATH` set, or it exits 2 with no output),
  and `test_ParameterApply` **12**, covering the retry-and-report path.
* Two build breaks were fixed on the way in: `SPEED/application.cpp` was missing the `Float64`
  and `QJson*` includes and had `validatedMetaData` undeclared in its header; and
  `InterfacePointers` was being passed to every script engine **uninitialised**, so the new
  `structSize` guard would have been read from stack garbage.
* All 14 deployed services launch and stay up from `R:\dist\msvc64`.

<a id="history-parameter-panel-deploy-2026-08-22-1153"></a>

### Parameter-panel deploy, 2026-08-22 11:53

* Rebuilt `all` after the parameter-panel changes: clean, `ninja -t deps` **621 entries, all
  VALID, 0 stale**. No build breaks to fix this time.
* Suite unchanged: **662 / 20 / 0**, plus `test_StreamInfo` 18, `test_SamplesCollector` 1,
  `test_ParameterApply` 12, `test_NetworkMode` 10.
* Deployed with `robocopy /E` (never `/MIR`) — **0 failed, 50 deploy-only items preserved**.
  Rollback: **`bin.pre-paramui-20260822-115315`** (181 files).
* Exactly one file actually changed in the deployed tree: `bin\Resonance\ParametersView.qml`.
  `Resonance.dll` was already byte-identical.
* ⚠ **`tepSoundService.exe` was deliberately NOT deployed.** It differs from the deployed copy
  only because another workflow edited `R:\src\tepSoundService\` earlier the same morning and this
  build compiled those edits. That work is not mine and was not verified here, so the deployed
  binary was left as it was; it is excluded from the copy, not forgotten. Whoever owns that change
  should build and deploy it themselves.
* Verified by launching the **deployed** tree: Configurator opens, discovers NVX136, the group
  selector draws, 44 wheel steps over the channel list produce no ghost, and the model reads back
  `["1:Ch 1","3:Ch 3"]`. Log clean — 0 `TwoWayBinding`, 0 binding loops, 0 `TypeError`.
* `nvx136` was run only with `--emulation` and only ever in state `init`; the physical amplifier
  was never opened, started or stopped. No processes left behind.

---


<a id="history-item-8-and-9--two-small-tepsound-fixes-asked-for-on-2026-08-22-deployed-1202"></a>

## Item 8 and 9 — two small tepSound fixes asked for on 2026-08-22 (deployed 12:02)

Rollback: `bin.pre-tepsound-display-20260822-120246`. Build clean, **662 tests / 20 executables /
0 failures**, header deps VALID, no non-ASCII in any new narrow string literal.

**8. Subject screen is a dropdown, not a text field.** Operator: *"the user doesnt have to TYPE wierd
windows display designators."* `screen` changed from `Parameters::String` to `Parameters::Select`,
populated by a new `TepSoundService::rebuildScreenOptions()` (`service_run.cpp`) from
`QGuiApplication::screens()`. On this rig it lists
`Any  (wherever the window manager opens it)` / `DISPLAY1 - 3840 x 1600 (primary)` /
`DISPLAY2 - 1920 x 1080 at 1024, 1600`.

* The option **value** is the raw `QScreen::name()`, so `StageWindow.qml`'s `placeOnNamedScreen()`
  matches exactly what it always did — nothing downstream changed. Only the option **text** is
  friendly, and it carries size and corner because "DISPLAY2" alone does not identify a monitor.
* Rebuilt on `QGuiApplication::screenAdded` / `screenRemoved`, so plugging the subject monitor in
  after the service starts updates the list instead of showing the rig as it was at launch.
* Re-selection after a rebuild is **by name, not index** — an index means a different display the
  moment a monitor is attached, which is precisely when the rebuild happens. A chosen display that
  has been unplugged falls back to `Any`, visibly.
* ⚠ `Select::setJson` matches a saved string against the option TEXT, so an older config carrying
  `"screen": "\\.\DISPLAY2"` no longer matches and falls back to `Any`. Since Item 1 landed
  that refusal is **reported**, not silent. Re-pick the screen once and re-save.
* `ui/SettingsPane.qml` control kind `string` -> `select`.

**9. Fullscreen defaults OFF.** Operator: *"Large full-screen back window is disrupting for any work
or test process."* `m_fullscreen->setValue(false)`. Verified on the deployed build: the stage comes up
**800x600 windowed at 1520,480** with the fixation cross, and the `fullscreen` box renders unticked.
The two cases that do want it — a real session, and a presentation test — are the ones where somebody
is present to switch it on.

---


<a id="history-item-10--tepsound-could-not-fire-the-tms-at-all-deployed-1545"></a>

## Item 10 — tepSound could not fire the TMS at all (deployed 15:45)

Rollback: `bin.pre-triggerfix-20260822-155336` (181 files). Build clean, **679 tests /
21 executables / 0 failures**, header deps VALID.

The operator's report: *"manual comport operation does go through and activate the TMS, but
tepsound service were not able to do it."* Not a timing problem, not a wiring problem — the
service's bytes never became commands.

<a id="history-what-was-wrong-4"></a>

### What was wrong

⭐ **`TriggerOut::writeSerial()` wrote the command bytes and no line terminator.**
`R:\src\stimulusService\triggerout.cpp` — the old `:115-122` — put the command on the wire and
stopped. The arduinoTTL firmware (`arduinoTTL\doc\arduinoTTL.ino:1216-1234`) executes a line
**only** on `\n` or `\r`; until then it accumulates into `char line[72]` and silently discards any
line that reaches a 72nd character.

So a whole armed session arrived as one unterminated string — `2=OUT,LOW2:P12:P12:P1…` —
`handleLine()` never ran, no role was set, no pulse was armed, nothing replied, and the board's own
`out2=` counter never moved. Manual operation worked because a Serial Monitor sends Enter.

There was **no configuration workaround**: `setSerialCommands()` parses with
`(\d+)\s*=\s*(\S+)`, and `\S+` is non-whitespace only, so a terminator can never reach the map.

Four more defects sat in the same path:

| | what | consequence |
|---|---|---|
| 2 | The init was written **immediately** after `m_port.open()`, with no delay and no handshake | Opening a port asserts DTR, which **resets an Arduino Nano for ~1.5 s**. The init was swallowed, D3 kept its power-on high-Z role, and every later `2:P…` would have been answered `ERR ch2 not an output` — which nothing read. An ATmega328P Xplained Mini is *not* reset, so a fixed sleep was not the answer |
| 3 | `configure()` called `close()` **unconditionally**, and it is reached from `TepSoundService::reconfigure()` via a 50 ms coalescing timer that **any** parameter write arms | Editing any tepSound parameter while armed silently closed the trigger port. Nothing reopened it until Stop then Arm. Very likely present in the operator's actual sequence: type the port name → Arm → tweak something |
| 4 | An unmapped code sent one raw byte, `QByteArray(1, char(code & 0xFF))` | Code 2 became `0x02`, which the firmware accumulated into its line buffer and which then **corrupted the next real command**. The parameter description meanwhile promised a *fallback to the first entry* — which the code did not do, and which would have been worse if it had |
| 5 | `close()` never parked the line | No `S` on the way out, unlike `SerialTransport::close()` (`arduinoTTL\transport.cpp:61-71`). The channel was abandoned rather than stopped |

<a id="history-what-changed-5"></a>

### What changed

New file **`R:\src\stimulusService\triggerline.hpp` / `.cpp`** — Qt-Core only, no `QSerialPort`, no
Resonance. It holds the four decisions that were actually wrong: `isTerminated`/`terminate`,
`longestLine`/`fits` (`kMaxLineChars = 71`), `parseCommands`, `classify` (board identity vs. boot
banner), and `Wire`/`needsReopen`. Nothing in it touches a port, so nothing in it can fire
anything — and it can be unit-tested with no stimulator in the room.

1. **The terminator lives in `writeSerial()`**, not at the two call sites — one place means a third
   call site cannot forget. It appends `\n` only when the command is non-empty and does not already
   end in `\n` or `\r`, so a config-supplied terminator passes through rather than doubling.
   The **72-character limit is refused visibly and early**: `open()` checks the init and every
   mapped command *before* the port is opened and refuses the Arm naming the offending code, with
   `writeSerial` re-checking as a backstop. The check is per *line*, not per write.
2. **A handshake replaces the blind write.** `setDataTerminalReady(true)` / `setRequestToSend(true)`
   (the Xplained Mini's mEDBG passes no traffic without them), then `ID?` every 400 ms, up to 12
   tries, with the count restarted **once** by a `…ready` banner. Bounded, not a sleep: an Xplained
   Mini answers on the first try and pays nothing; a resetting Nano costs ~1.6 s; an absent board
   costs 4.8 s and then **refuses the Arm**. `open()` stays synchronous and still reports through
   `bool` + `*error`, so `beginSession()` refuses the Arm exactly as before — an Arm that returns
   true before the port is usable would be worse than the wait. The handshake runs **only when an
   init string is configured**, so `stimulusService`'s legacy single-character boxes, which do not
   speak `ID?`, are not made unusable by a question they cannot answer.
3. **`configure()` compares backend, target and baud** and closes only on a real change of
   connection. Deliberately *not* compared: the pulse width and the command map (both read when a
   pulse is issued) and the init string (read on the **next** open — a safety choice, because
   re-applying an output role puts an edge on BNC2, so a parameter edit must never be able to
   reissue it). When a change genuinely does cost the port mid-session it now says so.
4. **An unmapped code sends nothing** and reports *"trigger code N has no line in the trigger map;
   nothing was sent"*. The documented fallback-to-the-first-entry was **not** implemented — it
   would let a code nobody mapped fire the stimulator. The parameter description was corrected to
   match the code, in both tepSound and stimulusService.
5. **`S\n` + `waitForBytesWritten(200)` before `close()`** — but only when the handshake identified
   an arduinoTTL. On a board whose language was never confirmed, inventing a command is how you
   find out what its `S` means, and this file drives a stimulator. A `readyRead` drain was added
   with it: the board never used to reply, because nothing was ever terminated; now it replies to
   every line, and without the drain `QSerialPort`'s read buffer would grow one reply per pulse for
   a whole session.

<a id="history--the-safety-fact-now-reaches-the-operator"></a>

### ⚠ The safety fact now reaches the operator

`firmware-README.md:213-214`: *applying an output role sets the idle level immediately, so expect
one edge on BNC2 at that moment.* D3 boots released and high-Z with no bias. ⇒ **the `2=OUT,LOW`
init string can itself fire the TMS**, and nothing in tepSound said so. The `triggerInit`
description now carries it, terse and factual:

> ⚠ Applying an output role sets the idle level at once, so arming puts one edge on BNC2. That
> edge can fire the stimulator. Arm before the coil is on the head.

The reasoning stays in a source comment, per the operator-facing-text rule.

<a id="history-proof--the-exact-bytes-with-no-board-attached"></a>

### Proof — the exact bytes, with no board attached

No virtual COM pair is possible on this machine: `com0com` is not installed, installing a
kernel-mode driver was out of scope, only one COM port exists (a Bluetooth SPP port, no board), and
`QSerialPort` **refuses a named pipe** — probed and confirmed, it fails with *invalid handle*
because `GetCommState` cannot be called on one. So this is **not a wire capture**.

What was done instead is stronger than a unit test and weaker than a sniffer, and is labelled that
way: the **shipped, unmodified `triggerout.cpp`** was compiled against a recording stand-in for
`QSerialPort` that also **models the firmware's `line[72]` input path** — it executes a line only
on `\n`/`\r` and drops an overlong one. The harness then drives the exact tepSound sequence
(`configure`/`setSerialInit`/`setSerialCommands` → `open` → `pulse` ×3 → `close`).

Pre-fix path, reconstructed from the old line numbers, shipped defaults:

```
2=OUT,LOW2:P12:P12:P1\x09
32 3D 4F 55 54 2C 4C 4F 57 32 3A 50 31 32 3A 50 31 32 3A 50 31 09
```

⭐ The emulated board logged **no EXECUTE line at all** across the whole session. That is the bug,
reproduced.

Post-fix, same defaults, same sequence:

| when | ascii | hex |
|---|---|---|
| Arm — handshake | `ID?\n` | `49 44 3F 0A` |
| Arm — init, only after the board answered | `2=OUT,LOW\n` | `32 3D 4F 55 54 2C 4C 4F 57 0A` |
| each pulse | `2:P1\n` | `32 3A 50 31 0A` |
| Stop | `S\n` | `53 0A` |
| unmapped code 9 | *nothing* — 0 bytes, `failed()` raised | — |

The emulated board executed every one of them and reported a pulse on BNC2 for each `2:P1`.

With the board silent (a Nano stuck in reset), the fixed `open()` sent `ID?\n` twelve times, wrote
**no init byte**, and refused the Arm with *"no arduinoTTL answered ID? on COM8 after 4 s"*. A
failed Arm therefore cannot put an edge on BNC2 — worth stating explicitly.

The reopen fix, watched through the port state:

| step | wire string |
|---|---|
| after Arm | `COM8 open` |
| after editing the pulse width (5 → 7) while armed | `COM8 open` — **0 bytes emitted**, so no re-issued init edge either |
| after editing the trigger map while armed | `COM8 open` |
| the next pulse | `2:P2\n` reached the board, using the new map |
| after changing the port name COM8 → COM4 | `S\n` sent, then `COM4 (not open)` + *"Stop and arm again to reopen it"* |

Both halves matter: the first shows the bug is gone, the second shows the fix did not simply stop
reopening ports.

<a id="history-tests"></a>

### Tests

New GTest binary **`test_TriggerLine`, 17 cases** (`stimulusService/tests/triggerline_test.cpp`),
linking `GTest::GTest Qt5::Core` and compiling `triggerline.cpp` only — **no `Qt5::SerialPort`, on
purpose: the test binary must not be able to open anything.**

The ⭐ one, `ExactBytesForShippedDefaults`, asserts the literal buffer for the shipped defaults is
`"2=OUT,LOW\n2:P1\n2:P1\n2:P1\n"` and explicitly `EXPECT_NE`s the defect's
`"2=OUT,LOW2:P12:P12:P1"`. The rest cover: terminator not doubled (`\n`, `\r`, `\r\n`), empty stays
empty, 71 fits and 72 does not, the limit is per line, map parsing including the legacy `1 = a`
form, an unmapped code yielding empty rather than the first entry, the `\S+` capture being unable
to smuggle a terminator, banner-vs-identity classification including the `2 ` prefix and CRLF, and
the reopen comparison in both directions.

Test-executable baseline **20 → 21**, case count **662 → 679**.

<a id="history--what-still-needs-the-rig"></a>

### ⚠ What still needs the rig

None of this has met a board. Untestable here and listed as such in the test file's own header:

* opening a real port at all;
* the DTR-reset handshake against a real Nano — whether `ID?` is answered within 12 tries;
* the init edge on BNC2, and whether it discharges the coil;
* `S` on close actually parking the channel;
* and the whole question the fix exists for: **does the coil fire.**

`R:\config\lab\LAB_PROMPT.md` was rewritten for this. Job 1 changed from *find out why it does not
fire* to *confirm it fires, and confirm the four secondary fixes*; the ranked-cause table was kept
and reframed as a **fault tree**, with causes 1, 2, 5 and 7 marked FIXED so that seeing one again
means the distribution is wrong rather than the diagnosis. The coil-clear-before-**init** rule is
unchanged and still prominent — the init edge is not affected by any of this.

<a id="history-left-alone-deliberately"></a>

### Left alone deliberately

* `triggerInit` stays a single-line `Parameters::String` and `parseCommands` keeps the `\S+`
  capture. The terminator is the transport's job now, not the config's — and the `tepsound-lf`
  config workaround is therefore obsolete.
* `TriggerOut` was **not** refactored toward `arduinoTTL`'s `Board`: no `Transport`, no reply
  parsing beyond the identity line, no async state machine. The point was a working terminator and
  a handshake, not an architecture.
* The `Transition` and `Parameter` backends are untouched.
* `description()` is unchanged — `service_run.cpp:360` compares it against `"off"`.
* tepSound publishes its `pulse/fired` event regardless of whether `TriggerOut` actually wrote
  (`service_run.cpp:311-325`). That is a truthfulness gap, not a safety one, it is outside this
  diagnosis, and the `failed()` signal still raises the operator's trigger error banner.

⚠ `triggerout.cpp` is compiled into **both** `stimulusService` and `tepSoundService`; both were
rebuilt and both were deployed and launched.

---

<a id="history-post-lab-block--items-1115-deployed-2026-08-23"></a>

# Post-lab block — items 11–15, deployed 2026-08-23

From the first real TMS session (`R:\tests\lab-session-20260822\REPORT.md`). The trigger fix of
item 10 was **confirmed on hardware** in that session — tepSound armed on COM8 and all three
commanded pulses discharged the coil — so item 10 is closed. What follows is what the session
exposed on the way.


<a id="history-at-a-glance-1"></a>

## At a glance

| # | Symptom | Cause | State |
|---|---|---|---|
| 11 | A harness reports "clamped to 20 %" while the stimulator can still fire at 30 % | `connect` makes the service **adopt the device's own settings**, and the harness clamped only *before* `connect` | **Fixed structurally.** Harnesses no longer send `charge` at all; `PowerGate.qml` does, and only after a verified read-back |
| 12 | "Does a parameter edit while armed close the trigger port?" — **untestable** | The port state (`off` / `COM8 (not open)` / `COM8 open`) existed only as console UI; none of tepSound's 108 parameters exposed it | **Fixed and proved.** Published on `events` and sampled as status channels 41–42 |
| 13 | An A16 refusal says only `pulsesSkipped: n` — *why* is on the console | The interlock's sentence never reached the `events` stream | **Fixed and proved.** `{"type":"pulse","event":"refused","reason":…,"blocker":…}` |
| 14 | ⚠ A 94 kB file holding `NeuroMS/status` where 90 s of 25 kHz trigger lane was expected | A bare `discover:///…` string was **refused**, and a refused write leaves the slot holding its previous value — which the recorder then recorded, silently | **Fixed on both sides and proved end to end.** The string form applies; a refusal that stands now blocks recording |
| 15 | `--dangling-probe` can only ever return silence | `ttl_probe.py` wrote `S\n` on every exit path, terminating the very line the probe leaves dangling | **Fixed.** The park is suppressed in `--as-tepsound`, out loud |

Five items, and the interesting thing about them is that **four are observability failures, not
behaviour failures.** Items 12, 13 and 15 each made a specific test impossible; item 14 is the one
where the invisibility produced wrong data rather than merely no answer. Item 11 is the only one
that was a live hazard.


<a id="history-item-11--the-clamp-that-did-not-hold"></a>

## Item 11 — the clamp that did not hold

`R:\config\lab\harness_tms_session.qml` clamped `maxPower`/`power1` **before** `connect` only, and
`connect` makes the service adopt the device's own settings. The lab's `settings` event arrived
reading `power1=30, power2=30, "adopted from the device; nothing was written to it"` *after* the
clamp to 20. Nothing fired at 30 % that session — but a harness that believes it clamped, firing a
stimulator at an intensity the operator did not authorise, is the failure mode, and it was one
event away.

The fix is deliberately **not** "clamp again after connect in that harness". It is a shared
component, `R:\config\lab\PowerGate.qml`, which owns the `charge` transition outright: no harness
sends `charge` any more. It is released only when all four hold — values rewritten after `connect`
as well as before; 3500 ms settled (the ~3 s stale-read-back trap is baked into the mechanism, not
left to a comment); a read-back present **and** within the ceiling for all three, where a parameter
*missing* from the read-back counts as a failure rather than a zero; and `parameterRefusals`
naming none of them. A 5 s watchdog re-reads after charging and refuses on an intensity that
*rose* mid-run, because the front-panel knob is a live input.

`harness_neuroms_probe.qml` had the same defect and now uses `PowerGate.verifyOnly()`.
`run_harness.ps1` refuses to launch a harness that uses `PowerGate` when `PowerGate.qml` is not
beside it.

⚠ **QML, so untested by any binary in this tree.** `qmllint` passes on every touched file; the gate
itself has not been exercised against a stimulator. It is the highest-value thing to watch on the
next session.


<a id="history-items-12-and-13--proved-against-a-live-service-no-hardware"></a>

## Items 12 and 13 — proved against a live service, no hardware

Both were proved by driving a real `tepSoundService` from a QML harness over the EventBus and
reading its `events` stream from outside the process — no GUI, no COM port, nothing physical.

Item 13, a manual pulse while not armed:

```
{"blocker":"notArmed","event":"refused","pulsesSkipped":0,
 "reason":"the session is not armed","source":"manual","type":"pulse","v":1}
```

Item 12, the question the lab wrote down as untestable — **arm, then edit a parameter while
armed**:

```
{"backend":"Serial","engaged":true,"event":"state","open":false,"ready":false,
 "target":"COM98","type":"trigger","v":1,"was":"COM99 (not open)",
 "why":"reconfigured WHILE ARMED","wire":"COM98 (not open)"}
```

So the answer is **yes**: any parameter write re-runs `reconfigure()`, `TriggerOut::configure()`
closes an open port, and the service now says so, names the previous wire in `was`, and gives the
reason in `why`. Four `trigger/state` events were observed across one run — `reconfigured`,
`armed - open failed: …`, `reconfigured WHILE ARMED`, `stopped` — which is the whole life of the
wire, readable by a script.


<a id="history-item-14--the-silent-wrong-recording-reconstructed-and-closed"></a>

## Item 14 — the silent wrong recording, reconstructed and closed

⭐ This is the one with a real end-to-end test available, and it was run: a live `recorderService`
and a live `signalGenerator`, driven from a QML harness, reproducing the lab's exact state.

1. `stream1` pointed at a real stream **with a bare address string** — now **accepted**, where it
   was refused before. This is the form the slot's own tooltip documents.
2. A value that is still refused on purpose (`signalGenerator/generated` — no scheme, addresses
   nothing) is written. It bounces, and the slot **still holds the previous source**. That is the
   lab's state exactly, and it is now visible in `parameterRefusals` instead of being silent.
3. `start` is pressed in that state. **The recorder refuses and stays in `idle`**, with

   ```
   RECORDING REFUSED: stream1 was asked for and is NOT set. The slot still holds its previous
   value, so starting now would record something other than what was configured.
   ```

   and no file is opened — confirmed by the output directory, not by the log.
4. An applying value is sent again; the refusal clears and recording starts normally. The file
   written contains `generated`, 3 channels at 250 Hz — **the stream that was actually asked
   for**.

Both halves were needed. Accepting the string form removes the failure at its source; making the
refusal fatal covers the cases the string form does not reach. ⚠ **No override parameter, on
purpose** — an override is how this comes back. The recovery is a value that applies.

Re-run against the **deployed** binaries after deployment, with the same result.


<a id="history-item-15-and-the-documentation-corrections"></a>

## Item 15 and the documentation corrections

`ttl_probe.py` suppresses its parking write in `--as-tepsound` and says so, printing the exact
follow-up commands; `--park-anyway` restores the old behaviour and voids the probe.

The corrections the lab had to discover the hard way are applied wherever they were wrong: the A16
parameter is **`input/tmsStatus`**, not `tms/tmsStatus`; the board firmware is **v2.2**, not v2.3
(channel 1 has no role command — `1=OUT,LOW` answers `ERR unknown` — because D9 is a permanent
output); the extra Arduino→NVX lead is on **bit 1**, so the pairing is `--pair 1:0`; the idle word
on this rig is **`0x0000FFFE`** (TMS on) / **`0x0000FFFF`** (standby).


<a id="history-the-rig-numbers-and-the-one-that-is-most-likely-to-be-misquoted"></a>

## The rig numbers, and the one that is most likely to be misquoted

* ⭐ **TMS Trig-Out pulse width = 120 µs**, and the NVX136 driver has **no edge-latch mode, only
  level sampling**. At 1 kHz a pulse is caught ~12 % of the time — the lab saw 1 of 8; at 25 kHz,
  4 of 4. **Any trigger or latency campaign on this rig must run at 25 kHz.** A short count on
  bit 0 at 1 kHz means nothing at all.
* **command → pulse = 0.840 ms median** (n=4, span 1 sample), of which **0.838 ms is the Arduino
  dispatching two serial lines**; the stimulator's own trigger-in → Trig-Out contribution is below
  the 40 µs resolution. ⚠ **Never quote 0.840 ms as "the stimulator's latency".**
* **The stimulator is in paired-pulse mode**: every trigger delivers **two** discharges — 16 device
  discharges from 8 commands. Not a fault, but trial counts halve, a host ledger *should* differ
  from the device count by 2×, and bit 0 shows **one** edge, so the trigger channel cannot count
  discharges.
* Confirmed for this rig: `triggerChannel 0`, `triggerBit 0`, `triggerEdge Rising`.


<a id="history-tests-1"></a>

## Tests

* `R:\src\Core\Resonance\tests\StreamParameter_test.cpp`, target `test_StreamParameter`, 11 cases
  — including `ARefusedWriteLeavesThePreviousSourceInPlace`, which pins the exact behaviour the
  recorder's refusal compensates for.
* `R:\src\tepSoundService\tests\sound_test.cpp` — the append-only status-channel pin extended
  from 36 to 42 names, locking the two new channels in position.
* `R:\src\nvx136\tests\logic_test.cpp`, target `test_Nvx136Logic`, 12 cases (see
  `nvx136-cold-start.md`).

**Suite after this block: 691 tests / 22 executables / 0 failures** in
`R:\dist\_build\msvc64\tests`, plus `test_StreamInfo` 18, `test_SamplesCollector` 1,
`test_ParameterApply` 12, `test_StreamParameter` 11 and `test_NetworkMode` 10. Up from 679/21/0.

⚠ **What is QML-only or needs hardware, and is therefore unproven:** `PowerGate` and both harness
rewrites; the recorder's red banner; every tepSound trigger path that needs a real COM port. And
separately — **the whole NVX136 cold-start fix is an untested inference** until the cold ladder
runs at the rig; see `nvx136-cold-start.md` §9.
