#!/bin/sh
# Installs everything uqview ships into DESTDIR (default /): the program, the desktop entry and
# icon, and the uQ Settings page. Used by the PKGBUILD; also handy for a manual install:
#   cargo build --release --workspace && sudo scripts/install-files.sh
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
d=${DESTDIR:-}
install -Dm755 "$here/target/release/uqview" "$d/usr/bin/uqview"
install -Dm644 "$here/packaging/desktop/io.github.asafelobotomy.uqview.desktop" \
    "$d/usr/share/applications/io.github.asafelobotomy.uqview.desktop"
install -Dm644 "$here/packaging/desktop/io.github.asafelobotomy.uqview.metainfo.xml" \
    "$d/usr/share/metainfo/io.github.asafelobotomy.uqview.metainfo.xml"
install -Dm644 "$here/packaging/desktop/uqview.svg" "$d/usr/share/icons/hicolor/scalable/apps/uqview.svg"
install -Dm644 -t "$d/usr/share/uq/settings/pages/uqview/" "$here"/uq/pages/uqview/*.qml \
    "$here/uq/pages/uqview/logic.js" "$here/uq/pages/uqview/page.toml"
# uqview's problem codes, for uqctl explain and uQ Settings' Problems page.
install -Dm644 "$here/uq/diag/uqview.toml" "$d/usr/share/uq/diag/uqview.toml"
install -Dm644 "$here/LICENSE" "$d/usr/share/licenses/uqview/LICENSE"
