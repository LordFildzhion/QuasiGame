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
    readonly property var checkedList: (self.parent && self.parent.serialized)
                                       ? self.parent.serialized : []
    property var selectedRows: ({})
    property int selectionAnchor: -1

    function toggleRows(rows) {
        if (!self.parent || !self.parent.serialized)
            return
        var list = [...self.parent.serialized]
        var changed = false
        for (var k = 0; k < rows.length; ++k) {
            var row = rows[k]
            if (row >= 0 && row < list.length) {
                list[row] = !list[row]
                changed = true
            }
        }
        if (changed)
            self.parent.serialized = list
    }

    function isSelected(row) {
        return selectedRows[row] === true
    }

    /**
     * ⭐ Every path that selects a row must also TAKE THE KEYBOARD.
     *
     * `Keys.onSpacePressed` below only fires while the ListView has **active** focus, and
     * `focus: true` alone does not give it any: it sets focus within this component's scope,
     * which is inert until something up the chain hands the scope active focus. Nothing does --
     * this editor is loaded into a Loader inside ParametersView, and a MouseArea does not take
     * focus by design.
     *
     * So selecting a channel with the mouse and pressing Space did nothing at all. The row
     * highlighted, the keystroke went somewhere else, and the channel did not toggle. That is
     * the whole of the reported defect, and it is a regression from the Qt 5 Controls 1
     * TableView, which had a real selection model and its own key handling.
     */
    function takeFocus() {
        channelList.forceActiveFocus()
    }

    function selectRow(row, modifiers) {
        var selected = ({})
        if ((modifiers & Qt.ShiftModifier) && selectionAnchor >= 0) {
            var first = Math.min(selectionAnchor, row)
            var last = Math.max(selectionAnchor, row)
            for (var i = first; i <= last; ++i)
                selected[i] = true
        } else if (modifiers & Qt.ControlModifier) {
            selected = Object.assign({}, selectedRows)
            if (selected[row])
                delete selected[row]
            else
                selected[row] = true
            selectionAnchor = row
        } else {
            selected[row] = true
            selectionAnchor = row
        }
        selectedRows = selected
        channelList.currentIndex = row
        takeFocus()
    }

    /**
     * Arrow-key movement, which has to leave the selection where Space will act.
     *
     * The previous version moved `currentIndex` and nothing else, so the arrows walked an
     * INVISIBLE cursor while Space kept toggling whatever the mouse had last selected -- two
     * different notions of "the current row" with only one of them drawn. Moving the selection
     * with the cursor is what a list is expected to do; Shift extends from the anchor instead.
     */
    function moveCurrent(delta, modifiers) {
        var count = self.channels ? self.channels.length : 0
        if (count <= 0)
            return
        var from = channelList.currentIndex >= 0 ? channelList.currentIndex : 0
        var row = Math.max(0, Math.min(count - 1, from + delta))
        selectRow(row, modifiers & Qt.ShiftModifier)
        channelList.positionViewAtIndex(row, ListView.Contain)
    }

    function selectedRowNumbers() {
        var rows = []
        for (var key in selectedRows) {
            if (selectedRows[key])
                rows.push(Number(key))
        }
        return rows
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
                spacing: 0
                Label { Layout.preferredWidth: 30; text: "" }
                Label {
                    Layout.fillWidth: true
                    text: qsTr("Channel name")
                    font.bold: true
                }
            }
        }

        ListView {
            id: channelList
            // Named so a test can find the item that actually has to hold the keyboard.
            objectName: "channelListView"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            focus: true
            model: self.channels ? self.channels.length : 0
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { }

            // A list you can tab into. Without this the editor is reachable only with the mouse,
            // and the keyboard handlers below can never be the thing that has focus.
            activeFocusOnTab: true

            Keys.onSpacePressed: function(event) {
                var rows = self.selectedRowNumbers()
                if (rows.length === 0 && currentIndex >= 0)
                    rows = [currentIndex]
                self.toggleRows(rows)
                event.accepted = true
            }
            Keys.onUpPressed: function(event) { self.moveCurrent(-1, event.modifiers); event.accepted = true }
            Keys.onDownPressed: function(event) { self.moveCurrent(1, event.modifiers); event.accepted = true }
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
                    var all = ({})
                    var count = self.channels ? self.channels.length : 0
                    for (var i = 0; i < count; ++i)
                        all[i] = true
                    self.selectedRows = all
                    event.accepted = true
                }
            }

            delegate: Rectangle {
                required property int index
                width: channelList.width
                // Match the compact 16 px Qt 5 desktop rows, with two extra pixels for the
                // Controls 2 font rather than inheriting Fusion's 28 px touch-oriented metric.
                height: 18
                color: self.isSelected(index) ? "#d7e8f8"
                                              : (index % 2 ? "#fafafa" : "#ffffff")

                /// The keyboard cursor, drawn. Space acts on the selection, and the selection
                /// follows the cursor -- so if the cursor is invisible the operator cannot tell
                /// what the next keystroke will do. Only shown while the list actually holds the
                /// keyboard, so it never competes with the mouse selection for attention.
                Rectangle {
                    anchors.fill: parent
                    visible: channelList.activeFocus && channelList.currentIndex === index
                    color: "transparent"
                    border.color: "#5a8fc7"
                    border.width: 1
                }

                Rectangle {
                    id: checkMark
                    x: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 13
                    height: 13
                    radius: 2
                    color: "white"
                    border.color: "#777777"

                    Rectangle {
                        anchors.centerIn: parent
                        visible: self.checkedList[index] === true
                        width: 7
                        height: 7
                        color: "#303030"
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5
                        // Ticking the box also makes this the current row and takes the
                        // keyboard, so Space continues from wherever the mouse left off rather
                        // than from whatever was selected before it.
                        onClicked: {
                            channelList.currentIndex = index
                            self.takeFocus()
                            self.toggleRows([index])
                        }
                    }
                }

                Text {
                    x: 30
                    width: parent.width - x - 4
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: self.channels ? self.channels[index] : ""
                }

                MouseArea {
                    anchors.left: parent.left
                    anchors.leftMargin: 30
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    acceptedButtons: Qt.LeftButton
                    onClicked: function(mouse) { self.selectRow(index, mouse.modifiers) }
                    onDoubleClicked: self.toggleRows([index])
                }
            }
        }
    }
}
