import QtQuick
import QtQuick.Controls.Basic
Rectangle {
 property var backend
 signal closed()
 color:backend.hostWindow
 Column { anchors.fill:parent; anchors.margins:20; spacing:12
  Button { text:"Close"; onClicked:closed() }
  ComboBox { model:["artist","year","decade","none"]; currentIndex:model.indexOf(backend.grouping); onActivated:backend.surface.setting("group",currentText) }
  ComboBox { model:["artist-year","title","year"]; currentIndex:model.indexOf(backend.sort); onActivated:backend.surface.setting("sort",currentText) }
  Switch { text:"Show separators"; checked:backend.surface.showSeparators; onToggled:backend.surface.setting("separators",String(checked)) }
 }
}
