import QtQuick 2.15
import QtQuick.Controls 2.15

/**
 * A single-line text entry that is driven by a value from outside and reports edits back out.
 *
 * ### ⚠ WHY THIS TYPE EXISTS: no editable control may own its state
 *
 * The channel-checkmark ghosting in this tree was a delegate assigning its own `checked` on
 * release: the assignment destroyed the binding, the delegate was recycled onto another row, and
 * the value came with it. A text field is worse, because a `TextField` writes its own `text` on
 * every keystroke by construction — so `text: someModelValue` is a binding that the first key
 * press destroys, permanently, and the field then shows one row's text against another row's
 * data for the rest of the session.
 *
 * The arrangement here removes the possibility rather than the symptom:
 *
 *  * `sourceValue` is the outside truth. It is **assigned into** `text`, never bound to it.
 *  * Any change of `sourceValue` re-assigns — so a panel filling with a different row's values,
 *    or a delegate being recycled, always redraws from the truth.
 *  * Losing focus re-assigns too, which means an abandoned half-edit reverts visibly instead of
 *    sitting there looking committed.
 *  * `commit(value)` is emitted on Enter and on focus-out, and **only** then. Emitting per
 *    keystroke would revalidate the whole experiment on every letter of a label.
 *
 * The result is that this component holds a display string and nothing else. Every value that
 * matters lives in the service, which is the only place the operator's document exists.
 */
Item {
    id: root

    /// The value to show. Assigned into the entry; never bound to it.
    property string sourceValue: ""
    property string placeholder: ""
    property bool readOnly: false
    /// Right-align numbers, left-align names. Set by the caller because only it knows which.
    property int alignment: Text.AlignLeft
    property alias horizontalAlignment: root.alignment
    property alias font: entry.font
    property color textColour: Theme.ink

    /// The operator finished an edit. @p value is what the entry now holds.
    signal commit(string value)

    implicitHeight: 22
    implicitWidth: 120

    function sync() {
        entry.text = root.sourceValue
        if (!entry.activeFocus) entry.cursorPosition = 0
    }
    onSourceValueChanged: root.sync()

    Component.onCompleted: root.sync()

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: root.readOnly ? "transparent" : Theme.raised
        border.width: 1
        border.color: entry.activeFocus ? Theme.accent : Theme.rule
    }

    TextInput {
        id: entry

        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: root.alignment
        color: root.readOnly ? Theme.dim : root.textColour
        font.pixelSize: Theme.fontBody
        selectByMouse: true
        selectionColor: Theme.accent
        selectedTextColor: "#241A08"
        clip: true
        readOnly: root.readOnly

        onActiveFocusChanged: {
            if (activeFocus) {
                selectAll()
                return
            }
            // Committed on the way out, then redrawn from the truth. If the service refuses the
            // value — an unparseable sequence, a field this build does not know — `sourceValue`
            // does not change and the reassignment below puts the old text back, so the box never
            // shows a value the document does not hold.
            root.commit(entry.text)
            root.sync()
        }
        onAccepted: root.commit(entry.text)

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: root.alignment
            visible: entry.text === "" && !entry.activeFocus && root.placeholder !== ""
            text: root.placeholder
            color: Theme.faint
            font: entry.font
            elide: Text.ElideRight
        }
    }
}
