TARGET = ru.template.Aurora_notes

CONFIG += \
    auroraapp

QT += qml quick core gui

PKGCONFIG += \

SOURCES += \
    src/appsettings.cpp \
    src/main.cpp \

HEADERS += \
    src/appsettings.h

DISTFILES += \
    qml/pages/AdaptiveButton.qml \
    qml/dialogs/ColorSortDialog.qml \
    qml/dialogs/ConfirmationDialog.qml \
    qml/pages/ImportExportPage.qml \
    qml/pages/SettingsPage.qml \
    qml/dialogs/SortDialog.qml \
    qml/pages/TrashArchiveNoteCard.qml \
    rpm/ru.template.Aurora_notes.spec \

AURORAAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += auroraapp_i18n

TRANSLATIONS += \
    translations/ru.template.Aurora_notes-ru.ts \
    translations/ru.template.Aurora_notes-en.ts \
    translations/ru.template.Aurora_notes-de.ts \
    translations/ru.template.Aurora_notes-ch.ts \
    translations/ru.template.Aurora_notes-es.ts \
    translations/ru.template.Aurora_notes-fr.ts \
