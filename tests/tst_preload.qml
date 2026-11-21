import QtQuick
import QtTest
import "../qml"
import "../qml/native" as Native

TestCase {
    id:test;name:"NestPreload";when:windowShown;visible:true;width:1024;height:600
    Component {id:fixture;NestView {width:1024;height:440;backend:DemoBackend {size:1000;distinctArtKeys:true}}}
    Component {id:chosenImages;NestView {width:1024;height:440;backend:DemoBackend {preferences:({"spineImages":"on"})}}}
    Component {id:paletteFactory;Native.SpinePalette {}}
    Component {id:preloadFactory;Native.SpinePalettePreloader {}}
    Component {id:spineFactory;Spine {height:300;artActive:true;viewMoving:true}}
    function test_solids_are_the_default_and_reset_and_saved_choices_are_respected(){
        const view=createTemporaryObject(fixture,test)
        verify(!view.imagesEnabled);verify(!view.resolver.automatic)
        view.setting("images","true");verify(view.imagesEnabled)
        view.command("reset");verify(!view.imagesEnabled)
        const restored=createTemporaryObject(chosenImages,test)
        verify(restored.imagesEnabled)
    }
    function test_new_colors_load_while_the_shelf_moves(){
        const view=createTemporaryObject(fixture,test)
        const uri=String(Qt.resolvedUrl("../qml/demo-0.svg"))+"?moving="+Date.now()
        const spine=createTemporaryObject(spineFactory,test,{backend:view.backend,controller:view.controller,colors:view.colors,album:{id:9001,title:"Moving",artist:"Fixture",year:"2026",art:uri}})
        verify(spine.viewMoving);verify(spine.spinePalette.active)
        tryVerify(()=>spine.spinePalette.ready,2000)
        verify(!Qt.colorEqual(spine.spinePalette.background,"#35383b"))
        verify(spine.spinePalette.contrast>=4.5)
    }
    function test_preloaded_colors_apply_without_activating_the_palette(){
        const uri=String(Qt.resolvedUrl("../qml/demo-1.svg"))+"?preloaded="+Date.now()
        const warm=createTemporaryObject(preloadFactory,test,{sources:[uri],active:true})
        const probe=createTemporaryObject(paletteFactory,test,{active:false})
        tryVerify(()=>{probe.source="";probe.source=uri;return probe.ready},2000)
        verify(!probe.active);verify(!Qt.colorEqual(probe.background,"#35383b"));verify(probe.contrast>=4.5)
        warm.active=false;compare(warm.held,0)
    }
    function test_preload_is_bounded_and_releases_its_subscriptions(){
        const uri=String(Qt.resolvedUrl("../qml/demo-2.svg"))
        const warm=createTemporaryObject(preloadFactory,test,{sources:Array.from({length:100},(_,index)=>uri+"?bounded="+index),active:true})
        compare(warm.held,64);compare(warm.sources.length,64)
        warm.active=false;compare(warm.held,0)
        warm.sources=[];compare(warm.sources.length,0)
    }
    function test_both_sides_are_preloaded_without_extra_album_delegates(){
        const view=createTemporaryObject(fixture,test)
        tryVerify(()=>view.shelf.view && view.shelf.view.itemAtIndex(0))
        waitForRendering(view);wait(60)
        const list=view.shelf.view
        list.positionViewAtIndex(50,ListView.Beginning);list.forceLayout();waitForRendering(view)
        tryVerify(()=>view.shelf.palettePreloader.held===16,2000)
        const visible=Array.from(list.contentItem.children).filter(slot=>slot.spine && slot.inViewport)
        const first=Math.min(...visible.map(slot=>slot.index)),last=Math.max(...visible.map(slot=>slot.index))
        const sources=Array.from(view.shelf.palettePreloader.sources).map(String)
        verify(sources.includes(view.backend.artAt(first-8)))
        verify(sources.includes(view.backend.artAt(last+8)))
        verify(list.contentItem.children.length<120)
        compare(list.maximumFlickVelocity,2000);compare(list.flickDeceleration,2200)
        view.visible=false
        tryCompare(view.shelf.palettePreloader,"held",0)
        compare(view.shelf.palettePreloader.sources.length,0);verify(!view.shelf.preloadScheduled)
    }
}
