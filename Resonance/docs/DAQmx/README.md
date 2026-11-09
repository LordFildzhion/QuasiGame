# DAQmx — Qt 6 x64

Requires an external NI-DAQmx x64 installation with device support. NI MAX is useful for device
configuration and simulation. Building also requires **NI-DAQmx ANSI C development support**;
install Visual Studio before adding that NI component. The current installed SDK is selected by
`NIDAQMX_SDK_ROOT`; no vendored NI header or import library is used. The executable delay-loads
`nicaiu.dll` only after checking the Windows System32 runtime and required exports. No NI driver
DLL is bundled. This software uses the installed NI runtime; the Qt runtime is app-local.

The six original parameter keys/defaults/labels and the `data` Float64 stream are preserved.
Values are snapshotted at Start; later edits apply on the next Start. NI coerced sample rate is
read back for truthful stream metadata. Empty selection, invalid rate/block/range and mismatched
CED are rejected before hardware setup. CED rows describe the selected channels in their stream
order. `rescan` and `stop` in `error` are additive recovery actions; the old error state was a
dead end. The normal init/scanning/running transitions are unchanged.

Continuous-task buffering requests at least one second or two blocks per channel, whichever is
larger. DAQmx may allocate more. A worker timer reads only complete blocks with zero timeout;
the Done callback only stores its result atomically. Read/setup/Done errors close the stream and
clear the task. Stop and destruction join the worker after cleanup on its own thread.

No NI devices were enumerated on this machine. Software tests cover configuration, bounded buffer
arithmetic, setup unwinding, read-status handling, no-device recovery and cross-generation parameter
parity. Physical voltage scaling, channel order, supported device rates/ranges, sustained acquisition,
Start/Stop and disconnect recovery still require a known device and operator-approved bench test.
