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
  -o "$ROOT/app/WallpaperMenu" "$ROOT/app/MenuApp.swift"

# Sincronizar artefactos al .app empaquetado del repo
if [ -d "$ROOT/Wallpaper Sync.app" ]; then
  cp -f "$ROOT/app/WallpaperEngine" "$ROOT/Wallpaper Sync.app/Contents/Resources/app/WallpaperEngine"
  cp -f "$ROOT/app/WallpaperMenu"   "$ROOT/Wallpaper Sync.app/Contents/MacOS/WallpaperMenu"
  cp -f "$ROOT/app/Info.plist"      "$ROOT/Wallpaper Sync.app/Contents/Info.plist"
  cp -f "$ROOT/bin/wallpaper"       "$ROOT/Wallpaper Sync.app/Contents/Resources/bin/wallpaper"
  cp -f "$ROOT/bin/_set_lockscreen_video.py" "$ROOT/Wallpaper Sync.app/Contents/Resources/bin/_set_lockscreen_video.py"
fi

chmod +x "$ROOT/bin/wallpaper"

if [ ! -f "$ROOT/config.json" ]; then
  cat > "$ROOT/config.json" <<JSON
{
  "video": "",
  "fill": "fill",
  "pauseOnBattery": false,
  "pauseOnLowPower": false
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
