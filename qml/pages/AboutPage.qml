import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1 // Needed for ColumnLayout
import QtQuick.LocalStorage 2.0 // Needed for DB access
import "DatabaseManager.js" as DB // Import DatabaseManager

Page {
    id: aboutPage // Added ID for consistency and property binding
    objectName: "aboutPage"
    allowedOrientations: Orientation.All
    // Use customBackgroundColor for consistent theme application.
    // customBackgroundColor itself has a fallback from DB.getThemeColor().
    backgroundColor: aboutPage.customBackgroundColor
    showNavigationIndicator: false // Ensure navigation indicator is hidden by default

    // Property to control side panel visibility
    property bool panelOpen: false

    // Property to hold the currently selected custom background color
    property string customBackgroundColor: DB.getThemeColor() || "#121218" // Load from DB, default to a dark color

    Component.onCompleted: {
        console.log("AboutPage opened. Initializing side panel and theme.");
        sidePanelInstance.currentPage = "about"; // Highlight 'about' in the side panel

        // Load initial custom background color from DB
        var storedColor = DB.getThemeColor();
        if (storedColor) {
            aboutPage.customBackgroundColor = storedColor;
        } else {
            // If no custom color is set, ensure a default is used
            DB.setThemeColor("#121218"); // Set initial default if not already set
            aboutPage.customBackgroundColor = "#121218";
        }
    }

    // --- PageHeader structure copied directly from SettingsPage.qml ---
    PageHeader {
        id: pageHeader
        height: Theme.itemSizeExtraLarge // Consistent height with SettingsPage

        // Menu icon button, copied from SettingsPage for consistent styling
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
                source: "../icons/menu.svg" // Menu icon for toggling side panel
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                color: Theme.primaryColor // Ensured primary color for consistency
            }

            MouseArea {
                anchors.fill: parent
                onPressed: menuRipple.ripple(mouseX, mouseY)
                onClicked: {
                    aboutPage.panelOpen = true // Open the side panel
                    console.log("Menu button clicked in AboutPage → panelOpen = true")
                }
            }
        }

        // Label for the page title, copied from SettingsPage
        Label {
            text: qsTr("About Application") // Page title, translatable
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            horizontalAlignment: "AlignHCenter"
            font.bold: true
        }
    }

    SilicaFlickable {
        id: flickable
        objectName: "flickable"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        // Ensure flickable content starts exactly below the PageHeader
        anchors.top: pageHeader.bottom
        contentHeight: layout.implicitHeight + Theme.paddingLarge // Use implicitHeight for ColumnLayout
        clip: true
        ColumnLayout { // Changed to ColumnLayout for consistent layout behavior with SettingsPage
            id: layout
            objectName: "layout"
            width: parent.width - (2 * Theme.paddingLarge) // Account for side margins
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingMedium // Spacing between sections and elements

            // Section for "What is this app?"
            SectionHeader {
                objectName: "aboutAppHeader"
                text: qsTr("What is this app?")

            }

            Label {
                objectName: "descriptionText"
                color: Theme.primaryColor // Use primaryColor for text
                font.pixelSize: Theme.fontSizeSmall
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                horizontalAlignment: "AlignJustify"
                Layout.fillWidth: true // Ensures label fills the width in ColumnLayout
                text: qsTr("This is a simple yet powerful note-taking application designed to help you organize your thoughts, ideas, and tasks efficiently. It provides a clean interface for creating, editing, and managing your notes, complete with tagging capabilities and quick search functionality. Whether for personal reminders or professional project management, this app aims to be your reliable digital notebook.")
            }

            // Section for "Who are the Developers?"
            SectionHeader {
                objectName: "developersHeader"
                text: qsTr("Who are the Developers?")
            }

            Label {
                objectName: "developersText"
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                horizontalAlignment: "AlignJustify"
                Layout.fillWidth: true // Ensures label fills the width in ColumnLayout
                text: qsTr("This application was developed with passion and dedication by a team committed to creating intuitive and effective tools for everyday use. We believe in open-source principles and continuously work to improve the app based on user feedback. Special thanks to the Sailfish OS community for their invaluable support and resources.")
            }


            SectionHeader {
                objectName: "licenseHeader"
                text: qsTr("3-Clause BSD License")
            }

            Label {
                objectName: "licenseText"
                color: Theme.primaryColor // Use primaryColor for text
                font.pixelSize: Theme.fontSizeSmall
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                horizontalAlignment: "AlignJustify"
                Layout.fillWidth: true // Ensures label fills the width in ColumnLayout
                text: qsTr("Copyright (c) [Year], [Developer Name/Organization]\nAll rights reserved.\n\nRedistribution and use in source and binary forms, with or without\nmodification, are permitted provided that the following conditions are met:\n\n1. Redistributions of source code must retain the above copyright notice, this\n   list of conditions and the following disclaimer.\n\n2. Redistributions in binary form must reproduce the above copyright notice,\n   this list of conditions and the following disclaimer in the documentation\n   and/or other materials provided with the distribution.\n\n3. Neither the name of the copyright holder nor the names of its\n   contributors may be used to endorse or promote products derived from\n   this software without specific prior written permission.\n\nTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\"\nAND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE\nIMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE\nDISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE\nFOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL\nDAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR\nSERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER\nCAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,\nOR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE\nOF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.")
            }
        }
    }

    // SidePanel, copied from SettingsPage
    SidePanel {
        id: sidePanelInstance
        open: aboutPage.panelOpen
        onClosed: aboutPage.panelOpen = false
        Component.onCompleted: sidePanelInstance.currentPage = "about";
        // Pass the custom background color to the SidePanel so it can update its appearance
        customBackgroundColor: DB.darkenColor(aboutPage.customBackgroundColor, 0.30)
    }
    ScrollBar {
        flickableSource: flickable
        anchors.top: flickable.top
        anchors.bottom: flickable.bottom
        anchors.right: parent.right
        width: Theme.paddingSmall
    }
}
