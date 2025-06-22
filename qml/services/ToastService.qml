/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/services/ToastService.qml
 * Этот файл определяет визуальный компонент для одного всплывающего
 * уведомления (тоста). Он представляет собой прямоугольник с текстом.
 * Функция show() запускает анимацию, которая плавно показывает,
 * удерживает и затем скрывает уведомление. Компонент может
 * самоуничтожаться после завершения анимации.
 */

import QtQuick 2.0

Rectangle {
    function show(text, duration) {
        message.text = text;
        if (typeof duration !== "undefined") {
            time = Math.max(duration, 2 * fadeTime);
        }
        else {
            time = defaultTime;
        }
        animation.start();
    }

    property bool selfDestroying: false
    id: root

    readonly property real defaultTime: 3000
    property real time: defaultTime
    readonly property real fadeTime: 250

    property real margin: 10

    anchors {
        left: parent.left
        right: parent.right
        margins: margin
    }

    height: message.height + margin
    radius: margin

    opacity: 0
    color: "#222222"

    Text {
        id: message
        color: "white"
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: margin / 2

        }
    }

    SequentialAnimation on opacity {
        id: animation
        running: false


        NumberAnimation {
            to: .9
            duration: fadeTime
        }

        PauseAnimation {
            duration: time - 2 * fadeTime
        }

        NumberAnimation {
            to: 0
            duration: fadeTime
        }

        onRunningChanged: {
            if (!running && selfDestroying) {
                root.destroy();
            }
        }
    }
}
