# Builds — three, all verified running

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-builds--three-all-verified-running"></a>

### Builds — three, all verified running

| Tree | Toolchain | Status |
|---|---|---|
| `R:\dist\mingw32` | MinGW 8.1 x86 | built, deployed, launch+discovery verified |
| `R:\dist\mingw64` | MinGW 8.1 x64 | built, deployed, launch+discovery verified |
| `R:\dist\msvc64` | MSVC v142 x64 | built, deployed, launch+discovery verified |

Verification protocol: [build-and-distro.md §7](../migrations/and-distro.md#history-7-verifying-a-deploy).
**A compile is not a build — launch it.**

⚠ **Always build with `-j6`.** At `-j32` this machine throws WHEA hardware errors and compilers
ICE at random ([known-issues §11b](../incidents/README.md)).

