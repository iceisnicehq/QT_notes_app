/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/services/ToastManagerService.qml
 * Этот QML компонент управляет очередью всплывающих уведомлений (тостов).
 * Он реализован как ListView, который отображает элементы ToastService.
 * Публичная функция show(text, duration) позволяет динамически
 * добавлять новые уведомления в список. Уведомления появляются снизу
 * экрана и выстраиваются вверх.
 */

import QtQuick 2.0

ListView {
    function show(text, duration) {
        model.insert(0, {text: text, duration: duration});
    }

    id: root

    z: Infinity
    spacing: 5
    anchors.fill: parent
    anchors.bottomMargin: 100
    verticalLayoutDirection: ListView.BottomToTop

    interactive: false

    displaced: Transition {
        NumberAnimation {
            properties: "y"
            easing.type: Easing.InOutQuad
        }
    }

    delegate: ToastService {
        Component.onCompleted: {
            if (typeof duration === "undefined") {
                show(text);
            }
            else {
                show(text, duration);
            }
        }
    }

    model: ListModel {id: model}
}
