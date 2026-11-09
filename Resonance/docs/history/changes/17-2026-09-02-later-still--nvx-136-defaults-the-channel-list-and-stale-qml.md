# 2026-09-02 (later still) — NVX-136 defaults, the channel list, and stale QML

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-02-later-still--nvx-136-defaults-the-channel-list-and-stale-qml"></a>

### 2026-09-02 (later still) — NVX-136 defaults, the channel list, and stale QML

Three field reports, all fixed, rebuilt, redeployed and revalidated. **27/27 enabled CTests pass**;
four hardware/external tests remain disabled by design.

**The NVX-136 shipped starting point is now in the service.** A fresh launch of either generation
comes up on **1 kHz, block 50, the first 64 EEG channels plus the trigger, and
`mks64_standard.ced`**. It used to live in `params\nvx136_default64ch.json`, applied by the
launcher through `--serviceConfig` — which only worked for launches that went through the
launcher, could not fill a channel list whose shape it had not seen, and was refused outright if
the length did not match the device. `NVX136.bat` no longer passes it; the preset stays in
`params\` as an example to load by hand. Values in `R:\src\nvx136\nvx136defaults.hpp`, asserted
by `test_Nvx136Defaults`, verified on the deployed package off the bus:
`1 kHz`, block `50`, 4581 bytes of CED, `65/137` channels.

**`nvx136_2021` now registers as `NVX136`.** Same name as the mainline, so the two are drop-in
swaps: every saved parameter file, harness and protocol that names `NVX136` drives whichever one is
running. ⚠ **Run one or the other, never both.** The launcher keeps the `_2021` suffix.

**Channel list: selecting a channel and pressing Space did nothing.** Reported against `nvx136`,
`nvx136_2021` and the regular `nvx` at once — all three share one QML editor. The Qt 5 version
was a Controls 1 `TableView` with its own selection model and key handling; the Qt 6 rewrite
hand-rolled the selection and put `Keys.onSpacePressed` on a ListView **that never had active
focus**. Selecting a row now takes the keyboard; the arrow keys move the selection rather than an
invisible cursor, the current row is drawn while the list holds focus, Tab reaches it and Ctrl+A
selects all. `test_ChannelsListQml` drives real mouse and key events through a real window.

⚠ **And the reason that fix took three attempts to verify: the build tree was running stale QML.**
`install_directory()`'s POST_BUILD copy only fires when the target **relinks**, and editing a `.qml`
does not relink the plugin — so the staged copy under `_build/runtime/bin/Resonance` stayed at
whatever version was current the last time C++ changed (measured: 5254 bytes against 9223 in
source). `cmake --install` refreshed it, so the deployed package was always right and only the build
tree lied, which is the worse way round because the build tree is what a test runs against. A
`quickStimulusQml ALL` target now stages it every build.

---

