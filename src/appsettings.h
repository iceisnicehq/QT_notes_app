#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QTranslator>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
// #include <QQuickView>

class AppSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentLanguage READ currentLanguage NOTIFY currentLanguageChanged)

public:
    explicit AppSettings(QObject *parent = nullptr);
    void loadInitialLanguage(QGuiApplication* app);

    Q_INVOKABLE bool setApplicationLanguage(const QString& languageCode);
    QString currentLanguage() const { return m_currentLanguage; }

signals:
    void currentLanguageChanged();

private:
    QTranslator m_translator;
    QGuiApplication* m_app;
    QString m_currentLanguage;
    void saveLanguageSetting(const QString& languageCode);
    QString loadLanguageSetting();
};

#endif // APPSETTINGS_H
