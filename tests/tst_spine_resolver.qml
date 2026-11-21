import QtQuick
import QtTest
import "../qml"

TestCase {
    id: tests
    name: "SpineResolver"
    when: windowShown
    width: 400; height: 300; visible: true
    Component {
        id: backendFactory
        QtObject {
            property bool offline: false
            property Component hintComponent: null
            property var preferences: ({})
            property var saved: ({})
            function spineFor(album) { return saved[album.id] || "" }
            function setSpine(album,url) { const next=Object.assign({},saved);next[album.id]=String(url);saved=next }
            function readPreference(key,fallback) { return preferences[key] || fallback }
            function keepPreference(key,value) { const next=Object.assign({},preferences);next[key]=value;preferences=next }
        }
    }
    Component {
        id: fakeArchive
        QtObject {
            property bool busy: false
            property string error: ""
            property var releases: []
            property var candidates: []
            property int searches: 0
            property int reads: 0
            property int cancels: 0
            property bool missing: false
            property bool hold: false
            signal changed()
            signal saved(url image)
            function cancel() { cancels++;busy=false;changed() }
            function search(artist,title) { searches++;busy=true;error="";releases=[{id:"edition",cd:true,date:"2001",score:100,detail:"2001 · CD"}];if(!hold)Qt.callLater(complete) }
            function complete() { busy=false;changed() }
            function images(id) { reads++;busy=true;candidates=missing ? []:[{url:"https://archive.org/fixture.png",preview:"https://archive.org/preview.png",spine:true,combined:false,label:"Spine"}];Qt.callLater(complete) }
            function save(url,crop) { saved("file:///fixture-spine.png") }
        }
    }
    Component { id: serviceFactory; SpineResolver { archiveComponent:fakeArchive } }
    property var backend
    property var service
    readonly property var album: ({id:42,title:"A fixture",artist:"An artist",year:"2001"})
    function init(){backend=createTemporaryObject(backendFactory,tests);service=createTemporaryObject(serviceFactory,tests,{backend:backend,automatic:true})}
    function cleanup(){service.suspend();service.destroy();backend.destroy();service=null;backend=null}
    function test_unique_edition_applies_spine_and_stops_its_clock(){
        service.request(album)
        tryVerify(() => backend.spineFor(album) !== "",4000)
        compare(service.archive.searches,1)
        compare(service.archive.reads,1)
        compare(service.stateFor(album).state,"found")
        verify(!service.busy && !service.scheduled)
        service.request(album)
        wait(50)
        compare(service.archive.searches,1)
    }
    function test_missing_spines_are_cached_and_not_retried_on_every_view(){
        service.archive.missing=true
        service.request(album)
        tryVerify(() => service.stateFor(album) !== null,4000)
        compare(service.stateFor(album).state,"missing")
        compare(backend.spineFor(album),"")
        const searches=service.archive.searches
        service.request(album);wait(1400)
        compare(service.archive.searches,searches)
        verify(!service.scheduled)
    }
    function test_hiding_cancels_inflight_lookup_and_discards_queued_work(){
        service.archive.hold=true
        service.request(album)
        tryVerify(() => service.archive.busy,2500)
        service.automatic=false
        compare(service.queue.length,0)
        verify(!service.busy && !service.scheduled && !service.archive.busy)
        verify(service.archive.cancels>0)
        compare(service.stateFor(album),null)
    }
    function test_queue_and_persistent_journal_have_limits(){
        service.archive.hold=true
        for(let i=1;i<=400;i++)service.request({id:i,title:"Fixture",artist:"Artist",year:"2001"})
        verify(service.queue.length<=256)
        service.suspend()
        const journal={}
        for(let i=1;i<=2100;i++)journal[String(i)]={state:"missing",time:i,message:"x".repeat(400)}
        service.journal=journal;service.current=album;service.results=[];service.finish("missing","Fixture")
        verify(Object.keys(service.journal).length<=2048)
        verify(JSON.stringify(service.journal).length<=524288)
    }
}
