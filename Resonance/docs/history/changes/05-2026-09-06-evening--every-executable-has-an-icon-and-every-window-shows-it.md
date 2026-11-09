# 2026-09-06 (evening) — every executable has an icon, and every window shows it

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-06-evening--every-executable-has-an-icon-and-every-window-shows-it"></a>

### 2026-09-06 (evening) — every executable has an icon, and every window shows it

⭐ **All 25 executables in `R:\dist\bin` now carry their own icon**, and every service window —
QML or QWidget — shows it on the taskbar, in Alt+Tab and in Task Manager; Explorer shows the same
picture for the headless drivers. One visual language: a coloured tile whose colour is the
family (violet operator apps, teal sources, blue input devices, orange actuators, grey helpers,
navy for the framework runner) and a white glyph that is the job — the record ring, the play
triangle, the TEP curve behind a dashed TMS marker, the figure-8 coil, the topoplot head with a
device badge for the five EEG amplifiers. Masters, `.ico` files, tools and the full table:
`R:\src\icons\` (`README.md`, `preview.png`). Rule and mechanism:
[architecture §11d](../migrations/framework-evolution.md); the new-service recipe gained a step.

**One CMake line per module** — `resonance_icon(<target> <icon>)` — embeds the `.ico` as the
`IDI_ICON1` resource Qt's platform plugin gives every window class. `quickStimulus` additionally
sets the icon **and the taskbar identity** per built-in tool before its window exists: measured,
the message sender had been filed under the Configurator's button because the service rename that
sets the AppUserModelID happens from QML after the window is up. The `--console` window gets the
service's icon too.

Built clean (131 steps, 24 resource compiles, 0 errors), deployed with `cmake --install` — the
Qt closure is unchanged, so `windeployqt` had nothing to do, and a Configurator running from
`R:\dist` held three files, which were renamed aside rather than the operator's window killed —
`validate-dist-qt6.ps1` **PASS**. Verified live: the shell API extracts the intended icon from
every executable; the recorder, playback, TEP·SOUND, stimulus and message-sender windows report
the icon through `WM_GETICON` / the window class; a taskbar capture shows them.
⚠ `R:\dist\bin.pre-20260906-1402-icons` is the rollback copy. The three `*.pre-icons` files
that Configurator ran on were deleted on 2026-09-07, once it had been closed.

