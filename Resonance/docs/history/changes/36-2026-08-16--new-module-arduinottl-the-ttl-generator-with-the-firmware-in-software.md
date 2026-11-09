# 2026-08-16 — new module `arduinoTTL`: the TTL generator, with the firmware in software

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-16--new-module-arduinottl-the-ttl-generator-with-the-firmware-in-software"></a>

### 2026-08-16 — new module `arduinoTTL`: the TTL generator, with the firmware in software

Full write-up: **[arduino-ttl-service.md](../components/arduino-ttl.md)**. The two-channel TTL pulse /
gate generator that drives the FeetStim rig — an ATmega328P with two BNCs — is now a Resonance
service. There was no PC-side program to port: the host side lived inside `feetStim` as one page,
so this takes its fields, its `TriggerLink`, and the PWM-profile one-liner, and adds the second
channel as first-class controls, a timing diagram, presets, and the streams.

**The only device module in the tree with no architecture gate.** No vendor DLL, no SDK — a
serial port. It builds for `mingw32`, `mingw64` and `msvc64` alike.

**The board's language is the API.** Commands are built from the parameters and read back into
them, and anything this service cannot model is passed through unchanged, so the firmware is never
reduced to the subset one window renders. A **preset is a script in that language**:

```
2=OUT,LOW ; V1 ; 2:P10@o1+30* ; T20,1000,50
```

and the *order* is the content: `@o1` waits for OUT1's **next** start, so channel 2 has to be
armed before channel 1 is commanded, and a profile uploaded before it is played. That lives in
one place now. The nine shipped defaults are the firmware's own bench test plan, in order.

| | |
|---|---|
| Parameters | **53** in five groups, every one with a tooltip |
| Streams out | `events` — **the board's own `micros()` stamp for every edge** next to the host RTC, plus every line both ways; `status` (Float64, 17 channels at 2 Hz) |
| Stream in | `command` — board commands or JSON; a digit 1-9 launches a preset; replays its own records |
| Emulation | a software model of the firmware — both channels, the triggers and standing rules, armed-vs-busy and its `DROP`, the roles, the profile, the counters, every reply spelling |

**Verified:** 25/25 unit tests (grammar, every reply spelling, every guard from the firmware's
TESTS.md §12, the profile, the preset script); and live against the emulator — 46 events in 26 s,
a train reporting `FIRE` 1…5 then `DONE n=5`, a **standing rule firing on all three separate
shots** at +21.1 / +20.0 / +20.1 ms with no re-arming, `WEND edges=300` for 500 Hz × 0.6 s, and
all three §12 guards answering exactly as the firmware spells them.

⚠ **No board was attached** — only a Bluetooth COM port exists on this machine, so everything is
the emulator, which models the protocol and **not** the physics (1 ms tick).
[arduino-ttl-service.md §9](../components/arduino-ttl.md) is the bring-up; §5 is the one thing to know
first: **the firmware never announces an input edge**, so an `@i2` run with a standing rule is the
only way to get a hardware-timestamped record of an external trigger.

**2026-08-17 — stop no longer sticks; presets save themselves; a run is one command.**

Four changes, from a session on the rig:

* **Stop left the service in `running` with the button stuck.** The service was waiting for the
  board to confirm — and the board never does. `S` stops channel 2 silently, and channel 1's
  `STOP` is gated on `V1`. `stopAll()` now clears its own channel model. Separately, the state
  machine's `connectionChanged` was emitted *before* the machine moved, so readouts lagged one
  transition behind; every state now reports its own arrival.
* **No more Save preset.** An edit writes the slot immediately, and 300 ms later the ini and the
  board. Shift-click still copies the panels into another slot.
* **Setup and fire are separate.** `setupCommands()` (role, verbosity, armed channel 2, profile
  upload, passthrough) is pushed on identification and after an edit; `fireCommand()` is the one
  line that starts channel 1. Firing the same stimulus twice sends `P8000` and nothing else.
* **Send setup** — a button, an action, a `sendSetup` transition from `ready`, and a `setup` verb
  — pushes unconditionally, for a board that was edited while unplugged or power-cycled since.

Verified against the emulator: setup out on connect with no fire line; `→ P8000` alone on Fire;
`→ S` mid-run answered `← STOP` with the state back to `ready`; and the same with a channel-2
standing rule armed, which is the case the firmware reports nothing at all for. 29/29 unit tests,
four of them new and about the split.

**2026-08-17 — the window went 942 → 552 px.** The board's identification banner was setting the
window's width, and the panels were built to absorb whatever width they were given. The status
label now elides on its own row under Port; the `Run:` / `Role:` combos no longer carry a stretch
factor; each channel's `standing` checkbox moved off the onset row, which alone was 142 px of it;
combos and numeric fields share caps. At 552 the **presets row is what sets the width** — nine
buttons and `Save preset` — and the banner arriving no longer moves it. The port list is also
enumerated at start-up now, where before it stayed empty until Rescan was pressed. The rule this
came from is [architecture.md §11a](../migrations/framework-evolution.md).

