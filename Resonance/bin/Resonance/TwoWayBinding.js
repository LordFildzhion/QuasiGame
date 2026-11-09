/**
 * Does `object` actually carry `property` right now?
 *
 * Both sides of a two-way binding are `property var`s that are filled one at a time, so between
 * `onOneChanged` and `onOtherChanged` exactly one side exists. The signal handler installed by
 * the first assignment is live from that moment, and the very next binding evaluation on that
 * side fires it -- with the other side still undefined.
 *
 * ⚠ The guard this replaces read `Object.keys(o).indexOf(prop)` as a truth test. indexOf returns
 * -1 (truthy) when the property is ABSENT and 0 (falsy) when it is the FIRST key, so it blocked
 * legal captures and passed illegal ones -- which is why the guard was there and the crash
 * happened anyway.
 */
function hasProperty(object, property){
    if(!object || !property) return false
    if(typeof object[property] !== 'undefined') return true
    // Only when the value itself reads as undefined: a declared property that happens to hold
    // undefined is present, and a QObject wrapper lists its declared properties here.
    return Object.keys(object).indexOf(property) !== -1
}

function sidesReady(){
    return hasProperty(state.one.object, state.one.property)
            && hasProperty(state.other.object, state.other.property)
}

function valueChanged(sourceIsOne){
    if(!state.enabled) return
    // ⚠ Reached from a signal handler, not only from captureValue(), so it has to make this
    // check for itself. Without it, every Boolean parameter control threw twice while its panel
    // was being built -- 46 uncaught TypeErrors per tepSound panel, each one unwinding whatever
    // QML was in the middle of doing.
    if(!sidesReady()) return

    let value
    if(sourceIsOne){
        value = state.one.object[state.one.property]
    } else {
        value = state.otherToOne(state.other.object[state.other.property])
    }

    if(sourceIsOne){
        const newValue = state.oneToOther(value)
        const oldValue = state.otherToOne(newValue)
        if(!state.compare(oldValue, value)){
            throw new Error('Infinite transformation detected')
        }

        if(!state.compare(state.other.object[state.other.property], newValue)){

            state.other.object[state.other.property] = newValue
        }
    } else {
        if(!state.compare(state.one.object[state.one.property], value)){
            state.one.object[state.one.property] = value
        }
    }
}

function captureValue(sourceIsOne){
    if(sidesReady()){
        valueChanged(sourceIsOne)
    }
}

function ret(x){
    return x
}

function isEqual(a, b){
    return a === b
}

var state = {
    'one': {
        'object': null,
        'property': null,
        'handler': function(){
            valueChanged(true)
        }
    },
    'other': {
        'object': null,
        'property': null,
        'handler': function(){
            valueChanged(false)
        }
    },
    oneToOther: ret,
    otherToOne: ret,
    compare: isEqual,
    enabled: true
}

function setTransformations(oneToOther, otherToOne, compare){
    state.oneToOther = oneToOther?oneToOther: ret
    state.otherToOne = otherToOne?otherToOne: ret
    state.compare = compare?compare: isEqual
}

function setEnabled(enabled)
{
    state.enabled = enabled
}

function getSignalName(prop){
    if(!prop) return ''
    return 'on'+prop[0].toUpperCase()+prop.slice(1)+'Changed'
}

function sideChanged(state, object, prop){
    // Every step here is guarded because this runs while the binding is half built: the property
    // name can still be empty (getSignalName('') used to index [0] of an empty string and throw),
    // and a name that is set may not name a signal on the object that is set.
    if(state.object && state.property){
        var previous = state.object[getSignalName(state.property)]
        if(previous && previous.disconnect) previous.disconnect(state.handler)
    }
    state.object = object
    state.property = prop
    if(object && prop) {
        var signal = object[getSignalName(prop)]
        if(signal && signal.connect) signal.connect(state.handler)
    }
}
