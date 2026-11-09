import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Resonance 3.0

/**
 * The channel list, and everything that acts on a set of channels at once.
 *
 * Selection and visibility are deliberately two different things. Ticking a box shows or hides
 * one channel; selecting rows -- click, ctrl+click, shift+click for a range, Ctrl+A for all --
 * picks the set that the buttons act on. Setting the colour of forty channels is one range select
 * and one click, instead of forty visits to a settings dialog.
 *
 * Space toggles the tick on every selected channel, matching how channel selection already works
 * in the NVX configuration dialogs.
 */
Pane {
    id: root

    property var channelModel: null
    property var plot: null

    padding: 4
    font.pixelSize: 11

    /// The established gesture: select rows, press Space, their ticks flip together.
    function toggleSelectedVisibility() {
        if (!channelModel || channelModel.selectedCount === 0)
            return false
        // Flip as a block, using the first selected channel to decide the direction, so a mixed
        // selection resolves to one state instead of scattering.
        var sel = channelModel.selectedChannels()
        var first = channelModel.data(channelModel.index(sel[0], 0), ChannelModel.VisibleRole)
        channelModel.setSelectionVisible(!first)
        return true
    }

    /**
     * Actions are dispatched by name.
     *
     * They used to be function values carried in the Repeater's model. A JS object handed to a
     * Repeater is converted to a QVariantMap, and that conversion silently drops function
     * properties -- so every button rendered correctly and did nothing.
     */
    function act(id) {
        var m = root.channelModel
        if (!m)
            return
        switch (id) {
        case "all":      m.selectAll(); break
        case "none":     m.clearSelection(); break
        case "invert":   m.invertSelection(); break
        case "show":     m.setSelectionVisible(true); break
        case "hide":     m.setSelectionVisible(false); break
        case "solo":     m.soloSelection(); break
        case "showAll":  m.showAll(); break
        case "bad":      m.setSelectionBad(true); break
        case "good":     m.setSelectionBad(false); break
        case "nofilter": m.setSelectionFilterBypass(true); break
        case "filter":   m.setSelectionFilterBypass(false); break
        }
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Space && root.toggleSelectedVisibility()) {
            event.accepted = true
        } else if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
            root.act("all")
            event.accepted = true
        }
    }

    Keys.onPressed: root.handleKey(event)

    // Anchored, and it has to be: a Controls 2 Pane sizes an internal wrapper to its available
    // area but leaves the children inside it at their implicit size, so an unanchored Layout
    // collapses to its content and the list gets no height at all.
    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 3

            TextField {
                id: search
                Layout.fillWidth: true
                // A Layout will not take an item below its implicit width unless told it may,
                // and the Default TextField background is 200 px wide. Without this the panel
                // silently overflows instead of shrinking.
                Layout.minimumWidth: 60
                implicitHeight: 20
                padding: 2
                leftPadding: 4
                font.pixelSize: 11
                placeholderText: "Filter (AUX, Trig, Fz)"
                selectByMouse: true
                background: Rectangle {
                    radius: 2
                    color: "#ffffff"
                    border.width: 1
                    border.color: search.activeFocus ? "#4a90d9" : "#a8a8a8"
                }
                onTextEdited: {
                    if (text.length > 0)
                        root.channelModel.selectMatching(text)
                    else
                        root.channelModel.clearSelection()
                }
            }
            Label {
                text: root.channelModel ? (root.channelModel.selectedCount + "/"
                                           + root.channelModel.count) : "0/0"
                opacity: 0.7
            }
        }

        // --- appearance of the selection ---------------------------------------------------
        RowLayout {
            id: colourRow
            Layout.fillWidth: true
            spacing: 3

            // In scalp mode the derived colour outranks a per-channel override for every channel
            // the montage PLACED -- but not for the ones it did not, which are exactly the
            // channels an operator still needs to be able to recolour. So the swatches stay live
            // and the caption says where the placed ones get their colour from instead. Nothing
            // is lost either way: an override set here is stored and reappears on the way out of
            // the mode.
            readonly property bool scalpMode:
                root.channelModel !== null && root.channelModel.traceColorMode === "scalp"

            Label {
                text: colourRow.scalpMode ? "Colour (EEG: from position)" : "Colour"
                ToolTip.visible: hoverHandler.hovered && colourRow.scalpMode
                ToolTip.text: "Trace colour is set to Scalp position. These apply to channels "
                              + "without one, and to every channel once the mode is off."
                HoverHandler { id: hoverHandler }
            }

            Repeater {
                model: root.channelModel ? root.channelModel.palette() : []

                Rectangle {
                    required property var modelData
                    width: 15
                    height: 15
                    radius: 2
                    color: modelData
                    border.width: swatchArea.containsMouse ? 2 : 1
                    border.color: swatchArea.containsMouse ? "black" : "#909090"

                    MouseArea {
                        id: swatchArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.channelModel.setSelectionColor(parent.color)
                    }
                }
            }

            CompactButton {
                text: "Auto"
                implicitHeight: 18
                ToolTip.visible: hovered
                ToolTip.text: "Back to the group's colour"
                onClicked: root.channelModel.clearSelectionColor()
            }

            Item { Layout.fillWidth: true }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 4
            rowSpacing: 2

            Label { text: "Width" }
            ComboBox {
                id: widthCombo
                Layout.fillWidth: true
                Layout.minimumWidth: 70
                topPadding: 2
                bottomPadding: 2
                font.pixelSize: 11
                focusPolicy: Qt.NoFocus
                background: Rectangle {
                    implicitHeight: 22
                    radius: 2
                    color: widthCombo.enabled ? "#fdfdfd" : "#f0f0f0"
                    border.color: widthCombo.activeFocus ? "#4a90d9" : "#a0a0a0"
                }
                model: ["Auto", "1", "2", "3", "4"]
                onActivated: root.channelModel.setSelectionLineWidth(
                                 currentIndex === 0 ? 0 : parseFloat(currentText))
            }

            Label { text: "Draw" }
            ComboBox {
                id: drawCombo
                Layout.fillWidth: true
                Layout.minimumWidth: 70
                topPadding: 2
                bottomPadding: 2
                font.pixelSize: 11
                focusPolicy: Qt.NoFocus
                background: Rectangle {
                    implicitHeight: 22
                    radius: 2
                    color: drawCombo.enabled ? "#fdfdfd" : "#f0f0f0"
                    border.color: drawCombo.activeFocus ? "#4a90d9" : "#a0a0a0"
                }
                textRole: "text"
                model: [
                    { text: "Line", value: ChannelModel.Line },
                    { text: "Step (hold)", value: ChannelModel.Step },
                    { text: "Bits (one per bit)", value: ChannelModel.Bits }
                ]
                onActivated: root.channelModel.setSelectionRenderMode(model[currentIndex].value)
            }

            Label { text: "Scale" }
            ComboBox {
                id: scaleCombo
                Layout.fillWidth: true
                Layout.minimumWidth: 70
                topPadding: 2
                bottomPadding: 2
                font.pixelSize: 11
                focusPolicy: Qt.NoFocus
                background: Rectangle {
                    implicitHeight: 22
                    radius: 2
                    color: scaleCombo.enabled ? "#fdfdfd" : "#f0f0f0"
                    border.color: scaleCombo.activeFocus ? "#4a90d9" : "#a0a0a0"
                }
                textRole: "text"
                model: [
                    { text: "Follow group", value: ChannelModel.GroupScale },
                    { text: "Auto (this channel)", value: ChannelModel.AutoScale }
                ]
                onActivated: root.channelModel.setSelectionScaleMode(model[currentIndex].value)
                ToolTip.visible: hovered
                ToolTip.text: "Per-channel autoscale overrides the group's fixed scale. "
                              + "Follow group hands it back."
            }

            Label { text: "Group" }
            ComboBox {
                id: groupCombo
                Layout.fillWidth: true
                Layout.minimumWidth: 70
                topPadding: 2
                bottomPadding: 2
                font.pixelSize: 11
                editable: true
                background: Rectangle {
                    implicitHeight: 22
                    radius: 2
                    color: "#fdfdfd"
                    border.color: groupCombo.activeFocus ? "#4a90d9" : "#a0a0a0"
                }
                model: root.channelModel ? root.channelModel.groupNames : []
                onAccepted: root.channelModel.setSelectionGroup(editText)
                onActivated: root.channelModel.setSelectionGroup(textAt(index))
            }
        }

        // --- actions, grouped by what they do, immediately above the list they act on -------
        Component {
            id: actionButton
            CompactButton {
                property string actionId: ""
                implicitHeight: 18
                onClicked: root.act(actionId)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 2
            Label { text: "Select"; opacity: 0.65; Layout.preferredWidth: 38 }
            Loader { sourceComponent: actionButton
                     onLoaded: { item.text = "All"; item.actionId = "all" } }
            Loader { sourceComponent: actionButton
                     onLoaded: { item.text = "None"; item.actionId = "none" } }
            Loader { sourceComponent: actionButton
                     onLoaded: { item.text = "Invert"; item.actionId = "invert" } }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 2
            Label { text: "Show"; opacity: 0.65; Layout.preferredWidth: 38 }
            Loader { sourceComponent: actionButton
                     onLoaded: { item.text = "Show"; item.actionId = "show" } }
            Loader { sourceComponent: actionButton
                     onLoaded: { item.text = "Hide"; item.actionId = "hide" } }
            Loader { sourceComponent: actionButton
                     onLoaded: { item.text = "Solo"; item.actionId = "solo" } }
            Loader { sourceComponent: actionButton
                     onLoaded: { item.text = "All"; item.actionId = "showAll" } }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 2
            Label { text: "Flag"; opacity: 0.65; Layout.preferredWidth: 38 }
            Loader { sourceComponent: actionButton
                     onLoaded: { item.text = "Bad"; item.actionId = "bad" } }
            Loader { sourceComponent: actionButton
                     onLoaded: { item.text = "Good"; item.actionId = "good" } }
            Loader { sourceComponent: actionButton
                     onLoaded: { item.text = "No filter"; item.actionId = "nofilter" } }
            Loader { sourceComponent: actionButton
                     onLoaded: { item.text = "Filter"; item.actionId = "filter" } }
            Item { Layout.fillWidth: true }
        }

        // --- the list ------------------------------------------------------------------------
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            focus: true
            model: root.channelModel
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Keys.onPressed: root.handleKey(event)

            delegate: Rectangle {
                id: row
                width: list.width
                height: 18
                color: model.selected ? Qt.rgba(0.30, 0.50, 0.75, 0.35) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 1
                    anchors.rightMargin: 2
                    spacing: 3

                    CompactCheckBox {
                        checked: model.visible
                        boxSize: 11
                        focusPolicy: Qt.NoFocus
                        // Visibility is per channel and independent of the selection, so a
                        // tick here never disturbs the set the buttons act on.
                        onToggled: model.visible = checked
                    }

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: model.effectiveColor
                        opacity: model.bad ? 0.35 : 1
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Label {
                        Layout.fillWidth: true
                        text: model.name
                        elide: Text.ElideRight
                        font.pixelSize: 11
                        font.strikeout: model.bad
                        opacity: model.visible ? 1 : 0.45
                    }

                    Label {
                        text: model.autoScaled ? "auto" : ""
                        font.pixelSize: 9
                        opacity: 0.65
                    }

                    Label {
                        text: model.group
                        font.pixelSize: 9
                        opacity: 0.6
                    }

                    Label {
                        text: "⌀"
                        font.pixelSize: 10
                        visible: model.filterBypass
                        opacity: 0.7
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.leftMargin: 16 // leave the checkbox its own hit area
                    acceptedButtons: Qt.LeftButton

                    onClicked: {
                        list.forceActiveFocus()
                        if (mouse.modifiers & Qt.ShiftModifier)
                            root.channelModel.selectRange(index)
                        else if (mouse.modifiers & Qt.ControlModifier)
                            root.channelModel.toggleSelection(index)
                        else
                            root.channelModel.selectOnly(index)
                    }

                    onDoubleClicked: {
                        root.channelModel.selectOnly(index)
                        root.channelModel.soloSelection()
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            text: "Click · Shift+click range · Ctrl+click add · Ctrl+A all · "
                  + "Space toggles ticks · Double-click solo"
            wrapMode: Text.WordWrap
            font.pixelSize: 9
            opacity: 0.6
        }
    }
}
