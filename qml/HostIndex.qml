import QtQuick
import QtQuick.Controls.Basic as Controls
import "qrc:/qt/qml/app/chilpa/kit/qml/Theme" as T

Item {
    id: index
    property var backend
    readonly property var palette: backend && backend.surface ? backend.surface.colors : null
    ListView {
        anchors.fill: parent
        orientation: ListView.Horizontal
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: ["#", "@"].concat("ABCDEFGHIJKLMNOPQRSTUVWXYZ".split(""))
        delegate: Controls.AbstractButton {
            id: button
            required property string modelData
            objectName: "nestIndex_" + modelData
            text: modelData
            width: 44; height: 32
            hoverEnabled: true
            activeFocusOnTab: enabled
            enabled: index.backend && index.backend.surface && index.backend.surface.indexTarget(modelData) >= 0
            contentItem: Text {
                text: button.text
                color: index.palette ? (button.enabled ? index.palette.text : index.palette.indexUnavailable) : "#292d2b"
                font.pointSize: T.Type.small
                font.weight: button.enabled ? Font.DemiBold : Font.Normal
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                radius: height / 2
                color: button.enabled && (button.hovered || button.down) && index.palette ? index.palette.panel : "transparent"
                border.width: button.activeFocus ? 1 : 0
                border.color: index.palette ? index.palette.accent : "#5d7158"
            }
            onClicked: index.backend.surface.jumpIndex(modelData)
        }
    }
}
