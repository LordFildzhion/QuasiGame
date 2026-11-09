import QtQuick 2.15

/**
 * A device's state as a shape as well as a word.
 *
 * The console is scanned, not read, so what needs attention has to survive peripheral vision.
 * A coloured dot plus the state text does that; the state text alone does not.
 */
Row {
    id: root

    property string state: ""
    property bool present: false

    spacing: 6

    /// Semantic, and separate from the accent: green/amber/red mean the device, not the brand.
    readonly property color dotColour: {
        if (!present)                       return Theme.idle
        if (state === "error")              return Theme.bad
        if (state === "running"
            || state === "recording")       return Theme.good
        if (state === "scanning"
            || state === "preparing")       return Theme.warn
        return Theme.dim
    }

    Rectangle {
        width: 8
        height: 8
        radius: 4
        color: root.dotColour
        anchors.verticalCenter: parent.verticalCenter
        // Hollow when absent: an unknown device must not read the same as a measured-good one.
        border.width: root.present ? 0 : 1
        border.color: Theme.faint
    }

    Text {
        text: root.present ? root.state : qsTr("not found")
        color: root.present ? Theme.ink : Theme.faint
        font.pixelSize: Theme.fontBody
        anchors.verticalCenter: parent.verticalCenter
    }
}
