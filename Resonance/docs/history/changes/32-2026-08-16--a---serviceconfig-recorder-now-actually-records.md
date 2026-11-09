# 2026-08-16 — a `--serviceConfig` recorder now actually records

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-16--a---serviceconfig-recorder-now-actually-records"></a>

### 2026-08-16 — a `--serviceConfig` recorder now actually records

Full write-up: **[known-issues.md §17b](../incidents/32-framework-findings-from-building-estim-2026-08-16.md#history-17b-recorderservice---serviceconfig-records-nothing-from-a-configured-stream---fixed-2026-08-16)**.
Two defects, both in `Core/Resonance`, so both are framework-wide rather than recorder-specific.

**`StreamInfo::fromJson()` did not read the stream name out of a `discover://` URL**, while
`StreamInfo(const QUrl&)` always has. One connector filled two ways therefore produced two
different objects — a slot filled by dragging is named, the identical slot written into a config
file was not — and the nameless one reached HDF5, which refuses an empty dataset name. Three
layers then turned that hard failure into silence: the exception was caught, logged below the
default level, and `addStream()` returned `void`, so the service reported a healthy recording
into a file that did not contain the stream. Fixed at the root, and the silence fixed with it:
failures are `qWarning`, `HDFRecorder::addStream()` returns `bool`, and a stream the file refused
reads **`not recorded`** with a red tray icon instead of green.

**`autoStart` in a config file never fired.** `RecorderService`'s constructor read the value and
armed its timer before `ResonanceApp` applied `--serviceConfig` — the config is applied from
`afterExec()`, on the first turn of the event loop, i.e. after every service constructor. The
value is now read when the timer *fires*. The general rule, worth carrying to every service:
**nothing read in a constructor can be configured by `--serviceConfig`.**

One knock-on, fixed in the same pass: `applyParameters()` re-checked each parameter by comparing
its read-back against the caller's text, so a parameter that normalises what it is given was
reported *"Rejected — value does not fit"* after applying cleanly. It now compares against what
the parameter settled at.

**Verified** against `signalGenerator`: the nameless config that produced an empty file now gives
105 blocks / 2100 samples at 250 Hz with 0 NaN, and an `autoStart: true` config with **no `start`
sent by anyone** gives 59 blocks / 1180 samples. 235 unit tests pass, including three new
`StreamInfo` cases covering the derivation and the clear-this-connector round trip.

The reported second symptom — "the dataset is created and stays empty" — **was not a bug.** An
idle `eStim` publishes nothing on `events`, and a `MessageReceiver` subscribed to the same stream
over the same window received nothing either. A dataset at `shape == (1,)` with `created == 0`
holds **zero** records, not one; that is [§14k](../incidents/24-defects-found-and-fixed-2026-08-15.md#history-14k-every-hdf5-dataset-ends-in-one-all-zero-row--open)
showing through. Check the producer before the recorder when a stream comes out empty.

⚠ `params\ns65-recorder.json` needed both fixes and had never worked. It needs no edit now, but
it has still never been run against an NS-65.

