import QtQuick
import QtQuick.Controls.Basic as Controls

Item {
    id:marquee
    property string text:""
    property bool active:false
    property color ink:"#f4eee3"
    property string family:"Inter"
    property int pixels:13
    property bool requested:false
    readonly property bool scrolling: active && requested && label.implicitWidth>width
    clip:true
    height:18
    Text {
        id:label
        text:marquee.text
        width:marquee.scrolling ? implicitWidth:marquee.width
        color:marquee.ink;font.family:marquee.family;font.pixelSize:marquee.pixels;font.weight:Font.DemiBold
        elide:Text.ElideRight
    }
    onScrollingChanged:if(!scrolling)label.x=0
    onTextChanged:if(cycle.running)cycle.restart()
    TapHandler {onTapped:if(marquee.active && label.implicitWidth>marquee.width)marquee.requested=true}
    HoverHandler {id:hover}
    Controls.ToolTip.visible:hover.hovered && label.implicitWidth>marquee.width
    Controls.ToolTip.text:marquee.text
    SequentialAnimation {
        id:cycle
        running:marquee.scrolling
        loops:1
        onFinished:{marquee.requested=false;label.x=0}
        PauseAnimation{duration:1500}
        NumberAnimation{target:label;property:"x";from:0;to:Math.min(0,marquee.width-label.implicitWidth);duration:Math.max(1,(label.implicitWidth-marquee.width)*1000/30)}
        PauseAnimation{duration:1500}
        NumberAnimation{target:label;property:"x";to:0;duration:0}
    }
}
