import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Resonance 3.0
import Resonance.Plot 3.0

/**
 * The interpolated scalp map, made operable: EEGLAB's topoplot field, its colour scale, the
 * controls that change what the scale means, and one line of text saying what the picture is.
 *
 * ⚠ THE ARITHMETIC IS NOT HERE, AND MUST NOT MOVE HERE. @ref TopoView does the squeeze, the
 * biharmonic solve and every pixel of the drawing, validated against grids EEGLAB itself
 * produced. This file owns the surrounding furniture: which settings drive it, where the colour
 * bar gets its unit, and what the caption says. A number computed in QML here would be a second
 * copy of something already validated over there.
 *
 * ⭐ WHAT THIS DOES NOT DECIDE. It does not pick a time, does not read a stream and does not
 * choose the values. @ref values is pushed in by the owner -- one number per CHANNEL INDEX in
 * BASE units -- exactly as TopoView asks for, and @ref headline is the owner's sentence about
 * where those numbers came from. That is what lets the sweep hand it a one-second mean and the
 * epoch viewer hand it a single sample at a cursor, with no branch in this file.
 *
 * ⚠ UNITS. Everything crossing this boundary is in base units (volts), and the SI prefix is
 * derived ONCE, here, at colour-bar-label time -- from the LIMIT, not from a channel's own range.
 * Labelling the bar from a channel whose range happens to be in millivolts would print millivolt
 * numbers against a microvolt scale. @ref ChannelModel::baseUnit exists for exactly this.
 *
 * ⚠ THE HOLLOW RULE, and why the four impedance swatches are gone. A channel with no finite
 * reading is excluded from the fit -- one NaN makes every grid point NaN -- and drawn hollow ON
 * TOP of the field, so an unconnected electrode can never be mistaken for a measured extreme one.
 * @ref ColorBar carries that hollow marker at its right-hand end. HeadView's good/fair/poor/bad
 * legend describes impedance thresholds a potential field does not have, and the two never appear
 * together.
 */
Item {
    id: root

    /// Per-channel names, kinds, positions, colours, visibility and bad flags. THE SAME model the
    /// traces are drawn from, so a montage set up in the channel panel means the same thing here.
    property var channelModel: null

    /// One number per CHANNEL INDEX, BASE units, non-finite or absent meaning "no reading".
    property var values: []

    /// The viewer's persisted settings. Null is tolerated -- it is assigned from outside and a
    /// binding can evaluate before that has happened -- so every read below is guarded.
    property var settings: null

    /// The owner's sentence about what the numbers are: "at -48.0 ms", "1.0 s mean". Shown ahead
    /// of the item's own status, which says how many channels got in and why any did not.
    property string headline: ""

    /// A second line, for anything the owner has to admit -- a clamp, a mismatch, a stale epoch.
    /// Drawn in warning ink and takes the caption's place when it is set.
    property string warning: ""

    /// Exposed so a harness can reach the item itself: sampleGrid(), layoutInfo(), fieldAt().
    property alias topo: topo

    readonly property color paper: settings ? settings.head_background : "#ffffff"
    readonly property bool lightPaper:
        0.299 * paper.r + 0.587 * paper.g + 0.114 * paper.b > 0.5
    readonly property color ink: lightPaper ? "#303030" : "#d0d0d0"
    readonly property color inkFaint: lightPaper ? "#5a5a5a" : "#909090"

    /**
     * The unit the colour bar prints, derived from the limit rather than from any channel.
     *
     * Re-derived whenever the field changes, because the limit moves with it on an auto scale.
     * `baseUnit` is the group's unprefixed name ("V"); `unitExponent` is the decade the LIMIT
     * sits in; the bar divides by `tickScale` and prints `unitText`.
     */
    property string baseUnitName: ""
    readonly property int unitExponent:
        (channelModel && baseUnitName !== "" && topo.effectiveLimit > 0)
        ? channelModel.siExponent(topo.effectiveLimit) : 0
    readonly property real tickScale: Math.pow(10, unitExponent)
    readonly property string unitText:
        (channelModel && baseUnitName !== "")
        ? (channelModel.siPrefix(unitExponent) + channelModel.displayUnit(baseUnitName)) : ""

    /**
     * Find the base unit by asking a channel that is actually ON the map.
     *
     * Not channel 0: the montage is chosen by KIND, so channel 0 may be a trigger line or an EMG
     * pair member with a different unit -- or no unit at all. The first electrode TopoView kept is
     * by construction one of the channels the numbers came from.
     */
    function refreshUnit() {
        if (!channelModel) {
            baseUnitName = ""
            return
        }
        var list = topo.electrodes()
        for (var i = 0; i < list.length; ++i) {
            var u = channelModel.baseUnit(list[i].channel)
            if (u !== "") {
                baseUnitName = u
                return
            }
        }
        baseUnitName = ""
    }

    /// Tick values in BASE units, from the C++ map, so the bar and the field cannot disagree
    /// about where zero is.
    property var barTicks: []

    function refreshScale() {
        barTicks = topo.barTicks(4)
        refreshUnit()
    }

    Component.onCompleted: refreshScale()

    Connections {
        target: topo
        function onFieldChanged() { root.refreshScale() }
    }

    Rectangle {
        anchors.fill: parent
        color: root.paper
        z: -1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        // --- controls --------------------------------------------------------------------------
        // Six things and no more: how big the scale is, what it looks like, whether the electrodes
        // are named, how many isolines are drawn, and how far the map is allowed to extrapolate.
        // Everything else about this picture is measured, not chosen.
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 6
            // 🐞 D1, the other half: controls for a map that does not exist.
            //
            // ⚠ `settings !== null` alone put this row -- and every tooltip on it -- on screen
            // with NO STREAM CONNECTED. The sweep shows this panel on `settings.head_mode`
            // alone, a persisted setting, so a viewer whose saved stream does not resolve comes
            // up empty with the whole control row live and hoverable over it. Gated on there
            // being electrodes: with none, the status label below says why there is no map, and
            // there is nothing to hover.
            visible: root.settings !== null && topo.montageCount > 0

            CompactCheckBox {
                text: "Auto scale"
                checked: root.settings ? root.settings.head_field_auto_limit : true
                ToolTip.visible: hovered
                ToolTip.text: "Colour limit from the largest magnitude on the interpolated grid, "
                            + "as EEGLAB does. Off holds the limit beside it."
                onClicked: {
                    if (!root.settings)
                        return
                    // The limit it is leaving is the one worth keeping: switching to manual with
                    // a stale number would jump the colours the instant it is unticked.
                    if (!checked && topo.effectiveLimit > 0)
                        root.settings.head_field_limit = topo.effectiveLimit
                    root.settings.head_field_auto_limit = checked
                }
            }

            NumberField {
                label: "±"
                enabled: root.settings !== null && !root.settings.head_field_auto_limit
                // Shown in the SAME derived display unit as the bar. The setting behind it stays
                // in base units; nothing is stored prefixed.
                value: topo.effectiveLimit / root.tickScale
                suffix: root.unitText
                suffixWidth: 26
                decimals: 2
                logSteps: true
                fieldWidth: 62
                // 🐞 D1. No description. The control is a "±" and a unit next to a colour bar;
                // what it does is on its face, and what was here instead was three lines of
                // design rationale for the scale being symmetric -- which belongs in
                // topoview.hpp, where it is, and not on a hovered control.
                //
                // ⚠ It could never have shown anyway: `ToolTip.visible: hovered` was bound on a
                // NumberField, which is a RowLayout and has no `hovered` -- the binding threw
                // "ReferenceError: hovered is not defined" on every evaluation. Verified against
                // qml.exe. Where a NumberField does need a description, it takes a HoverHandler.
                onEdited: {
                    if (root.settings)
                        root.settings.head_field_limit = value * root.tickScale
                }
            }

            CompactButton {
                text: root.settings && root.settings.head_field_variant === "jet"
                      ? "Jet" : "Diverging"
                implicitHeight: 19
                ToolTip.visible: hovered
                ToolTip.text: "Colour map: the tree's own diverging map, or MATLAB's jet."
                onClicked: {
                    if (root.settings)
                        root.settings.head_field_variant =
                                root.settings.head_field_variant === "jet" ? "diverging" : "jet"
                }
            }

            CompactCheckBox {
                text: "Names"
                checked: root.settings ? root.settings.head_field_labels : false
                ToolTip.visible: hovered
                ToolTip.text: "Electrode names on the map. Hovering an electrode names it too."
                onClicked: {
                    if (root.settings)
                        root.settings.head_field_labels = checked
                }
            }

            // EEGLAB's numcontour. Integer, so no decimals and no 1-2-5 ladder: 3 and 4 isolines
            // are different pictures and both are ordinary requests.
            NumberField {
                label: "Contours"
                value: root.settings ? root.settings.head_field_contours : 0
                minimumValue: 0
                maximumValue: 64
                decimals: 0
                stepSize: 1
                fieldWidth: 32
                suffixWidth: 0
                // 🐞 D1. What it does is on its face; the tooltip carries only the two facts the
                // face cannot: that 0 is a real setting, and where the levels come from -- which
                // is the one thing about isolines that can be silently wrong.
                ToolTip.visible: contourHover.hovered
                ToolTip.text: "Isolines over the field, at levels evenly spaced across its own "
                            + "range. 0 draws none."
                HoverHandler { id: contourHover }
                onEdited: {
                    if (root.settings)
                        root.settings.head_field_contours = Math.round(value)
                }
            }

            // EEGLAB's conv. The tooltip states a MEASURED number for this montage and stops
            // there: how much of what is on screen is extrapolation. Why one might care is not
            // the tooltip's business.
            CompactCheckBox {
                text: "Hull"
                checked: root.settings ? root.settings.head_field_conv : false
                ToolTip.visible: hovered
                ToolTip.text: checked
                    ? "On: map limited to the electrode hull."
                    : "Off: " + Math.round(topo.extrapolatedFraction * 100)
                      + "% of the map area is extrapolated beyond the electrode hull."
                onClicked: {
                    if (root.settings)
                        root.settings.head_field_conv = checked
                }
            }

            Item { Layout.fillWidth: true }

            Label {
                text: topo.lastSolveMs.toFixed(1) + " ms"
                font.pixelSize: 10
                color: root.inkFaint
                ToolTip.visible: solveHover.hovered
                ToolTip.text: "Solve and grid evaluation. Paint: "
                            + topo.lastPaintMs.toFixed(1) + " ms."
                HoverHandler { id: solveHover }
            }
        }

        // --- the map ---------------------------------------------------------------------------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TopoView {
                id: topo
                anchors.fill: parent

                channelModel: root.channelModel
                values: root.values

                // ⚠ EEG only, by KIND. This montage's EMG pair sits at radius 0.742 against the
                // outermost EEG at 0.665: letting them in pushes plotrad from 0.678 to 0.756 and
                // moves every single electrode. Not cosmetic.
                kind: "EEG"

                backgroundColor: root.paper
                colorVariant: root.settings ? root.settings.head_field_variant : "diverging"
                showLabels: root.settings ? root.settings.head_field_labels : false
                // EEGLAB's own default. Not exposed: a coarser grid is a different picture, and
                // nobody comparing against a reference render wants it to be a setting.
                //
                // ⚠ It is also what pins the CONTOUR LEVELS: zmin/zmax are taken from the sampled
                // grid, so the levels move slightly with gridscale. That is EEGLAB's behaviour,
                // and 200 is what lands on EEGLAB's own numbers.
                gridSize: 200

                // EEGLAB's numcontour and conv. Neither touches the field: the levels come from
                // the rmax-masked grid and the hull limit is applied to the drawing, so flipping
                // `conv` cannot move an isoline or the colour scale. See topoview.hpp.
                numContours: root.settings ? root.settings.head_field_contours : 0
                conv: root.settings ? root.settings.head_field_conv : false

                // A limit of zero has never been set, whatever the checkbox says — an operator who
                // has not chosen one yet must not be shown a blank map because of it.
                autoLimit: root.settings
                           ? (root.settings.head_field_auto_limit
                              || !(root.settings.head_field_limit > 0))
                           : true
                limit: root.settings ? root.settings.head_field_limit : 0
                // EEGLAB's absmax over the GRID, not over the readings: the interpolated surface
                // overshoots its electrodes, and a scale taken from the readings alone would clip
                // the very peaks a topoplot exists to show.
                limitSource: "field"
            }

            // --- hover readout -------------------------------------------------------------
            // Names an electrode, or reads the interpolated field off the paper. Without this the
            // field is a picture; with it, it is an instrument.
            MouseArea {
                id: mapHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                property int channel: -1
                property real fieldValue: NaN

                onPositionChanged: {
                    channel = topo.electrodeAtPixel(mouseX, mouseY, 12)
                    fieldValue = topo.fieldAtPixel(mouseX, mouseY)
                }
                onExited: {
                    channel = -1
                    fieldValue = NaN
                }
            }

            Rectangle {
                visible: mapHover.containsMouse && topo.ok && readoutText.text !== ""
                x: Math.min(Math.max(0, mapHover.mouseX + 12), parent.width - width)
                y: Math.min(Math.max(0, mapHover.mouseY + 12), parent.height - height)
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
                        if (!mapHover.containsMouse)
                            return ""
                        if (mapHover.channel >= 0) {
                            var e = topo.electrodeInfo(mapHover.channel)
                            if (!e || e.name === undefined)
                                return ""
                            // ⚠ The hollow rule said out loud. "no reading" is not "zero", and
                            // an electrode left out of the fit must never be quoted a number.
                            if (!e.contributing)
                                return e.name + " · no reading (hollow, not in the fit)"
                            return e.name + "  "
                                 + Number(e.value / root.tickScale).toFixed(2)
                                 + " " + root.unitText
                        }
                        if (!isFinite(mapHover.fieldValue))
                            return ""
                        return "interpolated  "
                             + Number(mapHover.fieldValue / root.tickScale).toFixed(2)
                             + " " + root.unitText
                    }
                }
            }

            // Nothing to draw, and why. A blank panel teaches the operator the feature is broken.
            Label {
                anchors.centerIn: parent
                visible: !topo.ok
                width: parent.width - 24
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                color: root.inkFaint
                text: topo.status
            }
        }

        // --- the colour scale --------------------------------------------------------------
        ColorBar {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.preferredHeight: implicitHeight
            visible: topo.ok

            // ⚠ Through the C++ item, never a gradient written out in QML: a second copy of the
            // stop table would drift from the first the moment either was touched, and the table
            // is argued from measurements.
            colorAt: function (t) { return topo.colorAt(t) }
            limit: topo.effectiveLimit
            ticks: root.barTicks
            unit: root.unitText
            tickScale: root.tickScale
            ink: root.ink
            inkFaint: root.inkFaint
            lightBackground: root.lightPaper
        }

        // --- caption -----------------------------------------------------------------------
        // ⭐ What the picture represents, in words: WHICH INSTANT, and how many channels got in.
        // A scalp map with no time on it is an assertion about a moment nobody named.
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
                if (topo.status !== "")
                    parts.push(topo.status)
                if (root.warning !== "")
                    parts.push(root.warning)
                return parts.join(" · ")
            }

            ToolTip.visible: capHover.hovered
            ToolTip.text: topo.montageCount + " of " + topo.channelCount
                        + " channels are EEG with a scalp position; "
                        + topo.contributingCount + " are in the fit and "
                        + topo.hollowCount + " are drawn hollow. plotrad "
                        + topo.plotrad.toFixed(6) + ", squeezefac "
                        + topo.squeezefac.toFixed(6) + "."
            HoverHandler { id: capHover }
        }
    }
}
