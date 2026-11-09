# Choose a support tool

Status: current navigation and ownership guide. Runtime evidence is attached to individual entrypoints; a relocated file is not automatically a validated command.

Start with the [tools index](../../tools/README.md), the affected [component](../components/README.md), and the [verification guide](test.md). Read only the selected tool's README, source and input bundle. Use the [catalog](../../tools/tool-catalog.json) for an exact filename, execution scope, provenance or original-location lookup.

## Choose by task

| Task | Owner |
|---|---|
| Run a maintained Qt6 software check | [Software QA](../../tools/qa/README.md) |
| Investigate device behavior or timing | [Hardware tools](../../tools/hardware/README.md) or the complete [lab toolkit](../../tools/lab/README.md) |
| Recompute an independent numerical reference | [Reference generation](../../tools/reference-generation/README.md) |
| Analyze already-recorded output | [Analysis tools](../../tools/analysis/README.md) |
| Author a Word manual or correspondence | [Publication tools](../../tools/publications/README.md) |
| Study the historical noncausal offline pipeline | [Offline research](../../tools/research/offline/README.md) |
| Work against the retained Qt5 comparator | [Qt5 helper](../../tools/legacy/qt5/README.md) |
| Select a current configuration example | [Configuration index](../../config/README.md) |
| Reproduce an old saved setup | [Captured test fixtures](../../tests/fixtures/README.md) |

## What a status establishes

- **Software run validated:** the named invocation ran against the stated build and inputs. Check the result's actual tests/assertions, skips and scope; it establishes no physical-device acceptance.
- **CLI checked:** help, dry-run, parsing or import behavior was checked. This is not a rendered-publication or service-behavior result.
- **Needs revalidation:** the source and paths were reviewed, but current runtime behavior has not been proved.
- **Hardware:** the selected mode can touch devices, SDKs, serial ports or hardware-owning services. A previous rig's wiring, power limits and session approval do not describe today's rig.
- **History:** a preserved observation, script edition, prompt or result. Its commands and deadlines describe the old session.

## Before using a maintained command

Establish the runtime/build, inputs, output directory and process ownership. Keep raw recordings read-only and put derived results in the named run's output directory. Use only the necessary test-owned service graph; a generic service name can resolve to an operator's running experiment. Retained legacy harnesses require review before reuse, especially if they select or terminate processes by name.

Keep related inputs together. The lab kit uses local Python imports and adjacent QML components, including `PowerGate.qml`; moving one script alone can remove its enforcement path. Offline analyzers consume a particular recording layout and timestamp convention. A CSV or HDF5 oracle already in the history is evidence: preserve its bytes rather than silently regenerating it during cleanup.

Use `W:\MATLAB\startup.m` for a requested MATLAB run. Export MATLAB graphics only when requested; images are PNG and newly requested exported tables are XLSX. Operator manuals remain Word publications with their images.

## Add or change a support tool

Put the tool beside its functional family and link its owning procedure. State purpose, runtime, inputs, output location, device/process effects, and last actual validation. Keep current examples small; preserve a captured historical profile as a fixture before deriving a current example from it.

Update the catalog entry and attach a dated result for substantive verification. Keep an original-to-current relocation record for moved files, exact duplicates and removed caches. Retain history and old results without making them part of every coding task's initial context.
