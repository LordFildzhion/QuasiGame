# FieldTrip buffer — Qt 6 x64

Service identity `fieldtrip`; parameters `hostName=localhost`, `port=1972`; output `buffer`
Float64. Original keys, labels, limits, defaults and init/start/running/stop contract are retained.
Connection failures now keep the service running and retry every 500 ms until Stop, deliberately
replacing the old return-to-init failure behavior to survive server restart without operator action.

All socket creation, DNS/connect, requests and cleanup execute on the worker thread. Qt TCP
transport preserves the old IPv4 client behavior, with a 5 second connection deadline and a
1.5 second request deadline. It uses the
current upstream request builder/protocol definitions, avoiding the blocking upstream C transport's
int socket and unbounded read/connect APIs in the service. Every response has strict size/shape/type
checks and a 64 MiB limit. It accepts the same ten numeric types and republishes scan-order doubles.

Joining/reconnecting starts at the server tail, as before. An observed in-place count reset starts a
new stream at zero; channel/rate/type/chunk changes replace the publisher and description while
preserving the service UID and stream name.
GET_HDR is refreshed after every WAIT and data request, including unchanged/increasing counts.
Stop/destruction closes the publisher on the main thread, aborts the worker's socket, and joins
the thread. Main-thread publisher ownership also prevents a queued stream-creation callback
from outliving a worker that is being stopped.
FieldTrip v1 has no generation identifier: a same-shape reset that completely catches up between
header observations cannot be detected reliably. No continuity across server generations is claimed.

This software uses the FieldTrip buffer open source library under its BSD license. Copyright
2008–2017 Robert Oostenveld and contributors, Donders Centre for Cognitive Neuroimaging, Radboud
University. See LICENSE_BSD/COPYING and https://www.fieldtriptoolbox.org/ for details.
Core and request-builder files came from the operator's `buffer-20260904` module download at
`R:\equipment\Fieldtrip_src`, not the unrelated fileio/qsub modules. The missing official server and
demo programs came from FieldTrip commit `5a645ccf1cdc6384d18c4d6a40ce58359a96f44c`:
`realtime/src/utilities/buffer/buffer.c` and `realtime/src/buffer/test/`.
The service is MSVC v143/Qt 6 x64. The official Qt-free server/demo tools use MinGW GCC 13.1 x64
with static winpthreads. They install into `tools/fieldtrip`; no Qt 5 or old pthread DLL is shipped.

`tools\fieldtrip\buffer.exe 1972` and `demo_sinewave.exe localhost 1972` provide an official
hardware-free source: 16 channels at 512 Hz, blocks of 32; channel 1 is a sample counter, channel 2
is a 1 Hz unit sine, channel 3 noise, and the others sine plus noise. `demo_combined` runs a server
and a 16-channel, 250 Hz/125-sample variant together. These are upstream demo tools, not precision
real-time clocks; their wall-clock pacing differs from nominal sample time.

The existing data-only contract is preserved. Channel chunks are tracked to detect replacement,
but channel labels and FieldTrip event publication are deferred to a separately specified extension.
