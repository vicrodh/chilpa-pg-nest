import QtQuick

QtObject {
    required property var backend
    readonly property var rows:backend.sources.map(row=>Object.assign({},row,{
        on:(!row.plugin || row.plugin.on) && !!backend.surface && !backend.surface.excludedSources.includes(row.key)
    }))
    function flip(row,on){
        if(!backend.surface)return
        if(on && row.plugin && !row.plugin.on)backend.includeSource(row.plugin)
        backend.surface.setting("source:"+row.key,String(on))
    }
}
