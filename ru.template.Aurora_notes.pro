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
    qml/pages/ConfirmationDialog.qml \
    qml/pages/ImportExportPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/TrashNoteCard.qml \
    rpm/ru.template.Aurora_notes.spec \

AURORAAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += auroraapp_i18n

TRANSLATIONS += \
    translations/ru.template.Aurora_notes.ts \
    translations/ru.template.Aurora_notes-ru.ts \
