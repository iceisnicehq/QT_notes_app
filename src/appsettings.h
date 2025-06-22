/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /src/appsettings.h
 * Этот файл определяет класс AppSettings, который управляет
 * настройками приложения, в частности, языком интерфейса.
 * Класс позволяет устанавливать и получать текущий язык,
 * загружать начальные языковые настройки при запуске и
 * сохранять выбор пользователя. Он использует QTranslator
 * для интеграции системы переводов Qt в приложение.
 */

#ifndef APPSETTINGS_H
#define APPSETTINGS_H
#include <QObject>
#include <QTranslator>
#include <QGuiApplication>
#include <QQmlApplicationEngine>

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
