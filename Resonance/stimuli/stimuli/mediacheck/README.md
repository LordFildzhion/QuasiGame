# Media check set

Six small files whose only purpose is to tell three different failures apart when a video cue does
not play: **the container**, **the codec inside it**, and **the backend**.

Staged here on 2026-08-25 so the check works on a machine that cannot reach the operator's own
media at `N:\Projects_MSU\2025 - TEP\method\stimuli\videoSamples\`.

| file | what it isolates |
|---|---|
| `test_a.mp4` | a plain H.264 MP4. The control — if this fails, nothing about media works here |
| `test_c.mkv` | the same kind of content in Matroska. Fails where `test_a.mp4` succeeds ⇒ container |
| `remux_aac.mp4` | MP4 carrying AAC audio |
| `remux_flac.mkv` | Matroska carrying FLAC audio |
| `remux_noaudio.mkv` | Matroska with the audio track removed entirely — separates video from audio |
| `remux_lpcm.mov` | QuickTime carrying LPCM |

## What was already measured, on the development machine, 2026-08-25

A sweep of the operator's own 34 files through the shipping probe:

* **MP4 — 9 of 9 loaded**, `error=0`.
* **MKV — 23 of 25 InvalidMedia**, `error=2`, *"stream not supported — unknown format"*.
* **2 MKVs did load**: `countdownLight__blackTrigger.mkv`, `countdownLight__whiteTrigger.mkv`.

Those two are the whole point. If Matroska were simply unsupported, none would load. So the
container is not the problem by itself — **it is a codec inside the container**, and the operator's
animated stimuli happen to use one the pinned backend cannot decode.

⚠ That result is from the DEVELOPMENT machine. The lab PC may have different codecs installed, and
finding out is the job. Do not assume this table transfers.

## Reporting

For each file: does it probe, does it play, and the **verbatim** error string. The refusal text
currently blames raw PCM inside Matroska; where that is the wrong explanation, say so — the message
is going to be rewritten from what comes back.
