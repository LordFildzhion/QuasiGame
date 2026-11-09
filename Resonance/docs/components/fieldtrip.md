# FieldTrip buffer service

**Status:** active Qt 6 x64 service, executable/identity `fieldtrip`. It republishes FieldTrip numeric samples as Float64 `buffer`. The interface remains **data-only**; FieldTrip events and richer channel metadata are not currently bridged.

## Change locations and dependencies

| Change | Source |
|---|---|
| Parameters, publisher replacement, generation guards | [application.cpp](../../src/fieldtrip/application.cpp) |
| Asynchronous transport, header parsing, cursor/reconnect logic | [fieldtripclient.cpp](../../src/fieldtrip/fieldtripclient.cpp) |
| Pure bounds/type/reset logic | [logic.hpp](../../src/fieldtrip/logic.hpp), [logic_test.cpp](../../src/fieldtrip/tests/logic_test.cpp) |
| Build, tools and provenance | [CMakeLists.txt](../../src/fieldtrip/CMakeLists.txt), [README](../../src/fieldtrip/README.md), [PROVENANCE](../../src/fieldtrip/upstream/PROVENANCE.md) |

The service uses current FieldTrip request/wire definitions with Qt asynchronous TCP, not the old blocking C client's integer socket handles. Official C buffer/demos are separate Qt-free x64 tools in distribution `tools/fieldtrip`. Keep the selected BSD licence, copying notices and upstream provenance with these sources/tools. The old artificial x86 gate and obsolete pthread DLL are not part of the current build.

## Interface and reconnect contract

- `hostName`: `localhost`.
- `port`: 1972, supported editor range 1..32767.
- `init: start` and `running: stop` remain the normal actions.
- Connection/header failure leaves the service **running**, reports state information and retries every 500 ms. This intentionally differs from the Qt 5 return-to-init behavior.
- Stream/service names and service UID stay stable; a changed shape/rate/type/chunk replaces the publisher and description.

## Non-obvious implementation constraints

Socket creation, IPv4 DNS/connect, parsing, retry and close execute on the moved worker thread. Connect deadline is 5 s; request deadline 1.5 s. Check response version, size, type, shape and count; bound input/decoded buffers to 64 MiB and requests to 8192 samples. Convert all ten supported numeric types safely from potentially unaligned wire memory into sample-major doubles.

Refresh GET_HDR after WAIT/data even when counts are unchanged or increasing. Backward counts reset the request namespace. An empty selection must not form unsigned `count - 1`.

Disconnect clears header/rate/channel/cursor state. Initial joins and network reconnects start at the current tail. A directly observed in-place reset starts at zero in its new namespace. **FieldTrip v1 has no generation ID**: a same-shape reset that catches up entirely between observations cannot be reliably identified.

Stop aborts the socket, destroys the worker, quits/joins the thread. Publishers remain on the main thread; generation guards reject stale queued blocks.

Consumers need special care on replacement:

- Recorder cannot append a new stream shape to an existing dataset; record separate files/datasets per shape/epoch.
- Previous QA explicitly rebound its ResonanceForeignDriver reader. Automatic foreign-driver reader rebinding is not established by that acceptance result.

## Validation and evidence

Registered `test_FieldtripLogic` is device-free; see [test workflow](../how-to/test.md). End-to-end local acceptance is in [test-daqmx-fieldtrip.py](../../src/scripts/test-daqmx-fieldtrip.py), `--only acceptance`. Inspect its environment/process prerequisites before running.

The official `buffer.exe 1972` + `demo_sinewave.exe localhost 1972` produces 16 channels at nominal 512 Hz in 32-sample blocks: channel1 counter, channel2 unit 1 Hz sine, others noise/mixed waveforms. `demo_combined` embeds a 16-channel/250 Hz feeder. Demos use approximate sleeps; assess frequency in declared **sample time**.

[Previous acceptance](../history/components/fieldtrip.md#history-hardware-free-acceptance-and-consumer-boundary) covers official sine→service→recorder/HDF5, known-header reset, server restart, Stop/Start and normal exit. Qt 5 comparison required a separate LAN-mode session; current ordinary operation is loopback. Those are prior results, not tests rerun in this documentation change.

