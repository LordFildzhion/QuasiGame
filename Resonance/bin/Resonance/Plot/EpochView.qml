import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Resonance 3.0
import Resonance.Plot 3.0

/**
 * The epoch viewer -- ONE stimulus-locked window drawn across the full plot width and replaced
 * whole, with t=0 marked and a ruler that reads negative before the stimulus.
 *
 * A deliberate SMALL SIBLING of PlotView, not a copy of it. It borrows the same four pieces --
 * toolbar, channel gutter, plot area, time ruler -- and leaves out everything an epoch does not
 * need at this stage: no rubber-band zoom, no measurement cursors, no catch, no scalp map, no
 * channel panel, no settings popup, no trigger-event strip. Those either belong to a scrolling
 * sweep (the write cursor, the catch) or are later stages.
 *
 * WHAT IT DOES NOT OWN. The persisted @ref Settings object is handed in from outside rather than
 * created here: the sweep and the epoch view are two windows onto one connector, and a second
 * Settings would mean a second service parameter with the same name. Sharing it also means the
 * montage, the colours and the background follow the operator from one view to the other, which
 * is what they expect from what is nominally the same viewer.
 *
 * Channel state is READ from those settings and never written back. PlotView owns the write-back
 * timer; two models writing one key would fight, and this view has no channel panel to edit
 * anything with anyway.
 *
 * Qt Quick Controls 2 throughout. Every control is one of the Compact* wrappers, because the
 * Default style floors a Button at 100x40 px through its BACKGROUND -- font and padding tuning
 * alone leaves it that size.
 */
Item {
    id: epoch_root

    property alias sourceInfo: plot.sourceInfo
    property alias plot: plot

    /**
     * ⭐ PUBLISHING (Stage 6). The names this viewer publishes its average and its epochs under,
     * pushed DOWN from StreamView, which owns the two service parameters. Empty publishes
     * nothing, which is the default.
     *
     * ⚠ ONE WAY. This view does not own the parameters -- an output stream name has to be
     * restorable from a saved configuration and settable by another service, which means a
     * parameter, and parameters are declared where the connector is. So the buttons on the
     * average bar ASK, through @ref publishToggled, and the answer comes back as a new value on
     * these properties.
     */
    property string publishAverageName: ""
    property string publishEpochsName: ""

    /// The operator clicked one of the publish buttons. @p which is "average" or "epochs"; the
    /// handler decides the name, because the per-viewer prefix lives up there.
    signal publishToggled(string which)

    /**
     * The scalp map, exposed for the same reason @ref plot is: so it can be interrogated rather
     * than merely photographed.
     *
     * TopoPanel already publishes its TopoView as `topo`, which carries sampleGrid(), layoutInfo(),
     * electrodes() and fieldAt() -- the numeric half of "does this match EEGLAB". Without a way
     * through the EpochView those are reachable only from inside this file, and a harness is left
     * comparing pictures by eye, which is exactly how a transposed or mirrored field survives.
     */
    property alias headPanel: headPanel

    /**
     * The head-shaped array of per-electrode epoch traces, exposed for the same reason
     * @ref headPanel is.
     *
     * EpochGridPanel publishes its EpochGridView as `grid`, which carries cells(), cellInfo(),
     * layoutInfo(), channelAt() and plotToItem() -- the numeric half of "is this electrode where
     * the topoplot puts it". ⭐ That equality is the whole argument for the two renderings sharing
     * `TopoPlot::topoLayout`, and it is meant to be ASSERTED: without a way through the EpochView
     * a harness is left comparing two pictures by eye, which is exactly how a rotated or mirrored
     * head survives, since both still look like a head full of traces.
     */
    property alias gridPanel: gridPanel

    /**
     * The viewer's persisted settings, owned by the PlotView next to this one.
     *
     * Null is tolerated everywhere below -- the object is assigned by the embedding StreamView and
     * a binding can evaluate before that has happened -- so every read is guarded rather than
     * assumed.
     */
    property Settings settings: null

    // =============================================================================================
    // THE TIME CURSOR
    // =============================================================================================

    /**
     * ⭐ Where the cursor sits, as a LATENCY IN MILLISECONDS relative to the stimulus.
     *
     * ⚠ NOT PIXELS. The sweep's measure cursors hold a FRACTION of the time window for a
     * measured reason: pixels anchored a cursor to the window rather than to the data, so resizing
     * slid it off the samples it had been placed on and narrowing the window pushed it outside
     * entirely. Every rule that argument produces holds here -- nothing below ever stores an x.
     *
     * It goes one step further than a fraction, because an epoch has a coordinate a sweep does
     * not: a fraction is resize-proof but not WINDOW-proof, and this axis changes shape under a
     * live connection -- `reconnect` drops the type from the request, so the same connector can
     * reattach to a stream with a different pre-stimulus interval, and a producer that declares no
     * end edge sets the axis length per block. A fraction would then quietly move the cursor to a
     * different latency while the operator was looking at it. A latency is what they chose, so a
     * latency is what is kept; the drawn fraction is derived from it and re-derived whenever the
     * window moves.
     *
     * ⚠ Always CLAMPED into the window that actually exists, and the clamp is CAPTIONED rather
     * than hidden -- see @ref cursorColumn and @ref cursorWarning. Nothing here silently relocates
     * a time the operator asked for.
     */
    property real cursorMs: 0

    /**
     * What was asked for, before the clamp, or NaN when the cursor was placed by dragging.
     *
     * Kept apart from @ref cursorMs so the caption can say "you asked for +900, this window ends
     * at +400" -- and so a requested time that is outside a SHORT window comes back when a longer
     * one arrives, instead of being permanently rounded down to the old window's edge.
     */
    property real cursorRequestMs: NaN

    /**
     * Everything EpochReceiver::columnAtMs reported for the cursor: the clamped time, the window
     * that clamped it, the sample, and one BASE-unit reading per CHANNEL INDEX.
     *
     * Recomputed, never bound: columnAtMs is a plain call and a binding cannot know that a new
     * epoch landed under it. @ref refreshCursor is wired to every signal that can move it.
     */
    property var cursorColumn: null

    /// The cursor's position across the plot, 0..1. DERIVED -- assigning to it is what
    /// @ref setCursorFraction is for.
    readonly property real cursorPos: {
        var col = cursorColumn
        if (!col || !(col.spanMs > 0))
            return 0.5
        // ⚠ spanMs, NOT highMs - lowMs. The painter draws sample s at s * width / samples,
        // so the window is one sample longer than the interval between the first and last
        // readable instants; dividing by that interval instead would leave the cursor line one
        // sample's width away from the sample it is quoting at the right-hand end.
        return Math.max(0, Math.min(1, (cursorMs - col.lowMs) / col.spanMs))
    }

    /// True when there is an epoch under the cursor at all.
    readonly property bool cursorReady: cursorColumn !== null && cursorColumn.samples > 0

    /**
     * Place the cursor from a drag, given a fraction of the plot width.
     *
     * The fraction is turned into milliseconds IMMEDIATELY and the milliseconds are what is
     * stored: the round trip is linear and exact, so nothing drifts, and the cursor survives the
     * next window change as the latency it was put on.
     */
    function setCursorFraction(f) {
        var pos = Math.max(0, Math.min(1, f))
        cursorRequestMs = NaN
        cursorMs = plot.timeAt(pos)
        refreshCursor()
        writeCursorBack()
    }

    /**
     * Place the cursor at a time. The one entry point for a typed latency, a restored setting and
     * -- once the viewers are linked -- another viewer's cursor.
     *
     * ⚠ The clamp happens in C++, against the samples that actually arrived, and the
     * requested value is REMEMBERED rather than overwritten. See @ref cursorRequestMs.
     */
    function setCursorMs(ms) {
        if (!isFinite(ms))
            return
        cursorRequestMs = ms
        var col = plot.columnAtMs(ms)
        cursorColumn = col
        cursorMs = col.ms
        writeCursorBack()
    }

    /// Re-read the column under the cursor, holding the LATENCY still. Called whenever a new
    /// epoch lands or the window changes shape.
    function refreshCursor() {
        var want = isFinite(cursorRequestMs) ? cursorRequestMs : cursorMs
        var col = plot.columnAtMs(want)
        cursorColumn = col
        cursorMs = col.ms
    }

    /**
     * Persist the latency, coalesced.
     *
     * ⚠ Through a timer, never straight from the drag. Settings.changed() re-serialises the
     * whole blob into a service parameter, and a parameter write schedules a full
     * service-description re-serialisation; doing that on every mouse move is how a drag turns
     * into a stutter.
     */
    function writeCursorBack() { cursorSaveTimer.restart() }

    property Timer cursorSaveTimer: Timer {
        interval: 400
        onTriggered: {
            if (epoch_root.settings
                    && epoch_root.settings.epoch_cursor_ms !== epoch_root.cursorMs)
                epoch_root.settings.epoch_cursor_ms = epoch_root.cursorMs
        }
    }

    /**
     * A note from whatever is driving this cursor from OUTSIDE this viewer.
     *
     * Set by the embedding StreamView when the cross-viewer link is on, and empty otherwise. It
     * carries the things only the link can know: which viewer the time came from, and how the two
     * streams differ. Kept as a plain string rather than computed here, because this file has no
     * business knowing another viewer exists.
     */
    property string cursorNote: ""

    /// The clamp, said out loud, quoting the window THAT EXISTS rather than the number that was
    /// asked for. Empty when nothing was clamped.
    readonly property string cursorWarning: {
        var col = cursorColumn
        // ⚠ Only for a time somebody ASKED for -- typed, restored, or arriving from the
        // linked viewer. A drag cannot request a time outside the window; all it can do is land
        // in the half-sample tail past the last reading, and captioning that as a clamp would
        // put a warning on the screen every time the cursor was dragged to the end.
        if (!col || !col.clamped || !col.epoched || !isFinite(cursorRequestMs))
            return ""
        return "asked for " + msText(col.requestedMs) + " ms — this window holds "
             + msText(col.lowMs) + " … " + msText(col.highMs) + " ms, so the map is at "
             + msText(col.ms) + " ms"
    }

    /**
     * Move the cursor by whole SAMPLES.
     *
     * The only step that means anything: the epoch is not interpolated in time, so a sub-sample
     * latency would name an instant nothing was ever measured at, and the map drawn there would be
     * the neighbouring sample wearing a more precise label.
     */
    function nudgeCursor(samples) {
        var col = cursorColumn
        if (!col || !(col.rate > 0))
            return
        setCursorMs(cursorMs + samples * 1000 / col.rate)
    }

    // =============================================================================================
    // HEAD MODE
    // =============================================================================================

    /**
     * Does this stream carry electrode positions at all?
     *
     * A plain property refreshed by hand, not a binding: hasHeadLayout() is an invokable, and QML
     * has no way to know the montage arrived. A toggle that switches to an empty panel teaches the
     * operator the feature is broken, so the button is disabled until this is true.
     */
    property bool hasMontage: false

    function refreshMontage() {
        hasMontage = plot.channelModel ? plot.channelModel.hasHeadLayout() : false
    }

    /**
     * ⭐ The scalp map instead of the traces, sharing the sweep's `head_mode` setting.
     *
     * Shared deliberately: it is the same viewer and the same question -- "show me this montage on
     * a head" -- and a key of its own would let one viewer's two views disagree about it. Gated on
     * @ref hasMontage so a stream with no positions can never land on a blank panel.
     *
     * ⚠ The epoch viewer draws the FIELD or the TRACE ARRAY and never the discs, whatever
     * `head_view` says. The disc map is an impedance instrument: it reads a running mean of a
     * continuous stream over `head_average_seconds`, which an epoch -- one window, replaced whole
     * -- does not have. The sweep offers discs-or-field because those are the two answers that
     * exist over there; this view offers field-or-traces for the same reason.
     */
    readonly property bool headMode:
        settings !== null && settings.head_mode && hasMontage

    /**
     * ⭐ WHICH head rendering: the interpolated field, or the array of per-electrode traces.
     *
     * MUTUALLY EXCLUSIVE, through the SAME `head_view` key the sweep's discs/field selector uses,
     * because they are three answers to one question -- "show me this montage on a head" -- and a
     * key each would let one viewer's renderings disagree about which of them is showing.
     *
     * Anything this file does not recognise, INCLUDING a settings blob written before "traces"
     * existed and including the sweep's "discs", reads as the FIELD: that is what this viewer has
     * shown since head mode reached it, so an old configuration opens looking exactly as it did.
     *
     * ⭐ THE TWO RENDERINGS PUT AN ELECTRODE IN THE SAME PLACE. EpochGridView lays its cells out
     * through `TopoPlot::topoLayout` -- the same squeezed (py, px), the same plotrad and
     * squeezefac, the same cartoon head -- as TopoView interpolates its field over. Switching
     * between them is exactly what an operator does with this button, and a second projection
     * would slide every electrode under them while they did it. Asserted numerically rather than
     * inspected: see `R:\\config\\epoch_grid_numbers.qml`.
     */
    readonly property bool headTraceMode:
        settings !== null && settings.head_view === "traces"

    Connections {
        target: plot
        // The window can change under a live connection, and where no end edge was declared the
        // axis length is a per-block fact. Both land here, and both must leave the LATENCY alone.
        function onEpochGeometryChanged() {
            epoch_root.refreshCursor()
            epoch_root.refreshMontage()
        }
        function onEpochReceived(samples) {
            epoch_root.refreshCursor()
            epoch_root.refreshRejected()
            epoch_root.refreshEpochList()
        }
        // A rejection, a reset, a method change or an eviction all move what is on screen and
        // what the list says about it, with no block having arrived.
        function onAverageChanged() {
            // The field reads its numbers through columnAtMs, which reads the display source, so
            // a new average changes the map as surely as a new epoch does.
            epoch_root.refreshCursor()
            epoch_root.refreshRejected()
            epoch_root.refreshEpochList()
        }
        function onDisplaySourceChanged() { epoch_root.refreshCursor() }
    }

    onListVisibleChanged: refreshEpochList()

    Connections {
        target: plot.channelModel
        function onCountChanged() { epoch_root.refreshMontage() }
        function onGroupsChanged() { epoch_root.refreshMontage() }
    }

    // =============================================================================================
    // AVERAGING
    // =============================================================================================

    /// The four methods, in the order the button cycles them. All four are required; none of them
    /// is a fallback for another.
    readonly property var averageMethods: ["mean", "median", "trimmean10", "trimmean20"]

    function methodLabel(m) {
        switch (m) {
        case "median":     return "Median"
        case "trimmean10": return "Trim 10%"
        case "trimmean20": return "Trim 20%"
        }
        return "Mean"
    }

    /// Show the epoch list beside the plot. Persisted, so a viewer opens the way it was left.
    readonly property bool listVisible: settings !== null && settings.epoch_list_visible

    /**
     * Cycle: all conditions → each label in turn → all conditions.
     *
     * ⚠ "All conditions" and the DEFAULT BIN are different answers, and both are in the cycle.
     * The default bin is where an unlabelled epoch lands; it is a real condition, and it is only
     * the same as "all" while nothing carries a marker.
     */
    function cycleBin() {
        if (!settings)
            return
        var labels = plot.binLabels
        if (labels.length === 0)
            return
        if (plot.averageAllBins) {
            settings.epoch_average_all_bins = false
            settings.epoch_average_bin = labels[0]
            return
        }
        var i = labels.indexOf(plot.averageBin)
        if (i < 0 || i + 1 >= labels.length) {
            settings.epoch_average_all_bins = true
            return
        }
        settings.epoch_average_bin = labels[i + 1]
    }

    /**
     * Is the epoch on screen flagged out of the averages?
     *
     * A plain property refreshed by hand, not a binding: isEpochRejected is an invokable, and QML
     * has no way to know a flag moved. Same pattern as @ref hasMontage.
     */
    property bool currentRejected: false
    function refreshRejected() {
        currentRejected = plot.epochCount > 0 && plot.isEpochRejected(plot.epochSerial)
    }

    /// The held epochs, newest first, for the list. Re-read rather than bound, for the reason
    /// above; @ref listVisible gates it so nothing is built for a list nobody is looking at.
    property var epochRows: []
    function refreshEpochList() {
        epochRows = listVisible ? plot.epochList(200) : []
        picked = plot.selectedSerials().length
    }

    /// How many epochs have been picked out explicitly. 0 means the running average.
    property int picked: 0

    /**
     * Add or remove one epoch from the explicit pick.
     *
     * An explicit pick is a more explicit act than the running average: it ignores the rejection
     * flag, and it is combined in ascending serial order however it was clicked.
     */
    function togglePicked(serial) {
        var list = plot.selectedSerials()
        var i = list.indexOf(serial)
        if (i >= 0)
            list.splice(i, 1)
        else
            list.push(serial)
        plot.setSelectedSerials(list)
        // A pick that is not being drawn is a control that visibly does nothing, so picking one
        // switches the display source to the average it just described.
        if (settings && list.length > 0 && !settings.epoch_average_show)
            settings.epoch_average_show = true
        refreshEpochList()
    }

    /// Bytes as MB, to one decimal above a megabyte and to three below it.
    function mbText(bytes) {
        return (bytes / 1048576).toFixed(bytes > 1048576 ? 1 : 3)
    }

    // --- the retention notice -------------------------------------------------------------------
    //
    // ⭐ THE STORE NEVER EVICTS ON ITS OWN, so the operator has to be the one who decides. This is
    // that decision, and it is a strip with two buttons rather than a warning with none: a warning
    // that cannot be acted on is a warning that gets ignored. NOT a dialog and NOT repeated -- the
    // receiver fires once per crossing and re-arms only after a flush.

    /// Is the notice up? Raised by the crossing, lowered by Flush or by Keep.
    property bool retentionNoticeVisible: false
    /// What the crossing said, in MB, so the strip states the number that caused it rather than a
    /// number that has moved on since.
    property real retentionNoticeMB: 0
    property real retentionNoticeThresholdMB: 0
    property int retentionNoticeEpochs: 0
    /// The ceiling is a different sentence: growth has stopped and epochs ARE being dropped.
    property bool retentionNoticeIsCeiling: false

    Connections {
        target: plot
        function onRetentionThresholdCrossed(accountedMB, thresholdMB, epochs) {
            epoch_root.retentionNoticeMB = accountedMB
            epoch_root.retentionNoticeThresholdMB = thresholdMB
            epoch_root.retentionNoticeEpochs = epochs
            epoch_root.retentionNoticeIsCeiling = false
            epoch_root.retentionNoticeVisible = true
        }
        function onRetentionCeilingReached(epochs) {
            epoch_root.retentionNoticeMB = plot.bytesAccounted / 1048576
            epoch_root.retentionNoticeThresholdMB = plot.notifyThresholdMB
            epoch_root.retentionNoticeEpochs = epochs
            epoch_root.retentionNoticeIsCeiling = true
            epoch_root.retentionNoticeVisible = true
        }
    }

    /// One line of retention arithmetic, for the readouts that quote it: what is held, what it
    /// costs, and against what. ⚠ The arithmetic itself comes from the receiver — one source, so
    /// the banner, the tooltip and the status line cannot come to state different numbers.
    readonly property string retentionText: {
        var text = plot.retentionSummary
        if (plot.averageMismatched > 0) {
            text += " " + plot.averageMismatched + " held epochs are on a different time base "
                  + "and are excluded."
        }
        if (plot.accumulatorRebuilds > 1)
            text += " Running total rebuilt " + plot.accumulatorRebuilds + " times."
        return text
    }

    implicitHeight: 200
    focus: true

    // Controls 2's default metrics are sized for touch; this is a desktop instrument panel.
    readonly property int uiFontSize: 11

    readonly property color plotBackground: settings ? settings.background : "#000000"
    /// Ink for text drawn OVER the plot background. A fixed grey works on the black default and
    /// vanishes on a white one, and the background is a setting.
    readonly property bool lightPlot:
        0.299 * plotBackground.r + 0.587 * plotBackground.g + 0.114 * plotBackground.b > 0.5
    readonly property color plotInk: lightPlot ? "#505050" : "#909090"

    // --- settings <-> item ---------------------------------------------------------------------
    // Bound rather than assigned, so a settings load, a Configurator push and a local edit all end
    // up in the same place. `settings &&` on every one of them: see the property's note.
    Binding { target: plot; property: "lineWidth"
              value: settings ? settings.lineWidth : 1 }
    Binding { target: plot; property: "antialiasTraces"
              value: settings ? settings.antialias : true }
    // ⭐ CED trace colours. Needs a binding of its own even though this view shares the sweep's
    // Settings object: the two viewers own SEPARATE ChannelModels, so a mode set on one would
    // otherwise leave the other drawing the old palette and the operator switching between them
    // would see the colours change under the same setting.
    Binding { target: plot.channelModel; property: "traceColorMode"
              value: settings ? settings.trace_color_mode : "palette"
              when: plot.channelModel !== null }
    Binding { target: plot; property: "rowsPerPage"
              value: settings ? settings.rows_per_page : 0 }
    // ⭐ The butterfly. Shared with the sweep's "Stack" rather than given a key of its own: it is
    // the same C++ property and the same question -- "overlay every channel on one axis" -- and a
    // second key would make one viewer's two views disagree about it.
    Binding { target: plot; property: "stacked"
              value: settings ? settings.stacked : false }
    Binding { target: plot; property: "backgroundColor"
              value: settings ? settings.background : "#000000" }
    Binding { target: plot; property: "gridColor"
              value: settings ? settings.grid_color : "#3c3c3c" }
    Binding { target: plot; property: "zeroLineColor"
              value: settings ? settings.grid_middleLine_color : "#6e6e5a" }
    Binding { target: plot; property: "showGrid"
              value: settings ? settings.grid_visible : true }
    Binding { target: plot; property: "showZeroLine"
              value: settings ? settings.grid_middleLine_visible : true }

    // --- averaging (Stage 4) -------------------------------------------------------------------
    // ⭐ ONE display source for the traces, the field and the trace array. Every one of them
    // reads EpochReceiver::displayChannel, so switching rendering never switches what is shown.
    Binding { target: plot; property: "showAverage"
              value: settings ? settings.epoch_average_show : false }
    Binding { target: plot; property: "averageMethod"
              value: settings ? settings.epoch_average_method : "mean" }
    Binding { target: plot; property: "averageAll"
              value: settings ? settings.epoch_average_all : true }
    Binding { target: plot; property: "averageWindow"
              value: settings ? settings.epoch_average_window : 100 }
    Binding { target: plot; property: "averageAllBins"
              value: settings ? settings.epoch_average_all_bins : true }
    Binding { target: plot; property: "averageBin"
              value: settings ? settings.epoch_average_bin : "" }

    // --- ⭐ stimulus attribution and the stimulus-grouped display -------------------------------
    //
    // ⚠ The latency is a Binding and not a one-way write, so that reloading a session restores
    // the number that decided its conditions. A latency nobody recorded is a session whose
    // conditions nobody can reconstruct.
    Binding { target: plot; property: "attributionEnabled"
              value: settings ? settings.epoch_attribution_enabled : false }
    Binding { target: plot; property: "perceptionLatencyMs"
              value: settings ? settings.epoch_perception_latency_ms : 150 }
    Binding { target: plot; property: "groupedByStimulus"
              value: settings ? settings.epoch_grouped_by_stimulus : false }
    // Empty string means every type present, which is why the split guards against it: "".split(",")
    // is [""], and a one-entry list naming a type that does not exist draws nothing at all.
    Binding { target: plot; property: "shownStimulusTypes"
              value: (settings && settings.epoch_shown_stimulus_types.length > 0)
                     ? settings.epoch_shown_stimulus_types.split(",") : [] }
    // ⚠ RETENTION IS UNCAPPED AND THIS KEY IS NOW THE NOTIFY THRESHOLD, in MB. Stage 4 spelled a
    // hard cap here; the ring now grows as epochs arrive and never evicts on its own, and this is
    // the point at which it says so once and keeps going.
    //
    // ⚠ THE KEY IS ONLY HONOURED WHERE IT LOOKS LIKE A THRESHOLD SOMEBODY SET. 512 was the
    // Stage 4 cap default, and anything under 16 MB is what a cap experiment left behind (the
    // harnesses wrote 1.5 to force eviction); neither was ever a threshold, so both fall back to
    // the 2048 MB the operator asked for. Any other value is taken as written.
    Binding { target: plot; property: "notifyThresholdMB"
              value: (settings && settings.epoch_budget_mb >= 16
                               && settings.epoch_budget_mb !== 512)
                     ? settings.epoch_budget_mb : 2048 }

    // --- publishing (Stage 6) --------------------------------------------------------------------
    // ⭐ The NAMES come from service parameters (see the class note) and the counters from the
    // settings blob. Bound rather than assigned so a Configurator push, a restored configuration
    // and a click on the bar all land in the same place.
    Binding { target: plot; property: "publishAverageName"
              value: epoch_root.publishAverageName }
    Binding { target: plot; property: "publishEpochsName"
              value: epoch_root.publishEpochsName }
    Binding { target: plot; property: "publishCounters"
              value: settings ? settings.epoch_publish_counters : true }

    // Channel appearance, one way only. See the class note.
    function loadChannelState() {
        if (settings && settings.channel_state !== "")
            plot.channelModel.stateJson = settings.channel_state
    }

    /// The saved latency, applied once when the settings object arrives. Through setCursorMs, so
    /// a latency saved against a longer window is clamped and captioned like any other.
    function loadCursor() {
        if (settings && isFinite(settings.epoch_cursor_ms))
            setCursorMs(settings.epoch_cursor_ms)
        else
            refreshCursor()
    }

    Component.onCompleted: { loadChannelState(); loadCursor(); refreshMontage() }
    onSettingsChanged: { loadChannelState(); loadCursor() }

    Connections {
        target: epoch_root.settings
        function onChannel_stateChanged() { epoch_root.loadChannelState() }

        /**
         * ⚠ A restored configuration arrives LATE.
         *
         * `--serviceConfig` is applied after constructors, so the settings blob's own value
         * changes long after Component.onCompleted has been and gone: without this the saved
         * latency would be written but never read back.
         *
         * It cannot loop with the write-back. writeCursorBack only assigns when the key differs
         * from `cursorMs`, and this only applies when it differs from `cursorMs`, so the two can
         * never take turns.
         */
        function onEpoch_cursor_msChanged() {
            if (epoch_root.settings
                    && epoch_root.settings.epoch_cursor_ms !== epoch_root.cursorMs)
                epoch_root.setCursorMs(epoch_root.settings.epoch_cursor_ms)
        }
    }

    // --- caption ---------------------------------------------------------------------------------

    /// "-100" / "+400", the way an epoch window is quoted. The sign is explicit on the positive
    /// side so the pre-stimulus interval reads as the negative one it is.
    function msText(v) {
        if (v === undefined || v === null || !isFinite(v))
            return "?"
        var s = Math.abs(v) >= 10 ? Number(v).toFixed(0) : Number(v).toFixed(1)
        // toFixed can produce "-0"; the stimulus instant is 0, not minus zero.
        if (Number(s) === 0)
            s = "0"
        return (Number(s) > 0 ? "+" : "") + s
    }

    /**
     * What is on screen, in words.
     *
     * ⭐ When the producer declared no window this says "t0 unknown" out loud. Drawing an
     * undeclared epoch from 0 with a ruler that looks authoritative is how a viewer teaches an
     * operator a latency that is not there.
     */
    readonly property string captionText: {
        if (!plot.active)
            return "no stream"
        if (plot.channels <= 0)
            return "connecting…"

        // ⭐ WHICH KIND OF EPOCH THIS IS. Producer-cut and viewer-cut are drawn identically and
        // averaged identically, and whose alignment the operator is trusting depends entirely on
        // the answer -- so it leads the caption rather than hiding in a tooltip.
        var origin = plot.epochOrigin === "viewer" ? "viewer-cut"
                   : plot.epochOrigin === "stream" ? "producer-cut" : ""

        // ⭐ WHAT IS ON SCREEN, from the item itself: "epoch #12" or "average, n = 41". n is
        // `contributing` -- the epochs actually in the reduction -- and never `received`.
        var head = plot.epochCount > 0 ? plot.displayCaption
                                       : "waiting for the first epoch"
        if (origin !== "")
            head = origin + " · " + head
        var body = plot.channels + " ch · " + Number(plot.rate).toFixed(0) + " Hz · "
                 + plot.samples + " samples"

        var win
        if (!plot.epoched) {
            win = "t0 unknown — no window_start_ms; the axis reads sample offsets, not latencies"
        } else {
            win = msText(plot.timeOriginMs) + " .. " + msText(plot.windowEndMs) + " ms"
            if (!plot.windowEndDeclared)
                win += " (end taken from the delivered length; none was declared)"
            if (!plot.uniformWindow)
                win += " · channels declare different windows"
            if (!plot.lengthInvariantHolds)
                win += " · ⚠ declared window disagrees with the delivered length"
        }

        var tail = []
        if (plot.epochKind !== "")
            tail.push(plot.epochKind)
        if (plot.epochStage !== "")
            tail.push(plot.epochStage)
        if (plot.epochStamp !== "")
            tail.push("t0=" + plot.epochStamp)

        // ⭐ The cursor is part of what is on screen, so it is part of what the caption
        // says. A map or a readout with no time on it is an assertion about a moment nobody named.
        var cur = ""
        if (cursorReady) {
            cur = " · cursor " + (plot.epoched
                        ? msText(cursorMs) + " ms"
                        : "sample " + cursorColumn.sample)
        }
        // Quoted from the CLAMPED range, never from the number that was asked for.
        var clamp = cursorWarning !== "" ? " · ⚠ " + cursorWarning : ""
        var note = cursorNote !== "" ? " · " + cursorNote : ""

        // ⭐ THE REFUSAL COUNT. A refused trigger produces no epoch, which looks exactly like no
        // trigger at all -- and one means "check the window", the other "check the cable".
        var cut = plot.cutSummary !== "" ? " · " + plot.cutSummary : ""

        // ⭐ WHAT IS GOING OUT ON THE NETWORK, on the caption rather than in a tooltip. The line
        // carries the rebuild count, which is the only way to see from here that "publish once,
        // send many" is holding -- a stream whose port is moving under its consumers is
        // otherwise completely invisible to the operator producing it.
        var pub = plot.publishStatus !== "" ? " · " + plot.publishStatus : ""

        return head + " · " + body + " · " + win
             + (tail.length > 0 ? " · " + tail.join("/") : "")
             + cur + clamp + note + cut + pub
    }

    // --- keyboard ----------------------------------------------------------------------------
    // The same letters as the sweep, so muscle memory carries across. Only the ones that mean
    // something here.
    Keys.onPressed: {
        switch (event.key) {
        case Qt.Key_P:        plot.frozen = !plot.frozen; event.accepted = true; break
        case Qt.Key_F:        plot.fitNow(); event.accepted = true; break
        case Qt.Key_K:        if (settings) { settings.stacked = !settings.stacked }
                              event.accepted = true; break
        // The average, and the operator's judgement on the epoch in front of them. Two keys,
        // because these are the two things done repeatedly while watching a run.
        case Qt.Key_A:        if (settings) { settings.epoch_average_show = !plot.showAverage }
                              event.accepted = true; break
        case Qt.Key_R:        plot.toggleRejectedCurrent(); event.accepted = true; break
        case Qt.Key_PageDown: plot.firstRow = plot.firstRow + plot.drawnRows; event.accepted = true; break
        case Qt.Key_PageUp:   plot.firstRow = plot.firstRow - plot.drawnRows; event.accepted = true; break
        case Qt.Key_Home:     plot.firstRow = 0; event.accepted = true; break
        // The scalp map, on the same letter the sweep uses.
        case Qt.Key_H:        if (epoch_root.hasMontage && settings) {
                                  settings.head_mode = !settings.head_mode
                                  event.accepted = true
                              }
                              break
        // Whole samples, and Shift for ten of them. The sweep spends the arrows on the time
        // range; an epoch's window is the producer's to choose, so they are free here and go to
        // the one thing this viewer lets the operator move.
        case Qt.Key_Left:     nudgeCursor((event.modifiers & Qt.ShiftModifier) ? -10 : -1)
                              event.accepted = true; break
        case Qt.Key_Right:    nudgeCursor((event.modifiers & Qt.ShiftModifier) ? 10 : 1)
                              event.accepted = true; break
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        // --- toolbar -------------------------------------------------------------------------
        // Inside a Pane so the chrome carries its own background: sitting directly on the plot's
        // dark background the default control palette renders near-black on near-black. Clipped,
        // so a narrow viewer can never draw its toolbar over the one beside it.
        Pane {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            padding: 2
            font.pixelSize: epoch_root.uiFontSize
            clip: true

            RowLayout {
                anchors.fill: parent
                spacing: 2

                CompactButton {
                    text: plot.frozen ? "Run" : "Hold"
                    implicitHeight: 19
                    highlighted: plot.frozen
                    ToolTip.visible: hovered
                    ToolTip.text: "Stop replacing the epoch on screen without touching the stream "
                                + "(P). Epochs that arrive while held are counted, not drawn."
                    onClicked: plot.frozen = !plot.frozen
                }

                CompactButton {
                    text: "Fit"
                    implicitHeight: 19
                    ToolTip.visible: hovered
                    ToolTip.text: "Fit each group's scale to what is on screen, once, and leave "
                                + "it fixed there (F)"
                    onClicked: plot.fitNow()
                }

                CompactButton {
                    text: "Butterfly"
                    implicitHeight: 19
                    // Deliberately NOT `checkable`. A checkable Button assigns its own `checked`
                    // on click, which overwrites the binding on it -- and this setting is shared
                    // with the sweep's "Stack", so it can change without this button being the
                    // one that changed it. `highlighted` is a plain property and keeps following.
                    highlighted: epoch_root.settings ? epoch_root.settings.stacked : false
                    enabled: epoch_root.settings !== null
                    ToolTip.visible: hovered
                    ToolTip.text: "Every channel on one axis instead of a lane each (K)."
                    onClicked: {
                        if (epoch_root.settings)
                            epoch_root.settings.stacked = !epoch_root.settings.stacked
                    }
                }

                CompactButton {
                    text: "Head"
                    implicitHeight: 19
                    // NOT `checkable`, for the reason the Butterfly button gives: a checkable
                    // Button assigns its own `checked` on click and overwrites the binding, and
                    // this setting is shared with the sweep, so it can change while this button is
                    // not the one that changed it.
                    highlighted: epoch_root.headMode
                    enabled: epoch_root.hasMontage && epoch_root.settings !== null
                    ToolTip.visible: hovered
                    ToolTip.text: epoch_root.hasMontage
                        ? "The scalp map instead of the traces (H). EEG channels only, at the "
                          + "cursor's sample; the cursor moves on the strip below the map."
                        : "This stream carries no electrode positions. The driver needs a .ced "
                          + "montage."
                    onClicked: {
                        if (epoch_root.settings)
                            epoch_root.settings.head_mode = !epoch_root.settings.head_mode
                    }
                }

                CompactButton {
                    // ⭐ Field or trace array, one click, and only while the map is up: a control
                    // for a panel that is not on screen is clutter. The sweep's sibling of this
                    // button chooses discs-or-field; both write the one `head_view` key.
                    text: epoch_root.headTraceMode ? "Traces" : "Field"
                    implicitHeight: 19
                    visible: epoch_root.headMode
                    // NOT `checkable`, for the reason the two buttons before it give: a checkable
                    // Button assigns its own `checked` on click and overwrites the binding, and
                    // this setting is shared with the sweep.
                    highlighted: epoch_root.headTraceMode
                    accentColor: "#7fb3d5"
                    ToolTip.visible: hovered
                    ToolTip.text: epoch_root.headTraceMode
                        ? "Showing a trace per electrode, all on one shared amplitude. Click for "
                          + "the interpolated field at the cursor."
                        : "Showing the interpolated field at the cursor. Click for the whole "
                          + "window as a trace per electrode."
                    onClicked: {
                        if (epoch_root.settings)
                            epoch_root.settings.head_view =
                                    epoch_root.headTraceMode ? "field" : "traces"
                    }
                }

                ToolSeparator { padding: 1; implicitHeight: 18 }

                // ⭐ The latency, typeable. Dragging is how a cursor is placed; typing is how
                // it is placed at the number a paper quotes. Out-of-window values are clamped in
                // C++ and the clamp is captioned -- nothing here rejects a time silently.
                NumberField {
                    label: "t"
                    labelWidth: 8
                    suffix: plot.epoched ? "ms" : "smp"
                    suffixWidth: 22
                    fieldWidth: 58
                    decimals: 1
                    stepSize: 1
                    minimumValue: -1e7
                    maximumValue: 1e7
                    enabled: epoch_root.cursorReady
                    value: epoch_root.cursorMs
                    // ⚠ Through a HoverHandler, never `ToolTip.visible: hovered`: a NumberField
                    // is a RowLayout and has no `hovered`, so that binding throws a
                    // ReferenceError and the description never appears. 🐞 D1 found it.
                    ToolTip.visible: cursorFieldHover.hovered
                    ToolTip.text: "Cursor latency in ms relative to the stimulus, negative "
                                + "before it. Arrow keys step one sample, Shift ten."
                    HoverHandler { id: cursorFieldHover }
                    onEdited: epoch_root.setCursorMs(value)
                }

                ToolSeparator { padding: 1; implicitHeight: 18 }

                Label {
                    text: plot.epoched ? "epoched" : "no window declared"
                    color: plot.epoched ? "#7ad07a" : "#d0a020"
                    font.pixelSize: 11
                    ToolTip.visible: epochedHover.hovered
                    ToolTip.text: plot.epoched
                        ? "The stream publishes window_start_ms on every channel, so t=0 on the "
                          + "ruler is the stimulus instant."
                        : "This stream publishes no well-formed window_start_ms, so where the "
                          + "stimulus falls inside the block is unknown."
                    HoverHandler { id: epochedHover }
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
                    // ⭐ BOTH CLOCKS. lastPaintMs times the painter; lastIngestMs times taking an
                    // epoch in, which since Stage 4 includes the average -- and the average runs
                    // on this thread.
                    text: plot.lastIngestMs.toFixed(1) + " / " + plot.lastPaintMs.toFixed(1)
                          + " ms"
                    font.pixelSize: 11
                    opacity: 0.55
                    ToolTip.visible: paintHover.hovered
                    ToolTip.text: "Ingest / paint. Ingest is the transpose into the store plus "
                                + "the average: mean " + plot.meanIngestMs.toFixed(2)
                                + " ms, worst " + plot.maxIngestMs.toFixed(2) + " ms over "
                                + plot.ingestCount + " epochs. Paint is a full redraw."
                    HoverHandler { id: paintHover }
                }
            }
        }

        // --- the average bar ---------------------------------------------------------------------
        // ⭐ WHAT IS BEING SHOWN, and everything that changes it. Every rendering below honours
        // this row: the traces, the interpolated field and the head trace array all draw the
        // receiver's display source.
        Pane {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            padding: 2
            font.pixelSize: epoch_root.uiFontSize
            clip: true
            visible: plot.active

            RowLayout {
                anchors.fill: parent
                spacing: 2

                CompactButton {
                    text: plot.showAverage ? "Average" : "Epoch"
                    implicitHeight: 19
                    highlighted: plot.showAverage
                    accentColor: "#9ecf9e"
                    enabled: epoch_root.settings !== null
                    ToolTip.visible: hovered
                    ToolTip.text: plot.showAverage
                        ? "Showing the average (A). Click to show each epoch as it arrives."
                        : "Showing each epoch as it arrives (A). Click to show the average."
                    onClicked: {
                        if (epoch_root.settings)
                            epoch_root.settings.epoch_average_show = !plot.showAverage
                    }
                }

                CompactButton {
                    text: epoch_root.methodLabel(plot.averageMethod)
                    implicitHeight: 19
                    visible: plot.showAverage
                    enabled: epoch_root.settings !== null
                    ToolTip.visible: hovered
                    // Terse and factual, and the one number worth knowing: where a trimmed mean
                    // stops differing from the mean.
                    ToolTip.text: "Averaging method (click to cycle). The percentage is the total "
                                + "removed, half from each end. Below 20 epochs Trim 10% equals "
                                + "the mean; below 10, so does Trim 20%."
                    onClicked: {
                        if (!epoch_root.settings)
                            return
                        var list = epoch_root.averageMethods
                        var i = list.indexOf(plot.averageMethod)
                        epoch_root.settings.epoch_average_method =
                                list[(i + 1 + list.length) % list.length]
                    }
                }

                CompactButton {
                    text: plot.averageAll ? "All" : ("Last " + plot.averageWindow)
                    implicitHeight: 19
                    visible: plot.showAverage
                    enabled: epoch_root.settings !== null
                    ToolTip.visible: hovered
                    ToolTip.text: "All epochs since the last reset, or the last N ACCEPTED ones "
                                + "— rejected epochs are skipped, not counted."
                    onClicked: {
                        if (epoch_root.settings)
                            epoch_root.settings.epoch_average_all = !plot.averageAll
                    }
                }

                NumberField {
                    label: "N"
                    labelWidth: 10
                    fieldWidth: 46
                    decimals: 0
                    stepSize: 10
                    minimumValue: 1
                    maximumValue: 100000
                    visible: plot.showAverage && !plot.averageAll
                    value: plot.averageWindow
                    onEdited: {
                        if (epoch_root.settings)
                            epoch_root.settings.epoch_average_window = Math.round(value)
                    }
                }

                // The condition, only once there is more than one. With no marker stream every
                // epoch lands in the default bin and there is nothing to choose between.
                CompactButton {
                    text: plot.averageAllBins
                          ? "All conditions"
                          : (plot.averageBin === "" ? "(unlabelled)" : plot.averageBin)
                    implicitHeight: 19
                    visible: plot.showAverage && plot.binLabels.length > 1
                    enabled: epoch_root.settings !== null
                    ToolTip.visible: hovered
                    ToolTip.text: "Which condition is averaged (click to cycle). "
                                + plot.binLabels.length + " seen since the last reset."
                    onClicked: epoch_root.cycleBin()
                }

                ToolSeparator { padding: 1; implicitHeight: 18 }

                // --- ⭐ stimulus attribution ------------------------------------------------
                // D1: what the control does and what the number is. No rationale on the bar —
                // the basis for 150 ms is in the tooltip, where it can be read once.

                CompactButton {
                    text: "By stimulus"
                    implicitHeight: 19
                    highlighted: plot.groupedByStimulus
                    accentColor: "#f0b43c"
                    enabled: epoch_root.settings !== null
                    ToolTip.visible: hovered
                    ToolTip.text: "One trace per stimulus type, each averaged over its own bin. "
                                + "ISI, welcome, end and the run edges are excluded — "
                                + plot.excludedEpochs + " epochs held are excluded now."
                    onClicked: {
                        if (epoch_root.settings) {
                            epoch_root.settings.epoch_grouped_by_stimulus =
                                    !plot.groupedByStimulus
                        }
                    }
                }

                CompactButton {
                    text: "Attribute"
                    implicitHeight: 19
                    highlighted: plot.attributionEnabled
                    accentColor: "#f0b43c"
                    enabled: epoch_root.settings !== null
                    ToolTip.visible: hovered
                    ToolTip.text: "Label epochs from the stimulus service's cue and pulse "
                                + "events instead of from the marker stream. " + (
                                    plot.attributionEnabled
                                    ? plot.attributionSummary
                                    : "Off: labels come from the marker stream.")
                    onClicked: {
                        if (epoch_root.settings) {
                            epoch_root.settings.epoch_attribution_enabled =
                                    !plot.attributionEnabled
                        }
                    }
                }

                NumberField {
                    label: "Perception"
                    suffix: "ms"
                    decimals: 0
                    stepSize: 10
                    minimumValue: 0
                    maximumValue: 2000
                    fieldWidth: 46
                    visible: plot.attributionEnabled
                    value: plot.perceptionLatencyMs
                    // ⚠ A HoverHandler, not `hovered`: NumberField is a RowLayout and has no such
                    // property, and a binding to an undefined name is a binding-loop-shaped
                    // warning that nobody would connect to this control.
                    HoverHandler { id: latencyHover }
                    ToolTip.visible: latencyHover.hovered
                    ToolTip.text: "A pulse landing less than this after a cue onset is "
                                + "attributed to the interval BEFORE it. 150 ms is the earliest "
                                + "latency at which a visual cue's identity is influencing the "
                                + "brain (Thorpe, Fize & Marlot, Nature 1996). Lower it for an "
                                + "auditory cue. Saved with the session and written into the "
                                + "published stream."
                    onEdited: {
                        if (epoch_root.settings)
                            epoch_root.settings.epoch_perception_latency_ms = value
                    }
                }

                // The types on screen, with n each. Read-only: the selection is the caption's
                // job and the button above turns the mode on. ⚠ It shows the EXCLUDED count too,
                // because a count nobody can see is how an operator ends up believing an average
                // has more in it than it does.
                Label {
                    visible: plot.groupedByStimulus
                    color: "#f0b43c"
                    font.pixelSize: 11
                    text: plot.drawnStimulusTypes.length === 0
                          ? "no type yet"
                          : (plot.drawnStimulusTypes.length + " types, "
                             + plot.excludedEpochs + " excluded")
                    ToolTip.visible: typeHover.hovered
                    ToolTip.text: plot.displayCaption
                    HoverHandler { id: typeHover }
                }

                ToolSeparator { padding: 1; implicitHeight: 18 }

                CompactButton {
                    text: "Reset"
                    implicitHeight: 19
                    ToolTip.visible: hovered
                    ToolTip.text: "Drop every stored epoch and start the average again. The "
                                + "method, the window and the montage are kept."
                    onClicked: plot.resetAverage()
                }

                CompactButton {
                    text: epoch_root.currentRejected ? "Un-reject" : "Reject"
                    implicitHeight: 19
                    // A rejection is per epoch, so it needs an epoch on screen to act on.
                    enabled: !plot.showAverage && plot.epochCount > 0
                    accentColor: "#e0a0a0"
                    highlighted: epoch_root.currentRejected
                    ToolTip.visible: hovered
                    ToolTip.text: "Flag the epoch on screen out of the averages, or put it back "
                                + "(R). The epoch itself is kept either way."
                    onClicked: plot.toggleRejectedCurrent()
                }

                ToolSeparator { padding: 1; implicitHeight: 18 }

                // --- publishing (Stage 6) ---------------------------------------------------
                // ⭐ OFF BY DEFAULT AND VISIBLY SO. A viewer that had started producing without
                // the operator knowing would be a surprise on the network, so the two buttons
                // stay on the bar whether or not anything is being published, and light up when
                // it is. D1: what they do, and the name on the wire. No rationale.
                CompactButton {
                    text: "Pub avg"
                    implicitHeight: 19
                    highlighted: plot.publishingAverage
                    accentColor: "#9ecfd6"
                    ToolTip.visible: hovered
                    ToolTip.text: plot.publishAverageName === ""
                        ? "Publish the running average as an output stream."
                        : ("Publishing the running average as '" + plot.publishAverageName
                           + "'. Click to stop.")
                    onClicked: epoch_root.publishToggled("average")
                }

                CompactButton {
                    text: "Pub epochs"
                    implicitHeight: 19
                    highlighted: plot.publishingEpochs
                    accentColor: "#9ecfd6"
                    ToolTip.visible: hovered
                    ToolTip.text: plot.publishEpochsName === ""
                        ? "Publish each epoch as an output stream, as it is stored."
                        : ("Publishing each epoch as '" + plot.publishEpochsName
                           + "'. Click to stop.")
                    onClicked: epoch_root.publishToggled("epochs")
                }

                ToolSeparator { padding: 1; implicitHeight: 18 }

                CompactButton {
                    text: "List"
                    implicitHeight: 19
                    highlighted: epoch_root.listVisible
                    enabled: epoch_root.settings !== null
                    ToolTip.visible: hovered
                    ToolTip.text: "The held epochs, newest first. Click one to pick it for an "
                                + "average of its own; Ctrl-click rejects it."
                    onClicked: {
                        if (epoch_root.settings)
                            epoch_root.settings.epoch_list_visible = !epoch_root.listVisible
                    }
                }

                Item { Layout.fillWidth: true }

                // ⭐ n, AND WHERE IT CAME FROM. `contributing` is the plot's n; `received` is
                // what was taken in. They differ the moment anything is rejected or evicted, and
                // showing only one of them is how a run bar and a plot end up disagreeing.
                Label {
                    text: plot.showAverage
                          ? ("n = " + plot.averageContributing + " of "
                             + plot.averageReceived + " received")
                          : (plot.acceptedEpochs + " held"
                             + (plot.rejectedEpochs > 0
                                ? (" · " + plot.rejectedEpochs + " rejected") : ""))
                    font.pixelSize: 11
                    color: plot.evicting ? "#d0a020" : palette.text
                    opacity: 0.9
                    ToolTip.visible: nHover.hovered
                    ToolTip.text: epoch_root.retentionText
                    HoverHandler { id: nHover }
                }

                // ⭐ RESIDENT AGAINST THE THRESHOLD, which is what the number means now: the ring
                // grows and nothing is dropped, so a capacity is no longer the operator's limit.
                // A hard cap, if one is set, says so instead. D1: no rationale, just the numbers.
                Label {
                    text: {
                        var held = epoch_root.mbText(plot.bytesAccounted)
                        if (plot.retentionMode !== "uncapped")
                            return held + " MB · cap " + plot.historyCapacity
                        if (plot.notifyThresholdMB <= 0)
                            return held + " MB"
                        return held + " / " + Number(plot.notifyThresholdMB).toFixed(0) + " MB"
                    }
                    font.pixelSize: 11
                    color: (plot.overThreshold || plot.ceilingReached || plot.evicting)
                           ? "#d0a020" : palette.text
                    opacity: 0.7
                    ToolTip.visible: capHover2.hovered
                    ToolTip.text: epoch_root.retentionText
                    HoverHandler { id: capHover2 }
                }
            }
        }

        // --- the retention notice ----------------------------------------------------------------
        // ⚠ A STRIP IN THE LAYOUT, not a popup: it pushes the plot down instead of covering it,
        // and acquisition carries on underneath either way. Two buttons, because the whole point
        // of the notice is that the decision is the operator's.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            // ⚠ AND the state it describes must still hold: a flush from anywhere -- this
            // button, the toolbar's Reset, a service -- clears overThreshold, so the notice goes
            // with it instead of lingering over a store that no longer matches it.
            visible: epoch_root.retentionNoticeVisible
                     && (plot.overThreshold || plot.ceilingReached)
            color: epoch_root.retentionNoticeIsCeiling ? "#4a2a18" : "#3a3418"
            border.color: "#d0a020"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 4
                spacing: 6

                // D1: terse and factual. What is held, against what, and what the store did --
                // which for the threshold is NOTHING, and saying so is the point.
                Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.pixelSize: 11
                    color: "#f0d890"
                    text: epoch_root.retentionNoticeIsCeiling
                          ? (plot.epochCeiling + "-epoch ceiling reached at "
                             + epoch_root.retentionNoticeMB.toFixed(0)
                             + " MB. The oldest epoch is now dropped for each one that arrives.")
                          : (epoch_root.retentionNoticeMB.toFixed(0) + " MB held, over the "
                             + epoch_root.retentionNoticeThresholdMB.toFixed(0) + " MB threshold. "
                             + epoch_root.retentionNoticeEpochs
                             + " epochs kept, none dropped.")
                    ToolTip.visible: noticeHover.hovered
                    ToolTip.text: epoch_root.retentionText
                    HoverHandler { id: noticeHover }
                }

                CompactButton {
                    text: "Flush"
                    implicitHeight: 19
                    // The primary action, and accentColor only shows on a highlighted button.
                    highlighted: true
                    accentColor: "#d0a020"
                    ToolTip.visible: hovered
                    ToolTip.text: "Drop every held epoch and start the average again. Frees the "
                                + "memory and re-arms this notice."
                    onClicked: {
                        plot.resetAverage()
                        epoch_root.retentionNoticeVisible = false
                        epoch_root.refreshEpochList()
                    }
                }

                CompactButton {
                    text: "Keep"
                    implicitHeight: 19
                    ToolTip.visible: hovered
                    ToolTip.text: "Keep every epoch and hide this. It comes back only after a "
                                + "flush."
                    onClicked: epoch_root.retentionNoticeVisible = false
                }
            }
        }

        // --- gutter + plot ---------------------------------------------------------------------
        Item {
            id: plotContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Head mode REPLACES the traces, the way it does in the sweep. What it must not
            // replace is the control that moves the cursor -- see cursorStrip below.
            visible: !epoch_root.headMode

            property int rows: Math.max(1, plot.drawnRows)
            /// Row pitch in the channel column. In the butterfly there is no lane to line a name
            /// up with, so the names become a plain list rather than one name per screen.
            property real gutterPitch: plot.stacked
                                       ? Math.min(16, height / rows) : height / rows

            // --- channel gutter ------------------------------------------------------------
            Rectangle {
                id: gutter
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: epoch_root.settings ? epoch_root.settings.gutter_width : 51
                color: epoch_root.plotBackground

                Column {
                    anchors.fill: parent

                    Repeater {
                        model: plot.drawnRows

                        Item {
                            id: gutterRow
                            required property int index

                            width: gutter.width
                            height: plotContainer.gutterPitch

                            // In the butterfly every visible row is drawn from row 0, so the
                            // paging offset must not be added -- it would name the traces wrong.
                            property int row: plot.stacked ? index : plot.firstRow + index
                            property var info: plot.rowInfo(row)

                            // rowInfo is a plain call, so it has to be re-read whenever anything
                            // that feeds it moves.
                            function refresh() { info = plot.rowInfo(gutterRow.row) }

                            Connections {
                                target: plot
                                function onRowsChanged() { gutterRow.refresh() }
                                function onStackedChanged() { gutterRow.refresh() }
                                function onEpochGeometryChanged() { gutterRow.refresh() }
                            }
                            Connections {
                                target: plot.channelModel
                                function onAppearanceChanged() { gutterRow.refresh() }
                                function onScalesChanged() { gutterRow.refresh() }
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
                                    font.pixelSize: Math.max(8, Math.min(13,
                                                             plotContainer.gutterPitch * 0.5))
                                    font.strikeout: gutterRow.info ? gutterRow.info.bad : false
                                    elide: Text.ElideRight
                                }

                                // The magnitude the trace is drawn at, without which a trace is a
                                // shape with no size. Only where there is room for it.
                                Text {
                                    width: parent.width
                                    visible: plotContainer.gutterPitch > 26 && gutterRow.info
                                    text: gutterRow.info
                                          ? ("±" + Number(gutterRow.info.range).toPrecision(3)
                                             + " " + gutterRow.info.unit)
                                          : ""
                                    color: epoch_root.plotInk
                                    font.pixelSize: Math.max(7, Math.min(10,
                                                             plotContainer.gutterPitch * 0.28))
                                    elide: Text.ElideRight
                                }

                                // ⚠ Named only when it differs from the ruler. The ruler is drawn
                                // for the window most channels declare, and a channel on a
                                // different one -- tepSoundService puts its MEP column 200 ms
                                // away from the EEG -- is drawn where it actually belongs. Saying
                                // so here is what stops that trace being read off the wrong axis.
                                Text {
                                    width: parent.width
                                    visible: plotContainer.gutterPitch > 26
                                             && gutterRow.info && gutterRow.info.window
                                             && gutterRow.info.window.known
                                             && gutterRow.info.window.startMs !== plot.timeOriginMs
                                    text: gutterRow.info && gutterRow.info.window
                                          ? (epoch_root.msText(gutterRow.info.window.startMs)
                                             + " ms")
                                          : ""
                                    color: "#d0a020"
                                    font.pixelSize: Math.max(7, Math.min(10,
                                                             plotContainer.gutterPitch * 0.26))
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    epoch_root.forceActiveFocus()
                                    var ch = gutterRow.info ? gutterRow.info.channel : -1
                                    if (ch < 0)
                                        return
                                    if (mouse.modifiers & Qt.ControlModifier)
                                        plot.channelModel.toggleSelection(ch)
                                    else if (mouse.modifiers & Qt.ShiftModifier)
                                        plot.channelModel.selectRange(ch)
                                    else
                                        plot.channelModel.selectOnly(ch)
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

                // Same divider as the sweep, driving the same setting: the channel column is a
                // property of the viewer, not of which view is on top of it.
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
                        if (!pressed || !epoch_root.settings)
                            return
                        epoch_root.settings.gutter_width = Math.round(
                                    Math.max(24, Math.min(260, pressWidth + mouseX)))
                    }
                    onDoubleClicked: {
                        if (epoch_root.settings)
                            epoch_root.settings.gutter_width = 51
                    }
                    ToolTip.visible: containsMouse && !pressed
                    ToolTip.text: "Drag to resize the channel column · double-click to reset"
                }
            }

            // --- the epoch ------------------------------------------------------------------
            // ⭐ One window across the FULL width, replaced whole when the next one arrives.
            // Background, grid, the t=0 marker and the traces are all painted by the item into one
            // image, so they cannot drift apart.
            EpochReceiver {
                id: plot

                anchors.left: gutter.right
                anchors.right: vScroll.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                reconnect: true
                // The stimulus instant, drawn by the item itself so it is registered with the
                // traces to the pixel rather than to whatever QML thinks the width is.
                showZeroMarker: true
            }

            // --- overlay ---------------------------------------------------------------------
            Item {
                id: overlay
                anchors.fill: plot

                // --- amplitude axis ----------------------------------------------------------
                // Only when one lane fills the plot -- which in this viewer is the butterfly, and
                // is exactly when an amplitude number is worth reading off. Sixty lanes of tick
                // labels is not an axis, it is noise.
                Item {
                    id: axisLayer
                    anchors.fill: parent
                    visible: plot.axisIsReadable && plot.drawnRows > 0
                    z: 3

                    property var ticks: []
                    /// Row index into the model, not the drawn index: in the butterfly every row
                    /// is drawn from 0, in lanes the page starts at firstRow.
                    property int axisRow: plot.stacked ? 0 : plot.firstRow

                    function rebuild() {
                        axisRow = plot.stacked ? 0 : plot.firstRow
                        ticks = plot.axisIsReadable
                                ? plot.amplitudeGrid(axisRow, plot.laneHeight()) : []
                    }

                    Component.onCompleted: rebuild()
                    onVisibleChanged: rebuild()
                    onHeightChanged: rebuild()

                    Connections {
                        target: plot
                        function onRowsChanged() { axisLayer.rebuild() }
                        function onStackedChanged() { axisLayer.rebuild() }
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
                            y: plot.laneCentre(axisLayer.axisRow - (plot.stacked ? 0 : plot.firstRow))
                               + modelData.dy - implicitHeight / 2
                            text: modelData.label
                            color: epoch_root.plotInk
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
                        color: epoch_root.plotInk
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                // --- hover crosshair ------------------------------------------------------
                // A latency is the thing an operator takes off an evoked response, so the one
                // readout this stage carries is where in the window the pointer is.
                Rectangle {
                    visible: hover.containsMouse
                    x: Math.round(hover.mouseX)
                    width: 1
                    height: overlay.height
                    color: "#ffffff"
                    opacity: 0.4
                    z: 4
                }

                Rectangle {
                    visible: hover.containsMouse && overlay.width > 0
                    z: 5
                    radius: 2
                    color: Qt.rgba(0, 0, 0, 0.72)
                    border.width: 1
                    border.color: "#606060"
                    width: hoverText.implicitWidth + 8
                    height: hoverText.implicitHeight + 4
                    // Flips to the other side of the cursor near the right edge, so the box is
                    // never half outside the plot.
                    x: Math.min(Math.max(0, hover.mouseX + 8), overlay.width - width)
                    y: 4

                    Text {
                        id: hoverText
                        anchors.centerIn: parent
                        color: "#e8e8e8"
                        font.pixelSize: 10
                        text: {
                            if (!hover.containsMouse || overlay.width <= 0)
                                return ""
                            var f = hover.mouseX / overlay.width
                            var ms = plot.timeAt(f)
                            if (!isFinite(ms))
                                return ""
                            return (plot.epoched ? epoch_root.msText(ms) + " ms"
                                                 : "sample " + plot.sampleAt(f))
                        }
                    }
                }

                // --- the time cursor ---------------------------------------------------
                // ⭐ A 1 px line is not a grab target. The sweep's first measurement layer
                // could be switched on but not operated for exactly that reason, so the line
                // carries a labelled handle and the whole 16 px column around it drags.
                //
                // ⚠ Nothing here stores an x. The drag reports a FRACTION of the width and
                // setCursorFraction turns it into a latency on the spot; the line's position is
                // derived back from that latency. See the note on `cursorMs`.
                Item {
                    id: timeCursor
                    anchors.fill: parent
                    z: 6
                    visible: epoch_root.cursorReady

                    readonly property color tint: "#ffd24a"
                    readonly property real px: epoch_root.cursorPos * width

                    Rectangle {
                        x: Math.round(timeCursor.px)
                        width: 1
                        height: timeCursor.height
                        color: timeCursor.tint
                    }

                    Item {
                        id: cursorHandle
                        x: Math.round(timeCursor.px) - width / 2
                        width: 16
                        height: timeCursor.height

                        Rectangle {
                            width: 16
                            height: 13
                            radius: 2
                            color: timeCursor.tint

                            Text {
                                anchors.centerIn: parent
                                text: "t"
                                color: "#101010"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.SizeHorCursor
                            preventStealing: true
                            onPositionChanged: {
                                if (!pressed)
                                    return
                                var w = Math.max(1, timeCursor.width)
                                epoch_root.setCursorFraction((cursorHandle.x + mouse.x) / w)
                            }
                        }
                    }

                    // The latency it is sitting on. Flips to the left of the line near the right
                    // edge, so the number is never half outside the plot.
                    Text {
                        id: cursorLabel
                        x: Math.max(0, Math.min(timeCursor.px + 5,
                                                timeCursor.width - implicitWidth - 1))
                        y: 15
                        text: plot.epoched
                              ? epoch_root.msText(epoch_root.cursorMs) + " ms"
                              : ("sample " + (epoch_root.cursorColumn
                                              ? epoch_root.cursorColumn.sample : 0))
                        color: timeCursor.tint
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    // A click anywhere on the plot puts the cursor there. The handle sits above
                    // this (z 6) and takes its own drag, so the two do not fight.
                    onClicked: {
                        epoch_root.forceActiveFocus()
                        if (overlay.width > 0)
                            epoch_root.setCursorFraction(mouse.x / overlay.width)
                    }
                }
            }

            ScrollBar {
                id: vScroll
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 11
                policy: plot.channelRows > plot.drawnRows ? ScrollBar.AlwaysOn
                                                          : ScrollBar.AlwaysOff
                orientation: Qt.Vertical
                size: plot.channelRows > 0 ? plot.drawnRows / plot.channelRows : 1
                position: plot.channelRows > 0 ? plot.firstRow / plot.channelRows : 0
                onPositionChanged: {
                    if (pressed && plot.channelRows > 0)
                        plot.firstRow = Math.round(position * plot.channelRows)
                }
            }
        }

        // --- the scalp map -----------------------------------------------------------------
        // ⭐ THE DELIVERABLE: EEGLAB's interpolated topoplot of THIS epoch at the instant
        // the cursor is on, EEG channels only, in base units, captioned with the time it
        // represents and how many channels got into the fit.
        TopoPanel {
            id: headPanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: epoch_root.headMode && !epoch_root.headTraceMode

            channelModel: plot.channelModel
            settings: epoch_root.settings

            // ⚠ Only while it is on screen. Every assignment re-solves and re-evaluates a
            // 200x200 grid, and doing that for a panel nobody is looking at is pure cost. The
            // empty list is also what draws nothing rather than a stale map when the traces come
            // back. `visible` is read here rather than `headMode` alone, so switching to the
            // trace array stops paying for the field as well as stops showing it.
            values: (headPanel.visible && epoch_root.cursorColumn)
                    ? epoch_root.cursorColumn.values : []

            // ⭐ The time this picture represents, in the caption, every time. The
            // contributing count comes from the item itself and is appended after this.
            headline: {
                // The SAME sentence the traces are captioned with: an epoch serial, or
                // "average, n = N". The map must never be less specific about what it is
                // drawing than the view the operator switched away from.
                var which = plot.epochCount > 0 ? plot.displayCaption : "no epoch yet"
                if (!epoch_root.cursorReady)
                    return which
                if (!plot.epoched) {
                    return which + " at sample " + epoch_root.cursorColumn.sample
                         + " — this stream declares no window_start_ms, so that is an offset "
                         + "into the block, not a latency"
                }
                return which + " at " + epoch_root.msText(epoch_root.cursorMs) + " ms"
            }

            // Quoted from the CLAMPED range. See EpochReceiver::columnAtMs. The link's own
            // note rides alongside it: a follower whose window cannot hold the source's latency
            // has to say both what it did and who asked.
            warning: [epoch_root.cursorWarning, epoch_root.cursorNote]
                     .filter(function (t) { return t !== "" }).join(" · ")
        }

        // --- the array of per-electrode traces ---------------------------------------------
        // ⭐ THE OTHER DELIVERABLE: the whole epoch at every electrode, each miniature trace at
        // that electrode's own scalp position and every cell on ONE shared amplitude — so a
        // response is read as a PLACE and not only as a shape.
        //
        // ⚠ The SAME positions the field above uses, because both go through
        // TopoPlot::topoLayout. That is not tidiness: this button is how an operator flips
        // between the two, and a second projection would move every electrode while they looked.
        EpochGridPanel {
            id: gridPanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: epoch_root.headMode && epoch_root.headTraceMode

            // The SAME receiver the trace panel draws from, handed over as an object rather than
            // as marshalled samples: the item reads the epoch buffer as channel-major float, and
            // the array and the traces can never end up showing two different epochs.
            receiver: plot
            channelModel: plot.channelModel
            settings: epoch_root.settings

            // ⭐ WHICH epoch, in the caption, every time — the one thing only this file knows.
            // The panel appends the item's own sentence: the shared amplitude, the span that was
            // actually painted, and how many channels got in.
            headline: {
                if (plot.epochCount <= 0)
                    return "no epoch yet"
                // The SAME sentence the traces and the field carry: an epoch serial, or
                // "average, n = N" with n the contributing count.
                return plot.displayCaption
            }

            // The array draws the WHOLE window, so the cursor's clamp is not its business — but
            // the LINK's note is: a follower whose window cannot hold the source's latency has to
            // say so wherever it is showing that window's contents.
            warning: epoch_root.cursorNote
        }

        // --- the cursor, when the traces are not on screen ---------------------------------
        // ⭐ Head mode replaces the traces and the cursor line goes with them — but the map
        // IS the cursor's readout, so losing the control that moves it is the one thing that must
        // not happen. Same latency, same setter, same clamp: a strip, not a second cursor.
        Item {
            id: cursorStrip
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            // ⚠ Only under the FIELD. The field is a single instant and this strip is the control
            // that chooses it, so losing it with the traces would leave the map unmoveable. The
            // trace array draws the whole window at once and nothing on screen would answer a
            // drag here — a control that visibly does nothing teaches the operator it is broken.
            visible: epoch_root.headMode && !epoch_root.headTraceMode && epoch_root.cursorReady

            Rectangle {
                id: track
                anchors.left: parent.left
                anchors.right: parent.right
                y: 6
                height: 5
                radius: 2
                color: epoch_root.lightPlot ? "#d0d0d0" : "#3a3a3a"

                // t=0, where the item itself puts it. Never recomputed here: the marker and the
                // ruler must agree, and two derivations of one number are two chances to disagree.
                Rectangle {
                    visible: plot.zeroPosition >= 0
                    x: plot.zeroPosition * track.width
                    y: -3
                    width: 1
                    height: 11
                    color: plot.zeroMarkerColor
                }
            }

            Rectangle {
                id: stripHandle
                x: epoch_root.cursorPos * track.width - width / 2
                y: 0
                width: 14
                height: 17
                radius: 2
                color: "#ffd24a"

                Text {
                    anchors.centerIn: parent
                    text: "t"
                    color: "#101010"
                    font.pixelSize: 9
                    font.bold: true
                }
            }

            Text {
                x: Math.max(0, Math.min(stripHandle.x + 18, cursorStrip.width - implicitWidth))
                y: 3
                text: plot.epoched
                      ? epoch_root.msText(epoch_root.cursorMs) + " ms"
                      : ("sample " + (epoch_root.cursorColumn
                                      ? epoch_root.cursorColumn.sample : 0))
                color: "#ffd24a"
                font.pixelSize: 10
            }

            // The window's own edges, so the strip is a ruler and not just a slider.
            Text {
                anchors.left: parent.left
                y: 16
                text: epoch_root.cursorColumn
                      ? epoch_root.msText(epoch_root.cursorColumn.lowMs) : ""
                color: epoch_root.plotInk
                font.pixelSize: 9
            }
            Text {
                anchors.right: parent.right
                y: 16
                text: epoch_root.cursorColumn
                      ? (epoch_root.msText(epoch_root.cursorColumn.highMs)
                         + (plot.epoched ? " ms" : "")) : ""
                color: epoch_root.plotInk
                font.pixelSize: 9
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeHorCursor
                preventStealing: true
                onPressed: epoch_root.setCursorFraction(mouse.x / Math.max(1, track.width))
                onPositionChanged: {
                    if (pressed)
                        epoch_root.setCursorFraction(mouse.x / Math.max(1, track.width))
                }
            }
        }

        // --- time ruler ------------------------------------------------------------------------
        // ⭐ In the plot's own column and with the plot's own margins, so a label can never point
        // at a place the trace is not. It reads NEGATIVE before the stimulus: t=0 is where the
        // stimulus happened, not where the block started.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 16
            visible: !epoch_root.headMode

            Item {
                id: ruler
                anchors.left: parent.left
                anchors.leftMargin: gutter.width
                anchors.right: parent.right
                anchors.rightMargin: vScroll.width
                height: parent.height

                property var ticks: []

                /// What the numbers on this ruler are counted in.
                readonly property string unitText: plot.epoched ? "ms" : "samples"

                /**
                 * Index of the RIGHTMOST tick that carries a label, or -1 if none does.
                 *
                 * The unit is drawn as part of that label rather than as a free-floating item
                 * anchored to the right edge. Anchoring it there put it on top of the last tick's
                 * label -- the window's closing edge is a tick, its label hangs to the right of
                 * it like every other, and at the right edge there is nothing to hang into: the
                 * ruler read "ms400" with the 400 half outside the plot. Both halves of that are
                 * fixed here, because they are the same fact: the last label needs the space the
                 * unit was sitting in, and it has to hang inwards.
                 */
                property int lastLabelled: -1

                function rebuild() {
                    ticks = plot.timeGrid(width)
                    var last = -1
                    for (var i = 0; i < ticks.length; ++i) {
                        var t = ticks[i]
                        if (t.major && (t.zero || (t.label !== undefined && t.label !== "")))
                            last = i
                    }
                    lastLabelled = last
                }

                onWidthChanged: rebuild()
                Component.onCompleted: rebuild()

                Connections {
                    target: plot
                    // The window can change under a live connection -- with reconnect the type is
                    // dropped from the request, so the same connector can reattach to a stream of
                    // a different shape -- and where no end edge was declared the axis length is a
                    // per-block fact. Both land here.
                    function onEpochGeometryChanged() { ruler.rebuild() }
                    function onEpochReceived(samples) { ruler.rebuild() }
                }

                Repeater {
                    model: ruler.ticks

                    Item {
                        required property var modelData
                        required property int index
                        visible: modelData.major
                        x: modelData.x * ruler.width
                        height: ruler.height

                        /// The last labelled tick carries the unit, so the ruler reads
                        /// "-100 -80 ... 360 400 ms" -- a ruler, rather than the list that
                        /// "-100 ms -80 ms" would be.
                        readonly property bool carriesUnit: index === ruler.lastLabelled

                        Rectangle {
                            width: 1
                            height: modelData.zero ? 8 : 4
                            color: modelData.zero ? plot.zeroMarkerColor : "#707070"
                        }

                        Text {
                            id: tickLabel
                            // Zero is centred under its own tick and named "0" whatever the tick
                            // step rounded it to. Everything else hangs to the RIGHT of its tick
                            // the way the sweep's ruler does -- except the last one, which has no
                            // room to the right and hangs inwards instead.
                            x: modelData.zero ? -implicitWidth / 2
                             : parent.carriesUnit ? -implicitWidth - 2
                             : 2
                            anchors.verticalCenter: parent.verticalCenter
                            text: (modelData.zero ? "0" : modelData.label)
                                  + (parent.carriesUnit ? " " + ruler.unitText : "")
                            color: modelData.zero ? plot.zeroMarkerColor : epoch_root.plotInk
                            font.pixelSize: 10
                            font.bold: modelData.zero
                        }
                    }
                }

                // Only when no tick carried it -- a degenerate axis with nothing labelled on it
                // still has to say what it is counting.
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: ruler.lastLabelled < 0
                    text: ruler.unitText
                    color: epoch_root.plotInk
                    font.pixelSize: 10
                    opacity: 0.8
                }
            }
        }

        // --- caption -----------------------------------------------------------------------------
        // What is on screen, said in words: which epoch, how many channels, at what rate, over what
        // window. An operator who cannot name what they are looking at cannot trust it.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 18
            color: "transparent"

            Label {
                anchors.fill: parent
                anchors.leftMargin: 3
                anchors.rightMargin: 3
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                font.pixelSize: 11
                opacity: 0.85
                color: plot.epoched ? palette.text : "#d0a020"
                text: epoch_root.captionText

                // The item's own one-line status carries anything the caption had to leave out.
                ToolTip.visible: captionHover.hovered
                ToolTip.text: plot.status
                HoverHandler { id: captionHover }
            }
        }
    }

    // =============================================================================================
    // THE EPOCH LIST
    // =============================================================================================
    //
    // ⭐ THE OPERATOR ASKED FOR THIS AS DESIRABLE, AND IT ONLY FITS AS AN OVERLAY. The panel is a
    // column of stacked full-width rows -- toolbar, average bar, view, ruler, caption -- and a
    // list column inside that layout would either be nested under one view (and vanish when the
    // operator switched to the head) or force the three views into a re-layout that cannot be
    // tested here. As a narrow overlay it is available over ALL THREE renderings, it is off by
    // default, and it takes no width from anything when it is off.
    //
    // ⚠ SERIALS, NOT ROWS. Every entry carries the epoch's serial and every action is by serial:
    // after the first eviction a list addressed by position names a different epoch, which is a
    // failure this viewer has already had once.
    Rectangle {
        id: epochListPanel
        visible: epoch_root.listVisible
        z: 10
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 52 // clear of the two toolbars
        anchors.bottomMargin: 20 // clear of the caption
        width: 104
        color: epoch_root.lightPlot ? Qt.rgba(1, 1, 1, 0.92) : Qt.rgba(0, 0, 0, 0.82)
        border.width: 1
        border.color: epoch_root.plotInk

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 2

            Label {
                Layout.fillWidth: true
                text: epoch_root.picked > 0 ? (epoch_root.picked + " picked") : "held epochs"
                font.pixelSize: 10
                color: epoch_root.plotInk
                elide: Text.ElideRight
            }

            ListView {
                id: epochList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: epoch_root.epochRows
                spacing: 0
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    required property var modelData
                    width: epochList.width
                    height: 15
                    color: modelData.selected ? Qt.rgba(0.30, 0.50, 0.75, 0.35)
                         : (modelData.serial === plot.epochSerial
                            ? Qt.rgba(0.5, 0.5, 0.5, 0.20) : "transparent")

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 3
                        verticalAlignment: Text.AlignVCenter
                        text: "#" + modelData.serial
                              + (modelData.label !== "" ? (" " + modelData.label) : "")
                        // Off the averaging time base is a different fact from rejected, and it
                        // is not the operator's doing, so it is not drawn as their decision.
                        color: !modelData.onKey ? "#d0a020" : epoch_root.plotInk
                        font.pixelSize: 10
                        font.strikeout: modelData.rejected
                        opacity: modelData.rejected ? 0.5 : 1
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            if (mouse.modifiers & Qt.ControlModifier)
                                plot.setEpochRejected(modelData.serial, !modelData.rejected)
                            else
                                epoch_root.togglePicked(modelData.serial)
                        }
                    }
                }
            }

            CompactButton {
                Layout.fillWidth: true
                implicitHeight: 17
                text: "Clear picks"
                visible: epoch_root.picked > 0
                ToolTip.visible: hovered
                ToolTip.text: "Go back to the running average."
                onClicked: plot.setSelectedSerials([])
            }
        }
    }
}
