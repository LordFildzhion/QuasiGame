# 2026-08-16 — new module `eStim`: the electrostimulator, with its GUI, as a service

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-16--new-module-estim-the-electrostimulator-with-its-gui-as-a-service"></a>

### 2026-08-16 — new module `eStim`: the electrostimulator, with its GUI, as a service

Full write-up: **[estim-service.md](../components/estim.md)**. The standalone `eStim` program that has
been driving the Neurosoft stimulator at the rig is now `R:\src\eStim` — an x64 Resonance service
that keeps the window, the command language and the vendor-DLL wrapper, and moves the state out
of the widgets into parameters. The second actuator in the tree after `neuroMS`.

**The design decision everything follows from:** four ways in — the window, serial, UDP, and a
Resonance `command` stream — and all of them write a `Parameters::*` object, which is the only
thing that talks to the hardware. The standalone kept its state in the widgets, which was already
one feature from breaking: the coupled limits were enforced in the spin boxes alone, so the
serial path could set combinations the UI refused.

**Presets are one line of the command language**, held in nine fixed `String` parameters:

```
preset1 = F110 D200 A3 N5 PB f10 d200 a3 n5 pb TB
```

which is what makes a saved configuration reloadable — a `presetCount` → `preset1…N` shape would
have walked straight into
[§16b](../incidents/33-framework-traps-found-building-playbackservice-2026-08-15.md#history-16b-applyparameters-screens-names-before-it-applies-anything--fixed-2026-08-22). The
translation runs both ways: the window's Line box rewrites itself as the panels move, typing a
line into it sets the panels, editing `presetN` in the Configurator loads it, and every
`parameters` record on the events stream carries the line as well as the fields.

| | |
|---|---|
| Parameters | **54** in six index-banded groups, every one with a tooltip |
| Streams out | `events` (Message/JSON — every command with its source, every train with its timing, every clamp, every refusal) and `status` (Float64, **31 named channels** at 2 Hz) |
| Stream in | `command` — the same text grammar as the serial line, or JSON; it also accepts this service's own `command` records, so a recorded session **replays** through `playbackService` |
| Safety | frequency ≤ 40 kHz, duration ≤ period, interphase ≤ duration − 50 µs, pre-pulse ≤ ISI, amplitude capped at 7 mA until unlocked (99 mA ceiling). Every clamp published. An over-cap amplitude is **refused**, not silently reduced |
| ini | `eStim.ini` still exists for what the network cannot do; a file written by the standalone is **read and converted** in place |

**Verified:** 23/23 unit tests (scanner, one-liner round trip, timing, clamps — all hardware-free);
39 live checks over the EventBus and UDP against the running service, including the rig's real
`eStim.ini` migrating all nine presets and `freqMax=100000` capping to 40000; and both streams
through the real QML plugin — 33 `events` records and `status` at 31 channels, 1.91 Hz measured
against 2 Hz declared. `!terminate` exits cleanly and rewrites the ini.

⚠ **No stimulator was attached** — the operator's own standalone `eStim` held the device for the
whole session and was deliberately left running. Nothing past enumeration is exercised: no device
opened, no current delivered, no train timed against a scope.
**[estim-service.md §13](../components/estim.md)** is a step-by-step bring-up; the one number no test
could check is whether the computed train length matches what the device actually does, since the
vendor DLL gives no completion callback and the service returns to `ready` on a timer.

⚠ **`recorderService --serviceConfig` did not record a configured stream** in this session — for
`eStim` and for a `signalGenerator` control alike. Configure a recorder from the Configurator
until it is chased down; [known-issues §17b](../incidents/README.md).

