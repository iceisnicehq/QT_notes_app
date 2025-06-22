// /qml/components/RippleEffectComponent.qml
import QtQuick 2.0

Item {
    id: root
    anchors.fill: parent

    property point origin: Qt.point(0, 0)

    function ripple(x, y) {
        origin = Qt.point(x, y)
        rippleCircle.width = 0
        rippleCircle.opacity = 0.8
        rippleAnimation.restart()
    }

    Rectangle {
        id: rippleCircle
        width: 0
        height: width
        radius: width/2
        color: Qt.rgba(1, 1, 1, 0.2)
        x: origin.x - width/2
        y: origin.y - height/2
        opacity: 0
    }

    SequentialAnimation {
        id: rippleAnimation
        running: false

        ParallelAnimation {
            NumberAnimation {
                target: rippleCircle
                property: "width"
                to: Math.max(root.width, root.height) * 2
                duration: 300
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: rippleCircle
                property: "opacity"
                to: 0.8
                duration: 300
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: rippleCircle
                property: "opacity"
                to: 0
                duration: 300
            }
        }
    }
}
