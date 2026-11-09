# Network behavior

Status: current engineering reference. Scope: Resonance framework networking in the Qt 6 tree, with external device/protocol traffic explicitly separate. Authority: [ResonanceApp](../../src/Core/Resonance/ResonanceApp.cpp), [CommunicationLayer](../../src/Core/Resonance/communicationlayer.cpp), and the stream connection source; inspected 2026-09-15.

## Mode is a startup decision

The order is default `loopback` → optional `resonance.cfg` `networkMode` → `--networkMode`. The configuration file is read beside the executable, not beside the documentation. For the default package that is `R:/dist/bin/resonance.cfg`. Each package/process reads its own configuration; setting the Qt 6 file does not configure a Qt 5 executable elsewhere.

The mode is resolved before `CommunicationLayer` binds sockets. Do not make it a mutable runtime flag while leaving the existing sockets open. An unrecognized command-line mode falls back to loopback and warns. Every service logs the chosen mode; use `--console` or captured Qt logs to verify the actual startup decision.

For an explicitly distributed session, either use:

```json
{ "networkMode": "lan" }
```

or pass `--networkMode lan` to each participating process. Loopback needs no configuration. The framework's LAN control interface is unauthenticated: reachable peers can send service transitions and control operations. Mode selection therefore changes who can control a service, not only who can see it.

## Addresses and transport

| Boundary | Loopback behavior | Relevant implementation |
|---|---|---|
| UDP discovery/control announcements | Bind 127.0.0.1:13370 with shared-address flags; send to 127.255.255.255 | [CommunicationLayer](../../src/Core/Resonance/communicationlayer.cpp) |
| Advertised stream endpoints | Default host IP 127.0.0.1 and no host names | [ResonanceApp](../../src/Core/Resonance/ResonanceApp.cpp) |
| TCP stream listeners | Bind loopback; operating system assigns the port | [TcpStreamSender](../../src/Core/Resonance/internal/TcpStreamSender.cpp) |
| Incoming discovery candidates | Reject non-permitted peers before use | [ServiceDiscovery](../../src/Core/Resonance/servicediscovery.cpp) |
| Outbound connections | Filter retry candidates and check again at connect | [StreamPool](../../src/Core/Resonance/internal/StreamPool.cpp), [TcpStreamReceiver](../../src/Core/Resonance/internal/TcpStreamReceiver.cpp) |

**Keep the loopback broadcast address.** On the documented Windows setup, sending to the host address 127.0.0.1 reached one holder of the shared UDP port; sending to 127.255.255.255 reached all. Substituting ordinary loopback unicast can break discovery fanout while a two-process smoke test still passes. The experiment and rationale are retained in [network history](../history/migrations/network-isolation.md).

Loopback permits loopback literals (including IPv6 and IPv4-mapped loopback) and the name `localhost`; other host names are not resolved as an escape route. A local adapter's LAN/vSwitch address is not loopback. Both candidate filtering and the final connect guard are required: the first avoids repeated rejected retries, and the second protects callers that construct a receiver directly.

Explicit `hostIPs` and `hostNames` settings override advertisement choices, not bind/dial enforcement. Advertising a LAN address while isolated creates an unusable endpoint. Remove that override or intentionally choose LAN mode. Do not infer the listening-port range from `portRangeBegin/End`: the current TCP sender calls `listen(..., 0)` for an ephemeral port.

LAN mode retains the older broadcast/multicast implementation, including a recorded multicast-join concern. Treat changes there as protocol behavior changes and consult [issues](../issues/README.md); repairing an apparently misplaced join can enable an additional ingestion path.

## External connections are separate

Framework loopback mode does not promise that a process makes no other network/device calls. Examples include a [FieldTrip](../components/fieldtrip.md) buffer connection, [feetStim](../components/feetstim.md) UDP commands, serial links, and vendor SDK traffic. FieldTrip is an active Qt 6 service; its external TCP client is not an unported exception.

Document and test each external endpoint at its component boundary. FFI clients embedded in another process also need review of how that process passes arguments and configures the Resonance singleton.

## Debug in this order

1. Identify the actual executable/package, service names, and startup mode for every participant.
2. Compare advertised endpoints with permitted bind/dial addresses. Check unwanted `hostIPs`/`hostNames` overrides.
3. Distinguish discovery success from successful stream connection and from received data. Inspect service/stream identity after a producer restart.
4. For configuration inspection, distinguish `serialized/desiredStream` from `attributes/activeStream`; readback can retain an old connection after a refused request.
5. Reproduce with a bounded synthetic producer/consumer and then the relevant existing test. Never use blanket process-name termination to clean up a shared rig; track the process IDs the test started.

[NetworkMode_test.cpp](../../src/Core/Resonance/tests/NetworkMode_test.cpp) checks predicates/defaults and creates real framework sockets. Its default, explicit loopback, and LAN variants are separate process runs. It is not currently registered with CTest. The LAN variant is a deliberate network test, not part of a passive documentation check. See [testing](../how-to/test.md) for execution setup and distinguish source/software evidence from a physical-rig acceptance result.

