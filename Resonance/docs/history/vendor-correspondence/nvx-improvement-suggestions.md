# Suggestions for the NVX / NVX136 hardware, firmware and SDK — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../decisions/proposals/vendor-sdk-inquiries.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-suggestions-for-the-nvx--nvx136-hardware-firmware-and-sdk"></a>


**Prepared 2026-08-18.** Offered in the spirit of a long-term user who intends to keep building on
these amplifiers. Everything here comes from measurements on our own NVX-52 and NVX136 during
August 2026; where a suggestion rests on inference rather than measurement, it says so.

Ordered by what we think would help most, not by how easy it is. Section 1 is an architectural
proposal rather than a defect report: a PCI Express media converter, keeping the existing fibre
link, to remove a latency floor that USB imposes structurally. The rest are smaller and mostly
concern letting software see what the device already knows.

---


<a id="history-1-transport-a-pcie-media-converter-would-remove-a-latency-floor-usb-cannot"></a>

## 1. Transport: a PCIe media converter would remove a latency floor USB cannot

**The question is how soon a sample can be acted on, not how many samples per second fit down the
cable.** Throughput is not in doubt — the NVX136 already sustains about 13.6 MB/s over USB at
25 kHz across 70 channels without loss. The constraint that matters for closed-loop work is
different: with USB the host cannot have a sample until the next packet arrives, and when that
packet arrives is decided by the host controller's schedule rather than by the amplifier.

*(Nothing in this section concerns the NVX-52's 5 kHz sample loss. That is a defect in a different
and much simpler product, and we expect it to be a firmware matter — it is raised separately in
our question list, not here.)*

<a id="history-11-why-usb-imposes-a-floor"></a>

### 1.1 Why USB imposes a floor

USB is a host-polled bus. A device cannot deliver data when it has data; it delivers when it is
asked, in the slot the controller allocates:

* transfers are quantised to the **125 µs microframe** on high speed, so that is the best case
  before any software runs;
* the amplifier cannot signal urgency — there is no device-initiated transfer, only an answer to
  an IN token;
* the host stack adds its own scheduling, and a user-space SDK adds a copy and a wakeup on top;
* to avoid overhead, drivers batch — the NVX SDK's "read at least once per second" requirement
  implies a substantial internal ring, and any batching is added directly to the latency budget.

At 25 kHz a sample is 40 µs, so even the microframe alone is roughly three samples, before the
driver, the SDK and the scheduler have taken their share.

<a id="history-12-what-pcie-changes"></a>

### 1.2 What PCIe changes

A PCIe media converter with the **same fibre link to the ADC unit** changes the delivery model
rather than the bandwidth:

* the device **writes into host memory by DMA when it has data**, instead of waiting to be asked;
* completion is signalled by **MSI/MSI-X**, in the order of microseconds rather than the hundreds
  of microseconds a polled bus needs;
* with a DMA ring, a host thread can watch a memory location and see new samples **without a
  syscall at all** — the "wait for the next packet" step disappears rather than shrinking;
* the timing becomes deterministic, which for closed-loop work matters more than the mean: a
  bounded worst case is worth more than a good average.

For neurofeedback, BCI, or stimulation triggered on a detected feature, this is the difference
between a budget dominated by transport and one dominated by the algorithm.

<a id="history-13--isolation-is-not-an-argument-against-this--correcting-our-own-earlier-reading"></a>

### 1.3 ⚠ Isolation is not an argument against this — correcting our own earlier reading

An earlier draft of this document objected that a PCIe card would compromise patient isolation.
**That was wrong, and we withdraw it.** The isolation in the NVX136 lives in the **fibre link
between the ADC unit and the media converter**. The media converter itself is USB-powered and
referenced to PC ground — its DB-9 trigger lines are tied to PC ground and 5 V, and the vendor
manual states plainly that the synchronisation channels are *"not galvanically isolated from the
PC"*.

So a PCIe converter keeping the same fibre link **preserves patient isolation exactly as it is
today**. The card would sit on PC power and ground, which is precisely where the media converter
already sits.

If anything this is an opportunity: a card with **optically isolated trigger I/O** would be
strictly better than the present arrangement, in which a trigger cable to another instrument ties
that instrument's ground to the PC's.

<a id="history-14-the-real-costs-and-a-middle-path"></a>

### 1.4 The real costs, and a middle path

We would not want to understate what this asks of you:

* a PCIe device needs a **kernel-mode driver** — WDF, signing, and eventually WHQL — which is a
  different maintenance burden from a user-space USB library;
* a card is **desktop-only**, and some of our own rigs are laptops;
* it is a new hardware design rather than a firmware revision.

**Thunderbolt / USB4 is worth considering as a middle path.** It tunnels PCIe over a cable, so an
external converter could present as a PCIe device with DMA and MSI, keep a cable and a distance,
and still work with laptops. The driver model is the same as for a card. PCIe-over-cable is a
further variant of the same idea.

**If the bus stays USB**, two things would still help materially:
* let the host choose a much smaller delivery granularity, with an **interrupt or isochronous
  endpoint** rather than large buffered bulk reads;
* document what the achievable floor actually is (see below), so integrators can design to it.

<a id="history-15-the-question-that-decides-this-where-is-data-held-and-for-how-long"></a>

### 1.5 The question that decides this: where is data held, and for how long?

A sample crosses several stages between conversion and the point where our code can act on it, and
**any stage that accumulates data before passing it on adds directly to the latency budget.** Only
the last two are ours; the rest we cannot see into.

| # | Stage | Who can measure it |
|---|---|---|
| 1 | ADC conversion in the amplifier module | you |
| 2 | Amplifier packs samples and sends over the fibre | **you** |
| 3 | Media converter holds them before presenting to USB | **you** |
| 4 | USB transfer scheduling (microframe, host controller) | either, in principle |
| 5 | Windows USB stack | either |
| 6 | NVX DLL internal ring, before `NVXGetData` will return | **you** |
| 7 | Our chosen block size | us |
| 8 | Our service assembling and publishing a block | us |

**This is what decides whether a change of bus is worth your effort.** If stages 2, 3 or 6
accumulate several milliseconds, then replacing USB removes stage 4 and leaves the rest — a large
engineering cost for a small share of the total. If instead those stages stream continuously and
the delay really is USB scheduling plus the DLL's ring, then PCIe moves the floor from roughly a
millisecond to roughly ten microseconds, and the case is strong.

**Specifically, we would like to know:**

1. What is the smallest unit the ADC unit sends over the fibre — a single sample, or a block? At
   what interval?
2. Does the media converter accumulate before data becomes available on USB, and if so how much?
3. Does `NVXGetData` return as soon as any sample is available, or does it wait for a threshold?
   How large is the DLL's internal ring?
4. Is the "read at least once per second" requirement the consequence of a fixed-size ring, and
   what is that size?
5. Is there a figure — measured or specified — for *sample converted → visible to `NVXGetData`*?

**What we measured.** We have since built a probe service that watches the amplifier's trigger
word and, the instant a stimulus bit changes, commands that same amplifier's trigger output. Since
the output readback lives in the *same* status word, the entire loop is timed in the amplifier's
own samples — no cross-clock comparison anywhere. Measured on an NVX-52 at 2 kHz, 25 stimuli per
point, sweeping the block size across a 47-fold range:

| block requested | delivered | block duration | median reaction | min | sd | our host-side share |
|---|---|---|---|---|---|---|
| 1 | 4 | 2.0 ms | **15.5 ms** | 13.0 | **1.90** | 1.78 ms |
| 5 | 5 | 2.5 ms | 20.5 ms | 12.5 | 6.16 | 1.85 ms |
| 20 | 20 | 10.0 ms | 22.5 ms | 13.5 | 5.75 | 3.89 ms |
| 50 | 32 | 16.0 ms | 22.0 ms | 12.5 | 10.61 | 8.34 ms |
| 250 | 188 | 94.0 ms | 32.5 ms | 21.5 | 7.56 | 16.77 ms |

⚠ **The reaction stops falling at about 12.5 ms and no host setting goes below it.** With a 2 ms
block our own contribution is **1.78 ms**, and the total is still 15.5 ms median with a 13.0 ms
minimum. So roughly **12–13 ms belongs to the amplifier, the SDK and the command path**, and is
invisible from here.

Two further observations:

* **A request for block 1 or 2 is not honoured** — both delivered 4 samples. There appears to be a
  delivery-granularity floor of about 4 samples at 2 kHz. What sets it?
* **Small blocks are dramatically more consistent**: at block 1 the spread is sd 1.90 ms against
  6–17 ms at every larger setting. For closed-loop work the bounded worst case matters more than
  the median, so this is the more important half of the result.

**What this figure does and does not contain.** It is a round trip: it includes the outbound path
(our command → `NVXSetOut` → the pin → the readback appearing in a sample) as well as the inbound
one. We can separate the two by timing a directly commanded output against its own readback, and
will do so. Even undivided, though, the conclusion holds: **the part of a closed-loop budget that
the host can influence is a few milliseconds, and the part it cannot is around twelve.** That is
the ratio that makes the transport question worth asking.


<a id="history-2-clock-discipline-give-the-host-a-way-to-measure-and-correct-drift"></a>

## 2. Clock discipline: give the host a way to measure and correct drift

Over a long recording the amplifier's clock and the host's clock diverge, and there is currently
no supported way to measure that divergence, let alone correct it.

<a id="history-21-what-we-found-while-looking-for-one"></a>

### 2.1 What we found while looking for one

The NVX136's PLL is settable at fine resolution — `t_NVXPll.PllFrequency` in Hz, 10–27 MHz,
default 25.6 MHz — so an obvious idea is to trim the ADC clock until it matches the host. Two
things stop this from being a usable technique today:

1. **`NVXSetPll` is a start-time setting.** It cannot be adjusted while acquiring, so a control
   loop would have to stop and restart the acquisition on every correction. That rules it out for
   drift tracking during a session.
2. **`t_NVXPll.Status` is documented only as "PLL status".** We do not know what its values mean,
   so we cannot tell a locked external reference from an unlocked one. Our own driver documents
   this as "there is no lock indicator", which may be unfair to the field — but nothing tells us
   otherwise.

<a id="history-22-what-we-would-suggest-instead"></a>

### 2.2 What we would suggest instead

In rough order of usefulness:

* **A per-block device timestamp**, taken from the amplifier's own clock, delivered alongside the
  data. This single addition would let any host measure drift exactly, and resample or annotate as
  it sees fit — no clock steering needed, and it works over USB.
* **Allow the PLL frequency to be trimmed while running**, so a host that wants to close the loop
  can. The resolution is already there.
* **Document `t_NVXPll.Status`** — at minimum, which value means "locked".
* **A documented specification for the clock itself**: nominal accuracy in ppm, and temperature
  coefficient. Knowing the amplifier is, say, ±20 ppm tells us how much drift to expect over an
  hour without measuring it.

**A note on the external-clock input**, since we were asked whether it could be used to lock the
amplifier to the PC. In principle yes — feed a PC-derived reference into the BNC Sync-In and the
ADC follows it. In practice a PC has no disciplined 3–27 MHz output to give, and a PC's own
oscillator is a poor master anyway. **The better arrangement is the reverse**: let the amplifier be
the good clock, and give the host the timestamps it needs to align to it. That is what the first
suggestion above does.

---


<a id="history-3-error-reporting-the-nvx136-does-this-well-and-the-nvx-api-does-not"></a>

## 3. Error reporting: the NVX136 does this well and the NVX API does not

**Credit where it is due.** The NVX136 SDK offers `NVXGetErrorStatus`, returning total samples,
CRC errors, counter errors and per-device errors, plus `NVXGetDataStatus`. That is exactly the
right shape.

**⚠ In fairness, we should say that our NVX136 driver does not yet read either of them** — that
is our gap, not yours, and we are fixing it. We mention it because it makes the next point sharper
rather than weaker.

**The NVX (24/36/52) API has no equivalent.** We searched: there is no acquisition error-status
call. `NVXGetStreamStatus` exists but concerns the TET stimulus stream. So on the NVX-52, a host
that wants to know whether it lost data must derive it from the per-frame `Counter` — which works,
and is how we quantified the 5 kHz fault, but means every integrator reimplements it and only
those who think to look find anything at all.

⚠ **Capacity failures on the NVX-52 are entirely silent.** At 2 kHz, block 19000 gave no missing
data but multi-second latency; block 20000 was the first case that lost data. Nothing — no return
code, no status, no counter exposed by the API — announced either transition.

**Suggested:**
1. Bring `NVXGetErrorStatus` / `NVXGetDataStatus` to the NVX API, with the same fields.
2. Return a distinct error code from `NVXGetData` when frames have been dropped since the last
   call, rather than returning success with a gap in the counter.
3. Document the per-frame `Counter` as the supported way to detect loss, since it is.

---


<a id="history-4-impedance-three-changes-would-remove-most-of-the-difficulty"></a>

## 4. Impedance: three changes would remove most of the difficulty

Impedance on the NVX136 took us the longest of anything to get working, and none of it was
conceptually hard — it was all discovery.

1. **⚠ Correct the `NVXImpedanceGetData` header.** It documents `CountEeg + 1 GND`; the DLL
   requires `CountEeg + CountAux + 1`, and ground is the **last** word, after the AUX block. A
   reader following the documentation is refused outright with `NVX_ERR_PARAM`; one that fixes
   only the size then publishes AUX 1 as ground, permanently out of range.
2. **Provide a sweep-completion indicator.** The device sweeps ~32 electrodes per 750 ms, so most
   reads land mid-sweep, and electrodes not yet reached read **0 Ohm** — which is not a sentinel,
   it is the best possible impedance, and a viewer paints it green. A counter, a flag, or a
   per-word validity bit would remove the guesswork. We currently hold the last real reading per
   electrode, which is an inference about intent.
3. **Give "over range" and "not measured" distinct, documented values.** We observe 999 900 Ohm
   for unconnected electrodes and `INT_MAX` for an aborted sweep, but the header documents only
   `INT_MAX`, and the NVX programming guide says values above 120 kOhm return `INT_MAX`. Three
   values, one documented.

Also worth documenting prominently rather than in a footnote: **both GND and the REF electrode
must be connected or nothing is measured at all.** It is in the header; it deserves to be in the
user manual, because the failure looks like a dead device.

---


<a id="history-5-triggers"></a>

## 5. Triggers

* **Make the output readback follow the pin, not the register.** On the NVX-52, bit 9 of the
  status word reflects what the host last wrote through `NVXSetOut`. If it followed the actual
  line, software could detect a stuck or heavily loaded output. If it cannot follow the pin,
  documenting that it does not would be almost as useful.
* **Specify the minimum guaranteed input pulse width.** We measure the NVX-52's falling-edge mode
  latching an isolated **20 µs** pulse 95.5 % of the time — far better than the manual's "±0.5
  reading" sampling accuracy implies. We would like to rely on that, but cannot without a
  specification.
* **Clarify `NVXSetOut`'s argument.** It is documented as "bits 0, 1", but on a device reporting
  `OutTriggersCount = 1` only the exact value 1 raises the line; 2 and 3 leave it low, including
  3, which has bit 0 set.
* **Allow the power-up state to be configured.** Outputs rest HIGH by design and this is
  documented, but it means a receiver sees an asserted trigger from the moment the amplifier is
  powered, before any software runs. A configurable reset state — or simply a documented way to
  define it — would help rigs where the trigger output drives something that acts on it.
* **Document `NVXSetMirrorTriggers`.** It is declared in the NVX136 header with no documentation
  block at all, and our media converter answers `NVX_ERR_SUPPORT`.

---


<a id="history-6-start-up-and-lifecycle"></a>

## 6. Start-up and lifecycle

* **`NVXOpenEx` costs about 3.3 s** on our NVX136, which we assume is firmware boot. If some of
  it is avoidable — or if a device can be held open across acquisitions — that would be welcome.
  If it is irreducible, saying so in the documentation would stop integrators hunting for a bug.
* **⚠ Make the battery calls fail fast.** `NVXGetBatteryLevel` and `NVXGetBatteryParameters`
  block for **2.75 s** and then return −3 on our media converter. We removed them and derive a
  charge estimate from `NVXGetVoltages` (16–32 ms, real data) instead. An immediate "not
  supported on this device" would be far better than a timeout.
* **Publish a voltage-to-charge curve for the NVX136-ACC pack**, or expose charge directly from
  whichever module knows it. Ours is interpolated from a generic 6 V sealed-lead-acid table and
  sags under load — we measured 53 % → 49 % over the first minute of acquisition on a rested pack,
  which is an artefact of our estimate, not of the battery.
* **⚠ Say which calls are legal during acquisition.** On the NVX136, `NVXGetVersion` issued after
  the impedance sweep starts **silently aborts the sweep** — every electrode then reads
  `NVX_IMP_INVALID` indefinitely, and every call still returns success. The programming guide does
  state ordering rules for some functions (`NVXSetTriggersMode` is documented "before `NVXStart`"),
  so the convention exists; it just does not cover this.

---


<a id="history-7-documentation"></a>

## 7. Documentation

Small, cheap, and would have saved us the most time overall.

* **Reconcile the `Status` word bit map.** `NVX.h` describes ten inputs with the output at bit 10;
  the user manual specifies 9 sync inputs and 1 output for the NVX-52, `NVXGetPossibility` reports
  `InTriggersCount = 9`, and measurement puts the output readback at **bit 9**. The header is the
  outlier. A plausible reconciliation is that the readback bit is at `InTriggersCount` rather than
  fixed at 10 — if so, saying that would cover every model at once.
* **Document the settling period after `NVXStart`.** The first 14 frames carry `Status == 0` on
  our NVX-52, before the word reaches its resting value. A reader that takes frame 0 as the
  resting level then misreads every subsequent input.
* **State the read-cadence requirement numerically.** We infer a limit near one second between
  reads from where our block-size sweeps start losing data. It deserves a number.
* **Consider publishing the developer documentation as a browsable reference** rather than a PDF
  per kit. We routinely have three headers and two manuals open to answer one question.

---


<a id="history-8-what-we-would-prioritise"></a>

## 8. What we would prioritise

If only a few of these are practical, these are the ones we would choose, and why.

| Priority | Suggestion | Why this one |
|---|---|---|
| 1 | ⚠ Resolve the **NVX-52 5 kHz sample loss** (§1 context, and our separate question list) | It is the only item that blocks experiments outright. Everything else is friction. |
| 2 | **Per-block device timestamp** (§2.2) | One field, enormous benefit: every host can measure and correct drift without steering any clock. |
| 3 | **Error status on the NVX API** (§3) | Turns silent data loss into a reportable condition. The NVX136 already shows the right design. |
| 4 | **Correct the impedance header and add a sweep indicator** (§4) | Pure documentation plus one small field, and it removes the single largest source of integration effort we hit. |
| 5 | **Header/manual reconciliation** (§7) | Costs nothing but editing, and prevents the next integrator repeating our week. |

Transport is deliberately not in that list, because it is a larger undertaking than the rest and answers a different need — closed-loop latency rather than data integrity. We would still very much like the conversation in §1 to happen, and §1.5 is the question that should come first.

---


<a id="history-in-closing"></a>

## In closing

None of this is a complaint about the hardware. The analog front end has been excellent
throughout, the NVX136's optical isolation is the right design for an MR environment, the
falling-edge trigger latch performs better than its specification, and 1 kHz and 2 kHz acquisition
have been faultless over fifteen-minute runs. The suggestions above are almost entirely about
*observability* — letting software see what the device already knows.

Our open questions are in `nvx-sdk-questions.md` (NVX / NVX-52) and `nvx136-sdk-questions.md`
(NVX136), both available in Russian as well.
