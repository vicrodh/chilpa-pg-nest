import QtQuick
Rectangle {
    id:lcd
    objectName:"nestDeckLCD"
    required property var deck
    readonly property var backend:deck.backend
    readonly property bool compact:deck.profile!=="full"
    readonly property bool stacked:deck.vertical
    readonly property real clockWidth:compact ? 82:106
    readonly property real metadataWidth:Math.max(0,width-28-clockWidth)
    property bool remaining:false
    property bool volumeShown:false
    property int busyIndex:0
    property real dragPosition:0
    readonly property real displayedPosition:seekControl.pressed ? dragPosition:Math.floor(backend.position)
    readonly property string phase:deck.controller ? deck.controller.phase:""
    readonly property bool reading:phase==="loading" || backend.preparing
    readonly property string message:volumeShown ? "VOL "+backend.volume:backend.tr(backend.error ? "Can't play":phase==="ejecting" ? "Open":reading ? "Reading":!deck.hasMedia ? "No disc":"").toUpperCase()
    color:"#080a09";radius:6;border.width:2;border.color:"#050606"
    Rectangle {x:2;y:2;width:parent.width-4;height:1;color:"#40000000"}
    FontLoader {id:digits;source:"fonts/DSEG7Classic-Bold.ttf"}
    FontLoader {id:codes;source:"fonts/DSEG14Classic-Bold.ttf"}
    function showVolume(){volumeShown=true;volumeHold.restart()}
    Timer {id:volumeHold;interval:1200;onTriggered:lcd.volumeShown=false}
    Timer {interval:120;repeat:true;running:lcd.visible && lcd.reading;onTriggered:lcd.busyIndex=(lcd.busyIndex+1)%8}
    Item {
        id:metadata;objectName:"nestDeckMetadata"
        x:10;y:lcd.compact ? 5:10
        width:lcd.stacked ? parent.width-20:lcd.metadataWidth
        height:lcd.stacked ? 48:parent.height-y-10;clip:true
        DeckMarquee {
            width:parent.width
            text:lcd.message || lcd.backend.title || (deck.album ? deck.album.title:"")
            ink:lcd.backend.error ? "#ff7a6b":lcd.message ? "#ffb547":"#f4eee3"
            family:lcd.message && lcd.backend.language==="en" ? codes.name:"Inter"
            pixels:lcd.compact ? 12:15
            active:deck.live && !deck.controller.reducedMotion && !lcd.message
        }
        DeckMarquee {y:lcd.compact ? 17:22;width:parent.width;text:deck.hasMedia ? lcd.backend.artist:"CHILPA NEST";ink:"#d6c49c";pixels:lcd.compact ? 10:12;active:deck.live && !deck.controller.reducedMotion}
        DeckMarquee {y:40;width:parent.width;height:14;visible:!lcd.compact && !lcd.stacked && !lcd.message;text:(deck.album || lcd.backend.currentAlbum || {}).title || "";ink:"#b6b9ad";pixels:10;active:deck.live && !deck.controller.reducedMotion}
    }
    Item {
        id:timeBlock;objectName:"nestDeckTimeBlock"
        x:parent.width-width-10;y:lcd.stacked ? 60:lcd.compact ? 5:10
        width:lcd.clockWidth;height:lcd.compact ? 38:54
        Text {objectName:"nestDeckTrackCounter";width:parent.width;height:16;text:deck.hasMedia ? lcd.backend.trackNumber+" / "+lcd.backend.trackTotal:"-- / --";horizontalAlignment:Text.AlignRight;color:"#d6c49c";font.pixelSize:lcd.compact ? 9:11}
        Text {
            y:lcd.compact ? 17:24;width:parent.width;height:lcd.compact ? 20:28
            text:!deck.hasMedia ? "--:--":lcd.remaining ? lcd.backend.remaining:lcd.backend.elapsed
            horizontalAlignment:Text.AlignRight;color:"#ffb547";font.family:digits.name;font.pixelSize:lcd.compact ? 16:22
        }
        MouseArea {anchors.fill:parent;onClicked:lcd.remaining=!lcd.remaining}
        Accessible.role:Accessible.Button;Accessible.name:lcd.backend.tr("Toggle elapsed and remaining time")
    }
    Text {
        x:10;y:lcd.stacked ? 66:parent.height-22
        width:lcd.stacked ? lcd.metadataWidth:lcd.metadataWidth
        text:[lcd.backend.quality,lcd.backend.origin,lcd.backend.shuffle ? "SHUF":"",lcd.backend.repeatMode ? "REP"+(lcd.backend.repeatMode===2 ? " 1":""):""].filter(s=>s).join("  ·  ")
        visible:!lcd.message && deck.hasMedia && lcd.height>=50;color:"#d6c49c";font.pixelSize:9;elide:Text.ElideRight;wrapMode:lcd.stacked ? Text.WordWrap:Text.NoWrap
    }
    Row {x:10;y:parent.height-8;spacing:2;visible:lcd.reading;Repeater {model:8;Rectangle {required property int index;width:6;height:2;color:index===lcd.busyIndex ? "#ffb547":"#302b19"}}}
    Item {
        id:seek;x:10;width:parent.width-20;y:parent.height-5;height:3
        Rectangle {anchors.fill:parent;color:"#302b19"}
        Rectangle {objectName:"nestDeckProgress";width:parent.width*(lcd.backend.duration>0 ? Math.min(1,lcd.displayedPosition/lcd.backend.duration):0);height:3;color:"#ffb547"}
    }
    MouseArea {
        id:seekControl;objectName:"nestDeckSeek"
        x:10;y:parent.height-32;width:lcd.stacked ? Math.max(0,lcd.metadataWidth):lcd.metadataWidth;height:32
        enabled:deck.hasMedia && lcd.backend.duration>0
        function seekAt(mouse){lcd.dragPosition=Math.max(0,Math.min(1,mouse.x/width))*lcd.backend.duration;lcd.backend.seek(lcd.dragPosition)}
        onPressed:mouse=>seekAt(mouse)
        onPositionChanged:mouse=>{if(pressed)seekAt(mouse)}
        Accessible.role:Accessible.Slider;Accessible.name:lcd.backend.tr("Playback position")
    }
    Keys.onPressed:event=>{if(event.key===Qt.Key_Left || event.key===Qt.Key_Right){backend.seek(Math.max(0,Math.min(backend.duration,backend.position+(event.key===Qt.Key_Right ? 5:-5))));event.accepted=true}}
    activeFocusOnTab:true
    Rectangle {anchors.fill:parent;anchors.margins:-3;color:"transparent";radius:9;border.color:deck.colors.focus;border.width:2;visible:lcd.activeFocus}
}
