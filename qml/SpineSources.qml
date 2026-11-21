import QtQuick
import QtQuick.Dialogs
import "native" as Native
Item {
    id: logic
    property var backend: null
    property var album: null
    property string selectedImage: ""
    property string previewImage: ""
    property real cropX: 0
    property real cropWidth: 1
    property real cropY: 0
    property real cropHeight: 1
    property string notice: ""
    readonly property bool busy: archive.busy
    readonly property string error:backend ? backend.tr(archive.error):archive.error
    Native.SpineLibrary {
        id: archive
        onSaved: url => { if (logic.album) logic.backend.setSpine(logic.album,url); logic.notice = "Spine saved for this edition."; logic.selectedImage = "" }
    }
    FileDialog { id: picker; title:logic.backend ? logic.backend.tr("Choose a spine or back scan"):"Choose a spine or back scan"; nameFilters:[logic.backend ? logic.backend.tr("Images (*.png *.jpg *.jpeg *.webp)"):"Images (*.png *.jpg *.jpeg *.webp)"]; onAccepted: if (archive.previewLocal(selectedFile)) logic.useImage(String(selectedFile),String(selectedFile),false) }
    function importImage() { picker.open() }
    function useImage(url,preview,combined) { selectedImage = url; previewImage = preview; preset(combined ? "right" : "whole"); notice = "" }
    function preset(side) { cropX = side === "right" ? .935 : 0; cropWidth = side === "whole" ? 1 : .065; cropY = 0; cropHeight = 1 }
    function save() { if (album && selectedImage) archive.save(selectedImage,Qt.rect(cropX,cropY,cropWidth,cropHeight)) }
}
