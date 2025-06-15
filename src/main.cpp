// main.cpp
#include <auroraapp.h>
#include <QtQuick>
#include "filemanager.h" // Включаем наш новый класс FileManager

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> application(Aurora::Application::application(argc, argv));
    application->setOrganizationName(QStringLiteral("ru.template"));
    application->setApplicationName(QStringLiteral("Aurora_notes"));

    QScopedPointer<QQuickView> view(Aurora::Application::createView());

    // Создаем экземпляр FileManager
    FileManager fileManager;
    // Делаем его доступным в QML под именем "fileManager"
    view->rootContext()->setContextProperty(QStringLiteral("fileManager"), &fileManager);
    qDebug() << "fileManager зарегистрирован в QML-контексте.";
    view->setSource(Aurora::Application::pathTo(QStringLiteral("qml/Aurora_notes.qml")));
    view->show();

    return application->exec();
}
