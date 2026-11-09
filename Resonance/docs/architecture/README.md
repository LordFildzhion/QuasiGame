# Architecture

Status: current engineering overview. Scope: the Qt 6 tree in `src/`. Authority: [top-level CMake](../../src/CMakeLists.txt) and the source entrypoints below; inspected 2026-09-15.

## Mental model

Resonance is a set of cooperating processes. A device driver, signal generator, processor, recorder, or display can run independently. Each participating process creates a `ResonanceApp`, which supplies service identity, discovery, stream connections, parameters, state publication, logging, and recording support.

A service exposes two kinds of interface:

- **Control:** its name, current state, available transitions, parameters, status, and control events. The Configurator discovers services and presents this interface; it does not own the device's parameter meanings.
- **Data:** named streams with declared types, channel metadata, timing, and connection information. Producers publish blocks; consumers subscribe through the framework.

Discovery uses UDP. Stream connections use TCP, including the EventBus control stream. The default network mode confines framework discovery, listeners, and outbound connections to loopback. Distributed rigs explicitly select LAN mode; [network](network.md) owns the details and external-protocol boundaries.

```text
service process                         consumer process
  driver / generator                      viewer / processor / recorder
        |                                            ^
  OutputStream -> TCP data connection -> InputStream |
        |
  ResonanceApp + CommunicationLayer
        |
  discovery, description, parameters, state, EventBus
        |
  Configurator / ServiceControl / another service
```

## Read by change boundary

| Change | Canonical context | Source entrypoint |
|---|---|---|
| Find a component and its build ownership | [Source map](source-map.md) | [CMake service list](../../src/CMakeLists.txt) |
| Protocol, parameters, stream lifecycle, paths, recording | [Framework](framework.md) | [Core/Resonance](../../src/Core/Resonance) |
| Discovery or connection behavior | [Network](network.md) | [ResonanceApp.cpp](../../src/Core/Resonance/ResonanceApp.cpp) |
| Configurator, QML, parameter editors, viewer layout | [UI](ui.md) | [quickStimulus](../../src/quickStimulus) |
| Device or service behavior | The component page linked from [source map](source-map.md) | Its configuration/state machine and driver |
| Add a process to the suite | [Add a service](../how-to/add-service.md) | [SignalGenerator](../../src/SignalGenerator) |
| Compile or validate a change | [Build](../how-to/build.md), [test](../how-to/test.md) | Build scripts and module CMake |

## Boundaries to preserve

A state transition is an operation; a stored parameter is configuration. Loading a parameter file must not replay an action such as firing a stimulator. Requested configuration, accepted configuration, and live hardware state can differ; expose refusals and readback explicitly.

Qt 6 is the active build. `src_legacy/Qt5/` and `dist_legacy/Qt5/` remain legacy/comparison material, including some old experiment QML and test oracles. Source presence alone does not imply an active target: the old NVX-136 comparator is retained but excluded from the current top-level CMake. KARDi2 currently uses a Qt 6 service plus an x86 vendor broker.

Keep device-specific constraints with the component. For example, NVX initialization contains an apparently unused voltage read backed by hardware evidence; generic cleanup rules cannot replace that contract. Consult [NVX-136](../components/nvx136.md) before modifying its initialization.

## Current status and history

[Issues](../issues/README.md) owns unresolved work and validation gaps. Build success, passing software tests, and measured physical-device behavior are distinct evidence. This overview claims source inspection, not a new acceptance run.

The [architecture history](../history/migrations/framework-evolution.md), [Qt migration history](../history/migrations/qt5-to-qt6-transition.md), and [module history](../history/migrations/modules.md) retain earlier designs and changes. Read them when the rationale or a legacy behavior matters.
