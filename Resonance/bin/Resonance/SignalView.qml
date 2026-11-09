import QtQuick 2.0
import QtQuick.Layouts 1.3
import Resonance 3.0
import QtQuick.Controls 1.4

Rectangle {
	border.width: 1
    clip: true

    Canvas {
        id: canvas
        anchors.fill: parent

        Connections {
            target: plot
            onOffsetChanged: {
                canvas.requestPaint()
            }

            onDurationChanged: {
                canvas.requestPaint()
            }

            onScaleChanged: {
                canvas.requestPaint()
            }
        }
        Connections {
            target: ui_line1
            onValueChanged: {
                canvas.requestPaint()
            }
        }
        Connections {
            target: ui_line2
            onValueChanged: {
                canvas.requestPaint()
            }
        }

        onPaint: {
            var ctx=getContext('2d');
            ctx.beginPath();
            ctx.fillStyle = Qt.rgba(1,1,1,1);
            ctx.globalCompositeOperation = 'copy';
            ctx.fillRect(0, 0, width, height);
            ctx.globalCompositeOperation = 'source-over';
            ctx.lineWidth = 0.5;

            var totalCh = (plot.visibleChannels.length?plot.visibleChannels.length:plot.channels);

            var offset = plot.offset + plot.channelHeight/2


            function dashedLine(start_x, start_y, end_x, end_y){
                var length = 10
                var space = 8
                var dash_length = 1
                var dash_space = 1
                var stipple_length = (dash_length + dash_space) > 0 ? (dash_length + dash_space) : 16

                var dashLen = stipple_length;
                var dX = end_x - start_x;
                var dY = end_y - start_y;
                var dashes = Math.floor(Math.sqrt(dX * dX + dY * dY) / dashLen);
                if (dashes == 0)
                {
                    dashes = 1;
                }
                var dash_to_length = dash_length/dashLen
                var space_to_length = 1 - dash_to_length
                var dashX = dX / dashes;
                var dashY = dY / dashes;
                var x1 = start_x;
                var y1 = start_y;

                ctx.moveTo(x1,y1);

                var q = 0;
                while (q++ < dashes) {
                    x1 += dashX*dash_to_length;
                    y1 += dashY*dash_to_length;
                    ctx.lineTo(x1, y1);
                    x1 += dashX*space_to_length;
                    y1 += dashY*space_to_length;
                    ctx.moveTo(x1, y1);
                }
            }

            for(var ch=0; ch< totalCh; ch++, offset += plot.channelHeight){
                var y;

                ctx.beginPath();
                ctx.strokeStyle = 'grey'
                ctx.fillStyle = 'black'
                ctx.font = "16px Arial";
                ctx.textAlign = 'right'
                ctx.lineWidth = 0.5;


                for(var i=1; i<=3; ++i){
                    var n = (plotSettings.min + (plotSettings.max-plotSettings.min)/4*i)
                    y = offset - n*plot.scale

                    y = Math.round(y)+0.5
                    dashedLine(0, y, width, y)

                    ctx.fillText((n/Math.pow(10, ui_multiply.value)).toFixed(1), 30, y-3);
                }

                ctx.stroke();
                ctx.closePath();

                ctx.beginPath();
                ctx.strokeStyle = 'red';
                ctx.lineWidth = 0.5;
                y = -ui_line1.value * Math.pow(10, ui_multiply.value) * plot.scale + offset;
                y = Math.round(y)+0.5
                ctx.moveTo(0, y)
                ctx.lineTo(width, y)
                ctx.stroke();
                ctx.closePath();

                ctx.beginPath();
                ctx.strokeStyle = 'blue';
                ctx.lineWidth = 0.5;
                y = -ui_line2.value * Math.pow(10, ui_multiply.value) * plot.scale + offset;
                y = Math.round(y)+0.5
                ctx.moveTo(0, y)
                ctx.lineTo(width, y)
                ctx.stroke();
                ctx.closePath();
            }

            var xw = width/plot.duration
            for(var x=xw; x<width; x+=xw){
                ctx.beginPath();
                ctx.strokeStyle = 'grey' // '#ebebeb'  Qt.rgba(0.5,0.5,0.5,1);
                ctx.lineWidth = 1;
                dashedLine(Math.round(x)+0.5, 0, Math.round(x)+0.5, height)
                ctx.stroke();
                ctx.closePath();
            }
        }
    }

	TimeSeriesReceiver {
		id: plot

		clip: true
		
		source: pidLog.stream

		anchors.fill: parent

        duration: ui_time.value
        lineWidth: 2

		visible: true
		enabled: true

		highpass: 0
		lowpass: 0
		notch: 0

        property double channelHeight: height/ (visibleChannels.length?visibleChannels.length:channels)
        scale: channelHeight/(plotSettings.max-plotSettings.min)
        offset: (plotSettings.max+plotSettings.min)/2*scale

        visibleChannels: [0, 0]

	}

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: plot.width*plot.cursorPosition-1
        width: 4
        color: "#FF8800"
    }

	ColumnLayout {
		anchors.right: parent.right
		anchors.top: parent.top
		anchors.bottom: parent.bottom

		width: 60


        Repeater {
            model: plot.visibleChannels.length

            Text {
                text: plot.lastValues[plot.visibleChannels[index]].toFixed(3)
            }
        }

	}

	MouseArea {
		anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
		onClicked: {
			if(mouse.button === Qt.RightButton){
				plotSettings.visible = !plotSettings.visible;
			}
		}
	}

	Rectangle {
		id: plotSettings
        color: Qt.rgba(1,1,1,0.7)
		anchors.fill: parent
        visible: false

        property double min: ui_min.value * Math.pow(10, ui_multiply.value)
        property double max: ui_max.value * Math.pow(10, ui_multiply.value)

        GridLayout {
            anchors.fill: parent



            SpinBox {
                id: ui_multiply
                minimumValue: -6
                maximumValue: 0
                decimals: 0

                prefix: '1E'
            }

            SpinBox {
                id: ui_min
                minimumValue: -999999.9
                maximumValue: 999999.9
                decimals: 1
                stepSize: 0.1
                value: -10
            }

            SpinBox {
                id: ui_max
                minimumValue: -999999.9
                maximumValue: 999999.9
                decimals: 1
                stepSize: 0.1
                value: 10
            }

            SpinBox {
                id: ui_time

                minimumValue: 1
                maximumValue: 99
                value: 4
            }

            SpinBox {
                id: ui_line1
                minimumValue: -99.999
                maximumValue: 99.999
                decimals: 3
                stepSize: 0.1
                value: 3
            }

            SpinBox {
                id: ui_line2
                minimumValue: -99.999
                maximumValue: 99.999
                decimals: 3
                stepSize: 0.1
                value: -7
            }
        }
	}
}
