import QtQuick
import "native" as Native

// A single precomposed texture rotates without per-frame image painting.
Item {
    id:disc
    property string title:""
    property string artist:""
    property url art:""
    property bool preparing:false
    property color recess:"#0b0c0d"
    Native.SpinePalette {id:discPalette;source:disc.art;active:disc.visible || disc.preparing}
    Loader {
        active:disc.visible || disc.preparing
        sourceComponent:Native.DiscArt {width:256;height:256;scale:disc.width/256;transformOrigin:Item.TopLeft;source:disc.art;active:true;color:discPalette.background}
    }
    Text {x:width*.1;y:height*.14;width:parent.width*.8;text:disc.art ? "":disc.title;color:discPalette.foreground;font.pixelSize:Math.max(7,disc.width*.065);font.weight:Font.DemiBold;elide:Text.ElideRight;horizontalAlignment:Text.AlignHCenter}
}
