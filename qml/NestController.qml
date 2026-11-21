import QtQuick

QtObject {
    id: control
    required property var backend
    property var selected: null
    property var loaded: null
    property string phase: "shelf"
    property bool reducedMotion: false
    readonly property bool busy: phase === "loading" || phase === "ejecting"
    readonly property bool hasDisc: loaded !== null
    property string message: ""
    property var replacement: null
    property int requestedRow: -1
    property string requestedTrackId: ""
    signal playbackRequested(var album, int row, string trackId)
    signal stopRequested()
    Component.onCompleted: {
        if (backend.activeAlbumId && backend.currentAlbum) {
            loaded = backend.currentAlbum
            phase = "loaded"
        }
    }

    function open(album) {
        if (busy || !album || !album.id) return false
        selected = album
        phase = "case"
        message = ""
        return true
    }
    function close() {
        if (busy) return
        selected = null
        phase = hasDisc ? "loaded" : "shelf"
    }
    function insert() {
        if (busy || !selected || hasDisc || backend.loading || backend.preparing) return false
        if (!backend.available(selected.id)) { message = "This album is unavailable for playback."; return false }
        message = ""
        loaded = selected
        phase = "loading"
        return true
    }
    function finishInsert() {
        if (phase !== "loading" || !loaded) return
        phase = "loaded"
        selected = null
        const row = requestedRow, trackId = requestedTrackId
        requestedRow = -1; requestedTrackId = ""
        playbackRequested(loaded, row, trackId)
    }
    function requestPlay(album, row, trackId) {
        if (busy || replacement || backend.loading || backend.preparing || !album || !backend.available(album.id)) return false
        const request = {album:album,row:row === undefined ? -1:row,trackId:String(trackId || ""),currentId:loaded ? loaded.id:0}
        if (hasDisc && loaded.id !== album.id) { replacement=request; return true }
        if (hasDisc) { playbackRequested(album,request.row,request.trackId); return true }
        return loadRequest(request)
    }
    function loadRequest(request) {
        if (!open(request.album)) return false
        requestedRow=request.row; requestedTrackId=request.trackId
        return insert()
    }
    function cancelReplacement() { replacement=null }
    function confirmReplacement() {
        const request=replacement
        replacement=null
        if (!request || busy || backend.loading || backend.preparing || !loaded || loaded.id !== request.currentId || !backend.available(request.album.id)) return false
        stopRequested()
        loaded=null
        return loadRequest(request)
    }
    function eject() {
        if (busy || !hasDisc || backend.preparing) return false
        cancelReplacement()
        stopRequested()
        selected = loaded
        phase = "ejecting"
        return true
    }
    function finishEject() {
        if (phase !== "ejecting") return
        loaded = null
        phase = "case"
    }
    function reconcile() {
        // A command can fail after dispatch. Preserve the physical disc and show the error.
        if (backend.error) message = backend.error
        if (loaded && backend.activeAlbumId && backend.activeAlbumId !== loaded.id) {
            loaded = null
            cancelReplacement()
            if (!selected) phase = "shelf"
        }
    }
}
