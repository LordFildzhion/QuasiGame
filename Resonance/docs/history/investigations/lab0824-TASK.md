# Field batch 2026-08-24 — status, and what is still open — historical record

Status: historical evidence, proposal or change record. Scope: original dates, trees and rigs specified in each section.

[Current entry point](../../issues/README.md)

The record retains previous implementations, measurements, proposed fixes and later corrections.
An old “open”, “now”, deadline or imperative applies to that recorded session; consult the
current entry point for work today. Original evidence paths in code spans are historical provenance.

<a id="history-field-batch-2026-08-24--status-and-what-is-still-open"></a>


**Eleven field-reported defects, fixed, built and deployed 2026-08-25.** Five lanes plus a ship
pass. Rollback `R:\dist\msvc64\bin.pre-lab0824-20260825-033902` (190 files). Deploy was
`robocopy /E` over `bin, protocols, stimuli, montages, calib, params` + root `*.bat` — 126 copied,
0 failed, 5 deploy-only extras preserved. Post-deploy `diff -rq` against the build tree: **0
differing files**.

**31 test executables, 922 gtest cases, 0 failures**, plus `nvx136_cold_start_recovery_test` 6/6,
`nvx136_driver_emulation_integration` 1/1 against the real vendor SDK, `ns_bridge_smoke` 82/0, and
`nms_stream_check` 20 checks / 3 failures — **identical to the 2026-08-23 build run as a control**.
Regression: `epochs` SHA1 `92746fcd2957` and `labels` SHA1 `7709c9d9670c` unchanged across the
Aug-23 build, the new build tree and the deployed tree.


<a id="history-the-eleven"></a>

## The eleven

| # | defect | lane | evidence |
|---|---|---|---|
| 1 | NVX136 `NVXStart` −3 on a cold converter — in-place retries can never cure it | nvx | offline double, 6 tests; **no hardware** |
| 2 | neuroMS `THE STIMULATOR MAY STILL BE CHARGED` on every orderly disconnect (and an 8 s frozen Configurator with it) | nms | measured ~1 s disconnect |
| 3 | `power2` flickering 30 ↔ power1 at 2 Hz — two writers, one of them the raw block-2 register | nms | 12 samples over 7.7 s, pixel-identical |
| 4 | front-panel charge/discharge invisible to the service; the reverse mirror re-armed a manual discharge | nms | emulator |
| 5 | post-connect settings written blind at 1500 ms into a controller boot that takes 2512 ms — accepted and dropped | nms | emulator, real log |
| 6 | ISI was a table row in the randomisation pool, with `generator.isiNumber` as a second contradictory answer | seq | 114/114 + his real paradigm |
| 7 | background pattern gated by three phase booleans alongside a millisecond start delay | seq | pixels |
| 8 | photodiode patch bottom-right, no control anywhere — and a `.tep.json`'s whole `screen` block was dead | stage | pixels, build tree and deployed |
| 9 | `followMedia` / `mediaFrom` / `text` survived a medium change; an image + `followMedia` armed a 0 ms cue | stage | pixels |
| 10 | video: validation and playback ran on **two different backends in one process**; `~VideoCue` left MF holding a destroyed surface | stage | 34-clip sweep, WER record |
| 11 | every Save/Open dialog opened in `bin\` among the DLLs; stored relative paths resolved against the CWD | paths | pixels, unset and overridden |

`NVXSetMirrorTriggers` was removed outright alongside #1 (call, parameter and option). Both shipped
`params\*.json` keep the key deliberately and are refused by name.


<a id="history-documents-updated-2026-08-25"></a>

## Documents updated 2026-08-25

* `docs\guide_tep-operator.md` — §11.1 table and sequence box (ISI is an interval, `ISI between` is
  gone), the per-medium fields, §11.1 background pattern (lead-in / lead-out, the three toggles
  gone), the refusal list, **§11.1.1 rewritten — it used to say "video needs a codec pack" and to
  set `directshow`, both wrong**, §14a photodiode / bit 2, §14b video, **new §15 where the file
  dialogs open**.
* `docs\arch_known-issues.md` §24 — rewritten around the transition rule, with the three field
  facts, the competing hypothesis, and an explicit block naming what the previous version of the
  entry got wrong. §14c, §19e already in line.
* `docs\service_neuroms.md` (both copies), `docs\_notes\nvx136-cold-start.md` §6.
* `config\lab\LAB_ROUND3.md` — **the next lab prompt**; `LAB-PROMPT.md` points at it.
  `config\lab\NVX136-coldstart-ladder-test.md` is its supporting procedure.


<a id="history--still-open--in-the-order-that-matters"></a>

## ⭐ Still open — in the order that matters

<a id="history-needs-one-bench-trip-and-only-that"></a>

### Needs one bench trip, and only that

1. **Nothing in #1, #2, #3, #4 or #5 has touched an NVX136 or a Neuro-MS.** The cold-start ladder is
   proven against a fake that encodes the field report; the neuroMS work against the emulator.
   `LAB_ROUND3.md` is written to settle all of it in one session.
2. **Is the cure the re-open, or the process restart?** The operator's cure was a *second launch*,
   which reloads `NVX136.dll` and its process-global device table; the driver's in-process
   `NVXClose`/`NVXOpenEx` does not. Both hypotheses fit every field fact. `--ladder`'s new
   `recovery` control stage distinguishes them. If it is the DLL, the shipped ladder is a 7.2 s
   no-op.
3. **The speculative `NVXStop` in the recovery cycle.** ~10 ms = free; ~873 ms = a wasted deadline
   per cycle, drop it. The log line prints its elapsed time for exactly this.
4. **Is the front-panel charge button a toggle?** The one guess in #4. `ready → charged` works
   either way; only the reverse mirror is at stake.
5. **The unevidenced firmware claim behind #2**: "the stimulator manages its own capacitors when it
   leaves USB mode". It reverses D1/D2 in `service_neuroms.md`. No bench test, no vendor doc. The
   8-second-freeze argument for removing the wait stands on its own; removing the *warning* does
   not.

<a id="history-decisions-someone-has-to-make-not-fixes"></a>

### Decisions someone has to make, not fixes

6. ~~**`emgChannelA/B` = 65/66, real sockets 72/73 (kind AUX).**~~ **WITHDRAWN — the premise was
   false, and it was mine, not a lane's.** The operator states the protocol directly: *"emg was
   never aux to begin with — we used 65-66th channels of EEG amp to plug EMG electrode (that is the
   proper protocol)."* Measured against his own `params\nvx136_64ch_8emg.json`, which enables
   `Ch 1`…`Ch 72` + `AUX 1` + `AUX 2` + `Trigger`: stream position **65 = `Ch 65`**, **66 =
   `Ch 66`**, and AUX 1/2 sit at **73/74**. So `emgChannelA/B` = 65/66 points exactly at the two
   amplifier inputs the EMG electrodes are plugged into. **His config was correct; the code
   defaults are correct; do not "fix" them to 73/74.**

   `mks64_emg2.ced` puts `EMG1`/`EMG2` at rows **65 and 66** — correct for the same reason. In the
   CED index space (device inputs, electrodes first) row 65 *is* amplifier input 65. That those
   rows are electrode slots is the point, not the error: an EMG pair plugged into an electrode
   input is still an electrode input.

   What was actually missing is now built: every `.ced` carries an EEGLAB `type` column
   (EEG/EMG/EOG/ECG/TRIG, column 11 per `readlocs.m`), and the nvx136 driver reads it into each
   channel's `kind`. A montage can now say "input 65 is EMG" and be believed.
7. **`mepTo` 45 ms truncated a peak at 46.3 ms.** Same file, same status.
8. **`nms_stream_check`'s 3 remaining failures are pre-existing** and are the handshake's stated
   intent: it forces the interval to 0 ms, so a paired-mode delay written in the first ~2.5 s is
   overwritten. Worth a decision, not an unasked fix.

<a id="history-known-reasoned-from-code-not-measured"></a>

### Known, reasoned from code, not measured

9. **Configurator crash with a native chooser open** — `Qt5Core.dll+0x9d80`, `0xC0000005`. The paths
   verifier reproduced it on both the new build and the Aug-23 one, so it is **pre-existing**, but
   it sits directly on "make the operator browse for files". Not reproduced in the ship pass (a
   Save dialog sat open ~60 s and survived; zero WER records after 02:24). What would settle it: a
   Configurator idle 15 min with three services on discovery, versus a chooser opened with
   discovery quiet.
10. **`Nvx136Config::start()` is `Qt::BlockingQueuedConnection`**, so a give-up freezes the
    Configurator 20 s, and a Rescan pressed inside that window can purge the nvx136 entry
    (`kRescanStaleAfterMs = 10000`). Making `start()` asynchronous is a Config-lane restructure.
11. **`NVXOpenEx ≈ 3 s`** is from a comment, never measured.
12. **A migrated `.tep.json` gets a new digest** — `isi` is a new top-level key. Correct, and it
    will still look like a mismatch when he compares two runs of "the same" file.
13. **The `~VideoCue` teardown fix is carried on the stage lane's evidence only.** The ship pass
    never created a video row; the sole corroboration is the absence of any crash since 02:25.
14. **`background.noRoom` is gated on `plan.totalMs > 0`.** A run containing a step that waits on
    the subject has an unknowable timeline; if `totalMs` is 0 there, a switched-on pattern whose
    lead-in and lead-out exceed the run would arm with nothing said. Untested.


<a id="history-rules-that-were-carried-in-and-still-hold"></a>

## Rules that were carried in and still hold

⚠ Build with `chcp 65001` after `vcvarsall`, MSVC v142, `-j 6`. Without it ninja records **no**
header dependencies and a header edit yields a binary that links cleanly and crashes.
⚠ `robocopy /E`, never `/MIR` — 15 params and 5 deploy-only items would be destroyed.
⚠ Never terminate an amplifier or stimulator mid-acquisition. Stop, wait for the state to leave
`running`, then close.
⚠ The shared build tree is contested: the full build blocked for minutes on
`runtime\bin\Resonance.dll` held by another lane's running service. Check for live services before
linking.

Evidence index: `R:\dist\_build\lab0824\ship\README-ship.txt`. Per-lane scratch:
`R:\dist\_build\{nvxcold,nmssync,seqfix,stagefix,pathfix,lab0824docs}\`.
