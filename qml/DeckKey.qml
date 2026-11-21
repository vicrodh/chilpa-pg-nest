import QtQuick
import QtQuick.Controls.Basic as Controls
Controls.AbstractButton {
    id: key
    required property var colors
    property string glyph: "playpause"
    property string legend: ""
    property string tip: legend
    property color led: colors.off
    implicitWidth: 48
    implicitHeight: legend ? 58 : 44
    activeFocusOnTab: true
    Accessible.name: tip
    Controls.ToolTip.visible: hovered
    Controls.ToolTip.text: tip
    Controls.ToolTip.delay: 650
    background: Item {
        Rectangle { y: 2; width: parent.width; height: 44; radius: 5; color: key.colors.edgeLow }
        Rectangle {
            width: parent.width; height: 44; y: key.down ? 2 : 0; radius: 5
            gradient: Gradient { GradientStop { position: 0; color: key.hovered && key.enabled ? Qt.lighter(key.colors.keyTop,1.04) : key.colors.keyTop } GradientStop { position: 1; color: key.colors.keyBottom } }
            Rectangle { x: 3; y: 1; width: parent.width-6; height: 1; color: key.colors.edge }
            Behavior on y { NumberAnimation { duration: key.down ? 60 : 90; easing.type: Easing.OutCubic } }
            Rectangle { x: parent.width-14; y: 5; width: 8; height: 3; radius: 1; color: key.led }
            Image { anchors.centerIn: parent; width: 20; height: 18; source: "deck-"+key.glyph+(key.colors.silver ? "-dark.svg":"-light.svg"); opacity: key.enabled ? 1 : .38; sourceSize: Qt.size(40,36); fillMode: Image.PreserveAspectFit }
        }
        Rectangle { x: -3; y: -3; width: parent.width+6; height: 50; radius: 8; color: "transparent"; border.color: key.colors.focus; border.width: 2; visible: key.visualFocus }
    }
    contentItem: Text { y: 48; height: 10; width: key.width; text: key.legend; color: key.colors.ink; font.pixelSize: 9; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignBottom; opacity: key.enabled ? 1 : .38 }
}
