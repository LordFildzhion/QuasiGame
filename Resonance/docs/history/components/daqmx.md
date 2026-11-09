# DAQmx — native Qt 6 x64 analog input — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/daqmx.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-daqmx--native-qt-6-x64-analog-input"></a>


**Ported 2026-09-05.** Active source `R:\src\DAQmx`, executable `R:\dist\bin\DAQmx.exe`,
location-independent launcher `R:\dist\DAQmx.bat`. The service identity `DAQmx`, six original
parameter keys/labels/options/defaults, normal init/scanning/running transitions and Float64
`data` stream are preserved. All six rows now have full Configurator descriptions and use the
existing shared light/compact controls. The detailed implementation record is
[`R:\src\DAQmx\README.md`](../../../src/DAQmx/README.md).


<a id="history-installed-sdk-and-external-runtime-2026-09-05"></a>

## Installed SDK and external runtime, 2026-09-05

The ANSI C API reports **26.5.0**. `C:\Windows\System32\nicaiu.dll` is **PE32+ AMD64**, file
version **26.5.0f461**. NI Package Manager reports `ni-daqmx` **26.5.0.49618-0+f466**, C support
**26.5.0.49613-0+f461**, and runtime core **26.5.0.49622-0+f470**, all windows_x64. MAX and
configuration support are installed. Enumeration returned **no real or simulated devices**.

CMake selects `C:\Program Files (x86)\National Instruments\Shared\ExternalCompilerSupport\C`:
`include\NIDAQmx.h` and **`lib64\msvc\NIDAQmx.lib`**. The import library's AMD64 machine type
was checked with dumpbin; the Program Files (x86) directory name is not its architecture.
`NIDAQMX_SDK_ROOT` can select another installed SDK with this layout. Neither the stale vendored
import libraries nor `nisyscfg.lib` is used. Runtime/header/library hashes and package versions
are in `R:\src\docs\qa\daqmx-installed-sdk.json` and `ni-installed-packages.log`.

**No NI runtime DLL or kernel driver is bundled.** Install NI-DAQmx x64 runtime and support for
the intended device; MAX/configuration support provides device setup/simulation. Building also
requires ANSI C development support, installed after Visual Studio/MSVC. The service checks the
explicit System32 runtime and required exports before touching delay-loaded imports. A missing
runtime is a controllable diagnostic, not a startup loader crash. The Qt runtime is app-local;
the source/distribution snapshot is not an NI driver installer.


<a id="history-repaired-behavior"></a>

## Repaired behavior

Parameters are snapshotted at Start. Empty channels, invalid block/rate/range, read-buffer overflow
and CED count/missing names are rejected before task setup. Every create/channel/timing/Done
registration/Start/actual-rate call must succeed before publication. A failure stops the sequence
and unwinds; no valid data stream is advertised after failed setup. Actual NI clock rate is read
back for truthful stream metadata. The editor retains its legacy zero range minimum, but Start
rejects zero volts.

The continuous-task buffer hint is **`max(rate, 2 * blockSize)`**, allowing at least one second or
two blocks per channel; NI may allocate more. Read memory is bounded to 64 MiB. The worker polls
at half a block period (clamped 1..50 ms), reads complete blocks with zero timeout and drains at
most 16 blocks per turn. Read status/count and atomic Done status are checked; partial/oversized
reads and unexpected continuous-task completion stop the task. Stop/Clear status is diagnosed.

NI calls, timers and read memory stay on the worker; publishers are created/destroyed on the main
thread with guarded queued block delivery. Stop/destruction cleans the task, quits and joins the
thread. A fresh worker is used for every Start. Rescan refreshes channels even when the device
name stays the same. The **additive `error: rescan/stop` actions** repair the Qt 5 error dead end;
the normal transition contract is unchanged.


<a id="history-software-versus-physical-validation"></a>

## Software versus physical validation

`test_DaqmxLogic` covers invalid configuration and overflow, buffer sizing, every injected setup
failure and retry, read status/counts, montage count/missing names, and Done statuses without NI.
Live ResonanceForeignDriver checks compare the Qt 5/Qt 6 six-parameter contracts/defaults and
initial actions, safe writes, four no-channel recovery cycles, normal exit and a forced missing
runtime path. The GUI probe checks that failed Start advertises no data stream.

No NI acquisition was started. Scaling, channel order, supported device rates/ranges, sustained
throughput, real Start/Stop and unplug/read-error recovery remain an operator-approved bench
session with a known NI device/reference signal. Final software evidence is in
`R:\src\docs\VALIDATION.md` and `R:\src\docs\qa`.

---


<a id="history-historical-2026-09-04-assessment-superseded-by-the-port-above"></a>

## Historical 2026-09-04 assessment (superseded by the port above)

**Assessed 2026-09-04; not ported in this task.** Current source:
`R:\src_Qt5\DAQmx`. It is a six-parameter, headless analog-input service that publishes a Float64
stream named `data`.


<a id="history-current-ni-status"></a>

## Current NI status

NI's current download is **NI-DAQmx 2026 Q3**, released 2026-07-23, with 32- and 64-bit components
for Windows 11, Windows Server 2025/2022 and Windows 10 IoT Enterprise 2021. NI explicitly says to
install the programming environment (including Visual Studio) before NI-DAQmx. The current C
documentation still describes the service's core calls: task creation, voltage-channel setup,
sample-clock timing, starting, `DAQmxReadAnalogF64`, stopping and clearing.

Primary sources:

- [NI-DAQmx download/current release](https://www.ni.com/en/support/downloads/drivers/download.ni-daq-mx.html)
- [NI-DAQmx in text-based programming environments](https://www.ni.com/en/support/documentation/supplemental/21/using-ni-daqmx-in-text-based-programming-environments.html)
- [NI-DAQmx 2026 Q3 bug fixes](https://www.ni.com/en/support/documentation/bugs/26/ni-daqmx-2026-q3-bug-fixes.html)

The 2026 Q3 release fixes CVE-2026-8035 (local denial of service) and CVE-2026-8036 (potential local
privilege escalation) affecting multiple older releases. This is an additional reason to install
the current driver rather than reconstructing an old runtime around the vendored import library.


<a id="history-source-defects-to-repair-during-the-port"></a>

## Source defects to repair during the port

- `DAQmxErrChk` logs failures but does not return or unwind. Initialization continues after a
  failed create/channel/timing/start call and still advertises a stream.
- `everyNCallback` ignores the return status of `DAQmxReadAnalogF64`; the Done callback ignores its
  `status`; read errors therefore look like a silent data stall.
- Start failure leaves the worker/thread lifecycle incomplete, and repeated Start/Stop ownership
  needs a deterministic synchronous shutdown.
- No validation rejects an empty channel selection, zero-sized read buffer, unsupported rate/range,
  or CED/channel-count mismatch before starting hardware.
- The hard-coded `sampsPerChanToAcquire=1000` should be justified or derived from block/rate.

Those are service correctness issues, not API-migration issues. Estimate: half a day for a careful
port plus one laboratory session for enumeration, scaling, channel order, sustained acquisition,
read-error recovery, Stop/Start and unplug/replug.
