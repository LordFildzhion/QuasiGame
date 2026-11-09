import QtQuick 2.15

/**
 * A check or a cross, drawn from line segments.
 *
 * ⚠ WHAT THIS DRAWS IS A PLACEHOLDER. The service has no classifier; `verdict` is produced by a
 * counter or a coin — see `TepSoundService::postFeedback()`. This component knows nothing about
 * that and would draw a real verdict identically, which is exactly why the caller has to be the
 * one that says so.
 *
 * Two callers, one file: the subject's stage draws it for the subject, and the Feedback view
 * draws the same glyph beside the settings so the operator can see what the subject will get
 * without a subject in front of it. Two hand-rolled copies of the same geometry is two glyphs
 * that eventually stop matching, and the whole point of the operator's copy is that it matches.
 *
 * ### Why rectangles
 *
 * Not a font: there is no glyph in a guaranteed font that is a check mark, and a missing glyph
 * renders as a box — on the subject's screen, mid-session. Not a `Canvas` either: this is drawn
 * on the frame-locked stage window, and a Canvas repaints through a texture upload at the moment
 * the mark appears. Rotated rectangles cost a transform on two nodes that already exist.
 *
 * ### Colour
 *
 * `ink` has no default that would make it visible anywhere in particular, on purpose. The
 * console's convention for a mark over a continuous field is black; the STAGE's convention is
 * `stageWindow.textColour`, derived from the protocol's own background so a cue on white paper
 * is still legible — and black on the default black stage would be an invisible mark that looks
 * exactly like a broken one. The caller passes the ink its own surface uses.
 */
Item {
    id: root

    /// -1 nothing, 0 cross, 1 check. Anything else draws the cross.
    property int verdict: -1
    /// The surface's own ink. Required — see the note above.
    property color ink: "#EFEFEF"
    /// Bar width. Scales with the mark so one size setting is enough.
    readonly property real stroke: Math.max(2, height * 0.15)

    implicitWidth: implicitHeight
    visible: verdict >= 0

    // Endpoints in a unit box, y down: [x1, y1, x2, y2].
    //
    // The check's vertex sits low and left of centre and its long arm overshoots the box's top
    // right, which is what makes it read as a check rather than as a bent line.
    readonly property var checkSegments: [[0.06, 0.52, 0.38, 0.84], [0.38, 0.84, 0.96, 0.14]]
    readonly property var crossSegments: [[0.12, 0.12, 0.88, 0.88], [0.88, 0.12, 0.12, 0.88]]

    Repeater {
        model: root.verdict === 1 ? root.checkSegments : root.crossSegments

        /**
         * ⚠ The delegate owns no state. Every property below is `readonly` and derived from
         * `modelData` and `root`; nothing is assigned from a handler. The recycling defect in
         * this tree was a control writing its own property on release, and the written value
         * then survived onto a different row.
         */
        delegate: Rectangle {
            readonly property real x1: modelData[0] * root.width
            readonly property real y1: modelData[1] * root.height
            readonly property real x2: modelData[2] * root.width
            readonly property real y2: modelData[3] * root.height

            // The bar starts at (x1, y1) and is rotated about that point, so `Item.Left` — the
            // middle of the left edge — is the only transform origin that keeps the joint of the
            // check's two arms actually joined.
            x: x1
            y: y1 - root.stroke / 2
            width: Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
            height: root.stroke
            radius: root.stroke / 2
            color: root.ink
            antialiasing: true
            transformOrigin: Item.Left
            rotation: Math.atan2(y2 - y1, x2 - x1) * 180 / Math.PI
        }
    }
}
