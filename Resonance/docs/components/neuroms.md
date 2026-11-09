# NeuroMS

**Status:** active Qt6 x64 service `neuroMS.exe` / discovery `NeuroMS`, with mixed-mode `nmsbridge.dll`. Normal experiment firing is external TTL; the service configures, charges/discharges and records feedback. Hardware evidence primarily concerns a monophasic one-/two-block rig.

## Change locations and dependencies

| Change | Source |
|---|---|
| Flat C ABI, SDK resolver, callback/action queues, emulation | [nmsbridge.h](../../src/neuroMS/bridge/nmsbridge.h), [nmsbridge.cpp](../../src/neuroMS/bridge/nmsbridge.cpp) |
| Device worker, open/retry, status, settings, pulse attribution | [neuromsdriver.cpp](../../src/neuroMS/neuromsdriver.cpp), [driver header](../../src/neuroMS/neuromsdriver.h) |
| Parameters/states, async connect/teardown, handshake and guards | [neuromsconfig.cpp](../../src/neuroMS/neuromsconfig.cpp) |
| Pure mode, interval, limits, watchdog/status schema | [neuromslogic.h](../../src/neuroMS/neuromslogic.h) |
| File log, heartbeat/crash evidence | [servicelog.cpp](../../src/neuroMS/servicelog.cpp) |
| Build/tests | [CMake](../../src/neuroMS/CMakeLists.txt), [bridge CMake](../../src/neuroMS/bridge/CMakeLists.txt), [tests](../../src/neuroMS/tests) |

MSVC x64, C++/CLI for the current toolset and .NET Framework4.8 are required. Bind the managed device SDK directly: the older COM wrapper discards trigger settings/return values and omits callbacks.

Managed assemblies stay in **bin/neuroMS/**; NS65 has different same-name unsigned assemblies in its own directory. Stale flat managed DLLs win before resolvers; follow [deploy](../how-to/deploy.md). The connected event reports actual vendor assembly path. Resolver initialization must occur before any vendor type loads: separate the resolver class and preserve the NoInlining warm-up boundary. SDK callbacks catch exceptions, C exports contain managed exceptions and clear/preserve correct error text across cleanup.

## Modes and settings

| Device state / requested interval | Meaning |
|---|---|
| SINGLE | One block; power2/delay disabled |
| TWIN,0 interval | Simultaneous “strong” pulse; power2 mirrors power1 |
| TWIN,positive interval | Paired pulse; independent powers/delay |
| SLAVE | Wrong unit selected; use the master with coil/trigger connection |
| STANDBY | Front-panel power off; connection can remain open |

Interval ladder:0 is explicit; first positive value1ms;0.1ms steps below100ms,1ms at/above100, maximum999ms. **Never round a positive request to0**, because that changes paired mode to simultaneous firing.

Connect adopts observed **intensities**, but keeps the service/configuration's `delay` (default0); it does not adopt the machine profile's initial interval. Readiness handshake waits for an operating response, nudges power1 and restores it, reapplies settings and verifies the **quantized expected interval** and block2 reporting. Do not replace this with a blind sleep, hard-coded zero, or an unchecked write. Later panel interval changes mirror only after the initial configured interval was written.

A pre-connect power limit does not establish post-connect intensity. Clients must confirm applied values after connect, including absent/refused readbacks, before charging. Observe parameter reports/readback rather than assuming sending equals delivery.

## Parameter/state interface

Groups: main (device/model/mode/power1/power2/delay/fire/command); hardware (trigger input/output settings, number display, coil/firmware); safety (maxPower, keepCharged, idleDischargeMinutes, temperature warning, panel policies, allowHostFire); telemetry (statusInterval).

Charge/discharge are **transitions**, not persistent Booleans that configuration loading could invoke. Lifecycle includes init/scanning/ready/charging/charged/**standby**/error. Standby disables operating controls, offers disconnect and returns to ready when the machine becomes operating. A lost charge is not automatically a lost connection.

- Charging requires attached coil and no overtemperature.
- `ready` telemetry also requires settled capacitor after an intensity change; gate a trigger on this rather than an optimistic UI state.
- `keepCharged` watches observed charger state, rate-limits/bounds rearming and publishes chargerLost/recharge. Default idle bound10min without a pulse stops rearming.
- `remainsSeconds` is raw device telemetry; the observed register is elapsed charge-cycle time, **not remaining time to discharge**.
- maxPower applies across clients and mirrored panel controls. Host firing is separately disabled by default (`allowHostFire=false`).
- Panel actions are decided/queued in callbacks and **executed by NMS_GetEvents on the worker**, not re-entered from the SDK callback thread. Initial bridge policy is restrictive and installed before Open; panel/mirrored events distinguish request from action.
- There is no dose/session-count/rTMS policy implied by these controls. Unsupported SDK families/modes are not validated by the mono/twin tests.

## Current connect, failure and shutdown policy

These constants/paths were checked in current source; older incident rounds contain superseded values and causal hypotheses.

| Policy | Current value / behavior |
|---|---|
| Open retries |12 attempts,500ms pause; `NEUROMS_OPEN_ATTEMPTS` / `NEUROMS_OPEN_RETRY_MS` override |
| Retry identity | Re-enumerate by default; relocate by serial, not stale index |
| Post-close settle | `NEUROMS_OPEN_SETTLE_MS` defaults to0 (disabled); a positive value opts into a bridge settle window |
| Forced collection after close | `NEUROMS_CLOSE_GC` defaults to0 (disabled); nonzero opts into collection and waiting for finalizers |
| Connect watchdog |240s; cancellation checked between vendor calls |
| Readiness |100ms polling,15s budget; bounded verification attempts |
| Status failure threshold |5 failures trigger diagnosis, not immediate abandonment |
| Still-present stall | Keep session/poll for30s, then recheck presence/escalate |
| Never answered | Failed-connect path, not proof of mid-session USB loss |
| Missing device after prior replies | Abandon managed session without blocking close, report loss |
| Disconnect watchdog |10s, armed when queued shutdown can reach worker, not behind an active connect |
| Memory guard |2048MiB default,2s sampling,3 consecutive over-limit samples; threshold doubled during connect |
| Terminal failure | Reasoned process abandonment/exit3 avoids hanging vendor finalizers; grace/log delay depends on console path |

Disconnect is queued; main thread must not block behind a stalled SDK close. Pending connect/shutdown calls are skipped or retried within readiness budgets, not turned into fresh device errors. Normal close calls the vendor's Close and clears managed references; collection and waiting for finalizers occur only when `NEUROMS_CLOSE_GC` is enabled. The normal return does not establish immediate release of every finalizer-owned handle. Abandon deliberately avoids a finalizer that may wait forever for absent hardware. Unconditional disarm is attempted on normal disconnect; return code is recorded, **not proof that capacitor voltage reached zero**. Preserve the failure reason across cleanup.

`NEUROMS_NEVER_SELF_DISCONNECT=1` suppresses autonomous session drop/self-exit and logs what would happen. It also permits a failed vendor stack to keep leaking until explicitly closed; preserve this operator-selected behavior and its observability.

**First diagnostic: identify every neuroMS process by executable path/PID.** Qt5 and Qt6 have the same filename and can contend for one device. The resolved incident found duplicate services. Current retry log strings still contain older categorical USB/device explanations; those strings are not a proven diagnosis. See [dated incident](../history/components/neuroms.md#history--it-was-two-services-on-one-stimulator-2026-09-07-night-resolved) and [issues](../issues/README.md).

## Streams, logging and timing

`events` exists for the **process lifetime**, so clients can attach before connect and capture identity/settings. JSONv1 uses decimal-string RTC. Pulse records include stim block, count, measured dI/dT, electrical values, settings in force, coil temperatures and statusAgeMs. Paired/simultaneous mode produces two records per trigger. SDK source attribution is heuristic (panel window250ms); record it as such, not ground truth. Sync frame/offset records and an independently recorded TTL are needed for physical timing.

`status`: Float64,28 named lanes at default2Hz, always two-block shape; absent/disconnected values are NaN. Preserve armed/ready/stimOn/mode/intensity1/2/ipi/coil/thermal/counter lanes and both blocks' charger/temperature/capacitor/time/fan fields. Intensity/interval telemetry comes from the device, not just desired parameters.

`command`: Message JSON connect/disconnect/charge/discharge/rescan/set(power1,power2,delayMs), acknowledged by id. It supports SPEED, whose script interface has stream output but no direct parameter/transition API; all commands still write the same parameter/state authority.

Logs: `neuroMS.log`, rolling `.log.1`, crash dumps, `neuroMS.last-exit.txt`. Preserve PID/path/vendor/environment/exit reason and heartbeat memory/state context. `NEUROMS_LOG`, `NEUROMS_LOG_VERBOSE`, `NEUROMS_LOG_MAX_MB` and `NEUROMS_HEARTBEAT_MS` tune output. Diagnostic logs/dumps are not runnable distribution content.

## Validation and physical boundary

Registered `test_NeuroMsLogic` and `ns_bridge_smoke --emulation` are device-free. `nms_stream_check` requires a running service and is registered disabled; `nms_bringup` is a deliberate bench tool. See [test workflow](../how-to/test.md).

Emulation fault hooks include `NEUROMS_EMU_OPEN_FAIL`, `NEUROMS_EMU_UNPLUG_MS`, `NEUROMS_EMU_CLOSE_HANG_MS` and `NEUROMS_EMU_STALL_ONLY`; they test policy, not real capacitor/USB physics. [Full bring-up and evidence](../history/components/neuroms.md#history-9-hardware-bring-up-with-a-contingency-for-each-step) preserves panel, interval-unit, voltage-scale, sham and timing acceptance boundaries. Hardware capacitor discharge after USB loss and unsupported modes require their own evidence. No SDK/device/test execution occurred in this restructure.
