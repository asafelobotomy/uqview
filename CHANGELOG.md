# Changelog

## 0.1.6 — 2026-11-22

- **uQview follows uQ's Reduce motion** and takes its look from uQ's shared theme base. `Theme.qml` is now `UqThemeBase` (vendored unchanged from uQ's `native/uq-consts`, uq-consts 1.0.0), with the desktop's own palette off uQ as before; inner corners use `radiusControl`.
- uq-theme 1.1.0 (reads `tokens.json`'s `motion`). CI checks every vendored kit and the problem codes with one script, `scripts/check-uq-native.sh`, from `uq/native.toml`; it replaces `check-uq-theme.sh`, `check-uq-diag.sh` and `check-diag-codes.sh`.

## 0.1.5 — 2026-11-22

- **uQview's problems show in uQ.** uQview uses uQ's shared uq-diag module (`crates/uqview/src/uq_diag.rs`, uq-diag 1.0.1): a panic leaves a crash record that uQ 0.3.35 lists on Settings › Problems with a report to copy, and a window that can't open logs `UQVIEW-001` in uQ's format, explained by `uqctl explain` and the Problems page from `/usr/share/uq/diag/uqview.toml`. CI checks the vendored copy and that the codes and the list agree.

## 0.1.4 — 2026-11-22

- **Moves like the desktop.** Hover and press colours fade in 100 ms instead of snapping, and fades, slides and toasts use uQ's shell speeds (100, 140 and 220 ms) with an ease-out curve instead of a mix of 70 to 250 ms and linear easing. The speeds are `Theme.motionFast`, `motionBase`, `motionSlow` and `Theme.easing`, matching uQ's `shell/core/Motion.qml`.

## 0.1.3

- Follows uQ's theme with a file watch instead of checking the file once a second (uQ's shared uq-theme module, `crates/uqview/src/uq_theme.rs`); it also catches uQ swapping the whole theme folder.
- AppStream metadata, so software centres show uQview.

## 0.1.2

**Tabs.** One uQview window per session: a picture opened while uQview is open (from the file
manager, uQ's screenshot preview, Open… or a drop) gets its own tab in that window and brings it
forward, instead of starting a second uQview. Each tab keeps its own folder, place and Mark up, so
marks in one tab stay as they are while you look at another; a dot on a tab marks unsaved marks.
A picture already open in a tab is shown there rather than opened twice. `Ctrl+W` closes a tab
(middle-click or × too), `Ctrl+Tab`/`Ctrl+Shift+Tab` or `Ctrl+PgDown`/`Ctrl+PgUp` switch, + opens
pictures in a new tab. The tab row shows once two or more tabs are open.

**Never lose marks.** Closing Mark up, a tab or the window with marks not yet saved asks *Save
your marks?* with Save (Enter), Discard and Cancel (Esc). Save saves as the settings say (a copy
by default) and then carries on closing.

Dialogs, menus and tooltips now use uQ's colours (they were drawn in the default light style).
`uqview --new-window` opens a separate window regardless.

## 0.1.1

Renamed from Qview to uQview: the command, the package, the desktop entry
(`io.github.asafelobotomy.uqview`), the settings file (`~/.config/uqview/config.toml`) and the
uQ Settings page are now `uqview`, because the AUR's `qview` is another app (qView).

## 0.1.0

First release: view, zoom and step through a folder; Mark up (pen, highlighter, arrow, line, box,
ellipse, text, numbers, pixelate, crop) saved as a copy, over the original or to the clipboard;
Set as wallpaper through uQ; copy; trash with undo; details; uQ theme; uQ Settings page.
