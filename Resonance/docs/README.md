# Resonance documentation

Start here when working on code. Read [working with code](working-with-code.md) once,
then follow the route for your task. [Current state](current.md) identifies the active
tree and outstanding limitations. Detailed history is available when a task needs it.

## Find the right context

| Task | Read next | Then inspect |
|---|---|---|
| Add a service | [Service recipe](how-to/add-service.md) | A similar [component](components/README.md), its CMake and tests |
| Fix a service bug | Its [component guide](components/README.md) | Named source symbols, validation, related [issues](issues/README.md) |
| Change parameters, streams or recording | [Framework contracts](architecture/framework.md) | Producer, consumer and serialization tests |
| Change epochs or scalp maps | [Epoch contracts](architecture/epochs.md) | [Viewer](components/signal-viewer.md), [TepSound](components/tepsound.md), shared math |
| Change Configurator or parameter widgets | [UI contracts](architecture/ui.md) | Source QML, compiled resources and deployed QML ownership |
| Diagnose discovery or reconnection | [Network contract](architecture/network.md) | Mode, identities, connection and control paths |
| Set up or build | [Setup](how-to/setup.md), [build](how-to/build.md) | Existing scripts and CMake configuration |
| Validate a change | [Testing](how-to/test.md) | Smallest relevant tests and their prerequisites |
| Use a QA harness, lab tool or numerical reference | [Support tools](how-to/support-tools.md) | Selected entrypoint, runtime, input bundle and actual validation status |
| Deploy or package | [Deployment](how-to/deploy.md) or [snapshot](how-to/snapshot.md) | Live configuration ownership and requested destination |
| Investigate a regression | Current component, then [history](history/README.md) | Relevant change record, rejected hypotheses and original evidence |
| Work on an older paradigm | [Legacy scope](architecture/legacy.md) | The named Qt 5 tree and comparator evidence |
| Operate the equipment | [Operator manuals](operators/README.md) | Illustrated Word manual for that device/application |
| Set up the MPRAC EEG practicum | [MPRAC venue](how-to/mprac.md) | Venue launchers, protocols, montage and automatic recording workflow |
| Set up the BPRAC EEG practicum | [BPRAC venue](how-to/bprac.md) | Rhythms/movement and P300 6×6/3×3, twelve-channel NVX or eight-channel Movicom |
| Set up eight-channel P300 testing | [P300TEST venue](how-to/p300test.md) | NVX AUX1 photodiode, Movicom firmware sync, primary subject display and secondary Configurator |

[Architecture](architecture/README.md) explains the system. [Source map](architecture/source-map.md)
locates modules and shared code. [Decisions](decisions/README.md) records accepted tradeoffs and
separates proposals. [Prompt examples](how-to/ai-task-prompts.md) show how to use these routes with
any coding agent.

## Which document owns a fact?

- **Current contracts and procedures:** the relevant architecture, component or how-to page.
- **Implementation:** the source files and build manifests linked from that page. Source presence
  establishes implementation, not physical hardware acceptance.
- **Unresolved work:** [issues](issues/README.md), with status and evidence scope.
- **Past changes and measurements:** [history](history/README.md). Historical “open”, “fixed”,
  commands and deadlines describe the recorded session, not a new instruction.
- **Code-local port and QA records:** [source documentation](../src/docs/README.md) and
  [test evidence](../tests/README.md), retained where they belong.
- **Support commands and fixtures:** [tools](../tools/README.md), [current examples](../config/README.md)
  and [captured fixtures](../tests/fixtures/README.md), with per-entry validation and provenance.
- **Operator publications:** Word files with their original images. They are intended for people
  and are not required context for coding agents.

Read only the relevant pages and linked source. Update the owning current page when a code
change alters its contract; retain the reason and evidence under [maintenance rules](maintenance/README.md).
