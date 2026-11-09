# ⚠ Unfinished: nothing is committed

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../current.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history--unfinished-nothing-is-committed"></a>

### ⚠ Unfinished: nothing is committed

`R:\src` is on branch `feature/cmake-dual-build` (local only, never pushed). Nothing is
committed, and `user.name`/`user.email` are **unset** so committing will refuse until set.

**Build fixes (2026-08-11):**

| File | Fix |
|---|---|
| `CMakeLists.txt` | `install_files_with_prefix` compat shim |
| `DAQmx/driver.cpp` `.hpp` | NI `int32`/`uInt32` typedefs + include order |
| `quickStimulus/CMakeLists.txt` | removed never-committed `Head.qml.bak` |
| `scriptEngines/CMakeLists.txt` | x64 arch gate |
| **`scriptEngines/python`** | **`stdout` → `stdoutHook` — lives in the SUBMODULE working tree** |

**SignalGenerator rework (2026-08-17)** — entirely inside its own directory; `CMakeLists.txt`
already listed the module, so nothing outside it changed at all:

| Area | Files |
|---|---|
| ✚ Pure logic (no Resonance types; compiles into the test binary too) | `SignalGenerator/` — `synth.{hpp,cpp}`, `channelplan.{hpp,cpp}`, `schedule.{hpp,cpp}`, `eegmodel.{hpp,cpp}` |
| ✚ Service and lanes | `service.{hpp,cpp}`, `lane.{hpp,cpp}`, `pacer.{hpp,cpp}`, `channelwindow.{hpp,cpp}`, `res.qrc` |
| Rewritten | `main.cpp`, `CMakeLists.txt` |
| ✖ Removed | `generator.{hpp,cpp}` — superseded wholesale |
| ✚ Unit tests | `tests/generator_test.cpp`, target `test_SignalGenerator` (68 cases) |
| Harnesses (not in `src`) | `R:\config\siggen_params_check.qml`, `siggen_record_harness.qml`, `siggen_config_check.qml`, `siggen_config_roundtrip.json` |

**TEP module (2026-08-16)** — all new, nothing outside its own directory except one line:

| Area | Files |
|---|---|
| ✚ New module | `tepService/` — `main.cpp`, `service.{hpp,cpp}`, `pipeline.{hpp,cpp}`, `epochprocessor.{hpp,cpp}`, `epochstore.{hpp,cpp}`, `dsp.{hpp,cpp}`, `views.{hpp,cpp}`, `ui/{Console,RunBar,SettingsPane}.qml`, `import/Resonance/Tep/*` (10 files), `montages/mumeg_mks64.ced`, `tests/pipeline_test.cpp`, `res.qrc`, `tepService.bat`, `CMakeLists.txt` |
| Registration | `add_subdirectory(tepService)` in `src/CMakeLists.txt` |
| Harnesses (not in `src`) | `R:\config\tep_params_check.qml`, `tep_record_harness.qml`, `tep_settings_harness.qml`, `tep_reference_pipeline.py` |

**Playback module (2026-08-15)** — all new, nothing outside its own directory except one line:

| Area | Files |
|---|---|
| ✚ New module | `playbackService/` — `hdfsource.{hpp,cpp}`, `playbackjob.{hpp,cpp}`, `player.{hpp,cpp}`, `sourceservice.{hpp,cpp}`, `sourcemain.cpp`, `service.{hpp,cpp}`, `main.cpp`, `ui.qml`, `res.qrc`, `playbackService.bat`, `playbackSource.bat`, `CMakeLists.txt` |
| Registration | `add_subdirectory(playbackService)` in `src/CMakeLists.txt` |

**Feature and defect work (2026-08-12)** — new files marked ✚:

| Area | Files |
|---|---|
| ✚ New module | `recorderService/` — `main.cpp`, `service.{hpp,cpp}`, `ui.qml`, `strip.qml`, `res.qrc`, `recorderService.bat`, `CMakeLists.txt`; `add_subdirectory` in `src/CMakeLists.txt` |
| ✚ New parameter type | `Core/Resonance/Parameters/action.{hpp,cpp}`, listed in `all.hpp` + `Core/Resonance/CMakeLists.txt`; QML `quickStimulus/import/Resonance/Resonance__Parameters__Action.qml` |
| Parameter notification | `Parameters/{integer,double,string,MultiLine,boolean,stream}.cpp` |
| Stream identity | `streaminfo.{hpp,cpp}` (`isEmpty`, `fromJson` round-trip), `Parameters/stream.{hpp,cpp}` |
| Reconnection | `servicediscovery.{hpp,cpp}` (`persistentStreamRequest`), `internal/StreamPool.{hpp,cpp}`, `internal/TcpStreamReceiver.cpp`, `ThreadCapsule.cpp` |
| Recording | `recorder.{hpp,cpp}`, `internal/HDFRecorder.{hpp,cpp}` |
| Parameter application | `communicationlayer.cpp` (`applyParameters` rewrite) |
| Configurator / viewers | `quickStimulus/`: `main.cpp`, `servicelocator.{hpp,cpp}`, `qml_ResonanceApp.{hpp,cpp}`, `timeseriesreceiver.*`, `messagereceiver.*`, and `import/Resonance/{Configurator,StreamView,Resonance__Parameters__*}.qml` |
| NVX | `nvx/application.cpp` (null-`runner` crash, deterministic `stop()`) |

**Signal viewer work (2026-08-13)** — new files marked ✚:

| Area | Files |
|---|---|
| ✚ Channel/group model | `quickStimulus/channelmodel.{hpp,cpp}` |
| ✚ Axis and decimation maths | `quickStimulus/plotmath.{hpp,cpp}` |
| ✚ Unit tests | `quickStimulus/tests/plotmath_test.cpp`, target `test_PlotMath` in `quickStimulus/CMakeLists.txt` |
| Renderer and data path | `quickStimulus/timeseriesreceiver.{hpp,cpp}` (rewritten) |
| ✚ Viewer QML | `import/Resonance/Plot/{ChannelPanel,PlotSettings,NumberField}.qml` |
| Viewer QML | `import/Resonance/Plot/{PlotView,Settings,qmldir}`, `import/Resonance/StreamView.qml` |
| Plugin registration | `quickStimulus/resonanceqmlplugin.cpp` (`ChannelModel`) |
| Driver metadata | `nvx/nvxdatathread.{h,cpp}`, `nvx136/nvx136driver.cpp` |

**The submodule one is fragile:** a routine `git submodule update` discards it silently and the
build breaks again with no obvious cause. It needs committing to `Resonance-engine-python` with
a pointer bump, or extracting to a patch file kept in-tree.

