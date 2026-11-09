# 20. The Configurator erased every `MultiLine` parameter it displayed — ✅ fixed 2026-08-18

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-20-the-configurator-erased-every-multiline-parameter-it-displayed---fixed-2026-08-18"></a>

### 20. The Configurator erased every `MultiLine` parameter it displayed — ✅ fixed 2026-08-18

**TRANSFERS UNCHANGED — the fix crossed, the mechanism did not.** The content-keyed guard is in
`R:\src\quickStimulus\import\Resonance\Resonance__Parameters__MultiLine.qml` (`__remoteText` at
`:21`, the commit test at `:55`), so the defect cannot return. But its *cause* — a Controls 1
`TextArea` emitting `textChanged` during construction — is **QT 5 ONLY**: the Qt 6 delegate is a
Controls 2 `TextArea`, and whether it emits during construction has not been measured. The guard was
carried across because it is keyed on content, which is correct either way. ⚠ The overlay-patch
property still holds under Qt 6: `R:\dist\bin\Resonance\**` is a tree of loose `.qml` files loaded
from disk, so a delegate fix is still toolchain-independent — but the compiled
`quickStimulusPlugin.dll` beside them is not, and since §25b some formatting that used to be QML is
inside it.

Reported as *"`--serviceConfig` cannot load a `MultiLine` parameter, but the Configurator's Load
button can"*. **`--serviceConfig` was never at fault.** It applied the values correctly; the
parameter panel wrote an empty string over them about a second later, which is when an operator
looks.

Measured on `SPEED` launched with `R:\config\speed_feetStim_params.json`, a `ParametersView`
attached one second after:

```
t=1  code = "import os\nroot = os.path.join(...)"      <- the config applied
t=2  code = ""                                          <- the panel wiped it
```

Not specific to `SPEED`: `signalGenerator`'s `channelPlan` — the whole channel table, and the one
parameter [signal-generator.md §3](../components/signal-generator.md) keeps as a single `MultiLine`
precisely so a saved configuration *can* be reloaded — went the same way. Any service with a
`MultiLine` parameter loses it the first time anyone opens it.

**Cause.** `Resonance__Parameters__MultiLine.qml` marks itself dirty — *the operator is editing,
do not overwrite* — on any `textChanged` that arrives while it is not applying a remote value. A
Controls 1 `TextArea` emits one such change **while it is being constructed, before
`Component.onCompleted`**:

```
DIAG onTextChanged applyingRemote=false text=""     <- construction
DIAG onCompleted
DIAG applyRemote dirty=true  -> returns early       <- the value is never displayed
DIAG timer
DIAG commit serialized="import resonance" text=""   -> parent.serialized = ""
```

So the flag latched before the delegate had ever seen a value, and two things followed, both
silent: `__applyRemote()` refused to display the parameter for the life of the panel, and 300 ms
later `__commit()` wrote the empty string back to the service.

**The flag was keyed on timing; it is now keyed on content** — text that differs from what the
service last supplied (`__remoteText`). At construction the delegate's text and that record are
both empty, so nothing is an edit; every genuine edit still is.

⚠ **`Parameters::String` carried the identical guard** and was fixed with it, though it was
measured *not* to fail: a `TextField` does not emit `textChanged` during construction where a
`TextArea` does. eStim's and arduinoTTL's nine preset strings survived a panel render before the
fix. The distinction is a Controls 1 implementation detail and not worth leaving a delegate that
can blank a preset on.

**Why Load appeared to work:** both paths end in the same `applyParameters` — the Configurator's
Load sends the whole array over the EventBus. What differs is that on that path the panel's own
text *is* the value being sent, so the delegate agrees with itself.

⚠ **Two QML files, no rebuild** — `bin\Resonance\**` is loaded from disk
([deployed-vs-repo.md](../migrations/deployed-vs-repo.md)), so the fix is toolchain- and
architecture-independent. Overlay patch: `R:\dist\patch_20260818_multiline-delegate.zip`.

**Verified:** the value survives a panel render and a service restart under a second config; the
delegate now *displays* it, which it never did; an edit still commits; `signalGenerator` 0 of 101
parameters changed by the view, `eStim` 0 of 54, `arduinoTTL` 0 of 53; `siggen_params_check.qml`
unchanged. Harnesses in `R:\config\multiline_delegate_check.qml`.

---

