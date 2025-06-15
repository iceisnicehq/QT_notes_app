#include <auroraapp.h>
#include <QtQuick>
#include <QTranslator>
#include <QLocale>
#include <QSettings>
#include <QQmlApplicationEngine>
#include <QQuickView> // Keep this for createView() return type, even if we avoid explicit declaration

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

    // Pass only the application to loadInitialLanguage, as the view will be handled in QML
    appSettings.loadInitialLanguage(application.data()); // <--- CHANGED CALL

    // Load your main QML file that will contain the Loader
    view->setSource(Aurora::Application::pathTo(QStringLiteral("qml/Aurora_notes.qml")));
    view->show();

    return application->exec();
}
