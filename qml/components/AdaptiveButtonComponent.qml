/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/components/AdaptiveButtonComponent.qml
 * Этот компонент представляет собой адаптивную кнопку, цвет фона
 * которой динамически изменяется в зависимости от состояний:
 * выделена (highlighted) или нажата (pressed). Компонент
 * использует функцию darkenColor из DatabaseManagerService для
 * затемнения базового цвета, создавая визуальный отклик
 * на действия пользователя.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../services/DatabaseManagerService.js" as DB

Item {
    id: root

    property string text: ""
    property bool highlighted: false
    property color baseColor: "#121218"
    property bool enabled: true

    signal clicked()

    width: parent.width
    height: Theme.itemSizeMedium
    Rectangle {
        id: background
        anchors.fill: parent
        radius: Theme.paddingSmall
        antialiasing: true
        color: {
            if (root.highlighted) {
                return DB.darkenColor(root.baseColor.toString(), -0.20)
            } else if (mouseArea.pressed) {
                return DB.darkenColor(root.baseColor.toString(), -0.10)
            } else {
                return "transparent"
            }
        }

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Label {
        text: root.text
        anchors.centerIn: parent
        color: root.highlighted ? Theme.primaryColor : Theme.secondaryColor
        opacity: root.enabled ? 1.0 : 0.5
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
