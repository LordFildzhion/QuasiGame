# 2026-08-17 — trigger paths characterised across three devices; NS-65 sync port reachable at last

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-17--trigger-paths-characterised-across-three-devices-ns-65-sync-port-reachable-at-last"></a>

### 2026-08-17 — trigger paths characterised across three devices; NS-65 sync port reachable at last

Full report: **`report_trigger-validation.md` (on the lab drive, `R:\docs\_notes\`)**.

**A real arduinoTTL board was attached for the first time** (COM4, firmware v2.3), so the
board-free claims in [arduino-ttl-service.md §8](../components/arduino-ttl.md) are now hardware claims.

**A trigger edge can be located on the NVX's timeline to ±½ sample and no worse** — measured with
a phase-dithered carrier over 733 edges: residual span 499.4 µs against a 500 µs sample period,
sd 144.3 µs against the 144.3 µs that pure quantisation predicts, histogram flat. **Through the
Resonance service layer the same edge is dated 9.34 ms late with a 16.7 ms spread.** Transport is
only 0.24 ms of that; the rest is the driver's 38 ms poll cadence and the fact that a block's
`created` belongs to its *last* sample. Which number applies depends entirely on where the reader
sits.

| | |
|---|---|
| Pin map, measured | arduinoTTL BNC1 → `Status` bit 6, BNC2 → bit 7, **NS-65 sync out → bit 8**, NVX output readback → **bit 9** |
| Idle word | `0x0000EFFF` — every input rests HIGH, so an input edge is a bit going **low** |
| `NVX_TRG_REAR` | **latches**: catches an isolated 20 µs pulse at 95.5 %, and is rate-independent (a 0.25-sample pulse at 250 Hz: 25/25) |
| `NVX_TRG_NORMAL` | plain level sampling — catch fraction is width/sample-period at every point tested |
| `NVX_TRG_FRONT` | catches nothing below 1 ms on an idle-HIGH line; the bit does not move at all |
| End to end | 180 board pulses → 180 NVX edges → 180 recorded, nothing lost |

⚠ **`trigger_state` was wrong and is fixed.** It offered 0..3 as "two low-order output lines";
this hardware has **one** (`OutTriggersCount` = 1) and only the exact value **1** raises it — 2
and 3 both leave it low. An experiment encoding a code as 2 or 3 emitted nothing and recorded a
plausible zero. Capped at 1.

⚠ **`NVX.h`'s Status-word comment is off by one.** It says inputs 0–9 and output at bit 10; the
device reports 9 inputs, the vendor programming guide §2.6 and the user manual agree, and
measurement puts the output readback at **bit 9**.

**The Neuron-Spectrum sync port is reachable for the first time.** The `/clr` bridge had *zero*
functional references to `SynchroModule` / `LightStimulator` / `PatternStimulator`; sixteen entry
points were added. `NS_StimStart(light, 10)` now puts **10 pulses onto NVX bit 8**. Two facts
from the vendor IL shaped it: the only SDK path that enables sync-in is the end of
`StimulatorsControlUnit.powerOn()`, and a read-modify-write guard on `SynchInEnable` would
*never* write the hardware because the managed shadow reads back `true` from construction while
`LoadSynchInReg` has never run.

⚠ **The event offset is not sub-sample.** The SDK computes `samplesCount / 16000.0`, so the
quantum is exactly **62.5 µs**. Five places in the tree claimed otherwise; corrected.

⚠ **An earlier "NVX out → NS-65 sync in produces no events" conclusion is RETRACTED.** The 2.5 mm
plug was on contact 3, the sync **out**, not contact 2, the sync **in** — every run drove the
amplifier's output pin while its input sat unconnected. The result says nothing either way, and
**the NVX output remains unverified as a physical signal**: only `Status` bit 9, the device's own
internal readback, has ever been seen following `NVXSetOut`.

**The NS-65 sync input works, and locates an edge to one 16 kHz sample.** Driven from the
arduinoTTL board: 8/8 in all four enable/invert combinations, 40/40 on a train, residual 18.5 µs
against the 18.0 µs pure quantisation predicts — an independent confirmation of the 62.5 µs
quantum derived from the vendor IL.

⚠ **The NS-65 was timestamping the pulse's TRAILING edge, and that is now fixed.** With
`sync_in_inverted = false` — the default it shipped with until now — a 500 ms pulse was dated
500 ms late. The error
equals the stimulus width, and a constant width makes it a constant offset that **no consistency
check inside a session can reveal**; it would silently corrupt any ERP or TEP latency. Measured
with 300 ms and 20 ms pulses alternating: 279.968 ms at `false`, **0.057 ms at `true`**, inside the
62.5 µs quantum. The default is now `true`, rebuilt and deployed.

**Four sessions recorded through `recorderService`** with `neuronSpectrum` and `arduinoTTL`
together, at 1 kHz anti-aliased and at 16 kHz unfiltered — 74 pulses of deliberately mixed widths,
708 800 samples and zero NaN in the 16 kHz files. Two pre-fix files are kept as the primary
evidence for the defect. ⚠ **One sync-in event was dropped** in one 16 kHz session (73 against 74),
unreproduced in the other three; see `report_trigger-validation.md` §6d (on the lab drive, `R:\docs\_notes\`).

**The sync output can now be fired from the `neuronSpectrum` service.** It previously could not:
the driver configured the socket and never drove it. What was missing was more than a call — the
socket is wired to a stimulator, so `SynchroOutSource` alone routes a signal nothing generates;
the stimulator's module is now powered at Start, which needs no lamp attached. `Fire` and `Stop`
are `Parameters::Action`, not values, because a value-typed parameter only acts when it *changes*
and firing the same train twice would do nothing the second time.

⚠ **That work found a bug only hardware could catch.** The first implementation restarted a
stimulator the SDK still considered running: `NS_StimStart` returned OK, the service logged
`fired 5 pulse(s)`, and the socket emitted an **unbounded train** — the count silently lost. It
was visible only because a second device was counting the pulses, and the runaway rates matched
the configured periods exactly (≈5/s at 200 ms, 10/s at 100 ms, 20/s at 50 ms). Fixed by stopping
unconditionally before configuring.

**Both directions now measured in one recording**, at 1 kHz and at 16 kHz unfiltered
(`R:\dist\msvc64\data\ns65-sync-in-and-out-*.h5`): 74 pulses in, 36 out, per file. The output's
placement is as good as the amplifier's clock — at 200, 100 and 50 ms the **median interval error
is 0.000 ms**, i.e. zero to the 62.5 µs quantum. The control that makes this mean anything is that
the board's `in2` counter stayed flat through the whole input phase, so the amplifier's input does
not leak to its output through the shared 2.5 mm connector.

⚠ **A sporadic sync-in event loss is real and unexplained**: two events in 444 across six
sessions, at *both* rates, so it is not the 16 kHz effect it first looked like. Timing of the
surviving events is unaffected. Compare `events` against your own stimulus log rather than assume
the counts match — and note the trigger lane is synthesised from the same events, so it is not an
independent check.

⚠ The synthesised NS-65 trigger lane is still not group-delay corrected, so it leads the data by
~1.4 ms with the default filter: measure from the `events` stream, not the lane.

