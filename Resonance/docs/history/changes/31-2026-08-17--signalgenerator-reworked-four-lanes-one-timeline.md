# 2026-08-17 — `signalGenerator` reworked: four lanes, one timeline

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-17--signalgenerator-reworked-four-lanes-one-timeline"></a>

### 2026-08-17 — `signalGenerator` reworked: four lanes, one timeline

Full write-up: **[signal-generator.md](../components/signal-generator.md)**.

The module the rest of the tree is tested against was ~200 lines emitting one sine on every
channel of one stream. It now publishes **five streams from one process** — a `continuous` channel
table, an `eeg` simulation, an `epochs` stream, a `stimuli` message stream and `status` — **all
driven off one event schedule**, so a marker, a trigger bit-flip and an evoked response are the
same event on the same sample. Two generator processes cannot do that, and it is what makes an
epoching pipeline testable with no amplifier, no stimulator and no subject.

| | |
|---|---|
| Parameters | **101** in exactly **four** index-banded tabs (`continuous`, `eeg`, `epoched`, `messages`), each leading with its enable flag and stream name; 91 typed, 89 with tooltips |
| Waveforms | 27 — the standard function-generator set plus `noisepink`, `noisebrown`, `prbs`, `cardiac`, `chirp`, `arbitrary` and `bits` |
| Channel table | a scrollable window, one row per channel, 20 columns, with bulk edits; stored as **one `MultiLine` parameter** so a saved configuration can actually be loaded back |
| EEG model | Cholesky-mixed 1/f over the **montage's own electrode distances**, posterior alpha, frontal blinks, drift, mains, EMG/AUX/trigger channels |
| Faults | NaN/inf runs, flat, clip, whole-block drops — `dperiod=20 dlen=3` reproduces the NVX 5 kHz fault exactly |
| Pacing | off `QTimer` and onto the `playbackService` high-resolution pacer; blocks stamped with the instant they were **scheduled** for |
| Lifecycle | a state machine at last: `init → armed → running`. `autoStart` defaults true, so a bare launch behaves as before |

**Verified: 68/68 unit tests and 56/56 live checks** against a 20 s recording of all five streams
made through `recorderService` from the deployed tree, read back with h5py. Every assertion is
arithmetic on the samples — a 10 Hz sine at exactly 1e-4, a square at a measured 25.25 % duty,
noise at σ 5.007e-4 against 5e-4 asked, **15.00 % NaN with every one at `index % 20 < 3`**, 41
trigger pulses each exactly 20 ms wide, an inter-block interval of **100.000000 ms with 0.000000 ms
max deviation**, and epochs peaking exactly on the event sample. Pacer lateness **0.377 ms mean,
0.853 ms worst**. A `--serviceConfig` with a three-line channel plan loads in full.

⚠ **Three defects in the old generator, all long-standing.** `dirtySine` was *bit-identical* to
`fixedSine` (`case fixedSine: case dirtySine:` fell through); `fixedNaNMeander` emitted **+∞, not
NaN**; and **every channel carried identical samples**, so no consumer that transposed, swapped or
dropped a channel could ever have been caught by it. All three fixed, with the original behaviour
still exactly reproducible (`shiftStep` and `signatureStep` default to 0).

⚠ **`RESONANCE_RECORD_PATH` is not set by the shipped `.bat` launchers on this machine.** They all
write `call env`, and with `NoDefaultCurrentDirectoryInExePath` set the call does not resolve, so
recordings land in `bin\` instead of `data\`. This is not new and not specific to this module —
`call .\env` is the fix, in every launcher.

⚠ **Only `msvc64` builds this**; no run above 1 kHz; the table window was driven from a config
rather than clicked through; and no consumer beyond `recorderService` was pointed at the streams.

