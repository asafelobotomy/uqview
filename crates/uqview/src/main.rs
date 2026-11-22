//! uqview: a fast picture viewer for uQ. Shows a picture and steps through its folder, zooms,
//! marks up (pen, highlighter, arrows, boxes, text, numbers, pixelate, crop), copies, sets the
//! wallpaper through uQ and moves pictures to the trash. On uQ it takes its colours from uQ's
//! theme tokens; elsewhere it follows the desktop palette.
//!
//! Exit codes: 0 normal, 2 bad command line or setting, 4 no window could be created.

use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QQuickStyle, QString, QUrl};
use uqview_core::args::{self, Cmd};
use uqview_core::config::{self, Config};
use uqview_core::defaults;

mod app;
mod backend;
mod theme;
#[allow(dead_code)] // vendored whole; this app uses part of it
#[rustfmt::skip]
mod uq_diag;
#[allow(dead_code)] // vendored whole; this app uses part of it
#[rustfmt::skip]
mod uq_theme;

fn main() {
    // uQ's log format and a crash record on a panic (uQ's native/uq-diag).
    uq_diag::init("uqview", "warn");
    // `--new-window`: skip handing the pictures to an open uQview.
    let mut new_window = false;
    let argv: Vec<String> = std::env::args()
        .skip(1)
        .filter(|a| {
            let nw = a == "--new-window";
            new_window |= nw;
            !nw
        })
        .collect();
    let cmd = match args::parse(argv) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("uqview: {e}\n\n{}", args::USAGE);
            std::process::exit(2);
        }
    };
    match cmd {
        Cmd::Version => println!("uqview {}", env!("CARGO_PKG_VERSION")),
        Cmd::Help => println!("{}", args::USAGE),
        Cmd::ConfigShow { json } => config_show(json),
        Cmd::ConfigSet { json, key, value } => config_set(json, &key, &value),
        Cmd::DefaultStatus { json } => default_status(json),
        Cmd::DefaultSet { json } => default_set(json),
        Cmd::View { paths, markup } => {
            let request = serde_json::json!({
                "paths": paths.iter().map(|p| uqview_core::folder::absolute(p).to_string_lossy().into_owned()).collect::<Vec<_>>(),
                "markup": markup,
            })
            .to_string();
            backend::set_start(paths, markup);
            window(if new_window { None } else { Some(request) });
        }
    }
}

fn config_show(json: bool) {
    let c = Config::load(config::path().as_deref());
    if json {
        println!("{}", c.to_json());
    } else {
        print!("{}", c.to_toml());
    }
}

fn config_set(json: bool, key: &str, value: &str) {
    let Some(path) = config::path() else {
        fail(json, "no home folder");
    };
    let mut c = Config::load(Some(&path));
    if let Err(e) = c.set(key, value).and_then(|()| c.save(&path)) {
        fail(json, &e.to_string());
    }
    if json {
        println!(
            "{}",
            serde_json::json!({ "ok": true, "config": c.to_json() })
        );
    }
}

/// What `xdg-mime` says opens `mime`, or "" when nothing does (or xdg-mime is missing).
fn query_default(mime: &str) -> String {
    std::process::Command::new("xdg-mime")
        .args(["query", "default", mime])
        .stdin(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default()
}

fn default_status(json: bool) {
    let (png, jpeg) = (query_default("image/png"), query_default("image/jpeg"));
    let is = defaults::is_default(&png, &jpeg);
    if json {
        println!("{}", serde_json::json!({ "default": is, "current": png }));
    } else if is {
        println!("uQview opens pictures.");
    } else if png.is_empty() {
        println!("No app is set to open pictures.");
    } else {
        println!("{png} opens pictures.");
    }
}

fn default_set(json: bool) {
    let argv = defaults::set_argv();
    let ok = std::process::Command::new(&argv[0])
        .args(&argv[1..])
        .stdin(std::process::Stdio::null())
        .status()
        .is_ok_and(|s| s.success());
    if !ok {
        fail(
            json,
            "xdg-mime couldn't set the default (is xdg-utils installed?)",
        );
    }
    if json {
        println!("{}", serde_json::json!({ "ok": true, "default": true }));
    } else {
        println!("Pictures now open in uQview.");
    }
}

fn fail(json: bool, msg: &str) -> ! {
    if json {
        println!("{}", serde_json::json!({ "ok": false, "error": msg }));
    }
    eprintln!("uqview: {msg}");
    std::process::exit(2);
}

fn window(forward: Option<String>) {
    // The "Basic" Qt Quick Controls style draws from the palette, which Theme sets per item.
    QQuickStyle::set_style(&QString::from("Basic"));
    let mut app = QGuiApplication::new();
    app::ffi::uqview_describe_application(env!("CARGO_PKG_VERSION"));
    // One window per session: a picture opened while uQview is open shows there, in a new tab.
    if forward.is_some_and(|r| app::ffi::uqview_forward_to_running(&r)) {
        return;
    }
    app::ffi::uqview_register_types();
    // Qt 6.4 doesn't search qrc:/qt/qml on its own (6.5 does); the app's module lives there.
    // SAFETY: no other thread exists yet.
    unsafe { std::env::set_var("QML_IMPORT_PATH", ":/qt/qml") };
    let mut engine = QQmlApplicationEngine::new();
    if let Some(engine) = engine.as_mut() {
        engine.load(&QUrl::from("qrc:/qt/qml/org/uqview/app/qml/Main.qml"));
    }
    if !app::ffi::uqview_has_window() {
        tracing::error!("[UQVIEW-001] the window couldn't be created (is Qt Quick installed?)");
        std::process::exit(4);
    }
    if let Some(app) = app.as_mut() {
        app.exec();
    }
}
