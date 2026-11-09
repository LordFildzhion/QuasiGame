import QtQuick 2.0
import Resonance 3.0
import QtQuick.Controls 1.4


ComboBox {
    id: root
    textRole: "key"
    
    property alias other: binding.other
    property alias otherProperty: binding.otherProperty
    
    Component.onCompleted: {
        binding.enableOtherLeading()
    }
    
    TwoWayBinding {
        id: binding
        
        one: root
        oneProperty: 'currentIndex'
        
        enabled: false
        
        oneToOther: function(x){
            return one.model.get(x)?one.model.get(x).value:0
        }
        otherToOne: function(x){
            for(var i=0; i< one.model.count; ++i){
                if(one.model.get(i).value === x)
                    return i
            }
            return -1
        }
    }
} 
