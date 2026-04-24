#!/usr/bin/env bash
# Compila el motor y deja todo listo. Es idempotente.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "·· compilando WallpaperEngine…"
/usr/bin/swiftc -O -whole-module-optimization \
  -framework Cocoa -framework AVFoundation -framework AVKit -framework IOKit \
  -o "$ROOT/app/WallpaperEngine" "$ROOT/app/WallpaperEngine.swift"

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
