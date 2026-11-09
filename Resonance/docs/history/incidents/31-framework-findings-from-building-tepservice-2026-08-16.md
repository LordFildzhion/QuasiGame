# 18. Framework findings from building `tepService`, 2026-08-16

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-18-framework-findings-from-building-tepservice-2026-08-16"></a>

### 18. Framework findings from building `tepService`, 2026-08-16

**Mixed. §18a UNKNOWN UNDER QT 6; §18b FIXED BY THE PORT.** ⚠ `tepService` itself is retired and
retained as a Qt 5 comparator — [qt5-still-needed.md §3.2](../migrations/qt5-still-needed.md) — but neither finding
is in it.

Context: [tep-service.md](../components/tep.md). Neither is in that module; both are in shipped code
that every service goes through.

<a id="history-18a-rendering-any-service-through-parametersview-throws-in-twowaybindingjs--open"></a>

### 18a. Rendering any service through `ParametersView` throws in `TwoWayBinding.js` — open

**UNKNOWN UNDER QT 6.** `TwoWayBinding.js` is **byte-identical** in `R:\src` and `R:\src_Qt5`, and
both carry the rewritten `hasProperty()` guard, so the file has moved since this frame was captured
and line 17 is no longer the line named here. Nobody has counted the throws against a Qt 6
Configurator. Treat it as live in both trees. (The 2026-08-16 frame below names the tree that is
today `R:\dist_Qt5\msvc64`.)

```
file:///R:/dist/msvc64/bin/Resonance/TwoWayBinding.js:17:
    TypeError: Cannot read property 'serialized' of undefined
```

Measured with the same harness against two different services, so it is not about either of them:

| Service | Parameters | Throws |
|---|---|---|
| `TEP` | 60 | **11 times** |
| `Recorder` | 10 | **2 times** |

It is thrown during the delegate creation `ParametersView` does when a description arrives, and
the panel renders correctly afterwards — which is exactly why it has survived: the visible
outcome is right and the log is full of a repeating TypeError that looks like somebody else's
problem. Anything reading a service's log for a real fault has to filter it out first.

Reproduce with `quickStimulus.bat -l R:\config\tep_params_check.qml`, which also prints the
parameter set's shape.

<a id="history-18b-hdfrecorder-writes-one-row-more-than-it-recorded--open-under-qt-5--fixed-by-the-port"></a>

### 18b. `HDFRecorder` writes one row more than it recorded — open under Qt 5, ✅ FIXED BY THE PORT

**Same defect as [§14k](24-defects-found-and-fixed-2026-08-15.md#history-14k-every-hdf5-dataset-ends-in-one-all-zero-row--open), reached from the
recorder side; see there for the measured before/after.** A `R:\dist` recording has
`rows == sum(blocks['samples'])` exactly. Still open in `R:\dist_Qt5\msvc64`, deliberately not
back-ported, so the two files below remain one row long — and so does every historical recording.

A `Float64` stream recorded by `recorderService` comes back one row longer than the sum of its
own block sizes:

| File | Sum of `blocks['samples']` | Rows in `data` |
|---|---|---|
| `run02_recorded_streams.h5` (17 blocks × 2000) | 34,000 | **34,001** |
| `01_TP_M1_60MSO_single_REAL.hdf5` (4995 blocks) | 9,798,760 | **9,798,761** |

The graduation file the playback module was validated against has it too, so this is not new and
not specific to any producer. The extra row is presumably an un-trimmed extent from the dataset's
last `extend`. It is harmless as long as an analysis reconciles against `blocks` rather than
against `data.shape[0]` — which the playback module does, and which is why nobody has noticed.
Anything that reads the last row of a recording is reading whatever the extend left there.

---

