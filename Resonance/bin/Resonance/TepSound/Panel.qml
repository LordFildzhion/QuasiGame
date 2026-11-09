import QtQuick 2.15
import QtQuick.Layouts 1.15

/// A titled box. `content` is a column; anything declared inside lands in it.
Rectangle {
    id: root

    property string title: ""
    property string hint: ""
    default property alias contentData: body.data

    color: Theme.panel
    border.color: Theme.rule
    border.width: 1
    radius: 3
    clip: true
    implicitHeight: column.implicitHeight + Theme.pad * 2

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: Theme.pad
        spacing: Theme.gap

        RowLayout {
            visible: root.title !== ""
            Layout.fillWidth: true
            spacing: Theme.gap

            Text {
                text: root.title
                color: Theme.dim
                font.pixelSize: Theme.fontSmall
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 0.8
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumWidth: 8
                height: 1
                color: Theme.rule
            }
            /**
             * \warning THE HINT MAY NOT WIDEN THE PANEL.
             *
             * It could not shrink and it could not elide, so its full length went into the
             * title row's implicit width, into the panel's, and into the settings pane's
             * content width — and a `ScrollView` sizes its content item from that, which
             * destroys the `width: availableWidth` binding underneath it. The panel then laid
             * itself out WIDER than the visible pane and every right-aligned value in it was
             * drawn past the clip: `Lambda` read as an empty box, `Iterations` lost its `+`.
             *
             * The trigger was a live status line growing — `SOUND` gains
             * `model 9 · 100 epochs · ref P2 · σ med 2.20 max 11.62 µV` once a model exists — so
             * the panel was correct at launch and wrong ten epochs later.
             */
            Text {
                id: hintText
                visible: root.hint !== ""
                text: root.hint
                color: Theme.faint
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.maximumWidth: hintText.implicitWidth
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.gap
        }
    }
}
