import QtQuick
import "qrc:/qt/qml/app/chilpa/kit/qml/Primitives" as Ui
Item {
    property var backend: null
    function focusInput() { input.focusInput() }
    implicitHeight: 40
    Ui.SearchField {
        id: input
        objectName: "nestSearch"
        width: Math.min(parent.width, 320); height: 36
        placeholder: parent.backend.tr("Album or artist"); shortcut: ""
        onAccepted: if (parent.backend) parent.backend.query = text
        onTextChanged: delay.restart()
        onEscaped: if (parent.backend) parent.backend.query = ""
        onCleared: if (parent.backend) parent.backend.query = ""
        Timer { id: delay; interval: 160; onTriggered: if (input.parent.backend) input.parent.backend.query = input.text }
    }
}
