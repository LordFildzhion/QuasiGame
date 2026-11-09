import QtQuick
import QtQuick.Controls

TextField {
    id: self

    // `text` is deliberately not bound to parent.serialized. The service re-broadcasts its
    // description on every change and ParametersView rewrites control.serialized from it, so a
    // live binding overwrites the field mid-edit and erases characters as they are typed.
    property bool __applyingRemote: false
    property bool __dirty: false

    // What the service last supplied -- see Resonance__Parameters__MultiLine.qml. A TextField
    // does not emit textChanged while it is being constructed and a TextArea does, so only the
    // MultiLine delegate was observed erasing its parameter; the guard is the same here because
    // the shape that allowed it is the same, and a delegate that can silently blank a preset
    // string is not worth leaving on that distinction.
    property string __remoteText: ""

    function __applyRemote() {
        if (__dirty) {
            return
        }
        if (parent.serialized === text) {
            __remoteText = text
            return
        }
        __applyingRemote = true
        text = parent.serialized
        __applyingRemote = false
        __remoteText = text
    }

    function __commit() {
        if (parent.serialized !== text) {
            parent.serialized = text
        }
        __dirty = false
        __remoteText = text
    }

    Component.onCompleted: __applyRemote()

    Connections {
        target: self.parent
        function onSerializedChanged() {
            self.__applyRemote()
        }
    }

    onTextChanged: {
        if (!__applyingRemote && text !== __remoteText) {
            __dirty = true
            timer.restart()
        }
    }

    onActiveFocusChanged: {
        __commit()
        __applyRemote()
    }

    Timer {
        id: timer
        interval: 300
        repeat: false

        onTriggered: self.__commit()
    }
}
