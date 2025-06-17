import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    // Свойства, которые мы передаем в диалог
    property string fileName
    property string filePath
    property int dataSize
    property int operationsCount
    property string sampleData

    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        DialogHeader {
            title: qsTr("Экспорт завершен")
            acceptText: qsTr("Отлично!")
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            wrapMode: Text.Wrap
            color: Theme.highlightColor
            text: qsTr("Файл: ") + "<b>" + fileName + "</b>"
            textFormat: Text.StyledText
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            wrapMode: Text.Wrap
            text: qsTr("Путь: ") + filePath
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryColor
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            wrapMode: Text.Wrap
            color: Theme.highlightColor
            text: qsTr("Заметок экспортировано: ") + operationsCount
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            wrapMode: Text.Wrap
            color: Theme.highlightColor
            text: qsTr("Размер файла: ") + (dataSize / 1024).toFixed(2) + " KB"
        }

        SectionHeader {
            text: qsTr("Пример данных:")
        }

        TextArea {
            width: parent.width
            height: Math.min(implicitHeight, Screen.height / 4)
            readOnly: true
            text: sampleData
            font.family: "monospace"
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
        }
    }
}
