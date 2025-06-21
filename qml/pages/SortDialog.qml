import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

Item {
    id: root
    anchors.fill: parent
    z: 100
    visible: root.dialogVisible

    property color dialogBackgroundColor: "#121218"
    property var availableColors: []

    property bool dialogVisible: false
    property string currentSortBy: "updated_at"
    property string currentSortOrder: "desc"

    signal sortApplied(string sortBy, string sortOrder)
    signal cancelled()


    ListModel {
        id: colorSortOrderModel
    }

    function reorderColors(draggedIndex, dropIndex) {
        if (draggedIndex === dropIndex) return;
        colorSortOrderModel.move(draggedIndex, dropIndex, 1);
    }
    onDialogVisibleChanged: {
        if (dialogVisible) {
            availableColors = DB.colorPalette;
            if (colorSortOrderModel.count === 0) {
                for (var i = 0; i < availableColors.length; i++) {
                    colorSortOrderModel.append({ "color": availableColors[i] });
                }
            }
        }
    }


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
        color: root.dialogBackgroundColor
        radius: Theme.itemSizeSmall / 2
        anchors.centerIn: parent
        opacity: root.dialogVisible ? 1 : 0
        scale: root.dialogVisible ? 1.0 : 0.9
        clip: true
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
                delegate: Rectangle {
                    id: delegateRoot
                    Layout.fillWidth: true
                    height: Theme.itemSizeMedium
                    radius: Theme.paddingSmall
                    property bool isHighlighted: root.currentSortBy === modelData.key

                    // Адаптивный цвет выделения
                    color: {
                        if (isHighlighted) {
                            // ИСПРАВЛЕНИЕ: Преобразуем цвет в строку перед передачей в JS
                            return DB.darkenColor(root.dialogBackgroundColor.toString(), 0.15)
                        } else if (mouseArea.pressed) {
                            // ИСПРАВЛЕНИЕ: Преобразуем цвет в строку перед передачей в JS
                            return DB.darkenColor(root.dialogBackgroundColor.toString(), 0.08)
                        } else {
                            return "transparent"
                        }
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Label {
                        text: modelData.text
                        anchors.centerIn: parent
                        color: delegateRoot.isHighlighted ? "white" : Theme.secondaryColor
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        onClicked: {
                            root.currentSortBy = modelData.key
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                // Динамически меняем высоту
                Layout.preferredHeight: root.currentSortBy === 'color' ? colorSortGrid.contentHeight + Theme.paddingMedium : 0
                visible: root.currentSortBy === 'color'
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 200 } }

                GridView {
                    id: colorSortGrid
                    anchors.fill: parent
                    cellWidth: (width - (Theme.paddingMedium * 3)) / 4 // 4 цвета в ряд
                    cellHeight: cellWidth
                    model: colorSortOrderModel

                    // Делегат для каждого кружка с цветом
                    delegate: Rectangle {
                        width: colorSortGrid.cellWidth * 0.8
                        height: colorSortGrid.cellHeight * 0.8
                        anchors.centerIn: parent
                        radius: width / 2
                        color: model.color

                        // --- Логика Drag and Drop ---
                        DropArea {
                            anchors.fill: parent
                            onDropped: {
                                // Когда другой элемент бросают на этот, меняем их порядок
                                if (drag.source.hasOwnProperty('dragIndex')) {
                                    root.reorderColors(drag.source.dragIndex, index);
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            drag.target: parent // Указываем, что перетаскивать будем родительский Rectangle

                            // Передаем индекс элемента, который тащим
                            onPressed: drag.source.dragIndex = index
                        }
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
                    opacity: highlighted ? 1.0 : 0.5
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    onClicked: root.currentSortOrder = 'asc'
                }
                Button {
                    text: qsTr("Descending")
                    highlighted: root.currentSortOrder === 'desc'
                    opacity: highlighted ? 1.0 : 0.5
                    Behavior on opacity { NumberAnimation { duration: 150 } }
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
