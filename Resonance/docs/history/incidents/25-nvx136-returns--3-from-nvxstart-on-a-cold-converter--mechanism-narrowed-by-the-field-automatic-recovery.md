# 24. ⚠ NVX136 returns `-3` from `NVXStart` on a COLD converter — mechanism narrowed by the field, automatic recovery deployed 2026-08-25, still UNPROVEN on hardware

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-24--nvx136-returns--3-from-nvxstart-on-a-cold-converter--mechanism-narrowed-by-the-field-automatic-recovery-deployed-2026-08-25-still-unproven-on-hardware"></a>

### 24. ⚠ NVX136 returns `-3` from `NVXStart` on a COLD converter — mechanism narrowed by the field, automatic recovery deployed 2026-08-25, still UNPROVEN on hardware

> ⚠ **TRANSFERS UNCHANGED — into `R:\dist` only. The two trees have DIVERGED here, and this section
> describes the Qt 6 driver's current state, not the Qt 5 one's.**
>
> This is one of the two reasons **`R:\dist` is not yet cleared for a laboratory session**. A
> session with an NVX-136 runs from `R:\dist_Qt5\msvc64`. Ranked and costed in
> [qt6-work-list.md §1a](../migrations/qt6-work-list.md).
>
> The Qt 6 `nvx136` was snapshotted on **2026-08-27**, before the 2026-08-28 rig work below.
> `R:\src\nvx136\nvx136driver.cpp` therefore still implements exactly what is described here and
> nothing after it: `powerCycleConverter()` at `:574-598` — `NVXOpenEx(PowerDown)` + `NVXClose`,
> called from the recovery ladder — `ColdStartAttempts = 2` at `:39` and
> `ColdStartRecoveryPauseMilliseconds = 500` **hard-coded** at `:49`, and the full pre-start
> sequence (`NVXGetDevices`, `NVXSetDevices`, `NVXSetPowerSave`, `NVXGetProperty` twice,
> `NVXSetChannelsEnabled`, `NVXSetAuxGain`, `NVXSetPll`, `NVXSetActiveShieldGain`,
> `NVXSyncPulseSetParam`). **The converter power-down is one of the cures the rig falsified.**
>
> `R:\src_Qt5\nvx136` has moved on. Its `nvx136driver.h:57-82` records that **three** cold-start
> hypotheses are now falsified — the reopen ladder, the converter power-down, and `NVXSelectDevice`
> — and it acts on that: `legacyStartSequence = true` by default, which skips
> `NVXGetDevices`/`NVXSetDevices`/`NVXSelectDevice` before the start and defers
> `NVXGetProperty`/`NVXSetChannelsEnabled` until after it, leaving the four calls the driver that
> *did* start a cold amplifier made. `NVXSelectDevice` was traced out of NeoRec at the rig on
> 2026-08-28 and added — and **adding it alone did not cure the cold start either**, so it too is
> gated off. ⚠ The Qt 6 driver never had that call at all; it predates the hypothesis, which is why
> `NVXSelectDevice` appears in no source file under `R:\src\nvx136` outside the vendor header
> `sdk\include\nvx.h:311` (the vendor's own `Dll\` binaries export it, as they always did).
>
> ⚠ **`cold_start_pause_ms` does not exist in Qt 6.** `R:\src_Qt5\nvx136\nvx136config.cpp:122`
> exposes it as a `Parameters::Integer` in group `hardware` precisely because the pause is the last
> unexplained variable and the rig needs to sweep it. A Qt 5 parameter file still loads into the Qt 6
> service — the unknown key is reported and every other entry applies — but that one value is
> ignored.
>
> ⚠ **The Qt 6 `nvx136` test suite asserts the falsified cure**, so it passes while modelling
> behaviour the rig disproved. `OnlyAPowerDownCloseCuresTheConverter`, below, is that test.
> Re-copying `nvx136driver.{h,cpp}` and `nvx136config.{h,cpp}` from `R:\src_Qt5` must bring the
> tests with it.

Found at the rig on 2026-08-22. On a **freshly powered-on** NVX136, `NVXStart` returns `-3`
(`NVX_ERR_FAIL`) for every configuration. Once something has opened the device, attempted a start
and re-opened it, it starts normally until the next power cycle.

```
NVX136 DLL/driver versions: 281497876496384 844442110066834
NVXStart failed (NVX136 error -3)
```

<a id="history--2026-08-26--the-rule-below-was-falsified-at-the-rig-and-the-mechanism-is-now-known"></a>

### ⛔ 2026-08-26 — the rule below was FALSIFIED at the rig, and the mechanism is now known

The ladder built from facts (a)–(c) **ran and did not work.** The operator's console shows two full
recovery cycles — `NVXStop`, `NVXClose`, pause, re-open, re-configure — and all three `NVXStart`
calls still returned `-3`, at 3936 / 3978 / 3923 ms. Kept in
`R:\tests\lab-session-20260826\`.

**What actually cures it, measured the same day:** *merely opening the vendor tool and closing it
again, without starting anything.* Resonance then starts on the first attempt.

The distinguishing call is in the SDK header, and this driver had been getting it wrong since the
beginning:

```c
/*! \param PowerDown - power down Media converter after call NVXClose() */
NVX_API HANDLE NVXOpenEx(unsigned int Number, bool PowerDown);
```

`nvx136driver.cpp` passed **`false`**. The flag is set at *open* and honoured at *close*, so **no
close this driver ever performed powered the media converter down** — which is exactly why any
number of close/open cycles cleared nothing.

⚠ **And the operator had to correct the wiring assumption too:** power-cycling the **amplifier**
does not touch the converter. *"converter always connected to USB and has access to power, and was
never power-cycled."* So the converter survives the amplifier's restart holding a link to an
MSP430 that rebooted underneath it — which is both why the control channel keeps answering (fact
(a), still true) and why only taking the converter's own power away resynchronises them.

**Fact (c) below is therefore wrong** and is kept only so the reasoning that produced it can be
followed. Facts (a) and (b) survive. The recovery cycle now performs a real converter power-cycle:
`NVXOpenEx(PowerDown = true)` → `NVXClose` → settle → open normally. `ColdStartAttempts` dropped
from 3 to **2**, because every observation says one cure is enough and a cycle now costs ~4 s more.

Wall time, simulated at the rig's own timings: recovered cold start **14.3 s**, give-up **17.2 s**,
warm start **+0**.

⚠ Still unproven on hardware. `fake_nvx.cpp` now models the `PowerDown` rule instead of the
falsified one, and `OnlyAPowerDownCloseCuresTheConverter` is the regression test for precisely the
failure above: a close/open pair with `PowerDown = false` must **not** cure the fake.

<a id="history-the-three-field-facts-that-pin-it"></a>

### The three field facts that pin it

From the operator's 2026-08-24 report on the 2026-08-23 build. ⚠ **Provenance:** these three
observations exist in this tree only as the report they came in as and the work built on it —
`config\lab\NVX136-coldstart-ladder-test.md`. Nothing else corroborates them, and the earliest
recorded symptom (the quoted block at the head of `_notes/nvx136-cold-start.md`) names *NeoRec* as
the cure rather than a second Resonance launch.

| # | fact |
|---|---|
| a | The **control channel is alive throughout.** The device answers version and status queries while `NVXStart` is failing. It is not dead, not asleep, not unplugged |
| b | **Rescans do not help.** `probe()` is an `NVXOpenEx`/`NVXClose` pair, and any number of them leaves the next start failing |
| ~~c~~ | ⛔ **FALSIFIED 2026-08-26 — see the block above.** ~~`NVXClose` → `NVXOpenEx` → `NVXStart` cures it, but only after a start has been attempted and failed.~~ The ladder built on this ran twice at the rig and did not cure anything. The real cure is a converter power-down, which no close in this driver was performing |

Three in-place retries on one handle gave three identical timeouts — **3966 / 3003 / 3029 ms** —
and then a give-up.

<a id="history-the-rule-those-facts-fit"></a>

### The rule those facts fit

**The cure needs BOTH a failed `NVXStart` and a re-open. Neither half alone does anything.** (b) is
a re-open with no failed start and does nothing; three retries are a failed start with no re-open
and do nothing. So something on the device changes state only when Start is *attempted*, and the
host must then drop and rebuild the link — `NVXClose` drops the UART channel, `NVXOpenEx` rebuilds
the handle, the USB pipes and the FPGA load — before it can use that state. Which side holds the
stale framing is not settled and does not have to be: the transition rule is enough to automate
the cure.

⚠ **A competing hypothesis is NOT excluded by these facts.** The operator's cure was a **second
process**, which unloads and reloads `NVX136.dll` and its process-global device table. The
in-process `NVXClose`/`NVXOpenEx` the driver now performs does not. Every field fact above is
equally consistent with "the DLL's own state is what has to be rebuilt", and the offline test
double asserts the driver's version of the rule because that is what it was written from. Test A in
`config\lab\NVX136-coldstart-ladder-test.md` is what distinguishes them: if the in-process cycle
recovers a genuinely cold device, the DLL-reload hypothesis is dead.

<a id="history--what-the-previous-version-of-this-entry-got-wrong"></a>

### ⚠ What the previous version of this entry got wrong

Left here rather than deleted, because the disassembly evidence in it is still good and only the
conclusion moved.

* **It said the cause was `NVXGetVersion`'s placement** (moved from after `NVXStart` to immediately
  before it), and the 2026-08-23 build took the call out of the acquisition path on that basis.
  **The cold failure reproduced on that build.** H1 is therefore not the whole cure, and may be
  none of it. What the disassembly established still stands and is still in
  `_notes/nvx136-cold-start.md`: `NVXGetVersion` issues a raw `CmdSend(0)` polled 3×50 ms and an
  `Msp430CmdCycle(0xFF)` with an 873 ms timeout, no preceding `SelectDeviceCmd`, and it
  `return 0`s unconditionally, sharing the DLL's single command-response slot with the PLL query
  `Start()` reads first. Keeping the pre-`Start` gap empty remains right; it is just not sufficient.
* **It described `NVXStart` retried 3× at 250 ms as the answer.** Fact (c) says three retries on one
  handle can never work. That ladder is gone.
* **It said a failed start does not warm the device**, so a ladder of sequences could be run inside
  one power cycle "as long as none of them succeeds" (`_notes/nvx136-cold-start.md` §6, now carrying
  a SUPERSEDED IN PART note). Under the transition rule that is exactly backwards, and it is why
  `nvx136_coldprobe.py --ladder` needed a new control stage — see below.

It **still refutes three theories** and those refutations are unaffected: a missing bitstream (that
path returns `-1` and fails inside `NVXOpenEx`); "the new SDK needs an extra call" (both DLLs export
the same 68 symbols and `Open`/`Start`/`LoadFpga`/`GetPll`/`SetPll` are instruction-identical
between 1.4 and 1.5 — the new SDK is a new *header*, not a new API); and configuration of any kind
(no gate inside `Start()` reads any configured value, and all eight rate/blockSize combinations
start once warm).

<a id="history-what-was-deployed-2026-08-25--the-recovery-ladder"></a>

### What was deployed 2026-08-25 — the recovery ladder

`Nvx136Driver::startWithRetries()` → `startWithColdStartRecovery()`. Start is attempted **once**; on
`NVX_ERR_FAIL` the driver performs the operator's manual cure itself:

`NVXStop` (return code recorded and ignored) → `NVXClose` → **500 ms** → `NVXOpenEx` → the
**complete** configuration again (device mask, settings, power save, channels-enabled, aux gain,
PLL, active shield, sync pulse, impedance) → `NVXStart`. Two such cycles, three starts in total.

The 500 ms pause is deliberately short. The operator's 60-second wait proves time alone cures
nothing, so it covers only the cyusb handle and endpoint release before the next open.

One line per cycle, and the elapsed `NVXStop` in it is the **instrument**:

```
NVX136 cold-start recovery 1 of 2: NVXStop -3 in n ms, NVXClose 0 in n ms, paused 500 ms, reopen+reconfigure ok in 3007 ms
```

Wall time, simulated at the rig's own timings: recovered cold start **14.3 s**; give-up **17.2 s**;
warm start **+0**. ⚠ Superseded numbers: before the converter power-cycle was added these read
10.2 s and 20.0 s, and the ladder they measured did not work.

**Should the first start pre-emptively tear down and re-open? No.** A teardown with no Start attempt
before it is precisely a rescan, which is fact (b).

⚠ **The give-up advice was wrong in both directions and now names which reset is which.** It used to
say "power-cycle the amplifier and try again"; that was then reversed to "do NOT power-cycle"; both
are wrong, because the ladder performs a close/open and **the service has no way to know whether
power was cycled before this run**. It now names the two resets separately: power-cycle first if
that has not been done, then NeoRec.

⚠ `Nvx136Config::start()` still uses `Qt::BlockingQueuedConnection`, so the Configurator is frozen
for the whole ladder — 14 s on a recovery, 17 s on a give-up. A `Rescan` pressed during that window
can purge the nvx136 entry from the service list (`kRescanStaleAfterMs = 10000`). Reasoned from the
code, not measured. Making `start()` asynchronous is a Config-lane restructure and was not attempted.

<a id="history-what-has-and-has-not-been-shown"></a>

### What has and has not been shown

**Nothing here has touched an NVX136.** `src\nvx136\tests\fake_nvx.cpp` builds a DLL exporting the
same `NVX*` names, and the **shipping driver source, unchanged**, is compiled against it;
`nvx136_cold_start_recovery_test` is 6 tests, all passing, one of them old-code-fails /
new-code-recovers. That proves the code matches the author's model of the device. It cannot prove
the model. The vendor emulator cannot reproduce the bug at all — it starts on attempt 1 in every
sequence.

**Two numbers have to come back from the rig**, and the log line prints both:

* the elapsed **`NVXStop`**. Under ~10 ms the DLL screened it against its own state flag and the
  speculative Stop is free; around **873 ms** it reached a silent converter, costs a deadline per
  cycle, and should be dropped.
* **which attempt succeeded.** Every field observation says attempt 2. If attempt 2 always works,
  `ColdStartAttempts` can drop to 2 and save ~7 s on a genuine give-up.

`NVXOpenEx ≈ 3 s` is taken from a comment in `nvx136config.cpp`, not measured.

<a id="history-how-it-gets-settled"></a>

### How it gets settled

`R:\config\lab\nvx136_coldprobe.py --ladder`, on a converter that has not yet been powered on,
before anything else touches the amplifier. Procedure, expected console lines and pass/fail:
**`R:\config\lab\NVX136-coldstart-ladder-test.md`**. Diagnosis and disassembly:
`_notes/nvx136-cold-start.md`.

⚠ **The ladder was changed on 2026-08-25 and the change is load-bearing.** Every stage brackets
itself with its own `NVXOpenEx`/`NVXClose`, so `current` (open, failed start, close) followed by
`nogetversion` (fresh open, start) **is**, step for step, the recovery cycle — and the old ladder
would have stopped there and printed "H1 confirmed" for a success the re-open explains just as
well, spending the one cold window a power cycle gives you on a false verdict. A `recovery` control
stage now sits between them: the same sequence as `current`, `NVXGetVersion` **included**, on a
fresh open. `recovery` starts ⇒ the re-open is the cure and H1 is not implicated. `recovery` fails
and `nogetversion` starts ⇒ H1, and now it means something. The verdict block refuses to say "H1"
without that control.

<a id="history-24a-nvx136_driver_emulation_integration-crashed-at-teardown-about-a-third-of-the-time---fixed-2026-08-23"></a>

### 24a. `nvx136_driver_emulation_integration` crashed at teardown about a third of the time — ✅ fixed 2026-08-23

**TRANSFERS UNCHANGED — the fix crossed.** `R:\src\nvx136\tests\driver_emulation_integration.cpp`
carries it, and the general lesson at the end is Qt-version-independent.

Not related to §24, but found while using that test as evidence for it, and worth separating so
the two are not confused.

The test crashed with an access violation (`0xC0000005`) at teardown in roughly one run in three:
measured 3 crashes in 6 runs in one build, 2 in 8 in another. **It is timing-sensitive, not
change-sensitive** — which is the trap. Any edit that shifts when the first data block arrives
changes the odds, so an unrelated change can look exactly like the thing that broke it, and a
single passing run is not evidence that it is healthy. It was nearly attributed to §24's version
query on precisely that basis.

The cause is in the test, not the driver. The lambda watching `Nvx136Driver::data` is attached
with `Qt::DirectConnection`, so it runs on the **worker thread**, and it captures three of the
test function's locals by reference. `WorkerSession session` is declared **first**, so it is
destroyed **last** — the semaphore and the two counters are destroyed while the driver's poll
timer is still firing and `processData()` is still emitting into them.

**Fix:** stop the acquisition at the end of the test body, while the captured objects are still
alive, rather than leaving it to `~WorkerSession`
(`R:\src\nvx136\tests\driver_emulation_integration.cpp`). `shutdown()` deletes the poll timer, so
no further `data` can be emitted, and it is idempotent. 12 of 12 runs pass afterwards.

**General lesson, and it is not specific to this test:** a `Qt::DirectConnection` handler capturing
stack locals by reference is only safe while the *emitter* is guaranteed stopped. Declaration order
decides destruction order, and the object that owns the emitting thread being declared first makes
it the last thing torn down — which is the opposite of what is needed.

---

