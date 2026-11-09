import QtQuick 2.0
import "TwoWayBinding.js" as Imp

QtObject {
    property bool enabled: true
    property var one
    property string oneProperty
    property var other
    property string otherProperty
    property var oneToOther: null
    property var otherToOne: null
    property var compare: null
    
    onOneToOtherChanged: Imp.setTransformations(oneToOther, otherToOne, compare)
    onOtherToOneChanged: Imp.setTransformations(oneToOther, otherToOne, compare)
    onCompareChanged: Imp.setTransformations(oneToOther, otherToOne, compare)
    onEnabledChanged: Imp.setEnabled(enabled)
    
    function enableOneLeading(){
        enabled = true
        Imp.captureValue(true)
    }
    
    function enableOtherLeading(){
        enabled = true
        Imp.captureValue(false)
    }
    
    onOneChanged: {
        Imp.sideChanged(Imp.state.one, one, oneProperty)
        Imp.captureValue(true)
    }
    onOnePropertyChanged: {
        Imp.sideChanged(Imp.state.one, one, oneProperty);
        Imp.captureValue(true)
    }
    
    onOtherChanged: {
        Imp.sideChanged(Imp.state.other, other, otherProperty)
        Imp.captureValue(false)
    }        
    onOtherPropertyChanged: {
        Imp.sideChanged(Imp.state.other, other, otherProperty)
        Imp.captureValue(false)
    }
}
