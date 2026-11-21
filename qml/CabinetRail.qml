import QtQuick

Rectangle {
    required property var colors
    color: colors.rail
    gradient: Gradient {
        GradientStop { position: 0; color: colors.railTop }
        GradientStop { position: 0.17; color: colors.rail }
        GradientStop { position: 0.82; color: colors.rail }
        GradientStop { position: 1; color: colors.railBottom }
    }
    Image { anchors.fill: parent; source: colors.wood ? "woodgrain.svg" : ""; fillMode: Image.Tile; opacity: 0.25 }
    Rectangle { y: 0; width: parent.width; height: 1; color: "#45ffffff" }
    Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: "#40000000" }
}
