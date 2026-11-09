import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Resonance 3.0
import Resonance.Plot 3.0

/**
 * The head-shaped array of epoch traces, made operable: one miniature trace at each electrode's own
 * scalp position, the one amplitude they all share, and a line of text saying what is on screen.
 *
 * A deliberate SIBLING of @ref TopoPanel, built the same way for the same reasons: the arithmetic
 * is in C++ (@ref EpochGridView), this file owns the surrounding furniture -- which settings drive
 * it, what the hover readout says, and what the caption states. Nothing here computes a position,
 * a scale or a sample index; a number derived in QML would be a second copy of something already
 * validated over there.
 *
 * ⭐ WHY IT SHARES THE FIELD'S LAYOUT. @ref EpochGridView places its cells through
 * `TopoPlot::topoLayout` -- the SAME squeezed (py, px), plotrad and squeezefac the topoplot uses --
 * so an electrode sits in the same place whichever of the two head renderings is showing.
 * Switching between them is exactly what an operator does, and a third projection would move every
 * electrode under them while they did it. It also hands over the cartoon head for free, so the
 * outline under the traces is the outline under the field.
 *
 * ⚠ ONE AMPLITUDE FOR THE WHOLE ARRAY, and there is no per-cell autoscale anywhere in this file
 * or behind it. The array exists so that "the response is bigger at C3 than at C4" is a statement
 * about the picture; a per-cell scale would make every trace fill its box and destroy exactly that.
 * The controls below choose ONE number, and the caption states it.
 *
 * ⚠ THE HOLLOW RULE. A channel that is hidden, marked bad, or carries nothing finite in the drawn
 * span is a hollow ring and no trace -- never a flat line, which reads as a measured zero and is
 * the one thing an unconnected electrode is not. The same argued rule as colormap.hpp's and
 * TopoPanel's, spelled for a rendering whose "worst colour" would be a straight line.
 *
 * ⚠ NOT A SERVICE PARAMETER. Everything persisted here is a key inside the viewer's existing
 * settings blob. Parameter names are screened once, up front, so a parameter added late can never
 * be filled in from a configuration saved before it existed; an unknown key in the blob is ignored
 * on load and a missing one keeps its default, so a new key restores for free.
 */
Item {
    id: root

    /// Where the samples come from. The SAME receiver the trace panel draws, so the array and the
    /// traces can never be showing two different epochs.
    property var receiver: null

    /// Per-channel names, kinds, positions, colours, visibility and bad flags. THE SAME model the
    /// traces are drawn from, so a montage set up in the channel panel means the same thing here.
    property var channelModel: null

    /// The viewer's persisted settings. Null is tolerated -- it is assigned from outside and a
    /// binding can evaluate before that has happened -- so every read below is guarded.
    property var settings: null

    /// The owner's sentence about WHICH epoch this is: "epoch #41", "no epoch yet". Shown ahead of
    /// the item's own caption, which states the amplitude, the painted span and the counts.
    property string headline: ""

    /// A second line, for anything the owner has to admit. Drawn in warning ink.
    property string warning: ""

    /// Exposed so a harness can reach the item itself: cells(), cellInfo(), layoutInfo(),
    /// channelAt(), plotToItem(). That is what makes this assertable rather than photographable.
    property alias grid: grid

    // ⚠ The SAME paper the field is drawn on. Two head renderings of one montage on two different
    // backgrounds would read as two different instruments.
    readonly property color paper: settings ? settings.head_background : "#ffffff"
    readonly property bool lightPaper:
        0.299 * paper.r + 0.587 * paper.g + 0.114 * paper.b > 0.5
    readonly property color ink: lightPaper ? "#303030" : "#d0d0d0"
    readonly property color inkFaint: lightPaper ? "#5a5a5a" : "#909090"

    /**
     * The unit the amplitude control prints, derived from the AMPLITUDE's own magnitude and the
     * montage's base unit -- never from a channel's declared range.
     *
     * The same rule TopoPanel derives its colour-bar unit by, and for the same reason: a montage
     * can hold a channel whose range happens to be in millivolts, and labelling this control from
     * it would print millivolt numbers against a microvolt scale.
     */
    property string baseUnitName: ""
    readonly property int unitExponent:
        (channelModel && baseUnitName !== "" && grid.effectiveAmplitude > 0)
        ? channelModel.siExponent(grid.effectiveAmplitude) : 0
    readonly property real tickScale: Math.pow(10, unitExponent)
    readonly property string unitText:
        (channelModel && baseUnitName !== "")
        ? (channelModel.siPrefix(unitExponent) + channelModel.displayUnit(baseUnitName)) : ""

    /**
     * Find the base unit by asking a channel that actually has a CELL.
     *
     * Not channel 0: the montage is chosen by KIND, so channel 0 may be a trigger line or an EMG
     * pair member with a different unit -- or no unit at all. Every cell the item drew is by
     * construction one of the channels the traces came from.
     */
    function refreshUnit() {
        if (!channelModel) {
            baseUnitName = ""
            return
        }
        var list = grid.cells()
        for (var i = 0; i < list.length; ++i) {
            var u = channelModel.baseUnit(list[i].channel)
            if (u !== "") {
                baseUnitName = u
                return
            }
        }
        baseUnitName = ""
    }

    Component.onCompleted: refreshUnit()

    Connections {
        target: grid
        function onLayoutChanged() { root.refreshUnit() }
        function onAmplitudeChanged() { root.refreshUnit() }
    }

    Rectangle {
        anchors.fill: parent
        color: root.paper
        z: -1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        // --- controls ----------------------------------------------------------------------
        // Four things and no more, exactly as the field has: how big the shared scale is, whether
        // the electrodes are named, and whether the cells are boxed. Everything else about this
        // picture is measured, not chosen.
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 6
            visible: root.settings !== null

            CompactCheckBox {
                text: "Auto scale"
                checked: root.settings ? root.settings.head_trace_auto_amplitude : true
                ToolTip.visible: hovered
                ToolTip.text: "Shared amplitude from the montage's widest group scale. Off holds "
                            + "the value beside it."
                onClicked: {
                    if (!root.settings)
                        return
                    // The amplitude it is leaving is the one worth keeping: switching to manual
                    // with a stale number would jump every cell the instant it is unticked.
                    if (!checked && grid.effectiveAmplitude > 0)
                        root.settings.head_trace_amplitude = grid.effectiveAmplitude
                    root.settings.head_trace_auto_amplitude = checked
                }
            }

            NumberField {
                label: "±"
                enabled: root.settings !== null && !root.settings.head_trace_auto_amplitude
                // Shown in the SAME derived display unit as the caption. The setting behind it
                // stays in base units; nothing is stored prefixed.
                value: grid.effectiveAmplitude / root.tickScale
                suffix: root.unitText
                suffixWidth: 26
                decimals: 2
                logSteps: true
                fieldWidth: 62
                // Through a HoverHandler: a NumberField is a RowLayout and has no `hovered`, so
                // `ToolTip.visible: hovered` throws a ReferenceError and shows nothing. 🐞 D1.
                ToolTip.visible: ampHover.hovered
                ToolTip.text: "Half-height of every cell. One value for the whole array; there "
                            + "is no per-cell scale."
                HoverHandler { id: ampHover }
                onEdited: {
                    if (root.settings)
                        root.settings.head_trace_amplitude = value * root.tickScale
                }
            }

            NumberField {
                // ⚠ THE ONE SIZE CONTROL, and it is here because the ported layout MEASURABLY
                // needs it. tepService sizes a cell as side/sqrt(n) x 0.72, which is right for a
                // UNIFORM grid of n cells; a 10-20 cap is denser along its central rows than a
                // uniform grid, so on the shipped 64-channel montage 48 of the 2016 cell pairs
                // overlap at 0.72 and 16 still do at 0.55. The default is left at tepService's
                // number -- that is the ported picture and it is what an operator should see
                // first -- and this is how they separate the cells when the cap is dense. Turn
                // "Frames" on to see exactly which ones are touching.
                label: "cell"
                labelWidth: 22
                enabled: root.settings !== null
                value: root.settings ? root.settings.head_trace_scale : 0.72
                decimals: 2
                stepSize: 0.02
                minimumValue: 0.20
                maximumValue: 1.50
                fieldWidth: 48
                ToolTip.visible: cellHover.hovered
                HoverHandler { id: cellHover }
                ToolTip.text: "Cell width as a fraction of side/√n. 0.72 is the reference "
                            + "value; at it a 64-channel cap overlaps in 48 of 2016 pairs. "
                            + "Electrode positions do not move."
                onEdited: {
                    if (root.settings)
                        root.settings.head_trace_scale = value
                }
            }

            CompactCheckBox {
                text: "Names"
                checked: root.settings ? root.settings.head_trace_labels : true
                ToolTip.visible: hovered
                ToolTip.text: "Electrode names above each cell."
                onClicked: {
                    if (root.settings)
                        root.settings.head_trace_labels = checked
                }
            }

            CompactCheckBox {
                text: "Frames"
                checked: root.settings ? root.settings.head_trace_frames : false
                ToolTip.visible: hovered
                ToolTip.text: "A faint box around every cell. Shows whether a dense montage "
                            + "overlaps."
                onClicked: {
                    if (root.settings)
                        root.settings.head_trace_frames = checked
                }
            }

            Item { Layout.fillWidth: true }

            Label {
                text: grid.lastPaintMs.toFixed(1) + " ms"
                font.pixelSize: 10
                color: root.inkFaint
                ToolTip.visible: paintHover.hovered
                ToolTip.text: "Time for a full redraw of the array. Reported once per epoch."
                HoverHandler { id: paintHover }
            }
        }

        // --- the array -----------------------------------------------------------------------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            EpochGridView {
                id: grid
                anchors.fill: parent

                receiver: root.receiver
                channelModel: root.channelModel

                // ⚠ EEG only, by KIND, and the SAME kind the field uses. This montage's EMG pair
                // sits outside the outermost EEG electrode: letting it in moves plotrad and every
                // electrode with it, and the two head renderings would stop agreeing. Not
                // cosmetic. See topofield.hpp, "WHICH CHANNELS GO IN".
                kind: "EEG"

                backgroundColor: root.paper
                gridColor: root.settings ? root.settings.grid_color : "#464646"
                zeroMarkerColor: root.settings ? root.settings.grid_middleLine_color : "#dca03c"
                lineWidth: root.settings ? root.settings.lineWidth : 1
                antialiasTraces: root.settings ? root.settings.antialias : true

                showLabels: root.settings ? root.settings.head_trace_labels : true
                showFrames: root.settings ? root.settings.head_trace_frames : false
                // ⚠ Guarded against a settings blob that carries a zero: a cell of no width is
                // an empty head, and a saved configuration must never be able to produce one.
                cellScale: (root.settings && root.settings.head_trace_scale > 0)
                           ? root.settings.head_trace_scale : 0.72
                showHead: true
                // ⭐ The item's own caption is OFF and the caption below draws it instead. Only
                // the owner knows WHICH epoch these samples are, and a caption that cannot say
                // that is the complaint every plot in this tree has had.
                showCaption: false

                // An amplitude of zero has never been set, whatever the checkbox says — an
                // operator who has not chosen one yet must not be shown a flat array because of
                // it. The same guard the field's limit carries.
                autoAmplitude: root.settings
                               ? (root.settings.head_trace_auto_amplitude
                                  || !(root.settings.head_trace_amplitude > 0))
                               : true
                amplitude: root.settings ? root.settings.head_trace_amplitude : 0

                hoverChannel: arrayHover.channel
            }

            // --- hover readout, and click to select --------------------------------------
            // Names an electrode and says whether it is in the picture at all. Without this the
            // array is sixty-four anonymous squiggles; with it, it is an instrument.
            //
            // ⭐ Wired HERE, in QML, through EpochGridView::channelAt() -- there is no C++
            // coupling between this item and any other plot, which is what keeps the three head
            // renderings independent of one another.
            MouseArea {
                id: arrayHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton

                property int channel: -1

                onPositionChanged: channel = grid.channelAt(mouseX, mouseY)
                onExited: channel = -1
                onClicked: {
                    var c = grid.channelAt(mouse.x, mouse.y)
                    if (c >= 0 && root.channelModel)
                        root.channelModel.selectOnly(c)
                }
            }

            Rectangle {
                visible: arrayHover.containsMouse && readoutText.text !== ""
                x: Math.min(Math.max(0, arrayHover.mouseX + 12), parent.width - width)
                y: Math.min(Math.max(0, arrayHover.mouseY + 12), parent.height - height)
                width: readoutText.implicitWidth + 8
                height: readoutText.implicitHeight + 4
                radius: 2
                color: root.lightPaper ? Qt.rgba(1, 1, 1, 0.92) : Qt.rgba(0, 0, 0, 0.82)
                border.width: 1
                border.color: root.inkFaint

                Text {
                    id: readoutText
                    anchors.centerIn: parent
                    color: root.ink
                    font.pixelSize: 10
                    text: {
                        if (!arrayHover.containsMouse || arrayHover.channel < 0)
                            return ""
                        var c = grid.cellInfo(arrayHover.channel)
                        if (!c || c.name === undefined)
                            return ""
                        // ⚠ The hollow rule said out loud. A cell with no trace is not a cell
                        // reading zero, and the readout must never let the two be confused.
                        if (!c.hasData)
                            return c.name + " · no trace (hollow, nothing measured here)"
                        if (!c.placed)
                            return c.name + " · off-montage, drawn in the strip below the head"
                        return c.name + " · ±" + grid.amplitudeLabel
                    }
                }
            }

            // Nothing to draw, and why. A blank panel teaches the operator the feature is broken.
            Label {
                anchors.centerIn: parent
                visible: grid.cellCount === 0 || grid.epochSerial < 0
                width: parent.width - 24
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                color: root.inkFaint
                text: grid.status
            }
        }

        // --- caption ---------------------------------------------------------------------
        // ⭐ What the picture represents, in words: WHICH EPOCH, how many channels are in it, and
        // the ONE amplitude every cell shares. An array with no stated scale is a picture of
        // nothing, and one with no stated epoch is a picture of no particular moment.
        Label {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.preferredHeight: 16
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            font.pixelSize: 11
            color: root.warning !== "" ? "#d0a020" : root.ink
            opacity: 0.9
            text: {
                var parts = []
                if (root.headline !== "")
                    parts.push(root.headline)
                if (grid.caption !== "")
                    parts.push(grid.caption)
                if (root.warning !== "")
                    parts.push(root.warning)
                return parts.join(" · ")
            }

            ToolTip.visible: capHover.hovered
            ToolTip.text: grid.montageCount + " of " + grid.channelCount
                        + " channels are " + grid.kind + " with a scalp position; "
                        + grid.unplacedCount + " more are drawn in the strip and "
                        + grid.hollowCount + " cells are hollow. Cell "
                        + grid.cellWidth.toFixed(1) + "×" + grid.cellHeight.toFixed(1)
                        + " px. plotrad " + grid.plotrad.toFixed(6) + ", squeezefac "
                        + grid.squeezefac.toFixed(6) + "."
            HoverHandler { id: capHover }
        }
    }
}
