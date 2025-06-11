// NavigationSection.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    id: root
    width: parent.width
    spacing: Theme.paddingSmall

    property string title: ""
    property bool showEdit: false
    property list<QtObject> items

    // Section header
    Item {
        width: parent.width
        height: Theme.itemSizeSmall
        visible: title !== ""

        Label {
            text: root.title
            color: "#a0a1ab"
            font.pixelSize: Theme.fontSizeSmall
            anchors {
                left: parent.left
                leftMargin: Theme.paddingLarge
                verticalCenter: parent.verticalCenter
            }
        }

        IconButton {
            id: editButton
            icon.source: "../icons/edit.svg"
            visible: root.showEdit
            anchors {
                right: parent.right
                rightMargin: Theme.paddingLarge
                verticalCenter: parent.verticalCenter
            }
            onClicked: console.log("Edit clicked for", root.title)
        }
    }

    // Section items
    Repeater {
        model: root.items
        delegate: NavigationItem {
            icon: modelData.icon
            text: modelData.name
            page: modelData.page
        }
    }

    // Delimiter
    Rectangle {
        width: parent.width - Theme.paddingLarge * 2
        height: 1
        color: "#2a2b38"
        anchors.horizontalCenter: parent.horizontalCenter
        visible: parent.visible
    }
}
