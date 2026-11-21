import QtQuick
import QtQuick.Controls.Basic as Controls
Rectangle {
    id: tray
    objectName:"nestDeckCover"
    required property var deck
    property bool minimal:false
    readonly property var colors:deck.colors
    readonly property var album:deck.album || deck.backend.currentAlbum
    readonly property bool over:receiver.containsDrag
    color:colors.recess;radius:4
    border.width:2
    border.color:over ? colors.amber:colors.edgeLow
    activeFocusOnTab:true
    Accessible.role:Accessible.Button
    Accessible.name:deck.backend.tr(album && album.id ? "Show album tracks":"Empty tray: drag a CD here to load it")
    Accessible.onPressAction:activate()
    function activate(){
        if(!deck.controller || deck.controller.busy)return
        if(album && album.id && deck.nest)deck.nest.showLoadedAlbum()
        else if(deck.controller.selected)deck.controller.insert()
    }
    Image {
        objectName:"nestDeckCoverImage"
        anchors.fill:parent;anchors.margins:3
        source:tray.visible && deck.nest && deck.nest.presented && tray.album && tray.album.id ? tray.album.art || "":""
        sourceSize:Qt.size(256,256)
        asynchronous:true;cache:false;fillMode:Image.PreserveAspectCrop
    }
    Text {anchors.centerIn:parent;visible:!tray.album || !tray.album.id;text:deck.backend.tr("No disc").toUpperCase();color:colors.off;font.pixelSize:9}
    Rectangle {anchors.fill:parent;anchors.margins:-3;color:"transparent";radius:6;border.width:2;border.color:colors.focus;visible:tray.activeFocus}
    DropArea {
        id:receiver;anchors.fill:parent;keys:["app.chilpa.disc"]
        onEntered:drag=>{drag.accepted=deck.canLoad && deck.nest.dragAlbum!==null}
        onDropped:drop=>{if(deck.canLoad && deck.nest.dragAlbum){deck.nest.command("drop");drop.acceptProposedAction()}}
    }
    TapHandler {enabled:deck.controller!==null;onTapped:{tray.forceActiveFocus();tray.activate()}}
    Keys.onSpacePressed:activate()
    Keys.onReturnPressed:activate()
    Keys.onEnterPressed:activate()
    HoverHandler {id:hover;cursorShape:Qt.PointingHandCursor}
    Controls.ToolTip.visible:hover.hovered
    Controls.ToolTip.text:Accessible.name
}
