import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

Item {
    id: confirmDialog
    property bool dialogVisible: false
    property string dialogTitle: qsTr("")
    property string dialogMessage: ""
    property string confirmButtonText: qsTr("Confirm")
    property color confirmButtonHighlightColor: Theme.highlightColor
    property color dialogBackgroundColor: DB.darkenColor(DB.getThemeColor(), 0.30)

    signal confirmed()
    signal cancelled()

    anchors.fill: parent
    visible: dialogVisible
    z: 100

    Rectangle {
        id: overlayRect
        anchors.fill: parent
        color: "#000000"
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        onVisibleChanged: opacity = confirmDialog.dialogVisible ? 0.5 : 0

        MouseArea {
            anchors.fill: parent
            enabled: confirmDialog.dialogVisible
            onClicked: {
                confirmDialog.cancelled()
            }
        }
    }

    Rectangle {
        id: dialogBody
        color: confirmDialog.dialogBackgroundColor
        radius: Theme.itemSizeSmall / 2
        anchors.centerIn: parent

        visible: confirmDialog.dialogVisible

        opacity: 0
        scale: 0.9

        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { PropertyAnimation { property: "scale"; duration: 200; easing.type: Easing.OutBack } }

        onVisibleChanged: {
            if (visible) {
                dialogBody.opacity = 1;
                dialogBody.scale = 1.0;
            } else {
                dialogBody.opacity = 0;
                dialogBody.scale = 0.9;
            }
        }

        width: Math.min(confirmDialog.width * 0.8, Theme.itemSizeExtraLarge * 8)
        height: contentColumnLayout.implicitHeight + (Theme.paddingLarge * 2)

        ColumnLayout {
            id: contentColumnLayout
            width: parent.width - (Theme.paddingLarge * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingMedium

            Rectangle {
            height: Theme.paddingLarge * 0.9
            color: "transparent"
            }
            Label {
                Layout.fillWidth: true
                text: confirmDialog.dialogTitle
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                wrapMode: Text.Wrap
            }

            Label {
                Layout.fillWidth: true
                text: confirmDialog.dialogMessage
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.primaryColor
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.paddingMedium

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Cancel")
                    onClicked: confirmDialog.cancelled()
                }

                Button {
                    Layout.fillWidth: true
                    text: confirmDialog.confirmButtonText
                    highlightColor: confirmDialog.confirmButtonHighlightColor
                    onClicked: confirmDialog.confirmed()
                }
            }
        }
    }
}
