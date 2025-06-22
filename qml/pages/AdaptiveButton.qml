// AdaptiveButton.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../services/DatabaseManager.js" as DB

Item {
    id: root

    // --- Свойства, которыми мы будем управлять извне ---
    property string text: ""
    property bool highlighted: false // Выбрана ли эта кнопка?
    property color baseColor: "#121218" // Базовый цвет для адаптации
    property bool enabled: true // Включена ли кнопка

    // Сигнал, который компонент будет отправлять при клике
    signal clicked()

    // Задаем размеры компонента
    width: parent.width
    height: Theme.itemSizeMedium

    // --- Визуальная часть ---
    Rectangle {
        id: background
        anchors.fill: parent
        radius: Theme.paddingSmall
        antialiasing: true // Для гладких краев

        // --- САМАЯ ГЛАВНАЯ ЧАСТЬ: АДАПТИВНЫЙ ЦВЕТ ---
        // Эта привязка автоматически пересчитывает цвет при изменении состояний
        color: {
            if (root.highlighted) {
                // Цвет для "выбранного" состояния
                return DB.darkenColor(root.baseColor.toString(), -0.20) // Делаем светлее
            } else if (mouseArea.pressed) {
                // Цвет для "нажатого" состояния
                return DB.darkenColor(root.baseColor.toString(), -0.10) // Делаем чуть светлее
            } else {
                // Цвет по умолчанию
                return "transparent"
            }
        }

        // Плавный переход цвета при смене состояний
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    // Текст кнопки
    Label {
        text: root.text
        anchors.centerIn: parent
        // Цвет текста тоже может быть адаптивным
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
