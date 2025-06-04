// SidePanel.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

Item {
    id: sidePanel
    anchors.fill: parent
    z: 1000 // Ensure it's on top of everything
    visible: opacity > 0
    opacity: open ? 1 : 0

    property bool open: false
    property string currentPage: "notes"
    property var tags: []

    Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
    }

    // Semi-transparent overlay for the rest of the screen
    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "black"
        opacity: 0.6
    }

    MouseArea {
        anchors.fill: parent
        enabled: open
        onClicked: {
            mainPage.panelOpen = false
        }
    }

    // The actual panel content
    Rectangle {
        id: panelContent
        width: parent.width * 0.75
        height: parent.height
        color: "#1c1d29"
        x: open ? 0 : -width

        Behavior on x {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuad
            }
        }

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: contentColumn.height

            Column {
                id: contentColumn
                width: parent.width
                spacing: Theme.paddingMedium

                // Header
                Item {
                    width: parent.width
                    height: Theme.itemSizeLarge

                    Label {
                        text: "Aurora Notes"
                        color: "#e2e3e8"
                        font.pixelSize: Theme.fontSizeLarge
                        anchors {
                            left: parent.left
                            leftMargin: Theme.paddingLarge
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    IconButton {
                        id: closeButton
                        icon.source: "../icons/close.svg"
                        anchors {
                            right: parent.right
                            rightMargin: Theme.paddingLarge
                            verticalCenter: parent.verticalCenter
                        }
                        onClicked: sidePanel.open = false
                    }
                }

                // Navigation Section
                Column {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    SectionHeader {
                        text: "Navigation"
                        font.pixelSize: Theme.fontSizeSmall
                        color: "#a0a1ab"
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.paddingLarge
                        horizontalAlignment: Text.AlignLeft
                    }

                    // Notes Button
                    NavigationButton {
                        icon: "../icons/notes.svg"
                        text: "Notes"
                        selected: sidePanel.currentPage === "notes"
                        onClicked: {
                            sidePanel.currentPage = "notes"
                            sidePanel.open = false
                        }
                    }

                    // Reminders Button
                    NavigationButton {
                        icon: "../icons/reminders.svg"
                        text: "Reminders"
                        selected: sidePanel.currentPage === "reminders"
                        onClicked: {
                            sidePanel.currentPage = "reminders"
                            sidePanel.open = false
                        }
                    }
                }

                // Delimiter
                Rectangle {
                    width: parent.width - Theme.paddingLarge * 2
                    height: 1
                    color: "#2a2b38"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Tags Section
                Column {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    Item {
                        width: parent.width
                        height: Theme.itemSizeSmall

                        SectionHeader {
                            text: "Tags"
                            font.pixelSize: Theme.fontSizeSmall
                            color: "#a0a1ab"
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.paddingLarge
                            horizontalAlignment: Text.AlignLeft
                        }

                        IconButton {
                            id: editButton
                            icon.source: "../icons/edit.svg"
                            anchors {
                                right: parent.right
                                rightMargin: Theme.paddingLarge
                                verticalCenter: parent.verticalCenter
                            }
                            onClicked: {
                                pageStack.push(Qt.resolvedUrl("TagEditPage.qml"))
                                sidePanel.open = false
                            }
                        }
                    }

                    // Tags List
                    Repeater {
                        model: tags
                        delegate: NavigationButton {
                            icon: "../icons/tag.svg"
                            text: modelData
                            maxTextWidth: panelContent.width - 100
                            onClicked: {
                                console.log("Tag selected:", modelData)
                                sidePanel.open = false
                                // pageStack.push(Qt.resolvedUrl("TagNotesPage.qml"), {tag: modelData})
                            }
                        }
                    }

                    // Add Tag Button
                    NavigationButton {
                        icon: "../icons/add.svg"
                        text: "Add Tag"
                        onClicked: {
                            pageStack.push(Qt.resolvedUrl("TagEditPage.qml"))
                            sidePanel.open = false
                        }
                    }
                }

                // Delimiter
                Rectangle {
                    width: parent.width - Theme.paddingLarge * 2
                    height: 1
                    color: "#2a2b38"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Other Navigation
                Column {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    NavigationButton {
                        icon: "../icons/archive.svg"
                        text: "Archive"
                        selected: sidePanel.currentPage === "archive"
                        onClicked: {
                            sidePanel.currentPage = "archive"
                            sidePanel.open = false
                        }
                    }

                    NavigationButton {
                        icon: "../icons/trash.svg"
                        text: "Trash"
                        selected: sidePanel.currentPage === "trash"
                        onClicked: {
                            sidePanel.currentPage = "trash"
                            sidePanel.open = false
                        }
                    }

                    NavigationButton {
                        icon: "../icons/settings.svg"
                        text: "Settings"
                        selected: sidePanel.currentPage === "settings"
                        onClicked: {
                            sidePanel.currentPage = "settings"
                            sidePanel.open = false
                        }
                    }

                    NavigationButton {
                        icon: "../icons/about.svg"
                        text: "About"
                        selected: sidePanel.currentPage === "about"
                        onClicked: {
                            sidePanel.currentPage = "about"
                            pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                            sidePanel.open = false
                        }
                    }
                }
            }
        }
    }
}
