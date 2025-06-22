/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/cover/DefaultPageCover.qml
 * Этот файл определяет внешний вид обложки приложения,
 * которая отображается в сетке запущенных приложений (Homescreen)
 * в ОС Аврора. Он использует стандартный CoverTemplate для
 * отображения иконки и названия приложения.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    objectName: "defaultCover"

    CoverTemplate {
        objectName: "applicationCover"
        primaryText: "App"
        secondaryText: qsTr("Notes")
        icon {
            source: Qt.resolvedUrl("../icons/Aurora_notes.svg")
            sourceSize { width: icon.width; height: icon.height }
        }
    }
}
