# Device drivers

Updated: 2026-09-25. Intel/AMD x64 Windows.

Each folder has `Install.bat`. INF installation requires administrator rights.

| Resonance device | Package |
|---|---|
| KARDi2, NVX 24/36/52 | [kardi2](kardi2/README.md) |
| NVX136 / optical media converter | [nvx136](nvx136/README.md) |
| Movicom / FTDI USB serial | [movicom](movicom/README.md) |
| Neuron-Spectrum | [neuronSpectrum](neuronSpectrum/README.md) |
| eStim, Neuro-MS | [neurosoft-ezusb](neurosoft-ezusb/README.md) |
| Arduino boards with CH340/CH341 | [ch340](ch340/README.md) |
| Arduino / Genuino USB serial | [arduino](arduino/README.md) |
| NI acquisition devices | [daqmx](daqmx/README.md) — Internet required |

`COMport`, `arduinoTTL`, `mStim` and `feetStim` use the package matching their USB-serial chip.

Neurosoft WinUSB and EzUSB packages cover overlapping USB IDs. Install only the
required stack, with other Neurosoft device families disconnected.

actiCHamp uses the [Brain Products USB driver](https://www.brainproducts.com/downloads/more-software/).
