pragma Singleton
import QtQuick 2.15

/**
 * One palette and one set of metrics for the console.
 *
 * A singleton rather than an id, because an id is scoped to the file that declares it: reaching
 * for one from a component defined in another file is a ReferenceError on every evaluation, and
 * the component still *looks* like it works until the binding is exercised.
 *
 * The neutrals are the stimulus console's, deliberately — a rig running both should look like it
 * is running one instrument. The signal colours are the ones the legacy TEP plots used, so an
 * operator reading a green trace here reads the same thing they read there.
 */
QtObject {
    readonly property color paper:    "#15181C"
    readonly property color panel:    "#1B1F25"
    readonly property color raised:   "#232830"
    readonly property color rule:     "#2E353E"
    readonly property color ink:      "#E3E7EB"
    readonly property color dim:      "#8C96A1"
    readonly property color faint:    "#5C6570"

    readonly property color accent:   "#E0A63C"
    readonly property color good:     "#5FB47E"
    readonly property color warn:     "#D9A441"
    readonly property color bad:      "#D2635A"
    readonly property color idle:     "#4E5964"

    // The two signals, kept distinct at a glance: EEG cool, EMG warm.
    readonly property color tep:      "#7FB7D8"
    readonly property color mep:      "#C98A6B"

    readonly property int pad:        10
    readonly property int gap:        6
    readonly property int rowHeight:  24
    readonly property int labelWidth: 108
    readonly property int fontSmall:  11
    readonly property int fontBody:   12
    readonly property int fontLarge:  15
}
