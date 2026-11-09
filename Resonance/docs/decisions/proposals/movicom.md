# Movicom eight-channel EEG service

Status: the native x64 option was implemented on 2026-09-25. This page preserves the original options and rationale. The [current Movicom contract](../../components/movicom.md) and [implementation/acceptance record](../../history/changes/2026-09-25-movicom.md) supersede proposed behavior below. [Original investigation](../../history/investigations/movicom-20260925.md).

## Recommended integration

Implement a native x64 Qt6 service, working name `Movicom`, using the installed **FTDI D2XX** interface and the recovered frame protocol. Keep all USB I/O in a worker and present ordinary Resonance parameters, state transitions and Float64 streams. A direct x64 probe already acquired from this amplifier successfully. No new kernel driver is needed on this machine.

Use USB serial identity plus the expected device description for discovery. The current unit is `A8WU1ZVW`, COM14, USB path 10.4; do not hardcode the COM number, physical port or first FTDI device. The generic 0403:6001 VID/PID alone does not distinguish Movicom from unrelated adapters.

The FTDI input-request size and latency timer are material acquisition settings: the tested 64-byte request / 2 ms timer combination produced roughly 2.5 ms host delivery intervals, compared with about 283 ms at defaults. Configure before Start, check results, and restore the original timer on normal teardown. Restoration on abrupt process death remains a lifecycle consideration. Normal UI should not require operators to tune USB parameters.

Retain the unchanged x86 MoviEEG library and a small diagnostic broker/probe as a reference for parity. There is no reason to carry Python 2.6 or the old browser UI into the deployed native service.

The supplied application's **KARDi2.dll is a software-filter dependency**. Its viewer's Check mode calls KARDi filter functions; actual Movicom acquisition uses MoviEEG.dll/FTD2XX. It does not justify routing the device through the existing Resonance KARDi hardware service. The original acquisition/viewer path and offline Fisher training on the provided example data have now been exercised; full live P300 validation remains outstanding.

## Offline Windows driver deployment

Include an offline FTDI driver installation option with the eventual service deployment. A prepared x64 package is available at `R:\equipment\Movicom\Offline-driver-FTDI-2.12.36.20-x64.zip`, with installation instructions in its adjacent folder. It contains the unchanged working FTDI 2.12.36.20 bus/port packages and a small PnPUtil installer wrapper. Signatures, INF catalog membership and archive hashes were verified; clean-PC installation remains an acceptance check. Retain vendor license/copyright material and confirm distribution terms before public release.

The original setup really does embed `drivers\CDM20802_Setup.exe`, but that package is version 2.08.02 from 2010. Preserve it as a reference. No bespoke Windows kernel driver is proposed: the new Resonance service and the signed FTDI USB driver are separate deployment pieces. Do not modify signed INF identities or assume an x64 export supports 32-bit Windows/ARM64.

## Alternatives

1. **x64 service plus x86 vendor broker**, following [KARDi2](../../components/kardi2.md). Feasible: the old DLL acquired on this PC. This preserves vendor parsing, conversion, filters and host-tag synchronization, but also retains opaque behavior and the measured 16.5-second reopen. Isolation and bounded parent-side waits are essential. Useful fallback if protocol parity reveals a missing behavior.
2. **Direct virtual COM port with Qt SerialPort.** The same wire protocol should be usable in principle; this has not been tested. It offers a familiar API but less direct control over FTDI USB transfer buffering. COM numbers change; discovery still needs USB identity. D2XX is the demonstrated native route.
3. **Bridge the old program's shared-memory ring.** The format is recovered, but it retains an old process and its 100 ms polling, two-second ring and weak cursor convention. Reserve for a temporary compatibility comparison, not the primary new service.

## NVX-style controls within demonstrated capabilities

- **Device:** discovered serial/description, rescan, read-only transport details and detected version where available.
- **Start/Stop:** ordinary service transitions and clear init/running/error states. Stop sends the demonstrated stop command, handles/drains pending bytes and releases the device. Do not publish running until valid acquisition frames arrive. Handle unplug/silence and repeated start/stop without blocking Configurator.
- **Sampling rate:** 500 Hz nominal, read-only. No supported hardware rate change was found. Software decimation, if later requested, must be explicitly named and filtered.
- **Block size:** host-side publication setting, proposed default 25 samples (50 ms), configurable independently of USB read cadence. A large publication block must not delay draining the device.
- **Channels:** select any of the eight physical inputs; default all eight. Hardware continues sending all eight. Use CH1–CH8 until a CED montage supplies names, coordinates and types. REF and GND are connectors, not two additional sampled channels.
- **Montage:** normal CED selection/resolution and metadata, with optional software bipolar/reference processing if requested. Do not present a hardware reference switch that the protocol cannot implement.
- **EEG output:** Float64 with confirmed volts conversion, channel kind/unit metadata and standard Recorder/viewer compatibility. Preserve saturation/validity distinctions; do not invent an invalid-electrode sentinel.
- **Diagnostics:** serial, received samples, detected missing samples, CRC errors, resynchronization, duplicates, silence and clock observations. Six-bit counter limitations must remain explicit; ambiguous long losses cannot be reported as exact counts.
- **Filters:** default unfiltered acquisition. The old library's selectors are software filters with currently unidentified cutoff labels. Existing Resonance processing can provide named filters; any acquisition-side software filters must be labelled and validated separately.
- **No advertised impedance, trigger input/output, active shield, programmable gain or battery controls:** none were established from the supplied API/protocol. The user reports only GND, REF and eight channels. Unknown status bits and host synchronization tags are not triggers.

P300 software event streams remain separate from the EEG stream. The demo's `sync_correction=0.04` is a legacy experiment setting, not a universal device delay. Physical display-onset validation would require an appropriate external measurement arrangement; the current material does not establish one for this unit.

## Implementation and acceptance plan

1. Put protocol/CRC/sign-extension/partial-frame/counter logic in a hardware-independent module. Test frame splitting, corruption, false DA markers, sign extremes, modulo wrap and ambiguous loss. Captured frames provide regression fixtures; preserve provenance and avoid assuming connected-electrode data.
2. Add the D2XX worker and bounded state machine, discovery by serial, startup timeout, stop/close and hot-unplug recovery. Register device-free tests; keep real hardware checks opt-in. Confirm repeated lifecycle and device exclusivity. Configure 500,000 baud/8N1/no flow control before a recovery stop on a newly opened handle; do not assume termination of an acquisition process stops the hardware.
3. Add normal NVX-style configuration, montage, streams, cumulative diagnostics, launcher/icon, build/deploy integration and current component documentation. Proposed source folder: `src/movicom/`; this is not present yet. Follow [add-service](../../how-to/add-service.md).
4. Validate a known analog signal for scale, polarity, channel order, noise and saturation. The DLL arithmetic strongly suggests nanovolts, but the physical calibration is not yet proven. Characterize the nominal 500 Hz clock against a reference; the short optimized probes estimated about 500.9 frames/s.
5. Run an extended capture through Configurator and Recorder, including channel subsets, montage metadata, block sizes, stop/restart and a deliberate unplug/reconnect. Distinguish transport continuity from usable EEG and synchronization accuracy. If host-tag clock alignment is implemented, validate echo wrap, delay and stale-tag handling separately.
6. Test offline driver installation and acquisition on a second x64 Windows PC without relying on Windows Update. Check installation with the amplifier initially connected and initially absent, and retain original signed packages and installation logs.

The investigation proves practical acquisition paths. It does not yet establish production acceptance, calibrated amplitude, long-run stability or ERP timing accuracy.
