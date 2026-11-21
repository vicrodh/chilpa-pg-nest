import QtQuick
import "native" as Native
Item {
    id:spectrum
    required property var backend
    property bool live:false
    property bool useGpu:true
    readonly property bool gpuAvailable:GraphicsInfo.api!==GraphicsInfo.Unknown && GraphicsInfo.api!==GraphicsInfo.Software && GraphicsInfo.api!==GraphicsInfo.Null
    function sync(){if(backend)backend.setSpectrumActive(live && visible)}
    onBackendChanged:sync()
    onLiveChanged:sync()
    onVisibleChanged:sync()
    Component.onCompleted:sync()
    Component.onDestruction:if(backend)backend.setSpectrumActive(false)
    Native.SpectrumArt {
        id:meter;objectName:"nestSpectrumState";anchors.fill:parent
        accelerated:spectrum.useGpu && spectrum.gpuAvailable
        active:spectrum.live && spectrum.visible
        levels:spectrum.backend ? spectrum.backend.spectrumLevels:[]
    }
}
