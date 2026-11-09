# COMport

**Status:** active Qt 6 service, `COMport.exe`, identity `COMport`. This page is the coding entry point; packaged launch/build rules live in [build](../how-to/build.md) and [deploy](../how-to/deploy.md).

## Change locations

| Change | Source |
|---|---|
| Parameter names, options and state actions | [Configuration.cpp](../../src/COMport/Configuration.cpp) |
| Receive/send queues, port lifecycle and stream replacement | [PortCommunicator.cpp](../../src/COMport/PortCommunicator.cpp) |
| Entry point and packaging | [main.cpp](../../src/COMport/main.cpp), [CMakeLists.txt](../../src/COMport/CMakeLists.txt) |

## Contract

Serial input becomes a Resonance `Message` stream named `dataFromPort`. A connected `Message` input is encoded with the Windows local 8-bit code page and queued to the serial port. The service adds/removes **no terminator**. It is text-oriented; arbitrary byte sequences are not guaranteed to survive a `Message` round trip.

| Parameter | Default / meaning |
|---|---|
| `source` | First scanned COM port; `rescan` refreshes the choices |
| `baudRate` | 115200 |
| `dataBits` | 8 |
| `parity` | None; also even, odd, mark, space |
| `stopBits` | 1; also 1.5 on Windows and 2 |
| `flowConrol` | None; also RTS/CTS and XON/XOFF |
| `input` | Disconnected; Message stream to transmit |

Retain the misspelled **`flowConrol`** key: saved configurations and remote clients use it. Keep port option labels as `COM4`, `COM8`, etc. Select values persist the display label; appending localized device descriptions breaks portability and old saved values.

States are `scanning → init → running`, with `rescan`, `start`, `stop`. A resource error returns to `init`.

## Invariants

- Queue the entire payload, including its last byte. Remove only bytes accepted by the serial API; resume on `bytesWritten`. Do not restore the old shortened-write loop.
- Replacing the input disconnects the former stream; otherwise it can keep transmitting.
- A successful open is not evidence that bytes reached a peer.

## Validation and evidence

[CMake](../../src/COMport/CMakeLists.txt) has no dedicated module unit-test target. Use the shared [test route](../how-to/test.md) for build/package/discovery and safe no-port startup checks. Exact-byte acceptance requires a serial loopback or paired virtual ports: include a distinctive last byte, verify the peer payload, send a reply, and record `dataFromPort`.

The port record documents software-only acceptance; it does not establish physical-loopback success. [Historical repair and acceptance boundary](../history/components/comport.md#history-qt-5-parity-and-repaired-defect). This documentation pass ran no executable or serial test.

