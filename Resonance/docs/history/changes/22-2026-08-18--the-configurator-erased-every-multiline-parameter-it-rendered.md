# 2026-08-18 — the Configurator erased every `MultiLine` parameter it rendered

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-18--the-configurator-erased-every-multiline-parameter-it-rendered"></a>

### 2026-08-18 — the Configurator erased every `MultiLine` parameter it rendered

Full write-up: **[known-issues §20](../incidents/README.md)**. Reported as *"`--serviceConfig`
cannot load a `MultiLine` parameter, the Configurator's Load button can"*, and
**`--serviceConfig` was never at fault** — it applied the values correctly and the parameter panel
wrote an empty string over them a second later, which is exactly when an operator looks.

Measured on `SPEED` with `R:\config\speed_feetStim_params.json`: `code` held the configured value
at t=1 and `""` at t=2, with a `ParametersView` attached and nothing else running. Not
SPEED-specific — **`signalGenerator`'s `channelPlan`, the entire channel table, went the same
way**, and so would any service's `MultiLine`.

The delegate marked itself dirty — *the operator is editing, do not overwrite* — on any
`textChanged` arriving while it was not applying a remote value, and a Controls 1 `TextArea`
emits one **while it is being constructed, before `Component.onCompleted`**. So the flag latched
before the delegate had ever seen a value: `__applyRemote()` then refused to display the
parameter for the life of the panel, and 300 ms later `__commit()` wrote the empty string back.
⚠ Both halves were silent, and the visible one — a blank field — reads as *the configuration did
not load*. The flag now keys on **content**, not on when the change arrived.

⚠ **`Parameters::String` carried the identical guard** and was corrected with it, although it was
measured *not* to fail: a `TextField` does not emit `textChanged` during construction where a
`TextArea` does. That is a Controls 1 implementation detail, not a design boundary.

**Two QML files, no rebuild** — `bin\Resonance\**` is loaded from disk, so the fix is
toolchain- and architecture-independent and applies to `mingw32`/`mingw64` as well.
Deployed to `R:\dist\msvc64`; overlay patch for another tree:
**`R:\dist\patch_20260818_multiline-delegate.zip`** (two files + a README, 3.7 KB).

**Verified:** the value survives a panel render and a restart under a second config; the delegate
now *displays* it, which it never did; an edit still commits back; `signalGenerator` 0 of 101
parameters changed by the view, `eStim` 0 of 54, `arduinoTTL` 0 of 53; `siggen_params_check.qml`
passes unchanged. Harness: `R:\config\multiline_delegate_check.qml`.

