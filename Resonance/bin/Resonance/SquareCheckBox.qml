import QtQuick
import QtQuick.Controls

// Compact desktop checkbox shared by the Configurator chrome and parameter delegates. A solid
// inner square stays legible at any scaling factor without depending on a glyph font or escaping
// the dense table row that owns it.
CheckBox {
    id: control

    property int boxSize: 13
    // Table cells have a deliberately fixed width and look best centred. Parameter editors fill
    // a shared value column and must instead start at that column's left edge.
    property bool centerIndicatorWhenEmpty: true

    padding: 0
    spacing: 5
    implicitHeight: Math.max(16, contentItem.implicitHeight, indicator.implicitHeight)

    indicator: Rectangle {
        implicitWidth: control.boxSize
        implicitHeight: control.boxSize
        x: control.text || !control.centerIndicatorWhenEmpty
           ? control.leftPadding
           : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        color: control.enabled ? control.palette.base : control.palette.button
        border.width: 1
        border.color: control.activeFocus ? control.palette.highlight
                                          : (control.hovered ? control.palette.dark
                                                             : control.palette.mid)

        Rectangle {
            anchors.centerIn: parent
            width: 7
            height: 7
            visible: control.checkState !== Qt.Unchecked
            color: control.enabled ? control.palette.text : control.palette.mid
        }
    }

    contentItem: Text {
        leftPadding: control.indicator && !control.mirrored
                     ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.mirrored
                      ? control.indicator.width + control.spacing : 0
        text: control.text
        font: control.font
        color: control.enabled ? control.palette.windowText : control.palette.mid
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
}
