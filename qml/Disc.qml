import QtQuick

Item {
    id: disc
    property color accent: "#bd754b"
    property string title: ""
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        border.width: 2
        border.color: "#c9d1ca"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#99a8a0" }
            GradientStop { position: 0.24; color: "#e0d9d0" }
            GradientStop { position: 0.5; color: "#fbfaf1" }
            GradientStop { position: 0.72; color: "#b7c6c5" }
            GradientStop { position: 1; color: "#e7e0ce" }
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.76; height: width; radius: width / 2
            color: disc.accent
            border.color: "#40ffffff"
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.18
                width: parent.width * 0.74
                horizontalAlignment: Text.AlignHCenter
                text: disc.title.toUpperCase()
                elide: Text.ElideRight
                color: "#fff9e9"
                font.pixelSize: Math.max(9, disc.width * 0.048)
                font.letterSpacing: 2
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.72
                text: "CHILPA NEST"
                color: "#fff9e9"
                font.pixelSize: Math.max(7, disc.width * 0.035)
                font.letterSpacing: 2
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.22; height: width; radius: width / 2
            color: "#d7d8cf"
            border.color: "#f9f4df"
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.42; height: width; radius: width / 2
                color: "#30332e"
                border.color: "#90958b"
            }
        }
    }
}
