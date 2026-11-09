import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * A switch and the number it gates, on one row.
 *
 * This shape recurs all over the processing settings — `useKurtosis` + `kurtosisThreshold`,
 * `preHighpass` + `preHighpassHz`, `badChanEnable` + `badPasses`, `mepRemoveTrend` +
 * `mepTrendWindow` — and it is one setting, not two: the number is meaningless with the switch
 * off, and the switch is meaningless without the number.
 *
 * ⚠ Splitting each pair into two `ParamRow`s is what makes the bad-channel detector ten rows
 * instead of five, and ten rows is the difference between a column that fits on screen and one
 * that has to be scrolled — which is the whole defect this view exists to fix.
 *
 * The label and the tooltip come from the SWITCH, because the switch is the thing the operator is
 * looking for by name. Both are overridable.
 *
 * ⚠ THIS ROW OWNS NO STATE, for the same reason `ParamRow` owns none: a control that assigns its
 * own `checked` keeps the assigned value across a delegate recycle, and this row is meant to be
 * usable inside a `Repeater`.
 */
TepField {
    id: root

    /// The service to resolve both names against. Required.
    property var service: null
    /// The switch — a boolean parameter.
    property string name: ""
    /// The parameter the switch gates.
    property string value: ""
    /// bool | int | double | string | select — the KIND OF THE GATED parameter. The switch is
    /// always a bool.
    property string kind: "double"
    property real step: 1
    property int decimals: 1
    /// Trailing unit. Keep it short: at the shipped column width there are about forty pixels
    /// left after the label, the switch and the editor.
    property string unit: ""

    readonly property var gate: (service !== null && name !== "") ? service.parameter(name) : null
    readonly property var gated: (service !== null && value !== "") ? service.parameter(value)
                                                                    : null

    label: gate !== null ? gate.label : name
    hint: gate !== null ? gate.description : ""

    ParamControl {
        visible: root.gate !== null
        param: root.gate
        kind: "bool"
    }

    ParamControl {
        visible: root.gated !== null
        param: root.gated
        kind: root.kind
        step: root.step
        decimals: root.decimals
        Layout.fillWidth: true
    }

    Text {
        visible: root.unit !== ""
        text: root.unit
        color: Theme.faint
        font.pixelSize: Theme.fontSmall
        elide: Text.ElideRight
    }

    /// A name that resolved to nothing, said out loud. Same reason as `ParamRow`'s: an editor
    /// that accepts a value and has nowhere to put it is silent everywhere else.
    Text {
        visible: root.service !== null
                 && ((root.name !== "" && root.gate === null)
                     || (root.value !== "" && root.gated === null))
        text: "no parameter `" + (root.gate === null ? root.name : root.value) + "`"
        color: Theme.bad
        font.pixelSize: Theme.fontSmall
        elide: Text.ElideRight
        Layout.fillWidth: true
    }
}
