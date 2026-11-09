# 4. `nvx136` library path depends on `CMAKE_BUILD_TYPE` — ✅ fixed 2026-08-15

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../components/nvx136.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-4-nvx136-library-path-depends-on-cmake_build_type---fixed-2026-08-15"></a>

### 4. `nvx136` library path depends on `CMAKE_BUILD_TYPE` — ✅ fixed 2026-08-15

**TRANSFERS UNCHANGED — the fix crossed.** `R:\src\nvx136\CMakeLists.txt:20` links the fixed
`x64/Release/NVX136.lib` and says so in a comment naming this section. The "use single-config
Ninja" rule still holds: `build-qt6.ps1` configures `-G Ninja` with an explicit
`CMAKE_BUILD_TYPE`, and so does `build-kardi2-x32.ps1`.

Retired by the 2025 driver merge: `nvx136` now links `sdk/x64/Release/NVX136.lib` at a fixed
path. The description below is kept because the same shape appears elsewhere and the failure
mode is silent — an empty `CMAKE_BUILD_TYPE` produced a link error *and* an `install_files`
that copied nothing.

`src/nvx136/CMakeLists.txt`, before the merge:

```cmake
set(NVX_LIBRARY_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Dll/x86_64/${CMAKE_BUILD_TYPE})
```

On-disk directories are exactly `Debug` and `Release`. Consequences:

* **Multi-config generators break.** With `-G "Visual Studio 17 2022"` or `-G "Ninja Multi-Config"`,
  `CMAKE_BUILD_TYPE` is empty → the path becomes `Dll/x86_64/` → link fails and the
  `install_files` of `NVX136.dll` copies nothing. **Use single-config Ninja.**
* `-DCMAKE_BUILD_TYPE=RelWithDebInfo` also fails — no such directory. Only `Release` and `Debug`
  work.

Worth replacing with a `$<IF:$<CONFIG:Debug>,Debug,Release>` generator expression.

---

