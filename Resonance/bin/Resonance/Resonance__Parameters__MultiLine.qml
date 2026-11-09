import QtQuick
import QtQuick.Controls

TextArea {
    id: self

    textFormat: TextEdit.PlainText

    // See Resonance__Parameters__String.qml -- `text` is not bound to parent.serialized so an
    // incoming service description cannot overwrite an edit in progress.
    property bool __applyingRemote: false
    property bool __dirty: false

    // What the service last supplied. An edit is text that differs from *this*, not merely a
    // `textChanged` that arrived while __applyingRemote was false: a Controls 1 TextArea emits
    // textChanged once while it is being constructed, before Component.onCompleted, and keying
    // the dirty flag on timing alone therefore latched it before the delegate had ever seen a
    // value. Two things followed, both silent -- __applyRemote() refused to display the
    // parameter for the life of the panel, and 300 ms later __commit() wrote the empty string
    // back, so opening a service in the Configurator erased every MultiLine parameter it had.
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

    onEditingFinished: __commit()

    Timer {
        id: timer
        interval: 300
        repeat: false

        onTriggered: self.__commit()
    }
}
