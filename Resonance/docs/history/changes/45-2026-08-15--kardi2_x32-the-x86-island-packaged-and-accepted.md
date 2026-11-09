# 2026-08-15 — `kardi2_x32`: the x86 island, packaged and accepted

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-15--kardi2_x32-the-x86-island-packaged-and-accepted"></a>

### 2026-08-15 — `kardi2_x32`: the x86 island, packaged and accepted

**`R:\dist\kardi2_x32.zip`** (13.1 MB, 33 MB unpacked; staging tree at `R:\dist\kardi2_x32\`).
Drop the folder into a distribution root beside `bin\`, `qt\` and `data\` — or run it anywhere
else, including another PC. Operator instructions in its `README.txt`; design and evidence in
[kardi2.md §8](../components/kardi2.md).

Contents: `KARDi2.exe`, the vendor `KARDi2.dll`, 32-bit `libResonance.dll`, four Qt 5.15.2 DLLs,
three MinGW runtime DLLs, the unmodified vendor USB driver (amd64 + i386), and a launcher.

**It does not interfere with an x64 tree.** Windows searches an executable's own directory before
`PATH`, so with every 32-bit DLL beside `KARDi2.exe` the service resolves its own Qt and
Resonance even when the x64 `bin\` and `qt\` are first on `PATH`. `KARDi2.bat` sets no `PATH` and
calls no `env.bat`. The names do not collide either — x64 ships `Resonance.dll`, x86 ships
`libResonance.dll`. Environment requirement is nil: the only variable `Core` reads is
`RESONANCE_RECORD_PATH`, for recording.

| Check | Result |
|---|---|
| `PATH` stripped to `System32` only | ✅ reaches `init` |
| 32- and 64-bit `Qt5Core.dll` in one tree, **x64 first on `PATH`** | ✅ starts — the x64 copy would give `0xC000007B`, so starting is the proof |
| x64 `recorderService` discovers it | ✅ matched the x86 service's UUID |
| Unpacked from the archive into `R:\dist\msvc64\`, launched via `KARDi2.bat` with the x64 env active | ✅ running, x64 recorder alongside, discovery active |

The test copy was removed afterwards; `R:\dist\msvc64` is unchanged. Still **no KARDi2 hardware**,
so everything past device enumeration remains unverified.

