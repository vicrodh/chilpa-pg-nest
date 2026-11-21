import QtQuick
import "qrc:/qt/qml/app/chilpa/kit/qml/Patterns" as HostPatterns

HostPatterns.ConfirmDialog {
    objectName:"nestReplaceDialog"
    property var controller
    property var backend
    readonly property var request:controller ? controller.replacement:null
    title:backend ? backend.tr("Replace the loaded CD?"):""
    message:backend && request ? backend.tr("Stop and eject “{current}”, then play “{next}”?",{current:controller.loaded ? controller.loaded.title:"",next:request.album.title}):""
    confirmText:backend ? backend.tr("Eject and play"):""
    cancelText:backend ? backend.tr("Cancel"):""
    onConfirmed:controller.confirmReplacement()
    onDismissed:controller.cancelReplacement()
}
