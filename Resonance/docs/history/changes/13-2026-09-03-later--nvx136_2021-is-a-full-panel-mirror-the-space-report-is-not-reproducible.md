# 2026-09-03 (later) — `nvx136_2021` is a full panel mirror; the Space report is not reproducible

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-03-later--nvx136_2021-is-a-full-panel-mirror-the-space-report-is-not-reproducible"></a>

### 2026-09-03 (later) — `nvx136_2021` is a full panel mirror; the Space report is not reproducible

**28/28 enabled CTests pass.** `validate-dist-qt6.ps1` PASS. Deployed.

**`nvx136_2021` now presents the same panel as the mainline** — 21 parameters against 13, same
three groups, same indices, labels, descriptions and option strings. Verified over the bus by
`scripts\nvx136-parity-check.qml`: **21/21 matched, nothing only in one side.**

⚠ Option strings mattered more than they look: `Parameters::Select` serialises the option **label**,
so `"1000 Hz (all channels)"` vs `"1 kHz (all channels)"` meant a saved parameter file could not
load into both builds. Four option lists plus the generated `device` labels were aligned.

Six rows are published **disabled**, each saying why in its tooltip: three because the 2021 SDK
lacks the call, three because applying them would add a device transaction between `NVXOpen` and
`NVXStart` — and a short sequence there is the entire reason this build exists. `battery` is the
one that is neither: `NVXGetVoltages` is in both SDKs, and it is unwired only because no NVX-136
was available to test the extra call. Details in
[`build_qt5-to-qt6-transition.md` §4a-bis](../migrations/qt5-to-qt6-transition.md).

⚠ **The known-good pre-change sources are preserved** at
`R:\src\_patches\nvx136_2021-working-20260903\` with a restore command. The parity change touches
no start/stop logic; rebuilding the preserved sources gave identical state-machine behaviour, so
the first-try launch property should be intact — but it is untested on an NVX-136.

<a id="history--space-does-not-toggle-channels-in-nvx136--could-not-be-reproduced"></a>

### ⚠ "Space does not toggle channels in nvx136" — could not be reproduced

Reported as working in `nvx` and `KARDi2` and failing in both `nvx136` builds. Everything checked
here passes, on the current build:

* the editor in isolation — `test_ChannelsListQml`, passes;
* **the editor inside a real `ParametersView` with three groups and 137 channels** — new
  `test_ChannelsListInTabsQml`, passes. This was the leading hypothesis (only the nvx136 builds
  publish multiple group tabs) and it is **refuted**;
* the wire representation of the two channel parameters — identical field for field, same type,
  same flags;
* the service accepting a change — `scripts\channels-apply-probe.qml`, 65/137 → 64/137, no refusals;
* description churn that would rebuild the panel under the operator — 0 updates in 20 s for both;
* **the real Configurator driven with real mouse and real keyboard** —
  `scripts\space-toggle-hardware-probe.ps1`, and Space toggled the channel.

⚠ Two harness traps found on the way, both worth knowing: a synthesised Windows `WM_KEYDOWN` does
**not** reach Qt's focus item, so the first probe "failed" for `nvx` too and proved nothing; and a
`ParametersView` with no controller binds `tabs.enabled: false`, so every row is disabled and
nothing can take focus — which made the first version of the new test fail identically for one
group and for three.

The one difference not reproducible here is **real NVX-136 hardware**; the tests above used
`--emulation`. Next step is on the rig: does the tick move when the channel *name* is clicked and
Space pressed, versus clicking the tick box directly?

**A refactor came out of it:** `ParametersView`'s description handler is now
`applyDescription(parameters, state, info, transitions)`, with `Connections.onDescriptionChanged`
delegating to it. That is what let a test drive the panel with a service-shaped description instead
of reimplementing the panel's own structure rules.

---

