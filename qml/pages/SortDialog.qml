// SortDialog.qml

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB // DB все еще нужен для логики цвета в Label

Item {
    id: root
    anchors.fill: parent
    z: 100
    visible: root.dialogVisible

    // --- ИЗМЕНЕНИЕ 1: Добавляем свойство для цвета фона ---
    property color dialogBackgroundColor: "#121218" // Безопасный цвет по умолчанию

    property bool dialogVisible: false
    property string currentSortBy: "updated_at"
    property string currentSortOrder: "desc"

    signal sortApplied(string sortBy, string sortOrder)
    signal cancelled()

    readonly property var sortOptions: [
        { key: "updated_at", text: qsTr("By Update Date") },
        { key: "created_at", text: qsTr("By Creation Date") },
        { key: "title_alpha", text: qsTr("By Title (A-Z)") },
        { key: "title_length", text: qsTr("By Title Length") },
        { key: "content_length", text: qsTr("By Content Length") },
        { key: "color", text: qsTr("By Color") }
    ]

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.dialogVisible ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea {
            anchors.fill: parent
            enabled: root.dialogVisible
            onClicked: root.cancelled()
        }
    }

    Rectangle {
        id: dialogBody
        width: Math.min(parent.width * 0.9, Theme.itemSizeExtraLarge * 9)
        height: contentColumn.implicitHeight + Theme.paddingLarge * 2

        // --- ИЗМЕНЕНИЕ 2: Используем свойство, переданное извне ---
        color: root.dialogBackgroundColor

        radius: Theme.itemSizeSmall / 2
        anchors.centerIn: parent
        opacity: root.dialogVisible ? 1 : 0
        scale: root.dialogVisible ? 1.0 : 0.9
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { PropertyAnimation { property: "scale"; duration: 200; easing.type: Easing.OutBack } }

        ColumnLayout {
            id: contentColumn
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingMedium
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingLarge
            anchors.bottomMargin: Theme.paddingLarge

            Label {
                text: qsTr("Sort Notes")
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                color: "white"
                Layout.alignment: Qt.AlignHCenter
            }

            Repeater {
                model: root.sortOptions
                delegate: BackgroundItem {
                    Layout.fillWidth: true
                    height: Theme.itemSizeMedium
                    highlighted: root.currentSortBy === modelData.key
                    onClicked: {
                        root.currentSortBy = modelData.key
                    }
                    Label {
                        text: modelData.text
                        anchors.centerIn: parent
                        color: parent.highlighted ? DB.darkenColor(Theme.primaryColor, 0.5) : Theme.secondaryColor
                    }
                }
            }

            Item { Layout.preferredHeight: Theme.paddingMedium }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.paddingMedium
                Button {
                    text: qsTr("Ascending")
                    highlighted: root.currentSortOrder === 'asc'
                    onClicked: root.currentSortOrder = 'asc'
                }
                Button {
                    text: qsTr("Descending")
                    highlighted: root.currentSortOrder === 'desc'
                    onClicked: root.currentSortOrder = 'desc'
                }
            }

            Item { Layout.preferredHeight: Theme.paddingLarge }

            Button {
                text: qsTr("Apply")
                Layout.alignment: Qt.AlignHCenter
                highlightColor: Theme.highlightColor
                onClicked: root.sortApplied(root.currentSortBy, root.currentSortOrder)
            }
        }
    }
}
