# Field bugs from the 2026-08-21 experiment — task, ETA, assumptions — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../issues/README.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-field-bugs-from-the-2026-08-21-experiment--task-eta-assumptions"></a>


**Handed over 2026-08-22 ~01:30, operator AFK.** Today's session was a success — tepSound filtered
online correctly. These are **bugs in wrongly realised features**, found in the field. UI ergonomics
are explicitly deferred to a later pass.

The operator's framing on item 1 sets the standard for the whole batch:
> *"I want this fixed in principle, across the board. **Parameters that are silently not loaded
> cant happen.**"*


<a id="history-the-seven-items"></a>

## The seven items

| # | item | area | state |
|---|---|---|---|
| 1 | `--serviceConfig` loads an incomplete parameter set — 2 of 3 stream slots empty; manual load of the same JSON populates them | Core / parameters | in flight — `wf_50a94bf4-c14` |
| 5 | SPEED script publishes epochs; viewer shows a concatenated strip. Needs WAS → SUPPOSED-TO-BE instructions for a colleague | SPEED / epoch contract | in flight — same workflow |
| 7 | `test_online_tepsound.hdf` will not replay as epochs in the viewer | recorder / playback / viewer | in flight — same workflow |
| 6 | offline verification of today's experiment against the online output | tepSound | in flight — `wf_d2f3fdc8-3db` |
| 3 | channel checkmark lists ghost and mis-update on scroll | parameters UI | **done** — view bug only, the selection was always right; proof in `field-bugs-20260822.md` |
| 2 | spurious "some parameters were wrong" warning when loading just-saved params | parameters UI | **done** — reproduced (a service-side write inside the 700 ms check window), removed, and real refusals are now named |
| 4 | playback: click/drag the progress bar to seek to any time | playbackService | queued |

⚠ **3 and 2 are held until item 1's fix lands** — both touch the parameter path and a concurrent edit
would collide. **4 is held until item 7's diagnosis lands**, because that may put a fix in
`playbackService` too.

✅ **RESOLVED — the tree carries no unbuilt code.** The three parameter-panel loose ends were
built, click-tested and deployed on 2026-08-22 at 11:53 (rollback
`bin.pre-paramui-20260822-115315`). The `implicitWidth` binding loop is gone (1 warning → 0) and
the unlabelled tab bar is replaced by a wrapping group selector, both confirmed on screen. The
negative delegate-model size was a **wrong guess**: the speculative clamp in `Plot/PlotView.qml`
was **rolled back**, and the warning is now traced to a defect in Qt's own
`Private/BasicTableView.qml` (`rowfiller` feeds `viewport.height − contentHeight`, negative
whenever content overflows, straight into a `Repeater`). It is harmless console noise in someone
else's file. Details in `field-bugs-20260822.md`, "The three loose ends in the parameter panel".


<a id="history-eta--811-h-wall-clock-with-two-workflows-in-parallel"></a>

## ETA — ~8–11 h wall clock with two workflows in parallel

| block | est. |
|---|---|
| 1 + 5 + 7 — the stream-contract cluster (running) | 3–4 h |
| 6 — offline verification (running, parallel) | 2.5–3.5 h |
| 3 + 2 — checkmark ghosting and the spurious warning | 3–4 h |
| 4 — playback seek | 2–3 h |

Serial estimate is 11–14 h; the first two overlap, so ~8–11 h.


<a id="history--assumptions-i-am-making-so-they-can-be-corrected-rather-than-discovered"></a>

## ⭐ Assumptions I am making, so they can be corrected rather than discovered

1. **Item 6 means equivalence, not a better analysis.** Reprocess with *the session's own settings*
   and compare numbers against the online output. An offline average that merely looks like a TEP
   proves nothing.
2. **`12_52MSO_TMS_BCI.hdf5` is the raw file behind `test_online_tepsound.hdf`.** Being verified by
   evidence — RTC spans, trigger instants, pulse counts — not assumed from the filenames. If it is
   not, the sibling files get scanned for the one that is.
3. **Item 1 gets both halves**: the dropped streams are actually restored, *and* any parameter that
   cannot be applied is named to the operator. The second half is the stated requirement and holds
   even where the value genuinely cannot be restored.
4. **Item 5's deliverable is instructions**, not an edit to the colleague's script — unless the gap
   turns out to be in *our* SPEED binding (e.g. no way to set per-channel MetaData at all), in which
   case that gets fixed here.
5. **Item 4 = click to seek and drag to scrub**, working both before and during playback.
6. ✔ **CONFIRMED BY MEASUREMENT, not left as an assumption.** Item 3's ghosts are a view bug, not
   a state bug — the operator's own evidence is that they
   vanish on reload, so the model is right and the delegate is wrong. ⚠ If the underlying state
   turns out to be genuinely wrong, that is far more serious (it would mean recording the wrong
   channels) and gets escalated at the top of the report.
7. **Verify against the binary the session actually ran on** — the deployed tree at `R:\dist\msvc64`,
   not a newer build — or the verification proves something about tonight instead of about today.


<a id="history-rules-carried-in"></a>

## Rules carried in

⚠ The two experimental recordings are **irreplaceable human-subject data: READ-ONLY**, output to
`R:\dist\_build\offline-verify\`.
⚠ **Speed 1 only** for any reported number — `scaleRate` defaults false, so at any other speed every
RTC-to-sample conversion is silently off by `speed`.
⚠ **Console up ~10 s before the first pulse**, or the first ten epochs carry an IIR settling
transient (measured 1758 → 191 → 52 → 3.5 → 0.12 → 0 µV) that moves the median and trips the
bad-channel detector.
⚠ **Do not "correct" the trigger polarity** to match `report_trigger-validation.md` — that document
is wrong for this rig. But re-verify polarity from *this* session's data; it is a different session.
⚠ Build with `chcp 65001` after vcvarsall, target `all`, -j6, MSVC v142. `robocopy /E`, never `/MIR`
— 15 deploy-only items would be destroyed. Baseline **647 tests / 19 executables / 0 failures**.
