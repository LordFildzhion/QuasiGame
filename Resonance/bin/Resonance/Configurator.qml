import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import QtQml.Models
import QtCore
import Resonance 3.0

ApplicationWindow
{
    id: root
    // Embedded venue configurations need a stable identity of their own.
    width: 1200
    height: 850
    // Below this, the 220 px service/parameter pane plus two viewer minima and split handles
    // cannot all remain useful. Let Windows stop the resize instead of letting controls overlap
    // or silently disappear beyond an edge.
    minimumWidth: 760
    minimumHeight: 600
    visible:true

    // The menu-bar row: the two menus at the left, and the icon strip in the space to their
    // right that was always empty. The MenuBar keeps the whole row -- its background and its
    // keyboard handling are untouched -- and the strip is laid over the part of it that has no
    // menu, starting where the menus' content ends. View > Show icon strip hides it, and that
    // choice is remembered (Settings below); View > Edit icon strip opens its file.
    menuBar: Item {
        id: menuRow
        implicitHeight: Math.max(mainMenu.implicitHeight,
                                 launchBar.visible ? launchBar.implicitHeight : 0)

        MenuBar {
            id: mainMenu
            anchors.fill: parent

            Menu {
                title: "&Settings"
                implicitWidth: 300
                MenuItem {
                    id: opt_use_service_discovery_url
                    text: "Use service discovery URL for streams"
                    checkable: true
                    checked: true
                }
                MenuItem {
                    id: opt_delete_terminates_service
                    objectName: "deleteTerminatesServiceSetting"
                    text: "Delete terminates selected service"
                    checkable: true
                    checked: false
                }
            }

            Menu {
                title: "&View"
                ButtonGroup { id: viewerLayoutGroup }

                MenuItem {
                    text: "Viewers &stacked (2x1)"
                    checkable: true
                    ButtonGroup.group: viewerLayoutGroup
                    checked: viewerLayout.index === 0
                    onTriggered: viewerLayout.index = 0
                }
                MenuItem {
                    text: "Viewers side by &side (1x2)"
                    checkable: true
                    ButtonGroup.group: viewerLayoutGroup
                    checked: viewerLayout.index === 1
                    onTriggered: viewerLayout.index = 1
                }
                MenuSeparator { }
                MenuItem {
                    id: opt_show_launch_icons
                    text: "Show &icon strip"
                    checkable: true
                    checked: true
                }
                MenuItem {
                    text: "&Edit icon strip…"
                    // Explorer on the distribution root with launchbar.txt selected; the strip
                    // re-reads the file as soon as it is saved.
                    onTriggered: launchBar.model.edit()
                }
            }
        }

        LaunchBar {
            id: launchBar
            visible: opt_show_launch_icons.checked && count > 0
            x: mainMenu.leftPadding + mainMenu.contentWidth + 10
            y: Math.max(0, Math.round((parent.height - height) / 2))
            width: Math.max(0, parent.width - x - 4)
        }
    }

    Settings {
        category: "configurator"
        property alias showLaunchIcons: opt_show_launch_icons.checked
        property alias deleteTerminatesService: opt_delete_terminates_service.checked
    }

    function streamFromCtrlObject(ctrlObj){
        var json = ctrlObj.toJson();
        if(opt_use_service_discovery_url.checked){
            // leave only discover URL
            json.connections = json.connections.filter(url => url.startsWith('discover://'))
            delete json.uid
        }
        return json;
    }

    title: "Configurator"

    ServiceLocator {
      id: locator
    }

    /// How the two viewers are arranged. A parameter rather than a plain property so it persists
    /// with the rest of the service configuration and can be set from the parameter panel too.
    ///
    /// The container numbers its two Selects 1 and 2 (a Select cannot take a sort index of its
    /// own, see below), so they sit at the top of the plot tab, before viewer 1's entries at
    /// 10..15 and viewer 2's at 20..25; the head calibration below is at 90..93. ⚠ The default
    /// numbering, 10, 20, ... per container, collided with the viewers' and the two Selects
    /// swapped places with "Plot 1 stream" / "Plot 2 stream" between instances (2026-09-07).
    Parameters {
        firstIndex: 1
        indexStep: 1

        Select {
            id: viewerLayout
            name: "viewer_layout"
            group: "plot"
            label: "Viewer layout"
            options: ["Stacked (2x1)", "Side by side (1x2)"]
            // NOT `index: 1`, and reordering the two declarations does not help either --
            // measured, twice. `Select::setIndex` drops any index at or past the number of
            // options it currently holds, and an array literal like the line above is compiled
            // as a *binding*, which QML evaluates in a later phase than a plain literal such as
            // `index: 1`. So the index is always applied against an empty option list, always
            // rejected, and this always started stacked whatever the source said.
            // Component.onCompleted runs after both phases, which is the only ordering that
            // holds without a framework change.
            Component.onCompleted: index = 0
        }

        /// The head map's background picture, and how far the electrodes spread across it. One
        /// pair for the whole application: a rig has one cap and one picture of it, and asking
        /// for the path twice only creates a way for the two viewers to disagree. High indices so
        /// they sort to the bottom of the tab, under the per-viewer entries.
        String {
            id: headImageParam
            name: "head_image"
            group: "plot"
            label: "Head image"
            index: 90
        }

        // Fine steps and four decimals throughout: these are calibration numbers against a
        // picture, and the difference between 0.735 and 0.740 is visible on a 64-electrode cap.
        // The defaults are the measured figures for Bricks/topomap64_full_s.png.
        Double {
            id: headScaleParam
            name: "head_scale"
            group: "plot"
            label: "Head electrode spread"
            index: 91
            value: 0.739
            minimum: 0.05
            maximum: 4
            stepSize: 0.005
            decimals: 4
        }

        Double {
            id: headXParam
            name: "head_x"
            group: "plot"
            label: "Head centre x"
            index: 92
            value: 0.5006
            minimum: 0
            maximum: 1
            stepSize: 0.005
            decimals: 4
        }

        Double {
            id: headYParam
            name: "head_y"
            group: "plot"
            label: "Head centre y"
            index: 93
            value: 0.4690
            minimum: 0
            maximum: 1
            stepSize: 0.005
            decimals: 4
        }

        /**
         * ⭐ Which epoch viewer's time cursor drives the other one.
         *
         * The DIRECTION is configuration -- it is a decision about the rig that should survive a
         * restart -- so it is a parameter, like the head image beside it. The CURSOR ITSELF is
         * not: see StreamView.incomingCursor. Every `Double::setValue` schedules a full
         * service-description re-serialisation, and a live cursor is a mouse-move-rate signal.
         *
         * ⚠ `Select::index` SHADOWS `Parameter::index`: on a Select it is the chosen option,
         * not the sort position, so this one cannot be given a place in the tab the way the head
         * parameters above are. Same trap as `viewer_layout` -- and for the same reason the
         * default is set in Component.onCompleted rather than as a binding, because an `options`
         * array literal is compiled as a binding and evaluated after a plain literal `index`,
         * so any index set here would be applied against an empty option list and dropped.
         */
        Select {
            id: cursorLinkParam
            name: "epoch_cursor_link"
            group: "plot"
            label: "Epoch cursor link"
            options: ["Off", "Viewer 1 drives viewer 2", "Viewer 2 drives viewer 1"]
            Component.onCompleted: index = 0
        }
        Integer {
            id: secondarySizeParam
            name: "viewer_secondary_percent"
            group: "plot"
            label: "Secondary viewer size (%)"
            description: "Initial share of the two-viewer area applied by a preset. Zero uses the standard compact secondary pane. The divider remains draggable."
            minimum: 0; maximum: 90; value: 0
            onValueChanged: Qt.callLater(viewerSplit.applySecondarySize)
        }
    }

    // --- the live cursor ------------------------------------------------------------------------
    /**
     * ⭐ The cursor record in flight between the two viewers, or null.
     *
     * ⚠ `property var`, deliberately: a plain JavaScript object assigned to a typed gadget
     * property fails SILENTLY. Both viewers are in ONE QML process, so this is the whole
     * transport -- no parameter, no serialisation, no round trip through the service.
     *
     * ⚠ ONE WAY. Only the viewer whose role is "source" ever emits; the follower applies
     * and captions and never echoes. Writing a follower's clamped value back would drag the
     * source cursor to the follower's clamp and make it jump under the operator's hand.
     */
    property var epochCursor: null

    readonly property string cursorRole1: cursorLinkParam.index === 1 ? "source"
                                        : cursorLinkParam.index === 2 ? "follower" : "off"
    readonly property string cursorRole2: cursorLinkParam.index === 1 ? "follower"
                                        : cursorLinkParam.index === 2 ? "source" : "off"

    Binding { target: viewer;  property: "cursorLinkRole"; value: root.cursorRole1 }
    Binding { target: viewer2; property: "cursorLinkRole"; value: root.cursorRole2 }
    // Pushed to BOTH: the source ignores what arrives -- applyIncomingCursor() returns
    // immediately unless the role is "follower" -- so there is nothing to gate here, and gating it
    // would only create a second place for the direction to be decided.
    Binding { target: viewer;  property: "incomingCursor"; value: root.epochCursor }
    Binding { target: viewer2; property: "incomingCursor"; value: root.epochCursor }

    Connections {
        target: viewer
        function onCursorPublished(record) { root.epochCursor = record }
    }
    Connections {
        target: viewer2
        function onCursorPublished(record) { root.epochCursor = record }
    }

    // Pushed into both viewers, and taken back out of whichever one changes it. `Binding` rather
    // than a plain assignment because the viewer's own setup panel writes the same property
    // directly, which would break an ordinary binding and leave the two viewers disagreeing; a
    // Binding re-asserts itself as soon as the parameter moves again, so the round trip converges.
    Binding { target: viewer;  property: "headImage"; value: headImageParam.value }
    Binding { target: viewer2; property: "headImage"; value: headImageParam.value }
    Binding { target: viewer;  property: "headScale"; value: headScaleParam.value }
    Binding { target: viewer2; property: "headScale"; value: headScaleParam.value }
    Binding { target: viewer;  property: "headX"; value: headXParam.value }
    Binding { target: viewer2; property: "headX"; value: headXParam.value }
    Binding { target: viewer;  property: "headY"; value: headYParam.value }
    Binding { target: viewer2; property: "headY"; value: headYParam.value }

    Connections {
        target: viewer
        function onHeadScaleChanged() {
            if (headScaleParam.value !== viewer.headScale)
                headScaleParam.value = viewer.headScale
        }
        function onHeadXChanged() {
            if (headXParam.value !== viewer.headX)
                headXParam.value = viewer.headX
        }
        function onHeadYChanged() {
            if (headYParam.value !== viewer.headY)
                headYParam.value = viewer.headY
        }
    }

    Connections {
        target: viewer2
        function onHeadScaleChanged() {
            if (headScaleParam.value !== viewer2.headScale)
                headScaleParam.value = viewer2.headScale
        }
        function onHeadXChanged() {
            if (headXParam.value !== viewer2.headX)
                headXParam.value = viewer2.headX
        }
        function onHeadYChanged() {
            if (headYParam.value !== viewer2.headY)
                headYParam.value = viewer2.headY
        }
    }

    Recorder {
        id: recorder
    }

    // Streams ticked for recording, keyed by "<stream>@<service>" -- the same key the recorder
    // files them under, so status can be looked up by it.
    property var recSelection: ({})
    // Per-stream reconnection policy, same keys. Persistent by default.
    property var recPersistent: ({})

    function streamJsonAt(index) {
        var obj = locator.data(index, ServiceLocator.ControllerRole)
        return (obj && obj.toJson) ? obj.toJson() : null
    }

    function recordKey(json) {
        return json.name + '@' + locator.serviceNameByUuid(json.uid)
    }

    function isSelected(key) {
        return recSelection[key] !== undefined
    }

    function setSelected(json, key, on) {
        // Copy-on-write is not cosmetic here. Mutating the existing object and assigning the
        // same identity back emits no recSelectionChanged signal, so Record.enabled and recycled
        // delegates never learn that the stream was ticked.
        var sel = Object.assign({}, recSelection)
        if (on) {
            // Stored as-is; a persistent stream is re-expressed by service+stream name inside
            // the recorder, so there is nothing to strip here.
            sel[key] = json
        } else {
            delete sel[key]
        }
        recSelection = sel
    }

    /// Keep a ticked stream's stored reference current. It matters for one-time connections,
    /// which are pinned to exactly what was picked: if the producing service restarted since
    /// the tick, the stored reference points at an endpoint that no longer exists. Persistent
    /// streams re-derive themselves by name and do not care.
    function refreshSelected(json, key) {
        if (!json || key === "" || recSelection[key] === undefined) {
            return
        }
        if (JSON.stringify(recSelection[key]) === JSON.stringify(json)) {
            return
        }
        var sel = Object.assign({}, recSelection)
        sel[key] = json
        recSelection = sel
    }

    function isPersistent(key) {
        return recPersistent[key] !== false
    }

    function setPersistent(key, on) {
        var p = Object.assign({}, recPersistent)
        p[key] = on
        recPersistent = p
        if (recorder.isOpen) {
            recorder.setStreamReconnect(key, on)
        }
    }

    function statusFor(key) {
        var list = recorder.streamStatus
        for (var i = 0; i < list.length; ++i) {
            if (list[i].name === key)
                return list[i]
        }
        return null
    }

    function clock(seconds) {
        var mm = Math.floor(seconds / 60)
        var ss = seconds % 60
        return (mm < 10 ? "0" : "") + mm + ":" + (ss < 10 ? "0" : "") + ss
    }

    /// Three digits, MB or GB only. KB is noise at the sizes recorded here, and "1009 KB"
    /// reads smaller than it is.
    function humanSize(bytes) {
        var v = (bytes > 0 ? bytes : 0) / (1024 * 1024)
        var unit = "MB"
        if (v >= 1000) {
            v /= 1024
            unit = "GB"
        }
        var digits = v >= 100 ? 0 : (v >= 10 ? 1 : 2)
        return v.toFixed(digits) + " " + unit
    }

    /// Same rule as humanSize, one unit lower: rates arrive in KB/s, and a fast multichannel
    /// stream reads five digits there.
    function humanRate(kbps) {
        var v = kbps > 0 ? kbps : 0
        var unit = "KB/s"
        if (v >= 1000) {
            v /= 1024
            unit = "MB/s"
        }
        var digits = v >= 100 ? 0 : (v >= 10 ? 1 : 2)
        return v.toFixed(digits) + " " + unit
    }

    Component.onCompleted: {
        console.log("Configurator ready");
        ResonanceApp.setServiceName("Configurator");
        locator.rescan();
        console.log(viewer.source)
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal


        SplitView {
        orientation: Qt.Vertical
        /**
         * ⭐ THE INTENDED PARAMETER-COLUMN WIDTH: 300 px. Contract, not a suggestion.
         *
         * Every service's parameter editors are designed to FIT in this column. A service does
         * not get to be wider because one of its options is wordy -- ParametersView caps its
         * content to the pane and Select elides, so long text goes to the drop-down popup and
         * the tooltip instead of into the column width.
         *
         * The budget at 300 px: 130 px label column (ParametersView.labelColumnWidth) + 6 px
         * spacing + ~46 px of editor chrome = 182 px of overhead, leaving ~118 px of editor text.
         * Written down in docs/build_qt5-to-qt6-transition.md; change both together.
         *
         * minimumWidth is the same 300: the pane may be dragged WIDER for comfort, but never
         * narrower than the width every service was laid out against.
         */
        SplitView.preferredWidth: 300
        SplitView.minimumWidth: 300

        // The stock handle is about four pixels tall with no marking, which is a hard thing to
        // find and an easy thing to miss. Nine pixels and a grip make it look like something you
        // can drag, which is most of the reason to have it.
        handle: Rectangle {
            implicitHeight: 9
            implicitWidth: 9
            color: SplitHandle.pressed ? "#4a90d9"
                 : (SplitHandle.hovered ? "#c8d8ea" : "#e6e6e6")

            Row {
                anchors.centerIn: parent
                spacing: 3
                Repeater {
                    model: 3
                    Rectangle {
                        width: 2
                        height: 2
                        radius: 1
                        color: SplitHandle.pressed ? "#ffffff" : "#8a8a8a"
                    }
                }
            }
        }

        GroupBox {
            title: "Services"
            id: servicesList
            // A preferred height, not a filled one: the list starts at a sensible size, the
            // parameters below take the slack as the window grows, and the divider between them
            // is draggable because neither is pinned. It used to carry fillHeight *and* a
            // maximumHeight, which is a size the operator could not change in either direction.
            SplitView.fillWidth: true
            // Controls 2 otherwise holds this pane at 260 px, leaving much more blank tree than
            // the Qt 5 desktop table and pushing useful parameters below the fold.
            SplitView.preferredHeight: 200
            SplitView.minimumHeight: 80

            ColumnLayout {
                anchors.fill: parent

                RowLayout {
                    Layout.fillWidth: true

                    // Used rarely; the header space is worth more than the word.
                    Button {
                        text: "↻"
                        ToolTip.text: qsTr("Rescan for services")
                        ToolTip.visible: hovered
                        implicitWidth: 24
                        Layout.preferredWidth: 24
                        onClicked: {
                            locator.rescan();
                        }
                    }

                    Button {
                        text: recorder.isOpen ? "Stop" : "Record"
                        enabled: recorder.isOpen || Object.keys(root.recSelection).length > 0
                        onClicked: {
                            if (recorder.isOpen) {
                                recorder.closeFile()
                                return
                            }
                            recorder.openFile(recFileName.text)
                            for (var key in root.recSelection) {
                                recorder.addStream(root.recSelection[key], key,
                                                   root.isPersistent(key))
                            }
                        }
                    }

                    // Before recording this is where the file name goes; during recording the
                    // same spot carries the clock and whether everything picked is still there.
                    TextField {
                        id: recFileName
                        Layout.fillWidth: true
                        text: 'record-$$$$.h5'
                        visible: !recorder.isOpen
                    }

                    // size, then clock, then stream status.
                    Label {
                        visible: recorder.isOpen
                        color: "#34495e"
                        text: recorder.isOpen ? humanSize(recorder.fileSize) : ""
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: recorder.isOpen
                        font.bold: !recorder.allStreamsPresent
                        color: recorder.allStreamsPresent ? "#1e8449" : "#c0392b"
                        text: recorder.isOpen ? (clock(recorder.recordingSeconds) + "  "
                                                 + (recorder.allStreamsPresent ? "all streams present"
                                                                               : "STREAM DROPPED"))
                                              : ""
                    }
                }

                // Qt 6 TreeView obtains both columns from the QAbstractItemModel. Keep the old
                // compact header explicitly so column 1 can remain a purpose-built recording
                // surface instead of pretending to be ordinary model text.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label { text: qsTr("name"); Layout.fillWidth: true; font.bold: true }
                    Label { text: qsTr("rec"); Layout.preferredWidth: 146; font.bold: true }
                }

                TreeView {
                    id: tree
                    objectName: "configuratorServiceTable"
                    model: locator
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    clip: true
                    // Qt 6.11 can recycle a removed stream cell into the following service
                    // without refreshing its name/controller roles when that stream returns.
                    // This compact tree must never reuse a cell that still targets a stream.
                    reuseItems: false
                    boundsBehavior: Flickable.StopAtBounds
                    columnSpacing: 4
                    rowSpacing: 0
                    columnWidthProvider: function(column) {
                        return column === 0 ? Math.max(80, width - 154) : 150
                    }

                    selectionModel: ItemSelectionModel { model: locator }

                    // Stream rows also carry a ControllerRole, but it is a StreamInfo rather than
                    // a ServiceControl -- only the latter can drive the parameters view.
                    function __serviceAt(modelIndex) {
                        var obj = locator.data(modelIndex, ServiceLocator.ControllerRole)
                        return (obj && obj.requestDescription !== undefined) ? obj : null
                    }

                    Keys.onDeletePressed: function(event) {
                        event.accepted = false
                        // Window activation is checked as well as item focus: the table can
                        // retain activeFocus when a different application is foreground.
                        if (!opt_delete_terminates_service.checked || !root.active
                                || !tree.activeFocus || event.isAutoRepeat
                                || event.modifiers !== Qt.NoModifier)
                            return
                        var selected = tree.selectionModel.currentIndex
                        if (!tree.selectionModel.isSelected(selected))
                            return
                        var service = tree.__serviceAt(selected)
                        if (!service)
                            return
                        service.sendTransition("!terminate")
                        event.accepted = true
                    }

                    delegate: Item {
                        id: cell
                        // Qt 5's Desktop TableViewStyle used max(16, font height). Eighteen keeps
                        // that density while leaving one pixel of breathing room above/below the
                        // current Windows font.
                        implicitHeight: 18
                        implicitWidth: column === 0 ? 180 : 150

                        required property TreeView treeView
                        required property bool isTreeNode
                        required property bool expanded
                        required property bool hasChildren
                        required property int depth
                        required property int row
                        required property int column
                        required property bool current
                        // QAbstractItemModel roles. Declaring them required lets Qt 6's
                        // TableView delegate adaptor keep them updated as descriptions arrive;
                        // asking the source model back through a flattened view index rendered
                        // empty cells.
                        required property string name
                        required property var controller

                        readonly property var __index: tree.index(row, column)
                        readonly property var __controller: controller
                        readonly property var __json: (__controller && __controller.toJson)
                                                      ? __controller.toJson() : null
                        readonly property bool __isStream: !!__json
                        readonly property string __key: __json ? recordKey(__json) : ""
                        readonly property bool __currentRow: tree.currentRow === cell.row

                        Component.onCompleted: refreshSelected(__json, __key)

                        Rectangle {
                            anchors.fill: parent
                            // TableView's `current` marks only column zero. The old result looked
                            // like two unrelated half-rows, so highlight the whole logical row.
                            color: cell.__currentRow ? root.palette.highlight
                                                     : (cell.row % 2
                                                        ? root.palette.alternateBase
                                                        : root.palette.base)
                        }

                        Text {
                            id: disclosure
                            z: 3
                            visible: cell.column === 0 && cell.hasChildren
                            x: 4 + cell.depth * 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: cell.expanded ? "▼" : "▶"
                            color: cell.__currentRow ? root.palette.highlightedText : "#555555"

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                onClicked: {
                                    tree.forceActiveFocus(Qt.MouseFocusReason)
                                    tree.selectionModel.setCurrentIndex(
                                                tree.index(cell.row, 0),
                                                ItemSelectionModel.ClearAndSelect)
                                    tree.toggleExpanded(cell.row)
                                }
                            }
                        }

                        Text {
                            id: nameCell
                            visible: cell.column === 0
                            x: 8 + (cell.depth + (cell.hasChildren ? 1 : 0)) * 16
                            width: parent.width - x - 4
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: cell.name
                            color: cell.__currentRow ? root.palette.highlightedText
                                                     : root.palette.text
                        }

                        MouseArea {
                            id: streamMouse
                            anchors.fill: parent
                            visible: cell.column === 0
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            drag.target: cell.__isStream ? dragPayload : null

                            onClicked: function(mouse) {
                                tree.forceActiveFocus(Qt.MouseFocusReason)
                                var idx = tree.index(cell.row, 0)
                                tree.selectionModel.setCurrentIndex(
                                            idx, ItemSelectionModel.ClearAndSelect)
                                // The full-cell handler overlaps the compact disclosure glyph on
                                // some Qt 6 styles. Keep the glyph hit target deterministic even
                                // when that handler receives the click.
                                if (cell.hasChildren
                                        && mouse.x <= disclosure.x + disclosure.width + 5)
                                    tree.toggleExpanded(cell.row)
                                var service = tree.__serviceAt(idx)
                                if (service)
                                    pv.controller = service
                            }

                            onDoubleClicked: function(mouse) {
                                var idx = tree.index(cell.row, 0)
                                var service = tree.__serviceAt(idx)
                                if (service) {
                                    pv.controller = null
                                    pv.controller = service
                                } else if (cell.__controller && cell.__controller.toJson) {
                                    if (mouse.button === Qt.LeftButton)
                                        viewer.source.serialized = {
                                            desiredStream: streamFromCtrlObject(cell.__controller)
                                        }
                                    else if (mouse.button === Qt.RightButton)
                                        viewer2.source.serialized = {
                                            desiredStream: streamFromCtrlObject(cell.__controller)
                                        }
                                }
                            }

                            Item {
                                id: dragPayload
                                parent: tree
                                visible: false
                                Drag.hotSpot.x: 0
                                Drag.hotSpot.y: 0
                                Drag.active: streamMouse.drag.active && cell.__isStream
                                Drag.dragType: Drag.Automatic
                                Drag.supportedActions: Qt.CopyAction
                                Drag.mimeData: cell.__isStream ? {
                                    "url/stream-connection": JSON.stringify(
                                        streamFromCtrlObject(cell.__controller))
                                } : ({})
                            }
                        }

                        Item {
                            anchors.fill: parent
                            visible: cell.column === 1 && cell.__isStream

                            SquareCheckBox {
                                id: recordCheck
                                anchors.left: parent.left
                                anchors.leftMargin: 7
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18
                                height: 16
                                checked: isSelected(cell.__key)
                                enabled: !recorder.isOpen && cell.__key !== ""
                            }

                            // Keep the checkbox a pure view of recSelection. CheckBox writes its
                            // own checked property on click and would otherwise destroy the
                            // binding above; the overlay sends the model operation instead.
                            MouseArea {
                                anchors.fill: recordCheck
                                enabled: recordCheck.enabled
                                onClicked: setSelected(cell.__json, cell.__key,
                                                       !isSelected(cell.__key))
                            }

                            Label {
                                id: reconnectLabel
                                anchors.left: recordCheck.right
                                anchors.leftMargin: 7
                                anchors.verticalCenter: parent.verticalCenter
                                text: isPersistent(cell.__key) ? "keep" : "once"
                                color: cell.__currentRow ? root.palette.highlightedText
                                      : (isPersistent(cell.__key) ? "#1e8449" : "#7f8c8d")
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: setPersistent(cell.__key,
                                                             !isPersistent(cell.__key))
                                }
                            }

                            Label {
                                anchors.left: reconnectLabel.right
                                anchors.leftMargin: 4
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                visible: recorder.isOpen
                                text: {
                                    var s = statusFor(cell.__key)
                                    if (!s) return ""
                                    if (s.state === "incompatible") return "shape!"
                                    if (s.state === "reconnecting") return "reconn."
                                    if (s.state === "dropped") return "dropped"
                                    if (s.state === "waiting") return "wait"
                                    return humanRate(s.rate)
                                }
                                color: {
                                    if (cell.__currentRow)
                                        return root.palette.highlightedText
                                    var s = statusFor(cell.__key)
                                    if (!s) return "#555555"
                                    if (s.state === "dropped" || s.state === "incompatible")
                                        return "#c0392b"
                                    if (s.state !== "recording" || s.rate <= 0)
                                        return "#b9770e"
                                    return "#1e8449"
                                }
                            }
                        }
                    }
                }
            }
        }



        ParametersView {
            id: pv
            // No anchors. Anchoring an item inside a SplitView drives its geometry directly and
            // the split's own sizing never reaches it -- which is exactly why the divider above
            // could not be dragged: it moved, and nothing followed. fillHeight makes this the
            // item that absorbs a change in window height.
            SplitView.fillWidth: true
            SplitView.fillHeight: true
            SplitView.minimumHeight: 120
        }


        }

        SplitView {
        id: viewerSplit
        SplitView.fillWidth: true
        SplitView.fillHeight: true
        // Stacked or side by side. Side by side is what a scalp map wants: the map is square, so
        // stacked it gets a wide strip and wastes most of it, while beside a trace view it fills
        // its half. That pairing -- map on the left, traces on the right -- is the arrangement the
        // standalone impedance tool had.
        orientation: viewerLayout.index === 1 ? Qt.Horizontal : Qt.Vertical
        property real secondaryHeight: 300
        property real secondaryWidth: 450
        function applySecondarySize() {
            var fraction = secondarySizeParam.value / 100
            if (fraction > 0) {
                secondaryWidth = Math.max(160, width * fraction)
                secondaryHeight = Math.max(120, height * fraction)
            }
            sizeSecondary()
        }
        function sizeSecondary() {
            viewer2.SplitView.preferredWidth = viewer2.collapsed ? 150 : secondaryWidth
            viewer2.SplitView.preferredHeight = viewer2.collapsed ? 28 : secondaryHeight
        }
        function setSecondaryCollapsed(collapse) {
            if (collapse === viewer2.collapsed) return
            if (collapse) {
                if (orientation === Qt.Horizontal) secondaryWidth = viewer2.width
                else secondaryHeight = viewer2.height
            }
            viewer2.collapsed = collapse
            sizeSecondary()
        }
        onOrientationChanged: Qt.callLater(sizeSecondary)
        Component.onCompleted: Qt.callLater(applySecondarySize)

            StreamView {
                id: viewer
                title: "Signal viewer"
                // The primary viewer takes the available space. The secondary viewer starts as a
                // minimal strip below it, matching the established 2x1 operating layout, but its
                // divider remains fully draggable.
                SplitView.fillWidth: true
                SplitView.fillHeight: true
                SplitView.minimumWidth: 120
                SplitView.minimumHeight: 80
                parameter_group: "plot"
                parameter_name: "plot1_"
                parameter_label: "Plot 1 "
                // Explicit, and spaced, so the "plot" tab lists viewer 1's stream and settings
                // before viewer 2's instead of in whatever order they happened to register.
                parameter_index: 10
            }

            StreamView {
                id: viewer2
                // A non-filling second pane keeps this initial size while the window grows. Once
                // the operator drags its divider, SplitView preserves that chosen size.
                title: "Signal viewer 2"
                objectName: "secondarySignalViewer"
                collapsible: true
                collapsed: true
                onCollapseRequested: collapse => viewerSplit.setSecondaryCollapsed(collapse)
                SplitView.preferredWidth: 150
                SplitView.preferredHeight: 28
                SplitView.minimumWidth: 120
                SplitView.minimumHeight: collapsed ? 28 : 80
                SplitView.maximumHeight: collapsed && viewerSplit.orientation === Qt.Vertical ? 28 : Infinity
                SplitView.maximumWidth: collapsed && viewerSplit.orientation === Qt.Horizontal ? 150 : Infinity
                parameter_group: "plot"
                parameter_name: "plot2_"
                parameter_label: "Plot 2 "
                parameter_index: 20
            }

        }



    }

}
