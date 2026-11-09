# KARDi2 — audit and 2020 SDK alignment — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/kardi2.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-kardi2--audit-and-2020-sdk-alignment"></a>


**Written: 2026-08-15. Status block and §9 added 2026-09-02.** Covers `R:\src\KARDi2` (the
KARDi2N/KARDi2NP ECG-polygraph service) and its vendor SDK. Read
[architecture.md](../migrations/framework-evolution.md) first for what a service is, and
[known-issues.md](../incidents/README.md) for the tree-wide defect list.

⚠ **KARDi2 is no longer a Qt 5 exception.** Since 2026-09-02 it is an ordinary x64 Qt 6 service
in `R:\dist\bin`, built by `build-qt6.ps1` against the one shared `Resonance.dll` like everything
else. `KARDi2.dll` is still PE32/i386 and MCS still ships no x64 build — that fact has not
changed — but the service no longer has to *be* x86 to use it. It reaches the DLL through
`kardi2-broker-x86.exe`, a 164 KiB x86 helper whose only import is `KERNEL32.dll`, over framed
anonymous pipes. **§10 is the current architecture. §8 and §9 are the two earlier islands, kept
because they explain why the shape is what it is.**

⚠ **Qt 5 is no longer structurally necessary anywhere in the tree.** KARDi2 was the last case. See
[qt5-still-needed.md](../migrations/qt5-still-needed.md) and
[qt5-to-qt6-transition.md §6](../migrations/qt5-to-qt6-transition.md).

⚠ Distribution paths in §1–§9 predate the 2026-09-02 tree rename and the island's removal.
`R:\dist` now means the Qt 6 distribution; `R:\dist\msvc64` is now `R:\dist_Qt5\msvc64`; and
`R:\dist\mingw32`, `R:\dist\mingw64`, `R:\dist\_build` and `R:\dist\kardi2_x32.zip` are preserved
under `R:\dist_2026aug\`. `R:\dist\kardi2_x32\` no longer exists at all. The old island's private
CMake root and its private copy of the Resonance core are preserved, out of every build, at
`R:\src\KARDi2\_legacy\qt5-island`.

---


<a id="history-1-what-requipmentmcs_kardi2n_2020-actually-is"></a>

## 1. What `R:\equipment\MCS_KARDi2N_2020` actually is

It is **not a newer SDK**. Every header, binary and driver file in it is byte-identical to what
was already vendored in `R:\src\KARDi2\3dparty`:

| File | Status |
|---|---|
| `Defines/CPP/KARDi2.h` | identical (md5 `c33a0b08…`) |
| `Defines/DELPHI/K2DLL_D.pas` | identical (md5 `b203d944…`) |
| `Test&DLL/KARDi2.dll` | identical (md5 `b6195c26…`), PE32 **i386**, built **2019-11-25** |
| `Test&DLL/KARDi2N.exe` | identical (md5 `16e4e087…`), 2008 |
| `Driver/**` (`McsUsb30.sys` ×2, `WdfCoInstaller01009.dll` ×2, `.inf`, `.cat`) | all identical |
| `Doc/…Руководство прикладного программиста.doc` | identical |

The package adds exactly **two documents**, and one of them matters a great deal:

* `Doc/KARDi2N-Руководство прикладного программиста.pdf` — the programmer's manual, **v3 of
  6.2014**, in PDF. Same content as the `.doc` already vendored.
* `Doc/Дополнение - работа с триггерными каналами.pdf` — **"Уточнение от 03_08_2023"**, a
  supplement defining `K2GetTriggers`/`K2SetTriggers` and the trigger bit layout in the service
  word. This document did not exist in the tree and is the authority for code the driver
  already contained.

So "porting to the 2020 SDK" is not a binary migration. It is **conforming the driver to the API
contract that this package finally documents** — and the driver did not conform.

`3dparty` now carries the complete package; the two PDFs were copied in and the trees verified
identical.

**The `2020` in the folder name is a packaging date.** The DLL is 2019, the manual is 2014, and
the supplement inside it is 2023.


<a id="history-2-how-the-api-contract-was-established"></a>

## 2. How the API contract was established

Three sources disagree with one another, so none was trusted on its own:

| Source | `K2Info` | `K2GetVersion` | Info struct |
|---|---|---|---|
| `Defines/CPP/KARDi2.h` (vendor C++) | 2 params | 0 params | 4 fields **+ `double dVoltInBit`** |
| `K2DLL_D.pas` (vendor Delphi) | 3 params | 3 params | 4 fields |
| Programmer's manual §K2Info | 3 params | 3 params | 4 fields |

The tie-break is the DLL itself. `KARDi2.dll` exports **undecorated** names, so a wrong
declaration cannot fail at link time — but every export is `__stdcall`, and a `__stdcall`
epilogue encodes its own argument byte count in `ret N`:

| Export | `ret N` | Arguments | Driver declared |
|---|---|---|---|
| `K2Info` | **12** | **3** | **2** ❌ |
| `K2GetVersion` | 12 | 3 | 0 ❌ (never called) |
| `K2SetDebugMode` | 8 | 2, `__stdcall` | 2, **`__cdecl`** ❌ |
| `K2Read` | 16 | 4 | 4 ✅ |
| `K2SetGain`, `K2GetGain`, `K2GetVoltInBit`, `K2GetInputRange` | 12 | 3 | 3 ✅ |
| `K2GetTriggers`, `K2SetTriggers`, `K2SetSampling`, `K2GetSampling`, `K2GetResolution`, `K2SetTimeOut` | 8 | 2 | 2 ✅ |
| `K2Open`, `K2Close`, `K2Start`, `K2Stop`, `K2Reset`, `K2GetID` | 4 | 1 | 1 ✅ |
| `K2GetCount` | plain `ret` | 0 | 0 ✅ |

Disassembly confirms the arity rather than inferring it — `K2Info` reads its third argument
directly:

```
4572d0:  mov ecx, DWORD PTR [ebp+0x10]   ; arg3 = Size
4572d3:  mov edx, DWORD PTR [ebp+0x0c]   ; arg2 = PInfo
4572d8:  call 0x455738                   ; worker(dev, PInfo, Size)
```

and the worker validates it:

```
45573e:  cmp ecx, 0x1c      ; Size vs 28
455741:  jb  0x4557b9       ; too small -> return failure, write nothing
45574b:  mov [esi+0x18], edx  ; Channels   at offset 24
455763:  mov [esi],     edx  ; Model      at offset 0
455771:  mov [esi+0x4], edx  ; SerialNumber at offset 4
455786:  lea eax,[esi+8] ; call 0x4099e8  ; ProductionDate at offset 8 (SYSTEMTIME)
```

Two conclusions follow. The structure is **exactly 28 bytes** — and the vendor C++ header's
trailing `double dVoltInBit` is a **phantom field the DLL never writes**. Use `K2GetVoltInBit`
for scaling, which is what the driver already did.

The linker corroborated all of it. Before the fix:

```
Warning: resolving _K2Info@8 by linking to _K2Info
```

`@8` is the caller's belief (two 4-byte arguments) against the DLL's `ret 12`. MinGW's
stdcall-fixup resolved it silently. After the fix it reads `_K2Info@12`, and `_K2SetDebugMode@8`
joins the decorated list.


<a id="history-3-findings"></a>

## 3. Findings

Severity is about consequence on hardware, not about how hard the fix was.

<a id="history-31-critical"></a>

### 3.1 Critical

**F1 — `K2Info` called with two arguments against a three-argument `__stdcall`.**
The callee pops 12 bytes, the caller pushed 8, so **every call left the stack 4 bytes out** —
inside a loop over devices, so the drift accumulated. The `Size` the DLL used was whatever
happened to be on the stack; if it was below 28 the call simply failed, and if it was large the
call "succeeded" on a corrupted stack. *Fixed: declared with three parameters, called with
`sizeof(info)`.*

**F2 — the `Driver` constructor never opened the device before `K2Info`.**
`enumerateDevices()` called `K2Open` first; the constructor did not. The DLL's `K2Info` worker
branches on a flag the open sequence sets (`cmp BYTE PTR [eax+0x190],0`) and, when it is clear,
**zeroes `Model` and `SerialNumber`** instead of failing. The constructor compared
`info.SerialNumber == serialNumber`, so on an unopened device it compared against 0 and never
matched. `m_id`/`m_channels` stayed 0, and acquisition could not start. *Fixed: open before
querying, and keep the matched device open for `initialize()`.*

**F3 — the channel list was hardcoded to 12 analog channels.**
`Config::updateChannels()` published a fixed list of `Channel 1…Channel 12` plus 6 derived
channels, ignoring the device entirely, while `Driver::initialize()` rejected any list whose
size was not `m_channels + 6`. Per the manual's model table the range is **3 channels
(KARDi2/4N, model 1204), 9 (KARDi2N, 1209) and 12 (KARDi2-NP, 1402)** — so on every model except
the 12-channel polygraph, **start could never succeed**. *Fixed: the list is built from the
selected device's model and channel count.*

**F4 — the result of `initialize()` was discarded.**
`Config::start()` assigned it to an unused local. Every failure above — no device, wrong channel
count, a failed SDK call — therefore moved the service to `running` with **no stream, no error
and no log**, which is indistinguishable from a working amplifier until someone notices there is
no data. *Fixed: a null result logs the reason and drives the state machine to `error`.*

<a id="history-32-high"></a>

### 3.2 High

**F5 — `K2SetDebugMode` declared without `WINAPI`.** Every other prototype had it. The DLL is
`__stdcall` (`ret 8`), the declaration was `__cdecl`, so caller and callee both popped: an 8-byte
imbalance on a call made once per start. *Fixed.*

**F6 — the trigger handler was a context-less lambda.**
`connect(stream, &InputStream::blockReceived, [this](DataBlock){…})` has no receiver object, so
the connection outlives both the stream and the `Config` it captures — a use-after-free once
either dies. It also ran on whichever thread delivered the block while reading the `driver`
member unsynchronised, and could dereference it after `stop()` had nulled it. *Fixed: `this` as
context object, plus a null check.*

**F7 — trigger connections were duplicated.** `newTriggerStream()` ran on every `jsonChanged`
and on every `ready`, adding a fresh lambda each time without removing the old one. After N
reconfigurations one trigger message drove the device N times. *Fixed: both connections are
tracked and disconnected before being rebuilt.*

<a id="history-33-medium"></a>

### 3.3 Medium

**F8 — `1 << 31` on a signed `int` for the cardio-detector bit.** Shifting into the sign bit is
undefined, and the arithmetic right shift that followed turned a set bit into **-1, not 1**, so
that channel published the wrong value whenever a pacemaker pulse was detected. The other four
trigger bits (27–30) were unaffected. *Fixed: the service word is read as `uint32_t`.*

**F9 — `K2Read`'s result was ignored and its output was uninitialised.**
`size_t count;` was declared without initialisation, passed to a function expecting
`unsigned int*`, and then tested with `if(count>0)` — so a failed read that left `count`
untouched was processed as though it held data. *Fixed: initialised, the return code is checked,
and a read failure surfaces as a service error.*

**F10 — a partial trailing frame was silently dropped.** `samples = readings/(m_channels+1)`
truncates, and the leftover words were discarded rather than carried into the next read. One
short read would have shifted every subsequent sample by one channel **for the rest of the
session**. *Fixed: the remainder is retained and prepended to the next read.*

**F11 — the acquisition timer could be a spin loop.** `startTimer(1000*blockSize/samplingRate)`
is integer division: at block size 1 and 4 kHz it is `1000/4000` = **0 ms**, which fires on
every event-loop iteration. The buffer also held exactly one block, so a late tick could never
catch up. *Fixed: `pollIntervalMilliseconds()` rounds up, clamps to ≥1 ms and polls at 0.75× the
block interval; the buffer holds ≥2 blocks.*

**F12 — the sample counter dropped a bit.** `counterBitMask` masked 26 bits. The 2014 manual
gives the counter the low 31 bits with bit 31 as the pacemaker flag; the 2023 supplement
reassigns bits 27–30 to triggers. That leaves **bits 0–26, i.e. 27 bits** — the mask silently
truncated bit 26. *Fixed to 27 bits, with the derivation recorded in `kardi2logic.h`.*

**F13 — the counter was never checked for continuity**, though the manual explicitly asks for it
("здесь должна быть проверка на корректность автоинкрементации"). Given how much missing-sample
analysis the NVX drivers needed, an ECG driver silently dropping samples is a real risk.
*Fixed: gaps are detected and logged with a running total.*

**F14 — the vendor DLL was driven from two threads.** `K2Open`, `K2SetGain`, `K2Start` ran on
the Resonance main thread; `K2Read` ran on the worker after `moveToThread`. `K2Open` alone blocks
**1–1.5 s per device** by the manual, so a scan froze the UI. *Fixed: a persistent worker thread
is created once and every SDK call is marshalled onto it, as `nvx` does.*

**F15 — `stop()` released the device asynchronously.** It posted `deleteLater` and returned, so
`K2Stop`/`K2Close` happened at an unspecified later time while the service already reported
`init`. This is the same hazard as the standing rule that an amplifier must be stopped before
teardown. *Fixed: teardown is a blocking call, and `~Config` stops before joining the thread.*

**F16 — out-of-range samples were published as `+infinity`.** The device substitutes
`0x7FFFFFFF` for a bad electrode contact. The rest of the project — `nvx`, `nvx136`, the signal
viewer, the HDF recorder — represents missing data as **NaN**, and an infinity poisons autoscale
rather than being skipped. *Fixed: `quiet_NaN()`.*

<a id="history-34-low"></a>

### 3.4 Low

**F17 — the `error` state was constructed but never registered.** `machine.addState(error)` was
missing and `onError` was routed to `initial`, so a failure was indistinguishable from a normal
stop; the `QState` itself leaked. *Fixed: registered, `onError` targets it, and `rescan` leaves
it — matching `nvx`.*

**F18 — `qDebug()` printed the info structure outside the success branch**, so a failed `K2Info`
logged uninitialised stack memory (including the phantom `dVoltInBit`). *Fixed.*

**F19 — no channel metadata and non-vendor channel names.** The stream carried no `kind` or
`unit`, so the viewer autoscaled a 27-bit sample counter against millivolt ECG, and channels were
named `Channel N` rather than the vendor's electrode names. The manual gives them per model:
`R, L, F, C1…C6, A1…A3` for the electrocardiographs and `R, L, F, C1, C2, C3, A1…A6` for the
polygraph. *Fixed: names from the model table, with `kind`/`unit` of `ECG`/`V`,
`Trigger`/`bitfield` and `Counter`.*

**F20 — no "at least one channel" guard**, so an empty selection produced a zero-channel
`Float64` stream. `nvx` refuses this. *Fixed.*

**F21 — `volatile Config core;` in `main.cpp`.** A `volatile`-qualified QObject serves no
purpose. *Removed.*

<a id="history-35-examined-and-found-correct--do-not-fix-these"></a>

### 3.5 Examined and found correct — do not "fix" these

* **The sampling-rate list `{250, 500, 1000, 2000, 4000}` is right.** The Delphi unit contains a
  stale `cSamplesRateArray = (125, 250, 500, 1000, 2000)`; the manual's `K2SetSampling` section
  is the contract and matches the code.
* **The trigger bit numbers are right.** The 2023 supplement confirms 27/28 = input triggers
  1/2, 29/30 = output triggers 1/2, and `K2SetTriggers(id, 1 << 29)` to raise output 1 — exactly
  what the driver did.
* **The vendor buffer sizes were not overflowing.** The manual's "Важные комментарии" demand at
  least twelve 4-byte elements for `K2SetGain`/`K2GetVoltInBit`, and the code sized them by
  channel count, which looks like an overflow. Disassembly shows both functions reject
  `Size < channels*4` and then clamp to `min(Size/4, 12)`:

  ```
  454edd:  shl eax,0x2      ; channels*4
  454ee0:  cmp ecx,eax      ; Size >= channels*4 ?
  454ee2:  jb  fail
  454ef8:  shr edi,0x2      ; elements = Size/4
  454efb:  cmp edi,0xc
  454f00:  mov edi,0xc      ; clamp to 12
  ```

  So the calls were in-bounds. The buffers are now sized to the documented twelve-element
  minimum anyway, as defensive conformance — not because a live overflow existed.
* **`K2Read`'s `Size` and `count` are byte counts**, and the code treated them as such.


<a id="history-4-what-changed"></a>

## 4. What changed

| File | Change |
|---|---|
| ✚ `kardi2logic.h` | New. Service-word bit layout with its derivation, poll-interval and buffer-sizing maths, vendor buffer minimum, model codes and the per-model electrode names. Header-only and free of Qt widgets, so it is unit-testable the way `nvxframelogic.h` is. |
| `driver.cpp` / `.hpp` | Corrected `extern "C"` block against the DLL's real ABI; 28-byte `K2Information` with a `static_assert`; open-before-query; error reporting via `lastError()`/`errorOccurred` instead of exceptions across threads; buffers allocated once instead of two heap vectors per tick; partial-frame carry; unsigned service-word decode; counter continuity check; NaN for out-of-range; channel metadata. |
| `config.cpp` / `.hpp` | Persistent worker thread with all SDK calls marshalled onto it; device list drives the channel list; `initialize()` failure handled; `error` state registered; trigger connections tracked and rebuilt; blocking teardown; publisher-ready re-announce; parameter tooltips; group renamed `default` → `main` to match `nvx`. |
| `main.cpp` | Dropped `volatile`. |
| `CMakeLists.txt` | Added `kardi2logic.h` to the target sources. |
| `3dparty/Doc/` | Added the two documents from the 2020 package. |


<a id="history-5-verified-and-not"></a>

## 5. Verified, and not

**Verified.** Builds clean under MinGW 8.1 x86. The linker now emits `_K2Info@12` and
`_K2SetDebugMode@8`, matching the DLL's epilogues. The service launches, announces itself,
publishes its parameter set, joins discovery cycles and settles in `init` — the same behaviour as
the shipped 2024 binary from `R:\dist_legacy\distro-dual\mingw32` run as a control, including the
same benign multicast warning on this machine. All four services in `R:\dist\mingw32` still
launch.

**Not verified — no KARDi2 hardware is attached to this PC.** Everything past `K2GetCount()`
returning 0 is unexercised: device enumeration, open, gain and scaling, acquisition, the frame
decode, trigger output, and the counter check. F1–F3 in particular are *reasoned from the DLL's
own instructions and the vendor documents*, and want a device to confirm. When one is available,
the checks worth running first are:

1. `rescan` lists the device with its real serial number and channel count (proves F1 and F2).
2. `start` on a 9-channel KARDi2N reaches `running` and publishes `9 + selected extras` channels
   (proves F3).
3. `start` with the device unplugged reaches `error`, not `running` (proves F4).
4. A recording shows the counter channel incrementing by exactly 1 with no gap warnings (F12,
   F13), and the cardio-detector channel reading 0/1 rather than 0/-1 (F8).

**✅ Run on a physical KARDi2-NP (model 1402, serial 5321, 12 analog channels) on 2026-09-02.**
Checks 1, 3 and 4's counter half passed outright; check 2 was exercised on that 12-channel NP
rather than on a 9-channel KARDi2N, and the cardio-detector channel read 0 for the whole session,
so F8's 0/1-versus-0/-1 question is answered only on the zero side. The bench also found three
defects that no amount of disassembly would have reached — two in this driver, one in the shared
HDF5 writer. See §9.4. Analog amplitude and channel scaling, cardio-detector assertion and live
USB unplug/replug remain the physical test gaps, so the `K2GetVoltInBit` unit question in §6 is
still open.


<a id="history-6-open-items"></a>

## 6. Open items

* **`R:\dist\mingw32` cannot currently be rebuilt end to end.** `quickStimulus/qml_Recorder.cpp`
  fails under MinGW on an ambiguous `Recorder::addStream` overload — a pre-existing defect from
  the 2026-08-12 recorder work, unrelated to KARDi2. `libResonance.dll` and `KARDi2.exe` in that
  distribution were refreshed by hand and all four services launch, but the rest of the tree is
  still the 2024-08-11 build. Backup: `R:\dist\_build\libResonance.dll.mingw32-aug11.bak`.
  **✅ No longer gates anything, 2026-08-29.** The default distribution builds no MinGW tree at
  all, and the island's CMake root (`R:\src\KARDi2\qt5-island\CMakeLists.txt`) contains exactly
  two subdirectories — `Core/Resonance` and the KARDi2 service — so `quickStimulus` is never
  compiled for x86. The full MinGW dual-arch distribution and that backup are preserved at
  `R:\dist_2026aug\{mingw32, mingw64, _build}`. See §9.
* **`K2SetTimeOut` is not exposed.** The default keeps the isolated section powered for 15
  minutes after `K2Close`, which makes a subsequent open fast. Worth a parameter if operators
  care about the 1.5 s open cost.
* **`K2Reset` is not called before configuration**, unlike the vendor's own example.
* **`K2GetResolution` is unused** — it reports how many of the 32 bits actually carry data at the
  current rate, which the viewer could use.
* **The unit of `K2GetVoltInBit` should be confirmed on hardware.** The manual's prose says
  multiply to get millivolts, but its worked example (gain 2, ±411 mV range, 7.839e-7 per bit)
  is volts per bit, and 0.411/2^19 ≈ 7.84e-7 confirms volts. The driver publishes volts and
  labels the unit `V`; a known calibration signal would settle it.
* **`RESONANCE_KARDI2N_DEBUG` sets `K2SetDebugMode(id, 1)`**, which per the Delphi header makes
  the device emit a 12-channel triangular test signal. That is a useful no-hardware-signal test
  mode and is currently undocumented for operators.

---


<a id="history-7-can-kardi2-be-built-for-x64"></a>

## 7. Can KARDi2 be built for x64?

This section is no longer only a packaging question. It is the **justification for the Qt 6 port's
single architecture exception**: everything below applies verbatim to Qt 6.11.2, whose Windows kit
is x64-only, and it is why one Qt 5 island still ships. Changing the MSVC version does not touch
it.

**Not by changing our code.** A 64-bit process cannot load a 32-bit DLL — that is an operating
system boundary, not a compiler setting, and no amount of rewriting `driver.cpp` moves it. The
`CMAKE_SIZEOF_VOID_P EQUAL 4` gate in `KARDi2/CMakeLists.txt` is a consequence of the vendor
library, not a choice.

There is no x64 `KARDi2.dll`. Every copy on this drive — **20 of them**, across all eight branch
worktrees, the 2021 legacy checkout, six legacy distributions, the current build and the 2020
vendor package — is the same i386 binary, md5 `b6195c26…`.

Our own source is otherwise architecture-clean: after this pass the only 32-bit assumption left
was `size_t` being passed where the SDK wants `unsigned int*`, which is now correctly typed.

<a id="history-what-is-x64-already"></a>

### What *is* x64 already

| Component | Architecture |
|---|---|
| `KARDi2.dll` (user mode) | **i386 only** ← the sole blocker |
| `Driver/amd64/McsUsb30.sys` | amd64 |
| `Driver/amd64/WdfCoInstaller01009.dll` | amd64 |
| `McsUsb.inf` | declares `%Mcs.Name% = MCS, NTamd64` and an `[MCS.NTamd64]` section |

So **the device itself is fully supported on 64-bit Windows.** Only the user-mode translation
library was never rebuilt for it.

<a id="history-four-routes-ranked"></a>

### Four routes, ranked

**1. Ship KARDi2 as an x86 island inside the x64 distribution — recommended.**
Resonance is a multi-process framework: services are separate processes that find each other over
UDP discovery and exchange data over TCP. A 32-bit `KARDi2.exe` therefore interoperates with
64-bit services on the same machine *with no bridging code at all* — the architecture boundary is
already a process boundary.

This is not theoretical; it is the shipped pattern. `R:\dist_legacy\{clinicP300, focus, p300,
mipuzzle}` and `R:\src_legacy\sources_2021\rpe` each carry a `resonance_mingw_32\` sub-tree
(32-bit Qt + `libResonance.dll` + the arch-locked services) alongside their main x64 tree, with
launchers named `KARDi2_mingw_32.bat` that set up the 32-bit environment before starting the
service. `R:\dist_legacy\distro-dual` is the same idea at the top level (`mingw32\` beside
`msvc\`).

Cost: disk space for a second Qt runtime. Risk: none — it is how these amplifiers have always
been run. The same island also carries `NsEzUSB.dll` and `Electrostim.dll`, which are 32-bit-only
for the same reason.

**2. Ask MCS for an x64 `KARDi2.dll` — the clean long-term fix, and cheap to try.**
The vendor demonstrably builds x64 now: `R:\src\nvx\sdk\x64\Release\nvxmcs.dll` (NVX API 2.3,
2025) and `R:\src\nvx136\sdk\x64\Release\NVX136.dll` are both amd64, from the same company
(ООО «Медицинские компьютерные системы»). Their KARDi2 kernel driver already supports x64. The
user-mode DLL is simply stale — 2019, against a manual from 2014 — and the 2023 trigger
supplement shows the product is still being supported. This costs an email and would collapse
the whole problem.

**3. A 32-bit surrogate process with private IPC — do not do this.**
Writing a small x86 helper that owns the DLL and pipes frames to an x64 service is strictly worse
than route 1, because Resonance *already is* that IPC layer, with discovery, typed streams,
parameters and recording. Only worth considering if KARDi2 had to be driven in-process by x64
code, which it does not.

**4. Bypass the DLL and drive `McsUsb30.sys` directly from x64 — not recommended.**
Physically possible, since the amd64 driver exists and the device enumerates on 64-bit Windows.
But the vendor documents only the DLL-level API; the USB wire protocol is undocumented, and the
manual is explicit that the library exists precisely to translate "the hardware-dependent
protocol into high-level calls". That is a reverse-engineering project against a medical device,
which would then need full revalidation on hardware. The effort is out of proportion to routes 1
and 2.

<a id="history-outcome"></a>

### Outcome

Route 2 was tried and **MCS confirmed no x64 build of `KARDi2.dll` exists**. Route 1 was taken:
the island was built and packaged as `R:\dist\kardi2_x32.zip` (now `R:\dist_2026aug\kardi2_x32.zip`)
— see §8. It was taken a second time, and permanently, at the Qt 6 move — see §9.

If an x64 DLL ever does arrive, the module needs nothing beyond removing the
`CMAKE_SIZEOF_VOID_P` gate, pointing the link at the x64 import library, and re-checking the
`extern "C"` block: on x64 there is only one calling convention, so the `__stdcall` arity traps in
§2 disappear — but `K2Info`'s third parameter and the 28-byte structure are ABI facts that stay
true, and `SYSTEMTIME` keeps the structure at 28 bytes on both architectures.

---


<a id="history-8-the-x86-island--kardi2_x32"></a>

## 8. The x86 island — `kardi2_x32`

⚠ **This section records the 2026-08-15 island, built to sit beside a Qt 5 x64 MSVC distribution.
The island that ships today is its Qt 6 successor — different binaries, different build path,
different launcher. Read §9 for what is deployed; read this for why it is shaped the way it is.**

**Archive: `R:\dist\kardi2_x32.zip`** (13.1 MB, 33 MB unpacked), now at
`R:\dist_2026aug\kardi2_x32.zip`. Staging tree at `R:\dist\kardi2_x32\`, now
`R:\dist_2026aug\kardi2_x32\`. Operator instructions are in its `README.txt`.

```
kardi2_x32\
    KARDi2.bat          launcher — sets no PATH, calls no env.bat
    README.txt
    bin\                KARDi2.exe + KARDi2.dll + libResonance.dll
                        + Qt5{Core,Gui,Network,WinExtras}.dll
                        + libgcc_s_dw2-1 / libstdc++-6 / libwinpthread-1
    driver\             the vendor USB driver, unmodified (amd64 + i386)
    data\               default recording destination
```

Ten binaries, closed over by walking the import tables recursively. `Qt5Gui` is present only
because `Qt5WinExtras` links against it; the service is a `QCoreApplication` and never opens a
window, so no platform plugin and no `qt.conf` are needed. No `resonance.cfg` exists in any
distribution, and `ResonanceApp` treats it as optional. ⚠ Since 2026-08-18 its **absence is a
decision**, not a neutral default: no `resonance.cfg` means `networkMode: loopback`, i.e. the
service talks to nothing off this machine.

<a id="history-why-it-does-not-interfere"></a>

### Why it does not interfere

**Windows searches an executable's own directory before `PATH`.** Every 32-bit DLL sits beside
`KARDi2.exe`, so the x86 service resolves its own Qt and Resonance even when an x64
distribution's `bin\` and `qt\` are first on `PATH`. The launcher deliberately does **not**
modify `PATH` and does **not** call the host `env.bat`; it only inherits `RESONANCE_RECORD_PATH`
if one is already set. The library names do not collide either — MSVC x64 ships `Resonance.dll`,
MinGW x86 ships `libResonance.dll`.

The environment requirement is genuinely nil: the only variable `Core` reads is
`RESONANCE_RECORD_PATH`, and only for recording.

<a id="history-verified"></a>

### Verified

| Check | Result |
|---|---|
| Runs with `PATH` stripped to `System32` alone | ✅ reaches `init` — nothing outside the folder is referenced |
| A 32-bit and a 64-bit `Qt5Core.dll` coexisting in one tree, **x64 first on `PATH`** | ✅ starts normally. Had the loader taken the x64 copy the process would die with `0xC000007B` (`STATUS_INVALID_IMAGE_FORMAT`), so starting *is* the proof |
| x64 `recorderService` discovers the x86 service | ✅ matched the x86 process's own service UUID, 6 references in its discovery log |
| x64 `SignalGenerator` running alongside | ✅ both stable |
| **Acceptance:** unpacked from the archive, dropped into `R:\dist\msvc64\`, launched through `KARDi2.bat` with the full x64 environment active | ✅ running, with the x64 recorder alongside and discovery active |

Installing is one copy — drop the `kardi2_x32` folder from the archive into the distribution root
beside `bin\`, `qt\` and `data\`. It works equally well outside a distribution. The test copy was
removed after acceptance, so `R:\dist\msvc64` is unchanged.

⚠ **"or on another PC on the same network" stopped being true on 2026-08-18.** A service is
loopback-only by default, so an x86 island on a second machine is invisible to the x64 rig unless
**both** carry `{"networkMode": "lan"}`. Two further traps if you try it: `resonance.cfg` is read
from the directory holding the *executable*, so `kardi2_x32\bin\` and `<distro>\bin\` are
**independent scopes** and both need the file; and the archived x86 binaries predate `NetworkMode`
entirely, so they are permanently `lan` and cannot see a default x64 tree on the same machine
either. Rebuild the island rather than putting the x64 tree into `lan` mode.
See [network-isolation.md](../migrations/network-isolation.md).

Still unverified at the time of writing: **no KARDi2 hardware was attached.** §9.4 records the
first live session, on 2026-09-02.

---


<a id="history-9-the-qt-6-island--what-shipped-between-2026-08-29-and-2026-09-02"></a>

## 9. The Qt 6 island — what shipped between 2026-08-29 and 2026-09-02

⚠ **Superseded by §10 after four days.** This is the Qt 5.15/MinGW x86 island rebuilt against
the Qt 6 distribution. It shipped, it worked, and it is gone: no `kardi2_x32\` directory, no
`libResonance.dll`, no Qt 5 DLL anywhere in `R:\dist`. Read it for the deployment reasoning §10
inherited — the ten-binary closure, the loader argument, the `resonance.cfg` scoping — and read §10
for what is actually installed. `build-kardi2-x32.ps1` and `validate-kardi2-x32.ps1`, named
throughout §9.2, **have been deleted**.

**2026-09-02.** KARDi2 crossed into the Qt 6 tree on 2026-08-29 as the port's only architecture
exception. Everything in §7 still holds; §8's island was rebuilt against the Qt 6 distribution
rather than a Qt 5 MSVC one, and is no longer a hand-assembled zip dropped in by an operator — it
is a first-class product of the deploy script.

<a id="history-91-what-is-deployed"></a>

### 9.1 What is deployed

```
R:\dist\
    KARDi2.bat          two lines: call "%~dp0kardi2_x32\KARDi2.bat" %*
    bin\                x64 Qt 6 services + Resonance.dll  ← no KARDi2.exe here
    qt\bin\             Qt6Core.dll, Qt6Gui.dll, …
    kardi2_x32\
        KARDi2.bat      the island launcher — no PATH edit, no host env.bat
        README.txt      operator instructions, rewritten for the Qt 6 distribution
        env.bat         ⚠ inert leftover of the core's own install rule. Nothing calls it, and
                        it names qt\bin and python folders the island does not have
        bin\            KARDi2.exe + KARDi2.dll + libResonance.dll
                        + Qt5{Core,Gui,Network,WinExtras}.dll
                        + libgcc_s_dw2-1 / libstdc++-6 / libwinpthread-1
        driver\         the vendor USB driver, unmodified (amd64 + i386)
        data\           default recording destination
```

The ten-binary closure is unchanged from §8 — the reasoning there (Windows searches the
executable's own directory before `PATH`; `Qt5Gui` only because `Qt5WinExtras` links it; no
platform plugin because the service is a `QCoreApplication`) transfers verbatim.

Two of §8's caveats are **retired** by this build:

| §8 said | Now |
|---|---|
| The proof of no loader collision is that a 32-bit and a 64-bit `Qt5Core.dll` can coexist with x64 first on `PATH` | Stronger and structural: the host ships `Qt6*.dll` + `Resonance.dll`, the island ships `Qt5*.dll` + `libResonance.dll`. **The two sets cannot collide by name at all**, so there is nothing for the loader to get wrong |
| ⚠ The archived x86 binaries predate `NetworkMode` entirely, so they are permanently `lan` | The island is rebuilt from the current core and carries `networkMode` and `--networkMode` (verified: both strings are present in `R:\dist\kardi2_x32\bin\libResonance.dll` and absent from `R:\dist_2026aug\kardi2_x32\bin\libResonance.dll`). It defaults to **loopback**, matching the rest of the Qt 6 distribution, and `resonance.cfg` is still read per-executable-directory — so `kardi2_x32\bin\` and `<distro>\bin\` remain independent scopes. See [network-isolation.md](../migrations/network-isolation.md) |

⚠ **Recordings do not land in the distribution's `data\`.** The island launcher sets
`RESONANCE_RECORD_PATH=<island>\data` when the variable is unset, so an operator who starts KARDi2
through `R:\dist\KARDi2.bat` records into `R:\dist\kardi2_x32\data`, not `R:\dist\data`. Listed in
[qt6-work-list.md §8](../migrations/qt6-work-list.md).

<a id="history-92-building-deploying-and-validating-it"></a>

### 9.2 Building, deploying and validating it

Three scripts, all in `R:\src\scripts\`:

| Script | What it does |
|---|---|
| `build-kardi2-x32.ps1` | Configures and builds `R:\src\KARDi2\qt5-island` into `R:\src\_build-kardi2-x32` with `C:\Qt515\5.15.2\mingw81_32`, `C:\Qt515\Tools\mingw810_32`, and the CMake/Ninja under `C:\Qt515\Tools`. Then stages `runtime\bin\` by copying the four Qt 5 DLLs and the three MinGW runtimes, plus `KARDi2.bat`, `README.txt` and `3dparty\Driver\*`, and fails loudly if `KARDi2.exe`, `KARDi2.dll`, `libResonance.dll` or `Qt5Core.dll` is missing |
| `deploy-qt6.ps1` | Invokes the above unless `-SkipBuild`, copies `runtime\*` to `<distro>\kardi2_x32`, and installs `KARDi2\KARDi2_Qt6.bat` as the distribution root's `KARDi2.bat` |
| `validate-kardi2-x32.ps1` | Checks the 15-file manifest, runs `objdump -f` over `KARDi2.exe`, `KARDi2.dll`, `libResonance.dll` and `Qt5Core.dll` and requires `pei-i386` / `architecture: i386` on all four, then launches through the *root* `KARDi2.bat` and asserts the process image is the island's `KARDi2.exe`. `validate-dist-qt6.ps1` repeats the file manifest as part of the whole-distribution check |

The island has its own Conan closure — `R:\src\KARDi2\qt5-island\conanfile.txt`
(`hdf5/1.13.1`, `boost/1.78.0` with `header_only=True`, `gtest/1.15.0`) and its own profile
`profiles\mingw-x86-release` (`arch=x86`, `compiler=gcc` 8, `cppstd=17`, `libcxx=libstdc++11`,
`exception=dwarf2`, `threads=posix`). ⚠ **The header-only Boost option is load-bearing, not an
optimisation.** With compiled Boost the first attempt resolved against the host's VS 2026 x64
binaries instead of MinGW x86. Conan is run with `-c tools.build:jobs=1`; the compile itself is
capped at `-j 6` like everything else on this machine.

The architecture-neutral half of the module — the service-word bit layout, poll-interval and
buffer maths, counter arithmetic and the per-model channel tables in `kardi2logic.h` — is compiled
**into the main x64 Qt 6 build** as `test_Kardi2Logic` and registered with CTest by
`KARDi2/CMakeLists.txt`. Only the vendor calls and acquisition are confined to the x86 process.
(It is one of the few Qt 6 test targets that *is* registered. `Core/Resonance`'s **seven** gtest
binaries carry no `add_test` at all — `Core/Resonance/tests/CMakeLists.txt:95-96` has
`include(GoogleTest)` and `gtest_discover_tests(...)` commented out — and **nine of
`quickStimulus`'s twelve** are unregistered too; only `test_ParameterFile`,
`test_ParameterFileQml` and `test_StreamConnectorQml` reach ctest. ⚠ The island's *own* copy of
`Core/Resonance/tests/CMakeLists.txt` registers all seven properly — five through
`gtest_discover_tests`, `RecorderPath` and the three `NetworkMode` cases by hand — so the fix is
to copy that block back the other way. See [qt6-work-list.md §4](../migrations/qt6-work-list.md).)

<a id="history-93--two-resonance-cores-now-exist-and-they-have-already-drifted"></a>

### 9.3 ⚠ Two Resonance cores now exist, and they have already drifted

`R:\src\KARDi2\qt5-island\Core\Resonance` is a **private copy** of the framework, compiled only
for the PE32 island. Once `R:\src_Qt5` becomes a comparator, this copy is the only Qt 5 Resonance
code that still *ships*. Measured 2026-09-02:

| Compared with | Files differing |
|---|---|
| `R:\src\Core\Resonance` (the Qt 6 core) | 8 |
| `R:\src_Qt5\Core\Resonance` (the Qt 5 comparator core) | 3 |

Three of the eight are genuine Qt 5 API requirements that must never be replayed — `QRegExp` and
`QtWinExtras` in `ResonanceApp.cpp`, `splitRef`/`QStringRef` in `DiscoverURI.cpp` and
`ParseCED.cpp`. The rest are simply **unreplayed**: the island lacks the `Resonance::StreamInfo`
`Q_PROPERTY` qualification in `Parameters/stream.hpp`, and — more seriously — lacks the
`query.size() != 2` bounds guard the Qt 6 `DiscoverURI.cpp` took on 2026-08-28, which is a
UDP-facing out-of-bounds read. In the other direction the island **carries** the trailing-zero-row
fix (§9.4) that `R:\src_Qt5` still lacks; the code is identical to the Qt 6 core's and only the
comment text differs, which is what proves that fix is Qt-5-portable.

**Nothing in the tree marks which differences are deliberate.** Every core change from now on has
to be triaged three ways. See [qt6-work-list.md §3](../migrations/qt6-work-list.md) for the proposed fix (a
diff-check against a declared allow-list, or compiling the Qt 6 core's sources directly from the
island's `CMakeLists.txt`).

<a id="history-94-what-the-first-hardware-session-changed--and-these-repairs-are-qt-6-only"></a>

### 9.4 What the first hardware session changed — and these repairs are Qt 6 only

A physical **KARDi2-NP, model 1402, serial 5321, 12 analog channels** (PnP
`USB\VID_0B6E&PID_2004\180427&095123`) was attached on 2026-09-02 and driven against an
`arduinoTTL` on COM4 through both Sync loops. Full record:
`R:\src\docs\KARDI2NP_ARDUINOTTL_HARDWARE_VALIDATION_2026-09-02.md`. It closed §5's four checks
and found three defects that no amount of reasoning from the DLL could have reached — two in this
driver, one in the shared HDF5 writer that only a physical loop could expose.

**F22 — an output trigger is a device-owned latch, and neither `K2Stop` nor `K2Close` clears it.**
Bench readback with Trigger 1 Out asserted: `K2GetTriggers` = `0x38000000`. After `K2Stop`,
success returned and the readback was still `0x38000000`. After `K2Close` and a fresh `K2Open`,
still `0x38000000`. So pressing Stop with a trigger up left the physical Sync output asserted
indefinitely, and restarting the process did not clear it. *Fixed in `driver.cpp` with a checked
`K2SetTriggers(id, 0)` at **five** points — after a scan gains exclusive access to an idle device;
immediately after the selected device is opened; immediately before acquisition starts; before
`K2Stop` in the destructor; and once more after `K2Stop`, immediately before `K2Close`.* The
repetition is deliberate defence in depth around a hardware output. Final readback after Stop is
`0x18000000` — both inputs idle high, both outputs clear.
⚠ This does **not** make an ungraceful kill safe. If the process, PC or Windows dies with an
output asserted, no destructor runs and the latch stays on until some process opens and clears the
device. This is the KARDi2 form of the standing rule that an amplifier must be stopped before
teardown.

**F23 — sustained sample loss at 4 kHz, invisible to the functional matrix.** A 60-second
all-channel recording at a declared 4,000 Hz stored 191,850 samples in 59.95 s — about 3,200 Hz —
with 908 counter discontinuities and 11,892 proven missing samples. F11's timer asked for a read
every 5 ms, but Windows occasionally delivered it 15–16 ms late, and the F11 buffer held only 50
frames (12.5 ms at 4 kHz). `K2Read` drains the device queue even when the caller's buffer is too
short, so every late tick silently discarded the excess. *Fixed in `kardi2logic.h`:
`readBufferFrames()` now returns `max(2 × blockSize, samplingRate)` — at least one full second,
208 KiB for the widest KARD frame, and the natural bound implied by the device's rule that the
host must read at least once a second — and `pollIntervalMilliseconds()` is capped at **750 ms** so
a very large block size is split into smaller published blocks instead of overrunning that
deadline.* The repeat run:
239,952 samples over 59.9699 s = 4,001.19 Hz, zero discontinuities, zero missing samples.
`blockSize`'s parameter description was reworded to match — a large setting is now safe rather
than unsafe.

**F24 — the shared HDF5 writer appended a row it never wrote.** Not a KARDi2 defect, but the
KARDi2 loop is what exposed it: every numeric dataset was created at extent 1 and extended to
`offset + samples + 1`, so every recording ended with an all-zero row — a fabricated falling edge
on a trigger channel and a counter reset. *Fixed in `Core/Resonance/internal/HDFRecorder.cpp`:
numeric, block, message and event datasets start at logical length 0 and extend only to records
actually written.* Verified on the physical loop: 6,290 data rows against a block sample sum of
6,290, no terminal zero row.

⚠ **All three fixes exist only in `R:\src` — and therefore in the deployed island, which compiles
from it.** `R:\src_Qt5\KARDi2\driver.cpp` has one `K2SetTriggers` call site, not six;
`R:\src_Qt5\KARDi2\kardi2logic.h` still has the 50-frame buffer and the uncapped poll; and
`R:\src_Qt5\Core\Resonance\internal\HDFRecorder.cpp` still writes the trailing zero row. This is
deliberate — the Qt 5 tree is a comparator and no `KARDi2.exe` is deployed in
`R:\dist_Qt5\msvc64` — but **F22 must land before any Qt 5 KARDi2 is deployed again**, because it
is a hardware-output safety defect. Tracked in [qt6-work-list.md §6](../migrations/qt6-work-list.md).

**Also passed on the day.** The deployed-service matrix reached `KARD_MATRIX_DONE cases=22` —
all five sampling rates, all eight gains, block sizes 1/25/100/250/1000, the all / analog /
derived / single / counter channel selections, both trigger outputs, error and recovery, rescan
and parameter round-trip, with no dropped-sample message in the service log. Both Sync loops
passed end-to-end through two deployed services into HDF5: ten Arduino pulses produced exactly ten
falling and ten rising transitions on the KARD input lane, five commanded output cycles produced
exactly five rises and falls on the readback lane and five Arduino edges, and the counter advanced
by one for every stored sample.

**Still not verified on hardware:** analog amplitude and channel scaling (so §6's `K2GetVoltInBit`
unit question is open), cardio-detector assertion, and live USB unplug/replug recovery. The
programme for closing them is in §"Full service test algorithm" of the validation record.


---


<a id="history-10-the-x64-service-and-its-x86-broker--what-actually-ships"></a>

## 10. The x64 service and its x86 broker — what actually ships

**2026-09-02.** The island is gone. KARDi2 is an x64 Qt 6 service like every other, and the only
32-bit thing left in the distribution is a 164 KiB helper executable.

<a id="history-101-the-shape"></a>

### 10.1 The shape

```
R:\dist\
    KARDi2.bat                      an ordinary service launcher, same as actiChamp.bat
    bin\
        KARDi2.exe                  x64, Qt 6.11.2, links the shared Resonance.dll
        kardi2-broker-x86.exe       x86, /MT, imports KERNEL32.dll and nothing else
        KARDi2.dll                  the unmodified PE32 vendor DLL, beside the broker
    driver\kardi2\                  McsUsb.inf/.cat + amd64\ and i386\ McsUsb30.sys
```

`KARDi2.exe` spawns the broker and talks to it over framed anonymous pipes; the broker is the only
process that ever loads `KARDi2.dll`. Windows searches an executable's own directory before `PATH`,
so putting the vendor DLL in `bin\` beside the broker binds it without any environment work.

**Why this is better than the island, in one line each:** one Resonance core instead of two; no Qt
5 DLLs in the distribution at all; the service is built by the same `build-qt6.ps1` run as
everything else; and a vendor-DLL crash takes down 164 KiB of helper instead of the service.

<a id="history-102-building-it"></a>

### 10.2 Building it

`scripts\build-qt6.ps1` builds the broker **before** configuring the tree, in its own `cmd.exe`
with the x86 MSVC environment, into `KARDi2\_build-x86\bin\`. `scripts\build-kardi2-x32.ps1` and
`scripts\validate-kardi2-x32.ps1` are deleted.

⚠ **The order is not optional and the failure mode was severe.** The broker is an *input* to the
`KARDi2` target — CMake `install()`s it and copies it — but this directory cannot build it, because
it is a different architecture and one configure produces one. `KARDi2/CMakeLists.txt` used to
`message(FATAL_ERROR)` on a missing broker, and it does that while being processed by
`add_subdirectory()` from the top-level configure: on a machine that had never run the old island
build, `build-qt6.ps1` produced **zero binaries for the entire tree** — not quickStimulus, not nvx,
not even `Resonance.dll` — and the obvious recovery was circular, because the island build's x64
half needed the `Resonance.dll` that build had just failed to make. It now warns and `return()`s
when configured in-tree, and stays fatal in standalone mode where the broker is the whole point.
Verified by moving `KARDi2\_build-x86` aside and building from scratch: broker configured with
`cl.exe` `HostX86/x86`, tree built, `[238/244] Linking CXX executable runtime\bin\KARDi2.exe`.

⚠ **The USB kernel driver is not a build output**, and removing the island silently dropped it from
the distribution — `R:\dist` had no `McsUsb30.sys` at all, so a fresh machine could not enumerate a
KARD. `deploy-qt6.ps1` now stages `KARDi2\_legacy\3dparty\Driver\*` into `R:\dist\driver\kardi2\`.
That legacy tree is the **only** copy in the repository; do not delete it as dead weight.

`validate-dist-qt6.ps1` asserts all three of `bin\KARDi2.exe`, `bin\KARDi2.dll` and
`bin\kardi2-broker-x86.exe`. Asserting the set is the point: the service is useless without the
broker, and the broker binds the vendor DLL by directory.

<a id="history-103--the-broker-has-no-crash-handler-and-a-trigger-latch-is-device-owned"></a>

### 10.3 ⚠ The broker has no crash handler, and a trigger latch is device-owned

F22 (§9.4) established that an output trigger is a latch the device keeps: neither `K2Stop` nor
`K2Close` clears it, and restarting the process does not either. The service clears it at five
points, all of which run in **orderly** teardown.

The broker adds a path where no orderly teardown happens. It installs no
`SetUnhandledExceptionFilter` and no console-control handler, and it sets
`SEM_NOGPFAULTERRORBOX`, so a fault inside the vendor DLL is *silent* — the broker vanishes and the
service sees a closed pipe. `Config`'s own `m_broker->kill()` path has the same shape. If either
happens with Sync Out asserted, **the physical trigger output stays driven** until some process
opens the device and clears it.

This is the KARDi2 form of the standing rule that an amplifier must be stopped before its service
is terminated, and it is currently unmitigated. The fix is a `SetUnhandledExceptionFilter` plus a
`SetConsoleCtrlHandler` in the broker that call `K2SetTriggers(id, 0)` before dying, and replacing
the unconditional `kill()` with a "clear triggers, then close" request that only escalates to
`kill()` on timeout. Tracked in [qt6-work-list.md](../migrations/qt6-work-list.md).

<a id="history-104-verified-on-hardware-2026-09-02-second-session"></a>

### 10.4 Verified on hardware, 2026-09-02 (second session)

Against the same physical **KARDi2-NP, model 1402, serial 5321, 12 analog channels**, through the
deployed x64 service and its broker:

| Check | Result |
|---|---|
| Device enumerated through the broker | `Device ID = #5321 (12 channels)` |
| Parameters published | 6, all with `visible=true` on the wire |
| Sampling-rate label | `250 Hz` — §10.5's cosmetic fix, on the wire |
| Acquisition at 1000 Hz | **59 blocks, 1888 samples, 18 channels** |
| Analog data | A1–A6 live, 43–72 mV means, peak-to-peak 0.38–1.56 mV |
| Trigger command → Sync Out | commanded on then off; readback lane showed the transition |
| Stop | service returned to `init` cleanly |

Harness: `scripts\kardi2-hardware-service-probe.qml`, driven through
`quickStimulus.exe -l`. The 2026-08-29 22-case matrix in §9.4 has **not** been re-run against the
x64 service; that is the next hardware task.

<a id="history-105-the-sampling-rate-label"></a>

### 10.5 The sampling-rate label

`config.cpp` built the rate options as `QString("%1\tHz")`. A tab inside a `ComboBox` item is drawn
as a wide gap, so the unit rendered halfway across the row instead of beside the value, and the
string cost **94 px** of parameter-column width where `"250 Hz"` costs 35. It is now a single
space, matching the tree's `<value> Hz` / `<value> kHz` convention.

⚠ `Parameters::Select` serialises its option **label**. Nine QML harnesses sending
`serialized: "1000\tHz"` were repointed in the same change; no saved `.json` under `R:\dist\params`
carried the old form. See [qt5-to-qt6-transition.md §6a](../migrations/qt5-to-qt6-transition.md).

<a id="history-106-the-sampling-rate-is-visible-during-acquisition-again"></a>

### 10.6 The sampling rate is visible during acquisition again

`Config::setParametersEnabled(false)` disables `device`, `samplingRate`, `blockSize`, `gain` and
`channels` while recording, which is correct — none of them may change mid-acquisition. But the
Configurator's **"Hide disabled options"** switch, on by default, turned "disabled" into "erased",
so the operator lost sight of the sampling rate at exactly the moment they most wanted to confirm
it. That switch is removed tree-wide; disabled now means greyed, and the rows stay readable. No
change was needed in `config.cpp` — the service was already saying the true thing.
