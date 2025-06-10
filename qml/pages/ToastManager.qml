// ToastManager.qml
import QtQuick 2.0

ListView {
    function show(text, duration) {
        model.insert(0, {text: text, duration: duration})
    }

    id: root
    z: Infinity
    spacing: 5
    anchors.fill: parent
    anchors.bottomMargin: 10
    verticalLayoutDirection: ListView.BottomToTop
    interactive: false

    displaced: Transition {
        NumberAnimation {
            properties: "y"
            easing.type: Easing.InOutQuad
        }
    }

    delegate: Toast { // Ensure this path is correct if Toast.qml is in a different folder
        Component.onCompleted: {
            // The original logic here was a bit redundant.
            // The `duration` is already passed in the model.
            // Directly call show with the model data.
            show(text, duration);
        }
    }

    model: ListModel {id: model}
}
