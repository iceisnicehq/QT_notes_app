/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /src/main.cpp
 * Это главный файл приложения, точка входа в программу.
 * Он инициализирует приложение Aurora, создает основной
 * QQuickView и экземпляр класса AppSettings для управления
 * настройками. AppSettings регистрируется как контекстное
 * свойство в QML, что позволяет вызывать его функции из
 * интерфейса. После инициализации языка загружается
 * главный QML-файл и отображается окно приложения.
 */

#include <auroraapp.h>
#include <QtQuick>
#include <QTranslator>
#include <QLocale>
#include <QSettings>
#include <QQmlApplicationEngine>
#include <QQuickView>

#include "appsettings.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> application(Aurora::Application::application(argc, argv));
    application->setOrganizationName(QStringLiteral("ru.template"));
    application->setApplicationName(QStringLiteral("Aurora_notes"));

    QScopedPointer<QQuickView> view(Aurora::Application::createView());

    AppSettings appSettings; // Create instance

    if (view->engine()) {
        view->engine()->rootContext()->setContextProperty("AppSettings", &appSettings);
    } else {
        qWarning() << "QQmlApplicationEngine not found for the view. Cannot set AppSettings context property.";
    }

    appSettings.loadInitialLanguage(application.data());

    view->setSource(Aurora::Application::pathTo(QStringLiteral("qml/Aurora_notes.qml")));
    view->show();

    return application->exec();
}
