import QtQuick
import QtQuick.Controls.Basic
Item {
 property var backend
 property var album
 property var controller
 property bool back:false
 signal closed()
 signal flipRequested()
 signal spineRequested()
 signal dismissed()
 Rectangle { anchors.fill:parent; color:"#55151918" }
 Button { objectName:"nestFlipCase"; text:back ? "Frente":"Contraportada"; height:44; onClicked:flipRequested() }
 Button { objectName:"nestCloseCase"; anchors.right:parent.right; text:"×"; width:44; height:44; onClicked:closed() }
 Button { objectName:"nestInsert"; anchors.bottom:parent.bottom; anchors.right:parent.right; text:"Play"; height:44; enabled:!controller.busy&&!controller.replacement&&!backend.preparing&&album&&backend.available(album.id); onClicked:controller.requestPlay(album) }
 Button { objectName:"nestEditSpine"; anchors.bottom:parent.bottom; text:"Lomo"; height:44; onClicked:spineRequested() }
}
