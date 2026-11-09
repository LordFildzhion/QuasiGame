# tepSoundService — four-view build crashed with the subject screen open — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/tepsound.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-tepsoundservice--four-view-build-crashed-with-the-subject-screen-open"></a>


**Status: CLOSED, 2026-08-23. Fixed and deployed.** `R:\dist\msvc64` now carries the four-view
console. The backup of the previous distro is `R:\dist\msvc64\bin.pre-fourviews-20260823-031827`.


<a id="history-what-happened"></a>

## What happened

With `Show subject screen` on — the default, and the ordinary session configuration — the service
died with an access violation about four seconds after the amplifier stream was discovered.

```
Faulting application: tepSoundService.exe
Faulting module:      Qt5Core.dll  5.15.2.0
Exception code:       0xc0000005
Fault offset:         0x0000000000001196     (identical in every occurrence)
```


<a id="history-the-cause"></a>

## The cause

**A use-after-free of a QML-garbage-collected `Parameters::Parameter`.**

`TepSoundService::buildParameters()` (`src/tepSoundService/service.cpp:257`) creates every parameter
with `new` and **no parent**, keeps a raw pointer in a member, and registers it through
`CommunicationLayer::addParameter()` (`src/Core/Resonance/communicationlayer.cpp:296`), which does
not reparent either. Nothing in `R:\src` ever called `QQmlEngine::setObjectOwnership`.

`TepSoundService::parameter()` is a `Q_INVOKABLE` returning `QObject*`. Qt's V4 collector deletes a
wrapped object whenever `!object->parent() && !ddata->indestructible` — so any parameter handed to
QML through that method was **owned by the garbage collector**. When one was collected, the C++ raw
member kept pointing at the freed block. `reconfigure()` (`service_analysis.cpp:474`) then ran

```cpp
m_trigger.setSerialCommands(m_triggerMap->value());
```

against a `Parameters::MultiLine` whose heap block the allocator had already reissued to Qt's
`QUnifiedTimer`. The `QString` copy constructor read a garbage `d` pointer and the process died.

Why it only appeared with the four-view console: every other lookup in the UI stores the parameter
in a QML property (`ParamRow`/`ParamControl { param: ... }`), which pins the wrapper and keeps it
reachable. `StimuliView.qml:483` was the **only** site that fetched one transiently inside a binding
expression and dropped the reference:

```qml
root.param("triggerMap").value.split("\n").join(" · ")
```

`triggerMap` was therefore the only collectable parameter, and it is the only `MultiLine` in the
service. That single line is what made a latent framework defect reachable.

This accounts for every observation that made the bug confusing: the intermittency (GC timing), the
constant fault offset, `Binding loop` staying 0, the dependence on the stage (`QUnifiedTimer` only
exists once QML animations run), the apparent correlation with `FeedbackView` (GC pressure, not
layout), and why three plausible QML "fixes" each passed one run.


<a id="history-the-fix"></a>

## The fix

One line, at the single door through which QML obtains a parameter —
`TepSoundService::parameter()`, `src/tepSoundService/service_run.cpp:1161`:

```cpp
QQmlEngine::setObjectOwnership(p, QQmlEngine::CppOwnership);
```

`CppOwnership` sets `QQmlData::indestructible`, which is exactly the true statement about these
objects: C++ owns them for the life of the process (nothing ever deletes them). It changes nothing
else — no reparenting, no destruction order, no new allocation, no new deletion.

**`FeedbackView` was not touched.** Neither were `StimuliView`'s `Layout.minimumHeight: 244` nor
`ParamControl`'s 110 px `int` floor.


<a id="history-what-was-refuted"></a>

## What was refuted

⚠ **The layout-recursion hypothesis was wrong.** The real stack — caught under a purpose-built
debugger, reproduced identically 5/5, with a fault RVA matching the WER fault offset — was **22
frames deep and used 29 KB of a 1024 KB stack**, with no repeating cycle and not one QML or layout
frame anywhere. It was never a stack overflow. The static audit agreed independently:
`Layout.preferredHeight: 116` on the two placeholder panels *replaces* `implicitHeight` in
`QQuickLayoutAttached::effectiveSizeHints()`, so the supposed cycle never closed. A stack overflow
would also have raised `0xC00000FD`, not `0xC0000005`.

The earlier reverts of the three candidate QML fixes were correct — for the wrong reason.


<a id="history-confirmation"></a>

## Confirmation

The fault is **not** a Poisson process: it is a one-shot event ~4 s after stream discovery. Survive
that window and the run is clean indefinitely (two pre-fix survivors ran the full 300 s). So
**survival time proves nothing; only pass rate does** — which is why single green runs misled the
earlier attempts.

| configuration | pre-fix | post-fix |
|---|---|---|
| four-view, subject screen on, 45 s / 300 s ceiling | **13 of 16 crashed (81 %)**, all within 12.2–12.7 s wall (4.1–4.7 s after the stream) | **0 of 20 crashed** |
| under the debugger (NT debug heap on, fills reuse with `BAADF00D`) | **5 of 5 crashed**, deterministic, ~8 s | **0 of 8 crashed** |
| deployed distro after the fix, subject screen on | — | **0 of 6 crashed** |

`showStage` defaults to `true`, so every one of those runs was in the crashing configuration.
`Binding loop` count was **0** in all 34 runs.

At the measured pre-fix rate of p = 0.81, twenty consecutive clean runs by chance is
0.19²⁰ ≈ **1 × 10⁻¹⁵**. A 45 s ceiling is provably sufficient: every one of the 18 observed
crashes fired within 4.7 s of the stream, and no survivor ever crashed later.


<a id="history-regression"></a>

## Regression

* **691 tests / 22 executables / 0 failures.**
* `Binding loop` **0**.
* Replay of file A (`11_TMS_48MSO_heel_+60.hdf5`): **150 epochs, 0 rejected, labels 50/50/50, 0
  blank**. The epoch file is **bit-identical to the deployed build's on 14 of 16 datasets** —
  including `epochs`, `preproc`, `peak_uV`, `model_id`, `rejected`, `labels`, all `sound/*` and all
  `mep/*`. The two that differ are `latency_ms` and `timestamps`, which are wall-clock and must.
* All four views captured and inspected at 1680×980 and at the 1196×739 minimum window: Processing's
  spin boxes render their digits (`EEG channels` reads **64**), Stimuli still shows Condition,
  Operator and both block rules at the minimum, and `FeedbackView`'s two *not implemented* panels
  read as deliberate rather than collapsed.


<a id="history--the-same-defect-is-still-latent-elsewhere"></a>

## ⚠ The same defect is still latent elsewhere

This is a **framework-wide** pattern, not a four-view one. `tepService` has the identical shape —
`TepService::parameter()` (`src/tepService/service.cpp:2125`) returns unparented parameters to QML,
and `ui/Console.qml:44-45` and `:320-321` fetch them transiently inside binding expressions. It has
not been observed to crash, but nothing structural prevents it.

The durable fix is at the choke point every service shares,
`CommunicationLayer::addParameter()` — but `Core/Resonance` does not link `Qt5::Qml` today, so that
change also drags a new dependency into every service and was deliberately **not** made as part of
this one. It is the right next step.
