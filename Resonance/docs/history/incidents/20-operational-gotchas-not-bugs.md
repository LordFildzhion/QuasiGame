# 11. Operational gotchas (not bugs)

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-11-operational-gotchas-not-bugs"></a>

### 11. Operational gotchas (not bugs)

**Mixed — marked per bullet.** The bullets that changed shape are the MinGW `PATH` warning, the
network-mode rule, `PYTHONHOME` and the launcher note; the rest transfer verbatim, including
`--console`, the `StreamPool` retry timer and the loopback default.

* **Never put both MinGW `bin` dirs on `PATH` at once.** Cross-linking 32/64-bit objects
  produces error messages that look nothing like the actual cause. *(QT 5 ONLY for the 64-bit
  half: the Qt 6 tree uses no MinGW x64 at all. `mingw810_32` is still on the machine for the
  KARDi2 x86 island, so the trap survives in the x86 direction.)*
* **Discovery is confined to this machine by default** (since 2026-08-18; the entry here used
  to read "Discovery is LAN-wide" and no longer applies). UDP 13370 binds `127.0.0.1`, the
  13371 multicast socket is not created at all, discovery goes to `127.255.255.255`, and a
  datagram from a non-loopback source is dropped. Two rigs on one subnet do **not** find each
  other. To opt in: `{"networkMode": "lan"}` in `resonance.cfg`, or `--networkMode lan`.
  ⚠ `resonance.cfg`'s `hostIPs`/`hostNames` change only what is **advertised**, never what is
  bound, and `portRangeBegin/End` are dead code — see
  [network-isolation.md](../migrations/network-isolation.md).
* ⚠ **One network mode per machine, across BOTH distributions.** *(TRANSFERS UNCHANGED — restated,
  because the tree list is what changed.)* A `lan` service advertises only its LAN addresses and a
  `loopback` consumer refuses all of them; neither receives the other's datagrams either. Which
  trees know about `NetworkMode` at all, measured 2026-09-02 by looking for the string in each
  tree's `Resonance.dll`/`libResonance.dll`:

  | tree | `NetworkMode`? |
  |---|---|
  | `R:\dist` (Qt 6, the default) | ✅ |
  | `R:\dist_Qt5\msvc64` | ✅ |
  | `R:\dist_Qt5\msvc64\bin.pre-*` — ten rollbacks, all dated 2026-08-25 or later | ✅ |
  | `R:\dist\kardi2_x32` — rebuilt from the current core | ✅ |
  | `R:\dist_2026aug\msvc64-lanIsolation` | ✅ |
  | `R:\dist_2026aug\msvc64`, `R:\dist_2026aug\kardi2_x32`, everything in `R:\dist_legacy` | ❌ permanently `lan` |

  ⚠ **The new hazard is the pair, not the rollbacks.** A Qt 5 service out of `R:\dist_Qt5\msvc64`
  and a Qt 6 service out of `R:\dist` are *designed* to interoperate — the wire protocol did not
  change — and a laboratory session may still need one of each while the legacy `sp_*.qml`
  paradigms run only in the Qt 5 host. They must be given the **same** network mode explicitly, or the split reads as a discovery
  fault. Mixing them gives a split service tree. Restart every service together after a deploy.
* ⚠ **`StreamPool`'s retry timer never starts in most services.** `StreamPool` is a value
  member of `ResonanceAppPrivate`, so it is constructed before the `QCoreApplication` exists in
  the services that build `ResonanceApp` first — `QObject::startTimer` then refuses with
  *"Timers can only be used with threads started with QThread"*, the message at the top of
  every service log. Discovery still runs, driven by `discoverStream()` and by stream state
  changes. Pre-existing; it matters slightly more now, because a request whose candidates are
  all refused has nothing left to re-enter the cycle.
* **Services are `WIN32` subsystem** — no console, so `qDebug()` goes nowhere visible *unless
  one is asked for*. Since 2026-08-19 every service takes **`--console`**, and any running service
  can be given one from the Configurator (**System → Show console**, in the parameter panel
  beside the service's own transitions, which sends `!showConsole`) — [architecture §11c](../migrations/framework-evolution.md). The older routes still work:
  `R:\Dbgview.exe` (already on the drive) shows every service at once, or set
  `QT_FORCE_STDERR_LOGGING=1` **and** genuinely redirect stderr. ⚠ The first line every service now prints is the one that says whether it
  can talk to anything off this machine —
  `Resonance network mode: loopback - discovery, listeners and dialling are confined to this
  machine` — and without one of those two routes it is invisible.
* **`env.bat` sets `PYTHONHOME=%CD%\python` for a directory that may not exist.** *(FIXED BY THE
  PORT in `R:\dist`, still live in `R:\dist_Qt5\msvc64`.)* `R:\dist\env.bat` guards it —
  `if exist "%CD%\python\python312.zip"` — and the directory is really there: a private CPython
  3.12.1 with NumPy 1.26.2 and SciPy, which is what SPEED runs on.
  ⚠ `R:\dist_Qt5\msvc64\env.bat:29` still sets it unconditionally and
  **`R:\dist_Qt5\msvc64\python` does not exist**, so the comparator's SPEED has no usable
  interpreter. Any tree you assemble should ship an embedded CPython there or drop the line.
* **The `.bat` launchers `cd bin` then `start X`** — so services always run with the working
  directory `<distro>\bin`. Several drivers rely on this
  (`QDir::setCurrent(applicationDirPath())` in `nvx136`, `actiChamp`, `DAQmx`) to find their
  `.bit` firmware files. *(TRANSFERS UNCHANGED. The Qt 6 launchers do it location-independently —
  `call "%~dp0env.bat"` then `cd /d "%RESONANCE_DIR%\bin"` — where the Qt 5 ones use bare
  `call env` / `cd bin`; see §19e.)*

---

