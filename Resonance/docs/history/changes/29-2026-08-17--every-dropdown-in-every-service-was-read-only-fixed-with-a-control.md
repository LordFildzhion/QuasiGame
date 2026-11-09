# 2026-08-17 — every dropdown in every service was read-only; fixed, with a control

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-17--every-dropdown-in-every-service-was-read-only-fixed-with-a-control"></a>

### 2026-08-17 — every dropdown in every service was read-only; fixed, with a control

Full reasoning and evidence: **`workpc-changes.md` §5 (on the lab drive, `R:\docs\_notes\`)**. Two QML files, no
rebuild — `bin\Resonance\**` is loaded from disk.

**`Resonance__Parameters__Select.qml` wrote nothing back to its service**, so every `Select` in
every service — `viewer_layout`, both NVX drivers' `samplingRate` and `mode`, every dropdown in
the tree — moved on screen and applied nothing. The guard `root.status !== Loader.Ready` names the
**GroupBox**, not the Loader that instantiates the delegate; a `GroupBox` has no `status`, so the
test was `undefined !== Loader.Ready`, always true, and the handler returned before writing. It is
a regression from the 2026-08-15…17 rework, when that Loader's id was renamed and this one
delegate was not updated.

⚠ **Repairing the id is not the fix, and is worse than the bug.** The write-back hung on
`onCurrentIndexChanged`, which cannot distinguish a person's choice from a programmatic change —
and changing `model` resets `currentIndex` to 0, which `ParametersView` triggers on *every*
description re-broadcast. A repaired guard therefore sends index 0 to the service on every
re-broadcast: an NVX rate would not merely *display* 250 Hz, it would become it. The write-back
now hangs on **`onActivated`**, which Qt emits only for a user action, and the `_block` flag and
the `status` guard are both gone.

**Proved with a control** — same harness, same live service, same emitted signal, only the QML
differing: original `applied=false`, fixed `applied=true`, and after a forced re-broadcast the
value held with no index-0 write. Harness: `R:\config\select_apply_check.qml`.

Also fixed: **the Configurator could never start side by side.** `viewer_layout` declares
`index: 1` and read back `"Stacked (2x1)"`. Reordering `options` before `index` does *not* help —
an array literal is a binding and is evaluated after the `index: 1` literal — so it is set from
`Component.onCompleted` instead. ⚠ Separately, `Select` re-declares `index` for the selected option
and thereby **shadows `Parameter::index`**, so a `Select` cannot carry a tab sort index at all.

**`playbackService` was re-validated end to end and is NOT broken** — standalone worker, the
controller through `prepare`/`armed`/`start`, and the Configurator's own double-click path all
carry data into the real `StreamView`. The work-PC report does not reproduce here;
`workpc-changes.md` §5d (on the lab drive, `R:\docs\_notes\`) records what is still needed from that machine.

