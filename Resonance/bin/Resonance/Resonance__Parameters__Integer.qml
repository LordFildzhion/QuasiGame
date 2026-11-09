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

    // Guarded for the same reason as Resonance__Parameters__Double.qml: the control exists
    // before ParametersView assigns its `attributes`, and the one evaluation against an
    // undefined object is a QML diagnostic the distribution validator treats as fatal.
    from: parent.attributes ? parent.attributes.minimum : 0
    to: parent.attributes ? parent.attributes.maximum : 0
    stepSize: parent.attributes ? parent.attributes.stepSize : 1
    editable: true

    // `value` is deliberately not bound to parent.serialized. The service re-broadcasts its
    // description whenever anything changes and ParametersView rewrites control.serialized from
    // it, so a live binding snaps the box back mid-edit -- that is what used to erase characters
    // as they were typed and revert the field after dwelling on it.
    property bool __applyingRemote: false

    function __applyRemote() {
        if (activeFocus || parent.serialized === value) {
            return
        }
        __applyingRemote = true
        value = parent.serialized
        __applyingRemote = false
    }

    function __commit() {
        if (!__applyingRemote && parent.serialized !== value) {
            parent.serialized = value
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

    // Qt 6's valueModified signal is user-only. It keeps a remote value assignment from being
    // echoed back as an edit and covers buttons, wheel, keys and typed input.
    onValueModified: __commit()
    onActiveFocusChanged: {
        __applyRemote()
    }
}
