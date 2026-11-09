import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// One stored integer, two editable units. Unit labels are separate from the
// text/selection/clipboard; the ms box always returns to the realizable duration.
RowLayout {
    id: root
    objectName: "frameDurationEditor"
    spacing: 4
    property var parameter: parent
    readonly property var bounds: parameter.attributes || ({})
    readonly property double hz: Number(bounds.frameRateHz || 0)
    readonly property bool rateKnown: isFinite(hz) && hz > 0
    readonly property int minimum: bounds.minimum === undefined ? 1 : bounds.minimum
    readonly property int maximum: bounds.maximum === undefined ? 99999 : bounds.maximum
    readonly property bool locked: parameter.readOnly === true

    function milliseconds(value) { return rateKnown ? (Number(value)*1000/hz).toLocaleString(Qt.locale(), 'f', 1) : "—" }
    function refresh(force) {
        if (!frames || !ms) return
        if (force || !frames.activeFocus || !frames.dirty) { frames.text = (''+parameter.serialized); frames.dirty=false }
        if (force || !ms.activeFocus || !ms.dirty) { ms.text = milliseconds(parameter.serialized); ms.dirty=false }
    }
    function converted(value, fromMs) {
        if (!isFinite(value) || (fromMs && !rateKnown)) return NaN
        return Math.max(minimum, Math.min(maximum, Math.round(fromMs ? value*hz/1000 : value)))
    }
    function commit(field, fromMs) {
        if (!locked && field.dirty && field.acceptableInput && field.text.trim().length) {
            var value = Number.fromLocaleString(Qt.locale(), field.text)
            var count = converted(value, fromMs)
            if (isFinite(count) && parameter.serialized !== count) parameter.serialized = count
        }
        refresh(true)
    }
    Component.onCompleted: refresh(true)
    onHzChanged: refresh(true)
    Connections {
        target: root.parameter
        function onSerializedChanged() { root.refresh(false) }
    }
    TextField {
        id: frames
        property bool dirty: false
        objectName: "durationFrames"
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.minimumWidth: 0
        font.pixelSize: 12
        leftPadding: 5; rightPadding: frameUnit.width + 7
        horizontalAlignment: Text.AlignLeft
        selectByMouse: true
        readOnly: root.locked
        validator: IntValidator {bottom: root.minimum; top: root.maximum}
        onTextEdited: {dirty=true;if (acceptableInput && text.trim().length) ms.text=root.milliseconds(Number.fromLocaleString(Qt.locale(),text))}
        onEditingFinished: root.commit(frames, false)
        onActiveFocusChanged: if(!activeFocus) root.commit(frames, false)
        Label {
            id: frameUnit
            objectName: "frameUnit"
            text: "frames"
            font.pixelSize: 10
            color: frames.palette.placeholderText
            anchors.right: parent.right; anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    TextField {
        id: ms
        property bool dirty: false
        objectName: "durationMilliseconds"
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.minimumWidth: 0
        font.pixelSize: 12
        leftPadding: 5; rightPadding: msUnit.width + 7
        horizontalAlignment: Text.AlignLeft
        selectByMouse: true
        readOnly: root.locked || !root.rateKnown
        validator: DoubleValidator {bottom: 0; top: root.rateKnown ? root.maximum*1000/root.hz : 0; decimals: 3; notation: DoubleValidator.StandardNotation}
        onTextEdited: {dirty=true;if (acceptableInput && text.trim().length && root.rateKnown) frames.text=(''+root.converted(Number.fromLocaleString(Qt.locale(),text),true))}
        onEditingFinished: root.commit(ms, true)
        onActiveFocusChanged: if(!activeFocus) root.commit(ms, true)
        Label {
            id: msUnit
            objectName: "msUnit"
            text: "ms"
            font.pixelSize: 10
            color: ms.palette.placeholderText
            anchors.right: parent.right; anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}

