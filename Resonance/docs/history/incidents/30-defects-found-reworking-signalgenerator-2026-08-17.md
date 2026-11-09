# 19. Defects found reworking `signalGenerator`, 2026-08-17

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-19-defects-found-reworking-signalgenerator-2026-08-17"></a>

### 19. Defects found reworking `signalGenerator`, 2026-08-17

**TRANSFERS UNCHANGED — every fix crossed with the module**, and §19e's trap is additionally closed
by the Qt 6 launchers: `R:\dist\signalGenerator.bat` is `call "%~dp0env.bat"` followed by
`cd /d "%RESONANCE_DIR%\bin"`, so `NoDefaultCurrentDirectoryInExePath` cannot stop `env.bat`
resolving. `R:\dist_Qt5\msvc64\signalGenerator.bat` is still bare `call env` / `cd bin`. The real
fix — `resolveRootPath()` deriving the root from `applicationDirPath()` — is in both trees, so
neither depends on the launcher.

Context: [signal-generator.md](../components/signal-generator.md). The first three had been in the tree since
the module was written and matter because **this is the source everything else is tested
against** — a test signal that is wrong is worse than no test signal.

<a id="history-19a-dirtysine-was-bit-identical-to-fixedsine---fixed-2026-08-17"></a>

### 19a. `dirtySine` was bit-identical to `fixedSine` — ✅ fixed 2026-08-17

`generator.cpp` switched on the mode with

```cpp
case fixedSine:
case dirtySine:
```

falling through to one body. The mode had existed for as long as the module had and had never
differed from Single sine by one sample. Anyone who selected it to get a noisy signal got a clean
one. It now adds noise at a tenth of the amplitude.

<a id="history-19b-fixednanmeander-emitted--not-nan---fixed-2026-08-17"></a>

### 19b. `fixedNaNMeander` emitted `+∞`, not NaN — ✅ fixed 2026-08-17

```cpp
val = amplitude / ((sample % static_cast<long>(samplingRate)) > (samplingRate / 2));
```

The divisor is a `bool`, so this is `amplitude / 0.0` for the first half of every second — which
in IEEE arithmetic is **positive infinity**, not NaN, for any non-zero amplitude. The signal
viewer's NaN handling and [§13b](37-signal-viewer-defects-found-and-fixed-2026-08-13.md#history-13b-one-nan-killed-a-channel-for-good) were exercised against
infinities. The replacement keeps the same 1 Hz timing and the same duty and emits real NaN.

<a id="history-19c-every-channel-carried-identical-samples---fixed-2026-08-17"></a>

### 19c. Every channel carried identical samples — ✅ fixed 2026-08-17

The inner loop wrote one computed value across every channel:

```cpp
for (int channel = 0; channel < channels; ++channel)
    d[i * channels + channel] = val;
```

So a consumer that transposed, swapped, reordered or dropped a channel produced **bit-identical
output**, and no amount of channel-count testing could catch one. The 70-channel and 25 kHz
campaigns in STATUS ([change history](../changes/README.md)) were all run against a stream in which every channel was the same.

Fixed with `shiftStep` (channel *i* shifted by *i* × ms) and `signatureStep` (channel *i* at
`fixedFrequency + i ×` Hz), plus per-channel recipes in the channel table. **Both default to 0**,
so the original behaviour is still exactly reproducible for a comparison against an old recording.

<a id="history-19d-entering-running-republished-the-streams---fixed-2026-08-17"></a>

### 19d. Entering `running` republished the streams — ✅ fixed 2026-08-17

Introduced by the rework and caught by a recording rather than by a test. `armed` exists so a
consumer can attach before anything is emitted; entering `running` then called the same
`publishAll()` and rebuilt every `OutputStream`, which is a **new connection** — so the recorder
that had just latched on spent its first seconds rediscovering, and arming bought nothing.

Measured on the same 20 s run recording five streams: **172 blocks before, 203 after**; 35 messages
before, 41 after. Evidence: `R:\dist\_build\siggen-verify\`.

The general shape is worth remembering for any service with an arm-then-run lifecycle: **the
transition into `running` must not touch anything a consumer may already be attached to.**

<a id="history-19e-resonance_record_path-is-never-set-by-the-shipped-launchers-on-this-machine--fixed-2026-08-25"></a>

### 19e. `RESONANCE_RECORD_PATH` is never set by the shipped launchers on this machine — FIXED 2026-08-25

Every `.bat` in a distribution root begins

```bat
call env
```

and this PC has `NoDefaultCurrentDirectoryInExePath` set, so the call does not resolve, `env.bat`
never runs, and `RESONANCE_RECORD_PATH` is never exported. `ResonanceApp` then falls back to the
process's working directory, which for these launchers is `bin\`.

Two 2.5 MB recordings were written into `R:\dist\msvc64\bin` during this session before it was
noticed. This is **not specific to `signalGenerator`** — it applies to every launcher in every
distribution, and it silently defeats the packaging requirement recorded in
STATUS ([change history](../changes/README.md)) that every distribution has a `data\` directory for exactly this purpose.

`call .\env` was the proposed fix. It was never applied — one line in every `.bat` in the tree and
in three deployed distributions is a packaging change — and it is no longer needed.

**Fixed instead in `ResonanceApp` itself**, by removing the working directory from the answer
altogether. `resolveRootPath()` takes `RESONANCE_DIR` when it is exported and otherwise derives the
distribution root from `QCoreApplication::applicationDirPath()` — `bin\..` — so an executable
started with no environment at all, by a launcher whose `call env` did not resolve or by a desktop
shortcut that runs no batch file, still resolves `<root>\data`. `recordPath()` is now
`contentPath("data")`, which is `RESONANCE_RECORD_PATH` if set and `<root>\data` if not.

Verified 2026-08-25 with every `RESONANCE_*` variable unset and the working directory set to `bin`:
"Record to auto file" on `signalGenerator` wrote `distro\data\autodump.1.h5` and left `bin` empty.
Evidence in `R:\dist\_build\pathfix\`. The same change gives every file chooser in the tree a
content folder to open in instead of `bin` — see `arch_architecture.md`.

> ⚠ Two follow-ups applied at the 2026-08-25 ship:
>
> * **`data` no longer falls back to the root.** `contentPath()` returns `<root>\<kind>` if that
>   folder exists and `<root>` if it does not — which for `data` meant recordings landing beside
>   `env.bat` on a distribution whose `data\` had never been created (and `env.bat` is exactly
>   what creates it, and exactly what does not run here). `data` is now created instead.
> * **The `RESONANCE_<KIND>_PATH` variables now move loaders, not only choosers.** As first
>   shipped they changed where a file dialog *opened* and nothing that *resolved* a stored
>   relative path, so `RESONANCE_MONTAGES_PATH=D:\lab\montages` browsed to `D:\lab\montages`
>   and then read `<root>\montages\mks64_standard.ced` — one setting, two answers, nothing said.
>   `ResonanceApp::resolveContent(kind, path)` is the shared resolver;
>   `tepSoundService`'s montage, lead-field and protocol loaders go through it.

---

