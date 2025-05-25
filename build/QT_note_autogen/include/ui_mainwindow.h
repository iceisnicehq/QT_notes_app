/********************************************************************************
** Form generated from reading UI file 'mainwindow.ui'
**
** Created by: Qt User Interface Compiler version 6.9.0
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_MAINWINDOW_H
#define UI_MAINWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QListWidget>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QSplitter>
#include <QtWidgets/QStatusBar>
#include <QtWidgets/QTextEdit>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_MainWindow
{
public:
    QWidget *centralwidget;
    QHBoxLayout *mainLayout;
    QSplitter *mainSplitter;
    QWidget *leftPanel;
    QVBoxLayout *leftLayout;
    QLabel *foldersLabel;
    QListWidget *foldersList;
    QLabel *tagsLabel;
    QListWidget *tagsList;
    QPushButton *settingsButton;
    QWidget *centerPanel;
    QVBoxLayout *centerLayout;
    QHBoxLayout *searchLayout;
    QLineEdit *searchEdit;
    QPushButton *addNoteButton;
    QPushButton *toggleLeftPanelButton;
    QListWidget *notesList;
    QWidget *rightPanel;
    QVBoxLayout *rightLayout;
    QHBoxLayout *noteHeaderLayout;
    QLabel *noteTitleLabel;
    QSpacerItem *headerSpacer;
    QLabel *editDateLabel;
    QPushButton *menuButton;
    QLineEdit *noteTitleEdit;
    QTextEdit *noteBodyEdit;
    QHBoxLayout *tagsLayout;
    QLabel *noteTagsLabel;
    QLineEdit *noteTagsEdit;
    QMenuBar *menubar;
    QStatusBar *statusbar;

    void setupUi(QMainWindow *MainWindow)
    {
        if (MainWindow->objectName().isEmpty())
            MainWindow->setObjectName("MainWindow");
        MainWindow->resize(1000, 700);
        centralwidget = new QWidget(MainWindow);
        centralwidget->setObjectName("centralwidget");
        mainLayout = new QHBoxLayout(centralwidget);
        mainLayout->setObjectName("mainLayout");
        mainSplitter = new QSplitter(centralwidget);
        mainSplitter->setObjectName("mainSplitter");
        mainSplitter->setOrientation(Qt::Horizontal);
        leftPanel = new QWidget(mainSplitter);
        leftPanel->setObjectName("leftPanel");
        leftLayout = new QVBoxLayout(leftPanel);
        leftLayout->setObjectName("leftLayout");
        leftLayout->setContentsMargins(0, 0, 0, 0);
        foldersLabel = new QLabel(leftPanel);
        foldersLabel->setObjectName("foldersLabel");

        leftLayout->addWidget(foldersLabel);

        foldersList = new QListWidget(leftPanel);
        foldersList->setObjectName("foldersList");

        leftLayout->addWidget(foldersList);

        tagsLabel = new QLabel(leftPanel);
        tagsLabel->setObjectName("tagsLabel");

        leftLayout->addWidget(tagsLabel);

        tagsList = new QListWidget(leftPanel);
        tagsList->setObjectName("tagsList");

        leftLayout->addWidget(tagsList);

        settingsButton = new QPushButton(leftPanel);
        settingsButton->setObjectName("settingsButton");

        leftLayout->addWidget(settingsButton);

        mainSplitter->addWidget(leftPanel);
        centerPanel = new QWidget(mainSplitter);
        centerPanel->setObjectName("centerPanel");
        centerLayout = new QVBoxLayout(centerPanel);
        centerLayout->setObjectName("centerLayout");
        centerLayout->setContentsMargins(0, 0, 0, 0);
        searchLayout = new QHBoxLayout();
        searchLayout->setObjectName("searchLayout");
        searchEdit = new QLineEdit(centerPanel);
        searchEdit->setObjectName("searchEdit");

        searchLayout->addWidget(searchEdit);

        addNoteButton = new QPushButton(centerPanel);
        addNoteButton->setObjectName("addNoteButton");

        searchLayout->addWidget(addNoteButton);

        toggleLeftPanelButton = new QPushButton(centerPanel);
        toggleLeftPanelButton->setObjectName("toggleLeftPanelButton");

        searchLayout->addWidget(toggleLeftPanelButton);


        centerLayout->addLayout(searchLayout);

        notesList = new QListWidget(centerPanel);
        notesList->setObjectName("notesList");

        centerLayout->addWidget(notesList);

        mainSplitter->addWidget(centerPanel);
        rightPanel = new QWidget(mainSplitter);
        rightPanel->setObjectName("rightPanel");
        rightLayout = new QVBoxLayout(rightPanel);
        rightLayout->setObjectName("rightLayout");
        rightLayout->setContentsMargins(0, 0, 0, 0);
        noteHeaderLayout = new QHBoxLayout();
        noteHeaderLayout->setObjectName("noteHeaderLayout");
        noteTitleLabel = new QLabel(rightPanel);
        noteTitleLabel->setObjectName("noteTitleLabel");

        noteHeaderLayout->addWidget(noteTitleLabel);

        headerSpacer = new QSpacerItem(40, 20, QSizePolicy::Policy::Expanding, QSizePolicy::Policy::Minimum);

        noteHeaderLayout->addItem(headerSpacer);

        editDateLabel = new QLabel(rightPanel);
        editDateLabel->setObjectName("editDateLabel");

        noteHeaderLayout->addWidget(editDateLabel);

        menuButton = new QPushButton(rightPanel);
        menuButton->setObjectName("menuButton");

        noteHeaderLayout->addWidget(menuButton);


        rightLayout->addLayout(noteHeaderLayout);

        noteTitleEdit = new QLineEdit(rightPanel);
        noteTitleEdit->setObjectName("noteTitleEdit");

        rightLayout->addWidget(noteTitleEdit);

        noteBodyEdit = new QTextEdit(rightPanel);
        noteBodyEdit->setObjectName("noteBodyEdit");

        rightLayout->addWidget(noteBodyEdit);

        tagsLayout = new QHBoxLayout();
        tagsLayout->setObjectName("tagsLayout");
        noteTagsLabel = new QLabel(rightPanel);
        noteTagsLabel->setObjectName("noteTagsLabel");

        tagsLayout->addWidget(noteTagsLabel);

        noteTagsEdit = new QLineEdit(rightPanel);
        noteTagsEdit->setObjectName("noteTagsEdit");

        tagsLayout->addWidget(noteTagsEdit);


        rightLayout->addLayout(tagsLayout);

        mainSplitter->addWidget(rightPanel);

        mainLayout->addWidget(mainSplitter);

        MainWindow->setCentralWidget(centralwidget);
        menubar = new QMenuBar(MainWindow);
        menubar->setObjectName("menubar");
        MainWindow->setMenuBar(menubar);
        statusbar = new QStatusBar(MainWindow);
        statusbar->setObjectName("statusbar");
        MainWindow->setStatusBar(statusbar);

        retranslateUi(MainWindow);

        QMetaObject::connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow *MainWindow)
    {
        MainWindow->setWindowTitle(QCoreApplication::translate("MainWindow", "Notes App", nullptr));
        foldersLabel->setText(QCoreApplication::translate("MainWindow", "\320\237\320\260\320\277\320\272\320\270", nullptr));
        tagsLabel->setText(QCoreApplication::translate("MainWindow", "\320\242\320\265\320\263\320\270", nullptr));
        settingsButton->setText(QCoreApplication::translate("MainWindow", "\342\232\231 \320\235\320\260\321\201\321\202\321\200\320\276\320\271\320\272\320\270", nullptr));
        searchEdit->setPlaceholderText(QCoreApplication::translate("MainWindow", "\320\237\320\276\320\270\321\201\320\272...", nullptr));
        addNoteButton->setText(QCoreApplication::translate("MainWindow", "\357\274\213", nullptr));
        toggleLeftPanelButton->setText(QCoreApplication::translate("MainWindow", "\342\256\234", nullptr));
        noteTitleLabel->setText(QCoreApplication::translate("MainWindow", "\320\235\320\260\320\267\320\262\320\260\320\275\320\270\320\265 \320\267\320\260\320\274\320\265\321\202\320\272\320\270", nullptr));
        editDateLabel->setText(QCoreApplication::translate("MainWindow", "\320\230\320\267\320\274\320\265\320\275\320\265\320\275\320\276: --.--.----", nullptr));
#if QT_CONFIG(tooltip)
        editDateLabel->setToolTip(QCoreApplication::translate("MainWindow", "\320\241\320\276\320\267\320\264\320\260\320\275\320\276: --.--.----", nullptr));
#endif // QT_CONFIG(tooltip)
        menuButton->setText(QCoreApplication::translate("MainWindow", "\342\213\256", nullptr));
        noteTitleEdit->setPlaceholderText(QCoreApplication::translate("MainWindow", "\320\222\320\262\320\265\320\264\320\270\321\202\320\265 \320\275\320\260\320\267\320\262\320\260\320\275\320\270\320\265...", nullptr));
        noteBodyEdit->setPlaceholderText(QCoreApplication::translate("MainWindow", "\320\242\320\265\320\272\321\201\321\202 \320\267\320\260\320\274\320\265\321\202\320\272\320\270...", nullptr));
        noteTagsLabel->setText(QCoreApplication::translate("MainWindow", "\320\242\320\265\320\263\320\270:", nullptr));
        noteTagsEdit->setPlaceholderText(QCoreApplication::translate("MainWindow", "\320\224\320\276\320\261\320\260\320\262\321\214\321\202\320\265 \321\202\320\265\320\263\320\270...", nullptr));
    } // retranslateUi

};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINWINDOW_H
