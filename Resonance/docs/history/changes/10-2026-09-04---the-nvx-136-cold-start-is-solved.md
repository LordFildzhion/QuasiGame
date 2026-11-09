# 2026-09-04 — ✅ the NVX-136 cold start is solved

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-04---the-nvx-136-cold-start-is-solved"></a>

### 2026-09-04 — ✅ the NVX-136 cold start is solved

**One discarded read after `NVXOpen` — `NVXGetVoltages` — and the 2025 build starts a cold
amplifier on the first attempt.** Measured on hardware, confirmed twice:

```
without it   NVXStart -3 (NVX_ERR_FAIL) after 3954 ms, twice, recovery cycle no help
with it      NVXStart  0 (NVX_ERR_OK)   after 1210 ms, first attempt
```

⚠ **It was in the 2021 driver all along and looks like dead code** — `NVXGetVoltages(handle,
&voltages)` into a variable nothing reads, dropped from the 2025 rewrite as obviously pointless.
That is the whole difference.

Eliminated first, each at the cost of a session: the vendor DLL, `NVXGetVersion` (which the source
called "the prime suspect"), the length of the `NVXOpen`..`NVXStart` gap, `NVXSetPowerSave` in the
probe, and `NVXStop` on a probe teardown.

**`q4-minimal-cure` = q3 minus q2, confirmed on hardware**: 1188 ms, first attempt, with q2
dropped — so q2 contributed nothing. `R:\dist` now carries it, deployed through
`deploy-qt6.ps1` and `validate-dist-qt6.ps1` PASS. **29/29 ctest.**

⭐ **The cure is now guarded by a test**, because a discarded read is exactly what a future reader
deletes. `Nvx136ColdStart.TheDiscardedVoltageReadHappensBeforeAnyConfiguration` asserts on ORDER,
not on a count — the driver reads voltages again later, so a count would pass with the cure gone.
⚠ Verified by deleting the call and watching the test go red first.

⚠ **`test_ChannelsListInTabsQml` was flaky (~1 run in 4) and is fixed.** It was mine, added during
the SPACE investigation, and every wait in it was a fixed `pump()` — including the wait for OS
window activation, which takes as long as it takes. Replaced with predicate waits on a deadline.
Six consecutive clean runs since.

⚠ **A trap worth remembering:** `nvx136_cold_start_recovery_test` links the driver sources, so a
targeted `--target nvx136` build leaves the TEST binary stale and ctest reports the *previous*
revision's behaviour. It produced a confident, wrong bisection. Full-build before believing ctest
about a driver change.

---

