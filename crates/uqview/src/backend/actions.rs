//! The `Backend`'s actions on a picture: trash and undo, copy, set as wallpaper, info, save a
//! mark-up, change a setting, show in folder. The bridge and the list of pictures are in
//! `backend.rs`.

use std::path::Path;
use std::pin::Pin;
use std::process::{Command, Stdio};

use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::QString;
use serde_json::json;
use uqview_core::config::{self, MarkupSave};
use uqview_core::trash::{self, TrashError};
use uqview_core::{folder, markup, wallpaper};

use super::qobject::Backend;
use super::{display_name, encode, path_of};
use crate::app::ffi;

impl Backend {
    pub(crate) fn trash(mut self: Pin<&mut Self>, path: &QString) {
        let p = path_of(path);
        let name = display_name(&p);
        match trash::trash(&p) {
            Ok(t) => {
                self.as_mut().rust_mut().last_trashed = Some(t);
                self.as_mut().set_can_undo(true);
                self.as_mut().drop_file(&p);
                self.as_mut().notice(
                    QString::from("trashed"),
                    QString::from(&format!("Moved {name} to the trash")),
                );
            }
            Err(TrashError::OtherDrive) => {
                // The drive's own trash: `gio trash` knows where it is. No undo from here.
                let ok = Command::new("gio")
                    .args(["trash", "--"])
                    .arg(&p)
                    .stdin(Stdio::null())
                    .stdout(Stdio::null())
                    .stderr(Stdio::null())
                    .status()
                    .is_ok_and(|s| s.success());
                if ok {
                    self.as_mut().rust_mut().last_trashed = None;
                    self.as_mut().set_can_undo(false);
                    self.as_mut().drop_file(&p);
                    self.as_mut().notice(
                        QString::from("ok"),
                        QString::from(&format!("Moved {name} to the trash")),
                    );
                } else {
                    self.as_mut().notice(
                        QString::from("error"),
                        QString::from(&format!("Couldn't move {name} to the trash")),
                    );
                }
            }
            Err(e) => self.as_mut().notice(
                QString::from("error"),
                QString::from(&format!("Couldn't move {name} to the trash: {e}")),
            ),
        }
    }

    pub(crate) fn drop_file(mut self: Pin<&mut Self>, p: &Path) {
        let mut files = self.files.clone();
        let Some(i) = files.iter().position(|f| f == p) else {
            return;
        };
        files.remove(i);
        let index = i.min(files.len().saturating_sub(1));
        self.as_mut().publish(files, index);
    }

    pub(crate) fn undo(mut self: Pin<&mut Self>) {
        let Some(t) = self.as_mut().rust_mut().last_trashed.take() else {
            return;
        };
        self.as_mut().set_can_undo(false);
        match trash::restore(&t) {
            Ok(()) => {
                let (sort, desc) = (self.config.sort, self.config.sort_descending);
                let (files, index) = folder::around(&t.original, &self.exts, sort, desc);
                self.as_mut().publish(files, index);
                self.as_mut().notice(
                    QString::from("ok"),
                    QString::from(&format!("Put {} back", display_name(&t.original))),
                );
            }
            Err(e) => self.as_mut().notice(
                QString::from("error"),
                QString::from(&format!("Couldn't put it back: {e}")),
            ),
        }
    }

    pub(crate) fn copy_image(mut self: Pin<&mut Self>, path: &QString) -> bool {
        let ok = ffi::uqview_copy_image(&path.to_string());
        let (kind, text) = if ok {
            ("ok", "Copied to the clipboard")
        } else {
            ("error", "Couldn't copy the picture")
        };
        self.as_mut()
            .notice(QString::from(kind), QString::from(text));
        ok
    }

    pub(crate) fn set_wallpaper(self: Pin<&mut Self>, path: &QString) {
        let p = path_of(path);
        let qt = self.qt_thread();
        std::thread::spawn(move || {
            let (kind, text) = match wallpaper::uqctl() {
                None => (
                    "error".to_string(),
                    "Setting the wallpaper needs uQ".to_string(),
                ),
                Some(uqctl) => {
                    let argv = wallpaper::command(&uqctl, &p);
                    match Command::new(&argv[0])
                        .args(&argv[1..])
                        .stdin(Stdio::null())
                        .output()
                    {
                        Ok(o) if o.status.success() => ("ok".into(), "Set as the wallpaper".into()),
                        Ok(o) => {
                            let err = String::from_utf8_lossy(&o.stderr);
                            let err = err.lines().last().unwrap_or("").trim();
                            let why = if err.contains("unrecognized subcommand") {
                                "this needs a newer uQ".to_string()
                            } else if err.is_empty() {
                                "uqctl failed".to_string()
                            } else {
                                err.trim_start_matches("error: ").to_string()
                            };
                            ("error".into(), format!("Couldn't set the wallpaper: {why}"))
                        }
                        Err(e) => ("error".into(), format!("Couldn't set the wallpaper: {e}")),
                    }
                }
            };
            let _ = qt.queue(move |mut b| {
                b.as_mut()
                    .notice(QString::from(&kind), QString::from(&text))
            });
        });
    }

    pub(crate) fn info(&self, path: &QString) -> QString {
        let p = path_of(path);
        let mut v: serde_json::Value =
            serde_json::from_str(&ffi::uqview_image_info(&p.to_string_lossy()))
                .unwrap_or_else(|_| json!({}));
        if let Ok(meta) = std::fs::metadata(&p) {
            v["size"] = json!(folder::human_size(meta.len()));
            if let Ok(m) = meta.modified()
                && let Ok(d) = m.duration_since(std::time::UNIX_EPOCH)
            {
                v["modified"] = json!(d.as_millis() as u64);
            }
        }
        v["name"] = json!(display_name(&p));
        v["folder"] = json!(p.parent().map(|d| d.to_string_lossy().into_owned()));
        QString::from(&v.to_string())
    }

    pub(crate) fn save_markup(
        mut self: Pin<&mut Self>,
        src: &QString,
        marks: &QString,
        mode: &QString,
    ) -> QString {
        let src_path = path_of(src);
        let mode = mode.to_string();
        let mode = match mode.as_str() {
            "save" => match self.config.markup_save {
                MarkupSave::Copy => "copy",
                MarkupSave::Overwrite => "overwrite",
            },
            m => m,
        };
        let dst = match mode {
            "copy" => Some(markup::copy_path(&src_path)),
            "overwrite" => Some(src_path.clone()),
            "clipboard" => None,
            _ => return QString::from(&json!({"ok": false, "error": "unknown mode"}).to_string()),
        };
        let dst_s = dst
            .as_ref()
            .map(|d| d.to_string_lossy().into_owned())
            .unwrap_or_default();
        let err = ffi::uqview_render_markup(
            &src_path.to_string_lossy(),
            &marks.to_string(),
            &dst_s,
            dst.is_none(),
        );
        if !err.is_empty() {
            return QString::from(&json!({"ok": false, "error": err}).to_string());
        }
        if let Some(d) = &dst {
            // Show the saved picture next.
            let (sort, desc) = (self.config.sort, self.config.sort_descending);
            let (files, index) = folder::around(d, &self.exts, sort, desc);
            self.as_mut().publish(files, index);
        }
        QString::from(&json!({"ok": true, "path": dst_s}).to_string())
    }

    pub(crate) fn config_set(mut self: Pin<&mut Self>, key: &QString, value: &QString) -> bool {
        let Some(path) = config::path() else {
            return false;
        };
        let mut c = self.config.clone();
        if c.set(&key.to_string(), &value.to_string()).is_err() || c.save(&path).is_err() {
            return false;
        }
        let resort = c.sort != self.config.sort || c.sort_descending != self.config.sort_descending;
        self.as_mut()
            .set_config_json(QString::from(&c.to_json().to_string()));
        self.as_mut().rust_mut().config = c;
        if resort && let Some(cur) = self.current() {
            let (sort, desc) = (self.config.sort, self.config.sort_descending);
            let (files, index) = folder::around(&cur, &self.exts, sort, desc);
            self.as_mut().publish(files, index);
        }
        true
    }

    pub(crate) fn show_in_folder(&self, path: &QString) {
        let p = path_of(path);
        let uri = format!("file://{}", encode(&p.to_string_lossy()));
        // The file manager's ShowItems selects the file; without one, open the folder.
        let shown = Command::new("dbus-send")
            .args([
                "--session",
                "--print-reply",
                "--dest=org.freedesktop.FileManager1",
                "/org/freedesktop/FileManager1",
                "org.freedesktop.FileManager1.ShowItems",
            ])
            .arg(format!("array:string:{uri}"))
            .arg("string:")
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .is_ok_and(|s| s.success());
        if !shown
            && let Some(dir) = p.parent()
            && let Ok(mut child) = Command::new("xdg-open")
                .arg(dir)
                .stdin(Stdio::null())
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .spawn()
        {
            std::thread::spawn(move || {
                let _ = child.wait();
            });
        }
    }
}
