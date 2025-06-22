/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /src/appsettings.cpp
 * Этот файл содержит реализацию класса AppSettings.
 * Он отвечает за логику загрузки и установки файлов перевода (.qm)
 * в зависимости от выбранного или системного языка. Класс также
 * обрабатывает сохранение и загрузку языковых настроек с помощью
 * QSettings, обеспечивая их персистентность между сессиями.
 * В случае отсутствия конкретного перевода, предусмотрен
 * механизм отката к базовому языку (английскому).
 */

#include "appsettings.h"
#include <QDebug>
#include <QSettings>
#include <QDir>
#include <QQmlContext>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QLocale>

#include <auroraapp.h>

AppSettings::AppSettings(QObject *parent)
    : QObject(parent), m_app(nullptr)
{
}

void AppSettings::loadInitialLanguage(QGuiApplication* app)
{
    m_app = app;
    QString langCode = loadLanguageSetting();
    if (langCode.isEmpty()) {
        langCode = QLocale::system().name().section('_', 0, 0);
    }

    setApplicationLanguage(langCode);
}

bool AppSettings::setApplicationLanguage(const QString& languageCode)
{
    if (!m_app) {
        qWarning() << "AppSettings not properly initialized. Cannot change language.";
        return false;
    }

    m_app->removeTranslator(&m_translator);
    QString baseTranslationDir = Aurora::Application::pathTo(QStringLiteral("translations")).toLocalFile();

    QString specificQmFile;
    if (languageCode == "ru") {
        specificQmFile = "ru.template.Aurora_notes-ru.qm";
    } else if (languageCode == "de") {
        specificQmFile = "ru.template.Aurora_notes-de.qm";
    } else if (languageCode == "ch") {
        specificQmFile = "ru.template.Aurora_notes-ch.qm";
    } else if (languageCode == "es") {
        specificQmFile = "ru.template.Aurora_notes-es.qm";
    } else if (languageCode == "fr") {
        specificQmFile = "ru.template.Aurora_notes-fr.qm";
    } else {
        specificQmFile = "ru.template.Aurora_notes-en.qm";
    }

    qDebug() << "Attempting to load translator for language:" << languageCode
             << "at path:" << baseTranslationDir << "with file:" << specificQmFile;

    if (m_translator.load(specificQmFile, baseTranslationDir)) {
        m_app->installTranslator(&m_translator);
        m_currentLanguage = languageCode;
        saveLanguageSetting(languageCode);
        emit currentLanguageChanged();
        qDebug() << "Language changed to:" << languageCode << "using" << specificQmFile;
        return true;
    } else {
        qWarning() << "Failed to load specific translator:" << specificQmFile
                   << "from" << baseTranslationDir;

        QString baseQmFile = "ru.template.Aurora_notes.qm";
        qDebug() << "Attempting to load base translator:" << baseQmFile;
        if (m_translator.load(baseQmFile, baseTranslationDir)) {
            m_app->installTranslator(&m_translator);
            m_currentLanguage = "en";
            saveLanguageSetting("en");
            emit currentLanguageChanged();
            qDebug() << "Language set to base (likely English) fallback using" << baseQmFile;
            return true;
        } else {
            qWarning() << "Could not load any translator, including base:" << baseQmFile;
            return false;
        }
    }
}

void AppSettings::saveLanguageSetting(const QString& languageCode)
{
    QSettings settings;
    settings.setValue("language", languageCode);
    qDebug() << "Language setting saved:" << languageCode;
}

QString AppSettings::loadLanguageSetting()
{
    QSettings settings;
    QString lang = settings.value("language", "").toString();
    qDebug() << "Language setting loaded:" << lang;
    return lang;
}
