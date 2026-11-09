import QtQuick 2.15
import QtQuick.Controls 2.15

/**
 * One stage of the processing chain, as a card: what the stage is, what it is configured to, and
 * what it costs.
 *
 * ### The latency badge is the whole reason this is a component
 *
 * Every card carries a badge, and the badge always says which of three things the number is:
 *
 * - **measured** — it came off this rig, or off a bench measurement that is written down
 *   somewhere. `holdMs`, `lastTrainMs`, `lastLatencyMs` and the bad-channel timings are these;
 * - **derived** — it is exact by construction and needs no measurement. A trigger detected on the
 *   sample it arrives on costs 0 ms; an epoch cannot be delivered before its own right edge, so
 *   the tail is exactly `windowEnd + guard`;
 * - **unmeasured** — nobody has characterised it. The two causal Butterworths are the honest
 *   examples: they are small and they have phase, and "small" is not a number.
 *
 * ⚠ A card with no badge, or a badge with a plausible figure and no class, is the failure this
 * component exists to prevent. Half the stages either side of any given one carry a real number,
 * which is exactly what makes an invented one impossible to spot by eye — a wrong latency on an
 * engineering diagram reads as fact and gets used to explain an alignment that is actually a bug.
 * That is not hypothetical here: the viewer's display filter costs a measured +20 ms and, unnamed,
 * it read as an alignment defect and cost a session.
 *
 * The class is said in words as well as in colour. Colour alone is a legend nobody has, and two of
 * the three classes are the ones an operator most needs to tell apart in a hurry.
 *
 * ### Selection
 *
 * The card owns no selection state. It writes the shared `selection` object and reads it back, so
 * exactly one card can be current and no card can disagree with another about which — the
 * delegate-recycling class of defect in this tree came from a control that assigned its own
 * `checked` and then kept it.
 */
Rectangle {
    id: root

    /// The stage's name. Short — this is a 164 px card, not a paragraph.
    property string title: ""
    /// The stage's configuration, live. Wraps to at most two lines at the shipped card width.
    property string detail: ""
    /**
     * The sentence that does not fit on the card: what the latency means, what it is measured
     * against, where the number is written down. Shown on hover and in the view's selected-stage
     * strip, never on the card itself — a card that carried it would be three times as tall and
     * the chain would not fit on a screen.
     */
    property string note: ""
    /// The figure itself, e.g. "0 ms", "+700 ms", "1.60 ms". Empty for a stage that is off, or
    /// for one whose class is `unmeasured` and therefore has no figure to print.
    property string latency: ""
    /// measured | derived | unmeasured | none
    property string certainty: "none"

    /// True when the stage is switched off. Drawn faint, and its latency class drops to `none` —
    /// a stage that is not running has no cost, and printing one would be a third kind of lie.
    property bool off: false

    /**
     * The shared single-selection holder: any object with a `node` and a `group` property. Passed
     * in rather than reached for, so this brick has no reference to the view that hosts it.
     */
    property var holder: null

    /// Which settings group configures this stage. Written to the holder on click, so selecting a
    /// card can outline the controls that change it.
    property string group: ""

    readonly property bool selected: holder !== null && holder.node === root

    /// Fixed. A chain reads as a chain because the cards are the same size; a card that sized
    /// itself to its text would turn a pipeline into a bar chart of description lengths.
    property int cardWidth: 164
    /// Floor, so every badge in a lane lands on the same baseline.
    property int minCardHeight: 66

    readonly property color certaintyColour:
          root.off                     ? Theme.faint
        : certainty === "measured"     ? Theme.good
        : certainty === "derived"      ? Theme.tep
        : certainty === "unmeasured"   ? Theme.warn
                                       : Theme.faint

    implicitWidth: cardWidth
    implicitHeight: Math.max(minCardHeight, head.height + badge.height + 14)

    color: root.off ? Theme.panel : Theme.raised
    border.color: root.selected ? Theme.accent : Theme.rule
    border.width: root.selected ? 2 : 1
    radius: 3
    opacity: root.off ? 0.6 : 1.0

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if (root.holder !== null) {
                root.holder.node = root
                root.holder.group = root.group
            }
        }
    }

    TepToolTip {
        text: root.note
        visible: hover.containsMouse && root.note !== ""
        x: 8
        y: root.height
    }

    Column {
        id: head
        x: 7
        y: 5
        width: root.width - 14
        spacing: 1

        Text {
            width: parent.width
            text: root.title
            color: root.off ? Theme.faint : Theme.ink
            font.pixelSize: Theme.fontSmall
            font.bold: true
            font.letterSpacing: 0.4
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: root.detail !== ""
            text: root.detail
            color: Theme.dim
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }

    Row {
        id: badge
        x: 7
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        spacing: 4

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: root.certaintyColour
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            // The class is ALWAYS printed. The dot is a second channel for the same fact, not the
            // only one — a colour is unreadable to a fraction of operators and unmemorable to the
            // rest, and this is the one field on the card that must never be guessed at.
            text: root.off ? "off"
                           : (root.latency !== "" ? root.latency + " · " + root.certainty
                                                  : root.certainty)
            color: root.certaintyColour
            font.pixelSize: Theme.fontSmall
            font.family: "Consolas"
            // Pinned and elided rather than left to grow: a long badge on a fixed-width card
            // draws straight out through the border, and the card is fixed-width on purpose.
            width: root.width - 31
            elide: Text.ElideRight
        }
    }
}
