# Prompts for coding tasks

These examples work with any coding agent that can read local files and edit the project.
Replace text in square brackets with the actual requirement, symptom or component. Paths use
the current machine layout; adapt the root on another machine.

Give the agent a concrete outcome, constraints and evidence. Let the task index select the
relevant pages rather than requesting a full read of the documentation on every task. The
illustrated Word manuals are for operators and are not required coding context.

## Implement a new service

```text
Implement a new Resonance service for [device/protocol/purpose].

Read R:\docs\README.md and R:\docs\working-with-code.md, then
R:\docs\how-to\add-service.md and the most relevant existing component guide.
Inspect that component's source and the framework contracts it uses.

Requirements:
- Inputs: [SDK, connection, commands, data].
- Outputs: [streams, channel types/units, events/status].
- Lifecycle: [connect, configure, start, stop, disconnect behavior].
- Configuration and UI: [operator settings and persistence requirements].
- Constraints: [supported device/version, timing, compatibility, dependencies].

Implement in R:\src using the existing service conventions. Identify shared-code
consumers before changing framework code. Reuse a comparable module where useful.
Validate with the relevant device-free tests; distinguish checks needing hardware.
Update the component guide, source map and relevant task routes. Record significant
decisions and the implementation change in the new documentation structure.

Deliver the implementation, validation results and any remaining hardware acceptance
steps. Do not deploy to the live rig as part of this task.
```

If the design is still uncertain, replace “Implement” with “Propose the service design and
validation plan first; do not edit code yet,” and supply the SDK location.

## Fix a specific service bug

```text
Fix [symptom] in [service]. Expected behavior: [expected result].
Reproduction: [steps, settings, input file, log/error]. First observed: [build/date].

Start with R:\docs\README.md, R:\docs\working-with-code.md and
R:\docs\components\[service-slug].md. Inspect the linked source and tests.
Check R:\docs\issues\README.md and relevant history for this symptom, including
previous fixes and rejected diagnoses. Treat old OPEN/FIXED labels as dated claims.

Establish whether this is in the current source, deployed configuration, dependency
or test harness. Implement a focused fix that preserves the component's documented
interfaces and hardware constraints. Add a regression check when it can meaningfully
reproduce the defect; run the relevant existing checks.

Update the owning current guide if behavior changes. Add a dated change/incident
record explaining the cause, fix and evidence; update the issue disposition.
Report the actual verification performed and what remains unverified.
```

Example slug: `playback`, `recorder`, `neuroms`, `nvx136`, `signal-viewer` or `tepsound`.
For NVX136 startup, explicitly include the cold-start report and fake-SDK recovery tests;
for playback configuration, include the shared parameter-application contract.

## Investigate a regression before changing code

```text
Investigate why [behavior] differs between [known-good build/configuration] and
[current build/configuration]. Evidence is at [paths]. Do not change code yet.

Use R:\docs\README.md to find the current component and validation route. Read
only the history relevant to this behavior, following corrections and later outcomes.
Inspect source, build manifests and configuration to separate a code regression from
different binaries, SDKs, runtime assets, input data or device state.

Return the strongest supported explanation, competing hypotheses, evidence for each,
and the smallest useful next check. Distinguish source observations from measured
behavior. Do not run hardware tests or deploy unless this task specifically requests it.
```

## Change a parameter or shared framework behavior

```text
Change [parameter/stream/framework behavior] to [new requirement].
Compatibility requirement: [existing saved files/clients/protocol must keep working,
or explicitly describe the permitted migration].

Read R:\docs\working-with-code.md, R:\docs\architecture\framework.md and the
affected component guides. For QML editors read architecture\ui.md; for epoch metadata
read architecture\epochs.md. Trace serialization, dynamic parameter creation,
notifications, producers and consumers before editing.

Implement the change and check affected saved configurations and consumers. Preserve
IDs, units and wire layout unless the requirement explicitly changes them. Run the
relevant targeted tests and document migration behavior if needed. Update the single
owning contract and record the reason for the change.
```

## Validate an existing change

```text
Validate the changes in [files or patch description] against [requirements].

Read the affected component guides and R:\docs\how-to\test.md. Inspect the change
and select the smallest meaningful verification set, including dependent consumers.
Check whether each target is built, registered with CTest, actually executed and whether
its result is software-only, emulator or hardware evidence.

Run the applicable device-free checks. Report failures with their likely layer and
reproduction, and identify any required evidence that is unavailable. Do not equate
a successful build with successful execution or physical acceptance. Update test/evidence
links if the change made them stale. Do not modify the live distribution.
```

## Prepare a deployment

```text
Prepare deployment of [change/build] to [destination]. First produce a reviewable
deployment plan; do not deploy yet.

Read R:\docs\how-to\deploy.md and the affected component guides. Identify the
exact source/build inputs, runtime dependencies, operator-edited configuration and
files that would be overwritten. Check relevant validation evidence. State the
rollback method and the post-deployment checks, including any device prerequisites.

Return a concrete file/configuration impact summary and commands for this destination.
```

When deployment is already intended and authorized, replace the first paragraph with that
explicit instruction and the agreed destination; retain the configuration-preservation steps.

## Keep documentation aligned with a completed change

```text
Update documentation for [completed change] in [source files].
Use R:\docs\maintenance\README.md and the relevant current component/contract page.

Verify claims against source and the available test results. Update the canonical
current page, related task links and issue status. Preserve the previous decision,
change and evidence in a dated history record with links to the new outcome. Avoid
copying the same rule into several pages. Keep illustrated operator Word manuals as
operator documents; change them only if the task includes an operator-facing revision.
Run the documentation link and structure checks.
```

## A short everyday form

```text
[Task and expected result]. Start at R:\docs\README.md, follow the relevant component
and validation route, and inspect the linked source. Use history when needed to explain
this behavior. Implement and verify the change, update its owning current documentation,
and retain the reason/evidence in history. Constraints: [scope and environment].
```

