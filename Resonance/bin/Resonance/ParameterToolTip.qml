// A parameter description, pinned to the parameter panel rather than to whatever was hovered.
//
// A stock Controls 2 ToolTip lays its text out on a single line and grows to fit, so a
// three-sentence parameter description becomes a strip spanning the whole application window --
// far outside the panel the pointer is actually in, and unreadable as a result. There is no
// "maximum width" on ToolTip: the width has to be set, and the content item has to be told to
// wrap at it, which is what this wrapper does.
//
// It also has to be told WHERE to go. A ToolTip defaults to centring on its parent, and these are
// declared on both the label and the control of every row -- two parents of very different widths.
// Combined with a box that shrank to fit its text, that put the same panel's tooltips at a
// different x for every row and made them look like they were jumping about at random. Neither
// variable is left free here:
//
//   * the width is FIXED at the panel's width, so the text wraps edge to edge and a short
//     description makes a short box, never a narrow one;
//   * the x is resolved in WINDOW coordinates and then mapped back through whatever parent this
//     instance happens to have, so a label's tooltip and its control's tooltip land in exactly
//     the same column.
//
// Policy for this tree: a parameter tooltip is exactly as wide as the parameter panel, and always
// appears in the same column beside it.
import QtQuick 2.12
import QtQuick.Window 2.2
import QtQuick.Controls 2.0 as C2

C2.ToolTip {
    id: tip

    /// The parameter panel this tooltip belongs to. Both the width and the placement come from
    /// it, which is what keeps every row's tooltip identical. Without it this degrades to a
    /// plain centred tooltip of `fallbackWidth`, rather than breaking.
    property Item panel: null

    /// Gap between the panel's edge and the tooltip.
    property int gap: 6

    /// Used only when no panel was given.
    property int fallbackWidth: 320

    delay: 500
    // Long enough to read several sentences; the stock 5 s is not.
    timeout: 20000

    // Fixed, not a ceiling. The text wraps into this width and the box is only ever as TALL as
    // the description needs -- which is the axis a reader tolerates varying.
    width: panel ? panel.width : fallbackWidth

    // Beside the hovered row, not above it. The default -height puts a long description over the
    // rows above the one being read; level with it is where the eye already is.
    y: 0

    x: {
        if (!panel || !parent)
            return 0

        // Recomputed against these so the binding re-evaluates when the window is resized or the
        // splitter is dragged; none of them are otherwise read here.
        var _w = tip.width
        var _pw = panel.width

        var panelLeft = panel.mapToItem(null, 0, 0).x
        var panelRight = panel.mapToItem(null, panel.width, 0).x
        var here = parent.mapToItem(null, 0, 0).x

        // To the right of the panel when there is room -- that keeps the parameters themselves
        // readable while the description is open. Otherwise fall back onto the panel, which is
        // always at least as wide as the tooltip and so always fits.
        var windowWidth = panel.Window.window ? panel.Window.window.width : 0
        var toRight = panelRight + gap
        var target = (windowWidth > 0 && toRight + _w <= windowWidth) ? toRight : panelLeft

        return target - here
    }

    contentItem: Text {
        id: body
        text: tip.text
        wrapMode: Text.WordWrap
        width: tip.availableWidth
        color: tip.palette ? tip.palette.toolTipText : "black"
    }
}
