/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/components/NavigationButtonComponent.qml
 * Этот компонент реализует кнопку для навигационного меню.
 * Он включает иконку, текстовую метку и опциональный счетчик
 * (например, для количества заметок). Внешний вид кнопки
 * (цвет фона и текста) изменяется, когда она выбрана (selected),
 * используя основной цвет темы, полученный из DatabaseManagerService.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../services/DatabaseManagerService.js" as DB

Item {
    id: root
    width: parent.width
    height: Theme.itemSizeMedium
    property string icon: ""
    property string text: ""
    property bool selected: false
    property int noteCount: -1     
    property string selectedColor: DB.getThemeColor() 
    signal clicked()

    Rectangle {
        anchors.fill: parent
        color: selected ? root.selectedColor : "transparent"
        visible: mouseArea.pressed || selected
        radius: Theme.itemSizeSmall * 0.1
    }
    Icon {
        id: navIcon
        source: root.icon
        width: Theme.iconSizeSmall
        height: Theme.iconSizeSmall
        color: selected ? Theme.primaryColor : Theme.secondaryColor 
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.paddingLarge
    }
    Label {
        id: countLabel
        visible: root.noteCount !== -1
        text: root.noteCount >= 1000 ? "999+" : root.noteCount.toString()
        color: selected ? Theme.primaryColor : Theme.secondaryColor
        font.pixelSize: Theme.fontSizeSmall * 0.9
        font.bold: true 
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        width: Theme.fontSizeMedium * 1.5
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingLarge
    }
    Label {
        id: tagNameLabel
        text: root.text
        color: selected ? Theme.primaryColor : Theme.secondaryColor
        font.pixelSize: Theme.fontSizeMedium
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: navIcon.right
        anchors.leftMargin: Theme.paddingMedium
        anchors.right: countLabel.left
        anchors.rightMargin: Theme.paddingMedium
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            root.clicked()
        }
    }
}
