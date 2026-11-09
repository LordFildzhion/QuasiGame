import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * An editor bound to one `Resonance::Parameters::*` object.
 *
 * The point of binding to the parameter object rather than to a copy is that there is no copy:
 * the console and the Configurator edit the same object, so neither can be showing a stale value
 * and there is nothing to reconcile when a saved configuration is applied while the window is
 * open.
 *
 * `kind` is given explicitly by the caller instead of being sniffed from the object. Sniffing
 * would work until a parameter type gained a property that made it look like another one, and
 * the failure would be a control that silently edits nothing.
 */
Item {
    id: root

    property QtObject param: null
    property string kind: "string"   // bool | int | double | string | select | action
    property string suffix: ""
    property real step: 1
    property int decimals: 1

    implicitHeight: 24
    implicitWidth: loader.implicitWidth

    /**
     * ⚠ An editor that fills its row needs a FLOOR.
     *
     * A `RowLayout` shrinks its `fillWidth` children down to `Layout.minimumWidth` — which
     * defaults to **0** — before it will let the row overflow. At the settings pane's shipped
     * 330 px that collapsed every `double` field to an empty box and pushed the trailing units
     * ("of the cap", "epochs") off the edge: `Lambda`, `Kurtosis`, `Amplitude`, `Incoherence`,
     * `Neighbour`, `Flatline` and `Repair at most` all read as if no value were set, in the
     * panels that decide the SOUND regularisation and which electrodes get repaired.
     *
     * A check box has nothing to shrink, so it keeps its own width.
     */
    /**
     * ⚠ AND `int` NEEDS A BIGGER FLOOR THAN THE REST — measured, not assumed.
     *
     * The `int` editor is a Controls 2 `SpinBox`, and its up/down indicators are drawn by the
     * style OUTSIDE the `contentItem`. Measured off a rendered console — the light runs either
     * side of the digits — each indicator is **40 px**, so 80 of any width handed to a spin box
     * is gone before a digit is drawn. At the 66 px floor above the digits get nothing.
     *
     * That is not a cosmetic squeeze, it is a box that states a number the service does not
     * hold. On the Processing view's 228 px columns it read: `eegChannels` 64 as "4",
     * `emgChannelA` 65 as "5", `workRate` 5000 as "0", and `windowStart` / `windowEnd` /
     * `guardMs` — which carry a trailing "ms" and so are squeezed hardest — as **blank**. An
     * operator reading the epoch window off that column reads a fabrication.
     *
     * 110 = 80 for the two indicators + 30 for the digits, which holds "-2000" at `fontBody`.
     * The other kinds are plain fields with no furniture either side and keep the 66.
     */
    Layout.minimumWidth: (root.kind === "bool" || root.kind === "action")
                         ? root.implicitWidth
                         : root.kind === "int" ? 110 : 66

    // No tooltip here. The explanation belongs on the row's *label* (TepField), where a pointer
    // that is reading rather than about to drag naturally goes, and where it cannot cover the
    // control it describes.

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: root.kind === "bool"   ? boolEditor
                       : root.kind === "int"    ? intEditor
                       : root.kind === "double" ? doubleEditor
                       : root.kind === "select" ? selectEditor
                       : root.kind === "action" ? actionEditor
                                                : stringEditor
    }

    Component {
        id: boolEditor
        CheckBox {
            checked: root.param !== null ? root.param.value : false
            onToggled: if (root.param !== null) root.param.value = checked
            indicator: Rectangle {
                implicitWidth: 15
                implicitHeight: 15
                x: 0
                y: parent.height / 2 - height / 2
                radius: 2
                color: parent.checked ? Theme.accent : Theme.raised
                border.color: Theme.rule
            }
            contentItem: Item {}
            padding: 0
            implicitHeight: 22
            implicitWidth: 18
        }
    }

    Component {
        id: intEditor
        SpinBox {
            from: root.param !== null ? root.param.minimum : -2147483647
            to: root.param !== null ? root.param.maximum : 2147483647
            value: root.param !== null ? root.param.value : 0
            stepSize: root.step
            editable: true
            onValueModified: if (root.param !== null) root.param.value = value
            implicitHeight: 24
            font.pixelSize: Theme.fontBody
            background: Rectangle {
                color: Theme.raised
                border.color: Theme.rule
                radius: 2
            }
            contentItem: TextInput {
                id: intInput
                text: parent.textFromValue(parent.value, parent.locale)
                color: Theme.ink
                font.pixelSize: Theme.fontBody
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                readOnly: !parent.editable
                validator: parent.validator
                selectByMouse: true

                // Typing replaces the value rather than being inserted into it. Without this the
                // digits typed merge with the digits already there and the SpinBox's validator
                // then truncates the result to something in range: typing 250 over 500 committed
                // 2500. The operator sees a plausible number they did not type.
                //
                // ⚠ And `selectAll()` alone is not enough: a first keystroke the validator
                // refuses drops the selection and the digits after it merge anyway. Same guard,
                // same reason, as the double editor below.
                property bool untouched: false
                onActiveFocusChanged: { untouched = activeFocus; if (activeFocus) selectAll() }
                Keys.onPressed: {
                    if (intInput.untouched && event.text.length > 0
                            && event.text.charCodeAt(0) >= 0x20
                            && event.text.charCodeAt(0) !== 0x7f
                            && (event.modifiers & Qt.ControlModifier) === 0
                            && (event.modifiers & Qt.AltModifier) === 0)
                        intInput.text = ""
                    intInput.untouched = false
                }

                /**
                 * ⚠ Write the PARAMETER, not the box.
                 *
                 * `parent.value = ...` assigned straight to `SpinBox.value`, which does two
                 * things: it permanently destroys the `value: root.param.value` binding above,
                 * and — measured, not assumed — it does **not** emit `valueModified`, so
                 * `onValueModified` never runs and the service is never told. The typed number
                 * showed on screen and the pipeline kept the old one. Worse, the box's dead
                 * value became live at the next click of a step button, so a value typed
                 * minutes earlier took effect at a moment the operator was not thinking about it.
                 *
                 * Assigning to `root.param.value` writes the service, and the two bindings then
                 * bring back whatever the service actually adopted — which is not always what was
                 * typed, because `reconfigure()` clamps.
                 *
                 * `text` is re-bound explicitly because editing a TextInput destroys ITS binding
                 * too, and an edit the service clamps or refuses would otherwise leave the typed
                 * text on screen for ever.
                 */
                onEditingFinished: {
                    if (root.param !== null)
                        root.param.value = parent.valueFromText(text, parent.locale)
                    text = Qt.binding(function() {
                        return intInput.parent.textFromValue(intInput.parent.value,
                                                             intInput.parent.locale)
                    })
                }
            }
        }
    }

    Component {
        id: doubleEditor
        // A plain field rather than a SpinBox: Controls 2's SpinBox is integer-only, and the
        // usual workaround (an integer box with a scaling validator) turns every decimal into a
        // rounding decision made in the UI rather than in the service.
        TextField {
            id: doubleInput
            text: root.param !== null ? root.param.value.toFixed(root.decimals) : ""
            color: Theme.ink
            font.pixelSize: Theme.fontBody
            horizontalAlignment: Qt.AlignRight
            selectByMouse: true
            implicitHeight: 24
            implicitWidth: 88
            padding: 4

            /**
             * ⚠ `selectAll()` on focus is not enough on its own.
             *
             * If the FIRST keystroke is one the validator refuses — a `-` typed into a
             * positive-only field — the refusal drops the selection, and every digit after it
             * is *inserted* into the number that was already there. Measured: Anti-alias 450,
             * typed `-10`, committed **10450 Hz**, accepted without complaint. The warnings strip
             * caught that one because it crossed Nyquist; a value inside the legal range would
             * have gone through silently.
             *
             * So the first printable key after focus empties the field itself. That does not
             * depend on a selection surviving a refused character.
             */
            property bool untouched: false
            onActiveFocusChanged: { untouched = activeFocus; if (activeFocus) selectAll() }
            Keys.onPressed: {
                if (doubleInput.untouched && event.text.length > 0
                        && event.text.charCodeAt(0) >= 0x20 && event.text.charCodeAt(0) !== 0x7f
                        && (event.modifiers & Qt.ControlModifier) === 0
                        && (event.modifiers & Qt.AltModifier) === 0)
                    doubleInput.text = ""
                doubleInput.untouched = false
            }

            validator: DoubleValidator {
                bottom: root.param !== null ? root.param.minimum : -1e12
                top: root.param !== null ? root.param.maximum : 1e12
                decimals: root.decimals
                notation: DoubleValidator.StandardNotation
            }
            background: Rectangle {
                color: Theme.raised
                border.color: parent.activeFocus ? Theme.accent : Theme.rule
                radius: 2
            }
            /**
             * The value applies; the DISPLAY used to stop following it.
             *
             * `text = root.param.value.toFixed(...)` is a plain assignment, so it destroyed the
             * `text:` binding above on the first edit and the box then showed whatever it was
             * last given — not necessarily what is in force. It went stale after a Configurator
             * edit, after a `--serviceConfig` apply, and after `reconfigure()` clamped the value,
             * which are exactly the moments the number on screen is worth reading.
             *
             * Re-binding instead of assigning keeps the round trip: the box shows what the
             * service adopted, whether or not that is what was typed.
             */
            onEditingFinished: {
                if (root.param === null)
                    return
                var v = parseFloat(text)
                if (!isNaN(v))
                    root.param.value = v
                text = Qt.binding(function() {
                    return root.param !== null ? root.param.value.toFixed(root.decimals) : ""
                })
            }
        }
    }

    Component {
        id: stringEditor
        TextField {
            id: stringField
            text: root.param !== null ? root.param.value : ""
            color: Theme.ink
            font.pixelSize: Theme.fontBody
            selectByMouse: true
            implicitHeight: 24
            padding: 4

            /**
             * ⭐ SHOW THE START OF THE STRING, NOT THE END.
             *
             * A `TextField` narrower than its text scrolls to keep the cursor visible, and the
             * cursor starts at the END of a value assigned by binding. So a field the operator
             * has never touched displays its own tail: `epochFile` is
             * `tepsound_$subject_$condition_$$$.h5` and what was on screen, photographed at
             * 1920×1017, was `und_$subject_$condition_$$$.h5`.
             *
             * That is worse than a truncation. `und_…` looks like a complete filename that
             * happens to begin oddly — there is no ellipsis, no clipped glyph, nothing saying
             * anything is missing — so the operator reads a wrong value as the value. The same
             * applies to `protocol`, `carExcluded`, `protectedChannels` and `triggerTarget`.
             *
             * The cursor is pushed home whenever the value changes and whenever focus leaves, so
             * a field being typed into behaves normally and a field being read shows its head.
             */
            onTextChanged: if (!activeFocus) cursorPosition = 0
            onActiveFocusChanged: if (!activeFocus) cursorPosition = 0
            background: Rectangle {
                color: Theme.raised
                border.color: parent.activeFocus ? Theme.accent : Theme.rule
                radius: 2
            }
            // Same round trip as the numeric editors: editing a TextField destroys its own `text`
            // binding, so a path the service rejects or rewrites would otherwise stay on screen
            // looking accepted.
            onEditingFinished: {
                if (root.param === null)
                    return
                root.param.value = text
                text = Qt.binding(function() {
                    return root.param !== null ? root.param.value : ""
                })
            }
        }
    }

    Component {
        id: selectEditor
        /**
         * ⚠ The closed box was themed; the OPEN LIST was not.
         *
         * A `ComboBox` draws its popup from `popup` and `delegate`, neither of which inherits
         * anything from `background` or `contentItem`. Every select in the pane — `Average of`,
         * `Average by`, `Trigger out`, `Train on`, `Schedule` — therefore opened as a **white**
         * Qt list with black, olive and purple item text over a dark console, in the one moment
         * the operator is choosing between things that change what the pipeline computes.
         */
        ComboBox {
            id: combo
            model: root.param !== null ? root.param.options : []
            currentIndex: root.param !== null ? root.param.index : -1
            onActivated: if (root.param !== null) root.param.index = index
            implicitHeight: 24
            implicitWidth: 120
            font.pixelSize: Theme.fontBody
            background: Rectangle {
                color: Theme.raised
                border.color: combo.activeFocus ? Theme.accent : Theme.rule
                radius: 2
            }
            contentItem: Text {
                text: combo.displayText
                color: Theme.ink
                font.pixelSize: Theme.fontBody
                verticalAlignment: Text.AlignVCenter
                leftPadding: 6
                rightPadding: 20
                elide: Text.ElideRight
            }
            delegate: ItemDelegate {
                width: combo.width - 2
                height: 24
                padding: 0
                highlighted: combo.highlightedIndex === index
                background: Rectangle {
                    color: highlighted ? Theme.accent
                         : (index === combo.currentIndex ? Theme.raised : "transparent")
                }
                contentItem: Text {
                    text: modelData
                    color: highlighted ? Theme.paper : Theme.ink
                    font.pixelSize: Theme.fontBody
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 6
                    rightPadding: 6
                    elide: Text.ElideRight
                }
            }
            popup: Popup {
                y: combo.height
                width: combo.width
                implicitHeight: Math.min(216, listView.contentHeight + 2)
                padding: 1
                background: Rectangle {
                    color: Theme.panel
                    border.color: Theme.rule
                    border.width: 1
                    radius: 2
                }
                contentItem: ListView {
                    id: listView
                    clip: true
                    model: combo.delegateModel
                    currentIndex: combo.highlightedIndex
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollIndicator.vertical: ScrollIndicator {}
                }
            }
        }
    }

    Component {
        id: actionEditor
        TepButton {
            text: root.param !== null && root.param.buttonText !== ""
                  ? root.param.buttonText
                  : (root.param !== null ? root.param.label : "")
            onClicked: if (root.param !== null)
                           root.param.serialized = { "invoke": true }
        }
    }
}
