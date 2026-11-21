import QtQuick
import "qrc:/qt/qml/app/chilpa/sources/qml/Patterns" as HostSourcePatterns
import "qrc:/qt/qml/app/chilpa/qml/Components" as App

Column {
    id:filters
    required property var backend
    required property var page
    spacing:12
    Component.onCompleted:backend.sourceFiltersVisible=visible
    onVisibleChanged:if(backend)backend.sourceFiltersVisible=visible
    Component.onDestruction:if(backend)backend.sourceFiltersVisible=false
    App.SettingsRow {
        width:parent.width;rowKind:1;key:"nest.favoritesOnly"
        title:filters.backend.tr("Favorites only")
        description:filters.backend.tr("Saved albums are not automatically favorites.")
        control:"toggle";action:"";value:filters.page.valueFor("favoritesOnly");page:filters.page
        options:[];optionValues:[];marks:[]
    }
    HostSourcePatterns.SourceSwitches {
        objectName:"nestSourceSwitches"
        width:parent.width
        active:filters.visible
        sourceModel:filters.backend.sourceSelector
    }
}
