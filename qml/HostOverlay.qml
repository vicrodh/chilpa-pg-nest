import QtQuick
import app.chilpa
import "qrc:/qt/qml/app/chilpa/kit/qml/Theme" as T
import "qrc:/qt/qml/app/chilpa/kit/qml/Primitives" as Ui
import "qrc:/qt/qml/app/chilpa/qml/Components" as App
Item {
    id: panel
    function t(message){return backend ? backend.tr(message):message}
    property var album: null
    property var controller: null
    property var backend: null
    property bool back: false
    signal dismissed()
    signal closed()
    signal flipRequested()
    signal spineRequested()
    App.AlbumCardOverlay {
        anchors.fill: parent
        albumId: panel.album ? panel.album.id : 0
        year: panel.album ? String(panel.album.year) : ""
        selectionVisible: false
        dismissOnBackground: true
        onDismissed: panel.dismissed()
        onDragStarted: (x,y) => panel.backend.surface.beginDrag(panel.album, x, y)
        onDragMoved: (x,y) => panel.backend.surface.moveDrag(x, y)
        onDragFinished: if(panel.backend.surface)panel.backend.surface.endDrag()
        expanded: panel.back
        quickTip:panel.t(panel.back ? "Show cover":"Show back")
        quickGlyph: T.Lucide.rotateCcw
        playEnabled: panel.controller && !panel.controller.busy && !panel.controller.replacement && !panel.backend.preparing && panel.album && panel.backend.available(panel.album.id)
        playAction: () => panel.controller.requestPlay(panel.album)
        dragTarget: panel.backend && panel.backend.surface ? panel.backend.surface.dragDisc : null
        onQuick: panel.flipRequested()
        onMenu: (x,y) => menu.show(albumId, panel.album.title, panel.album.artist, 0, x, y)
    }
    Ui.IconButton { objectName: "nestCloseCase"; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: T.Metrics.overlayPad; size: T.Metrics.overlayButton; round: true; tone: "overlay"; glyph: T.Icons.x; tip: panel.t("Return case to shelf"); onClicked: panel.closed() }
    App.AlbumMenu {
        id: menu
        playAction: () => panel.controller.requestPlay(panel.album)
        extraEntries: [{text:panel.t("Eject album"),glyph:T.Lucide.eject,act:"extension:eject",enabled:panel.album && panel.controller && panel.controller.hasDisc && panel.controller.loaded.id===panel.album.id && !panel.controller.busy},{text:panel.t("Review spine"),glyph:T.Icons.disc,act:"extension:spine"},{text:panel.t(panel.back ? "Show cover":"Show back"),act:"extension:flip"}]
        onExtraAction: entry => { if(entry.act==="extension:eject")panel.controller.eject();else if (entry.act === "extension:spine") panel.spineRequested(); else panel.flipRequested() }
    }
}
