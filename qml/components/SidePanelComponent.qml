// /qml/components/SidePanelComponent.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../services/DatabaseManagerService.js" as DB
import "../pages"

Item {
    id: sidePanel
    anchors.fill: parent
    z: 1000
    visible: opacity > 0
    opacity: open ? 1 : 0
    property string customBackgroundColor:  DB.darkenColor(DB.getThemeColor(), 0.30)
    property string activeSectionColor: DB.getThemeColor()
    property bool open: false
    property string currentPage: "notes"
    property var tags: []
    property int totalNotesCount: 0
    property int trashNotesCount: 0
    property int archivedNotesCount: 0

    signal closed();

    Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
    }

    function refreshTagsInSidePanel() {
        tags = DB.getAllTagsWithCounts();
        tags.sort(function(a, b) {
            return b.count - a.count;
        });
        console.log("SidePanel: Tags refreshed with counts.", JSON.stringify(tags));
    }

    function refreshNoteCounts() {
        totalNotesCount = DB.getAllNotes().length;
        trashNotesCount = DB.getDeletedNotes().length;
        archivedNotesCount = DB.getArchivedNotes().length;
        console.log("SidePanel: Total notes count:", totalNotesCount);
        console.log("SidePanel: Trash notes count:", trashNotesCount);
        console.log("SidePanel: Archived notes count:", archivedNotesCount);
    }

    function navigateAndManageStack(targetPageUrl, newCurrentPageProperty, targetPageObjectName) {
        if (sidePanel.currentPage === newCurrentPageProperty) {
            sidePanel.closed();
            return;
        }

        sidePanel.currentPage = newCurrentPageProperty;
        var currentStackPageObjectName = pageStack.currentPage ? pageStack.currentPage.objectName : "";

        if (currentStackPageObjectName === "mainPage") {
            pageStack.push(targetPageUrl);
        } else {
            if (targetPageUrl === Qt.resolvedUrl("MainPage.qml")) {
               pageStack.pop();
            }
            else {
                pageStack.replace(targetPageUrl);
            }
        }
        sidePanel.closed();
    }

    Component.onCompleted: {
        DB.permanentlyDeleteExpiredDeletedNotes();
        refreshTagsInSidePanel();
        refreshNoteCounts();
    }

    onOpenChanged: {
        if (open) {
            refreshTagsInSidePanel();
            refreshNoteCounts();
        }
    }

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
            sidePanel.closed();
        }
    }

    Rectangle {
        id: panelContent
        width: parent.width * 0.75
        height: parent.height
        color: sidePanel.customBackgroundColor
        x: open ? 0 : -width

        Behavior on x {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuad
            }
        }

        SilicaFlickable {
            id: sidePanelFlickable
            anchors.fill: parent
            contentHeight: contentColumn.height

            Column {
                id: contentColumn
                width: parent.width
                spacing: Theme.paddingMedium

                Item {
                    id: sidePanelHeader
                    width: parent.width
                    height: Theme.itemSizeLarge

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("../pages/MainPage.qml"), "notes", "mainPage");
                        }

                        Label {
                            text: qsTr("Aurora Notes")
                            color: "#e2e3e8"
                            font.pixelSize: Theme.fontSizeExtraLarge
                            font.bold: true
                            anchors {
                                left: parent.left
                                leftMargin: Theme.paddingLarge
                                verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    Item {
                        width: Theme.fontSizeExtraLarge * 1.1
                        height: Theme.fontSizeExtraLarge * 1.1
                        clip: false
                        anchors {
                            right: parent.right
                            rightMargin: Theme.paddingLarge
                            verticalCenter: parent.verticalCenter
                        }
                        RippleEffectComponent {
                            id: closeRipple
                        }
                        Icon {
                            id: pinIconButton
                            source: "../icons/close.svg"
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: closeRipple.ripple(mouseX, mouseY)
                            onClicked: {
                                sidePanel.closed();
                            }

                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    SectionHeader {
                        text: qsTr("Navigation")
                        font.pixelSize: Theme.fontSizeSmall
                        color: "#a0a1ab"
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.paddingLarge
                        horizontalAlignment: "AlignLeft"
                    }

                    NavigationButtonComponent {
                        icon: "../icons/notes.svg"
                        text: qsTr("Notes")
                        selected: sidePanel.currentPage === "notes"
                        noteCount: sidePanel.totalNotesCount
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("../pages/MainPage.qml"), "notes", "mainPage");
                        }
                    }

                    NavigationButtonComponent {
                        icon: "../icons/archive.svg"
                        text: qsTr("Archive")
                        selected: sidePanel.currentPage === "archive"
                        noteCount: sidePanel.archivedNotesCount
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("../pages/ArchivePage.qml"), "archive", "archivePage");
                        }
                    }

                    NavigationButtonComponent {
                        icon: "../icons/trash.svg"
                        text: qsTr("Trash")
                        selected: sidePanel.currentPage === "trash"
                        noteCount: sidePanel.trashNotesCount
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("../pages/TrashPage.qml"), "trash", "trashPage");
                        }
                    }

                    NavigationButtonComponent {
                        icon: "../icons/import_export.svg"
                        text: qsTr("Import & Export")
                        selected: sidePanel.currentPage === "import/export"
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("../pages/ImportExportPage.qml"), "import/export", "importExportPage");
                        }
                    }

                    NavigationButtonComponent {
                        icon: "../icons/settings.svg"
                        text: qsTr("Settings")
                        selected: sidePanel.currentPage === "settings"
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("../pages/SettingsPage.qml"), "settings", "settingsPage");
                        }
                    }

                    NavigationButtonComponent {
                        icon: "../icons/about.svg"
                        text: qsTr("About")
                        selected: sidePanel.currentPage === "about"
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("../pages/AboutPage.qml"), "about", "aboutPage");
                        }
                    }
                }

                Rectangle {
                    width: parent.width - Theme.paddingLarge * 2
                    height: 1
                    color: "#80ffffff"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Column {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    SectionHeader {
                        text: qsTr("Tags")
                        font.pixelSize: Theme.fontSizeSmall
                        color: "#a0a1ab"
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.paddingLarge
                        horizontalAlignment: "AlignLeft"
                    }

                    NavigationButtonComponent {
                        width: parent.width
                        icon: "../icons/edit.svg"
                        text: qsTr("Edit Tags")
                        selected: sidePanel.currentPage === "edit"
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("../pages/TagEditPage.qml"), "edit", "tagEditPage");
                        }
                    }
                    Label {
                        id: noTagsLabel
                        width: parent.width
                        horizontalAlignment: "AlignHCenter"
                        verticalAlignment: "AlignVCenter"
                        text: qsTr("You have no tags.\n Go to edit tags page\nto create one!")
                        font.italic: true
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        visible: tags.length === 0
                    }
                    Repeater {
                        model: tags
                        delegate: NavigationButtonComponent {
                            icon: "../icons/tag.svg"
                            text: modelData.name
                            noteCount: modelData.count
                            selectedColor: sidePanel.activeSectionColor
                            onClicked: {
                                console.log("Tag selected:", modelData.name);

                                var isMainPageActive = pageStack.currentPage && pageStack.currentPage.objectName === "mainPage";

                                if (isMainPageActive) {
                                    pageStack.currentPage.selectedTags = [modelData.name];
                                    console.log("Updated existing MainPage with tag filter: %1".arg(modelData.name));
                                    mainPage.performSearch("", [modelData.name])
                                    sidePanel.currentPage = "notes";
                                } else {
                                    pageStack.pop();
                                    pageStack.completeAnimation();
                                    pageStack.replace(Qt.resolvedUrl("MainPage.qml"), { selectedTags: [modelData.name], currentSearchText: "" });
                                    console.log("Navigating to new MainPage with tag filter: %1".arg(modelData.name));

                                    sidePanel.currentPage = "notes";
                                }

                                sidePanel.closed();
                            }
                        }
                    }
                }
            }
        }
    }
}
