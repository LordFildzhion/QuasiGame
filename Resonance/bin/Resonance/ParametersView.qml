// 2.12 for HoverHandler, which reports hover without taking any button or wheel event away
// from the control underneath -- a MouseArea over a parameter editor would.
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Resonance 3.0

GroupBox {
    id: root

    title: "Parameters"
    property var controller: null

    /**
     * Ceiling on the label column, not a fixed width.
     *
     * What has to match across tabs is the *total*: label + control should fill the panel and
     * stop there. That happens on its own -- the layout fills the viewport and the controls
     * carry fillWidth -- as long as no tab's content forces the layout wider than the panel,
     * because then that tab alone overflows and gets clipped. One 46-character label used to
     * do exactly that.
     *
     * So cap the column rather than pin it. A tab of short labels still gets a narrow label
     * column and correspondingly wide controls, which is what makes the main tab readable; a
     * tab with longer ones stops at the cap and wraps instead of eating the control side.
     */
    /**
     * ⭐ The width of the label column, in every tab of every service. PINNED, not capped.
     *
     * Change it here and every panel in the distribution moves together, which is the whole
     * point -- see build_qt5-to-qt6-transition.md section 6a for the 300 px budget this sits in.
     */
    property int labelColumnWidth: 130

    /*
     * Tooltip geometry is no longer a property here. It is taken from this panel directly --
     * ParameterToolTip is given `panel: root` and derives both its width and its x from it, so
     * every row's tooltip is the same width and lands in the same column. It used to be a
     * per-instance ceiling, which let the box shrink to its text and, combined with ToolTip's
     * default centring on its parent, put each row's tooltip at a different x.
     */

    property bool __blockUpdate: false
    property bool __hasStreamParameters: false


    Component {
        id: _paramTabViewComponent

        ScrollView {
            id: sv
            clip: true

            readonly property alias layout: layo
            property var pairs: ({})

            /*
             * Measured from the ScrollView, deliberately NOT from its viewport.
             *
             * ScrollView binds its flickable's contentWidth to this item's width, and the
             * viewport is what is left of the ScrollView after the scroll bars that contentWidth
             * and contentHeight decide to show. Reading viewport.width here therefore closed a
             * cycle -- implicitWidth -> width -> contentWidth/contentHeight -> scroll bars ->
             * viewport.width -- and Qt reported "Binding loop detected for property
             * implicitWidth" from this line on every tab that was built (thirteen times in one
             * session). sv.width is set by the panel above and cannot answer back, so the intent
             * survives with the cycle cut: at least as wide as the visible area, wider only when
             * the layout genuinely needs it.
             *
             * __chrome is the frame padding, a vertical scroll bar and the 3 px margin on each
             * side. It has to be a constant, because every exact measurement of it is downstream
             * of this property. It assumes the vertical bar is present -- which in this panel it
             * nearly always is -- because over-allowing costs a few pixels of unused width on the
             * right, while under-allowing puts a horizontal scroll bar on a tab that fits, and
             * that bar then eats a row of height.
             */
            Item {
                id: scrollContents
                implicitHeight: layo.implicitHeight + 6
                /**
                 * ⭐ The pane's width is the BUDGET, not a suggestion.
                 *
                 * This used to be Math.max(sv.availableWidth, layo.implicitWidth + 6): a control
                 * whose implicit width exceeded the pane pushed the content wider and produced a
                 * horizontal scroll bar inside the panel, so every service ended up with its own
                 * effective width depending on how wordy its longest option happened to be.
                 *
                 * The intended parameter-column width is 300 px and is documented in
                 * R:\docs\build_qt5-to-qt6-transition.md. Every service's parameters fit in it.
                 * Text that does not fit is elided in the row and shown in full in the drop-down
                 * popup or the tooltip -- it does not get to widen the column.
                 */
                implicitWidth: sv.availableWidth
                width: implicitWidth
                height: implicitHeight

                GridLayout {
                    id: layo
                    anchors.fill: parent
                    anchors.margins: 3

                    columns: 2
                }
            }

            background: Rectangle {
                // Labels use the active palette. A hard-coded white canvas makes them white on
                // white when Windows is in dark mode, which looks exactly like missing labels.
                color: sv.palette.base
                border.color: sv.palette.mid
                border.width: 1
            }
        }
    }

    // Controls 1 TabView disappeared in Qt 6. These descriptors preserve the small API the
    // parameter update code needs (title/item/count/getTab/insertTab/removeTab), while the pages
    // themselves are ordinary ScrollViews. Keeping the API local makes the wire and parameter
    // logic unchanged.
    Component {
        id: _tabDescriptorComponent
        QtObject {
            property string title: ""
            property var item: null
            property var sourceComponent: null
            property bool active: true
        }
    }
    Component {
        id: _paramViewComponent

        Loader {
            // Deliberately not "root": that is the ParametersView itself, and shadowing it here
            // means a delegate cannot reach the panel's own properties.
            id: paramControl
            property var label: null
            property var description: null
            property var attributes: null
            property var group: null
            property var name: null
            property var type: null
            property int index: -1
            property int row
            /// Shown with its value, not editable. Distinct from disabled, and since
            /// 2026-09-02 neither one hides anything -- see `paramVisible`.
            property bool readOnly: false

            /**
             * Whether this row exists in the current configuration at all.
             *
             * ⚠ The ONLY thing that removes a row from the panel, and it comes from the service:
             * only the service knows that a bipolar pair list means nothing in unipolar mode.
             *
             * It replaced "Hide disabled options", a client-side switch that was ON by default and
             * erased every DISABLED row -- so a running KARDi2 showed one parameter and its
             * sampling rate disappeared at exactly the moment an operator wanted to read it. Not
             * being changeable is not a reason to be unreadable; disabled rows are greyed now.
             *
             * Defaults true, and an absent key from an older service stays true, so a service that
             * has never heard of it shows everything exactly as before.
             */
            property bool paramVisible: true

            Layout.row: row
            Layout.column: 1

            visible: paramVisible

            property var serialized: null

            source: attributes && attributes.frameDuration === true
                    ? 'FrameDuration.qml' : type.replace(/:/g, '_') + '.qml'

            // ⚠ A read-only row is drawn in its normal colours -- greying it out is what the
            // operator specifically did not want, because a greyed value reads as inapplicable
            // rather than as "this is what the device says". So the control stays enabled and
            // this swallows the interaction instead.
            MouseArea {
                anchors.fill: parent
                enabled: paramControl.readOnly
                visible: enabled
                acceptedButtons: Qt.AllButtons
                onWheel: wheel.accepted = true
                z: 10
            }

            HoverHandler {
                id: controlHover
            }
            ParameterToolTip {
                text: paramControl.description ? paramControl.description : ""
                visible: !!paramControl.description && controlHover.hovered
                panel: root
            }
        }
    }
    Component {
        id: _paramLabelComponent

        Label {
            id: paramLabel
            property var control: null
            text: control.label == null ? "" : control.label
            visible: control.label != null && control.paramVisible
            enabled: control.enabled || control.readOnly
            Layout.row: control.row
            Layout.column: 0
            /**
             * ⭐ PINNED, not capped. Column 0 is exactly labelColumnWidth in every tab of every
             * service, so the editors all begin at the same x and are all the same width. A panel
             * whose geometry shifts as the operator clicks between services reads as broken even
             * when every individual tab is fine on its own.
             *
             * ⚠ This was CAPPED until 2026-09-06, and the objection recorded then still holds:
             * a tab whose labels are all short now carries 130 px of column it does not need, and
             * its controls are correspondingly narrower. That cost is accepted deliberately --
             * uniformity across services was judged worth more than a few wider editors on the
             * tabs that happen to have terse labels.
             *
             * A label wider than the column wraps to a second line rather than eliding: a label
             * nobody can read in full is worse than a row that is two lines tall. 11 of the 276
             * labels in the distribution wrap; none needs a third line.
             */
            Layout.preferredWidth: root.labelColumnWidth
            Layout.minimumWidth: root.labelColumnWidth
            Layout.maximumWidth: root.labelColumnWidth
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            wrapMode: Text.WordWrap

            HoverHandler {
                id: labelHover
            }
            ParameterToolTip {
                text: control.description ? control.description : ""
                visible: !!control.description && labelHover.hovered
                panel: root
            }
        }
    }

    property string stateStr: ""
    property var stateInfo: ({})

    /**
     * The samples a service says it has lost, or -1 when it has not said.
     *
     * Services publish this as the `droppedSamples` key of `stateInfo`
     * (`CommunicationLayer::reportDroppedSamples`). Absent means "this service does not count",
     * which is not the same as zero and must not read as a clean bill of health -- but neither is
     * worth a word on the status line, so both render as nothing.
     */
    readonly property int droppedSamples: {
        if (!stateInfo || typeof stateInfo !== "object")
            return -1
        var value = stateInfo["droppedSamples"]
        // Qt.isQtObject-free type test: a JSON number arrives as a JS number, and anything else
        // -- undefined, null, a string a future service put there by mistake -- is not a count.
        if (typeof value !== "number" || !isFinite(value))
            return -1
        return Math.floor(value)
    }

    /**
     * ⭐ Below this, say nothing.
     *
     * A handful of lost samples is normal on a USB amplifier and is not something to put in front
     * of an operator mid-session -- it trains them to ignore the line, which is exactly what you
     * do not want on the day it says 400 000. 100 is the operator's chosen floor.
     */
    readonly property int droppedSamplesFloor: 100

    /**
     * "running" on its own, or "running, 11231 samples dropped".
     *
     * Deliberately one string in one Text rather than a second element that appears and
     * disappears: a row that changes its child count changes its layout, and this header sits
     * above a 300 px parameter column that must not move.
     */
    readonly property string stateLine: {
        if (droppedSamples < droppedSamplesFloor)
            return stateStr
        return qsTr("%1, %2 samples dropped").arg(stateStr).arg(droppedSamples)
    }
    property var transitionsStr: []

    /**
     * The titles the group selector draws, in tab order.
     *
     * Held here rather than read out of the TabView by the selector's delegates. A Repeater over
     * `tabs.count` would be wrong for the same reason a recycled check box was wrong: inserting a
     * group in the middle changes the count by one, so the Repeater builds one delegate and every
     * delegate after the insertion point keeps the title it was built with while the tab
     * underneath it has shifted. Assigning a fresh array rebuilds all of them, which is the only
     * way this list cannot drift out of step with the tabs.
     */
    property var tabTitles: []

    function __refreshTabTitles() {
        var titles = []
        for (var i = 0; i < tabs.count; ++i)
            titles.push(tabs.getTab(i).title)
        tabTitles = titles
    }

    onControllerChanged: {
        updateTimer.stop()
        updateTimer.updateList = ({})
        __hasStreamParameters = false
        while (tabs.count > 0) {
            removeTab(0)
        }
        __refreshTabTitles()
        transitionsStr = []
        stateStr = ""
        stateInfo = ({})

        if (controller) {
            controller.requestDescription()
        }
    }

    // Independently packaged services can use a core that does not broadcast input loss.
    // Refresh just the displayed service, including while another app has focus. Newer
    // services still deliver their immediate notifications through the same handler.
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && root.Window.window && root.Window.window.visible
                 && root.Window.window.visibility !== Window.Minimized
                 && !!root.controller && root.__hasStreamParameters
        onTriggered: root.controller.requestDescription()
    }

    Timer {
        id: updateTimer
        interval: 150

        property var updateList: ({})

        onTriggered: {
            for (var name in updateList) {
                console.log(name, updateList[name])
                controller.sendParameter(name, updateList[name])
            }
            updateList = {}
        }
    }

    function removeTab(i) {
        var tab = tabs.getTab(i)
        for (var j = tab.item.layout.children.length - 1; j >= 0; --j) {
            tab.item.layout.children[j].destroy()
        }
        tab.sourceComponent = null
        tabs.removeTab(i)
    }

    /**
     * Rebuild the panel from one service description.
     *
     * Split out of `Connections.onDescriptionChanged` so the same code can be driven from a
     * description that did not arrive over the wire. That is not a test backdoor: the handler is
     * the only place the panel's structure is decided -- which groups become tabs, which rows
     * exist, which editor each row loads -- and a test that reimplemented any of it would be
     * testing its own copy. `test_ChannelsListInTabsQml` calls this with a description shaped
     * like the one `nvx136` publishes, which is the only way to reproduce a defect that depends
     * on how many groups a service has.
     */
    function applyDescription(parameters, state, info, transitions) {
        __blockUpdate = true

        // Qt 6 exposes QVariantList properties as a read-only JavaScript sequence. Sorting
        // that sequence in place raises "Cannot insert into a readonly container"; work on
        // a real array because row/group ordering is view-local.
        var params = [...parameters]
        __hasStreamParameters = params.some(function(p) {
            return p.type === "Resonance::Parameters::Stream"
                    || (p.attributes && p.attributes.activeStream !== undefined)
        })
        stateStr = state
        stateInfo = info
        transitionsStr = transitions

        // remove excess parameters and tabs
        var tabnames = []
        var paramnames = []
        for (var i in params) {
            if (tabnames.indexOf(params[i].group) === -1)
                tabnames.push(params[i].group)
            paramnames.push(params[i].name)
        }
        for (var i = 0; i < tabs.count; ++i) {
            if (tabnames.indexOf(tabs.getTab(i).title) == -1) {
                // remove tab
                removeTab(i)
                i--
            } else {
                var pairs = tabs.getTab(i).item.pairs

                var removes = []

                for (var j in pairs) {
                    if (paramnames.indexOf(pairs[j][1].name) == -1) {
                        pairs[j][0].destroy(0)
                        pairs[j][1].destroy(1)
                        removes.push(j)
                    }
                }
                removes.map(function (name) {
                    delete pairs[name]
                })
                tabs.getTab(i).item.pairs = pairs
            }
        }

        //console.log(JSON.stringify(params))

        // Tab order follows the service, not the alphabet: groups are ordered by the
        // lowest parameter index in each. A driver that wants "main" before "hardware"
        // before "trigger" says so by numbering its parameters in bands, which is the
        // same mechanism that already orders the rows inside a tab. Sorting titles
        // alphabetically put "adc" in front of "default" and there was no way to say
        // otherwise.
        function groupOrder(sortedParams) {
            var order = []
            for (var i in sortedParams) {
                var g = sortedParams[i].group
                if (order.indexOf(g) === -1)
                    order.push(g)
            }
            return order
        }

        function addTab(name, order) {
            for (var i = 0; i < tabs.count; ++i) {
                if (tabs.getTab(i).title == name)
                    return tabs.getTab(i)
            }

            // Insert ahead of the first existing tab that the service ranks after us.
            var rank = order.indexOf(name)
            var at = tabs.count
            for (var j = 0; j < tabs.count; ++j) {
                var otherRank = order.indexOf(tabs.getTab(j).title)
                if (otherRank > rank) {
                    at = j
                    break
                }
            }

            var tab = tabs.insertTab(at, name, _paramTabViewComponent)
            tab.active = true // force tab to load the component
            return tab
        }

        function updateParam(tab, p) {
            var label, control
            if (!(p.name in tab.item.pairs)) {
                control = _paramViewComponent.createObject(tab.item.layout,
                                                           {
                                                               "label": p.label,
                                                               "description": p.description,
                                                               "attributes": p.attributes,
                                                               "enabled": p.enabled,
                                                               "readOnly": !!p.readOnly,
                                                               // ⚠ `!== false`, not
                                                               // `!!` -- an older service
                                                               // omits the key entirely and
                                                               // must stay VISIBLE.
                                                               "paramVisible":
                                                                   p.visible !== false,
                                                               "group": p.group,
                                                               "name": p.name,
                                                               "type": p.type,
                                                               "index": p.index,
                                                               "serialized": p.serialized,
                                                               "row": p.row
                                                           })
                label = _paramLabelComponent.createObject(tab.item.layout, {
                                                              "control": control
                                                          })

                control.onSerializedChanged.connect(function () {
                    if (!root.__blockUpdate) {
                        if (controller) {
                            updateTimer.updateList[control.name] = control.serialized
                            updateTimer.restart()
                        }
                    }
                })

                control.Layout.fillWidth = true
                // ⚠ Without this a control's IMPLICIT width is its floor in the grid,
                // and fillWidth only ever grows it. That is what let one wordy
                // ComboBox set the width of a whole service's panel. Zero lets every
                // editor shrink to the budget and elide instead.
                control.Layout.minimumWidth = 0

                //label.control = control;
                tab.item.pairs[p.name] = [label, control]
            } else {
                label = tab.item.pairs[p.name][0]
                control = tab.item.pairs[p.name][1]
            }
            control.attributes = p.attributes
            control.description = p.description
            control.enabled = p.enabled
            control.readOnly = !!p.readOnly
            // Absent means visible: never let a missing key hide a row.
            control.paramVisible = p.visible !== false
            // A status refresh must not reset an unchanged editor or replace a local edit
            // waiting in the send debounce with the service's preceding value.
            if (!(p.name in updateTimer.updateList)
                    && JSON.stringify(control.serialized) !== JSON.stringify(p.serialized))
                control.serialized = p.serialized
            control.row = p.row
            // or maybe expand options here?
            // attributes
            // group
            // enabled *
            // label
            // name
            // type
            // serialized *
        }

        // By sort index, unindexed ones first as before -- and equal indices by name, so that
        // the panel of one service reads the same in every instance and after every restart.
        // Without the tie-break the order among equals was whatever order the service had
        // registered them in, which differs between two Configurators (2026-09-07).
        params.sort(function (a, b) {
            var ai = a.index || 0
            var bi = b.index || 0
            if (ai && bi && ai !== bi)
                return ai - bi
            if (ai && !bi)
                return 1
            if (!ai && bi)
                return -1
            return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)
        })

        params.map(function (param, row) {
            param.row = row
        })

        var hadNoTabs = tabs.count === 0
        var order = groupOrder(params)
        for (var i in params) {
            var p = params[i]
            var tab = addTab(p.group, order)
            updateParam(tab, p)
        }

        // A service always opens on its first tab. Only when the tabs were just built --
        // otherwise every description re-broadcast (which happens on any parameter
        // change) would yank the operator back out of whatever tab they were using.
        if (hadNoTabs && tabs.count > 0)
            tabs.currentIndex = 0

        // After the add and remove passes, never between them: the selector must never be
        // built against a half-updated tab set.
        __refreshTabTitles()

        __blockUpdate = false
    }

    Connections {
        target: controller
        function onDescriptionChanged() {
            root.applyDescription(controller.parameters, controller.state,
                                  controller.stateInfo, controller.transitions)
        }
    }


    /**
     * Open @p dialog where content of @p kind lives.
     *
     * ⚠ Assigned here rather than bound on the FileDialog, and that is not a style choice.
     * `ResonanceApp.startFolder()` moves as the operator uses dialogs, and it is a plain
     * invokable with no change signal, so a `folder:` binding would be evaluated once at
     * creation and then never again -- the session memory would be written and never read.
     * Re-asking immediately before every open() is what makes "remember the last folder" work,
     * and it is also what makes Save and Load agree: both are kind `params`, so whichever ran
     * last decides where the next one opens.
     */
    function __openIn(dialog, kind) {
        dialog.currentFolder = ResonanceApp.startFolderUrl(kind)
        dialog.open()
    }

    FileDialog {
        id: saveFileDialog
        fileMode: FileDialog.SaveFile
        nameFilters: ["Text files (*.json)", "All files (*)"]
        onAccepted: {
            applyNotice.clear()
            ResonanceApp.rememberFolder('params', saveFileDialog.selectedFile)
            var result = ResonanceApp.saveParameterFile(
                        saveFileDialog.selectedFile.toString(), controller.parameters)
            if (!result.ok) {
                applyNotice.showFailure(qsTr("Save failed - %1").arg(result.error))
            }
        }
    }

    FileDialog {
        id: recordFileDialog
        fileMode: FileDialog.SaveFile
        nameFilters: ["HDF files (*.hdf)", "All files (*)"]
        onAccepted: {
            ResonanceApp.rememberFolder('data', recordFileDialog.selectedFile)
            if (controller) {
                // ⚠ ResonanceApp.localPath(), not `.replace(/^file:\/{3}/, '')`. That was the
                // inbound half of the same defect `startFolderUrl` fixes on the way out: a `#`
                // in a folder name ends a QUrl string at the fragment and everything after it
                // is silently dropped, and percent-encoding is left in the path for the file
                // system to choke on.
                controller.sendTransition(
                            '!recordToFile=' + ResonanceApp.localPath(
                                recordFileDialog.selectedFile.toString()))
            }
        }
    }

    FileDialog {
        id: openFileDialog
        fileMode: FileDialog.OpenFile
        nameFilters: ["Text files (*.json)", "All files (*)"]
        onAccepted: {
            ResonanceApp.rememberFolder('params', openFileDialog.selectedFile)
            applyNotice.clear()

            // Drop any edit still sitting in the 150 ms debounce. A file supersedes it, and more
            // to the point the service reports refusals for the LAST set it was sent -- so an
            // edit landing after the load would replace the load's account with its own and the
            // banner would report the wrong apply.
            updateTimer.stop()
            updateTimer.updateList = ({})

            var result = ResonanceApp.loadParameterFile(openFileDialog.selectedFile.toString())
            if (!result.ok) {
                applyNotice.showFailure(qsTr("Load failed - %1").arg(result.error))
                return
            }

            controller.sendParameters(result.parameters)
            // The service names every entry it refused and why, in its description. Read
            // that back rather than guessing from the values: see __missingNames below.
            __sentParameters = result.parameters
            applyCheckTimer.restart()
        }
    }

    property var __sentParameters: []

    /**
     * Fallback for a service too old to report refusals: names it does not have at all.
     *
     * ⚠ Deliberately NOT the old check, which compared the text we sent against the text read
     * back and counted every difference as a rejection. A parameter is free to normalise what it
     * is given -- a Stream fills in the stream name a `discover://` URL implies -- and a service
     * may write one of its own parameters (nvx136 refreshes `battery` every 10 s on real
     * hardware) inside the same window. Both made the old check fire with nothing wrong, which
     * is the most likely source of the "wrong parameters" warning reported from the lab, and
     * being intermittent by construction is why it could not be reproduced on demand. The C++
     * side abandoned the same test for the same reason (parameterapply.cpp).
     *
     * A missing NAME cannot false-positive that way. A value the service refused is invisible to
     * this check, so the banner says so rather than implying the rest went in.
     */
    function __missingNames(sent, current) {
        var known = ({})
        for (var i in current) {
            known[current[i].name] = true
        }

        var missing = []
        for (var j in sent) {
            var entry = sent[j]
            if (!entry || entry.name === undefined)
                continue
            if (!known[entry.name])
                missing.push(entry.name)
        }
        return missing
    }

    Timer {
        id: applyCheckTimer
        // Long enough for the service to apply and re-broadcast its description (which it
        // debounces by 30 ms), short enough to still feel like a response to the load.
        interval: 700
        repeat: false
        onTriggered: {
            if (controller) {
                if (controller.parameterRefusalsSupported) {
                    applyNotice.showRefusals(controller.parameterRefusals)
                } else {
                    applyNotice.showMissingNames(__missingNames(__sentParameters,
                                                                controller.parameters))
                }
            }
            __sentParameters = []
        }
    }

    ColumnLayout {

        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true
            // Like the transition Flow below, this header consumes the dock width it is given;
            // its implicit width must never become a request to move the viewer divider.
            Layout.preferredWidth: 0
            spacing: 5

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                text: root.stateLine
                enabled: !!root.controller
                elide: Text.ElideRight
                // Only the annotated form is coloured. A plain state name is not a warning, and
                // painting it red would make the normal case look like the abnormal one.
                color: root.droppedSamples >= root.droppedSamplesFloor ? "#b00020" : root.palette.text
                ToolTip.text: qsTr("%1 samples lost since acquisition started, as counted by the device's own sample counter.").arg(root.droppedSamples)
                ToolTip.visible: stateHover.hovered
                        && root.droppedSamples >= root.droppedSamplesFloor
                HoverHandler { id: stateHover }
            }

            Button {
                id: systemButton
                Layout.preferredWidth: 100
                Layout.preferredHeight: 25
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                text: qsTr("System")
                visible: !!root.controller
                onClicked: systemMenu.open()

                Menu {
                    id: systemMenu
                    y: parent.height

                    MenuItem {
                        text: qsTr("Record to auto file")
                        onTriggered: {
                            if (root.controller) {
                                root.controller.sendTransition('!recordToFile=')
                            }
                        }
                    }
                    MenuItem {
                        text: qsTr("Record to file")
                        onTriggered: root.__openIn(recordFileDialog, 'data')
                    }
                    MenuItem {
                        text: qsTr("Stop recording")
                        onTriggered: {
                            if (root.controller) {
                                root.controller.sendTransition('!stopRecording')
                            }
                        }
                    }

                    // Every service in the tree is a windowed (WIN32) binary, so its qDebug() and
                    // qWarning() output has nowhere to go until a console is attached -- and the
                    // moment one is wanted is never a moment when relaunching the service with
                    // --console is acceptable, because relaunching destroys the state being
                    // investigated.
                    //
                    // It belongs here rather than in the application's own menu bar because this
                    // is where the framework's other service-scoped verbs already live
                    // (!recordToFile=, !stopRecording, !terminate) and because this menu is inside
                    // the panel that is already showing one service: no label has to name which
                    // service it means, and it cannot re-target under the operator when the tree
                    // selection moves.
                    MenuItem {
                        // One item that changes what it says, rather than two of which one is
                        // always wrong: the state is read back from the service's own description,
                        // so it is still right when the console was opened from somewhere else --
                        // --console at launch, or the service's own window.
                        text: (root.controller && root.controller.consoleVisible) ? qsTr("Hide console")
                                                                                  : qsTr("Show console")
                        // Greyed out against a service built before the verbs existed, rather than
                        // offering an action that would silently do nothing.
                        enabled: !!root.controller && root.controller.consoleControl
                        onTriggered: {
                            if (root.controller) {
                                root.controller.sendTransition(root.controller.consoleVisible ? '!hideConsole'
                                                                                              : '!showConsole')
                            }
                        }
                    }

                    // Terminate is the one entry here that cannot be undone -- on an amplifier it
                    // wedges the device until it is physically replugged (known-issues §14f) --
                    // and it now sits directly under an item an operator will use often. Keep it
                    // separated.
                    MenuSeparator { }

                    MenuItem {
                        text: qsTr("Terminate")

                        onTriggered: {
                            if (root.controller) {
                                root.controller.sendTransition('!terminate')
                            }
                        }
                    }
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            // Transition buttons are service state, not a request to resize the containing dock.
            // In particular NVX exposes rescan + start after Stop; a RowLayout's implicit width
            // used to widen the entire left SplitView and draw across the viewer. System now has
            // its own invariant place at the right edge of the status line; Flow wraps only the
            // changing service actions below it.
            Layout.preferredWidth: 0
            Layout.preferredHeight: childrenRect.height
            spacing: 5

            Repeater {
                model: root.transitionsStr

                Button {
                    width: Math.max(70, implicitWidth)
                    height: 25
                    text: modelData
                    onClicked: {
                        if (root.controller) {
                            root.controller.sendTransition(modelData)
                        }
                    }
                }
            }

        }

        RowLayout {
            Button {
                text: qsTr("Save")
                enabled: !!controller
                onClicked: root.__openIn(saveFileDialog, 'params')
            }

            Button {
                text: qsTr("Load")
                enabled: !!controller

                onClicked: root.__openIn(openFileDialog, 'params')
            }
        }

        /**
         * What the last Load did not apply, named, with the service's own reason for each.
         *
         * Sits right under Load, where the eye already is after choosing a file. Deliberately not
         * a dialog, so it never blocks the next action -- and deliberately NOT self-clearing on a
         * timer any more: a list of refused parameters that erases itself after eight seconds is
         * the same silent failure it exists to prevent. It clears on the next Load, or on a
         * click.
         */
        Rectangle {
            id: applyNotice

            /// One line per refusal, already written by the service.
            property var lines: []
            /// Counts the damage. Empty when the whole message is the lines themselves.
            property string header: ""
            /// A qualifier under the list, when the check itself was partial.
            property string note: ""
            /// Refusals past what is drawn, so a 137-entry file cannot fill the panel.
            property int overflow: 0

            // Enough to name a real misconfiguration, few enough that the banner cannot squeeze
            // the parameter tabs off the panel. The overflow line points at the service console,
            // which has the whole list.
            readonly property int maxLines: 8

            Layout.fillWidth: true
            visible: lines.length > 0
            implicitHeight: visible ? noticeColumn.implicitHeight + 8 : 0
            color: "#fdecea"
            border.color: "#c0392b"
            border.width: 1
            radius: 3

            function clear() {
                lines = []
                header = ""
                note = ""
                overflow = 0
            }

            function __setLines(text) {
                lines = text.slice(0, maxLines)
                overflow = Math.max(0, text.length - maxLines)
                var total = lines.length + overflow
                header = total === 1 ? qsTr("Load: 1 parameter was not applied")
                                     : qsTr("Load: %1 parameters were not applied").arg(total)
            }

            /// A Load that never got as far as sending anything. One line, no count.
            function showFailure(text) {
                clear()
                lines = [text]
            }

            /// The service's own account. Each entry carries a ready-to-display `sentence`.
            function showRefusals(refusals) {
                clear()
                if (!refusals || refusals.length === 0)
                    return

                var out = []
                for (var i = 0; i < refusals.length; ++i) {
                    var r = refusals[i]
                    if (r && r.sentence)
                        out.push(r.sentence)
                    else if (r && r.name)
                        out.push(qsTr("%1 NOT APPLIED").arg(r.name))
                }
                __setLines(out)
            }

            /// Against a service that does not report refusals, only unknown names can be
            /// checked -- say that, rather than let an empty list read as a clean load.
            function showMissingNames(names) {
                clear()
                if (!names || names.length === 0)
                    return

                var out = []
                for (var i = 0; i < names.length; ++i) {
                    out.push(qsTr("%1 NOT APPLIED - this service has no parameter by that name").arg(
                                 names[i]))
                }
                __setLines(out)
                note = qsTr("This service does not report refused values; only unknown names were checked.")
            }

            Column {
                id: noticeColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    color: "#7b241c"
                    font.bold: true
                    visible: applyNotice.header !== ""
                    text: applyNotice.header
                }

                Repeater {
                    model: applyNotice.lines

                    Text {
                        width: noticeColumn.width
                        color: "#7b241c"
                        wrapMode: Text.WordWrap
                        text: modelData
                    }
                }

                Text {
                    width: parent.width
                    color: "#7b241c"
                    visible: applyNotice.overflow > 0
                    text: qsTr("and %1 more - see the service console for the full list").arg(
                              applyNotice.overflow)
                }

                Text {
                    width: parent.width
                    color: "#7b241c"
                    wrapMode: Text.WordWrap
                    visible: applyNotice.note !== ""
                    text: applyNotice.note
                }

                Text {
                    width: parent.width
                    color: "#a04d44"
                    text: qsTr("Click to dismiss.")
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: applyNotice.clear()
            }
        }

        // "Hide disabled options" stood here until 2026-09-02. It was ON by default and hid
        // every DISABLED row, which meant a service that greys its settings while running -- KARDi2
        // greys five of its six, actiChamp all of them -- showed the operator an almost empty panel
        // and took the sampling rate away exactly when it needed reading. Greyed is enough; what a
        // row does NOT apply at all is now the service's own statement, through the parameter's
        // `visible` attribute.

        /*
         * The group selector, in place of the TabView's own tab bar.
         *
         * A Controls 1 tab bar divides the panel between its tabs rather than sizing each one to
         * its title -- both the Base and the Desktop style cap a tab at availableWidth/count. The
         * parameter dock is 300 px wide by default and 220 px at its minimum, so a service with
         * twelve groups got twenty-four pixels per tab and every title elided to nothing. Twelve
         * unlabelled tabs is not a tab bar, and there is no width the operator can drag to that
         * makes it one.
         *
         * A Flow wraps instead of dividing: each button is as wide as its own title, so every
         * group is readable at any pane width and stays one click away. The cost is a row of
         * height per three or four groups, and only for a service that has that many -- with two
         * or three groups this is a single row, the same as the bar it replaces.
         */
        Flow {
            Layout.fillWidth: true
            // A Flow that has not been given a width yet lays every button out on one line, and
            // that line's width would otherwise become the panel's preferred width -- a twelve
            // group service would ask for a dock several hundred pixels wider than it needs.
            // Contribute nothing and take the width the column has.
            Layout.preferredWidth: 0
            spacing: 3
            visible: tabs.count > 0
            enabled: tabs.enabled

            Repeater {
                model: root.tabTitles

                Rectangle {
                    id: groupButton

                    property bool current: tabs.currentIndex === index

                    width: groupLabel.implicitWidth + 12
                    height: groupLabel.implicitHeight + 6
                    radius: 2
                    // The same three colours the split handles use, so a selector and a handle
                    // do not read as two different kinds of control.
                    color: current ? "#4a90d9"
                                   : (groupMouse.containsMouse ? "#c8d8ea" : "#e6e6e6")
                    border.color: current ? "#3a72ad" : "#c0c0c0"
                    opacity: enabled ? 1.0 : 0.5

                    Text {
                        id: groupLabel
                        anchors.centerIn: parent
                        text: modelData
                        color: groupButton.current ? "#ffffff" : "#202020"
                    }

                    MouseArea {
                        id: groupMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: tabs.currentIndex = index
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true

            id: tabs

            enabled: !!controller
            clip: true

            property var tabItems: []
            readonly property int count: tabItems.length
            property int currentIndex: -1

            function getTab(index) {
                return (index >= 0 && index < tabItems.length) ? tabItems[index] : null
            }

            function __syncPages() {
                for (var i = 0; i < tabItems.length; ++i)
                    tabItems[i].item.visible = (i === currentIndex)
            }

            function insertTab(at, title, component) {
                var page = component.createObject(tabs)
                if (!page)
                    throw new Error("Could not create parameter page " + title)
                page.anchors.fill = tabs

                var tab = _tabDescriptorComponent.createObject(tabs, {
                    "title": title,
                    "item": page,
                    "sourceComponent": component,
                    "active": true
                })
                var list = tabItems.slice()
                list.splice(at, 0, tab)
                tabItems = list

                if (currentIndex < 0)
                    currentIndex = 0
                else if (at <= currentIndex)
                    currentIndex += 1
                __syncPages()
                return tab
            }

            function removeTab(at) {
                if (at < 0 || at >= tabItems.length)
                    return
                var list = tabItems.slice()
                var tab = list.splice(at, 1)[0]
                tabItems = list
                if (tab.item)
                    tab.item.destroy()
                tab.destroy()

                if (tabItems.length === 0)
                    currentIndex = -1
                else if (currentIndex >= tabItems.length)
                    currentIndex = tabItems.length - 1
                __syncPages()
            }

            onCurrentIndexChanged: __syncPages()
        }
    }
}
