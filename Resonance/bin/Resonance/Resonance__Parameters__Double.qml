import QtQuick
import QtQuick.Controls

SpinBox {
    id: self
    readonly property string unit: parent.attributes && parent.attributes.unit ? parent.attributes.unit : ""
    // Separate decoration: never part of the editable value or clipboard text.
    Label {
        id: unitLabel
        objectName: "numberUnit"
        text: self.unit
        visible: text.length > 0
        font.pixelSize: 10
        color: self.palette.placeholderText
        anchors.right: parent.right
        anchors.rightMargin: self.rightPadding
        anchors.verticalCenter: parent.verticalCenter
    }
    Binding {
        target: self.contentItem
        property: "rightPadding"
        value: unitLabel.visible ? unitLabel.implicitWidth + 6 : 0
    }
    Binding {
        target: self.contentItem
        property: "horizontalAlignment"
        value: Text.AlignLeft
    }

    // ⚠ Every read of `attributes` is guarded, and the validator refers to the SpinBox by id
    // rather than through `parent`.
    //
    // The control is created before ParametersView assigns its `attributes`, so each of these
    // bindings evaluates once against an undefined object. Qt reports that as
    // `Unable to assign [undefined] to int` -- harmless in itself, but the distribution
    // validator treats any `file:///...` QML diagnostic as fatal, so it turned into a
    // validation failure that appeared and disappeared with the order the parameters happen to
    // arrive in (seen 2026-09-07, after the parameter sort changed that order).
    property int decimals: parent.attributes ? parent.attributes.decimals : 0
    readonly property real factor: Math.pow(10, decimals)

    from: Math.round((parent.attributes ? parent.attributes.minimum : 0) * factor)
    to: Math.round((parent.attributes ? parent.attributes.maximum : 0) * factor)
    stepSize: Math.max(1, Math.round((parent.attributes ? parent.attributes.stepSize : 1) * factor))
    editable: true

    validator: DoubleValidator {
        bottom: Math.min(self.from, self.to) / self.factor
        top: Math.max(self.from, self.to) / self.factor
        decimals: self.decimals
        notation: DoubleValidator.StandardNotation
    }

    textFromValue: function(scaledValue, locale) {
        return Number(scaledValue / factor).toLocaleString(locale, 'f', decimals)
    }

    valueFromText: function(text, locale) {
        return Math.round(Number.fromLocaleString(locale, text) * factor)
    }

    // See Resonance__Parameters__Integer.qml -- `value` is not bound to parent.serialized so
    // that an incoming service description cannot overwrite an edit in progress.
    property bool __applyingRemote: false

    function __applyRemote() {
        var scaled = Math.round(parent.serialized * factor)
        if (activeFocus || scaled === value) {
            return
        }
        __applyingRemote = true
        value = scaled
        __applyingRemote = false
    }

    function __commit() {
        var realValue = value / factor
        if (!__applyingRemote && parent.serialized !== realValue) {
            parent.serialized = realValue
        }
    }

    Component.onCompleted: {
        __applyRemote()
    }

    Connections {
        target: self.parent
        function onSerializedChanged() {
            self.__applyRemote()
        }
    }

    onValueModified: __commit()
    onDecimalsChanged: __applyRemote()
    onActiveFocusChanged: {
        __applyRemote()
    }
}
