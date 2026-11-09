# 12. Framework defects found and fixed 2026-08-12

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-12-framework-defects-found-and-fixed-2026-08-12"></a>

### 12. Framework defects found and fixed 2026-08-12

**TRANSFERS UNCHANGED — every fix crossed.** The Qt 6 tree was snapshotted from `R:\src_Qt5` commit
`fae69c34` on 2026-08-27, two weeks after this work, so every §12 fix is in
`R:\src\Core\Resonance` as well. ⚠ The exception is the **Qt Quick Controls 1 traps** bullet at the
end: `styleData.depth`,
`TreeViewItemDelegateLoader` and the Controls 1 `ScrollView` are **QT 5 ONLY** — Controls 1 does not
exist in Qt 6 and the Configurator's tree was reimplemented on Qt 6 `TreeView`. The QML layout trap
above it (elided `Text.contentWidth` fed back into `Layout.preferredWidth`) is version-independent
and still applies.

Six real bugs, all in `Core/Resonance`, surfaced by building
[`recorderService`](../components/recorder.md) and by testing reconnection against a live NVX-52.
All are **fixed**; recorded here because each was invisible until a specific scenario hit it.

<a id="history-12a-setvalue-notified-nobody"></a>

### 12a. `setValue()` notified nobody

`Integer`, `Double`, `String`, `MultiLine` had silent setters. Harmless while every service set
values only during construction; fatal once a service had its own GUI, because a value set
locally never reached any client. Now emits `valueChanged` + `jsonChanged` + `triggerUpdate`
behind an equality guard. `Boolean` had two of the three. See
[architecture §6](../migrations/framework-evolution.md#history-6-parameters).

**Watch for:** `SPEED` writes `errorMessages`/`loadCode`/`code` from its own code; those paths
now re-broadcast the description. Correct, but new traffic where there was none.

<a id="history-12b-streaminfofromjson-was-not-null"></a>

### 12b. `StreamInfo::fromJson({})` was not null

`isNull()` is pointer identity against one shared instance, so an empty JSON object
deserialised to a *non-null* `StreamInfo` with no name, no uid and no connections. Every
`isNull()` check treated it as a real request — so clearing a connector left a phantom stream
attached and the Configurator kept showing it connected. `fromJson` now returns the shared null
for an unaddressable object, and `isEmpty()` exists for the "should I connect" decisions.

<a id="history-12c-reconnection-was-intolerant-of-stream-properties"></a>

### 12c. Reconnection was intolerant of stream properties

A persistent request stored the original `StreamInfo` verbatim. Restarting a producer changes
its uid; changing channel count or sampling rate changes the serialized type. Either made the
request stop matching, and `StreamPool` then created a *new* pending connection on every
discovery cycle — 84 threads and a wedged Configurator inside a minute. Fixed by
`persistentStreamRequest()` (name-addressed rewrite) plus a `requestedFor` cap of one in-flight
attempt per request, and stale attempts are now cleared in place rather than left behind.

<a id="history-12d-applyparameters-could-loop-forever"></a>

### 12d. `applyParameters` could loop forever

Retried entries were de-duplicated with `std::unique`, which only collapses *adjacent*
duplicates, so the retry set grew every round. Rewritten: unknown names are rejected once, each
round must retire at least one entry, and progress is measured by set membership rather than
size. Rejections are logged as `Rejected parameter "<name>" - …` and counted back to the client.

<a id="history-12e-threadcapsule-never-destroyed-its-contained-object"></a>

### 12e. `ThreadCapsule` never destroyed its contained object

`exec()` returned and the object — and its sockets — survived for the process lifetime. A
`deleteLater()` posted after `exec()` returns is never delivered, so nothing else could do it.
Now deleted in its own thread while that thread still exists.

<a id="history-12f-tcpstreamreceiver-waited-30-s-to-connect"></a>

### 12f. `TcpStreamReceiver` waited 30 s to connect

`waitForConnected()` with the default timeout. A dead address held a reconnect attempt for half
a minute; combined with 12c this is what produced the 30–35 s reconnects and 15 s freezes.
Capped at 3 s.

<a id="history-also-fixed-outside-the-framework"></a>

### Also fixed, outside the framework

* **`nvx`**: applying a saved parameter set while stopped dereferenced a null `runner` via
  `trigger_state` → `sendTrigger()` — access violation `0xc0000005`. Guarded. `stop()` now also
  destroys the runner deterministically instead of leaking it.
* **`quickStimulus`**: missing `WIN32` on `add_executable` (console window on every launch —
  now opt-in with `--console`); numeric parameter fields committed only on focus change
  (needed TAB, reverted on dwell, ate keystrokes) — now commit on edit and ignore remote
  updates while focused; `MessageReceiver` gated on the requested type *before* connecting, so
  it could never subscribe by `discover://` URL — validated on Ready instead.
* **Qt Quick Controls 1 traps**, both hit while building the Configurator's recording column:
  `styleData.depth` is hardwired to 0 outside column 0 in `TreeViewItemDelegateLoader`, and a
  `ScrollView` does not size its content item — `parent.width` there is undefined and every
  `Layout.fillWidth` child collapses to zero.
* **QML layout trap:** feeding `contentWidth` of an *elided* `Text` back into its
  `Layout.preferredWidth` is a loop that settles at almost nothing. Measure with `TextMetrics`.

---

