# 1. Empty submodules — ✅ RESOLVED 2026-08-11

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-1-empty-submodules---resolved-2026-08-11"></a>

### 1. Empty submodules — ✅ RESOLVED 2026-08-11

**QT 5 ONLY.** The Qt 6 tree has no submodules to be empty: `R:\src` carries no `.git` and no
`.gitmodules`, `3dparty\` holds `thir` and `qml-colors` as ordinary directories, and
`scriptEngines\python` / `scriptEngines\R` are ordinary source. The git indirection was removed
deliberately so the Qt 6 tree has no hidden source dependency on the Qt 5 one
(`R:\src\docs\PORTING_LOG.md`). ⚠ That is also why it has no history — see
[qt6-work-list.md](../migrations/qt6-work-list.md) §5.

**Was:** `R:\src` held a **zip export** downloaded from Gitea, not a clone. A zip carries one
repository's files only — submodule pointers are not files, so the exporter writes a bare empty
directory for each. Verified against `R:\src_legacy\Resonance-feature-conan2-20-08-11.zip`:
966 entries, and exactly **one** entry per submodule path (the directory itself, zero files).
No `.git` either, so git could not even tell you what was missing.

**Fixed by** a proper recursive clone:

```bash
git clone --recursive -b feature/conan2 https://gitea.atedgeof.net/bcilab/Resonance
```

The clone was then swapped into place as `R:\src`; the old export moved aside to
`R:\_src_zipexport_old` (safe to delete — the zip backup remains in `R:\src_legacy\`).
The two trees were **byte-identical** (`diff --strip-trailing-cr -r`, only CRLF differences from
git's `core.autocrlf`), confirming the download had been exactly the branch tip.

* HEAD: `1185960` *"Adjust NVX136 parameters according to feedback"*, Sat 5 Jul 2025
* `git describe --tags` → **`3.4.1-85-g1185960`** (this is what issue 5 needs)

Pinned submodule commits, now recovered:

| Path | Commit | Note |
|---|---|---|
| `3dparty/thir` | `c85482f9` | == `master` — a hand-clone would have been correct |
| `3dparty/qml-colors` | `aa8d453e` | `v1.0-3-gaa8d453` |
| `3dparty/access_private` | `73b1bcda` | |
| `scriptEngines/python` | `e2eed717` | == `master` |
| `scriptEngines/R` | `e0b4b829` | pulls 10 nested submodules of its own (boost pieces, RInside, googletest, thir) |

`.gitmodules` URLs point at **github.com**, not Gitea; all resolved fine. If GitHub access ever
becomes undesirable, mirror them into Gitea and rewrite with `git submodule set-url <path> <url>`.

---

