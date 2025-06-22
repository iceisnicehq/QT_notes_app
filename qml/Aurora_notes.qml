// qml/Aurora_notes.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

ApplicationWindow {
    initialPage: mainLoader.source
    Loader {
        id: mainLoader
        anchors.fill: parent
        source: "pages/MainPage.qml"

        Connections {
            target: AppSettings
            onCurrentLanguageChanged: {
                console.log("QML: Language changed signal received. Reloading mainLoader.");
                mainLoader.source = "";
                mainLoader.source = "pages/MainPage.qml";
            }
        }
    }
}
