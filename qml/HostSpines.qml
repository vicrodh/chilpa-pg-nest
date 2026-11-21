import QtQuick
import QtQuick.Controls.Basic as Controls
import "qrc:/qt/qml/app/chilpa/kit/qml/Theme" as T
import "qrc:/qt/qml/app/chilpa/kit/qml/Primitives" as Ui
import "qrc:/qt/qml/app/chilpa/qml/Components" as App
Item {
    id: panel
    function t(message){return backend ? backend.tr(message):message}
    property bool blocksWindowShortcuts: true
    Keys.onEscapePressed: panel.closed()
    property var backend: null
    property var album: null
    property bool showUnavailable: false
    readonly property var resolver: backend && backend.surface ? backend.surface.resolver : null
    signal closed()
    SpineSources { id: logic; backend: panel.backend; album: panel.album }
    function useImage(url,preview,combined) { logic.useImage(url,preview,combined) }
    readonly property string notice: logic.notice
    Rectangle { anchors.fill: parent; radius:T.Metrics.radiusPanel; color:T.Theme.color.surfaceRaised; Ui.Edge {} }
    Column {
        x:20; y:16; width:parent.width - 40; spacing:10
        Row { width:parent.width
            Text { width:parent.width-44; text:panel.t("Spines"); color:T.Theme.color.textPrimary; font.pointSize:T.Type.section; anchors.verticalCenter:parent.verticalCenter }
            Ui.IconButton { objectName:"nestCloseConnections"; size:36; glyph:T.Icons.x; tip:panel.t("Close"); onClicked:panel.closed() }
        }
        Flickable {
            width:parent.width; height:panel.height - 78; clip:true
            contentWidth:width;contentHeight:body.height
            interactive:contentHeight>height;flickableDirection:Flickable.VerticalFlick;acceptedButtons:Qt.NoButton;boundsBehavior:Flickable.StopAtBounds
            Controls.ScrollBar.vertical:Ui.ViewportScrollBar {policy:Controls.ScrollBar.AsNeeded}
            Column {
                id: body
                width:parent.width; spacing:8
                Text { width:parent.width; text:panel.album ? panel.album.artist + " · " + panel.album.title :panel.t("Open a CD to review its spine."); font.pointSize:T.Type.body; color:T.Theme.color.textPrimary; wrapMode:Text.WordWrap }
                Text { width:parent.width; text:panel.t("Automatic edition lookup. Back scans may need cropping; your front cover is preserved."); font.pointSize:T.Type.small; color:T.Theme.color.textSecondary; wrapMode:Text.WordWrap }
                Flow { width:parent.width; spacing:6
                    Ui.PillButton { objectName:"nestSearchSpines"; text:panel.t("Review editions"); enabled:panel.album !== null && panel.resolver !== null && !panel.resolver.busy && !panel.backend.offline; onClicked:panel.resolver.retry(panel.album) }
                    Ui.PillButton { objectName:"nestImportSpine"; text:panel.t("Import scan"); enabled:panel.album !== null && !logic.busy; onClicked:logic.importImage() }
                }
                Text { width:parent.width; text:panel.t(logic.error || logic.notice || (panel.resolver ? panel.resolver.status : "")); visible:text !== ""; color:logic.error ? T.Theme.color.statusNegative : T.Theme.color.textSecondary; font.pointSize:T.Type.small; wrapMode:Text.WordWrap }
                App.SettingsRow {
                    width:parent.width; rowKind:1; key:"unavailable"; title:"Show editions without a spine"; description:""; control:"toggle"; action:""; value:String(panel.showUnavailable); options:[]; optionValues:[]; marks:[]; page:panel
                }
                Repeater {
                    model: panel.resolver ? panel.resolver.resultsFor(panel.album).filter(item => item.url || panel.showUnavailable).slice().sort((a,b) => Number(!a.url) - Number(!b.url)) : []
                    Ui.MenuEntry {
                        required property var modelData
                        width:body.width; height:44
                        entry:({text:panel.t(modelData.url ? "Review · " : "No spine · ") + panel.t(modelData.edition),enabled:!!modelData.url,glyph:modelData.url ? T.Icons.check : T.Icons.x})
                        onClicked:logic.useImage(modelData.url,modelData.preview,modelData.combined)
                    }
                }
                Column {
                    width:parent.width; spacing:8; visible:logic.selectedImage !== ""
                    Text { width:parent.width; text:panel.t("Crop the spine strip. A horizontal strip rotates when saved."); color:T.Theme.color.textSecondary; font.pointSize:T.Type.small; wrapMode:Text.WordWrap }
                    Item {
                        width:parent.width; height:Math.min(220,width*.65)
                        Rectangle { anchors.fill:parent; color:T.Theme.color.fillField }
                        Image { id:preview; anchors.fill:parent; source:logic.selectedImage ? logic.previewImage : ""; sourceSize:Qt.size(768,768); fillMode:Image.PreserveAspectFit; autoTransform:true; asynchronous:true; cache:false }
                        Rectangle { x:(parent.width-preview.paintedWidth)/2+logic.cropX*preview.paintedWidth; y:(parent.height-preview.paintedHeight)/2+logic.cropY*preview.paintedHeight; width:preview.paintedWidth*logic.cropWidth; height:preview.paintedHeight*logic.cropHeight; color:"#33ffffff"; border.color:T.Theme.color.accent; border.width:2 }
                    }
                    Ui.SelectField { width:Math.min(parent.width,240); options:["Right spine","Left spine","Whole image"].map(option=>panel.t(option)); values:["right","left","whole"]; value:logic.cropWidth === 1 ? "whole" : logic.cropX > .5 ? "right" : "left"; onPicked:value => logic.preset(value) }
                    Flow {
                        width:parent.width; spacing:8
                        Repeater {
                            model:[{key:"cropX",label:"X %"},{key:"cropWidth",label:"Width %"},{key:"cropY",label:"Y %"},{key:"cropHeight",label:"Height %"}]
                            Column {
                                required property var modelData
                                width:Math.max(64,(body.width-24)/4); spacing:3
                                Text { text:panel.t(parent.modelData.label); color:T.Theme.color.textSecondary; font.pointSize:T.Type.small }
                                Ui.TextField { objectName:parent.modelData.key; width:parent.width; placeholder:"%"; text:String(Math.round(logic[parent.modelData.key]*1000)/10); onEditingFinished: { const value = Number(text)/100; if (Number.isFinite(value)) logic[parent.modelData.key] = value } }
                            }
                        }
                    }
                    Ui.PillButton { objectName:"nestSaveSpine"; text:panel.t("Save spine"); kind:"primary"; enabled:!logic.busy; onClicked:logic.save() }
                }
                Ui.PillButton { objectName:"nestForgetSpine"; text:panel.t("Use solid color"); enabled:panel.album !== null; onClicked: { panel.backend.setSpine(panel.album,""); logic.notice = "The cover's dominant color will be used." } }
            }
        }
    }
    Component.onDestruction: if (resolver) resolver.cancelManual()
    function set(key,value) { if (key === "unavailable") showUnavailable = value === "true" }
}
