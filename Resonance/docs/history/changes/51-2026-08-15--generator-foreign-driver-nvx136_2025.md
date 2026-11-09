# 2026-08-15 — generator, foreign driver, NVX136_2025

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-15--generator-foreign-driver-nvx136_2025"></a>

### 2026-08-15 — generator, foreign driver, NVX136_2025

Three unrelated defects, full write-ups in [known-issues §14](../incidents/README.md) and
[§12g](../incidents/35-resonanceforeigndriverreleasestring-corrupts-the-heap---fixed-2026-08-15.md#history-12g-resonanceforeigndriverreleasestring-corrupts-the-heap---fixed-2026-08-15).

| | Status |
|---|---|
| **`signalGenerator` went silent at midnight** — `QTime` wraps at 24 h, so the next single-shot tick was scheduled ~24 hours out. Now `QElapsedTimer`. | ✅ fixed, rebuilt, verified (252.6 Hz) |
| **`--streamName` added to `SignalGenerator`**; `signalGenerator.bat` now passes `--serviceName` and `--streamName` explicitly, so a second generator is a copied launcher rather than an ambiguous duplicate. | ✅ verified — two generators side by side, both streaming, distinct addresses |
| **`ResonanceForeignDriver::releaseString()`** freed `QByteArray::data()` instead of the array — heap corruption on the first call from any FFI client. Python wrapper's missing `bytes` encodings fixed with it. | ✅ fixed, 200 round trips clean |
| **NVX136_2025 could never start**: `NVXSetMirrorTriggers` answers `NVX_ERR_SUPPORT` (-5) on this converter and was treated as fatal even with mirroring off. | ✅ fixed, **verified on hardware** — 6 clean start/stop cycles, 407 blocks in 30 s |
| **NVX136_2025 never re-announced on publisher-ready** (the NVX2025 §3.5 race, never applied here). | ✅ fixed |
| **NVX136_2025 named every EEG channel `?? N`** — `addCEDinfo()` called with no CED file, the same defect as [§12h](../incidents/36-parseced-on-an-empty-file-relabels-every-channel--n---fixed-in-nvx-2026-08-14.md#history-12h-parseced-on-an-empty-file-relabels-every-channel--n---fixed-in-nvx-2026-08-14). | ✅ fixed, confirmed in a recording |
| `--emulation` on `nvx136_2025` checked `value()` instead of `isSet()`, so the flag did nothing. | ✅ fixed (`nvx136` still has it) |

**NVX136_2025 acceptance, on the physical media converter (2026-08-15):**

| Check | Result |
|---|---|
| Discovery | `Media converter #0`, 137 channels offered (128 EEG + 8 AUX + Trigger) |
| Start | reaches `running` ~4.5 s after the transition — the 2–5 s lag is `NVXOpenEx` + configure + `NVXStart` |
| Lifecycle | 3 clean start/stop cycles, each returning to `init`; no hard reset |
| Stream | `eeg`, **33 channels** (32 EEG + Trigger) at 250 Hz, publisher listening |
| Recording | 4,921 rows, **0 NaN**, 253 blocks / 4,920 samples reconciled |
| Metadata | `Ch 1…Ch 32` + `Trigger`; kinds EEG/Trigger, units V/bitfield |

Evidence HDFs: `R:\dist\_build\nvx136-verify\`.

⚠ **A crashed consumer wedged the service once**, mid-acquisition, unrecoverably: it stopped
answering discovery and survived `taskkill /F /T`, blocked inside a kernel-mode USB call, and
only a physical replug of the converter released it (and the held `.exe`). Any script that
drives an amplifier must send `stop` in a `finally` block — see
[known-issues §14f](../incidents/README.md).

⚠ `R:\dist\msvc64-nvx2025\bin\nvx2025\` and `NVX2025.bat` are **stale** — that driver now ships
as `nvx.exe` in `R:\dist\msvc64`. Delete them to avoid running the superseded copy.

**Note on the test harness, not the product:** a `ResonanceForeignDriver`-based Python consumer
would not attach to this service's stream (by name or by direct `tcp-ip://`), while
`recorderService` attached and recorded from it every time. The driver is fine; that client path
is not, and it is what produced several misleading "running but no data" readings during this
session. Prefer `recorderService` or the Configurator when checking whether a driver streams.

The staging build no longer carries `nvx2025`: `R:\dist\_build\msvc64-nvx2025\module-overlay.cmake`
now adds only `nvx136_2025`, because `nvx2025` was merged into `nvx`. `R:\src\CMakeLists.txt` is
untouched by the staging tree, as before.

