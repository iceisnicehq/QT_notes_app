// qml/pages/ConfirmDeleteDialog.qml
// ПРАВИЛЬНАЯ СТРУКТУРА SAILFISH.SILICA DIALOG

import Sailfish.Silica 1.0

Dialog {
    id: confirmDeleteDialog

    // Заголовок и текст диалога передаются как свойства Dialog
    property alias dialogTitle: confirmDeleteDialog.title // Алиас для удобства
    property alias dialogText: confirmDeleteDialog.text   // Алиас для удобства

    // Текст для кнопок передается как свойства Dialog
    property alias acceptButtonText: confirmDeleteDialog.acceptText
    property alias cancelButtonText: confirmDeleteDialog.cancelText

    // Сигналы, которые мы будем испускать после закрытия диалога
    signal acceptedCustom() // Используем другое имя, чтобы не конфликтовать с внутренним accepted
    signal canceledCustom() // Используем другое имя

    // Обработка закрытия диалога - важно для сигналов
    onDone: {
        if (result === Dialog.Accepted) {
            acceptedCustom();
        } else {
            canceledCustom();
        }
    }

    // Содержимое диалога (если нужно что-то помимо простого текста)
    // В данном случае, мы используем 'text' свойство Dialog, поэтому contentItem не нужен.
    // Если бы вам нужно было что-то сложное (например, TextField внутри диалога),
    // вы бы поместили это сюда:
    /*
    contentItem: Column {
        // ... ваши элементы ...
        Label { text: confirmDeleteDialog.text; wrapMode: Text.WordWrap }
    }
    */
}
