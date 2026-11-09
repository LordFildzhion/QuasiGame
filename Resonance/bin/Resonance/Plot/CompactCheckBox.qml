import QtQuick 2.15
import QtQuick.Controls 2.15

/**
 * A checkbox sized and drawn for an instrument panel.
 *
 * The Default style's indicator is a large rounded box with an oversized tick, which next to
 * 11 px labels reads as decoration rather than as a control. This is a plain square with a filled
 * square inside it when set -- the convention every measurement application already uses.
 */
CheckBox {
    id: control

    property int boxSize: 12

    padding: 0
    spacing: 4
    font.pixelSize: 11

    indicator: Rectangle {
        implicitWidth: control.boxSize
        implicitHeight: control.boxSize
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: 1
        border.width: 1
        border.color: !control.enabled ? "#c0c0c0"
                                       : (control.hovered ? "#4a4a4a" : "#808080")
        color: control.enabled ? "#ffffff" : "#f2f2f2"

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 6
            height: parent.height - 6
            radius: 1
            visible: control.checkState !== Qt.Unchecked
            color: control.enabled ? "#1e1e1e" : "#a0a0a0"
        }
    }

    contentItem: Text {
        leftPadding: control.indicator.width + control.spacing
        text: control.text
        font: control.font
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        color: control.enabled ? "#1e1e1e" : "#9a9a9a"
    }
}
