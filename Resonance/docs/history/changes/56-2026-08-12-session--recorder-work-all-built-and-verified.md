# 2026-08-12 session — recorder work, all built and verified

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-12-session--recorder-work-all-built-and-verified"></a>

### 2026-08-12 session — recorder work, all built and verified

Hardware **has** now been exercised: NVX-52 on this PC, plus `signalGenerator`, across every
change below. `R:\dist\msvc64` is the tree that was rebuilt and tested; `mingw32`/`mingw64` have
**not** been rebuilt since and are now behind.

**New module: [`recorderService`](../components/recorder.md)** — standalone HDF5 recorder, its own
process, with four faces (Configurator, own window, tray icon, always-on-top status strip) and
two published streams (`status`, `annotations`). Operator documentation:
[Resonance-Recorder-Guide.docx](../../operators/manuals/recorder.docx).

**Framework changes** (affect every service — read
[known-issues §12](../incidents/22-framework-defects-found-and-fixed-2026-08-12.md#history-12-framework-defects-found-and-fixed-2026-08-12)):

| Change | Why it matters elsewhere |
|---|---|
| `setValue()` now notifies | Any service that sets its own parameter values now re-broadcasts. `SPEED` is the one existing caller that does this at runtime. |
| New `Parameters::Action` type | A parameter rendered as a button. `Save`/`Load` cannot replay one. |
| `StreamInfo::isEmpty()` | **Use it instead of `isNull()`** when deciding whether to connect. |
| `persistentStreamRequest()` + `reconnect` default true | Connections now survive a producer restart *or reconfiguration*, by name. |
| `Recorder` extended | Per-stream rates and presence, reconnect policy, dataset re-binding, flush interval. |
| `Parameters::Stream::activeStream` is a property | A live view can read the resolved connection without going through serialised attributes. |

**Defects fixed:** NVX null-`runner` crash on applying a saved parameter set; `quickStimulus`
console window; numeric parameter fields eating keystrokes; the reconnection thread storm;
`applyParameters` infinite loop; `ThreadCapsule` object leak; 30 s TCP connect timeout. Full
list with causes in [known-issues §12](../incidents/22-framework-defects-found-and-fixed-2026-08-12.md#history-12-framework-defects-found-and-fixed-2026-08-12).

**Measured improvement:** stream reconnection after a producer restart went from 30–35 s (with a
15 s freeze) to ~1–2 s.

⚠ **`mingw32` and `mingw64` are stale.** Everything above was built and verified only under
`msvc64`. Rebuild the other two before treating them as current.

