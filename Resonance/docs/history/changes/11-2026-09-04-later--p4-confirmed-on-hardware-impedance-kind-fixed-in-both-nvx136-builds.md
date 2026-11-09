# 2026-09-04 (later) — p4 confirmed on hardware; impedance kind fixed in both nvx136 builds

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-04-later--p4-confirmed-on-hardware-impedance-kind-fixed-in-both-nvx136-builds"></a>

### 2026-09-04 (later) — p4 confirmed on hardware; impedance kind fixed in both nvx136 builds

**p4 cold-starts first try on the physical NVX-136** (operator, lab). Kept. Note what that rules
out: p4 contains p3, whose three settings sit in the `NVXOpen`..`NVXStart` gap — so a longer gap
is evidently NOT sufficient to cause the 2025 build’s cold-start failure.

**`p5-impedance-kind`** fixes impedance labelling in **both** builds. ⚠ The first patch in the
series that also replaces the 2025 `bin
vx136.exe`; `p0-baseline-rollback` now carries both.

* **2025:** the driver set `kind=Impedance`/`unit=Ohm` correctly and `describeOutputs` threw the
  kind away — a CED `type` column overrode it unconditionally, and the shipped montage carries
  `type = EEG`. Result: `kind=EEG` beside `unit=Ohm`. The override now applies only when the
  stream is not an impedance stream.
* **2021:** `initializeImpedance` published no `kind` and no `unit` at all. It now calls the same
  `describeOutputs()`.

Verified: both builds now publish `{"Impedance": 65}` / `{"Ohm": 65}` in impedance and
`{"EEG": 64, "Trigger": 1}` / `{"V": 64, "bitfield": 1}` in normal — identical to each other.
Names preserved (T7 … GND).

⚠ **A 2x2 experiment is now prepared and unrun:** the 2025 DLL is a strict API superset, so
`nvx136_2021.exe` runs against it with no rebuild. `x-dll-swap-experiment\` swaps it in. If the
2021 code fails cold start on the 2025 DLL, **the vendor DLL is the cause** and no call-sequence
work will fix the 2025 build.

⚠ One ctest run showed 27/28 with an unidentified failure; seven consecutive runs since were
28/28 and it did not reproduce. Not chased further — recorded so it is not forgotten.

---

