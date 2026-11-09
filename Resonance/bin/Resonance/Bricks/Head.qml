import QtQuick 2.5

Image {
    id: head
	
    //property string cedFile: ''
    property var measurements: []
    property var colorScale: [
        {color: '#00000000'},
        {value: 95, color: 'red'},
        {value: 25, color: 'yellow'},
        {value: 10, color: 'green'}
    ]
    property alias points: points
    property var signalSource: null
    property var imageSource: "head_mp_text.png"
    property var channelsMap: []
    property double valueScaleFactor: 1.0
    /// Window the reading is averaged over. A device reports impedance a few times a second and
    /// consecutive readings differ by a kilohm or two, so the raw value will not sit still.
    property double averageSeconds: 1.0
    property var _metaData: signalSource?signalSource.sourceInfo.metaData:null
    property var size: Math.min(width, height)

    source: imageSource
    fillMode: Image.PreserveAspectFit

    /**
     * Superseded by Plot/HeadView.qml, which draws the head rather than laying electrodes over a
     * bitmap. Kept working for the experiment QML that still imports Resonance.Bricks.
     *
     * Polled rather than driven from onDataReceived: the readings are averaged anyway, and at
     * 1 kHz that signal fires far more often than a person can read a number.
     */
    Timer {
        interval: 250
        repeat: true
        running: head.visible && head.signalSource !== null
        onTriggered: {
            // headValues() replaced the old lastValues property in the 2026-08-13 viewer rework.
            // baseValue is in the channel's own base unit (ohms), which is what valueScaleFactor
            // is written against; `valid` is false for a channel the device could not measure,
            // and an unmeasured electrode must not read as a good one.
            const readings = head.signalSource.headValues(head.averageSeconds)
            var m = []
            if (head.channelsMap.length === 0) {
                for (var i = 0; i < readings.length; ++i) {
                    if (readings[i].valid)
                        m[i] = readings[i].baseValue * head.valueScaleFactor
                }
            } else {
                head.channelsMap.forEach(function(to, from){
                    if (from < readings.length && readings[from].valid)
                        m[to] = readings[from].baseValue * head.valueScaleFactor
                })
            }
            head.measurements = m
        }
    }
    
    on_MetaDataChanged: {
        if(/*cedFile === '' &&*/ _metaData && _metaData.channelPropertyNames().length>0 )
        {
            points.clear();
            const names = _metaData.channelProperty('name')
            const theta = _metaData.channelProperty('theta')
            const radius = _metaData.channelProperty('radius')
            for(let i in names){
                points.append({
                                  name:names[i],
                                  theta: theta[i],
                                  radius: radius[i]
                              })
            }
        }
    }
    
    /*onCedFileChanged: {
        // load ced file
        var xhr = new XMLHttpRequest;
        xhr.open("GET", cedFile);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var file = xhr.responseText;
                points.clear();
                
                var lines = file.split('\r\n');
                lines.shift() // remove header
                
                lines.map(function(row){
                    var cols = row.split('\t');
                    if(cols.length >= 10)
                        points.append({
                                          number:     cols[0],
                                          name:       cols[1],
                                          theta:      cols[2],
                                          radius:     cols[3],
                                          x:          cols[4],
                                          y:          cols[5],
                                          z:          cols[6],
                                          sph_theta:  cols[7],
                                          sph_phi:    cols[8],
                                          sph_radius: cols[9]
                                      });
                })
            }
        };
        xhr.send();
    }*/
    
    
    ListModel {
        id: points
    }
    
    Repeater {
        model: points
        
        Rectangle {
            radius: 15
            width: 2*radius
            height: 2*radius
            border.width: 1
            
            color: {
                // calculate color from value
                var color = head.colorScale[0].color
                var meas = head.measurements[index];
                head.colorScale.map(function(level){
                    if(level.value>= meas){
                        color = level.color;
                    }
                })
                return color;
            }
            
            Text {
                anchors.centerIn: parent
                font.pixelSize: 16
                text: {
                    var meas = head.measurements[index];
                    if(meas !== undefined && meas < 100){
                        return meas.toFixed(0);
                    } else {
                        return '';
                    }
                }
            }
            
            //x: head.width/2*(1 + 2*Math.cos((theta-90)/180*Math.PI)*model.radius)-width/2
            //y: head.height/2*(1 + 2*Math.sin((theta-90)/180*Math.PI)*model.radius)-height/2
			
			
			
            x: head.width/2 - width/2 + head.size*Math.cos((model.theta - 90)/180 *Math.PI)*model.radius
            y: head.height/2 - height/2 + head.size*Math.sin((model.theta - 90)/180 *Math.PI)*model.radius
        }
    }
}
