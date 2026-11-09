import QtQuick 2.15
import QtQuick.Controls 2.15

/**
 * A compact number entry with a unit written into it.
 *
 * Not a `SpinBox`: Controls 2's is integer-only and its up/down buttons cannot be got under
 * 40 px without replacing three delegates. The two numbers on a plot's strip — the time range
 * and the amplitude — are typed or wheeled, never clicked up one at a time.
 */
Item {
    id: root

    property real value: 0
    property real minimumValue: -1e9
    property real maximumValue: 1e9
    property real step: 1
    property int decimals: 0
    property string suffix: ""
    /**
     * Two-way mode: the box does NOT write its own `value`, it only reports `edited` and lets the
     * owner's binding write back.
     *
     * The default, one-way, makes the box the source of truth — which is wrong the moment
     * anything in C++ also moves the number, because assigning `value` here would break the
     * binding that shows it and the box would then display a figure that is no longer true. That
     * is exactly what the auto-fit does, so its box is bound `value: plot.amplitude` and set to
     * `twoWay`. If the owner refuses the edit the field snaps back to the truth, which is the
     * honest answer and not a control that silently did nothing.
     */
    property bool twoWay: false
    /**
     * What this number is, on hover.
     *
     * ⚠ NOT the attached `ToolTip.text`. That property attaches to any `Item`, so it accepts the
     * assignment and looks correct in source — but nothing ever sets `ToolTip.visible` for a plain
     * Item, so the tooltip can never appear. Controls 2 `Button` shows one because `Button` opens
     * it itself; this is not a Button. Two boxes on the plot strips were written that way and
     * carried explanations no operator could reach.
     */
    property string hint: ""
    signal edited(real value)

    implicitHeight: 22
    implicitWidth: 86

    /**
     * A disabled box has to LOOK disabled.
     *
     * `enabled: false` on an `Item` stops the input reaching it and changes not one pixel, so a
     * box that is inert because a neighbouring toggle is off reads as a box the operator simply
     * typed the wrong thing into. The fit-interval boxes on the Visualization strip are exactly
     * that case.
     */
    opacity: root.enabled ? 1.0 : 0.45

    function commit(v) {
        var clamped = Math.max(minimumValue, Math.min(maximumValue, v))
        if (clamped !== root.value) {
            if (!root.twoWay)
                root.value = clamped
            root.edited(clamped)
        }
        // ⚠ Re-BIND, never assign. A plain `field.text = ...` destroys the `text:` binding
        // below on the first edit, and in two-way mode — where C++ owns the number — the box
        // then shows the figure it was last given for ever. Measured: the box read 120.0 µV
        // while the auto-fit had the plot at ±50 µV, which is the exact failure the two-way
        // mode exists to prevent. Re-binding keeps the round trip, as `ParamControl` already does.
        field.text = Qt.binding(function() { return root.value.toFixed(root.decimals) })
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.raised
        border.color: field.activeFocus ? Theme.accent : Theme.rule
        radius: 2
    }

    TextInput {
        id: field
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.right: unit.left
        anchors.rightMargin: 3
        anchors.verticalCenter: parent.verticalCenter
        text: root.value.toFixed(root.decimals)
        color: Theme.ink
        font.pixelSize: Theme.fontSmall
        font.family: "Consolas"
        horizontalAlignment: Text.AlignRight
        selectByMouse: true
        onEditingFinished: {
            var v = parseFloat(text)
            root.commit(isNaN(v) ? root.value : v)
        }
    }

    Text {
        id: unit
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        text: root.suffix
        color: Theme.faint
        font.pixelSize: Theme.fontSmall
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: root.hint !== ""
        onWheel: root.commit(root.value + (wheel.angleDelta.y > 0 ? root.step : -root.step))

        TepToolTip {
            text: root.hint
            visible: parent.containsMouse && root.hint !== ""
            x: 0
            y: root.height + 2
        }
    }
}
