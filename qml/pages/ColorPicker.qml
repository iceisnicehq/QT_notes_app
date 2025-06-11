// qml/pages/ColorPicker.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: colorPickerRoot
    // Adjust width as needed for your dialog, e.g., parent.width * 0.8
    implicitWidth: 300
    implicitHeight: header.implicitHeight + grid.implicitHeight + Theme.paddingLarge * 2

    // Custom properties
    property color selectedColor: "#121218"
    signal colorSelected(color selectedColor)

    Column {
        id: layoutColumn
        width: parent.width
        spacing: Theme.paddingSmall

        // Header for the color picker
        Label {
            id: header
            text: "Choose Color"
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.highlightColor
            topPadding: Theme.paddingMedium
            bottomPadding: Theme.paddingMedium
        }

        // Grid for color swatches
        Grid {
            id: grid
            width: parent.width // Span full width
            columns: 4 // Adjust number of columns as desired
            spacing: Theme.paddingSmall

            // Define your color palette here
            Repeater {
                model: [
                    "#121218", // Dark background
                    "#FF6F61", // Living Coral
                    "#6B5B95", // Serenity Blue
                    "#88B04B", // Greenery
                    "#F7CAC9", // Rose Quartz
                    "#92A8D1", // Light Blue
                    "#FFD700", // Gold
                    "#FF8C00", // Dark Orange
                    "#DA70D6", // Orchid
                    "#4682B4", // Steel Blue
                    "#D2B48C", // Tan
                    "#F4A460", // Sandy Brown
                    "#C0C0C0", // Silver
                    "#A0522D", // Sienna
                    "#20B2AA", // Light Sea Green
                    "#FFB6C1"  // Light Pink
                ]
                delegate: Rectangle {
                    width: (grid.width - (grid.columns - 1) * grid.spacing) / grid.columns
                    height: width // Make squares
                    radius: Theme.itemRadius // Slightly rounded corners
                    color: modelData // Color from the model
                    border.color: selectedColor === modelData ? Theme.highlightColor : "transparent"
                    border.width: selectedColor === modelData ? Theme.borderWidthLarge : 0
                    Behavior on border.width { NumberAnimation { duration: 100 } }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            colorPickerRoot.selectedColor = modelData;
                            colorSelected(modelData); // Emit signal with selected color
                        }
                    }
                }
            }
        }
        Item { width: parent.width; height: Theme.paddingLarge } // Bottom padding
    }
}
