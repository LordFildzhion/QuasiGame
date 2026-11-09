import QtQuick 2.4;

Rectangle{
    color: "#cecece"
    
    /**
     * [{ img: image
     *    code: code
     *    text: text
     *  }]
     */
    property var stimulusList: []
    property var stimulusId: null
    
    Repeater {
        model: stimulusList
        
        delegate: Item {
            anchors.fill: parent
            visible: modelData.code === stimulusId
            
            Image {
                anchors.fill: parent
                source: modelData.img
                
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                
                Text {
                    anchors.centerIn: parent
                    font.pointSize: modelData.fontSize || 40
                    text: modelData.text || ""
                }
            }
            
            
        }
    }
}



