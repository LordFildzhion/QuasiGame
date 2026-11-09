# 2026-09-04 — `nvx136_2021` cumulative patch series for lab bisection

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-04--nvx136_2021-cumulative-patch-series-for-lab-bisection"></a>

### 2026-09-04 — `nvx136_2021` cumulative patch series for lab bisection

**`R:\patches
vx136_2021_20260904\`** — five drop-in builds of `nvx136_2021.exe` only, each
containing the previous. `R:\dist` is left at `p0`; `R:\src
vx136_2021` is left at `p4`.

| # | adds | cold-start risk |
|---|---|---|
| p0 | the build currently deployed — rollback target | — |
| p1 | **trigger channel published as `Trigger`**, + failure messages | none (no device call changes) |
| p2 | battery readout | none (polled after `NVXStart`) |
| p3 | `power_save`, `active_shield_gain`, `disable_unused_channels` | ⚠ **applied in the `NVXOpen`..`NVXStart` gap** |
| p4 | PLL defects fixed, SDK/firmware versions logged | low |

**The reported defect (p1):** the build published only `addCEDinfo(ced)`, whose properties are
indexed by CED row, while the stream carries EEG + AUX + trigger — so the trigger had **no `kind`**
and every consumer defaulted it to EEG. Verified fixed: 65 channels,
`{"EEG": 64, "Trigger": 1}`, last channel `name=Trigger kind=Trigger unit=bitfield`, identical to
the 2025 reference.

⚠ **Two real defects found in the 2021 PLL block (p4):** `case PLLExternal:` had **no `break`** and
fell through to `default:`, so "External PLL" silently did what "Internal PLL" does; and both
branches assigned `PllExternal` twice instead of `PllExternal` and `AdcExternal`. The Internal case
— the shipped default — came out correct by accident, which is why nothing noticed.

⚠ **`p1`–`p3` could not be started under emulation**: the 2021 vendor DLL refuses `NVXSetPll` with
`NVX_ERR_PARAM`, which p4 skips as the 2025 build does. Their `describeOutputs()` is byte-identical
to p4's, so the trigger fix is verified by construction. **No NVX-136 was available; cold start is
untested.** 28/28 CTests pass at p4.

---

