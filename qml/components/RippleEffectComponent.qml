/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/components/RippleEffectComponent.qml
 * Данный компонент создает визуальный эффект "волны" (ripple),
 * который обычно используется для обратной связи при нажатии
 * на элементы интерфейса. Анимация запускается вызовом
 * функции ripple(x, y), которая создает расходящийся
 * и затухающий круг из точки нажатия.
 */

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
