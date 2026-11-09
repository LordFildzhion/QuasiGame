# FieldTrip buffer source provenance

Imported on 2026-09-05 from the supplied `R:\equipment\Fieldtrip_src\buffer-20260904`.
Only the C buffer/client implementation and its directly included headers, plus `FtBuffer.h`
and `SimpleStorage.h`, are retained. No MATLAB toolbox, fileio, qsub, RDA server, alternative
socketserver or timestamp utility is imported. The equipment download is unchanged.

The download does not contain the standalone server main or test/demo programs. These files
come from the official FieldTrip GitHub repository, pinned to commit
`5a645ccf1cdc6384d18c4d6a40ce58359a96f44c`:

- `realtime/src/utilities/buffer/buffer.c` → `tools/buffer.c`
- `realtime/src/buffer/test/{demo_sinewave.c,demo_combined.c,sinewave.c}` → `test/`

Source: https://github.com/fieldtrip/fieldtrip/tree/5a645ccf1cdc6384d18c4d6a40ce58359a96f44c/realtime/src

The buffer package's COPYING offers the BSD or GPL licence; this distribution uses the BSD
option, retaining the copyright notices and `LICENSE_BSD`. The acknowledgement in that licence
applies to scientific publications using this software. This is not a licence claim about the
unrelated FieldTrip toolbox.

Local compatibility changes: `platform_includes.h` uses modern MSVC `<stdint.h>` and omits an
unused, unavailable POSIX gettimeofday shim in the Win64/MSVC branch; `swapbytes.h` also uses
modern MSVC `<stdint.h>`; `interface.h` guards duplicate wire datatype macros. These changes do
not alter the wire protocol. The service uses the current C++ request builder and fixed-width C
wire definitions, with a native asynchronous Qt TCP transport. It does not use the upstream
blocking C transport's integer socket handles. The standalone reference server and demos use
the selected C sources and are separately compiled using MinGW-w64 GCC 13.1 x64 with static
winpthreads, without Qt or an app-local pthread DLL.
