# 2026-08-15 — `R:\dist\mingw32` rebuilt in full and redeployed

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-15--rdistmingw32-rebuilt-in-full-and-redeployed"></a>

### 2026-08-15 — `R:\dist\mingw32` rebuilt in full and redeployed

The x86 tree **builds end to end again** (40/40) and `R:\dist\mingw32` has been refreshed from it.

The blocker was `quickStimulus/qml_Recorder.cpp:9`: a captureless lambda converts both to
`std::function<void()>` *and* to a function pointer and thence to `bool`, so
`addStream(StreamInfo, QString, std::function<void()>, bool)` and
`addStream(StreamInfo, QString, bool)` were equally good matches — one user-defined conversion
each. GCC rejects that as ambiguous; MSVC accepts it, which is why only the MinGW builds broke.
Fixed at the call site by naming the `std::function` explicitly. The overload pair is still a
trap for the next caller.

Five services verified launching from the deployed tree — `KARDi2`, `SignalGenerator`,
`recorderService`, `quickStimulus`, `COMport`. `recorderService` and the reworked signal-viewer
QML reach the x86 distribution for the first time. Backup of the previously deployed DLL:
`R:\dist\_build\libResonance.dll.mingw32-aug11.bak`.

⚠ `mingw64` is still behind — it has never seen any of this.

