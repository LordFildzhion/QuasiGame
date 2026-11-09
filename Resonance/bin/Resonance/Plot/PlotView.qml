import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Resonance 3.0
import Resonance.Plot 3.0

/**
 * The signal viewer.
 *
 * Layout is one row per drawn lane, with the channel gutter on the left aligned to the same
 * lanes. Background, grid and traces are all painted by TimeSeriesReceiver into one image, so
 * they cannot drift apart; everything QML draws on top -- names, cursors, readout -- is either
 * static or follows the mouse.
 *
 * Written against Qt Quick Controls 2 throughout. The previous version mixed Controls 1 and 2,
 * and Controls 1 does not exist in Qt 6.
 */
Item {
    id: plot_root_window

    property alias sourceInfo: plot.sourceInfo
    property alias plot: plot
    /// Exposed so an embedding app (or a test rig) can drive the persisted settings directly.
    property alias settings: settings
    /// The scalp map, so a test rig can ask it what colour a reading resolves to.
    property alias headView: headView
    /// The interpolated field, the other half of head mode. See @ref headFieldMode.
    property alias headField: headField

    /**
     * ⭐ WHICH scalp map head mode shows: the discs, or the interpolated field.
     *
     * MUTUALLY EXCLUSIVE, and that is the point. They are two answers to the same question, drawn
     * by two different rules -- the discs colour each electrode against impedance thresholds, the
     * field interpolates a potential surface between them -- and laying one over the other would
     * put a disc coloured by one rule on top of a colour produced by the other.
     *
     * Anything this file does not recognise, INCLUDING a settings blob written before the key
     * existed, reads as the discs: that is what this viewer has always shown, so an old
     * configuration opens looking exactly as it did.
     *
     * ⚠ `head_view` HAS A THIRD VALUE THIS VIEW CANNOT DRAW: "traces", the epoch viewer's
     * head-shaped array of per-electrode epoch traces. One miniature stimulus-locked window per
     * electrode is not something a scrolling sweep has, so it lands in the clause above and this
     * view shows the discs. The two views are never on screen together (see StreamView), so the
     * fallback is invisible in use -- but the button below deliberately does not offer "traces"
     * rather than offering it and drawing something else.
     */
    readonly property bool headFieldMode:
        settings !== null && settings.head_view === "field"

    /**
     * The readings the FIELD is drawn from: one number per CHANNEL INDEX, in BASE units, NaN where
     * the averaging window held no finite sample.
     *
     * ⚠ BASE units, never the prefixed display ones -- `headValues` publishes both and this
     * takes `baseValue`. The SI prefix is derived once, in the panel, from the colour LIMIT.
     *
     * ⚠ NaN, never zero, for a channel the amplifier could not read. One NaN drops that
     * channel from the fit and draws it hollow; a zero would be a reading, and an invented one.
     */
    property var headFieldValues: []

    function refreshHeadField() {
        if (!settings || !settings.head_mode || !headFieldMode) {
            if (headFieldValues.length > 0)
                headFieldValues = []
            return
        }
        var all = plot.headValues(settings.head_average_seconds)
        var out = []
        for (var i = 0; i < all.length; ++i)
            out.push(all[i].valid ? all[i].baseValue : NaN)
        headFieldValues = out
    }

    Timer {
        // The same cadence HeadView runs at, and for the same reason: a scalp figure that changes
        // faster than it can be read is not more informative. Stopped while the field is off
        // screen -- every assignment re-solves and re-evaluates a 200x200 grid.
        interval: 250
        repeat: true
        running: plot_root_window.headFieldMode && plot_root_window.settings !== null
                 && plot_root_window.settings.head_mode
        triggeredOnStart: true
        onTriggered: plot_root_window.refreshHeadField()
    }

    /// The head map's background picture and the electrode spread over it. Assigned from outside
    /// -- one picture serves both viewers, so the Configurator owns the parameters and hands the
    /// values down rather than each viewer carrying its own copy.
    property alias headImage: settings.head_image
    property alias headScale: settings.head_scale
    property alias headX: settings.head_image_cx
    property alias headY: settings.head_image_cy

    property alias parameter_name: settings.parameter_name
    property alias parameter_group: settings.parameter_group
    property alias parameter_label: settings.parameter_label
    property alias parameter_index: settings.parameter_index

    property bool showChannelPanel: false
    property bool measuring: false
    /// Rubber-band zoom armed. One rectangle, then it switches itself off — a mode that stays on
    /// swallows the next click somebody meant for the trace under it.
    property bool zooming: false
    /// Whether the settings panel is up. An alias so an embedding app can open it directly.
    property alias settingsVisible: settingsPopup.visible

    /**
     * Per-row statistics between the measurement cursors, refreshed while they are up.
     *
     * The interval on its own only answers "how far apart are they". What people take off a
     * marked interval is an amplitude -- a burst, an artifact, a blink -- so each lane shows its
     * own peak-to-peak next to the channel name, with min/max/mean/RMS behind a tooltip.
     */
    property var measureStats: []

    function refreshMeasureStats() {
        if (!measuring || measureLayerLoaded === null) {
            measureStats = []
            return
        }
        measureStats = plot.statsBetween(measureLayerLoaded.aPos, measureLayerLoaded.bPos)
    }

    /// Set by the measurement layer once it exists, so the stats helper can reach its cursors.
    property var measureLayerLoaded: null

    Timer {
        interval: 400
        repeat: true
        running: plot_root_window.measuring
        onTriggered: plot_root_window.refreshMeasureStats()
    }

    onMeasuringChanged: refreshMeasureStats()

    implicitHeight: 200
    focus: true

    // Controls 2's default metrics are sized for touch; this is a desktop instrument panel and
    // density matters more than hit area. `font` is set on each Pane rather than here, because
    // a plain Item has no font property to inherit from -- only Controls do.
    readonly property int uiFontSize: 11

    /// Ink for the text drawn *over* the plot background -- the time ruler and the gutter's scale
    /// line. Fixed grey works on the black default and vanishes on a white one, and the background
    /// is a setting now.
    readonly property bool lightPlot:
        0.299 * settings.background.r + 0.587 * settings.background.g
        + 0.114 * settings.background.b > 0.5
    readonly property color plotInk: lightPlot ? "#505050" : "#909090"

    Settings { id: settings }

    // --- settings <-> live objects --------------------------------------------------------
    // Bound rather than assigned so a settings load, a Configurator push and a local edit all
    // end up in the same place.
    Binding { target: plot; property: "duration"; value: settings.axis_time_max }
    Binding { target: plot; property: "highpass"
              value: settings.filter_highpass_enabled ? settings.filter_highpass : 0 }
    Binding { target: plot; property: "lowpass"
              value: settings.filter_lowpass_enabled ? settings.filter_lowpass : 0 }
    Binding { target: plot; property: "notch"
              value: settings.filter_notch_enabled ? settings.filter_notch : 0 }
    Binding { target: plot; property: "notchWidth"; value: settings.filter_notchWidth }
    Binding { target: plot; property: "notchHarmonics"; value: settings.filter_notchHarmonics }
    Binding { target: plot; property: "filterType"; value: settings.filter_type }
    Binding { target: plot; property: "filterOrder"; value: settings.filter_order }
    Binding { target: plot; property: "lineWidth"; value: settings.lineWidth }
    // One way, like every other Binding here: the panel writes the setting and the setting reaches
    // the model. The model never writes back, so this cannot loop.
    Binding { target: plot.channelModel; property: "traceColorMode"
              value: settings.trace_color_mode
              when: plot.channelModel !== null }
    Binding { target: plot; property: "antialiasTraces"; value: settings.antialias }
    Binding { target: plot; property: "rowsPerPage"; value: settings.rows_per_page }
    Binding { target: plot; property: "stacked"; value: settings.stacked }
    Binding { target: plot; property: "referenceMode"; value: settings.reference_mode }
    Binding { target: plot; property: "referenceChannel"; value: settings.reference_channel }
    Binding { target: plot; property: "backgroundColor"; value: settings.background }
    Binding { target: plot; property: "gridColor"; value: settings.grid_color }
    Binding { target: plot; property: "zeroLineColor"; value: settings.grid_middleLine_color }
    Binding { target: plot; property: "showGrid"; value: settings.grid_visible }
    Binding { target: plot; property: "showZeroLine"; value: settings.grid_middleLine_visible }
    Binding { target: plot; property: "hideConstantBits"; value: settings.hide_constant_bits }
    Binding { target: plot; property: "catchLevel"; value: settings.catch_level }
    Binding { target: plot; property: "catchEdge"; value: settings.catch_edge }

    // --- ⭐ viewer-side epoching --------------------------------------------------------------
    // The sink itself is assigned by StreamView, which owns both viewers; everything here is a
    // setting. One way, as with every other Binding above: the panel writes the setting and the
    // setting reaches the receiver, so a --serviceConfig load and a click land in the same place.
    Binding { target: plot; property: "cutEnabled"; value: settings.epoch_cut_enabled }
    Binding { target: plot; property: "cutStamp"; value: settings.epoch_cut_stamp }
    Binding { target: plot; property: "cutUseBlockTimestamps"; value: settings.epoch_cut_use_block_timestamps }
    Binding { target: plot; property: "cutTriggerChannel"
              value: settings.epoch_cut_trigger_channel }
    Binding { target: plot; property: "cutTriggerMode"; value: settings.epoch_cut_trigger_mode }
    Binding { target: plot; property: "cutTriggerBit"; value: settings.epoch_cut_trigger_bit }
    Binding { target: plot; property: "cutTriggerLevel"; value: settings.epoch_cut_trigger_level }
    Binding { target: plot; property: "cutTriggerEdge"; value: settings.epoch_cut_trigger_edge }
    Binding { target: plot; property: "cutPreMs"; value: settings.epoch_cut_pre_ms }
    Binding { target: plot; property: "cutPostMs"; value: settings.epoch_cut_post_ms }
    Binding { target: plot; property: "cutRefractoryMs"; value: settings.epoch_cut_refractory_ms }
    Binding { target: plot; property: "cutCodeMask"; value: settings.epoch_cut_code_mask }
    Binding { target: plot; property: "cutAcceptedCodes"; value: settings.epoch_cut_codes }
    Binding { target: plot; property: "cutMarkerAllowanceMs"
              value: settings.epoch_cut_marker_allowance_ms }

    // The level is dragged on the plot and the edge is cycled by double-clicking it, so unlike
    // every other setting here these are changed from the C++ side. Writing them back is what
    // keeps a dragged level across a restart.
    Connections {
        target: plot
        function onCatchChanged() {
            settings.catch_level = plot.catchLevel
            settings.catch_edge = plot.catchEdge
        }
    }

    // Channel appearance is a lot of state and it changes on every click. Serialising it into a
    // service parameter on each change would re-broadcast the whole description constantly, so
    // the write back is coalesced.
    property bool _syncingChannelState: false

    Timer {
        id: channelStateWriteback
        interval: 500
        repeat: false
        onTriggered: {
            if (plot_root_window._syncingChannelState)
                return
            plot_root_window._syncingChannelState = true
            settings.channel_state = plot.channelModel.stateJson
            plot_root_window._syncingChannelState = false
        }
    }

    Connections {
        target: plot.channelModel
        function onStateJsonChanged() { channelStateWriteback.restart() }

        // The catch's source *is* the selection, so moving the selection moves the catch. A
        // caught result is left alone: it is a measurement already taken, not a live setting.
        function onSelectionChanged() {
            if (!plot.catchEnabled || plot.catchState === TimeSeriesReceiver.CatchHit)
                return
            var sel = plot.channelModel.selectedChannels()
            if (sel.length === 1 && sel[0] !== plot.catchChannel)
                plot.catchChannel = sel[0]
        }
    }

    Connections {
        target: settings
        function onChannel_stateChanged() {
            if (plot_root_window._syncingChannelState || settings.channel_state === "")
                return
            plot_root_window._syncingChannelState = true
            plot.channelModel.stateJson = settings.channel_state
            plot_root_window._syncingChannelState = false
        }
    }

    // --- helpers ---------------------------------------------------------------------------

    function scaleBy(factor) {
        var gs = plot.channelModel.groupList()
        for (var i = 0; i < gs.length; ++i) {
            if (gs[i].scaleMode !== ChannelModel.AutoScale)
                plot.channelModel.setGroupRange(gs[i].name, gs[i].range * factor)
        }
    }

    function scrollRows(delta) {
        plot.firstRow = plot.firstRow + delta
    }

    /**
     * Apply a rubber-band rectangle, in plot pixels.
     *
     * Time and amplitude are separate axes here and the rectangle sets both: its width becomes the
     * window length, and within every row it overlaps, the covered band becomes that channel's
     * scale. Per row rather than per group, because a rectangle drawn over one trace means that
     * trace -- a group-wide change would rescale channels the operator did not point at.
     *
     * The time *origin* is not preserved, only the span. The display is a wrap-around sweep whose
     * buffer is rebuilt whenever the window length changes, so there is no earlier data to show
     * at a new offset; the window refills from the right as it always does.
     */
    function applyZoomRect(x0, y0, x1, y1, plotWidth, plotHeight) {
        var left = Math.min(x0, x1)
        var right = Math.max(x0, x1)
        var top = Math.min(y0, y1)
        var bottom = Math.max(y0, y1)

        // A stray click is not a zoom. Below a few pixels the rectangle is noise and applying it
        // would leave the viewer at some unusable scale for no reason the operator can see.
        if (right - left < 6 || bottom - top < 6 || plotWidth <= 0 || plotHeight <= 0)
            return false

        var rows = plot.drawnRows
        if (rows > 0) {
            var swimlane = plotHeight / rows
            for (var i = 0; i < rows; ++i) {
                var rowTop = i * swimlane
                var rowBottom = rowTop + swimlane
                var lo = Math.max(top, rowTop)
                var hi = Math.min(bottom, rowBottom)
                if (hi - lo < 2)
                    continue

                var row = plot.firstRow + i
                var info = plot.rowInfo(row)
                // Bit lanes have no amplitude to zoom; their scale is a fixed 0..1.
                if (!info || info.bit >= 0 || info.channel < 0)
                    continue

                var vHi = plot.rowYToValue(row, lo)
                var vLo = plot.rowYToValue(row, hi)
                if (isNaN(vHi) || isNaN(vLo) || vHi <= vLo)
                    continue
                plot.channelModel.setChannelScale(info.channel, (vHi - vLo) / 2,
                                                  (vHi + vLo) / 2)
            }
        }

        var span = (right - left) / plotWidth * plot.duration
        if (span > 0.02)
            settings.axis_time_max = span
        return true
    }

    /// Space flips the tick on every selected channel, the way channel selection already works
    /// in the NVX dialogs. Freeze moved to P to leave Space for it.
    function toggleSelectedVisibility() {
        var m = plot.channelModel
        if (!m || m.selectedCount === 0)
            return false
        var sel = m.selectedChannels()
        var first = m.data(m.index(sel[0], 0), ChannelModel.VisibleRole)
        m.setSelectionVisible(!first)
        return true
    }

    Keys.onPressed: {
        switch (event.key) {
        case Qt.Key_Space:      if (toggleSelectedVisibility()) event.accepted = true; break
        case Qt.Key_P:          plot.frozen = !plot.frozen; event.accepted = true; break
        case Qt.Key_Up:         scaleBy(0.8); event.accepted = true; break
        case Qt.Key_Down:       scaleBy(1.25); event.accepted = true; break
        case Qt.Key_Right:      settings.axis_time_max *= 0.8; event.accepted = true; break
        case Qt.Key_Left:       settings.axis_time_max *= 1.25; event.accepted = true; break
        case Qt.Key_PageDown:   scrollRows(plot.drawnRows); event.accepted = true; break
        case Qt.Key_PageUp:     scrollRows(-plot.drawnRows); event.accepted = true; break
        case Qt.Key_Home:       plot.firstRow = 0; event.accepted = true; break
        case Qt.Key_F:          plot.fitNow(); event.accepted = true; break
        case Qt.Key_C:          showChannelPanel = !showChannelPanel; event.accepted = true; break
        case Qt.Key_S:          openSettingsAt(-1, -1); event.accepted = true; break
        case Qt.Key_M:          measuring = !measuring; event.accepted = true; break
        case Qt.Key_Z:          zooming = !zooming; event.accepted = true; break
        case Qt.Key_K:          settings.stacked = !settings.stacked; event.accepted = true; break
        case Qt.Key_Escape:     if (zooming) { zooming = false; event.accepted = true }; break
        case Qt.Key_T:          plot.catchEnabled = !plot.catchEnabled; event.accepted = true; break
        case Qt.Key_H:          if (plot.hasHeadLayout) {
                                    settings.head_mode = !settings.head_mode
                                    event.accepted = true
                                }
                                break
        case Qt.Key_R:          if (plot.catchEnabled) { plot.armCatch(); event.accepted = true }; break
        }
    }

    /**
     * Shut every panel this viewer owns.
     *
     * settingsPopup is a Controls 2 Popup, so it lives in the WINDOW's overlay rather than
     * inside this item. Hiding the viewer -- which StreamView does the moment its connector is
     * cleared -- therefore leaves the panel floating over a viewer that says "Drag stream here",
     * with nothing left on screen that can dismiss it. Closing it explicitly is the only way
     * back.
     */
    function closePanels() {
        settingsPopup.close()
        showChannelPanel = false
    }

    // Losing the stream closes everything. Both the deliberate case (the operator clears the
    // connector) and the involuntary one (the producer dies) land here, because either way the
    // receiver's resolved info goes empty.
    Connections {
        target: plot
        function onSourceInfoChanged() {
            if (plot.sourceInfo.isEmpty())
                plot_root_window.closePanels()
        }
    }

    // Setup and Channels are alternatives, not companions: both are wide, and open together they
    // leave a strip of plot between two panels of controls.
    onShowChannelPanelChanged: {
        if (showChannelPanel)
            settingsPopup.close()
    }

    /// Opens the settings panel where it was asked for. Anchoring it to the right edge meant a
    /// right-click in the plot always threw it to the far side of the window.
    function openSettingsAt(gx, gy) {
        if (settingsPopup.visible) {
            settingsPopup.close()
            return
        }
        showChannelPanel = false
        if (gx >= 0) {
            settingsPopup.x = Math.max(2, Math.min(gx, width - settingsPopup.width - 2))
            settingsPopup.y = Math.max(2, Math.min(gy, height - settingsPopup.height - 2))
        } else {
            settingsPopup.x = Math.max(2, width - settingsPopup.width - 12)
            settingsPopup.y = 26
        }
        settingsPopup.open()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        // --- toolbar -------------------------------------------------------------------------
        // Inside a Pane so the chrome carries its own background. Sitting directly on the plot's
        // dark background, the default control palette rendered near-black text on near-black.
        Pane {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            padding: 2
            font.pixelSize: plot_root_window.uiFontSize
            // A RowLayout still lays its children out when their combined minimum exceeds the
            // width it was given -- it just runs past the end, and a Pane does not clip by
            // default. With two viewers side by side that put this toolbar's tail ("73 ch ·
            // 25000 Hz", the row counter, the paint time) on top of the NEIGHBOURING viewer.
            // Clip so a viewer can never draw outside itself.
            clip: true

            RowLayout {
            anchors.fill: parent
            spacing: 2

            CompactButton {
                id: holdButton
                implicitHeight: 19
                highlighted: plot.frozen
                ToolTip.visible: hovered
                ToolTip.text: "Stop the display without touching the stream (P)"
                onClicked: plot.frozen = !plot.frozen

                // Drawn, not typed. The pause glyph in the UI font renders as two bars a word
                // apart, which reads as a mistake rather than as a symbol.
                contentItem: Row {
                    spacing: 4

                    Item {
                        id: holdIcon
                        width: 8
                        height: holdLabel.implicitHeight
                        anchors.verticalCenter: parent.verticalCenter

                        // Integer widths at integer offsets. At 2.5 px the two bars landed on
                        // different sub-pixel phases and rasterised 2 px and 3 px wide, so the
                        // symbol came out visibly lopsided.
                        Item {
                            width: 8
                            height: 9
                            y: Math.round((holdIcon.height - 9) / 2)
                            visible: !plot.frozen

                            Rectangle { x: 0; width: 3; height: 9; color: "#2a2a2a" }
                            Rectangle { x: 5; width: 3; height: 9; color: "#2a2a2a" }
                        }

                        Canvas {
                            id: playGlyph
                            anchors.centerIn: parent
                            width: 8
                            height: 9
                            visible: plot.frozen
                            onPaint: {
                                var c = getContext("2d")
                                c.reset()
                                c.fillStyle = "#2a2a2a"
                                c.beginPath()
                                c.moveTo(0, 0)
                                c.lineTo(8, 4.5)
                                c.lineTo(0, 9)
                                c.closePath()
                                c.fill()
                            }
                            // By id, not by `parent`: inside Connections `parent` is the
                            // Connections object, which has nothing to repaint.
                            Connections {
                                target: plot
                                function onFrozenChanged() { playGlyph.requestPaint() }
                            }
                        }
                    }

                    Text {
                        id: holdLabel
                        text: plot.frozen ? "Run" : "Hold"
                        font: holdButton.font
                        color: "#1e1e1e"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            CompactButton {
                text: "Fit"
                implicitHeight: 19
                ToolTip.visible: hovered
                ToolTip.text: "Fit each group's scale to the data on screen, once, and leave it "
                              + "fixed there (F)"
                onClicked: plot.fitNow()
            }
            CompactButton {
                text: "Stack"
                implicitHeight: 19
                // NOT `checkable`. A checkable Button assigns its own `checked` on click, which
                // overwrites the binding -- and this setting is shared with the epoch view's
                // "Butterfly", so it can change while this button is not even on screen, and a
                // broken binding would show the wrong state on the way back. `highlighted` is a
                // plain property and keeps following the setting.
                highlighted: settings.stacked
                enabled: !settings.head_mode
                ToolTip.visible: hovered
                ToolTip.text: "Overlay every channel on one axis instead of a lane each (K) — for "
                              + "comparing traces against each other rather than reading them one "
                              + "at a time."
                onClicked: settings.stacked = !settings.stacked
            }
            CompactButton {
                text: "Channels"
                implicitHeight: 19
                checkable: true
                checked: plot_root_window.showChannelPanel
                ToolTip.visible: hovered
                ToolTip.text: "Channel list, selection and colours (C)"
                onClicked: plot_root_window.showChannelPanel = checked
            }
            CompactButton {
                text: "Setup"
                implicitHeight: 19
                ToolTip.visible: hovered
                ToolTip.text: "Filters, reference and per-group scales (S, or right-click the plot)"
                onClicked: plot_root_window.openSettingsAt(-1, -1)
            }
            CompactButton {
                text: "Measure"
                implicitHeight: 19
                checkable: true
                checked: plot_root_window.measuring
                ToolTip.visible: hovered
                ToolTip.text: "Drag the A and B handles at the top of the plot; the gap between "
                              + "them is shown as a time and as a frequency (M)"
                onClicked: plot_root_window.measuring = checked
            }
            CompactButton {
                text: "Head"
                implicitHeight: 19
                checkable: true
                checked: settings.head_mode
                // Enabled only when there is a montage to draw. A toggle that switches to an
                // empty panel teaches the operator the feature is broken.
                enabled: plot.hasHeadLayout
                ToolTip.visible: hovered
                ToolTip.text: plot.hasHeadLayout
                    ? "Show the channels on a scalp map instead of as traces (H). Built for "
                      + "impedance: colours follow the thresholds in Setup."
                    : "This stream carries no electrode positions, so there is no map to draw. "
                      + "The driver needs a .ced montage."
                onClicked: settings.head_mode = checked
            }
            CompactButton {
                // ⭐ Discs or field, one click, and only while the map is up: a control for a
                // panel that is not on screen is clutter.
                text: plot_root_window.headFieldMode ? "Field" : "Discs"
                implicitHeight: 19
                visible: settings.head_mode
                enabled: plot.hasHeadLayout
                // NOT `checkable`: a checkable Button assigns its own `checked` on click and
                // overwrites the binding, and this setting is shared with the epoch viewer.
                highlighted: plot_root_window.headFieldMode
                accentColor: "#7fb3d5"
                ToolTip.visible: hovered
                ToolTip.text: plot_root_window.headFieldMode
                    ? "Showing the interpolated field over the EEG channels, averaged over the "
                      + "head window. Click for one disc per electrode, coloured against the "
                      + "impedance thresholds in Setup."
                    : "Showing one disc per electrode, coloured against the impedance thresholds "
                      + "in Setup. Click for the interpolated field over the EEG channels."
                onClicked: settings.head_view =
                        plot_root_window.headFieldMode ? "discs" : "field"
            }
            CompactButton {
                id: catchButton
                text: "Catch"
                implicitHeight: 19
                checkable: true
                checked: plot.catchEnabled
                // Amber while it is watching, green once it has something, so the state is
                // readable from across a room without hunting for a label.
                accentColor: plot.catchState === TimeSeriesReceiver.CatchHit
                             ? "#7ec97e" : "#e2b843"
                // The source is whatever single channel is selected, so arming needs a selection
                // of exactly one. Switching it off is always allowed -- otherwise a stray click in
                // the channel list would strand an armed catch with no way to cancel it.
                enabled: plot.catchEnabled || plot.channelModel.selectedCount === 1
                ToolTip.visible: hovered
                ToolTip.text: plot.channelModel.selectedCount === 1 || plot.catchEnabled
                    ? "Pause automatically when the selected channel crosses the level (T). Drag "
                      + "the amber line to set the level; double-click it to change which "
                      + "direction counts. The window stops with the crossing in the middle."
                    : "Select exactly one channel to catch on."
                onClicked: {
                    if (checked) {
                        var sel = plot.channelModel.selectedChannels()
                        if (sel.length === 1)
                            plot.catchChannel = sel[0]
                    }
                    plot.catchEnabled = checked
                }
            }


            CompactButton {
                id: cutButton
                text: "Cut"
                implicitHeight: 19
                // NOT `checkable`, for the reason the Stack button gives: a checkable Button
                // assigns its own `checked` on click and overwrites the binding, and this setting
                // is also written by the epoching panel.
                highlighted: settings.epoch_cut_enabled
                // Green once epochs are coming out, amber while it is only watching, so the state
                // is readable without hunting for a number.
                accentColor: plot.cutCounters.epochs > 0 ? "#7ec97e" : "#e2b843"
                enabled: settings !== null
                ToolTip.visible: hovered
                ToolTip.text: {
                    if (!settings.epoch_cut_enabled)
                        return "Cut epochs out of this stream around a trigger carried in it, and "
                             + "show them in the epoch view beside the sweep. Trigger lane, "
                             + "window and codes are in Setup → Epoching."
                    if (plot.cutProblem !== "")
                        return "Epoching is off: " + plot.cutProblem
                    return plot.cutStatus + "\nWindow " + plot.cutSamples + " samples, t=0 at "
                         + plot.cutZeroSample + ". Settings are in Setup → Epoching."
                }
                onClicked: settings.epoch_cut_enabled = !settings.epoch_cut_enabled
            }

            CompactButton {
                text: "Zoom"
                implicitHeight: 19
                checkable: true
                checked: plot_root_window.zooming
                enabled: !settings.head_mode
                ToolTip.visible: hovered
                ToolTip.text: "Drag a rectangle on the plot (Z). Its width becomes the time "
                              + "range; its height becomes the amplitude range of every row it "
                              + "covers. Fit or the row menu puts a scale back."
                onClicked: plot_root_window.zooming = checked
            }

            ToolSeparator { padding: 1; implicitHeight: 18 }

            Label {
                visible: plot.catchEnabled
                text: {
                    switch (plot.catchState) {
                    case TimeSeriesReceiver.CatchArmed:   return "armed"
                    case TimeSeriesReceiver.CatchFilling: return "caught — filling"
                    case TimeSeriesReceiver.CatchHit:     return "caught"
                    }
                    return "no source"
                }
                color: plot.catchState === TimeSeriesReceiver.CatchHit ? "#7ad07a" : "#d0a020"
                font.pixelSize: 11
            }

            CompactButton {
                visible: plot.catchEnabled && plot.catchState === TimeSeriesReceiver.CatchHit
                text: "Re-arm"
                implicitHeight: 19
                ToolTip.visible: hovered
                ToolTip.text: "Throw this one away and watch for the next crossing"
                onClicked: plot.armCatch()
            }

            Label {
                text: {
                    if (plot.channels <= 0)
                        return "no stream"
                    var s = plot.channels + " ch · " + plot.samplingRate.toFixed(0) + " Hz"
                    if (plot.decimation > 1)
                        s += " · ÷" + plot.decimation
                    return s
                }
                font.pixelSize: 11
                opacity: 0.75
                ToolTip.visible: rateHover.hovered
                ToolTip.text: plot.decimation > 1
                    ? "Stored as a min/max envelope of every " + plot.decimation + " samples ("
                      + plot.storedRate.toFixed(0) + " Hz). Peaks are kept; sub-sample shape is not."
                    : "Every sample is stored"
                HoverHandler { id: rateHover }
            }

            Label {
                visible: plot.filterError !== ""
                text: "⚠ filter"
                color: "#e04030"
                font.pixelSize: 11
                ToolTip.visible: errHover.hovered
                ToolTip.text: plot.filterError
                HoverHandler { id: errHover }
            }

            Item { Layout.fillWidth: true }

            Label {
                text: plot.channelRows > plot.drawnRows
                      ? ("rows " + (plot.firstRow + 1) + "–" + (plot.firstRow + plot.drawnRows)
                         + " of " + plot.channelRows)
                      : (plot.channelRows + " rows")
                font.pixelSize: 11
                opacity: 0.75
            }

            Label {
                text: plot.lastPaintMs.toFixed(1) + " ms"
                font.pixelSize: 11
                opacity: 0.55
                color: plot.lastPaintMs > 33 ? "#d0a020" : palette.text
                ToolTip.visible: paintHover.hovered
                ToolTip.text: "Time for a full redraw. Above ~33 ms the display cannot keep 30 fps "
                              + "— reduce rows per screen, or turn off antialiasing."
                HoverHandler { id: paintHover }
            }
            }
        }

        // --- plot + gutter + channel panel ------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // The plot and its time ruler share one column, so the ruler's width is the plot's
            // width by construction. It used to be a sibling spanning the whole window, so
            // opening the channel panel narrowed the plot and left the second labels behind,
            // pointing at nothing.
            ColumnLayout {
                id: traceColumn
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                // Hidden rather than unloaded: the receiver keeps its buffer and its stream, so
                // switching back shows the last few seconds instead of an empty window, and the
                // head map reads its numbers out of that same buffer.
                visible: !settings.head_mode

            Item {
                id: plotContainer
                Layout.fillWidth: true
                Layout.fillHeight: true

                property int rows: Math.max(1, plot.drawnRows)
                /// Height of one *lane*. Stacked, every trace uses the whole plot, so this is the
                /// full height and the gutter has to stop using it as a row pitch -- see below.
                property real swimlane: settings.stacked ? height : height / rows
                /// Row pitch in the channel column. Stacked, the names become a plain list: there
                /// is no lane to line them up with, and a 60-row list at full height would put one
                /// name on screen.
                property real gutterPitch: settings.stacked
                                           ? Math.min(16, height / rows) : swimlane

                // --- channel gutter -------------------------------------------------------
                Rectangle {
                    id: gutter
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: settings.gutter_width
                    color: settings.background

                    Column {
                        anchors.fill: parent

                        Repeater {
                            model: plot.drawnRows

                            Item {
                                id: gutterRow
                                required property int index

                                width: gutter.width
                                height: plotContainer.gutterPitch

                                property var info: plot.rowInfo(plot.firstRow + index)
                                property int ch: info ? info.channel : -1

                                // rowInfo is a plain call, so it has to be re-read when anything
                                // that feeds it moves.
                                Connections {
                                    target: plot
                                    function onRowsChanged() { gutterRow.info = plot.rowInfo(plot.firstRow + gutterRow.index) }
                                    function onFirstRowChanged() { gutterRow.info = plot.rowInfo(plot.firstRow + gutterRow.index) }
                                }
                                Connections {
                                    target: plot.channelModel
                                    function onAppearanceChanged() { gutterRow.info = plot.rowInfo(plot.firstRow + gutterRow.index) }
                                    function onScalesChanged() { gutterRow.info = plot.rowInfo(plot.firstRow + gutterRow.index) }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.rightMargin: 1
                                    color: (gutterRow.info && gutterRow.info.selected)
                                           ? Qt.rgba(0.30, 0.50, 0.75, 0.35) : "transparent"
                                }

                                Column {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 4
                                    anchors.right: parent.right
                                    anchors.rightMargin: 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 0

                                    Text {
                                        width: parent.width
                                        text: gutterRow.info ? gutterRow.info.name : ""
                                        color: gutterRow.info ? gutterRow.info.color : "white"
                                        opacity: (gutterRow.info && gutterRow.info.bad) ? 0.45 : 1
                                        font.pixelSize: Math.max(8, Math.min(13, plotContainer.gutterPitch * 0.5))
                                        font.strikeout: gutterRow.info ? gutterRow.info.bad : false
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        // The scale bar every EEG viewer puts next to the label:
                                        // without it a trace is a shape with no magnitude. While
                                        // measuring it gives way to the peak-to-peak between the
                                        // cursors, which is what the cursors were put there for.
                                        visible: plotContainer.gutterPitch > 26 && gutterRow.info
                                                 && gutterRow.info.bit < 0
                                        text: {
                                            if (!gutterRow.info)
                                                return ""
                                            var st = plot_root_window.measuring
                                                     ? plot_root_window.measureStats[gutterRow.index]
                                                     : null
                                            if (st && st.valid && st.peakToPeak !== undefined) {
                                                // A single glyph for peak-to-peak: the gutter is
                                                // deliberately narrow and "pp " ate the number.
                                                return "↕" + Number(st.peakToPeak).toPrecision(3)
                                                       + " " + st.unit
                                            }
                                            return "±" + Number(gutterRow.info.range).toPrecision(3)
                                                   + " " + gutterRow.info.unit
                                        }
                                        color: plot_root_window.measuring ? "#40c0ff" : plot_root_window.plotInk
                                        font.pixelSize: Math.max(7, Math.min(10, plotContainer.gutterPitch * 0.28))
                                        elide: Text.ElideRight

                                        ToolTip.visible: statsHover.hovered
                                                         && plot_root_window.measuring
                                        ToolTip.text: {
                                            var st = plot_root_window.measureStats[gutterRow.index]
                                            if (!st || !st.valid || st.peakToPeak === undefined)
                                                return ""
                                            return "min " + Number(st.min).toPrecision(4) + " " + st.unit
                                                 + "\nmax " + Number(st.max).toPrecision(4) + " " + st.unit
                                                 + "\npeak-peak " + Number(st.peakToPeak).toPrecision(4) + " " + st.unit
                                                 + "\nmean " + Number(st.mean).toPrecision(4) + " " + st.unit
                                                 + "\nRMS " + Number(st.rms).toPrecision(4) + " " + st.unit
                                        }
                                        HoverHandler { id: statsHover }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                                    onClicked: {
                                        plot_root_window.forceActiveFocus()
                                        if (gutterRow.ch < 0)
                                            return
                                        if (mouse.button === Qt.RightButton) {
                                            if (!plot.channelModel.data(
                                                    plot.channelModel.index(gutterRow.ch, 0),
                                                    ChannelModel.SelectedRole))
                                                plot.channelModel.selectOnly(gutterRow.ch)
                                            rowMenu.channel = gutterRow.ch
                                            rowMenu.popup()
                                        } else if (mouse.modifiers & Qt.ShiftModifier) {
                                            plot.channelModel.selectRange(gutterRow.ch)
                                        } else if (mouse.modifiers & Qt.ControlModifier) {
                                            plot.channelModel.toggleSelection(gutterRow.ch)
                                        } else {
                                            plot.channelModel.selectOnly(gutterRow.ch)
                                        }
                                    }

                                    onDoubleClicked: {
                                        if (gutterRow.ch < 0)
                                            return
                                        // Solo, and un-solo by showing everything again.
                                        if (plot.channelModel.visibleCount === 1)
                                            plot.channelModel.showAll()
                                        else {
                                            plot.channelModel.selectOnly(gutterRow.ch)
                                            plot.channelModel.soloSelection()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 1
                        height: parent.height
                        color: gutterHandle.containsMouse || gutterHandle.pressed
                               ? "#4a90d9" : "#505050"
                    }

                    // Drag the divider to trade gutter width against plot width. Montages vary
                    // wildly -- "Fz" and "AUX 1" want very different amounts of room -- so this
                    // is a per-viewer setting rather than a constant someone has to live with.
                    MouseArea {
                        id: gutterHandle
                        anchors.right: parent.right
                        anchors.rightMargin: -3
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 7
                        hoverEnabled: true
                        cursorShape: Qt.SplitHCursor
                        preventStealing: true

                        property real pressWidth: 0

                        onPressed: pressWidth = gutter.width
                        onPositionChanged: {
                            if (!pressed)
                                return
                            settings.gutter_width = Math.round(
                                        Math.max(24, Math.min(260, pressWidth + mouseX)))
                        }
                        onDoubleClicked: settings.gutter_width = 51
                        ToolTip.visible: containsMouse && !pressed
                        ToolTip.text: "Drag to resize the channel column · double-click to reset"
                    }
                }

                // --- the traces -------------------------------------------------------------
                TimeSeriesReceiver {
                    id: plot

                    anchors.left: gutter.right
                    anchors.right: vScroll.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    // Row separators are the zero lines; a wide swimlane also gets its own grid.
                    onRowsChanged: plotOverlay.requestPaint()

                    Component.onCompleted: {
                        if (settings.channel_state !== "")
                            plot.channelModel.stateJson = settings.channel_state
                    }
                }

                // --- overlay: write cursor, hover crosshair, measurement -------------------
                Item {
                    id: overlay
                    anchors.fill: plot

                    // Where the ring buffer is currently writing: everything to its left is the
                    // most recent data, everything to its right is the previous sweep.
                    Rectangle {
                        x: plot.cursorPosition * overlay.width
                        width: 1
                        height: overlay.height
                        color: "#ff8800"
                        opacity: plot.frozen ? 0.25 : 0.9
                    }

                    Rectangle {
                        visible: hover.containsMouse
                        x: hover.mouseX
                        width: 1
                        height: overlay.height
                        color: "#ffffff"
                        opacity: 0.4
                    }

                    // --- amplitude axis ---------------------------------------------------
                    // Only when one lane fills the plot. Sixty lanes of tick labels is not an
                    // axis, it is noise, so this appears exactly when there is one axis to label.
                    Item {
                        id: axisLayer
                        anchors.fill: parent
                        visible: plot.axisIsReadable && plot.drawnRows > 0
                        z: 3

                        property var ticks: []
                        property int axisRow: plot.firstRow

                        function rebuild() {
                            axisRow = plot.firstRow
                            ticks = plot.axisIsReadable
                                    ? plot.amplitudeGrid(axisRow, plot.laneHeight()) : []
                        }

                        Component.onCompleted: rebuild()
                        onVisibleChanged: rebuild()
                        onHeightChanged: rebuild()

                        Connections {
                            target: plot
                            function onRowsChanged() { axisLayer.rebuild() }
                            function onFirstRowChanged() { axisLayer.rebuild() }
                        }
                        Connections {
                            target: plot.channelModel
                            function onScalesChanged() { axisLayer.rebuild() }
                        }

                        Repeater {
                            model: axisLayer.ticks

                            Text {
                                required property var modelData
                                visible: modelData.major && modelData.label !== ""
                                x: 3
                                y: plot.laneCentre(axisLayer.axisRow - plot.firstRow)
                                   + modelData.dy - implicitHeight / 2
                                text: modelData.label
                                color: plot_root_window.plotInk
                                font.pixelSize: 10
                            }
                        }

                        // The unit, once, rather than repeated on every tick.
                        Text {
                            x: 3
                            y: 2
                            text: {
                                var info = plot.rowInfo(axisLayer.axisRow)
                                return info && info.unit ? info.unit : ""
                            }
                            color: plot_root_window.plotInk
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    // --- scale bar --------------------------------------------------------
                    // A known length to compare deflections against: "that blink is about two of
                    // these". Rounded to a value people quote -- 10 uV, 1 mV -- with the bar's
                    // height following, rather than a tidy bar labelled 13.7 uV.
                    Item {
                        id: scaleBarLayer
                        visible: settings.scale_bar && plot.drawnRows > 0 && bar.pixels > 2
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 10
                        anchors.bottomMargin: 8
                        width: barLabel.implicitWidth + 14
                        height: Math.max(bar.pixels, barLabel.implicitHeight) + 4
                        z: 3

                        property var info: ({})
                        readonly property real pixels: info && info.pixels ? info.pixels : 0

                        function rebuild() {
                            info = plot.scaleBar(plot.firstRow, plot.laneHeight() * 0.25)
                        }

                        Component.onCompleted: rebuild()
                        // ⚠ NOT `onHeightChanged` ON THIS ITEM. This layer's own height is
                        // `max(bar.pixels, label) + 4`, so rebuilding on it rewrites `info`,
                        // which invalidates `pixels`, which re-evaluates `height` -- a genuine
                        // cycle, and the "Binding loop detected for property \"pixels\"" this
                        // file used to emit several times per parameter edit.
                        //
                        // It was not merely redundant either. scaleBar() reads the row, the row's
                        // scale and the unit -- and laneHeight(), which is the PLOT's height
                        // divided by the drawn rows. The layer's height is not an input to it at
                        // all, while the plot's height is and had no handler: resizing the plot
                        // left the bar at its old pixel length with a stale label. Both are
                        // fixed by listening to the real inputs.
                        Connections {
                            target: plot
                            function onRowsChanged() { scaleBarLayer.rebuild() }
                            function onFirstRowChanged() { scaleBarLayer.rebuild() }
                            function onHeightChanged() { scaleBarLayer.rebuild() }
                            function onStackedChanged() { scaleBarLayer.rebuild() }
                        }
                        Connections {
                            target: plot.channelModel
                            function onScalesChanged() { scaleBarLayer.rebuild() }
                        }

                        Rectangle {
                            id: bar
                            readonly property real pixels: scaleBarLayer.pixels
                            x: 0
                            anchors.bottom: parent.bottom
                            width: 2
                            height: pixels
                            color: plot_root_window.plotInk
                        }

                        // End caps, so the bar reads as a measured length rather than a stray line.
                        Rectangle {
                            x: 0; y: parent.height - bar.pixels
                            width: 8; height: 2
                            color: plot_root_window.plotInk
                        }
                        Rectangle {
                            x: 0; y: parent.height - 2
                            width: 8; height: 2
                            color: plot_root_window.plotInk
                        }

                        Text {
                            id: barLabel
                            x: 11
                            y: parent.height - bar.pixels / 2 - implicitHeight / 2
                            text: scaleBarLayer.info && scaleBarLayer.info.label
                                  ? scaleBarLayer.info.label : ""
                            color: plot_root_window.plotInk
                            font.pixelSize: 10
                        }
                    }

                    // --- rubber-band zoom -------------------------------------------------
                    // Above the hover crosshair and the measure cursors so it takes the drag
                    // while it is armed, and gone entirely the rest of the time.
                    Item {
                        id: zoomLayer
                        anchors.fill: parent
                        visible: plot_root_window.zooming
                        z: 20

                        property real x0: 0
                        property real y0: 0
                        property real x1: 0
                        property real y1: 0
                        property bool dragging: false

                        Rectangle {
                            visible: zoomLayer.dragging
                            x: Math.min(zoomLayer.x0, zoomLayer.x1)
                            y: Math.min(zoomLayer.y0, zoomLayer.y1)
                            width: Math.abs(zoomLayer.x1 - zoomLayer.x0)
                            height: Math.abs(zoomLayer.y1 - zoomLayer.y0)
                            color: Qt.rgba(0.29, 0.56, 0.85, 0.18)
                            border.color: "#4a90d9"
                            border.width: 1
                        }

                        // What the rectangle will do, while it is being drawn. A zoom that only
                        // announces itself after it has happened is one you have to undo to read.
                        Rectangle {
                            visible: zoomLayer.dragging && zoomText.text !== ""
                            x: Math.min(zoomLayer.x0, zoomLayer.x1)
                            y: Math.max(0, Math.min(zoomLayer.y0, zoomLayer.y1) - height - 2)
                            width: zoomText.implicitWidth + 8
                            height: zoomText.implicitHeight + 4
                            color: Qt.rgba(0, 0, 0, 0.8)
                            border.color: "#4a90d9"
                            radius: 2

                            Text {
                                id: zoomText
                                anchors.centerIn: parent
                                color: "white"
                                font.pixelSize: 10
                                text: {
                                    var w = Math.abs(zoomLayer.x1 - zoomLayer.x0)
                                    if (w < 6 || overlay.width <= 0)
                                        return ""
                                    var span = w / overlay.width * plot.duration
                                    return span >= 1 ? span.toFixed(2) + " s"
                                                     : (span * 1000).toFixed(0) + " ms"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.CrossCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            preventStealing: true

                            onPressed: {
                                if (mouse.button === Qt.RightButton) {
                                    plot_root_window.zooming = false
                                    return
                                }
                                zoomLayer.x0 = mouse.x
                                zoomLayer.y0 = mouse.y
                                zoomLayer.x1 = mouse.x
                                zoomLayer.y1 = mouse.y
                                zoomLayer.dragging = true
                            }
                            onPositionChanged: {
                                if (!zoomLayer.dragging)
                                    return
                                zoomLayer.x1 = mouse.x
                                zoomLayer.y1 = mouse.y
                            }
                            onReleased: {
                                if (!zoomLayer.dragging)
                                    return
                                zoomLayer.dragging = false
                                plot_root_window.applyZoomRect(
                                            zoomLayer.x0, zoomLayer.y0,
                                            zoomLayer.x1, zoomLayer.y1,
                                            overlay.width, overlay.height)
                                // One rectangle per arming: leaving the mode on turns every later
                                // click into a zoom, including the ones meant for a trace.
                                plot_root_window.zooming = false
                            }
                        }
                    }

                    // --- catch level ------------------------------------------------------
                    // The level is a number in Setup, but nobody sets a trigger by typing volts.
                    // It is also a line you drag onto the part of the trace you care about, and
                    // that is the control this layer provides.
                    Item {
                        id: catchLayer
                        anchors.fill: parent
                        visible: plot.catchEnabled && plot.catchChannel >= 0
                        z: 4

                        /// Row and pixel are both re-read on anything that could move them: the
                        /// row's scale, which page is showing, and the level itself.
                        property int row: -1
                        property real levelY: NaN
                        readonly property bool onScreen: !isNaN(levelY)
                                                         && levelY >= 0 && levelY <= height

                        function refresh() {
                            row = plot.rowForChannel(plot.catchChannel)
                            levelY = row < 0 ? NaN : plot.rowValueToY(row, plot.catchLevel)
                        }

                        Component.onCompleted: refresh()
                        onHeightChanged: refresh()
                        onVisibleChanged: refresh()

                        Connections {
                            target: plot
                            function onCatchChanged() { catchLayer.refresh() }
                            function onRowsChanged() { catchLayer.refresh() }
                            function onFirstRowChanged() { catchLayer.refresh() }
                        }
                        Connections {
                            target: plot.channelModel
                            function onScalesChanged() { catchLayer.refresh() }
                            function onRowLayoutChanged() { catchLayer.refresh() }
                        }

                        // The level, drawn only across the row it applies to. A line spanning the
                        // whole plot would read as a threshold on every channel.
                        Item {
                            visible: catchLayer.onScreen
                            y: catchLayer.levelY
                            width: parent.width

                            Repeater {
                                // During the first layout pass the pane can briefly report a
                                // negative available width. Repeater rejects a negative integer
                                // model (once per viewer); zero is the correct empty geometry.
                                model: Math.max(0, Math.ceil(catchLayer.width / 10))

                                Rectangle {
                                    required property int index
                                    x: index * 10
                                    width: 6
                                    height: 1
                                    color: "#e2b843"
                                    opacity: 0.85
                                }
                            }

                            // Which way through the level counts, shown where the level is rather
                            // than only in a settings panel three clicks away.
                            Text {
                                x: 4
                                y: -implicitHeight - 1
                                text: {
                                    var arrow = ["↑", "↓", "↕"][plot.catchEdge] || "↕"
                                    var m = plot.channelModel
                                    if (!m || plot.catchChannel < 0)
                                        return arrow
                                    // The level is in base units; the row shows a prefixed unit.
                                    // Take the exponent the row itself resolved to rather than
                                    // deriving one -- rowInfo's range has already been divided by
                                    // it, so re-deriving from that scaled it a second time.
                                    var idx = m.index(plot.catchChannel, 0)
                                    var exp = m.data(idx, ChannelModel.UnitExponentRole)
                                    return arrow + " "
                                           + Number(plot.catchLevel / Math.pow(10, exp)).toPrecision(3)
                                           + " " + m.data(idx, ChannelModel.UnitRole)
                                }
                                color: "#e2b843"
                                font.pixelSize: 9
                            }
                        }

                        // A 1 px dashed line is not a grab target. The handle is, and so is the
                        // 11 px band around the line.
                        MouseArea {
                            id: levelDrag
                            visible: catchLayer.onScreen
                            x: 0
                            y: catchLayer.levelY - 5
                            width: parent.width
                            height: 11
                            cursorShape: Qt.SizeVerCursor
                            hoverEnabled: true
                            preventStealing: true

                            onPositionChanged: {
                                if (!pressed || catchLayer.row < 0)
                                    return
                                var v = plot.rowYToValue(catchLayer.row, y + mouse.y)
                                if (!isNaN(v))
                                    plot.catchLevel = v
                            }

                            // The edge lives on the line rather than in a panel: the line is
                            // where the direction is visible, and it is already the thing you
                            // reach for to set the level.
                            onDoubleClicked: plot.cycleCatchEdge()

                            ToolTip.visible: containsMouse && !pressed
                            ToolTip.text: "Drag to set the catch level · double-click to cycle "
                                          + "rising / falling / either"

                            Rectangle {
                                x: parent.width - 15
                                y: 0
                                width: 14
                                height: 11
                                radius: 2
                                color: levelDrag.pressed || levelDrag.containsMouse
                                       ? "#f2cf6a" : "#e2b843"

                                Text {
                                    anchors.centerIn: parent
                                    text: "T"
                                    color: "#101010"
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }
                        }

                        // The level is set but its row is scrolled off the page, or the level is
                        // outside the row's range. Silence here would look like a broken feature.
                        Rectangle {
                            visible: !catchLayer.onScreen
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 2
                            width: offLabel.implicitWidth + 8
                            height: offLabel.implicitHeight + 4
                            color: Qt.rgba(0, 0, 0, 0.8)
                            border.color: "#e2b843"
                            radius: 2

                            Text {
                                id: offLabel
                                anchors.centerIn: parent
                                color: "#e2b843"
                                font.pixelSize: 10
                                text: catchLayer.row < 0
                                      ? "catch source is not on this page"
                                      : "catch level is off this row's scale"
                            }
                        }
                    }

                    // Where the crossing landed. Kept separate from the level layer: it stays up
                    // while the window fills, when the level line may not even be on the page.
                    Item {
                        visible: plot.catchMarkPosition >= 0
                        x: plot.catchMarkPosition * overlay.width
                        width: 1
                        height: overlay.height
                        z: 4

                        Rectangle {
                            width: 1
                            height: parent.height
                            color: "#7ec97e"
                        }

                        Rectangle {
                            x: 1
                            y: 0
                            width: markLabel.implicitWidth + 6
                            height: markLabel.implicitHeight + 2
                            color: Qt.rgba(0, 0, 0, 0.75)

                            Text {
                                id: markLabel
                                anchors.centerIn: parent
                                text: "catch"
                                color: "#7ec97e"
                                font.pixelSize: 9
                            }
                        }
                    }

                    // --- measurement ------------------------------------------------------
                    // A 1 px line is not a grab target, which is why the first version could be
                    // switched on but not operated. Each cursor now carries a labelled handle at
                    // the top of the plot, and the whole 14 px column around the line drags it.
                    Item {
                        id: measure
                        anchors.fill: parent
                        visible: plot_root_window.measuring
                        z: 5

                        // Cursors live on the *time axis*, as a fraction of the window, and their
                        // pixel positions are derived from that. Storing pixels instead anchored
                        // them to the window rather than to the data: resizing slid them off the
                        // samples they had been placed on, and narrowing the window pushed them
                        // outside it entirely. A fraction is also always on screen by
                        // construction, so they cannot be lost.
                        property real aPos: 0.35
                        property real bPos: 0.65

                        readonly property real aX: aPos * width
                        readonly property real bX: bPos * width
                        readonly property real seconds: Math.abs(bPos - aPos) * plot.duration

                        function timeOf(pos) { return pos * plot.duration }

                        Component.onCompleted: plot_root_window.measureLayerLoaded = measure
                        onAPosChanged: plot_root_window.refreshMeasureStats()
                        onBPosChanged: plot_root_window.refreshMeasureStats()

                        Rectangle {
                            x: Math.min(measure.aX, measure.bX)
                            width: Math.abs(measure.bX - measure.aX)
                            height: measure.height
                            color: "#40c0ff"
                            opacity: 0.08
                        }

                        Repeater {
                            model: 2

                            Item {
                                id: cursor
                                required property int index
                                readonly property bool isA: index === 0
                                readonly property color tint: isA ? "#40c0ff" : "#ff60a0"

                                x: (isA ? measure.aX : measure.bX) - width / 2
                                width: 14
                                height: measure.height

                                Rectangle {
                                    x: cursor.width / 2
                                    width: 1
                                    height: parent.height
                                    color: cursor.tint
                                }

                                Rectangle {
                                    width: 14
                                    height: 13
                                    radius: 2
                                    color: cursor.tint

                                    Text {
                                        anchors.centerIn: parent
                                        text: cursor.isA ? "A" : "B"
                                        color: "#101010"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }

                                // The time this cursor is sitting on. Stays put across a resize,
                                // which is the whole point of holding the position as a fraction.
                                Text {
                                    y: 14
                                    x: cursor.isA ? -implicitWidth - 2 : cursor.width + 2
                                    text: measure.timeOf(cursor.isA ? measure.aPos : measure.bPos)
                                          .toFixed(3) + " s"
                                    color: cursor.tint
                                    font.pixelSize: 9
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.SizeHorCursor
                                    onPositionChanged: {
                                        if (!pressed)
                                            return
                                        var w = Math.max(1, measure.width)
                                        var pos = Math.max(0, Math.min(1, (cursor.x + mouse.x) / w))
                                        if (cursor.isA)
                                            measure.aPos = pos
                                        else
                                            measure.bPos = pos
                                    }
                                }
                            }
                        }

                        Rectangle {
                            x: Math.min(measure.aX, measure.bX)
                            y: 15
                            width: deltaText.implicitWidth + 8
                            height: deltaText.implicitHeight + 4
                            color: Qt.rgba(0, 0, 0, 0.8)
                            border.color: "#40c0ff"
                            radius: 2

                            Text {
                                id: deltaText
                                anchors.centerIn: parent
                                color: "white"
                                font.pixelSize: 11
                                text: measure.seconds > 0
                                      ? ("Δ " + (measure.seconds * 1000).toFixed(1) + " ms   "
                                         + (1 / measure.seconds).toFixed(2) + " Hz")
                                      : "drag A and B"
                            }
                        }
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        property var readout: null

                        onPositionChanged: readoutTimer.restart()
                        onExited: readout = null

                        onClicked: {
                            plot_root_window.forceActiveFocus()
                            if (mouse.button === Qt.RightButton) {
                                var p = mapToItem(plot_root_window, mouse.x, mouse.y)
                                plot_root_window.openSettingsAt(p.x, p.y)
                            }
                        }

                        onWheel: {
                            if (wheel.modifiers & Qt.ControlModifier)
                                settings.axis_time_max *= wheel.angleDelta.y > 0 ? 0.8 : 1.25
                            else if (wheel.modifiers & Qt.ShiftModifier)
                                plot_root_window.scaleBy(wheel.angleDelta.y > 0 ? 0.8 : 1.25)
                            else
                                plot_root_window.scrollRows(wheel.angleDelta.y > 0 ? -1 : 1)
                            wheel.accepted = true
                        }
                    }

                    // Reading every row on every mouse move is wasted work at 70 rows; the value
                    // under the pointer is what anyone actually wants.
                    Timer {
                        id: readoutTimer
                        interval: 40
                        repeat: false
                        onTriggered: {
                            if (!hover.containsMouse || plot.drawnRows <= 0) {
                                hover.readout = null
                                return
                            }
                            var all = plot.readoutAt(hover.mouseX / Math.max(1, overlay.width))
                            var idx = -1
                            if (settings.stacked) {
                                // Every trace shares the lane, so the row cannot be read off the
                                // pointer's height. Pick the trace the pointer is nearest to,
                                // which is the one being asked about.
                                var best = 1e9
                                for (var i = 0; i < all.length; ++i) {
                                    if (!all[i].valid || all[i].bit >= 0)
                                        continue
                                    var y = plot.rowValueToY(all[i].row, all[i].baseValue)
                                    if (isNaN(y))
                                        continue
                                    var d = Math.abs(y - hover.mouseY)
                                    if (d < best) { best = d; idx = i }
                                }
                            } else {
                                idx = Math.floor(hover.mouseY / plotContainer.swimlane)
                            }
                            hover.readout = (idx >= 0 && idx < all.length) ? all[idx] : null
                        }
                    }

                    Rectangle {
                        visible: hover.containsMouse && hover.readout !== null
                        x: Math.min(hover.mouseX + 12, overlay.width - width - 2)
                        y: Math.min(hover.mouseY + 12, overlay.height - height - 2)
                        width: readoutText.implicitWidth + 10
                        height: readoutText.implicitHeight + 6
                        color: Qt.rgba(0, 0, 0, 0.82)
                        border.color: "#707070"
                        radius: 3

                        Text {
                            id: readoutText
                            anchors.centerIn: parent
                            color: "white"
                            font.pixelSize: 11
                            text: {
                                if (!hover.readout)
                                    return ""
                                var r = hover.readout
                                var t = plot.timeAt(hover.mouseX / Math.max(1, overlay.width))
                                if (!r.valid)
                                    return r.name + ": no data\n" + t.toFixed(3) + " s"
                                var v = (r.bit >= 0)
                                        ? ("bit " + r.bit + " = " + r.value)
                                        : (Number(r.value).toPrecision(4) + " " + r.unit)
                                return r.name + ": " + v + "\n" + t.toFixed(3) + " s"
                            }
                        }
                    }
                }

                ScrollBar {
                    id: vScroll
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 11
                    policy: plot.channelRows > plot.drawnRows ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    orientation: Qt.Vertical
                    size: plot.channelRows > 0 ? plot.drawnRows / plot.channelRows : 1
                    position: plot.channelRows > 0 ? plot.firstRow / plot.channelRows : 0
                    onPositionChanged: {
                        if (pressed && plot.channelRows > 0)
                            plot.firstRow = Math.round(position * plot.channelRows)
                    }
                }

                Canvas { id: plotOverlay; visible: false; width: 1; height: 1 }
            }

        // --- time ruler, inside the plot column so it can never point at the wrong place -----
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 16

            Item {
                id: ruler
                anchors.left: parent.left
                anchors.leftMargin: gutter.width
                anchors.right: parent.right
                anchors.rightMargin: vScroll.width
                height: parent.height

                property var ticks: []
                function rebuild() { ticks = plot.timeGrid(width) }

                onWidthChanged: rebuild()
                Component.onCompleted: rebuild()
                Connections {
                    target: plot
                    function onDurationChanged() { ruler.rebuild() }
                }

                Repeater {
                    model: ruler.ticks

                    Item {
                        required property var modelData
                        visible: modelData.major
                        x: modelData.x * ruler.width
                        height: ruler.height

                        Text {
                            x: 2
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label + " s"
                            color: plot_root_window.plotInk
                            font.pixelSize: 10
                        }
                        Rectangle { width: 1; height: 4; color: "#707070" }
                    }
                }

                // No measurement readout here. It duplicated the box already sitting between the
                // cursors and overprinted the second labels.
            }
        }

            } // plot column

            // ⭐ The interpolated field. Mutually exclusive with the discs above -- see
            // @ref headFieldMode -- and fed one BASE-unit number per channel rather than reading
            // the stream itself, which is what lets the epoch viewer feed the same panel a single
            // sample at a cursor with no branch inside it.
            TopoPanel {
                id: headField
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: settings.head_mode && plot_root_window.headFieldMode

                channelModel: plot.channelModel
                settings: settings
                values: plot_root_window.headFieldValues

                // ⭐ What the numbers are, in the caption. A mean is not an instant, and a
                // map that does not say which it is invites being read as the wrong one.
                headline: "mean of the last "
                        + Number(settings.head_average_seconds).toFixed(1) + " s"

                // Right-click reaches the same setup panel as it does over the traces.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: {
                        var p = mapToItem(plot_root_window, mouse.x, mouse.y)
                        plot_root_window.openSettingsAt(p.x, p.y)
                    }
                }
            }

            HeadView {
                id: headView
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: settings.head_mode && !plot_root_window.headFieldMode
                plot: plot
                settings: settings

                // Right-click reaches the same setup panel as it does over the traces, which is
                // where the thresholds are.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: {
                        var p = mapToItem(plot_root_window, mouse.x, mouse.y)
                        plot_root_window.openSettingsAt(p.x, p.y)
                    }
                }
            }

            ChannelPanel {
                Layout.preferredWidth: 285
                Layout.minimumWidth: 240
                Layout.fillHeight: true
                visible: plot_root_window.showChannelPanel
                channelModel: plot.channelModel
                plot: plot
            }
        }

        // --- decoded trigger events -----------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            visible: plot.events.length > 0
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 4

                Label {
                    text: "Events"
                    font.pixelSize: 10
                    opacity: 0.6
                }

                ListView {
                    id: eventList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    spacing: 6
                    clip: true
                    model: plot.events

                    delegate: Rectangle {
                        required property var modelData
                        height: eventList.height - 2
                        width: label.implicitWidth + 10
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            id: label
                            anchors.centerIn: parent
                            color: "#d0d0d0"
                            font.pixelSize: 10
                            text: modelData.name + " = " + modelData.value
                        }
                        ToolTip.visible: evHover.hovered
                        ToolTip.text: "was " + modelData.previous + ", bits changed 0x"
                                      + modelData.changed.toString(16) + "\nrtc " + modelData.rtc
                        HoverHandler { id: evHover }
                    }
                }

                Button {
                    text: "Clear"
                    padding: 3
                    font.pixelSize: 10
                    focusPolicy: Qt.NoFocus
                    onClicked: plot.clearEvents()
                }
            }
        }
    }

    // --- context menu on a channel name -------------------------------------------------------
    Menu {
        id: rowMenu
        property int channel: -1

        MenuItem {
            text: "Show only this"
            onTriggered: plot.channelModel.soloSelection()
        }
        MenuItem {
            text: "Hide"
            onTriggered: plot.channelModel.setSelectionVisible(false)
        }
        MenuItem {
            text: "Show all"
            onTriggered: plot.channelModel.showAll()
        }
        MenuSeparator {}
        // Every flag needs its inverse here, or the menu becomes a one-way trip: it could mark a
        // channel bad and offered no way to take it back.
        MenuItem {
            text: "Mark bad"
            onTriggered: plot.channelModel.setSelectionBad(true)
        }
        MenuItem {
            text: "Mark good"
            onTriggered: plot.channelModel.setSelectionBad(false)
        }
        MenuItem {
            text: "Bypass filter"
            onTriggered: plot.channelModel.setSelectionFilterBypass(true)
        }
        MenuItem {
            text: "Apply filter"
            onTriggered: plot.channelModel.setSelectionFilterBypass(false)
        }
        MenuSeparator {}
        MenuItem {
            text: "Draw as bits"
            onTriggered: plot.channelModel.setSelectionRenderMode(ChannelModel.Bits)
        }
        MenuItem {
            text: "Draw as steps"
            onTriggered: plot.channelModel.setSelectionRenderMode(ChannelModel.Step)
        }
        MenuItem {
            text: "Draw as line"
            onTriggered: plot.channelModel.setSelectionRenderMode(ChannelModel.Line)
        }
        MenuSeparator {}
        MenuItem {
            text: "Autoscale these"
            onTriggered: plot.channelModel.setSelectionScaleMode(ChannelModel.AutoScale)
        }
        MenuItem {
            text: "Follow group scale"
            onTriggered: plot.channelModel.setSelectionScaleMode(ChannelModel.GroupScale)
        }
    }

    // --- settings ---------------------------------------------------------------------------
    Popup {
        id: settingsPopup
        parent: plot_root_window
        // x and y are assigned by openSettingsAt() rather than bound, so the panel appears where
        // it was asked for instead of always at one edge.
        width: 300
        height: Math.min(plot_root_window.height - 30, 720)
        padding: 0
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape

        PlotSettings {
            anchors.fill: parent
            plot: plot
            settings: settings
        }
    }
}
