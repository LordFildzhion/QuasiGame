import QtQuick 2.4;
import QtQuick.Controls 1.4
import QtQuick.Window 2.2
import QtQuick.Layouts 1.3
import Resonance 3.0

ApplicationWindow
{
    id: root
    width: 1200
    height: 500
    visible:true
    
    title: "Configurator"
    
    ServiceLocator {
      id: locator
    }

    Component.onCompleted: {
        ResonanceApp.setServiceName("Configurator");
        locator.rescan();
    }

    SplitView {
        anchors.fill: parent

        GroupBox {
            title: "Services"
            width: 220
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent

                Button {
                    width: parent.width
                    height: 20

                    text: "Rescan"

                    onClicked: {
                        locator.rescan();
                    }
                }

                TreeView {
                   id: tree
                   model: locator

                   Layout.fillHeight: true
                   Layout.fillWidth: true

                   TableViewColumn {
                       role: "name"
                       title: "name"
                       width: tree.width-2
                   }

                   onDoubleClicked: {
                       pv.controller = locator.data(index,  ServiceLocator.ControllerRole)
                   }

                   itemDelegate: Item {
                       MouseArea {
                           id: dragArea
                           anchors.fill: parent

                           enabled: styleData.depth>0

                           drag.target: Item {
                                parent: tree

                                Drag.hotSpot.x: 0
                                Drag.hotSpot.y: 0
                                Drag.active: dragArea.drag.active
                                Drag.dragType: Drag.Automatic
                                Drag.supportedActions: Qt.CopyAction
                                Drag.mimeData: {
                                    var ctrlObj = locator.data(styleData.index, ServiceLocator.ControllerRole)
                                    if(ctrlObj && ctrlObj.toJson)
                                    {
                                        return {
                                            "url/stream-connection": JSON.stringify(ctrlObj.toJson())
                                        }
                                    } else {
                                        return {}
                                    }

                                }
                           }
                           
                           onDoubleClicked: {
                               var ctrlObj = locator.data(styleData.index, ServiceLocator.ControllerRole)
                               if(ctrlObj && ctrlObj.toJson) {
                                   viewer.source.serialized = {desiredStream: ctrlObj.toJson()}
                               }
                           }

                           Text {
                               id: txt
                               anchors.verticalCenter: parent.verticalCenter
                               color: styleData.textColor
                               elide: styleData.elideMode
                               text: styleData.value
                           }
                       }
                   }
                }
            }
        }

        ParametersView {
            Layout.preferredWidth: 250
            id: pv
            Layout.fillHeight: true
            Layout.fillWidth: false
        }

        StreamView {
            id: viewer
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
    
}
