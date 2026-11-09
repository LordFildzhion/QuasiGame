# 2026-08-14 packaging requirement — dedicated recording directory

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-2026-08-14-packaging-requirement--dedicated-recording-directory"></a>

### 2026-08-14 packaging requirement — dedicated recording directory

Every new distribution contains `data\` at the same level as `bin\` and `qt\`.
`Core/Resonance/env.bat` exports `RESONANCE_RECORD_PATH=<distribution>\data` and creates the
directory if it is missing, so every launcher that calls `env.bat` gives recorders one stable
destination. Direct `.exe` launch bypasses this contract and is not the supported recording path.
Top-level CMake creates both `<build>\runtime\data` and `<build>\deploy\data`, preserving the
empty directory during normal `/E` distribution assembly.

