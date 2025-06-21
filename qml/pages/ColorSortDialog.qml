import QtQuick 2.0
import Sailfish.Silica 1.0
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
    property int selectedIndex: -1

    // Сигналы
    signal colorOrderApplied(var orderedColors)
    signal cancelled()

    // Модель и функции
    ListModel { id: colorSortOrderModel }

    function moveItem(direction) {
        if (selectedIndex === -1) return;
        var originalIndex = selectedIndex;
        var newIndex;

        if (direction === 'up') {
            if (selectedIndex > 0) {
                newIndex = selectedIndex - 1;
                colorSortOrderModel.move(originalIndex, newIndex, 1);
                selectedIndex = newIndex;
            }
        } else if (direction === 'down') {
            if (selectedIndex < colorSortOrderModel.count - 1) {
                // При перемещении вниз нужно указывать целевой индекс + 1
                newIndex = selectedIndex + 1;
                colorSortOrderModel.move(originalIndex, newIndex + 1, 1);
                selectedIndex = newIndex;
            }
        }
    }


    onColorsToOrderChanged: {
        colorSortOrderModel.clear();
        selectedIndex = -1;
        if (!root.dialogVisible) {
            for (var i = 0; i < colorsToOrder.length; i++) {
                colorSortOrderModel.append({ "colorValue": colorsToOrder[i] });
            }
        }
    }

    onDialogVisibleChanged: {
        if (!dialogVisible) {
            selectedIndex = -1;
            colorSortOrderModel.clear();
        }
    }

    // UI
    Rectangle {
        anchors.fill: parent; color: "#000000"; opacity: root.dialogVisible ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea { anchors.fill: parent; enabled: root.dialogVisible; onClicked: root.cancelled() }
    }

    Rectangle {
        id: dialogBody
        width: parent.width - (Theme.paddingLarge * 2)
        height: parent.height - (Theme.paddingLarge * 4)
        color: root.dialogBackgroundColor
        radius: Theme.itemSizeSmall / 2
        anchors.centerIn: parent
        clip: true
        opacity: root.dialogVisible ? 1 : 0
        scale: root.dialogVisible ? 1.0 : 0.9
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { PropertyAnimation { property: "scale"; duration: 200; easing.type: Easing.OutBack } }

        Column {
            id: contentColumn
            width: parent.width
            height: parent.height
            anchors.centerIn: parent

            PageHeader {
                title: qsTr("Set Color Order")
            }

            Label {
                width: parent.width
                text: qsTr("Click to select a color, then use arrows to move it.")
                font.pixelSize: Theme.fontSizeSmall; color: Theme.secondaryColor
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                padding: Theme.paddingMedium
            }

            Row {
                id: listContainer
                width: parent.width
                height: parent.height - header.height - subHeader.height - bottomButton.height - (Theme.paddingLarge * 2)
                spacing: Theme.paddingMedium
                anchors.horizontalCenter: parent.horizontalCenter

                SilicaFlickable {
                    width: parent.width - arrowButtons.width - listContainer.spacing
                    height: parent.height
                    contentHeight: listView.contentHeight

                    ListView {
                        id: listView
                        anchors.fill: parent
                        model: colorSortOrderModel
                        spacing: Theme.paddingTiny // Уменьшаем отступ между элементами

                        // --- ИЗМЕНЕНИЕ: Уменьшаем размер каждого элемента ---
                        delegate: BackgroundItem {
                            width: parent.width
                            height: Theme.itemSizeSmall // Используем меньший стандартный размер
                            highlighted: root.selectedIndex === index

                            onClicked: {
                                root.selectedIndex = (root.selectedIndex === index) ? -1 : index
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: Theme.paddingMedium
                                spacing: Theme.paddingMedium

                                Rectangle {
                                    width: Theme.iconSizeMedium // Уменьшаем размер кружка
                                    height: Theme.iconSizeMedium
                                    radius: width/2; color: model.colorValue
                                    border.color: "white"; border.width: 1
                                }
                                Label {
                                    text: model.colorValue
                                    font.pixelSize: Theme.fontSizeSmall // Уменьшаем шрифт
                                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                                }
                            }
                        }
                    }
                    VerticalScrollDecorator { flickable: parent }
                }

                Column {
                    id: arrowButtons
                    height: parent.height
                    spacing: Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter

                    Button {
                        icon.source: "image://theme/icon-m-up"
                        enabled: root.selectedIndex > 0
                        onClicked: root.moveItem('up')
                    }
                    Button {
                        icon.source: "image://theme/icon-m-down"
                        enabled: root.selectedIndex !== -1 && root.selectedIndex < (colorSortOrderModel.count - 1)
                        onClicked: root.moveItem('down')
                    }
                }
            }

            Item { id: header; height: 1; anchors.top: contentColumn.top }
            Item { id: subHeader; height: 1 }

            Button {
                id: bottomButton
                text: qsTr("Apply Color Sort")
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingLarge
                onClicked: {
                    var finalColorOrder = [];
                    for (var i = 0; i < colorSortOrderModel.count; i++) {
                        finalColorOrder.push(colorSortOrderModel.get(i).colorValue);
                    }
                    root.colorOrderApplied(finalColorOrder);
                }
            }
        }
    }
}
