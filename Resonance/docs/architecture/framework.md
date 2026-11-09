# Framework contracts

Status: current engineering reference. Scope: Qt 6 `Core/Resonance` and its clients. Authority: linked source owns implementation; the preserved [framework history](../history/migrations/framework-evolution.md) supplies prior rationale. Source passages inspected 2026-09-15; no tests rerun for this documentation change.

## Service and transport

[ResonanceApp](../../src/Core/Resonance/ResonanceApp.hpp) is a process singleton. It creates or works with the Qt application and provides a [CommunicationLayer](../../src/Core/Resonance/communicationlayer.hpp), discovery, a stream pool, configuration, and optional recorder. `--serviceName` overrides the advertised name; `--serviceUid` overrides the per-process UUID. Preserve uniqueness when launching comparison instances.

[ServiceDiscovery](../../src/Core/Resonance/servicediscovery.cpp) consumes announcements/descriptions. [ServiceControl](../../src/Core/Resonance/servicecontrol.hpp) addresses a discovered service and sends parameter updates or named transitions. Network mode is fixed before sockets are constructed; [network](network.md) owns binds, advertisements, and permitted peers.

Keep the two configuration inputs distinct: optional `resonance.cfg` beside the executable configures framework settings, while `--serviceConfig <file>` loads a service parameter set through the application/apply path. Invalid files and refused entries must reach the diagnostic/reporting path; neither a file being found nor a JSON parse succeeding proves that the requested service configuration took effect.

The binary protocol's schema is [Protocol/protocol_definition.hpp](../../src/Core/Resonance/Protocol/protocol_definition.hpp). Its generator/switch headers and [protocol.hpp](../../src/Core/Resonance/protocol.hpp) implement serialization. Change the definition and its affected readers/writers together. `RESONANCE_EXPOSE_PROTOCOL` gates direct protocol access; ordinary service code should use framework interfaces. `RESONANCE_STANDALONE` is the non-Qt protocol path. Do not infer compatibility solely from both programs using Qt or sharing a type name.

## Streams, metadata and reconnection

[OutputStream](../../src/Core/Resonance/outputstream.hpp) publishes typed [DataBlock](../../src/Core/Resonance/DataBlock.hpp) objects; [InputStream](../../src/Core/Resonance/inputstream.hpp) subscribes. [StreamInfo](../../src/Core/Resonance/streaminfo.hpp) carries stream/service identity, data type, channel metadata, and connection candidates. [SamplesCollector](../../src/Core/Resonance/SamplesCollector.hpp) assembles samples into blocks; preserve sample counts, rates, timestamps and channel order through transforms.

A producer restart creates a new UUID. Persistent desired-stream configuration must retain the stable service/stream names needed to find the replacement, rather than freezing an old process UUID. Read `StreamInfo::isNull()` and `isEmpty()` before using either as a readiness check: null internal identity and empty/unusable information are different states.

The [StreamPool](../../src/Core/Resonance/internal/StreamPool.cpp) and TCP sender/receiver own connection lifetime. A stream can become ready during construction, before a later signal connection exists; consumers must also inspect current state. Worker-owned callbacks and block buffers must obey thread affinity and ownership. A direct call into a worker object does not become thread-safe merely because that object was moved to a thread.

The stream-pool retry timer starts on its first discovery request, after a Qt event dispatcher exists; the pool itself can be constructed before QCoreApplication in headless services. Output closure is queued behind pending sends and retains the publisher capsule until that closure runs, so immediate OutputStream destruction does not discard a final partial TCP block. These paths have explicit [Movicom acceptance regressions](../history/changes/2026-09-25-movicom.md).

On disconnect/reconnect, reset state whose interpretation depends on the old stream: dimensions, rate, buffers and subscriptions. Match the component's reconnect contract; the [recorder](../components/recorder.md) can rebind a replacement stream into the existing dataset, representing an outage as a timestamp gap.

## Parameter model and updates

[Parameters](../../src/Core/Resonance/Parameters) have a stable wire `name`, display `label`, group, ordering `index`, description, serialized value, and read-only attributes. Parameter objects are not owned by the CommunicationLayer; their owner must keep them alive. The layer observes destruction.

| Property | Meaning | Client behavior |
|---|---|---|
| `enabled=false` | Temporarily unavailable for changes | Keep readable and grey the editor |
| `readOnly=true` | Published readback, not a setting | Keep readable without editing |
| `visible=false` | Inapplicable in this mode | Hide the editor |

Do not implement visibility by hiding disabled controls. Missing `visible` in an older description defaults to visible. Attribute changes must reach both local bindings and remote clients: `setEnabled`, `setReadOnly`, `setVisible`, labels and descriptions use `triggerUpdate` to schedule a description publication.

Local value changes need the appropriate `valueChanged`, `jsonChanged`, and wire update; the base parameter connects `jsonChanged` to `triggerUpdate`. Remote `setJson` runs through the request/apply path, which schedules the response. Use equality guards to prevent binding feedback. Inspect the concrete type rather than assuming all attribute setters have identical notification coverage; remaining gaps belong in [issues](../issues/README.md).

[parameterapply.cpp](../../src/Core/Resonance/parameterapply.cpp) and `CommunicationLayer::applyParametersReported` own batch application. Dependencies can create parameters during an apply (for example, stream-count settings create stream selectors), so the live lookup is repeated. Do not replace this with a one-pass filter over initially existing names. The report records refused entries, is published back to clients, and is emitted synchronously through `parametersApplied` so a later write cannot erase the only evidence of a refusal.

For a stream selector, distinguish desired configuration from `attributes/activeStream` readback. An unsuccessful request can leave the earlier stream active. A recorder or actuator must use the apply result and actual state before proceeding; do not infer success from the presence of a serialized request.

Every parameter, including readouts, needs a service-owned plain-text description explaining meaning, units, application timing and refusal behavior. Run the [description audit](../../src/scripts/audit-parameter-descriptions.py) after adding parameters. UI presentation rules live in [UI](ui.md).

An [Action](../../src/Core/Resonance/Parameters/action.hpp) has no persistent value: `json()` is null, and execution requires an explicit `invoke` marker. Save/load or a repeated description must not fire it. Preserve stable Select option values: some labels are serialized configuration and cannot be renamed as a purely cosmetic change.

## State, status and lifecycle

[ResonanceState](../../src/Core/Resonance/resonancestate.hpp) and [ResonanceTransition](../../src/Core/Resonance/resonancetransition.hpp) publish the current state and available named operations. A transition name is the client's command. Keep device operations in the service state/driver boundary; UI widgets should request transitions and reflect published state.

`stateInfo` supplements the state name. `CommunicationLayer::reportDroppedSamples` publishes the acquisition's cumulative `droppedSamples` count, with an immediate first-loss notification and coalesced updates. The counter path crosses driver/framework threads and must retain its synchronization. Entering a state clears status bookkeeping. Absence of a counter means unreported, not zero; display thresholds belong to clients.

Stop acquisition and let the device release/stop sequence complete before terminating an amplifier service. Abrupt termination of NVX services has wedged physical devices. Keep queued work, timers, and thread-owned objects valid until cleanup finishes; consult [ThreadCapsule](../../src/Core/Resonance/ThreadCapsule.hpp) and the component's shutdown path when changing lifetime management.

## Content paths and recording

`ResonanceApp::rootPath()` uses an existing `RESONANCE_DIR`; otherwise it uses the executable directory, moving up one level when that directory is named `bin`. It does not use the working directory as the distribution root. Launchers still matter for DLL/plugin/environment setup; they are not the sole mechanism for finding content.

`contentPath(kind)` uses these overrides:

| Kind | Environment variable |
|---|---|
| data | `RESONANCE_RECORD_PATH` |
| params | `RESONANCE_PARAMS_PATH` |
| protocols | `RESONANCE_PROTOCOLS_PATH` |
| stimuli | `RESONANCE_STIMULI_PATH` |
| montages | `RESONANCE_MONTAGES_PATH` |
| calib | `RESONANCE_CALIB_PATH` |

Without an override it uses the corresponding root subfolder; missing browse folders fall back to the root. The data folder is created/used as a write destination. `resolveContent(kind,path)` leaves absolute paths alone, handles an already-present kind prefix, searches the override before root, and returns an unresolved original value for the caller's error. Choosers use `startFolder`; a remembered folder is session-only and must still exist. Use these helpers for both browsing and loading so one setting has one meaning.

[Recorder](../../src/Core/Resonance/recorder.hpp) and [HDFRecorder](../../src/Core/Resonance/internal/HDFRecorder.cpp) own file/dataset behavior. Relative/generated recording names resolve under the data path. The Qt 6 numeric dataset extent is exactly the number of written samples. Historical Qt 5 recordings can contain a final unwritten zero row; downstream code must not blindly trim the final row of a Qt 6 file. See [recorder](../components/recorder.md) for format/application details and [migration history](../history/migrations/qt5-to-qt6-transition.md) for the deliberate compatibility difference.

## Diagnostics

Use Qt logging and [logging categories](../../src/Core/Resonance/logging.hpp), not scattered ad-hoc output paths. [DebugConsole](../../src/Core/Resonance/DebugConsole.cpp) is shared by services: `--console` enables it at startup; the Configurator can toggle it at runtime. Closing/hiding the debug console must not terminate an acquiring service. Preserve the Windows console control handling when changing it.

For automated diagnostics, capture stdout/stderr and inspect exit status, configuration refusals, service state and relevant output data. A missing error line is not proof that acquisition or a parameter apply succeeded. [Testing](../how-to/test.md) routes the existing checks; [issues](../issues/README.md) records known gaps.
