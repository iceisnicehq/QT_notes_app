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
        if (selectedIndex < 0) {
            return;
        }

        var oldIndex = selectedIndex;
        var newIndex = -1;

        if (direction === 'up' && oldIndex > 0) {
            newIndex = oldIndex - 1;
        } else if (direction === 'down' && oldIndex < colorSortOrderModel.count - 1) {
            newIndex = oldIndex + 1;
        }

        if (newIndex !== -1) {
            colorSortOrderModel.move(oldIndex, newIndex, 1);
            selectedIndex = newIndex;
        }
    }

    onColorsToOrderChanged: {
    }

    onDialogVisibleChanged: {
        if (dialogVisible) {
            colorSortOrderModel.clear();
            selectedIndex = -1;
            for (var i = 0; i < colorsToOrder.length; i++) {
                colorSortOrderModel.append({ "colorValue": colorsToOrder[i] });
            }
        } else {
            selectedIndex = -1;
            colorSortOrderModel.clear();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.dialogVisible ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea {
            id: backgroundMouseArea
            anchors.fill: parent
            enabled: root.dialogVisible
            onClicked: {
                root.cancelled()
            }
        }
    }

    Rectangle {
        id: dialogBody
        width: parent.width - (Theme.paddingLarge * 2)
        height: Math.min(
            parent.height - (Theme.paddingLarge * 4),
            subHeader.implicitHeight + bottomButton.implicitHeight +
            (colorSortOrderModel.count * (Theme.itemSizeSmall + listView.spacing)) +
            (Theme.paddingLarge * 2) +
            (Theme.paddingMedium * 4)
        )
        color: root.dialogBackgroundColor
        radius: Theme.itemSizeSmall / 2
        anchors.centerIn: parent
        clip: true

        MouseArea {
            anchors.fill: parent
            enabled: root.dialogVisible
            onClicked: { /* поглощаем клик */ }
        }

        Column {
            id: contentColumn
            width: parent.width
            height: parent.height
            spacing: Theme.paddingMedium

            Label {
                id: subHeader
                width: parent.width
                text: qsTr("Click to select a color, then use arrows to move it.")
                font.pixelSize: Theme.fontSizeSmall; color: Theme.secondaryColor
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                padding: Theme.paddingMedium
            }

            Row {
                id: listAndArrowsContainer
                width: parent.width
                height: parent.height - subHeader.implicitHeight - bottomButton.implicitHeight - (contentColumn.spacing * 3) - Theme.paddingLarge
                spacing: Theme.paddingMedium
                anchors.horizontalCenter: parent.horizontalCenter

                SilicaFlickable {
                    id: flickableList
                    width: parent.width - arrowButtons.width - listAndArrowsContainer.spacing
                    height: parent.height
                    contentHeight: listView.contentHeight
                    flickableDirection: Flickable.VerticalFlick
                    interactive: false

                    ListView {
                        id: listView
                        anchors.fill: parent
                        model: colorSortOrderModel
                        spacing: Theme.paddingTiny
                        highlightFollowsCurrentItem: false
                        highlightMoveDuration: 0

                        delegate: Item {
                            width: parent.width
                            height: Theme.itemSizeSmall

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.selectedIndex = (root.selectedIndex === index) ? -1 : index
                                }
                                onPressed: { mouse.accepted = true; }
                                onPositionChanged: {
                                    if (mouse.drag && mouse.drag.active) {
                                        mouse.accepted = true;
                                        mouse.drag.active = false;
                                    }
                                }
                                drag.target: null
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 252
                                width: childrenRect.width
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.paddingMedium

                                Rectangle {
                                    width: Theme.itemSizeMedium * 1.5
                                    height: Theme.itemSizeSmall
                                    radius: 5
                                    color: model.colorValue
                                    border.color: (root.selectedIndex === index) ? Theme.highlightColor : "white"
                                    border.width: (root.selectedIndex === index) ? 2 : 1
                                }
                            }
                        }
                    }
                    VerticalScrollDecorator { flickable: parent }
                }

                Column {
                    id: arrowButtons
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingMedium

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
                implicitHeight: Theme.itemSizeMedium

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
