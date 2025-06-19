// qml/pages/SettingsPage.qml

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1 // Still needed for ColumnLayout within sections
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

Page {
    id: settingsPage
    // Dynamically adapt background color based on custom setting or default
    backgroundColor: settingsPage.customBackgroundColor !== undefined ? settingsPage.customBackgroundColor : "#121218"
    showNavigationIndicator: false

    property bool panelOpen: false

    readonly property var colorPalette: ["#121218", "#1c1d29", "#3a2c2c", "#2c3a2c", "#2c2c3a", "#3a3a2c",
        "#43484e", "#5c4b37", "#3e4a52", "#503232", "#325032", "#323250"]

    readonly property var languageModel: [
        { name: qsTr("English"), code: "en" },
        { name: qsTr("Русский"), code: "ru" },
        { name: qsTr("Deutsch"), code: "de" },
        { name: qsTr("中國人"), code: "ch" },
    ]
    property bool languageListVisible: false

    property string customBackgroundColor: DB.getThemeColor() || "#121218"
    property string currentLanguageSetting: DB.getLanguage()

    property bool confirmDialogVisible: false
    property string confirmDialogTitle: qsTr("Confirm Action")
    property string confirmDialogMessage: ""
    property string confirmButtonText: qsTr("Confirm")
    property var onConfirmCallback: null
    property color confirmButtonHighlightColor: Theme.primaryColor

    property bool hasAnyNotes: false
    property bool hasNonArchivedNonDeletedNotes: false
    property bool hasNonDeletedNotes: false

    Component.onCompleted: {
        console.log("SettingsPage opened. Initializing settings.");
        sidePanelInstance.currentPage = "settings";
        var storedColor = DB.getThemeColor();
        if (storedColor) {
            settingsPage.customBackgroundColor = storedColor;
        } else {
            DB.setThemeColor("#121218");
            settingsPage.customBackgroundColor = "#121218";
        }
        settingsPage.currentLanguageSetting = DB.getLanguage();
        updateNoteCounts();
    }

    function updateNoteCounts() {
        var activeNotes = DB.getAllNotes();
        var deletedNotes = DB.getDeletedNotes();
        var archivedNotes = DB.getArchivedNotes();

        settingsPage.hasAnyNotes = (activeNotes.length > 0 || deletedNotes.length > 0 || archivedNotes.length > 0);
        settingsPage.hasNonArchivedNonDeletedNotes = (activeNotes.length > 0);
        settingsPage.hasNonDeletedNotes = (activeNotes.length > 0 || archivedNotes.length > 0);

        console.log("updateNoteCounts called:");
        console.log("  hasAnyNotes:", settingsPage.hasAnyNotes);
        console.log("  hasNonArchivedNonDeletedNotes (for Archive All):", settingsPage.hasNonArchivedNonDeletedNotes);
        console.log("  hasNonDeletedNotes (for Move to Trash):", settingsPage.hasNonDeletedNotes);
    }

    function showConfirmDialog(message, callback, title, buttonText, highlightColor) {
        confirmDialogMessage = message;
        onConfirmCallback = callback;
        confirmDialogTitle = (title !== undefined) ? title : qsTr("Confirm Action");
        confirmButtonText = (buttonText !== undefined) ? buttonText : qsTr("Confirm");
        confirmButtonHighlightColor = (highlightColor !== undefined) ? highlightColor : Theme.primaryColor;
        confirmDialogVisible = true;
    }

    function refreshPageStack() {
        pageStack.clear();
        pageStack.completeAnimation();
        pageStack.push(Qt.resolvedUrl("MainPage.qml"));
        pageStack.completeAnimation();
        pageStack.push(Qt.resolvedUrl("SettingsPage.qml"));
        pageStack.completeAnimation();
    }


    PageHeader {
        id: pageHeader
        height: Theme.itemSizeExtraLarge

        Item {
            id: menuButton
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 0.95
            clip: false
            anchors {
                left: parent.left
                leftMargin: Theme.paddingMedium
                verticalCenter: parent.verticalCenter
            }

            RippleEffect { id: menuRipple }

            Icon {
                id: leftIcon
                source: "../icons/menu.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                color: Theme.primaryColor
            }

            MouseArea {
                anchors.fill: parent
                onPressed: menuRipple.ripple(mouseX, mouseY)
                onClicked: {
                    settingsPage.panelOpen = true
                    console.log("Menu button clicked in SettingsPage → panelOpen = true")
                }
            }
        }

        Label {
            text: qsTr("Settings")
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            font.bold: true
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        anchors.topMargin: pageHeader.height
        // Flickable теперь будет следить за высотой contentContainer
        contentHeight: contentContainer.implicitHeight + Theme.paddingLarge * 2 // Добавим немного буфера снизу
        flickableDirection: Flickable.VerticalFlick
        clip: true

        MouseArea {
            anchors.fill: parent
            enabled: settingsPage.languageListVisible
            onClicked: settingsPage.languageListVisible = false
        }

        // Основной контейнер, который теперь является простым Item
        Item {
            id: contentContainer
            width: parent.width - (2 * Theme.paddingLarge)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: Theme.paddingLarge
            // Высота будет рассчитываться по содержимому

            // --- СЕКЦИЯ ВЫБОРА ЯЗЫКА ---
            Column { // Используем Column, а не ColumnLayout здесь, так как это Item
                id: languageSection
                width: parent.width
                anchors.top: parent.top // Привязываем к верху Flickable
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium // Отступ между элементами внутри этой секции

                Label {
                    text: qsTr("Language")
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                    color: "white"
                }

                Item {
                    width: parent.width
                    height: languageButton.height + (languageList.visible ? languageList.height : 0)

                    Button {
                        id: languageButton
                        width: parent.width
                        text: {
                            var currentLangCode = DB.getLanguage() || "en";
                            for (var i = 0; i < settingsPage.languageModel.length; i++) {
                                if (settingsPage.languageModel[i].code === currentLangCode) {
                                    return settingsPage.languageModel[i].name;
                                }
                            }
                            return "English";
                        }
                        onClicked: {
                            settingsPage.languageListVisible = !settingsPage.languageListVisible;
                        }
                    }

                    Rectangle {
                        id: languageList
                        width: parent.width
                        height: contentColumn.implicitHeight
                        anchors.top: languageButton.bottom
                        visible: settingsPage.languageListVisible
                        z: 10
                        color: Theme.secondaryHighlightColor
                        radius: Theme.paddingSmall

                        Behavior on opacity { NumberAnimation { duration: 100 } }
                        opacity: visible ? 1.0 : 0.0

                        Column {
                            id: contentColumn
                            width: parent.width
                            Repeater {
                                model: settingsPage.languageModel
                                delegate: BackgroundItem {
                                    width: parent.width
                                    height: Theme.itemSizeMedium
                                    highlighted: (DB.getLanguage() || "en") === modelData.code

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.name
                                        // ИЗМЕНЕНО ЗДЕСЬ: Цвет текста для выбранного/невыбранного языка
                                        color: highlighted ? DB.darkenColor(Theme.primaryColor, 0.5) : Theme.secondaryColor
                                    }

                                    onClicked: {
                                        settingsPage.languageListVisible = false;
                                        var newLangCode = modelData.code;
                                        if ((DB.getLanguage() || "en") !== newLangCode) {
                                            if (AppSettings.setApplicationLanguage(newLangCode)) {
                                                DB.setLanguage(newLangCode);
                                                toastManager.show(qsTr("Language changed to %1").arg(modelData.name));
                                                settingsPage.refreshPageStack();
                                            } else {
                                                toastManager.show(qsTr("Failed to change language."));
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } // End of languageSection

            // Spacer
            Item {
                id: spacer1
                width: parent.width
                height: Theme.paddingLarge // Отступ между секциями
                anchors.top: languageSection.bottom
            }

            // --- СЕКЦИЯ ВЫБОРА ЦВЕТА ТЕМЫ ---
            Column { // Используем Column, а не ColumnLayout
                id: themeColorSection
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: spacer1.bottom // Привязываем к низу первого спейсера
                spacing: Theme.paddingMedium

                Label {
                    text: qsTr("Theme Color")
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: "AlignHCenter"
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                    color: "white"
                }

                Rectangle {
                    id: colorSelectionArea
                    width: parent.width // Используем width родительского Column, не Layout.fillWidth
                    height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + (Theme.itemSizeSmall / 2) * 2
                    color: settingsPage.customBackgroundColor
                    radius: Theme.itemSizeSmall / 2

                    Column {
                        id: colorPanelContentColumn
                        width: parent.width
                        height: implicitHeight
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: Theme.paddingMedium
                        spacing: Theme.paddingMedium

                        Label {
                            id: colorTitle
                            text: qsTr("Select Theme Color")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Flow {
                            id: colorFlow
                            width: parent.width
                            spacing: Theme.paddingSmall
                            anchors.horizontalCenter: parent.horizontalCenter
                            layoutDirection: Qt.LeftToRight
                            readonly property int columns: 6
                            readonly property real itemWidth: (width - (spacing * (columns - 1))) / columns

                            Repeater {
                                model: settingsPage.colorPalette
                                delegate: Item {
                                    width: parent.itemWidth
                                    height: parent.itemWidth

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: (settingsPage.customBackgroundColor === modelData) ? DB.darkenColor(settingsPage.customBackgroundColor, -0.65) : DB.darkenColor(settingsPage.customBackgroundColor, -0.15)
                                        border.color: "transparent"
                                    }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.85
                                        height: parent.height * 0.85
                                        radius: width / 2
                                        color: modelData
                                        border.color: "transparent"

                                        Rectangle {
                                            visible: settingsPage.customBackgroundColor === modelData
                                            anchors.centerIn: parent
                                            width: parent.width * 0.7
                                            height: parent.height * 0.7
                                            radius: width / 2
                                            color: modelData

                                            Icon {
                                                source: "../icons/check.svg"
                                                anchors.centerIn: parent
                                                width: parent.width * 0.75
                                                height: parent.height * 0.75
                                                color: DB.darkenColor(settingsPage.customBackgroundColor, -0.65)
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: true
                                        onClicked: {
                                            settingsPage.customBackgroundColor = modelData;
                                            DB.setThemeColor(modelData);
                                            settingsPage.refreshPageStack();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } // End of themeColorSection

            // Spacer
            Item {
                id: spacer2
                width: parent.width
                height: Theme.paddingLarge // ИЗМЕНЕНО: теперь такой же, как spacer1
                anchors.top: themeColorSection.bottom
            }

            // --- СЕКЦИЯ УПРАВЛЕНИЯ ДАННЫМИ ---
            Column { // Используем Column, а не ColumnLayout
                id: dataManagementSection
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: spacer2.bottom // Привязываем к низу второго спейсера
                spacing: Theme.paddingMedium

                Label {
                    id: dataManagmentLabel
                    text: qsTr("Data Management Actions")
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: "AlignHCenter"
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                    color: "white"
                }

                // Column for data management buttons
                ColumnLayout { // Здесь все еще используем ColumnLayout для кнопок, так как это удобно
                    id: dataButtons
                    width: parent.width // Привязываем к ширине родительского Column
                    spacing: Theme.paddingSmall

                    Button {
                        id: archiveAllButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                        highlightColor: Theme.highlightColor
                        enabled: settingsPage.hasNonArchivedNonDeletedNotes
                        opacity: enabled ? 1 : 0.5
                        Column {
                            anchors.centerIn: parent
                            Label {
                                text: qsTr("Archive All Notes")
                                color: Theme.primaryColor
                                font.pixelSize: Theme.fontSizeSmall
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        onClicked: {
                            console.log("Archive all notes clicked");
                            settingsPage.showConfirmDialog(
                                qsTr("Are you sure you want to archive all your notes?"),
                                function() {
                                    DB.archiveAllNotes();
                                    settingsPage.updateNoteCounts();
                                    settingsPage.refreshPageStack();
                                },
                                qsTr("Confirm Archive"),
                                qsTr("Archive All"),
                                Theme.highlightColor
                            );
                        }
                    }

                    Button {
                        id: moveAllToTrashButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                        highlightColor: Theme.highlightColor
                        enabled: settingsPage.hasNonDeletedNotes
                        opacity: enabled ? 1 : 0.5
                        Column {
                            anchors.centerIn: parent
                            Label {
                                text: qsTr("Move All Notes to Trash")
                                color: Theme.primaryColor
                                font.pixelSize: Theme.fontSizeSmall
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        onClicked: {
                            console.log("Move all notes to trash clicked");
                            settingsPage.showConfirmDialog(
                                qsTr("Are you sure you want to move all your notes to trash?"),
                                function() {
                                    DB.moveAllNotesToTrash();
                                    settingsPage.updateNoteCounts();
                                    settingsPage.refreshPageStack();
                                },
                                qsTr("Confirm Move to Trash"),
                                qsTr("Move to Trash"),
                                Theme.highlightColor
                            );
                        }
                    }

                    Button {
                        id: permanentDeleteButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                        backgroundColor: "#A03030"
                        highlightColor: Theme.errorColor
                        enabled: settingsPage.hasAnyNotes
                        opacity: enabled ? 1 : 0.5

                        Column {
                            anchors.centerIn: parent
                            Label {
                                text: qsTr("Permanently Delete All Notes")
                                color: "white"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        onClicked: {
                            console.log("Permanently delete all notes clicked");
                            settingsPage.showConfirmDialog(
                                qsTr("Are you sure you want to permanently delete ALL your notes and associated tags? This action cannot be undone."),
                                function() {
                                    DB.permanentlyDeleteAllNotes();
                                    settingsPage.updateNoteCounts();
                                    settingsPage.refreshPageStack();
                                },
                                qsTr("Confirm Permanent Deletion"),
                                qsTr("Delete"),
                                Theme.errorColor
                            );
                        }
                    }
                } // End of dataButtons ColumnLayout
            } // End of dataManagementSection

        } // End of contentContainer Item
    } // End of SilicaFlickable

    ToastManager {
        id: toastManager
    }

    ConfirmDialog {
        id: confirmDialogInstance
        dialogVisible: settingsPage.confirmDialogVisible
        dialogTitle: settingsPage.confirmDialogTitle
        dialogMessage: settingsPage.confirmDialogMessage
        confirmButtonText: settingsPage.confirmButtonText
        confirmButtonHighlightColor: settingsPage.confirmButtonHighlightColor
        dialogBackgroundColor: DB.darkenColor(settingsPage.customBackgroundColor, 0.30)
        onConfirmed: {
            if (settingsPage.onConfirmCallback) {
                settingsPage.onConfirmCallback();
            }
            settingsPage.confirmDialogVisible = false;
        }
        onCancelled: {
            settingsPage.confirmDialogVisible = false;
            console.log(qsTr("Action cancelled by user."));
        }
    }

    SidePanel {
        id: sidePanelInstance
        open: settingsPage.panelOpen
        onClosed: settingsPage.panelOpen = false
        Component.onCompleted: sidePanelInstance.currentPage = "settings";
        customBackgroundColor:  DB.darkenColor(settingsPage.customBackgroundColor, 0.30)
        activeSectionColor: settingsPage.customBackgroundColor
    }
}
