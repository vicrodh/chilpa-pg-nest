import QtQuick
import QtQuick.Controls.Basic as Controls
Item {
    id: knob
    function t(message,args){return backend.tr(message,args)}
    required property var colors
    required property var backend
    property bool legends: true
    implicitWidth: 60
    implicitHeight: legends ? 74 : 48
    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.name: knob.t("Volume")
    Accessible.description: knob.t(backend.volumeLocked ? "Fixed volume":"{value} percent",{value:backend.volume})
    signal adjusted()
    function choose(value, commit) { if (!backend.volumeLocked) { backend.chooseVolume(Math.max(0,Math.min(100,Math.round(value))),commit); adjusted() } }
    Keys.onPressed: event => {
        const delta = event.key === Qt.Key_Right || event.key === Qt.Key_Up ? 2 : event.key === Qt.Key_Left || event.key === Qt.Key_Down ? -2 : event.key === Qt.Key_PageUp ? 10 : event.key === Qt.Key_PageDown ? -10 : 0
        if (delta) { choose(backend.volume+delta,true); event.accepted=true }
    }
    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 0; width: Math.min(54,parent.width); height: width; radius: width/2; color: knob.colors.edgeLow; border.color: knob.colors.edge; border.width: 2
        Repeater { model: 32; Rectangle { required property int index; x: parent.width/2-1; y: 1; width: 1; height: 4; color: knob.colors.secondary; transform: Rotation { origin.x: 0; origin.y: parent.height/2-1; angle: index*360/32 } } }
        Rectangle { anchors.centerIn: parent; width: parent.width-10; height: width; radius: width/2; rotation: -135+knob.backend.volume*2.7; opacity: knob.backend.volumeLocked ? .55:1
            gradient: Gradient { GradientStop { position: 0; color: knob.colors.keyTop } GradientStop { position: 1; color: knob.colors.keyBottom } }
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 4; width: 2; height: 12; radius: 1; color: knob.colors.silver ? knob.colors.ink : knob.colors.amber }
        }
    }
    Text { y: parent.height-10; width: parent.width; text: knob.t(knob.backend.volumeLocked ? "Fixed":"Volume").toUpperCase(); color: knob.colors.ink; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; visible: knob.legends }
    Rectangle { anchors.fill: parent; anchors.margins: -2; color: "transparent"; border.width: 2; border.color: knob.colors.focus; radius: 8; visible: knob.activeFocus }
    MouseArea { anchors.fill: parent; hoverEnabled: true; property real startVolume; property point origin
        onPressed: mouse => { knob.forceActiveFocus(); startVolume=knob.backend.volume; origin=Qt.point(mouse.x,mouse.y) }
        onPositionChanged: mouse => { if (pressed) knob.choose(startVolume+((mouse.x-origin.x)-(mouse.y-origin.y))/2,false) }
        onReleased: knob.choose(knob.backend.volume,true)
        onWheel: wheel => { knob.choose(knob.backend.volume+(wheel.angleDelta.y>0 ? 2:-2),true); wheel.accepted=true }
        Controls.ToolTip.visible: containsMouse
        Controls.ToolTip.text: knob.t(knob.backend.volumeLocked ? "Output volume is fixed":"Volume: {value}",{value:knob.backend.volume})
    }
}
