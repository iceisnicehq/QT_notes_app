import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import "DatabaseManager.js" as DB

Item {
    id: root
    anchors.fill: parent
    z: 101
    visible: root.dialogVisible

    // Свойства
    property bool dialogVisible: false
    property var colorsToOrder: []
    property color dialogBackgroundColor: DB.darkenColor(DB.getThemeColor() || "#121218", 0.15)

    // Сигналы
    signal colorOrderApplied(var orderedColors)
    signal cancelled()


    onDialogVisibleChanged: {
        // Этот лог покажет, получает ли компонент команду стать видимым
        console.log("[DEBUG] ColorSortDialog: property 'dialogVisible' changed to: " + root.dialogVisible);
    }

    // Модель и функции
    ListModel {
        id: colorSortOrderModel
    }

    function reorderColors(draggedIndex, dropIndex) {
        if (draggedIndex === dropIndex) return;
        colorSortOrderModel.move(draggedIndex, dropIndex, 1);
    }

    onColorsToOrderChanged: {
        colorSortOrderModel.clear();
        if (root.dialogVisible) {
            console.log("ColorSortDialog: Populating model with " + colorsToOrder.length + " colors.");
            for (var i = 0; i < colorsToOrder.length; i++) {
                colorSortOrderModel.append({ "colorValue": colorsToOrder[i] });
            }
        }
    }

    // UI
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
        height: Math.min(parent.height * 0.8, contentColumn.implicitHeight + Theme.paddingLarge * 2)
        color: root.dialogBackgroundColor
        radius: Theme.itemSizeSmall / 2
        anchors.centerIn: parent
        clip: true
        opacity: root.dialogVisible ? 1 : 0
        scale: root.dialogVisible ? 1.0 : 0.9
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { PropertyAnimation { property: "scale"; duration: 200; easing.type: Easing.OutBack } }

        SilicaFlickable {
            id: flickable
            anchors.fill: parent
            contentHeight: contentColumn.implicitHeight

            Column {
                id: contentColumn
                // Создаем отступы, управляя шириной и якорями
                width: parent.width - (Theme.paddingLarge * 2)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingLarge
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingLarge
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    text: qsTr("Set Color Order")
                    font.pixelSize: Theme.fontSizeLarge; font.bold: true; color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    width: parent.width
                    text: qsTr("Drag colors to change their priority")
                    font.pixelSize: Theme.fontSizeSmall; color: Theme.secondaryColor
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                GridView {
                    id: colorSortGrid
                    width: parent.width

                    readonly property int columnCount: 4
                    readonly property int rowCount: Math.ceil(model.count / columnCount)
                    // Явное вычисление высоты
                    height: rowCount * cellHeight + (rowCount > 0 ? Theme.paddingMedium * (rowCount - 1) : 0)

                    cellWidth: width / columnCount
                    cellHeight: cellWidth
                    model: colorSortOrderModel
                    clip: true

                    // Отступы между ячейками
                    flow: GridView.FlowLeftToRight
                    layoutDirection: Qt.LeftToRight

                    delegate: Item {
                        width: colorSortGrid.cellWidth; height: colorSortGrid.cellHeight

                        Rectangle {
                            id: dragItem
                            width: parent.width * 0.8; height: parent.height * 0.8
                            anchors.centerIn: parent
                            radius: width / 2; color: model.colorValue; border.color: "white"; border.width: 1

                            Drag.active: dragMouseArea.drag.active
                            Drag.hotSpot.x: width / 2; Drag.hotSpot.y: height / 2

                            states: [ State { when: dragItem.Drag.active; PropertyChanges { target: dragItem; scale: 1.2; opacity: 0.7 } } ]
                            transitions: Transition { NumberAnimation { properties: "scale,opacity"; duration: 150 } }

                            MouseArea {
                                id: dragMouseArea; anchors.fill: parent; drag.target: parent
                                onPressed: drag.source.dragIndex = index
                            }
                        }
                        DropArea {
                            anchors.fill: parent
                            onDropped: function(drag) {
                                if (drag.source.hasOwnProperty('dragIndex')) {
                                    root.reorderColors(drag.source.dragIndex, index);
                                }
                            }
                        }
                    }
                }

                Item { width: 1; height: Theme.paddingLarge }

                Button {
                    text: qsTr("Apply Color Sort")
                    anchors.horizontalCenter: parent.horizontalCenter
                    highlightColor: Theme.highlightColor
                    onClicked: {
                        var finalColorOrder = [];
                        for (var i = 0; i < colorSortOrderModel.count; i++) {
                            finalColorOrder.push(colorSortOrderModel.get(i).colorValue);
                        }
                        root.colorOrderApplied(finalColorOrder);
                    }
                }
            }
            VerticalScrollDecorator { flickable: flickable }
        }
    }
}
