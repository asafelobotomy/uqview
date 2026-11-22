use cxx_qt_build::{CxxQtBuilder, QmlFile, QmlModule};

fn main() {
    let files = [
        "qml/Main.qml",
        "qml/Tab.qml",
        "qml/TabStrip.qml",
        "qml/AppView.qml",
        "qml/Viewer.qml",
        "qml/Markup.qml",
        "qml/Strip.qml",
        "qml/InfoPanel.qml",
        "qml/Toast.qml",
        "qml/IconButton.qml",
        "qml/logic.js",
    ];
    let mut module = QmlModule::new("org.uqview.app").qml_files(files.map(QmlFile::from));
    module = module.qml_files([QmlFile::from("Theme.qml").singleton(true), QmlFile::from("UqThemeBase.qml")]);
    CxxQtBuilder::new_qml_module(module)
        .qt_module("Gui")
        .qt_module("Quick")
        .qt_module("QuickControls2")
        .qt_module("Network")
        .files(["src/backend.rs", "src/app.rs"])
        .cpp_file("cpp/app.cpp")
        .cpp_file("cpp/paint.cpp")
        .cpp_file("cpp/markupcanvas.cpp")
        .cpp_file("cpp/markupcanvas.h")
        .cpp_file("cpp/instance.h")
        .build();
}
