import QtQuick 2.15
import QtQuick.Controls 2.15

/**
 * A dialog wearing the console's palette, with its own buttons.
 *
 * Controls 2's default Dialog is light chrome carrying Qt's own translated standard buttons, and
 * on this console both are wrong. `Theme.ink` is a near-white meant for a dark panel, so the
 * question a confirmation is asking renders invisible on the default background while the smaller
 * explanatory line underneath — `Theme.dim`, a mid-grey — is the only part that reads. And
 * `standardButtons` comes out in the system locale: on the rig this was tested on, the Reset
 * confirmation offered "Отклонить" and "Отмена" while every other string in the service was
 * English. A destructive button labelled in a language the rest of the program does not use,
 * beside a question the operator cannot read, is worse than no confirmation at all.
 *
 * So: the background and header come from the theme, and every dialog declares its own `footer`
 * out of `TepButton`s with the text written here rather than translated underneath us.
 */
Dialog {
    id: root

    modal: true
    padding: Theme.pad

    background: Rectangle {
        color: Theme.panel
        border.color: Theme.rule
        border.width: 1
        radius: 3
    }

    header: Text {
        text: root.title
        visible: root.title !== ""
        color: Theme.ink
        font.pixelSize: Theme.fontLarge
        elide: Text.ElideRight
        leftPadding: Theme.pad
        rightPadding: Theme.pad
        topPadding: Theme.pad
        bottomPadding: Theme.gap
    }
}
