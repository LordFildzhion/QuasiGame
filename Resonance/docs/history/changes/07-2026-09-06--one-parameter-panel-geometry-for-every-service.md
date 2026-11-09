# 2026-09-06 — one parameter-panel geometry for every service

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-06--one-parameter-panel-geometry-for-every-service"></a>

### 2026-09-06 — one parameter-panel geometry for every service

⭐ **The label column is pinned at 130 px in every tab of every service.** It used to be a *cap*,
so each tab sized its own column from its own labels: `SPEED`, whose labels are "Engine" and
"Code", got a narrow column and unusually wide editors, `neuronSpectrum` got the full 130 and
narrow ones. Clicking between services made the controls jump. Now they do not.

⚠ The cost was known and rejected once before — a tab of short labels now carries column it does
not need. Accepted deliberately this time: consistency across services is worth more.
`arch_known-issues.md` §14l is marked superseded rather than rewritten.

**Thirteen labels shortened** so fewer rows wrap — nine in `neuroMS`, two in `nvx`, one each in
`nvx136` and `latencyProbe`. Where a label carried its only explanation, that sentence moved into
the description instead of being dropped. Wrapping went from 24 rows to 11.

⚠ **The remaining 11 are all in services under label parity** (`neuronSpectrum`, `tepSoundService`,
`fieldtrip`). `scripts\test-neuron-mstim-estim-parity.py` and friends compare **labels** between
the Qt 5 and Qt 6 builds, and the Qt 5 tree is frozen — rewording only the Qt 6 side fails the gate.
They wrap by necessity.

Rule written down in
[qt5-to-qt6-transition.md §6a](../migrations/qt5-to-qt6-transition.md#history-6a--the-parameter-column-is-300-px-this-is-a-contract),
with the per-service label census; the authoring rule ("about 22 characters") is in
[architecture.md](../migrations/framework-evolution.md).

Build clean, ctest 33/33, `validate-dist-qt6.ps1` PASS, captures in `src\docs\qa\param-column\`
(`pinned-*`, `uniform-*`) showing `SPEED`, `neuronSpectrum`, `neuroMS` and `nvx` with identical
control geometry.

