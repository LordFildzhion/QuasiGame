# 2026-09-08 — Configurator: filtering recovers after impedance; connection arrows update live

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-08--configurator-filtering-recovers-after-impedance-connection-arrows-update-live"></a>

### 2026-09-08 — Configurator: filtering recovers after impedance; connection arrows update live

Both operator reports reproduced without hardware and are fixed in `R:\src` and `R:\dist`.
`ChannelModel` remembered channels by electrode name alone, carrying impedance's automatic
`filterBypass=true` and step rendering into EEG. The filter chain rebuilt correctly but ingest
bypassed it. Channel state is now remembered by name **and source kind**, so impedance and EEG
keep their own processing, rendering and scale settings; an operator's EEG bypass/range survives
a reconnect and a round trip through impedance. Saved channel state includes the source kind.

`Parameters::Stream` notified local views when a connection became ready or ended but did not
request a service-description broadcast. It also omitted an attributes notification on clearing
the source. Ready, lost, rerouted and cleared connections now notify both local views and remote
Configurators, through the existing 30 ms description coalescer. Retired inputs are detached from
the parameter so their delayed notifications cannot close a replacement connection. The connector's
URL helper also avoids the QML `String` type shadowing JavaScript's string conversion.

Release rebuild passed; **35/35 enabled CTests passed**, four physical/external tests disabled.
The new `test_ViewerReconnect` passed all **4 cases** against the packaged Qt runtime and deployed
DLLs/QML: repeated 1.25 Hz impedance -> 1 kHz EEG, measured DC rejection, retained EEG overrides,
and local/remote arrow colours under both once and keep/reconnect policies. Another **41 core
cases** passed (stream values, parameter application, stream identity). Configurator startup with
only the package and Windows on PATH passed. No physical amplifier was operated.

Only `bin\Resonance.dll`, `bin\Resonance\quickStimulusPlugin.dll` and the Stream connector QML
were replaced in the distribution; SHA-256 matches the build. Restart the Configurator and services
using the old core once to load the update. A cumulative three-file patch, original source and
distribution backups are in `R:\src\_patches\configurator-stream-recovery-20260908`; evidence is in
`R:\src\docs\qa\configurator-recovery-20260908`. The September 7 snapshot predates this fix.

