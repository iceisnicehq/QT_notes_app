TARGET = ru.template.Aurora_notes

CONFIG += \
    auroraapp \
    auroraapp_i18n

QT += qml quick core gui

PKGCONFIG += \

SOURCES += \
    src/appsettings.cpp \
    src/main.cpp \

HEADERS += \
    src/appsettings.h

RESOURCES += resources.qrc

DISTFILES += \
    rpm/ru.template.Aurora_notes.spec \

AURORAAPP_ICONS = 86x86 108x108 128x128 172x172

TRANSLATIONS += \
    translations/ru.template.Aurora_notes-ru.ts \
    translations/ru.template.Aurora_notes-en.ts \
    translations/ru.template.Aurora_notes-de.ts \
    translations/ru.template.Aurora_notes-ch.ts \
    translations/ru.template.Aurora_notes-es.ts \
    translations/ru.template.Aurora_notes-fr.ts \
