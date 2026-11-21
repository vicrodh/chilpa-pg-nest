import QtQuick
import QtQuick.Window
import QtTest
import "../qml"
import "../qml/native" as Native

TestCase {
    id: test
    name: "ChilpaNest"
    when: windowShown
    visible: true
    width: 1180; height: 760
    Component {
        id: fixture
        NestView { width: test.width; height: test.height; backend: DemoBackend {} }
    }
    Component { id: restoredController; NestController {} }
    property var view: null
    function init() { view = createTemporaryObject(fixture, test); verify(view !== null); waitForRendering(view); tryVerify(() => view.shelf.view && view.shelf.view.itemAtIndex(0)) }
    function cleanup() { if (view) view.destroy(); view = null }
    function named(item, name) { return findChild(item, name) }
    function openFirst() {
        const spine = view.shelf.view.itemAtIndex(0).spine
        verify(spine !== null)
        mouseDoubleClickSequence(spine, spine.spineWidth / 2, spine.height / 2)
        tryCompare(view.controller, "phase", "case")
        tryVerify(() => view.openCase !== null)
        tryCompare(spine, "reveal", 1, 1200)
        view.shelf.view.forceLayout()
        waitForRendering(view)
    }
    function revealControls() {
        const box = view.openCase
        if (!box.controlsVisible) mouseClick(box,box.width*.4,box.back ? 60:box.height*.45)
        tryVerify(() => box.controlsVisible)
        waitForRendering(box)
    }
    function insertFirst() {
        openFirst()
        revealControls()
        const insert = named(view.openCase, "nestInsert")
        verify(insert !== null)
        mouseClick(insert)
        tryCompare(view.controller, "phase", "loaded", 1600)
        compare(view.backend.playCalls, 1)
    }
    function test_real_double_click_load_transport_and_eject() {
        insertFirst()
        const discId = view.controller.loaded.id
        verify(view.backend.playing)
        const pause = named(view, "nestToggle")
        mouseClick(pause)
        verify(view.backend.paused)
        mouseClick(pause)
        verify(!view.backend.paused)
        mouseClick(named(view, "nestEject"))
        compare(view.backend.stopCalls, 1)
        tryCompare(view.controller, "phase", "case", 1600)
        verify(view.controller.loaded === null)
        compare(view.controller.selected.id, discId)
        compare(view.backend.activeAlbumId, 0)
        revealControls()
        mouseClick(named(view.openCase, "nestCloseCase"))
        tryCompare(view.controller, "phase", "shelf")
        tryCompare(view, "openCase", null)
    }
    function test_touch_double_tap_opens_a_case() {
        const spine = view.shelf.view.itemAtIndex(0).spine
        const touch = touchEvent(spine)
        touch.press(0, spine, spine.spineWidth / 2, spine.height / 2).commit()
        touch.release(0, spine, spine.spineWidth / 2, spine.height / 2).commit()
        wait(60)
        touch.press(0, spine, spine.spineWidth / 2, spine.height / 2).commit()
        touch.release(0, spine, spine.spineWidth / 2, spine.height / 2).commit()
        tryCompare(view.controller, "phase", "case")
    }
    function test_reopening_a_stopped_album_keeps_its_disc_loaded() {
        const album=view.backend.album(0)
        view.backend.play(album)
        view.backend.deckStop()
        verify(!view.backend.playing)
        const restored=createTemporaryObject(restoredController,test,{backend:view.backend})
        verify(restored !== null)
        compare(restored.phase,"loaded")
        compare(restored.loaded.id,album.id)
        verify(restored.hasDisc)
        verify(!view.backend.playing)
    }
    function test_source_and_favorite_filters_are_independent_and_persist(){
        view.setting("favoritesOnly","true")
        tryCompare(view.backend,"count",80)
        view.setting("source:plugin:fixture","false")
        tryCompare(view.backend,"count",40)
        for(let i=0;i<view.backend.count;i++){verify(view.backend.album(i).favorite);compare(view.backend.album(i).source,"local:default")}
        view.setting("favoritesOnly","false")
        tryCompare(view.backend,"count",120)
        compare(view.backend.readPreference("excludedSources",""),'["plugin:fixture"]')
        view.command("reset");tryCompare(view.backend,"count",240)
    }
    function test_language_changes_without_replacing_the_surface(){
        const same=view
        view.backend.language="ja";compare(view.backend.tr("Shelves"),"棚")
        view.backend.language="en";compare(view.backend.tr("Shelves"),"Shelves")
        compare(view,same)
    }
    function test_filter_and_resize_preserve_the_loaded_album() {
        insertFirst()
        const discId = view.controller.loaded.id
        view.backend.query = "no match"
        tryCompare(view.backend, "count", 0)
        compare(view.controller.loaded.id, discId)
        view.width = 390; view.height = 680
        waitForRendering(view)
        verify(view.shelf.columns >= 1)
        compare(view.controller.loaded.id, discId)
        view.backend.query = ""
        tryCompare(view.backend, "count", 240)
        compare(view.controller.loaded.id, discId)
    }
    function test_touch_drag_scrolls_without_opening_a_case() {
        const grid = view.shelf.view
        const touch = touchEvent(grid)
        touch.press(0, grid, grid.width - 40, grid.height / 2).commit()
        for (let step = 1; step <= 8; step++) {
            touch.move(0, grid, grid.width - 40 - step * 24, grid.height / 2).commit()
            wait(16)
        }
        touch.release(0, grid, grid.width - 232, grid.height / 2).commit()
        tryVerify(() => grid.contentX > 40)
        compare(view.controller.phase, "shelf")
    }
    function test_rows_follow_the_screen_height_and_targets_remain_touch_sized() {
        const rows = view.shelf.visibleRows
        view.height = 1080
        waitForRendering(view)
        verify(view.shelf.visibleRows > rows)
        verify(view.shelf.spineWidth >= 18)
        view.width = 390; view.height = 640
        waitForRendering(view)
        verify(view.shelf.spineWidth >= 18)
        verify(named(view, "nestEject").height >= 44)
    }
    function test_embedded_controls_reserve_the_host_player_space() {
        const eject = named(view, "nestEject")
        const deck = eject.parent.parent
        const previousY = deck.mapToItem(view,0,0).y
        view.backend.embeddedBottomInset = 105
        compare(deck.mapToItem(view,0,0).y, previousY - 105)
        verify(deck.mapToItem(view,0,0).y + deck.height < view.height - 105)
        view.fullscreenActive = true
        verify(!view.deckVisible)
        tryVerify(() => named(view,"nestEject") === null)
    }
    function test_large_catalog_is_virtualized_and_remains_scrollable() {
        view.height = 440
        view.backend.size = 10000
        tryCompare(view.backend, "count", 10000)
        waitForRendering(view)
        const grid = view.shelf.view
        verify(grid.itemAtIndex(9999) === null)
        verify(grid.contentItem.children.length < 120)
        grid.positionViewAtIndex(9999, ListView.End)
        waitForRendering(view)
        tryVerify(() => grid.itemAtIndex(9999) !== null)
        verify(grid.itemAtIndex(0) === null)
        verify(grid.contentItem.children.length < 120)
    }
    function test_unavailable_album_and_repeated_commands_do_not_start_audio() {
        openFirst()
        view.backend.permitPlayback = false
        verify(!view.controller.insert())
        verify(view.controller.message !== "")
        compare(view.backend.playCalls, 0)
        view.backend.permitPlayback = true
        verify(view.controller.insert())
        compare(view.controller.message, "")
        verify(!view.controller.insert())
        verify(!view.controller.eject())
        view.controller.close()
        compare(view.controller.phase, "loading")
        tryCompare(view.controller, "phase", "loaded", 1600)
        compare(view.backend.playCalls, 1)
    }
    function test_playback_error_is_visible_and_eject_still_works() {
        insertFirst()
        view.backend.error = "Playback failed"
        tryCompare(view.controller, "message", "Playback failed")
        verify(view.controller.eject())
        tryCompare(view.controller, "phase", "case", 1600)
    }
    function test_reduced_motion_finishes_and_closed_cover_is_released() {
        view.controller.reducedMotion = true
        insertFirst()
        tryCompare(view, "openCase", null)
        compare(view.openCase, null)
        verify(view.controller.eject())
        tryCompare(view.controller, "phase", "case")
        view.controller.close()
        tryCompare(view, "openCase", null)
    }
    function test_keyboard_activation() {
        const spine = view.shelf.view.itemAtIndex(0).spine
        spine.forceActiveFocus()
        keyClick(Qt.Key_Return)
        tryCompare(view.controller, "phase", "case")
    }
    function test_back_button_turns_a_volumetric_case_and_tracks_scroll() {
        openFirst()
        const box = view.openCase
        revealControls()
        verify(box.depth > 0)
        mouseClick(named(box, "nestFlipCase"))
        tryCompare(box, "turn", 180, 1200)
        verify(box.back)
        tryCompare(box.tracks, "count", 24)
        verify(box.tracks.contentHeight > box.tracks.height)
        box.controlsVisible = false
        const list = box.tracks
        const touch = touchEvent(list)
        touch.press(0, list, list.width / 2, list.height - 5).commit()
        for (let i = 1; i <= 6; i++) { touch.move(0, list, list.width / 2, list.height - 5 - i * 17).commit(); wait(16) }
        touch.release(0, list).commit()
        tryVerify(() => list.contentY > 15)
        verify(box.back, "vertical track scrolling does not turn the box")
        tryVerify(() => !list.moving,3000)
        // Track taps play; the printed header remains a control-reveal target.
        mouseClick(box,box.width*.4,60)
        tryVerify(()=>box.controlsVisible)
        mouseClick(named(box, "nestFlipCase"))
        tryCompare(box, "turn", 0, 1200)
        verify(!box.back)
        tryCompare(box.tracks, "count", 0)
    }
    function test_horizontal_box_gesture_turns_without_scrolling_the_shelf() {
        openFirst()
        const box = view.openCase, before = view.shelf.view.contentX
        const touch = touchEvent(box)
        touch.press(0, box, box.width - 15, box.height * .5).commit()
        for (let i = 1; i <= 8; i++) { touch.move(0, box, box.width - 15 - i * box.width * .065, box.height * .5).commit(); wait(16) }
        touch.release(0, box).commit()
        tryCompare(box, "turn", 180, 1400)
        verify(box.back)
        compare(view.shelf.view.contentX, before)
    }
    function test_a_short_deliberate_swipe_turns_the_box() {
        openFirst()
        const box=view.openCase,touch=touchEvent(box),x=box.width*.75,y=box.height*.5
        touch.press(0,box,x,y).commit()
        for(let i=1;i<=8;i++){touch.move(0,box,x-i*box.width*.025,y).commit();wait(16)}
        touch.release(0,box).commit()
        tryCompare(box,"turn",180,1000)
        verify(box.back)
    }
    function test_open_box_and_close_button_fit_a_narrow_touch_display() {
        view.width = 390; view.height = 640
        waitForRendering(view)
        openFirst()
        const strip = view.shelf.view, box = view.openCase
        revealControls()
        verify(box.width + 19 <= strip.width)
        const close = named(box, "nestCloseCase")
        const point = close.mapToItem(strip, close.width, close.height)
        verify(point.x <= strip.width && point.x >= close.width)
        mouseClick(close)
        tryCompare(view, "openCase", null)
    }
    function test_external_playback_releases_the_previous_disc() {
        insertFirst()
        view.backend.activeAlbumId = 9999
        tryCompare(view.controller, "loaded", null)
    }
    function test_eject_waits_for_an_outstanding_queue_insertion() {
        insertFirst()
        view.backend.preparing = true
        verify(!view.controller.eject())
        verify(!named(view, "nestEject").enabled)
        compare(view.backend.stopCalls, 0)
        view.backend.preparing = false
        verify(view.controller.eject())
        tryCompare(view.controller, "phase", "case", 1600)
        compare(view.backend.stopCalls, 1)
    }
    function test_three_finishes_and_live_host_theme_preserve_the_disc() {
        insertFirst()
        const loaded = view.controller.loaded.id
        for (const finish of ["dark", "light", "wood", "host"]) {
            view.setting("theme",finish)
            compare(view.themeMode, finish)
            compare(view.backend.readPreference("theme", ""), finish)
            compare(view.controller.loaded.id, loaded)
        }
        view.backend.hostDark = true
        compare(view.colors.finish, "dark")
        view.backend.hostDark = false
        compare(view.colors.finish, "light")
        view.backend.hostAccent = "#995522"
        verify(Qt.colorEqual(view.colors.accent, view.backend.hostAccent))
    }
    function test_spine_sources_panel_targets_the_selected_album() {
        openFirst()
        const selected = view.controller.selected.id
        revealControls()
        mouseClick(named(view.openCase, "nestEditSpine"))
        tryCompare(view, "connectionsOpen", true)
        compare(view.spineAlbum.id, selected)
        view.connectionsOpen = false
        tryCompare(view, "connectionsOpen", false)
        compare(view.controller.selected.id, selected)
    }
    function test_spine_artwork_is_bounded_and_released_while_hidden() {
        view.setting("images","true")
        const spine = view.shelf.view.itemAtIndex(0).spine
        tryVerify(() => String(spine.artwork.source) !== "")
        compare(spine.artwork.sourceSize.width, 48)
        compare(spine.artwork.sourceSize.height, 768)
        view.visible = false
        tryVerify(() => String(spine.artwork.source) === "")
        view.visible = true
        tryVerify(() => String(spine.artwork.source) !== "")
    }
    function test_case_unfolds_in_its_row_and_moves_the_next_spine() {
        const first = view.shelf.view.itemAtIndex(0)
        const second = view.shelf.view.itemAtIndex(1)
        const before = second.x
        openFirst()
        tryCompare(first.spine, "reveal", 1, 1200)
        verify(second.x > before + 100)
        verify(view.openCase.parent !== view)
        const settled = second.x
        wait(120)
        compare(second.x, settled)
        view.controller.close()
        tryCompare(first.spine, "reveal", 0)
        tryCompare(view, "openCase", null)
    }
    function test_solid_spines_use_cover_color_and_wcag_contrast() {
        const spine = view.shelf.view.itemAtIndex(0).spine
        tryVerify(() => !Qt.colorEqual(spine.spinePalette.background, "#35383b"))
        verify(spine.spinePalette.contrast >= 4.5)
        view.imagesEnabled = false
        tryCompare(spine.artwork, "source", "")
        verify(spine.spinePalette.contrast >= 4.5)
        verify(!spine.scanned)
    }
    function test_group_and_secondary_sort_are_chained_and_persisted() {
        view.setting("group","artist")
        view.setting("sort","artist-year")
        compare(view.backend.readPreference("grouping", ""), "artist")
        compare(view.backend.readPreference("sort", ""), "artist-year")
        let previous = view.backend.album(0)
        for (let i = 1; i < view.backend.count; i++) {
            const album = view.backend.album(i)
            verify(previous.artist.localeCompare(album.artist) <= 0)
            if (previous.artist === album.artist) verify(Number(previous.year) <= Number(album.year))
            previous = album
        }
    }
    function test_host_ambient_changes_only_the_background() {
        const cabinet = view.colors.cabinet
        const spine = view.shelf.view.itemAtIndex(0).spine
        const paper = spine.spinePalette.background
        view.backend.hostAmbient = true
        verify(view.colors.ambient)
        verify(Qt.colorEqual(view.colors.window, "transparent"))
        compare(view.colors.cabinet, cabinet)
        compare(spine.spinePalette.background, paper)
        view.themeMode = "wood"
        verify(!view.colors.ambient)
        verify(!Qt.colorEqual(view.colors.window, "transparent"))
    }
    function test_overlay_is_hidden_until_a_single_tap() {
        openFirst()
        verify(!view.openCase.controlsVisible)
        verify(named(view.openCase,"nestInsert") === null)
        revealControls()
        verify(named(view.openCase,"nestInsert") !== null)
        view.openCase.controlsVisible = false
        tryVerify(() => named(view.openCase,"nestInsert") === null)
    }
    function test_fixed_shelves_scroll_vertically_and_snap_to_complete_rows() {
        view.width = 1180; view.height = 480
        view.setting("shelves","4")
        waitForRendering(view)
        compare(view.shelf.totalRows,4)
        compare(view.shelf.visibleRows,1)
        const rails = view.shelf.verticalView, touch = touchEvent(rails)
        touch.press(0,rails,rails.width*.6,rails.height-20).commit()
        for(let i=1;i<=8;i++){touch.move(0,rails,rails.width*.6,rails.height-20-i*22).commit();wait(16)}
        touch.release(0,rails).commit()
        tryVerify(() => rails.contentY > 20)
        tryVerify(() => !view.shelf.moving,3000)
        verify(Math.abs(rails.contentY / view.shelf.rowHeight - Math.round(rails.contentY / view.shelf.rowHeight)) < .01)
        view.setting("shelves","auto")
        waitForRendering(view)
        compare(view.shelf.totalRows,view.shelf.fittingRows)
    }
    function test_index_and_separator_options_preserve_album_identity() {
        insertFirst()
        const id = view.controller.loaded.id
        view.setting("separators","false")
        compare(view.shelf.showSeparators,false)
        view.setting("index","true")
        verify(view.indexTarget("M") >= 0)
        view.jumpIndex("M")
        waitForRendering(view)
        compare(view.controller.loaded.id,id)
        compare(view.backend.readPreference("index",""),"true")
        compare(view.backend.readPreference("separators",""),"false")
    }
    function test_disc_drop_uses_one_load_and_rejects_an_occupied_tray() {
        openFirst()
        const album = view.controller.selected, target = named(view,"nestEject").parent.parent
        const point = target.mapToItem(view.Window.window.contentItem,target.width*.5,target.height*.5)
        verify(view.beginDrag(album,point.x,point.y))
        waitForRendering(view)
        view.endDrag()
        tryCompare(view.controller,"phase","loaded",2000)
        compare(view.backend.playCalls,1)
        verify(!view.beginDrag(view.backend.album(1),point.x,point.y))
        compare(view.backend.playCalls,1)
    }
    Component { id: archiveFactory; Native.SpineLibrary {} }
    SignalSpy { id: saved; signalName: "saved" }
    function test_local_spine_import_and_invalid_crop() {
        const archive = createTemporaryObject(archiveFactory, test)
        saved.target = archive; saved.clear()
        archive.save(Qt.resolvedUrl("fixture-spine.png"), Qt.rect(0, 0, 1, 1))
        verify(archive.error === "", archive.error)
        tryCompare(saved, "count", 1)
        verify(String(saved.signalArguments[0][0]).startsWith("file:"))
        archive.save(Qt.resolvedUrl("fixture-spine.png"), Qt.rect(-1, 0, 1, 1))
        verify(archive.error !== "")
        compare(saved.count, 1)
        archive.images("not-an-edition")
        verify(archive.error !== "")
        archive.save("https://example.com/image.png", Qt.rect(0, 0, 1, 1))
        verify(archive.error !== "")
        verify(!archive.busy)
    }
    function test_panoramic_shelf_scrolls_horizontally() {
        view.width = 1920; view.height = 360; view.fullscreenActive = true
        waitForRendering(view)
        verify(view.shelf.panoramic)
        const grid = view.shelf.view
        compare(grid.orientation, ListView.Horizontal)
        verify(grid.contentWidth > grid.width)
        const touch = touchEvent(grid)
        touch.press(0, grid, grid.width - 40, grid.height / 2).commit()
        for (let step = 1; step <= 8; step++) {
            touch.move(0, grid, grid.width - 40 - step * 24, grid.height / 2).commit()
            wait(16)
        }
        touch.release(0, grid, grid.width - 232, grid.height / 2).commit()
        tryVerify(() => grid.contentX > 40)
        compare(view.controller.phase, "shelf")
    }
    Component { id: presentationFactory; NestPresentation { width: 1180; height: 760; backend: DemoBackend {} } }
    function test_fullscreen_reparents_the_same_surface_and_restores_the_window() {
        view.visible = false
        const stage = createTemporaryObject(presentationFactory, test)
        const surface = stage.surface
        const owner = stage.Window.window
        const previousVisibility = owner.visibility
        verify(surface.controller.open(surface.backend.album(0)))
        verify(surface.controller.insert())
        tryCompare(surface.controller, "phase", "loaded", 1600)
        const loaded = surface.controller.loaded.id
        stage.setFullscreen(true)
        tryCompare(stage.fullscreenWindow, "visibility", Window.FullScreen)
        tryVerify(() => surface.width > 0 && surface.height > 0)
        verify(surface.fullscreenActive)
        compare(stage.surface, surface)
        compare(surface.controller.loaded.id, loaded)
        verify(!owner.visible)
        stage.setFullscreen(false)
        tryCompare(owner, "visibility", previousVisibility)
        compare(surface.controller.loaded.id, loaded)
        compare(stage.surface, surface)
        stage.destroy()
    }
    function test_unloading_fullscreen_restores_the_host_window() {
        view.visible = false
        const stage = createTemporaryObject(presentationFactory, test)
        const owner = stage.Window.window
        const previousVisibility = owner.visibility
        stage.setFullscreen(true)
        tryCompare(stage.fullscreenWindow, "visibility", Window.FullScreen)
        verify(stage.detachedVisible)
        stage.destroy()
        tryCompare(owner, "visibility", previousVisibility)
    }
}
