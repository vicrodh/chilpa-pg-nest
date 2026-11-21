import QtQuick
import QtQuick.Controls.Basic
import "native" as Native

Item {
    id: shelf
    required property var backend
    required property var controller
    required property var colors
    property real density: 1
    property bool imagesEnabled: false
    property string shelfCount: "auto"
    property bool showSeparators: true
    property bool highlightPlaying: true
    readonly property int fittingRows: Math.max(1, Math.min(4, Math.floor((height - 28) / (240 * density))))
    readonly property int totalRows: shelfCount === "auto" ? fittingRows : Math.max(1, Math.min(4, Number(shelfCount)))
    property double selectedId: 0
    readonly property int visibleRows: Math.min(totalRows, fittingRows)
    readonly property real rowHeight: (height - 28) / visibleRows
    readonly property real spineWidth: Math.max(18, Math.min(34, rowHeight * 0.067)) * density
    readonly property int perRow: Math.max(1, Math.ceil(backend.count / totalRows))
    readonly property int columns: Math.max(1, Math.floor((width - 36) / spineWidth))
    readonly property bool panoramic: true
    property var view: null
    property var openCase: null
    readonly property var verticalView: rows
    property var offsets: ({})
    property bool verticalDragging:false
    readonly property bool moving: verticalDragging || verticalSnap.running || rows.moving || (view ? view.moving : false)
    readonly property int preloadAlbums:8
    property string preloadSignature:""
    readonly property alias palettePreloader:nearbyColors
    readonly property bool preloadScheduled:colorWarmup.running
    Native.SpinePalettePreloader {id:nearbyColors;objectName:"nestPalettePreloader";active:shelf.visible}
    // One coalesced, lifetime-owned job for all visible rails.
    Timer {id:colorWarmup;interval:40;onTriggered:shelf.warmNearbyColors()}
    function scheduleWarmup(){if(visible && colorWarmup && !colorWarmup.running)colorWarmup.start()}
    function warmNearbyColors(){
        if(!visible)return
        const spans=[]
        for(const row of rows.contentItem.children){
            if(!row.view || !row.inViewport)continue
            let first=Infinity,last=-1
            for(const slot of row.view.contentItem.children)if(slot.spine && slot.inViewport){first=Math.min(first,slot.index);last=Math.max(last,slot.index)}
            if(last>=0)spans.push({start:row.start,first:first,last:last,count:row.view.count})
        }
        const signature=backend.revision+":"+backend.count+":"+JSON.stringify(spans)
        if(signature===preloadSignature)return
        preloadSignature=signature
        const sources=[]
        for(const span of spans){
            for(let offset=1;offset<=preloadAlbums;offset++){
                for(const index of [span.last+offset,span.first-offset]){
                    if(index<0 || index>=span.count)continue
                    const url=backend.artAt(span.start+index)
                    if(url)sources.push(url)
                }
            }
        }
        nearbyColors.sources=sources
    }
    onVisibleChanged:{if(visible)scheduleWarmup();else{if(colorWarmup)colorWarmup.stop();if(nearbyColors)nearbyColors.sources=[];preloadSignature=""}}
    Component.onCompleted:scheduleWarmup()
    Connections {
        target:shelf.backend
        function onRevisionChanged(){shelf.preloadSignature="";shelf.scheduleWarmup()}
        function onCountChanged(){shelf.preloadSignature="";shelf.scheduleWarmup()}
        function onSortChanged(){shelf.preloadSignature="";shelf.scheduleWarmup()}
        function onGroupingChanged(){shelf.preloadSignature="";shelf.scheduleWarmup()}
    }
    NumberAnimation {
        id:verticalSnap;target:rows;property:"contentY";duration:shelf.controller.reducedMotion ? 1:260;easing.type:Easing.OutCubic
        property int destination:0
        onFinished:{rows.currentIndex=destination;if(rows.currentItem)shelf.view=rows.currentItem.view}
    }
    function settleRows() { if (rows && rows.currentIndex >= 0) rows.positionViewAtIndex(rows.currentIndex, ListView.Beginning) }
    onRowHeightChanged: {Qt.callLater(shelf.settleRows);scheduleWarmup()}
    signal spineNeeded(var album)
    function visitVisible(callback) {
        for (const row of rows.contentItem.children) {
            if (!row.view || !row.inViewport) continue
            for (const slot of row.view.contentItem.children) if (slot.spine && slot.inViewport) callback(slot.album)
        }
    }
    function jump(index) {
        const row = Math.max(0, Math.min(totalRows - 1, Math.floor(index / perRow)))
        rows.currentIndex = row
        rows.positionViewAtIndex(row, ListView.Contain)
        Qt.callLater(shelf.finishJump,row,index)
    }
    function finishJump(row,index) { if (!rows) return; rows.forceLayout(); const item = rows.itemAtIndex(row); if (item) { item.view.positionViewAtIndex(index-row*perRow,ListView.Beginning); shelf.view=item.view } }
    signal opened(var album)
    signal spineRequested(var album)
    Rectangle {
        anchors.fill: parent; radius: 5; color: shelf.colors.cabinet; border.color: shelf.colors.cabinetEdge
        Image { anchors.fill: parent; source: shelf.colors.wood ? "woodgrain.svg" : ""; fillMode: Image.Tile; opacity: 0.4 }
    }
    Rectangle { x: 9; y: 9; width: parent.width - 18; height: parent.height - 18; color: shelf.colors.recess }
    Item {
        x: 18; y: 14; width: parent.width - 36; height: parent.height - 28; clip: true
        ListView {
            id: rows
            objectName: "nestVerticalShelves"
            anchors.fill: parent
            model: shelf.totalRows
            orientation: ListView.Vertical
            snapMode: ListView.SnapOneItem
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: shelf.totalRows > shelf.visibleRows && !(shelf.openCase && shelf.openCase.interacting)
            cacheBuffer: 0; reuseItems: true; clip: true
            onMovementStarted: if (!shelf.controller.busy) shelf.controller.close()
            onMovementEnded: { currentIndex = Math.round(contentY / shelf.rowHeight); if (currentItem) shelf.view = currentItem.view }
            onCurrentItemChanged: if (currentItem) shelf.view = currentItem.view
            onContentYChanged:shelf.scheduleWarmup()
            delegate: Item {
                id: rail
                required property int index
                readonly property var view: strip
                readonly property int start: index * shelf.perRow
                property bool pooled:false
                readonly property bool inViewport: !pooled && y + height > rows.contentY && y < rows.contentY + rows.height
                onInViewportChanged:if(typeof shelf!=="undefined" && shelf)shelf.scheduleWarmup()
                ListView.onPooled: pooled=true
                ListView.onReused:{pooled=false;Qt.callLater(rail.restoreOffset)}
                width: rows.width; height: shelf.rowHeight
                Component.onCompleted: if (index === rows.currentIndex) shelf.view = strip
                function restoreOffset() { if (typeof shelf !== "undefined" && shelf && typeof strip !== "undefined" && strip) strip.contentX = Math.max(0,Math.min(shelf.offsets[index] || 0,strip.contentWidth-strip.width)) }
                onStartChanged: Qt.callLater(rail.restoreOffset)
                ListView {
                    id: strip
                    objectName: "nestShelf"
                    anchors.fill: parent; anchors.bottomMargin: 17
                    orientation: ListView.Horizontal
                    flickableDirection: Flickable.HorizontalFlick
                    onMovementEnded: { const next = Object.assign({}, shelf.offsets); next[rail.index] = contentX; shelf.offsets = next }
                    onContentXChanged:if(typeof shelf!=="undefined" && shelf)shelf.scheduleWarmup()
                    model: rail.pooled ? 0:Math.max(0, Math.min(shelf.perRow, shelf.backend.count - rail.start))
                    cacheBuffer: shelf.spineWidth * 2; reuseItems: !rail.pooled; clip: true
                    boundsBehavior: Flickable.StopAtBounds; flickDeceleration: 2200; maximumFlickVelocity: 2000
                    pixelAligned: false; keyNavigationEnabled: true; spacing: 1
                    interactive: !(currentItem && currentItem.spine.interacting)
                    acceptedButtons: Qt.LeftButton
                    onMovementStarted: { shelf.view = strip; if (!shelf.controller.busy) shelf.controller.close() }
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
                    delegate: Item {
                        id: slot
                        required property int index
                        readonly property int albumIndex: rail.start + index
                        readonly property int currentRevision: shelf.backend.revision
                        readonly property var album: { const revision = currentRevision; return shelf.backend.album(albumIndex) }
                        readonly property string label: shelf.backend.groupLabelAt(albumIndex)
                        readonly property bool groupStart: shelf.showSeparators && label !== "" && (index === 0 || label !== shelf.backend.groupLabelAt(albumIndex - 1))
                        property bool pooled: false
                        readonly property bool inViewport: shelf.visible && rail.inViewport && !pooled && x + width > strip.contentX && x < strip.contentX + strip.width
                        onInViewportChanged:if(typeof shelf!=="undefined" && shelf)shelf.scheduleWarmup()
                        readonly property var spine: jewel
                        width: jewel.width + (groupStart ? 19 : 0); height: strip.height
                        function keepVisible() { if (jewel && jewel.selected && strip) strip.positionViewAtIndex(slot.index,ListView.Contain) }
                        ListView.onPooled: pooled = true
                        ListView.onReused: pooled = false
                        Text {
                            x: 0; y: parent.height - 3; width: parent.height - 6; height: 16; rotation: -90; transformOrigin: Item.TopLeft
                            visible: slot.groupStart; text: slot.label; color: shelf.colors.text; font.pixelSize: 9; font.weight: Font.DemiBold; elide: Text.ElideRight
                        }
                        Spine {
                            id: jewel
                            x: slot.groupStart ? 19 : 0; height: strip.height - 5
                            album: slot.album; colors: shelf.colors; controller: shelf.controller; backend: shelf.backend
                            spineWidth: shelf.spineWidth
                            maxFaceWidth: strip.width - 20
                            spineSource: shelf.backend.spineFor(album)
                            imagesEnabled: shelf.imagesEnabled
                            artActive: slot.inViewport
                            viewMoving: shelf.moving
                            selected: shelf.controller.selected !== null && shelf.controller.selected.id === album.id && !slot.pooled
                            loaded: shelf.highlightPlaying && shelf.controller.loaded !== null && shelf.controller.loaded.id === album.id
                            motion: !shelf.controller.reducedMotion && slot.inViewport
                            onPicked: { shelf.view = strip; shelf.selectedId = album.id; strip.currentIndex = slot.index }
                            onWidthChanged: if (selected) Qt.callLater(slot.keepVisible)
                            onOpened: { strip.cancelFlick(); shelf.view = strip; shelf.selectedId = album.id; strip.currentIndex = slot.index; shelf.opened(album); Qt.callLater(slot.keepVisible) }
                            onSpineNeeded: shelf.spineNeeded(album)
                            onSpineRequested: shelf.spineRequested(album)
                            onCoverReady: item => shelf.openCase = item
                        }
                    }
                }
                DragHandler {
                    id: verticalDrag
                    target: null; xAxis.enabled:false; yAxis.enabled:true
                    enabled: rows.interactive
                    property real startOffset: 0
                    onActiveChanged: {
                        shelf.verticalDragging=active
                        if(active){verticalSnap.stop();startOffset=rows.contentY;rows.cancelFlick();if(!shelf.controller.busy)shelf.controller.close()}
                        else if(rows.interactive){const next=Math.max(0,Math.min(shelf.totalRows-shelf.visibleRows,Math.round(rows.contentY/shelf.rowHeight)));verticalSnap.destination=next;verticalSnap.to=next*shelf.rowHeight;verticalSnap.start()}
                    }
                    onActiveTranslationChanged: if(active) rows.contentY=Math.max(0,Math.min(rows.contentHeight-rows.height,startOffset-activeTranslation.y))
                }
                CabinetRail { y: parent.height - 13; width: parent.width; height: 13; colors: shelf.colors }
            }
        }
    }
    Column {
        anchors.centerIn: parent; width: Math.min(parent.width - 40, 350); spacing: 10; visible: shelf.backend.count === 0
        Text { width: parent.width; text: shelf.backend.tr(shelf.backend.loading ? "Preparing your shelves…":"Room for your music."); color: shelf.colors.text; font.pixelSize: 20; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter }
        Text { width: parent.width; text: shelf.backend.tr(shelf.backend.query ? "No matching albums.":"Add music to your Chilpa library to see it here."); color: shelf.colors.muted; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter }
    }
}
