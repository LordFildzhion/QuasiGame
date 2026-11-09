import QtQuick 2.15

/**
 * The join between two `ChainNode`s.
 *
 * Its whole job is to be the same height as a card so that a lane reads as one line rather than
 * as a row of boxes with glyphs floating above them. `ChainNode.minCardHeight` and this height
 * are the same number for that reason; changing one without the other tilts every lane.
 *
 * `text` is overridable, because not every join is a plain hand-off: `⇢` marks the point where a
 * copy leaves for the calibration thread, `⇉` a split into several streams, `↺` the loop closing
 * back onto the epoch lane.
 */
Text {
    text: "→"
    color: Theme.faint
    font.pixelSize: Theme.fontBody
    height: 66
    verticalAlignment: Text.AlignVCenter
}
