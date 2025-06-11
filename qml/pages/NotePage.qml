// NotePage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

Page {
    id: newNotePage
    backgroundColor: newNotePage.noteColor

    property var onNoteSavedOrDeleted: null
    property int noteId: -1
    property string noteTitle: ""
    property string noteContent: ""
    property var noteTags: []
    property bool noteIsPinned: false
    property date noteCreationDate: new Date()
    property date noteEditDate: new Date()
    property string noteColor: "#121218"

    readonly property var colorPalette: [
        "#121218", // Dark Grey (default)
        "#1c1d29", // Slightly Lighter Dark Grey
        "#3a2c2c", // Dark Red
        "#2c3a2c", // Dark Green
        "#2c2c3a", // Dark Blue
        "#3a3a2c", // Dark Yellow
        "#43484e", // Border color from NoteCard, nice neutral option
        "#5c4b37", // A warmer tone
        "#3e4a52", // A cooler, muted blue
        "#503232", // Another muted red
        "#325032", // Another muted green
        "#323250"  // Another muted blue
    ]

    Component.onCompleted: {
        console.log("NewNotePage opened.");

        if (noteId !== -1) {
            noteTitleInput.text = noteTitle;
            noteContentInput.text = noteContent;
            console.log("NewNotePage opened in EDIT mode for ID:", noteId);
            console.log("Note color on open:", noteColor);
        } else {
            noteContentInput.forceActiveFocus();
            Qt.inputMethod.show();
            console.log("NewNotePage opened in CREATE mode. Default color:", noteColor);
        }
    }

    Component.onDestruction: {
        console.log("NewNotePage being destroyed. Attempting to save/delete note.");

        var trimmedTitle = noteTitle.trim();
        var trimmedContent = noteContent.trim();

        if (trimmedTitle === "" && trimmedContent === "") {
            if (noteId !== -1) {
                DB.deleteNote(noteId);
                console.log("Debug: Empty existing note deleted with ID:", noteId);
            } else {
                console.log("Debug: New empty note not saved.");
            }
        } else {
            if (noteId === -1) {
                var newId = DB.addNote(noteIsPinned, noteTitle, noteContent, noteTags, noteColor);
                console.log("Debug: New note added with ID:", newId + ", Color: " + noteColor);
            } else {
                DB.updateNote(noteId, noteIsPinned, noteTitle, noteContent, noteTags, noteColor);
                console.log("Debug: Note updated with ID:", noteId + ", Color: " + noteColor);
            }
        }

        if (onNoteSavedOrDeleted) {
            onNoteSavedOrDeleted();
        }
    }

    ToastManager {
        id: toastManager
    }

    // --- Custom Page Header ---
    Rectangle {
        id: header
        width: parent.width
        height: Theme.itemSizeMedium
        color: newNotePage.noteColor // Цвет хедера привязан к noteColor
        anchors.top: parent.top
        z: 2

        Column {
            anchors.centerIn: parent
            Label {
                text: newNotePage.noteId === -1 ? "New Note" : "Edit Note"
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeLarge
                color: "#e8eaed"
            }

            Column {
                visible: newNotePage.noteId !== -1
                anchors.horizontalCenter: parent.horizontalCenter

                Label {
                    text: "Created: " + Qt.formatDateTime(newNotePage.noteCreationDate, "dd.MM.yyyy - hh:mm")
                    font.pixelSize: Theme.fontSizeExtraSmall * 0.7
                    color: Theme.secondaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    text: "Edited: " + Qt.formatDateTime(newNotePage.noteEditDate, "dd.MM.yyyy - hh:mm")
                    font.pixelSize: Theme.fontSizeExtraSmall * 0.7
                    color: Theme.secondaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
        Item {
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 1.1
            clip: false
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.paddingLarge }
            RippleEffect { id: backRipple }
            Icon {
                id: closeButton
                source: newNotePage.noteId === -1 ?  "../icons/check.svg" :  "../icons/back.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
            }
            MouseArea {
                anchors.fill: parent
                onPressed: backRipple.ripple(mouseX, mouseY)
                onClicked: pageStack.pop()
            }
        }

        Item {
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 1.1
            clip: false
            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Theme.paddingLarge }
            RippleEffect { id: pinRipple }
            Icon {
                id: pinIconButton
                source: noteIsPinned ? "../icons/pin-enabled.svg" : "../icons/pin.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
            }

            MouseArea {
                anchors.fill: parent
                onPressed: pinRipple.ripple(mouseX, mouseY)
                onClicked: {
                    noteIsPinned = !noteIsPinned;
                    var msg = noteIsPinned ? "The note was pinned" : "The note was unpinned"
                    toastManager.show(msg)
                    noteContentInput.forceActiveFocus();
                    Qt.inputMethod.show();
                }
            }
        }
    }

    // --- Нижний тулбар (всегда на дне) ---
    Rectangle {
        id: bottomToolbar
        width: parent.width
        height: Theme.itemSizeSmall
        // ИСПРАВЛЕНИЕ: Используем привязку к нижней части родителя
        // и корректируем позицию, если клавиатура видна.
        // Это более надежно, чем динамическое изменение y.
        anchors.bottom: parent.bottom
        color: "#1c1d29" // Фиксированный цвет, чтобы не сливался с noteColor
        z: 10 // Важно: панель выбора цвета будет иметь z: 11, чтобы быть выше тулбара

        // ИСПРАВЛЕНИЕ: Перемещаем логику поднятия тулбара при появлении клавиатуры сюда.
        // Привязываем нижнюю границу тулбара к верхней границе клавиатуры.
        // Если клавиатура не видна, bottomToolbar.y будет равен parent.height - height
        // (то есть, находиться внизу экрана).
        // Если клавиатура видна, bottomToolbar.y будет равен Qt.inputMethod.keyboardRectangle.y - height.
        y: Qt.inputMethod.visible ? (Qt.inputMethod.keyboardRectangle.y - height) : (parent.height - height)

        Behavior on y {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic } // Плавная анимация
        }

        Row {
            id: leftToolbarButtons
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

            // Palette Button
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: paletteRipple }
                Icon {
                    id: paletteIcon
                    source: "../icons/palette.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: paletteRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Change color/theme - showing panel");
                        // Устанавливаем положение colorSelectionPanel для анимации
                        if (!colorSelectionPanel.visible) {
                            // Изначальное положение для появления: прямо над тулбаром
                            colorSelectionPanel.y = bottomToolbar.y - colorSelectionPanel.height;
                            Qt.inputMethod.hide(); // Скрываем клавиатуру при открытии панели
                        } else {
                            // Если панель уже видна, мы просто скроем ее,
                            // и анимация вернет ее за пределы экрана.
                            noteContentInput.forceActiveFocus(); // Возвращаем фокус
                            Qt.inputMethod.show(); // Показываем клавиатуру
                        }
                        colorSelectionPanel.visible = !colorSelectionPanel.visible;
                    }
                }
            }

            // Text Edit Button (Placeholder for now, or might be removed if replaced by new buttons)
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: textEditRipple }
                Icon {
                    id: textEditIcon
                    source: "../icons/text_edit.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: textEditRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Text Edit Options");
                        toastManager.show("Text edit options clicked!");
                        noteContentInput.forceActiveFocus();
                        Qt.inputMethod.show();
                    }
                }
            }

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: alignLeftRipple }
                Icon {
                    source: "../icons/format_align_left.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: alignLeftRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Align Left");
                        noteContentInput.horizontalAlignment = Text.AlignLeft;
                        noteContentInput.forceActiveFocus();
                        Qt.inputMethod.show();
                    }
                }
            }

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: alignCenterRipple }
                Icon {
                    source: "../icons/format_align_center.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: alignCenterRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Align Center");
                        noteContentInput.horizontalAlignment = Text.AlignHCenter;
                        noteContentInput.forceActiveFocus();
                        Qt.inputMethod.show();
                    }
                }
            }

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: alignRightRipple }
                Icon {
                    source: "../icons/format_align_right.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: alignRightRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Align Right");
                        noteContentInput.horizontalAlignment = Text.AlignRight;
                        noteContentInput.forceActiveFocus();
                        Qt.inputMethod.show();
                    }
                }
            }

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: alignJustifyRipple }
                Icon {
                    source: "../icons/format_align_justify.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: alignJustifyRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Align Justify");
                        noteContentInput.horizontalAlignment = Text.AlignJustify;
                        noteContentInput.forceActiveFocus();
                        Qt.inputMethod.show();
                    }
                }
            }

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: undoRipple }
                Icon {
                    id: undoIcon
                    source: "../icons/undo.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: undoRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Undo");
                        toastManager.show("Undo action triggered!");
                        noteContentInput.forceActiveFocus();
                        Qt.inputMethod.show();
                    }
                }
            }

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: redoRipple }
                Icon {
                    id: redoIcon
                    source: "../icons/redo.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: redoRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Redo");
                        toastManager.show("Redo action triggered!");
                        noteContentInput.forceActiveFocus();
                        Qt.inputMethod.show();
                    }
                }
            }
        }

        Row {
            id: rightToolbarButtons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: archiveRipple }
                Icon {
                    id: archiveIcon
                    source: "../icons/archive.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: archiveRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Archive Note");
                        toastManager.show("Note archived!");
                        pageStack.pop();
                    }
                }
            }

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: deleteRipple }
                Icon {
                    id: deleteIcon
                    source: "../icons/delete.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: deleteRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Delete Note");
                        toastManager.show("Note deleted!");

                        if (newNotePage.noteId !== -1) {
                            DB.deleteNote(newNotePage.noteId);
                            console.log("Note deleted with ID:", newNotePage.noteId);
                            if (onNoteSavedOrDeleted) {
                                onNoteSavedOrDeleted();
                            }
                        }
                        pageStack.pop();
                    }
                }
            }
        }
    }

    // --- Flickable Content Area ---
    SilicaFlickable {
        id: mainContentFlickable
        anchors.fill: parent
        anchors.topMargin: header.height
        // ИСПРАВЛЕНИЕ: Нижний отступ теперь динамически вычисляется:
        // он равен высоте тулбара, когда клавиатуры нет,
        // и равен высоте тулбара + высоте клавиатуры, когда клавиатура видна.
        // Это гарантирует, что тулбар не будет перекрывать контент и не будет пробелов.
        anchors.bottomMargin: bottomToolbar.height + (Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0)
        contentHeight: contentColumn.implicitHeight

        // Плавная анимация для нижнего отступа
        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Column {
            id: contentColumn
            width: parent.width - Theme.horizontalPageMargin * 2 // Добавил отступы по горизонтали
            anchors.horizontalCenter: parent.horizontalCenter // Центрируем колонку

            TextField {
                id: noteTitleInput
                width: parent.width
                // anchors.horizontalCenter: parent.horizontalCenter // Уже центрируется родительской колонкой
                placeholderText: "Title"
                text: newNotePage.noteTitle
                onTextChanged: newNotePage.noteTitle = text
                font.pixelSize: Theme.fontSizeLarge
                color: "#e8eaed"
                font.bold: true
                wrapMode: Text.Wrap
                inputMethodHints: Qt.ImhNoAutoUppercase
            }

            TextArea {
                id: noteContentInput
                width: parent.width
                // anchors.horizontalCenter: parent.horizontalCenter // Уже центрируется родительской колонкой
                height: implicitHeight > 0 ? implicitHeight : Theme.itemSizeExtraLarge * 3
                placeholderText: "Note"
                text: newNotePage.noteContent
                onTextChanged: newNotePage.noteContent = text
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeMedium
                color: "#e8eaed"
                verticalAlignment: Text.AlignTop
            }

            Flow {
                id: tagsFlow
                width: parent.width
                // anchors.horizontalCenter: parent.horizontalCenter // Уже центрируется родительской колонкой
                spacing: Theme.paddingMedium
                visible: newNotePage.noteTags.length > 0

                Repeater {
                    model: newNotePage.noteTags
                    delegate: Rectangle {
                        id: tagRectangle
                        property color normalColor: "#32353a"
                        property color pressedColor: "#50545a"
                        color: normalColor
                        radius: 12
                        height: tagText.implicitHeight + Theme.paddingSmall
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium, parent.width)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: tagText
                            text: modelData
                            color: "#c5c8d0"
                            font.pixelSize: Theme.fontSizeMedium
                            anchors.centerIn: parent
                            elide: Text.ElideRight
                            width: parent.width - Theme.paddingMedium
                            wrapMode: Text.NoWrap
                            textFormat: Text.PlainText
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: tagRectangle.color = tagRectangle.pressedColor
                            onReleased: {
                                tagRectangle.color = tagRectangle.normalColor
                                console.log("Tag clicked for editing:", modelData)
                            }
                            onCanceled: tagRectangle.color = tagRectangle.normalColor
                        }
                    }
                }
            }

            Item { width: parent.width; height: Theme.paddingLarge * 2 }
        }
    }

    // НОВАЯ ПАНЕЛЬ ВЫБОРА ЦВЕТА (ВЫЕЗЖАЮЩАЯ СНИЗУ)
    Rectangle {
        id: colorSelectionPanel
        width: parent.width
        // Высота вычисляется на основе содержимого, чтобы не было лишнего пространства
        // ВАЖНО: при использовании implicitHeight для родителя, убедитесь, что дочерние элементы
        // имеют свои implicitHeight. Для Flow implicitHeight может быть не сразу доступен.
        // Лучше использовать явную высоту или более сложный расчет для Flow, если он не работает как ожидается.
        height: colorTitle.implicitHeight + colorFlow.implicitHeight + cancelBtn.implicitHeight + Theme.paddingMedium * 4
        anchors.horizontalCenter: parent.horizontalCenter
        // !!! ИЗМЕНЕНИЕ ЗДЕСЬ: Изначальная позиция - за пределами экрана
        y: parent.height // Панель изначально скрыта за пределами экрана
        z: 11
        visible: false // Изначально скрыта

        radius: Theme.itemSizeSmall / 2
        color: "#282a36" // Цвет фона панели

        // Анимация для выезда/заезда панели
        Behavior on y {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        // При изменении видимости анимируем Y
        // Это более надежный способ, чем привязка в Behavior on visible,
        // так как visible может изменяться извне, и анимация должна быть связана с этим.
        onVisibleChanged: {
            if (visible) {
                // Если панель становится видимой, анимируем ее к позиции над тулбаром
                colorSelectionPanel.y = bottomToolbar.y - colorSelectionPanel.height;
            } else {
                // Если панель становится невидимой, анимируем ее обратно за пределы экрана
                colorSelectionPanel.y = newNotePage.height;
            }
        }


        Column {
            id: colorPanelContent
            anchors.fill: parent
            anchors.margins: Theme.paddingMedium
            spacing: Theme.paddingMedium

            Label {
                id: colorTitle
                text: "Select Note Color"
                font.pixelSize: Theme.fontSizeLarge
                color: "#e8eaed"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Flow {
                id: colorFlow
                width: parent.width // Use the full width of the parent column
                spacing: Theme.paddingSmall // Space between color circles
                anchors.horizontalCenter: parent.horizontalCenter
                layoutDirection: Qt.LeftToRight

                // Определяем количество столбцов для сетки цветов
                readonly property int columns: 6 // Увеличиваем до 6, чтобы круги были немного больше
                // Вычисляем ширину элемента на основе доступной ширины и желаемых столбцов/отступов
                readonly property real itemWidth: (parent.width - (spacing * (columns - 1))) / columns

                Repeater {
                    model: newNotePage.colorPalette
                    delegate: Item {
                        width: parent.itemWidth // Используем вычисленную itemWidth из Flow
                        height: parent.itemWidth // Делаем квадратным

                        Rectangle {
                            anchors.fill: parent
                            color: modelData // Цвет самого круга
                            radius: parent.width / 2 // Делает круглым, если width == height
                            border.color: (newNotePage.noteColor === modelData) ? Theme.highlightColor : "transparent"
                            border.width: (newNotePage.noteColor === modelData) ? 3 : 0 // Ширина границы для выделенного

                            // Галочка для выбранного цвета
                            // Добавляем фон для галочки
                            Rectangle {
                                visible: newNotePage.noteColor === modelData
                                anchors.centerIn: parent
                                width: parent.width * 0.7 // Размер фона для галочки
                                height: parent.height * 0.7
                                radius: width / 2 // Делаем круглым
                                color: Qt.darker(modelData, 1.2) // Делаем его немного темнее основного цвета
                                border.color: Theme.highlightColor // Добавляем яркую обводку
                                border.width: 2

                                Icon {
                                    source: "../icons/check.svg"
                                    anchors.centerIn: parent
                                    width: parent.width * 0.6
                                    height: parent.height * 0.6
                                    color: "white" // Делаем галочку белой для контраста
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                newNotePage.noteColor = modelData;
                                colorSelectionPanel.visible = false; // Скрываем панель
                                noteContentInput.forceActiveFocus(); // Возвращаем фокус на поле ввода
                                Qt.inputMethod.show(); // Показываем клавиатуру
                            }
                        }
                    }
                }
            }
            // Кнопка "Cancel" находится внизу
            Button {
                id: cancelBtn
                text: "Cancel"
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.6 // Ширина кнопки, чтобы не занимала всю ширину
                onClicked: {
                    colorSelectionPanel.visible = false; // Скрываем панель
                    noteContentInput.forceActiveFocus(); // Возвращаем фокус на поле ввода
                    Qt.inputMethod.show(); // Показываем клавиатуру
                }
            }
        }
    }
    ScrollBar {
        flickableSource: mainContentFlickable
        topAnchorItem: header
    }
}
