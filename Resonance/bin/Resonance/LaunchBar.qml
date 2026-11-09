import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Resonance 3.0

/// The icon strip: one button per line of `<root>\launchbar.txt`, meant for the menu-bar row of
/// the Configurator. The file is the operator's -- which launchers, in what order, in which
/// groups (a `[heading]` line starts one, drawn as a thin separator), with what tooltip and,
/// optionally, which icon; by default a button wears the icon of the executable its launcher
/// starts (LaunchBarModel has the format). A click runs the launcher from the distribution
/// root, as a double-click in Explorer would, minus the console flash. Wraps onto a second line
/// rather than hiding anything when the window is narrow.
Item {
    id: bar

    /// The icon edge in device-independent pixels. 16, 20, 24, 32 are sizes the .ico files carry
    /// as pixel-exact entries; anything else is a resample. 32 since 2026-09-24.
    property int iconSize: 32
    readonly property int count: launchers.count
    readonly property alias model: launchers

    implicitWidth: flow.implicitWidth
    implicitHeight: flow.implicitHeight

    LaunchBarModel { id: launchers }

    Flow {
        id: flow
        width: bar.width
        spacing: 0

        Repeater {
            model: launchers

            delegate: Row {
                id: item
                required property int index
                required property string name
                required property string file
                required property string program
                required property url iconSource
                required property string group
                required property bool firstInGroup
                required property string description
                required property bool available

                spacing: 0

                // The line between two groups.
                ToolSeparator {
                    visible: item.firstInGroup
                    height: button.height
                    padding: 0
                    horizontalPadding: 4
                    verticalPadding: 5
                }

                ToolButton {
                    id: button
                    padding: 3
                    display: AbstractButton.IconOnly
                    focusPolicy: Qt.NoFocus
                    enabled: item.available

                    // A plain Image rather than the button's icon: the icon is requested at the
                    // physical pixel size, so it is pixel-exact at 100 % and still crisp on a
                    // scaled display, and it is never tinted -- the tile colour is the family.
                    contentItem: Item {
                        implicitWidth: bar.iconSize
                        implicitHeight: bar.iconSize
                        Image {
                        anchors.centerIn: parent
                        source: item.iconSource
                        sourceSize: Qt.size(Math.round(bar.iconSize * Screen.devicePixelRatio),
                                            Math.round(bar.iconSize * Screen.devicePixelRatio))
                        width: bar.iconSize
                        height: bar.iconSize
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        opacity: button.enabled ? 1 : 0.4
                        }
                    }

                    // The tooltip is the description the file gives -- what the service does,
                    // in words -- and nothing else, unless the launcher is missing.
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    ToolTip.text: item.available ? item.description
                                                 : item.description + "\n⚠ not found: " + item.file

                    onClicked: launchers.launch(item.index)
                }
            }
        }
    }
}
