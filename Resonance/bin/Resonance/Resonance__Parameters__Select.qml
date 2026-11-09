import QtQuick
import QtQuick.Controls

ComboBox {
    id: self

    model: parent.attributes.options
    currentIndex: remoteIndex()

    /**
     * ⭐ A long option must not widen the column.
     *
     * Stock Qt 6 sizes a ComboBox to its CURRENT item, so one wordy value -- "10 kHz (select any
     * 24 EEG channels)" was 186 px of text on its own -- made this control, and through it the
     * whole parameter panel, as wide as the wordiest thing any service happened to publish. The
     * intended column width is 300 px (docs/build_qt5-to-qt6-transition.md), of which 182 px is
     * already spent on the label column and this control's own chrome.
     *
     * So: ask for a modest width, elide in the row, and let the POPUP be as wide as it needs.
     * Nothing is lost -- the full text is one click away, and the tooltip carries the parameter's
     * description regardless.
     */
    implicitWidth: 80

    contentItem: Text {
        leftPadding: 8
        rightPadding: self.indicator.width + self.spacing
        text: self.displayText
        font: self.font
        color: self.enabled ? self.palette.text : self.palette.placeholderText
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    /**
     * Wider than the control when the options need it, so eliding in the row costs nothing.
     *
     * Through a Binding rather than `popup.width:` -- `popup` is an object-typed property, not a
     * grouped one, so a dotted binding in the object body is not valid QML and silently would not
     * be what it looks like.
     */
    Binding {
        target: self.popup
        property: "width"
        value: Math.max(self.width,
                        Math.min(self.popup.contentItem.contentWidth + 24, 420))
        when: self.popup !== null
        restoreMode: Binding.RestoreNone
    }

    function remoteIndex(){
        if(parent.attributes.optionsAreUnique){
            return parent.attributes.options.indexOf(parent.serialized);
        } else {
            return parent.serialized;
        }

    }

    /**
     * Put the service's value back on the control.
     *
     * `currentIndex: remoteIndex()` above is only ever the *initial* value. Changing `model`
     * resets currentIndex to 0 -- ComboBox.qml documents it, and popupItems.onModelChanged is
     * where it happens -- and that write goes straight to `popup.__selectedIndex`, which
     * currentIndex is an alias of, so it destroys the binding. After the first model change
     * nothing tracks the service any more unless we re-assert it here.
     *
     * And `model` changes constantly: it reads `parent.attributes.options`, and ParametersView
     * re-assigns `attributes` on every description re-broadcast, which a service does on any
     * parameter change at all.
     */
    function syncFromService(){
        var i = remoteIndex();
        if(currentIndex !== i) currentIndex = i;
    }

    // Deferred, because the reset this is undoing happens *after* this handler: the Instantiator
    // inside ComboBox binds to `model` when the base type is built, so it is notified first.
    // Qt.callLater also collapses the several notifications one re-broadcast produces into one.
    onModelChanged: Qt.callLater(syncFromService)

    Connections {
        target: parent

        function onSerializedChanged() {
            syncFromService()
        }
    }

    /**
     * The write-back, and `activated` is the whole point of it: Qt emits it only when the index
     * was changed by the *user* -- popup item, wheel, arrow keys, type-ahead -- and never when it
     * was set programmatically.
     *
     * This used to hang off onCurrentIndexChanged, which cannot tell those two apart, so it was
     * guarded by a `status !== Loader.Ready` test naming an id that no longer refers to the
     * Loader. The guard therefore never passed and no Select in any service could apply anything
     * (workpc-changes E5). Simply repairing the id is not enough and is worse than the bug: the
     * model rebuild described above resets the index to 0, and onCurrentIndexChanged would then
     * send that 0 to the service as if it had been chosen -- an NVX sampling rate would not just
     * *display* 250 Hz, it would become it. `activated` removes the question rather than guarding
     * it, so the `_block` re-entrancy flag that used to try is gone too.
     *
     * Reading currentIndex rather than the injected `index` argument is deliberate: every one of
     * Qt's four emission sites assigns currentIndex before emitting, the Loader also carries a
     * property called `index`, and injected signal parameters are deprecated in Qt 5.15.
     */
    onActivated: {
        if(parent.attributes.optionsAreUnique){
            parent.serialized = parent.attributes.options[currentIndex];
        } else {
            parent.serialized = currentIndex;
        }
    }
}
