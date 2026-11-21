import QtQuick
import QtQuick.Controls.Basic
Item { property var backend; implicitHeight:40
 TextField { objectName:"nestSearch"; width:Math.min(parent.width,320); height:36; placeholderText:"Album or artist"; onTextEdited:parent.backend.query=text }
}
