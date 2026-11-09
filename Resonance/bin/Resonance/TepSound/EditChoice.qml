import QtQuick 2.15
import QtQuick.Controls 2.15

/**
 * A compact drop-down whose selection is driven from outside.
 *
 * Same contract as `EditField` and `EditNumber`: `sourceValue` is assigned into `currentIndex`,
 * never bound to it, and `commit` carries the chosen string out. `ComboBox` writes its own
 * `currentIndex` on activation, so binding it to a model value is a binding the first click
 * destroys — the same defect, in the same place, as a `TextField` bound to a row's text.
 *
 * ⚠ `focusPolicy: Qt.NoFocus`, like every other control in this console: `Console.qml` hands Space
 * back to any focused item carrying a `checked` property, and a control that takes focus is a
 * control that silently stops Space starting and pausing the run.
 */
Item {
    id: root

    /// The choices, as plain strings. What is committed is the string, not the index.
    property var choices: []
    // Display names may be friendlier than the stable strings stored in the document.
    property var choiceLabels: ({})
    property string sourceValue: ""
    property bool readOnly: false

    signal commit(string value)

    function labelFor(value) {
        return root.choiceLabels[value] !== undefined ? root.choiceLabels[value] : value
    }

    implicitHeight: 22
    implicitWidth: 110

    function indexOfValue(v) {
        for (var i = 0; i < root.choices.length; ++i) {
            if (root.choices[i] === v)
                return i
        }
        return -1
    }

    function sync() {
        box.currentIndex = root.indexOfValue(root.sourceValue)
    }

    onSourceValueChanged: root.sync()
    onChoicesChanged: root.sync()
    Component.onCompleted: root.sync()

    ComboBox {
        id: box

        anchors.fill: parent
        model: root.choices
        enabled: !root.readOnly
        focusPolicy: Qt.NoFocus
        font.pixelSize: Theme.fontBody

        // Assignment, never a binding: see the header note.
        onActivated: {
            if (index >= 0 && index < root.choices.length)
                root.commit(root.choices[index])
            // Redrawn from the truth. A refused change leaves `sourceValue` alone and the box
            // snaps back rather than showing a selection the document does not hold.
            root.sync()
        }

        background: Rectangle {
            radius: 2
            color: root.readOnly ? "transparent" : Theme.raised
            border.width: 1
            border.color: Theme.rule
        }

        contentItem: Text {
            leftPadding: 5
            rightPadding: 18
            text: box.currentIndex >= 0 ? root.labelFor(root.choices[box.currentIndex]) : ""
            color: root.readOnly ? Theme.dim : Theme.ink
            font: box.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Text {
            x: box.width - width - 5
            y: (box.height - height) / 2
            text: "▾"
            color: Theme.faint
            font.pixelSize: Theme.fontSmall
        }

        /**
         * ⚠ The popup below is `ParamControl.qml`'s ComboBox popup, deliberately copied rather
         * than rewritten. The first version of this file used the Qt documentation's
         * `model: box.popup.visible ? box.delegateModel : null` idiom, and every item rendered
         * with **empty text**: the delegates were instantiated (the popup sized itself to five
         * rows of 22 px) but `modelData` came out blank, with no QML warning to say so. Opening
         * `Medium` gave a five-row void. `ParamControl`'s combo, in the same window, was correct,
         * and the only difference was the conditional model. One working recipe per tree.
         */
        delegate: ItemDelegate {
            width: box.width - 2
            height: 22
            padding: 0
            focusPolicy: Qt.NoFocus
            highlighted: box.highlightedIndex === index
            contentItem: Text {
                text: root.labelFor(modelData)
                color: highlighted ? Theme.paper : Theme.ink
                font.pixelSize: Theme.fontBody
                verticalAlignment: Text.AlignVCenter
                leftPadding: 5
                rightPadding: 5
                elide: Text.ElideRight
            }
            background: Rectangle {
                color: highlighted ? Theme.accent
                     : (index === box.currentIndex ? Theme.raised : "transparent")
            }
        }

        popup: Popup {
            y: box.height
            width: box.width
            implicitHeight: Math.min(240, listView.contentHeight + 2)
            padding: 1

            contentItem: ListView {
                id: listView
                clip: true
                model: box.delegateModel
                currentIndex: box.highlightedIndex
                boundsBehavior: Flickable.StopAtBounds
                ScrollIndicator.vertical: ScrollIndicator {}
            }

            background: Rectangle {
                color: Theme.panel
                border.color: Theme.rule
                border.width: 1
                radius: 2
            }
        }
    }
}
