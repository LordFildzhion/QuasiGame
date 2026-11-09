# 2026-08-16 — new module `feetStim`: the solenoid stimulator's UDP/BNC mode

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-16--new-module-feetstim-the-solenoid-stimulators-udpbnc-mode"></a>

### 2026-08-16 — new module `feetStim`: the solenoid stimulator's UDP/BNC mode

Full write-up: **[feetstim-service.md](../components/feetstim.md)**. The foot-sole stimulator — two feet
of 15 × 6 solenoids — is now a Resonance service. The standalone program is 9 730 lines across
three operating modes; **this is the UDP/BNC one**, which is its default and the one an experiment
uses. The gait animation, the latency bench and the plantograph tracing dialog are deliberately
out (decided with the operator, [§1](../components/feetstim.md)).

**Traced feet carry over.** The service reads the standalone program's own `feetStim.ini` — the
outlines in grid coordinates, the photos as PNG side files — and writes back the keys it does not
use untouched, so a rig that has already traced its feet keeps them and the two programs can share
the file.

**The send path is the part worth knowing.** Strength mode or `_S` override → geometry mask →
monitoring solenoids, in that order, and the order is not tidying: a sensor solenoid marked
outside the traced extent **must still fire**, or the accelerometer on it stops recording exactly
when the frame is trimmed. One invariant holds throughout — an Off point stays off under every
mode and every override.

| | |
|---|---|
| Parameters | **45** in five groups, every one with a tooltip |
| Streams out | `events` — **the 90 force bytes per foot exactly as sent**, per armed frame, plus device errors, TTL edges with the board's own µs stamp, and the TMS rules; `status` (Float64, 20 channels at 2 Hz) |
| Stream in | `command` — the rig's UDP grammar or JSON; replays its own records |
| Presets | nine slots, each **one line of the UDP grammar** (`7!`, `3!_Sis+10`, `7_Gp20@200`) |
| Device | COM 57600 with the `Ver?` handshake, or the emulator's named pipe |
| TTL board | opened **directly**, as the standalone does — not delegated to the `arduinoTTL` service |

**Verified:** 21/21 unit tests (the strength modes and overrides, the mask, the monitor-after-mask
ordering, the frame format at v105 and v102, the UDP grammar against every documented example);
and live **against the real `emulator.exe` over the named pipe** — 45 parameters, the pipe
handshake, and on a frame drawn at 50 / 100 / 70 % the wire bytes came out `230,230,230` at fixed
90 %, `128,255,179` individually and `153,255,204` shifted +10 with the clamp at the top. Streams
carry the full `L`/`R` arrays.

⚠ **No stimulator hardware and no TTL board** — the controller was the emulator throughout.
[§8](../components/feetstim.md) is the bring-up; §9 the traps, including that **port 5005 is shared with
`eStim`** (both originals default to it) and that in Mode 1 the solenoids hold the last frame
until a **zero frame** arrives — stopping the trigger does not release them.

