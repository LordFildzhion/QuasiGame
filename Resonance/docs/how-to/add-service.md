# Add a service

Status: current implementation recipe. Scope: a new service in the active Qt 6 source tree. Authority: [SignalGenerator](../../src/SignalGenerator), [feetStim](../../src/feetStim), [top-level CMake helpers](../../src/CMakeLists.txt), and [framework contracts](../architecture/framework.md); source inspected 2026-09-15.

## 1. Define the boundary

Choose the stable service name, advertised stream names/types, parameter names and state transitions before wiring a UI. Reuse the framework's discovery, control, logging and stream interfaces. Keep device I/O separate from pure parsing/arithmetic so useful behavior can be checked without a device.

Use SignalGenerator as an example of service plus independently testable logic. Use feetStim for a native UI, serial/network dependencies and state-machine integration. Copy only the structure relevant to the new module; neighboring hardware assumptions are not generic defaults.

Create `src/myModule/` with `main.cpp`, configuration/state ownership, and driver/logic source as required. A minimal headless entrypoint is:

```cpp
#include "myconfig.hpp"
#include <Resonance/ResonanceApp.hpp>

int main(int argc, char* argv[])
{
    Resonance::ResonanceApp app(argc, argv, "myService");
    MyConfig config;
    return app.exec();
}
```

A native Widget application creates its `QApplication` first, then `ResonanceApp`, as in [feetStim/main.cpp](../../src/feetStim/main.cpp). Choose window-close behavior intentionally; closing a control window must not accidentally terminate an active device.

## 2. Implement parameters, states and data

- Create the required `Parameters::*`, register them with `CommunicationLayer::addParameter`, and retain their ownership. Give every parameter a stable name, group/index, short label, description, units/range where relevant, and correct enabled/read-only/visible behavior.
- Connect local edits and remote apply behavior according to [framework](../architecture/framework.md#parameter-model-and-updates). Publish and act on refusals; loading a file must not silently arm an operation against old state.
- Build a `ResonanceState`/`ResonanceTransition` graph. Remote clients send transition names; expose only operations available in the current state. Use `Action` for explicit operations that must not be replayed from saved values.
- Keep slow/blocking device I/O in the appropriate worker. Preserve QObject thread affinity, queued delivery and buffer ownership. Define stop/release/error behavior before exposing start/fire operations.
- Publish an `OutputStream` with the correct transmittable type and metadata. Use `SamplesCollector` where appropriate; maintain channel order, timing and count semantics. Report dropped samples only if the driver actually measures them.

Do not introduce a second network policy in the new service. Framework traffic follows [network](../architecture/network.md); document any external device/protocol socket separately in the component page.

## 3. Add the Qt 6 build target

Adapt this template to the modules the service actually uses:

```cmake
project(myModule)
find_package(Qt6 6.11 REQUIRED COMPONENTS Core StateMachine)

add_executable(myModule WIN32
    main.cpp myconfig.cpp myconfig.hpp mydriver.cpp mydriver.hpp)
target_link_libraries(myModule PRIVATE
    Resonance Qt6::Core Qt6::StateMachine)
if(MSVC)
    target_compile_options(myModule PRIVATE /utf-8)
endif()

install_target(myModule)
resonance_icon(myModule my-module)
install_files(myModule "" myModule.bat)
```

Qt 6's StateMachine is a separate module. List every Qt dependency used in both `find_package` and target linkage; add Gui/Widgets/SerialPort/Network/etc. only when needed. Top-level CMake supplies automatic MOC/UIC/RCC defaults. Add `add_subdirectory(myModule)` to the active root CMake list.

Architecture-specific SDKs need an explicit supported-platform gate or clear configuration error, and documented runtime inputs. A 32-bit vendor library cannot be linked into the x64 process; KARDi2's separate broker demonstrates that boundary. Managed bridges need their own compatible language/exception/assembly settings rather than global flags.

The icon helper requires an existing `icons/ico/my-module.ico` input. Follow [icons/README.md](../../src/icons/README.md) to add the icon and launcher mapping; do not leave an unresolved template icon name in CMake.

## 4. Add launcher and runtime content

Use the current launcher shape so the environment is located from the launcher's own directory:

```bat
@echo off
call "%~dp0env.bat"
cd /d "%RESONANCE_DIR%/bin"
start "myService" myModule.exe %*
```

The launcher forwards arguments. If multiple instances can coexist, provide distinct service/stream names; two default-identical producers are ambiguous to viewers and recorders. Use framework content helpers for parameter/protocol/montage/calibration/data paths rather than the working directory.

Install required defaults/vendor files through CMake into their correct package locations. Keep private SDK directories private and distinguish shipped defaults from operator-owned content. Update the deployment script's required-input/scanned-target lists and applicable package validator when a new binary, plugin, runtime or driver payload requires it; see [deploy](deploy.md).

## 5. Verify the new behavior

Create meaningful tests for the service's pure logic or observable contract. Register each runnable test with `add_test`; simply building a test executable does not make CTest run it. Keep test binaries outside `runtime/` so they are not installed as services. Device-dependent checks need explicit prerequisites and deliberate execution.

Run the [parameter-description audit](../../src/scripts/audit-parameter-descriptions.py), build the target through the [normal environment](build.md), and use the [test guide](test.md) to select checks. Verify description discovery, state/parameter behavior, stream metadata, refusal handling and stop/release using a synthetic/emulated path where possible. Any physical-device result needs its own scoped evidence.

## 6. Add the component context

Create `docs/components/<service-slug>.md` with purpose, source entrypoints, parameters/states/streams, dependencies, non-obvious contracts, verification commands and current limitations. Add one route to [source map](../architecture/source-map.md); put unresolved work in [issues](../issues/README.md). Add dated rationale to the relevant history/decision record only when it explains a consequential choice. Keep operator materials in their separate maintained form.

A finished service integrates source, build, runtime inputs, discoverable documentation and appropriate verification. It does not become hardware-qualified merely by appearing in the CMake build list.

