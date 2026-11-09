# Epoch support in the signal viewer — design proposal — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../architecture/epochs.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-epoch-support-in-the-signal-viewer--design-proposal"></a>


**Written 2026-08-19. Status: design SETTLED (§8); Stage 0 IMPLEMENTED and PROVEN LIVE.** Read
[service_signal-viewer.md](../components/signal-viewer.md) for the viewer as it stands and
[service_tep.md](../components/tep.md) §2 for the pipeline this borrows from.

Five features were asked for: native epoch display across the full plot width; a butterfly in
collapsed mode; a head-shaped array of epoch traces; two linked viewer instances driving an
interpolated topoplot; and real-time averaging with an optional output stream. Plus one direct
question, answered in §0.

Every claim below carries a `file:line`. The two load-bearing ones (§0) were re-read by hand
after the survey, not taken on trust.

---


<a id="history-0-what-the-epoch-type-actually-carries--the-answer"></a>

## 0. What the epoch "type" actually carries — the answer

**There is no epoch type. There is no time vector. There is no epoch-relative offset. And the
record cannot grow one.**

An epoch stream is a plain `Float64`. The entire data record is four fields
(`Protocol/protocol_definition.hpp:91-96`):

```
RECORD(Float64, FIELD(created, uint64_t) FIELD(received, uint64_t)
                FIELD(samples, uint32_t) VECTOR(data, double))
```

and the entire *type* is two (`:116-119`):

```
RECORD(ConnectionHeader_Float64, FIELD(channels, uint32_t) FIELD(samplingRate, double))
```

So negative pre-stimulus time is **unrepresentable on the wire today**, in any form. Four
consequences worth having in one place:

| | |
|---|---|
| No channel count in the block | it is only in the connection header, and the sample count is derived by division (`TimeSeriesHelper.cpp:48-49`). A block is meaningless without its `StreamInfo`. |
| Block length is fully variable | nothing in the type fixes it, so variable-length epochs are already wire-legal. Only their **alignment** is unexpressible. |
| Samples are sample-major | `index = sample*channels + channel` (`TimeSeriesHelper.cpp:58-62`, `nvx136driver.cpp:675-682`). Every epoch consumer wants the transpose. |
| `tepService` knows where t=0 is and never says | `zeroSample` is computed at `pipeline.cpp:71`, declared at `pipeline.hpp:145`, and a grep for it across `R:\src` returns only tepService, tepSoundService and their tests. Nothing in `Core`. |

<a id="history--created-already-means-three-different-things-and-nothing-on-the-wire-says-which"></a>

### ⚠ `created` already means three different things, and nothing on the wire says which

This is the trap underneath the question. `Float64::fromBinary` substitutes `RTC::now()` when the
caller passes 0 (`Float64.cpp:58-59`), and callers disagree:

| Producer | `created` is | Evidence |
|---|---|---|
| every hardware driver | `RTC::now()` **after** the samples were collected — so roughly the last sample | `nvx136driver.cpp:699`, `nvx/nvxdatathread.cpp:674`, `DAQmx/driver.cpp:45`, `KARDi2/driver.cpp:416` (all pass 0) |
| `signalGenerator` | the scheduled instant of the block's **first** sample | `lane.cpp:259-275` — `due = m_startRtc + period*m_blockIndex`, computed before the samples |
| `tepService`, `tepSoundService` | the **trigger** instant, which sits *inside* the block at index `zeroSample` | `service.cpp:1415-1419`, `service_analysis.cpp:719` |

So t0's absolute instant is *already* on the wire for an epoch stream — `created` is it. What is
missing is **where in the block it falls**, and there is no per-block start time to subtract it
from. That one number is the whole gap, and §1 is how it gets carried.

<a id="history--do-not-add-a-field-to-the-record"></a>

### ⚠ Do not add a field to the record

`thir` has no field tags and no version byte. Offsets are compile-time positional
(`3dparty/thir/thir/classes.hpp:137-155`) and the socket reader sizes each record from a static
per-id table (`classes.imp.hpp:16-41`). Record ids are `position+1` (`generate.hpp:172-176`).

Adding a field to `Float64` or to its connection header is therefore a **silent mis-framing break
with no diagnostic** — an old peer computes the wrong length and desynchronises the byte stream
from the first block onward. It would also change the HDF5 `BlockInfo` compound
(`HDFRecorder.cpp:129-137`) and invalidate the base64 `serializedType` in every saved config
(`streaminfo.cpp:200-206`). This is the option that looks most correct and is most catastrophic.

---


<a id="history-1-the-contract-five-metadata-keys-zero-framework-change"></a>

## 1. The contract: five metadata keys, zero framework change

`StreamInfo::MetaData` is the only additive channel in the framework, and it is additive for a
reason that is checkable rather than hoped for:

* it rides as arbitrary JSON inside a thir `ANY` field, in **both** places it must — the connection
  header (`ConnectionHeaderContainer`, `protocol_definition.hpp:126-131`) and the EventBus service
  description (`EventBus_Description_Stream`, `:37-42`). The JSON codec is generic
  (`jsonprotocol.cpp:55-124`), so a new key needs no protocol edit, no record id, no header change;
* ⭐ **`metaData` is excluded from `isSimilar()`** (`streaminfo.cpp:211-271`), so a missing, extra or
  malformed key **can never fail a connection**. No other carrier has that property;
* it is persisted into HDF5 for free through `temporary_as_json` (`HDFRecorder.cpp:106-108`).

Five keys, one per channel. ⚠ Every value below was tightened by the Stage 0 review — three of the
five were ambiguous enough that three agents implementing the same contract produced three different
readings. The table is now the settled wording.

| key | type | meaning |
|---|---|---|
| `window_start_ms` | double | where the epoch opens relative to the stimulus; negative for a pre-stimulus window. **Its presence is the declaration that the stream is epoched.** |
| `window_end_ms` | double | the **exclusive** (half-open) edge, so that `(end − start)/1000 × rate == samples` **exactly**. |
| `epoch_kind` | string | `trial` \| `average`. ⚠ Not optional — see §7.1. |
| `epoch_stage` | string | `raw` \| `preprocessed` \| `cleaned`. Absent means single-stage. |
| `epoch_stamp` | string | what the block's `created` refers to: `trigger` \| `first` \| `last` \| **`none`**. **Required** on an epoched stream. |

**`window_end_ms` is exclusive** because two of the three producers already read it that way and it
makes the epoch length recoverable from the window with no off-by-one. The inclusive reading costs a
sample: a consumer sizing `n = round((end−start)/1000×rate)` against an inclusive producer gets 700
for a 701-sample block, dropping one sample of every epoch with no diagnostic.

**Unit strings are ASCII, enumerated:** `V`, `mV`, `uV`, `Ohm`, `bitfield`, `""`. ⚠ Microvolts is
`uV` with an ASCII `u`, never U+00B5. Two agents independently chose two spellings for the same
physical unit on two streams meant for one consumer — and since string-matching is the entire purpose
of the key, one spelling *is* the point. It is also the safer family-wide choice: a non-ASCII narrow
literal is only safe in a module passing `/utf-8`, and this tree has been bitten by that twice
already (§14i, §13 "Also worth knowing").

**`epoch_stamp` is required, and `none` is why.** ⚠ An absent stamp used to default to `trigger` in
this document, and that default was a **blocker**: both services' `average` streams publish with
`fromBinary(info, 0, …)`, and `Float64::fromBinary` replaces a zero with `RTC::now()` — so `created`
on an average block is the *publish* instant. A consumer aligning `created + window_start_ms` would
draw a running average at wall-clock-now rather than at the stimulus it averages, with the error
growing all session and changing on every republication. `none` states that truth. Absent now means
"a producer predating the contract; unknown".

**`epoch_stage` exists because `epoch_kind` cannot separate two stages of one trial.**
tepSoundService publishes `epochs` (before SOUND) and `clean` (after) from one call with the *same*
trigger RTC — both are `trial`, so a consumer averaging everything marked `trial` double-counts every
trial *and* mixes processing stages, producing a half-cleaned average with `n` at twice the true
count. The key composes with `epoch_kind` rather than replacing it.

**Milliseconds, decided 2026-08-19**, on the grounds that they are what a person reads. Two things
follow, one free and one that has to be paid for.

Free: these are **exactly the spellings both services already write as HDF5 dataset attributes**
(`epochstore.cpp:591-598`, `soundstore.cpp:458-459`), so the stream and the file now agree and an
analysis script written for one works on the other. The sample-index alternative would have needed
its own namespace.

t0 is then derived at the consumer, `zeroSample = round(-window_start_ms/1000 * samplingRate)`, and
the display labels it explicitly (§3).

Ship `unit` in the same patch. It is not formally part of the contract, but `tepService`'s `epochs` is in
the amplifier's **volts** (`epochstore.hpp:38-40`) while its `average` is µV/mV (`:72-73`) and
`tepSoundService`'s `epochs` is µV (`soundstore.hpp:52`) — three units, one type, no way to tell
them apart. `ChannelModel` already reads `unit` (`channelmodel.cpp:435, 477`), so publishing it
fixes "the epoch draws as a flat line on a ±30 µV axis" with **zero viewer change**.

Negative time is then a consumer-side derivation, the same arithmetic tepService already trusts:

```
zeroSample = round(-window_start_ms / 1000.0 * samplingRate)
tMs(i)     = window_start_ms + i * 1000.0 / samplingRate
```

<a id="history--the-one-thing-milliseconds-cost-and-the-fix-that-is-cheaper-than-a-second-key"></a>

### ⚠ The one thing milliseconds cost, and the fix that is cheaper than a second key

`playbackService` **rewrites the declared sampling rate** when `scaleRate` is set —
`Float64(recorded->channels, recorded->samplingRate * job.speed)` (`player.cpp:447-449`) — while
carrying MetaData across **verbatim** (`:454-455`). So a −100 ms window replayed at 2× with
`scaleRate` on derives `zeroSample = 200` from a block whose trigger is still at index 100. The
marker lands in the wrong place, silently, and nothing on the wire says `scaleRate` is on.

A sample index would have been invariant. Rather than carry two keys for one quantity — the tree
already has one place where two sources of truth for a sample count disagree with nothing
reconciling them (`Float64::samples` vs data-length ÷ channels) — **fix it at the one producer that
breaks the invariant.** `playbackService` is already special-casing the rate at that exact line; it
must scale the two ms keys by the same factor when it does:

```cpp
// player.cpp, beside the scaleRate rate rewrite at :447-449
// scaleRate multiplies the declared rate, so a ms-denominated epoch window
// has to move with it or a consumer derives t0 at the wrong sample.
if (job.scaleRate) { /* window_start_ms /= job.speed, window_end_ms /= job.speed */ }
```

~5 lines, local to the module that already knows it is doing something unusual, and it keeps one
human-readable source of truth. ⚠ It must be covered by the §7.4 verification — replay an epoch
stream with `scaleRate` both off and on and check the t0 marker lands on the trigger sample both
times. That case is the whole reason this paragraph exists.

<a id="history-the-absent-vs-zero-rule"></a>

### The absent-vs-zero rule

Test on **list size, never on value**. A missing key yields an empty `QList` and does not appear in
`channelPropertyNames()` (`MetaData.cpp:52-59`); a present key is a list of exactly `channels`
entries. That distinction matters because a legal `window_start_ms` of **0** is reachable from the
UI today (`signalGenerator`'s `epochPreMs = 0`), so a sentinel design would fail on a real
configuration.

Four failure modes all collapse to "absent", which is the only safe default: key missing, wrong
length, non-numeric, and a derived `zeroSample` outside [0, samples) (checked per block — clamp and log,
do not draw a ruler that lies). This mirrors the validation the tree already does for
`theta`/`radius` at `channelmodel.cpp:504-517`.

<a id="history--the-ugliness-turned-out-to-be-load-bearing"></a>

### ⭐ The "ugliness" turned out to be load-bearing

`MetaData`'s only member is `QHash<QString, QList<QVariant>> m_perChannelProperties`
(`MetaData.hpp:37`), its JSON serialisation emits exactly one key, and its constructor reads
exactly that one key — **every other top-level key is silently discarded** (`MetaData.cpp:11-19`).
`setChannelsProperty` additionally asserts equal lengths across properties (`:37-45`).

So a stream-level scalar has to be **replicated N times**: sixty-four copies of `-100`. This section
used to call that a semantic lie accepted over an ABI break (`MetaData` is held by value in
`StreamInfoPrivate`, `streaminfo.cpp:41`, so a new member is undefined behaviour across mixed
binaries).

**The Stage 0 review found it is not a lie.** `tepSoundService` genuinely publishes **two different
windows across the channels of one stream** — its EEG columns sit on the epoch time base and its MEP
column on the guarded base, 200 ms apart at defaults (`soundpipeline.hpp:59-76`, and the two-base
warning at `views.cpp:145-149`). A per-channel window is therefore a real requirement that happened to
be satisfied by the shape forced on us.

⚠ **Consequence, and it is a rule for every consumer: the list may NOT be collapsed to element 0.**
The obvious implementation — read `window_start_ms[0]` — mis-aligns tepSoundService's MEP channel by
the whole guard. The same applies to any staleness read-back inside a producer: tepSoundService's own
rebuild predicate sampled the first entry and therefore could not see the guard move, which is the
exact staleness this contract exists to prevent, left open on the one channel an MEP consumer reads.

⚠ **Ordering trap.** The assert compares against `m_perChannelProperties.begin()->size()` — an
arbitrary hash element, not the first insertion — and it is a `Q_ASSERT`, so a one-element key
inserted before `name` aborts in Debug and produces malformed metadata in **Release**. Always
replicate to the channel count.

<a id="history-producers-to-patch"></a>

### Producers to patch

| Module | Where | Note |
|---|---|---|
| `tepService` | `namedChannels()` at `service.cpp:54-62`, call sites `:1174-1189` | ⚠ used by **both** `epochs` and `average` — must not emit the same `epoch_kind` for both (§7.1). Also fix the `matches` lambda at `:1142-1148` (§7.2). |
| `tepSoundService` | its own `namedChannels()` at `service_analysis.cpp:47-56`, three streams via one `makeStream` lambda at `:327-358` | has **two time bases** (`soundpipeline.hpp:59-76`) and a `zeroSample(bool mepScale)` (`service_run.cpp:1002`). Needs a per-stream decision, not a copy of the tepService patch. |
| `signalGenerator` | `EpochLane::publish()` at `lane.cpp:394`, just after `m_zeroIndex`/`m_samples` are computed at `:379-381` | also forward `theta`/`radius` from the montage it already loads — without positions, head mode and the topoplot **cannot be exercised against the generator at all**. |

---


<a id="history-2-shape-of-the-viewer-change-a-sibling-item-not-a-second-mode"></a>

## 2. Shape of the viewer change: a sibling item, not a second mode

Three shapes were designed and reviewed. The recommendation is a **sibling `EpochReceiver` /
`EpochView` beside `TimeSeriesReceiver` / `PlotView`, sharing `ChannelModel` and the settings
blob** — not a second mode inside the existing item.

The reason is the storage model, and it is structural rather than stylistic. The sweep **decimates
on ingest and loses the samples** — `m_min`/`m_max` are a min/max envelope over
`ceil(rate*duration/16384)` samples per slot. A min/max envelope cannot be averaged. The epoch item
inverts it: keep every sample, decimate only for ink. That inversion is exactly what makes exact
averaging possible, and it cannot be a flag on the same buffer.

Adversarial review then found three specific ways the second-mode variant breaks, each of which the
sibling avoids by construction:

* ⚠ **`m_slotsWritten` resets.** `prepareBuffer()` zeroes it (`timeseriesreceiver.cpp:763`) and runs
  on **every** stream-Ready (`:2252`), not only on a duration change. Any epoch serial or trigger
  address built on it silently stops completing after a reconnect.
* ⚠ **`m_frozen` returns before anything is stored** (`:1001-1005`) and the catch freeze sets it
  (`:1149`), so "freeze on a hit" and "keep averaging" cannot both be true through that flag.
  Demoting it to a render gate moves what the IIR delay lines and the event list contain during a
  pause.
* ⚠ **`paintRow`'s last-bin hold fires whenever `xInc >= 2.0`** (`:1817-1818`), which is true for a
  500-sample epoch in a ≥1000 px plot. Correct for a sweep — that sample's own time extent — and
  wrong for an epoch: a flat stub of real ink at the right edge that is not in the data. This is a
  new caller of the branch §13i/k/l/m was written about.

The sibling's total edit to `timeseriesreceiver.cpp` is two additive things: a `shapeVerdict`
property, and `headValuesAt()` (§5).

<a id="history-detection"></a>

### Detection

**A stream is epoched iff `window_start_ms` is present and well-formed** — not by block length,
not by name, not by cadence. Two provisos:

1. A three-state operator override (`auto` / `force epoch` / `force continuous`), persisted as a new
   key in `Settings.variables`, which is backward compatible for free (unknown keys ignored, missing
   keys keep their default) and sidesteps §16b because the parameter *name* set never changes.
2. For unpatched producers, a **provisional** verdict from the stream name (`^(epochs?|average|clean)$`)
   confirmed against the first two blocks, and **announced when it flips** ("epoched stream detected
   — switched view") rather than left as a mystery.

⚠ A cadence heuristic was proposed and rejected. The decisive test — median inter-block `created`
delta ≥ 1.5 × block duration — fails for **any ISI under 1.5 × the epoch window**. tepService's
default window is 400 ms, so a 5 Hz train, paired-pulse, or most SSEP protocols would classify an
epoch stream as continuous and draw it as a sweep.

⚠ Geometry must be re-read on **every** `AbstractStream::ready` and never cached: with
`reconnect=true`, `persistentStreamRequest` discards the type entirely (`servicediscovery.cpp:46-48`)
and `isSimilar` skips the type check when the local typeId is 0 (`streaminfo.cpp:226`), so a slot
will silently reattach to a stream whose channel count, rate or epoch length changed underneath it.
And note the viewer deliberately does **not** use `ready` — it connects `stateChanged` and calls the
handler synchronously (`:2218-2224`), because §16a means the stream can already be Ready before the
`connect` runs.

---


<a id="history-3-features-13-what-each-actually-costs"></a>

## 3. Features 1–3: what each actually costs

**Feature 1, full-width epoch.** The renderer is *already* an epoch renderer: `xInc = width/m_slots`
and slot `s` is plotted at `s*xInc` (`:1541, :1789`), so a frame occupying every slot fills the
width. The new work is time addressing, and negative time is five mechanical sites: `timeAt`,
`timeGrid`, the in-painter gridline, `PlotMath::timeTicks` (which gains a **defaulted** leading
`min`, so existing call sites and tests compile untouched — `build()` already handles a negative
minimum at `plotmath.cpp:69`), and `measure.timeOf` → `plot.timeAt`.

⚠ One rendering detail the ruler work will otherwise miss: ticks are multiples of `step` so 0 is
always a *gridline*, but **labels** are drawn every `labelEvery` ticks starting from `t.first`
(`plotmath.cpp:63-83`), with no phase anchoring. At t0 = −150 ms, step 50, labelEvery 2 the labels
land at −0.15, −0.05, +0.05 — and the stimulus instant is an unlabelled line. Anchor the label
phase to zero when zero is in range, and make *that* the test case.

**Feature 2, butterfly.** Essentially free: `stacked` already returns `height()` from `laneHeight()`
and `height()/2` from `laneCentre()` for every row (`:348-361`), collapses the amplitude grid
(`:1615`), and turns on the axis labels via `axisIsReadable`. Three gaps:

| gap | fix |
|---|---|
| paging — the paint loop draws `drawnRows()` from `m_firstRow` even when stacked (`:1664-1665`), so a "butterfly" shows one *page* | pin `rowsPerPage = 0` when stacked |
| per-channel centres — `rowScale()` resolves `effectiveCentre(channel)` per channel by design, because a group-wide centre once put three of four AUX channels off their lanes (`channelmodel.cpp:563-587`) | the epoch item uses 0, which is *true* for a baseline-corrected epoch. ⚠ Do **not** call `setGroupCentresToZero()` — mutating the operator's state to make a picture work is how their AUX layout gets lost |
| bit lanes — a trigger word drawn as Bits expands to several rows (`:682-723`) and contributes flat lines through the butterfly | no bit expansion in the epoch item; rows and channels are 1:1 |

"Which electrode is this peak" already exists as JS inside the stacked branch of the hover readout
(`PlotView.qml:1446-1462`); it becomes `channelAt(x,y)` in C++, feeding `ChannelModel` selection so
the gutter, the head array and the topoplot highlight together.

**Feature 3a, head-shaped trace array.** A **port** of `TepGridView` (`tepService/views.cpp:191-330`)
as a paint mode of the epoch item, using `PlotMath::scalpPoint`/`scalpScale` rather than a third copy
of the projection.

⚠ It cannot be a layer inside `HeadView`'s `map`: `map.disc` is a single *isotropic* fraction that is
also a term in `fitFactor` (`HeadView.qml:66-70, :261`), so a wide-and-short trace cell cannot be
expressed through it and widening it shrinks the whole map; and `map` has `clip: true` with the
off-montage Row anchored bottom-left *inside* it (`:314, 503-509`).

⚠ Promoting tepService's plots instead of porting them is a four-service refactor: `TepPlotBase`
does `qobject_cast<TepService*>` (`views.cpp:62`) and every paint path calls `m_service->…`; they are
registered from tepService's **executable** `main()` (`main.cpp:41-47`), so the URI does not exist in
the quickStimulus process; and tepSoundService has already forked both files. The tree's CMake has
already voted on this question — tepSoundService shares `dsp.cpp`/`pipeline.cpp`/`epochprocessor.cpp`
by path and pointedly does **not** share `views.cpp`.

**`HeadView` keeps working over an epoch stream unchanged**, because `headValues(seconds)` is
implemented with the same signature. So the discs stay for impedance and the trace array is a third
band beside them — which is what was asked for. ⚠ `StreamView`'s trailing-spacer visibility test
must be extended to the third band, or the layout regression documented at `StreamView.qml:117-120`
returns.

---


<a id="history-4-feature-5-averaging--and-what-the-four-methods-cost"></a>

## 4. Feature 5: averaging — and what the four methods cost

The four requested methods are **mean, median, trimmean10, trimmean20**. That requirement, not the
display, sets the memory floor:

> **A running accumulator gives you the mean and nothing else.** tepService reached the same wall —
> its accumulator is a mean-only fast path and "the median and trimmed mean still go through the
> full reduction and genuinely need the ring".

So every contributing epoch must be **retained**, not summed away. With *all since the start* as the
default that is unbounded, so the ring needs a **byte budget rather than a count**.

**Budget decided 2026-08-19: 512 MB**, which at the rig's real shapes buys:

| shape | per epoch (float32) | epochs at 512 MB |
|---|---|---|
| 64 ch × 701 (tepSound's delivered epoch) | 180 KB | ~2900 |
| 64 ch × 2000 (tepService default, 5 kHz) | 512 KB | **~1000** |
| 73 ch × 25 kHz × 2 s (undecimated) | 14.6 MB | ~35 |

`capacity = clamp(20, budget/epochBytes, …)`, shown in the UI, never silently defaulted. So at the
paradigm this is actually for, the ring outlives any plausible session and eviction never happens —
which is what makes "all since the start" honest rather than aspirational. ⚠ A fixed capacity in
*epochs* was proposed and is wrong for the same money: 512 MB of 128 ch × 25 kHz epochs is 17 of
them.

⚠ **And the honest consequence must be on screen.** Once eviction starts, "all since the start"
becomes "the last N" and the *median changes meaning*. tepService reports `contributing` separately
from `received` for exactly this reason — "a run bar saying 'in average 41' over a plot saying
'n = 3' is worse than no number at all" (`service.hpp:105-110`). The epoch band shows both.

Rules carried over verbatim, each because it is a bug this tree already paid for:

* **the accumulator only ever adds.** Eviction, rejection, un-rejection and any geometry change
  invalidate and rebuild from the ring. Subtracting drifts ~1e-15 relative from a fresh sum — nothing
  physically, but it makes the displayed *and saved* average depend on the order of the operator's
  clicks (`epochstore.hpp:195-201`). Un-rejection cannot be an append either; the epoch belongs in
  the middle of the session;
* **per-*point* finite counts, not per channel** — a processed sample can be NaN and the divisor must
  be the number of finite contributions at that point (`epochstore.hpp:181-184`);
* **different-length epochs are excluded, never padded** — "an average of two different time bases is
  not an average of anything" (`epochstore.cpp:342-356`). ⚠ Length alone is insufficient: two epochs
  can share a length and differ in `window_start_ms` (−100…+400 vs −200…+300), and averaging those
  aligns the wrong samples while every length check passes. **The averaging key is the triple
  `(window_start_ms, samples, rate)`** — which is precisely the term unavailable today;
* **"last N" means the last N *accepted*** epochs, walking backwards skipping rejected
  (`epochstore.cpp:457-462`). ⚠ tepSoundService windows by *position* instead (`soundstore.cpp:181-187`)
  — the two reference implementations disagree and the choice has to be deliberate;
* **rejection is a flag, never a deletion** (`epochstore.hpp:106-108`).

⚠ An exponential-forgetting mode was proposed and should be dropped or labelled display-only: its
value is order-dependent and cannot be rebuilt from the store, which is the exact property the
only-adds rule exists to prevent.

**Autoscale discipline.** The epoch item must not copy the sweep's 1 Hz whole-buffer autoscale
(`:168-170`) — a running average shrinks toward the mean as n grows, so the operator would watch the
trace breathe. Rescale when a new average lands, and publish it through
`ChannelModel::notifyScalesChanged()`, **never** `setData()`: `setData` always emits
`stateJsonChanged` (`channelmodel.cpp:319-328`), which restarts PlotView's 500 ms `channel_state`
write-back, which writes a service parameter, which schedules a full description broadcast. A running
average routed through `setData` would re-broadcast the whole description **once per stimulus**.

**Filters.** The IIR chains are stateful across blocks by design with an explicit `prime()`
(`:87-121, :1078`). Discontinuous epoch frames ring at every boundary. Fix: `reset()` then
`prime(firstSample, primeSamples())` per epoch — both methods already exist. Document that a highpass
corner near 1/epochLength is meaningless on an epoch stream.

⚠ **Two ingest-path bugs the epoch tap must not inherit**, both pre-existing:
`SingleChannel` reference mode skips only the reference channel, unlike its CAR/GroupAverage sibling
which also skips `bad`, `Bits` and `filterBypass` (`:1013-1031`) — so a trigger word gets an analog
reference subtracted from it, which already corrupts `recordEvents`. And `v -= baseline`
(`:1096`) subtracts the operator's manual DC offset, so pressing **Centre** would retroactively change
the running average's amplitude. Tap before it, or say explicitly that the operator's baseline is part
of the output.

<a id="history-the-output-stream"></a>

### The output stream

Must be `Float64`. `HDFRecorder` dispatches on exactly three typeIds and merely `qWarning`s
"Not recording … unsupported stream type" for anything else (`HDFRecorder.cpp:511-520`) — a bespoke
epoch type would be publishable and **silently unrecordable**.

⚠ `TimeSeriesSender` is the wrong instrument as it stands, for four verified reasons: it publishes
**no MetaData at all** (`timeseriessender.cpp:122-124`, no QML property), so our own averaged epochs
could not be read back as epochs by our own viewer; a nanosecond RTC does not survive a JavaScript
number, so the trigger stamp cannot come from QML (`qml_ResonanceApp.hpp:33-35` says so outright);
`setName`'s guard is **inverted** — `if (m_name == "") return;` (`:46-47`) — so a name bound to a
String parameter that starts empty latches at empty forever, and HDFRecorder refuses an empty dataset
name; and all four setters call `rebuildStream()`, which `deleteLater()`s and immediately recreates
without `close()` (tepService closes first, `service.cpp:1158-1162`).

So: publish from C++ on the epoch item, stamped with the newest contributing epoch's `triggerRtc`,
carrying the input's `name`/`unit`/`kind`/`theta`/`radius` plus our epoch keys, republishing the
input's rate **bit-for-bit as received** (`checkConnectionHeader` compares the double with exact `==`,
`Float64.cpp:39-44`), and sent only when the average moved.

⚠ Creating an `OutputStream` does **not** re-announce the description — nothing in `outputstream.cpp`,
`StreamPool.cpp` or `OutputStreamAggregator.cpp` calls `sendDescription`. Pair enabling it with an
explicit `comLayer()->sendDescription()`, as `qml_Recorder.cpp:14-17` already does.

⚠ Two file-format facts for whoever reads the output back. `Recorder` silently uniquifies colliding
dataset names (`recorder.cpp:374-387`), so a viewer stream called `epochs` alongside tepService's
records as `epochs_1` — default the name to `plot1_epochs`. And §14k is real: the `data` dataset is
extended to `offset + samples + 1` and only `samples` rows are written
(`HDFRecorder.cpp:212-226`), so an epoch stream's dataset has `n*samples + 1` rows and the obvious
`reshape(-1, n_samples, n_channels)` **throws or silently misaligns every epoch**. The read recipe is
the `blocks` dataset as the authoritative epoch index — and it belongs in a doc, not in folklore.

---


<a id="history-5-feature-4-linking-two-viewers"></a>

## 5. Feature 4: linking two viewers

**The link is the cheapest of the five features**, because both viewers are in **one QML process**.

The mechanism splits three ways, and the mistake is using one for all three:

| concern | mechanism | why |
|---|---|---|
| direction / on-off | a Configurator-owned `Select` + `Boolean` parameter, at **explicit** indices | it is configuration; it persists; it belongs to the pair, not to a viewer. ⚠ Explicit because the auto-numbering counter starts at 10 and steps by 10 (`parameters.cpp:27-38`), colliding with `plot1_stream` |
| the live cursor | a plain QML `property var` record | fires at full mouse rate, in-process, free |
| persistence of the last position | the same parameter, coalesced | see the cost note below |

**What travels** is a single record assigned as one property (⚠ a `property var`, never a typed
gadget — assigning a plain JS object to a gadget property fails **silently**, which is why the stream
connector goes through `serialized`): a monotone `seq`, the source's `streamKey`, `epochSerial`,
`t` in seconds **relative to t0** (negative before the stimulus), the raw `frac`, and the source's
own `t0`/`rate`/`samples` so the compatibility test is local.

**Time, not a fraction and not a sample index.** A fraction is meaningless across two different
windows — 0.4 is +100 ms in a −100…400 ms viewer and +80 ms in a −200…500 ms one. A sample index is
meaningless across two rates. When `streamKey` matches on both sides the fraction *is* exact, so the
follower prefers it and no rounding enters.

⚠ **One-way, and never write the follower's clamped value back.** The `head_*` bidirectional
`Binding` + guarded `Connections` pattern converges because both ends settle on the same number. A
cursor does not: the follower must clamp into its own window and snap to its own sample grid, so the
clamped value differs, the inequality guard passes, it overwrites the parameter, and the Binding drags
the **source** viewer's cursor to the follower's clamp. The operator's cursor jumps under their hand
whenever the two windows differ — i.e. the `epochs`/`average` pair, which is the canonical case.
Report clamping in the follower's caption instead ("clamped to +300 ms"), which is tepService's
`paintedRange` rule (`views.hpp:65-72`).

**Cost, measured rather than assumed.** Every `Double::setValue` emits `triggerUpdate`, which restarts
a **single-shot** 30 ms timer whose timeout re-serialises the *entire* service description
(`communicationlayer.cpp:88-91, 281-290, 198-223`). Because `QTimer::start()` restarts a running
timer, a 60 Hz drag (16.7 ms period) emits **nothing** during the drag and exactly one broadcast 30 ms
after it stops. ⚠ But a full-width epoch repaint is itself a ≥30 ms gap — PlotView flags amber past
33 ms — so a drag over a heavy epoch **will** flush mid-gesture. Hence: live cursor by QML property,
parameter for persistence only, behind the 500 ms coalescing already used for `channel_state`.

**The one C++ gap** is that no accessor answers "values at time t, for **all** channels, with
positions". `headValues(seconds)` has the positions but averages a trailing window behind the write
cursor (`:1945-2004`); `readoutAt(xFraction)` picks a slot but iterates **drawn rows only**, honouring
`m_firstRow` (`:2040-2051`), so a topoplot built on it silently shows one page of electrodes. Their
intersection, `headValuesAt(double)`, is ~35 lines and no new storage.

<a id="history-feature-3b-the-interpolated-topoplot"></a>

### Feature 3b: the interpolated topoplot

**The only genuinely new mathematics in the whole set.** There is no spatial interpolation anywhere
in `R:\src` (greps for `griddata`, `kriging`, `idw` return nothing; the only `interpolat` hits are
1-D TMS artefact fill) and **no continuous colormap** — only 3–4 stop discrete ladders.

Four pieces, only the last of which is net-new:

1. **Positions.** The spline wants row-major unit XYZ; the stream carries only `theta`/`radius`
   (`ParseCED.cpp:50-53, 102-108`). `PlotMath::scalpUnitVector(theta, radius)` with
   `sph_theta = -theta`, `sph_phi = (0.5 - radius)*180°` is ~8 lines in the existing Qt-free
   `test_PlotMath` target — reported verified against all 66 rows of `mks64_standard.ced` to the
   file's stored precision. Better than extending `ParseCED`, a Core file feeding every driver.
2. **Reuse `tepSoundService/spline.cpp`.** `splineKernel(ua, na, ub, nb, m, maxn)` already takes two
   arbitrary sets of unit vectors — a pixel grid is one. Extract the augment-pinv-decentre wrapper,
   currently inlined **twice** (`:97-121` and `:176-194`), into one `fieldMatrix(...)` and route both
   existing callers through it so the topoplot inherits their EEGLAB fixture test
   (`sound_test.cpp:376`). ⚠ **Do not re-derive the kernel:** it evaluates the Legendre polynomials at
   `1 - chord_distance`, *not* at the cosine, and the header warns that reaching for the cosine
   "produces a plausible wrong answer" — a smooth, symmetric, silently wrong field. `spline.cpp` and
   `linalg.cpp` are Qt-free, so compiling them by path is the tepSoundService precedent with no new
   `find_package`.
3. **Geometry — read, never re-derive.** Consume `map.originX/originY/scale/headRadius`
   (`HeadView.qml:292-312`). `scale` has **two unit systems** (fraction-of-picture with a backdrop,
   pixels-per-unit-radius without), the origin is measured from the *painted* image rect because
   `PreserveAspectFit` letterboxes, and the fit-the-widest-electrode shrink applies only with a
   backdrop. Assert through the existing `backdropInfo()`/`geometryInfo()` seams.
4. **The field itself** — one cached `nGrid × nCh` operator per configuration (~23 Mflop once at
   128×128 clipped to the circle, 64 channels), then one matvec per frame (~823k multiply-adds),
   independent of the spline order. Plus a diverging colormap symmetric about zero, legible on both the
   white default map background and black under the derived-ink luma rule (`HeadView.qml:129-133`).

⚠ **Three field-specific traps found by review, all of which produce a confident wrong picture:**

* **Cache the operator on the valid-channel SET, not on the montage.** `headValues` already carries
  `valid` (false for "over range or not connected"), `bad` and `visible` per channel. The cached matrix
  is stale the moment an electrode is marked bad or hidden — and feeding **one NaN** through the matvec
  makes the **entire field NaN**, silently, because every grid point is a weighted sum over all
  channels. Refuse below four valid channels with a message, as `repairMatrix` does (`spline.cpp:79-80`).
* **The hollow-reading rule must survive.** The tree has an argued rule that a missing reading is drawn
  hollow rather than as the worst colour, with its own legend entry (`HeadView.qml:106-107, 424-428, 608`).
  A filled field has no hollow. Exclude the channel from the fit and draw its disc hollow **on top** of
  the field, so the hole is visible.
* **Clip at `min(0.5, maxScalpRadius)`, not unconditionally at 0.5.** `mks64_standard.ced` runs to
  0.742 so 0.5 is safe there, but `topomap30.ced` has `sph_radius = 1` and any partial cap can have its
  outermost electrode *inside* 0.5 — where a thin-plate spline diverges and produces a smooth,
  confident, meaningless rim.

⚠ Worth doing before any per-frame layer lands: `HeadView`'s outline Canvas repaints on **every** 250 ms
value refresh, because `requestPaint()` is wired to `onPointsChanged` and `refresh()` reassigns `points`
unconditionally (`:189-207, 333-346`) — contradicting its own comment. Separate the geometry signal from
the value signal first, or the field inherits that baseline.

---


<a id="history-6-staging"></a>

## 6. Staging

⭐ **The completeness critic's most valuable finding: the first increment needs no engine at all.**
On a tepService-fed rig, subscribing to its existing `average` stream (`service.cpp:1182-1189`, same
declared geometry as `epochs`) delivers features **1–4** — full-width epoch, butterfly, head-shaped
trace array, topoplot at a chosen time — with no epoch store, no accumulator, no trigger, no rejection
and no output stream. That de-risks the two genuinely new renderers before any engine exists.

| stage | delivers | needs | est. |
|---|---|---|---|
| **0** producer metadata + `unit` | ✅ **DONE** — see §6a | §1, four modules, zero framework change | 0.5 d |
| **1** epoch geometry + display + butterfly | features 1, 2 on a subscribed stream | `EpochBuffer`, `EpochReceiver` ingest, negative-time axis | 6 d |
| **2** head trace array | feature 3a | port of `views.cpp:191-330` | 1 d |
| **3** link + topoplot | features 3b, 4 | `fieldMatrix` extraction, `scalpUnitVector`, colormap, `headValuesAt` | 4.5 d |
| **4** averaging engine | feature 5, mean/median/trimmean | the ring, the accumulator, per-condition bins | 3 d |
| **5** viewer-side epoching | epoch **any** continuous stream off a trigger | `EpochCatcher`, level + bit trigger sources | 2 d |
| **6** output stream | the light-analysis half | C++ publisher with metadata | 1 d |
| **7** verification | — | §7.4 | 2 d |

**~20 working days**, three to four weeks with hardware testing. Stages 0–2 are ~7.5 days and deliver
most of the visible intent.

<a id="history-6a-stage-0--done-and-measured-rather-than-asserted"></a>

### 6a. Stage 0 — done, and measured rather than asserted

Four modules patched (tepService, tepSoundService, signalGenerator, playbackService), zero framework
change, no protocol edit. Build green under MSVC v142 x64, 138/138 unit tests.

⚠ **The unit tests prove nothing about this work** — the GTest targets link only the pure logic
files, not any `service.cpp`, so the metadata code they were said to cover was never executed by
them. That is why the contract is now guarded by a live harness instead:
**`R:\config\epoch_contract_check.qml`** (+ `.ps1`), which discovers epoch-declared streams, receives
real blocks and asserts per channel.

Measured live, driving tepService and tepSoundService from `playbackSource` replaying
`R:\tests\source-recordings\11_TMS_48MSO_heel_+60.hdf5` — no amplifier:

| stream | shape | verdict |
|---|---|---|
| `TEP/epochs` | 72 ch @ 5 kHz, blocks of 2000 | window [−100, 300), `trial`, `trigger`, `V` |
| `TEP/average` | 72 ch @ 5 kHz, blocks of 2000 | `average`, **`none`**, `uV` ×71 + `mV` on ch 64 |
| `TepSound/epochs` | 65 ch @ 1 kHz, blocks of 701 | `trial` / `preprocessed` / `trigger` |
| `TepSound/clean` | 65 ch @ 1 kHz, blocks of 701 | `trial` / `cleaned` / `trigger` |
| `TepSound/average` | 65 ch @ 1 kHz, blocks of 701 | `average` / `cleaned` / `none` |
| `EPOCHGEN/epochs` | 8 ch @ 1 kHz, blocks of 500 | window [−100, 400), `trial`, `trigger`, `V` |

**155 assertions, 0 failures.** The length invariant held with worst error **0.000e+0 samples** on
every channel of every stream.

⭐ **The two-windows-in-one-stream case is confirmed on real blocks**, which is the strongest single
result here: `TepSound`'s channels 0–63 declare [−200, 501) ms and channel 64 declares [−400, 301) —
and both give exactly 701, the delivered block length. A consumer reading element 0 would mis-place
the MEP column by 200 ms. The per-channel rule in §1 is not theoretical.

**Not measured:** `playbackService::scaleEpochWindow` is gated on `--scaleRate` and no *already
epoched* recording exists in `R:\tests\source-recordings\` to replay through it. That path is
reviewed and unit-reasoned, not executed.

⚠ **This work also uncovered [known-issues §11c](../incidents/README.md), which is bigger than this
feature**: ninja records **no header dependencies** on this machine, so a header edit yields a
mixed-layout binary that links cleanly and crashes at run time. It cost four identical
`0xC0000005` faults here before it was found, and 138/138 tests passed against the broken binary.

Two prerequisites before a line is written: ⚠ **archive `timeseriesreceiver.*`, `plotmath.*`,
`channelmodel.*` and the `Plot/` QML directory** — quickStimulus is untracked and there is no
`git checkout` to fall back on; and build the current tree once so there is a working control.

---


<a id="history-7-blockers-any-implementation-must-respect"></a>

## 7. Blockers any implementation must respect

<a id="history-71-epoch_kind-is-not-optional"></a>

### 7.1 `epoch_kind` is not optional

⚠ **BLOCKER.** tepService passes the *same* `namedChannels(epochNames)` to both its `epochs` and its
`average` streams (`service.cpp:1174-1189`), and `publishAverage()` re-sends the whole average whenever
it moves, on a 100 ms tick (`:1451-1484`). So under a naive contract `average` is indistinguishable
from `epochs`, and the viewer's averager would **average successive republications of a running
average** — double-counting the same trials with `n` growing without bound. The displayed average would
depend on how many view ticks happened. Publish the geometry keys per stream, add `epoch_kind`, and
make the viewer **refuse to accumulate a stream marked `average`**.

<a id="history-72-epoch-length-changes-with-no-announcement-whatsoever"></a>

### 7.2 Epoch length changes with no announcement whatsoever

⚠ tepService's stream-rebuild test compares only channel count and fuzzy rate (`service.cpp:1142-1148`)
and returns early (`:1150-1156`), while `epochSamples` **and** `zeroSample` are both functions of the
window (`pipeline.cpp:63-71`). So nudging `windowStart` at constant rate changes the block length and
the zero point with **no stream rebuild, no `stateChanged`, and no re-announcement** — and the published
`window_start_ms` would then lie. A stale correct-looking number is more dangerous than an absent one.
Fix `matches` to include the window and `epochSamples` **in the same patch as the contract**.

<a id="history-73-the-gui-thread--decided-with-the-arithmetic-that-justifies-it"></a>

### 7.3 The GUI thread — decided, with the arithmetic that justifies it

**Decided 2026-08-19: the accumulator stays on the GUI thread**, on the operator's reasoning that the
viewer already runs live IIR filtering there. That holds up, and it is worth writing down because it
is the opposite conclusion to tepService's:

| | runs | cost per second at 70 ch / 25 kHz |
|---|---|---|
| the existing filter loop | per **sample**, per channel, at tick rate | 1.75 M biquad cascades — and it is already measured working |
| the epoch accumulator | per **point**, per epoch, at **stimulus** rate | 128 k adds per epoch, ~1 per 8.5 s at tepSound's ISI |

tepService's 99 % → 6 % came from moving the **continuous** stage — filtering 73 channels at 25 kHz —
off the GUI thread. That stage is not what this adds. Feeding an already-cut epoch into a sum is four
orders of magnitude cheaper and lands beside a filter loop that survives the harder job.

⚠ Two things this decision makes mandatory rather than optional. There is **no instrument for the
ingest path** today — `lastPaintMs` times only the painter (`:1519-1522`) — so an ingest counter goes
in with the accumulator, not after it. And the one case that is *not* cheap is the undecimated
extreme: 73 ch × 25 kHz × 2 s is 3.65 M points per epoch, so a paired-pulse protocol at that shape
wants measuring before it is trusted. Everything at the decimated rates this feature is actually for
is free.

<a id="history-74-extra-stream-parameter-slots-cannot-be-added-later"></a>

### 7.4 Extra `Stream` parameter slots cannot be added later

⚠ `applyParameters` screens parameter **names** once, up front, and permanently rejects anything not
already declared (`communicationlayer.cpp:338-351`; the retry loop re-tries *values*, never names). Each
viewer has exactly one `Stream` parameter today. These features want more — a markers/condition stream, a
trigger stream for the catch path, possibly tepService's `status` for `contributing`. **Declare them now,
statically, at explicit indices**, even if their handlers land later. An unused declared parameter is
free; an undeclared one is unrestorable from any saved config.

<a id="history-75-stale-constraints-for-the-record"></a>

### 7.5 Stale constraints, for the record

Two rules asserted during design that the review **disproved** — worth recording so nobody re-imposes
them: `Select::setOptions` and `Select::setIndex` *do* re-broadcast (both emit `jsonChanged`, and
`Parameter`'s constructor connects `jsonChanged → triggerUpdate`, `parameter.cpp:8-10`), so a dynamically
built option list is fine. §17a's genuine residue is only `Double::setMinimum`/`setMaximum`
(`double.cpp:82-98`) — which nothing proposed here trips.

---


<a id="history-8-decisions-taken-2026-08-19"></a>

## 8. Decisions taken, 2026-08-19

All five settled by the operator. Recorded here rather than in a chat log, because each one shapes
code that has not been written yet.

| | Decision | Consequence |
|---|---|---|
| 1 | **Milliseconds** for the epoch bounds, on human-readability | stream keys now match the HDF5 attribute spellings (free); requires the `playbackService` `scaleRate` fix in §1 (~5 lines) |
| 2 | **GUI thread** for the accumulator | §7.3; ingest counter becomes mandatory, and the undecimated 25 kHz case wants measuring |
| 3 | ~~**512 MB** epoch ring~~ — **SUPERSEDED 2026-08-20** | ships in Stage 4; then becomes **uncapped with a 2 GB notify-and-continue threshold**. The premise was wrong: 512 MB is ~1000 epochs at tepService's shape but only **36** undecimated, and since nothing is preallocated a low cap saves nothing — it only converts "all since the start" into "the last N". See [STATUS § retention model](design_viewer-epochs-STATUS.md) |
| 4 | **Per-condition averaging: yes, from day one** | `QString label` in the epoch struct and a label→(sum,count) map now, even with one bin shown. Needs the `markers` Stream slot declared up front (§7.4) |
| 5 | **GFP trace below the butterfly**, and the topoplot reads the cursor's time point | gives the cursor a reason to be somewhere; `headValuesAt()` is the accessor (§5) |

<a id="history-on-decision-4--what-it-pulls-in"></a>

### On decision 4 — what it pulls in

Per-condition averaging is not only a second accumulator dimension. It needs the **label** to exist,
which means a marker stream: tepService takes an optional `markers` `Stream` and the most recent
record before a trigger becomes that epoch's label (`service.cpp:179-188`, `:1375`). So the viewer
needs its own `plotN_markers` `Stream` parameter — **declared now**, per §7.4, or it can never be
restored from a saved configuration.

⚠ And note what the producers do *not* give: `signalGenerator` writes a condition code into
`EpochLane::Pending::code` and **never reads it back out** (`lane.cpp:424` vs `:441-467`), so
per-condition averaging cannot be exercised against the generator without a four-line generator fix.
That fix belongs in Stage 0 beside the metadata, since Stage 0 is already in that file.

<a id="history-on-decision-5--gfp-is-cheap-and-it-is-the-missing-half-of-the-cursor"></a>

### On decision 5 — GFP is cheap and it is the missing half of the cursor

Global field power over the epoch is one number per sample — the spatial standard deviation across
electrodes — so it is `samples` values derived from data already in hand, drawn as one trace in a
short band under the butterfly. It costs nothing and it is what turns "drag the cursor somewhere"
into "put the cursor on the peak", which is the whole reason a topoplot is taken at one instant. ⚠ It
must be computed over the **finite, visible, non-bad** channels only, for the same reason the field
operator is (§5) — one NaN electrode would otherwise flatten the trace.

---


<a id="history-9-not-verified"></a>

## 9. Not verified

Stated plainly, because the sections above read like completion.

* **Nothing is implemented.** This is a design, produced by reading the source. No code was written and
  no measurement was taken on a running viewer.
* Every performance number here is an **operation count**, not a timing: the ~23 Mflop operator build,
  the ~823k-multiply-add matvec, the 128k slot visits. None has been measured on this machine.
* The `scalpUnitVector` identity is reported verified against `mks64_standard.ced` only. `topomap30.ced`
  has `sph_radius = 1`, and `mks128`/`mks256` were not checked row by row.
* ⚠ The HDF5 phantom trailing row (§14k) is documented in the tree but **has not been confirmed against
  an actual recorded epoch file** in this survey. Confirm before publishing any read recipe.
* No claim here has been tested against `mingw32`/`mingw64`. Only `msvc64` is currently built.
* The tepSoundService two-time-base question (`soundpipeline.hpp:59-76`, `service_run.cpp:1002`) is
  **open**: which base each of its three streams should publish needs a decision from someone who knows
  that module, not a copy of the tepService patch.
