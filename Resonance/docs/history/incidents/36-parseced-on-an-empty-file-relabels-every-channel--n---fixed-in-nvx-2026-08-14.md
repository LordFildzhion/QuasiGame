# 12h. `parseCED` on an empty file relabels every channel `?? N` — ✅ fixed in `nvx` 2026-08-14

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx52.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-12h-parseced-on-an-empty-file-relabels-every-channel--n---fixed-in-nvx-2026-08-14"></a>

### 12h. `parseCED` on an empty file relabels every channel `?? N` — ✅ fixed in `nvx` 2026-08-14

**TRANSFERS UNCHANGED — both guards crossed** with `nvx` and `nvx136`. Not to be confused with §23,
which is a different `parseCED` defect and is still open in both trees.

`internal/ParseCED.cpp:90` fills any channel it found no label for with `QString("?? %1")`.
That is correct for a montage row with a missing label, and wrong for *no montage at all*:
`nvx`'s `Application::start()` called `metaData.addCEDinfo(ced->binary(), cedMask)`
unconditionally, so a default launch with no CED file produced 32 channels named `?? 1 … ?? 32`
in the viewer and in every recording, instead of `Ch 1 … Ch 32`.

Only visible through the *service*: the `nvx2025` validation probes construct `NVXDataThread`
directly and never touch `Application`, which is why an otherwise thorough hardware campaign
did not catch it. Fixed by calling `addCEDinfo` only when `ced->binary()` is non-empty.
The same fix landed in `nvx136` on 2026-08-15 (see §14d-bis) — it was reproduced there in a
real recording, where every EEG channel came out `?? N`.

