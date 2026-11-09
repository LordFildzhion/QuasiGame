import QtQuick
import QtQuick.Controls

SquareCheckBox {
    id: self
    // The loader stretches every parameter control to the value-column width. Keep an unlabelled
    // boolean at that column's left edge instead of centring it in the stretched area.
    centerIndicatorWhenEmpty: false
    // `parent` is null until the panel parents this control, and `serialized` is null until the
    // service has said what the value is; both read as unchecked rather than as an error.
    checked: parent ? parent.serialized === true : false

    TwoWayBinding {
        one: self
        other: parent
        oneProperty: 'checked'
        otherProperty: 'serialized'
        // ⚠ Was `enabled: parent`, i.e. an object assigned to a bool property. What was meant is
        // "not until there is a control to bind to".
        enabled: !!parent
    }
}
