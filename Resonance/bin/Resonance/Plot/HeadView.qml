import QtQuick 2.15
import QtQuick.Controls 2.15
import Resonance 3.0
import Resonance.Plot 3.0

/**
 * The same channels as the trace view, arranged on the scalp instead of on a time axis.
 *
 * Built for impedance checking, which is the job a montage-shaped display is really for: you are
 * looking for *which* electrodes are bad, and a column of 64 numbers does not answer that while a
 * picture of a head does, immediately.
 *
 * Two things are deliberately different from the version this replaces:
 *
 * - **The head is drawn, not photographed.** The old one laid electrodes over a bitmap of a head
 *   and carried a `/1750` scale factor and a 30-pixel offset to make the two line up, which meant
 *   the positions were correct only at one window size and only for that image. Drawing the
 *   outline from the same polar convention as the electrodes makes them agree by construction.
 * - **It is fitted to the montage, not to the outline.** Electrodes below ear level -- TP9, TP10 --
 *   have a CED radius past 0.5 and belong outside the circle. Fitting to the outline pushed them
 *   off the widget.
 */
Item {
    id: root

    // Nothing here may paint outside its panel: in a side-by-side layout the neighbour is another
    // viewer, and a legend spilling across it reads as a rendering fault.
    clip: true

    /// The TimeSeriesReceiver whose channels are shown. Shared with the trace view, so selection,
    /// colours and groups are the same objects rather than a parallel copy.
    property var plot: null
    property var settings: null
    readonly property var outlinePaths: headOutlineGeometry.headOutline()

    readonly property var channelModel: plot ? plot.channelModel : null

    /// Seconds averaged into each electrode's number.
    property real averageSeconds: settings ? settings.head_average_seconds : 1.0
    /// Thresholds in *display* units, best first. A value at or below `head_good` is good.
    property real goodLevel: settings ? settings.head_good : 10
    property real fairLevel: settings ? settings.head_fair : 20
    property real poorLevel: settings ? settings.head_poor : 35
    /// Disc diameter as a fraction of the map's side, or 0 for "size it from the montage".
    property real discFraction: settings ? settings.head_disc : 0
    property bool showNames: settings ? settings.head_show_names : true
    /// Electrode spread relative to the picture; see Settings.head_scale.
    property real headScale: settings && settings.head_scale > 0 ? settings.head_scale : 1
    /**
     * Whether to draw the circle, nose and ears.
     *
     * Always, when there is no picture -- that *is* the display. Over a picture, only if asked:
     * the picture supplies its own head, and a second circle on top of it is clutter. Worth
     * switching on for as long as it takes to set the scale.
     */
    property bool showOutline: imageUrl == ""
                               || (settings ? settings.head_outline : false)

    /**
     * Disc size when none was set by hand.
     *
     * A montage covers roughly a disc of its own maximum radius, so the room per electrode goes
     * as 1/sqrt(count): what suits 12 electrodes overlaps badly at 128. Fitting the default to
     * the montage is the difference between the map working on connect and needing a setting
     * adjusted every time the cap changes.
     */
    readonly property real autoDisc: {
        var n = Math.max(1, points.length)
        return Math.max(0.035, Math.min(0.16, 0.62 / Math.sqrt(n)))
    }
    readonly property real effectiveDisc: discFraction > 0 ? discFraction : autoDisc

    /**
     * The background image as something QML can load.
     *
     * A bare Windows path is not a URL: QML would resolve `C:\rig\head.png` against this file's
     * own directory and quietly show nothing. A relative path is left alone on purpose, so
     * `../Bricks/topomap64_full_s.png` reaches the montage images that ship beside the QML.
     */
    readonly property url imageUrl: {
        var p = ("" + (settings ? settings.head_image : "")).trim()
        if (p === "")
            return ""
        if (p.indexOf("://") >= 0)
            return p
        if (/^[A-Za-z]:[\\\/]/.test(p) || p.indexOf("\\\\") === 0)
            return "file:///" + p.replace(/\\/g, "/")
        return p
    }

    /// Compact enough for a legend: three significant figures, without an exponent for the
    /// magnitudes these thresholds actually take.
    function shortNumber(v) {
        if (!isFinite(v))
            return "–"
        if (Math.abs(v) >= 1000)
            return Number(v).toPrecision(3)
        return Math.abs(v) >= 10 ? Number(v).toFixed(0) : Number(v).toFixed(1)
    }

    readonly property color goodColor: "#7ec97e"
    readonly property color fairColor: "#e4d977"
    readonly property color poorColor: "#e8a05a"
    readonly property color badColor: "#e0685c"
    /// No finite reading at all. Distinct from "very high": an impedance the amplifier could not
    /// measure arrives as NaN, and showing that as the worst colour would be a guess. It is drawn
    /// hollow so an unconnected electrode cannot be mistaken for a measured bad one.
    readonly property color deadColor: "#4a4a4a"

    property var points: []
    /**
     * Channels the montage says nothing about.
     *
     * A .ced describes electrodes; a recording rarely stops there. Dropping them left the map
     * quietly showing fewer channels than the amplifier was sending, which is the wrong way for a
     * display to disagree with its stream -- so they are drawn in the empty band the head leaves
     * below the occipital row, with the same colours and readings as everything on the scalp.
     */
    property var offMontage: []
    property bool anyPositioned: false

    readonly property color background: settings ? settings.head_background : "#000000"
    /**
     * Text and rules, derived from the background rather than fixed.
     *
     * The map carries a lot of small text -- names, readings, the legend -- and a fixed light grey
     * disappears entirely on a white ground. Choosing the ink from the paper is what makes the
     * background actually selectable rather than merely settable.
     */
    readonly property bool lightBackground:
        0.299 * background.r + 0.587 * background.g + 0.114 * background.b > 0.5
    readonly property color inkStrong: lightBackground ? "#303030" : "#d0d0d0"
    readonly property color inkFaint: lightBackground ? "#5a5a5a" : "#909090"
    readonly property color rule: lightBackground ? "#606060" : "#8a8a8a"

    Rectangle {
        anchors.fill: parent
        color: root.background
        z: -1
    }

    function colorFor(entry) {
        if (!entry.valid)
            return root.deadColor
        var v = entry.value
        if (v <= root.goodLevel) return root.goodColor
        if (v <= root.fairLevel) return root.fairColor
        if (v <= root.poorLevel) return root.poorColor
        return root.badColor
    }

    /**
     * Where the background picture actually landed, for checking alignment.
     *
     * `imageHeadRadius` is the picture's own head circle projected to the screen and
     * `outlineRadius` is the drawn one; they are the same number when the calibration is right,
     * whatever the window size. Exposed because "does the picture line up" is the one thing about
     * this feature that cannot be judged from a description, and it is worth being able to assert
     * rather than squint at.
     */
    function backdropInfo() {
        var ready = backdrop.status === Image.Ready && backdrop.paintedWidth > 0
        return {
            ready: ready,
            paintedWidth: backdrop.paintedWidth,
            paintedHeight: backdrop.paintedHeight,
            originX: map.originX,
            originY: map.originY,
            outlineRadius: map.headRadius,
            scale: map.scale,
            // The invariant: the ear-level circle is head_scale x half the picture's displayed
            // width. Anything that moves the picture must move the electrodes by the same amount,
            // and this is the number that says whether it did.
            radiusOverHalfImage: ready ? map.headRadius / (backdrop.paintedWidth / 2) : 0
        }
    }

    /// Panel and map geometry, so "does the map still fit after a resize" can be asserted rather
    /// than noticed later as a clipped head.
    function geometryInfo() {
        return {
            viewWidth: root.width,
            viewHeight: root.height,
            mapWidth: map.width,
            mapHeight: map.height,
            legendHeight: legend.height
        }
    }

    function refresh() {
        if (!plot) {
            points = []
            offMontage = []
            return
        }
        var all = plot.headValues(averageSeconds)
        var kept = []
        var extra = []
        for (var i = 0; i < all.length; ++i) {
            // The channel list also controls the impedance map. In particular a
            // small cap must not show every unused input of a larger amplifier.
            if (all[i].visible === false)
                continue
            if (all[i].hasPosition)
                kept.push(all[i])
            else
                extra.push(all[i])
        }
        anyPositioned = kept.length > 0
        points = kept
        offMontage = extra
    }

    /**
     * A label for a channel the montage does not describe.
     *
     * The driver's own name is used when it says something -- an amplifier that calls a channel
     * EMG1 knows more than the montage does. `parseCED` fills in "?? 72" for rows it had no label
     * for, which is not a name; those become "#72", which at least says which channel it is.
     */
    function offMontageLabel(entry) {
        var name = ("" + entry.name).trim()
        if (name !== "" && !/^\?\?/.test(name) && !/^Ch\s*\d+$/i.test(name))
            return name
        return "#" + (entry.channel + 1)
    }

    Timer {
        // The map is a slow instrument -- an impedance figure that changes faster than it can be
        // read is not more informative. Four times a second is well past what the eye follows and
        // a small fraction of what recomputing 64 averages costs.
        interval: 250
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Connections {
        target: root.channelModel
        function onAppearanceChanged() { root.refresh() }
        function onSelectionChanged() { root.refresh() }
    }
    Connections {
        target: root.plot
        function onSourceInfoChanged() { root.refresh() }
    }

    // --- geometry ---------------------------------------------------------------------------
    /**
     * How much of the panel the picture may take, so that the *electrodes* still fit.
     *
     * A montage runs past the ear-level circle -- TP9/TP10 at 0.66, an EMG pair at 0.74 -- and the
     * spread is measured against the picture, so at spread 0.739 the outermost electrode sits at
     * 0.55 of the picture's width from centre, not 0.5. Fit the picture to the panel and those
     * electrodes hang outside it and get clipped, which is what happened whenever the window was
     * made wider: the panel changed shape, the picture followed it, and the overhang went with it.
     *
     * Shrinking the picture by this factor keeps picture and electrodes locked together -- they
     * scale by the same number, so the alignment is untouched -- while guaranteeing the widest
     * electrode, disc included, lands inside the panel.
     */
    readonly property real fitFactor: {
        var r = plot ? plot.maxScalpRadius() : 0.5
        var half = headScale * r + effectiveDisc / 2
        return half > 0.5 ? 0.5 / half : 1
    }

    /// Vertical room the legend actually occupies -- its drawn size, not its unscaled one, or the
    /// map would give away space to a legend that has shrunk itself to fit.
    readonly property real legendSpace: legend.visible ? legend.height * legend.scale : 0

    Item {
        id: map
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.legendSpace / 2
        // The square that fits the panel, then shrunk to whatever contains the montage.
        width: Math.max(0, Math.min(root.width, root.height - root.legendSpace - 6))
               * (backdrop.visible ? root.fitFactor : 1)
        height: width

        readonly property real disc: Math.max(8, width * root.effectiveDisc)

        /**
         * Pixels per unit CED radius.
         *
         * With a picture the picture is the reference: it is fitted to the panel and the
         * electrodes are laid over it, with CED radius 0.5 landing at `head_scale` x half the
         * picture's displayed width. Without one the montage is fitted to the panel by the same
         * code the unit tests cover, and the scale is a plain zoom on top.
         *
         * Either way there is exactly one number between the picture and the electrodes, and it
         * is the one the operator adjusts. The version this replaces had that relationship
         * spread across a `fillMode`, a `/1750` factor and a 30-pixel offset, which is why it
         * only ever lined up for one image at one window size.
         */
        readonly property real scale: {
            if (backdrop.visible)
                return root.headScale * backdrop.paintedWidth
            if (!root.plot) return 0
            // A small central montage must not enlarge the nose/ears out of the panel.
            // Bound the same unit-circle polylines used for drawing, alongside the electrodes.
            var extentX = 1, extentY = 1
            for (var p = 0; p < root.outlinePaths.length; ++p)
                for (var i = 0; i < root.outlinePaths[p].length; ++i) {
                    extentX = Math.max(extentX, Math.abs(root.outlinePaths[p][i].x))
                    extentY = Math.max(extentY, Math.abs(root.outlinePaths[p][i].y))
                }
            return Math.max(0, Math.min(root.plot.scalpScale(width, disc / 2),
                                       (width - 4) / extentX, (height - 4) / extentY)) * root.headScale
        }
        /// Radius of the ear-level circle on screen; outline, ears and nose all follow it.
        readonly property real headRadius: 0.5 * scale

        // PreserveAspectFit centres the picture and letterboxes the rest, so the drawn picture
        // starts partway into the item. Measuring from `x` instead of from the painted rectangle
        // is what would put the electrodes half a letterbox off on any non-square panel.
        readonly property real imageLeft: (width - backdrop.paintedWidth) / 2
        readonly property real imageTop: (height - backdrop.paintedHeight) / 2

        /// Where the electrode field is centred: on the picture's head when there is one.
        readonly property real originX: backdrop.visible
            ? imageLeft + (root.settings ? root.settings.head_image_cx : 0.5) * backdrop.paintedWidth
            : width / 2
        readonly property real originY: backdrop.visible
            ? imageTop + (root.settings ? root.settings.head_image_cy : 0.5) * backdrop.paintedHeight
            : height / 2

        clip: true

        /// Fitted to the panel and left alone. Making the *electrodes* follow the picture rather
        /// than the picture follow a description of itself is what turns alignment into one
        /// number somebody can drag until it looks right.
        Image {
            id: backdrop
            anchors.fill: parent
            visible: status === Image.Ready && root.imageUrl != ""
            source: root.imageUrl
            opacity: root.settings ? root.settings.head_image_opacity : 1
            asynchronous: true
            smooth: true
            mipmap: true
            fillMode: Image.PreserveAspectFit
        }

        // Outline, nose and ears. One Canvas rather than a stack of shapes, repainted only when
        // the geometry actually changes.
        Canvas {
            id: outline
            anchors.fill: parent
            visible: root.showOutline
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            Connections {
                target: root
                function onPointsChanged() { outline.requestPaint() }
                function onShowOutlineChanged() { outline.requestPaint() }
                // The fill and the stroke are both chosen from the background.
                function onLightBackgroundChanged() { outline.requestPaint() }
            }

            Connections {
                target: map
                function onOriginXChanged() { outline.requestPaint() }
                function onOriginYChanged() { outline.requestPaint() }
                function onScaleChanged() { outline.requestPaint() }
            }

            onPaint: {
                var c = getContext("2d")
                c.reset()
                var cx = map.originX
                var cy = map.originY
                // The ear-level circle, r = 0.5 in CED units, at the same scale as the electrodes
                // and as the background image, so none of the three can disagree.
                var r = map.headRadius
                if (!(r > 0))
                    return

                // A faint fill as well as a stroke. With a dense montage the outline is mostly
                // hidden behind discs, and a few disconnected arcs do not read as a head; the
                // wash does, and it is what tells the reader which electrodes are off the scalp.
                // Skipped over a picture, which supplies its own ground.
                if (!backdrop.visible) {
                    c.fillStyle = root.lightBackground ? "#eef1f5" : "#181c22"
                    c.beginPath()
                    c.arc(cx, cy, r, 0, 2 * Math.PI)
                    c.fill()
                }

                c.strokeStyle = backdrop.visible ? "#4a90d9" : ("" + root.rule)
                c.lineWidth = 1.5
                c.beginPath()
                c.arc(cx, cy, r, 0, 2 * Math.PI)
                c.stroke()

                // The same normalized polylines as Field, including its rounded nose and ears.
                c.lineJoin = "round"
                c.lineCap = "round"
                var paths = root.outlinePaths
                for (var pathIndex = 0; pathIndex < paths.length; ++pathIndex) {
                    var points = paths[pathIndex]
                    c.beginPath()
                    for (var i = 0; i < points.length; ++i) {
                        var px = cx + points[i].x * r
                        var py = cy - points[i].y * r
                        if (i === 0) c.moveTo(px, py)
                        else c.lineTo(px, py)
                    }
                    c.stroke()
                }
            }
        }

        TopoView { id: headOutlineGeometry; visible: false }

        Repeater {
            model: root.points

            Item {
                id: electrode
                required property var modelData
                required property int index

                width: map.disc
                height: map.disc
                x: map.originX + modelData.x * map.scale - width / 2
                y: map.originY + modelData.y * map.scale - height / 2

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: electrode.modelData.valid
                           ? root.colorFor(electrode.modelData) : "transparent"
                    border.width: electrode.modelData.selected ? 2.5 : 1
                    border.color: electrode.modelData.selected
                                  ? "#4a90d9"
                                  : (electrode.modelData.valid ? "#2a2a2a" : root.deadColor)
                    opacity: electrode.modelData.bad ? 0.4 : 1

                    // The number, in the channel's own display units. Dark on the light threshold
                    // colours, which are chosen light precisely so this stays readable.
                    // Name and reading both inside the disc. Outside it, the label of one
                    // electrode lands on the disc of its neighbour as soon as the montage gets
                    // dense -- on a 64-channel cap every row overprinted the row above it.
                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 4
                        spacing: -1

                        Text {
                            visible: root.showNames && map.disc >= 22
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: electrode.modelData.name
                            color: electrode.modelData.valid ? "#3c3c3c" : "#808080"
                            font.pixelSize: Math.max(6, map.disc * 0.26)
                            fontSizeMode: Text.HorizontalFit
                            minimumPixelSize: 5
                        }

                        // Shrunk to fit rather than elided. A reading rendered as "29…" is worse
                        // than no reading at all: it looks like a number and is not one.
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            // Dark on the threshold colours, which are chosen light so it stays
                            // readable; on a hollow "no reading" disc it is the page's ink.
                            color: electrode.modelData.valid ? "#1a1a1a" : root.inkFaint
                            font.pixelSize: Math.max(7, map.disc * 0.36)
                            font.bold: true
                            fontSizeMode: Text.HorizontalFit
                            minimumPixelSize: 6
                            text: electrode.modelData.valid
                                  ? root.shortNumber(electrode.modelData.value) : "—"
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true

                    onClicked: {
                        var m = root.channelModel
                        if (!m)
                            return
                        if (mouse.modifiers & Qt.ShiftModifier)
                            m.selectRange(electrode.modelData.channel)
                        else if (mouse.modifiers & Qt.ControlModifier)
                            m.toggleSelection(electrode.modelData.channel)
                        else
                            m.selectOnly(electrode.modelData.channel)
                    }

                    ToolTip.visible: containsMouse
                    ToolTip.text: electrode.modelData.name + " · ch "
                                  + (electrode.modelData.channel + 1) + "\n"
                                  + (electrode.modelData.valid
                                     ? (Number(electrode.modelData.value).toPrecision(4) + " "
                                        + electrode.modelData.unit)
                                     : "no reading — over range or not connected")
                }
            }
        }

        // --- channels the montage does not place ---------------------------------------------
        // Inside the map, in the empty band the head leaves below the occipital row -- both the
        // drawn outline and every topomap picture have one. A reserved strip below the map would
        // buy the same result by making the head smaller, which is the wrong trade on a panel
        // whose whole job is the head.
        Row {
            id: offMontageRow
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            spacing: Math.max(3, map.disc * 0.12)
            visible: root.offMontage.length > 0

            Repeater {
                model: root.offMontage

                Rectangle {
                    id: extra
                    required property var modelData

                    width: map.disc
                    height: map.disc
                    radius: width / 2
                    color: modelData.valid ? root.colorFor(modelData) : "transparent"
                    border.width: modelData.selected ? 2.5 : 1
                    border.color: modelData.selected
                                  ? "#4a90d9"
                                  : (modelData.valid ? "#2a2a2a" : root.deadColor)
                    opacity: modelData.bad ? 0.4 : 1

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 4
                        spacing: -1

                        Text {
                            visible: root.showNames && map.disc >= 22
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.offMontageLabel(extra.modelData)
                            color: extra.modelData.valid ? "#3c3c3c" : "#808080"
                            font.pixelSize: Math.max(6, map.disc * 0.26)
                            fontSizeMode: Text.HorizontalFit
                            minimumPixelSize: 5
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            color: extra.modelData.valid ? "#1a1a1a" : root.inkFaint
                            font.pixelSize: Math.max(7, map.disc * 0.36)
                            font.bold: true
                            fontSizeMode: Text.HorizontalFit
                            minimumPixelSize: 6
                            text: extra.modelData.valid
                                  ? root.shortNumber(extra.modelData.value) : "—"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        hoverEnabled: true

                        onClicked: {
                            var m = root.channelModel
                            if (!m)
                                return
                            if (mouse.modifiers & Qt.ShiftModifier)
                                m.selectRange(extra.modelData.channel)
                            else if (mouse.modifiers & Qt.ControlModifier)
                                m.toggleSelection(extra.modelData.channel)
                            else
                                m.selectOnly(extra.modelData.channel)
                        }

                        ToolTip.visible: containsMouse
                        ToolTip.text: extra.modelData.name + " · ch "
                                      + (extra.modelData.channel + 1) + "\n"
                                      + "not in the montage\n"
                                      + (extra.modelData.valid
                                         ? (Number(extra.modelData.value).toPrecision(4) + " "
                                            + extra.modelData.unit)
                                         : "no reading — over range or not connected")
                    }
                }
            }
        }
    }

    // --- legend -----------------------------------------------------------------------------
    Row {
        id: legend
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 4
        spacing: 20
        visible: root.anyPositioned

        // Double size where there is room, shrunk where there is not. A fixed size that suits a
        // wide panel spills straight across the neighbouring viewer when the window is narrowed,
        // and a legend is the one thing on this display that may be smaller rather than cropped.
        transformOrigin: Item.Bottom
        scale: Math.min(1, (root.width - 12) / Math.max(1, implicitWidth))

        Repeater {
            model: [
                { c: root.goodColor, t: "≤ " + root.shortNumber(root.goodLevel) },
                { c: root.fairColor, t: "≤ " + root.shortNumber(root.fairLevel) },
                { c: root.poorColor, t: "≤ " + root.shortNumber(root.poorLevel) },
                { c: root.badColor,  t: "> " + root.shortNumber(root.poorLevel) },
                { c: "transparent",  t: "no reading" }
            ]

            Row {
                required property var modelData
                spacing: 6

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    color: modelData.c
                    border.width: 1
                    border.color: modelData.c === "transparent" ? root.deadColor : "#2a2a2a"
                }
                Text {
                    text: modelData.t
                    color: root.inkFaint
                    font.pixelSize: 20
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Text {
            text: root.points.length > 0 ? (root.points[0].unit || "") : ""
            color: root.inkStrong
            font.pixelSize: 20
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Silence here would look like a broken feature, so say which of the two reasons it is.
    Label {
        anchors.centerIn: parent
        visible: !root.anyPositioned
        horizontalAlignment: Text.AlignHCenter
        color: root.inkFaint
        font.pixelSize: 12
        text: (root.plot && root.plot.channels > 0)
              ? "This stream carries no electrode positions.\n"
                + "The head map needs a montage — give the driver a .ced file."
              : "No stream connected."
    }
}
