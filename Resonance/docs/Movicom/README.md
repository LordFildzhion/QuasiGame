# Movicom

Updated: 2026-09-27.

Native x64 Resonance service. Eight inputs against REF; GND and REF are not data channels.
Fixed nominal 500 Hz. Unfiltered Float64 stream `eeg`, in volts.

Controls: device, channel selection, block size (default 25 samples), optional CED montage,
Start, Stop and Rescan. With CED empty, inputs 1–8 default to
**Cz, Pz, C3, C4, PO7, PO8, O1, O2**, including their coordinates.
A replacement CED uses physical input numbers, also for subsets.
No impedance, gain, mode or trigger controls. Startup waits up to 20 seconds for valid data.

Driver: `driver/movicom/Install.bat`.
MoviEEG.dll and KARDi2.dll are not required.

Voltage conversion follows MoviEEG: ADC count × `2.051 / 12 / 8388607` V.
Timestamps use host reception; the six-bit counter reports minimum detected loss.

**P300 firmware sync**, enabled by default and switchable off before Start, publishes D7 echo clock mappings in `sync`.
Use blocks of at most 500 samples. Select **Movicom firmware echo** in the native
P300 classifier panel; typing uses the saved model's timing choice. P300 records
the mapping and stops on lost synchronization. This does not measure screen-light onset.

Reference: [FTDI D2XX](https://ftdichip.com/drivers/d2xx-drivers/).
