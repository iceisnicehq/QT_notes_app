import QtQuick 2.0
import Sailfish.Silica 1.0
import "DatabaseManager.js" as DB // Assuming this exists for color functions

Item {
    id: root
    anchors.fill: parent
    z: 101
    visible: root.dialogVisible

    property bool dialogVisible: false
    property var colorsToOrder: []
    property color dialogBackgroundColor: DB.darkenColor(DB.getThemeColor() || "#121218", 0.15)

    // Properties for click-to-swap
    property int selectedIndex: -1

    // Properties for drag and drop
    property int draggedIndex: -1 // This will be the *current* model index of the item being dragged
    property var draggedColorData: null // Stores the color value of the item being dragged visually

    signal colorOrderApplied(var orderedColors)
    signal cancelled()

    ListModel { id: colorSortOrderModel }

    // Function to swap items using set, which is safer when dealing with indices
    function swapItems(indexA, indexB) {
        if (indexA === indexB || indexA < 0 || indexB < 0 ||
            indexA >= colorSortOrderModel.count || indexB >= colorSortOrderModel.count) {
            console.log("Invalid swap indices or same index: " + indexA + ", " + indexB);
            return;
        }

        console.log("Swapping index " + indexA + " and " + indexB);

        var itemA = colorSortOrderModel.get(indexA);
        var itemB = colorSortOrderModel.get(indexB);

        // Temporarily store values to avoid conflicts
        var tempValueA = itemA.colorValue;
        var tempValueB = itemB.colorValue;

        // Set the values
        colorSortOrderModel.set(indexA, { "colorValue": tempValueB });
        colorSortOrderModel.set(indexB, { "colorValue": tempValueA });
    }

    onColorsToOrderChanged: {
        colorSortOrderModel.clear();
        root.selectedIndex = -1; // Reset selection on new data
        root.draggedIndex = -1; // Reset drag state
        root.draggedColorData = null;

        if (colorsToOrder && colorsToOrder.length > 0) {
            for (var i = 0; i < colorsToOrder.length; i++) {
                colorSortOrderModel.append({ "colorValue": colorsToOrder[i] });
            }
        }
    }

    Rectangle { // Background dimming overlay
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
        color: root.dialogBackgroundColor // Dialog's main background color
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
                    font.pixelSize: Theme.fontSizeLarge; font.bold: true; color: "white"
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
                    interactive: false // Disable GridView's default interaction

                    // MouseArea covering the entire GridView for drag-and-drop and click-to-swap
                    MouseArea {
                        id: gridDragHandler
                        anchors.fill: parent
                        enabled: root.dialogVisible // Only active when dialog is visible

                        property int currentDraggedDelegateInitialIndex: -1 // The *initial* index of the delegate that started the drag

                        onPressAndHold: {
                            var clickedIndex = colorSortGrid.indexAt(mouseX, mouseY);
                            if (clickedIndex !== -1) {
                                currentDraggedDelegateInitialIndex = clickedIndex;
                                root.draggedIndex = clickedIndex; // Set the root property to indicate dragging is active
                                root.draggedColorData = colorSortOrderModel.get(clickedIndex).colorValue; // Store data
                                root.selectedIndex = -1; // Deselect any clicked item when drag starts

                                // Configure and show the separate dragVisual
                                dragVisual.color = root.draggedColorData;
                                dragVisual.width = colorSortGrid.cellWidth * 0.8;
                                dragVisual.height = colorSortGrid.cellHeight * 0.8;

                                // --- IMPORTANT FIX HERE: Use mapToItem for correct coordinate translation ---
                                var localMousePointInDialogBody = mapToItem(dialogBody, mouseX, mouseY);
                                dragVisual.x = localMousePointInDialogBody.x - dragVisual.width / 2;
                                dragVisual.y = localMousePointInDialogBody.y - dragVisual.height / 2;
                                // --- END FIX ---

                                // console.log("onPressAndHold - MouseX:", mouseX, "MouseY:", mouseY);
                                // console.log("onPressAndHold - dragVisual X:", dragVisual.x, "Y:", dragVisual.y);

                                dragVisual.visible = true;
                                dragVisual.opacity = 1; // Ensure it's visible after being configured
                                dragVisual.z = 10; // Bring to front
                            }
                        }

                        onReleased: {
                            // Reset pressed visual state for the item that was initially pressed
                            var pressedItem = colorSortGrid.itemAt(mouseX, mouseY);
                            if (pressedItem && pressedItem.colorCircle) {
                                pressedItem.colorCircle.isPressedInternal = false;
                            }

                            if (root.draggedIndex !== -1) { // If a drag operation was active
                                // Hide and reset the dragVisual
                                dragVisual.visible = false;
                                dragVisual.opacity = 0;
                                dragVisual.z = 0; // Reset z-index

                                currentDraggedDelegateInitialIndex = -1;
                                root.draggedIndex = -1; // Clear drag active flag
                                root.draggedColorData = null;
                            }
                        }

                        onPositionChanged: {
                            if (root.draggedIndex !== -1) { // If a drag is active
                                // --- IMPORTANT FIX HERE: Use mapToItem for correct coordinate translation ---
                                var localMousePointInDialogBody = mapToItem(dialogBody, mouseX, mouseY);
                                // Move the floating visual element (dragVisual)
                                dragVisual.x = localMousePointInDialogBody.x - dragVisual.width / 2;
                                dragVisual.y = localMousePointInDialogBody.y - dragVisual.height / 2;
                                // console.log("onPositionChanged - dragVisual X:", dragVisual.x, "Y:", dragVisual.y);
                                // --- END FIX ---


                                // Determine the new target index in the grid
                                // Use the dragVisual's center point for accurate indexAt lookup
                                var targetXInGrid = dragVisual.mapToItem(colorSortGrid, dragVisual.width/2, dragVisual.height/2).x;
                                var targetYInGrid = dragVisual.mapToItem(colorSortGrid, dragVisual.width/2, dragVisual.height/2).y;
                                var newTargetIndex = colorSortGrid.indexAt(targetXInGrid, targetYInGrid);

                                // If the target index is valid and different from the current position of the dragged item
                                if (newTargetIndex !== -1 && newTargetIndex !== root.draggedIndex) {
                                    console.log("Moving model item from " + root.draggedIndex + " to " + newTargetIndex);
                                    colorSortOrderModel.move(root.draggedIndex, newTargetIndex, 1);
                                    // Crucial: Update root.draggedIndex to the item's *new* model position
                                    // This keeps `root.draggedIndex` in sync with the actual item's position in the model
                                    root.draggedIndex = newTargetIndex;
                                }
                            }
                        }

                        onClicked: { // Handle click-to-swap only if no drag was active
                            if (root.draggedIndex === -1) { // Ensure no drag operation is in progress
                                var clickedIndex = colorSortGrid.indexAt(mouseX, mouseY);
                                if (clickedIndex !== -1) {
                                    if (root.selectedIndex === -1) {
                                        root.selectedIndex = clickedIndex; // Select this item
                                    } else {
                                        if (root.selectedIndex === clickedIndex) {
                                            root.selectedIndex = -1; // Deselect this item if already selected
                                        } else {
                                            // Swap with the previously selected item
                                            root.swapItems(root.selectedIndex, clickedIndex);
                                            root.selectedIndex = -1; // Deselect after swap
                                        }
                                    }
                                }
                            }
                        }

                        onPressed: {
                            // Visual feedback for press (before potential long press or quick click)
                            var pressedItem = colorSortGrid.itemAt(mouseX, mouseY);
                            if (pressedItem && pressedItem.colorCircle) {
                                pressedItem.colorCircle.isPressedInternal = true;
                            }
                        }
                    } // End of gridDragHandler MouseArea

                    delegate: Item {
                        id: delegateRoot
                        width: colorSortGrid.cellWidth
                        height: colorSortGrid.cellHeight

                        // Behaviors for delegateRoot's x and y for smooth grid movements
                        // These apply to the *underlying* grid items as the model changes
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
                            border.width: 1 // Default border width
                            z: 0 // Default z-index for grid items

                            // Hide the original item when its model index matches the currently dragged item's index
                            opacity: (root.draggedIndex === index) ? 0 : 1

                            property bool isPressedInternal: false // For visual pressed feedback

                            states: [
                                State {
                                    name: "selected"
                                    when: root.selectedIndex === index && root.draggedIndex === -1 // Only selected if not dragging
                                    PropertyChanges { target: colorCircle; scale: 1.2; border.width: 3 }
                                },
                                State {
                                    name: "pressed"
                                    // Only show pressed state if not in a drag operation and not the item currently being dragged (invisible)
                                    when: colorCircle.isPressedInternal && root.draggedIndex === -1
                                    PropertyChanges { target: colorCircle; scale: 1.1; border.width: 2 }
                                },
                                // Default normal state for when neither dragging, selected nor pressed
                                State {
                                    name: "normal"
                                    when: root.selectedIndex !== index && !colorCircle.isPressedInternal && root.draggedIndex === -1
                                    PropertyChanges { target: colorCircle; scale: 1.0; border.width: 1; z:0; opacity: 1; }
                                }
                            ]
                            transitions: [
                                // Transition for original item's opacity when drag starts/ends
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

                // --- Floating visual for drag and drop ---
                Rectangle {
                    id: dragVisual
                    parent: dialogBody // Parent to dialogBody so it floats above flickable content
                    width: 0; height: 0 // Will be set dynamically based on dragged item
                    radius: width / 2
                    color: "transparent" // Will be set dynamically
                    border.color: "white"
                    border.width: 3
                    visible: false // Hidden by default
                    opacity: 0 // Hidden by default, will fade in/out
                    scale: 1.2 // Visually larger when dragged
                    z: 20 // Ensure it's on top of everything else

                    // Transitions for drag object appearance
                    transitions: [
                        Transition {
                            from: "false"; to: "true" // When becoming visible
                            NumberAnimation { properties: "opacity"; duration: 100 }
                        },
                        Transition {
                            from: "true"; to: "false" // When becoming invisible
                            NumberAnimation { properties: "opacity"; duration: 100 }
                        }
                    ]
                }
                // --- END Floating visual ---

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
