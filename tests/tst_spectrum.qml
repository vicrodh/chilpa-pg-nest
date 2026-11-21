import QtQuick
import QtQuick.Window
import QtTest
import "../qml"

TestCase {
    id:test
    name:"NestSpectrum"
    when:windowShown
    visible:true;width:512;height:96
    DemoBackend{id:data;size:1}
    DeckSpectrum{id:gpu;width:256;height:96;backend:data;live:true}
    DeckSpectrum{id:bitmap;x:256;width:256;height:96;backend:data;live:true;useGpu:false}
    SignalSpy {id:frames;signalName:"frameChanged"}
    function init(){frames.target=findChild(gpu,"nestSpectrumState");verify(frames.valid);gpu.width=256;gpu.height=96;bitmap.width=256;bitmap.height=96;gpu.opacity=1;bitmap.opacity=1;gpu.live=false;bitmap.live=false;data.spectrumLevels=[];gpu.useGpu=true;gpu.live=true;bitmap.live=true}
    function test_all_sixteen_input_bands_are_independent(){
        const state=findChild(gpu,"nestSpectrumState")
        for(let band=0;band<16;band++){
            const values=Array(16).fill(0);values[band]=1;data.spectrumLevels=values
            compare(state.levels.length,16)
            for(let index=0;index<16;index++)compare(state.levels[index],index===band ? 1:0)
        }
        wait(100)
        if(Screen.devicePixelRatio===1)verify(grabImage(gpu).red(238,13)>240,"The final input band must reach the top segment")
    }
    function test_changing_music_keeps_a_live_meter_cadence(){
        frames.clear()
        for(let step=0;step<25;step++){data.spectrumLevels=Array.from({length:16},(_,band)=>((step+band)%12)/12);wait(50)}
        verify(frames.count>=22,"Changing music needs a live meter cadence; frames="+frames.count)
        verify(frames.count<=35,"The meter must stay within its 25 Hz budget; frames="+frames.count)
        gpu.live=false;frames.clear();wait(160);compare(frames.count,0)
    }
    function test_peaks_hold_and_decay_after_the_bars_fall(){
        data.spectrumLevels=Array(16).fill(1);wait(100)
        data.spectrumLevels=Array(16).fill(0);wait(900)
        if(Screen.devicePixelRatio===1){
            const image=grabImage(gpu);let peak=false
            for(let row=7;row<12;row++){const y=Math.round(88-(row+.5)*80/12);if(image.red(18,y)>200 || image.green(18,y)>100)peak=true}
            verify(peak,"Peak decay must retain the original envelope at the higher cadence")
            verify(image.green(18,83)<60,"The bars should have fallen below the held peak")
        }
        wait(1400);frames.clear();wait(160);compare(frames.count,0)
    }
    function test_bitmap_and_gpu_can_be_remounted(){
        if(!gpu.gpuAvailable)skip("Remounting requires a GPU scene graph")
        data.spectrumLevels=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
        gpu.useGpu=false
        verify(!findChild(gpu,"nestSpectrumState").accelerated)
        verify(findChild(gpu,"nestSpectrumBitmap").visible)
        wait(250);if(Screen.devicePixelRatio===1)verify(grabImage(gpu).red(18,13)>240)
        gpu.useGpu=true;waitForRendering(gpu)
        verify(findChild(gpu,"nestSpectrumState").accelerated)
        verify(!findChild(gpu,"nestSpectrumBitmap").visible)
        if(Screen.devicePixelRatio===1)verify(grabImage(gpu).red(18,13)>240)
    }
    function test_gpu_matches_the_bitmap_fallback_data(){return [{tag:"nominal",width:256,height:96,alpha:1},{tag:"horizontal",width:196,height:88,alpha:1},{tag:"vertical",width:248,height:72,alpha:1},{tag:"small-surface",width:40,height:32,alpha:1},{tag:"inherited-opacity",width:256,height:96,alpha:.5}]}
    function test_gpu_matches_the_bitmap_fallback(row){
        if(gpu.GraphicsInfo.api===GraphicsInfo.Software || gpu.GraphicsInfo.api===GraphicsInfo.Null)skip("GPU comparison requires a hardware scene graph")
        // QtTest's grabImage produces corrupt 2x snapshots on this Qt build.
        // tools/check-spectrum compares actual grabToImage pixels at both scales.
        if(Screen.devicePixelRatio!==1)skip("HiDPI pixels are checked by tools/check-spectrum")
        gpu.width=row.width;gpu.height=row.height;bitmap.width=row.width;bitmap.height=row.height;gpu.opacity=row.alpha;bitmap.opacity=row.alpha
        data.spectrumLevels=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
        waitForRendering(gpu);wait(250)
        verify(findChild(gpu,"nestSpectrumState").accelerated)
        verify(!findChild(gpu,"nestSpectrumBitmap").visible)
        const actual=grabImage(gpu),expected=grabImage(bitmap)
        compare(actual.width,expected.width);compare(actual.height,expected.height)
        for(let y=0;y<actual.height;y++)for(let x=0;x<actual.width;x++){
            verify(Math.abs(actual.red(x,y)-expected.red(x,y))<=1,"red "+x+","+y+": "+actual.red(x,y)+" / "+expected.red(x,y))
            verify(Math.abs(actual.green(x,y)-expected.green(x,y))<=1,"green "+x+","+y)
            verify(Math.abs(actual.blue(x,y)-expected.blue(x,y))<=1,"blue "+x+","+y)
        }
        if(row.alpha===1 && row.width===256){verify(actual.red(18,13)>240);verify(actual.green(18,73)>200)}
    }
    function test_disabled_spectrum_clears_and_stays_quiet(){
        gpu.live=false;bitmap.live=false
        verify(!findChild(gpu,"nestSpectrumState").active)
        waitForRendering(bitmap)
        const picture=grabImage(bitmap)
        if(Screen.devicePixelRatio===1){verify(picture.red(18,13)<60);verify(picture.green(18,73)<60)}
    }
}
