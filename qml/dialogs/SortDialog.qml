/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/dialogs/SortDialog.qml
 * Этот файл определяет диалоговое окно для выбора параметров сортировки заметок.
 * Пользователь может выбрать критерий сортировки (например, по дате обновления,
 * по заголовку) и порядок (по возрастанию/убыванию). Особый пункт "по цвету"
 * инициирует открытие отдельного диалога для настройки порядка цветов.
 * Кнопка "Применить" отправляет сигнал sortApplied с выбранными
 * параметрами.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../services/DatabaseManagerService.js" as DB
import "../pages"
import "../components"

Item {
    id: root
    anchors.fill: parent
    z: 100
    visible: root.dialogVisible

    property color dialogBackgroundColor: "#121218"
    property bool dialogVisible: false
    property string currentSortBy: "updated_at"
    property string currentSortOrder: "desc"

    signal sortApplied(string sortBy, string sortOrder)
    signal cancelled()
    signal colorSortRequested()
    signal showDisabledToast()

    property var availableColors: []
    readonly property int uniqueColorsInNotesCount: availableColors.length

    readonly property var sortOptions: [
        { key: "updated_at", text: qsTr("By update date") },
        { key: "created_at", text: qsTr("By creation date") },
        { key: "title_alpha", text: qsTr("By title (A-Z)") },
        { key: "title_length", text: qsTr("By title length") },
        { key: "content_length", text: qsTr("By content length") },
        { key: "color", text: qsTr("By color") }
    ]

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.dialogVisible ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea { anchors.fill: parent; enabled: root.dialogVisible; onClicked: root.cancelled() }
    }

    Rectangle {
        id: dialogBody
        width: Math.min(parent.width * 0.9, Theme.itemSizeExtraLarge * 9)
        height: contentColumn.implicitHeight + (Theme.paddingLarge * 2)
        color: root.dialogBackgroundColor
        radius: Theme.itemSizeSmall / 2
        anchors.centerIn: parent
        clip: true
        opacity: root.dialogVisible ? 1 : 0
        scale: root.dialogVisible ? 1.0 : 0.9
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { PropertyAnimation { property: "scale"; duration: 200; easing.type: Easing.OutBack } }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }

        Column {
            id: contentColumn
            width: parent.width - (Theme.paddingLarge * 2)
            anchors.centerIn: parent
            spacing: Theme.paddingSmall

            Label {
                width: parent.width
                text: qsTr("Sort Notes")
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                bottomPadding: Theme.paddingSmall
            }

            Repeater {
                model: root.sortOptions
                delegate: Item {
                    width: parent.width
                    height: adaptiveButton.height

                    AdaptiveButtonComponent {
                        id: adaptiveButton
                        text: modelData.text
                        anchors.centerIn: parent
                        width: parent.width * 0.9
                        baseColor: root.dialogBackgroundColor
                        highlighted: root.currentSortBy === modelData.key
                        enabled: modelData.key !== 'color' || root.uniqueColorsInNotesCount > 1
                        onClicked: {
                            if (!enabled) return;
                            root.currentSortBy = modelData.key;
                            if (modelData.key === 'color') {
                                root.colorSortRequested();
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: adaptiveButton
                        enabled: modelData.key === 'color' && !adaptiveButton.enabled

                        onClicked: {
                            console.log("Tapped on disabled 'By color' button. Emitting toast signal.");
                            root.showDisabledToast();
                        }
                    }
                }
            }

            Item { width: 1; height: Theme.paddingMedium }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium
                Button {
                    text: qsTr("Ascending")
                    highlighted: root.currentSortOrder === 'asc'
                    onClicked: root.currentSortOrder = 'asc'
                    enabled: root.currentSortBy !== 'color'
                    opacity: root.currentSortBy === 'color' ? 0.3 : (highlighted ? 1.0 : 0.5)
                }
                Button {
                    text: qsTr("Descending")
                    highlighted: root.currentSortOrder === 'desc'
                    onClicked: root.currentSortOrder = 'desc'
                    enabled: root.currentSortBy !== 'color'
                    opacity: root.currentSortBy === 'color' ? 0.3 : (highlighted ? 1.0 : 0.5)
                }
            }

            Item { width: 1; height: Theme.paddingLarge }

            Button {
                text: qsTr("Apply")
                anchors.horizontalCenter: parent.horizontalCenter
                highlightColor: Theme.highlightColor
                onClicked: {
                    root.sortApplied(root.currentSortBy, root.currentSortOrder)
                }
            }
        }
    }
}
