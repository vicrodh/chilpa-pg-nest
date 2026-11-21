import QtQuick
import QtQuick.Window

Item {
    id: deck
    objectName: "nestCDDeck"
    required property var backend
    required property var controller
    property var transport: null
    property var display: null
    readonly property var nest: backend.surface
    readonly property var album: controller ? controller.loaded:null
    readonly property bool hasDisc: album !== null
    readonly property bool hasMedia: hasDisc || backend.playing || backend.paused
    readonly property bool canLoad: !!controller && !hasDisc && !controller.busy && !backend.preparing
    readonly property bool live: visible && !!nest && nest.presented && !!controller && backend.playing && !backend.paused
    readonly property bool vertical: nest && nest.deckDock !== "bottom"
    readonly property string profile: vertical ? "full" : nest ? nest.effectiveDeckProfile : "slim"
    readonly property bool compact: profile !== "full"
    readonly property bool minimal: profile === "minimal"
    readonly property bool showSpectrum: nest && nest.spectrumEnabled && (vertical ? height >= 640 : !compact && modules.width >= 1140)
    readonly property alias colors: finishPalette
    readonly property alias trayItem: tray
    readonly property real pad: vertical ? 16 : compact ? 12 : 16
    readonly property real gap: compact || modules.width < 1140 ? 10 : 14
    readonly property real keyWidth: vertical ? 56 : compact ? 44 : 48
    readonly property real legendHeight: minimal ? 44 : 58
    implicitHeight: profile === "minimal" ? 64 : profile === "slim" ? 76 : 112
    DeckPalette { id: finishPalette; silver: deck.nest && deck.nest.deckFinish === "silver" }
    Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: finishPalette.faceTop } GradientStop { position: .55; color: finishPalette.faceMid } GradientStop { position: 1; color: finishPalette.faceBottom } } }
    Image { anchors.fill: parent; source: "deck-brush.svg"; fillMode: Image.Tile }
    Rectangle { width: parent.width; height: 1; color: finishPalette.edge }
    Rectangle { width: parent.width; height: 1; y: parent.height-1; color: finishPalette.edgeLow }
    Item {
        id: modules
        width: deck.vertical ? parent.width : Math.min(parent.width,deck.compact ? 1280:1440)
        height: parent.height; anchors.horizontalCenter: parent.horizontalCenter
        DeckTray {
            id: tray; deck: deck; minimal: deck.minimal
            x: deck.pad; y: deck.vertical ? 16 : (modules.height-height)/2
            width: height
            height: deck.vertical ? Math.max(150,Math.min(180,modules.height-(32+132+58+74+48+(deck.showSpectrum ? 84:0)))) : deck.minimal ? 48 : deck.compact ? 60:96
        }
        DeckKey {
            id: eject
            objectName: "nestDeckEject"; colors: finishPalette
            x: deck.vertical ? 16 : tray.x+tray.width+deck.gap
            y: deck.vertical ? tray.y+tray.height+12 : (modules.height-height)/2
            visible: !deck.vertical
            width: deck.keyWidth; legend:deck.minimal ? "":deck.backend.tr("Eject").toUpperCase(); glyph: "eject"; tip:deck.backend.tr("Eject CD")
            enabled: deck.hasDisc && !deck.controller.busy && !deck.backend.preparing
            led: deck.backend.error ? finishPalette.red : deck.controller && deck.controller.busy ? finishPalette.amber:finishPalette.off
            onClicked: deck.controller.eject()
        }
        DeckLCD {
            id: lcd; deck: deck
            x: deck.vertical ? 16 : eject.x+eject.width+deck.gap
            y: deck.vertical ? tray.y+tray.height+12 : (modules.height-height)/2
            width: deck.vertical ? 248 : transportKeys.x-deck.gap-x-(deck.showSpectrum ? 196+deck.gap:0)
            height: deck.vertical ? 132 : deck.compact ? modules.height-20:88
        }
        Loader {
            id: spectrum; active: deck.showSpectrum
            x: deck.vertical ? 16 : lcd.x+lcd.width+deck.gap
            y: deck.vertical ? lcd.y+lcd.height+12 : 12
            width: deck.vertical ? 248:196; height: deck.vertical ? 72:88
            sourceComponent: DeckSpectrum { backend: deck.backend; live: deck.live }
        }
        Row {
            id: transportKeys
            x: deck.vertical ? 16 : modules.width-deck.pad-setup.width-deck.gap-volume.width-deck.gap-modes.width-deck.gap-width
            y: deck.vertical ? lcd.y+lcd.height+12+(deck.showSpectrum ? 84:0) : (modules.height-height)/2
            spacing: deck.vertical ? 8 : deck.compact ? 4:6
            Repeater {
                model: ["prev","playpause","stop","next"]
                DeckKey {
                    required property string modelData
                    objectName: "nestDeck."+modelData; colors: finishPalette; width: deck.keyWidth
                    legend:deck.minimal ? "":deck.backend.tr(({prev:"Previous",playpause:"Play",stop:"Stop",next:"Next"})[modelData]).toUpperCase()
                    glyph: modelData === "playpause" && deck.live ? "pause":modelData
                    tip:deck.backend.tr(modelData === "prev" ? "Previous track":modelData === "next" ? "Next track":modelData === "stop" ? "Stop without ejecting":deck.live ? "Pause":"Play")
                    enabled: deck.hasMedia && !!deck.controller && !deck.controller.busy && !deck.backend.preparing
                    led: modelData === "playpause" ? (deck.live ? finishPalette.green:deck.backend.paused ? finishPalette.amber:finishPalette.off):finishPalette.off
                    onClicked: { if(modelData==="prev")deck.backend.previous();else if(modelData==="next")deck.backend.next();else if(modelData==="stop")deck.backend.deckStop();else deck.backend.toggle() }
                }
            }
        }
        Row {
            id: modes
            x: deck.vertical ? 16 : modules.width-deck.pad-setup.width-deck.gap-volume.width-deck.gap-width
            y: deck.vertical ? transportKeys.y+transportKeys.height+12 : (modules.height-height)/2
            spacing: deck.compact ? 4:6
            DeckKey { objectName:"nestDeckShuffle"; colors:finishPalette; width:deck.compact ? 44:52; glyph:"shuffle"; legend:deck.minimal ? "":deck.backend.tr("Shuffle").toUpperCase(); tip:deck.backend.tr("Shuffle"); enabled:deck.hasDisc && !deck.controller.busy; led:deck.backend.shuffle ? finishPalette.amber:finishPalette.off; onClicked:deck.backend.toggleShuffle() }
            DeckKey { objectName:"nestDeckRepeat"; colors:finishPalette; width:deck.compact ? 44:52; glyph:"repeat"; legend:deck.minimal ? "":deck.backend.tr("Repeat").toUpperCase()+(deck.backend.repeatMode===2 ? " 1":""); tip:deck.backend.tr("Repeat"); enabled:deck.hasDisc && !deck.controller.busy; led:deck.backend.repeatMode ? finishPalette.amber:finishPalette.off; onClicked:deck.backend.cycleRepeat() }
        }
        DeckKnob {
            id: volume; objectName:"nestDeckVolume"; colors:finishPalette; backend:deck.backend
            legends: !deck.minimal; width:deck.vertical ? 60:deck.compact ? 48:60
            x: deck.vertical ? 16+modes.width+14 : modules.width-deck.pad-setup.width-deck.gap-width
            y: deck.vertical ? modes.y : (modules.height-height)/2
            onAdjusted:lcd.showVolume()
        }
        DeckKey {
            id: setup; objectName:"nestDeckSetup"; colors:finishPalette; width:deck.vertical ? 48:deck.keyWidth
            x: deck.vertical ? modules.width-width-16 : modules.width-width-deck.pad
            y: deck.vertical ? modes.y : (modules.height-height)/2
            glyph:"settings"; legend:deck.minimal ? "":deck.backend.tr("Setup").toUpperCase(); tip:deck.backend.tr("Nest settings")
            led:deck.nest && deck.nest.sortingOpen ? finishPalette.amber:finishPalette.off
            onClicked:if(deck.nest)deck.nest.command("settings")
        }
        DeckKey {
            objectName:"nestDeckVerticalEject"; colors:finishPalette; visible:deck.vertical
            x:modules.width-width-deck.pad;y:tray.y+(tray.height-height)/2;width:44;glyph:"eject";tip:deck.backend.tr("Eject CD")
            enabled:deck.hasDisc && !deck.controller.busy && !deck.backend.preparing; onClicked:deck.controller.eject()
        }
    }
    function registerTray(){if(display)display.trayTarget=tray}
    onDisplayChanged:registerTray()
    Component.onCompleted:registerTray()
    Component.onDestruction:if(display && display.trayTarget===tray)display.trayTarget=null
}
