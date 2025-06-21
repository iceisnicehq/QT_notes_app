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
        // Width of the dialog body, with padding from parent edges
        width: parent.width - (Theme.paddingLarge * 2)
        // Height is now based on the implicit height of the contentColumn,
        // clamped by a maximum height to prevent it from going off-screen.
        height: Math.min(
            parent.height - (Theme.paddingLarge * 4), // Maximum height constraint
            contentColumn.implicitHeight + (contentColumn.padding * 2) // Dynamic height based on content
        )
        color: root.dialogBackgroundColor
        radius: Theme.itemSizeSmall / 2
        anchors.centerIn: parent
        clip: true

        // REMOVE THIS MOUSEAREA: It was consuming clicks regardless of button enabled state.
        // MouseArea {
        //     anchors.fill: parent
        //     enabled: root.dialogVisible
        //     onClicked: { /* Consume click to prevent background interaction */ }
        // }

        Column {
            id: contentColumn
            width: parent.width // Fills the dialogBody width
            // Removed fixed height: allows implicitHeight to be calculated from children
            spacing: Theme.paddingMedium
          //  padding: Theme.paddingLarge // Added padding to the column content

            Label {
                id: subHeader
                // Width adjusted to respect contentColumn's padding
                width: parent.width - (parent.padding * 2)
                text: qsTr("Click to select a color, then use arrows to move it.")
                font.pixelSize: Theme.fontSizeSmall; color: Theme.secondaryColor
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            }

            Row {
                id: listAndArrowsContainer
                // Width adjusted to respect contentColumn's padding
                width: parent.width - (parent.padding * 2)
                // Removed fixed height: allows its implicitHeight to be calculated from children
                spacing: Theme.paddingMedium

                SilicaFlickable {
                    id: flickableList

                    // Width calculation for the flickable list
                    width: parent.width - arrowButtons.width
                    // Dynamic height: grows with content but is capped at 60% of the root item's height
                    height: Math.min(listView.contentHeight, root.height * 0.6)
                    contentHeight: listView.contentHeight
                    flickableDirection: Flickable.VerticalFlick
                    interactive: true // Allow user to flick the list

                    ListView {
                        id: listView
                        width: parent.width + arrowButtons.width// List view fills the flickable's width
                        height: contentHeight // List view height adapts to its content
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
                                // Centered horizontally within the delegate item
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: childrenRect.width
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.paddingMedium

                                Rectangle {
                                    width: Theme.itemSizeMedium * 1.5
                                    height: Theme.itemSizeSmall
                                    radius: 5
                                    color: model.colorValue
                                    border.color: (root.selectedIndex === index) ? Theme.primaryColor : Theme.secondaryColor
                                    border.width: (root.selectedIndex === index) ? 5 : 2

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
                        opacity: root.selectedIndex > 0 && root.allowArrowClick ? 1 : 0.5
//                        enabled: root.selectedIndex > 0 && root.allowArrowClick
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
                        opacity: root.selectedIndex > 0 && root.allowArrowClick ? 1 : 0.5
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
                        interval: 350
                        onTriggered: {
                            root.allowArrowClick = true
                        }
                    }
                }
            }
            Button {
                id: bottomButton
                text: qsTr("Apply color sort")
                anchors.horizontalCenter: parent.horizontalCenter
//                implicitHeight: Theme.itemSizeMedium

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
