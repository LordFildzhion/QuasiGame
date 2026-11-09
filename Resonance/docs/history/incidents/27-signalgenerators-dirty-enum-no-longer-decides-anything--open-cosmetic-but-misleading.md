# 22. `signalGenerator`'s `Dirty` enum no longer decides anything — open, cosmetic but misleading

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-22-signalgenerators-dirty-enum-no-longer-decides-anything--open-cosmetic-but-misleading"></a>

### 22. `signalGenerator`'s `Dirty` enum no longer decides anything — open, cosmetic but misleading

**TRANSFERS UNCHANGED — identical in both trees.** `R:\src\SignalGenerator\service.cpp` carries the
same **55** `StructureDirty` references against **14** `ContentDirty`, as does
`R:\src_Qt5\SignalGenerator\service.cpp`. The recommendation below is unchanged and undone in both.

Noted 2026-08-20 while closing the viewer epoch work. Not a defect in behaviour; a trap for the
next reader.

Since §21's fix, `Service::onApplyPending()` tests `m_dirty` only for `== NothingDirty` — "did any
parameter change at all". The decision that actually matters, *does this stream's announcement
differ*, is made inside `publishAll()` by comparing descriptions. So the `ContentDirty` /
`StructureDirty` distinction has **no effect on anything**: `service.cpp` carries **55**
`StructureDirty` references against **14** `ContentDirty`, and roughly thirty of the
`StructureDirty` ones are on parameters that demonstrably do not change any announcement
(`epochAmplitude` and `epochSpread` are the ones §21 measured).

**Recommendation: delete the enum rather than re-classify the parameters.** Re-classifying thirty
bindings is thirty chances to get one wrong, and a wrong classification would be invisible — the
flag is not consulted. `markDirty()` needs one bit ("something changed, coalesce a re-apply") and
`bind()` can drop its `dirty` argument entirely. Anything that *does* need the structural/content
distinction should ask `publishAll()`, which is the only place that can answer correctly.

⚠ Until then, do not read a `StructureDirty` binding as a statement that the parameter rebuilds a
stream. It is not one, and on this generator it is usually false.

---

