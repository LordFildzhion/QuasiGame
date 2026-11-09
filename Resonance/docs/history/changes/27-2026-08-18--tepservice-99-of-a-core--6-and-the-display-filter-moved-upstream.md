# 2026-08-18 — tepService: 99% of a core → 6%, and the display filter moved upstream

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-18--tepservice-99-of-a-core--6-and-the-display-filter-moved-upstream"></a>

### 2026-08-18 — tepService: 99% of a core → 6%, and the display filter moved upstream

Four changes, from a session driving playback → TEP → Configurator on the 3.8 GB TMS file.
The operator's report was that the TEP window dragged in steps and parameter edits landed late.

| stage | CPU |
|---|---|
| as found | **~99 % of one core**, all of it on the GUI thread |
| pipeline moved to a worker thread | 72 % |
| views repaint only when something changed | 17 % |
| processed epochs cached and accumulated | **6 %** |

**The pipeline runs on a worker thread** (`tepService/signalworker.{hpp,cpp}`). The service had no
threading at all — no `QThread`, no `QtConcurrent`, nothing — so filtering 73 channels at 25 kHz
ran in the event loop that renders the console. The epoch processor, the store, the parameters and
the views deliberately stay on the GUI thread; only the continuous stage moved.

⚠ **But threading was the smaller half, and the first diagnosis was wrong.** With the input paused
the service still held 63 % of a core, and 0 % with the console closed: `refreshViews()` fired
unconditionally at 10 Hz, redrawing a 73-channel butterfly, a scalp grid, a strip and the epoch
table whether or not an epoch had arrived. It now repaints on a dirty flag, with a forced refresh
every 2 s as a safety net. The same argument already governed `publishAverage()`; it had never
been applied to the views.

**The average no longer re-derives the session on every epoch.** `EpochStore::reduceOver()` re-ran
the *whole* per-epoch stage — baseline, CAR, lowpass, MEP — over every stored epoch each time one
arrived, and the console pulls the average during the repaint. Processed epochs are now cached
beside the raw ones and a running total is extended by each arrival.

⚠ **The running total only ever adds, and that is a correctness decision, not an oversight.**
Subtracting an epoch back out — on eviction, rejection or deletion — drifts from a fresh sum by
~1e-15 relative. Physically nothing, but it makes a displayed *and saved* average depend on the
order of the operator's actions, so those paths rebuild from the cache instead. Measured, then
fixed: the first implementation subtracted and three of seven new tests caught it.
**`test_TepPipeline` is now 40/40**, including seven asserting the fast path is bit-identical to a
full reduction through arrival, NaN runs, eviction, reject/un-reject, removal and reprocessing.
With `epochBuffer` larger than the session nothing is ever evicted and the fast path holds
throughout.

**The display lowpass moved to the continuous stage** — see
[tep-service.md §2.1](../components/tep.md). It was the one filter still applied to an already-cut
epoch, which contradicts this module's own rule. ⚠ It changes the numbers, so the SciPy reference
comparison needs regenerating; and the display cutoff now applies from the next epoch rather than
retroactively. Baseline, CAR and re-reference are unchanged and still retroactive.

⚠ **Memory is the price.** Caching the processed form roughly doubles per-epoch cost — ~1.6 MB
against ~0.6 MB — so at the rig's `epochBuffer` 500 and 73 channels TEP settles near 1 GB. Lower
`epochBuffer` if that matters more than the averaging speed.

Also in this session: the signal viewer's toolbar no longer draws over the neighbouring viewer
(`clip`), Setup and Channels are mutually exclusive and both close when the stream drops (the
settings panel is a Controls 2 `Popup` and lives in the window overlay, so hiding the viewer left
it stranded), and a bare `playbackSource` launch refuses before `ResonanceApp` announces it —
previously it advertised a service, failed `--file is required` and exited inside a second, which
is long enough to be discovered and too short to ever form a connection whose loss would report
the death.

