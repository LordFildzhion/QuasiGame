# 2026-09-08 — Configurator: old service packages refresh live; optional Delete termination

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-08--configurator-old-service-packages-refresh-live-optional-delete-termination"></a>

### 2026-09-08 — Configurator: old service packages refresh live; optional Delete termination

The operator confirmed the impedance-to-EEG filter fix. A remaining arrow case was reproduced
with `E:\ndi polaris diy\ndi-dev\Navigator.lnk`: its private, older `Resonance.dll` serves correct
input attributes on request but does not broadcast input loss. With Navigator selected, stopping
signalGenerator left the arrow green; a manual re-read made it grey. Updating Resonance's own
distribution could not update that independently packaged library.

`ParametersView.qml` now requests a description once per second for the displayed service when
it has stream inputs, including compatible derived parameters carrying `activeStream`. Immediate
service broadcasts remain in use. Polling stops when the panel/window is hidden, minimized or
detached; changing app focus does not stop it. Refreshes preserve queued edits and unchanged
values, and switching services cancels pending writes to the preceding service.

**Settings > Delete terminates selected service** is a persistent Configurator option, default
off. With it enabled, plain Delete sends the existing `!terminate` system transition only for a
selected service row while its table has active focus and the Configurator window is active.
Stream rows, empty selection, other panes/apps, modified Delete and key auto-repeat do nothing.

Only `bin\Resonance\Configurator.qml` and `bin\Resonance\ParametersView.qml` change in `R:\dist`.
This patch does not modify Navigator. Source/backups: `R:\src\_patches\configurator-live-status-20260908`.
Regression tests and live-test logs: `R:\src\docs\qa\configurator-live-status-20260908`.
All **36 enabled CTests passed**, and all three new cases passed against the deployed runtime.
Live verification with the same running Navigator instance confirmed automatic green/grey START/STOP
updates and Delete limited to Configurator's focused service table. Lab overwrite archive:
`R:\patches\configurator-live-status-delete-20260908.zip` (two QML files).

