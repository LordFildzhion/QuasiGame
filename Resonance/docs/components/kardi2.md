# KARDi2

**Status:** active x64 Qt6 service `KARDi2.exe` plus an x86 native broker. The former Qt5/Qt6 “islands” are retired. Start source work in `service/` and `broker/`, not the older module-root/legacy driver.

## Architecture, change locations and packaging

```text
KARDi2.exe (x64 Qt6 + shared Resonance.dll)
  ↔ framed anonymous pipes
kardi2-broker-x86.exe (x86 native /MT)
  → unmodified x86 KARDi2.dll → McsUsb30 kernel driver → device
```

| Change | Source |
|---|---|
| Parameters, states, trigger input connections | [service/config.cpp](../../src/KARDi2/service/config.cpp) |
| Broker process/IPC lifecycle and published samples | [service/driver.cpp](../../src/KARDi2/service/driver.cpp) |
| Derived channels/counter/model names | [service/kardi2logic.hpp](../../src/KARDi2/service/kardi2logic.hpp) |
| Vendor ABI, buffering, read/poll and physical stop | [broker/main.cpp](../../src/KARDi2/broker/main.cpp) |
| Pipe wire contract | [protocol.hpp](../../src/KARDi2/protocol.hpp) |
| Build and tests | [CMake](../../src/KARDi2/CMakeLists.txt), [broker CMake](../../src/KARDi2/broker/CMakeLists.txt), [tests](../../src/KARDi2/tests) |

The broker alone loads the vendor DLL. Package **all three** executable/service/broker-DLL files together in bin. Shared Qt6 Resonance remains one core; no Qt5 runtime island is needed.

[build-qt6.ps1](../../src/scripts/build-qt6.ps1) builds the x86 broker **before** x64 configuration. The broker is an external input to the x64 target. Missing broker/vendor inputs warn and skip KARDi2 in a whole-tree configure, but are fatal in standalone mode. Do not restore a whole-tree fatal dependency cycle.

The maintained USB package is [runtime-content/driver/kardi2](../../src/runtime-content/driver/kardi2/README.md), shared with NVX 24/36/52. `KARDi2/_legacy/3dparty/Driver` remains a historical vendor copy, not a deployment input. Preserve the McsUsb INF/catalog and x64/x86 directories. See [deployment](../how-to/deploy.md).

## Acquisition and wire invariants

- Device model determines analog count/names: models1204/1209/1402 can have3/9/12 channels; do not hardcode12.
- Rates250/500/1000/2000/4000Hz follow the vendor sampling API. The old Delphi125Hz ladder is not the contract.
- Select rate labels serialize as `1000 Hz`, with a space, not the old tab. Labels are saved configuration values.
- `K2Info` is a three-argument x86 WINAPI call with the expected28-byte information structure. Open before querying; unopened info can appear as zero model/serial rather than a normal error.
- `K2SetDebugMode` also uses WINAPI. Keep byte-count units for `K2Read` size/count and vendor gain/volts buffers.
- Retain at least the documented12-element vendor gain/scale buffers. Keep the read result/count initialized and checked.
- Carry partial trailing frames into the next read. Dropping leftover words shifts every later channel.
- Buffer at least `max(2 * blockSize, samplingRate)` frames; the vendor can drain/discard excess when caller memory is too short. Poll interval is at least1ms and at most750ms, allowing at least one read/sec. Large blocks may therefore publish in smaller pieces.
- Convert invalid electrode sentinel `0x7FFFFFFF` to NaN, not infinity.
- Treat the service word as **unsigned**. Inputs bits27/28, outputs29/30, cardio-detector31; counter occupies bits0–26. Detect modulo-27-bit continuity without signed shifts.
- Additional channels are Trigger1In, Trigger1Out, Trigger2In, Trigger2Out, cardio-detector and sample counter. Preserve ECG/volts, Trigger/bitfield and Counter metadata so display scaling does not mix them.
- Validate at least one selected channel. Do not advertise a running stream after failed setup.
- Trigger stream replacement must disconnect prior handlers, supply QObject lifetime context and guard driver teardown. Otherwise reconnects multiply output actions.

## Device-owned output latch and shutdown

Prior physical testing established that **K2Stop and K2Close do not clear Sync outputs**. The device retains them even across reopen. Clear outputs after obtaining/opening the device, immediately before Start, and around Stop/Close.

Current source is more complete than the older “unconditional kill” narrative:

- [Driver::shutdownBroker](../../src/KARDi2/service/driver.cpp) sends clear→Stop→Shutdown, closes the write pipe, waits, and kills only after timeout.
- [Broker closeSafely](../../src/KARDi2/broker/main.cpp) clears→stops→clears→closes; EOF, malformed input and failed output pipe converge there.
- The broker still lacks an unhandled-exception/console-control cleanup handler. A vendor crash or forced timeout kill can bypass these paths; hardware latch release is not guaranteed then. Treat this residual separately from the handled parent-pipe-loss path.

## Validation and current boundary

No ordinary CTest target is registered by the current KARDi2 top-level CMake. Standalone build exposes `kardi2-bridge-probe` and `kardi2-service-integration`; [run-tests.ps1](../../src/KARDi2/run-tests.ps1) acquires at every rate and includes a **crash-high physical-output test**. It is hardware acceptance, not a safe routine software unit test.

[2026-09-02 hardware record](../../src/docs/KARDI2NP_ARDUINOTTL_HARDWARE_VALIDATION_2026-09-02.md) preserves the matrix, Sync loops, latch behavior and4kHz soak. A subsequent broker-service probe acquired1000Hz/18 lanes and toggled an output; the earlier full matrix was not rerun wholesale against that architecture. Analog calibration/scale units, cardio detector and USB recovery remain physical acceptance items. [Detailed dated evidence](../history/components/kardi2.md#history-10-the-x64-service-and-its-x86-broker--what-actually-ships).

Selected current build/broker/shutdown source was inspected. This documentation change ran no KARDi2 executable or hardware test.
