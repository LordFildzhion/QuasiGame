# Single-PC network isolation — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../architecture/network.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-single-pc-network-isolation"></a>


**Implemented 2026-08-18.** Assessed in an earlier session, built and measured in this one.
Reference for `NetworkMode` in `Core/Resonance` — `R:\src\Core\Resonance` in the Qt 6 default tree,
`R:\src_Qt5\Core\Resonance` in the comparator. Read
[architecture.md §3](framework-evolution.md) first for what discovery is.

**Status 2026-09-02 — the design carried into Qt 6 unchanged, and this is one of the port's quieter
successes.** Every mechanism below is present in the Qt 6 core, comment for comment: the loopback
bind and the deleted multicast socket (`communicationlayer.cpp:107`, `:132`), fail-closed
`parseNetworkMode` (`ResonanceApp.cpp:247`), the two dial guards
(`internal/TcpStreamReceiver.cpp:106` and `:130`), and the peer check on the accepted TCP socket
(`internal/TcpStreamSender.cpp:80`). **The default is still `loopback` in both generations, the
opt-in is still `--networkMode lan`, and the wire protocol did not change** — which is why a Qt 5
service and a Qt 6 service discover and drive each other
([`build_qt5-to-qt6-transition.md` §9](qt5-to-qt6-transition.md)). ⚠ Both sides must be in
the *same* mode; see the two-modes gap in [§6](network-isolation.md#history-known-gaps-deliberately-left), which applies across
generations exactly as it does within one.

⚠ **Deployment paths in the dated records below have moved.** Everything written `R:\dist\msvc64`
in §7, §8 and §8.1 was measured on 2026-08-18 against the tree that is today
**`R:\dist_Qt5\msvc64`**. The Qt 6 distribution is `R:\dist`, with `bin\` at its root and no
`msvc64\` level at all.

---


<a id="history-0-state-of-play"></a>

## 0. State of play

| | |
|---|---|
| Default mode | **`loopback`** — nothing leaves or enters this machine. Unchanged in Qt 6 |
| Opting out | `resonance.cfg` `"networkMode": "lan"`, or `--networkMode lan` per process |
| Scope | `Core/Resonance` only. No service module changed; the framework does it for all of them |
| Announced | every service says its mode on the first line of its log, every start |
| Tests | `test_NetworkMode`, run three ways (default / loopback / lan). ⚠ **Built in both trees, registered with CTest in neither**, so it only runs when someone runs it — [§7.4](network-isolation.md#history-74-unit-tests) |
| Built *(Qt 5, 2026-08-18)* | MSVC v142 x64, 185/185 targets |
| **Deployed** *(Qt 5, 2026-08-18)* | 07:48 to what is now `R:\dist_Qt5\msvc64`. Accepted on the live NVX-52 and every module with a signal — [§8.1](network-isolation.md#history-81-acceptance-on-the-deployed-tree) |
| **Qt 6** | Ships in `R:\dist` and is the default there too. Cross-generation interop verified in both directions — [§8.2](network-isolation.md#history-82-the-qt-6-tree-and-cross-generation-interop). ⚠ No live-amplifier acceptance run under Qt 6 yet |

**The short version.** A Resonance process used to broadcast its existence to 255.255.255.255,
listen for streams on every interface, accept a service announcement from any host that sent one,
and dial back whatever address that announcement came from. It now does none of those things
unless told to.

---


<a id="history-3-why-127255255255-and-not-127001"></a>

## 3. Why `127.255.255.255` and not `127.0.0.1`

This is the one design decision the whole thing rests on, and it was measured before it was
written. Every Resonance service on a host holds port 13370 with `ShareAddress`, so the question
is what a datagram addressed to loopback does when several sockets share the port.

Two sockets on `13999` with `SO_REUSEADDR`, one datagram each:

| sent to | sock0 | sock1 | source seen by the receiver |
|---|---|---|---|
| `127.255.255.255` | ✅ | ✅ | `127.0.0.1` |
| `255.255.255.255` (what it used to do) | ✅ | ✅ | **`172.20.144.1`** |
| `127.0.0.1` | ✅ | ❌ | `127.0.0.1` |

Three things follow.

**Unicast to loopback is wrong.** It reaches exactly one of the sockets sharing the port —
whichever the stack picks — so discovery would find one service at random. Only the directed
broadcast reaches all of them.

**⚠ The source address is why the guard can be simple.** A locally looped 255.255.255.255 datagram
arrives with the *sending interface's* address — here `172.20.144.1`, the Hyper-V vSwitch, not
`127.0.0.1`. Under the old arrangement a receiver could not tell a local announcement from a remote
one without enumerating its own interfaces, and enumeration is exactly what makes behaviour depend
on which adapters are up. Sent to `127.255.255.255` the source is `127.0.0.1`, so "is this local?"
is a plain loopback test with nothing behind it. **Goal 3 falls out of the choice of goal 1's
mechanism**, rather than needing its own machinery.

Two further properties, measured separately:

* `127.255.255.255` is delivered **without** `SO_BROADCAST` being set, so nothing depends on Qt's
  socket-option defaults;
* a socket bound to `127.0.0.1` does **not** receive a LAN-interface broadcast, while one bound to
  `0.0.0.0` does — which is goal 2 at the socket layer.

Harness: `C:\...\scratchpad\loopback_bcast.py` (reproduced in [§7](network-isolation.md#history-7-evidence)).

---


<a id="history-4-what-changed"></a>

## 4. What changed

<a id="history-resonanceapp--the-mode-and-when-it-is-decided"></a>

### `ResonanceApp` — the mode, and when it is decided

`NetworkMode::Loopback | Lan`, resolved **once**, in this order: default → `resonance.cfg`
`"networkMode"` → `--networkMode`. Nothing may change it afterwards, because the sockets are bound
from it and a mode that could move would describe something other than what is open.

⚠ **The ordering was the delicate part.** `setDefaultSettings()` used to fill `hostIPs` by walking
`QNetworkInterface`, and it runs *before* the config file is read and long before the command line
is parsed. It no longer fills the address lists at all; `finaliseAddresses()` does that after both
inputs are in, and it is placed between `parser.process()` and the `CommunicationLayer`
constructor, which is the only window where both facts are known and no socket is open yet.
In `R:\src\Core\Resonance\ResonanceApp.cpp` that is `parser.process()` at `:408`,
`finaliseAddresses()` at `:425`, the `CommunicationLayer` at `:468`; in `R:\src_Qt5`'s copy the same
three sites are `:407`, `:424`, `:467`. The arrangement is identical in both generations — only the
line numbers moved, and they moved again after the 2026-08-18 write-up, which cited `:214`/`:224`.

An explicit `hostIPs` / `hostNames` in `resonance.cfg` still wins over the mode's choice — tracked
by `hostIPsExplicit` / `hostNamesExplicit`, because "empty" cannot carry that distinction:
empty is also what loopback mode wants for `hostNames`.

In loopback mode `hostIPs` is `{127.0.0.1}` and `hostNames` is empty. The second half matters:
this machine's name resolves to a LAN address, so advertising it would publish a URL that cannot
be dialled — and it **would** be tried, because candidates are attempted in list order. Leaving it
empty also means a stream advertises exactly one connection, which is what `StreamPool::openStream`
requires (`if (info.connections().length() != 1) return nullptr;`).

<a id="history-communicationlayer--binds-target-and-the-source-guard"></a>

### `CommunicationLayer` — binds, target, and the source guard

* 13370 binds `127.0.0.1` instead of `0.0.0.0`. `ShareAddress | ReuseAddressHint` is kept — it is
  what lets every service on the host hold the port at once.
* the multicast socket is **not created** when isolated.
* announce and `identify` go to `discoveryTarget()`.
* `broadcastMessage()` drops a datagram whose source is not permitted, before anything is parsed.

⚠ **Removing the multicast socket removes nothing that worked.** `joinMulticastGroup` sits inside
the bind-**failure** branch:

```cpp
if (!d->multicast->bind(QHostAddress::AnyIPv4, 13371, ...)) {
    d->multicast->joinMulticastGroup(QHostAddress("224.0.0.1"));   // only when bind FAILED
}
```

so on the normal path the group has never been joined and that socket has never received a
multicast datagram. What it did do is *transmit* to 224.0.0.1 on every announce, which leaves the
machine — so deleting it is a goal-2 win, not a loss. **In `lan` mode it is left exactly as
found**, bug included: repairing the join would silently switch on a second ingest channel that
nothing has ever been tested against.

<a id="history-the-dial-path--two-guards-deliberately"></a>

### The dial path — two guards, deliberately

`isDialPermitted()` filters candidates in `StreamPool::createPotentialConnections()`, and
`TcpStreamReceiver::open()` checks again immediately before `connectToHost`.

The duplication is on purpose. The candidate filter keeps a refused address out of the retry
queue, where it would otherwise cost a 3 s connect timeout on every cycle for ever; the dial-site
check is the invariant, at the one point every path converges on, so a future caller that builds a
receiver directly cannot route around it.

A host that is a *name* rather than a literal is permitted only if it is `localhost`. Resolving
anything else would block the thread, and a name that resolves off-box is precisely what this mode
refuses.

---


<a id="history-5a-six-defects-found-by-review-after-it-all-worked"></a>

## 5a. Six defects found by review, after it all worked

The measurements in [§7](network-isolation.md#history-7-evidence) passed before this review ran, which is the point of
recording it: every one of these was invisible to a test that only asked "is the machine
isolated?".

| | Found | Fixed |
|---|---|---|
| **`TcpStreamReceiver` refused host names in *`lan`* mode.** `isPermittedPeer()` short-circuits to true when not isolated, so the IP branch was right — but the *named* branch consulted the mode nowhere, and `lan` mode advertises `tcp-ip://<hostname>:<port>` as its third candidate. It logged "this service is in loopback mode" while in LAN mode. Hidden in ordinary use because IPs are tried first, so the multi-homed case host names exist for was the case that broke | 3 of 4 lenses | `!isIsolated() \|\|` added, and re-tested live: a LAN consumer dialling `anatolyhome2024` now gets **1000 blocks** where it got 0 |
| **`playbackService` did not pass the mode to its workers.** `playbackSource` is a separate process that resolves its own mode, so `--networkMode lan` on the parent spawned loopback children. The control channel is a named pipe, so they start, connect and report "playing" — only their published streams are wrong | ✔ | forwarded explicitly |
| **A typo in `--networkMode` was fail-*open*.** `parseNetworkMode` left the mode untouched on a bad value, so on a rig whose `resonance.cfg` said `lan`, `--networkMode lopback` kept **lan** — the misspelling of the safety knob resolving to the open state | ✔ | an unparseable value now forces `Loopback` and says so |
| **A failed bind left the socket on every interface.** `QUdpSocket::writeDatagram` on an *unbound* socket implicitly binds it to `QHostAddress::Any` — so a failed loopback bind, which only logged a warning, would have left the process listening on all interfaces | ✔ | isolated mode deletes the socket and gives up discovery instead |
| **The path that executes commands had no peer check.** Discovery got two guards, but discovery only ever *leads* to `CommunicationLayer::clientRequest`; the accepted TCP socket that actually carries `!terminate` had none | ✔ | `clientConnected()` aborts a connection from a peer the mode forbids |
| **`localhost` was trusted by name.** It is permitted without resolving — resolving would block the thread — so a hosts-file entry pointing it off-box was the last outbound escape | ✔ | the address actually reached is re-checked after connect |

And one that is a **log** defect rather than a security one: a refused URL was re-created by the
1 s discovery cycle for ever, and `InputStream(info, 0, …)` never times out, so the first version
emitted two to three identical warnings a second indefinitely. Now announced once per URL —
measured, 39 lines → 1.

**All six are present in the Qt 6 core** — checked file by file on 2026-09-02, and the ⚠ comments
that record *why* each fix is shaped as it is came across verbatim. That follows from the
provenance rather than being a surprise: the Qt 6 tree was snapshotted on 2026-08-27 from `fae69c3`
on `feature/services-and-isolation`, which is the branch this work was committed on and is still the
comparator's checked-out tip ([`build_branch-inventory.md`](branch-inventory.md)). What the
snapshot did *not* pick up is `R:\src_Qt5`'s 14 uncommitted working-tree changes — but those are all
under `neuroMS/`, `nvx136/` and `scriptEngines/`, so none of them is an isolation fix.

| | Where it is, under `R:\src` |
|---|---|
| the `!isIsolated()` term on the named-host branch | `Core/Resonance/internal/TcpStreamReceiver.cpp:106` |
| `playbackService` forwards the mode to `playbackSource` | `playbackService/service.cpp:663-666`, with the ⚠ comment at `:657-662` |
| an unparseable `--networkMode` forces `Loopback` | `Core/Resonance/ResonanceApp.cpp:247`, applied at `:414` |
| a failed isolated bind deletes the socket and gives up discovery | `Core/Resonance/communicationlayer.cpp:111-121` |
| the accepted TCP socket checks its peer | `Core/Resonance/internal/TcpStreamSender.cpp:80` |
| `localhost` is re-checked against the address actually reached | `Core/Resonance/internal/TcpStreamReceiver.cpp:130` |

---


<a id="history-6-what-this-does-not-protect-against"></a>

## 6. What this does not protect against

* **Anything already on this machine.** Isolation is a machine boundary, not a process one. Any
  local program can still speak the protocol on 127.0.0.1 and terminate a service; the EventBus is
  still unauthenticated. If that matters, authentication is a separate piece of work.
* **`lan` mode.** It is unchanged, deliberately, so that it remains a faithful control — which
  also means every hazard in [§1](../../architecture/network.md) applies in full.
* **A service module's own sockets.** `arduinoTTL`, `eStim` and `feetStim` each open a UDP command
  channel (`service.cpp` ~1742 / ~1830 / ~1678 — the same three lines in both trees). They already
  bind `QHostAddress::LocalHost` and are off by default, and `NetworkMode` deliberately does not
  touch them: they are device I/O speaking a rig's own grammar, not Resonance discovery.
* **The absence of a firewall.** Windows Firewall is off on all three profiles here. That is
  outside this change, but it is why the bind addresses had to be the mechanism rather than a
  belt-and-braces extra.

<a id="history-known-gaps-deliberately-left"></a>

### Known gaps, deliberately left

⚠ **Two modes on one machine do not interoperate.** A `lan`-mode service advertises only its LAN
addresses — `finaliseAddresses()` skips loopback interfaces and falls back to `127.0.0.1` only
when the list comes out empty — and a `loopback` consumer refuses all of them. Discovery fails in
both directions independently, because neither socket receives the other's datagrams. So putting
*one* service in `lan` mode to reach a second PC cuts it off from every local consumer. Measured:
during this session's runs, three LAN-mode services were live continuously and every loopback run
in that window discovered only itself. **Choose one mode per machine.** (Making the LAN branch
always include `127.0.0.1` would fix the advertisement half but not discovery, so it was not
done — a half fix here reads as a working configuration.)

⚠ **The same gap decides mixed Qt 5 / Qt 6 rigs.** Generation has nothing to do with it — a
`loopback` Qt 6 Configurator and a `loopback` Qt 5 service on this PC find each other, and a
`lan` service of either generation is invisible to a `loopback` consumer of either. **Choose one
mode per machine, not one mode per tree.** Across machines, every launcher on both sides needs
`--networkMode lan`.

⚠ **`ResonanceForeignDriver` cannot be configured at all.** `lib.cpp` builds the app with
`argc = 1` (`ResonanceForeignDriver/lib.cpp:47`, unchanged in Qt 6), so `--networkMode` can never be
passed; and `resonance.cfg` is read from `applicationDirPath()` (`ResonanceApp.cpp:357`), which for
a DLL loaded into `python.exe` is **Python's** directory, not the driver's. It is therefore pinned
to whatever the default is — fine while that default is loopback and the rig is single-PC, a hard
block if the rig ever goes LAN. Worse in the embedded case: `QCommandLineParser::process()` reads
`QCoreApplication::arguments()`, i.e. the *host's* command line, so a Python host launched with
`--networkMode` anywhere in its arguments would steer the embedded Resonance instance.

⚠ **`fieldtrip` is outside `NetworkMode` entirely — and now outside the default tree.**
`fieldtripclient.cpp` dials through the vendored FieldTrip socket layer rather than Qt, to a host
that is a runtime `Parameters::String`, and `fieldtrip/tcpserver.c` binds `INADDR_ANY` through raw
Winsock. Neither consults the mode. It is one of the remaining services that was never ported, and
the comparator cannot run it either: there is no
`fieldtrip` directory under `R:\src` and no `fieldtrip.exe` in `R:\dist`, but there is none in
`R:\dist_Qt5\msvc64\bin` and no launcher for it there. The source survives only at
`R:\src_Qt5\fieldtrip\`, and the only binary anywhere is the archived x86
`R:\dist_2026aug\mingw32\bin\fieldtrip.exe`
([`arch_qt5-still-needed.md` §3.8](qt5-still-needed.md)). It is not part of the rig's live
configuration; if it ever is, it needs its own pass, and that pass now has to happen inside a port.

⚠ **`StreamPool`'s retry timer never starts in most services.** `StreamPool` is a value member of
`ResonanceAppPrivate` (`ResonanceApp.cpp:97`, unchanged in Qt 6), so it is constructed before the
`QCoreApplication` exists in the 11 services that build `ResonanceApp` first —
`QObject::startTimer` then refuses with *"Timers can only be used with threads started with
QThread"*, which is the message at the top of every service log. Pre-existing, carried into Qt 6,
and this change makes it matter slightly more, because a request whose candidates are all refused
now has nothing left to re-enter the cycle. Worth its own investigation.

---


<a id="history-7-evidence"></a>

## 7. Evidence

All measured on this machine, 2026-08-18, against the same binary with one flag changed.

<a id="history-71-what-each-mode-actually-opens"></a>

### 7.1 What each mode actually opens

`R:\config\isolation_check.ps1`, reading the OS rather than the program:

| | `loopback` (and default) | `lan` |
|---|---|---|
| UDP | `127.0.0.1:13370` | `0.0.0.0:13370`, `0.0.0.0:13371` |
| TCP listeners | `127.0.0.1` × 3 | `:::` × 3 (dual-stack wildcard) |
| **wildcard-bound endpoints** | **0** | **5** |
| advertised | `tcp-ip://127.0.0.1:2615` | `tcp-ip://172.20.144.1:5328`, `tcp-ip://192.168.132.171:5328`, `tcp-ip://anatolyhome2024:5328` |

⚠ **Read UDP with `netstat -ano`, not `Get-NetUDPEndpoint`.** Every service binds 13370 with
`ShareAddress`, and `Get-NetUDPEndpoint` collapses a shared endpoint to one row owned by whichever
process bound first — so it reports "no UDP endpoints" for every other service, which reads exactly
like a service that opened nothing. That artifact produced a wrong first version of this table.

<a id="history-72-the-local-path-still-works"></a>

### 7.2 The local path still works

`R:\config\isolation_stream_check.qml`, two isolated processes:

```
services discovered over loopback: ["quickStimulus[]","ISOGEN[generated,status]"]
ISOGEN/generated advertises: ["tcp-ip://127.0.0.1:5399","discover:///?stream=generated&name=ISOGEN"]
non-loopback URLs advertised = 0 (none)
blocks received over loopback TCP = 1001
```

Proving nothing is reachable is only half the claim; isolation that quietly stopped services
finding each other would look identical from outside.

<a id="history-73-a-stale-remote-url-is-refused--with-a-control"></a>

### 7.3 A stale remote URL is refused — with a control

`R:\config\isolation_remote_url_check.qml`. ⚠ The producer runs in **`lan` mode**, and that is what
makes the test mean anything: against an isolated producer the off-box address would fail to
connect regardless of any guard, so "0 blocks" would be indistinguishable from the bug.

| consumer | dials | blocks |
|---|---|---|
| isolated | `tcp-ip://127.0.0.1:<port>` — control | **750** |
| isolated | `tcp-ip://192.168.132.171:<port>` — same producer, genuinely listening there | **0**, refused |
| **`lan`** | `tcp-ip://anatolyhome2024:<port>` — by **name** | **1000** |

A `lan`-mode consumer pulled 1000 blocks through the LAN address in the same run, so it really was
reachable; only the address differs between the first two rows. The third row is the regression
test for [§5a](network-isolation.md#history-5a-six-defects-found-by-review-after-it-all-worked)'s first defect — it read **0**
before that fix, and no unit test could have caught it, because `isPermittedPeer` is only ever
handed literals.

⚠ **Getting the port wrong makes this test pass for the wrong reason.** The first run of it took
the last `TcpStreamSender: Ready` line from the producer's log, which is the `status` stream, not
`generated` — the control then read 0 blocks and, as the harness itself says, a control of 0 makes
the subject prove nothing. The port is now taken from discovery.

<a id="history-74-unit-tests"></a>

### 7.4 Unit tests

`test_NetworkMode`, run three ways — no argument (the shipped default), `loopback`, `lan` — 10
cases each. The table is deliberately concrete: `172.20.144.1` and `192.168.132.171` are **this
host's own addresses** and must be refused while isolated, so a predicate written as "any address
of this host" fails, and one written against only `8.8.8.8` would not have caught it.

It takes the mode on its **own** command line, because `ResonanceApp` is a singleton and one process
can therefore hold only one mode — which is why it is three runs and not three test cases.

⚠ **No CTest run executes it, in either tree.** `Core/Resonance/tests/CMakeLists.txt` builds the
target and ends with a commented-out `gtest_discover_tests`; there is no `add_test()` for it or for
any other `Core/Resonance` test, in `R:\src` or in `R:\src_Qt5`. So
`R:\src\_build\Core\Resonance\tests\test_NetworkMode.exe` is compiled by every build and reached
only when someone launches it by hand — which is what the port's own three-variant run was
(`R:\src\docs\VALIDATION.md`, "19 built non-hardware test executables … 21 runs because network mode
is exercised in default, explicit loopback, and LAN variants"). The consequence is that the shared
framework, the component every service links, contributes **zero** cases to any CTest total quoted
as the port's evidence ([`arch_qt6-work-list.md`](qt6-work-list.md)). Registering these is
cheap and is the reason this warning is here rather than in a backlog.

---


<a id="history-8-deployed-and-accepted-on-hardware"></a>

## 8. Deployed, and accepted on hardware

**Deployed 2026-08-18 07:48** to `R:\dist\msvc64\bin` — 97 files, 0 failed, with the previous
binaries kept beside it as `bin.pre-isolation-20260818-074817`.

```bat
robocopy R:\dist\_build\msvc64\runtime\bin R:\dist\msvc64\bin /E
```

⚠ **Both paths in that command have moved and that rollback is gone.** The tree is now
`R:\dist_Qt5\msvc64` and the build directory `R:\dist_Qt5\_build\msvc64\runtime\bin`, so a Qt 5
redeploy today is `robocopy R:\dist_Qt5\_build\msvc64\runtime\bin R:\dist_Qt5\msvc64\bin /E`. The
2026-08-18 rollback copy no longer exists — ten later `bin.pre-*` directories do, the newest
`bin.pre-20260829f`. The Qt 6 distribution is not deployed by hand at all: it is
`R:\src\scripts\deploy-qt6.ps1 -Destination R:\dist`, and ⚠ that script takes **no** `bin.pre-*`
copy of its own, so take one before deploying over a working rig
([transition notes §8](qt5-to-qt6-transition.md)).

⚠ **Every service must be restarted together.** An old (LAN) service broadcasting to
255.255.255.255 and a new (isolated) one bound to 127.0.0.1 **cannot see each other**, so a
half-restarted rig has a split service tree that looks like a discovery fault. Stop the amplifier
properly first — `stop`, wait for `init`, then `!terminate`; never kill it.

<a id="history-81-acceptance-on-the-deployed-tree"></a>

### 8.1 Acceptance on the deployed tree

Every combination run against `R:\dist\msvc64` — today's `R:\dist_Qt5\msvc64` — not the build
directory. Harness: `R:\config\isolation_acceptance.ps1`, whose `-Dist` default was repointed at the
comparator on 2026-09-02 and so still reproduces this table unchanged.

| Source → receiver | Result |
|---|---|
| `signalGenerator` → **viewer** | 835 blocks in 10 s |
| `signalGenerator` → **recorderService** (standalone) | `idle → recording → idle`; 2497 × 3, 832 blocks, **0 NaN**, std 7.071 |
| `signalGenerator` → **embedded Recorder** (the Configurator's own) | 2002 × 3, 667 blocks, **0 NaN**, std 7.068, `allStreamsPresent` |
| `playbackSource` (3.8 GB, 73 ch @ 25 kHz) → **viewer** | 127 blocks in 10 s |
| `playbackSource` → **recorderService** | 199,441 × 73, **0 NaN**, std 7617 |
| `playbackSource` → **embedded Recorder** | 199,601 × 73, **0 NaN**, 14.5 MB/s sustained |
| `playbackSource` → **tepService** | **51 epochs in 90 s**, all four TEP streams published, epoch file 54 × 2000 × 72, 0 NaN, MEP metrics present; playback **0 underruns** |
| **NVX-52, live hardware** → viewer + `recorderService` | `init → running → init`, 33 ch @ 1000.7 Hz, **33/33 channels finite, 0 NaN**, 19,999 rows, repaint 0.66 ms. Device left healthy |

Every advertised URL in every run was `tcp-ip://127.0.0.1:<port>` — **0 non-loopback URLs** — and
every service logged `network mode: loopback`.

⚠ The NVX's raw samples carry mV-scale DC offsets and mV-scale noise, i.e. floating inputs; the
viewer's ~8 µV figures are after its own filtering. **This run proves transport, lifecycle and
rate, not analogue signal quality** — that is a bench question and needs electrodes on a subject.
It is, however, a change from the 2026-08-17 acceptance, where 32 of 33 channels read all-NaN.

⚠ **What is NOT verified: the Configurator's Record *button*.** The embedded `Recorder` is
exercised through the exact three calls `Configurator.qml` makes — `openFile`, `addStream`,
`closeFile`, with the same `<stream>@<service>` key — and it wrote a valid file. What that does not
cover is the QML wiring around it: the per-stream checkboxes populating `recSelection`, the
button's `enabled` binding, and the on-screen size/duration readout. Driving the real window needs
desktop automation, and that grant was declined for this session. None of that QML was touched by
this change, but it has not been clicked.

<a id="history-82-the-qt-6-tree-and-cross-generation-interop"></a>

### 8.2 The Qt 6 tree, and cross-generation interop

`R:\dist` ships the same `NetworkMode` and the same `loopback` default. What has been measured
against it, from `R:\src\docs\VALIDATION.md`:

| | |
|---|---|
| Unit rules | the built network-mode tests were run in **all three variants** — shipped default, explicit `loopback`, explicit `lan` — which is why 19 test executables produce 21 runs. ⚠ Run directly, not through CTest ([§7.4](network-isolation.md#history-74-unit-tests)) |
| Deployed package | `validate-dist-qt6.ps1` launched the packaged NVX service and Configurator with a `PATH` of Windows plus `R:\dist\bin` and `R:\dist\qt\bin` only, no Qt installation reachable. Qt resolved as 6.11.2 from the package and **the two services discovered one another over loopback** |
| Qt 6 → Qt 5 | the Qt 6 Configurator discovered and fully drove running Qt 5.15 `nvx`, `SignalGenerator`, `recorderService` and `playbackService`, reading state, actions and the full parameter editor. Evidence: `R:\src\docs\qa\qt6-configurator-discovers-qt5-services.png`, `interop-qt5-nvx-qt6-configurator.png` |
| Qt 5 → Qt 6 | the Qt 5.15 Configurator discovered and drove the Qt 6 instances of all three. Evidence: `qa/qt5-configurator-discovers-qt6-services.png` |
| Across modes | the KARDi2 x86 island was driven by a preserved Qt 5 controller, by the rebuilt island in `lan` mode, and by the packaged **Qt 6 default-loopback** driver — all three producing the identical normalised contract hash `3264101b…` |

Two things follow, and they are the operating rules:

1. **Interop is at the process boundary and nowhere else.** A Qt 6 application links the Qt 6
   `Resonance` library and speaks the protocol to a Qt 5 process. ⚠ Qt 5 and Qt 6 DLLs, plugins and
   `Resonance.dll` binaries **must never be loaded into the same process**. Until 2026-09-02 the
   32-bit KARDi2 island inside `R:\dist\kardi2_x32` was the shape this took in practice — a complete
   Qt 5.15 process with its own `libResonance.dll`, entered by a launcher that did not import the
   Qt 6 environment. It is gone, and the principle now shows up one level down: `KARDi2.exe` is an
   ordinary x64 Qt 6 service, and the *architecture* boundary it cannot cross in-process is handled
   by `kardi2-broker-x86.exe`, which links no Qt and no Resonance at all
   ([kardi2.md §10](../components/kardi2.md)).
2. **Mode beats generation.** Nothing above needed a mode exception for being mixed — a `loopback`
   Qt 6 process and a `loopback` Qt 5 process on this PC are ordinary peers.

⚠ **§8.1 has no Qt 6 counterpart.** Every harness in the acceptance matrix now defaults to the
comparator — `isolation_acceptance.ps1 -Dist` is `R:\dist_Qt5\msvc64`, `isolation_check.ps1 -Bin`
is `R:\dist_Qt5\_build\msvc64\runtime\bin` — and none has been re-run against `R:\dist`. **No live
amplifier or stimulator has been driven under Qt 6 at all**, so the NVX-52 row of §8.1, and with it
the sustained-throughput evidence, remains Qt 5 evidence only. `R:\dist_Qt5\msvc64` stays the
acceptance reference until a lab session says otherwise
([`build_qt5-to-qt6-transition.md` §10](qt5-to-qt6-transition.md)).

<a id="history-what-breaks"></a>

### What breaks

One saved configuration, and it could never have worked anyway:

| File | Parameter | Requests |
|---|---|---|
| `R:\config\nvx136_direct_config.json` | `eegIn` | `tcp-ip://100.64.100.6:5172` |

`100.64.100.6` is a CGNAT/Tailscale address of another machine and `5172` an ephemeral port from a
long-dead process. Nothing else requests an off-machine address.

**Re-scanned 2026-09-02, including the Qt 6 distribution.** `R:\config` still has exactly that one
offender, at `/0/serialized/desiredStream/connections/0`. **`R:\dist` has none**: of its 19
`params\*.json` presets only `recorder_settings.json` matches a naive `tcp-ip://` search at all, and
its three hits are `127.0.0.1` ports sitting under `attributes.activeStream` — the readback subtree,
i.e. the exact false positive described next.

⚠ **Scanning for `tcp-ip://` in a config file over-reports badly, and the operator's own TEP
configuration is the example.** `tepservice_testTEP.json`, `test_viewer_001.json` and
`configurator_test_impedanceView.json` all contain LAN and Tailscale `tcp-ip://` URLs — but under
`attributes.activeStream`, which is a **readback** of what a connector happened to be attached to
when the file was saved. `Parameter::jsonPropertyName` is `"serialized"`, so `applyParameters()`
reads that subtree and nothing else. `tepservice_testTEP.json` actually requests
`discover:///?stream=eeg&name=TMSPLAY` and is unaffected. Scan `serialized/desiredStream`, not the
whole file.

---


<a id="history-9-harnesses"></a>

## 9. Harnesses

⚠ **All of these are Qt 5 harnesses today.** Their paths in `R:\config` are unchanged, but the
2026-09-02 rename repointed every distribution default in them at the comparator — `-Dist` and
`-Bin` parameters at `R:\dist_Qt5\msvc64` and `R:\dist_Qt5\_build`, output files under
`R:\dist_Qt5\msvc64\data\`. That was the right call for reproducing §7 and §8.1, and it means
**none of them has been pointed at `R:\dist`**. Doing so is the missing Qt 6 acceptance work
([§8.2](network-isolation.md#history-82-the-qt-6-tree-and-cross-generation-interop)); the argument shape supports it, since the
distribution root is a parameter in every case. ⚠ `tep_acceptance.qml` is the one that cannot be
repointed at all: `tepService` was never ported and exists only in `R:\dist_Qt5\msvc64`.

| | |
|---|---|
| `R:\config\isolation_check.ps1` | what each mode opens, from the OS, all three modes in one run |
| `R:\config\isolation_stream_check.qml` | discovery + streaming still work under isolation |
| `R:\config\isolation_remote_url_check.qml` | a remote URL is refused, with a loopback control |
| `R:\config\isolation_acceptance.ps1` + `.qml` | §8.1 — one source, three receivers, on the deployed tree |
| `R:\config\tep_acceptance.qml` | time-boxed tepService check: receives, epochs, publishes, saves |
| `R:\config\newbuild_nvx_check.qml` | live amplifier, and it stops the device through its own transition |
| `R:\config\resonance.cfg.example` | every configuration key, documented, including the dead ones. Applies to both generations |
| `test_NetworkMode` | the peer predicate and the default, pinned. ⚠ Built in both trees, registered with CTest in neither — [§7.4](network-isolation.md#history-74-unit-tests) |
