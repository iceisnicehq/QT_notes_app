#include "appsettings.h"
#include <QDebug>
#include <QSettings>
#include <QDir>
#include <QQmlContext>
#include <auroraapp.h> // Still needed for Aurora::Application::pathTo if you use it elsewhere.

AppSettings::AppSettings(QObject *parent)
    : QObject(parent), m_app(nullptr) // m_view no longer a member
{
}

// Only takes QGuiApplication now
void AppSettings::loadInitialLanguage(QGuiApplication* app) // <--- CHANGED SIGNATURE
{
    m_app = app;
    // m_view is no longer stored
    QString langCode = loadLanguageSetting();
    if (langCode.isEmpty()) {
        langCode = QLocale::system().name().section('_', 0, 0);
    }

    setApplicationLanguage(langCode);
}

bool AppSettings::setApplicationLanguage(const QString& languageCode)
{
    if (!m_app) { // No longer checking m_view
        qWarning() << "AppSettings not properly initialized. Cannot change language.";
        return false;
    }

    m_app->removeTranslator(&m_translator);

    QString translationsPath = QDir(QCoreApplication::applicationDirPath()).filePath("translations");
    QString qmFile = QString("Aurora_notes-%1.qm").arg(languageCode);

    if (m_translator.load(qmFile, translationsPath)) {
        m_app->installTranslator(&m_translator);
        m_currentLanguage = languageCode;
        saveLanguageSetting(languageCode);
        emit currentLanguageChanged(); // This signal will trigger QML reload

        // --- REMOVED C++ setSource() CALLS ---
        // QString mainQmlPath = Aurora::Application::pathTo(QStringLiteral("qml/Aurora_notes.qml"));
        // m_view->setSource(QUrl());
        // m_view->setSource(QUrl::fromLocalFile(mainQmlPath));
        // --- END REMOVAL ---

        qDebug() << "Language changed to:" << languageCode;
        return true;
    } else {
        qWarning() << "Failed to load translator for language:" << languageCode << "from" << translationsPath << "/" << qmFile;

        if (languageCode != "en") {
            qDebug() << "Attempting to load English as fallback.";
            if (m_translator.load("Aurora_notes-en.qm", translationsPath)) {
                m_app->installTranslator(&m_translator);
                m_currentLanguage = "en";
                saveLanguageSetting("en");
                emit currentLanguageChanged(); // This signal will trigger QML reload

                // --- REMOVED C++ setSource() CALLS (fallback) ---
                // QString mainQmlPath = Aurora::Application::pathTo(QStringLiteral("qml/Aurora_notes.qml"));
                // m_view->setSource(QUrl());
                // m_view->setSource(QUrl::fromLocalFile(mainQmlPath));
                // --- END REMOVAL ---

                qDebug() << "Language set to English (fallback).";
                return true;
            }
        }
        qWarning() << "Could not load any translator.";
        return false;
    }
}

// ... (saveLanguageSetting and loadLanguageSetting methods remain the same) ...
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
