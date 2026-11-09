import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/// A label and a number, sized so a row of them reads as one instrument panel.
///
/// `hint` is optional and shows on hover. A pill is always enabled, so unlike a disabled button
/// its tooltip can actually be reached — which is why the numbers whose MEANING is the
/// interesting part (two different "accepted"s, a merged lost count, an inoperative interlock)
/// carry their explanation here rather than in a legend nobody opens.
Rectangle {
    id: root

    property string label: ""
    property string value: ""
    property color valueColor: Theme.ink
    property string suffix: ""
    property string hint: ""

    ToolTip.visible: root.hint !== "" && pillHover.containsMouse
    ToolTip.delay: 400
    ToolTip.text: root.hint
    MouseArea {
        id: pillHover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    color: Theme.raised
    border.color: Theme.rule
    border.width: 1
    radius: 3
    implicitWidth: Math.max(74, column.implicitWidth + Theme.pad * 2)
    implicitHeight: column.implicitHeight + Theme.gap * 2

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        spacing: 1

        Text {
            text: root.label
            color: Theme.faint
            font.pixelSize: Theme.fontSmall
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            text: root.value + root.suffix
            color: root.valueColor
            font.pixelSize: Theme.fontLarge
            font.family: "Consolas"
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
