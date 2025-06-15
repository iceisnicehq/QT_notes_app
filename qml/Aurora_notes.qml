// qml/Aurora_notes.qml (This becomes your application's root QML)

import QtQuick 2.0
import Sailfish.Silica 1.0

ApplicationWindow {
    initialPage: mainLoader.source // Use Loader for initial page

    // Define the Loader
    Loader {
        id: mainLoader
        anchors.fill: parent
        source: "pages/MainPage.qml" // Load your actual main page here

        // React to language change signal from C++
        Connections {
            target: AppSettings // Your C++ AppSettings object
            onCurrentLanguageChanged: {
                console.log("QML: Language changed signal received. Reloading mainLoader.");
                // Reload the content of the Loader to force retranslation
                mainLoader.source = ""; // Clear source
                mainLoader.source = "pages/MainPage.qml"; // Reload source
                // This will effectively rebuild the QML hierarchy under mainLoader
                // causing all qsTr() calls to be re-evaluated with the new translator.
            }
        }
    }
}
