# `latencyProbe` — closed-loop trigger-response instrument — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../components/latency-probe.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-latencyprobe--closed-loop-trigger-response-instrument"></a>


**Ported to Qt 6 on 2026-09-04.** Source: `R:\src\latencyProbe`; executable:
`R:\dist\bin\latencyProbe.exe`; launcher: `R:\dist\latencyProbe.bat`; service name:
`LatencyProbe`.

The probe watches a selected bit in an amplifier's appended trigger/status channel. On the
asserting edge it can immediately command a parameter or transition on another discovered service,
then publishes one compact JSON message on its `events` stream. An external board that timestamps
the initiating edge and the amplifier response on one clock measures the real end-to-end loop.


<a id="history-parameters"></a>

## Parameters

All 12 parameters have Configurator descriptions/tool tips.

| key | default | meaning |
|---|---:|---|
| `source` | disconnected | Float64 amplifier stream containing a trigger/status channel. |
| `trigger_channel` | -1 | Zero-based trigger channel; -1 selects the last channel. |
| `input_mask` | 256 | Bit mask to watch. Exclude an output readback bit to avoid feedback. |
| `input_active_low` | true | Detect high→low when true, low→high when false. |
| `armed` | false | When false, observe/report only; when true, command the target. |
| `target_service` | `NVX` | Exact discovered service name to command. |
| `response_kind` | Boolean parameter | None, Boolean parameter, Integer parameter, or Transition. |
| `response_name` | `trigger_state` | Remote parameter/transition key. |
| `response_value` | 1 | Asserted Boolean/integer value. |
| `release_after` | 20 ms | Host-timer delay before release; zero leaves asserted. |
| `release_value` | 0 | Value written at release. |
| `status` | empty | Once-per-second detection, response, cadence and transport summary. |

States are `init` and `running`, with `start` and `stop` actions. Stream replacement disconnects
the old source, preventing duplicate detection after reconnects.

Each detection event includes the raw word, in-block sample index, rate, block creation/arrival/
dispatch/response timestamps, estimated host-side edge age, reaction time and armed state. The
timestamps that do not fit safely in a JSON double are decimal strings.

