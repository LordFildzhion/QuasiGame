# Trigger and latency validation — NVX-52, Neuron-Spectrum-65, arduinoTTL — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/tepsound.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-trigger-and-latency-validation--nvx-52-neuron-spectrum-65-arduinottl"></a>


**Run 2026-08-17 on this machine, on the hardware attached to it.** What was measured, how, and
what came out. The modules are described in [neuron-spectrum.md](../components/neuron-spectrum.md) and
[arduino-ttl-service.md](../components/arduino-ttl.md); the NVX driver has no reference document of its
own and STATUS.md ([change history](../changes/README.md)) carries its history.

**The headline.** A trigger edge can be located on the NVX's timeline to **±½ sample and nothing
worse** — measured, not assumed — but only if it is read at driver level. Through the Resonance
service layer the same edge is dated **9.3 ms late with a 16.7 ms spread**. That is three orders
of magnitude, and which number applies depends entirely on where the reader sits.

⚠ **The NVX trigger connector's output leg was physically broken** — its trace was torn off the pad and was repaired on 2026-08-18. Every NVX output result before that date is void, not
merely unverified. Re-measured after the repair in §7a: both directions work, and 1000 pulses were recorded without a single loss.

---


<a id="history-1-the-bench"></a>

## 1. The bench

| | |
|---|---|
| NVX-52 | serial 1219, 48 EEG + 4 AUX, NVX API 2.3.21648 |
| Neuron-Spectrum-65 | serial 22370366, WinUSB, vendor SDK 2023-04 |
| arduinoTTL | **a real board**, firmware v2.3, on COM4 — the first time this project has attached one. ⚠ The board at the TMS lab is a **different one, running v2.2**, on which `1=OUT,LOW` answers `ERR unknown` — channel 1 is a permanent output there |
| Wiring | arduinoTTL BNC1 and BNC2 into two NVX trigger inputs; the NVX and the NS-65 sync ports cabled to each other |

Everything below is at **driver level** unless it says otherwise: straight onto `nvxmcs.dll` and
onto `ns65bridge.dll`, with no Resonance in the path. That is deliberate. The service layer adds
a block cadence that is larger than most of what is being measured, so putting it in the path
would have measured the transport instead of the devices (§6 measures it on purpose).

Instruments, all in `R:\config`: `nvx_trigger_probe.py`, `ttl_link.py`, `trigger_bench.py`,
`ns65_sync_bench.py`, `analyze_trigger_recording.py`, `trigger_service_harness.qml`.
Evidence: `R:\dist\_build\trigger-campaign\*.json` and one HDF5.

---


<a id="history-2-the-pin-map-measured-rather-than-assumed"></a>

## 2. The pin map, measured rather than assumed

Nothing else could proceed until this was known, and every part of it contradicted something.

| NVX `Status` bit | What is on it | How it was established |
|---|---|---|
| 0–5 | unwired, idle HIGH | never moved in any run |
| **6** | **arduinoTTL BNC1** (D9) | a 3-pulse train gave exactly 3 falling edges on bit 6 and on no other bit |
| **7** | **arduinoTTL BNC2** (D3) | a 5-pulse train gave exactly 5 |
| **8** | **NS-65 sync out** | 10 stimulator pulses gave 10 rises on bit 8 (§5) |
| **9** | **the NVX's own output**, read back | only bit 9 moved across the write sequence `[0,1,0,1,2,3,2,3,0]` |
| 12 | reserved, idles **LOW** | constant in every run |

The idle word is **`0x0000EFFF`**: every input rests HIGH, so **an input edge is a bit going
low**. An analysis looking for a rising edge finds only the device's own start-up transient.

> ### ⚠ AMENDED 2026-08-20 — this is a PER-RIG fact, not a universal one
>
> **Everything in the table above is what was measured on THIS bench, with the arduinoTTL board
> wired to BNC1/BNC2 and nothing else attached.** It is not a property of the NVX and it must not
> be applied to another rig without re-measuring the idle word from that rig's own recording.
>
> The two reference TMS recordings taken for the tepSound work (`R:\config\...+60...`, one 150
> trials and one 107) were made on a **different** wiring of the same amplifier, driven by the
> `feetStim` box, and they measure:
>
> | | this bench (§2 above) | the tepSound reference recordings |
> |---|---|---|
> | idle word | `0x0000EFFF` | **`0x0000FFFA`** |
> | bit 0 | unwired, rests HIGH | **rests LOW, pulses HIGH for 10.00 ms** (250 samples at 25 kHz; 3 of 257 pulses measure 10.04 ms, one sample of jitter) |
> | bit 1 | unwired, rests HIGH | **rests HIGH, pulses LOW for 50.2 ms**, asserting 60.28 ms *before* every bit 0 rise — the peripheral stimulus, and the `+60` in both filenames |
> | an event is | a bit going **LOW** | a bit going **HIGH** |
>
> ⇒ On those files `tepSoundService`'s defaults — `triggerBit = 0`, `triggerEdge = Rising` — are
> **correct**, and "correcting" them to Falling to match the rule above cuts every epoch **10.0 ms
> late**, with the same trial count and a completely normal-looking average. Epoching **bit 1**
> instead yields a flawless average of the *peripheral* evoked potential with the TMS artefact
> parked at +60 ms. Neither mistake announces itself.
>
> ⇒ tepSound now measures the line rather than trusting either document: the run bar reads
> `bit 0: rests low, 150↑ 150↓, pulses high 10.00 ms` from the samples themselves, and turns amber
> when the selected edge is the one that *ends* the pulse. **Read that line before trusting any
> trigger setting, on any rig.**

> ### ⭐ AMENDED AGAIN 2026-08-22 — a THIRD rig, an NVX136, and the number that governs it
>
> Measured at the TMS lab on an **NVX136** (not the NVX-52 of §1) from that session's own
> recording, `lab-cmdpulse-001.h5`, 25 kHz trigger-only, 4 825 320 rows, no NaN rows. Full
> account: `R:\tests\lab-session-20260822\REPORT.md`.
>
> | | this bench (§2) | the tepSound reference recordings | ⭐ the TMS rig, 2026-08-22 |
> |---|---|---|---|
> | amplifier | NVX-52 | NVX-52 | **NVX136** |
> | idle word | `0x0000EFFF` | `0x0000FFFA` | **`0x0000FFFE`** (TMS on) / **`0x0000FFFF`** (standby) |
> | bit 0 | unwired, rests HIGH | rests LOW, pulses HIGH 10.00 ms | **TMS Trig-Out. Rests LOW, pulses HIGH, 0.120 ms** |
> | bit 1 | unwired, rests HIGH | rests HIGH, pulses LOW 50.2 ms | **arduinoTTL BNC1/D9. Rests HIGH, 1.480 ms** |
> | bits 2–7 | — | — | rest HIGH, never moved (an unwired input rests HIGH) |
> | settings that are correct there | — | `bit 0`, `Rising` | **`triggerChannel 0`, `triggerBit 0`, `triggerEdge Rising`** — confirmed from the rig's own data |
>
> ⚠ **Bit 0's rest level tells you whether the stimulator is POWERED**: it rests LOW only while
> the TMS is on. That is the whole difference between the two idle words, plus bit 2.
>
> ⚠ **Do not "fix" `triggerChannel = 0`.** On a trigger-only amplifier tepSound's pipeline line
> read `trigger: bit 0 of channel 1, rising edge` — 0 correctly resolved to the last channel.
>
> ### ⭐⭐ THE TRIG-OUT PULSE IS 120 µs, AND THE NVX136 ONLY LEVEL-SAMPLES
>
> **TMS Trig-Out high phase = 0.120 ms median (3 samples at 25 kHz), min 0.080 (2), max 0.120,
> sd 0.017.** The NVX136 driver has **no edge-latch mode, only level sampling** — unlike the
> NVX-52's latch measured in §4, which is what makes §4.2's ±½-sample result possible there.
>
> At 1 kHz a 120 µs pulse is caught roughly **12 %** of the time. The session saw exactly that:
> **1 of 8 discharges** appeared on bit 0 at 1 kHz, and **4 of 4** at 25 kHz.
>
> > **Any trigger or latency campaign on this rig must run at 25 kHz. A null or short count on
> > bit 0 at 1 kHz means NOTHING — it is the expected result of level-sampling a pulse eight
> > times shorter than the sample interval, and it is indistinguishable from a stimulator that
> > did not fire.**
>
> ### ⭐ command → pulse = 0.840 ms, and it is almost entirely the Arduino
>
> `latency.py --pair 1:0`, n = 4, one write of `P1
2:P1
` driving BNC1 (the command instant)
> and BNC2 (which fires the TMS) back to back. A difference of two sample indices in one
> recording — no host clock anywhere in it.
>
> | term | value | source |
> |---|---|---|
> | bit 1 → bit 0 on the sample axis | **0.840 ms** median, p90 0.880, min/max 0.840–0.880 (21–22 samples, span 1), sd 0.017 | `latency.py --pair 1:0` |
> | the board's own channel-1→channel-2 dispatch gap | **0.838 ms** median (840, 832, 836, 840 µs) | the board's `FIRE <us>` vs `2 FIRE <us>` replies, on its own microsecond clock |
> | ⇒ stimulator trigger-in → Trig-Out | **≈ 0.002 ms — below the 40 µs resolution** | the difference of the two above |
>
> ⚠⚠ **DO NOT QUOTE 0.840 ms AS "THE STIMULATOR'S LATENCY."** It is the Arduino dispatching two
> serial lines. The stimulator's own contribution is indistinguishable from zero at 25 kHz. Span
> of 1 sample is the measurement's quantisation, not device jitter. The constant part of the
> **host → board** leg is **unmeasured** on this rig and is folded into none of these numbers; it
> needs a scope.
>
> ⚠ **The stimulator is in PAIRED-PULSE mode: every trigger delivers TWO discharges.** 8
> commands → **16** `pulse` event records from neuroMS. Not a fault, and not visible on bit 0
> (the two discharges share one Trig-Out pulse) — but any trial count derived from commands is
> half the number of discharges the coil delivered.

⚠ **The first 14 frames of every acquisition carry `Status == 0`** before the register is
populated. Left in, they look like every input rising at once. This is the resting-level trap
[tep-service.md §4](../components/tep.md) records for the legacy Python — now confirmed on this
hardware rather than inferred.

<a id="history-21-three-sources-disagree-about-the-bit-layout-and-the-hardware-settles-it"></a>

### 2.1 Three sources disagree about the bit layout, and the hardware settles it

| Source | Inputs | Output readback |
|---|---|---|
| `NVX.h:108,116,124,139` | bits 0–9 (ten) | bit 10 |
| Vendor programming guide §1.6 | ten | — |
| Vendor programming guide §2.6 | **nine** | **"10-th bit"**, 1-indexed = bit 9 |
| User manual spec table | **9 sync in, 1 sync out** | — |
| `NVXGetPossibility` on this unit | **`InTriggersCount` = 9** | **`OutTriggersCount` = 1** |
| **Measured** | **bits 0–8** | **bit 9** |

The header comment is off by one and `R:\src\nvx` never reads `InTriggersCount`, so nothing in
the shipping code would have caught it.

---


<a id="history-3-the-nvx-output-line--trigger_state-is-wrong-on-this-hardware"></a>

## 3. The NVX output line — `trigger_state` is wrong on this hardware

`NVXSetOut` is documented as taking "bits 0, 1" and `nvx/application.cpp:132` describes
`trigger_state` as *"the two low-order trigger output lines as a two-bit value: 0=00, 1=01,
2=10, 3=11"*, with `setMaximum(3)`.

Measured, inside one continuous acquisition so a stale SDK queue could not fake a level:

| written | readback bit 9 |
|---|---|
| 0 | low |
| **1** | **high** |
| 2 | low |
| 3 | **low** |

**Only the exact value 1 asserts the line.** Not "bit 0 of the value" — 3 has bit 0 set and
leaves the output low. There is one output line, as `OutTriggersCount` says.

⚠ **Consequence:** any experiment that encodes a trigger code as 2 or 3 emits nothing and
records a clean, plausible zero. **Now fixed:** the parameter is a `Parameters::Boolean` checkbox, and the driver drives the line to its value at every Start (§7a).

---


<a id="history-4-edge-fidelity--the-question-the-sdk-does-not-answer"></a>

## 4. Edge fidelity — the question the SDK does not answer

`NVX.h` documents three trigger modes by name only — `NORMAL` "normal", `FRONT` "front
detection", `REAR` "rear detection" — and says nothing about latching, minimum pulse width, or
what the bit reads after a detected edge. The user manual describes the sync channels as sampled
*"synchronously with the issued channel readings, accuracy ±0.5 / reading"*, which describes
sampling and not latching.

This matters because the NS-65's sync-out pulse is **100 µs** (§5) and the NVX samples every
500 µs at 2 kHz.

**Method.** The arduinoTTL's Timer1 is the calibrated source. At a carrier of 16e6/65536 =
244.140625 Hz the prescaler is 1, so the duty step is 62.5 ns and a 5 µs pulse can actually be
asked for; pulses are one carrier period (4096 µs) apart, so each is an isolated event. The board
counts what it really emitted through its D2 loopback and reports it as `WEND edges=N`, so the
comparison is **board-truth against amplifier-observed**, not host-intention against
amplifier-observed.

Isolated pulses, 2 kHz, ~488 per point:

| LOW width | `normal` | `front` | `rear` |
|---|---|---|---|
| 2000 µs | 100 % | 100 % | 100 % |
| 1000 µs | 100 % | 100 % | 100 % |
| 500 µs | 100 % | 3.9 % | 100 % |
| 250 µs | 50.0 % | 0 % | 100 % |
| 100 µs | 20.1 % | 0 % | 100 % |
| 50 µs | 10.0 % | 0 % | 100 % |
| 20 µs | 4.1 % | 0 % | **95.5 %** |
| 10 µs | 2.0 % | 0 % | 52.3 % |
| 5 µs | 1.2 % | 0 % | 27.7 % |

**`normal` is plain level sampling.** The catch fraction is the probability that a pulse of
width *w* spans a sample instant, *w*/500 µs, to within counting noise at every point.

**`REAR` latches.** It catches a 20 µs pulse — one twenty-fifth of a sample period — and holds
the bit low for about 1.5 samples, one clean rise/fall pair per pulse.

**`FRONT` is useless on an idle-HIGH line.** At 250 µs bit 6 showed **0 rises and 0 falls**: the
bit does not move at all, so this is not an artefact of counting the wrong edge direction.

<a id="history-41-the-latch-is-rate-independent"></a>

### 4.1 The latch is rate-independent

Widely-spaced 1 ms pulses, which is a quarter of a sample period at 250 Hz:

| rate | pulse | `normal` | `rear` |
|---|---|---|---|
| 250 Hz | 1 ms = 0.25 samples | 0/25 | **25/25** |
| 1000 Hz | 1 ms = 1.00 samples | 25/25 | 25/25 |

So a rig at 250 Hz or 1 kHz still sees a 100 µs sync pulse, **provided REAR is selected**.

*(The 0/25 in level mode is below the ~25 % that chance overlap predicts: a 100 ms period is
exactly 25 samples at 250 Hz, so the phase was frozen and every pulse landed in the same losing
slot. Do not read it as "level mode never catches a quarter-sample pulse".)*

<a id="history-42-edge-placement-is-pure-sampling-quantisation-and-nothing-worse"></a>

### 4.2 Edge placement is pure sampling quantisation, and nothing worse

A first attempt at this measured nothing, and the way it failed is worth keeping: a 100 ms train
at 2 kHz is exactly 200 samples, so every edge landed at the **same** sub-sample phase, every
interval came out as 100.0000 ms, and the residual looked tiny while saying nothing about the
amplifier.

Repeated with the phase deliberately dithered — a 4096 µs carrier is 8.192 samples at 2 kHz, so
successive edges walk through every phase — over 733 edges:

| | measured | predicted for plain sampling |
|---|---|---|
| residual span | **499.4 µs** | 500.0 µs (one sample period) |
| residual sd | **144.3 µs** | 144.3 µs (= sample/√12) |
| histogram over one period | `[73,73,74,72,74,73,73,74,71,76]` | flat |

**The NVX adds no jitter of its own.** A trigger edge is located to ±½ sample and no worse.

⚠ **Unreconciled:** the clock-ratio slope came out **+19.8 ppm** here against **−0.6 ppm** from
the 60-pulse train fit. The residual result does not depend on it (it is scatter, not scale), but
the two estimates disagree and a longer run is needed to settle which is right.

---


<a id="history-5-across-devices-ns-65--nvx-works-and-this-is-the-first-time"></a>

## 5. Across devices: NS-65 → NVX works, and this is the first time

The Neuron-Spectrum's synchronisation port had never been reachable: the `/clr` bridge contained
**zero** functional references to `SynchroModule`, `LightStimulator` or `PatternStimulator`, so
sync-in could not be enabled and sync-out had no API at all. That is why
[neuron-spectrum.md §10](../components/neuron-spectrum.md) has always said the `events` path was unexercised.

Sixteen entry points were added to the bridge (`NS_SyncPowerOn`, `NS_SetSyncInEnabled`,
`NS_SetSyncOutSource`, `NS_Stim*`, …). Three facts shaped them, all from the vendor IL:

* **The only path in the whole SDK that enables sync-in** is the end of
  `StimulatorsControlUnit.powerOn()`, which `SynchroModule.PowerOn()` delegates to.
* **A read-modify-write guard would never write the hardware.** `SynchronisationModule`'s
  constructor initialises its shadow to `BitVector32(3)`, so `SynchInEnable` reads back *true*
  from construction while `LoadSynchInReg` has never run. Only the setter loads the register, so
  the new setters assign unconditionally — deliberately breaking the guarded idiom the rest of
  the bridge uses.
* **`SynchroOutDuration` is unreachable and the pulse is fixed at 100 µs.** It appears in no
  member signature anywhere in the assembly; it lives in bits 0–2 of a private `BitVector32` that
  the constructor sets to `_100_mks` and nothing ever writes again.

**Result:** `NS_StimStart(light, 10)` produced **10 rises on NVX bit 8** for 10 requested pulses,
with the NVX in REAR mode. The 100 µs width and the ≥20 µs REAR threshold agree by construction —
two independent routes to the same conclusion, one from decompiled IL and one from a pulse sweep.

⚠ **The sync out is driven *by* a stimulator.** There is no host-arbitrary-pulse source: a
stimulator must be powered, configured and started for the socket to do anything. The light
stimulator is a photic lamp.

**Replicated on a second, independent receiver.** With the cable moved to the arduinoTTL, the
board's IN2 counter took **10 edges for 10 stimulator pulses**, and then **20 of 20** with a
standing rule timestamping each one on the board's own clock:

| NS-65 photic stimulator, commanded 500.000 ms | measured on the board's crystal |
|---|---|
| median interval | **499.992 ms** |
| min / max | 499.972 / 500.000 ms |
| standard deviation | **0.010 ms** |
| period error | **-16 ppm** |

That is the first hardware-timestamped measurement of this amplifier's stimulus timing. It is a
different clock pair from §4.2's, so the ppm figures are not comparable with each other.

---


<a id="history-6-across-the-service-layer-9-ms-not-01-ms"></a>

## 6. Across the service layer: ~9 ms, not ~0.1 ms

One recording, 180 board pulses, through the full chain — arduinoTTL service → serial → board →
BNC1 → NVX → `nvx` service → TCP → `recorderService` → HDF5 — with the board's `events` stream
recorded into the same file so the same edge is present twice.

**180 board `fire` records ↔ 180 NVX falling edges. Nothing lost anywhere in the chain.**

| Same 180 edges, three clocks | Median interval |
|---|---|
| board `micros()` (ground truth) | **100.0000 ms** |
| arduinoTTL service RTC | 100.0014 ms |
| NVX path (block `created` + sample interpolation) | 100.0954 ms |

| | |
|---|---|
| **Same edge, NVX-path RTC − arduinoTTL-service RTC** | **+9.34 ms median, +6.55…+23.21, spread 16.7 ms** |
| Block `received − created` (driver → recorder transport) | 0.239 ms median, 1.222 ms max |

**The transport is not the cost.** 0.24 ms of it is TCP; the rest is the driver's poll cadence —
38 ms at 2 kHz with block 100 — and the fact that a block's `created` is stamped when the block
is *built*, i.e. after its last sample was collected.

**So: read the trigger channel out of the recording and interpolate within the block, and you get
±½ sample. Compare two services' RTCs for the same event and you get ~9 ms ± 17 ms.**

<a id="history-61-the-arithmetic-that-is-easy-to-get-backwards"></a>

### 6.1 The arithmetic that is easy to get backwards

`created` belongs to the **last** sample of its block, not the first:

```
rtc(row r in block i) = created_i - (lastRow_i - r) / samplingRate
```

Reading it as the first sample is what previously turned a +57.5 ms measurement into +364 ms
([stimulus-presentation.md](../components/stimulus-presentation.md)). Block sizes also vary — a requested 100
delivered 1…100, median 94 — so offsets must be accumulated per block, never assumed uniform.

---


<a id="history-6a-the-sync-connector-from-the-manual--and-the-wiring-fault-it-explains"></a>

## 6a. The sync connector, from the manual — and the wiring fault it explains

The operation manual's appendix 4 (`G091.00.D100.00.003`, p93) documents the connector the SDK
never describes. It is a **2.5 mm three-contact jack**, and figure 46 assigns:

| contact | on the plug | function |
|---|---|---|
| 1 | sleeve | common |
| **2** | **tip** | **sync IN** — pulled up through 47 kOhm |
| **3** | **ring** | **sync OUT** — driven through 1 kOhm |

* **Sync in** wants *"a negative-polarity TTL pulse of at least 100 us; the falling edge is taken
  as the sync start"*, and adds that *"the sync signal is also formed by shorting the input to
  the common wire for at least 100 us"* — i.e. it is a pulled-up, pull-to-common input. That is
  exactly what an arduinoTTL BNC does in `2=OUT,HIGH`, which idles high and fires low.
* **Sync out** is a negative-polarity TTL pulse whose falling edge marks the stimulus start, and
  the manual gives its width as **1 +- 0.05 ms** for photo and pattern stimulation.

⚠ **That contradicts the SDK.** `SynchroOutDuration` in the private register reads `_100_mks`
(§5), while the manual says 1 ms. Both cannot be right and neither has been measured directly —
an edge-latching receiver cannot tell them apart. Resolve it with a scope, or by sampling in
level mode at a rate where 100 us and 1 ms differ in catch fraction.

**Tip and ring are easy to swap, and doing so is not harmless.** Measured: with the cable
believed to be on the sync input, the board fired 8 pulses into it on all four polarity
combinations and the NS-65 reported nothing — while the board's own IN2 counter, listening on the
same wire, counted **10 edges for 10 stimulator pulses**. The cable was on the sync **out**. So
the board's push-pull pin and the amplifier's sync driver were facing each other.

The 1 kOhm series resistor bounds that contention to about 5 mA, which an AVR pin survives, so
contention alone does not explain a board that stops executing. What it does explain is why a
**ground** connection is the dangerous step: until the commons are joined there is no return
path and a miswire does nothing at all, so the fault appears at the moment the ground wire goes
on rather than when the signal wire did.


<a id="history-6b-the-ns-65-sync-input-works-and-locates-an-edge-to-one-16-khz-sample"></a>

## 6b. The NS-65 sync INPUT works, and locates an edge to one 16 kHz sample

Once the cable was moved from the ring to the tip, the input answered immediately: **8 of 8
pulses received on all four combinations** of BNC2 idle level and `InverseSynchInPolarity`. That
it works in all four is expected rather than surprising — a 50 ms pulse carries one falling and
one rising edge, so whichever the input selects there is exactly one per pulse.

A 40-pulse board-timed train then gave the timing, with the board's `micros()` as ground truth:

| | |
|---|---|
| Received | **40 of 40**, none lost |
| Clock ratio, NS-65 against the board | +44.2 ppm |
| **Residual RMS after the fit** | **18.5 us** |
| Predicted for pure quantisation | **18.0 us** (= 62.5 us / sqrt 12) |
| Residual max | 33.5 us, against a half-quantum of 31.25 us |
| Interval | median 200.000 ms for a commanded 200.000 |

**This is an independent confirmation of §9's quantisation claim, arrived at from the opposite
direction.** The 62.5 us figure was derived by decompiling the vendor SDK; here it falls out of a
hardware measurement that knows nothing about the IL. Had the offset been genuinely sub-sample,
the residual would sit far below 18 us. The amplifier locates an external edge to +-half of one
16 kHz sample and no better.


<a id="history-6c--the-ns-65-timestamps-the-pulses-trailing-edge-not-its-leading-one"></a>

## 6c. ⚠ The NS-65 timestamps the pulse's TRAILING edge, not its leading one

Found in a recording rather than in a probe, and it would be invisible to any test that used one
pulse width throughout.

A session recording 74 pulses of deliberately mixed widths — P500, P100, P20, P5, P1, and trains
at widths 20, 10, 100 and 8 ms — matched the board's stamps against the amplifier's sync-in
events. Interval for interval the two agree to a **median of 12 us**, comfortably inside the
62.5 us quantum. Every disagreement sits at a boundary between pulses of *different width*, and
equals the width difference:

| pulses | widths | board minus amplifier | width difference |
|---|---|---|---|
| 0 -> 1 | 500 ms -> 100 ms | 399.9 ms | 400 |
| 1 -> 2 | 100 ms -> 20 ms | 79.9 ms | 80 |
| 2 -> 3 | 20 ms -> 5 ms | 14.9 ms | 15 |
| 3 -> 4 | 5 ms -> 1 ms | 3.8 ms | 4 |
| 4 -> 5 | 1 ms -> 20 ms | -19.0 ms | -19 |
| 34 -> 35 | 10 ms -> 250 ms | -240.1 ms | -240 |

The board stamps the pin write at the pulse's **start**; the amplifier's event lands one pulse
width later. With `sync_in_inverted = false` and a source that idles HIGH and fires LOW, the
amplifier is therefore marking the **end** of the pulse.

**This contradicts the manual**, which says *"спад импульса будет определяться как начало
синхронизации"* — the falling edge is taken as the sync start (p93).

⚠ **The consequence is severe and silent.** A 500 ms pulse is dated 500 ms late, and a constant
pulse width makes the error a constant offset that no consistency check inside one session can
reveal. Anything deriving a latency from this stream — an ERP, an evoked potential, a TEP epoch —
is wrong by the stimulus pulse width unless the polarity is set to compensate or the offset is
subtracted.

**Confirmed and fixed by inverting.** A dedicated test alternating 300 ms and 20 ms pulses —
a constant width cannot answer this, because a constant offset cancels out of every interval:

| `sync_in_inverted` | swing | median difference | marks |
|---|---|---|---|
| **0** (the old default) | 280.0 ms, exactly wide minus narrow | 279.968 ms | **trailing edge** |
| **1** | 0.0 ms | **0.057 ms** | **leading edge** |

At `true` the amplifier agrees with the board to 57 us, inside the 62.5 us quantum.

**Fixed.** `sync_in_inverted` now defaults to **true** in `neuronspectrumconfig.cpp:401`, and the
parameter description carries the measured numbers instead of the previous admission that the edge
was "neither documented by the vendor nor measured here". False was wrong for exactly the source
the NS-65's own manual specifies — idle high, fire low. Rebuilt and deployed to
`R:\dist\msvc64\bin\neuronSpectrum.exe` (2026-08-17); the shipped binary was checked against the
build output by hash, not assumed.

Recordings made **before** this change carry the trailing-edge offset. Two are kept deliberately
(§6d) so the defect stays reproducible from the archive rather than only from this description.


<a id="history-6d-the-archived-recordings-and-a-dropped-event-at-16-khz"></a>

## 6d. The archived recordings, and a dropped event at 16 kHz

Four sessions in `R:\dist\_build\trigger-campaign\`, each recording the `neuronSpectrum` and
`arduinoTTL` services together. Written by `config/ttl_ns65_record_harness.qml` and
`config/ttl_ns65_record_16k_harness.qml`; checked by `config/verify_ttl_ns65_recording.py`.

Every file carries four groups: `eeg` (24 channels plus the synthesised Trigger lane),
`events` (the amplifier's sync-in, each with its absolute 16 kHz device sample), `events_1`
(the board's own `micros()` stamp per pulse) and `annotations`. The stimulus program is the same
in all four — 13 groups spanning P500 down to P1, trains at 10, 20 and 30 Hz, and mixed widths,
**74 pulses** in total. Mixed widths are the point: a uniform width cannot expose §6c.

| file | rate | size | `sync_in_inverted` | board / amp | interval agreement |
|---|---|---|---|---|---|
| `ttl-ns65-001.h5` | 1 kHz, anti-aliased | 8.7 MB | false | 74 / 74 | **399.9 ms** worst — the defect |
| `ttl-ns65-16k-001.h5` | 16 kHz, unfiltered | 136.4 MB | false | 74 / 74 | same defect at full rate |
| `ttl-ns65-v2-001.h5` | 1 kHz, anti-aliased | 8.7 MB | **true** | 74 / 74 | median 0.016 ms, max **0.159 ms** |
| `ttl-ns65-16k-v2-001.h5` | 16 kHz, unfiltered | 136.4 MB | **true** | 74 / **73** | median 0.008 ms, max 0.125 ms |

The first two are kept on purpose: they are the primary evidence for §6c, and deleting them would
leave the defect documented only by assertion.

The 16 kHz files use the device's own conversion rate with `decimation = Drop`, so nothing is
decimated and no anti-alias filter is in the path — the condition asked for. Both run
**1772 blocks of exactly 400 samples, 708 800 samples, 44.3 s, zero NaN**: the bridge and driver
sustain full rate with no ring overflow, which is itself the first evidence that they can.

⚠ **One sync-in event was dropped at 16 kHz.** `ttl-ns65-16k-v2-001.h5` holds 73 amplifier events
against 74 board pulses. It is a lost event and not a timing failure: removing the unmatched board
pulse aligns the remaining 73 to a **median of 0.008 ms and a maximum of 0.125 ms**, better
agreement than the 1 kHz file. The missing one is **board pulse 27, the third of the `T20,50,10`
train** — 20 Hz, 50 ms spacing, nothing unusual about its width or its neighbours.

**It is not a rate effect.** Two later sessions (§6e) repeated the same 74 pulses at 1 kHz and at
16 kHz: the **1 kHz** one dropped an event and the 16 kHz one was perfect — the opposite way round
from this file. So across six sessions and 444 pulses into the sync input, **two were lost, at
different rates**, and the drop is sporadic rather than tied to 16 kHz.

Both losses are in the amplifier's own `events` stream, and in both the surviving events keep
their timing to a median of 0.008 ms — so this loses a mark, it does not disturb the ones it
keeps. Cause unknown. ⚠ **Anything depending on a one-to-one event count must compare `events`
against its own stimulus log rather than assume the counts match**; at roughly 1 in 200 this will
appear in any long session. Note the trigger lane in `eeg` is synthesised from the same events, so
it drops the same mark and is not an independent check.


<a id="history-6e-the-sync-out-can-now-be-fired-from-the-service-and-a-count-bug-that-only-hardware-found"></a>

## 6e. The sync OUT can now be fired from the service, and a count bug that only hardware found

Until this change the `neuronSpectrum` service could configure the SYNC OUT socket and never
drive it: `sync_out_source` and `sync_out_inverted` were written to the device, but nothing in
`neuronspectrumdriver.cpp` ever called `NS_StimStart`, so the socket stayed idle. The §5
measurement drove the bridge directly, which is why it worked and the service did not.

**What was missing was not just a call.** The socket is wired to a stimulator — this amplifier has
no host-arbitrary output line — so setting `SynchroOutSource` alone routes a signal that nothing
is generating. The stimulator's module has to be powered too, which `applySync` now does at Start.
Powering it needs no lamp attached: it is a control-unit operation, which is exactly what makes
the socket usable as a plain trigger output.

Added: `sync_out_count` (0 = endless, the device's own encoding), `sync_out_period`,
`sync_out_flash`, and `Fire` / `Stop` buttons. They are `Parameters::Action` rather than values
because a fire must repeat on demand — a value-typed parameter only acts when it *changes*, so
firing the same train twice would do nothing the second time.

⚠ **`sync_out_flash` is the lamp's flash duration, not the width of the pulse on the socket.**
That stays a fixed 100 µs with no setter anywhere in the SDK (§6a). It is exposed only because the
SDK refuses a duration longer than the period and the pair must be written consistently.

<a id="history-the-count-bug"></a>

### The count bug

The first implementation started a stimulator that the SDK still considered running.
`NS_StimStart` returned `NS_ERR_OK`, the service logged `sync out fired 5 pulse(s) at 0.1 s`, and
the socket emitted an **unbounded train**. The count was silently lost.

Nothing short of a second device counting the pulses could have caught it. Measured on the board:

| fire | requested | in2 counter | actual |
|---|---|---|---|
| 1st | 10 at 200 ms | 1 → 11 | correct |
| 2nd | 1 | free-running | ≈5/s — the 200 ms period |
| 3rd | 5 at 100 ms | free-running | ≈10/s |
| 4th | 20 at 50 ms | free-running | ≈20/s |

Every rate matches the period that was set, which is what identifies it as a train that never
stopped rather than as spurious edges. `fireSyncOut` now calls `NS_StimStop` unconditionally
before configuring — including when nothing is believed to be running, because "it was not
running" is a perfectly good answer there and not an error worth reporting.

<a id="history-measured-both-directions-in-one-recording"></a>

### Measured, both directions in one recording

Two sessions in `R:\dist\msvc64\data`, at 1 kHz and at 16 kHz unfiltered, each with a phase A
(board → sync IN, mixed widths) and a phase B (sync OUT fired from the service, 36 pulses):

| | 1 kHz | 16 kHz unfiltered |
|---|---|---|
| phase A, board → amplifier | 74 → **73** | 74 → **74** |
| phase A interval agreement | median 0.008 ms, max 0.144 ms | median 0.008 ms, max 0.155 ms |
| phase B, service → board | **36 → 36** | **36 → 36** |
| board `in2` counter rise | **+36** | **+36** |
| 200 / 100 / 50 ms spacing | median error **0.000 ms** | median error **0.000 ms** |

The output's placement is as good as the amplifier's own clock: at every requested rate the
median interval error is **zero to the 62.5 µs quantum**.

<a id="history-the-branches-the-recording-did-not-exercise"></a>

### The branches the recording did not exercise

Written but never run is the state the count bug shipped in, so the remaining sync-out branches
were driven deliberately, with the board's `in2` counter as the instrument and **no phase marks in
the file** — the counter is segmented into rising and flat runs by
`config/analyze_syncout_lifecycle.py`, so a phase either appears in the data or it did not happen.
Evidence: `R:\dist\_build\trigger-campaign\ns65-syncout-lifecycle-001.h5`.

| branch | requested | counter | |
|---|---|---|---|
| endless, then `Stop` | `count = 0` | +47 rising, then flat 6.5 s | ✅ |
| finite count after a Stop | 5 | +5 | ✅ |
| **service stopped mid-train** | `count = 0` | +37, then flat 12.5 s | ✅ |
| restart, then fire | 5 | +5 | ✅ |
| absurd period and flash | 1 ms / 60 s | clamped to 10 ms / 10 ms, +5 | ✅ |
| **pattern stimulator as source** | 5 | **+1** | ❌ |

Every rising run is followed by a flat one, which is the property that matters: **no train ever
outlived its stop**, including one running when the service itself was stopped. That last case
rests entirely on `closeDevice`, because the bridge never stops a stimulator on its own.

⚠ **The pattern stimulator does not drive the socket.** It reports success and emits a single edge
for a five-pulse train. **Use the photic stimulator.** The likely reason is that it needs a display
attached — its stimulus *is* a screen inversion, where the photic stimulator's module is
meaningful with an empty socket — but that is untested; what is measured is only that it does not
pulse.

**The clamp found the module's real floor: a 10 ms period**, and a flash clamped to the period.
There was no way to know that before `NS_StimGetBounds`; the SDK reports the bounds and previously
nothing asked.

⚠ **The service Start appears to emit one spurious edge on the sync OUT.** Both restarts in this
run show a small isolated step (+1, then +2) *before* the commanded fire. This is consistent with
the sync IN side, where a register write itself produces an event (§7). It is inferred from
position rather than measured directly and needs its own test — but **treat a recording's first
sync-out mark as suspect until it is settled**, exactly as §7 warns for the input.

⚠ **The control that makes phase B meaningful** is that the board's `in2` counter stayed flat
through the whole of phase A — 74 pulses into sync IN produced *no* edges on sync OUT. Without
that, a rise in phase B could have been the amplifier's input leaking to its output through the
shared 2.5 mm connector, and the measurement would prove nothing. Note also that the counter reads
zero in the last status sample: the board zeroes its counters when the harness disconnects it, so
the rise must be taken against the peak, not the final value.


<a id="history-7--nvx-out--ns-65-sync-in-retracted-the-test-was-miswired"></a>

## 7. ⚠ NVX out → NS-65 sync in: RETRACTED, the test was miswired

An earlier revision of this document reported this direction as a hardware fault and listed
bench checks for the NVX output. **That conclusion is withdrawn.**

The 2.5 mm plug was subsequently proven to be on contact 3, the sync **out**, not contact 2, the
sync **in** (§6a). Every NVX-to-NS-65 run was therefore driving the amplifier's output pin, and
its input was never connected to anything. The result says nothing about the NVX output, which
remains **unverified in the physical sense**: only `Status` bit 9, the device's internal
readback, has ever been observed following `NVXSetOut`.

To settle it, re-run with the NVX output on the tip and its ground on the sleeve. The NS-65 input
is now known-good, so a null result would then be attributable.

⚠ One measurement here was nearly a false positive and the guard is worth keeping. A single
sync-in event appeared right after `NS_SetSyncInInverted` was written; repeating with the
polarity **set and settled before any pulse** gave zero. **The register write itself produces an
event.** Any test that changes polarity inside its measurement window will count it as a hit.

---


<a id="history-7a-nvx-52-after-the-connector-repair--both-directions-and-1000-triggers"></a>

## 7a. NVX-52 after the connector repair — both directions, and 1000 triggers

⚠ **The output leg of the NVX trigger connector had its trace torn off the pad.** It was repaired
on 2026-08-18. Every NVX *output* result recorded before that date is void rather than merely
unverified, including the retraction in §7 — there was nothing to measure.

Re-measured after the repair, with the board's output on an NVX input and the NVX output on the
board's reader. Evidence: `R:\dist\msvc64\data
vx-trigger-validation-001.h5`, analysed by
`config/analyze_nvx_trigger_validation.py`. NVX at 2 kHz, block 100, `NVX_TRG_REAR`.

<a id="history-pin-map-re-measured"></a>

### Pin map, re-measured

| | |
|---|---|
| board BNC1 → NVX input | **bit 8**, rests HIGH |
| NVX output readback | **bit 9**, rests LOW once the driver has written it |
| idle word | `0x0000EFFF`, unchanged |

<a id="history-input-reliability--the-1000-pulse-question"></a>

### Input reliability — the 1000-pulse question

Asked because the NS-65 loses roughly 1 sync event in 200 (§6d) and the board is the common
element. **1000 pulses at 50 Hz, 2 ms wide:**

| | |
|---|---|
| board fire events | **1000** — it delivered exactly what it was asked for |
| NVX input edges, whole file | **1065** = 5 probe + 1000 train + 60 echo, exactly as expected |
| lost | **none** |

**This clears the arduinoTTL board.** It delivered 1000/1000 and the NVX recorded every one, so
the NS-65's losses are on the NS-65 side of the cable, not in the source. It also gives the NVX a
much stronger reliability figure than the NS-65 has: zero loss in 1065 against two in 444.

<a id="history-output-and-a-round-trip-measured-without-leaving-the-devices-timebase"></a>

### Output, and a round trip measured without leaving the device's timebase

Because bit 9 reads the output back into the same status word that carries the input, the whole
loop can be timed in NVX samples — no host clock, no assumption about scheduling:

> `NVXSetOut` releases → cable → board detects → board echoes a pulse → NVX input bit latches it

| | |
|---|---|
| matched | **60 of 60** |
| round trip | median **0.000 ms**, max **1.5 ms**, sd 0.32 ms |
| distribution | 0.0 ms ×46, 0.5 ms ×12, 1.5 ms ×2 |

At 2 kHz one sample is 0.5 ms, so **the entire loop closes inside a single sample 77 % of the
time**. The output is active-HIGH and follows `trigger_state` directly; the board's falling-edge
reader saw the *release* edge, and never the assert, which is what confirms the polarity.

<a id="history--retracted-there-is-no-input-to-output-mirroring--it-was-a-bad-connector"></a>

### ⚠ RETRACTED: there is no input-to-output mirroring — it was a bad connector

An earlier revision of this section reported, as a measured finding, that the NVX-52 mirrors its
trigger input onto its physical output. **That conclusion is withdrawn.** It was an artifact of the
BNC2 connector's state, and the experiment that "proved" it was confounded.

The observation was real: the board's reader counted an edge for every pulse sent into the NVX
**input** — 200 for 200 — while the bit-9 readback did not move. Unplugging the NVX-OUT lead
removed those counts, which appeared to localise them to the amplifier's output pin.

**The flaw:** unplugging and *reseating* are the same intervention on the same connector. A third
run, with the lead reconnected, separates them:

| identical stimulus | baseline | lead unplugged | **reconnected (recheck)** |
|---|---|---|---|
| board fire events | 200 | 200 | 200 |
| NVX input edges, bit 8 | 201 | 201 | 201 |
| bit 9 readback | 10 / 10 | 10 / 10 | 10 / 10 |
| counts from the 200-pulse **input train** | **200** | 0 | **0** |
| counts from **10 commanded asserts** | 10 | 0 | **10** ← path proven good |

In the recheck the output path is *demonstrably* connected — ten commanded asserts arrived, 10 of
10 — and under that same condition the 200 input pulses produced **nothing**. So the amplifier does
not pass its trigger input to its trigger output. The 200 counts in the baseline were pickup on a
connection that had not been properly seated, and reseating it removed them.

**What the two runs should have had, and now do:** a positive control inside the same run. "The
counts went away" is worthless on its own — it is equally consistent with breaking the path you
meant to test and with breaking the path you meant to keep. The commanded asserts are that control,
and they are what makes the recheck conclusive where the unplug was not.

Two further checks agree with the retraction. A standing echo rule seeded from the NVX output
**never oscillated** at any pulse width down to the 1 ms firmware floor — one fire per seed, every
time — and the board's `miss1` counter stayed at **0**, so no returning edge arrived during the
board's own pulse either. Under real mirroring both would have been non-zero.

**Unaffected by this retraction:** the 1000-pulse input reliability (1065/1065) and the round-trip
latency, both of which are measured on the input bit and on commanded asserts — paths verified
working in every run above.

<a id="history-driver-changes-this-prompted"></a>

### Driver changes this prompted

* `trigger_state` is now a **`Parameters::Boolean`** — a checkbox. It was a 0..3 spin box offering
  a numeric range where the hardware has two states.
* ⚠ **The amplifier powers up with its trigger lines HIGH**, so the output is asserted before any
  software writes to it. The driver now **drives the line to the parameter's value at every
  Start**, so the checkbox describes the line instead of making a claim about it.
* The key is deliberately still `trigger_state`: `applyParameters` screens parameter *names*
  before applying any of them, so renaming would make every saved configuration mentioning it fail
  as a whole. The JSON type does change from number to bool, so an older saved set is refused for
  this one parameter.


<a id="history-8-not-verified"></a>

## 8. Not verified

Stated plainly, because the rest of this reads like completion.

* **NVX out → NS-65 sync in has never been validly tested** (§7). The cable was on the wrong
  contact throughout, so there is no result either way, and the NVX output remains unverified as
  a physical signal.
* **The sync-out pulse width is disputed**: the manual says 1 +- 0.05 ms, the SDK's private
  register says 100 us (§6a). Neither has been measured; an edge-latching receiver cannot tell
  them apart.
* ~~The sync output cannot be fired from the `neuronSpectrum` service.~~ **Fixed — see §6e.**
* **The synthesised NS-65 trigger lane is not group-delay corrected.** The latch is placed on the
  output sample containing the event's raw *input* sample, while the analog lanes published for
  that same sample are a symmetric anti-alias average centred ~22 input samples earlier — so with
  the default filter the lane leads the data by ~1.4 ms at 1 kHz / order 3.
  `boxCascadeDelaySamples()` already exists in `neuronspectrumlogic.h` for exactly this number
  and nothing outside the unit tests calls it. **Measure from the `events` stream, not the lane.**
* **No 10 kHz or 50 kHz NVX run**, and no bipolar or impedance mode. Everything is 250 Hz–5 kHz
  normal mode.
* **Whether the NVX mirrors its trigger input to its output is unresolved** (§7a) — one rewire
  settles it.
* **The NVX 5 kHz sample loss is the vendor's, not ours**: 10.717 % of the timeline, in a regular
  pattern of 2–3 missing samples every ~20, reproduced in the vendor's own recording application
  at any channel count and under both SDK generations. See [nvx-sdk-questions.md §1](../vendor-correspondence/nvx-sdk-questions.md).
* **The pattern stimulator does not drive the sync OUT** (§6e) — one edge for a five-pulse train.
  Whether it needs a display attached is untested; only the photic stimulator is usable today.
* **The spurious edge at Start is inferred, not measured** (§6e). It needs a dedicated run that
  starts the service with the board counting and fires nothing.
* **The sporadic sync-in event loss has no explanation** (§6d): two events lost in 444 across six
  sessions, at both 1 kHz and 16 kHz, so it is not a rate effect. Whether it is in the amplifier,
  the SDK's event queue or the bridge's drain is open, and separating those needs a run long
  enough to collect enough losses to characterise — thousands of pulses, not hundreds.
* **The clock-ratio disagreement in §4.2 is unresolved.**
* **`mingw32` / `mingw64` have not compiled the bridge change**, and by design never will — the
  module is MSVC-gated.


<a id="history-9-corrections-this-campaign-owes-other-documents"></a>

## 9. Corrections this campaign owes other documents

* `neuron-spectrum.md:146,156,161` and `STATUS.md:797,802` describe the NS-65 event offset as
  **sub-sample**. It is not: the SDK computes `offset = samplesCount / 16000.0`, so the quantum
  is exactly one 16 kHz sample, **62.5 µs**, and two events inside one sample collapse into one.
  The same claim is in `ns65bridge.h` and `neuronspectrumdriver.h`, which this change corrected.
* `nvx/application.cpp:132` describes two output lines (§3).
* `NVX.h`'s Status-word comment is off by one (§2.1).


<a id="history-10-what-this-campaign-changed-and-what-is-deployed"></a>

## 10. What this campaign changed, and what is deployed

Two defects were found and both are fixed in source, built, and deployed to `R:\dist\msvc64`
(full `msvc64` rebuild, 35/35 targets, 2026-08-17). Deployed binaries were verified against the
build output by MD5 rather than assumed from a successful compile.

| change | file | effect |
|---|---|---|
| `trigger_state` capped at 1, was 3 | `nvx/application.cpp` | the parameter no longer offers two output lines this hardware does not have (§3) |
| `sync_in_inverted` defaults true, was false | `neuronSpectrum/neuronspectrumconfig.cpp:401` | the sync input timestamps the pulse's leading edge, ending a silent error equal to the stimulus width (§6c) |
| 16 new bridge entry points | `neuronSpectrum/bridge/ns65bridge.{h,cpp}` | sync power / in / out / stimulator reachable at all — none of it was previously exposed |
| `eventPush` records its own absolute sample | `neuronSpectrum/bridge/ns65bridge.cpp` | events carry a sample index that survives block boundaries |
| SYNC OUT firable from the service | `neuronspectrumdriver.{h,cpp}`, `neuronspectrumconfig.{h,cpp}` | the socket is driven, not merely configured: the stimulator is powered at Start and `Fire` / `Stop` run it (§6e) |
| `NS_StimStop` before every configure | `neuronspectrumdriver.cpp` | fixes a silently unbounded train — the requested count was lost on every fire after the first (§6e) |
| `NS_StimGetBounds` | `neuronSpectrum/bridge/ns65bridge.{h,cpp}` | the driver clamps period and duration into the module's own limits instead of being refused by bounds it would have to guess |

Both parameter descriptions were rewritten to carry measured values instead of the previous
admissions that the behaviour was undocumented and unmeasured.

**`mingw32` and `mingw64` do not have the bridge change and never will** — the module is
MSVC-gated by design. The `sync_in_inverted` default is in `neuronspectrumconfig.cpp` and so is
equally MSVC-only, since the whole module is.
