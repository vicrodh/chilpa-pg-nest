import QtQuick
import QtQuick.Controls.Basic

Button {
    id: control
    property bool primary: false
    required property var colors
    property bool quiet: false
    implicitWidth: Math.max(48, label.implicitWidth + 32)
    implicitHeight: 44
    focusPolicy: Qt.StrongFocus
    Accessible.name: text
    contentItem: Text {
        id: label
        text: control.text
        font.pixelSize: 13
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: !control.enabled ? control.colors.muted : control.primary ? control.colors.onAccent : control.colors.text
    }
    background: Rectangle {
        radius: 6
        color: control.primary ? control.colors.accent : control.down || control.hovered ? control.colors.panel : control.quiet ? "transparent" : control.colors.field
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus || control.checked ? control.colors.accent : control.quiet && !control.hovered ? "transparent" : control.colors.edge
        opacity: control.enabled ? 1 : 0.6
    }
}
