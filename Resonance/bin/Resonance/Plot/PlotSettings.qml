import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Resonance 3.0

/**
 * Everything that is set once and then left alone: the filter chain, the reference, and the
 * per-group amplitude scales.
 *
 * Groups are the answer to one stream carrying three kinds of signal. An NVX stream has EEG at
 * microvolts, AUX at volts and a raw integer trigger; a single amplitude scale can show exactly
 * one of them. Set the scale per group once and all three are readable at the same time.
 *
 * ## Why every row is its own RowLayout
 *
 * The obvious way to lay this out is a GridLayout per section with a pinned first column. It does
 * not work. A GridLayout negotiates column widths across *all* of its children, and an item with
 * `Layout.columnSpan: 2` contributes to both columns' size requests -- so a single full-width row
 * (a long checkbox label, a wrapped warning) widens column 0, no matter what `Layout.maximumWidth`
 * the other cells in that column carry. Sections with such a row therefore settled on a different
 * column width from sections without one, and the value boxes drifted apart between sections.
 *
 * So there is no shared grid. Every row is an independent RowLayout whose first item is pinned to
 * exactly `labelColumnWidth` (minimum == maximum, not merely preferred) and whose second fills the
 * rest. Nothing negotiates with anything, and full-width rows are simply rows with one child.
 * Within the value column, `NumberField` puts its slack at the *end*, so the entry box, the unit
 * and the steppers sit at fixed offsets from the left of that column rather than from its right
 * edge.
 */
Pane {
    id: root

    property var plot: null
    property var settings: null
    property var channelModel: plot ? plot.channelModel : null

    property var groups: []

    /// One width for the caption column, everywhere in the panel.
    readonly property int labelColumnWidth: 78
    readonly property int columnGap: 5
    /// One set of field metrics, for the same reason.
    readonly property int valueFieldWidth: 66
    readonly property int valueSuffixWidth: 20
    readonly property int rowHeight: 20

    padding: 5
    font.pixelSize: 11

    // A group's own values feed the controls that edit them, so refreshing the model while
    // someone is typing destroys the delegate they are typing into. Deferred until the field
    // gives up focus.
    property int editingFields: 0
    property bool refreshPending: false

    function noteEditing(on) {
        editingFields = Math.max(0, editingFields + (on ? 1 : -1))
        if (editingFields === 0 && refreshPending) {
            refreshPending = false
            refreshGroups()
        }
    }

    function refreshGroups() {
        if (editingFields > 0) {
            refreshPending = true
            return
        }
        groups = channelModel ? channelModel.groupList() : []
    }

    /// Displayed unit of the channels that carry a scalp position, so the head thresholds are
    /// labelled with what they are actually compared against.
    property string headUnit: ""

    function refreshHeadUnit() {
        headUnit = ""
        if (!plot || !channelModel)
            return
        // The first channel that has a position; on an impedance stream they all share a unit.
        var all = plot.headValues(0.1)
        for (var i = 0; i < all.length; ++i) {
            if (all[i].hasPosition) {
                headUnit = all[i].unit
                return
            }
        }
    }

    Component.onCompleted: {
        refreshGroups()
        refreshHeadUnit()
    }

    Connections {
        target: root.channelModel
        function onGroupsChanged() { root.refreshGroups(); root.refreshHeadUnit() }
        function onScalesChanged() { root.refreshGroups() }
        function onCountChanged() { root.refreshHeadUnit() }
    }

    // --- row primitives ---------------------------------------------------------------------

    component SectionBox: GroupBox {
        padding: 5
        topPadding: 17
        Layout.fillWidth: true
        label: Label { text: parent.title; font.pixelSize: 11; font.bold: true }
    }

    /// A caption + control pair. The only row shape in the panel.
    component FormRow: RowLayout {
        Layout.fillWidth: true
        spacing: root.columnGap
    }

    /// Caption column, as text. Pinned, never merely preferred.
    component RowLabel: Label {
        Layout.minimumWidth: root.labelColumnWidth
        Layout.maximumWidth: root.labelColumnWidth
        Layout.preferredWidth: root.labelColumnWidth
        Layout.alignment: Qt.AlignVCenter
        elide: Text.ElideRight
        font.pixelSize: 11
    }

    /// Caption column, as a checkbox. Same pinning.
    component RowCheck: CompactCheckBox {
        Layout.minimumWidth: root.labelColumnWidth
        Layout.maximumWidth: root.labelColumnWidth
        Layout.preferredWidth: root.labelColumnWidth
    }

    /// Value column, as a number.
    component ValueField: NumberField {
        Layout.fillWidth: true
        Layout.minimumWidth: 1
        fieldWidth: root.valueFieldWidth
        suffixWidth: root.valueSuffixWidth
    }

    /// Value column, as a drop-down. Must be free to shrink: the Default style's implicit width
    /// is wide enough to push a row out on its own.
    component ValueCombo: ComboBox {
        id: combo
        Layout.fillWidth: true
        Layout.minimumWidth: 1
        topPadding: 2
        bottomPadding: 2
        font.pixelSize: 11
        background: Rectangle {
            implicitHeight: 22
            radius: 2
            color: combo.enabled ? "#fdfdfd" : "#f0f0f0"
            border.color: combo.activeFocus ? "#4a90d9" : "#a0a0a0"
        }
    }

    /// Value column, as free text. For the two epoching fields that are hex or a list, where a
    /// spinner would be the wrong shape entirely.
    component ValueText: TextField {
        Layout.fillWidth: true
        Layout.minimumWidth: 1
        topPadding: 2
        bottomPadding: 2
        implicitHeight: root.rowHeight
        font.pixelSize: 11
        selectByMouse: true
    }

    /// A row with no caption: one full-width control. No spanning, because there is no grid.
    component WideCheck: CompactCheckBox {
        Layout.fillWidth: true
        Layout.minimumWidth: 1
    }

    component WideNote: Label {
        Layout.fillWidth: true
        Layout.minimumWidth: 1
        wrapMode: Text.WordWrap
        font.pixelSize: 10
        opacity: 0.7
    }

    /**
     * Nine greys, white to black in even steps of 32. A short ladder rather than a colour picker:
     * what a background has to do is give the marks contrast, and the only axis that matters for
     * that is how light it is.
     */
    readonly property var shadeList: ["#ffffff", "#e0e0e0", "#c0c0c0", "#a0a0a0", "#808080",
                                      "#606060", "#404040", "#202020", "#000000"]

    component ShadeRow: RowLayout {
        id: shadeRow
        property color current: "#000000"
        signal picked(color shade)

        Layout.fillWidth: true
        Layout.minimumWidth: 1
        spacing: 4

        Repeater {
            model: root.shadeList

            Rectangle {
                required property var modelData
                Layout.preferredWidth: 16
                Layout.preferredHeight: root.rowHeight - 2
                radius: 2
                color: modelData
                border.width: Qt.colorEqual(modelData, shadeRow.current) ? 2 : 1
                border.color: Qt.colorEqual(modelData, shadeRow.current) ? "#4a90d9" : "#9a9a9a"

                MouseArea {
                    anchors.fill: parent
                    onClicked: shadeRow.picked(parent.modelData)
                }
            }
        }

        Item { Layout.fillWidth: true; Layout.minimumWidth: 1 }
    }

    // Anchored, and it has to be. A Controls 2 Pane sizes an internal wrapper to its available
    // area and leaves the children inside that wrapper at their implicit size, so a Layout that
    // is not anchored collapses to its content and Layout.fillHeight has nothing to distribute.
    ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: root.availableWidth
            spacing: 5

            // --- filters ------------------------------------------------------------------
            SectionBox {
                title: "Filters"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    WideNote {
                        visible: text !== ""
                        text: root.plot ? root.plot.filterError : ""
                        color: "#c0392b"
                        opacity: 1
                        font.pixelSize: 11
                    }

                    FormRow {
                        RowCheck {
                            id: hpEnabled
                            text: "Highpass"
                            checked: root.settings.filter_highpass_enabled
                            onToggled: root.settings.filter_highpass_enabled = checked
                        }
                        ValueField {
                            enabled: hpEnabled.checked
                            value: root.settings.filter_highpass
                            minimumValue: 0.01
                            maximumValue: 10000
                            decimals: 2
                            stepSize: 0.5
                            suffix: "Hz"
                            onEdited: root.settings.filter_highpass = value
                        }
                    }

                    FormRow {
                        RowCheck {
                            id: lpEnabled
                            text: "Lowpass"
                            checked: root.settings.filter_lowpass_enabled
                            onToggled: root.settings.filter_lowpass_enabled = checked
                        }
                        ValueField {
                            enabled: lpEnabled.checked
                            value: root.settings.filter_lowpass
                            minimumValue: 0.1
                            maximumValue: 100000
                            decimals: 1
                            stepSize: 5
                            suffix: "Hz"
                            onEdited: root.settings.filter_lowpass = value
                        }
                    }

                    FormRow {
                        RowCheck {
                            id: notchEnabled
                            text: "Notch"
                            checked: root.settings.filter_notch_enabled
                            onToggled: root.settings.filter_notch_enabled = checked
                        }
                        ValueField {
                            enabled: notchEnabled.checked
                            value: root.settings.filter_notch
                            minimumValue: 1
                            maximumValue: 10000
                            decimals: 1
                            stepSize: 10
                            suffix: "Hz"
                            onEdited: root.settings.filter_notch = value
                        }
                    }

                    FormRow {
                        RowLabel { text: "Notch width"; enabled: notchEnabled.checked }
                        ValueField {
                            enabled: notchEnabled.checked
                            value: root.settings.filter_notchWidth
                            minimumValue: 0.1
                            maximumValue: 100
                            decimals: 2
                            stepSize: 0.5
                            suffix: "Hz"
                            onEdited: root.settings.filter_notchWidth = value
                        }
                    }

                    FormRow {
                        RowLabel { text: "Harmonics"; enabled: notchEnabled.checked }
                        ValueField {
                            enabled: notchEnabled.checked
                            value: root.settings.filter_notchHarmonics
                            minimumValue: 1
                            maximumValue: 5
                            decimals: 0
                            stepSize: 1
                            onEdited: root.settings.filter_notchHarmonics = value
                            ToolTip.visible: hovered
                            ToolTip.text: "Also notch 2x and 3x the mains frequency. Hum on EMG "
                                          + "is rarely only at the fundamental."
                        }
                    }

                    FormRow {
                        RowLabel { text: "Type" }
                        ValueCombo {
                            model: ["Butterworth", "Chebyshev II"]
                            currentIndex: root.settings.filter_type
                            onActivated: root.settings.filter_type = index
                        }
                    }

                    FormRow {
                        RowLabel { text: "Order" }
                        ValueField {
                            value: root.settings.filter_order
                            minimumValue: 1
                            maximumValue: root.plot ? root.plot.maxFilterOrder : 16
                            decimals: 0
                            stepSize: 1
                            onEdited: root.settings.filter_order = value
                        }
                    }

                    WideNote {
                        visible: root.settings.filter_order > 8
                        color: "#b8860b"
                        opacity: 1
                        text: "Orders above 8 get numerically delicate at low corners."
                    }
                }
            }

            // --- scales per group -----------------------------------------------------------
            SectionBox {
                title: "Scales per group"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 5

                    Repeater {
                        model: root.groups

                        ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 1

                            // Header: what the group is, what it is measured in, whether the
                            // filter chain applies to it.
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Rectangle {
                                    width: 9; height: 9; radius: 4.5
                                    color: modelData.color
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                Label { text: modelData.name; font.bold: true }
                                Label {
                                    text: modelData.members
                                    font.pixelSize: 10
                                    opacity: 0.6
                                }
                                Item { Layout.fillWidth: true; Layout.minimumWidth: 1 }

                                TextField {
                                    id: unitField
                                    Layout.preferredWidth: 40
                                    implicitHeight: 19
                                    padding: 2
                                    leftPadding: 4
                                    font.pixelSize: 11
                                    text: modelData.unit
                                    placeholderText: "unit"
                                    selectByMouse: true
                                    background: Rectangle {
                                        radius: 2
                                        color: "#ffffff"
                                        border.width: 1
                                        border.color: unitField.activeFocus ? "#4a90d9" : "#a8a8a8"
                                    }
                                    onActiveFocusChanged: root.noteEditing(activeFocus)
                                    onEditingFinished: root.channelModel.setGroupUnit(
                                                           modelData.name, text)
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Base unit only -- V, Ohm. The prefix (n, u, m, "
                                                  + "k) follows the scale automatically."
                                }

                                CompactCheckBox {
                                    text: "Filter"
                                    boxSize: 11
                                    checked: modelData.filtered
                                    onToggled: root.channelModel.setGroupFiltered(modelData.name,
                                                                                  checked)
                                }
                            }

                            // Value row: the panel's standard shape. The mode button and the sign
                            // share the caption column, with the sign pushed to its right edge so
                            // it sits against the number it belongs to instead of stranded left.
                            FormRow {
                                Item {
                                    Layout.minimumWidth: root.labelColumnWidth
                                    Layout.maximumWidth: root.labelColumnWidth
                                    Layout.preferredWidth: root.labelColumnWidth
                                    Layout.preferredHeight: root.rowHeight

                                    CompactButton {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 48
                                        height: root.rowHeight
                                        checkable: true
                                        checked: modelData.scaleMode === ChannelModel.AutoScale
                                        text: checked ? "Auto" : "Fixed"
                                        ToolTip.visible: hovered
                                        ToolTip.text: checked
                                            ? "Tracking the data. Click to freeze it here."
                                            : "Fixed at the value shown. Click to track."
                                        onClicked: root.channelModel.setGroupScaleMode(
                                                       modelData.name,
                                                       checked ? ChannelModel.AutoScale
                                                               : ChannelModel.ManualScale)
                                    }

                                    // Not a label: it says which way the lane runs and switches
                                    // it. A quantity that cannot go negative -- an impedance, a
                                    // rectified envelope -- spends half a symmetric lane on a
                                    // region it never visits, at half the resolution it could
                                    // have.
                                    CompactButton {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 20
                                        height: root.rowHeight
                                        text: modelData.unipolar ? "+" : "±"
                                        opacity: modelData.scaleMode === ChannelModel.AutoScale
                                                 ? 0.45 : 1
                                        ToolTip.visible: hovered
                                        ToolTip.text: modelData.unipolar
                                            ? "Lane runs 0 to the value, zero at the bottom. "
                                              + "Click for ± about the centre."
                                            : "Lane runs ± the value about its centre. Click for "
                                              + "0 upwards, which suits anything that cannot go "
                                              + "negative."
                                        onClicked: root.channelModel.setGroupUnipolar(
                                                       modelData.name, !modelData.unipolar)
                                    }
                                }

                                ValueField {
                                    enabled: modelData.scaleMode !== ChannelModel.AutoScale
                                    // 1-2-5 stepping, so one control spans microvolts to volts.
                                    logSteps: true
                                    value: modelData.displayRange
                                    minimumValue: 0.001
                                    maximumValue: 999999
                                    decimals: 2
                                    suffix: modelData.displayUnit
                                    onEditingChanged: root.noteEditing(editing)
                                    onEdited: root.channelModel.setGroupRange(
                                                  modelData.name,
                                                  value * Math.pow(10, modelData.unitExponent))
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Enter or click away to apply. The arrows step "
                                                  + "1-2-5 and carry the prefix with them; typing "
                                                  + "5000 in mV gives 5 V."
                                }
                            }
                        }
                    }

                    WideNote {
                        visible: root.groups.length <= 1
                        text: "Groups come from the stream's metadata, or from channel names. "
                              + "Select channels and use Group to make your own."
                    }
                }
            }

            // --- reference ----------------------------------------------------------------
            SectionBox {
                title: "Reference"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    FormRow {
                        RowLabel { text: "Mode" }
                        ValueCombo {
                            model: ["None", "Single channel", "Common average",
                                    "Average per group"]
                            currentIndex: root.settings.reference_mode
                            onActivated: root.settings.reference_mode = index
                        }
                    }

                    FormRow {
                        visible: root.settings.reference_mode === 1
                        RowLabel { text: "Channel" }
                        ValueField {
                            value: root.settings.reference_channel
                            minimumValue: 0
                            maximumValue: 9999
                            decimals: 0
                            stepSize: 1
                            onEdited: root.settings.reference_channel = value
                        }
                    }

                    WideNote {
                        text: "Averages skip bad channels, triggers and bypassed channels."
                    }
                }
            }

            // --- ⭐ epoching ---------------------------------------------------------------
            // Cutting epochs out of THIS continuous stream. One section, because there is no room
            // for a third toolbar row: the sweep's toolbar is already one full row of ten buttons
            // and the epoch view's two rows are hard-cleared by the epoch list's top margin.
            SectionBox {
                title: "Epoching"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    WideCheck {
                        text: "Cut epochs from this stream"
                        checked: root.settings.epoch_cut_enabled
                        onToggled: root.settings.epoch_cut_enabled = checked
                    }

                    WideNote {
                        text: "The epoch view opens beside the sweep and shows what is cut."
                    }

                    FormRow {
                        RowLabel { text: "Trigger ch" }
                        ValueField {
                            value: root.settings.epoch_cut_trigger_channel
                            minimumValue: 0
                            maximumValue: 9999
                            decimals: 0
                            stepSize: 1
                            onEdited: root.settings.epoch_cut_trigger_channel = value
                        }
                    }

                    WideNote {
                        text: {
                            var resolved = root.plot ? root.plot.cutTriggerChannelResolved : -1
                            if (resolved < 0)
                                return "0 takes the last channel. No stream connected."
                            return "0 takes the last channel. Currently channel "
                                 + (resolved + 1) + "."
                        }
                    }

                    FormRow {
                        RowLabel { text: "Read as" }
                        ValueCombo {
                            model: ["Bit of a trigger word", "Level crossing"]
                            currentIndex: root.settings.epoch_cut_trigger_mode
                            onActivated: root.settings.epoch_cut_trigger_mode = index
                        }
                    }

                    FormRow {
                        visible: root.settings.epoch_cut_trigger_mode === 0
                        RowLabel { text: "Bit" }
                        ValueField {
                            value: root.settings.epoch_cut_trigger_bit
                            minimumValue: 0
                            maximumValue: 31
                            decimals: 0
                            stepSize: 1
                            onEdited: root.settings.epoch_cut_trigger_bit = value
                        }
                    }

                    FormRow {
                        visible: root.settings.epoch_cut_trigger_mode === 1
                        RowLabel { text: "Level" }
                        ValueField {
                            value: root.settings.epoch_cut_trigger_level
                            minimumValue: -1e9
                            maximumValue: 1e9
                            decimals: 3
                            stepSize: 0.1
                            onEdited: root.settings.epoch_cut_trigger_level = value
                        }
                    }

                    FormRow {
                        RowLabel { text: "Edge" }
                        ValueCombo {
                            model: ["Rising", "Falling", "Either"]
                            currentIndex: root.settings.epoch_cut_trigger_edge
                            onActivated: root.settings.epoch_cut_trigger_edge = index
                        }
                    }

                    FormRow {
                        RowLabel { text: "From" }
                        ValueField {
                            value: root.settings.epoch_cut_pre_ms
                            suffix: "ms"
                            minimumValue: -100000
                            maximumValue: 100000
                            decimals: 1
                            stepSize: 10
                            onEdited: root.settings.epoch_cut_pre_ms = value
                        }
                    }

                    FormRow {
                        RowLabel { text: "To" }
                        ValueField {
                            value: root.settings.epoch_cut_post_ms
                            suffix: "ms"
                            minimumValue: -100000
                            maximumValue: 100000
                            decimals: 1
                            stepSize: 10
                            onEdited: root.settings.epoch_cut_post_ms = value
                        }
                    }

                    WideNote {
                        text: {
                            if (!root.plot)
                                return ""
                            if (root.plot.cutProblem !== "")
                                return "⚠ " + root.plot.cutProblem
                            if (root.plot.cutSamples <= 0)
                                return "Negative before the trigger, positive after."
                            return "Negative before the trigger, positive after. "
                                 + root.plot.cutSamples + " samples, t=0 at sample "
                                 + root.plot.cutZeroSample + "."
                        }
                    }

                    FormRow {
                        RowLabel { text: "Refractory" }
                        ValueField {
                            value: root.settings.epoch_cut_refractory_ms
                            suffix: "ms"
                            minimumValue: 0
                            maximumValue: 100000
                            decimals: 1
                            stepSize: 10
                            onEdited: root.settings.epoch_cut_refractory_ms = value
                        }
                    }

                    FormRow {
                        RowLabel { text: "Code mask" }
                        ValueText {
                            text: root.settings.epoch_cut_code_mask
                            onEditingFinished: root.settings.epoch_cut_code_mask = text
                        }
                    }

                    FormRow {
                        RowLabel { text: "Accept" }
                        ValueText {
                            text: root.settings.epoch_cut_codes
                            placeholderText: "all codes"
                            onEditingFinished: root.settings.epoch_cut_codes = text
                        }
                    }

                    WideNote {
                        text: "Codes are the trigger word AND the mask. Leave Accept empty to take "
                              + "every code; otherwise list them, comma separated."
                    }

                    FormRow {
                        RowLabel { text: "Continuity" }
                        ValueCombo {
                            model: ["Block timestamps", "Sample order (padded gaps)"]
                            currentIndex: root.settings.epoch_cut_use_block_timestamps ? 0 : 1
                            onActivated: root.settings.epoch_cut_use_block_timestamps = index === 0
                        }
                    }
                    WideNote {
                        text: "Use sample order only when the source preserves every sample position "
                              + "and pads losses with missing values (NVX). This ignores PC delivery jitter. "
                              + "Epochs crossing missing rows are still refused."
                    }

                    // --- the stamp ---------------------------------------------------------
                    FormRow {
                        RowLabel { text: "Block time" }
                        ValueCombo {
                            model: ["names the last sample", "names the first sample",
                                    "names the trigger", "unknown"]
                            currentIndex: root.settings.epoch_cut_stamp
                            onActivated: root.settings.epoch_cut_stamp = index
                        }
                    }

                    WideNote {
                        text: "A continuous stream does not say which sample its block timestamp "
                              + "refers to. Amplifier drivers stamp the last sample; the signal "
                              + "generator stamps the first. This does not move the epochs; it "
                              + "sets the time each epoch is stamped with and matched to markers "
                              + "by."
                    }

                    FormRow {
                        RowLabel { text: "Late marker" }
                        ValueField {
                            value: root.settings.epoch_cut_marker_allowance_ms
                            suffix: "ms"
                            minimumValue: 0
                            maximumValue: 10000
                            decimals: 1
                            stepSize: 10
                            onEdited: root.settings.epoch_cut_marker_allowance_ms = value
                        }
                    }

                    WideNote {
                        text: "How long after a trigger a condition label may still arrive and "
                              + "claim its epoch. 0 takes the newest label at or before the "
                              + "trigger."
                    }

                    WideNote {
                        visible: root.plot ? root.plot.cutStatus !== "" : false
                        text: root.plot ? root.plot.cutStatus : ""
                        opacity: 0.9
                    }
                }
            }

            // --- head map -----------------------------------------------------------------
            SectionBox {
                title: "Head map"
                visible: root.plot ? root.plot.hasHeadLayout : false

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    WideCheck {
                        text: "Show the scalp map instead of traces"
                        checked: root.settings.head_mode
                        onToggled: root.settings.head_mode = checked
                    }

                    WideNote {
                        text: "Thresholds are in the channel's own displayed units"
                              + (root.headUnit !== "" ? " (" + root.headUnit + ")." : ".")
                              + " A value at or below each level takes that colour."
                    }

                    FormRow {
                        RowLabel { text: "Good ≤" }
                        ValueField {
                            value: root.settings.head_good
                            minimumValue: 0
                            maximumValue: 999999
                            decimals: 1
                            stepSize: 1
                            suffix: root.headUnit
                            onEditingChanged: root.noteEditing(editing)
                            onEdited: root.settings.head_good = value
                        }
                    }

                    FormRow {
                        RowLabel { text: "Fair ≤" }
                        ValueField {
                            value: root.settings.head_fair
                            minimumValue: 0
                            maximumValue: 999999
                            decimals: 1
                            stepSize: 1
                            suffix: root.headUnit
                            onEditingChanged: root.noteEditing(editing)
                            onEdited: root.settings.head_fair = value
                        }
                    }

                    FormRow {
                        RowLabel { text: "Poor ≤" }
                        ValueField {
                            value: root.settings.head_poor
                            minimumValue: 0
                            maximumValue: 999999
                            decimals: 1
                            stepSize: 1
                            suffix: root.headUnit
                            onEditingChanged: root.noteEditing(editing)
                            onEdited: root.settings.head_poor = value
                        }
                    }

                    FormRow {
                        RowLabel { text: "Average" }
                        ValueField {
                            value: root.settings.head_average_seconds
                            minimumValue: 0.05
                            maximumValue: 60
                            decimals: 2
                            stepSize: 0.25
                            suffix: "s"
                            onEdited: root.settings.head_average_seconds = value
                            ToolTip.visible: hovered
                            ToolTip.text: "The device reports a fresh impedance a few times a "
                                          + "second and consecutive readings differ by a kilohm "
                                          + "or two; averaging is what makes the number sit still."
                        }
                    }

                    FormRow {
                        RowLabel { text: "Disc size" }
                        ValueField {
                            value: root.settings.head_disc * 100
                            minimumValue: 0
                            maximumValue: 25
                            decimals: 1
                            stepSize: 0.5
                            suffix: "%"
                            onEditingChanged: root.noteEditing(editing)
                            onEdited: root.settings.head_disc = value / 100
                            ToolTip.visible: hovered
                            ToolTip.text: "0 sizes the discs from the montage, which is usually "
                                          + "right — a 128-electrode cap needs smaller discs than "
                                          + "a 12-electrode one."
                        }
                    }

                    WideCheck {
                        text: "Electrode names"
                        checked: root.settings.head_show_names
                        onToggled: root.settings.head_show_names = checked
                    }

                    FormRow {
                        RowLabel { text: "Background" }
                        ShadeRow {
                            current: root.settings.head_background
                            onPicked: root.settings.head_background = shade
                        }
                    }
                    // --- electrode spread ------------------------------------------------
                    FormRow {
                        RowLabel { text: "Spread" }
                        ValueField {
                            value: root.settings.head_scale
                            minimumValue: 0.05
                            maximumValue: 4
                            decimals: 4
                            stepSize: 0.005
                            onEditingChanged: root.noteEditing(editing)
                            onEdited: root.settings.head_scale = value
                            ToolTip.visible: hovered
                            ToolTip.text: root.settings.head_image !== ""
                                ? "How far the electrodes spread across the picture. 1.0 puts the "
                                  + "ear-level circle across the whole picture; a topomap whose "
                                  + "head fills two thirds of its image wants about 0.66. Adjust "
                                  + "until the electrodes sit on the ones in the picture."
                                : "Zoom on the montage."
                        }
                    }

                    WideNote {
                        visible: root.settings.head_image !== ""
                        text: "The same number is in the Configurator as \"head electrode "
                              + "spread\", shared by both viewers along with the picture."
                    }

                    WideCheck {
                        visible: root.settings.head_image !== ""
                        text: "Alignment circle over the picture"
                        checked: root.settings.head_outline
                        onToggled: root.settings.head_outline = checked
                        ToolTip.visible: hovered
                        ToolTip.text: "Draws the ear-level circle on top, to set the spread "
                                      + "against. Off the rest of the time — the picture already "
                                      + "has a head in it."
                    }

                    FormRow {
                        visible: root.settings.head_image !== ""
                        RowLabel { text: "Picture" }
                        ValueField {
                            value: Math.round(root.settings.head_image_opacity * 100)
                            minimumValue: 0
                            maximumValue: 100
                            decimals: 0
                            stepSize: 10
                            suffix: "%"
                            onEdited: root.settings.head_image_opacity = value / 100
                        }
                    }

                    FormRow {
                        visible: root.settings.head_image !== ""
                        RowLabel { text: "Head x" }
                        ValueField {
                            value: root.settings.head_image_cx
                            minimumValue: 0
                            maximumValue: 1
                            decimals: 4
                            stepSize: 0.005
                            onEditingChanged: root.noteEditing(editing)
                            onEdited: root.settings.head_image_cx = value
                            ToolTip.visible: hovered
                            ToolTip.text: "Where the head sits within the picture, as a fraction "
                                          + "of its size. Only needed for a picture whose head is "
                                          + "off-centre."
                        }
                    }

                    FormRow {
                        visible: root.settings.head_image !== ""
                        RowLabel { text: "Head y" }
                        ValueField {
                            value: root.settings.head_image_cy
                            minimumValue: 0
                            maximumValue: 1
                            decimals: 4
                            stepSize: 0.005
                            onEditingChanged: root.noteEditing(editing)
                            onEdited: root.settings.head_image_cy = value
                        }
                    }
                }
            }

            // --- display ------------------------------------------------------------------
            SectionBox {
                title: "Display"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    FormRow {
                        RowLabel { text: "Time range" }
                        ValueField {
                            value: root.settings.axis_time_max
                            minimumValue: 0.05
                            maximumValue: 3600
                            decimals: 2
                            stepSize: 0.5
                            suffix: "s"
                            onEdited: root.settings.axis_time_max = value
                        }
                    }

                    FormRow {
                        RowLabel { text: "Rows/screen" }
                        ValueField {
                            value: root.settings.rows_per_page
                            minimumValue: 0
                            maximumValue: 512
                            decimals: 0
                            stepSize: 1
                            onEdited: root.settings.rows_per_page = value
                            ToolTip.visible: hovered
                            ToolTip.text: "0 fits every row on screen at once"
                        }
                    }

                    FormRow {
                        RowLabel { text: "Line width" }
                        ValueField {
                            value: root.settings.lineWidth
                            minimumValue: 0.5
                            maximumValue: 6
                            decimals: 1
                            stepSize: 0.5
                            onEdited: root.settings.lineWidth = value
                        }
                    }

                    // ⭐ CED-based electrode colours, as a MODE beside the existing palette rather
                    // than in place of it. The note below it is the visible half of the fallback:
                    // an unplaced channel keeps the colour it had, which is indistinguishable from
                    // "the setting did nothing" unless the counts are read back.
                    FormRow {
                        RowLabel { text: "Trace colour" }
                        ValueCombo {
                            model: ["Channel palette", "Scalp position"]
                            currentIndex: root.settings.trace_color_mode === "scalp" ? 1 : 0
                            onActivated: root.settings.trace_color_mode =
                                             (index === 1 ? "scalp" : "palette")
                            ToolTip.visible: hovered
                            ToolTip.text: "Colours EEG electrodes by position: hue around the "
                                          + "head, saturation from the vertex out. Matches the "
                                          + "MATLAB prune UI."
                        }
                    }

                    // Nothing placed: the picture is identical to palette mode, so the panel has
                    // to say why rather than leave the operator to guess the setting was ignored.
                    WideNote {
                        visible: root.settings.trace_color_mode === "scalp"
                                 && root.channelModel !== null
                                 && root.channelModel.scalpColorCount === 0
                        color: "#c0392b"
                        opacity: 1
                        text: root.channelModel && root.channelModel.scalpCandidateCount === 0
                              ? "No EEG channels on this stream. Every trace keeps its palette "
                                + "colour."
                              : "No montage on this stream. Every trace keeps its palette colour."
                    }

                    WideNote {
                        visible: root.settings.trace_color_mode === "scalp"
                                 && root.channelModel !== null
                                 && root.channelModel.scalpColorCount > 0
                        text: root.channelModel
                              ? (root.channelModel.scalpColorCount
                                 < root.channelModel.scalpCandidateCount
                                 ? root.channelModel.scalpColorCount + " of "
                                   + root.channelModel.scalpCandidateCount
                                   + " EEG channels have a position; the rest keep their palette "
                                   + "colour."
                                 : root.channelModel.scalpColorCount
                                   + " EEG channels coloured by position.")
                              : ""
                    }

                    FormRow {
                        RowLabel { text: "Background" }
                        ShadeRow {
                            current: root.settings.background
                            onPicked: root.settings.background = shade
                        }
                    }

                    WideCheck {
                        text: "Scale bar"
                        checked: root.settings.scale_bar
                        onToggled: root.settings.scale_bar = checked
                        ToolTip.visible: hovered
                        ToolTip.text: "A reference length in the corner — 10 uV, 1 mV — to compare "
                                      + "deflections against. Rounded to a value people quote, "
                                      + "with the bar's height following."
                    }

                    WideCheck {
                        text: "Antialias traces"
                        checked: root.settings.antialias
                        onToggled: root.settings.antialias = checked
                        ToolTip.visible: hovered
                        ToolTip.text: "Ignored below a 24 px lane, where it costs 4x and shows "
                                      + "nothing"
                    }
                    WideCheck {
                        text: "Grid"
                        checked: root.settings.grid_visible
                        onToggled: root.settings.grid_visible = checked
                    }
                    WideCheck {
                        text: "Zero line"
                        checked: root.settings.grid_middleLine_visible
                        onToggled: root.settings.grid_middleLine_visible = checked
                    }
                    WideCheck {
                        text: "Only trigger bits that change"
                        checked: root.settings.hide_constant_bits
                        onToggled: root.settings.hide_constant_bits = checked
                    }
                }
            }

            // --- baseline -----------------------------------------------------------------
            SectionBox {
                title: "Baseline"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    FormRow {
                        RowLabel { text: "Window" }
                        ValueField {
                            id: baselineWindow
                            value: 1
                            minimumValue: 0.01
                            maximumValue: 60
                            decimals: 2
                            stepSize: 0.25
                            suffix: "s"
                        }
                    }

                    FormRow {
                        Item {
                            Layout.minimumWidth: root.labelColumnWidth
                            Layout.maximumWidth: root.labelColumnWidth
                            Layout.preferredWidth: root.labelColumnWidth
                            Layout.preferredHeight: 1
                        }
                        CompactButton {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 1
                            text: "Centre"
                            implicitHeight: root.rowHeight
                            ToolTip.visible: hovered
                            ToolTip.text: "Shift each channel so its own mean over the last "
                                          + "window sits on its lane centre"
                            onClicked: root.plot.baselineChannels(baselineWindow.value)
                        }
                        CompactButton {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 1
                            text: "Reset"
                            implicitHeight: root.rowHeight
                            onClicked: root.plot.resetBaselines()
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
