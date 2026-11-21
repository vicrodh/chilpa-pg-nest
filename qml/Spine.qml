import QtQuick
import QtQuick.Controls.Basic
import "native" as Native

FocusScope {
    id: spine
    required property var album
    required property var colors
    required property var controller
    required property var backend
    property url spineSource: ""
    property bool artActive: true
    property bool viewMoving: false
    property bool imagesEnabled: false
    property bool motion: true
    property real spineWidth: 23
    property real maxFaceWidth: 10000
    readonly property real faceHeight: Math.min(height, Math.max(1, maxFaceWidth) / 1.035)
    property bool selected: false
    property bool loaded: false
    property real reveal: selected ? 1 : 0
    readonly property alias artwork: scan
    readonly property alias spinePalette: palette
    readonly property alias caseLoader: front
    readonly property bool interacting: front.item ? front.item.interacting : false
    readonly property bool scanned: scan.status === Image.Ready
    width: spineWidth + (faceHeight * 1.035 - spineWidth) * Math.sin(reveal * Math.PI / 2)
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: album.artist + ", " + album.title + ", " + album.year
    Accessible.description: spine.backend.tr("Open CD on shelf")
    Accessible.onPressAction: opened()
    signal opened()
    signal picked()
    signal spineRequested()
    signal coverReady(var item)
    signal spineNeeded()
    onAlbumChanged: if (imagesEnabled && artActive && !viewMoving) Qt.callLater(spineNeeded)
    onArtActiveChanged: if (imagesEnabled && artActive && !viewMoving) Qt.callLater(spineNeeded)
    onViewMovingChanged: if (imagesEnabled && !viewMoving && artActive) Qt.callLater(spineNeeded)
    Component.onCompleted: if (imagesEnabled && artActive && !viewMoving) Qt.callLater(spineNeeded)
    Keys.onReturnPressed: opened()
    Keys.onSpacePressed: opened()
    Behavior on reveal { enabled: spine.motion && spine.visible; NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }
    Native.SpinePalette { id: palette; source: spine.album.art || ""; active: spine.artActive }
    Item {
        x: 0; y: 0; width: spine.spineWidth; height: parent.height
        opacity: 1 - spine.reveal
        visible: opacity > 0.005
        Rectangle { anchors.fill: parent; color: palette.background; border.color: spine.selected || spine.loaded ? spine.colors.accent : "#61716e"; border.width: 0.7 }
        Image {
            id: scan
            anchors.fill: parent; anchors.margins: 1
            source: spine.artActive && spine.imagesEnabled ? spine.spineSource : ""
            sourceSize: Qt.size(48, 768)
            asynchronous: true; cache: false; fillMode: Image.PreserveAspectCrop
        }
        Item {
            visible: !spine.scanned
            anchors.centerIn: parent
            width: parent.height - 22; height: parent.width - 6; rotation: -90
            Text {
                anchors.fill: parent
                text: String(spine.album.artist || "").toUpperCase() + "  ·  " + (spine.album.title || "") + (spine.album.year ? "  /  " + spine.album.year : "")
                color: palette.foreground; font.pixelSize: Math.max(9, Math.min(12, spine.spineWidth * 0.39)); font.weight: Font.Medium
                style: Text.Outline; styleColor: palette.background
                verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
            }
        }
        Rectangle { x: 0; width: 1; height: parent.height; color: "#90dbe1e1" }
        Rectangle { x: parent.width - 2; width: 2; height: parent.height; color: "#70000000" }
        Rectangle { x: 1; y: 1; width: parent.width - 2; height: 1; color: "#bbffffff" }
        Rectangle { x: 1; y: parent.height - 2; width: parent.width - 2; height: 1; color: "#77000000" }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: { spine.forceActiveFocus(); spine.picked() }
            onDoubleClicked: spine.opened()
        }
        TapHandler { acceptedDevices: PointerDevice.TouchScreen | PointerDevice.TouchPad; gesturePolicy: TapHandler.DragThreshold; onDoubleTapped: { spine.picked(); spine.opened() } }
    }
    Loader {
        id: front
        active: spine.artActive && (spine.selected || spine.reveal > 0.005)
        width: spine.faceHeight * 1.035; height: spine.faceHeight; y: (spine.height - height) / 2
        opacity: Math.min(1, spine.reveal * 8)
        sourceComponent: InlineCase { album: spine.album; controller: spine.controller; colors: spine.colors; backend: spine.backend; reveal: spine.reveal; span: spine.width; onClosed: spine.controller.close(); onSpineRequested: spine.spineRequested() }
        onLoaded: spine.coverReady(item)
    }
    HoverHandler { id: hover }
    ToolTip.visible: hover.hovered && spine.reveal < 0.01
    ToolTip.delay: 700
    ToolTip.text: spine.album.artist + " · " + spine.album.title + " · " + spine.album.year
}
