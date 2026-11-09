# DAQmx

**Status:** active native Qt 6 x64 analog-input service, `DAQmx.exe`, identity `DAQmx`. The pre-port Qt 5 assessment is historical. Current detailed module notes are in [src/DAQmx/README.md](../../src/DAQmx/README.md).

## Change locations and dependencies

| Change | Source / dependency |
|---|---|
| Parameters, CED validation and publisher lifecycle | [config.cpp](../../src/DAQmx/config.cpp) |
| NI runtime probe, acquisition worker, task cleanup | [driver.cpp](../../src/DAQmx/driver.cpp) |
| Pure configuration/read/status checks | [logic.hpp](../../src/DAQmx/logic.hpp) |
| SDK discovery and tests | [CMakeLists.txt](../../src/DAQmx/CMakeLists.txt), [logic_test.cpp](../../src/DAQmx/tests/logic_test.cpp) |

Build against the **installed** NI ANSI C headers and x64 import library. `NIDAQMX_SDK_ROOT` overrides the installed SDK root. The usual SDK path contains `Program Files (x86)` but its `lib64/msvc/NIDAQmx.lib` is x64; directory naming is not architecture evidence. Do not restore stale vendored import libraries or the unused `nisyscfg.lib`.

The distribution carries the [NI-DAQmx online installer](../../src/runtime-content/driver/daqmx/README.md), not app-local NI runtime DLLs or standalone kernel drivers. A target machine needs the appropriate NI-DAQmx x64 runtime/device support installed by NI; building also needs ANSI C development support. The service checks System32 runtime/required exports before delay-loaded calls so missing dependencies produce a controlled diagnostic. Installed package versions/hashes in [QA](../../src/docs/qa) are dated machine evidence, not universal prerequisites.

## Interface

Float64 stream `data`, selected analog channels in acquisition order, units volts. Normal states/actions remain `init`, `scanning`, `running`; `rescan`, `start`, `stop`. The error state additionally permits `rescan` and `stop`.

| Key | Contract |
|---|---|
| `device` | NI enumeration name |
| `channels` | At least one physical analog input |
| `samplingRate` | Requested 1..100000 Hz, default 1000; actual supported rate is device-dependent |
| `blockSize` | 1..10000 samples/channel, default 100 |
| `minMax` | Symmetric range in volts, default 1, maximum 10; editor permits 0 for compatibility but Start rejects it |
| `ced` | Optional text montage; exactly one valid named row per selected channel, in acquisition order |

These keys and options are compatibility surface. Parameters are snapshotted at Start.

## Acquisition and lifecycle invariants

- Reject empty channels, invalid rate/block/range, overflow and mismatched/unnamed CED rows before task setup.
- Every task-create/channel/timing/Done-registration/Start/actual-rate operation must succeed. Unwind on any failure; never publish a valid stream after failed setup.
- Read back NI's actual clock rate for stream metadata.
- Continuous buffer hint is `max(rate, 2 * blockSize)`; NI may allocate more. Read memory is bounded to 64 MiB.
- Worker polling uses half a block period clamped to 1..50 ms. Read complete blocks with zero timeout, at most 16 per turn.
- Check read status/count and atomic Done status. Partial/oversized reads or unexpected continuous-task completion stop acquisition. Diagnose Stop/Clear failures.
- NI calls, timers and read buffers belong to the worker. Publishers belong to the main thread; guarded queued delivery rejects retired workers.
- Stop/destruction cleans the task, quits and joins the thread; every Start uses a fresh worker. Rescan refreshes channels even if the device name is unchanged.

These rules are supported by the port record and selected current configuration/source inspection; source remains authoritative.

## Validation and current boundary

Run registered `test_DaqmxLogic` using the [test workflow](../how-to/test.md); no NI hardware is needed. It covers configuration/overflow, buffer sizes, injected setup failure/retry, read counts/status, montage checks and Done status.

[Validation record](../../src/docs/VALIDATION.md) and [prior software/physical boundary](../history/components/daqmx.md#history-software-versus-physical-validation) document parity/discovery, safe no-channel recovery, missing runtime and no-stream-on-failed-Start checks. They report **no NI acquisition**. Scaling, physical channel order, device rates/ranges, throughput, unplug/read-error recovery and real Start/Stop still require a known device/reference signal. No build or acquisition was run for this documentation change.
