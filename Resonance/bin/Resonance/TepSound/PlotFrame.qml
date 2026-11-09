import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * A titled frame with a controls strip along its top and a plot filling the rest.
 *
 * The strip is inside the frame rather than in a settings dialog, because the two things an
 * operator changes constantly — the time range and the amplitude — are the two the legacy put
 * behind a panel that opened somewhere else on the screen.
 */
Rectangle {
    id: root

    property string title: ""
    property string note: ""
    default property alias plotData: holder.data
    property alias controls: strip.data

    color: Theme.panel
    border.color: Theme.rule
    border.width: 1
    radius: 3
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 1
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            Layout.leftMargin: Theme.pad
            Layout.rightMargin: Theme.gap
            spacing: Theme.gap

            Text {
                text: root.title
                color: Theme.dim
                font.pixelSize: Theme.fontSmall
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 0.8
            }
            /**
             * ⚠ The note is the panel's only readout of what it drew, and it ELIDES.
             *
             * At the shipped column widths `TEP · ALL ELECTRODES n = 1 …` hid the fitted
             * interval and the excluded-channel count, and `MEP · AVERAGE ± SD 0.077 m…` hid
             * its own unit. Eliding is still right — the strip beside it holds the controls — but
             * an elided sentence has to be readable somewhere, so hovering it gives the whole
             * thing.
             */
            Text {
                id: noteText
                text: root.note
                color: Theme.faint
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
                Layout.fillWidth: true

                ToolTip.visible: noteHover.containsMouse && noteText.truncated
                ToolTip.delay: 400
                ToolTip.text: root.note
                MouseArea {
                    id: noteHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
            RowLayout {
                id: strip
                spacing: Theme.gap
            }
        }

        Item {
            id: holder
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
