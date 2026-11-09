import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * One labelled parameter row, resolved by NAME.
 *
 * `TepField` + `ParamControl` is the pair every settings row in this console is built from, and
 * writing the pair out by hand cost three lines and two lookups each: `label:`, `hint:
 * root.hintFor("x")`, `ParamControl { param: root.param("x"); kind: ... }`. Seventy-one of those
 * lived in one file with two file-private helpers behind them, and the four views that replace
 * that file would have needed four copies of the helpers — which is four things to drift.
 *
 * So the lookup moves into the brick. A row is now:
 *
 *     ParamRow { service: view.service; name: "guardMs"; kind: "int"; step: 10; unit: "ms" }
 *
 * and the label and the tooltip come from the parameter itself, which means they cannot disagree
 * with the Configurator's. Both are still overridable — several rows in this console deliberately
 * say something shorter or more specific than the parameter's own label.
 *
 * `service` is required and has no default. A brick that reached for the `tep` context property
 * by bare name would work in this console and be a ReferenceError in any other host that imports
 * `Resonance.TepSound`, and the failure would appear as a row that silently edits nothing.
 *
 * ⚠ THIS ROW OWNS NO STATE. Every editor binds to the parameter object and writes back to it;
 * nothing here caches a value. That is what makes it safe inside a `Repeater` or a `ListView`
 * delegate — the delegate-recycling defect in this tree was a control assigning its own `checked`
 * on release, and the assigned value then survived recycling onto a different row.
 */
TepField {
    id: root

    /// The service to resolve `name` against. Required.
    property var service: null
    /// The parameter's name, as declared in the service.
    property string name: ""
    /// bool | int | double | string | select | action — passed straight to `ParamControl`.
    property string kind: "string"
    /// Trailing unit or note, in the faint colour the settings rows already use. Empty means none.
    property string unit: ""
    /**
     * Pin the unit column to this width, so a stack of rows shares one right edge.
     *
     * ⚠ 0 (the default) means "as wide as the text", which is what every column in this console
     * had — and it means the EDITOR's width is whatever the unit leaves, so a row whose unit is
     * `ms after delivery` has a narrower spin box than the row above it whose unit is `ms`. On
     * the Feedback view that produced three spin boxes whose `+` buttons stood at three different
     * x, measured 71 px apart, with the labels perfectly aligned above them. Nothing was clipped
     * and it read as broken, which is the second half of what the operator asked for: elements
     * that VISUALLY align.
     *
     * Set it once on a column and every row in that column lines up. The unit still elides inside
     * its slot, so pinning it too narrow costs text rather than layout.
     */
    property int unitWidth: 0
    /// Spin-box step, for `int`.
    property real step: 1
    /// Decimal places, for `double`.
    property int decimals: 1
    /**
     * Whether the editor takes the rest of the row.
     *
     * True for anything with a value to read; false for a check box or a button, which have a
     * width of their own and look wrong stretched across a column.
     */
    property bool fill: kind !== "bool" && kind !== "action"

    /// The resolved parameter object, or null. Exposed so a caller can bind to `.value` without
    /// a second lookup — the Stimuli and Processing views both need that for their diagrams.
    readonly property var param:
        (service !== null && name !== "") ? service.parameter(name) : null

    // Both overridable: assigning `label:` or `hint:` at the call site replaces these bindings.
    label: param !== null ? param.label : name
    hint: param !== null ? param.description : ""

    ParamControl {
        // Hidden rather than empty when the name resolved to nothing: an editor that accepts a
        // value and has nowhere to put it is the failure the marker below exists to catch, and
        // leaving it on screen beside the marker is leaving the trap set.
        visible: root.param !== null
        param: root.param
        kind: root.kind
        step: root.step
        decimals: root.decimals
        Layout.fillWidth: root.fill
    }

    Text {
        // Reserved even with no text once the column is pinned: a row with no unit must still
        // leave the slot, or its editor is 110 px wider than its neighbours' and the column's
        // right edge is ragged again — which is the defect, not the unit.
        visible: root.unit !== "" || root.unitWidth > 0
        text: root.unit
        color: Theme.faint
        font.pixelSize: Theme.fontSmall
        elide: Text.ElideRight
        // Pinned only when asked. `Layout.preferredWidth: -1` is "use the implicit width", which
        // is exactly the old behaviour, so every existing row is unchanged.
        Layout.preferredWidth: root.unitWidth > 0 ? root.unitWidth : -1
        Layout.minimumWidth: root.unitWidth > 0 ? root.unitWidth : 0
        Layout.maximumWidth: root.unitWidth > 0 ? root.unitWidth : Number.POSITIVE_INFINITY
    }

    /**
     * A name that resolves to nothing is a typo, and it must not look like a setting that happens
     * to be blank.
     *
     * `parameter()` returns null for an unknown name with no warning anywhere, so a misspelt row
     * renders as an empty editor that accepts input and discards it. This is the only thing on
     * the row that is not about the parameter, and it appears only when there is no parameter.
     */
    Text {
        visible: root.service !== null && root.name !== "" && root.param === null
        text: "no parameter `" + root.name + "`"
        color: Theme.bad
        font.pixelSize: Theme.fontSmall
        elide: Text.ElideRight
        Layout.fillWidth: true
    }
}
