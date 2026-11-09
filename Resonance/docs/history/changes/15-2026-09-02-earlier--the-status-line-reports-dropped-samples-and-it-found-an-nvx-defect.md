# 2026-09-02 (earlier) — the status line reports dropped samples, and it found an NVX defect

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx52.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-02-earlier--the-status-line-reports-dropped-samples-and-it-found-an-nvx-defect"></a>

### 2026-09-02 (earlier) — the status line reports dropped samples, and it found an NVX defect

**27/27 enabled CTests pass** out of 31 registered (`docs\qa\ctest-qt6-20260902.log`).
`validate-dist-qt6.ps1` PASS.

**The Configurator now says `running, 11231 samples dropped` beside the state**, and nothing at all
when the count is absent or under 100. A service reports its running loss total through
`CommunicationLayer::reportDroppedSamples(quint64)`, which lands in the `droppedSamples` key of the
long-existing but never-filled `stateInfo`. Wired in `nvx`, `nvx136`, `actiChamp` and `KARDi2` —
every driver with a hardware sample counter. Cleared on every state entry, so a stopped run's
losses never linger on screen. `test_StatusLineQml` covers the 100 floor, the lifecycle and the
absent-is-not-zero rule.

⚠⚠ **Building it exposed a serious NVX-52 defect, and corrected an earlier understatement in these
notes.** The first write-up said the counter warnings were log spam and the data was fine. Measured:

| run | warnings | samples delivered | expected |
|---|---|---|---|
| A | 0 | 4 959 | ~5 000 ✅ |
| B | 3 017 | **415 692** | ~5 000 ❌ **84×** |
| C | 3 236 | **400 382** | ~5 000 ❌ **81×** |

Same binary, same device, same settings, minutes apart — **intermittent**. The driver pads the
stream with NaN rows for every counter gap up to 20 000, and ⚠ **the warning and the damage are on
opposite branches**: gaps *above* 20 000 are warned about and not padded; gaps of 1..20 000 are
padded and never logged. A raw-frame dump ruled out the frame layout — `frameWords=54,
statusWord=52, counterWord=53` matches the SDK exactly and the counter reads `0,1,2,3…` cleanly for
the first two reads before the device starts returning duplicated, out-of-order frames.
`nvxdatathread.cpp` is byte-identical to Qt 5's, so it ships in both generations.
**An NVX-52 recording's length is not currently trustworthy** —
[`arch_qt6-work-list.md` §3b](../migrations/qt6-work-list.md).

⚠ **The NVX-52 needs a USB replug.** It enumerates `OK` and nothing holds it, but `NVXStart`
returns `NVX_ERR_FAIL (-2)` after repeated start/stop cycles during this investigation. It
recovered once on its own after ~10 s and then wedged again. This is the firmware-level state the
standing "stop before terminating" rule exists to avoid; the cure is a power cycle, which is an
operator action.

---

