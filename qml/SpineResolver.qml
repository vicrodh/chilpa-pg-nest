import QtQuick
import "native" as Native

// One visible-view queue. No network requests, models or timers per CD.
Item {
    id: resolver
    required property var backend
    property bool automatic: false
    property var queue: []
    property var current: null
    property var hint: null
    property string phase: "idle"
    property string releaseId: ""
    property bool exactEdition: false
    property var editions: []
    property int editionIndex: 0
    property var results: []
    property var reports: ({})
    property var journal: ({})
    property var cacheOrder: []
    property var cacheSlots: ({})
    property var cacheSizes: ({})
    property string status: ""
    property bool manual: false
    readonly property bool busy: current !== null
    readonly property var currentResults: results.slice().sort((a,b) => Number(!a.url) - Number(!b.url))
    signal reportChanged(double albumId)
    signal scanRequested()
    property Component archiveComponent: Component { Native.SpineLibrary {} }
    property var archive: null
    readonly property bool scheduled: pace.running
    Connections {
        target: resolver.archive
        function onChanged() { if (resolver.archive && !resolver.archive.busy) Qt.callLater(resolver.advance) }
        function onSaved(url) {
            if (!resolver.current) return
            resolver.backend.setSpine(resolver.current, url)
            resolver.finish("found", "Spine found automatically.")
        }
    }
    Connections {
        target: resolver.hint
        ignoreUnknownSignals: true
        function onReadyChanged() { if (resolver.current && resolver.hint.albumId === resolver.current.id && resolver.hint.ready && resolver.phase === "hint") resolver.lookup() }
    }
    Timer { id: pace; interval: 1200; onTriggered: resolver.next() }
    onAutomaticChanged: {
        if (automatic) Qt.callLater(resolver.resume)
        else suspend()
    }
    Component.onCompleted: {
        try {
            const entries=JSON.parse(backend.readPreference("spine.lookup.index","[]")).slice(-2048),order=[],slots={},sizes={}
            for(const row of entries) if(Array.isArray(row) && typeof row[0]==="string" && Number.isInteger(row[1]) && row[1]>=0 && row[1]<2048 && row[2]>0 && row[2]<=16384){order.push(row[0]);slots[row[0]]=row[1];sizes[row[0]]=row[2]}
            cacheOrder=order;cacheSlots=slots;cacheSizes=sizes
        } catch(error){cacheOrder=[];cacheSlots={};cacheSizes={}}
        if (automatic) ensureResources()
    }
    function ensureResources() {
        if (!archive) archive = archiveComponent.createObject(resolver)
        if (!hint && backend.hintComponent) hint = backend.hintComponent.createObject(resolver)
    }
    function resume() { if (automatic) { ensureResources();resolver.scanRequested(); pace.restart() } }
    function cancelManual() { if (!manual) return; current=null;phase="idle";manual=false;archive.cancel();if(automatic)pace.restart();else pace.stop() }
    function suspend() { pace.stop();current=null;phase="idle";queue=[];manual=false;if(archive)archive.cancel();if(hint)hint.albumId=0 }
    function request(album) {
        if (!automatic || !album || !album.id || backend.spineFor(album)) return
        const kept = stateFor(album), now = Date.now()
        if (kept && now - kept.time < (kept.state === "failed" ? 3600000 : 1209600000)) return
        if (current && current.id === album.id || queue.some(item => item.id === album.id) || queue.length >= 256) return
        queue = queue.concat([album])
        if (!busy && !pace.running) pace.restart()
    }
    function retry(album) {
        if (!album) return
        ensureResources()
        archive.cancel(); current = null; phase = "idle"; queue = [album]; manual = true
        pace.restart()
    }
    function next() {
        if ((!automatic && !manual) || busy || !queue.length || backend.offline) return
        current = queue[0]; queue = queue.slice(1); results = []; editions = []; editionIndex = 0; releaseId = ""; exactEdition = false
        status = "Finding editions…"; phase = "hint"
        if (hint) { hint.albumId = current.id; if (hint.ready) Qt.callLater(lookup) } else lookup()
    }
    function lookup() {
        if (!current || phase !== "hint") return
        let id = ""
        try { id = hint ? JSON.parse(hint.document || "{}").release_id || "" : "" } catch (error) {}
        if (id) { exactEdition = true; releaseId = id; phase = "images"; archive.images(id) }
        else { phase = "search"; archive.search(current.artist, current.title) }
    }
    function advance() {
        if (!current || archive.busy) return
        if (phase === "search") {
            if (archive.error) return finish("failed", archive.error)
            editions = archive.releases.filter(item => item.cd).slice(0, manual ? 8 : 3)
            if (!editions.length) return finish("missing", "No CD editions found.")
            phase = "next-edition"; Qt.callLater(nextEdition)
        } else if (phase === "images") {
            const candidates = archive.candidates
            const edition = editions[editionIndex - 1]
            const candidate = candidates.find(item => item.spine) || candidates[0]
            if (candidate) {
                const result = Object.assign({}, candidate, {release:releaseId,edition:edition ? edition.detail : "Edition identified in tags",state:"review"})
                results = results.concat([result])
                const year = String(current.year || ""), unique = editions.length === 1 && edition && String(edition.date).startsWith(year) && year !== "" && edition.score >= 95
                if (candidate.spine && (exactEdition || unique)) {
                    phase = "save"; status = "Saving spine…"
                    archive.save(candidate.url, candidate.combined ? Qt.rect(.935,0,.065,1) : Qt.rect(0,0,1,1))
                    return
                }
            } else results = results.concat([{release:releaseId,edition:edition ? edition.detail : "Identified edition",state:archive.error ? "unavailable" : "missing",url:""}])
            if (exactEdition) finish(candidate ? "review" : "missing", candidate ? "A scan is available for crop review." : "This edition has no available spine.")
            else { phase = "next-edition"; Qt.callLater(nextEdition) }
        } else if (phase === "save" && archive.error) finish("failed", archive.error)
    }
    function nextEdition() {
        if (!current) return
        if (editionIndex >= editions.length) return finish(results.some(item => item.url) ? "review" : "missing", results.some(item => item.url) ? "Scans are available for review." : "No spine is available; keeping the solid color.")
        releaseId = editions[editionIndex++].id
        status = "Checking edition " + editionIndex + " of " + editions.length
        phase = "images"; archive.images(releaseId)
    }
    function finish(state, message) {
        if (!current) return
        const id = current.id
        const next = Object.assign({}, journal)
        next[String(id)] = {state:state,time:Date.now(),message:message,candidate:results.find(item => item.url) || null}
        const keys = Object.keys(next).sort((a,b) => next[b].time - next[a].time)
        for (const key of keys.slice(2048)) delete next[key]
        const bounded = {}; let bytes = 2
        for (const key of keys.slice(0,2048)) {
            const length = JSON.stringify(next[key]).length + JSON.stringify(key).length + 2
            if (bytes + length > 524288) break
            bounded[key] = next[key]; bytes += length
        }
        journal = bounded
        const updated = Object.assign({}, reports); updated[String(id)] = results
        const reportKeys = Object.keys(updated); for (const key of reportKeys.slice(0, Math.max(0, reportKeys.length - 16))) delete updated[key]
        reports = updated
        persistRecord(String(id),next[String(id)])
        status = message; phase = "idle"; current = null; manual = false
        reportChanged(id)
        if (automatic && queue.length) pace.restart()
    }
    // Fixed slot keys keep the settings map bounded even across a changing library.
    // At most 2048 records and 1 MiB of UTF-16 payload, owned by this resolver.
    function persistRecord(id,record){
        const order=cacheOrder.filter(key=>key!==id),slots=Object.assign({},cacheSlots),sizes=Object.assign({},cacheSizes)
        let value=JSON.stringify(record)
        if(value.length>16384){record=Object.assign({},record,{candidate:null});value=JSON.stringify(record)}
        let slot=slots[id]
        if(slot===undefined){
            const used=new Set(Object.values(slots))
            for(let i=0;i<2048;i++)if(!used.has(i)){slot=i;break}
            if(slot===undefined){const removed=order.shift();slot=slots[removed];delete slots[removed];delete sizes[removed]}
        }
        slots[id]=slot;sizes[id]=value.length;order.push(id)
        let bytes=Object.values(sizes).reduce((sum,size)=>sum+size,0)
        while(order.length>2048 || bytes>524288){const removed=order.shift();bytes-=sizes[removed];backend.keepPreference("spine.lookup.slot."+slots[removed],"");delete slots[removed];delete sizes[removed]}
        backend.keepPreference("spine.lookup.slot."+slot,value)
        backend.keepPreference("spine.lookup.index",JSON.stringify(order.map(key=>[key,slots[key],sizes[key]])))
        cacheOrder=order;cacheSlots=slots;cacheSizes=sizes
    }
    function stateFor(album) {
        if (!album) return null
        const key = String(album.id)
        if (journal[key]) return journal[key]
        if (cacheOrder.indexOf(key) < 0) return null
        try { return JSON.parse(backend.readPreference("spine.lookup.slot." + cacheSlots[key],"null")) } catch (error) { return null }
    }
    function resultsFor(album) {
        if (!album) return []
        if (current && current.id === album.id) return currentResults
        return reports[String(album.id)] || (stateFor(album) && stateFor(album).candidate ? [stateFor(album).candidate] : [])
    }
}
