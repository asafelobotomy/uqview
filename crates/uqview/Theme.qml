pragma Singleton
import QtQuick

// Every colour, radius and font the views use. On uQ these come from uQ's theme tokens (set by
// Main from backend.themeJson); elsewhere from the desktop's palette. No Kirigami: it would
// cost a viewer that should open instantly a noticeable part of its start-up.
QtObject {
    id: theme

    property var tokens: ({ present: false })
    readonly property bool uq: tokens.present === true
    readonly property SystemPalette pal: SystemPalette { colorGroup: SystemPalette.Active }

    function pick(key, fallback) {
        return uq && tokens.colors && tokens.colors[key] ? tokens.colors[key] : fallback;
    }
    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    readonly property color bg: pick("bg", pal.window)
    readonly property color surface: pick("surface", mix(pal.window, pal.windowText, 0.04))
    readonly property color surfaceAlt: pick("surface_alt", mix(pal.window, pal.windowText, 0.08))
    readonly property color overlay: pick("overlay", mix(pal.window, pal.windowText, 0.12))
    readonly property color text: pick("text", pal.windowText)
    readonly property color textMuted: pick("text_muted", mix(pal.window, pal.windowText, 0.6))
    readonly property color accent: pick("accent", pal.highlight)
    readonly property color accentText: pick("accent_text", pal.highlightedText)
    readonly property color border: pick("border", mix(pal.window, pal.windowText, 0.2))
    readonly property color success: pick("success", "#3fb950")
    readonly property color warning: pick("warning", "#d29922")
    readonly property color error: pick("error", "#f85149")
    readonly property bool dark: bg.hslLightness < 0.5

    readonly property int radius: uq && tokens.radius ? tokens.radius : 8
    readonly property string fontUi: uq && tokens.fontUi ? tokens.fontUi : Qt.application.font.family
    readonly property real bodySize: uq && tokens.fontSize ? tokens.fontSize : Qt.application.font.pointSize
    readonly property real smallSize: Math.max(7, bodySize - 1)
    readonly property int gap: 8
    readonly property int barHeight: 48

    // Motion: the same speeds and curves as uQ's shell (uQ shell/core/Motion.qml), so the
    // app's hovers, fades and slides move like the desktop's. Use these, not literal ms.
    // Hover, press and focus feedback; things going away.
    readonly property int motionFast: 100
    // Moves, slides, toasts and things coming in.
    readonly property int motionBase: 140
    // Large surfaces: a whole page or panel.
    readonly property int motionSlow: 220
    // Arriving or moving things start quick and settle.
    readonly property int easing: Easing.OutCubic
}
