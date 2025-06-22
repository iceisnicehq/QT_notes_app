/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/components/ScrollBarComponent.qml
 * Этот компонент реализует кастомный скроллбар для использования
 * с элементом Flickable. Его видимость и положение привязаны
 * к состоянию flickableSource: скроллбар появляется при прокрутке
 * или нажатии на контент и автоматически скрывается.
 * Он отображается только если высота контента превышает
 * видимую область.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: scrollBar

    property Flickable flickableSource: null
    property Item topAnchorItem: null

    width: 8
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.top: topAnchorItem ? topAnchorItem.bottom : parent.top
    opacity: (flickableSource && (flickableSource.flicking || flickableSource.pressed)) ? 0.7 : 0.0
    Behavior on opacity { NumberAnimation { duration: 200 } }
    visible: flickableSource && (flickableSource.contentHeight > flickableSource.height)

    Rectangle {
        x: 1
        y: (flickableSource ? flickableSource.visibleArea.yPosition : 0) * (parent.height - 2) + 1

        width: parent.width - 2
        height: (flickableSource ? flickableSource.visibleArea.heightRatio : 0) * (parent.height - 2)

        radius: (parent.width - 2) / 2
        color: "white"
        opacity: 0.7
    }

    Component.onCompleted: {
        if (!flickableSource) {
            console.warn("ScrollBar (ID: " + scrollBar.id + "): 'flickableSource' property is not set. Scrollbar will not function correctly.");
        }
    }
}
