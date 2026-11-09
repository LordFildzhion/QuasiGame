# 2026-08-15 — HDF5 chunking fixed; a lost 2025 fix restored to source

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-15--hdf5-chunking-fixed-a-lost-2025-fix-restored-to-source"></a>

### 2026-08-15 — HDF5 chunking fixed; a lost 2025 fix restored to source

⚠ **Every build made from `R:\src` since October 2025 had a recording regression**, because the
fix for it was only ever delivered as a compiled DLL.

On 2025-10-06 Yuri sent `Resonance.dll` with *"отключил дефлейт и поправил размер блока в хдф5"*.
That binary is `R:\dist_legacy\dist2025\bin\Resonance.dll` (2025-10-07). It was never committed —
`feature/conan2` ends at 2025-07-05 — so `HDFRecorder.cpp` still carried the 2020 code: chunk of
**one sample** and **deflate 9**, on every dataset. At 25 kHz that is 25 000 filter invocations
and B-tree entries per second.

Recovered by reading the layout out of the files that DLL wrote (HDF5 records chunk shape and
filter pipeline in its own header), then reimplemented in source:

| | |
|---|---|
| Chunk | one second of samples, capped to 1 MB so it still fits HDF5's default chunk cache |
| Compression | **off by default**, opt-in `0..9` via `Recorder::setCompression()` and the recorder's `compression` parameter |
| Index/event datasets | fixed 1024 / 256 records per chunk |

Verified: 2 ch @ 5 kHz → `chunk=(5000, 2) filter=NONE`, identical to his `test_acc3.hdf`;
64 ch @ 5 kHz → `chunk=(2048, 64)`, the cap engaging; `compression=6` stores 30.2 MB of samples
in 0.5 MB. Full detail: [recorder-service.md §6.4](../components/recorder.md).

**The lesson is the delivery, not the code.** A fix that ships as a binary is invisible to every
later build. Worth checking whether anything else in `dist2025` is in the same position — the
QML divergence in [deployed-vs-repo.md](../migrations/deployed-vs-repo.md) is a known second case.

