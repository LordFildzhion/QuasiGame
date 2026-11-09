# 10. `install()` destinations are absolute

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-10-install-destinations-are-absolute"></a>

### 10. `install()` destinations are absolute

**FIXED BY THE PORT.** `R:\src\CMakeLists.txt` rewrote all three helpers: `install_target`,
`install_files` and `install_directory` now pass **relative** destinations
(`RUNTIME DESTINATION "${prefix}"`), so `CMAKE_INSTALL_PREFIX` and `cmake --install --prefix` are
honoured. The build-time tree is still populated by `POST_BUILD` copies, now under
`RESONANCE_RUNTIME_ROOT` (`${CMAKE_BINARY_DIR}/runtime`, line 19). The absolute
`${CMAKE_BINARY_DIR}/deploy/...` shape survives in `R:\src_Qt5\CMakeLists.txt:32`.

All three helpers in `R:\src_Qt5\CMakeLists.txt` install to
`${CMAKE_BINARY_DIR}/deploy/...` — an absolute path — so `CMAKE_INSTALL_PREFIX` and
`cmake --install --prefix` are both ignored. Not harmful (the useful tree is
`<build>/runtime/` anyway, populated at build time), but surprising. Worth normalising if you
ever want `cpack` or a real installer.

---

