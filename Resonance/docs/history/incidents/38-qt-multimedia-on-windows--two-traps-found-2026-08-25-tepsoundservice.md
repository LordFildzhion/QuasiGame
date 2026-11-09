# 17. Qt Multimedia on Windows — two traps found 2026-08-25 (tepSoundService)

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-17-qt-multimedia-on-windows--two-traps-found-2026-08-25-tepsoundservice"></a>

### 17. Qt Multimedia on Windows — two traps found 2026-08-25 (tepSoundService)

**17a and 17b are QT 5 ONLY. 17c is UNKNOWN UNDER QT 6.** Qt 6 replaced the whole plugin-selector
machinery: there is no `QMediaServiceProviderHint`, no `QAbstractVideoSurface` (`VideoCue` connects
a `QVideoSink` instead), and `QT_MULTIMEDIA_PREFERRED_PLUGINS` is superseded by
**`QT_MEDIA_BACKEND`**. `R:\src\tepSoundService\main.cpp:82-83` pins `ffmpeg` unless the operator
has set the variable themselves, and the Qt 6 package carries a bundled FFmpeg. So neither the
two-backends-in-one-process split (17a) nor the Media Foundation teardown crash (17b) can arise
there — though `~VideoCue()` kept its ordered teardown anyway, which is right: it is a lifetime
rule, not a backend workaround.

⚠ **Both backend plugins still ship side by side** in `R:\dist\qt\plugins\multimedia\` —
`ffmpegmediaplugin.dll` and `windowsmediaplugin.dll` — so a rig that sets `QT_MEDIA_BACKEND=windows`
puts itself back on Media Foundation and back inside 17c. The override is deliberate, for a rig
qualified on another backend; it is not a default.

⚠ **17c has NOT been re-measured under FFmpeg.** Qt 6 validation covers two hardware-free files, one
MP4/AAC and one Matroska/FLAC (`R:\src\docs\VALIDATION.md`). The operator's 34-clip sweep — the 23
`A_PCM/INT/LIT` refusals that produced the remux advice — was run against Media Foundation and has
not been repeated. FFmpeg has no reason to refuse raw PCM in Matroska, and the Qt 6 source comment
asserts it does not, but **nobody has run those 34 files through it**. Until someone does, the remux
advice stands and the `.mkv` set should be treated as unqualified on the Qt 6 stage.

<a id="history-17a-qmediaserviceproviderhint-silently-overrides-qt_multimedia_preferred_plugins---fixed"></a>

### 17a. `QMediaServiceProviderHint` silently overrides `QT_MULTIMEDIA_PREFERRED_PLUGINS` — ✅ fixed

`main()` pins `QT_MULTIMEDIA_PREFERRED_PLUGINS=windowsmediafoundation` before `QApplication`, and
that is correct and necessary: unpinned, Qt 5.15.2 on this machine picks the **DirectShow** plugin,
which decodes **nothing** — not a `.mkv`, not a plain `.mp4` — and answers `0x80040266`
(`VFW_E_UNSUPPORTED_STREAM`) out of `DirectShowPlayerService::doRender`.

The pin worked for `mediaprobe.cpp`, which builds a plain `QMediaPlayer`, and **did not work** for
the stage, which built `QMediaPlayer(this, QMediaPlayer::VideoSurface)`. That flag is a
`QMediaServiceProviderHint`, and Qt's `QPluginServiceProvider::requestService()` gives
`VideoSurface` its own branch: it walks the plugin list and takes the first entry advertising the
feature, which here is DirectShow. The preferred-plugin list only decides the ORDER; that branch
ignores it.

The consequence was the worst shape a media bug can have: **validation and playback on two
different backends in one process**. A file passed the Arm-time probe under Media Foundation and
then would not play on the stage under DirectShow, with a black screen in front of the subject.

Fixed by dropping the flag — `QMediaPlayer(this)`. `setVideoOutput(QAbstractVideoSurface*)` works
either way, and QML's own `MediaPlayer`/`VideoOutput` pair constructs its player with no flag.
`VideoCue::backendName()` now reports the service class Qt actually chose, and it is logged once at
startup, because "which backend am I on" was not answerable from anywhere in the console.

<a id="history-17b-destroying-a-media-foundation-qmediaplayer-crashes-wmfenginedll---fixed"></a>

### 17b. Destroying a Media Foundation `QMediaPlayer` crashes `wmfengine.dll` — ✅ fixed

`0xC0000005` at `wmfengine.dll+0x9a55`, reproducible, with a WER record: switch a stimulus row to
`video` in the editor and then back to `text`. The `Loader` around `MediaLayer.qml` deactivates,
QML deletes `VideoOutput` and `VideoCue` in an order neither class chooses, and Media Foundation's
presenter is left holding a `QAbstractVideoSurface` that has gone. The row need never have been
given a file.

Latent until 17a was fixed — the stage had always been on DirectShow, so this teardown never ran
against an MF session.

`~VideoCue()` is now an ordered teardown instead of `= default`: stop the 16 ms frame poll, stop
the player, `setMedia(QMediaContent())`, `setVideoOutput(nullptr)`, then detach the relay's target,
all while both objects still exist.

<a id="history-17c-what-actually-stops-the-operators-mkv-files-playing"></a>

### 17c. What actually stops the operator's `.mkv` files playing

Not a codec pack. Measured over all 34 clips in the stimulus directory
(`R:\dist\_build\stagefix\sweep_wmf.txt`), against the shipped `qt\`: under Media Foundation all 9
`.mp4` load, and of 25 `.mkv` exactly the 2 with no audio track load. The other 23 all carry
`A_PCM/INT/LIT` — raw PCM inside Matroska — read out of the EBML headers; Windows' Matroska source
refuses the stream set over it and the picture goes with it. 34 files, no exception either way.

The remedy is a stream copy, not an install: `ffmpeg -i in.mkv -c:v copy -c:a flac out.mkv`,
verified to load. See `guide_tep-operator.md` §14b.

---

