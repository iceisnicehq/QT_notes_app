/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/Aurora_notes.qml
 * Это главный QML-файл приложения, который служит точкой входа
 * для пользовательского интерфейса. Он использует Loader для
 * загрузки основной страницы (MainPage.qml). Важной функцией
 * является отслеживание изменений языка через Connections к
 * AppSettings: при смене языка интерфейс полностью перезагружается
 * для применения новых переводов.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

ApplicationWindow {
    initialPage: mainLoader.source
    Loader {
        id: mainLoader
        anchors.fill: parent
        source: "pages/MainPage.qml"

        Connections {
            target: AppSettings
            onCurrentLanguageChanged: {
                console.log("QML: Language changed signal received. Reloading mainLoader.");
                mainLoader.source = "";
                mainLoader.source = "pages/MainPage.qml";
            }
        }
    }
}
