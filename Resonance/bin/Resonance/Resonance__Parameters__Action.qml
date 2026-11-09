import QtQuick 2.4
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.14
import Resonance 3.0

// A parameter that is a button. With a `prompt` attribute it asks for a line of text first and
// sends it together with the RTC of the click -- so a mark lands where the operator reacted,
// not where they finished typing.
Item {
    id: self
    property var target: parent

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    function attr(name, fallback) {
        return (target && target.attributes && target.attributes[name]) ? target.attributes[name]
                                                                        : fallback
    }

    function invoke(rtc, text) {
        target.serialized = { "invoke": true, "rtc": rtc, "text": text }
    }

    Button {
        id: button
        anchors.left: parent.left
        text: self.attr("buttonText", self.target ? self.target.label : "")
        onClicked: {
            var prompt = self.attr("prompt", "")
            if (prompt === "") {
                self.invoke(ResonanceApp.rtcNow(), "")
                return
            }
            // Captured before the dialog exists, which is the whole point.
            dialog.rtc = ResonanceApp.rtcNow()
            dialog.at = Qt.formatTime(new Date(), "HH:mm:ss.zzz")
            field.text = ""
            dialog.open()
            field.forceActiveFocus()
        }
    }

    Popup {
        id: dialog
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        anchors.centerIn: Overlay.overlay
        padding: 10

        property string rtc: "0"
        property string at: ""

        ColumnLayout {
            spacing: 6
            Label {
                text: self.attr("prompt", "") + "   " + dialog.at
            }
            TextField {
                id: field
                Layout.preferredWidth: 320
                onAccepted: {
                    self.invoke(dialog.rtc, text)
                    dialog.close()
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Button {
                    text: qsTr("Cancel")
                    onClicked: dialog.close()
                }
                Button {
                    text: qsTr("Mark")
                    onClicked: {
                        self.invoke(dialog.rtc, field.text)
                        dialog.close()
                    }
                }
            }
        }
    }
}
