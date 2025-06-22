/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/dialogs/ColorSortDialog.qml
 * Этот файл реализует диалоговое окно для ручной сортировки цветов.
 * Пользователь может изменять порядок цветов двумя способами:
 * 1. Перетаскиванием (long press, drag and drop).
 * 2. Выбором двух цветов для их обмена местами (click-to-swap).
 * Компонент использует GridView для отображения цветов и ListModel для
 * управления их порядком. По завершении он отправляет сигнал
 * colorOrderApplied с отсортированным массивом цветов.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../services/DatabaseManagerService.js" as DB

Item {
    id: root
    anchors.fill: parent
    z: 101
    visible: root.dialogVisible

    property bool dialogVisible: false
    property var colorsToOrder: []
    property color dialogBackgroundColor: DB.darkenColor(DB.getThemeColor() || "#121218", 0.15)

    property int selectedIndex: -1
    property int draggedIndex: -1
    property var draggedColorData: null

    signal colorOrderApplied(var orderedColors)
    signal cancelled()

    ListModel { id: colorSortOrderModel }

    function swapItems(indexA, indexB) {
        if (indexA === indexB || indexA < 0 || indexB < 0 ||
            indexA >= colorSortOrderModel.count || indexB >= colorSortOrderModel.count) {
            console.log("Invalid swap indices or same index: " + indexA + ", " + indexB);
            return;
        }

        console.log("Swapping index " + indexA + " and " + indexB);

        var itemA = colorSortOrderModel.get(indexA);
        var itemB = colorSortOrderModel.get(indexB);

        var tempValueA = itemA.colorValue;
        var tempValueB = itemB.colorValue;

        colorSortOrderModel.set(indexA, { "colorValue": tempValueB });
        colorSortOrderModel.set(indexB, { "colorValue": tempValueA });
    }

    onColorsToOrderChanged: {
        colorSortOrderModel.clear();
        root.selectedIndex = -1;
        root.draggedIndex = -1;
        root.draggedColorData = null;

        if (colorsToOrder && colorsToOrder.length > 0) {
            for (var i = 0; i < colorsToOrder.length; i++) {
                colorSortOrderModel.append({ "colorValue": colorsToOrder[i] });
            }
        }
    }

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
                width: parent.width - (Theme.paddingLarge * 2)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingLarge
                anchors.bottomMargin: Theme.paddingLarge
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    text: qsTr("Set Color Order")
                    font.pixelSize: Theme.fontSizeLarge;
                    font.bold: true; color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    width: parent.width
                    text: qsTr("Long press to drag and drop. Click to select and swap.")
                    font.pixelSize: Theme.fontSizeSmall; color: Theme.secondaryColor
                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                }

                GridView {
                    id: colorSortGrid
                    width: parent.width
                    implicitHeight: contentHeight
                    cellWidth: width / 4
                    cellHeight: cellWidth
                    model: colorSortOrderModel
                    clip: true
                    interactive: false

                    MouseArea {
                        id: gridDragHandler
                        anchors.fill: parent
                        enabled: root.dialogVisible

                        property int currentDraggedDelegateInitialIndex: -1

                        onPressAndHold: {
                            var clickedIndex = colorSortGrid.indexAt(mouseX, mouseY);
                            if (clickedIndex !== -1) {
                                currentDraggedDelegateInitialIndex = clickedIndex;
                                root.draggedIndex = clickedIndex;
                                root.draggedColorData = colorSortOrderModel.get(clickedIndex).colorValue;
                                root.selectedIndex = -1;

                                dragVisual.color = root.draggedColorData;
                                dragVisual.width = colorSortGrid.cellWidth * 0.8;
                                dragVisual.height = colorSortGrid.cellHeight * 0.8;

                                var localMousePointInDialogBody = mapToItem(dialogBody, mouseX, mouseY);
                                dragVisual.x = localMousePointInDialogBody.x - dragVisual.width / 2;
                                dragVisual.y = localMousePointInDialogBody.y - dragVisual.height / 2;

                                dragVisual.visible = true;
                                dragVisual.opacity = 1;
                                dragVisual.z = 10;
                            }
                        }

                        onReleased: {
                            var pressedItem = colorSortGrid.itemAt(mouseX, mouseY);
                            if (pressedItem && pressedItem.colorCircle) {
                                pressedItem.colorCircle.isPressedInternal = false;
                            }

                            if (root.draggedIndex !== -1) {
                                dragVisual.visible = false;
                                dragVisual.opacity = 0;
                                dragVisual.z = 0;

                                currentDraggedDelegateInitialIndex = -1;
                                root.draggedIndex = -1;
                                root.draggedColorData = null;
                            }
                        }

                        onPositionChanged: {
                            if (root.draggedIndex !== -1) {
                                var localMousePointInDialogBody = mapToItem(dialogBody, mouseX, mouseY);
                                dragVisual.x = localMousePointInDialogBody.x - dragVisual.width / 2;
                                dragVisual.y = localMousePointInDialogBody.y - dragVisual.height / 2;

                                var targetXInGrid = dragVisual.mapToItem(colorSortGrid, dragVisual.width/2, dragVisual.height/2).x;
                                var targetYInGrid = dragVisual.mapToItem(colorSortGrid, dragVisual.width/2, dragVisual.height/2).y;
                                var newTargetIndex = colorSortGrid.indexAt(targetXInGrid, targetYInGrid);

                                if (newTargetIndex !== -1 && newTargetIndex !== root.draggedIndex) {
                                    console.log("Moving model item from " + root.draggedIndex + " to " + newTargetIndex);
                                    colorSortOrderModel.move(root.draggedIndex, newTargetIndex, 1);
                                    root.draggedIndex = newTargetIndex;
                                }
                            }
                        }

                        onClicked: {
                            if (root.draggedIndex === -1) {
                                var clickedIndex = colorSortGrid.indexAt(mouseX, mouseY);
                                if (clickedIndex !== -1) {
                                    if (root.selectedIndex === -1) {
                                        root.selectedIndex = clickedIndex;
                                    } else {
                                        if (root.selectedIndex === clickedIndex) {
                                            root.selectedIndex = -1;
                                        } else {
                                            root.swapItems(root.selectedIndex, clickedIndex);
                                            root.selectedIndex = -1;
                                        }
                                    }
                                }
                            }
                        }

                        onPressed: {
                            var pressedItem = colorSortGrid.itemAt(mouseX, mouseY);
                            if (pressedItem && pressedItem.colorCircle) {
                                pressedItem.colorCircle.isPressedInternal = true;
                            }
                        }
                    }

                    delegate: Item {
                        id: delegateRoot
                        width: colorSortGrid.cellWidth
                        height: colorSortGrid.cellHeight

                        Behavior on x {
                            enabled: root.draggedIndex === -1 || (root.draggedIndex !== index)
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }
                        Behavior on y {
                            enabled: root.draggedIndex === -1 || (root.draggedIndex !== index)
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }

                        Rectangle {
                            id: colorCircle
                            anchors.centerIn: parent
                            width: parent.width * 0.8; height: parent.height * 0.8
                            radius: width / 2; color: model.colorValue
                            border.color: "white"
                            border.width: 1
                            z: 0

                            opacity: (root.draggedIndex === index) ? 0 : 1

                            property bool isPressedInternal: false

                            states: [
                                State {
                                    name: "selected"
                                    when: root.selectedIndex === index && root.draggedIndex === -1
                                    PropertyChanges { target: colorCircle; scale: 1.2; border.width: 3 }
                                },
                                State {
                                    name: "pressed"
                                    when: colorCircle.isPressedInternal && root.draggedIndex === -1
                                    PropertyChanges { target: colorCircle; scale: 1.1; border.width: 2 }
                                },
                                State {
                                    name: "normal"
                                    when: root.selectedIndex !== index && !colorCircle.isPressedInternal && root.draggedIndex === -1
                                    PropertyChanges { target: colorCircle; scale: 1.0; border.width: 1; z:0; opacity: 1; }
                                }
                            ]
                            transitions: [
                                Transition {
                                    from: "*"; to: "dragging"
                                    NumberAnimation { properties: "opacity"; duration: 150 }
                                },
                                Transition {
                                    from: "dragging"; to: "*"
                                    NumberAnimation { properties: "opacity"; duration: 150 }
                                },
                                Transition {
                                    from: "normal"; to: "selected"
                                    NumberAnimation { properties: "scale,border.width"; duration: 150; easing.type: Easing.OutQuad }
                                },
                                Transition {
                                    from: "selected"; to: "normal"
                                    NumberAnimation { properties: "scale,border.width"; duration: 150; easing.type: Easing.OutQuad }
                                },
                                Transition {
                                    from: "*"; to: "pressed"
                                    NumberAnimation { properties: "scale,border.width"; duration: 50; easing.type: Easing.OutQuad }
                                },
                                Transition {
                                    from: "pressed"; to: "*"
                                    NumberAnimation { properties: "scale,border.width"; duration: 100; easing.type: Easing.OutQuad }
                                }
                            ]
                        }
                    }
                }

                Rectangle {
                    id: dragVisual
                    parent: dialogBody
                    width: 0; height: 0
                    radius: width / 2
                    color: "transparent"
                    border.color: "white"
                    border.width: 3
                    visible: false
                    opacity: 0
                    scale: 1.2
                    z: 20

                    transitions: [
                        Transition {
                            from: "false"; to: "true"
                            NumberAnimation { properties: "opacity"; duration: 100 }
                        },
                        Transition {
                            from: "true"; to: "false"
                            NumberAnimation { properties: "opacity"; duration: 100 }
                        }
                    ]
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
                 Item { width: 1; height: Theme.paddingLarge }
            }
            VerticalScrollDecorator { flickable: flickable }
        }
    }
}
