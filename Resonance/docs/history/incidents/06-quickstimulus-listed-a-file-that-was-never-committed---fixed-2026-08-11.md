# 2c. `quickStimulus` listed a file that was never committed — ✅ fixed 2026-08-11

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2c-quickstimulus-listed-a-file-that-was-never-committed---fixed-2026-08-11"></a>

### 2c. `quickStimulus` listed a file that was never committed — ✅ fixed 2026-08-11

**FIXED BY THE PORT.** No `Head.qml.bak` anywhere in `R:\src\quickStimulus\CMakeLists.txt`.

```
CMake Error at quickStimulus/CMakeLists.txt:8 (add_library):
  Cannot find source file: import/Resonance/Bricks/Head.qml.bak
```

`Head.qml.bak` appears in the `add_library` source list but `git log --all --` on that path
returns nothing — it only ever existed on the author's machine. So `quickStimulus` has **never
configured from a clean checkout** under CMake. Line removed; a `.bak` file has no business in
a build anyway.

Another piece of evidence that the CMake port was never exercised end-to-end before now.

---

