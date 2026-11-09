import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Frame {
    id: self

    implicitWidth: 120
    implicitHeight: 200
    padding: 1

    /**
     * ⭐ Show that we are disabled, because nothing else does.
     *
     * Every row, tick, check square and header below is painted from a hard-coded hex literal,
     * not from the palette -- so a disabled list rendered at full contrast while silently
     * swallowing every click. That was survivable only while "Hide disabled options" removed the
     * row outright; once disabled rows are shown (2026-09-02) it becomes a control that looks
     * live and is not, which is worse than either.
     *
     * Opacity rather than a second set of greyed literals: it is one binding, it cannot drift out
     * of step with the colours above it, and it reads unmistakably as unavailable.
     */
    opacity: self.enabled ? 1.0 : 0.45

    property var channels: self.parent ? self.parent.attributes : []
    readonly property var pairs: (self.parent && self.parent.serialized)
                                 ? self.parent.serialized : []

    function pairAt(row, side) {
        var list = self.pairs
        if (row < 0 || row >= list.length)
            return 0
        var pair = list[row]
        return (pair && pair[side] !== undefined) ? pair[side] : 0
    }

    function setPair(row, side, channelIndex) {
        if (!self.parent || !self.parent.serialized || row < 0 || row >= self.pairs.length)
            return
        var list = [...self.parent.serialized]
        var pair = [pairAt(row, 0), pairAt(row, 1)]
        pair[side] = channelIndex
        list[row] = pair
        self.parent.serialized = list
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 20
            color: "#eeeeee"
            border.color: "#c7c7c7"
            RowLayout {
                anchors.fill: parent
                spacing: 4
                Label { Layout.fillWidth: true; text: "A"; font.bold: true }
                Label { Layout.fillWidth: true; text: "B"; font.bold: true }
            }
        }

        ListView {
            id: pairList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: self.pairs.length
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { }

            delegate: Rectangle {
                id: pairRow
                required property int index
                width: pairList.width
                height: 24
                color: index % 2 ? "#fafafa" : "#ffffff"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 4

                    ComboBox {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        implicitHeight: 22
                        model: self.channels
                        currentIndex: self.pairAt(pairRow.index, 0)
                        onActivated: function(channelIndex) {
                            self.setPair(pairRow.index, 0, channelIndex)
                            currentIndex = Qt.binding(function() {
                                return self.pairAt(pairRow.index, 0)
                            })
                        }
                        onModelChanged: Qt.callLater(function() {
                            currentIndex = self.pairAt(pairRow.index, 0)
                        })
                    }

                    ComboBox {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        implicitHeight: 22
                        model: self.channels
                        currentIndex: self.pairAt(pairRow.index, 1)
                        onActivated: function(channelIndex) {
                            self.setPair(pairRow.index, 1, channelIndex)
                            currentIndex = Qt.binding(function() {
                                return self.pairAt(pairRow.index, 1)
                            })
                        }
                        onModelChanged: Qt.callLater(function() {
                            currentIndex = self.pairAt(pairRow.index, 1)
                        })
                    }
                }
            }
        }
    }
}
