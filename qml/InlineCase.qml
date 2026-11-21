import QtQuick
import QtQuick.Controls.Basic
import "native" as Native

Item {
    id: jacket
    required property var album
    required property var controller
    required property var colors
    required property var backend
    property real reveal: 1
    property real span: width
    property real depth: Math.max(14, height * .067)
    property bool back: false
    property real turn: 0
    property real gestureBase: 0
    property int settleDuration: 300
    property bool controlsVisible: false
    property bool dragArmed: false
    readonly property real angle: -90 * (1 - reveal) + turn
    readonly property bool facingBack: Math.cos(angle * Math.PI / 180) < 0
    readonly property bool settled: reveal > .995 && Math.abs(turn - (back ? 180 : 0)) < .1 && !flipDrag.active
    readonly property var tracks: trackList
    readonly property bool interacting: contact.active
    signal closed()
    signal spineRequested()
    function flipTo(showBack) { const target=showBack ? 180:0; settleDuration=Math.max(80,Math.round(Math.abs(target-turn)*1.8));controlsVisible=false;back=showBack;turn=target }
    Behavior on turn { enabled: !flipDrag.active && !jacket.controller.reducedMotion; NumberAnimation { duration: jacket.settleDuration; easing.type: Easing.OutCubic } }
    Item {
        id: box
        anchors.fill: parent
        transform: Native.CasePose { faceWidth: box.width; faceHeight: box.height; depth: jacket.depth; span: jacket.span; reveal: jacket.reveal; turn: jacket.turn }
        // Six faces form a rigid jewel box. Its sides remain visible during turns.
        Rectangle {
            anchors.fill: parent; color: "#c8d0cf"; radius: 2; border.color: "#d8e5e4"
            visible: !jacket.facingBack
            transform: Matrix4x4 { matrix: Qt.matrix4x4(1,0,0,0, 0,1,0,0, 0,0,1,jacket.depth / 2, 0,0,0,1) }
            Rectangle { id: hinge; x: 2; y: 2; width: Math.max(9, parent.width * .055); height: parent.height - 4; color: "#242b2b"
                Repeater { model: 4; Rectangle { required property int index; x: 1 + index * 2; width: 1; height: parent.height; color: index % 2 ? "#687170" : "#101515" } }
            }
            Image { objectName: "nestCover"; x: hinge.width + 4; y: 3; width: parent.width - x - 3; height: parent.height - 6; source: jacket.visible ? jacket.album.art || "" : ""; sourceSize: Qt.size(512,512); asynchronous: true; cache: false; fillMode: Image.PreserveAspectCrop }
            Rectangle { x: 2; y: 1; width: parent.width - 4; height: 1; color: "#ccffffff" }
            Rectangle { x: parent.width - 3; y: 2; width: 1; height: parent.height - 4; color: "#bbffffff" }
        }
        Rectangle {
            id: rear
            anchors.fill: parent; color: jacket.colors.bookletBackground; border.color: jacket.colors.bookletBorder; border.width: 3
            visible: jacket.facingBack
            transform: [Rotation { origin.x: rear.width / 2; origin.y: rear.height / 2; axis.y: 1; axis.z: 0; angle: 180 }, Matrix4x4 { matrix: Qt.matrix4x4(1,0,0,0, 0,1,0,0, 0,0,1,-jacket.depth / 2, 0,0,0,1) }]
            Text { x: 13; y: 56; width: parent.width - 26; text: jacket.album.artist + " · " + jacket.album.title; color: jacket.colors.bookletText; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
            Loader { id: trackData; active: jacket.back || jacket.turn > .01; sourceComponent: jacket.backend.trackData; onLoaded: item.albumId = jacket.album.id }
            ListView {
                id: trackList
                objectName: "nestBackTracks"
                x: 13; y: 80; width: parent.width - 26; height: Math.max(20, parent.height - y - 64)
                model: trackData.item ? trackData.item.model : null
                clip: true; cacheBuffer: 0; boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    id: backScroll
                    objectName: "nestBackScrollBar"
                    policy: ScrollBar.AsNeeded
                    visible: size < 1
                    width: 32; leftPadding: 12; rightPadding: 12; topPadding: 0; bottomPadding: 0
                    minimumSize: Math.min(1, 32 / Math.max(1, height))
                    hoverEnabled: true
                    background: Rectangle {
                        x: backScroll.leftPadding; width: backScroll.availableWidth; height: parent.height
                        radius: width / 2; color: jacket.colors.bookletTrack
                    }
                    contentItem: Rectangle {
                        implicitWidth: 8; implicitHeight: 32; radius: width / 2
                        color: backScroll.pressed || backScroll.hovered ? jacket.colors.bookletText : jacket.colors.bookletThumb
                    }
                }
                delegate: Item {
                    id:trackRow
                    required property int index
                    required property var model
                    objectName:"nestTrack."+index
                    readonly property bool playable:!model.rowKind && model.available!==false && !jacket.controller.busy && !jacket.controller.replacement && !jacket.backend.preparing
                    activeFocusOnTab:playable
                    Accessible.role:model.rowKind ? Accessible.Heading:Accessible.Button
                    opacity:model.available===false ? .45:1
                    Accessible.name:model.title || model.headerLabel || ""
                    Accessible.onPressAction:playTrack()
                    function playTrack(){if(playable)jacket.controller.requestPlay(jacket.album,index,model.trackId)}
                    Keys.onReturnPressed:playTrack()
                    Keys.onSpacePressed:playTrack()
                    Rectangle {anchors.fill:parent;radius:3;color:trackRow.activeFocus || trackHover.hovered ? "#18ffffff":"transparent";border.width:trackRow.activeFocus ? 2:0;border.color:jacket.colors.accent}
                    HoverHandler {id:trackHover;cursorShape:trackRow.playable ? Qt.PointingHandCursor:Qt.ArrowCursor}
                    TapHandler {enabled:trackRow.playable;gesturePolicy:TapHandler.DragThreshold;onTapped:trackRow.playTrack()}
                    width: Math.max(0, ListView.view.width - (backScroll.visible ? backScroll.width + 4 : 0)); height: model.rowKind ? 26 : 34
                    Text { x: 0; width: 27; anchors.verticalCenter: parent.verticalCenter; text: model.rowKind ? "" : model.number; color: jacket.colors.bookletSecondary; font.pixelSize: 11 }
                    Text { x: 29; width: parent.width - 72; anchors.verticalCenter: parent.verticalCenter; text: model.rowKind ? model.headerLabel : model.title; color: jacket.colors.bookletText; font.pixelSize: 12; elide: Text.ElideRight; font.weight: model.rowKind ? Font.DemiBold : Font.Normal }
                    Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: model.duration || ""; color: jacket.colors.bookletSecondary; font.pixelSize: 10 }
                }
            }
        }
        Rectangle { x: 0; width: jacket.depth; height: parent.height; color: "#889b9a"; border.color: "#d7e6e5"; visible: Math.sin(jacket.angle * Math.PI / 180) > .001; transform: [Rotation { axis.y: 1; axis.z: 0; angle: 90 }, Matrix4x4 { matrix: Qt.matrix4x4(1,0,0,0, 0,1,0,0, 0,0,1,jacket.depth / 2, 0,0,0,1) }] }
        Rectangle { x: parent.width; width: jacket.depth; height: parent.height; color: "#30403f"; border.color: "#acbfbd"; visible: Math.sin(jacket.angle * Math.PI / 180) < -.001; transform: [Rotation { axis.y: 1; axis.z: 0; angle: 90 }, Matrix4x4 { matrix: Qt.matrix4x4(1,0,0,0, 0,1,0,0, 0,0,1,jacket.depth / 2, 0,0,0,1) }] }
        Rectangle { width: parent.width; height: jacket.depth; color: "#afc3c0"; transform: [Rotation { axis.x: 1; axis.z: 0; angle: 90 }, Matrix4x4 { matrix: Qt.matrix4x4(1,0,0,0, 0,1,0,0, 0,0,1,-jacket.depth / 2, 0,0,0,1) }] }
        Rectangle { y: parent.height; width: parent.width; height: jacket.depth; color: "#283432"; transform: [Rotation { axis.x: 1; axis.z: 0; angle: 90 }, Matrix4x4 { matrix: Qt.matrix4x4(1,0,0,0, 0,1,0,0, 0,0,1,-jacket.depth / 2, 0,0,0,1) }] }
    }
    PointHandler { id: contact; target: null; acceptedButtons: Qt.LeftButton }
    DragHandler {
        id: flipDrag
        objectName: "nestFlipGesture"
        target: null; xAxis.enabled: true; yAxis.enabled: false; dragThreshold: 12
        enabled: jacket.reveal > .995 && !jacket.controller.busy && !jacket.dragArmed && !jacket.controlsVisible
        onActiveChanged: {
            if (active) jacket.gestureBase = jacket.turn
            else { const delta = jacket.turn - jacket.gestureBase; jacket.flipTo(Math.abs(delta) > 22 ? delta > 0 : jacket.gestureBase > 90) }
        }
        onActiveTranslationChanged: if (active) jacket.turn = Math.max(0, Math.min(180, jacket.gestureBase - activeTranslation.x / jacket.width * 180))
    }
    TapHandler {
        target: null
        enabled: jacket.settled && !jacket.controlsVisible && !jacket.controller.busy
        gesturePolicy: TapHandler.DragThreshold
        onTapped: jacket.controlsVisible = true
        onPressedChanged: if (!pressed && !discDrag.active) jacket.dragArmed = false
        onLongPressed: {
            if (jacket.controller.hasDisc || !jacket.backend.surface) return
            jacket.dragArmed = true
        }
    }
    DragHandler {
        id: discDrag
        target: null; enabled: jacket.dragArmed; acceptedButtons: Qt.LeftButton
        onActiveChanged: {
            if (active) jacket.backend.surface.beginDrag(jacket.album, centroid.scenePosition.x, centroid.scenePosition.y)
            else { if(jacket.backend.surface)jacket.backend.surface.endDrag(); jacket.dragArmed = false }
        }
        onCentroidChanged: if (active && jacket.backend.surface) jacket.backend.surface.moveDrag(centroid.scenePosition.x,centroid.scenePosition.y)
    }
    Loader {
        id: overlay
        anchors.fill: parent
        active: jacket.settled && jacket.controlsVisible && !jacket.controller.busy
        sourceComponent: jacket.backend.overlayComponent
        onLoaded: { item.album = jacket.album; item.controller = jacket.controller; item.backend = jacket.backend }
    }
    Binding { target: overlay.item; property: "back"; value: jacket.back; when: overlay.item !== null }
    Connections {
        target: overlay.item; ignoreUnknownSignals: true
        function onClosed() { jacket.closed() }
        function onFlipRequested() { jacket.flipTo(!jacket.back) }
        function onSpineRequested() { jacket.spineRequested() }
        function onDismissed() { jacket.controlsVisible = false }
    }
}
