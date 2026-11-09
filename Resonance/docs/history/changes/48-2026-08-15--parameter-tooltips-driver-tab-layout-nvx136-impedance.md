# 2026-08-15 — parameter tooltips, driver tab layout, NVX136 impedance

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-15--parameter-tooltips-driver-tab-layout-nvx136-impedance"></a>

### 2026-08-15 — parameter tooltips, driver tab layout, NVX136 impedance

**Parameters can now carry a tooltip.** `Parameters::Parameter` gained a `description` property;
it travels in the service description (`communicationlayer.cpp`) and the Configurator renders it
on both the label and the editor via `HoverHandler` — chosen over a `MouseArea` because it
reports hover without taking a click or a wheel event away from the control underneath. The
service supplies the text, because the service is the only thing that knows its own hardware.

**Configurator tab order now follows the service, not the alphabet.** `ParametersView` orders
group tabs by the lowest parameter index in each group — the same numbering that already orders
rows inside a tab — and selects the first tab when a service is opened (only when the tabs were
just built, so a description re-broadcast cannot yank an operator out of the tab they are
using). Previously titles were sorted alphabetically, which is why NVX136 opened on `adc`.

**Driver parameter layout**, for both amplifiers:

| | |
|---|---|
| `nvx` | one tab, renamed `default` → **`main`**. 8 of 10 parameters carry tooltips. |
| `nvx136` | **`main`, `hardware`, `trigger`** — `adc` folded into `hardware`, `sync` into `trigger`. Indices renumbered into bands (main 10-99, hardware 110-199, trigger 210-299) so the order is explicit. 16 of 20 parameters carry tooltips. |

Verified against the live service with a QML harness driving the real `ParametersView`
(`quickStimulus.exe -l params_harness.qml`): `tabTitles=["main","hardware","trigger"]`,
`currentIndex=0 currentTitle=main`, `delegates=20 withTooltip=16`, no QML errors.

**NVX136 impedance mode now works** — it never had, on hardware. Two vendor-SDK traps, both
written up in [known-issues §15](../incidents/README.md): the DLL rejects the buffer size its own
header documents, and querying the device after `NVXStart` silently aborts the impedance sweep.
Verified end to end: the sweep fills 16 → 102 → **129 of 129** electrodes over ~8 s and settles
at 999900 Ohm on open inputs; recorded as 129 channels at 1.25 Hz, unit `Ohm`, named
`Ch 1…Ch 128` + `GND`. Normal mode re-verified in the same run: 4,495 rows × 33 channels at
250 Hz, 0 NaN.

⚠ **Harness config files belong in `R:\config`, not in a distribution.** Several
`*_config.json` written by test scripts had accumulated in `R:\dist\msvc64` and
`R:\dist\msvc64-nvx2025`; they have been moved. A distribution root holds launchers, `bin\`,
`qt\` and `data\` — nothing else.

