# Movicom firmware synchronization — 2026-09-26

Implemented the optional Movicom/P300 mode accepted in the [earlier scope](2026-09-25-p300-movicom-sync.md). Current operating contracts: [Movicom](../../components/movicom.md#p300-firmware-synchronization) and [P300](../../components/p300.md#optional-movicom-synchronization).

## Implementation

Native x64 Movicom sends recovered D7/tag/CRC commands from its acquisition worker. A bounded outstanding-tag table associates each confirmed first echo with its own host send timestamp. A rolling linear fit tracks sample-clock phase/rate. The original eight-channel EEG values and reception timestamps remain unchanged; an optional `sync` Message stream carries frozen per-block mapping, identity, continuity generation, quality and anchor evidence. The setting is off by default and locked during acquisition.

Native P300 pairs EEG and mapping regardless of arrival order, waits for lock, records the mapping with EEG and freezes the filter origin. Training and inference consume the same mapped sample times. Missing/invalid/wrong-session/stale timing is refused; synchronization loss stops the active run. Classifier models retain the selected timing method. MATLAB/SPEED feedback remains unchanged.

Sources: `src/movicom/{syncclock,synctimeline}.hpp`, transport/worker/config and tests; `src/P300` model/processor/import/controller/service, classifier panel and tests. No vendor DLL, firmware update, new Windows driver or separate runtime dependency was introduced.

## Physical evidence

Evidence bundle: [movicom-sync-20260926](../../../src/_test-output/movicom-sync-20260926/). Device: Movicom EEG Control, FTDI 0403:6001, serial A8WU1ZVW; eight inputs, nominal 500 Hz. The user supplied the connected amplifier/water-electrode fixture. Builds use Qt 6.11.2 and MSVC v143 14.44 x64. UI tests use offscreen software rendering and do not establish physical display onset.

- Final 90-second wire capture: **45,067 samples**, zero detected losses, duplicates, corrupt CRC frames or uncertain counter intervals. Clock remained valid after a 750-sample warmup, with **zero resets**. **4,327 commands**, **2,405 confirmed anchors**, repeated 8-bit tag wraps. Final fitted rate **500.7176 Hz**; anchor-fit residual median **0.541 ms**, final **0.485 ms**, maximum rolling RMS **0.624 ms**. Raw data and every block's frozen mapping are retained.
- Eight additional 12-second acquisition cycles under two CPU load workers: two each at synchronized block sizes **1, 37 and 500**, plus two at block size **25 with sync off**. All passed, with no lost mappings after warmup and no detected EEG loss/CRC error. Each restart produces a new clock session. Disabled acquisitions issue zero D7 commands.
- Same-capture residual about a fitted straight sample timeline was **0.816 ms for reception block timestamps** and **0.167 ms for mapped block timestamps** in the 90-second capture. Median reception-minus-mapped time was **4.202 ms**. These are consistency/buffering comparisons, not known-onset error or a display-delay calibration; the mapping is intentionally smoothed by its clock fit.
- Actual Movicom → P300 → Recorder test: three calibration letters, native classifier calculation, then three typing letters / **72 flash epochs**. Reloading the saved recording reproduced **every epoch sample index, every score (maximum difference zero), and all three decisions**. This uses measured water-fixture input and asserts processing parity, not physiological accuracy.
- The same complete test passed again from the installed `R:\dist` executables through discovery-addressed EEG and clock streams: another **72/72 identical epoch indices and scores**, and **3/3 identical decisions**. Final CTest acceptance: **4/4 targets passed** (Movicom, native P300 classifier, P300 UI, P300 plan). The amplifier was stopped and its USB handle released after testing.

The initial conservative exchanges exposed firmware behavior: many successful USB writes receive no echo, and an occasional unissued tag can appear. The first 12-second attempt failed to lock because it reset after each missed command; a 70-second intermediate attempt locked but reset twice. Those attempts are retained as rejected designs. The accepted exchange uses approximately 20 ms commands, a 100 ms association lifetime and fresh tag/time pairs; unconfirmed or unissued tags supply no anchor. It never treats USB write success as synchronization success. A one-second lack of usable anchors invalidates lock.

## Software and recording checks

- `test_Movicom`: existing parser, metadata, locking, transport lifecycle and final-block checks plus drift/wrap/held-tag/timeout/slow-write/outstanding-tag and exact mapping/refusal tests.
- Native P300 classifier, UI and plan regressions include the retained 500/1000 Hz numerical references and asynchronous recording replay. The new mode does not add a photo channel or emit a false photodiode event.
- Live synthetic source checks reverse EEG/clock arrival order successfully, then inject invalid validity, changed generation, wrong session, one missing mapping, a silent clock stream, and stale data before startup. Every fault is refused; silence stopped the run in about **3.1 seconds**.
- Seven modified recording copies test absent clock stream, absent mapping, invalid mapping, changed generation, wrong serial, repeated clock record and missing origin EEG block. Every import is refused with its specific reason. Originals remain intact.
- Actual 300 px shared Movicom parameter-panel PNGs verify the added option and locked acquisition layout.

Recorded evidence and test-only classifiers remain under `_test-output`; they are not shipped as operator presets or scientific test subjects. The distribution update contains `Movicom.exe`, `P300.exe` and the concise Movicom reference. Exact file hashes and final test/deployment results are retained in the evidence bundle.

## Limits

This verifies the firmware echo, clock lifecycle, native transport and reproducible P300 sample alignment on the connected unit. Movicom and live P300 must use the same PC performance-counter time base. It does not establish absolute amplifier input calibration, human P300 accuracy, optical stimulus onset, or host-to-device command delay. A new physical unplug/replug was not requested for this run; previous acquisition recovery is documented in the original Movicom acceptance, while this change tests restart and clock/session-loss refusal. No universal synchronization framework or support for other amplifiers was added.
