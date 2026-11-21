import QtQuick
import QtQuick.Controls.Basic
Dialog {
    objectName:"nestReplaceDialog"
    property var controller
    property var backend
    parent:Overlay.overlay
    anchors.centerIn:parent
    modal:true
    title:backend ? backend.tr("Replace the loaded CD?"):""
    standardButtons:Dialog.Ok | Dialog.Cancel
    onAccepted:controller.confirmReplacement()
    onRejected:controller.cancelReplacement()
}
