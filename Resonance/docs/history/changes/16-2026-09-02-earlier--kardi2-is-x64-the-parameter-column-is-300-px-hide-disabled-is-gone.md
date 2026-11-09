# 2026-09-02 (earlier) — KARDi2 is x64, the parameter column is 300 px, hide-disabled is gone

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-09-02-earlier--kardi2-is-x64-the-parameter-column-is-300-px-hide-disabled-is-gone"></a>

### 2026-09-02 (earlier) — KARDi2 is x64, the parameter column is 300 px, hide-disabled is gone

**26/26 enabled CTests pass** out of 30 registered; four hardware/external tests remain disabled by
design (`docs\qa\ctest-qt6-20260902.log`). `validate-dist-qt6.ps1` PASS against Qt 6.11.2.0.

**KARDi2 no longer needs Qt 5 — and neither does anything else.** The Qt 5.15/MinGW x86 island is
gone: `KARDi2.exe` is an ordinary x64 Qt 6 service in `bin\`, linked against the one shared
`Resonance.dll`, and it reaches the PE32-only vendor DLL through **`kardi2-broker-x86.exe`**, a
164 KiB helper that links `/MT` and imports only `KERNEL32.dll`. No `kardi2_x32\` directory, no
second Resonance core, **no Qt 5 DLL anywhere in `R:\dist`**. `arch_qt5-still-needed.md` §1 — the
one entry that said "permanent" — is closed.

Verified on the attached **KARDi2-NP serial 5321**: enumeration through the broker, 59 blocks /
1888 samples at 1000 Hz, live analog on A1–A6, Sync Out commanded and read back, clean return to
`init`. ⚠ The 22-case functional matrix from 2026-08-29 has **not** been re-run against the x64
service; that is the next hardware task.

⚠ **Three build-integration defects came with the changeover, all now fixed.** A clean tree could
not configure *at all* — `KARDi2/CMakeLists.txt` raised `FATAL_ERROR` on the missing broker while
being processed by `add_subdirectory`, so `build-qt6.ps1` produced **zero binaries for the whole
tree**, and the recovery was circular. The broker was not in the ninja graph, so an edited
`broker/main.cpp` deployed stale. And the **vendor USB kernel driver** — which had reached the
distribution as a passenger inside the island — silently vanished with it, leaving `R:\dist` with
no way to enumerate a KARD on a fresh machine. `build-qt6.ps1` now builds the broker first, in its
own x86 environment; `deploy-qt6.ps1` stages the driver into `driver\kardi2\`; and
`validate-dist-qt6.ps1` asserts all three KARDi2 files. Proven by moving `KARDi2\_build-x86` aside
and building from scratch. `build-kardi2-x32.ps1` and `validate-kardi2-x32.ps1` are deleted.

**⭐ The Configurator's parameter column is 300 px, and that is now a contract.** Every service's
parameter editors are designed to fit in it; a long option is not a reason to be wider. Text that
does not fit is elided in the row and shown in full in the drop-down popup and the tooltip. What
this ends: `ParametersView` used to let its content push wider than the pane, and a `ComboBox` sized
itself to its current item, so **every service had its own effective width** — set by whichever
string it happened to publish that was longest. Written down in
[`build_qt5-to-qt6-transition.md` §6a](../migrations/qt5-to-qt6-transition.md), checked by
`scripts\capture-parameter-column.ps1`.

**"Hide disabled options" is removed.** It was on by default and turned "disabled" into "erased",
which is a different statement — in KARDi2 it hid the **sampling rate during acquisition**, and in
neuroMS it emptied a hardware tab. Greying out is the whole of the signal now. The replacement is
**`Parameters::Parameter::visible`**, a real wire attribute defaulting to `true`, so a service says
outright which editors apply. NVX's bipolar-pairs list is now gated on `mode == Bipolar` rather than
on a disabled button; measured against the NVX-52, Impedance mode shows the channel list greyed
rather than gone.

**Cosmetic, reported from the lab:** KARDi2's sampling rate read `250⟶Hz` with the unit halfway
across the row. It was `QString("%1\tHz")`, and a tab in a `ComboBox` item is drawn as a wide gap —
94 px of column width where `"250 Hz"` costs 35. ⚠ `Select` serialises its option **label**, so nine
QML harnesses were repointed with it.

**Two findings raised, neither fixed, both in
[`arch_qt6-work-list.md`](../migrations/qt6-work-list.md):** the KARDi2 broker has **no crash handler**, so a
vendor-DLL fault can leave a physical Sync output latched (§3a); and **NVX counter-gap detection is
inoperative** — 2 142 warnings in 5 s, 2 066 of them a delta of exactly −1, the signature of reading
the wrong word as the counter. `nvxdatathread.cpp` is byte-identical to Qt 5's, so that one is
pre-existing and ships in both generations (§3b). Also new: service **discovery loses services when
about fifteen announce at once** (§3c).

**Lab result, reported by the operator:** on the NVX-136, `nvx136_2021` launches first try and the
new-SDK `nvx136` fails once then succeeds on the second — **the same behaviour as Qt 5**, so the
2021 comparator is doing its job. CED loading is confirmed fixed on hardware.

---

