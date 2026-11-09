# FieldTrip buffer — native Qt 6 x64 service — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/fieldtrip.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-fieldtrip-buffer--native-qt-6-x64-service"></a>


**Ported 2026-09-05.** Active source `R:\src\fieldtrip`, executable `R:\dist\bin\fieldtrip.exe`,
location-independent launcher `R:\dist\fieldtrip.bat`. The artificial x86 gate is gone: the service
is MSVC v143/Qt 6.11.2 **PE32+ AMD64**. Service identity `fieldtrip`, `hostName=localhost`,
`port=1972` (1..32767), original parameter labels and Float64 `buffer` stream remain compatible.
Both parameters have complete descriptions in the shared light/compact Configurator editors.


<a id="history-source-and-deployment"></a>

## Source and deployment

The supplied download is actually `R:\equipment\Fieldtrip_src\buffer-20260904`. Only the needed
C buffer/client sources and headers, `FtBuffer.h`/`SimpleStorage.h`, licence and provenance were
copied; equipment, fileio/qsub and unrelated toolbox assets are unchanged. Missing official
standalone/demo sources came from FieldTrip commit **5a645ccf1cdc6384d18c4d6a40ce58359a96f44c**:
`realtime/src/utilities/buffer/buffer.c` and `realtime/src/buffer/test/{demo_sinewave,demo_combined,sinewave}.c`.
The buffer package offers BSD/GPL alternatives; this distribution selects BSD and ships COPYING,
LICENSE_BSD and PROVENANCE.md, including the small modern-MSVC compatibility patches.

The service uses the current request builder/wire definitions with asynchronous Qt TCP transport,
avoiding the old blocking C client's integer socket handles. The official C server and demos are
separate **Qt-free x64 tools**, compiled with MinGW-w64 GCC 13.1 and static winpthreads. They deploy
to `R:\dist\tools\fieldtrip`; no Qt 5 or obsolete pthread DLL is shipped. Detailed provenance and
behavior are in [`R:\src\fieldtrip\README.md`](../../../src/fieldtrip/README.md) and
[`upstream/PROVENANCE.md`](../../../src/fieldtrip/upstream/PROVENANCE.md).


<a id="history-worker-reset-and-shutdown"></a>

## Worker, reset and shutdown

Socket creation, IPv4 DNS/connect, requests, parsing, retry and close execute after moveToThread.
Connect has a 5 s deadline, requests 1.5 s. Every response checks version/size/type/shape/count;
input and decoded buffers are bounded to 64 MiB, requests to 8192 samples. The original ten
numeric types are converted from possibly unaligned wire memory to sample-major doubles.

GET_HDR is refreshed after WAIT/data, even for unchanged or increasing counts. Backwards sample
counts reset the request namespace; an empty selection never forms an unsigned `count - 1`.
Channel/rate/type/chunk changes replace the publisher and description. Disconnect clears all
header/rate/channel/cursor state. Initial join/network reconnect starts at the current tail as
before; an observed in-place reset starts at zero in its new namespace. Service UID/name and the
stream name stay constant. FieldTrip v1 has no generation ID, so a same-shape reset that fully
catches up between observations cannot be detected reliably.

Normal `init: start` and `running: stop` actions are unchanged. An intentional recovery change
keeps the service running on connection/header failure, with a state-info diagnostic and automatic
retry every 500 ms. Qt 5 returned to init. Stop aborts the socket, destroys its worker, quits and
joins the thread. Publishers live on the main thread; generation guards reject stale queued blocks
during replacement. The interface stays **data-only**; channel metadata/events are later extensions.


<a id="history-hardware-free-acceptance-and-consumer-boundary"></a>

## Hardware-free acceptance and consumer boundary

Use `tools\fieldtrip\buffer.exe 1972` and `demo_sinewave.exe localhost 1972`: 16 channels, nominal
512 Hz, 32-sample blocks, channel 1 counter, channel 2 unit 1 Hz sine, remaining channels noise or
sine plus noise. `demo_combined` embeds a buffer and a 16-channel/250 Hz feeder. These official
demos use approximate sleeps; waveform frequency is assessed in declared sample time.

`scripts/test-daqmx-fieldtrip.py --only acceptance` exercises official sine → Qt 6 → Resonance →
recorderService/HDF5, PUT_HDR reset to 3 channels/256 Hz with a known 2-unit 4 Hz sine, server
restart back to the official feeder, Stop/Start and normal exit during activity. Analysis checks
sample/block totals, channel count/rate, counter continuity, sine error, amplitude and frequency.
Recordings are separate per shape/epoch: recorderService correctly refuses to append a different
shape to an existing dataset. The foreign-driver QA reader is explicitly rebound after publisher
replacement; automatic foreign-driver reader rebinding is not claimed. The service itself stays
running and reconnects to FieldTrip without another Start.

The Qt 5 comparator is `R:\dist_legacy\dist_2026aug\mingw32\bin\fieldtrip.exe` (PE32). It runs but
predates `--networkMode`, so live Qt 5/Qt 6 parameter/state comparison uses a dedicated LAN-mode
test session. Both pass init → running (buffer advertised, Stop available) → init with the
official sine source, as well as matching both parameter contracts and safe port write/readback.
Normal Qt 6 remains loopback by default. Final measured results, PNG captures,
stalled-peer checks and package verification are in `R:\src\docs\VALIDATION.md` and `docs\qa`.

---


<a id="history-historical-2026-09-04-assessment-superseded-by-the-port-above"></a>

## Historical 2026-09-04 assessment (superseded by the port above)

**Assessed 2026-09-04; research only.** Current source: `R:\src_Qt5\fieldtrip`; current local
service parameters are `hostName=localhost` and `port=1972`; output is a Float64 stream named
`buffer`.


<a id="history-is-it-x32"></a>

## Is it x32?

The old Resonance target is x32 only because its `CMakeLists.txt` explicitly checks
`CMAKE_SIZEOF_VOID_P EQUAL 4`. The client code is not inherently 32-bit: its embedded FieldTrip C
layer contains Win64 branches, the wire structures use fixed-width integers, and FieldTrip's
reference build instructions say the Visual C++/Windows SDK makefile works for both 32- and 64-bit
platforms. The local gate can be removed for an x64 Qt 6 build.

FieldTrip's public page reports historical test coverage on Windows 32-bit rather than claiming
equivalent Windows-64 runtime validation, so the proper conclusion is **64-bit build supported,
but this exact x64 client/server pairing still needs a test**, not “already proven.”


<a id="history-api-and-protocol-drift"></a>

## API and protocol drift

The upstream project remains active and still documents the Buffer as an OS/language-independent
TCP protocol with ANSI C and C++ clients. The current upstream `message.h` still declares protocol
version `0x0001` and the familiar header/data/event request structures. Newer sources add optional
no-response PUT commands; the old GET/WAIT path used by Resonance remains compatible.

The local embedded FieldTrip copy should nevertheless be refreshed from current upstream rather
than carried forward blindly. This avoids owning an unknown snapshot and provides current compiler
fixes while preserving the small Resonance adapter.

Primary sources:

- [FieldTrip buffer reference implementation and build instructions](https://www.fieldtriptoolbox.org/development/realtime/reference_implementation/)
- [FieldTrip C buffer and test programs](https://www.fieldtriptoolbox.org/development/realtime/buffer_c/)
- [FieldTrip language-independent buffer interfaces](https://www.fieldtriptoolbox.org/faq/realtime/fieldtripbuffer/)
- [Current upstream repository](https://github.com/fieldtrip/fieldtrip)


<a id="history-local-defects-to-fix-in-a-later-port"></a>

## Local defects to fix in a later port

- `openBuffer()` is called directly after `moveToThread`, so it actually runs in the caller thread;
  thread affinity and socket ownership are inconsistent.
- The buffer-reset path (`newSamples < numSamples`) is commented out. A restarted server can make
  `newSamples-1` underflow and leaves the old channel/rate header active.
- Error transitions do not guarantee socket close/reconnect, and deletion is queued onto a worker
  whose event loop may already be stopping.
- The service publishes no FieldTrip events and does not carry channel-name/header chunks into
  Resonance metadata; it is data-only despite the protocol being richer.

Conclusion: easy to preserve, low priority. Allow roughly **one day** for current upstream import,
Qt 6 port, lifecycle/reset hardening and simulator recording; two days if event and channel metadata
are promoted rather than merely preserving the old data-only behavior.
