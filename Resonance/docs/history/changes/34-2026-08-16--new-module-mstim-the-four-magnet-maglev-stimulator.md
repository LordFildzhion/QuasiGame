# 2026-08-16 — new module `mStim`: the four-magnet maglev stimulator

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-16--new-module-mstim-the-four-magnet-maglev-stimulator"></a>

### 2026-08-16 — new module `mStim`: the four-magnet maglev stimulator

Full write-up: **[mstim-service.md](../components/mstim.md)**. An Arduino Nano and two L298N bridges
driving four magnets over one COM port, ported from
`N:\Projects_MSU\2026 - Passive movements\exe\MagStim\mStim`. The fourth stimulator service in
this family, and the one where the preset design finally costs nothing at all.

**The firmware keeps no stimulus library and no EEPROM, and opening the port resets the board.**
Everything follows from that: the command line *is* the stimulus, so a preset is a firmware
definition line stored verbatim; `Program all` is mandatory after every connect rather than a
convenience; and the state machine distinguishes **`ready`** from **`programmed`**, because
"connected" and "ready to fire" are genuinely different here.

```
=1M1U50M2D100T150K1        one 150 ms pulse, M1 up 50 %, M2 down 100 %, TTL kind 1
=7M1U100M2OT50I150R4K0     a packet of four 50 ms pulses, 150 ms apart
=9Wd,d_T500:100,0_H200K0   a sweep; `d` is resolved by the DEVICE at run time
```

| | |
|---|---|
| Parameters | **57** in five groups, every one with a tooltip |
| Streams out | `events` — every line both ways with its source, plus typed `launch` / `program` / `params` records carrying the exact text sent; `status` (Float64, 22 channels at 2 Hz) |
| Stream in | `command` — raw firmware lines or JSON; a bare number fires that stimulus, as the firmware means it |
| Presets | fifteen slots, matching the device's own RAM capacity, each a definition line |

**Verified:** 21/21 unit tests (composition of every pulse shape, the unlisted-magnet rule, the
always-written `K` token, reserved IDs refused, the 220-character cap, and a parse round trip for
all four shapes including sweeps); and live over the EventBus with a port open — 57 parameters,
`stimulus.line` equalling `preset1` exactly, all fifteen slots well-formed with unique non-reserved
IDs, and **`program` publishing the ordered burst line by line**: the parameter line, `=d`, then
all fifteen definitions including a list, a packet and a sweep. `connect` → `ready`, `program` →
`programmed`, `disconnect` → `init`.

⚠ **No maglev hardware.** The live run used a Bluetooth serial port with nothing on it, which
exercises the whole host side and none of the device. [§6](../components/mstim.md) is the bring-up, and
its **step 2 comes before everything else**: `M<n>_orient` is a convention, not a measurement —
verify each coil's direction at low power before building a library, or every direction in every
stimulus is inverted for that magnet.

