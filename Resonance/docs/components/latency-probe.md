# Latency probe

**Status:** active Qt 6 executable `latencyProbe.exe`; discovered service identity is **`LatencyProbe`**. It detects an asserting edge in an amplifier trigger/status word, optionally commands another service, and publishes JSON on `events`.

## Change locations

[latencyprobe.cpp](../../src/latencyProbe/latencyprobe.cpp) owns parameters, edge detection, response dispatch, release timer and event accounting; [latencyprobe.hpp](../../src/latencyProbe/latencyprobe.hpp) owns state. [CMakeLists.txt](../../src/latencyProbe/CMakeLists.txt) and [main.cpp](../../src/latencyProbe/main.cpp) own packaging/identity. Changes depend on the amplifier's trigger-word contract and [network semantics](../architecture/network.md).

## Parameters and lifecycle

| Key | Default | Meaning |
|---|---|---|
| `source` | disconnected | Float64 amplifier stream |
| `trigger_channel` | -1 | Zero-based column; -1 means last |
| `input_mask` | 256 | Input bits to observe; exclude output readback to avoid feedback |
| `input_active_low` | true | High→low detection; false means low→high |
| `armed` | false | Observe/report only until enabled |
| `target_service` | `NVX` | Exact discovery name |
| `response_kind` | Boolean parameter | None, Boolean, Integer or Transition |
| `response_name` | `trigger_state` | Target parameter or transition key |
| `response_value` | 1 | Asserted Boolean/integer value |
| `release_after` | 20 ms | Host timer; zero leaves asserted |
| `release_value` | 0 | Boolean/integer release value |
| `status` | empty | Once-per-second counts/cadence/transport summary |

States are `init` and `running`; actions `start`, `stop`. Replacing the source disconnects the old stream to avoid duplicate detections.

## Timing contract

Detection records carry raw word, sample index within the block, sampling rate, block creation/arrival/dispatch/response timestamps, estimated host-side edge age, reaction time and armed state. Large RTC integers are **decimal strings**, not JSON doubles.

- `reactionMs`: block delivery through completion of the remote-command call.
- `edgeAgeMs`: adds the edge's estimated position relative to the newest sample.
- Neither measures ADC-to-output latency. Driver timestamping starts after its SDK returns.
- `release_after` is a normal host timer, not precision pulse generation. Repeated detections restart one timer: a high-rate sequence can hold the line asserted until the last detection plus the delay.
- Use a device-side self-releasing transition where distinct pulses are required. Do not interpret command completion as physical output onset.

## Validation and evidence

There is no dedicated unit-test target in [CMake](../../src/latencyProbe/CMakeLists.txt). Package/discovery, source connection and event formatting can be checked without a physical loop; see [test prerequisites](../how-to/test.md). Absolute timing requires a board that timestamps both the initiating edge and amplifier response on **one clock**. Host-only measurements cannot substitute.

[Original parameter and timing record](latency-probe.md) is previous documentation evidence; no timing experiment was run during this restructure.

