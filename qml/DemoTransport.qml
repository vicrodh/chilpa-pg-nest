import QtQuick
import QtQuick.Controls.Basic

Rectangle {
    id: deck
    DropArea { anchors.fill: parent; keys:["app.chilpa.disc"]; onEntered:drag => drag.accepted=!deck.controller.hasDisc&&!deck.controller.busy; onDropped:drop => { deck.backend.surface.command("drop");drop.acceptProposedAction() } }
    required property var backend
    required property var controller
    required property var colors
    readonly property bool compact: width < 660
    readonly property bool low: height < 100
    readonly property alias trayItem: tray
    color: colors.panel; radius: 5; border.color: colors.edge
    Rectangle {
        id: tray
        x: 14; y: deck.compact ? 12 : (parent.height - height) / 2
        width: deck.low || deck.compact ? 60 : 76; height: width
        radius: 4; color: "#141a15"; border.color: "#6f7667"
        Rectangle { anchors.centerIn: parent; width: parent.width - 10; height: width; radius: width / 2; color: "#0c120e"; border.color: "#444e3e" }
        Disc { anchors.centerIn: parent; width: parent.width - 12; height: width; accent: deck.colors.accent; title: deck.controller.loaded ? deck.controller.loaded.title : ""; visible: deck.controller.hasDisc && !deck.controller.busy }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - 5; width: parent.width * 0.55; height: 2; color: "#7e856f" }
    }
    Column {
        x: tray.x + tray.width + 14; y: deck.low ? 15 : 18
        width: deck.width - x - (deck.compact ? 14 : 300)
        spacing: 5
        Text {
            width: parent.width
            text: deck.controller.busy ? deck.backend.tr(deck.controller.phase === "loading" ? "Reading":"Eject")
                : deck.backend.preparing ? deck.backend.tr("Reading") : deck.controller.hasDisc ? deck.controller.loaded.title : deck.backend.tr("No disc")
            color: deck.colors.text; font.pixelSize: deck.low ? 14 : 17; font.weight: Font.DemiBold; elide: Text.ElideRight
        }
        Text { width: parent.width; text: deck.controller.hasDisc ? deck.backend.title || deck.controller.loaded.artist : deck.backend.tr("Open CD on shelf"); color: deck.colors.muted; font.pixelSize: 11; elide: Text.ElideRight }
        Row {
            width: parent.width; spacing: 8
            visible: !deck.low
            Text { text: deck.controller.hasDisc ? deck.backend.elapsed || "0:00" : "—:—"; color: deck.colors.muted; font.family: "monospace"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
            Slider {
                objectName: "nestSeek"
                width: Math.max(48, parent.width - 80); height: 22
                from: 0; to: Math.max(1, deck.backend.duration); value: deck.backend.position
                enabled: deck.controller.hasDisc && deck.backend.duration > 0 && !deck.controller.busy && !deck.backend.preparing
                onMoved: deck.backend.seek(value)
                Accessible.name: deck.backend.tr("Playback position")
                background: Rectangle { x: parent.leftPadding; y: (parent.height - height) / 2; width: parent.availableWidth; height: 2; color: deck.colors.edge; Rectangle { width: parent.width * parent.parent.visualPosition; height: 2; color: deck.colors.accent } }
                handle: Rectangle { x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width); y: (parent.height - height) / 2; width: 8; height: 8; radius: 4; color: deck.colors.accent }
            }
        }
    }
    Row {
        x: deck.compact ? 14 : deck.width - width - 14
        y: deck.compact ? 84 : (deck.height - height) / 2
        spacing: 6
        enabled: !deck.backend.preparing
        DemoButton { objectName: "nestPrevious"; colors: deck.colors; width: 44; text: "|‹"; enabled: deck.controller.hasDisc && !deck.controller.busy; Accessible.name: deck.backend.tr("Previous track"); onClicked: deck.backend.previous() }
        DemoButton { objectName: "nestToggle"; colors: deck.colors; width: deck.compact ? 82 : 90; text: deck.backend.tr(deck.backend.playing && !deck.backend.paused ? "Pause" : "Play"); enabled: deck.controller.hasDisc && !deck.controller.busy; onClicked: deck.backend.toggle() }
        DemoButton { objectName: "nestNext"; colors: deck.colors; width: 44; text: "›|"; enabled: deck.controller.hasDisc && !deck.controller.busy; Accessible.name: deck.backend.tr("Next track"); onClicked: deck.backend.next() }
        DemoButton { objectName: "nestEject"; colors: deck.colors; text: deck.backend.tr("Eject"); enabled: deck.controller.hasDisc && !deck.controller.busy && !deck.backend.preparing; onClicked: deck.controller.eject() }
    }
}
