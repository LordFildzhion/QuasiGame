# `COMport` — bidirectional serial/Resonance bridge — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/comport.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-comport--bidirectional-serialresonance-bridge"></a>


**Ported to Qt 6 on 2026-09-04.** Source: `R:\src\COMport`; executable:
`R:\dist\bin\COMport.exe`; launcher: `R:\dist\COMport.bat`; service name: `COMport`.

The service turns bytes received from one serial port into a Resonance `Message` stream named
`dataFromPort`. In the other direction, a connected Resonance `Message` stream is encoded with the
Windows local 8-bit code page and queued to the serial port. It adds and removes no terminator.


<a id="history-qt-5-parity-and-repaired-defect"></a>

## Qt 5 parity and repaired defect

The parameter keys, values, service name, state actions, output-stream name and text encoding are
preserved. The unused Qt 5 Designer form was not carried over; the service was headless and never
showed it.

The old send loop used `dataToWrite.size()-1`, so every message lost its final byte. Its loop
condition was also reversed (`written >= requested` rather than `written < requested`), which
could spin after a successful shortened write. The Qt 6 service queues the entire payload, removes
only the number of bytes actually accepted, and resumes draining on `bytesWritten`. Replacing the
input stream now disconnects the former one, preventing stale streams from continuing to transmit.

The port list deliberately displays only `COM4`, `COM8`, and so on. Resonance `Select` parameters
persist that display label; appending Windows' localized device description would make old JSON
values fail to match and make a freshly saved configuration machine-dependent.

