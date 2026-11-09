import QtQuick 2.15
import QtQuick.Controls 2.15

/**
 * A number entry with the same no-state-of-its-own contract as `EditField`.
 *
 * A `SpinBox` was the obvious choice and is the wrong one twice over: Controls 2 floors it at
 * 100×40 px through its background item (the same wall the signal viewer hit), and its `value` is
 * a two-way binding target, which is exactly the ownership this tree has already been bitten by.
 *
 * So this is `EditField` with a parse in front of the commit. Anything unparseable is **not**
 * committed and the box reverts, which is the honest outcome: a field that silently turned
 * "1.9s" into 1 would be a worse liar than one that refused it.
 */
Item {
    id: root

    /// The value to show. Assigned in, never bound.
    property real sourceValue: 0
    property int decimals: 0
    property real minimum: -2147483647
    property real maximum: 2147483647
    property string suffix: ""
    property string placeholder: ""
    property bool readOnly: false

    /// Committed only when the text parses and lands inside the range.
    signal commit(real value)

    implicitHeight: 22
    implicitWidth: 72

    function formatted() {
        return root.decimals > 0 ? root.sourceValue.toFixed(root.decimals)
                                 : Math.round(root.sourceValue).toString()
    }

    onSourceValueChanged: entry.text = root.formatted()
    onDecimalsChanged: entry.text = root.formatted()
    Component.onCompleted: entry.text = root.formatted()

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: root.readOnly ? "transparent" : Theme.raised
        border.width: 1
        border.color: entry.activeFocus ? Theme.accent
                    : !entry.acceptableInput ? Theme.bad : Theme.rule
    }

    TextInput {
        id: entry

        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: root.suffix !== "" ? suffixText.width + 8 : 5
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignRight
        color: root.readOnly ? Theme.dim : Theme.ink
        font.pixelSize: Theme.fontBody
        font.family: "Consolas"
        selectByMouse: true
        selectionColor: Theme.accent
        selectedTextColor: "#241A08"
        clip: true
        readOnly: root.readOnly

        // A validator rather than a filter on input: typing a minus sign, or clearing the box to
        // retype it, must not be blocked mid-edit. The check that matters happens at commit.
        validator: DoubleValidator {
            bottom: root.minimum
            top: root.maximum
            decimals: root.decimals
            notation: DoubleValidator.StandardNotation
        }

        function tryCommit() {
            var parsed = parseFloat(entry.text)
            if (isNaN(parsed) || parsed < root.minimum || parsed > root.maximum) {
                entry.text = root.formatted()
                return
            }
            if (parsed !== root.sourceValue)
                root.commit(parsed)
            // Redrawn from the truth whatever happened. If the service clamped or refused, the
            // box shows what the document actually holds rather than what was typed at it.
            entry.text = root.formatted()
        }

        onActiveFocusChanged: {
            if (activeFocus)
                selectAll()
            else
                tryCommit()
        }
        onAccepted: tryCommit()

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            visible: entry.text === "" && !entry.activeFocus && root.placeholder !== ""
            text: root.placeholder
            color: Theme.faint
            font: entry.font
        }
    }

    Text {
        id: suffixText
        visible: root.suffix !== ""
        text: root.suffix
        color: Theme.faint
        font.pixelSize: Theme.fontSmall
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
    }
}
