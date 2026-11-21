import QtQuick
import QtQuick.Window

Item {
    id: stage
    objectName: "chilpaNestPresentation"
    required property var backend
    readonly property alias surface: surface
    readonly property alias fullscreenWindow: expanded
    readonly property bool detachedVisible: expanded.visible
    readonly property var display: integration
    readonly property bool hostPresented: integration.host !== null && integration.host.active
    readonly property var integration: QtObject {
        property int version: 1
        property var host: null
        readonly property string label: "Chilpa Nest"
        readonly property bool ambient: surface.colors.ambient
        readonly property int minimumWidth: playerDock !== "bottom" ? 620 : surface.effectiveDeckProfile === "slim" ? 800 : surface.effectiveDeckProfile === "minimal" ? 840 : 900
        readonly property int minimumHeight: playerDock === "bottom" ? 320:560
        readonly property bool canEject: surface.controller.hasDisc && !surface.controller.busy && !stage.backend.preparing
        readonly property bool canLoad: !surface.controller.hasDisc && !surface.controller.busy && !stage.backend.preparing
        readonly property var dragAlbum: surface.dragAlbum
        readonly property bool useCustomPlayer: surface.useCustomPlayer && playerComponent !== null
        property Component playerComponent: stage.backend.deckComponent
        property var trayTarget: null
        readonly property string playerDock: surface.deckDock
        readonly property real playerExtent: surface.deckExtent
        readonly property var menuEntries: [{text:stage.backend.tr("Show loaded album"),command:"show-loaded",enabled:surface.controller.hasDisc},{text:stage.backend.tr("Settings"),command:"settings"},{text:stage.backend.tr("Spines"),command:"spines",enabled:surface.controller.selected !== null || surface.controller.loaded !== null},{text:stage.backend.tr("Search"),command:"search"}]
        function command(action) { if (action === "fullscreen" && host) host.toggleFullscreen(); else surface.command(action) }
    }
    property var previousWindow: null
    property int previousVisibility: Window.Windowed

    function setFullscreen(on) {
        if (integration.host) {
            const fullscreen = integration.host.window && integration.host.window.visibility === Window.FullScreen
            if (fullscreen !== on) integration.host.toggleFullscreen()
            return
        }
        if (on === expanded.visible) return
        if (on) {
            previousWindow = stage.Window.window
            if (!previousWindow) return
            previousVisibility = previousWindow.visibility
            if (previousWindow.screen) expanded.screen = previousWindow.screen
            surface.parent = expanded.contentItem
            expanded.showFullScreen()
            previousWindow.hide()
            surface.forceActiveFocus()
        } else {
            surface.parent = stage
            if (previousWindow) {
                previousWindow.visibility = previousVisibility
                previousWindow.requestActivate()
            }
            expanded.hide()
            surface.forceActiveFocus()
        }
        backend.keepPreference("fullscreen", on ? "on" : "off")
    }
    NestView {
        id: surface
        anchors.fill: parent
        backend: stage.backend
        presentation: stage
        fullscreenActive: stage.hostPresented && integration.host.window ? integration.host.window.visibility === Window.FullScreen : expanded.visible
        onFullscreenRequested: on => stage.setFullscreen(on)
    }
    Window {
        id: expanded
        objectName: "nestFullscreenWindow"
        title: "Chilpa Nest"
        flags: Qt.Window | Qt.FramelessWindowHint
        color: stage.backend.hostWindow
        onClosing: event => { event.accepted = false; stage.setFullscreen(false) }
    }
    Component.onCompleted: if (backend.simulated && backend.readPreference("fullscreen", "off") === "on") Qt.callLater(() => stage.setFullscreen(true))
    Component.onDestruction: {
        if (expanded.visible && previousWindow) previousWindow.visibility = previousVisibility
    }
}
