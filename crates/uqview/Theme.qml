pragma Singleton
import QtQuick

// Every colour, radius, font size and speed the views use: uQ's shared theme base
// (UqThemeBase.qml, vendored unchanged from uQ's native/uq-consts). On uQ it follows uQ's theme
// tokens (set by Main from backend.themeJson) and Reduce motion; elsewhere the colours are the
// desktop's palette. No Kirigami: it would cost a viewer that should open instantly a noticeable
// part of its start-up.
UqThemeBase {
    id: theme

    readonly property SystemPalette pal: SystemPalette { colorGroup: SystemPalette.Active }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    fallbackRadius: 8
    fallbackColors: ({
        bg: pal.window,
        surface: mix(pal.window, pal.windowText, 0.04),
        surface_alt: mix(pal.window, pal.windowText, 0.08),
        overlay: mix(pal.window, pal.windowText, 0.12),
        text: pal.windowText,
        text_muted: mix(pal.window, pal.windowText, 0.6),
        accent: pal.highlight,
        accent_text: pal.highlightedText,
        border: mix(pal.window, pal.windowText, 0.2),
        success: "#3fb950",
        warning: "#d29922",
        error: "#f85149",
    })

    readonly property int barHeight: 48
}
