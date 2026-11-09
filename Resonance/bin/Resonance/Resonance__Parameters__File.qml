import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
// For the ResonanceApp singleton. This file is reached by URL from ParametersView's Loader
// rather than through qmldir, so it does not inherit that file's imports.
import Resonance 3.0

RowLayout {
    id: self

    /**
     * Which content folder this particular File parameter belongs to.
     *
     * ⚠ A File parameter carries the file's CONTENTS, not its path (see
     * Core/Resonance/Parameters/File.cpp -- setJson stores the bytes, base64 for binary). So
     * unlike every other chooser in the tree there is no current value whose directory could be
     * reused, and the folder has to be decided from what the parameter *is*.
     *
     * `params` would be wrong: params/ holds the Configurator's own saved parameter sets, which
     * is not what any File parameter points at. Today every `Parameters::File` in the tree is an
     * electrode layout -- `ced` in DAQmx, neuronSpectrum, nvx, nvx136, and `ced`/`eegCed`/
     * `epochCed` in SignalGenerator -- and those live in montages/. Hence the name test.
     *
     * The fallback is the distribution ROOT, not any one content folder: from the root every one
     * of params/, protocols/, stimuli/, montages/, calib/ and data/ is a single double-click
     * away, whereas from a wrongly guessed folder the operator has to climb out first. Guessing
     * badly is worse than not guessing, and `bin` was worse than either.
     *
     * The alternative -- a folder hint declared on the parameter itself -- would have to travel
     * in `File::jsonAttributes()`, which is a bare bool today and is read positionally by every
     * running service. That is a wire change, and not one worth making for a control whose only
     * user is a .ced file.
     */
    property string folderKind: 'root'

    /// ⚠ Recomputed on demand, not bound. A Loader sets `parentItem` AFTER the loaded object's
    /// bindings have been evaluated, so a `parent.name`-based binding sees null exactly once --
    /// at the only moment that matters, before anything re-reads it -- and settles on the
    /// fallback. Asking again at click time is the version that observes the real parameter.
    function __recomputeKind() {
        var p = self.parent
        // Built by concatenation onto a string literal rather than through String(): an
        // unqualified `String` does not resolve to the JS global from a function body in this
        // component's scope -- it raises "Property 'String' of object [null] is not a function"
        // and the whole function is skipped, which is how this silently fell back to the root.
        var hint = ''
        if (p) {
            if (p.name) hint += p.name
            hint += ' '
            if (p.label) hint += p.label
        }
        hint = hint.toLowerCase()
        folderKind = (hint.indexOf('ced') >= 0 || hint.indexOf('montage') >= 0
                      || hint.indexOf('electrode') >= 0) ? 'montages' : 'root'
        return folderKind
    }

    Component.onCompleted: __recomputeKind()

    FileDialog {
        id: fileDialog
        title: "Please choose a file"
        fileMode: FileDialog.OpenFile
        nameFilters: self.folderKind === 'montages'
                     ? ["Electrode layout (*.ced)", "All files (*)"]
                     : ["All files (*)"]
        onAccepted: {
            ResonanceApp.rememberFolder(self.folderKind, fileDialog.selectedFile)

            const maxNameLength = 52;
            // '' + url, not String(url) -- see __recomputeKind() for why the global is not
            // reachable from this component's scope.
            var fname = '' + fileDialog.selectedFile
            if(fname.length>maxNameLength){
                console.log(fname)

                fname = '…' + fname.substring(fname.length-maxNameLength);
            }
            console.log(fname.length)

            fileName.text = fname

            /**
             * ⚠ Read through C++, not XMLHttpRequest.
             *
             * Qt 6 refuses `XMLHttpRequest` GET on a local file -- "Using GET on a local file is
             * disabled by default" -- and it refuses it by never advancing the request to DONE.
             * The `onreadystatechange` handler therefore never ran: no value was assigned, no
             * error was raised, and the only visible effect was the filename appearing beside
             * the button while the parameter stayed empty. Qt 5 permitted the same call, so the
             * defect arrived with the port and not with any change to the CED code.
             *
             * `readFileContents()` also returns the value already encoded the way
             * `File::setJson()` expects for this parameter's mode, which is what the old
             * `atob()` branch was trying and failing to do.
             */
            var result = ResonanceApp.readFileContents(fileDialog.selectedFile,
                                                       self.parent.attributes ? true : false)
            if (!result.ok) {
                // Say so. A refused read that looks like a successful one is exactly how this
                // went unnoticed through a whole port.
                console.warn("File parameter: " + result.error)
                readError.text = result.error
                return
            }
            readError.text = ""
            self.parent.serialized = result.serialized
        }
    }

    Button {
        text: "Select file"
        // Re-asked at every click, not bound: startFolder() moves with use and carries no change
        // signal, so a `folder:` binding would read the default once and never the memory.
        onClicked: {
            var kind = self.__recomputeKind()
            // nameFilters follows folderKind by binding, but selectedNameFilter does not reset
            // when the list changes if the old entry is still in it -- so "All files" would stay
            // picked and the .ced filter would only be reachable from the dropdown.
            fileDialog.selectedNameFilter.index = 0
            fileDialog.currentFolder = ResonanceApp.startFolderUrl(kind)
            fileDialog.open()
        }
    }

    Text {
        id: fileName
        text: ""
    }

    /// Only ever non-empty when the read failed. Kept beside the filename so the operator sees
    /// the reason in the same place they see the file they picked.
    Text {
        id: readError
        text: ""
        color: "#b00020"
        visible: text !== ""
    }

}
