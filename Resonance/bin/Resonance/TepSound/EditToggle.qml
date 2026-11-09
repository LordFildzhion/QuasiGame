import QtQuick 2.15
import QtQuick.Controls 2.15

/**
 * A checkbox whose state is driven from outside.
 *
 * ⚠⚠ This is the exact control the ghosting defect was found in. A `CheckBox` assigns its own
 * `checked` on release; if `checked` was bound to a model value, that binding is destroyed by the
 * first click and the delegate carries the stale value onto whatever row it is recycled onto —
 * which is how a channel that had never been touched came up ticked.
 *
 * So the tick here is drawn, not owned: `sourceValue` decides what is painted, the click only
 * emits, and the paint changes when — and only when — the service says the document changed.
 * A refused toggle therefore visibly does not move, which is the correct feedback.
 */
Item {
    id: root

    property bool sourceValue: false
    property string text: ""
    property bool readOnly: false

    signal commit(bool value)

    implicitHeight: 20
    implicitWidth: box.width + (root.text !== "" ? caption.implicitWidth + 6 : 0)

    Rectangle {
        id: box
        width: 14
        height: 14
        radius: 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.raised
        border.width: 1
        border.color: root.readOnly ? Theme.rule
                    : (hover.hovered ? Theme.accent : Theme.rule)

        Rectangle {
            width: 7
            height: 7
            anchors.centerIn: parent
            visible: root.sourceValue
            color: Theme.accent
        }
    }

    Text {
        id: caption
        visible: root.text !== ""
        text: root.text
        color: root.readOnly ? Theme.faint : Theme.dim
        font.pixelSize: Theme.fontBody
        anchors.left: box.right
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
    }

    HoverHandler { id: hover; enabled: !root.readOnly }

    MouseArea {
        anchors.fill: parent
        enabled: !root.readOnly
        cursorShape: Qt.PointingHandCursor
        // Emits. Never assigns. The tick moves when the document moves.
        onClicked: root.commit(!root.sourceValue)
    }
}
