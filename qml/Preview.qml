import QtQuick
import QtQuick.Controls.Basic

ApplicationWindow {
    width: 1180; height: 760
    minimumWidth: 340; minimumHeight: 320
    visibility: Window.Windowed
    title: "Chilpa Nest · Preview"
    NestPresentation { anchors.fill: parent; backend: DemoBackend {} }
}
