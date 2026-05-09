#!/usr/bin/env bash
# Empaqueta Wallpaper Sync.app en un ZIP listo para distribuir.
# Uso: ./build-zip.sh [version]   (default: lee CFBundleShortVersionString)
#
# Distribuimos como ZIP en vez de DMG porque, sin Apple Developer ID + notarizacion,
# en Apple Silicon un DMG sale como "esta danado, no se puede abrir" y no monta.
# Un ZIP con app firmada ad-hoc solo dispara el aviso clasico de "desarrollador
# no identificado", que se destraba con click derecho -> Abrir, sin terminal.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

APP="$ROOT/Wallpaper Sync.app"
[ -d "$APP" ] || { echo "x no existe '$APP' - corre ./install.sh primero"; exit 1; }

VERSION="${1:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")}"
ZIP="$ROOT/WallpaperSync-${VERSION}.zip"

echo "·· limpiando atributos extendidos del .app…"
xattr -cr "$APP"

echo "·· re-firmando ad-hoc deep…"
codesign --remove-signature "$APP" 2>/dev/null || true
codesign --force --deep --sign - --options runtime --timestamp=none "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

echo "·· generando ZIP ($ZIP)…"
rm -f "$ZIP"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo "·· verificando integridad y firma roundtrip…"
unzip -tq "$ZIP" >/dev/null
TMP="$(mktemp -d -t wpsync-zip-verify)"
trap 'rm -rf "$TMP"' EXIT
/usr/bin/ditto -x -k "$ZIP" "$TMP"
codesign --verify --deep --strict "$TMP/Wallpaper Sync.app"

SIZE=$(du -h "$ZIP" | awk '{print $1}')
echo ""
echo "+ listo: $ZIP ($SIZE)"
echo ""
echo "Subi este .zip como release asset en GitHub."
