import QtQuick 2.4
import QtQuick.Layouts 1.2
import QtQuick.Controls 1.2


ColumnLayout{

    property var stimulusList: []
    property alias sequence: _sequence.text
	
	function getStimCodeByNumber(i){
		const stim = selected[i - 1];
		return stim?stim:-1
	}

    property var generated: {
        const sep = _sequence.text.split(/[^\d]+/)

        var vec = sep.reduce(function(s, x){
            var foo = selected; // hack to hook self to model change
            if(s===null) return null;

			var i = selected[x-1]; 
            if(!i) return null;
			
            s.push(i);
            return s;
        }, [])
		
		console.log(vec)

        return vec===null?[]:vec

    }
	
	property var selected: []


    GridLayout {
        Repeater {
            model: stimulusList

            delegate: Rectangle {
                
                visible: modelData.col !== null && modelData.row !== null

                Layout.column: modelData.col||0
                Layout.row: modelData.row||0

                width: 98.5
                height: 50

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if(!selected.includes(modelData.code)){
                            selected.push(modelData.code)
							selected = selected;
                        }
                    }
                }

                Image {
                    anchors.fill: parent
                    source: modelData.img
                    smooth: true
                    mipmap: true
                    fillMode: Image.PreserveAspectCrop
                    
                    Text {
                        anchors.centerIn: parent
                        font.pointSize: modelData.fontSize || 40
                        text: modelData.text || ""
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    opacity: 0.75
                }

                Text {
                    anchors.fill: parent
                    text: modelData.name
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    elide: Text.ElideMiddle
                }
            }
        }
    }

    RowLayout {
        Repeater {
            model: selected

            delegate: Rectangle {

                width: 60
                height: 40
				
				property var stim : {
				
					return stimulusList.find(function(x){ return x.code == modelData});
				}

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        selected.splice( index, 1)
						selected = selected;
                    }
                }

                Image {
                    anchors.fill: parent
                    source: stim.img
                    smooth: true
                    mipmap: true
                    fillMode: Image.PreserveAspectCrop
                    
                    Text {
                        anchors.centerIn: parent
                        font.pointSize: stim.fontSize || 40
                        text: stim.text || ""
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    opacity: 0.45
                }

                Text {
                    anchors.fill: parent
                    text: stim.name
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    elide: Text.ElideMiddle
                    clip: true
                }
            }
        }
    }

    TextField {
        //Layout.rightMargin: 1
        //Layout.fillWidth: true
        Layout.preferredWidth: 700


        id: _sequence
        text: '1 2 2 1'

        Rectangle {
            id: indicator
            anchors.left: parent.right

            width: 20
            height: 20
            color: generated!=''?'green':'red'
        }
    }

}
