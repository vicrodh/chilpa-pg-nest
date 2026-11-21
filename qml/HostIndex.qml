import QtQuick
import "qrc:/qt/qml/app/chilpa/kit/qml/Primitives" as Ui
Item {
    property var backend
    ListView {
        anchors.fill:parent; orientation:ListView.Horizontal; clip:true; boundsBehavior:Flickable.StopAtBounds
        model:["#","@"].concat("ABCDEFGHIJKLMNOPQRSTUVWXYZ".split(""))
        delegate:Ui.PillButton {
            required property string modelData
            objectName:"nestIndex_"+modelData
            text:modelData; kind:"ghost"; width:44; height:32
            enabled:backend && backend.surface && backend.surface.indexTarget(modelData)>=0
            onClicked:backend.surface.jumpIndex(modelData)
        }
    }
}
