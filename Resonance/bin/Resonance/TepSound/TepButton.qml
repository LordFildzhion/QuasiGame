import QtQuick 2.15
import QtQuick.Controls 2.15

/**
 * A compact button.
 *
 * The background is replaced rather than restyled: Controls 2 floors every control at 100x40 px
 * *through its background item*, and no amount of font and padding tuning gets under that. The
 * signal viewer's densification pass found this the long way ([signal-viewer.md §11]).
 */
Button {
    id: root

    property bool primary: false
    property color tint: Theme.raised

    implicitHeight: 26
    implicitWidth: Math.max(64, contentItem.implicitWidth + 22)
    font.pixelSize: Theme.fontBody
    hoverEnabled: true

    background: Rectangle {
        radius: 3
        color: !root.enabled ? Qt.darker(root.tint, 1.4)
             : root.down     ? Qt.darker(root.primary ? Theme.accent : root.tint, 1.25)
             : root.hovered  ? Qt.lighter(root.primary ? Theme.accent : root.tint, 1.15)
                             : (root.primary ? Theme.accent : root.tint)
        border.color: root.primary ? Qt.darker(Theme.accent, 1.3) : Theme.rule
        border.width: 1
    }

    contentItem: Text {
        text: root.text
        font: root.font
        color: !root.enabled ? Theme.faint : (root.primary ? "#241A08" : Theme.ink)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    ToolTip.visible: hovered && ToolTip.text !== ""
    ToolTip.delay: 500
}
