# ⚠ How to read this file since the Qt 6 swap

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history--how-to-read-this-file-since-the-qt-6-swap"></a>

### ⚠ How to read this file since the Qt 6 swap

There are two trees now: **Qt 6.11.2 at `R:\src` / `R:\dist`, the default**, and **Qt 5.15.2 at
`R:\src_Qt5` / `R:\dist_Qt5\msvc64`**, the comparator and the only home of the remaining legacy services.
See [qt5-to-qt6-transition.md](../migrations/qt5-to-qt6-transition.md) for what moved and
[qt5-still-needed.md](../migrations/qt5-still-needed.md) for why the old tree stays. Every section below was
written against the Qt 5 tree, so each now carries a status line saying which tree it applies to:

| marker | means |
|---|---|
| **FIXED BY THE PORT** | gone in `R:\src` / `R:\dist`. Usually still live in the Qt 5 comparator |
| **TRANSFERS UNCHANGED** | same code, same rule or same hardware behaviour in both trees. On a ✅ entry it means the fix crossed too |
| **QT 5 ONLY** | cannot arise under Qt 6 — the code, the toolchain or the module is not there. Kept because the comparator is still built and still run |
| **QT 6 ONLY** | port-introduced, or a Qt 6 API change. Does not exist under Qt 5 |
| **UNKNOWN UNDER QT 6** | not re-measured since the port. Treat as live in both trees until someone measures it |

⚠ **A marker is a disposition, not a verdict on the text under it.** Nothing dated was rewritten: a
line saying "built and deployed to `R:\dist\msvc64`" was true on its date, and that path is today
`R:\dist_Qt5\msvc64`. The same holds for every evidence pointer below shaped
`R:\dist\_build\<name>\`: that whole build tree is now `R:\dist_Qt5\_build\<name>\`, and
`R:\dist\_build` does not exist — the Qt 6 tree builds inside `R:\src\_build`. Only present-tense
instructions and runnable commands were corrected.

Defects that exist only under Qt 6 are collected in
[§25](21-qt-6-only-defects-found-during-and-after-the-port.md#history-25-qt-6-only-defects-found-during-and-after-the-port), placed between the operational
gotchas and the dated defect log so nothing above it is renumbered.

---

