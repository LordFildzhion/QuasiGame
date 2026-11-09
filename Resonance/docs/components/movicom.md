# Movicom EEG amplifier

Native Windows x64 / Qt 6 Resonance service for the eight-input Movicom amplifier. Source: [movicom](../../src/movicom), [build target](../../src/movicom/CMakeLists.txt). The [initial investigation](../history/investigations/movicom-20260925.md) documents the supplied software and recovered protocol. The [implementation record](../history/changes/2026-09-25-movicom.md) owns measured acceptance and remaining limits.

## Operator controls

Start `Movicom.bat` in the Resonance distribution and select **Movicom** in Configurator. It uses the same 300 px parameter panel and service controls as NVX/NVX136/Neuron-Spectrum.

- **Device:** USB serial identity; **rescan** refreshes the list. A saved serial is retained through initial scanning and absence; another amplifier is never silently substituted.
- **Sampling rate:** fixed nominal 500 Hz, read-only.
- **Block size:** 1–5000 samples per channel, default 25 (50 ms, 20 published blocks/s at nominal 500 Hz); maximum 500 with firmware synchronization. USB reads run independently of block publication.
- **CED file:** optional replacement montage. Empty uses the embedded `movicom8.ced`: inputs **1–8 = Cz, Pz, C3, C4, PO7, PO8, O1, O2**, with coordinates. CED row numbers refer to physical inputs even for subsets. An explicit replacement owns its labels/positions; unlabelled inputs in a partial replacement retain CH-number names.
- **Channels:** select inputs 1–8; the control shows input numbers and the built-in electrode names. All are enabled initially. At least one is required. All eight inputs are acquired by hardware; only selected channels are published.
- **P300 firmware sync:** enabled by default for the P300TEST setup; may be disabled before acquisition. Publishes a paired `sync` stream; **Firmware clock** reports lock and fit quality.
- **start / stop:** asynchronous acquisition and release. Settings lock during starting/running/stopping. Running requires valid EEG frames. Diagnostics remain visible after Stop.

Every input measures against the shared REF electrode; GND and REF are not sampled channels. There is no mode selector, impedance control, trigger lane, programmable gain or software filter selector. No such hardware control was established. Use normal downstream Resonance processing for filtering or rereferencing.

## Windows driver

The service uses the installed **FTDI D2XX x64** driver from Windows System32. It does not use COM-port numbering, the x86 MoviEEG DLL, KARDi2.dll, Python, or the old browser application.

If Windows does not obtain the driver automatically, run `driver/movicom/Install.bat` as administrator. The INFs, catalogs and original `amd64`/`i386` directories are adjacent to that installer. [Package reference](../../src/runtime-content/driver/movicom/README.md). This is an unchanged signed FTDI 2.12.36.20 package for Intel/AMD x64 Windows 10/11; a clean second-PC installation remains untested. The original setup contains the much older FTDI 2.08.02 installer.

KARDi2.dll in Mind Controlled Browser provides its viewer's software filtering. It is not the Movicom acquisition driver.

## Stream and physical limits

The `eeg` stream is Float64, sample-major, in **volts**, with selected physical inputs in ascending order. Metadata includes `name`, `kind`, `unit`, `hardwareChannel`, `reference`, and supplied CED properties. Default kind is EEG and reference is REF. Trigger/Impedance CED kinds are refused before USB opens.

Conversion follows the recovered MoviEEG 1.3.190 scale: signed 24-bit ADC count × `2.051 / 12 / 8388607` V. Water-electrode tests establish acquisition and transport behavior, **not absolute input calibration or usable human EEG**. Exact positive/negative ADC full-scale values are preserved and counted separately from missing samples; clipping is not an impedance measurement.

Block creation timestamps estimate the last sample's host reception time, adjusted for remaining frames in that read at the nominal rate. They are strictly increasing but are not hardware trigger timestamps or a calibrated amplifier clock. Optional D7 clock fitting is published separately; it does not rewrite these EEG timestamps. The measured device sample clock can differ from nominal 500 Hz; do not infer precise physical event alignment from nominal rate alone.

The continuity check uses the same lower six counter bits established by the vendor parser. Missing counts are **minimum detected loss**: multiples of 64 frames cannot be uniquely recovered. Detected gaps produce NaN rows, duplicates are discarded, and corrupt CRC frames are rejected. USB read intervals of at least 128 ms are separately flagged as uncertain. Undocumented upper bits are displayed as diagnostics, never interpreted as triggers or electrode status.

## P300 firmware synchronization

**Movicom firmware receives D7 and echoes a numbered tag inside the EEG stream. FTDI transports the bytes.** Enable **P300 firmware sync** before acquisition, then use [P300's Movicom mode](p300.md#optional-movicom-synchronization). This is specific to Movicom and native P300, not a universal amplifier trigger interface.

The acquisition worker remains the sole USB owner. Approximately every 20 ms it stores the host performance-counter timestamp immediately before writing `D7`, tag, CRC. Tags run through 1–255, avoiding the currently held firmware tag. The first frame carrying an outstanding tag supplies its extended sample index and the stored send time. Only confirmed echoes within 100 ms are used. Missed writes, held tags, expired or unissued echoes supply no anchor; each later command has a new timestamp. Observed firmware misses make successful USB writes insufficient evidence of synchronization.

The last 128 anchors fit a centered linear sample/host-clock relationship. Lock requires at least eight anchors spanning 1.4 seconds, rate 450–550 Hz, RMS residual at most 2.5 ms, maximum residual at most 8 ms and a last anchor at most one second old. Once enough anchors exist, a candidate more than 8 ms from the fit is rejected. A slow write over 10 ms, counter gap/duplicate, CRC/resynchronization error, read interval at least 128 ms or backlog of at least 64 frames resets the fit. Every acquisition has a new session identifier. Acquisition can continue and relock after a clock failure; an active synchronized P300 run stops.

Each `sync` Message describes exactly one EEG block, matched by `eegCreatedNs` and sample count. Format `movicom-d7-block-v1` records serial/session/generation, first sample ordinal, frozen mapped first time, period, validity/quality, and the latest confirmed anchor including send/write-end/receive times and tag. Nanosecond timestamps and ordinals are decimal strings. EEG channel metadata carries the matching serial/session/protocol. P300 uses the same frozen per-block mapping live and from recordings; it does not refit historical blocks with later anchors. Blocks crossing warmup/reset are invalid, and mapped time may not move backwards. With the option off there are no D7 writes, no `sync` publisher and no clock metadata.

This tracks the sample/PC clock and reduces dependence on EEG receive buffering. It does **not** measure screen-light onset, remove host-to-device command delay, create a physical trigger input, resample EEG, or apply the old demo's 40 ms correction. Fit residual is internal consistency, not absolute optical accuracy. [Implementation and physical tests](../history/changes/2026-09-26-movicom-firmware-sync.md); [recovered protocol](../history/investigations/movicom-20260925.md#recovered-wire-protocol).

## Acquisition and shutdown contract

[D2XX transport](../../src/movicom/d2xxtransport.cpp) enumerates the exact `Movicom EEG Control` description, VID/PID 0403:6001 and nonempty USB serial. It rechecks identity before opening. Unrelated FTDI adapters receive no commands.

Transport uses 500000 baud, 8N1, no flow control, 64-byte USB input requests and a 2 ms FTDI latency timer. All USB operations run in one worker. Stop sends D0 DD and drains the previous acquisition, retries while input continues, and requires a quiet interval within a bounded deadline. The original FTDI latency timer is restored before releasing the handle. No EEPROM writes, firmware updates, GPIO, impedance or undocumented configuration commands are issued.

Start sends D1 DD; the vendor library also retries this command. The USB bridge can reappear before the amplifier supplies samples. The service permits at most twenty Start commands, spaced at least one second apart, within a twenty-second first-frame deadline; Stop remains available during this wait. It never retries Start in an established stream. A one-second valid-sample silence, USB error, publisher failure or invalid startup releases the device and exposes an error. The separate publisher-readiness deadline remains three seconds. Start/Stop waits run on the worker so Configurator remains responsive. Stop flushes the final partial software block; core output closure is ordered after pending TCP sends.

Only normal Stop/termination guarantees cleanup; forcibly killing a process or removing power cannot guarantee restored USB settings. Startup recovery stops and drains an abandoned acquisition before beginning a new one.

## Verification routes

- `test_Movicom`: software-only parser, captured-wire fixture, signed extremes, fragmentation/noise/CRC, counter limits, metadata, configuration locks/presets, failures, startup retry, cancellation, repeated lifecycle, late discovery and final partial TCP block.
- `movicom_panel_check`: software-only actual shared ParametersView with fake transport; offscreen PNGs at 300 px. Set `MOVICOM_UI_OUTPUT` to an evidence directory and provide fonts for Qt's offscreen backend.
- `movicom_hardware_check --serial SERIAL --seconds 10 --cycles 3 --report report.json`: intentional hardware acquisition. Optional `--sync` verifies continuous clock lock after warmup and saves the per-block ledger. Also accepts `--block`, `--channels` and `--capture` (new per-cycle raw-wire files). Never registered for unattended CTest.
- [service_acceptance.py](../../src/movicom/tests/service_acceptance.py): intentional hardware test through the actual service, remote parameter control, independent TCP subscriber and Recorder. Requires `--runtime`, `--serial`, `--output`; controls its uniquely named child processes and stops the amplifier before exiting. Optional `--reconnect-test` waits for an operator to physically unplug USB for five seconds and reconnect it after the explicit `READY_FOR_UNPLUG` signal, then checks discovery, restart and five seconds of recovered data.

See [build](../how-to/build.md) and [test](../how-to/test.md) for environment setup. Current measured results and package hashes are in the dated implementation record, not timeless guarantees.

The [P300TEST venue](../how-to/p300test.md) supplies the eight-channel P300 setup. Its [2026-09-26 connected-rig acceptance](../history/changes/2026-09-26-p300test.md) records USB hub routes, acquisition/presentation tests and the limits of bench validation.
