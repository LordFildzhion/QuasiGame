# 2e. `pythonengine.cpp` uses `stdout` as a variable name — ✅ patched locally, needs upstreaming

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2e-pythonenginecpp-uses-stdout-as-a-variable-name---patched-locally-needs-upstreaming"></a>

### 2e. `pythonengine.cpp` uses `stdout` as a variable name — ✅ patched locally, needs upstreaming

**FIXED BY THE PORT, and the "needs upstreaming" is void.**
`R:\src\scriptEngines\python\pythonengine.cpp:197` is now `py::class_<StdIOHook>(m, "stdout")` —
no variable at all, so the `<stdio.h>` macro has nothing to expand onto. There is no submodule to
upstream to either: the Qt 6 tree carries the engine as ordinary source (§1).

`scriptEngines/python/pythonengine.cpp:197`:

```cpp
py::class_<StdIOHook> stdout(m, "stdout");   // stdout is a <stdio.h> macro
```

⚠ **The record above is wrong about which fix landed, and it has been misleading a verification
step.** It says the local was renamed to `stdoutHook`. It was not: both trees read
`py::class_<StdIOHook>(m, "stdout")` at `:197` — the object is an unnamed temporary, so there is no
variable for the macro to collide with, and the identifier `stdoutHook` appears **nowhere on the
drive**. Any check written as `grep -n stdoutHook` therefore reports *failure on a healthy tree*;
`build_new-pc-setup.md` and `build_dev-environment.md` were corrected on 2026-09-02 to grep for
`channel_properties` instead.

The submodule half still stands for the comparator: in `R:\src_Qt5` the edit lives in the
`scriptEngines/python` submodule working tree, so `git submodule status` shows it modified (`m`
flag) and it is not covered by any commit. It must be committed to `Resonance-engine-python` and
the pointer bumped, or it will be lost on the next `git submodule update`. `R:\src` carries the
engine as ordinary source and has no submodule at all.

See open question 1 in §0 — it is not clear how the shipped DLL was ever built from this code.

---

