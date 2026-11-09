# 2026-08-18 — single-PC network isolation implemented, DEPLOYED and accepted on hardware

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-18--single-pc-network-isolation-implemented-deployed-and-accepted-on-hardware"></a>

### 2026-08-18 — single-PC network isolation implemented, DEPLOYED and accepted on hardware

Full document: **[network-isolation.md](../migrations/network-isolation.md)**. The earlier session assessed this
and implemented nothing; it is now built, reviewed, measured, **deployed to `R:\dist\msvc64`
(07:48)** and accepted against every module that has a signal. Rollback, if ever needed:
`R:\dist\msvc64\bin.pre-isolation-20260818-074817`.

**Acceptance on the deployed tree — every source against every receiver:**

| | |
|---|---|
| `signalGenerator` → viewer / recorderService / the Configurator's embedded Recorder | 835 blocks; 2497 × 3 and 2002 × 3 rows, **0 NaN**, std 7.07 |
| `playbackSource` (3.8 GB, 73 ch @ 25 kHz) → viewer / both recorders | 199,441 × 73 and 199,601 × 73, **0 NaN**, 14.5 MB/s sustained |
| `playbackSource` → **tepService** | **51 epochs in 90 s**, all four TEP streams, epoch file 54 × 2000 × 72 with MEP metrics; **0 underruns** |
| **NVX-52, live** → viewer + recorderService | `init → running → init`, 33 ch @ **1000.7 Hz**, **33/33 finite, 0 NaN**, repaint 0.66 ms, device left healthy |

Every advertised URL in every run was `tcp-ip://127.0.0.1:<port>` — **0 non-loopback URLs**.
⚠ The NVX result proves transport, lifecycle and rate, **not analogue signal quality**: the raw
samples show mV-scale offsets and noise, i.e. floating inputs. It is still an improvement on
2026-08-17, when 32 of 33 channels read all-NaN.
⚠ **The Configurator's Record *button* was not clicked** — the embedded `Recorder` is driven
through the exact calls `Configurator.qml` makes and wrote a valid file, but the checkbox →
`recSelection` → button-enabled wiring needs desktop automation, and that grant was declined.

**A `NetworkMode` in `Core/Resonance`, defaulting to `Loopback`.** Resolved once per process —
default, then `resonance.cfg` `"networkMode"`, then `--networkMode` — before the first socket
opens, and announced in the log at every start. `lan` restores the historical behaviour exactly and
adds a warning naming the unauthenticated transitions.

⚠ **The default is closed because this is a security hole, not tidiness.** A datagram from any host
became a live `ServiceControl` that the process then dialled back, and the EventBus honours
`!terminate`, `!recordToFile=` and `!stopRecording` with **no authentication**. Windows Firewall is
**off on all three profiles** here, so there was no second line either. Anything on the segment
could stop a running experiment.

| | loopback (default) | lan |
|---|---|---|
| UDP | `127.0.0.1:13370` | `0.0.0.0:13370` + `:13371` |
| TCP listeners | `127.0.0.1` × 3 | `:::` × 3 |
| **wildcard-bound endpoints** | **0** | **5** |
| advertises | `tcp-ip://127.0.0.1:4652` | 2 routable addresses + the hostname |

**The mechanism is a loopback-directed broadcast, and it was measured before it was written.**
Discovery goes to **`127.255.255.255`**, not `127.0.0.1`: every service shares port 13370, and
measured on this machine, unicast reached **1 of 2** sockets while the directed broadcast reached
**2 of 2**. ⭐ It also fixes the source address at `127.0.0.1` — a `255.255.255.255` datagram loops
back with the *sending interface's* address (`172.20.144.1`, the vSwitch), so the old arrangement
could not tell local from remote without enumerating interfaces. Because the source is now loopback
by construction, **the guard needs no enumeration at all — which is what makes it immune to VPN and
adapter changes**, rather than that being separate work.

**Verified:** 0 wildcard endpoints vs 5; the local path unaffected (**999 blocks** over loopback
TCP, 0 non-loopback URLs advertised); a stale remote URL refused **with a working control** — an
isolated consumer got 750 blocks from `127.0.0.1` and 0 from `192.168.132.171` on the *same
LAN-mode producer, genuinely listening there*. `test_NetworkMode` runs three ways. All 14 suites
pass.

⚠ **Six defects found by adversarial review AFTER all of that passed**, every one invisible to a
test that only asks "is the machine isolated?". The worst: **`lan` mode refused host names**, because
the named branch of the dial guard consulted the mode nowhere — hidden in ordinary use since IPs are
tried first, so the multi-homed case host names exist for was the case that broke. Also: a typo in
`--networkMode` was fail-**open**; a failed bind would have left the socket on **every interface**
(`writeDatagram` implicitly binds an unbound socket to `Any`); `playbackService` did not pass the
mode to its workers; the socket that actually carries `!terminate` had no peer check; and
`localhost` was trusted by name. All fixed, and the host-name regression re-tested live —
**1000 blocks where it was 0**.

⚠ **Choose one mode per machine.** Two modes on one host do not interoperate in either direction,
so putting one service in `lan` to reach a second PC cuts it off from every local consumer.

⚠ **Deploying is an all-at-once switch.** An old LAN service and a new isolated one cannot see each
other, so a half-restarted rig has a split service tree that looks like a discovery fault. Stop the
amplifier properly first — `stop`, wait for `init`, then `!terminate`.

**What breaks: one file.** `R:\config\nvx136_direct_config.json` requests
`tcp-ip://100.64.100.6:5172`, a Tailscale address of another machine on a long-dead ephemeral port.
⚠ **Grepping a config for `tcp-ip://` badly over-reports** — `tepservice_testTEP.json`,
`test_viewer_001.json` and `configurator_test_impedanceView.json` all contain remote URLs, but under
`attributes.activeStream`, which is a *readback*; `Parameter::jsonPropertyName` is `"serialized"`,
and the operator's TEP config actually requests `discover://` URLs and is unaffected. Scan
`serialized/desiredStream`, not the file.

Also corrected: [architecture.md §3](../migrations/framework-evolution.md) claimed Resonance needs "a TCP range
10000–20000 open". It does not — `portRangeBegin`/`portRangeEnd` are parsed and exposed but consumed
by nothing, and `TcpStreamSender` takes an OS-assigned ephemeral port.

