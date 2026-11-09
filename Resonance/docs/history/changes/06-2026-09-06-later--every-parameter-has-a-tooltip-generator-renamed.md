# 2026-09-06 (later) — every parameter has a tooltip; `generator` renamed

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-06-later--every-parameter-has-a-tooltip-generator-renamed"></a>

### 2026-09-06 (later) — every parameter has a tooltip; `generator` renamed

⭐ **All 294 registered parameters now have a description**, so every row in every Configurator
panel has a tooltip. 45 had none — 24 in `tepSoundService`, 5 in `SPEED`, 4 each in `KARDi2`,
`nvx136` and `nvx136_2021`, 2 in `neuroMS`, 1 each in `nvx` and `playbackService`.

**The rule is enforced, not just documented:** `scripts\audit-parameter-descriptions.py` pairs
every parameter with its `setDescription` and exits non-zero if one is missing. Run it after adding
a parameter. Tooltip width was already solved — `ParameterToolTip` is fixed at the panel width and
wraps into it (`arch_architecture.md`).

**`generator.bat` → `messageSender.bat`.** It works, and it is not a signal generator: it opens
named message streams and publishes typed text into them. It sat in the same directory as
`signalGenerator.bat` and `SignalGenerator.exe`, which is the real one. Window title, service name,
QML file and `--builtIn` token all renamed; the old `--builtIn generator` token still resolves so
an existing shortcut does not break, and the stale `R:\dist\generator.bat` is deleted.

⚠ **It has no Configurator parameters, and cannot** — `CommunicationLayer::addParameter` is not
exposed to QML, so no QML built-in can declare any. `configurator` and `recorder` are in exactly
the same position and always have been; an empty parameter panel is what a built-in *app* looks
like, as distinct from a service. Giving them parameters means building a QML-facing parameter
API, which is a feature, not a fix.

