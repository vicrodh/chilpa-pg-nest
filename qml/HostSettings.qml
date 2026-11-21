import QtQuick
import QtQuick.Controls.Basic as Controls
import "qrc:/qt/qml/app/chilpa/kit/qml/Theme" as T
import "qrc:/qt/qml/app/chilpa/kit/qml/Primitives" as Ui
import "qrc:/qt/qml/app/chilpa/qml/Components" as App

Controls.Popup {
    id: panel
    function t(message){return backend ? backend.tr(message):message}
    property bool blocksWindowShortcuts: true
    property var backend: null
    readonly property var nest: backend ? backend.surface : null
    property int section:0
    objectName:"nestSettingsPopup"
    parent:backend ? backend.dragLayer || backend.surface:null
    x:parent ? (parent.width-width)/2:0
    y:parent ? (parent.height-height)/2:0
    width:Math.min(parent ? parent.width-32:980,section===2 ? 560:980)
    height:Math.min(parent ? parent.height-32:600,implicitHeight)
    padding:0;modal:true;dim:false;focus:true
    closePolicy:Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnReleaseOutside
    Ui.PopupInput {surface:panel}
    Component.onCompleted:open()
    readonly property real chromeHeight:16+heading.height+sections.height+footer.height+36+12
    readonly property int columns: width >= 820 ? 2:1
    readonly property real formHeight:section===2 ? filters.implicitHeight:form.implicitHeight
    implicitHeight: formHeight+chromeHeight
    readonly property var rows:[
        {key:"spectrum",title:"Show spectrum",control:"toggle",description:"Available in full and vertical decks."},
        {key:"customPlayer",title:"Use Nest player",control:"toggle"},
        {key:"deckProfile",title:"CD Deck size",control:"select",description:"Auto selects Slim at 1024 × 600. Touch targets stay 44 px.",options:["Auto","Full · 112 px","Slim · 76 px","Minimal · 64 px"],values:["auto","full","slim","minimal"]},
        {key:"deckFinish",title:"CD Deck finish",control:"select",options:["Black","Silver"],values:["black","silver"]},
        {key:"deckDock",title:"CD Deck position",control:"select",options:["Bottom","Left","Right"],values:["bottom","left","right"]},
        {key:"theme",title:"Finish",control:"select",options:["Chilpa","Black","White","Wood"],values:["host","dark","light","wood"]},
        {key:"shelves",title:"Shelves",control:"select",description:"Auto fits the available height. Fixed shelves scroll vertically and snap into place.",options:["Auto","1","2","3","4"],values:["auto","1","2","3","4"]},
        {key:"group",title:"Group by",control:"select",options:["Artist","Album title","Main genre","Year","Decade","Label","Source","No grouping"],values:["artist","letter","genre","year","decade","label","source","none"]},
        {key:"sort",title:"Sort within group",control:"select",options:["Artist → Year","Album A–Z","Album Z–A","Year ascending","Year descending","Recently added"],values:["artist-year","title","title-desc","year-asc","year","added"]},
        {key:"density",title:"Spine size",control:"select",options:["Compact","Normal","Tall"],values:["0.85","1","1.25"]},
        {key:"separators",title:"Show separators",control:"toggle"},
        {key:"index",title:"Index # @ A–Z",control:"toggle"},
        {key:"highlight",title:"Highlight playing album",control:"toggle"},
        {key:"images",title:"Show real spines",control:"toggle"},
        {key:"autoSpines",title:"Find spines automatically",control:"toggle",description:"Checks visible editions in the background. Keeps a solid color when no reliable spine is available."},
        {key:"spines",title:"Review a spine",control:"button",description:"Open a CD to review its edition or import a scan.",action:"Spines"},
        {key:"reset",title:"Reset view",control:"button",action:"Reset"}
    ]
    background:Rectangle {radius:T.Metrics.radiusPanel;color:T.Theme.color.surfaceRaised;Ui.Hold {} Ui.Edge {}}
    contentItem:Item {
        objectName:"nestSettingsPanel"
        property alias section:panel.section
        Column {
        x:20;y:16;width:parent.width-40;spacing:12
        Row { id:heading; width: parent.width
            Text { width: parent.width - 44; text: "Chilpa Nest"; color: T.Theme.color.textPrimary; font.pointSize: T.Type.section; anchors.verticalCenter: parent.verticalCenter }
            Ui.IconButton { objectName: "nestCloseSettings"; size: 36; glyph: T.Icons.x; tip:panel.t("Close settings"); onClicked: panel.close() }
        }
        Ui.SegmentedControl {
            id:sections;objectName:"nestSettingsSections";width:parent.width
            options:[{text:panel.t("Shelves")},{text:panel.t("Player")}].concat(panel.backend && panel.backend.filteringAvailable ? [{text:panel.t("Filters")}]:[]);current:panel.section
            onActivated:index=>panel.section=index
        }
        Flickable {
            width: parent.width; height: panel.height - panel.chromeHeight; clip: true
            contentWidth: width
            contentHeight: panel.formHeight
            interactive:contentHeight>height
            flickableDirection:Flickable.VerticalFlick
            acceptedButtons:Qt.NoButton
            boundsBehavior:Flickable.StopAtBounds
            Controls.ScrollBar.vertical:Ui.ViewportScrollBar {policy:Controls.ScrollBar.AsNeeded}
            Grid {
                id:form
                visible:panel.section!==2
                width: parent.width; columns:panel.columns; columnSpacing:20; rowSpacing:0
                Repeater {
                    model:panel.section===2 ? []:panel.rows.filter(row=>panel.section===1 ? panel.isPlayer(row.key):!panel.isPlayer(row.key))
                    App.SettingsRow {
                        required property var modelData
                        width: (form.width-(panel.columns-1)*20)/panel.columns; rowKind: 1; key: "nest." + modelData.key
                        title:modelData.source ? modelData.title:panel.t(modelData.title); description:panel.columns===2 ? "":panel.t(modelData.description || ""); control:panel.isPlayer(modelData.key) && (!panel.nest || (modelData.key==="customPlayer" ? !panel.nest.customPlayerAvailable:!panel.nest.useCustomPlayer)) ? "fixed":modelData.control
                        action:panel.t(modelData.action || ""); value:panel.valueFor(modelData.key)
                        options:(modelData.options || []).map(option=>panel.t(option)); optionValues: modelData.values || []; marks: []
                        page: panel
                    }
                }
            }
            Loader {
                id:filters
                width:Math.min(parent.width,520)
                active:panel.section===2
                sourceComponent:HostFilters {backend:panel.backend;page:panel}
            }
        }
        Row {
            id:footer;width:parent.width;spacing:8
            Ui.PillButton {text:panel.t(panel.nest && panel.nest.fullscreenActive ? "Windowed":"Fullscreen");onClicked:if(panel.nest)panel.nest.fullscreenRequested(!panel.nest.fullscreenActive)}
            Ui.PillButton {text:panel.t("Return to Chilpa");onClicked:panel.exitView()}
        }
    }
    }
    function isPlayer(key){return ["spectrum","customPlayer","deckProfile","deckFinish","deckDock"].includes(key)}
    function valueFor(key){
        if(!nest)return ""
        switch(key){
        case "spectrum":return String(nest.spectrumEnabled)
        case "favoritesOnly":return String(nest.favoritesOnly)
        case "customPlayer":return String(nest.useCustomPlayer)
        case "deckProfile":return nest.deckProfile
        case "deckFinish":return nest.deckFinish
        case "deckDock":return nest.deckDock
        case "theme":return nest.themeMode
        case "shelves":return nest.shelfCount
        case "group":return backend.grouping
        case "sort":return backend.sort
        case "density":return String(nest.density)
        case "separators":return String(nest.showSeparators)
        case "index":return String(nest.showIndex)
        case "highlight":return String(nest.highlightPlaying)
        case "images":return String(nest.imagesEnabled)
        case "autoSpines":return String(nest.autoSpines)
        default:return key.startsWith("source:") ? String(!nest.excludedSources.includes(key.slice(7))):""
        }
    }
    function exitView(){panel.close();if(backend.nativeDisplay)backend.nativeDisplay.leave();else if(nest.presentation)nest.presentation.setFullscreen(false)}
    function set(key, value) { if (nest) nest.setting(key.replace("nest.", ""), value) }
    function press(key) { if (nest) nest.command(key === "nest.reset" ? "reset" : "spines") }
}
