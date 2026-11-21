import QtQuick
import app.chilpa
import app.chilpa.kit
import app.chilpa.sources
import app.chilpa.artwork
import app.chilpa.immersive
import app.chilpa.controls
import "qrc:/qt/qml/app/chilpa/sources/qml/Components" as HostViews
import "qrc:/qt/qml/app/chilpa/ambient/qml/Patterns" as HostAmbient
import "qrc:/qt/qml/app/chilpa/kit/qml/Theme" as HostTheme

QtObject {
    id: library
    readonly property bool filteringAvailable:HostViews.DisplayMode.albumScopeVersion === 1
    readonly property string language:I18n.language
    readonly property int localeRevision:I18n.rev
    readonly property var strings:NestStrings {language:library.language}
    function tr(message,args){const rev=localeRevision;return strings.t(message,args)}
    property bool sourceFiltersVisible:false
    readonly property var sourceCatalog:HostViews.SourceRows {active:library.sourceFiltersVisible && !!library.surface && library.surface.presented}
    readonly property var sources:sourceCatalog.rows
    readonly property var sourceSelector:SourceSelection {backend:library}
    function includeSource(plugin){plugin.actions.forEach(action=>Sources.command(action,plugin.id,"true"))}
    property var surface: null
    readonly property var nativeDisplay: HostViews.DisplayMode
    readonly property var dragLayer: HostViews.DisplayMode.dragLayer
    readonly property Component searchComponent: Component { HostSearch { backend: library } }
    readonly property Component settingsComponent: Component { HostSettings { backend: library } }
    readonly property Component overlayComponent: Component { HostOverlay { backend: library } }
    readonly property Component spinesComponent: Component { HostSpines { backend: library } }
    readonly property Component indexComponent: Component { HostIndex { backend: library } }
    readonly property Component transportComponent: null
    readonly property Component deckComponent: Component { CDDeck { backend:library; controller:library.surface ? library.surface.controller:null } }
    readonly property int volume: Player.volume
    readonly property bool volumeLocked: Player.volumeLocked
    readonly property bool shuffle: Player.shuffle
    readonly property int repeatMode: Player.repeat
    readonly property string quality: Player.qualityLabel
    readonly property string origin: {
        if (!Player.albumId) return ""
        if (Player.albumId > 0) return tr("Local").toUpperCase()
        const card = JSON.parse(Sources.card(Player.albumId, Library.remoteRev) || "{}")
        const panel = (JSON.parse(Sources.snapshot || "{}").panels || []).find(item => item.id === card.plugin)
        return panel ? panel.name : tr("Remote").toUpperCase()
    }
    readonly property var spectrumLevels: surface && surface.spectrumEnabled && surface.presented ? Visualizer.bars:[]
    readonly property var queuePosition: TransportActions.position(Player.queueRev).split("/")
    readonly property string trackNumber: Number(queuePosition[0]) > 0 ? queuePosition[0].padStart(2,"0"):"--"
    readonly property string trackTotal: Number(queuePosition[1]) > 0 ? queuePosition[1].padStart(2,"0"):"--"
    function setSpectrumActive(active) { Visualizer.setCompact(active,0) }
    function chooseVolume(value,commit) { Player.chooseVolume(value); if(commit)Player.persistVolume() }
    function toggleShuffle(){Player.toggleShuffle()}
    function cycleRepeat(){Player.cycleRepeat()}
    function deckStop(){TransportActions.stop()}
    readonly property Component hintComponent: Component { ArtworkHintModel {} }
    readonly property bool autoLookupAvailable: true
    readonly property bool reducedMotion: HostTheme.Motion.reduced
    property string query: ""
    property string sort: "artist"
    property string grouping: "artist"
    property int spineRevision: 0
    readonly property bool hostDark: ThemeModel.dark
    readonly property color hostAccent: ThemeModel.color("accent", ThemeModel.rev)
    readonly property color hostWindow: ThemeModel.color("surface.window", ThemeModel.rev)
    readonly property bool hostAmbient: ThemeModel.ambient
    readonly property bool simulated: false
    readonly property bool offline: SettingsModel.kept("integrations.offline") === "true"
    readonly property Component ambientBackground: Component { HostAmbient.AppBackground { paletteConsumer: "nest" } }
    readonly property Component replacementComponent: Component { HostReplacement {} }
    property var pendingTrackData: null
    readonly property Component trackData: Component {
        QtObject {
            id: data
            property double albumId: 0
            property int requestedRow: -1
            property string requestedId: ""
            signal finished(bool success)
            function start(row, trackId){requestedRow=row;requestedId=trackId;deadline.start();Qt.callLater(tryPlay)}
            function tryPlay(){
                if(requestedRow<0 || !detail.selectedId || !model.ready || model.count<=requestedRow)return
                const ids=JSON.parse(model.chosenTrackIdsJson(requestedRow) || "[]")
                if(requestedId && String(ids[0])!==requestedId){requestedRow=-1;deadline.stop();finished(false);return}
                const row=requestedRow;requestedRow=-1;deadline.stop();model.play(row);finished(true)
            }
            readonly property var observer: Connections {target:data.model;function onReadyChanged(){if(data.requestedRow>=0)Qt.callLater(data.tryPlay)} function onCountChanged(){if(data.requestedRow>=0)Qt.callLater(data.tryPlay)}}
            readonly property var deadline: Timer {id:deadline;interval:15000;onTriggered:{data.requestedRow=-1;data.finished(false)}}
            readonly property var detail: AlbumDetailModel { albumId: data.albumId; contentRev: Library.contentRev; remoteRev: Library.remoteRev + Library.remoteArtRev }
            readonly property var model: TrackListModel { kind: "album"; albumId: data.detail.selectedId; albumPage: data.detail.tracksRev }
        }
    }
    readonly property real embeddedBottomInset: HostTheme.Metrics.playerSpace + HostTheme.Metrics.playerBottom
    readonly property var rows: records
    readonly property int count: records.albums
    readonly property int revision: records.rev
    readonly property int navigationRevision: records.rev
    readonly property bool loading: !records.ready
    readonly property bool playing: Player.playing
    readonly property bool paused: Player.paused
    readonly property bool preparing: QueueActivity.busy
    readonly property real position: Player.position
    readonly property real duration: Player.duration
    readonly property string elapsed: Player.elapsed
    readonly property string remaining: Player.remaining
    readonly property string title: Player.title
    readonly property string artist: Player.artist
    readonly property string error: Player.error
    readonly property double activeAlbumId: Player.albumId
    readonly property var currentAlbum: ({id: Player.albumId, title: Player.album, artist: Player.artist, art: String(Player.art), year: ""})
    readonly property var catalog: AlbumGridModel {
        id: records
        kind: "all"
        key:library.surface ? JSON.stringify({excluded_sources:library.surface.excludedSources,favorites_only:library.surface.favoritesOnly}):""
        columns: 1
        order: library.sort === "artist-year" ? "artist" : library.sort === "year-artist" ? "year" : library.sort
        group: library.grouping === "none" ? "" : library.grouping
        filter: library.query
        contentRev: Library.contentRev + Library.remoteRev + Library.remoteArtRev + Ratings.rev
    }
    readonly property var groupRows: JSON.parse(records.groupIndex || "[]")
    function groupIndex() { return groupRows }
    function groupLabelAt(index) {
        let low = 0, high = groupRows.length - 1, label = ""
        while (low <= high) { const middle = (low + high) >> 1; if (groupRows[middle][0] <= index) { label = groupRows[middle][1]; low = middle + 1 } else high = middle - 1 }
        return label
    }
    function album(index) {
        if (index < 0 || index >= count) return {id:0,title:"",artist:"",year:"",art:""}
        const rev = records.rev
        return { id: records.albumId(index, rev), title: records.title(index, rev),
            artist: records.subtitle(index, rev), year: records.year(index, rev), art: String(records.art(index, rev)) }
    }
    function indexOfAlbum(id) { return records.indexOfAlbum(id) }
    function artAt(index) {return index>=0 && index<count ? String(records.art(index,records.rev)):""}
    function groupLabel(album) { return grouping === "artist" ? album.artist : grouping === "year" ? album.year || tr("No year") : grouping === "decade" ? (album.year ? Math.floor(Number(album.year) / 10) * 10 + "s" : tr("No year")) : "" }
    function spineFor(album) { const revision = spineRevision; return readPreference("spine." + album.id, "") }
    function setSpine(album, url) { keepPreference("spine." + album.id, String(url)); spineRevision++ }
    function available(id) { return AlbumActions.available(id, Library.contentRev + Library.remoteRev) }
    function play(album) { cancelTrackRequest();AlbumActions.playMany(JSON.stringify([album.id]), false); QueueActivity.refresh() }
    function playTrack(album,row,trackId) {
        cancelTrackRequest()
        const request=trackData.createObject(library,{albumId:album.id})
        if(!request)return
        pendingTrackData=request
        request.finished.connect(success=>{
            if(pendingTrackData!==request)return
            pendingTrackData=null
            if(!success && surface)surface.controller.message="This track is unavailable for playback."
            request.destroy()
        })
        request.start(row,trackId)
    }
    function cancelTrackRequest(){if(pendingTrackData){pendingTrackData.destroy();pendingTrackData=null}}
    function stop() { cancelTrackRequest();Player.clearQueue() }
    function toggle() { Player.toggle() }
    function next() { Player.next() }
    function previous() { Player.previous() }
    function seek(value) { Player.seek(value) }
    function readPreference(key, fallback) { return SettingsModel.kept("nest." + key) || fallback }
    function keepPreference(key, value) { SettingsModel.keep("nest." + key, String(value)) }
}
