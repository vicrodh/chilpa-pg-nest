import QtQuick
import QtTest
import "../qml/native" as Native

TestCase {
    id: test
    name: "PresentationLifetime"
    when: windowShown
    width: 400; height: 300
    visible: true
    property bool inStage: false
    Item { id: page }
    Item {
        id: owner
        Item { id: stage }
        Loader {
            id: mount
            objectName: "pluginDisplayLoader"
            parent: test.inStage ? stage : page
            sourceComponent: Component {
                Item {
                    id: surface
                    Native.PresentationLifetime { mount: surface.parent }
                }
            }
        }
    }
    function test_a_page_does_not_own_the_shared_mount() {
        tryVerify(()=>mount.item!==null)
        tryCompare(mount,"parent",owner)
        inStage=true
        tryCompare(mount,"parent",stage)
        inStage=false
        tryCompare(mount,"parent",owner)
        mount.active=false
        tryCompare(mount,"item",null)
        // The original host binding still works after the guard is destroyed.
        inStage=true
        tryCompare(mount,"parent",stage)
        mount.active=true
        tryVerify(()=>mount.item!==null)
        inStage=false
        tryCompare(mount,"parent",owner)
    }
}
