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

    function moveItem(direction) {
        if (selectedIndex === -1) return;
        var originalIndex = selectedIndex;
        var newIndex = (direction === 'up') ? selectedIndex - 1 : selectedIndex + 1;

        if (newIndex >= 0 && newIndex < colorSortOrderModel.count) {
            colorSortOrderModel.move(originalIndex, newIndex, 1);
            selectedIndex = newIndex;
        }
    }

    // Этот обработчик теперь максимально простой и надежный
    onColorsToOrderChanged: {
        colorSortOrderModel.clear();
        selectedIndex = -1;
        for (var i = 0; i < colorsToOrder.length; i++) {
            colorSortOrderModel.append({ "colorValue": colorsToOrder[i] });
        }
    }

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

        // --- НАДЕЖНАЯ ВЕРСТКА НА ЯКОРЯХ ---
        Column {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: Theme.paddingMedium
            spacing: Theme.paddingMedium

            PageHeader {
                id: pageHeader
                title: qsTr("Set Color Order")
            }

            Label {
                id: subHeader
                width: parent.width
                text: qsTr("Click to select a color, then use arrows to move it.")
                font.pixelSize: Theme.fontSizeSmall; color: Theme.secondaryColor
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            }

            Row {
                id: listContainer
                width: parent.width
                // Якоря, чтобы занять все доступное место между подзаголовком и кнопкой
                anchors.top: subHeader.bottom
                anchors.bottom: bottomButton.top
                anchors.topMargin: Theme.paddingMedium
                anchors.bottomMargin: Theme.paddingMedium
                spacing: Theme.paddingMedium

                SilicaFlickable {
                    width: parent.width - arrowButtons.width - listContainer.spacing
                    height: parent.height
                    contentHeight: listView.contentHeight

                    ListView {
                        id: listView
                        anchors.fill: parent
                        model: colorSortOrderModel
                        spacing: Theme.paddingSmall

                        delegate: BackgroundItem {
                            width: parent.width
                            height: Theme.itemSizeMedium
                            highlighted: root.selectedIndex === index
                            onClicked: { root.selectedIndex = (root.selectedIndex === index) ? -1 : index }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: Theme.paddingMedium
                                spacing: Theme.paddingMedium
                                Rectangle {
                                    width: Theme.itemSizeSmall; height: Theme.itemSizeSmall
                                    radius: width/2; color: model.colorValue
                                    border.color: "white"; border.width: 1
                                }
                                Label {
                                    text: model.colorValue
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
