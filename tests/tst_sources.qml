import QtQuick
import QtTest
import "../qml"

TestCase {
    name:"NestSourceSelection"
    QtObject {
        id:scope
        property var excludedSources:[]
        function setting(key,value){const id=key.slice(7);excludedSources=value==="true" ? excludedSources.filter(item=>item!==id):excludedSources.concat([id])}
    }
    QtObject {
        id:backend
        property var surface:scope
        property var requested:[]
        property var sources:[]
        function includeSource(plugin){requested=requested.concat([plugin.id])}
    }
    SourceSelection {id:selection;backend:backend}
    function init(){scope.excludedSources=[];backend.requested=[];backend.sources=[{key:"local:default",label:"Local",count:8,plugin:null},{key:"plugin:fixture",label:"Saved source",count:-1,plugin:{id:"fixture",actions:["album_library"],on:false}}]}
    function test_unlisted_saved_source_can_join_and_remains_available_when_hidden(){
        compare(selection.rows.length,2);compare(selection.rows[1].on,false)
        selection.flip(selection.rows[1],true);compare(backend.requested,["fixture"])
        backend.sources=[backend.sources[0],Object.assign({},backend.sources[1],{plugin:{id:"fixture",actions:["album_library"],on:true}})]
        compare(selection.rows[1].on,true)
        selection.flip(selection.rows[1],false);compare(selection.rows.length,2);compare(selection.rows[1].on,false)
        selection.flip(selection.rows[1],true);compare(selection.rows[1].on,true);compare(backend.requested,["fixture"])
    }
    function test_local_switch_only_changes_this_view(){selection.flip(selection.rows[0],false);compare(scope.excludedSources,["local:default"]);compare(backend.requested,[])}
}
