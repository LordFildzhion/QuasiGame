# P300 standard space, comma and backspace cells

2026-09-27. [Current P300 contract](../../components/p300.md). [Same-session recording analysis](../investigations/p300-opus-movicom-nvx-20260927.md).

The standard 6×6 alphabet now ends **Э Ю Я ␣ , ⌫**. Space inserts U+0020, comma inserts a literal comma and backspace removes the preceding Unicode grapheme (including a surrogate-pair emoji or base-plus-combining-mark character). Backspace on empty text does nothing. Each classifier selection, including editing commands, still counts as one selection. Training targets do not modify typed output. Existing saved custom alphabets retain literal `_`, `!` and `?` behavior; there is no reinterpretation of historical recordings.

The same action path handles native and legacy classifier results after trial/index validation. Consumed duplicate or stale results cannot repeat an edit. The selected cell receives ordinary feedback highlighting. Reserved space/comma/backspace cells render as text in image mode too, without requiring new PNG assets. Other image cells retain their asset checks.

The `events`/legacy `Stimulus` streams additionally publish `type: text_edit`, trial, selectedCell, symbol, action (insert/space/backspace), resulting text and runId. The message deliberately omits `classification_result` to avoid double-counting the original classifier output. Raw selection events remain available; edited text can therefore be reconstructed, including corrections.

Updated source defaults and the standard P300TEST/MPRAC presets. Deployed preset edits replace only the exact old standard alphabet, preserving other operator fields. The active P300 matrix was updated; the selected NVX classifier, mode, four-letter calibration setting, other parameters, running NVX acquisition, Recorder state/settings and raw files were preserved. A trained row/column model remains valid when these text labels change within the same 6×6 arrangement.

Build passed. All **21 UI/workflow tests** passed, including whitespace insertion, comma, backspace, empty backspace, surrogate/combining-character deletion, unchanged legacy literals and duplicate-result protection. The private eight-recording pretraining/typing test verified one text-edit event per selection and exact reconstructed text. All **nine planner tests** passed. An outdated hardcoded ten-letter test expectation was changed to use the configured count (now twelve by default); the planner itself was unchanged. Source and deployed executable hashes match.

Evidence: `R:/src/_test-output/p300-opus-editing-20260927/`: before/after operator descriptions, source/preset backups, build/test logs, `final-session/` synthetic recordings, UI PNGs and `deployment.json`. No physical stimulation was started for deployment verification.
