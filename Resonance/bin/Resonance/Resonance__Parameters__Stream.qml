import QtQuick 2.4
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.14

// One connector: what it is bound to, whether it will come back on its own, and whether it is
// live right now.
//
// Two hosts, two shapes of `target`. A configurator hands it a proxy carrying only the
// serialised JSON of a remote service's parameter; a service's own view hands it the live
// Parameters::Stream object, which has StreamInfo properties instead. Everything below reads
// through desiredOf()/activeOf(), which accept either -- the previous code only understood the
// JSON shape, so in a viewer the row rendered blank.
Item {
    id: self
    property var target: parent

    // `target` is deliberately polymorphic: a Loader-shaped proxy in Configurator and a C++
    // Parameters::Stream in StreamView. QJsonValue maps remain readable in a direct QML binding,
    // but Qt 6 presents them as opaque after they cross a JavaScript function argument. The old
    // label routed the map through desiredOf() and streamToStr(), so it always formatted as empty.
    // The formatter crosses into C++ as a QVariant/StreamInfo, where both representations are
    // deterministic; the revision makes both proxy and live-object notifications explicit.
    property int targetRevision: 0
    function refreshTarget() { ++targetRevision }
    onTargetChanged: refreshTarget()

    StreamDisplayFormatter { id: streamFormatter }

    readonly property var requestedStreamInfo:
        self.target && self.target.serialized ? self.target.serialized.desiredStream : null
    readonly property var activeStreamInfo:
        self.target && self.target.attributes ? self.target.attributes.activeStream : null
    readonly property string requestedDisplayText:
        streamFormatter.text(requestedStreamInfo, targetRevision)
    readonly property string activeDisplayText:
        streamFormatter.text(activeStreamInfo, targetRevision)
    readonly property bool hasRequestedStream:
        requestedDisplayText !== "" || streamFormatter.hasConnection(requestedStreamInfo,
                                                                       targetRevision)
    readonly property bool connected: streamFormatter.hasConnection(activeStreamInfo,
                                                                      targetRevision)
    // Value and attributes are separate EventBus fields and can arrive in different turns. An
    // active stream is authoritative evidence that this is not an empty drop target.
    readonly property string displayText:
        requestedDisplayText || activeDisplayText || ">> Drag stream here <<"

    Connections {
        target: self.target
        ignoreUnknownSignals: true
        // Configurator proxy.
        function onSerializedChanged() { self.refreshTarget() }
        function onAttributesChanged() { self.refreshTarget() }
        // Live Parameters::Stream.
        function onJsonChanged() { self.refreshTarget() }
        function onJsonAttributesChanged() { self.refreshTarget() }
        function onStreamChanged() { self.refreshTarget() }
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    StackLayout {
        id: layout
        anchors.fill: parent
        currentIndex: 0

        function desiredOf(t) {
            var revision = self.targetRevision
            if (!t)
                return null
            if (t.serialized && t.serialized.desiredStream !== undefined)
                return t.serialized.desiredStream
            if (t.desiredStream !== undefined && t.desiredStream !== null)
                return t.desiredStream
            return null
        }

        function activeOf(t) {
            var revision = self.targetRevision
            if (!t)
                return null
            if (t.attributes && t.attributes.activeStream !== undefined)
                return t.attributes.activeStream
            if (t.activeStream !== undefined && t.activeStream !== null)
                return t.activeStream
            return null
        }

        function urlParam(stream, key) {
            var conns = stream ? stream.connections : null
            if (!conns)
                return ''
            for (var i = 0; i < conns.length; ++i) {
                var m = new RegExp('[?&]' + key + '=([^&]*)').exec('' + conns[i])
                if (m)
                    return decodeURIComponent(m[1])
            }
            return ''
        }

        // A persistent request is addressed by name and carries no uid at all, so resolving the
        // service through the discovery uid finds nothing -- which is why these used to render
        // as a bare "eeg@". The discover URL already holds the pair; read it from there first.
        function serviceOf(stream) {
            if (!stream)
                return ''
            var fromUrl = layout.urlParam(stream, 'name')
            if (fromUrl)
                return fromUrl
            // `locator` is a Configurator id and simply does not exist in a service's own view.
            if (stream.uid && typeof locator !== 'undefined' && locator)
                return locator.serviceNameByUuid(stream.uid)
            return ''
        }

        function streamNameOf(stream) {
            if (!stream)
                return ''
            if (stream.name)
                return stream.name
            return layout.urlParam(stream, 'stream')
        }

        function streamToStr(stream) {
            var n = layout.streamNameOf(stream)
            var s = layout.serviceOf(stream)
            if (!n && !s)
                return ''
            return s ? (n + '@' + s) : n
        }

        function hasStream(t) {
            var d = layout.desiredOf(t)
            return !!(d && (layout.streamNameOf(d) || (d.connections && d.connections.length > 0)))
        }

        function isConnected(t) {
            var a = layout.activeOf(t)
            return !!(a && a.connections && a.connections.length > 0)
        }

        function isPersistent(t) {
            var revision = self.targetRevision
            // Lives in the value (operator's choice), with the attributes copy kept as a
            // fallback for services built before it moved there.
            if (t && t.reconnect !== undefined)
                return t.reconnect
            if (t && t.serialized && t.serialized.reconnect !== undefined)
                return t.serialized.reconnect
            if (t && t.attributes && t.attributes.reconnect !== undefined)
                return t.attributes.reconnect
            return false
        }

        function setPersistent(t, on) {
            if (!t)
                return
            if (t.reconnect !== undefined) {
                t.reconnect = on
                return
            }
            var newValue = Object.assign({}, t.serialized)
            newValue.reconnect = on
            t.serialized = newValue
        }

        // Always through `serialized`, never through the `desiredStream` property.
        //
        // Both hosts have `serialized`, and Parameters::Stream::setJson() runs the object through
        // StreamInfo::fromJson(). Assigning the same JS object to the live object's
        // `desiredStream` property instead asks QML to convert it to a StreamInfo gadget, which
        // it cannot do -- and it fails *silently*, so the connector inside a viewer accepted
        // hover, lit its clear button and then did nothing at all. The configurator's own
        // parameter panel worked only because its target is a proxy that has no desiredStream
        // property and so took this branch already.
        function setDesired(t, info) {
            if (!t)
                return
            var newValue = Object.assign({}, t.serialized)
            newValue.desiredStream = info
            t.serialized = newValue
        }

        function clearStream(t) {
            // An empty StreamInfo, which is what the service reads as "nothing connected here".
            // Until now the only way to drop a connection was to shrink the slot count, which
            // can only ever remove the last one.
            layout.setDesired(t, { "connections": [], "metaData": {} })
        }

        /// The round-trippable form: what the operator would paste somewhere else.
        function desiredUrl(t) {
            var d = layout.desiredOf(t)
            if (!d)
                return ''
            var conns = d.connections
            if (conns) {
                for (var i = 0; i < conns.length; ++i) {
                    if (('' + conns[i]).indexOf('discover:') === 0)
                        return '' + conns[i]
                }
                if (conns.length > 0)
                    return '' + conns[0]
            }
            return layout.streamNameOf(d)
        }

        RowLayout {
            // Always shown, so the connector says up front whether it will come back on its
            // own -- and clickable, because that is where the eye already is. It used to take a
            // trip through the detail popup to flip.
            Text {
                text: layout.isPersistent(self.target) ? "🗘 keep" : "↻ once"
                color: keepMouse.containsMouse
                       ? "#2980b9"
                       : (layout.isPersistent(self.target) ? "#1e8449" : "#7f8c8d")
                font.pointSize: 7
                font.underline: keepMouse.containsMouse

                MouseArea {
                    id: keepMouse
                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    onClicked: layout.setPersistent(self.target,
                                                    !layout.isPersistent(self.target))
                }
            }

            Text {
                id: nameText
                objectName: "streamConnectorName"
                Layout.fillWidth: true
                // Three numbers, because two different hosts size this row two different ways.
                // A configurator stretches the component, so the row must be *allowed* to
                // shrink or a long stream@service name pushes the marker and the clear button
                // out of the parameter column -- hence minimumWidth and elide. A service's own
                // view sizes the component from its implicit width instead, so the row must
                // also *ask* for enough to read: preferredWidth 1 made the name vanish there
                // entirely. Capped, so the natural size stays sane for very long names.
                Layout.minimumWidth: 40
                // Measured off to the side, not from contentWidth: on an elided Text
                // contentWidth is the width *after* eliding, so feeding it back into the
                // preferred width is a loop that settles at almost nothing -- which is how the
                // name ended up as "gen...tor" in a narrow host.
                // Capped low so the *implicit* width of the whole row stays compact: the
                // Configurator sizes its parameter column from that, and a wide row there
                // scrolls the marker and the clear button out of sight. Hosts that want the
                // full name set Layout.fillWidth on the component and the slack lands here.
                Layout.preferredWidth: Math.min(nameMetrics.width + 6, 140)
                elide: Text.ElideMiddle
                color: nameMouse.containsMouse ? "#2980b9" : "black"
                text: self.displayText

                TextMetrics {
                    id: nameMetrics
                    font: nameText.font
                    text: nameText.text
                }

                MouseArea {
                    id: nameMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: popup.open()
                }
            }

            // Just the arrow. It used to repeat the resolved stream's name, which for a
            // persistent connection is the same name already shown to its left and long enough
            // to push the rest of the row out of the column. The full resolved info is in the
            // popup.
            Text {
                objectName: "streamConnectorArrow"
                text: self.connected ? '⇒' : '⇏'
                color: self.connected ? "#1e8449" : "#95a5a6"
            }

            Item {
                // Sized as a button rather than a bare glyph, which is a ~9 px target.
                implicitWidth: 20
                implicitHeight: 16
                visible: self.hasRequestedStream || self.connected

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: clearMouse.containsMouse ? "#c0392b" : "#95a5a6"
                    font.pointSize: 8
                }
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: layout.clearStream(self.target)
                }
            }
        }
    }

    DropArea {
        anchors.fill: layout
        keys: ["url/stream-connection"]
        onDropped: {
            var obj = JSON.parse(drop.getDataAsString("url/stream-connection"))
            if (obj) {
                layout.setDesired(self.target, obj)
            }
        }
    }

    Popup {
        id: popup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        anchors.centerIn: Overlay.overlay
        padding: 10

        ColumnLayout {
            spacing: 6

            SquareCheckBox {
                text: qsTr("Keep this connection (re-acquire by service + stream name)")
                checked: layout.isPersistent(self.target)
                onClicked: layout.setPersistent(self.target, checked)
            }

            Text {
                text: self.connected
                      ? qsTr("connected to ") + self.activeDisplayText
                      : qsTr("not connected")
                color: self.connected ? "#1e8449" : "#7f8c8d"
            }

            RowLayout {
                // Read-only but selectable, so the address can be copied into a config file, a
                // script or another connector. It used to be a plain Text, which cannot be.
                TextField {
                    id: urlField
                    Layout.preferredWidth: 460
                    readOnly: true
                    selectByMouse: true
                    text: layout.desiredUrl(self.target)
                }
                Button {
                    text: qsTr("Copy")
                    onClicked: {
                        urlField.selectAll()
                        urlField.copy()
                        urlField.deselect()
                    }
                }
            }

            Text {
                Layout.preferredWidth: 520
                wrapMode: Text.WordWrap
                color: "#7f8c8d"
                font.pointSize: 7
                text: JSON.stringify(self.target ? self.target.serialized : null)
            }
        }
    }
}
