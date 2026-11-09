import QtQuick 2.15
import QtQuick.Layouts 1.15

/**
 * One labelled row: a label column pinned to exactly `Theme.labelWidth`, and a control that takes
 * the rest.
 *
 * Pinned, minimum == maximum, rather than laid out in a GridLayout — a GridLayout negotiates the
 * column across every child, so one long label in one section widens the column for every other
 * section. That is [known-issues §14l] and it has been fixed twice in this tree already.
 *
 * **The tooltip lives on the label, not on the control.** Hovering a spin box to read what it does
 * means the explanation appears while the pointer is on the thing you are about to drag, and it
 * covers the neighbouring rows; hovering the *name* of a setting is what someone does when they
 * want to know what the name means. The label is also the only part of the row that is never
 * itself interactive.
 */
RowLayout {
    id: root

    property string label: ""
    /// Usually `param.description` from the service. Empty means no tooltip.
    property string hint: ""
    default property alias holderData: holder.data

    spacing: Theme.gap
    Layout.fillWidth: true

    Text {
        id: caption
        text: root.label
        color: hover.hovered && root.hint !== "" ? Theme.ink : Theme.dim
        font.pixelSize: Theme.fontBody
        font.underline: hover.hovered && root.hint !== ""
        elide: Text.ElideRight
        Layout.minimumWidth: Theme.labelWidth
        Layout.maximumWidth: Theme.labelWidth
        Layout.preferredWidth: Theme.labelWidth
        Layout.alignment: Qt.AlignVCenter

        // HoverHandler rather than a MouseArea: it reports hover without taking a click or a
        // wheel event away from anything underneath.
        HoverHandler { id: hover }

        TepToolTip {
            text: root.hint
            visible: hover.hovered && root.hint !== ""
            x: caption.width
            y: caption.height
        }
    }

    RowLayout {
        id: holder
        spacing: Theme.gap
        Layout.fillWidth: true
    }
}
