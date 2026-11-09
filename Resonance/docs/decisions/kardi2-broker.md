# DEC-002: Keep the KARDi2 vendor DLL behind an x86 broker

**Status:** accepted; adopted 2026-09-02. **Source review:** 2026-09-15.

## Decision

Build the Resonance-facing KARDi2 service as x64 Qt 6 against the shared `Resonance.dll`. Load the unmodified x86 `KARDi2.dll` in `kardi2-broker-x86.exe`; exchange framed messages over anonymous pipes. The broker has no Qt dependency.

The active service is `KARDi2/service/`, with the broker in `KARDi2/broker/` and their protocol in `KARDi2/protocol.hpp`. The historical whole-service x86 and private Qt 5 islands are superseded.

## Why

The vendor DLL is PE32/i386 and no x64 replacement was available in the reviewed SDK. That restricts the DLL host, not the entire service. Separating the vendor boundary removes the last structural need for Qt 5 while retaining the actual hardware API.

The SDK C++ declarations were also inconsistent with the DLL ABI. Preserve the reconciled calling conventions, argument counts and structure sizes. A package name such as `2020` is not evidence of a newer DLL: the reviewed package combines material from several dates.

## Consequences

- Package the x64 service, x86 broker and vendor DLL together. Missing broker/vendor inputs cause a warning and skip in the top-level build, and failure in a standalone KARDi2 build. A successful overall configure therefore does not prove KARDi2 was included.
- Treat broker framing, timeout, exit and teardown behavior as part of the integration contract. Device acceptance must identify the broker and vendor DLL as well as the service.
- Historical paths under `_legacy` are not uniformly disposable: driver installer material is still used by packaging. Follow the [component reference](../components/kardi2.md).

**Implementation evidence:** [`KARDi2/CMakeLists.txt`](../../src/KARDi2/CMakeLists.txt), especially inputs and skip handling, active service sources and installation; [`protocol.hpp`](../../src/KARDi2/protocol.hpp); [`broker/CMakeLists.txt`](../../src/KARDi2/broker/CMakeLists.txt).

**History:** [KARDi2 integration](../history/components/kardi2.md), especially the vendor ABI reconciliation and successive architectures in §§8–10. Current shutdown clears triggers before stop/shutdown, and broker pipe failure converges on safe closure. KARD-001 concerns abrupt vendor faults and timeout escalation, not an unmitigated ordinary parent exit.
