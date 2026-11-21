import QtQuick
import QtQuick.Window

Rectangle {
    id: nest
    objectName: "chilpaNest"
    required property var backend
    property var presentation: null
    property bool fullscreenActive: false
    property string themeMode: backend.readPreference("theme","host")
    property real density: Number(backend.readPreference("density","1")) || 1
    property string shelfCount: backend.readPreference("shelves","auto")
    property bool showSeparators: backend.readPreference("separators","true") !== "false"
    property bool showIndex: backend.readPreference("index","false") === "true"
    property bool highlightPlaying: backend.readPreference("highlight","true") !== "false"
    property bool imagesEnabled: backend.readPreference("spineImages","off") === "on"
    property bool autoSpines: backend.readPreference("autoSpines","true") !== "false"
    property bool spectrumEnabled: backend.readPreference("spectrum","false") === "true"
    property bool favoritesOnly: backend.readPreference("favoritesOnly","false") === "true"
    property var excludedSources: { try { return JSON.parse(backend.readPreference("excludedSources","[]")) } catch(error) { return [] } }
    property bool useCustomPlayer: backend.readPreference("customPlayer","false") === "true"
    property string deckFinish: backend.readPreference("deckFinish","black")
    property string deckProfile: backend.readPreference("deckProfile","auto")
    property string deckDock: backend.readPreference("deckDock","bottom")
    readonly property real presentationWidth: presentation && presentation.integration.host && presentation.integration.host.window ? presentation.integration.host.window.width:width
    readonly property real presentationHeight: presentation && presentation.integration.host && presentation.integration.host.window ? presentation.integration.host.window.height:height
    readonly property string effectiveDeckProfile: deckProfile === "auto" ? (presentationWidth < 1100 || presentationHeight <= 600 ? "slim":"full"):deckProfile
    readonly property real deckExtent: deckDock !== "bottom" ? 280:effectiveDeckProfile === "minimal" ? 64:effectiveDeckProfile === "slim" ? 76:112
    readonly property bool customPlayerAvailable: presentation && presentation.integration.playerComponent !== null
    readonly property bool presented: visible && (!Window.window || (Window.window.visibility !== Window.Hidden && Window.window.visibility !== Window.Minimized))
    property alias colors: colors
    property alias controller: control
    property alias shelf: shelf
    property alias resolver: resolver
    readonly property var openCase: shelf.openCase
    readonly property bool compact: width < 660
    readonly property bool lowProfile: height < 480
    readonly property bool caseOpen: control.selected !== null
    readonly property bool deckVisible: !useCustomPlayer && backend.simulated && backend.surface !== null && (!fullscreenActive || control.hasDisc || control.busy)
    readonly property real bottomInset: backend.simulated && !fullscreenActive ? backend.embeddedBottomInset : 0
    property bool connectionsOpen: false
    property bool sortingOpen: false
    property var spineAlbum: null
    property var dragAlbum: null
    property bool dragging: false
    property bool endingDrag: false
    property var loadOrigin: null
    property var albumToReveal: null
    property double backAlbumId: 0
    property int revealFilterStage: 0
    readonly property alias dragDisc: disc
    onPresentedChanged: if (!presented) { resolver.suspend(); control.cancelReplacement(); albumToReveal=null }
    signal fullscreenRequested(bool on)
    color: colors.window; focus: true
    Keys.onEscapePressed: {
        if (connectionsOpen) connectionsOpen=false
        else if (sortingOpen) sortingOpen=false
        else if (dragging) cancelDrag()
        else if (openCase && openCase.controlsVisible) openCase.controlsVisible=false
        else if (caseOpen) control.close()
        else if (presentation && presentation.integration.host) presentation.integration.host.leave()
        else if (fullscreenActive) fullscreenRequested(false)
    }
    Keys.onPressed: event => { if (event.key === Qt.Key_F11) { fullscreenRequested(!fullscreenActive); event.accepted=true } }
    NestPalette { id: colors; mode:nest.themeMode; hostDark:backend.hostDark; hostAccent:backend.hostAccent; hostWindow:backend.hostWindow; hostAmbient:backend.hostAmbient }
    Loader { anchors.fill:parent; active:nest.presented && colors.ambient && backend.simulated; sourceComponent:backend.ambientBackground }
    NestController {
        id: control
        backend:nest.backend
        reducedMotion:backend.reducedMotion || backend.readPreference("motion","on") === "off"
        onPlaybackRequested: (album,row,trackId) => { if(row>=0)nest.backend.playTrack(album,row,trackId);else nest.backend.play(album) }
        onStopRequested:nest.backend.stop()
        onPhaseChanged: if (phase === "loading" || phase === "ejecting") Qt.callLater(nest.moveDisc)
    }
    onOpenCaseChanged: revealBack()
    Timer {interval:15000;running:nest.albumToReveal!==null;onTriggered:{control.message="This album is not on the current shelf.";nest.albumToReveal=null}}
    Connections { target:backend; function onNavigationRevisionChanged(){if(nest.albumToReveal)Qt.callLater(nest.locateAlbum)} function onLoadingChanged(){if(nest.albumToReveal)Qt.callLater(nest.locateAlbum)} }
    Loader {
        objectName:"nestReplacementLoader"
        active:control.replacement !== null
        sourceComponent:backend.replacementComponent
        onLoaded:{item.controller=control;item.backend=nest.backend;item.open()}
    }
    Connections { target:backend; function onErrorChanged(){control.reconcile()} function onActiveAlbumIdChanged(){if(!control.busy)control.reconcile()} }
    Loader { id:search; x:16; y:10; width:parent.width-32; height:40; sourceComponent:backend.searchComponent }
    Loader { id:index; x:16; y:52; width:parent.width-32; height:showIndex ? 34 : 0; active:showIndex; sourceComponent:backend.indexComponent }
    Shelf {
        id:shelf
        x:16; y:index.y+index.height+8; width:parent.width-32
        height:Math.max(100,(nest.deckVisible ? deck.y-10 : nest.height-16)-y)
        visible:nest.presented
        backend:nest.backend; controller:control; colors:nest.colors; density:nest.density
        shelfCount:nest.shelfCount; showSeparators:nest.showSeparators; highlightPlaying:nest.highlightPlaying; imagesEnabled:nest.imagesEnabled
        onOpened:album => control.open(album)
        onSpineRequested:album => { nest.spineAlbum=album; nest.connectionsOpen=true }
        onSpineNeeded:album => resolver.request(album)
    }
    SpineResolver { id:resolver; backend:nest.backend; automatic:nest.presented && nest.imagesEnabled && nest.autoSpines && backend.autoLookupAvailable && !shelf.moving && !nest.sortingOpen && !nest.connectionsOpen && !backend.offline; onScanRequested:shelf.visitVisible(album => resolver.request(album)) }
    Loader { id:deck; x:16; y:parent.height-height-16-nest.bottomInset; width:parent.width-32; height:nest.compact ? 144 : nest.lowProfile ? 82 : 108; active:nest.deckVisible; sourceComponent:backend.transportComponent }
    Rectangle {
        parent:backend.dragLayer || nest
        z:1; anchors.fill:parent; color:nest.colors.scrim; visible:nest.sortingOpen || nest.connectionsOpen
        MouseArea { anchors.fill:parent; onClicked:{nest.sortingOpen=false;nest.connectionsOpen=false;nest.forceActiveFocus()} }
    }
    Loader {
        id:settings
        objectName:"nestSettingsLoader"
        z:2
        parent:backend.dragLayer || nest
        anchors.centerIn:parent; width:Math.min(parent.width-32,980); height:Math.min(parent.height-32,item ? item.implicitHeight:900)
        active:nest.sortingOpen; sourceComponent:backend.settingsComponent
        onLoaded:item.forceActiveFocus()
    }
    Loader {
        id:spines
        objectName:"nestConnectionsLoader"
        z:2
        parent:backend.dragLayer || nest
        anchors.centerIn:parent; width:Math.min(parent.width-24,640); height:Math.min(parent.height-24,700)
        active:nest.connectionsOpen; sourceComponent:backend.spinesComponent
        onLoaded:{item.album=nest.spineAlbum;item.forceActiveFocus()}
    }
    Connections { target:spines.item; ignoreUnknownSignals:true; function onClosed(){nest.connectionsOpen=false;nest.forceActiveFocus()} }
    Connections { target:settings.item; ignoreUnknownSignals:true; function onClosed(){nest.sortingOpen=false;nest.forceActiveFocus()} }
    CDDisc {
        id:disc
        parent:backend.dragLayer || nest
        z:100; width:88; height:width; visible:nest.dragging || travel.running
        title:dragAlbum ? dragAlbum.title : control.loaded ? control.loaded.title : ""
        art:dragAlbum ? dragAlbum.art || "":control.loaded ? control.loaded.art || "":""
        artist:dragAlbum ? dragAlbum.artist:control.loaded ? control.loaded.artist:""
        Drag.active:nest.dragging; Drag.keys:["app.chilpa.disc"]; Drag.hotSpot.x:width/2; Drag.hotSpot.y:height/2
    }
    ParallelAnimation {
        id:travel
        NumberAnimation { id:travelX; target:disc; property:"x"; duration:control.reducedMotion ? 1 : 460; easing.type:Easing.InOutCubic }
        NumberAnimation { id:travelY; target:disc; property:"y"; duration:control.reducedMotion ? 1 : 460; easing.type:Easing.InOutCubic }
        onFinished:{if(control.phase === "loading")control.finishInsert();else if(control.phase === "ejecting")control.finishEject();nest.dragAlbum=null}
    }
    Text { x:24; y:parent.height-24; width:parent.width-48; visible:control.message !== "" && !nest.caseOpen; text:backend.tr(control.message); color:colors.negative; font.pixelSize:11; elide:Text.ElideRight }
    function setting(key,value) {
        switch(key) {
        case "deckFinish":deckFinish=value;break
        case "deckProfile":deckProfile=value;break
        case "deckDock":deckDock=value;break
        case "theme":themeMode=value;break
        case "shelves":shelfCount=value;break
        case "density":density=Number(value);break
        case "group":backend.grouping=value;backend.keepPreference("grouping",value);return
        case "sort":backend.sort=value;break
        case "separators":showSeparators=value === "true";break
        case "index":showIndex=value === "true";break
        case "highlight":highlightPlaying=value === "true";break
        case "images":imagesEnabled=value === "true";backend.keepPreference("spineImages",imagesEnabled ? "on":"off");return
        case "autoSpines":autoSpines=value === "true";break
        case "spectrum":spectrumEnabled=value === "true";break
        case "favoritesOnly":favoritesOnly=value === "true";break
        case "customPlayer":useCustomPlayer=customPlayerAvailable && value === "true";value=String(useCustomPlayer);break
        default:
            if(key.startsWith("source:")){const id=key.slice(7);excludedSources=value === "true" ? excludedSources.filter(item=>item!==id):Array.from(new Set(excludedSources.concat([id])));backend.keepPreference("excludedSources",JSON.stringify(excludedSources))}
            return
        }
        backend.keepPreference(key,value)
    }
    function command(action) {
        if(action === "settings"){connectionsOpen=false;sortingOpen=true}
        else if(action === "spines"){spineAlbum=control.selected || control.loaded;sortingOpen=false;connectionsOpen=true}
        else if(action === "eject")control.eject()
        else if(action === "show-loaded")showLoadedAlbum()
        else if(action === "search"){if(search.item && search.item.focusInput)search.item.focusInput()}
        else if(action === "drop" && dragAlbum && !control.hasDisc && !control.busy){loadOrigin=Qt.point(disc.x,disc.y);control.open(dragAlbum);control.insert()}
        else if(action === "reset"){
            excludedSources=[];backend.keepPreference("excludedSources","[]")
            for(const pair of [["spectrum","false"],["favoritesOnly","false"],["deckFinish","black"],["deckProfile","auto"],["deckDock","bottom"],["theme","host"],["shelves","auto"],["density","1"],["group","artist"],["sort","artist-year"],["separators","true"],["index","false"],["highlight","true"],["images","false"],["autoSpines","true"],["customPlayer","false"]])setting(pair[0],pair[1])
        }
    }
    function showLoadedAlbum() {
        const album=control.loaded || backend.currentAlbum
        if(control.busy || !album || !album.id)return false
        albumToReveal=album;revealFilterStage=0
        Qt.callLater(locateAlbum)
        return true
    }
    function locateAlbum() {
        if(!albumToReveal || backend.loading)return
        const at=backend.indexOfAlbum(albumToReveal.id)
        if(at<0 && revealFilterStage===0 && backend.query){revealFilterStage=1;backend.query="";return}
        // Only clear Nest-local filters when they hide this explicit target.
        if(at<0 && revealFilterStage<2 && (favoritesOnly || excludedSources.length)){
            revealFilterStage=2
            if(favoritesOnly)setting("favoritesOnly","false")
            if(excludedSources.length){excludedSources=[];backend.keepPreference("excludedSources","[]")}
            return
        }
        if(at<0){control.message="This album is not on the current shelf.";albumToReveal=null;return}
        const album=albumToReveal;albumToReveal=null
        backAlbumId=album.id
        shelf.jump(at)
        control.open(album)
        Qt.callLater(revealBack)
    }
    function revealBack() {
        if(openCase && backAlbumId && openCase.album.id===backAlbumId){openCase.flipTo(true);backAlbumId=0}
    }
    function beginDrag(album,x,y) {
        if(control.hasDisc || control.busy || !album || !backend.available(album.id))return false
        dragAlbum=album;dragging=true;moveDrag(x,y);return true
    }
    function moveDrag(x,y) {
        if(!dragging)return
        const point=disc.parent.mapFromItem(nest.Window.window.contentItem,x,y)
        disc.x=point.x-disc.width/2;disc.y=point.y-disc.height/2
    }
    function endDrag(){if(!dragging || endingDrag)return;endingDrag=true;const accepted=disc.Drag.drop();dragging=false;endingDrag=false;if(accepted === Qt.IgnoreAction)cancelDrag();else if(!control.busy)dragAlbum=null}
    function cancelDrag(){dragging=false;const point=casePoint();travelX.to=point.x;travelY.to=point.y;travel.start()}
    function casePoint(){return openCase ? openCase.mapToItem(disc.parent,openCase.width*.5-disc.width/2,openCase.height*.5-disc.height/2) : nest.mapToItem(disc.parent,nest.width/2,shelf.y+shelf.height/2)}
    function moveDisc(){
        if(!control.busy)return
        const target=backend.nativeDisplay ? backend.nativeDisplay.trayTarget : deck.item ? deck.item.trayItem : null
        const tray=target ? target.mapToItem(disc.parent,(target.width-disc.width)/2,(target.height-disc.height)/2) : nest.mapToItem(disc.parent,nest.width/2,nest.height-disc.height)
        const origin=loadOrigin || casePoint(), inserting=control.phase === "loading"
        disc.x=inserting ? origin.x:tray.x;disc.y=inserting ? origin.y:tray.y
        travelX.to=inserting ? tray.x:origin.x;travelY.to=inserting ? tray.y:origin.y
        loadOrigin=null;travel.start()
    }
    function indexKey(text){const c=String(text || "").trim().charAt(0).toUpperCase();if(/[0-9]/.test(c))return "#";const accents={"Á":"A","À":"A","Ä":"A","Â":"A","É":"E","È":"E","Ë":"E","Í":"I","Ï":"I","Ó":"O","Ö":"O","Ú":"U","Ü":"U","Ñ":"N"};return accents[c] || (/[A-Z]/.test(c) ? c:"@")}
    function indexTarget(key){const row=backend.groupIndex().find(item => indexKey(item[1]) === key);return row ? row[0]:-1}
    function jumpIndex(key){const at=indexTarget(key);if(at>=0){control.close();shelf.jump(at)}}
    Component.onCompleted:{backend.surface=nest;backend.sort=backend.readPreference("sort","artist-year");backend.grouping=backend.readPreference("grouping","artist")}
    Component.onDestruction:if(backend.surface === nest)backend.surface=null
}
