import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: sv
    anchors.fill: parent
    anchors.margins: 4
    clip: true
    leftPadding: 3
    rightPadding: 3
    topPadding: 2
    // Keep the final control wholly above the frame when the content is scrolled to its end.
    bottomPadding: 6

    readonly property alias layout: layo
    property var pairs: ({})

    GridLayout {
        columns: 2
        id: layo

        rowSpacing: 2
        columnSpacing: 6

        width: Math.max(sv.availableWidth, implicitWidth)
    }

    background: Rectangle {
        color: sv.palette.base
        border.color: sv.palette.mid
    }
}
