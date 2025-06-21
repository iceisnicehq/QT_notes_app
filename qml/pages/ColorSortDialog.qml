import QtQuick 2.0
import Sailfish.Silica 1.0
import "DatabaseManager.js" as DB

Item {
    id: root
    anchors.fill: parent
    z: 101
    visible: root.dialogVisible

    property bool dialogVisible: false
    property var colorsToOrder: []
    property color dialogBackgroundColor: DB.darkenColor(DB.getThemeColor() || "#121218", 0.15)
    property int selectedIndex: -1

    signal colorOrderApplied(var orderedColors)
    signal cancelled()

    ListModel { id: colorSortOrderModel }

    // ЗАМЕНИТЕ СТАРУЮ ФУНКЦИЮ SWAPITEMS НА ЭТУ:
    function swapItems(indexA, indexB) {
        // Проверка, чтобы индексы были разными и корректными
        if (indexA === indexB || indexA < 0 || indexB < 0) return;

        console.log("Swapping index " + indexA + " and " + indexB);

        // Чтобы избежать ошибок с индексами, всегда двигаем элемент
        // с большим индексом первым.
        if (indexA < indexB) {
            // Сначала двигаем B на место A
            colorSortOrderModel.move(indexB, indexA, 1);
            // Бывший A теперь находится на месте A+1, двигаем его на место B
            colorSortOrderModel.move(indexA + 1, indexB, 1);
        } else { // indexA > indexB
            // Сначала двигаем A на место B
            colorSortOrderModel.move(indexA, indexB, 1);
            // Бывший B теперь находится на месте B+1, двигаем его на место A
            colorSortOrderModel.move(indexB + 1, indexA, 1);
        }
    }

    // --- ИСПРАВЛЕННЫЙ БЛОК ---
    onColorsToOrderChanged: {
        colorSortOrderModel.clear();
        root.selectedIndex = -1; // Сбрасываем выбор при открытии

        // УСЛОВИЕ 'root.visible' УБРАНО. ЭТО ИСПРАВЛЕНИЕ.
        if (colorsToOrder && colorsToOrder.length > 0) {
            for (var i = 0; i < colorsToOrder.length; i++) {
                colorSortOrderModel.append({ "colorValue": colorsToOrder[i] });
            }
        }
    }
    // --- КОНЕЦ ИСПРАВЛЕННОГО БЛОКА ---


    Rectangle { // Фон
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

        MouseArea { anchors.fill: parent; hoverEnabled: true; }

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
                    font.pixelSize: Theme.fontSizeLarge; font.bold: true; color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    width: parent.width
                    text: qsTr("Click one color, then another to swap them. Click a selected color again to deselect.")
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

                    delegate: Item {
                        width: colorSortGrid.cellWidth
                        height: colorSortGrid.cellHeight

                        Rectangle {
                            id: colorCircle
                            width: parent.width * 0.8; height: parent.height * 0.8
                            anchors.centerIn: parent
                            radius: width / 2; color: model.colorValue
                            border.color: "white"

                            states: [
                                State {
                                    name: "selected"
                                    when: root.selectedIndex === index
                                    PropertyChanges { target: colorCircle; scale: 1.2; border.width: 3 }
                                },
                                State {
                                    name: "normal"
                                    when: root.selectedIndex !== index
                                    PropertyChanges { target: colorCircle; scale: 1.0; border.width: 1 }
                                }
                            ]
                            transitions: [
                                Transition {
                                    from: "normal"; to: "selected"
                                    NumberAnimation { properties: "scale,border.width"; duration: 150; easing.type: Easing.OutQuad }
                                },
                                Transition {
                                    from: "selected"; to: "normal"
                                    NumberAnimation { properties: "scale,border.width"; duration: 150; easing.type: Easing.OutQuad }
                                }
                            ]
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.selectedIndex === -1) {
                                    root.selectedIndex = index;
                                } else {
                                    if (root.selectedIndex === index) {
                                        root.selectedIndex = -1;
                                    } else {
                                        root.swapItems(root.selectedIndex, index);
                                        root.selectedIndex = -1;
                                    }
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
                 Item { width: 1; height: Theme.paddingLarge }
            }
            VerticalScrollDecorator { flickable: flickable }
        }
    }
}
