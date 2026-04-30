# Screenshots & demo assets

Drop the following files in this directory and they'll be picked up by the
main `README.md` (the hero `<img>` is currently in an HTML comment ready to
uncomment, and the **Screenshots** section below shows the expected file
names).

## Expected files

| File | What it shows | Recommended |
|---|---|---|
| `demo.gif` | 3–5 sec loop of a video playing as desktop background, then the lock screen showing the same video | ≤ 8 MB, 1280×800, 24 fps |
| `screenshot-hud.png` | Main HUD window with the wallpaper grid, ideally with several thumbnails and one active card | 2× resolution, ~1600 px wide |
| `screenshot-modal.png` | First-run setup overlay (the blurred modal that asks the user to download Tahoe Day) | 2× resolution |
| `screenshot-lockscreen.png` | Mac lock screen showing the active wallpaper (use Touch ID / Cmd+Ctrl+Q to lock, then capture from another device or wait + screencapture -i after a delay) | optional but very nice |

## How to capture

```bash
# HUD screenshot (interactive, lets you click the window):
screencapture -W -t png ~/Desktop/screenshot-hud.png

# Whole screen, PNG:
screencapture -t png ~/Desktop/full.png

# 5-second delayed capture of a specific area you select:
screencapture -T 5 -i -t png ~/Desktop/area.png
```

For the GIF: use **[Kap](https://getkap.co/)** (free, open source) — it
records a window, supports trimming, and exports lightweight `.gif` or
`.mp4`. Drop the `.gif` here as `demo.gif`.

## Once images are in place

Edit `README.md`:

1. Uncomment the `HERO IMAGE` block at the top (around line 14).
2. Add a new section above **Installation**:

```markdown
## Screenshots

<p align="center">
  <img src="docs/screenshot-hud.png" alt="Wallpaper Sync HUD" width="720"><br>
  <em>The main HUD with the wallpaper grid.</em>
</p>

<p align="center">
  <img src="docs/screenshot-modal.png" alt="First-run setup modal" width="500"><br>
  <em>First-run setup overlay.</em>
</p>
```

That's it.
