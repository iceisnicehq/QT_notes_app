// qml/pages/SettingsPage.qml

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1

Page {
    id: settingsPage
    backgroundColor: Theme.backgroundColor
    showNavigationIndicator: false

    PageHeader {
        id: pageHeader
        height: Theme.itemSizeExtraLarge

        Label {
            text: qsTr("Settings") // Заголовок страницы
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            font.bold: true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: pageHeader.height // Отступ от заголовка страницы
        spacing: Theme.paddingMedium // Промежуток между элементами
        anchors.margins: Theme.paddingLarge // Отступы от краев страницы

        SectionHeader {
            text: qsTr("Language") // Заголовок секции "Язык"
        }

        // Кнопка для Русского языка
        Button {
            Layout.fillWidth: true
            text: qsTr("Russian") // Текст кнопки
            // Устанавливаем подсветку, если текущий язык русский
            highlighted: AppSettings.currentLanguage === "ru"

            onClicked: {
                console.log("Выбран язык: Русский");
                if (AppSettings.setApplicationLanguage("ru")) { // Вызываем C++ функцию с кодом "ru"
                    toastManager.show(qsTr("Language changed to Russian"));
                    pageStack.pop(); // Возвращаемся на предыдущую страницу
                } else {
                    toastManager.show(qsTr("Failed to change language."));
                }
            }
        }

        // Кнопка для Английского языка
        Button {
            Layout.fillWidth: true
            text: qsTr("English") // Текст кнопки
            // Устанавливаем подсветку, если текущий язык английский
            highlighted: AppSettings.currentLanguage === "en"

            onClicked: {
                console.log("Выбран язык: Английский");
                if (AppSettings.setApplicationLanguage("en")) { // Вызываем C++ функцию с кодом "en"
                    toastManager.show(qsTr("Language changed to English"));
                    pageStack.pop(); // Возвращаемся на предыдущую страницу
                } else {
                    toastManager.show(qsTr("Failed to change language."));
                }
            }
        }
    }

    ToastManager {
        id: toastManager // Менеджер для всплывающих сообщений
    }
}
