# `neuroMS` — the Neuro-MS magnetic stimulator service — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/neuroms.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-neuroms--the-neuro-ms-magnetic-stimulator-service"></a>


**Written 2026-08-15.** Covers `R:\src\neuroMS`, its `/clr` bridge over the Neurosoft Neuro-MS
SDK, and — because no stimulator was available while it was built — the offline test plan and
the hardware bring-up procedure that go with it.

Read [architecture.md](../migrations/framework-evolution.md) first for what a service is, and
[known-issues.md](../incidents/README.md) for the tree-wide defect list. The closest sibling module is
[`neuronSpectrum`](neuron-spectrum.md), whose bridge this one is modelled on; the shared
`/clr` build component is [dev-environment-setup §B5](../migrations/dev-environment.md).

**Ported to Qt 6, 2026-08-28, and current.** `neuroMS.exe` and its mixed-mode `nmsbridge.dll` ship
in the default distribution at `R:\dist\bin`, with the vendor managed assemblies in
`R:\dist\bin\neuroMS\` (§3) and the software stimulator intact. Source is `R:\src\neuroMS`; it is
built with **MSVC v143 14.44** against Qt 6.11.2, not v142. The Qt 5 build survives as the
comparator in `R:\src_Qt5\neuroMS` → `R:\dist_Qt5\msvc64`. See
[qt5-to-qt6-transition.md](../migrations/qt5-to-qt6-transition.md).

✅ **Resolved 2026-09-02: the Qt 6 build now has the `standby` state.** It was one iteration
behind — no `standby`, no `enteredOperatingState()`, so a machine switched off at its own front
panel landed in **`ready`, which still offers Charge**, exactly the arrangement the rig rejected
on 2026-08-26 (§7.1, §7.3). `neuromsconfig.{h,cpp}` and `neuromsdriver.{h,cpp}` were merged from
`R:\src_Qt5` and the Qt 6-only paired-pulse handshake fix re-applied on top, so `R:\dist` now
carries **both** halves of §7.1. Confirmed in the binary: `enteredOperatingState` is present in
`R:\dist\bin\neuroMS.exe` and was absent before.

⚠ **No Qt 6 build has ever driven a physical Neuro-MS.** The first session from `R:\dist` is a
bring-up, not routine use — run §9 and keep `R:\dist_Qt5\msvc64` available as the fallback. See
[qt6-work-list.md §1b](../migrations/qt6-work-list.md).

---


<a id="history-1-what-this-driver-is-for"></a>

## 1. What this driver is for

The Neuro-MS is a **transcranial magnetic stimulator**. Unlike every other device in this tree
it is an **actuator**, not a sensor, and that changes the shape of the service: there is no
acquisition to keep up with, there is a machine to be configured, charged, and then left alone
while an external TTL fires it.

The rig this was written for uses a **monophasic unit with paired-pulse capability** — one or
two blocks, master plus slave — and fires it from a TTL that the EEG/EMG recorder also records,
which is what makes the pulse timing trustworthy. The driver is therefore asked to do four
things and no more:

| | |
|---|---|
| **charge** | before the first trigger of a recording |
| **discharge** | at the end of a measurement |
| **set power** | per block |
| **set delay** | between the two pulses |

and to **report back, per firing**, what the coil actually delivered along with the coil
temperature and the settings in force.

Everything else it publishes — capacitor voltage, unit temperatures, the device's own disarm
countdown, the stimulus counter — rides along on a 2 Hz telemetry stream, which costs nothing
and is recorded beside the EEG.

**The driver does not fire the stimulator** in normal operation. The trigger input does. Host
firing exists, is off by default, and is discussed in §7.

---


<a id="history-3-the-two-neurosoft-sdks-collide-and-the-fix-is-structural"></a>

## 3. The two Neurosoft SDKs collide, and the fix is structural

`R:\src` now contains two Neurosoft SDKs. They ship **seven assemblies with identical simple
names, identical version `1.0.0.0`, no strong name, and different bytes**:

| Assembly | Neuro-MS package | `neuronSpectrum/sdk/lib` |
|---|---|---|
| `Neurosoft.Hardware.Devices.dll` | 2016-04-20, 1.93 MB | 2023-03-03, 2.01 MB |
| `NeuroSoft.Common.dll` | 2019-07-29 | 2023-03-03 |
| `NeuroSoft.Devices.NSUSB2.dll` | 2019-07-29 | 2023-04-10 |
| `Neurosoft.Hardware.{Common,Usb,Tools,WinAPI}.dll` | 2018–2019 | 2023-03-03 |

The CLR resolves an unsigned assembly **by simple name from the probing path**, so with both
stacks flat in `bin\` whichever driver's files were copied last would decide what *both* of them
ran against — and the failure would surface as a `MissingMethodException` deep inside a vendor
call, on hardware, months later.

So:

* each driver's managed assemblies live in **`bin\<driver>\`** (`bin\neuroMS\`,
  `bin\neuronSpectrum\`), and each bridge installs an `AppDomain::AssemblyResolve` handler
  pinned to its own directory;
* the **native** IPP runtime that `neuronSpectrum` needs stays in `bin\`, because P/Invoke uses
  `LoadLibrary`'s search order and knows nothing about CLR probing paths;
* `NMS_GetVendorAssemblyPath()` reports the path the vendor stack was actually loaded from, and
  the driver puts it in the `connected` event — because CLR probing checks the executable's own
  directory **before** any resolve handler runs, so a stale flat copy left by an older build
  would win silently. Recording the path turns that into one line in the session log.

> ⚠ **When redeploying over an existing tree, delete `bin\NeuroSoft.*.dll` and
> `bin\Neurosoft.*.dll` first.** `copy_if_different` never removes anything, so a tree built
> before this change keeps its flat copies and they take precedence over both private
> directories. This was hit during development; it is not hypothetical.

<a id="history-31-two-clr-traps-this-walked-into"></a>

### 3.1 Two `/clr` traps this walked into

Both produced failures that pointed nowhere near their cause, and both are now commented in the
source:

**Touching any static of a managed class runs its type initializer.** The resolver was first
written as static members of the same `Session` class that holds the `NsBase^` device handle —
so asking the resolver to install itself resolved the types of every static field in the class,
which loaded the vendor assemblies, before the handler existed. It failed with *"the type
initializer for 'Session' threw an exception"*. The resolver now lives in its own class holding
nothing but mscorlib types.

**The JIT resolves a method's type references when it compiles that method.** A `typeid` on a
vendor type written directly inside `NMS_Initialize` loads the assembly before the handler
installed three lines earlier can be consulted. The reference sits behind a `NoInlining` call
boundary (`Session::WarmUp`) so the enclosing method can be compiled knowing only its signature.

---


<a id="history-5-published-streams"></a>

## 5. Published streams

<a id="history-events--message-json-v-1"></a>

### `events` — `Message`, JSON, `v: 1`

**Created at service start and kept for the life of the process**, not per device session. That
matters: created at connect time, the `connected` and `settings` records — which say which
device, which mode, which firmware and which vendor assembly are in use — were published into a
stream no consumer could yet have subscribed to, and were therefore missing from every
recording. It also made the streams churn on every connect.

One record per delivered pulse, which is the part that cannot be reconstructed from anything
else:

```json
{"v":1,"type":"pulse","rtc":"177331460756700","stim":0,"pulse":1,
 "didt":93.25,"u0":880,"u1":73,"L":78,"T":120,
 "power1":55,"power2":40,"delayMs":12.5,"mode":"paired",
 "coilTemp1":24,"coilTemp2":24,"statusAgeMs":159,"source":"configurator"}
```

* `didt` is dI/dT in kA/s — what the coil actually delivered, as the device measured it. It is
  how a coil that is not delivering what it was asked for becomes visible.
* `power1` / `power2` / `delayMs` / `mode` are what was in force at that moment, which the
  device does not report back.
* `coilTemp1` / `coilTemp2` come from the last status read, so `statusAgeMs` says how old they
  are rather than implying a precision that is not there.
* `source` is `external` (the TTL input, or the front panel if mirroring is off), `panel`, or
  the name of whatever asked for a host fire. The SDK does not say where a pulse came from, so
  this is a labelled heuristic: a pulse within 250 ms of a mirrored panel trigger is attributed
  to the panel.

In paired and simultaneous mode there are **two records per trigger**, `stim` 0 and 1.

Other record types: `connected` / `disconnected`, `settings`, `charge` / `charged` /
`chargerLost` / `recharge` / `autoDischarge` / `discharge`, `coil` (plugged, unplugged, type,
serial), `overTemperature` (rising and falling edge, coil and unit separately),
`coilTemperatureWarning`, `sync` (the device's own frame/offset for a pulse), `device`,
`panel` and `mirrored` (§7), `error`, and `ack` / `nack` for every command.

<a id="history-status--float64-28-channels-2-hz-by-default"></a>

### `status` — `Float64`, 28 channels, 2 Hz by default

Named, with `kind` and `unit` metadata so the signal viewer groups them and derives SI prefixes.
Always the two-block layout; a lone unit publishes NaN for the absent block, because the channel
count is part of the stream's declared type.

`armed`, `ready`, `stimOn`, `mode`, `intensity1`, `intensity2`, `ipi`, `coilConnected`,
`coilOverTemp`, `unitOverTemp`, `cableTemp`, `stimCounter`, and per block:
`chargerState`, `coilTemp`, `thyristorTemp`, `chargeResTemp`, `capVolt`, `capVoltSet`,
`remainsSeconds`, `fanRpm`.

Two of these are worth calling out:

* **`intensity1` / `intensity2` / `ipi` come from the device**, not from our own settings. A
  recording therefore proves what the machine was actually set to, independently of what it was
  asked for.
* **`ready`** is derived: armed, not overheating, coil attached, and the capacitor has finished
  tracking a changed setpoint. Changing intensity mid-session re-charges the capacitor, and an
  experiment that fires before it settles gets a pulse at the previous intensity. This is the
  one lane an experiment should gate on.

The stream keeps publishing while nothing is connected, with NaN for everything the device would
have supplied — a continuous 2 Hz lane that says "no device" reads better in a session recording
than a hole.

<a id="history-command-input--message-json"></a>

### `command` (input) — `Message`, JSON

Verbs: `connect`, `disconnect`, `charge`, `discharge`, `rescan`, and
`set {power1, power2, delayMs}`. Every command is acknowledged on `events` with the same `id`.

This exists for **SPEED**. A QML experiment or a Python client can use the existing parameter and
transition mechanisms and needs no command stream at all — but
`R:\src\Core\Resonance\scriptengineinterface.hpp` gives a script
engine exactly `declareStream`, `sendBlock`, `startTimer`, `stopTimer` and `logError`. **There is
no parameter or transition path from inside a SPEED script**, so a stream is the only way in.

Commands write the *parameter objects*, which then drive the device, so there is one copy of
every setting and the Configurator always shows what a script set. `connect` / `charge` and the
rest are emitted on the CommunicationLayer by name, which is the same path a remote client's
transition takes — one place decides whether a request is legal from where the service is.

---


<a id="history-6-parameters-and-states"></a>

## 6. Parameters and states

| Group | Parameters |
|---|---|
| `main` 10–99 | `device`, `model`, `mode` (read-only), `power1`, `power2`, `delay`, `fire` (Action), `command` (Stream) |
| `hardware` 110–199 | `trigIn`, `trigOutWidth`, `trigOutInvert`, `trigOutOnSecondPulse`, `showStimNumber`, `coil`, `firmware` |
| `safety` 210–299 | `maxPower`, `keepCharged`, `idleDischargeMinutes`, `coilTempWarning`, `panelArm`, `panelTrigger`, `panelIntensity`, `allowHostFire` |
| `telemetry` 310+ | `statusInterval` |

```
init ──rescan──▶ scanning ──▶ init
init ──connect──▶ ready                       device open, trigger input on, charger off
ready ──charge──▶ charging ──(charger reports armed)──▶ charged
ready ──(charge button on the front panel)──▶ charged   the operator armed it himself
charged ──(device disarmed itself, watchdog will recover)──▶ charging
charging|charged ──(over-temperature, coil pulled, idle bound)──▶ ready
charging|charged ──discharge──▶ ready
ready ──disconnect──▶ init
any ──▶ error   (entering error discharges and releases the device)
```

**`charge` and `discharge` are transitions, not a Boolean parameter.** A parameter named
`charged` would be set true by loading a saved parameter set — a JSON file on disk charging the
capacitors. Transitions cannot be replayed that way, and the current state is broadcast to every
client, so an experiment can wait for `charged` (QML `ServiceChangedState`, or the events
stream) before releasing its first trigger.

`charging` is a real intermediate state because charging takes seconds; the vendor's own sample
polls for up to 4 s.

<a id="history-61-the-device-disarms-itself--the-keep-charged-watchdog"></a>

### 6.1 The device disarms itself — the keep-charged watchdog

`StatPwr.RemainsCntr` is displayed by the vendor's sample as `"ARMED - N sec"`, and it is a
`Byte`, so the armed state expires within about four minutes of idle at most. "Charge once
before the first trigger and fire for ten minutes" would therefore stop working part-way
through, silently.

With `keepCharged` on (the default), the driver watches the **observed charger state** — not the
device's countdown, so it is correct however that counter turns out to behave — and re-arms
whenever the charge goes away while it is still wanted, publishing `chargerLost` and `recharge`
so the recording shows it.

That deliberately defeats a safety feature, so it has a bound of its own:
`idleDischargeMinutes` (default 10). No pulse for that long and the service gives the capacitors
back and says why.

> The rig this was written for fires often enough that the device's own timer never expires, so
> this should never trigger in practice. It is a safety net, not a workflow.

---


<a id="history-7-the-front-panel-must-keep-working"></a>

## 7. The front panel must keep working

**This is a hard requirement, not an option.** While a program holds the device, its front panel
is routed through the host — all three vendor samples call `SetArmed`, `SetParam` and
`StartStimulation` from their `USER_CTL` handler. Without mirroring, the buttons and knobs on the
machine stop working, and a rig that hunts the motor hotspot by hand would have to disconnect
USB to do it.

So the driver mirrors `ARM`, `TRIG` and the `AMP1` / `AMP2` / `IPI` knobs, all on by default, on
the principle that **connecting a service must not change how the box already behaves**.

Mirroring happens **in the bridge**, on the SDK's own callback thread, so it keeps working
through a busy or stalled Qt event loop. The *policy* — which controls are mirrored, and the
intensity ceiling — is pushed down from the driver, which owns it. Every panel action produces a
`panel` event; every action the bridge takes on the operator's behalf produces a separate
`mirrored` event, so a recording can distinguish "the operator turned the knob" from "and the
machine took it". Mirrored intensity changes are written back into the parameters, so the
Configurator shows what the stimulator is actually set to.

`allowHostFire` is a **separate** parameter and is **off** by default. The operator pressing the
button on the machine is one thing; a program deciding to deliver a pulse is another.

⚠ **The threat model behind that sentence changed on 2026-08-18, in both directions.** It used
to say "a program on the network"; by default no program on the network can reach this service at
all, because every socket is on `127.0.0.1` and a non-loopback peer is refused. But a rig put in
`lan` mode is *more* exposed than the old wording suggests: service control is **unauthenticated**,
so any host that can reach it can set parameters and drive transitions. `allowHostFire` is the only
thing standing between that and a pulse. Leave it off unless the rig is isolated.
See [network-isolation.md §1](../migrations/network-isolation.md).

<a id="history-71--switching-the-machine-off-at-its-own-panel--2026-08-26"></a>

### 7.1 ⭐ Switching the machine OFF at its own panel — 2026-08-26

Mirroring the buttons was only half of it. The operator turned the stimulator off at the front
panel while the service held it, and:

* `Operating mode` correctly read **`standby`** — the readout was right;
* the service sat in **`charged`**, offering live **Fire** and **Discharge** for a machine that was
  off;
* **block 1's intensity could still be edited** on it;
* and pressing one of those stale buttons put `Operating mode`, `Charger` and `Alarms` all to
  **`not connected`**.

Three separate defects, all now fixed:

1. **Nothing carried "the device left an operating state" into the state machine.** The transitions
   all followed the *charger*; none followed the *stimulator*. `NeuroMsDriver::leftOperatingState()`
   now fires when `canStimulate()` stops being true, and `charging` and `charged` transition to
   `ready` on it. Leaving an operating state is not an error and must not disconnect — the device
   is fine, it is simply off.
   ⚠ **Superseded on 2026-08-28 in the Qt 5 tree, and not yet in the Qt 6 one.** The rig reported
   back that `ready` is the wrong destination because `ready` still offers **Charge** — it moved
   the problem rather than removing it. `R:\src_Qt5` gained a dedicated `standby` state with no
   device transition out of it except `disconnect`, plus an `enteredOperatingState()` return path.
   `R:\src` — and therefore `R:\dist` — is still the version described in this paragraph. **§7.3.**
2. **`caps.open` is not the same as "can do something".** A stimulator switched off at the panel is
   open, answering, and useless. `updateParameterAvailability()` now holds `power1`, `power2` and
   `delay` **read-only** whenever the device is connected but not operating, and `fire` follows
   `operating`, not `connected`.
3. **One failed status poll disconnected the device.** `NMS_GetStatus` failing raised
   `errorOccurred` → `error` → `doDisconnect()`. At a 500 ms interval a single USB hiccup mid-block
   cost a rescan, a reconnect and the block. It now tolerates
   `MaxConsecutiveStatusFailures = 5` — 2.5 s of silence — and logs the recovery. The keep-charged
   watchdog's failed re-arm was the same shape and now emits `chargeAbandoned()` instead: losing a
   charge must cost the charge, not the connection.

<a id="history-72-two-readouts-that-were-lying--2026-08-26"></a>

### 7.2 Two readouts that were lying — 2026-08-26

**The charger's "auto-disarm in N s" is gone.** It was built from the device's `remainsSeconds`,
which does not hold what the name suggests. Measured across a real session, block 1 reads:

```
18, 19, 19, 20, 20, 20, 0, 0, 1, 1, 2, 2, 0, 0, 1, 1, 2, 2, 0, 0, 1, 1, 0, 0, ...
```

It counts **up** and resets every time `chargerState` cycles 1 → 3 → 1. It is seconds *since* the
current charge cycle began, not seconds remaining, and the status carries no remaining-time figure
to put there instead. The number was real; the label was a lie about it.

**`Coil` is now two fields.** `Coil` carries type and serial; `Coil temperature` carries the
temperature with a real `°` sign — this service compiles **without `/utf-8`**, so it is built with
`QChar(0x00B0)` rather than typed into a literal. One string carrying all of it meant a
whole-degree temperature change rewrote the identity too.
⚠ That constraint carried into the Qt 6 tree unchanged: `R:\src\neuroMS\CMakeLists.txt` still adds
no `/utf-8`, and `neuromsconfig.cpp:289` / `neuromsdriver.cpp:989` still build the degree sign from
`QChar(0x00B0)`. It is a deliberate exception to the tree-wide rule in
[architecture.md §11b](../migrations/framework-evolution.md) — do not "fix" it by typing the character into a
literal.

⚠ **The two temperatures are not the two pulses of a pair.** The device reports a *complete
per-block status set* — `coilTemp1`/`coilTemp2`, `chargerState1/2`, `capVolt1/2`,
`remainsSeconds1/2`, `fanRpm1/2`, `thyristorTemp1/2` — so they are two readings of the **same
physical coil** through the two blocks' channels, which is why they agree. The second is now shown
only when it disagrees with the first.

<a id="history-73--the-two-trees-diverged-here-in-both-directions--2026-09-02"></a>

### 7.3 ⚠ The two trees diverged here, in both directions — 2026-09-02

`neuroMS` was copied into the Qt 6 tree on 2026-08-28, about five hours *before* `R:\src_Qt5`
received the second half of the §7.1 fix. Neither tree is a superset of the other, and the merge
has to go both ways.

**What Qt 6 was missing — the `standby` state.** ✅ Merged on 2026-09-02; what follows is the
record of the gap, kept because it is what makes the merge checkable. Verified in the sources at
the time. In
`R:\src_Qt5\neuroMS\neuromsconfig.cpp`: `:396` creates `standby`, `:467-468` send
`ready`/`charging`/`charged` there on `leftOperatingState()`, `:469` returns to `ready` on
`enteredOperatingState()`, and `:471` gives `standby` its own `disconnect` transition and nothing
else. `R:\src\neuroMS\neuromsconfig.cpp:458` is the *first attempt* the rig rejected —
`leftOperatingState()` → `ready`, over `{charging, charged}` only, with the in-code comment
"`ready` is the honest destination". There is no `enteredOperatingState()` anywhere in the Qt 6
module (`grep` returns zero hits across `neuromsconfig.*` and `neuromsdriver.*`), so switching the
machine back on does not move the service either. Its in-code justification, that
`updateParameterAvailability()` takes the buttons away, does not hold: that function is identical
in both trees and only touches parameters and the `fire` Action — it cannot disable a
`QStateMachine` transition, so **`charge` stays offered on `ready`**. The third hunk is missing
too: on an `NMS_GetCapabilities` failure the Qt 5 driver (`neuromsdriver.cpp:186-196`) works out
whether it *could* stimulate before clearing `m_caps` and emits `leftOperatingState()` if so; the
Qt 6 driver clears and returns silently, leaving the state machine in `charged` describing a device
it has just lost.

**What Qt 5 is missing — the paired-pulse handshake fix.** After a connect the device answers with
block 1 only, so `refreshBothBlocks()` writes block 1's intensity up one step and straight back
down; the second answer is the one that carries block 2, and the intensity ends where it started.
Both trees do that. The Qt 5 version *also* forces `delay` to zero on every connect, on the
reasoning — in the code — that "we only ever run at
zero inter-pulse delay" — which **silently converts a deliberately requested paired-pulse setting
into simultaneous firing**, changing both the discharge count and block 2's intensity. §4.1 is
exactly why that is a mode change and not a rounding. `R:\src\neuroMS\neuromsconfig.cpp:797` no
longer forces it: it computes `expectedIpiMicros` from the operator's own `delay` through
`quantiseIpiMicros()`, re-applies it with the nudge, and `verifyBothBlocks()` compares the device's
echo against that value instead of requiring zero. Validated on 2026-08-28 through a deployed
`neuroMS.exe --emulation`: 20/20 checks, with 55/40 %, a 12.5 ms interval and **paired mode
surviving the handshake**.

⚠ **2026-09-07 — the interval is the service's, not the machine's.** The 2026-08-28 rewrite also
made the driver *adopt* the machine's interval at connect (D3), and the two changes together
undid what Qt 5's forced zero had been for: a Neuro-MS comes up on its own profile at **10 ms**,
the adopted 10 ms replaced the parameter's 0 ms, and the handshake faithfully re-applied it —
every start was a paired-pulse start (`neuroMS: … reapplied delay 10 ms … device reports 30 / 30 %,
delay 10 ms`), on a rig whose protocols run simultaneous. The driver now adopts the intensities
only; `delay` keeps what the configuration or the operator gave it, 0 ms by default, and that is
what the handshake writes and verifies (`… delay 0 ms`). A paired-pulse setting chosen *before*
connecting still survives, because the parameter decides, not the profile. The `settings` event
published at connect carries `delayMs` (the service's, about to be written) and `deviceDelayMs`
(what the profile reported).

⚠ Seen on the machine the same evening, after that change: still `reapplied delay 10 ms`. The
adopt block was not the only path. The status poll's **mirror** copies the machine's report into
the parameters whenever it changes, and on the real machine the first real report after Open —
30 / 30 / 10, the Open-time read being all zeros — arrives before the handshake has written
anything (`device ready after 1 ms`), so `delay` was 10 ms by the time the handshake read it. The
emulator's profile arrives at Open and only ever dodged this by timing. Now the mirror, status
poll and front-panel events alike, leaves the **interval** alone until this service has written
its settings once (`m_intervalWritten`, set by `pushStimulationParameters()`); the intensities are
mirrored as before, and the machine's own knob is mirrored again once the service's value is on
the machine.

<a id="history-disconnecting-from-a-machine-that-is-off-or-unplugged-2026-09-07"></a>

### Disconnecting from a machine that is off or unplugged (2026-09-07)

Reported from the rig the same day: switch the stimulator off at its own button, pull the USB
cable, press **Disconnect** — and the service froze, unresponsive, and the Configurator showed it
with no parameters at all. The teardown ran on the driver thread through a *blocking*
cross-thread call: a disarm (`NMS_SetArmed(0)`) and then `NMS_Close()`, which powers the machine
down and waits for it. On a machine that is off those vendor calls never return, the worker sat
inside the vendor DLL, the service's main thread sat waiting for the worker, its event loop was
gone, discovery timed out, and the Configurator dropped the service. The same teardown runs on
the way into `error`, which the status poll enters by itself after **5** unanswered reads
(`MaxConsecutiveStatusFailures`), so the hang did not even need the button.

And the frozen services were not idle. Found later the same day in Task Manager: the two
`neuroMS.exe` left behind by the unplug tests had taken **13 GB of memory each** and were writing
to the SSD flat out, and the machine had slowed to a crawl. Nothing on our side accumulates — the
bridge's error buffer, event queue and panel-action queue are fixed-size arrays — so the growth is
inside the vendor stack: its own threads carry on after the USB device has vanished, and its
`LogBase` writes as they go. There is no vendor call that stops them; `Close()` is the one that
waits on the machine.

**So a lost stimulator ends the service.** Four things changed:

* **The disconnect is queued to the worker and not waited for.** `doDisconnect()` posts
  `shutdown` with a queued connection, clears the readouts, and the state machine has already
  moved to `init`. A **watchdog** (`DisconnectWatchdogMilliseconds`, 10 s — a power-down on a
  live machine takes a second or two) then checks whether the driver came back
  (`shutdownFinished`). If not, the process ends: see below.
* **A machine that has gone from the USB bus ends the service too.** Five unanswered status
  reads (`MaxConsecutiveStatusFailures`) are only the point at which the driver *asks the
  question* — see the escalation ladder below. When the answer is "not on the bus any more", the
  session is dropped through the new bridge entry **`NMS_Abandon()`**, which releases the managed
  handles without a disarm or a close (there is nothing to disarm or power down on a machine
  that is off, and both calls would wait on it); the `disconnected` event carries
  `abandoned: true`; and the process ends.
* **Ending means `abandonProcess()`**: one `qCritical` line naming the reason and the remedy —
  *restart `NeuroMS.bat` once the stimulator is plugged in and switched on* — then, 500 ms later,
  `TerminateProcess` with **exit code 3**. Not `exit()`: a thread stuck inside the vendor DLL must
  not be handed a DLL-detach or a finaliser to hang in, and there is nothing to flush. The
  Configurator sees the service leave the bus, which is a plain fact rather than a frozen row
  with no parameters; the strip starts a fresh one in one click.
* **A memory guard** polls the process's private memory every 2 s and calls `abandonProcess()`
  above **1024 MB** (`NEUROMS_MEMORY_CEILING_MB` in the environment overrides it; a healthy
  service runs well under 200 MB). It is the last line of defence for anything the first three
  do not catch — a vendor stack running away while the machine is still nominally there.

All of it is reproducible offline. With `--emulation`, `NEUROMS_EMU_UNPLUG_MS=<ms>` makes the
software stimulator stop answering that long after connect (status, capability and settings
calls fail as on an unplugged device) and `NEUROMS_EMU_CLOSE_HANG_MS=<ms>` makes its `Close()`
block that long first, the way the vendor stack does. Run 2026-09-07 through the deployed
`neuroMS.exe --emulation`: a normal connect/disconnect (`disconnected in 0 ms`, service up); an
unplug followed by an immediate disconnect with a 30 s close — the watchdog fired at 10 s and the
process ended with code 3; an unplug left alone — 5 failed reads, `error`, session abandoned,
process ended with code 3; a ceiling of 8 MB — the guard ended the process at once.

⚠ Not run on hardware: whether the real vendor `Close()` ever returns on an unplugged machine, and
what exactly its threads allocate, is what could not be measured; the policy is written for the
case that neither can be reasoned with. ⚠ *(Written when five failed reads still ended the
service outright. They do not: see "Five failed reads are a question, not a verdict" below, which
was the correction the rig asked for within the hour.)*

<a id="history-the-log-file-the-heartbeat-and-the-crash-handler-2026-09-07"></a>

### The log file, the heartbeat and the crash handler (2026-09-07)

Asked for from the rig after a session in which *"the Neuro-MS randomly disconnected (turned off)
the device"* and the console went with the process: **a service that cannot be watched has to
write things down.** Every message this process emits — its own and the framework's — is appended
to a file beside the executable, flushed line by line, with the console handler chained rather
than replaced (`neuroMS/servicelog.cpp`):

| file | what it is |
|---|---|
| `bin\neuroMS.log` | every line, across runs, one banner per run; rolls to `neuroMS.log.1` at 64 MB |
| `bin\neuroMS-crash-*.dmp` | a minidump, if the process dies of an unhandled exception |
| `bin\neuroMS.last-exit.txt` | the reason for the last deliberate self-exit (also read back into the next run's banner) |

* `NEUROMS_LOG=<path>` writes it elsewhere, `NEUROMS_LOG=off` writes none,
  `NEUROMS_LOG_VERBOSE=1` includes `qDebug()`, `NEUROMS_LOG_MAX_MB=<n>` changes the roll size.
* **The banner** names the pid, the executable, the command line, the bridge and vendor build,
  every `NEUROMS_*` variable that is set, and how the previous run ended. A fault read days later
  needs no one to remember what was configured.
* **A heartbeat every 10 s** (`NEUROMS_HEARTBEAT_MS`) records connected state, mode, charger,
  both intensities, the interval, the alarm text and **this process's private memory** — the
  figure that shows a vendor stack starting to run away long before any ceiling is reached, and
  the timeline that turns "it disconnected at some point" into a minute and a second.
* **Every disconnect says why, one line above itself.** `doDisconnect()` logs the reason it was
  given: the `disconnect` transition (the operator or a client), the `error` state *and the fault
  text that led to it*, a watchdog, or a graceful exit. "The stimulator turned itself off" is the
  symptom; this is the cause, in the same file.
* **A crash is distinguishable from a clean exit.** An unhandled structured exception writes the
  exception code, the faulting address and a minidump before the process goes.

<a id="history--neuroms_never_self_disconnect1--the-operator-keeps-the-connection"></a>

### ⚠ `NEUROMS_NEVER_SELF_DISCONNECT=1` — the operator keeps the connection

From the same report: *"the device connection is not something it should really manipulate on its
own"*, which is right during an experiment. With this set, the service **never** drops the session
or ends itself on its own judgement — not on a fault, not on a lost machine, not on the memory
ceiling. Each of those becomes a log line saying what it would have done and why (the exit
warning repeats once a minute so a growing fault stays visible). The trade is explicit: if the
machine really has gone, the vendor stack will leak until the service is closed by hand, and the
heartbeat's memory figure is how that is watched.

<a id="history-the-open-succeeded-in-about-half-of-attempts-2026-09-07"></a>

### The open succeeded in about half of attempts (2026-09-07)

Reported from the rig: `NMS_Open failed (bridge error -1)`, with the machine's relays audibly
clicking first — the vendor stack was talking to it and the open then aborted. Three defects met
in that one line:

* **The reason was being wiped before anyone could read it.** Both failure paths in `NMS_Open`
  set an explanation and then called `NMS_Close()` to tidy up, and *every* bridge entry point
  begins with `setErrorNative(nullptr)`. So `NMS_GetLastError()` was empty by the time the driver
  read it, and the log carried a number with no cause. The bridge now saves the text across the
  cleanup call. A refusal that is not transient says what it is: switched off at the front panel,
  still settling, held by another program, or the slave block of a two-unit machine.
* **A stimulator that has just been closed is not ready to be opened.** The vendor `Close()`
  powers the machine down; an open that arrives while it is coming back is refused. The bridge
  keeps the time of the last close and an open waits out the remainder of a **1.2 s** settle
  window (`NEUROMS_OPEN_SETTLE_MS`, 0 disables).
* **One refusal was final.** The driver now retries: **5 attempts** with a **growing pause**
  (0.7, 1.4, 2.1, 2.8 s — `NEUROMS_OPEN_ATTEMPTS`, `NEUROMS_OPEN_RETRY_MS`), re-enumerating
  between them and looking the machine up **by serial**, because a refresh renumbers the list and
  retrying a bare index could open a different unit on a two-machine rig. Three fixed attempts
  were not enough: a **cold start** — a fresh process, with nothing of ours to release — was
  reported opening only on the third try, so the wait belongs to the machine itself after the
  previous host let go of it, and a fixed short pause could not cover it. Nothing blocks the
  service during any of this, so patience is cheap.
* **The handle is released deterministically.** The vendor wrapper owns its USB handle and frees
  it from a *finalizer*, so dropping the last reference in `NMS_Close()` only made the object
  eligible for collection — a reopen in the same process could meet a device its own previous
  session had not let go of. `NMS_Close()` now collects, waits for finalizers and collects again
  before it returns. ⚠ Deliberately not in `NMS_Abandon()`: its whole point is a machine that has
  gone, whose finalizer may block on a device that will never answer.
* **A leftover service is named.** If the first open fails, the driver looks for other
  `neuroMS.exe` processes and says so with their process ids — one of them holding the
  stimulator is a cause no amount of retrying can fix, and it is invisible without Task Manager.

**What the rig's own log then measured** (2026-09-07 evening, `bin\neuroMS.log`, four reconnects):

| | |
|---|---|
| a **failed** open | ~7 s inside the vendor call, and the re-enumeration after it about as much again — so ~14 s per retry, which is where the "very long wait" came from; the pauses were never the cost |
| a **successful** open | ~3 s |
| when the machine became openable | **45–50 s** after the previous close in the two reconnects that struggled; **6–10 s** in the two that did not |
| what told them apart | the slow ones followed a session whose charger had been **armed** for minutes, and one where the machine had been **switched off at its own panel** (`mode standby` in the heartbeat just before). A stimulator that has been holding a charge, or has just been powered down, is not ready to be reopened for the better part of a minute |
| memory during those attempts | 46 → 155 → 363 → 211 → 46 MB — ordinary .NET churn while the vendor stack retries, **not** a leak. The steady state is 30–47 MB |

So the retry now runs to **8 attempts** (≈2 minutes of trying, which outlasts the machine's own
recovery), the pause is a flat 500 ms because the open dominates it, **every phase is timed in the
log**, and after the second failure one line says what is happening and that it is normal. The
connect watchdog is 240 s so that a connect which is merely slow is never mistaken for one that
will never return. `NEUROMS_OPEN_REFRESH=0` skips the re-enumeration between attempts, worth
trying if those timings show it is the expensive half.

<a id="history--a-retried-connect-owns-the-worker-and-that-was-worse-than-the-fault-2026-09-07-last-round"></a>

### ⚠ A retried connect owns the worker, and that was worse than the fault (2026-09-07, last round)

The next log from the rig showed the machine refusing every open, and the service turning that
into a cascade of its own making:

```
17:53:22  open attempt 1 of 8 failed after 13130 ms ...
17:53:28  driver call skipped -- the driver is still connecting     (×2)
17:53:28  Unable to charge:
17:53:28  disconnecting -- the service entered the `error` state
17:53:34  cannot connect -- the previous disconnect is still in progress
17:53:38  the vendor stack has not returned from the disconnect after 10000 ms ... exit code 3
```

Three separate defects, all mine, all from making the connect asynchronous without following the
consequences through:

* **A skipped driver call was treated as a device fault.** A retried open occupies the worker for
  up to two minutes; anything the operator does meanwhile is correctly skipped, but
  `attemptCharge()` read that as "the charge failed" and raised `errorOccurred`, which
  disconnects. Pressing Charge during a slow connect therefore killed the connect. A skipped call
  now retries within the existing readiness budget and never becomes an error.
* **The disconnect watchdog timed a driver that was not stuck.** The shutdown is queued behind
  the open loop, so the ten-second watchdog measured the *open*, decided the vendor stack was
  hung and ended the process. It is armed now only when the worker can actually reach the
  disconnect — from `onConnectFinished()` when a connect is in flight.
* **A connect could not be cancelled.** `NeuroMsDriver::cancelConnect()` sets an atomic flag the
  retry loop checks between attempts, so a disconnect takes effect within one open call instead
  of after the whole loop, and its expected failure is not reported as a fault
  (`m_connectCancelled`).

**And the enumeration is not the expensive half after all.** The timings settled the question the
previous round raised: the open itself is **13.1–13.7 s** and the re-enumeration **~0.5 s**, so
`NEUROMS_OPEN_REFRESH=0` buys nothing and the default stands.

<a id="history--it-was-two-services-on-one-stimulator-2026-09-07-night-resolved"></a>

### ⚠⚠⚠⚠ It was two services on one stimulator (2026-09-07, night, resolved)

The log finally caught it in the act:

```
22:51:59  neuroMS: ⚠ another neuroMS.exe is running (pid 14408)
```

**Two Neuro-MS services were running at once** — the Qt 5 build and the Qt 6 one, whose
executables have the same name — and each held the device away from the other. That explains the
whole evening at last, including the part that made no sense: "the Qt 5 build stopped working
too", and "a reboot did not help". Whichever service was started first owned the machine; the
other was refused, and switching builds only swapped which one was locked out.

Three consequences, all now in the code:

* the duplicate-process check runs **before the first open attempt**, not after the first failure,
  and says plainly that one service per stimulator is the rule and that the Qt 5 build counts;
* the readiness poll is **queued like everything else**. A single probe blocked the service for
  **53 s** while the USB link was erroring (`ERROR_BAD_COMMAND`, then `device ready after
  53368 ms`), and a blocking probe stops the whole service — no discovery answers, no
  description, and a Configurator showing the service with an **empty parameter pane**. That is
  precisely what was reported as "wedged, no parameters"; nothing on the main thread waits for
  the device now;
* the earlier advice to power cycle, and the conclusion that this was the device or the USB link,
  were both wrong. They are left below, struck through, because being able to see how a wrong
  conclusion was reached is worth more than a tidy document.

**The rule for the rig: one `neuroMS.exe` at a time.** Check Task Manager before blaming anything
else, and remember that `R:\dist\bin\neuroMS.exe` and `R:\dist_Qt5\msvc64\bin\neuroMS.exe` are
indistinguishable there by name.

<a id="history-correction-the-qt-5-build-fails-the-same-way-so-this-is-the-machine-2026-09-07-night-superseded"></a>

### ~~Correction: the Qt 5 build fails the same way, so this is the machine~~ (2026-09-07, night, SUPERSEDED)

The section below was written from a single Qt 5 comparison and is **wrong**. Within the hour the
same Qt 5 build stopped connecting too — no parameters, no response to Connect — and **a reboot of
the PC did not clear it**. The Qt 6 build then opened on its eighth attempt. So:

* both builds are refused identically, so it is not a Qt 6 regression and not the settle sleep or
  the forced collection (which are still off by default; that part of the change stands, because
  neither was measured and neither belongs in a driver on a hunch);
* a refused open takes a **very consistent 13.00 s** and a successful one 3.1 s, which is a
  timeout somewhere below us, in the vendor stack, the USB driver or the stimulator's firmware;
* it always eventually succeeds — on the rig, on attempts 2, 4, 5, 7 and 8 — so the retry is
  riding out a device-side fault rather than papering over one here;
* it **survives a PC reboot**, which rules out our process state, handle leaks and the .NET heap
  entirely.

What the software can honestly do about it, and now does: keep trying (**12 attempts**), say in
the log that the Qt 5 build is refused the same way so nobody goes hunting through Resonance, log
the **enumeration count between attempts** so a machine dropping off the bus can be told from one
that is present and refusing, and stay alive while it happens.

⚠ **The memory guard needed one more concession.** A refused connect allocates enormously inside
the vendor stack — 333 → 868 → 1124 → **1316** → 463 MB across seven refusals in the rig's log,
all reclaimed afterwards. The ceiling is therefore **doubled while a connect is in flight**;
otherwise a service would be killed during a connect that was about to succeed.

**The decisive test, if it happens again:** run Neurosoft's own program. If that is slow to
connect too, nothing in Resonance can help and the machine or its USB link needs attention.

<a id="history-the-qt-5-build-reconnects-instantly-so-the-regression-is-ours-2026-09-07-evening--superseded"></a>

### The Qt 5 build reconnects instantly, so the regression is ours (2026-09-07, evening) — SUPERSEDED

The measurement that ended the guessing: on the same machine, minutes apart, the **Qt 5 build of
2026-08-28 connects, disconnects and reconnects in quick succession with no refusals at all**,
while this build needs 30–60 s and four to five open attempts before the stimulator will let it
back in. The device is therefore not "settling", not wedged, and not in need of a power cycle —
those were hypotheses, and this observation refutes them.

The two builds' device-facing sequences were then diffed call for call. They are identical —
`pushPanelPolicy`, `NMS_Open` with the same options, `NMS_SetArmed(0)`, `NMS_GetDroppedEventCount`,
`NMS_Close` — **except for two things added to this build on 2026-09-07**:

1. `waitForOpenSettleWindow()`, a sleep before the open;
2. `GC::Collect()` + `WaitForPendingFinalizers()` in `NMS_Close()`, forcing the vendor's finalizer
   to release the USB handle immediately.

Both were reasoned, neither was measured, and one of them is very likely the cause — (2) is the
better suspect, because forcing the finalizer the instant `Close()` returns can cut the machine's
own power-down short, which is exactly the kind of thing that leaves a device unwilling to
reopen. **Both are now off by default**, so the shipped path is the Qt 5 one, and both are
switchable for a controlled test: `NEUROMS_OPEN_SETTLE_MS=<ms>` and `NEUROMS_CLOSE_GC=1`.

⚠ The lesson for this driver, written down because it has now cost a day: **when a comparator
exists that demonstrably works, diff against it before adding a mitigation.** Every fix above
that was derived from a measurement held up; every one derived from a hypothesis about the
hardware made things worse.

⚠ **What was thought to wedge the machine.** In that log the previous service was ended *during* its
disconnect — the last line before it disappeared is `disconnecting -- asked for through the
`disconnect` transition` with no `disconnected in N ms` after it. A vendor close that never
finishes leaves the stimulator half-closed, and it then refuses **every** open, for as long as
fifteen minutes of retrying showed. Only a power cycle clears it: off at the panel, USB out, ten
seconds, USB in, on. After the fourth refusal the driver says that, because no operator can be
expected to know it. ⚠ *Written before the Qt 5 comparison above, which shows the machine is not
actually wedged — an interrupted close is still worth avoiding, but it is not the explanation for
the slow reconnects.*

⚠ **And the memory guard was one bad connect away from firing on nothing.** 363 MB of churn
against a 1024 MB ceiling is not much margin on a slower machine, and ending a service in the
middle of a connect that was about to succeed would have been the worst kind of false positive.
The ceiling is **2048 MB** and it must be exceeded on **three consecutive samples** — a spike is
not a runaway, while the 13 GB case was monotonic and is still caught six seconds later.

⚠ **And a failed connect used to poison the next one.** The sequence is `error` → disconnect →
`scanning`; since the disconnect became a queued call, the rescan landed inside the window where
driver calls are skipped (`driver call skipped -- the driver is still disconnecting`), so the
Stimulator list was emptied and the following connect had nothing to open. `onDriver()` reports
whether the call was made, and a scan that could not run is re-run as soon as the driver is free.

**A machine that never answered is a failed connect, not a lost one** (the same evening, after a
USB re-plug: `Neuro-MS: … USB error (WinError 22 ERROR_BAD_COMMAND)` repeated, then five
unanswered reads — and under the first version of the policy the process ended, which the operator
saw as a crash). Five failures with **no successful status read since the connect**
(`m_everAnswered`) close the session normally, take the service to `error` and print what to do —
*switch the stimulator off and on at its own button, then connect again* — without ending the
process. The vendor's repeated error lines are rate-limited to one per distinct text and one every
5 s with a count; every event still reaches the `events` stream. And because a console window
vanishes with the process, `abandonProcess()` also writes **`bin\neuroMS.last-exit.txt`** with the
reason and the remedy, and waits 6 s instead of 0.5 s when a console is on screen. Emulator
scenario for it: `NEUROMS_EMU_UNPLUG_MS=0`, silent from the first read — `error`, the line, the
service up, no exit note.

⚠ **Merge, do not choose.** The two changes touch adjacent lines of the same function.
[qt6-work-list.md §1b](../migrations/qt6-work-list.md) is the merge instruction, and it names one latent
inconsistency to resolve while doing it: `neuromsconfig.cpp:797` computes `expectedIpiMicros` with
**no mode test**, while `neuromsdriver.cpp:534` writes `usesInterval(mode) ?
quantiseIpiMicros(ipiMicros) : 0`. On a single-block unit with a non-zero `delay` the echo can
therefore never match and the handshake retries to exhaustion.

---


<a id="history-8-offline-test-plan"></a>

## 8. Offline test plan

Everything below runs with no stimulator attached. It is what keeps the driver honest between
visits to the lab, and it is the baseline to compare against when something fails on hardware.

| # | What | Command | Good looks like |
|---|---|---|---|
| 1 | Logic | `<build>\tests\test_NeuroMsLogic.exe` | **38 tests, all passing.** Interval ladder, dead zone, knob arithmetic, mode determination, charge policy, `ready` derivation, status channel table |
| 2 | Bridge C ABI | `<build>\tests\neuroMS\ns_bridge_smoke.exe --emulation` | **65 checks, 0 failures.** Enumeration, open/close, all three modes, charge/fire/discharge, panel mirroring and its ceiling, coil unplug, no dropped events |
| 3 | Whole service | start `neuroMS.exe --emulation`, then `nms_stream_check.exe --seconds 6 --fire` | **24 checks, 0 failures.** Discovery, both streams present *before* connecting, 28 named status channels at 2 Hz, full charge/fire/discharge lifecycle, pulse records carrying dI/dT, coil temperature and the powers in force |
| 4 | Recording | add `--record <file>.h5` to (3) | The file grows; reopening it shows `/events/messages` and `/status/data` with 28 named channels |

Measured on 2026-08-15: (1) 38/38, (2) 65/65, (3) 24/24, (4) 12 event records and 10 status rows
× 28 channels in a 69,736-byte file, all read back independently with `h5py`.

The emulator is not a stub — it is a software stimulator with charge timing, a self-disarm
countdown, a coil that warms with each pulse and cools between them, and injectable faults
(`NMS_EmuInjectPanel`, `NMS_EmuInjectDeviceEvent`, `NMS_EmuSetStimState`,
`NMS_EmuSetCoilConnected`). Those hooks exist so that the paths a keyboard cannot reach offline —
a knob being turned, a coil being unplugged mid-session — are still covered by a test.

---


<a id="history-9-hardware-bring-up-with-a-contingency-for-each-step"></a>

## 9. Hardware bring-up, with a contingency for each step

Run in order. Each step says what to do if it fails, because several of the assumptions below
are inferences from the assembly and the vendor's samples rather than documented behaviour.

**Before anything: no coil, or a coil pointed into free air. Nothing in this list needs to
discharge into anything, and only step 9 discharges at all.**

<a id="history-90-prepare"></a>

### 9.0 Prepare

⚠ **Either distribution will now do, and that is the point of the first session.** The `standby`
state landed in `R:\dist` on 2026-09-02 (§7.3), so the Qt 6 build is no longer disqualified — but
it has never driven a physical stimulator, so take `R:\dist_Qt5\msvc64` along as the fallback and
be ready to compare. Delete any
`bin\NeuroSoft.*.dll` / `bin\Neurosoft.*.dll` at the top level of `bin\` (§3). Run the offline plan
(§8) first — if steps 1–4 do not pass on that machine, stop; the problem is the deployment, not the
stimulator.

The Qt 6 equivalent, for when it is cleared, is the whole of `R:\dist` — there is no `msvc64\`
level in it, `bin\` sits at the root, and the ten vendor assemblies are already staged in
`bin\neuroMS\` with nothing flat in `bin\`.

<a id="history-91-the-device-enumerates"></a>

### 9.1 The device enumerates

```bash
rem Qt 5 comparator tree
cd /d R:\dist_Qt5\_build\msvc64\tests\neuroMS && ns_bridge_smoke.exe --hardware

rem Qt 6 tree — the build root is inside the source tree
cd /d R:\src\_build\tests\neuroMS && ns_bridge_smoke.exe --hardware
```

⚠ The Qt 6 binaries in `R:\src\_build` still run, but the cache there is bound to the pre-rename
path (`CMAKE_HOME_DIRECTORY:INTERNAL=R:/srcQt6`). Delete `R:\src\_build` and
`R:\src\_build-kardi2-x32` before the next configure.

*Expect:* one device listed, with its serial and `Neuro-MS monophasic`.

* **"no Neuro-MS stimulator found"** — the bridge scanned all three families (`0x8315`,
  `0x8316`, `0x8317`). Check the machine is switched on at the front panel and that Windows
  shows it under `USB\VID_ACCA&PID_831x`. The vendor's EzUSB driver is vendored at
  `src\neuroMS\sdk\driver\` if Windows has not bound one.
* **"bridge did not initialise"** — assembly resolution. Confirm `bin\neuroMS\` holds the ten
  vendor DLLs and that no flat copies remain in `bin\`.
* **A biphasic or quadripulse machine is listed instead** — expected to work at the bridge level
  (§2), but the service layer has only been reasoned through for the monophasic. Stop and say so.

<a id="history-92-it-opens-and-the-trigger-input-survives"></a>

### 9.2 It opens, and the trigger input survives

*Expect:* `device opens with the trigger input enabled`, then a state of `SINGLE` (one block) or
`TWIN` (two).

* **`STATE_SLAVE`** — the slave block was selected. Pick the master.
* **`STANDBY`** — the front-panel power is off.
* **Open fails** — the machine may already be held by the vendor's own application. Close it.
* ⚠ **Now check the TTL still fires the stimulator**, by hand, with the service connected. This
  is the single most important check in the list: if opening the device disabled the trigger
  input, everything else is worthless. If it did, the fallback is `NeuroMsMono::OpenMS()` in
  place of the base `Open()` with `TriggerSettings` — the bridge uses the latter because it is
  common to all three families and carries `OutForSecondPulse`, but the former is the documented
  path for the monophasic.

<a id="history-93-the-front-panel-still-works"></a>

### 9.3 The front panel still works

With the service connected, at the machine: press **ARM**, turn **intensity**, press
**TRIG** (coil in free air), turn the **IPI** knob.

*Expect:* each produces a `panel` event and a matching `mirrored` event; intensity changes appear
in the Configurator; the ceiling on the safety tab holds.

* **Nothing happens at all** — the panel may be handled entirely in firmware and the callback may
  be notification-only. Harmless: turn `panelArm` / `panelTrigger` / `panelIntensity` off, since
  mirroring is then pointless.
* **A `panel` event but no `mirrored` one** — the policy is off, or the ceiling refused it.
* **Nothing reaches the host at all** — this is the `System.Windows.Forms` risk (§11): the SDK
  may need a pumped message loop that a `WIN32`-subsystem Qt service does not provide. The fix
  is a message loop on the bridge's own thread. Test for it by running
  `ns_bridge_smoke.exe --hardware` (a console app) and pressing the panel buttons: if the events
  arrive there but not in the service, that is the cause.

<a id="history-94-the-ipi-unit--one-measurement-settles-it"></a>

### 9.4 The IPI unit — one measurement settles it

`ns_bridge_smoke --hardware` sets 12.5 ms and prints the device's raw word.

*Expect:* `device raw word = 125`, confirming 0.1 ms per count.

* **12 or 13** — the device counts whole milliseconds. Change `IpiRawPerMillisecond` in
  `bridge/nmsbridge.cpp` from 10 to 1. Nothing else depends on it.
* **Anything else** — record the value and the requested interval and work the scale out from
  two more points.

<a id="history-95-the-capacitor-voltage-scale"></a>

### 9.5 The capacitor voltage scale

The smoke test prints `CAP SCALE CHECK: compare <n> against the front panel's own reading`.

Record the pair. `capVolt` / `capVoltSet` are published unlabelled until this is known; once it
is, give them a unit in `statusChannels()`.

<a id="history-96-charge-and-discharge"></a>

### 9.6 Charge and discharge

*Expect:* `armed` within a few seconds, a non-zero `remainsSeconds`, then `disarmed`.

* **Never reaches armed** — check the coil is connected and neither over-temperature flag is set;
  both are published on the status stream.
* **`remainsSeconds` is 0 or does not count down** — the keep-charged watchdog does not depend on
  it (§6.1), so this is informational. Note what it does instead.

<a id="history-97-does-it-self-disarm-on-usb-loss"></a>

### 9.7 Does it self-disarm on USB loss?

Charge, then unplug USB (or kill the service). Watch the front panel.

This is the one genuinely unknown safety question, and nobody on the project has used this
machine over USB before. If the device **does not** disarm itself, say so loudly in this file and
consider whether a heartbeat the device can time out on is needed.

<a id="history-98-a-sham-pulse"></a>

### 9.8 A sham pulse

`StartStimulation(..., noPulse: true)` appears to run the whole chain — sync, trigger out, event
— **without discharging the coil**. That is inferred from the parameter name and is worth
confirming, because if it holds it is both a sham-stimulation capability for controlled studies
and the safe way to test everything downstream.

*Test:* with a coil attached and the machine charged, fire with `noPulse` and listen. No click,
no `pulse` event with a plausible dI/dT, capacitor voltage unchanged → confirmed.

<a id="history-99-one-real-pulse"></a>

### 9.9 One real pulse

`ns_bridge_smoke.exe --hardware --allow-fire`, coil in free air.

*Expect:* a `pulse` record with a plausible `didt`, and in twin mode two records with `stim` 0
and 1.

* **The pulse fires but no record arrives** — same message-pump question as §9.3.
* **One record in twin mode** — check whether both blocks report; the driver publishes one record
  per `PulseParamInfo` and never rolls them up, so a missing one is the device's.

<a id="history-910-the-number-that-actually-matters-timing"></a>

### 9.10 The number that actually matters: timing

Wire **Trig Out** into an EEG/EMG trigger or AUX input, record with `recorderService`, fire N
pulses, and measure the distribution of *(trigger-channel time − event `rtc`)*.

The TTL is the ground truth; the event RTC is what the software knows. This measurement is what
lets a TEP analysis use the software record at all, and it belongs in this file once taken.

> ## ⭐ TAKEN, 2026-08-22, ON A REAL MACHINE
>
> First measurements from an actual Neuro-MS on the TMS rig, against an **NVX136** at 25 kHz.
> Full account `R:\tests\lab-session-20260822\REPORT.md`; the wider trigger context is
> `_notes/report_trigger-validation.md` §2.
>
> ### ⭐⭐ Trig Out is a 120 µs pulse, and that dictates the sampling rate
>
> **High phase = 0.120 ms median (3 samples at 25 kHz), min 0.080 (2), max 0.120, sd 0.017.**
> The **NVX136 driver has no edge-latch mode, only level sampling**, so whether the amplifier
> sees a pulse at all is a matter of where the sample instants fall inside 120 µs.
>
> | amplifier rate | chance of catching one pulse | measured on the rig |
> |---|---|---|
> | 1 kHz | ~12 % | **1 of 8 discharges appeared on bit 0** |
> | 25 kHz | 3 samples wide, certain | **4 of 4** |
>
> > **Any trigger or latency campaign involving this stimulator must record at 25 kHz.** A null
> > or short count on the trigger bit at 1 kHz means **nothing at all** — it is what
> > level-sampling a 120 µs pulse looks like, and it is indistinguishable from a stimulator
> > that never fired.
>
> ### The stimulator's own contribution to latency is below 40 µs
>
> Command → pulse measured **0.840 ms** median (n = 4, p90 0.880, span 1 sample, sd 0.017) as a
> difference of two sample indices in one recording. It **decomposes**:
>
> | term | value |
> |---|---|
> | bit 1 (the command instant, arduinoTTL BNC1) → bit 0 (Trig Out) | **0.840 ms** |
> | the Arduino's own channel-1→channel-2 dispatch gap, on its own µs clock | **0.838 ms** |
> | ⇒ **this stimulator's trigger-in → Trig-Out** | **≈ 0.002 ms, below the 40 µs resolution** |
>
> ⚠⚠ **Never quote 0.840 ms as "the stimulator's latency."** It is the Arduino dispatching two
> serial lines. The host → board leg is still unmeasured and is in none of these numbers.
>
> ### ⚠ The rig's unit is in PAIRED-PULSE mode: one trigger, two discharges
>
> **8 commands produced 16 `pulse` event records.** §5 already says there are two records per
> trigger in paired and simultaneous mode (`stim` 0 and 1) — this is that, seen from the outside,
> and it is worth stating as an operational fact rather than a wire-format one:
>
> * a trial count derived from commands is **half** the number of discharges the coil delivered;
> * a pulse ledger written by a host tool and the device's own count **should** differ by 2×,
>   and a run that assumes they must match will read the healthy case as a fault;
> * bit 0 does **not** show two edges — the pair shares one Trig-Out pulse — so the trigger
>   channel cannot be used to count discharges on this machine. The `pulse` records can.
>
> ### Trigger settings confirmed for this rig
>
> `triggerChannel 0`, `triggerBit 0`, `triggerEdge Rising` — from the session's own recording,
> idle word `0x0000FFFE` with the machine on and `0x0000FFFF` in standby. **Bit 0 rests LOW only
> while the stimulator is powered**, which makes its rest level a power indicator.

<a id="history-911-a-full-session"></a>

### 9.11 A full session

`neuroMS.exe`, `recorderService`, and the EEG driver together: connect, charge, run the block,
discharge, disconnect. Reopen the HDF5 and confirm the `events` and `status` datasets are beside
the EEG, and that the pulse records line up with the trigger channel.

---


<a id="history-10-safety"></a>

## 10. Safety

Firing is the TTL's job, so the dangerous surface is small. What is built in:

* `maxPower` clamps every intensity change — Configurator, command stream, **and the knob on the
  machine**.

> ⚠⚠ **`connect` ADOPTS THE MACHINE'S OWN SETTINGS, so a clamp sent before `connect` does not
> survive it.** This is D3 in §11a working as designed — the driver deliberately writes nothing
> to the device on open — but it has a consequence every host tool must handle: at the rig on
> 2026-08-22 a harness set `maxPower`/`power1` to 20 %, connected, and the service's `settings`
> event then arrived reading `power1=30, power2=30, "adopted from the device; nothing was written
> to it"`. The harness believed it had clamped to 20; the machine held 30.
>
> **The rule for anything driving this service: clamp AFTER `connect` as well as before, read the
> values back, and refuse to charge unless the read-back is what was asked for.** Two further
> details make that harder than it sounds and are part of the rule:
> * a read of `svc.parameters` within ~1 s of `sendParameter` returns the **stale** value, which
>   is indistinguishable from a silent refusal — **wait ~3 s**;
> * a parameter that is **absent** from the read-back must count as a failure, not a pass.
>
> `R:\config\lab\PowerGate.qml` is that sequence as a shared component, and it owns the
> `charge` transition so no harness can reach `charge` without having passed it.
* Charging is refused with no coil, or with either over-temperature flag set, and the reason is
  published rather than swallowed.
* `discharge` on `stop`, on entering `error`, and in the destructor. On `disconnect` the driver
  asks for a disarm and does **not** wait for it: `shutdown` is invoked across threads with a
  blocking connection, so the old `NVX`-style eight-second `NMS_WaitCharger` was up to eight
  seconds of frozen Configurator on every disconnect, and the `qCritical` it fed fired on a
  timeout rather than on any evidence the machine was still charged. The `NMS_SetArmed(0)` return
  code rides on the `disconnected` event as `disarmResult`, and a refusal is said once on the
  console. ⚠ Whether the stimulator brings its own capacitors down after the host lets go is NOT
  established here — see the comment in `NeuroMsDriver::disconnectDevice()`.
* `idleDischargeMinutes` bounds the keep-charged watchdog.
* `coilTempWarning` publishes a warning before the protection cuts in, so an experimenter can
  pace the protocol instead of discovering it mid-block.
* Host firing is off by default and is separate from panel mirroring.

Not built in, and deliberately: any notion of dose limits, per-session pulse counts or
inter-train intervals. This unit has no rTMS mode, and inventing safety arithmetic the machine
does not itself enforce would be worse than not having it.

---


<a id="history-11a-twelve-defects-fixed-before-the-first-lab-visit-2026-08-17"></a>

## 11a. Twelve defects fixed before the first lab visit (2026-08-17)

An adversarial review, run specifically against "what breaks when a real stimulator is on the
other end", found twelve. All are fixed. They are recorded because every one of them was
invisible in emulation, and several would have been dangerous rather than merely wrong.

| | What it was | Why it mattered |
|---|---|---|
| **D1** | `disconnectDevice()` discharged only if the driver believed the device was charged | A charge from the front panel, with mirroring off, would have been left in place. Now unconditional. ⚠ **Superseded 2026-08-25**: the blocking confirmation and the `dischargeFailed` event and `qCritical` that depended on it are gone — the wait froze the Configurator for up to 8 s and the warning fired on a timeout, not on evidence. `NMS_SetArmed(0)` is still sent unconditionally and its return code is now the `disarmResult` field on the `disconnected` event. |
| **D2** | Nothing discharged when the process was killed | These services are windowed and routinely closed with the mouse, and `keepCharged` re-arms the device on every expiry. Now `SetConsoleCtrlHandler` + `aboutToQuit`. Cannot cover `TerminateProcess`; nothing can. |
| **D3** | Connecting pushed the Configurator's defaults (30 / 30 / 0) into the device | An operator part-way through hunting a threshold at 20 % would have been raised to 30 % by the act of starting the service. The driver now **adopts the intensities** the machine is set to and writes nothing to them. ⚠ The **interval it does not adopt** (2026-09-07): a Neuro-MS coming up on its own profile reports 10 ms, and adopting that had turned every start into paired-pulse. `delay` keeps what the configuration or the operator gave it — 0 ms, simultaneous, by default — and the post-connect handshake writes it. |
| **D4** | The bridge's panel policy defaulted to fully permissive, and the real policy was pushed *after* `NMS_Open` | The vendor wrapper raises its handlers *during* open, so a front-panel TRIG in that window would have fired the coil. Now defaults to all-off, and the policy goes down before the open. |
| **D5** | `chargerIsSettling` omitted `PREPARING` and `WAITING` | A device sitting in either would have been re-armed fifty times a second, forever, drowning the log meant to explain it. Now included, plus a one-per-second rate limit and a ten-attempt bound. |
| **D6** | Four of the five SDK callbacks had no exception handler | An exception escaping into the SDK's event dispatch realistically kills the notification thread — pulse reporting stops silently while everything else keeps working. |
| **D7** | Null guards sat *outside* their `try`, and touching a `Session` static loads the vendor assemblies | On a broken deployment the managed exception unwinds out of a C-ABI export into native code and takes the process with it — crashing on exit instead of reporting the deployment problem. |
| **D8** | `setErrorNative(nullptr)` was called in 3 of ~25 exports | `NMS_GetLastError()` was stale on almost every failure, so a `SetParams` refusal reported *"the stimulator refused to open"*. **The worst defect for a lab day: every diagnostic pointed at the wrong thing.** Now cleared in all 33 exports, and the real return code reaches `fail()`. |
| **D9** | Capabilities were read once, microseconds after open, and never again | If that read caught `STANDBY`, the driver believed all session that there was one block — which silently sets a twin machine's slave to 0 %, because `effectiveSecondIntensity()` returns 0 for `Mode::Single`. Emulation answers `TWIN` instantly, so it could never show this. |
| **D10** | The bring-up tool's edge detector compared the whole 32-bit trigger word | Any other input bit toggling counted as a stimulus, and a falling edge on the wired line counted as nothing. The word never rests at zero — one rig idles at `0xFFE6`. Now reads one bit, adopts its resting level, and reports which bits actually moved. |
| **D11** | The status stream declared 2 Hz and published at ~1.3 | A default `QTimer` is coarse and quantised to Windows' ~15.6 ms tick, so a 20 ms period fires at ~31 ms. A `Float64` consumer lays samples at the declared rate, so the whole telemetry timeline was misplaced. Now `PreciseTimer`, paced by the elapsed clock. |
| **D12** | Front-panel mirroring re-entered the SDK from the SDK's own callback thread | Including `StartStimulation`, which discharges the coil. If the SDK serialises device I/O behind a lock held while raising the event — the ordinary shape for a USB reader thread — that deadlocks, and nothing notices, because cached status properties keep answering. Mirroring is now split: the callback decides and queues, and `NMS_GetEvents` performs it on the worker thread. **The panel still works, which was a hard requirement.** |


<a id="history-11b-the-lab-kit"></a>

## 11b. The lab kit

`R:\dist\lab-kit-neuroMS` is a self-contained 14 MB folder for the bring-up visit: the
diagnostic tool, its own copies of every DLL it needs, three launchers, and the printed guide.
It deliberately carries its own vendor assemblies — see §3 for why running it inside an existing
`bin\` would be a mistake.

`nms_bringup` walks §9 in order, does the automated half itself, asks for the half only a person
can judge, and writes a Markdown transcript and a JSON file that are **flushed after every
step** — so a crash, a stop, or an unplugged cable still leaves everything up to that point on
disk. Nothing that can discharge a coil sits behind a single keystroke: those prompts require
the word `FIRE`. Every step is skippable.

It talks to the bridge directly rather than to the service: one process, one journal, and it
works before the service is trusted.

<a id="history-the-rigs-wiring-is-better-than-a-single-trigger-line-and-the-tool-exploits-it"></a>

### The rig's wiring is better than a single trigger line, and the tool exploits it

Both of the NVX136's trigger **inputs** are in use, and neither is an output:

| Amplifier input | Carries | Meaning |
|---|---|---|
| bit 0 | the stimulator's **Trig Out** | moves only when the coil actually discharged |
| a second bit | a T-splitter on the line **into** the stimulator's Trig In (from the Arduino) | the command that was sent |

Cause and effect are therefore two bits of **one sampled word on one clock**, which changes what
can be measured:

* **Command → discharge latency needs no assumptions at all.** It is a count of samples between
  two bits of the same word — 40 µs of resolution at 25 kHz — with no cross-clock inference and
  no dependence on whether a block's timestamp belongs to its first or last sample.
* **"The TTL arrived but the machine did not fire" becomes a measurement.** A command edge with
  no discharge edge after it is exactly that, stated outright, rather than judged by ear. The
  tool uses this to answer §9.2 — the visit's most important question — and counts dropped
  triggers over the whole run.
* The driver's own RTC is then compared against the discharge bit, and the **spread** is
  reported rather than a single offset: the constant part depends on the block-timestamp
  convention and can be settled later from the recording, while the spread cannot.

Firing for the timing run is either the `arduinoTTL` service over UDP (channel 2 only, so the
foot stimulator is never kicked) or by hand. There is no NVX trigger output wired to the
stimulator on this rig, so no software path through the amplifier exists.


<a id="history-12-verified-and-not"></a>

## 12. Verified, and not

**Verified, 2026-08-15 (Qt 5 tree).** Builds clean under MSVC v142 x64 as part of the whole tree.
The bridge compiles and links against the real vendor assemblies, so every managed type, member,
enum and delegate signature derived by reflection is checked. 38 logic tests, 65 bridge checks and 24
wire-level acceptance checks pass; a session recorded through the framework's own `Recorder`
reopens with 12 event records and 28 named status channels. Assembly resolution from the private
directory is confirmed — the `--hardware` path initialises the managed stack from `bin\neuroMS\`
with nothing flat in `bin\` — and correctly reports no stimulator found.

**Not verified: no magnetic stimulator has ever been attached to this machine.** Present on this
PC are a Neuron-Spectrum-65 (`PID_8277`) and a Neuro-MEP electrical stimulator (`PID_8300`) —
neither is a Neuro-MS. Everything past `NMS_Refresh()` returning zero is unexercised against
hardware: open, the trigger settings, the front panel, charging, firing, the pulse records, and
every inference in §11. Section 9 is the list of what to run when a machine is available.

`neuronSpectrum` was changed by this work as well (§3) and needs its own re-check on the NS-65:
it still builds and its assemblies moved to `bin\neuronSpectrum\`, but that path has not been
exercised against the amplifier.

**Verified, 2026-08-28 (Qt 6 tree).** Builds clean under **MSVC v143 14.44** against Qt 6.11.2.
The `/clr` bridge is the component most sensitive to a toolset change, because it links the vendor
managed assemblies — and it survived: the final package carries `neuroMS.exe`, `nmsbridge.dll` and
the NeuroSoft assemblies, and the mixed-mode bridge smoke test passes in 8.6 s. A deployed
`neuroMS.exe --emulation` was then driven through discovery, parameter writes, connect, ready,
charge, charged, discharge, disconnect and both streams: **20/20 checks**, including 55/40 %, a
12.5 ms interval, and paired mode surviving the post-connect handshake (§7.3). `NeuroMS.bat
--emulation` invoked from `C:\Windows\Temp` started exactly the deployed executable below
`R:\dist\bin`. Full record: `R:\src\docs\VALIDATION.md`, "2026-08-28 final recorder/NVX136/NeuroMS
validation".

**Still not verified under Qt 6, and unchanged from the Qt 5 position:** no physical pulse was
requested during the port, so the USB device, coil state and temperature, front-panel behaviour and
any real discharge all remain for the lab. §9 is still the list to run. Since 2026-09-02 it can be run from
`R:\dist` (§7.3) — with `R:\dist_Qt5\msvc64` alongside as the control, because no Qt 6 build has
yet driven this device.
