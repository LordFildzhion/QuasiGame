# UI and QML contracts

Status: current engineering reference. Scope: Qt 6 quickStimulus, its Resonance QML module, and shared service UI conventions. Authority: [quickStimulus CMake](../../src/quickStimulus/CMakeLists.txt), [QML module](../../src/quickStimulus/import/Resonance), and the owning service's parameter/state declarations; inspected 2026-09-15.

## Ownership and edit locations

quickStimulus is both a QML host and the host of built-in Configurator, Generator, and Recorder applications. C++ types are registered in [resonanceqmlplugin.cpp](../../src/quickStimulus/resonanceqmlplugin.cpp); reusable QML lives in `quickStimulus/import/Resonance/`. Embedded application resources are listed in [res.qrc](../../src/quickStimulus/res.qrc).

The service owns the parameter's name, type, accepted values, group, description and availability. The editor reflects that contract and sends a request. Hardware logic or descriptions should not be duplicated as service-specific tables in the Configurator. [Framework](framework.md) owns parameter signals, apply/refusal reporting, actions, states and content paths.

## Parameter panels

| Requirement | Implementation entrypoint |
|---|---|
| Keep disabled settings readable; hide only `visible=false` | [ParamView.qml](../../src/quickStimulus/import/Resonance/ParamView.qml) |
| Group/tab order follows the group's lowest parameter index | [ParametersView.qml](../../src/quickStimulus/import/Resonance/ParametersView.qml), [ParamTabView.qml](../../src/quickStimulus/import/Resonance/ParamTabView.qml) |
| Render the editor for the declared parameter type | `Resonance__Parameters__*.qml` in the [module](../../src/quickStimulus/import/Resonance) |
| Wrap explanatory text within the parameter panel | [ParameterToolTip.qml](../../src/quickStimulus/import/Resonance/ParameterToolTip.qml) |
| Preserve local/remote update behavior | [TwoWayBinding.qml](../../src/quickStimulus/import/Resonance/TwoWayBinding.qml) and concrete editors |

Design for the approximately 300 px parameter panel and the pinned 130 px label column. Keep labels short (roughly 22 characters where possible), include units where they prevent ambiguity, and move explanations into the description. Long labels may wrap; they must not widen the application. A tooltip must wrap within the panel, rather than becoming a screen-wide strip.

Integer parameters may opt into the shared `FrameDuration.qml` editor with `attributes.frameDuration=true` and a service-supplied `frameRateHz`. Both loaders render paired frames/ms fields with fixed grey unit labels anchored to the right inside each field; only integer frames are sent or saved. The service owns the selected-monitor rate. Integer and Double parameters may opt into `attributes.unit` for the same right-anchored grey decoration and left-aligned numeric value. Units are separate Labels, excluded from editing, parsing and clipboard text. Parameters without unit metadata retain their existing editor alignment and commit behavior.

`enabled`, `readOnly` and `visible` are separate conditions. A mode can hide inapplicable controls while leaving temporarily unavailable controls visible. A readout needs a description too. Do not restore the old global “hide disabled options” behavior.

Changes to Select labels/options need a compatibility check: some option labels are serialized values in saved settings and on the wire. Before renaming one, inspect the concrete parameter's JSON conversion, shipped presets, loaders and tests. A UI wording change can otherwise invalidate existing configuration.

Actions execute only on explicit invocation. A value binding, description refresh, or file load must not replay a button press. Display apply refusals and live state; an editor showing a requested value is not proof that a device accepted it.

## Stable layout and interaction

The standard launch strip uses 32-pixel icons for both executable artwork and preset PNGs. Configurator's generic `viewer_secondary_percent` can set an initial second-pane share (0 uses the usual compact default); the splitter remains draggable. Cut mode can display epochs alone while continuing to ingest the underlying stream. See [MPRAC follow-up evidence](../history/changes/2026-09-24-mprac-followup-p300.md).

Dynamic text such as device names, errors, sample counts or status should not force the top-level window or dock to resize. Use wrapping/elision and explicit layout constraints. Preserve normal readable disabled/read-only states and the shared light palette used by native service windows.

Keyboard shortcuts must account for focused editors. A Space shortcut should not steal text entry or bypass the service state machine. Keep focus and availability checks close to the shortcut implementation, and test editing as well as button/keyboard activation.

Configurator's service TreeView disables delegate pooling (`reuseItems=false`). With Qt 6.11.2, removing an expanded service's stream and inserting it again could recycle that stream cell into the following service while retaining its name/controller roles. The source model still held the correct service, so rereading its settings did not repair the cell. Preserve this guard unless a runtime regression proves safe reuse. ServiceLocator notifies both columns when role data changes; the recording column also holds controller/stream identity. `test_ConfiguratorLiveStatus` checks the actual Configurator delegates through repeated stream removal/return.

Do not use deprecated Controls 1 or Qt 5-only effects in the active module. For a retained Qt 5 paradigm, classify it as legacy rather than assuming its QML will run under the current host. Widget and QML styling have different implementations; follow the neighboring current component rather than copying an old deployment-only QML file wholesale.

## Loading files and staging changes

Use the existing [ParameterFile implementation](../../src/quickStimulus/parameterfile.cpp) and `ResonanceApp` content helpers for native-path parameter/configuration operations. Keep browser URLs, local file URLs, and Windows paths distinct. A file chooser and its loader must agree on overrides; see [framework content paths](framework.md#content-paths-and-recording).

Qt 6 restricts local-file XMLHttpRequest behavior. Before modifying an older montage/paradigm loader, inspect the active loader and host configuration and test a real shipped file. Do not treat a script that silently receives no content as a valid empty montage.

There are separate source, build-staged, and deployed QML copies. The `quickStimulusQml` target is an `ALL` target that copies the module into the build runtime even when the plugin does not relink. A source edit is not automatically present in an existing `dist/` package. For a stale UI, identify which executable/import path was launched, rebuild the staging target through the normal build environment, and deploy only to the intended package.

The legacy `plotrender.cpp`/`plotrendershader.cpp` sources are excluded from the Qt 6 target. Editing them will not change the current viewer. For active plot/channel/epoch implementation, use [signal viewer](../components/signal-viewer.md) and the CMake source list.

## Encoding, icons and diagnostics

The Configurator icon strip reads operator-owned `launchbar.txt` and watches it for saved changes. `launchbar-default.txt` supplies new installations; updating that default alone does not migrate an existing strip. The stock Recorder entry launches standalone `recorderService.bat`. `recorder.bat` remains the explicit built-in quickStimulus recorder launcher.

`RESONANCE_LAUNCHBAR_PATH` selects a separate strip (relative values resolve under the distribution root). Launch entries and icons then resolve relative to that file's directory; `RESONANCE_DIR` retains its normal meaning. Without the override, existing behavior is unchanged. The [MPRAC venue](../how-to/mprac.md) uses this only for a task-only launcher strip. Configurator keeps its standard name and view; venue-specific toolbar/controller QML is not used.

MSVC source/execution encoding is target-specific in this tree. `tepSoundService` and several newer modules enable `/utf-8`; quickStimulus currently does not. Do not add non-ASCII narrow literals there assuming the file's UTF-8 encoding is sufficient. Check target flags and choose an explicit encoding-safe implementation; treat any build-flag change as a separate code change to validate.

Icons are build inputs documented in [icons/README.md](../../src/icons/README.md). Use the `resonance_icon` CMake helper and the launcher generator when adding a service; preserve stable icon IDs for built-in quickStimulus tools. The operator-facing debug console is shared framework behavior, documented in [framework](framework.md#diagnostics).

## UI automation

Do not use `CreateDesktopW` or `SwitchDesktop` for testing: they can strand the operator's visible session. Existing harnesses use message-based control and `PrintWindow` capture; [capture-parameter-column.ps1](../../src/scripts/capture-parameter-column.ps1) is an example. Identify the specific test-owned windows/processes and preserve normal service stop/release behavior during cleanup.

## Verification and history

Use the relevant existing QML/C++ integration checks: ParameterFileQml, StreamConnectorQml, ViewerReconnect, ConfiguratorLiveStatus, ChannelsListQml, StatusLineQml, and ChannelsListInTabsQml. Their actual registration/dependencies are in [CMake](../../src/quickStimulus/CMakeLists.txt). Visual inspection should include the constrained parameter panel, focus behavior, tooltips, unavailable controls, and a source-to-runtime staging check. See [testing](../how-to/test.md).

[Qt migration history](../history/migrations/qt5-to-qt6-transition.md) and [architecture history](../history/migrations/framework-evolution.md) retain design changes and older layouts. Use [issues](../issues/README.md) for current gaps; historic screenshots or old OPEN headings are not a current status registry.
