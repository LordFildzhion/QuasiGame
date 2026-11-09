# NVX-24/36/52 amplifier service

Status: active Qt 6 service, executable `nvx`. Source authority:
[CMake](../../src/nvx/CMakeLists.txt), [acquisition](../../src/nvx/nvxdatathread.cpp),
[application/configuration](../../src/nvx/application.cpp). Source inspected 2026-09-15.

## Change locations

- `NVXDataThread`: SDK open/start, available channels, bipolar mapping, acquisition polling,
  frame conversion, trigger output, impedance, shutdown and dropped-sample reporting.
- [nvxframelogic.h](../../src/nvx/nvxframelogic.h): unsigned counter gaps, status/counter word
  offsets, buffer size and polling arithmetic.
- [NVXInfo.cpp](../../src/nvx/NVXInfo.cpp): device properties and supported capabilities.
- `application.cpp`: public parameters, state transitions and stream metadata.
- `CMakeLists.txt`: vendor DLL selection and distribution/test separation.

Consumers include [recorder](recorder.md), [viewer](signal-viewer.md), [TepSound](tepsound.md)
and [latency probe](latency-probe.md). Preserve their channel, timestamp and trigger assumptions.

## SDK and data contracts

The active target uses NVX API **2.3.21648** in `sdk`, with its `nvxmcs.dll` and `PowerUp.conf`.
The old `dll` directory contains 2.1.8683; same filename does not mean interchangeable behavior.
Package the library selected by CMake with the executable.

- Derive frame width and status/counter positions from the reported analog width. The status
  word follows the analog words; the counter follows status. Unsigned counter wrap is deliberate.
- The read buffer holds at least 2 ms of frames even for very small requested blocks. The polling
  interval uses the bounded logic helper; do not substitute a timer-per-sample design.
- Preserve hardware counter-gap detection and dropped-sample reporting. Repeated/padded rows
  maintain output shape but do not recover physical samples.
- CED rows use physical device input numbers. They can name selected EEG and AUX inputs
  (AUX 1 is row 49 on NVX-52); the trigger retains its own identity. AUX remains kind AUX
  in volts, regardless of its montage label. A non-scalp sensor such as Photodiode should
  have NaN coordinates and type AUX. Never force all channel kinds to EEG. Impedance
  channels bypass signal filtering and carry Ohm units.
- Trigger-mode capability depends on the device model. For a configurable device, `openAndStart`
  orders `NVXOpen` → `NVXSetTriggersMode` → `NVXStart`; the selected SDK rejects the mode change
  before open. Preserve that order rather than moving calls solely because their names look like configuration.
- Trigger levels, input bits and output bits are distinct. `sendTrigger` masks its argument with
  `0x03`, but that does not establish two physical output lines or ordinary bitmask semantics:
  the documented NVX-52 has one output, and only value `1` drove it high (`0`, `2` and `3` were low).
  The public `trigger_state` parameter is Boolean and sends `0` or `1`. Preserve its application
  after acquisition starts: the device can power up with the line high before software drives it low.
- The documented NVX-52 status measurements place output readback at bit 9, contrary to the
  SDK header's bit 10, and show inputs resting high. An initial zero-status transient was also
  recorded; do not assume the first frame establishes the stable input level. Keep these measured
  model-specific facts separate from NVX136 and from unverified SDK-header descriptions; see
  [vendor correspondence](../decisions/proposals/vendor-sdk-inquiries.md).

## Measured limitations and handling

The August/September records report clean campaigns at 1 kHz/block 100 and 2 kHz/block 200, and
sample loss at 5 kHz reproduced below the Resonance driver with the raw SDK counter probe.
These are measured configurations, not a guarantee for every device/rate/duration. Preserve the
warning and its evidence when changing polling or padding. Stop through the service before
termination; competing processes and interrupted acquisition can invalidate a hardware test.

## Validation route

[Frame arithmetic tests](../../src/nvx/tests/framelogic_test.cpp) are device-free:

```powershell
ctest --test-dir R:\src\_build -N -R 'NvxFrameLogic|nvx_'
ctest --test-dir R:\src\_build --output-on-failure -R '^test_NvxFrameLogic$'
```

The SDK tests, integration test, stability probe and counter probe require physical hardware.
They are built separately from the distribution. Hardware CTest entries are disabled by default;
selecting a label alone does not turn disabled tests into executed acceptance. Inspect the
test source and deliberate hardware procedure before running an executable directly.

For a regression, compare the raw SDK counter probe with the driver to separate transport loss
from conversion/streaming defects. Keep sample rate, block size, SDK identity, device and duration
in the result. See [test guidance](../how-to/test.md), [issue registry](../issues/README.md),
[change history](../history/changes/README.md) and [NVX vendor correspondence](../decisions/proposals/vendor-sdk-inquiries.md).

The [P300TEST venue](../how-to/p300test.md) supplies the eight-channel P300 setup. Its [2026-09-26 connected-rig acceptance](../history/changes/2026-09-26-p300test.md) records USB hub routes, acquisition/presentation tests and the limits of bench validation.
