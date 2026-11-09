# TEP analysis — operator guide — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](legacy-tep.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-tep-analysis--operator-guide"></a>


**For the person running the session.** How to start it, what each control does, what the screen
is telling you, and what to do when it tells you something is wrong.

> ## ⚠ Which distribution each half of this guide runs against
>
> **Read this before §2.** This guide covers two different programs, and only one of them is in
> the default distribution.
>
> **§1–§10 are `tepService`, and `tepService` is Qt 5 only.** It was not carried into the Qt 6
> port, so `R:\dist` holds neither `tepService.bat` nor `bin\tepService.exe`. Every launch
> instruction in §1–§10 — §2.1 step 3, the command line in §2.2, the rehearsal in §8 — runs from
> **`R:\dist_Qt5\msvc64\tepService.bat`**. Start that session's `NVX136.bat`,
> `recorderService.bat` and `playbackService.bat` from the same tree: all three exist in both
> distributions, and a session is easier to reason about when it comes out of one of them.
>
> **§11–§15 are `tepSoundService`, and that *is* in `R:\dist`** — `tepSoundService.bat` at the
> root, `bin\tepSoundService.exe`. It is the console the lab runs today, and it covers the §1–§10
> paradigm: turn its `soundEnable` parameter **off** and, in its own words, "the service is an
> ordinary online TEP/MEP analyser". Three tepService behaviours it does **not** cover are named
> in the box at the top of [`service_tep.md`](../history/components/tep.md); if you need one of them, you need
> the Qt 5 launcher.
>
> ⚠ **And which `tepSoundService` you start still depends on the hardware.** `R:\dist` is not yet
> cleared for a session with an NVX-136 or a Neuro-MS — two confirmed Qt 6 driver regressions — so
> such a session runs this console from `R:\dist_Qt5\msvc64` as well, and the whole chain with it
> ([`build_qt5-to-qt6-transition.md`](../history/migrations/qt5-to-qt6-transition.md)).
>
> Why tepService did not cross and what porting it would cost:
> [`arch_qt5-still-needed.md` §3.2](../history/migrations/qt5-still-needed.md).

The technical reference is [tep-service.md](../history/components/tep.md); the evidence that the numbers are
right is `report_tep-service-validation.md` (on the lab drive, `R:\docs\_notes\`). You do not need either to run a
session.

---


<a id="history-1-what-this-program-does"></a>

## 1. What this program does

It watches the amplifier's stream, notices every TMS pulse on the trigger line, cuts the signal
into epochs around each one, removes the stimulus artifact, averages them, and measures the MEP.
You get four pictures and a table, live, while the session runs.

It does **not** present stimuli, drive the stimulator, or start the amplifier. Those are other
programs. It also does not record the raw EEG — `recorderService` does that, and it should be
running alongside.

---


<a id="history-2-starting-a-session"></a>

## 2. Starting a session

<a id="history-21-the-short-version"></a>

### 2.1 The short version

⚠ All three launchers below are the **`R:\dist_Qt5\msvc64`** ones — `tepService.bat` does not
exist in `R:\dist`. See the box at the top.

1. Start the amplifier driver (`NVX136.bat`) and let it reach **running**.
2. Start `recorderService.bat` and point it at the amplifier's `eeg` stream. Start the recording.
3. Start `tepService.bat`.
4. In the console, set **Subject** and **Condition**.
5. Press **Start** (or `Space`).
6. Run the session.
7. Press **Stop** (or `Esc`). The epoch file is written automatically.

<a id="history-22-starting-it-already-configured"></a>

### 2.2 Starting it already configured

The launcher takes arguments, so a rig can have a one-click shortcut:

```bat
tepService.bat --signal NVX136/eeg --montage ..\montages\mumeg_mks64.ced --autoStart
```

| Option | What it does |
|---|---|
| `--signal Service/stream` | which amplifier stream to analyse. A full `discover:///?…` URL also works |
| `--montage file.ced` | the electrode layout for the scalp picture and for channel names |
| `--autoStart` | begin collecting 2.5 seconds after launch, without anyone pressing Start |

Everything else can be set in the console, or in the Configurator, or from a saved parameter
file (`--serviceConfig`).

<a id="history-23-if-the-run-bar-says-no-signal-stream"></a>

### 2.3 If the run bar says "no signal stream"

**Start** is disabled and hovering it says why. Usually the amplifier is not running, or the
stream name is wrong. Open the Configurator, find **TEP**, and set the `signal` parameter — it
is the same parameter the `--signal` argument sets, and either is fine.

⚠ **There is a third cause, and nothing on screen names it.** Since 2026-08-18 a Resonance
service only sees other services **on the same computer**, and only ones running in the same
network mode. If the amplifier is on another machine, or was started from a different (older)
copy of the program, TEP will never find it however long you wait and the stream list stays
empty. Everything for one experiment must run on one computer, from one copy of the program.
Ask whoever maintains the rig for [network-isolation.md](../history/migrations/network-isolation.md) if you need the
amplifier on a second machine.

The plots say what they are waiting for rather than sitting blank, and the yellow line at the top
is about the settings, not about the missing stream — see §5.

---


<a id="history-3-the-screen"></a>

## 3. The screen

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ ● TEP  eeg · 67 ch · 25000 Hz    epochs · in average · triggers · lost   [ buttons ]  │  run bar
│ ⚠ warnings about the settings, if there are any                                      │
├───────────────┬──────────────────────────────────────┬───────────────────────────────┤
│  settings     │  the scalp grid                      │  TEP · all electrodes         │
│               │                                      ├───────────────────────────────┤
│               ├──────────────────────────────────────┤  MEP · average ± sd           │
│               │  the epoch table                     ├───────────────────────────────┤
│               │                                      │  MEP · single trials          │
└───────────────┴──────────────────────────────────────┴───────────────────────────────┘
```

**Every divider moves** — the three columns sideways, and the panels inside the middle and right
columns up and down. Which of these matters is different while the coil is being positioned (the
scalp map) and in the middle of a run (the single trials), so none of them has a fixed share.

The table is under the grid because clicking a row changes what the grid draws, and the three time
courses share the right-hand column one above the other so their x axes line up by eye.

<a id="history-the-run-bar"></a>

### The run bar

| | |
|---|---|
| **epochs** | how many have been collected |
| **in average** | how many are actually **in** the average. Rejected epochs are not, and neither are epochs collected at a different window length — changing the window mid-session leaves the earlier ones on a different time base, and they stop contributing |
| **triggers** | how many pulses were seen on the trigger line. If this is larger than **epochs**, some pulse did not produce a usable epoch |
| **lost** | epochs the program could not build. **This should be zero.** Anything else means the machine could not keep up, or a pulse arrived inside the refractory period |

<a id="history-the-scalp-grid"></a>

### The scalp grid

One small trace per electrode, drawn where that electrode sits on the head. This is the picture
to read for *where* a response is — a response at the coil and nothing elsewhere looks completely
different from a response everywhere, and neither is visible in a stack of sixty-four lines.

- **average / selected** switches between the running average and whatever is picked in the
  epoch table. `A` does the same.
- **± 30 µV** is the vertical scale of every cell. Type over it or roll the wheel on it.
- **labels on / off** hides the electrode names when the grid gets crowded.
- Hovering a cell names it at the top of the panel; clicking it highlights that electrode in the
  butterfly below.

<a id="history-tep--all-electrodes"></a>

### TEP · all electrodes

Every electrode over one axis. Useful for the shape and the timing; the grid is for the place.
The two `ms` boxes on its strip set the time range for **both** it and the grid.

<a id="history-mep--average--sd"></a>

### MEP · average ± sd

The averaged MEP with a shaded band one standard deviation wide across single trials. **The band
is the number that matters**: a large average with a band as large as itself means the trials
disagree, and averaging more of them will not fix it.

The shaded vertical strip is the measurement window (**Measure from / to** in the settings). The
amplitude in the table is the peak-to-peak inside it.

<a id="history-mep--single-trials"></a>

### MEP · single trials

The last few, newest at the bottom. Set how many with **Single MEPs**. This is where
pre-innervation shows up — a trace that is already moving before the pulse.

Each trace carries **▼ and ▲ at the two extremes the amplitude was measured between**, and its
peak-to-peak value on the right. The markers are inside the measurement window, so what is drawn
and what the table reports are the same number, and moving **Measure from / to** moves both.

A trace whose amplitude reaches **Threshold** is drawn in green. It marks nothing and rejects
nothing — it is there so a run of subthreshold trials is visible at a glance while the coil is
being positioned, which is when it matters. Set the threshold to 0 to draw every trial alike.

<a id="history-the-epoch-table"></a>

### The epoch table

One line per epoch, newest first.

| Column | What it is |
|---|---|
| `#` | epoch number |
| `time` | when it arrived |
| `MEP mV` | peak-to-peak amplitude in the measurement window |
| `onset` | when the response left the noise band, in ms. `—` means it never did |
| `rms` | the EMG's root-mean-square **before** the pulse. **This is the pre-innervation number.** A resting muscle is a few thousandths of a millivolt; a tense one is ten times that |
| `label` | the condition, if a marker stream is connected — the marker's own text, verbatim |

**Selecting rows changes what the plots show.** Click one epoch to look at it; Ctrl-click to add
or drop one; Shift-click to take everything between; `Ctrl+A` for all; `Esc` back to the running
average. With several selected, the scalp grid and the butterfly draw the average of exactly
those — which is how two conditions get compared without waiting for the session to end.

**Right-click** rejects an epoch, or puts it back. A rejected epoch stays in the file — marked,
not deleted.

---


<a id="history-4-the-settings-that-matter-during-a-session"></a>

## 4. The settings that matter during a session

Everything here can be changed while the session runs, and the whole session redraws — it is not
"from the next stimulus onwards". Nothing is lost by trying a setting.

<a id="history-epoch"></a>

### Epoch

| | |
|---|---|
| **Window from / to** | how much of the signal around each pulse to keep, in milliseconds. Changing this restarts the epoch geometry, so epochs already collected at the old length stop contributing to the average — watch **in average** |
| **Window from**, positive | allowed, and not a mistake: an epoch that opens *after* the artifact has been interpolated away looks only at the response. The baseline then has nothing before the stimulus to work from, so switch it off or move it inside the window |
| **Epoch rate** | the rate the epochs come out at. 5000 Hz from a 25 kHz amplifier is a factor of five |
| **Remove artifact** | on, always, for TMS. It replaces the pulse with a straight line |
| **Artifact from / to** | the span replaced. `hold 15.3 ms` beside it is how far behind the live signal the analysis necessarily runs — that is the algorithm, not the computer |

<a id="history-processing"></a>

### Processing

| | |
|---|---|
| **Display lowpass** | smooths the picture. It does not affect what is recorded |
| **Baseline** | subtracts the level of a pre-pulse interval so every epoch starts at zero. **Keep the interval clear of the artifact** — a baseline that reaches into the pulse takes the artifact's own level as zero |
| **CAR** | common average reference: the mean over every electrode, subtracted from each. **CAR excluding** names the ones left *out* of that mean — mastoids, neck electrodes, anything known bad. Empty means average over all of them. It is also the quickest way to see past the TMS artifact's tail, which is common to every electrode: |
| **Re-reference** | subtract an explicit reference from every electrode. **Reference to** names the electrodes that *form* it: one is an ordinary re-reference, several are averaged together first and that mean is what gets subtracted — which is how a linked-mastoid reference is built |

Both pictures are the same 75 epochs. The change was made while the session was loaded and the
whole session redrew — nothing had to be decided in advance.

⚠ The old Python program used the same list the opposite way round — it averaged over exactly
the listed electrodes rather than excluding them, so its shipped configuration re-referenced
everything to the mean of FT9, FT10, TP9 and TP10. That behaviour is **not** reproduced here.
An old result computed with it cannot be reproduced by this program, and should not be.

<a id="history-average"></a>

### Average

| | |
|---|---|
| **Show average** | average, or the newest epoch |
| **Average by** | `mean` is what an evoked potential is. `median` survives a few ruined trials untouched. `trimmed mean` drops the extreme tenth at each end |
| **Average all / over N** | all of the session, or only the most recent N |
| **Keep epochs** | how many stay in memory. Each is about half a megabyte |

<a id="history-mep"></a>

### MEP

| | |
|---|---|
| **Measure from / to** | the response window the amplitude is taken over. It is shaded on the averaged MEP and it is where the ▼▲ markers on the single trials sit |
| **Threshold** | peak-to-peak, in mV, above which a single trial is drawn green. 0 draws them all alike |
| **Remove slow trend** | takes a slow drift out of the EMG without touching a response |
| **Reject above … mV rms** | automatically mark an epoch whose pre-pulse EMG is above this. 0 accepts everything. Start at 0, watch the `rms` column for a few minutes, then set it above what a resting trial actually reads |

---


<a id="history-5-the-warning-strip"></a>

## 5. The warning strip

A yellow line under the run bar means a setting will quietly produce a wrong answer. Each one is
worth reading before the subject is in the chair.

| Warning | What to do |
|---|---|
| *The MEP window (A…B ms) overlaps the interpolated artifact span* | Part of what is measured is a straight line the program drew, not signal. Either shorten the artifact span or start the measurement later |
| *The baseline window (A…B ms) overlaps the interpolated artifact span* | The baseline is being taken partly from interpolated samples. Move it earlier |
| *The epoch window closes at A ms, at or before it opens at B ms* | Window to must be greater than Window from |
| *Decimating by N with the continuous lowpass switched off* | Turn the lowpass back on. Without it, high-frequency content folds down into the epoch and cannot be told from signal |
| *The lowpass is at N Hz but the epoch rate is M Hz* | Same problem: the lowpass must be below half the epoch rate |
| *Artifact span is in legacy mode* | A deliberate compatibility setting, for reproducing an old result. Fine if you meant it |

A warning goes **the instant its cause does**. Nothing here is a log: if a message is on screen,
the thing it describes is true right now. The same applies to the red text in the status bar —
a montage that could not be opened stops being reported the moment one loads.

An epoch window that opens after the artifact, or a measurement window that simply sits after it,
is not warned about. Only a real overlap is.

---


<a id="history-6-ending-a-session"></a>

## 6. Ending a session

**Stop** (or `Esc`) ends collection and writes the epoch file if **Save on stop** is ticked. The
file name comes from **Epoch file**:

```
tep_$subject_$condition_$$$.h5
```

`$subject` and `$condition` are replaced from the fields above, and the run of `$` becomes a
number that counts up, so a session is never overwritten. A plain name lands in the
distribution's `data\` folder.

**Save** writes it without stopping — useful mid-session.

**Reset** throws the session away and starts counting from one. It does not touch a file already
written.

**Note…** (or `N`) puts a line of text into the event stream with the current time. Use it for
anything the recording cannot say for itself: a coil that moved, a subject who spoke, a change of
intensity.

---


<a id="history-7-what-the-epoch-file-contains"></a>

## 7. What the epoch file contains

The same layout the previous program wrote, so every analysis script already written for it keeps
working:

| Dataset | |
|---|---|
| `epochs` | `[n_epochs × n_samples, n_channels]`, float32, in the amplifier's units |
| `timestamps` | one per epoch, nanoseconds, the moment of the **pulse** |
| `labels` | one per epoch: the condition, from the marker stream. Empty when none was connected |
| `mep/amplitude_mV`, `mep/onset_ms`, `mep/rejected` | the measurements, beside the epochs they were made from |

The attributes on `epochs` carry `Fs`, `n_epochs`, `n_samples`, `n_channels`,
`window_start_ms`, `window_end_ms`.

This is **not** the recording. The recording is whatever `recorderService` wrote — the full raw
stream. The epoch file is a derived product, and if you change a setting and save again you get a
different one, which is the point.

---


<a id="history-8-checking-a-session-before-the-subject-arrives"></a>

## 8. Checking a session before the subject arrives

Nothing here needs a subject or a stimulator:

1. Replay a previous recording with `playbackService.bat`, mapped to the same service and stream
   names the rig uses.
2. Start this program against it and press Start.
3. Watch the epoch count follow the recording's stimuli, and the MEP average build.

That exercises the whole path — discovery, the trigger line, the pipeline, the file — and it is
the same thing the validation report did.

---


<a id="history-9-if-something-is-wrong"></a>

## 9. If something is wrong

| Symptom | Cause to check first |
|---|---|
| **triggers counts up, epochs does not** | The window opens before the stream did (only at the very start), or the epochs are being lost. Check `lost` |
| **triggers stays at 0, or counts fewer than you fired** | ⭐ **On the NVX136 TMS rig, check the amplifier's SAMPLING RATE first.** The stimulator's Trig-Out pulse is only **120 µs** wide and the NVX136 driver **level-samples** — it has no edge latch. At 1 kHz roughly **7 pulses in 8 are missed** (measured: 1 of 8 seen); at **25 kHz all of them are seen** (4 of 4). **Record at 25 kHz** for anything that counts or times triggers on that rig; a low or zero count at 1 kHz means nothing at all. Otherwise: wrong `Trigger bit` or wrong channel. The trigger word is a bitfield and an unconnected input reads `0xFF` — the value is never zero, so only one bit is the stimulus. **Confirmed for the TMS rig: `Trigger channel` 0, `Trigger bit` 0, `Trigger edge` Rising**, and `Trigger channel = 0` is correct — 0 means the last channel, which is where a trigger lane is |
| **The scalp grid says "no montage"** | No `.ced` file, and the driver did not publish electrode positions. Set **Montage** in the Configurator's `input` group |
| **Every trace is a huge slow decay** | That is the TMS artifact's tail, and it is real: it is common to every electrode, so a **CAR** removes it and the TEP waveforms appear underneath. The other cure is the continuous **Highpass** at 1 Hz. Both change what is measured, so decide deliberately — but see the note below, because the lab's own notes already say the highpass is required for the EMG |
| **The MEP is upside down** | Swap **EMG channel A** and **EMG channel B**. The trace is B minus A |
| **The average stops changing** | Check **in average** against **epochs** — epochs are being rejected, or their length changed when a window setting moved |
| **The Pulse button does nothing** | It was refused, and the reason is now on the `events` stream as `{"type":"pulse","event":"refused","reason":…}` as well as in the message strip. The two usual reasons are that the session is not armed, and that the stimulator interlock is holding it — no coil, not charged, over temperature, or the stimulator's status stream has not published |
| **The trigger fired but nothing left the machine** | Read `Trigger out` in the run bar. Its state — `off` / `COM8 (not open)` / `COM8 open` — is also published on the `events` stream as `{"type":"trigger","event":"state",…}` on every change, and as `triggerOutReady` on the `status` stream, so a recording afterwards can be asked whether the port was open at the time. ⚠ **Editing any parameter re-applies the trigger configuration, and that can close an open port mid-session** — the event says `why: "reconfigured WHILE ARMED"` when it does |

---


<a id="history-10-one-recommendation-from-the-validation"></a>

## 10. One recommendation, from the validation

**Turn the continuous highpass on at 1 Hz.**

The shipped configuration has it off, and the epochs therefore carry the amplifier's DC offset —
about half a millivolt on the EMG difference. Nothing about the live display cares. The **offline**
analysis does: `logic/mep_movement_detection.py` band-passes each epoch from a cold start, so a
DC step of that size produces a transient at the beginning of every epoch four times larger than
the real response, and the movement detector reports "movement at −100 ms" in **every single
trial**. That is measured, in
`report_tep-service-validation.md` §6a (on the lab drive, `R:\docs\_notes\`) — with the offset removed the same
detector on the same epochs finds movement in 26 of 75 with sensible onsets.

The lab's own note file already says so. `R:\dist_legacy\TEP_visualization\notes`, in full:

> Для ЭМГ: highpass 1 Hz — must have

Set **Highpass** on in the `filter` group, at 1 Hz. It applies to the continuous stream, before
the epoch is cut, so it costs nothing per epoch and the epoch file comes out without the step.

---


<a id="history-11-the-tepsound-console--four-views"></a>

## 11. The tepSound console — four views

⚠ **This section is about `tepSoundService`, not `tepService`.** The console described in §3 is
`tepService`'s and is unchanged. `tepSoundService` presents cues, fires the pulse and cleans with
SOUND in one process, and its console is split into four views of the same session.

**From here to the end of the guide the program is `tepSoundService`, and both distributions carry
it.** `R:\dist\tepSoundService.bat` is the Qt 6 build and the default — ⚠ but until the NVX-136 and
Neuro-MS regressions clear, a session with either of those devices runs the whole chain, this
console included, from `R:\dist_Qt5\msvc64`
([`build_qt5-to-qt6-transition.md`](../history/migrations/qt5-to-qt6-transition.md)). These pages describe both, and
they can: the console's QML was already Qt Quick Controls 2 under Qt 5, so nothing you *see* moved.
The Qt 6 build pins the **Basic** Controls style to keep the Qt 5 layout, and a parity run on
2026-08-28 found the two consoles' screenshots the same size with the same four views, run bar,
counters and plot subdivision, and the same 135 parameter names under one SHA-256
(`R:\src\docs\VALIDATION.md`, "2026-08-28 tepSoundService validation"). What did move is underneath
the pictures: the media backend (§14b) and the video-cue onset guarantee (§11.1.1), both flagged
where they belong.

One bar under the run bar switches them. `Ctrl+1`…`Ctrl+4` do the same, in the order shown. The
choice is remembered between runs; it is **not** a session parameter, so it never reaches a saved
configuration or the Configurator.

| View | | What is on it |
|---|---|---|
| **Stimuli** | `Ctrl+1` | ⭐ The experiment, authored: one table of stimuli, the selected row’s editor and its triggers, the sequence box and the background pattern, the session settings, and the live estimate and validation report |
| **Processing** | `Ctrl+2` | The chain diagram — every stage a sample passes through, with its settings and what it costs — over six columns holding every processing setting |
| **Visualization** | `Ctrl+3` | The plots you watch while responses come in: scalp grid, TEP, MEP average, MEP single trials, the epoch table, the cap report. **This is the default view** |
| **Feedback** | `Ctrl+4` | The subject-facing verdict mark, and the two empty boxes where a classifier will go |

The run bar, the message strip, the warning strip, the status strip and every dialog stay on
screen in all four. **Stop is always reachable**, and so is the trigger-polarity readout.

<a id="history-111-the-stimuli-tab--authoring-an-experiment"></a>

### 11.1 The Stimuli tab — authoring an experiment

The whole experiment is defined here. There is no JSON to edit: what you type is the experiment,
and `Save` writes it to a `.tep.json` file carrying every row, every trigger, the sequence and the
seed. `Import old` reads a legacy `protocols/*.json` once and turns it into rows.

Five bands, top to bottom, in the order the questions get asked.

<a id="history-the-table"></a>

#### The table

**One row is one stimulus.** What it shows, how long it shows it, what marker it stamps and what
goes out of the box — all on the same row.

| Column | |
|---|---|
| `#` | the number the sequence refers to. `▶` is the welcome screen, `■` the end screen, `✚` **the interval between stimuli — it has no number and the sequence cannot name it** |
| `label` | your name for it; it goes into the recording |
| `medium` | blank, text, image, video or audio |
| `what is shown` | the text, the file name, or the colour |
| `duration` | one number if fixed, `1.80–2.20 s` if jittered |
| `mark` | the marker stamped on the recording. This is what a later analysis bins on |
| `trg` | how many triggers hang off this row |
| `×` | how many times the generator draws it. The interval carries the word **between** here instead of a count: it is not drawn, it is placed |

Buttons: `+ stimulus`, `Duplicate`, `Delete`, `↑` `↓` to reorder, and `Welcome` / `Between` /
`End` for the three rows that are not part of the sequence. If one of them does not exist yet,
selecting it offers to create it.

⚠ **`+ ISI` is gone, and `Between` replaces it.** The interval between stimuli used to be an
ordinary table row with a number, a repetition count and a place in the sequence — so the
generator drew it into the same pool as the cues, and `generator.isiNumber` was a second,
contradictory answer to the same question. It is now one record per document, outside the table,
with no number the sequence can print, placed automatically between every consecutive pair and
never after the last. **A hand-typed sequence gets the gaps too**: `1, 2, 3` is three stimuli and
five steps. Opening a document written before this change says, in the message strip, exactly
what it revoked.

⚠ **Deleting a row renumbers the table AND rewrites the sequence.** Entries naming the deleted row
are dropped, everything else keeps meaning what it meant, and the console says how many went.

Select a row and the right-hand panel fills with its settings: medium, file, text, colour, seek-in,
duration range, "hold for the media's own length", what it waits for, marker, repetitions, whether
the background pattern may fire during it, and its trigger list.

⚠ **`Start at` and `hold for the media's own length` are per-medium and only exist for video and
audio.** An image is a file and has no length; text and blank have neither. Both controls now
disappear for those media, and **changing a row's medium clears what the new medium cannot mean**
and says so in the message strip:

`stimulus 1 is now text, which has no media length — cleared "hold for the media's own length"`

Before this, the flag survived the change and was invisible: the planner then asked a PNG how long
it was, got nothing, and armed the row at a duration nobody had chosen.

<a id="history-the-sequence-box"></a>

#### The sequence box

⭐ **One box, whether the generator wrote it or you pasted it.** It holds the order as plain
numbers — `3, 2, 3, 2, 1, 2, 3, 2, …` — and you can edit it by hand at any time.

| Control | |
|---|---|
| `Generate` | draw a new order from the pool and write it into the box |
| mode | `shuffle` (one permutation of the pool) or `block` (balanced blocks, each shuffled) |
| `block` | trials per block. The pool must divide into whole balanced blocks or the generator refuses and says by how much |
| `max run` | no more than this many identical trials in a row. A plain shuffle produces runs of five |
| `not first` / `not last` | stimulus numbers barred from the ends |
| `seed` | the number that reproduces this run. Write it down |
| `New` | draw a **new** seed — this re-draws the order, every jittered duration, every trigger offset and every background beat |

⚠ **`ISI between` is gone from this box, and there is nothing to replace it with.** It used to name
which table row to interleave. There is one interval per document now, it is not a table row, and
there is nothing to choose between — if the document has an interval it goes between every
consecutive pair, always, and never after the last. `Between` (in the table's button row) is where
you create it, remove it, and set its duration. The caption under the box states the arithmetic:
`3 stimuli · 5 steps with the interval between them`.

The generator is a **constrained randomisation**, not a uniform sample of all valid orders: it
draws position by position and restarts on a dead end. A design it cannot satisfy is **refused by
name with the arithmetic in the sentence**, never approximated and never looped on.

<a id="history-triggers"></a>

#### Triggers

Each row carries a list of output events, each hung off **that row's own onset** — the frame the
subject actually saw it, not the moment the software decided to show it.

| Field | |
|---|---|
| backend | `serial` (a TTL box on a COM port), `udp` (a datagram to a peer such as feetStim), `transition` / `parameter` (another service) |
| target | a COM port, a `host:port`, or a service name |
| code | looked up in the **Trigger map** (below) |
| `at a – b ms` | the offset window. Equal numbers mean a fixed offset |
| `p` | probability, 0–1, drawn once per occurrence |
| `min gap` | the minimum this wire will schedule two pulses at. 500 ms for serial, 10 ms for the message backends |
| `board-timed remainder` | serial only: hand the sub-frame remainder to the board's own `@<ms>` delay |
| `Test` | ⭐ fire this trigger **now**, with no stimulus and no subject, to prove the wiring |

The worked example is two triggers on one cue: `10–80 ms` at `p 1.00`, and `100–500 ms` at
`p 0.50`. A row may mix backends — a COM pulse and a UDP datagram on the same cue both go out, on
their own wires.

⚠ **`serial` is the only backend proven on hardware**, and the only one with a board timer. The
others go through another process's event loop, so their latency is neither small nor bounded.

⚠ **Every offset is drawn before Arm, from the seed, and written into the recording** — including
the ones whose coin came up tails. A trigger that fired at a random time nobody logged is unusable
data. The `plan` event published before the first cue carries the whole draw.

<a id="history-the-trigger-map"></a>

#### The trigger map

A trigger's `code` is looked up in a map of `code=command` lines, one per line, in the backend's own
language: `2:P1` pulses arduinoTTL's BNC2, `_Gp1` is a feetStim datagram. Click the map summary
under **Trigger out** to edit it.

⚠ **The map is a service setting, not part of the experiment file.** Opening a `.tep.json` on
another rig brings the codes but not their meanings. Every code with no line is refused at Arm by
name — check the map after opening an experiment the machine did not author.

<a id="history-the-background-pattern"></a>

#### The background pattern

A pulse train independent of the cues — "TMS goes off every 1.9–2.1 s for the whole run". It has
its own wire, its own period range (`every 1900 – 2100 ms`, drawn per beat), and **two offsets that
keep it clear of the run's two edges**:

`clear [0] ms from start   and   [0] ms before end`

That is the whole gate. The pattern beats inside `[lead-in, run length − lead-out)` and nothing
else stops it. When either offset is non-zero the period row reads the pair back **in periods** —
`clear 2.1 + 1.6 periods` — because "two periods clear from the end" is how the question is
normally asked, but the offsets themselves are stored in **milliseconds**: a period here is a
*range*, so "two periods" has no single millisecond value, and an offset held in periods would
move on its own every time the period was retuned. The readout takes the **short** end of the
range, which is the conservative reading.

⚠ **The three phase switches are gone** — `during ISI`, `during welcome`, `during end`. They were a
second, contradictory answer to "when may this fire": three booleans about named phases, alongside
a start delay measured in milliseconds. What is left of them is per row: `the pattern may fire
during this row`, which is off by default on the welcome and end rows, so the old default
behaviour is unchanged. Opening a document written before this change carries each old boolean onto
the row it was about, and says so in the message strip. A `during ISI: false` in a document with no
interval has nowhere to go and says that too.

⚠ **Offsets that meet are a refusal, not a warning.** A lead-in and a lead-out that overlap inside
the run leave the pattern switched on and provably silent — which is an empty column in the
analysis three weeks later. The panel says `these two meet inside a 41.5 s run — the pattern would
never fire` beside the numbers, and `Arm` stays grey.

⚠ **Collisions.** Two pulses on different wires never collide. On one wire, a background beat
landing within the minimum gap of a cue trigger is **dropped and recorded** — the pattern keeps its
own phase, so it does not drift because a cue happened. Two **cue** triggers, or two background
beats, inside the minimum gap are a **refusal at Arm**, named with both and the gap.

<a id="history-before-arming"></a>

#### Before arming

`This run` gives the step count, a live **duration estimate** (a range, because of the jitter), the
number of cue pulses and the number of background beats.

`Before arming` lists every problem. **✕** is a refusal and `Arm` stays grey; **⚠** is worth saying
and does not stop the session. `Validate` re-checks everything from scratch, re-reading the disk
rather than a memo. `Preview` shows the selected row on the subject's screen, firing nothing.

What refuses a session: a media file missing, changed since it was added, or undecodable; a text
row with no text; a trigger with no code, an unmapped code, a dead COM port, a UDP peer that does
not answer, or an offset window that can outlast the row's own shortest duration; a sequence naming
a row that no longer exists; a background period shorter than its wire allows; a background lead-in
and lead-out that meet inside the run; and **a row set to hold for the media's own length whose
file opens but does not report one** —

`stimulus 2 is set to hold for the media's own length, and clip.mkv opens but does not report one
— untick it and set a duration`

⚠ That last one used to be a warning, and it mattered: ticking the box greys the duration range
out, so when the length is unknown the number the planner falls back to is one the operator cannot
see and did not choose. Two shipped clips in `operator-demo.tep.json` still record a length of `0`
from the DirectShow era; a recorded `0` is now read as "never measured", not as "zero long", and
either the probe at `Validate` supplies a real length or the row is refused.

<a id="history-1111-video"></a>

### 11.1.1 Video

⚠ **This section used to say "video needs a codec pack" and to tell you to install LAV Filters and
set `QT_MULTIMEDIA_PREFERRED_PLUGINS=directshow`. Both were wrong, and the second one is exactly
backwards.** That measurement was taken with the backend unpinned, which meant it was measuring
DirectShow — which decodes **nothing** here, `.mp4` included. **Install nothing.** The full
measurement, over all 34 clips, and the one-line remux that fixes the 23 files that do fail, are in
**§14b**.

Two things that were right and still are:

⚠ **Prove it once on the rig before a subject is in the chair.** Add a video row and press
`Validate`. Validation requires the decoder to report a positive duration, so a backend that loads
a file it cannot draw is caught here rather than in front of a subject. If a video row does arm and
the screen stays black, the run aborts itself rather than continuing.

⚠ **A video cue's onset is its first decoded frame**, not the moment `play()` returned. Trigger
offsets are measured from that frame, and nothing is armed until it arrives.

⚠ **2026-09-02 — in `R:\dist` the black-screen abort is weaker than the paragraph above says.**
Qt 5 counted a frame only when the QML video output *accepted* it, so a surface that refused the
format produced no count and the stage stalled loudly. The Qt 6 build counts any valid frame
arriving at the `QVideoSink`, upstream of anything the output decides, so a rendering-side refusal
can read as a **clean onset**: the trigger fires on schedule while the subject sees black. Nothing
has observed this and nothing has ruled it out — no recorded Qt 6 run has loaded a video row at
all. Until one has, prove a video cue on the rig with eyes on the subject screen
([`arch_qt6-work-list.md` §2](../history/migrations/qt6-work-list.md)).

<a id="history-112-the-chain-diagram-processing"></a>

### 11.2 The chain diagram (Processing)

Every card carries a latency **and the class of that latency**:

| | |
|---|---|
| **measured** | off this rig, or a bench figure written down |
| **derived** | exact by construction — a cut, a rate change, a subtraction |
| **unmeasured** | nobody has characterised it. **Not** a claim that it is small |

The two continuous Butterworths, the ICA repair and SOUND itself read `unmeasured`, and that is
deliberate. The anti-alias FIR reads `0 ms` with its group delay printed beside it: it is
zero-phase and runs inside the guard, so it spends guard, not latency.

⚠ **The `+20 ms` at the foot of the diagram is signalViewer's, not this chain's.** tepSound
applies no display filter. The same epoch read through signalViewer's default display filter is
20 ms late — measured. It has already once been read as an alignment bug.

Clicking a card fills the strip below it and outlines the settings column that configures it.
The settings do not scroll; the diagram does.

<a id="history-113-feedback"></a>

### 11.3 Feedback

`Verdict source` has five settings. Four are placeholders and one is real.

| source | what decides the mark |
|---|---|
| `alternating` (default) | a counter — check, cross, check, cross |
| `random` | a coin, at `Correct rate` |
| `always correct` / `always wrong` | fixed |
| `classifier` | **the LDA of §11.4, applied to the epoch that just landed** |

⚠ **The four placeholders read nothing about the epoch.** They are not derived from the MEP, the
threshold, or anything else measured. The panel says so in amber whenever one of them is armed.

⚠ With `classifier` selected and no model loaded or fitted, **the subject is shown nothing**. There
is no fallback to a placeholder, and a warning strip says so.

`Show verdict to subject` is **off by default**, and while it is off nothing is computed and the
subject's screen is byte-identical to a build without the feature. `Test ✓` / `Test ✗` are refused
while it is off, and say so.

When armed, a mark appears on the subject's screen `Delay` ms after the epoch is delivered and is
held for `Hold` ms. ⚠ **`Delay` defaults to 3000 ms**, which places the mark in the gap after a 7 s
cue; a protocol with a shorter cue will put it inside the cue.

<a id="history-114-the-classifier"></a>

### 11.4 The classifier

A two-class regularised LDA over TEPs — `hand` vs `rest` in the example the panel ships with.

**Turning it on.** `Collect trials` starts it gathering. `Class A` and `Class B` are the two label
strings it looks for; an epoch whose label is neither is counted as `not one of the two classes`
and ignored. It fits when `Warm-up per class` trials of each class have arrived, and refits every
`Refit every` trials after that.

**What it measures.** The mean amplitude of each channel over each of five intervals —
`20-40, 40-55, 55-80, 85-140, 150-250 ms`, the TEP's own components. With 64 channels that is
**320 features**. The panel prints the count against the number of trials, because with the default
window of 40 per class there are more dimensions than trials.

⚠ **There is deliberately no feature before 20 ms.** The TMS interpolation writes −2…+10 ms and its
decay runs past that; a feature there measures the interpolator, not the brain. If you move
`Intervals` earlier the panel says so.

**The window is rolling.** `Trials per class` (default 40) is how many of each class are kept. The
oldest are dropped, and every refit is from the retained set only — the panel shows
`retained of ... seen` so the two numbers are never confused.

**Regularization.** Ledoit-Wolf shrinkage toward a scaled identity. There is nothing to tune. The
coefficient γ is printed on the panel, in the fit event, and in the saved file. **γ near 1 means the
covariance told it almost nothing** and the classifier has fallen back to a distance-to-mean rule.

**The accuracy figure is always out-of-sample.**

`66.3 % out of sample (±9.2 across folds) · AUC 0.729 · majority class 50.0 % · 5-fold, stratified,
folds cut on cue interval (20 groups); refitted inside every fold`

⚠ Compare it against the **majority class**, not against 50 %. With unequal classes the majority
class is what guessing scores.

⚠ **Folds are cut on the cue interval, not on the trial.** Several pulses inside one cue share a
label and are correlated; folds cut on the trial put siblings on both sides of the split and report
that correlation as performance. If the panel shows no figure it is because there was no
cross-validation — **it never falls back to accuracy on the training trials**.

**Save and load.** `Save…` writes a JSON model carrying the subject, the condition, the session,
the number of trials per class, the complete feature definition and γ. `Load…` reads one back, so a
model fitted on one recording can be tested on another.

⚠ **A classifier is subject-specific.** Loading a model fitted on a different subject warns, on the
panel and in the run bar:

`CROSS-SUBJECT: this model was fitted on '01AV' and the session is '02NS'. A classifier is
subject-specific — what this measures is transfer, not performance.`

It also warns when either side records no subject at all, and when the feature definition of the
model does not match the session's.

**What to expect.** On the ten reference recordings, within-session grouped 5-fold accuracy ranged
**52 – 76 %** (mean 60 %) using every trial, and **44 – 68 %** (mean 57 %) with the shipped 40-per-class
window. Fitting on one session and applying to the same subject's other session gave **50 – 71 %**
(mean 63 %). One subject sat at chance. These are the numbers as measured; nothing has been tuned.


<a id="history-12-stimulus-attribution-and-the-stimulus-grouped-view"></a>

## 12. Stimulus attribution and the stimulus-grouped view

This is in the **signal viewer's epoch display**, not in the tepSound console.

<a id="history-121-what-it-is-for"></a>

### 12.1 What it is for

When cues run in blocks and TMS fires on its own schedule, a pulse has to be attributed to whichever
cue was in force. Doing that by timestamp does not work on this rig — the real-time clock is good to
about ±2.5 s, wider than the gap between pulses. The attribution uses the **frame counter** the
stimulus stage stamps on both its cue and its pulse records, which is exact.

<a id="history-122-the-perception-latency"></a>

### 12.2 The perception latency

⚠ **This parameter decides which condition a trial lands in.**

`Perception … ms` on the epoch toolbar. A pulse that lands **less than this after a cue onset is
attributed to the interval before it**, because the subject has not perceived the new cue yet.

**Default 150 ms.** That is the earliest latency at which a visual cue's *identity* is demonstrably
influencing the brain (Thorpe, Fize & Marlot, *Nature* 381:520-522, 1996). Earlier responses exist —
striate cortex is reached at 50-60 ms — but they are driven by luminance and contrast, not by which
cue it was.

⚠ **150 ms is a number for a VISUAL cue.** An auditory cue is faster, a somatosensory one faster
still. Lower it for those.

The value is written into every epoch announcement and into the session settings, so a recorded
session says which number decided its conditions. Changing it republishes the stream. **Epochs
already filed are not re-binned.**

<a id="history-123-turning-it-on"></a>

### 12.3 Turning it on

| control | what it does |
|---|---|
| `Attribute` | label epochs from the stimulus service's cue and pulse records instead of from the marker stream |
| `By stimulus` | one trace per stimulus type, each averaged in its own bin |
| `Perception … ms` | the latency above; shown only while `Attribute` is on |

The readout beside them — `3 types, 15 excluded` — is live.

<a id="history-124-what-is-excluded"></a>

### 12.4 What is excluded

⚠ **ISI is not drawn at all**, and neither is the welcome screen, the goodbye screen, anything
before the first cue, or anything after the run ends. They are not a stimulus, so they are not a
bin.

The caption under the array states the whole result:

`by stimulus: cue_a n = 23  cue_b n = 24  cue_c n = 27  [every type present]  map & published: cue_a
| 15 excluded as ISI or run edge  mean  labels=attribution 150 ms`

— which types are drawn, **n for each**, and **how many epochs were excluded**. Read the excluded
count. It is the difference between the average you think you have and the one you have.

⚠ **The scalp map and anything published describe the FIRST type drawn**, named in the caption after
`map & published:`. A scalp field is one number per electrode; several conditions would be several
maps.

⚠ **If the traces are solid blocks of colour, press `Fit`.** A viewer with no stored amplitude scale
draws every trace hard against the top and bottom of its row. This is not particular to
`By stimulus` — a single-epoch view with no scale does the same — and `Fit` fixes it in both.


<a id="history-13-where-the-settings-moved"></a>

## 13. Where the settings moved

The Visualization view's settings column has been removed. Nine of its groups already existed on
Processing or Stimuli; the rest moved:

| setting | now on |
|---|---|
| `Epoch file`, `Save on stop` | **Stimuli · Session** |
| `Average of`, `Over all`, `Over last` | **Processing · Epoch & average**, beside `Average by` and `Trim` |
| `Init` (the trigger port's init string) | **Stimuli · Trigger out** |
| `Fallback` protocol | **Stimuli · This run** — it says whether it is in force |
| Auto-fit, fit interval, scalp colours | stayed on **Visualization** |

The average's definition is no longer editable from Visualization, but the panel title states it —
`TEP · average · cleaned · last 200` — so the picture says what it is.

---


<a id="history-14-the-subject-screen-the-photodiode-patch-and-video-that-will-not-play"></a>

## 14. The subject screen: the photodiode patch, and video that will not play

<a id="history-14a-the-photodiode-patch-is-now-in-the-upper-right-and-there-is-a-control-for-it"></a>

### 14a. The photodiode patch is now in the UPPER RIGHT, and there is a control for it

The patch is the small square that inverts black↔white on every cue onset. Tape the sensor over
it and the recording carries the true onset — the light, not the software's intention — which is
the only thing that measures the constant compositor-and-panel offset.

**It used to be drawn bottom-right.** Not by choice: `protocols/tms-cue-block.json` line 37 said
`"photodiode": "bottom-right"`, and there was no control anywhere that could move it. Three things
changed:

* every shipped document now says `top-right` — `tms-cue-block.json`, `operator-demo.tep.json`,
  and `stimulusService`'s two motor-imagery protocols;
* the built-in default is `top-right` as well, and it is now **on** rather than `none`, so a
  document that never mentions the subject screen still records its own onsets;
* **Stimuli → Subject screen** now carries `Photodiode`, its size, `Fixation` and `Background`.
  The corner is a five-way choice: `none`, `top-left`, `top-right`, `bottom-left`,
  `bottom-right`.

⚠ Those four controls edit the **authored document**. When a JSON protocol is being presented
instead, that file owns the subject screen: the values are shown but not editable, and a line
under them says so.

The patch is identical for **every** medium — text, image, video, audio and blank alike. It is
decoration on the stage at `z: 100`, a sibling of the cue layers rather than a child, and the
video path is not an exception: `VideoCue` feeds `VideoOutput` through a video-surface relay, so
frames become scene-graph nodes inside a layer at `z: 0` and the patch composites on top of them.
Verified with pixels on a 1920×1080 clip.

**On this rig the sensor is on trigger bit 2**, which is a different bit from the TMS trigger on
bit 0. Both are recorded at once, in the same trigger word.

⚠ **Which bit the sensor lands on is a fact about your wiring, not a setting.** tepSound does not
detect, count or display a photodiode edge, and there is no photodiode-bit parameter: bit 2 is
read out of the recording afterwards. The only bit the service itself reads is `Trigger bit`
(Stimuli → Trigger in), which selects which bit **cuts an epoch**, and it stays at **0** for the
TMS pulse. Do not move `Trigger bit` to 2 — that would cut epochs on the screen instead of on the
coil. If the sensor is moved to another bit, nothing in the console needs changing, and nothing in
the console will notice.

<a id="history-14b-video-what-to-install-on-the-lab-pc--nothing"></a>

### 14b. Video: what to install on the lab PC — nothing

⚠ **2026-09-02 — the backend below is the Qt 5 one, and the Qt 6 build in `R:\dist` uses a
different one.** Qt 6 removed the `QT_MULTIMEDIA_PREFERRED_PLUGINS` selector; the Qt 6 tepSound
pins `QT_MEDIA_BACKEND=ffmpeg` in `main()` before the application exists, and
`qt\plugins\multimedia\ffmpegmediaplugin.dll` ships in the distribution. Its source records that
FFmpeg decodes the whole laboratory stimulus set including raw PCM inside Matroska, which is
exactly what Media Foundation refuses — **but the 34-file sweep below has not been re-run against
it**, so treat the remux advice as still standing until it has. ⚠ More than that: no recorded Qt 6
run has yet loaded a video row at all, so the Qt 6 onset behaviour of a video cue is unmeasured
([`arch_qt6-work-list.md` §2](../history/migrations/qt6-work-list.md)). The two conclusions that do carry
over unchanged: nothing has to be installed on the lab PC, and a remux is never a re-encode.
Everything from here to the end of §14b is the Qt 5 measurement, kept because it is the evidence.

Measured on this machine 2026-08-25, against the then-shipped `qt\` folder — the tree now at
`R:\dist_Qt5\msvc64` — over all 34 clips in the stimulus directory. The full sweep is in
`R:\dist_Qt5\_build\stagefix\sweep_wmf.txt`.

| what | result |
|---|---|
| all 9 `.mp4` | **play** |
| `countdownLight__blackTrigger.mkv`, `countdownLight__whiteTrigger.mkv` | **play** |
| the other 23 `.mkv` | refused, `FormatError` |

The split is exact and has no exception. The 23 that fail all carry `A_PCM/INT/LIT` — a **raw-PCM
audio track inside Matroska** — read straight out of the file headers; the two that work carry a
video track and nothing else. Windows' own Matroska reader will not accept raw PCM and refuses the
whole file over it, including the picture.

So **nothing has to be installed on the lab PC**. Windows 10 and 11 already decode H.264 in both
MP4 and Matroska. Two earlier answers were wrong and should not be repeated:

* *"install LAV Filters and set `QT_MULTIMEDIA_PREFERRED_PLUGINS=directshow`"* — backwards.
  DirectShow decodes **nothing** here, `.mp4` included: every load answers `0x80040266`,
  `VFW_E_UNSUPPORTED_STREAM`.
* *"nothing decodes under Media Foundation either, so a codec pack is mandatory"* — that
  measurement was taken with the backend unpinned, which means it was measuring DirectShow.

**To fix the 23 files, remux them once.** This is a stream copy: not a re-encode, so every video
frame and its timing are bit-identical, and FLAC is lossless, so the audio comes back sample for
sample. Nothing about the stimulus changes.

```
ffmpeg -i in.mkv -c:v copy -c:a flac out.mkv
```

Verified: the output loads and plays. `-c:a aac` into `.mp4` also works but is lossy and the
encoder inserts its own priming delay, so do not use it for a clip whose click has to land on a
known sample. A clip with no audio at all (`-an`) plays as well.

If a file still refuses after that, the console says which backend it is on: one line, written the
first time a video row is loaded — `findstr /i "media backend"` over the service's stderr.

| build | the line | what you want to see |
|---|---|---|
| `R:\dist` (Qt 6) | `TepSound Qt 6 media backend: …` | **`ffmpeg`**. Anything else means something set `QT_MEDIA_BACKEND` first. ⚠ The line echoes the backend that was *asked for* — it prints `QT_MEDIA_BACKEND`, not the plugin Qt loaded — and both `ffmpegmediaplugin.dll` and `windowsmediaplugin.dll` sit in `qt\plugins\multimedia\` |
| `R:\dist_Qt5\msvc64` (Qt 5) | `TepSound media backend: … (QT_MULTIMEDIA_PREFERRED_PLUGINS=…)` | **`MFPlayerService`**, which is Media Foundation. `DirectShowPlayerService` is not |

---


<a id="history-15-where-the-file-dialogs-open"></a>

## 15. Where the file dialogs open

Every launcher does `cd bin` before it starts a program, so until 2026-08-25 **every** Save and
Open dialog in Resonance opened among the DLLs — the Configurator's `Save`/`Load` parameter
buttons, `Record to file`, tepSound's experiment and media choosers, the classifier's `Save…` and
`Load…`. It was not the dialogs; it was the working directory.

They no longer use the working directory at all. Each one opens in the folder that kind of file
lives in, derived from the program's own location (`bin\..`):

| Dialog | Opens in |
|---|---|
| Configurator `Save` / `Load` (parameters) | `params\` |
| `Record to file`, `Record to auto file` | `data\` |
| A `.ced` electrode layout | `montages\` |
| tepSound `Save` / `Open` experiment, `Import old` | `protocols\` |
| tepSound's media chooser | `stimuli\` |
| classifier `Save…` / `Load…` | `data\` |

**Each one remembers where you last went, for the rest of the session.** Save and Load share one
memory, so loading a file out of `protocols\` and then pressing Save offers `protocols\`.

`env.bat` sets `RESONANCE_RECORD_PATH`, `RESONANCE_PARAMS_PATH`, `RESONANCE_PROTOCOLS_PATH`,
`RESONANCE_STIMULI_PATH`, `RESONANCE_MONTAGES_PATH` and `RESONANCE_CALIB_PATH`. **None of them is
required** — with all six unset the dialogs still land correctly, which matters because on at
least one PC here `env.bat` never runs at all (`NoDefaultCurrentDirectoryInExePath` stops
`call env` from resolving). ⚠ **That trap is a `R:\dist_Qt5\msvc64` one and is fixed in
`R:\dist`:** the Qt 6 launchers say `call "%~dp0env.bat"` and `cd /d "%RESONANCE_DIR%\bin"`, which
resolve from the launcher's own directory and do not depend on the current one. The Qt 5 launchers
still say bare `call env` / `cd bin`. Set a variable only to move that folder elsewhere: a data
drive for recordings, a shared `params\` on the network. A relative value already stored in a
parameter —
`protocols/tms-cue-block.json`, `montages/mks64_standard.ced` — is resolved against the same
folder the chooser opens in, so the browse button and the loader cannot disagree.
