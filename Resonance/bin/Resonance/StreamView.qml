import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Resonance 3.0
import Resonance.Plot 3.0

/**
 * A stream connector, the viewer for it, and -- when the stream carries messages rather than
 * samples -- a message log.
 *
 * There are two viewers, not one. A continuous stream is shown as a scrolling sweep (PlotView);
 * an EPOCH stream -- one stimulus-locked window per block, with a pre-stimulus interval -- is
 * shown as an epoch (EpochView), drawn across the full width and replaced whole. Which one
 * appears is decided by @ref declaresEpochWindow below, and can be overruled by the operator.
 *
 * Controls 2 throughout: this is the Configurator's window onto the viewer, and Controls 1 does
 * not exist in Qt 6.
 */
GroupBox {
    id: root
    title: "Viewer"
    padding: 3
    topPadding: collapsible ? 26 : 16
    property bool collapsible: false
    property bool collapsed: false
    signal collapseRequested(bool collapse)
    label: Row {
        Label { visible: !root.collapsible; text: root.title; font.pixelSize: 11; font.bold: true }
        ToolButton {
            visible: root.collapsible
            text: (root.collapsed ? "\u25b6  " : "\u25bc  ") + root.title
            font.pixelSize: 11; font.bold: true
            height: 24
            onClicked: root.collapseRequested(!root.collapsed)
        }
    }

    property alias source: siconv
    /// The condition-label stream (`plotN_markers`), exposed for the same reason `source` is: a
    /// test rig has to be able to point it at a real producer. Without this the marker path can
    /// only ever be exercised by poking `nextLabel` by hand, which tests the latch fallback and
    /// not the rtc comparison that actually ships.
    property alias markerSource: markerStream
    /// The trigger-instant stream (`plotN_trigger`). Declared and currently unread -- see the
    /// Stream below for why -- but aliased alongside its sibling so the pair stay symmetric.
    property alias triggerSource: triggerStream
    /// The two OUTPUT stream names (`plotN_publishAverage`, `plotN_publishEpochs`), exposed so a
    /// test rig can turn publishing on without going through the Configurator's parameter tab.
    /// Empty publishes nothing, which is the default.
    property alias publishAverageParameter: publishAverageParam
    property alias publishEpochsParameter: publishEpochsParam
    /// Exposed so a test rig can measure the viewer inside a real layout.
    property alias plotView: plotView
    /// The epoch viewer, likewise. A sibling of the sweep, not a mode of it.
    property alias epochView: epochView
    /// Likewise for the message log -- PlotView contains ListViews of its own, so a rig that goes
    /// looking for "the ListView" finds one of those instead.
    property alias messageList: messageList
    /// Passed straight through to the viewer: the head picture and the electrode spread over it
    /// are one setting for the whole application, not one per viewer.
    property alias headImage: plotView.headImage
    property alias headScale: plotView.headScale
    property alias headX: plotView.headX
    property alias headY: plotView.headY

    // =============================================================================================
    // THE CROSS-VIEWER CURSOR LINK
    // =============================================================================================

    /**
     * ⭐ The live cursor arriving from the other viewer, or null.
     *
     * ⚠ A PLAIN `property var`, NEVER A TYPED GADGET. Assigning a plain JavaScript object to
     * a gadget-typed property fails SILENTLY -- no warning, no assignment, the old value simply
     * stays -- which is exactly why the stream connector goes through `serialized` rather than
     * through a typed value. A `var` holds the object as written.
     *
     * ⚠ AND NOT A PARAMETER. Both viewers live in ONE QML process, so this costs a property
     * write; routing it through a Double would schedule a full service-description
     * re-serialisation on every mouse move. The link's DIRECTION is configuration and does belong
     * in a parameter -- see the Configurator -- but the cursor itself must not.
     *
     * The record carries TIME IN MILLISECONDS relative to t0, plus the source's rate and window,
     * so the compatibility test is local: a fraction would mean a different latency in every
     * window and a sample index a different latency at every rate, and neither can be checked
     * against this viewer without asking the other one questions.
     */
    property var incomingCursor: null

    /// "off" | "source" | "follower". Pushed down from the Configurator's parameter, which is
    /// where the direction is configured and persisted.
    property string cursorLinkRole: "off"

    /// Emitted when THIS viewer is the source and its cursor moved. The Configurator relays it.
    signal cursorPublished(var record)

    /**
     * Identity of the stream this viewer is on, for the "are these even the same recording" test.
     *
     * The uid, not the name: two services can publish streams with the same name, and a link that
     * silently believed them to be one recording would carry a latency between two different
     * experiments without saying so.
     */
    function streamKey() {
        var info = siconv.activeStream
        if (!info || info.isEmpty())
            return ""
        return "" + info.uid
    }

    function streamLabel() {
        var info = siconv.activeStream
        return (!info || info.isEmpty()) ? "" : info.name
    }

    function publishCursor() {
        if (cursorLinkRole !== "source" || !epochMode || !epochView.cursorReady)
            return
        var col = epochView.cursorColumn
        // A plain object literal. See the note on incomingCursor.
        cursorPublished({
            "title": root.title,
            "key": streamKey(),
            "label": streamLabel(),
            "ms": epochView.cursorMs,
            "rate": col.rate,
            "lowMs": col.lowMs,
            "highMs": col.highMs,
            "epoched": col.epoched,
            "stamp": Date.now()
        })
    }

    /**
     * Take the source's latency, and say what happened to it.
     *
     * ⚠ ONE WAY, ALWAYS. The follower clamps into its own window and snaps to its own
     * sample grid; writing that result back would drag the SOURCE cursor to the follower's clamp,
     * and the operator's cursor would jump under their hand the moment they dragged it past the
     * follower's window. Nothing in this function writes anything the source can see. The
     * difference is CAPTIONED instead.
     */
    function applyIncomingCursor() {
        if (cursorLinkRole !== "follower") {
            epochView.cursorNote = ""
            return
        }

        var rec = root.incomingCursor
        if (!rec || rec.ms === undefined) {
            epochView.cursorNote = "linked, waiting for the other viewer's cursor"
            return
        }

        var from = "following " + rec.title
        var notes = []

        if (!epochMode || !epochView.cursorReady) {
            epochView.cursorNote = from + " — but this viewer has no epoch to place a "
                                 + "cursor in"
            return
        }

        var col = epochView.cursorColumn

        if (rec.key !== "" && streamKey() !== "" && rec.key !== streamKey()) {
            notes.push("different streams (" + rec.label + " → " + streamLabel()
                       + "), so only the TIME is carried across")
        }
        if (rec.rate > 0 && col.rate > 0 && Math.abs(rec.rate - col.rate) > 1e-9) {
            notes.push("source runs at " + Number(rec.rate).toFixed(0) + " Hz and this stream at "
                       + Number(col.rate).toFixed(0) + " Hz, so the latency lands on the nearest "
                       + "sample here")
        }
        if (rec.epoched && col.epoched
                && (rec.lowMs !== col.lowMs || rec.highMs !== col.highMs)) {
            notes.push("source window " + epochView.msText(rec.lowMs) + " … "
                       + epochView.msText(rec.highMs) + " ms, this one "
                       + epochView.msText(col.lowMs) + " … "
                       + epochView.msText(col.highMs) + " ms")
        }
        if (!col.epoched) {
            notes.push("this stream declares no t0, so the latency is being applied to an axis "
                       + "that starts at 0")
        }

        epochView.cursorNote = notes.length > 0 ? (from + " — " + notes.join("; ")) : from

        // Last, so the clamp EpochView reports is against the window this note just described.
        epochView.setCursorMs(rec.ms)
    }

    onIncomingCursorChanged: applyIncomingCursor()
    onCursorLinkRoleChanged: {
        applyIncomingCursor()
        publishCursor()
    }
    // The epoch/sweep switch also lands here, through the existing onEpochModeChanged below:
    // QML allows ONE handler per signal per object, and a second declaration is a load-time
    // error, not a second handler.

    Connections {
        target: epochView
        // Only while this viewer is the source. A follower that echoed would close the loop the
        // one-way rule exists to keep open.
        enabled: root.cursorLinkRole === "source"
        function onCursorMsChanged() { root.publishCursor() }
    }

    property string parameter_name: "plot1_"
    property string parameter_group: "plot"
    property string parameter_label: "Plot1 "
    /// Where this viewer's parameters sort in the "plot" tab. Without an explicit index every
    /// viewer's stream and settings share index 0 and the tab's order is arbitrary from run to
    /// run -- which is exactly what it looked like.
    property int parameter_index: 10

    // =============================================================================================
    // Sweep or epoch
    // =============================================================================================

    /**
     * ⭐ THE SWITCH: does this stream declare a stimulus-locked window?
     *
     * The test is on the per-channel MetaData of the RESOLVED stream, and on nothing else. Not on
     * the stream's name ("epochs" is a convention, not a contract, and `clean` and `average` carry
     * epochs too), not on the block length, not on the cadence -- a producer that sends one block
     * per stimulus and one that sends blocks continuously are indistinguishable from the outside.
     *
     * A key counts as PRESENT only when its list is exactly `channels` long. Tested on SIZE, never
     * on value: `window_start_ms == 0` is a legal declaration -- an epoch that opens at the
     * stimulus -- and a truth test on the value would read that stream as continuous. A malformed
     * key is treated exactly as an absent one.
     *
     * `channels` is not readable from a StreamInfo in QML -- it lives in the serialised type -- so
     * it is recovered as the MODAL length of the per-channel lists the stream publishes. Every one
     * of them is `channels` long by the same contract, so the most common length IS the channel
     * count; taking the mode rather than insisting all agree means one malformed key cannot veto a
     * window that is otherwise well declared. When `window_start_ms` is the only per-channel key
     * there is, its own length is the mode and the test reduces to "present and finite".
     *
     * This is a pre-verdict, cheap enough to run on every announce. EpochReceiver runs the same
     * rule against the channel count taken from the connected stream's own type, which is
     * authoritative; @ref epochDemoted below defers to it.
     */
    function declaresEpochWindow(info) {
        return epochProbeReason(info) === ""
    }

    /**
     * The same test, saying which of its five exits it took. Empty means the stream declares an
     * epoch window.
     *
     * ⭐ One function, not two: the verdict above is defined as "this returned nothing", so the
     * reason can never drift away from the decision it explains. The reason exists because a
     * stream that fails this test is drawn as a plain sweep, and the operator was given no
     * statement anywhere that a declaration had been looked for at all -- a stream whose producer
     * simply forgot to publish window_start_ms looked exactly like a stream that is genuinely
     * continuous.
     *
     * ⚠ Text only. Nothing branches on it, so it cannot change what is drawn.
     */
    function epochProbeReason(info) {
        var lists = perChannelLists(info)
        if (!lists)
            return "No resolved stream to ask."

        var start = lists["window_start_ms"]
        if (!start || start.length === undefined)
            return "The stream publishes no window_start_ms channel property."
        if (start.length < 1)
            return "The stream publishes window_start_ms, but it is empty."

        // ⚠ Every entry, never element 0. Channels may genuinely declare different windows --
        // tepSoundService publishes [-200,501) ms on channels 0-63 and [-400,301) ms on channel
        // 64 -- so what is checked is that each one is a real number, not that they agree.
        for (var i = 0; i < start.length; ++i) {
            var v = Number(start[i])
            if (start[i] === undefined || start[i] === null || !isFinite(v))
                return "window_start_ms[" + i + "] is not a number."
        }

        var modal = modalListLength(lists)
        if (start.length !== modal)
            return "window_start_ms covers " + start.length + " channels, the stream has " + modal
                    + "."

        return ""
    }

    /// Every per-channel list the stream announces, as { key: array }. Null when there is no
    /// resolved stream to ask.
    function perChannelLists(info) {
        if (!info || info.isEmpty === undefined || info.isEmpty())
            return null
        var md = info.metaData
        if (!md || md.channelPropertyNames === undefined)
            return null

        var names = md.channelPropertyNames()
        var out = {}
        for (var i = 0; i < names.length; ++i)
            out[names[i]] = md.channelProperty(names[i])
        return out
    }

    /// The channel count, recovered as the most common per-channel list length. Ties break to the
    /// longer list, so a stream carrying one short malformed key still reports its real width.
    function modalListLength(lists) {
        var counts = {}
        var bestCount = 0
        var bestLength = 0
        for (var key in lists) {
            var l = lists[key]
            if (!l || l.length === undefined || l.length === 0)
                continue
            var n = l.length
            counts[n] = (counts[n] || 0) + 1
            if (counts[n] > bestCount || (counts[n] === bestCount && n > bestLength)) {
                bestCount = counts[n]
                bestLength = n
            }
        }
        return bestLength
    }

    /**
     * The authoritative verdict, once the epoch viewer has actually connected, saying NO.
     *
     * EpochReceiver::epoched applies the same rule against the channel count taken from the
     * stream's own type rather than from a show of hands among the metadata keys, so where the two
     * disagree it wins. Used in one direction only -- to demote a stream this file promoted -- and
     * cleared whenever the connector's stream changes, because a producer that is reconfigured or
     * relaunched gets a fresh hearing.
     */
    property bool epochDemoted: false

    /// The verdict before any override. Kept separate so the mode button can say what "auto"
    /// currently resolves to.
    readonly property bool autoEpoch: declaresEpochWindow(siconv.activeStream) && !epochDemoted

    /// Why `autoEpoch` is false, in one line. Empty when it is true.
    readonly property string epochProbeNote:
        epochDemoted ? "The epoch receiver rejected the declaration against the stream's own "
                       + "channel count."
                     : epochProbeReason(siconv.activeStream)

    /// "auto" | "epoch" | "continuous", persisted in the viewer's existing settings blob. Anything
    /// else -- including a blob written before this key existed -- reads as "auto".
    readonly property string streamMode:
        (plotView.settings && (plotView.settings.stream_mode === "epoch"
                               || plotView.settings.stream_mode === "continuous"))
        ? plotView.settings.stream_mode : "auto"

    readonly property bool epochMode: streamMode === "epoch" ? true
                                    : streamMode === "continuous" ? false
                                    : autoEpoch

    // =============================================================================================
    // ⭐ VIEWER-SIDE EPOCHING: BOTH VIEWS AT ONCE
    // =============================================================================================

    /**
     * The sweep is cutting epochs out of a continuous stream and the epoch view is showing them.
     *
     * ⚠ THIS IS THE ONE CASE WHERE BOTH VIEWERS ARE LIVE. Everywhere else they are mutually
     * exclusive -- @ref applySources points one at the stream and the other at nothing. Here the
     * sweep must stay on screen, because it is the continuous record the operator is checking the
     * alignment against and where the trigger lane is selected, and the epoch view must be on
     * screen beside it, because the cut epoch is the thing being checked. Showing one at a time
     * would answer the operator's question ("do other events line up with the trigger") by hiding
     * half of it.
     */
    readonly property bool cutMode:
        !epochMode && plotView.settings !== null && plotView.settings.epoch_cut_enabled
        && !siconv.desiredStream.isEmpty()

    // =============================================================================================
    // ⭐ THE MARKER STREAM -> CONDITION LABELS
    // =============================================================================================

    /**
     * The condition label carried by one marker record.
     *
     * A Message is one RTC and one free string; there is no label field on the wire. Two shapes
     * exist in this tree: signalGenerator's default template is the label itself, and its `json`
     * format wraps it in an object with a `label` key. So: **a JSON object with a `label` key
     * contributes that key; anything else is the label whole.**
     *
     * ⚠ A TEMPLATE THAT VARIES PER TRIAL MAKES ONE BIN PER TRIAL. `"%L %C %I %T"` produces a
     * distinct string for every event, and per-condition averaging over one epoch per bin is not
     * averaging. Nothing here can detect that; it is the operator's to notice, and the bin list on
     * the average bar is where they will.
     */
    function labelFromMarker(text) {
        if (!text)
            return ""
        var t = ("" + text).trim()
        if (t.length > 1 && t.charAt(0) === "{") {
            try {
                var o = JSON.parse(t)
                if (o && typeof o === "object" && o.label !== undefined && o.label !== null)
                    return "" + o.label
            } catch (e) {
                // Not JSON after all. The whole string is the label, which is the other shape.
            }
        }
        return t
    }

    /// Point the marker receiver at the declared slot and forget the previous stream's records --
    /// a different marker stream is a different experiment, not a continuation of this one.
    function applyMarkerStream() {
        markerReceiver.sourceInfo = markerStream.desiredStream
        epochView.plot.clearMarkers()
        epochView.plot.nextLabel = ""
        // ⭐ The cue log and the label queue too: a different event stream is a different run, and
        // a queue carried across would stamp the new run's epochs with the old run's conditions.
        epochView.plot.resetAttribution()
        // Both label paths, or the sweep's epocher would keep labelling new epochs with the
        // PREVIOUS experiment's conditions while the epoch viewer had already forgotten them.
        plotView.plot.resetCutting()
    }

    /**
     * Point each viewer at the stream, or away from it.
     *
     * The sweep keeps the stream in BOTH modes. It is what owns the persisted channel state, and a
     * receiver with no stream has no channels to describe -- so cutting it loose on every mode
     * switch would let its write-back overwrite the saved montage with an empty one. An epoch
     * stream costs it one block per stimulus, which is nothing.
     *
     * The epoch viewer is cut loose when it is not showing, because on a continuous stream it
     * would otherwise buffer every block as if it were an epoch, for nobody.
     */
    function applySources() {
        plotView.sourceInfo = siconv.desiredStream
        epochView.sourceInfo = root.epochMode ? siconv.desiredStream
                                              : ResonanceApp.streamInfo({})

        // ⭐ THE SAME DOOR. A viewer-cut epoch is handed to the epoch viewer's own item, so it
        // goes into the same store, the same average, the same three renderings and the same
        // caption a producer-cut epoch does. A direct pointer, not a signal carrying samples:
        // an epoch is channels x samples doubles and marshalling it through QML would copy it
        // twice for no reader.
        //
        // Assigned whenever the epoch view is NOT stream-driven, whether or not cutting is on --
        // the receiver is inert until `cutEnabled` and a shape are both there, and leaving the
        // sink connected means switching cutting on takes effect on the next block rather than
        // needing this function to run again.
        plotView.plot.epochSink = root.epochMode ? null : epochView.plot
    }

    // A parameter set restored from a --serviceConfig lands before this component is complete, so
    // its jsonChanged has already been and gone by the time the handler below exists.
    Component.onCompleted: {
        applySources()
        applyMarkerStream()
    }

    onEpochModeChanged: {
        // A Controls 2 Popup lives in the WINDOW's overlay, not inside the item that opened it, so
        // hiding the sweep would leave its setup panel floating over the epoch view with nothing
        // left on screen able to dismiss it.
        if (epochMode)
            plotView.closePanels()
        applySources()
        // A viewer that just left epoch mode has no cursor to follow or publish, and one that
        // just entered it needs the link applied to the view that now exists.
        applyIncomingCursor()
        publishCursor()
    }

    Connections {
        target: siconv
        // The resolved stream changed under us -- it became ready, or died and came back. Both are
        // a fresh hearing for a stream this file previously demoted.
        function onJsonAttributesChanged() { root.epochDemoted = false }
    }

    onCutModeChanged: {
        // Leaving cut mode is not a reason to throw away what was measured, so the store is left
        // alone. Entering it needs the epoch view to get the keyboard and the layout to settle,
        // which the visibility bindings below already do.
        if (cutMode)
            plotView.closePanels()
    }

    /**
     * ⭐ THE MARKER STREAM. A SECOND receiver, because the one in the message log below is bound
     * to the MAIN stream slot -- it exists so that selecting a Message stream as the plot source
     * shows a log -- and is already spoken for.
     *
     * Every record goes to three places, and they are not redundant:
     *
     *  - the EPOCH viewer's own log, which labels a PRODUCER-cut epoch by comparing the record's
     *    time against the epoch's trigger instant;
     *  - the SWEEP's epocher, which labels a VIEWER-cut epoch the same way, at its own trigger;
     *  - `nextLabel`, the latch, which is the fallback for a producer whose stream does not say
     *    what its block timestamp names and therefore has no instant to compare against.
     *
     * ⚠ With no marker stream configured nothing calls any of it, both logs stay empty and every
     * epoch lands in the default bin -- which is a real bin, so the average is correct with no
     * markers at all, exactly as before this handler existed.
     */
    MessageReceiver {
        id: markerReceiver
        onMessage: {
            /**
             * ⭐ THE SAME STREAM FEEDS BOTH LABEL RULES, AND THE PLOT CHOOSES BETWEEN THEM.
             *
             * `takeStimulusEvent` recognises the stimulus service's own `cue` / `pulse` / `run`
             * records and feeds the attribution; everything else it ignores and costs one JSON
             * parse. The marker path below is unchanged and still runs, so pointing this slot at
             * a plain marker stream works exactly as it did, and pointing it at tepSoundService's
             * event stream now ALSO builds the attribution.
             *
             * ⚠ Which rule actually labels an epoch is `plot.attributionEnabled`, decided in C++
             * in one place. Feeding both here and choosing there is deliberate: the alternative
             * is a QML branch that has to be kept in step with the C++ one, and the two would
             * drift.
             */
            epochView.plot.takeStimulusEvent(text)

            var label = root.labelFromMarker(text)
            epochView.plot.pushMarker(timestamp, label)
            plotView.plot.pushCutMarker(timestamp, label)
            epochView.plot.nextLabel = label
        }
    }

    Connections {
        target: epochView.plot
        // ⚠ Re-read on EVERY geometry announce, never cached from the first connect: with
        // reconnect the type is dropped from the request, so a viewer can silently reattach to a
        // stream of a different shape.
        function onEpochGeometryChanged() {
            if (epochView.plot.channels > 0 && !epochView.plot.epoched)
                root.epochDemoted = true
        }
    }

    ColumnLayout {
        visible: !root.collapsed
        anchors.fill: parent
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: 3

            Resonance__Parameters__Stream {
                // Without this the connector is sized from its own implicit width, which is
                // deliberately compact, and the stream name is elided down to nothing.
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                target: siconv

                Parameters {
                    /**
                     * ⭐ THE MARKER STREAM, DECLARED NOW BECAUSE IT CANNOT BE DECLARED LATER.
                     *
                     * ⚠ `applyParameters` screens parameter NAMES once, up front, and
                     * permanently rejects anything not already declared -- so a slot added in a
                     * later build can never be filled in from a configuration saved today. This
                     * is `plotN_markers`: the stream whose most recent record before a trigger
                     * becomes that epoch's CONDITION LABEL, which is what per-condition averaging
                     * bins on (tepService takes the same optional parameter).
                     *
                     * ⭐ READ AS OF STAGE 5, by `markerReceiver` below. Each record goes to the
                     * epoch viewer's own MarkerLog (for producer-cut epochs), to the sweep's
                     * epocher (for viewer-cut ones) and to `nextLabel`, which survives only as
                     * the fallback for a producer whose stream does not say what its block
                     * timestamp names. With no marker stream configured nothing calls any of it
                     * and every epoch lands in the default bin -- a real bin, so the average is
                     * correct with no markers at all.
                     */
                    Stream {
                        id: markerStream
                        name: parameter_name + 'markers'
                        group: parameter_group
                        label: parameter_label + 'markers'
                        // After this viewer's stream (index) and its settings (index + 1); the
                        // next viewer starts ten further on.
                        index: root.parameter_index + 2

                        onJsonChanged: root.applyMarkerStream()
                    }

                    /**
                     * ⭐ THE TRIGGER STREAM, DECLARED NOW AND DELIBERATELY UNUSED.
                     *
                     * ⚠ Same rule as the markers slot above: `applyParameters` screens parameter
                     * names once, so a slot added in a later build can never be filled in from a
                     * configuration saved today. Declaring it costs one name; not declaring it
                     * costs every configuration written before it lands.
                     *
                     * ⚠ AND NOTHING READS IT, ON PURPOSE. A trigger on a SEPARATE stream can only
                     * be located by comparing timestamps, and a continuous stream does not publish
                     * what its own timestamps name -- so its alignment would rest on a convention
                     * that cannot be read off the wire, and RTC is per-machine and per-boot
                     * besides. The trigger this viewer cuts on is a lane INSIDE the source stream,
                     * where the sample index is exact and no timestamp enters. A rig whose trigger
                     * genuinely arrives on its own hardware stream is an obvious near-future ask;
                     * this is the slot it will use.
                     */
                    Stream {
                        id: triggerStream
                        name: parameter_name + 'trigger'
                        group: parameter_group
                        label: parameter_label + 'trigger'
                        index: root.parameter_index + 3
                    }

                    /**
                     * ⭐ THE TWO OUTPUT STREAM NAMES (Stage 6). THE VIEWER IS A PRODUCER.
                     *
                     * ⚠ PARAMETERS, NOT SETTINGS-BLOB KEYS, and declared now because they cannot
                     * be declared later: `applyParameters` screens parameter names once, up
                     * front, and permanently rejects anything not already declared. Every OTHER
                     * epoch setting is a key in the blob -- but an output stream NAME is what a
                     * second service is told to set (`SetParameters`, a saved rig configuration,
                     * an experiment script), and rewriting a JSON blob to turn a recording on is
                     * not something a script should have to do.
                     *
                     * ⭐ THE NAME IS THE SWITCH. Empty publishes nothing, which is the default: a
                     * viewer that silently started producing would be a surprise on the network.
                     * One control rather than a name plus an enable, because a name is what a
                     * second viewer would collide on anyway -- so the thing the operator sets is
                     * the thing that has to be unique.
                     *
                     * ⚠ TWO VIEWERS UNDER ONE NAME. Every viewer in a Configurator shares ONE
                     * service name, and a stream is resolved by (service, stream), so two viewers
                     * publishing "average" announce the same identity twice with different uids:
                     * a consumer gets whichever discovery answered, and a reconnect can flip
                     * between them mid-session with nothing marking the join. The second claimant
                     * REFUSES and says so on its own caption (EpochOutputStream::nameIsClaimed).
                     * The defaults the button below writes are `plot1_average`, `plot2_average`
                     * and so on, so the collision is something the operator has to type.
                     */
                    String {
                        id: publishAverageParam
                        name: parameter_name + 'publishAverage'
                        group: parameter_group
                        label: parameter_label + 'publish average'
                        index: root.parameter_index + 4
                    }

                    String {
                        id: publishEpochsParam
                        name: parameter_name + 'publishEpochs'
                        group: parameter_group
                        label: parameter_label + 'publish epochs'
                        index: root.parameter_index + 5
                    }

                    Stream {
                        id: siconv
                        name: parameter_name + 'stream'
                        group: parameter_group
                        label: parameter_label + 'stream'
                        index: root.parameter_index

                        onJsonChanged: {
                            messages.clear()
                            msgReceiver.sourceInfo = siconv.desiredStream
                            // A different stream is a fresh hearing, whatever the last one was.
                            root.epochDemoted = false
                            root.applySources()
                        }
                    }
                }
            }

            // --- the override -------------------------------------------------------------------
            CompactButton {
                objectName: "cutSweepVisibility"
                implicitHeight: 19
                visible: root.cutMode
                text: plotView.settings && plotView.settings.epoch_cut_show_sweep ? "Sweep + epochs" : "Epochs only"
                ToolTip.visible: hovered
                ToolTip.text: "Show or hide the continuous trace beside the cut epochs. Cutting keeps running."
                onClicked: plotView.settings.epoch_cut_show_sweep = !plotView.settings.epoch_cut_show_sweep
            }
            // One click cycles auto -> epoch -> continuous -> auto. Three states rather than a
            // plain on/off because "let the stream say" is a real answer and the usual one, and
            // losing it the first time somebody overrules a verdict would be a bad trade.
            CompactButton {
                id: modeButton
                implicitHeight: 19
                visible: !siconv.desiredStream.isEmpty()
                enabled: plotView.settings !== null
                // Deliberately NOT `checkable`. A checkable Button assigns its own `checked` on
                // every click, which overwrites any binding on it -- and this control has three
                // states, so a two-state latch would desync from the setting on the first click.
                // `highlighted` is a plain property, so it keeps following the setting.
                highlighted: root.streamMode !== "auto"
                accentColor: "#e2b843"
                text: {
                    if (root.streamMode === "epoch")
                        return "Epoch"
                    if (root.streamMode === "continuous")
                        return "Sweep"
                    return root.autoEpoch ? "Auto · epoch" : "Auto · sweep"
                }
                ToolTip.visible: hovered
                ToolTip.text: {
                    // Says what was looked for AND what was found, so a sweep is never just an
                    // unexplained default: a producer that forgot to publish window_start_ms and
                    // one that is genuinely continuous read differently here.
                    var verdict = root.autoEpoch
                        ? "This stream declares window_start_ms on every channel, so Auto reads it "
                          + "as epoched."
                        : "Auto looked for an epoch declaration and did not find one, so it reads "
                          + "this stream as continuous.\n" + root.epochProbeNote
                    var now = root.streamMode === "auto"
                        ? "Following the stream."
                        : (root.streamMode === "epoch" ? "Forced to the epoch view."
                                                       : "Forced to the scrolling sweep.")
                    return verdict + "\n" + now + "\nClick to cycle: auto → epoch → sweep."
                }
                onClicked: {
                    if (!plotView.settings)
                        return
                    var next = root.streamMode === "auto" ? "epoch"
                             : root.streamMode === "epoch" ? "continuous" : "auto"
                    plotView.settings.stream_mode = next
                }
            }
        }

        PlotView {
            id: plotView
            Layout.fillHeight: true
            Layout.fillWidth: true
            focus: true
            parameter_name: root.parameter_name
            parameter_group: root.parameter_group
            parameter_label: root.parameter_label
            parameter_index: root.parameter_index + 1

            // isEmpty, not isNull: a StreamInfo built from an empty JSON object is not null, so
            // isNull() here left the viewer showing for a cleared connector.
            visible: !sourceInfo.isEmpty() && !root.epochMode
                     && (!root.cutMode || plotView.settings.epoch_cut_show_sweep)
        }

        EpochView {
            id: epochView
            Layout.fillHeight: true
            Layout.fillWidth: true
            // ⭐ One Settings object for the pair. A second one would mean a second service
            // parameter under the same name; sharing it also means the montage, the colours and
            // the butterfly toggle mean the same thing in both views.
            settings: plotView.settings
            // ⚠ `plot.active`, NOT `!sourceInfo.isEmpty()`. A viewer-cut epoch has no stream of
            // its own and never will, so the old test hid the only mode this stage adds.
            visible: root.epochMode ? epochView.plot.active : root.cutMode

            // ⭐ The publication names come DOWN from the parameters, one way. EpochView does not
            // own them -- they are service parameters and they belong to this file -- so it asks
            // for a change by signal instead, and the default name it would be given is composed
            // here, where `parameter_name` lives.
            publishAverageName: publishAverageParam.value
            publishEpochsName: publishEpochsParam.value
            onPublishToggled: {
                var param = (which === "average") ? publishAverageParam : publishEpochsParam
                // ⚠ The default carries this viewer's own prefix -- `plot1_average`,
                // `plot2_average` -- so two viewers switched on with the same click do not
                // announce the same stream name. See the note on the parameters themselves.
                param.value = (param.value === "") ? (root.parameter_name + which) : ""
            }
        }

        ListView {
            id: messageList
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true

            visible: !msgReceiver.sourceInfo.isEmpty()

            model: ListModel { id: messages }

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Row {
                spacing: 4
                Text { text: ('          ' + (ts / 1E9).toFixed(3)).slice(-11) }
                Text { text: msg }
            }

            MessageReceiver {
                id: msgReceiver
                onMessage: messages.insert(0, { msg: text, ts: timestamp })
            }
        }

        // With no stream selected every view above is hidden and the layout has nothing to give
        // its slack to, so it centres the connector halfway down an empty panel. This keeps it
        // where it belongs.
        //
        // It must test ALL of them, not just the sweep. A message stream hides the plot and shows
        // the list -- so on `!plotView.visible` alone this spacer switched on alongside a visible
        // list, and since both carry fillHeight they split the panel evenly. That is the empty
        // band under a message log that stops halfway down: the bottom half is this Item.
        Item {
            Layout.fillHeight: true
            visible: !plotView.visible && !epochView.visible && !messageList.visible
        }
    }
}
