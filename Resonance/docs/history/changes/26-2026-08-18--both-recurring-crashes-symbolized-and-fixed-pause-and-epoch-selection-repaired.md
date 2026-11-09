# 2026-08-18 — both recurring crashes symbolized and fixed; pause and epoch selection repaired

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-18--both-recurring-crashes-symbolized-and-fixed-pause-and-epoch-selection-repaired"></a>

### 2026-08-18 — both recurring crashes symbolized and fixed; pause and epoch selection repaired

**Every crash dump on this machine is now explained.** No debugger exists here, so the analysis
was done by parsing the minidumps, the PE `.pdata` exception directories and the x64 unwind
information directly — the method `workpc-changes.md` E1 (on the lab drive, `R:\docs\_notes\`) used, taken further.

**`playbackService` — five dumps across four sessions, one cause.** All five die inside
`QObject::setProperty`; three share the exact fault offset. A full 22-frame unwind lands on
`PlaybackService::onWorkerReadyRead`, `service.cpp:603` — `socket->setProperty("pending", buffer)`
on a **destroyed** `QLocalSocket`. Proof rather than inference: at the fault the object's vptr
slot held `QObject`'s *own* vtable, which is what is left after `~QObject` has run.

The mechanism is a use-after-free through the read loop. `handleWorkerLine()` is called *inside*
that loop; an `ended` from the last worker sends `stop`, the idle state calls `killWorkers()`, and
that did a synchronous `delete worker->socket` — destroying the socket while its own slot was
still on the stack. Fixed at both ends: `killWorkers()` uses `deleteLater()` for the socket and
the process, and `onWorkerReadyRead()` holds a `QPointer` and bails out if the worker went away
mid-loop.

**`tepService`** faulted at `InputStream::detachThread()+0x11` (`inputstream.cpp:62`),
dereferencing a null `m_thread`. Three paths reach that function — `close()`, the `failed` lambda
and the `closed` lambda — all queued across the stream's thread, so one can still be in the event
queue when another has already reset it. That is an ordinary race, not a teardown-ordering
violation, so the guard returns quietly. ⚠ The exact crashing `Resonance.dll` had already been
overwritten by a later build; the symbol was recovered from 256 bytes of the real faulting code
that the minidump preserved, and a naive same-RVA lookup against either surviving build would
have given a **different and wrong** answer.

**Pause never stopped epoch accumulation.** Measured: 39 epochs arrived during 75 s of "paused",
against 43 while collecting. The `m_paused` state handler only set the label. ⚠ Not a regression
from the threading work — `m_collectingActive` was only ever cleared on `idle`, so the old
GUI-thread gate was equally open while paused. Fixed with a separate `m_acceptingEpochs`, checked
in `onEpochReady`. The worker is deliberately left running through a pause: `Pipeline` assumes a
contiguous sample stream, so starving it would splice a discontinuity into the first epoch after
resuming. Verified: 42 epochs collecting → **0 paused** → 23 after resume.

**Epoch selection was dead, and it is a numbering collision.** The console displays and hands back
each epoch's monotonic **serial**; `EpochStore` addressed epochs by **position** in its 500-deep
ring. The two agree only until the first eviction — after which clicks selected the wrong epoch,
and once every visible serial exceeded `count()` (about a thousand stimuli on a 500 buffer) the
bounds check rejected them all. Right-click reject was broken identically. The store's public
interface now takes serials throughout (`at`, `remove`, `setRejected`, `averageOf`), with
`indexOfSerial()` the one place the two schemes meet.

⚠ **Two defects in yesterday's display-lowpass move, found by review and fixed.** Moving that
filter into the continuous cascade put it over **every** signal channel — but the per-epoch filter
it replaced touched only the EEG, and `extractMep()` never lowpassed at all. The EMG pair was
being band-limited at 250 Hz: −4.9 dB at 300 Hz, and on a synthetic burst peak-to-peak fell to
0.81× and baseline RMS to 0.31×, moving the onset too. **Every MEP number would have changed as a
side effect of a display setting.** It is now a second filter over the EEG columns only. Separately,
`reprocess()` re-enabled the per-epoch filter that `reconfigure()` had just switched off — and
`reconfigure()` calls `reprocess()` — so the EEG was being filtered **twice**.

**`TcpStreamReceiver`'s stall was misdiagnosed in the docs and is now fixed.** The blocking
`waitForConnected(3000)` does **not** run on the GUI thread; it runs on the capsule's worker. The
GUI thread stalls because it *joins* that worker — `~ThreadCapsule` is `quit(); wait();`, an
unbounded join against a thread parked in a wait `quit()` cannot interrupt. `ThreadCapsule::retire()`
is the same teardown without the wait, and `StreamPool` now hands out capsules with a deleter that
uses it.

**323 unit tests across 11 suites, all passing**, including new coverage for each of the above:
serial-vs-position addressing, and that a strided filter leaves the trailing channels untouched.

New document: **[new-pc-setup.md](../migrations/new-pc-setup.md)** — what to install on a fresh machine, with
versions, links, the exact Conan profiles and a verification checklist. ⚠ Its headline finding is
not a package: **`R:\src` cannot be reproduced by `git clone`** — `Core`, `quickStimulus`,
`tepService`, `playbackService` and a dozen more modules are untracked, along with every vendored
vendor SDK. The tree must be copied as files.

