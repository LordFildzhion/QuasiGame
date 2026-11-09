import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * One line per epoch, newest first: its number, its condition, what the MEP measured, and whether
 * it is in the average.
 *
 * **Selection is the point of it, not decoration.** Picking several epochs and seeing their
 * average is how two conditions get compared during a session, or how a run before and after the
 * coil moved gets looked at — without waiting for the session to end and without a script. The
 * modifiers are the ones every list in every operating system uses:
 *
 * | | |
 * |---|---|
 * | click | that epoch alone; it becomes the anchor |
 * | Ctrl + click | add or remove one, keep the rest |
 * | Shift + click | everything between the anchor and here |
 * | ↑ ↓ | one epoch at a time, Shift to extend |
 * | Ctrl + A | all of them |
 * | Esc | back to the running average |
 * | right-click | reject or un-reject (never deletes) |
 *
 * The legacy console had none of this: it had a counter.
 */
Rectangle {
    id: root

    property var rows: []
    property var selection: []
    property int anchor: 0

    signal picked(int number, bool additive, bool range)
    signal toggled(int number, bool rejected)
    signal selectAllRequested()
    signal selectionCleared()

    color: Theme.panel
    border.color: Theme.rule
    border.width: 1
    radius: 3
    clip: true

    function isSelected(n) { return root.selection.indexOf(n) !== -1 }

    // The list takes focus on any click, so the shortcuts below apply to it and not to whichever
    // plot happened to be focused first.
    Keys.onPressed: {
        if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
            root.selectAllRequested()
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            root.selectionCleared()
            event.accepted = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 1
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            height: 20
            color: Theme.raised
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 4
                Text { text: "#";      color: Theme.faint; font.pixelSize: Theme.fontSmall; Layout.preferredWidth: 34 }
                Text { text: "time";   color: Theme.faint; font.pixelSize: Theme.fontSmall; Layout.preferredWidth: 54 }
                Text { text: "MEP mV"; color: Theme.faint; font.pixelSize: Theme.fontSmall; Layout.preferredWidth: 58; horizontalAlignment: Text.AlignRight }
                Text { text: "onset";  color: Theme.faint; font.pixelSize: Theme.fontSmall; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight }
                Text { text: "rms";    color: Theme.faint; font.pixelSize: Theme.fontSmall; Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight }
                Text { text: "label";  color: Theme.faint; font.pixelSize: Theme.fontSmall; Layout.fillWidth: true }
                Text {
                    text: root.selection.length > 1 ? root.selection.length + " selected" : ""
                    color: Theme.accent
                    font.pixelSize: Theme.fontSmall
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.rows
            clip: true
            focus: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            /**
             * ⚠ A `ListView`'s own arrow keys move `currentIndex`, which this table does not
             * use — selection is the service's, keyed by an epoch's SERIAL. So the arrows moved
             * a cursor nothing draws and nothing reads, and pressing Down twice changed nothing
             * on screen. They move the selection instead, from the anchor, with Shift extending
             * the range exactly as Shift-click does.
             *
             * Rows are newest first, so Down walks back through the session.
             */
            Keys.onPressed: {
                if (event.key !== Qt.Key_Up && event.key !== Qt.Key_Down)
                    return
                if (root.rows.length === 0)
                    return
                var at = -1
                for (var i = 0; i < root.rows.length; ++i) {
                    if (root.rows[i].n === root.anchor) {
                        at = i
                        break
                    }
                }
                at = at < 0 ? 0
                   : (event.key === Qt.Key_Down ? Math.min(root.rows.length - 1, at + 1)
                                                : Math.max(0, at - 1))
                root.picked(root.rows[at].n, false,
                            (event.modifiers & Qt.ShiftModifier) !== 0)
                list.positionViewAtIndex(at, ListView.Contain)
                event.accepted = true
            }

            delegate: Rectangle {
                id: row
                width: list.width
                height: 20

                readonly property bool selected: root.isSelected(modelData.n)

                color: selected ? Qt.rgba(0.88, 0.65, 0.24, 0.18)
                     : (index % 2 === 0 ? "transparent" : Qt.rgba(1, 1, 1, 0.02))

                Rectangle {
                    visible: modelData.n === root.anchor && root.selection.length > 1
                    width: 2
                    height: parent.height
                    color: Theme.accent
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 4

                    Text {
                        text: modelData.n
                        color: modelData.rejected ? Theme.bad : Theme.ink
                        font.pixelSize: Theme.fontSmall
                        font.family: "Consolas"
                        Layout.preferredWidth: 34
                    }
                    Text {
                        text: modelData.time
                        color: Theme.dim
                        font.pixelSize: Theme.fontSmall
                        Layout.preferredWidth: 54
                    }
                    /**
                     * ⚠ An em-dash for "not measurable", never `0.000`.
                     *
                     * A zero amplitude is a finding — the subject produced no response. A
                     * missing one is not a finding at all, and the two used to be written
                     * identically here, while the onset column beside them rendered ITS zero as
                     * an em-dash: two columns of one row disagreeing about what a zero means.
                     * The service now sends a validity flag beside every figure and none of the
                     * three is substituted.
                     *
                     * A trailing `*` means the MEP window reached outside the epoch and the
                     * measurement was taken over the part that exists.
                     */
                    Text {
                        text: modelData.amplitudeValid
                              ? modelData.amplitude.toFixed(3)
                                + (modelData.windowClipped ? "*" : "")
                              : "—"
                        color: modelData.rejected ? Theme.faint
                             : modelData.amplitudeValid ? Theme.ink : Theme.faint
                        font.pixelSize: Theme.fontSmall
                        font.family: "Consolas"
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 58
                    }
                    Text {
                        text: modelData.onsetValid ? modelData.onset.toFixed(1) : "—"
                        color: Theme.dim
                        font.pixelSize: Theme.fontSmall
                        font.family: "Consolas"
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 44
                    }
                    Text {
                        text: modelData.rmsValid ? modelData.rms.toFixed(3) : "—"
                        color: modelData.rejected ? Theme.bad
                             : modelData.rmsValid ? Theme.dim : Theme.faint
                        font.pixelSize: Theme.fontSmall
                        font.family: "Consolas"
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 46
                    }
                    Text {
                        text: modelData.label
                        color: Theme.dim
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: {
                        list.forceActiveFocus()
                        if (mouse.button === Qt.RightButton) {
                            root.toggled(modelData.n, !modelData.rejected)
                            return
                        }
                        root.picked(modelData.n,
                                    (mouse.modifiers & Qt.ControlModifier) !== 0,
                                    (mouse.modifiers & Qt.ShiftModifier) !== 0)
                    }
                }
            }
        }
    }
}
