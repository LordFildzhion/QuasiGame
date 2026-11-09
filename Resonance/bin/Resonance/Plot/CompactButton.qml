import QtQuick 2.15
import QtQuick.Controls 2.15

/**
 * A button sized to its text.
 *
 * Reducing font and padding is not enough on its own: the Default style's button background
 * carries `implicitWidth: 100` and `implicitHeight: 40`, which floor the control no matter what
 * the content needs. Five of these in a row overflowed a 285 px panel. Replacing the background
 * is what actually makes them compact.
 */
Button {
    id: control

    /// Colour to take while checked, instead of the usual pale blue. Lets one toggle carry a
    /// state that matters more than on/off -- armed versus fired -- without a second indicator
    /// beside it. Transparent means "use the normal checked colour".
    property color accentColor: "transparent"

    padding: 4
    topPadding: 1
    bottomPadding: 1
    font.pixelSize: 11
    focusPolicy: Qt.NoFocus

    background: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        radius: 2
        border.width: 1
        border.color: control.enabled ? (control.hovered ? "#6b6b6b" : "#a8a8a8") : "#d0d0d0"
        color: {
            if (!control.enabled)
                return "#f2f2f2"
            if (control.down)
                return "#c8d8ea"
            if (control.checked || control.highlighted)
                return control.accentColor.a > 0 ? control.accentColor : "#d6e4f2"
            return control.hovered ? "#f0f0f0" : "#f8f8f8"
        }
    }

    contentItem: Text {
        text: control.text
        font: control.font
        color: control.enabled ? "#1e1e1e" : "#9a9a9a"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
