import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * A labelled numeric entry that accepts decimals.
 *
 * Controls 2's SpinBox is integer-only, and Controls 1 -- which the old settings panel used for
 * its decimal spin boxes -- does not exist in Qt 6. This is the replacement.
 *
 * Deliberately compact: this is a desktop instrument panel, not a touch target. The suffix column
 * has a fixed width whether or not there is a suffix, so the steppers of every field in a panel
 * line up instead of stepping in and out by the width of "Hz".
 */
RowLayout {
    id: root

    property string label: ""
    property real value: 0
    property real minimumValue: -1e12
    property real maximumValue: 1e12
    property int decimals: 2
    property real stepSize: 1
    property string suffix: ""
    property int fieldWidth: 66
    /// Reserved for the suffix even when empty, so steppers align down a column.
    property int suffixWidth: 20
    property bool showSteppers: true
    /**
     * Step through the 1-2-5 sequence instead of by a fixed amount.
     *
     * For an amplitude scale a fixed step is useless: the same increment is far too coarse at
     * 10 uV and far too fine at 50 V. Stepping by decade-and-a-half is how every oscilloscope's
     * volts/div works, and it is what makes one control cover microvolts to volts.
     */
    property bool logSteps: false
    /// Negative means "size the caption to its text".
    property real labelWidth: -1

    /// True while the text field holds keyboard focus. A panel that rebuilds itself when a value
    /// changes needs this to know not to rebuild out from under someone who is typing.
    readonly property bool editing: field.activeFocus

    signal edited(real value)

    spacing: 3
    Layout.preferredHeight: 20

    function commit(v) {
        var clamped = Math.max(minimumValue, Math.min(maximumValue, v))
        if (!isFinite(clamped))
            return
        if (clamped !== root.value) {
            root.value = clamped
            root.edited(clamped)
        }
        field.text = root.value.toFixed(root.decimals)
    }

    /// Next value up or down the 1-2-5 ladder.
    function nice125(v, up) {
        if (!(v > 0))
            return up ? 1 : 0
        var exponent = Math.floor(Math.log(v) / Math.LN10)
        var decade = Math.pow(10, exponent)
        var f = v / decade
        var seq = [1, 2, 5, 10]
        if (up) {
            for (var i = 0; i < seq.length; ++i)
                if (seq[i] > f * 1.0001)
                    return seq[i] * decade
            return 10 * decade
        }
        for (var j = seq.length - 1; j >= 0; --j)
            if (seq[j] < f * 0.9999)
                return seq[j] * decade
        return 0.5 * decade
    }

    function step(up) {
        if (root.logSteps)
            root.commit(root.nice125(root.value, up))
        else
            root.commit(root.value + (up ? root.stepSize : -root.stepSize))
    }

    Label {
        id: caption
        text: root.label
        visible: text !== ""
        elide: Text.ElideRight
        font.pixelSize: 11
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: root.labelWidth >= 0 ? root.labelWidth : implicitWidth
    }

    TextField {
        id: field
        Layout.preferredWidth: root.fieldWidth
        Layout.preferredHeight: 20
        padding: 2
        leftPadding: 4
        rightPadding: 4
        font.pixelSize: 11
        horizontalAlignment: TextInput.AlignRight
        selectByMouse: true
        text: root.value.toFixed(root.decimals)

        background: Rectangle {
            radius: 2
            color: field.enabled ? "#ffffff" : "#f2f2f2"
            border.width: 1
            border.color: field.activeFocus ? "#4a90d9" : "#a8a8a8"
        }

        validator: DoubleValidator {
            bottom: root.minimumValue
            top: root.maximumValue
            decimals: root.decimals
            notation: DoubleValidator.StandardNotation
        }

        // Committed on Enter or on clicking away -- never per keystroke.
        //
        // Applying every keystroke meant typing 1000 applied 1, then 10, then 100; and where the
        // value feeds a panel that rebuilds itself, the first character destroyed the field being
        // typed into. This is still not the old behaviour that made people press TAB: losing
        // focus commits, it does not revert.
        onEditingFinished: root.commit(parseFloat(text))

        // Enter means "done", so it gives up focus too. Without that the field stays in editing
        // mode, and anything that re-reads the value on the way out -- an SI prefix that should
        // renormalise 1000 uV to 1 mV, say -- is held back until the pointer happens to leave.
        Keys.onReturnPressed: field.focus = false
        Keys.onEnterPressed: field.focus = false

        onActiveFocusChanged: {
            if (activeFocus)
                return
            // editingFinished does not fire when the validator considers the text merely
            // Intermediate ("10." say), so clicking away would otherwise silently discard it.
            var v = parseFloat(text)
            root.commit(isFinite(v) ? v : root.value)
        }

        Keys.onEscapePressed: {
            field.text = root.value.toFixed(root.decimals)
            field.focus = false
        }

        // While the field has focus, an external change must not overwrite what is being typed.
        Connections {
            target: root
            function onValueChanged() {
                if (!field.activeFocus)
                    field.text = root.value.toFixed(root.decimals)
            }
        }

        // Only a focused field takes the wheel. Scrolling a settings panel must not silently
        // retune every filter it passes over.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true
            onWheel: {
                if (!field.activeFocus) {
                    wheel.accepted = false
                    return
                }
                root.step(wheel.angleDelta.y > 0)
                wheel.accepted = true
            }
        }
    }

    Label {
        text: root.suffix
        font.pixelSize: 11
        elide: Text.ElideRight
        Layout.preferredWidth: root.suffixWidth
        Layout.alignment: Qt.AlignVCenter
    }

    ColumnLayout {
        visible: root.showSteppers
        spacing: 0
        Layout.alignment: Qt.AlignVCenter

        Button {
            text: "▲"
            implicitWidth: 15
            implicitHeight: 10
            padding: 0
            font.pixelSize: 6
            focusPolicy: Qt.NoFocus
            onClicked: root.step(true)
            autoRepeat: true
        }
        Button {
            text: "▼"
            implicitWidth: 15
            implicitHeight: 10
            padding: 0
            font.pixelSize: 6
            focusPolicy: Qt.NoFocus
            onClicked: root.step(false)
            autoRepeat: true
        }
    }

    // The slack goes at the end, so the entry box, the suffix and the steppers all sit at fixed
    // offsets from the *left* of the value column. A leading stretch instead would anchor them to
    // the column's right edge, which is only identical between rows if every column is identical
    // -- and that is precisely what stops being true the moment one section has a full-width row.
    Item { Layout.fillWidth: true; Layout.minimumWidth: 0 }
}
