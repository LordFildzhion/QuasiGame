# Not done — known gaps

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-not-done--known-gaps"></a>

### Not done — known gaps

* **Hardware exercised: NVX-52, NVX-136 and Neuron-Spectrum-65.** The NVX-52 extensively on
  2026-08-12 (acquisition, parameter application, restart-and-reconnect, recording to file);
  the media converter on 2026-08-15; the Neuron-Spectrum-65 on 2026-08-15 (acquisition, rate
  sweep, impedance, front panel — see [neuron-spectrum.md §10](../components/neuron-spectrum.md#history-10-verified-on-hardware)).
  `actiCHamp`, `EyeLink`, `KARDi2` and NI-DAQmx remain untested; they compile and
  link, nothing more.
* **`actiChamp` is worse than untested — it cannot work as shipped.** `actichampdll.cpp`
  resolves its entry points from `ActiChamp_x86` via `QLibrary` while the module is x64-gated
  and links `ActiChamp_x64`, so every function pointer is null at runtime; `actiChamp.bat`
  starts `signalGenerator`; `EEGDriver::auxChannels` is never assigned but decides EEG-vs-AUX
  scaling; and its poll interval computes `1000 / samplingRate` in integers, which is 0 at
  1 kHz and above. Treat it as a port that was never finished.
* **`mingw32` / `mingw64` are behind `msvc64`** and need rebuilding before use.
* ⚠ **Always STOP an amplifier service before terminating it.** Killing `nvx` mid-acquisition
  wedges the device until it is replugged. Send the `stop` transition, wait, then `!terminate`.
* **Open defects not yet fixed**, all documented in [known-issues.md](../incidents/README.md):
  `TARGET_OS_WINDOWS` never defined under MSVC (§3); `nvx136` library path depends on
  `CMAKE_BUILD_TYPE` (§4); `GeneratedBuildInfo` version strings are null (§5); `eyelink/main.cpp`
  wrong-case include (§6).
* **`bin/Resonance/**` is user-editable configuration**, not build output. When replacing a
  deployment, copy it forward from the old tree or the rig loses its montages and tuned head
  display — see [deployed-vs-repo.md](../migrations/deployed-vs-repo.md).
* **Hardware instability parked.** `-j16` is clean on either core group; `-j32` fails. No
  reproducer isolated yet ([known-issues §11b](../incidents/README.md)).

