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
    // New property to control button enabling
    property bool allowArrowClick: true

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
            contentColumn.implicitHeight + (Theme.paddingLarge * 2)
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
                width: parent.width - (parent.padding * 2)
                text: qsTr("Click to select a color, then use arrows to move it.")
                font.pixelSize: Theme.fontSizeSmall; color: Theme.secondaryColor
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            }

            Row {
                id: listAndArrowsContainer
                width: parent.width - (parent.padding * 2)
                height: parent.height - subHeader.implicitHeight - bottomButton.implicitHeight - (contentColumn.spacing * 2) - (contentColumn.padding * 2)
                spacing: Theme.paddingMedium

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
                        // Disable button if an item is not selected, or if another click is pending
                        enabled: root.selectedIndex > 0 && root.allowArrowClick
                        onClicked: {
                            root.moveItem('up')
                            // Disable clicks temporarily
                            root.allowArrowClick = false
                            // Start timer to re-enable clicks
                            arrowClickTimer.start()
                        }
                    }
                    Button {
                        icon.source: "image://theme/icon-m-down"
                        // Disable button if an item is not selected, or if another click is pending
                        enabled: root.selectedIndex !== -1 && root.selectedIndex < (colorSortOrderModel.count - 1) && root.allowArrowClick
                        onClicked: {
                            root.moveItem('down')
                            // Disable clicks temporarily
                            root.allowArrowClick = false
                            // Start timer to re-enable clicks
                            arrowClickTimer.start()
                        }
                    }

                    Timer {
                        id: arrowClickTimer
                        // Adjust this duration as needed (e.g., 200-300ms)
                        interval: 350
                        onTriggered: {
                            root.allowArrowClick = true
                        }
                    }
                }
            }

            Button {
                id: bottomButton
                text: qsTr("Apply Color Sort")
                anchors.horizontalCenter: parent.horizontalCenter
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
