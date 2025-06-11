// NavigationItem.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    width: parent.width
    height: Theme.itemSizeMedium

    property string icon: ""
    property string text: ""
    property string page: ""
    property bool selected: (sidePanel.currentPage === page)
    property real maxTextWidth: parent.width - 100

    signal clicked()

    Rectangle {
        anchors.fill: parent
        color: selected ? "#2a2b38" : "transparent"
        visible: mouseArea.pressed || selected
    }

    Row {
        anchors {
            left: parent.left
            leftMargin: Theme.paddingLarge
            right: parent.right
            rightMargin: Theme.paddingLarge
            verticalCenter: parent.verticalCenter
        }
        spacing: Theme.paddingMedium

        Icon {
            source: root.icon
            width: Theme.iconSizeSmall
            height: Theme.iconSizeSmall
            color: selected ? "#e2e3e8" : "#a0a1ab"
        }

        Label {
            text: root.text
            color: selected ? "#e2e3e8" : "#a0a1ab"
            font.pixelSize: Theme.fontSizeMedium
            width: Math.min(implicitWidth, maxTextWidth)
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            root.clicked()
            if (page !== "") {
                sidePanel.currentPage = page
                // Handle navigation here
                if (page === "about") {
                    pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                }
                // Add other page navigations
            }
        }
    }
}
