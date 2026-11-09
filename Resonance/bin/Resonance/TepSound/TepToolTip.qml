import QtQuick 2.15
import QtQuick.Controls 2.15

/**
 * A tooltip of fixed width whose text wraps into it.
 *
 * A stock Controls 2 `ToolTip` lays its text out on **one line** and grows to fit, so a
 * three-sentence description becomes a strip across the whole application window, nowhere near
 * the pointer. `ToolTip` has no maximum-width property: the width has to be set *and* the content
 * item told to wrap at it, which is the entire reason this wrapper exists.
 *
 * The same trap, and the same fix, as `ParameterToolTip.qml` in the plugin.
 */
ToolTip {
    id: root

    property int fixedWidth: 320

    delay: 550
    timeout: 12000
    width: fixedWidth
    padding: 8

    background: Rectangle {
        color: Theme.raised
        border.color: Theme.rule
        border.width: 1
        radius: 3
    }

    contentItem: Text {
        text: root.text
        color: Theme.ink
        font.pixelSize: Theme.fontSmall
        // Both halves are needed. Without the explicit width the wrap mode has nothing to wrap
        // against and the tooltip grows to one long line again.
        width: root.fixedWidth - root.padding * 2
        wrapMode: Text.WordWrap
        lineHeight: 1.25
    }
}
