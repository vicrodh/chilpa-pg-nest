import QtQuick
import QtQuick.Window
import QtTest
import "../qml"
TestCase {
 id:test; name:"CDDeck";when:windowShown;visible:true;width:1024;height:600
 property int frames:0
 Connections{target:test.Window.window;function onFrameSwapped(){test.frames++}}
 DemoBackend{id:data}
 NestView{id:nest;backend:data;width:test.width;height:test.height-deck.height;themeMode:"wood";useCustomPlayer:true;visible:true}
 CDDeck{id:deck;backend:data;controller:nest.controller;width:test.width;height:nest.deckExtent;y:test.height-height}
 function test_compact_and_transport(){
  compare(deck.profile,"slim");compare(deck.height,76)
  const setup=findChild(deck,"nestDeckSetup"),prev=findChild(deck,"nestDeck.prev")
  verify(setup.width>=44 && setup.height>=44)
  verify(prev.width>=44 && prev.height>=44)
  nest.controller.open(data.album(0));verify(nest.controller.insert())
  tryCompare(nest.controller,"phase","loaded",2000)
  verify(data.playing);verify(!nest.deckVisible)
  verify(!nest.spectrumEnabled);verify(!deck.showSpectrum)
  wait(1400);test.frames=0;wait(800);console.log("PLAYING FRAMES "+test.frames);verify(test.frames<=1,"playing static deck has no continuous frames")
  nest.deckProfile="full";deck.width=1280;nest.setting("spectrum","true");verify(deck.showSpectrum)
  data.spectrumLevels=[.3,.6,.9,.7,.2,.1,.4,.6,.8,.5,.7,.2,.3,.7,.9,.1]
  wait(250)
  nest.setting("spectrum","false");verify(!deck.showSpectrum)
  deck.width=1024;nest.deckProfile="auto"
  mouseClick(findChild(deck,"nestDeck.playpause"));verify(data.paused)
  mouseClick(findChild(deck,"nestDeck.playpause"));verify(!data.paused)
  mouseClick(findChild(deck,"nestDeck.stop"));verify(!data.playing);verify(nest.controller.hasDisc)
  mouseClick(findChild(deck,"nestDeck.playpause"));verify(data.playing)
  mouseClick(setup);verify(nest.sortingOpen);nest.sortingOpen=false
  nest.setting("deckProfile","minimal");compare(deck.height,64)
  nest.setting("deckDock","left");deck.width=280;deck.height=600;compare(deck.vertical,true)
  nest.setting("deckDock","bottom");deck.width=1024;deck.height=76
  mouseClick(findChild(deck,"nestDeckEject"));tryCompare(nest.controller,"phase","case",2000)
  verify(!nest.controller.hasDisc)
 }
 function test_cover_locates_loaded_album_and_opens_playable_back(){
  failOnWarning(/TypeError|ReferenceError|Cannot read|Unable to assign/)
  const album=data.record(data.size-2)
  verify(nest.controller.requestPlay(album));tryCompare(nest.controller,"phase","loaded",2000)
  nest.shelf.jump(0);nest.controller.close();wait(500)
  data.query="no matching fixture";nest.setting("favoritesOnly","true")
  mouseClick(findChild(deck,"nestDeckCover"))
  tryVerify(()=>nest.openCase && nest.openCase.album.id===album.id,2500)
  tryVerify(()=>nest.openCase.back && nest.openCase.settled,2000)
  compare(data.query,"");verify(!nest.favoritesOnly)
  verify(!nest.openCase.controlsVisible)
  const tracks=nest.openCase.tracks
  tryVerify(()=>tracks.count>3)
  tracks.forceLayout()
  const row=tracks.itemAtIndex(2)
  verify(row!==null)
  mouseClick(row,row.width*.4,row.height/2)
  tryCompare(data,"trackNumber","03")
  compare(nest.controller.loaded.id,album.id)
  nest.controller.eject();tryCompare(nest.controller,"phase","case",2000);nest.controller.close()
 }
 function test_replacement_cancel_confirm_and_track_selection(){
  const first=data.album(0),second=data.album(1)
  verify(nest.controller.requestPlay(first));tryCompare(nest.controller,"phase","loaded",2000)
  const plays=data.playCalls,stops=data.stopCalls
  data.position=47
  verify(nest.controller.requestPlay(second,4,"5"))
  verify(nest.controller.replacement!==null)
  compare(nest.controller.loaded.id,first.id);compare(data.playCalls,plays);compare(data.stopCalls,stops);compare(data.position,47)
  nest.controller.cancelReplacement();wait(50)
  compare(nest.controller.loaded.id,first.id);compare(data.stopCalls,stops)
  verify(nest.controller.requestPlay(second,4,"5"))
  verify(nest.controller.confirmReplacement())
  verify(!nest.controller.requestPlay(first))
  tryCompare(nest.controller,"phase","loaded",2000)
  compare(nest.controller.loaded.id,second.id);compare(data.stopCalls,stops+1);compare(data.playCalls,plays+1);compare(data.trackNumber,"05")
  nest.controller.eject();tryCompare(nest.controller,"phase","case",2000);nest.controller.close()
 }
 function test_lcd_uses_title_space_and_stacks_track_above_time(){
  for(const profile of ["full","slim","minimal"]){
   nest.deckProfile=profile;deck.width=profile==="full" ? 1280:1024
   const lcd=findChild(deck,"nestDeckLCD"),metadata=findChild(lcd,"nestDeckMetadata"),time=findChild(lcd,"nestDeckTimeBlock"),counter=findChild(lcd,"nestDeckTrackCounter")
   verify(metadata.width>160);verify(metadata.x+metadata.width<time.x);compare(counter.parent,time)
   verify(findChild(deck,"nestDeckCover").width===findChild(deck,"nestDeckCover").height)
  }
  nest.deckProfile="auto";deck.width=1024
 }
 function test_vertical_eject_does_not_cover_the_album_art(){
  nest.setting("deckDock","left");deck.width=280
  for(const size of [560,720]){
   deck.height=size
   const cover=findChild(deck,"nestDeckCover"),eject=findChild(deck,"nestDeckVerticalEject")
   verify(cover.x+cover.width<eject.x)
   verify(eject.width>=44 && eject.height>=44)
   verify(eject.y>=cover.y && eject.y+eject.height<=cover.y+cover.height)
  }
  nest.setting("deckDock","bottom");deck.width=1024;deck.height=76
 }
 function test_z_releasing_the_surface_releases_the_deck(){
  failOnWarning(/TypeError|Cannot read|Unable to assign/)
  deck.controller=null;data.surface=null
  wait(50)
  verify(!deck.hasDisc);verify(!deck.canLoad);verify(!deck.live)
  data.surface=nest;deck.controller=nest.controller
 }
 function test_external_playback_runs_the_spectrum_without_a_loaded_disc(){
  verify(!nest.controller.hasDisc)
  deck.width=1280;nest.deckProfile="full";nest.setting("spectrum","true")
  data.playing=true;data.paused=false
  verify(deck.live,"the host can play without a disc loaded through Nest")
  compare(findChild(deck,"nestDeckLCD").message,"")
  verify(findChild(deck,"nestDeck.playpause").enabled)
  verify(findChild(deck,"nestDeck.stop").enabled)
  const meter=findChild(deck,"nestSpectrumState")
  verify(meter!==null);verify(meter.active)
  data.spectrumLevels=Array(16).fill(.75)
  tryVerify(()=>meter.levels.every(value=>value>.7))
  data.paused=true;verify(!meter.active)
  data.paused=false;verify(meter.active)
  deck.visible=false;verify(!meter.active)
  deck.visible=true;verify(meter.active)
  data.playing=false;verify(!meter.active)
  nest.setting("spectrum","false");nest.deckProfile="auto";deck.width=1024
 }
 function test_seek_stays_interactive_with_a_one_second_display(){
  nest.controller.open(data.album(0));verify(nest.controller.insert());tryCompare(nest.controller,"phase","loaded",2000)
  const progress=findChild(deck,"nestDeckProgress"),seek=findChild(deck,"nestDeckSeek")
  data.position=1.1;const before=progress.width
  data.position=1.9;compare(progress.width,before)
  data.position=2;verify(progress.width>before)
  mousePress(seek,seek.width*.3,seek.height/2)
  mouseMove(seek,seek.width*.7,seek.height/2)
  verify(data.position>data.duration*.6)
  verify(Math.abs(progress.width/progress.parent.width-data.position/data.duration)<.01)
  mouseRelease(seek)
  nest.controller.eject();tryCompare(nest.controller,"phase","case",2000)
 }
}
