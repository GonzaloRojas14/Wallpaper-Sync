#!/usr/bin/env bash
# Compila el motor y deja todo listo. Es idempotente.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "·· compilando WallpaperEngine…"
/usr/bin/swiftc -O -whole-module-optimization \
  -framework Cocoa -framework AVFoundation -framework AVKit -framework IOKit \
  -o "$ROOT/app/WallpaperEngine" "$ROOT/app/WallpaperEngine.swift"

echo "·· compilando WallpaperMenu (HUD)…"
/usr/bin/swiftc -O -whole-module-optimization \
  -framework Cocoa -framework AVFoundation -framework QuartzCore \
  -o "$ROOT/app/WallpaperMenu" "$ROOT/app/MenuApp.swift" "$ROOT/app/Localization.swift"

# Catálogos de idioma junto al binario: corriendo suelto desde el repo,
# Bundle.main resuelve los .lproj que estén al lado del ejecutable.
echo "·· copiando catálogos de idioma…"
rm -rf "$ROOT"/app/*.lproj
cp -R "$ROOT"/resources/*.lproj "$ROOT/app/"

# Sincronizar artefactos al .app empaquetado del repo
if [ -d "$ROOT/Wallpaper Sync.app" ]; then
  cp -f "$ROOT/app/WallpaperEngine" "$ROOT/Wallpaper Sync.app/Contents/Resources/app/WallpaperEngine"
  cp -f "$ROOT/app/WallpaperMenu"   "$ROOT/Wallpaper Sync.app/Contents/MacOS/WallpaperMenu"
  cp -f "$ROOT/app/Info.plist"      "$ROOT/Wallpaper Sync.app/Contents/Info.plist"
  cp -f "$ROOT/bin/wallpaper"       "$ROOT/Wallpaper Sync.app/Contents/Resources/bin/wallpaper"
  cp -f "$ROOT/bin/_set_lockscreen_video.py" "$ROOT/Wallpaper Sync.app/Contents/Resources/bin/_set_lockscreen_video.py"

  # Los .lproj van en Resources (los lee el HUD) y los catálogos de la CLI
  # junto al script que los sourcea.
  rm -rf "$ROOT/Wallpaper Sync.app/Contents/Resources"/*.lproj
  cp -R "$ROOT"/resources/*.lproj "$ROOT/Wallpaper Sync.app/Contents/Resources/"
  rm -rf "$ROOT/Wallpaper Sync.app/Contents/Resources/bin/i18n"
  cp -R "$ROOT/bin/i18n"            "$ROOT/Wallpaper Sync.app/Contents/Resources/bin/i18n"
fi

chmod +x "$ROOT/bin/wallpaper"

if [ ! -f "$ROOT/config.json" ]; then
  cat > "$ROOT/config.json" <<JSON
{
  "fill": "fill",
  "language": "",
  "pauseOnBattery": false,
  "pauseOnLowPower": false,
  "video": ""
}
JSON
fi

echo ""
echo "listo. Para usar desde cualquier terminal, agregá esta línea a tu shell:"
echo "  export PATH=\"$ROOT/bin:\$PATH\""
echo ""
echo "Comandos rápidos:"
echo "  wallpaper set library/sample_4k.mp4   # activar el ejemplo 4K"
echo "  wallpaper enable                       # autoarranque al iniciar sesión"
echo "  wallpaper status"
