/* 
 * Студент 1, Студент 2
 * 
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/main.qml
 * Этот файл является альтернативной или устаревшей точкой входа
 * для QML-интерфейса. Он напрямую загружает MainPage как
 * начальную страницу ApplicationWindow без использования Loader.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow {
    initialPage: Component { MainPage {} }
}
