import QtQuick

QtObject {
    id: demo
    readonly property bool filteringAvailable:true
    property string language:"en"
    readonly property var strings:NestStrings {language:demo.language}
    function tr(message,args){return strings.t(message,args)}
    readonly property var sources:[{key:"local:default",label:"Local"},{key:"plugin:fixture",label:"Fixture"}]
    property var surface: null
    readonly property var nativeDisplay: null
    readonly property var dragLayer: null
    readonly property bool autoLookupAvailable: false
    property bool reducedMotion:false
    readonly property Component indexComponent: null
    readonly property Component hintComponent: null
    readonly property Component searchComponent: Component { DemoSearch { backend: demo } }
    readonly property Component settingsComponent: Component { DemoSettings { backend: demo } }
    readonly property Component overlayComponent: Component { DemoOverlay { backend: demo } }
    readonly property Component spinesComponent: null
    readonly property Component transportComponent: Component { DemoTransport { backend: demo; controller: demo.surface.controller; colors:demo.surface.colors } }
    readonly property Component deckComponent: Component { CDDeck { backend:demo; controller:demo.surface ? demo.surface.controller:null } }
    property int volume:62
    property bool volumeLocked:false
    property bool shuffle:false
    property int repeatMode:0
    property string quality:"FLAC 24/96"
    property string origin:"LOCAL"
    property var spectrumLevels:[]
    property string trackNumber:"01"
    property string trackTotal:"24"
    function setSpectrumActive(active){}
    function chooseVolume(value,commit){volume=value}
    function toggleShuffle(){shuffle=!shuffle}
    function cycleRepeat(){repeatMode=(repeatMode+1)%3}
    function deckStop(){playing=false;paused=false;position=0}
    property string query: ""
    property string sort: "artist-year"
    property string grouping: "artist"
    property bool loading: false
    property bool playing: false
    property bool paused: false
    property bool preparing: false
    property double activeAlbumId: 0
    property var currentAlbum: null
    property real position: 0
    property real duration: 223
    property string elapsed: "0:00"
    property string remaining: "-3:43"
    property string title: ""
    property string artist: ""
    property string error: ""
    property int revision: 1
    readonly property string navigationRevision:JSON.stringify([revision,query,sort,grouping,surface ? surface.favoritesOnly:false,surface ? surface.excludedSources:[]])
    property int playCalls: 0
    property int stopCalls: 0
    property int size: 240
    property url artworkRoot:""
    property bool distinctArtKeys:false
    property bool permitPlayback: true
    property bool hostDark: false
    property bool hostAmbient: false
    property color hostWindow: hostDark ? "#171918" : "#eeeee9"
    readonly property bool simulated: true
    readonly property bool offline: false
    readonly property Component replacementComponent: Component { DemoReplacement {} }
    readonly property Component trackData: Component {
        QtObject {
            property double albumId: 0
            readonly property var model: ListModel {
                Component.onCompleted: { for (let i = 1; i <= 24; i++) append({rowKind:0,number:i,title:"Track " + i + " · " + demo.names[(i - 1) % 12],duration:"3:42",headerLabel:"",trackId:i,available:true,playing:false}) }
            }
        }
    }
    readonly property Component ambientBackground: Component { Rectangle { gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#294657" } GradientStop { position: 0.5; color: "#7d4c58" } GradientStop { position: 1; color: "#273e37" } } } }
    property int spineRevision: 0
    property color hostAccent: "#927049"
    property real embeddedBottomInset: 0
    property var preferences: ({})
    readonly property var names: ["Quiet mornings", "The blue hour", "Slow motion", "Small worlds", "Northern lights", "Still life", "A warmer place", "Open water", "Soft focus", "After the rain", "Golden days", "Night garden"]
    readonly property var artists: ["Mira Sol", "The Lowland Trio", "Jonas Field", "Alba", "Paper Hours", "Adrian Vale", "Good Company", "The Sound Room"]
    readonly property var matches: {
        const result = []
        for (let index = 0; index < size; index++) {
            const item = record(index)
            if(surface && (surface.excludedSources.includes(item.source) || surface.favoritesOnly && !item.favorite))continue
            if ((item.title + " " + item.artist).toLowerCase().includes(query.toLowerCase())) result.push(index)
        }
        return result.sort((a, b) => {
            const left = record(a), right = record(b)
            const artist = left.artist.localeCompare(right.artist)
            const year = Number(left.year) - Number(right.year)
            const group = grouping === "artist" ? artist : grouping === "year" ? -year : grouping === "decade" ? Math.floor(Number(right.year) / 10) - Math.floor(Number(left.year) / 10) : 0
            return group || (sort === "artist" || sort === "artist-year" ? artist || year : sort === "year" || sort === "year-artist" ? -year || artist : left.title.localeCompare(right.title)) || left.title.localeCompare(right.title) || a - b
        })
    }
    readonly property int count: matches.length
    readonly property int rows: count
    function record(index) { return { source:index%2 ? "plugin:fixture":"local:default",favorite:index%3===0,id:index + 1, title:names[index % names.length] + (index >= 12 ? " · " + (Math.floor(index / 12) + 1) : ""), artist:index < 6 ? "A Collection" : artists[index % artists.length], year:String(1992 + index % 32), art:(String(artworkRoot)!=="" ? String(artworkRoot)+"/"+index+".png":String(Qt.resolvedUrl("demo-" + (index % 6) + ".svg")))+(distinctArtKeys ? "?album="+index:"") } }
    function indexOfAlbum(id){return matches.findIndex(index=>record(index).id===id)}
    function artAt(index){return index>=0 && index<matches.length ? record(matches[index]).art:""}
    function groupLabelAt(index) { return groupLabel(album(index)) }
    function groupIndex() {
        const result = []; let previous = ""
        for (let i = 0; i < count; i++) { const label = groupLabelAt(i); if (label !== previous) { result.push([i,label]); previous=label } }
        return result
    }
    function groupLabel(album) { return grouping === "artist" ? album.artist : grouping === "year" ? album.year : grouping === "decade" ? Math.floor(Number(album.year) / 10) * 10 + "s" : "" }
    function spineFor(album) { const revision = spineRevision; return readPreference("spine." + album.id, album.id <= 6 ? String(Qt.resolvedUrl("demo-spine-" + (album.id - 1) + ".svg")) : "") }
    function setSpine(album, url) { keepPreference("spine." + album.id, String(url)); spineRevision++ }
    function album(index) { return index >= 0 && index < matches.length ? record(matches[index]) : {id:0,title:"",artist:"",year:"",art:""} }
    function available(id) { return permitPlayback && id !== 0 }
    function play(album) { playCalls++; currentAlbum = album; activeAlbumId = album.id; title = "First light"; artist = album.artist; playing = true; paused = false; position = 0 }
    function playTrack(album,row,trackId){play(album);trackNumber=String(row+1).padStart(2,"0");title="Track "+(row+1)}
    function stop() { stopCalls++; playing = false; paused = false; activeAlbumId = 0 }
    function toggle() { if (activeAlbumId) { if(!playing){playing=true;paused=false}else paused=!paused } }
    function next() { position = 0; title = "Another day" }
    function previous() { position = 0; title = "First light" }
    function seek(value) { position = value }
    function readPreference(key, fallback) { return preferences[key] === undefined ? fallback : preferences[key] }
    function keepPreference(key, value) { const next = Object.assign({}, preferences); next[key] = String(value); preferences = next }
}
