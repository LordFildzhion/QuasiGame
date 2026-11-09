# 2026-09-25 — optional P300 + Movicom firmware synchronization

Status: accepted scope, planned; documentation only. No service, executable or device configuration changed.

The user selected an optional P300 + Movicom mode based on the recovered D7 exchange: the PC sends a numbered tag to the amplifier, **Movicom firmware echoes it inside EEG frames**, and repeated sample/send-time anchors support mapping P300 host events to EEG indices. FTDI is the transport, not the source of this firmware capability. Universal synchronization and work on other amplifiers are explicitly outside this scope.

Current requirements and validation belong to [Movicom](../../components/movicom.md#p300-firmware-synchronization) and [P300](../../components/p300.md#optional-movicom-synchronization). At this recorded date the deployed driver used reception-based timestamps and the optional mode was unimplemented. The [2026-09-26 implementation and acceptance](2026-09-26-movicom-firmware-sync.md) supersedes that status; firmware echo still does not measure actual screen-light onset.
