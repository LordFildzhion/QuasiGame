import QtQuick 2.15

/**
 * The scalp field's colour scale, explained: a horizontal ramp with symmetric limits, ticks that
 * always include zero, and the unit the numbers are in.
 *
 * ⚠ THIS FILE KNOWS NO COLOURS. Every colour it draws comes from @ref colorAt, which the owner
 * wires to the C++ item that already wraps Colormap (colormap.hpp). A gradient written out in QML
 * would be a SECOND copy of the stop table, and the two would drift the first time either is
 * touched -- the same argument the plugin's CMakeLists makes for sharing spline.cpp with
 * tepSoundService by path rather than by copy. The stop table is argued from measurements
 * (monotone lightness per arm, arms of equal weight, no colour confusable with any of the nine
 * selectable backgrounds); a QML paraphrase would carry none of that and break all of it.
 *
 * ⚠ WHAT THIS REPLACES. HeadView's five-swatch discrete legend -- good / fair / poor / bad plus a
 * hollow "no reading" -- and this bar occupy the SAME reserved band (`legendSpace`), and in field
 * mode the legend is hidden and this takes its place. Never both: those four swatches describe
 * impedance thresholds that a potential field does not have, and showing them beside a continuous
 * scale would advertise cut-offs nothing is being compared against. The one part that carries
 * over is the hollow marker at the right-hand end, because the hollow rule is about missing
 * readings and not about impedance -- an electrode with no finite value is left out of the fit
 * and drawn hollow on top of the field, and this says so.
 */
Item {
    id: root

    /**
     * Colour lookup, `function(t) -> color`, with t in [-1, +1]. Supplied by the owner; the item
     * draws nothing until it is set, which is the honest state before a stream arrives.
     */
    property var colorAt: null

    /// Half-range, in BASE units (volts, not microvolts). The bar spans [-limit, +limit].
    property real limit: 0

    /**
     * Tick values in base units, from Colormap::barTicks(). Passed in rather than computed here
     * so the bar and the field cannot disagree about where zero is.
     */
    property var ticks: []

    /// Display unit INCLUDING its SI prefix, e.g. "uV" -- ChannelModel::unit() has already chosen
    /// the prefix, and @ref tickScale is the matching power of ten. Nothing here derives either.
    property string unit: ""
    /// Divide a base-unit tick by this to get the number to print. 1e-6 for microvolts.
    property real tickScale: 1

    /// The ink the surrounding view chose from its background, for text and rules ON THE PAPER.
    /// Text drawn ON the ramp picks its own -- see @ref inkOver below.
    property color ink: "#303030"
    property color inkFaint: "#5a5a5a"

    /// True when the view's background is light. Only used for the bar's casing.
    property bool lightBackground: true

    /// Does the operator have a scale at all? A degenerate limit produces no ticks, and a bar
    /// with no numbers on it would look like a working legend for a scale that does not exist.
    readonly property bool ready: colorAt !== null && limit > 0 && ticks.length > 1

    /// Sampling of the ramp. 96 strips across a bar this size is finer than the eye resolves and
    /// far cheaper than a pixel-accurate shader for something this small.
    readonly property int rampSteps: 96

    implicitWidth: 260
    /// Ramp, then the tick row, then the unit on its own line.
    implicitHeight: barHeight + 28
    readonly property real barHeight: 14

    visible: ready

    /// The tree's own luminance rule, applied to a colour of the ramp rather than to the paper --
    /// text over the bar has the bar as its background, and the two are not the same colour.
    function inkOver(c) {
        return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) > 0.5 ? "#303030" : "#d0d0d0"
    }

    function shortNumber(v) {
        if (!isFinite(v))
            return "–"
        var scaled = v / root.tickScale
        if (Math.abs(scaled) >= 100)
            return Number(scaled).toFixed(0)
        if (Math.abs(scaled) >= 10)
            return Number(scaled).toFixed(1)
        return Number(scaled).toFixed(2)
    }

    Row {
        anchors.fill: parent
        spacing: 8

        Item {
            id: barArea
            width: parent.width - noData.width - parent.spacing
            height: root.height

            // The ramp. One strip per step, sampled from the C++ map.
            Row {
                id: ramp
                y: 0
                width: parent.width
                height: root.barHeight

                Repeater {
                    model: root.rampSteps

                    Rectangle {
                        required property int index
                        width: ramp.width / root.rampSteps
                        height: ramp.height
                        // +0.5 so each strip is sampled at its own centre; sampling at the left
                        // edge shifts the whole ramp by half a strip and moves the zero colour
                        // off the zero tick.
                        color: root.colorAt
                               ? root.colorAt(-1 + 2 * (index + 0.5) / root.rampSteps)
                               : "transparent"
                    }
                }
            }

            /**
             * A hairline casing. The map legitimately reaches mid-lightness near zero, and on a
             * white background that stretch of the ramp has little to separate it from the paper;
             * the same is true of the dark ends on a black background. One rule in the paper's own
             * ink states where the scale starts and stops without touching the colours.
             */
            Rectangle {
                anchors.fill: ramp
                color: "transparent"
                border.width: 1
                border.color: root.lightBackground ? "#606060" : "#8a8a8a"
            }

            // The zero mark, drawn ON the ramp in ink chosen from the ramp. This is the one
            // position on the bar the operator navigates by, so it gets a full-height rule rather
            // than the short ticks the others get.
            Rectangle {
                x: ramp.width / 2 - width / 2
                y: 0
                width: 1
                height: root.barHeight
                color: root.colorAt ? root.inkOver(root.colorAt(0)) : "transparent"
            }

            Repeater {
                model: root.ticks

                Item {
                    required property var modelData
                    required property int index
                    // Position from the value, not from the index: if the owner ever passes an
                    // uneven set, the label still lands where the colour is.
                    x: root.limit > 0
                       ? (0.5 + 0.5 * modelData / root.limit) * ramp.width
                       : 0
                    y: 0
                    width: 0

                    Rectangle {
                        x: -0.5
                        y: root.barHeight
                        width: 1
                        height: 3
                        color: root.inkFaint
                    }
                    Text {
                        y: root.barHeight + 3
                        // The end labels are pulled inside the bar so neither runs off the panel;
                        // everything between is centred on its tick.
                        x: index === 0 ? 0
                           : (index === root.ticks.length - 1 ? -width : -width / 2)
                        text: root.shortNumber(modelData)
                        color: root.inkFaint
                        font.pixelSize: 10
                    }
                }
            }

            // The unit, on its own line under the numbers. Zero is always a tick and its label
            // already owns the centre of the tick row, so the unit cannot share that line.
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.barHeight + 16
                text: root.unit
                color: root.ink
                font.pixelSize: 10
                font.bold: true
            }
        }

        // The survivor of the discrete legend: a hollow disc, meaning "no reading". A channel
        // with no finite value is excluded from the fit entirely, so there is no field colour
        // that could stand for it; its electrode is drawn hollow over the field, and this is the
        // key to that. Hollow rather than a shade, for the reason the rule exists: an
        // unconnected electrode must not be readable as a measured extreme.
        Row {
            id: noData
            spacing: 4
            y: 0
            height: root.barHeight

            Rectangle {
                width: root.barHeight
                height: root.barHeight
                radius: height / 2
                color: "transparent"
                border.width: 1
                border.color: root.inkFaint
            }
            Text {
                text: "no reading"
                color: root.inkFaint
                font.pixelSize: 10
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
