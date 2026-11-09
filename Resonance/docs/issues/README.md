# Issue registry

**Reviewed:** 2026-09-15. **Scope:** current Qt 6 tree unless an entry says otherwise. No build, device test or deployment was performed during this documentation review. Owners and priorities are unassigned.

**Source-observed** means the named implementation/configuration still has the relevant shape; it does not mean a runtime failure was reproduced today. **Reported—needs recheck** means historical evidence remains unresolved and must be reproduced or reconciled before a fix is prescribed. **Proposed** means a design or product choice, not an accepted coding task.

## Later hardware findings

- <a id="ttl-001"></a>**TTL-001 — external Nano repeater back-powering /
  long pulses (2026-09-18).** Dedicated external `arduinoTTLrepeater`, not
  the full ArduinoTTL generator. Recorded 112.2–112.4 ms LOWs instead of 3 ms;
  reset with unchanged firmware and input diodes restored 3.0–3.2 ms,
  420/420 passed at 5/10/20/100 Hz. User subsequently reported recurrence
  after diode removal. **Input/back-power path implicated; precise mechanism
  unresolved; present faulty state to be preserved for diagnosis.** No COM4
  opening, reset, reflash or USB interruption before measuring supply and
  input/output behavior. Later user finding: Nano-only reset insufficient;
  both eStim and Nano required power-off. User scope also shows increased
  delay, not yet quantified. Retain diodes; recovery is not root-cause proof.
  [Evidence and wiring authority](../history/investigations/diode-trigger-viewer-20260918.md).

## Source-observed work (documentation review)

| ID | Finding and evidence | Next action / completion evidence |
|---|---|---|
| <a id="test-001"></a>**TEST-001** | Tests built but unregistered: [`Core/Resonance/tests/CMakeLists.txt`](../../src/Core/Resonance/tests/CMakeLists.txt) defines 7 executables and no active registration; [`quickStimulus/CMakeLists.txt`](../../src/quickStimulus/CMakeLists.txt) defines 17 executables, 8 registered and 9 unregistered (lines 328–414). | Register meaningful invocations with required environment/arguments. Include all three `test_NetworkMode` modes. Show discovery and results for the intended targets; a green aggregate alone cannot establish coverage. |
| <a id="test-002"></a>**TEST-002** | Topography/palette reference cases use `TOPO_REF_DIR`, default to `R:/dist_legacy/Qt5/_build/topo-ref`, and skip when inputs are absent. See [`topofield_test.cpp`](../../src/quickStimulus/tests/topofield_test.cpp) and [`cedpalette_test.cpp`](../../src/quickStimulus/tests/cedpalette_test.cpp). The retained oracle directory moved with the Qt 5 tree; MATLAB/Python generators remain in `R:\config`. | Put versioned reference artifacts and generation instructions in a durable, discoverable location. Include TepSound's topology tests in the review. Prove the intended oracle cases actually execute; do not describe the local artifacts as missing. |
| <a id="build-001"></a>**BUILD-001** | [`GeneratedBuildInfo.hpp`](../../src/Core/Resonance/GeneratedBuildInfo.hpp) contains zero-initialized `Date`, `Revision`, `Branch` pointers. `R:\src` has no Git metadata. | Define an honest source/build identity, generate it during the build, and verify a binary reports it. Version-control initialization and handling of historical uncommitted Qt 5 changes need a separate scoped change; do not invent a revision. [Earlier finding](../history/incidents/11-generatedbuildinfo-is-broken-in-the-cmake-build.md). |
| <a id="build-002"></a>**BUILD-002** | [`runtime-content/qt.conf`](../../src/runtime-content/qt.conf) still specifies `Qml2Imports=qml`. Historical Qt 6 inspection found the recognized key is `QmlImports`; default directory layout currently masks the difference. | Use the correct key and verify a clean process resolves imports with no inherited launcher environment, including a non-default import location. [Evidence](../history/incidents/21-qt-6-only-defects-found-during-and-after-the-port.md). |
| <a id="build-003"></a>**BUILD-003** | `R:\dist\env.bat` sets Qt plugin/QML paths without localizing the caller's environment. Historical Qt 6→Qt 5 launch in the same console leaked paths; source/configuration shape remains. | Review launcher plus environment script together: callers use variables after `env.bat` returns, so adding `setlocal` alone breaks them. Verify both launch orders from a reused console. [Evidence](../history/incidents/21-qt-6-only-defects-found-during-and-after-the-port.md). |
| <a id="core-001"></a>**CORE-001** | [`double.cpp`](../../src/Core/Resonance/Parameters/double.cpp) attribute setters emit their local signals without `triggerUpdate` or `jsonChanged`; [`communicationlayer.cpp`](../../src/Core/Resonance/communicationlayer.cpp) listens to `triggerUpdate` for rebroadcast. The older Select-index claim is superseded: [`parameter.cpp`](../../src/Core/Resonance/Parameters/parameter.cpp) connects `jsonChanged` to `triggerUpdate`, and Select emits it. | Exercise a service changing its own Double bounds/step/decimals while a client is connected; pin the required remote attribute update and avoid redundant broadcasts. [Earlier finding](../history/incidents/32-framework-findings-from-building-estim-2026-08-16.md). |
| <a id="sci-001"></a>**SCI-001** | [`ParseCED.cpp`](../../src/Core/Resonance/internal/ParseCED.cpp) reads rounded `theta`/`radius` columns directly. The old reference campaign measured a field discrepancy around 4e-5; TepSound's separate coordinate path was corrected. | Decide whether shared parser precision needs changing; compare the same montage through the current parser and EEGLAB oracle. Preserve fallback behavior for layouts lacking a higher-precision coordinate representation. [Evidence](../history/incidents/26-parseced-reads-the-ced-files-rounded-thetaradius-eeglab-recomputes-them--open-4e-5-on-the-field.md). |
| <a id="nvx-001"></a>**NVX-001** | [`nvx/application.cpp`](../../src/nvx/application.cpp) still calls `NVXAPIInit(nullptr)`. The reviewed SDK guide requests a version-100 configuration string; the null call historically succeeded. | Check the installed SDK contract and use/validate the documented initialization. This is reliance on undocumented behavior, not a newly reproduced acquisition failure. [SDK audit](../history/migrations/qt6-work-list.md). |
| <a id="kard-001"></a>**KARD-001** | [`broker/main.cpp`](../../src/KARDi2/broker/main.cpp) clears triggers on orderly closure and pipe failure, but has no `SetUnhandledExceptionFilter` or `SetConsoleCtrlHandler`. [`service/driver.cpp`](../../src/KARDi2/service/driver.cpp) sends clear→stop→shutdown before a bounded wait and timeout kill. Historical hardware evidence identifies a device-owned Sync latch surviving stop/close. | Review abrupt vendor faults and timeout escalation separately from the implemented normal/parent-loss cleanup. Establish a bounded recovery policy and test the latched-output case on the identified rig; a crash handler cannot guarantee cleanup for every failure. [Risk history](../history/migrations/qt6-work-list.md), [current component](../components/kardi2.md). |

## Reported work requiring recheck

The [pending-review inventory](pending-review.md) preserves actionable tails from investigations and migrations without treating every old “not tested” sentence as a current defect.

| IDs | Scope | First step |
|---|---|---|
| **TEST-003–005** | Historical viewer harnesses, epoch integration coverage, cross-generation evidence | Locate executable checks and prerequisites; separate absent evidence from a failing implementation. |
| **DATA-001–003** | Classifier extraction reproducibility, recording scale anomaly, MEP-window decision | Recover data lineage and settings before changing analysis defaults. |
| **RUNTIME-001–004** | Discovery fan-out, viewer wedge/memory, framework lifecycle, old chooser/QML incidents | Reproduce on the current tree with bounded instrumentation and process identity. |
| **DEVICE-001–003** | NVX counters, Neuron-Spectrum timing, Neuro-MS physical behavior | Identify firmware/DLL/rig and compare current behavior to the dated evidence. |
| <a id="build-004"></a>**BUILD-004**, **COMPAT-001**, **COMPONENT-001** | Deployment hygiene, Qt 5-only backports, remaining component reports | Reconcile current sources and package before carrying over a suggested patch. |
| **UX-001–002** | Viewer naming/controls and old Configurator navigation reports | Check current UI and determine whether a product change is still wanted. |

## Proposals and external dependencies

- **PROP-001:** [SMI RED500 proposal](../decisions/proposals/smi-red500.md).
- **VENDOR-001–004:** [NVX SDK inquiries and suggestions](../decisions/proposals/vendor-sdk-inquiries.md). Document delivery/reply status when evidence is available.
- **GOV-001:** [upstream author questions](../history/investigations/questions-for-author.md). Local Qt 6 mainline selection is already settled by DEC-001; upstream branch/merge ownership and correspondence remain separate questions.

## Closed or superseded: do not reopen from an old heading

- NVX136 cold start: later hardware confirmation supports the discarded voltage read immediately after open; the old GetVersion/reopen theory is superseded. Current ordering is in [NVX136](../components/nvx136.md).
- Qt 6 Double editor: current `Resonance__Parameters__Double.qml` uses `self` inside the validator and guards missing attributes. The old `parent` diagnosis no longer describes it; CORE-001 is a different issue.
- Recorder partial parameter application/refused-slot continuation, field-bug task queues, channel-list Space handling and parameter-file persistence have later fixes. Their old “queued” states are not active tasks.
- KARDi2 private Qt 5 island, FieldTrip/DAQmx unported status and retired tepService/MioStim port tasks are superseded.
- The EMG electrodes were correctly on amplifier inputs **65/66**. The proposal to move them to AUX positions **73/74** was withdrawn.
- NVX trigger output was physically validated later; old “unverified” and mirror questions must be read with the campaign amendments. The four-view TepSound GC crash is closed; RUNTIME-004 preserves only its unverified broader follow-up.

When closing an issue, add the build/source identity, reproduction or test result, and date; preserve its ID in history. Do not copy the full registry into component pages—link the relevant IDs and keep the contract there.
