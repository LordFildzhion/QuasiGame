import QtQuick
import QtQuick.Layouts
import QtQuick.Controls


Loader {
    id: root
    property var labelObject: null
    property var label: null
    property var attributes: null
    property var group: null
    property var name: null
    property var type: null
    property bool readOnly: false
    property int index: -1

    Layout.row: index
    Layout.column: 1

    property var serialized: null
    Layout.fillWidth: true


    //visible: enabled

    source: attributes && attributes.frameDuration === true
            ? 'FrameDuration.qml' : type.replace(/:/g,'_')+'.qml'
}

