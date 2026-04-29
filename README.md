# 🎬 Wallpaper Sync

Animated wallpaper engine for macOS Sonoma & Sequoia. Sets the same video as both your **desktop background** and **lock screen** simultaneously.

[![macOS](https://img.shields.io/badge/macOS-Sonoma%20%7C%20Sequoia%20%7C%20Tahoe-blue)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](#)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Donate](https://img.shields.io/badge/donar-ceneka-ff5f5f)](https://ceneka.net/gonza_007)
[![Instagram](https://img.shields.io/badge/Instagram-%40gonza._007-E4405F?logo=instagram&logoColor=white)](https://instagram.com/gonza._007)

> Hecho por **Gonzalo Rojas** ([@gonza._007](https://instagram.com/gonza._007)). Si te resulta útil y querés invitarme un café: **[ceneka.net/gonza_007](https://ceneka.net/gonza_007)** ☕

## Features

- 🖥️ **Animated desktop wallpaper** — Video plays behind your icons and windows
- 🔒 **Lock screen sync** — Same video on your lock/login screen automatically
- ⚡ **Instant switching** — Change wallpapers in < 1 second (HEVC optimized)
- 🔋 **Battery smart** — Auto-pause on battery to save power
- 🎨 **Beautiful GUI** — Dark-themed gallery with video thumbnails
- 📦 **Menu bar app** — Runs silently in the background, no dock clutter
- 🛠️ **Auto-setup** — Installs ffmpeg dependency automatically if needed

## Installation

### Download
1. Download the latest `WallpaperSync-X.Y.dmg` from [Releases](https://github.com/GonzaloRojas14/Wallpaper-Sync/releases)
2. Open the DMG and drag **Wallpaper Sync** to Applications
3. Right-click → **Open** (first time only, since the app is not notarized — no tengo Apple Developer ID, así que macOS te muestra el aviso de "developer no identificado")

### First-time Setup
1. The app will offer to install `ffmpeg` if not already present
2. Open **System Settings → Wallpaper** and download an animated wallpaper (e.g., "Tahoe Day")
3. Make sure **"Show as Screen Saver"** is enabled
4. That's it! Import your videos and pick your wallpaper

### Build from Source
```bash
# Clone
git clone https://github.com/GonzaloRojas14/Wallpaper-Sync.git
cd Wallpaper-Sync

# Install dependency
brew install ffmpeg

# Build
./install.sh

# Run
bin/wallpaper set your-video.mp4
```

## Usage

### GUI
Click the 🎬 icon in the menu bar to open the wallpaper gallery. Click any thumbnail to activate it.

### CLI
```bash
wallpaper set <file>          # Import + activate a video
wallpaper use <name>          # Switch to a library wallpaper (instant)
wallpaper list                # List library (▶ = active)
wallpaper add <file>          # Import without activating
wallpaper remove <name>       # Delete from library
wallpaper start | stop        # Control the engine
wallpaper battery on|off      # Auto-pause on battery
wallpaper status              # Show current config
```

## How It Works

```
┌─────────────────────────────────────────────────────┐
│  Your Video (.mp4/.mov/.gif)                        │
│       │                                             │
│       ▼                                             │
│  ffmpeg → HEVC .mov (one-time conversion)           │
│       │                                             │
│       ├──→ WallpaperEngine.swift (desktop window)   │
│       │    └─ AVPlayer behind desktop icons         │
│       │                                             │
│       └──→ Aerial slot replacement (lock screen)    │
│            └─ Atomic copy to system aerial file     │
│            └─ Index.plist selectedID update          │
│            └─ killall WallpaperAerialsExtension      │
└─────────────────────────────────────────────────────┘
```

### Architecture
- **WallpaperEngine** (Swift) — Renders video in a borderless window at `desktopIconLevel - 1`
- **MenuApp** (Swift) — Menu bar GUI with wallpaper gallery, import, and engine control
- **bin/wallpaper** (Bash) — CLI tool for all operations
- **_set_lockscreen_video.py** (Python) — Manages the macOS aerial file replacement

### Key Design Decisions
- **Single HEVC format** — Videos are converted once on import. Both desktop and lock screen use the same `.mov` file.
- **No cache needed** — Since conversion happens at import time, switching is just a file copy (~0.1s).
- **Hot-reload** — The engine watches `config.json` every 0.5s and swaps videos without restarting.
- **Sleep/wake safe** — Windows hide on sleep, aerial extension refreshes on unlock.

## Requirements

- macOS Sonoma (14) or Sequoia (15)
- [ffmpeg](https://formulae.brew.sh/formula/ffmpeg) (installed automatically by the app, or manually via `brew install ffmpeg`)
- One downloaded Aerial wallpaper in System Settings (e.g., "Tahoe Day")

## Performance

| Metric | Value |
|--------|-------|
| CPU | ~4% average |
| RAM | ~88 MB total |
| GPU | ~22% (4K HEVC hardware decode) |
| Battery impact | ~35% more drain vs static wallpaper |

> **Tip:** Enable `wallpaper battery on` to auto-pause when unplugged.

## Author

**Gonzalo Rojas**
- 📷 Instagram: [@gonza._007](https://instagram.com/gonza._007)
- ☕ Donaciones: [ceneka.net/gonza_007](https://ceneka.net/gonza_007)
- 🐙 GitHub: [@GonzaloRojas14](https://github.com/GonzaloRojas14)

Si Wallpaper Sync te ahorró tiempo o te gustó cómo quedó tu Mac, considerá invitarme un café — el desarrollo es 100% en tiempo libre y cualquier aporte motiva a seguir mejorándolo.

## License

MIT — © 2026 Gonzalo Rojas. Ver [LICENSE](LICENSE).
