# Wallpaper Sync CLI — English (development language)
#
# Every message is a MSG_<key> variable consumed by t() in bin/wallpaper.
# Values are printf formats: %s marks a runtime argument, in order.
#
# This catalog is sourced first, always, so any key a translation omits falls
# back to the English text below. Keep it complete. See docs/TRANSLATING.md.
#
# shellcheck shell=bash disable=SC2034

# ── Conversion ────────────────────────────────────────────────────────
MSG_need_ffmpeg="ffmpeg is not installed (brew install ffmpeg)"
MSG_already_hevc="already HEVC, remuxing to .mov…"
MSG_already_hevc_mov="already an HEVC .mov, copying as-is…"
MSG_encoding="encoding to HEVC (hardware)…"
MSG_encoded_ok="✓ encoded with HEVC VideoToolbox"
MSG_encode_fallback="falling back to software x265…"
MSG_unsupported_format="unsupported format: %s"

# ── Engine ────────────────────────────────────────────────────────────
MSG_syncing_lockscreen="syncing lock screen…"
MSG_binary_missing="binary not found: %s"
MSG_no_active="no active wallpaper. Use: wallpaper use <name>"
MSG_already_running="already running (pid %s)"
MSG_start_failed="failed to start (see %s)"
MSG_started="started (pid %s)"
MSG_stopped="stopped"

# ── Library ───────────────────────────────────────────────────────────
MSG_usage_add="usage: wallpaper add <file>"
MSG_usage_use="usage: wallpaper use <name>"
MSG_usage_set="usage: wallpaper set <file>"
MSG_usage_remove="usage: wallpaper remove <name>"
MSG_not_found="does not exist: %s"
MSG_not_in_library="not in your library: %s (see 'wallpaper list')"
MSG_added="added: %s"
MSG_removed="removed: %s"
MSG_active_now="active wallpaper: %s"
MSG_library_empty="(library empty)"
MSG_library_empty_hint="(library empty — use 'wallpaper set <file>' to add one)"

# ── Status ────────────────────────────────────────────────────────────
# Keys on the left of the colon are literal config fields and stay untranslated;
# these two lines carry the only prose. Pad them to keep the column aligned.
MSG_state_running="state:           RUNNING (pid %s)"
MSG_state_stopped="state:           stopped"
MSG_autostart_yes="autostart:       yes"
MSG_autostart_no="autostart:       no"

# ── Settings ──────────────────────────────────────────────────────────
MSG_fill_set="fill=%s"
MSG_usage_fill="usage: wallpaper fill <fill|fit|stretch>"
MSG_battery_pause="pause on battery: %s"
MSG_usage_battery="usage: wallpaper battery <on|off>"
MSG_lowpower_pause="pause on low power: %s"
MSG_usage_lowpower="usage: wallpaper lowpower <on|off>"
MSG_powersave_set="power saving (still frame): %s"
MSG_usage_powersave="usage: wallpaper powersave <on|off>"

# ── Autostart ─────────────────────────────────────────────────────────
MSG_autostart_installed="autostart installed"
MSG_autostart_removed="autostart removed"
MSG_autostart_absent="autostart was not installed"

# ── Misc ──────────────────────────────────────────────────────────────
MSG_no_logs="(no logs)"
MSG_sanity="sanity check: small 320x180 window, closes itself after 8s"

MSG_usage="wallpaper — animated wallpaper engine for macOS

USAGE:
  wallpaper set <file>          Convert to HEVC and activate as wallpaper
  wallpaper use <name>          Activate a wallpaper from the library (instant)
  wallpaper add <file>          Add to the library without activating
  wallpaper list                List the library (▶ = active)
  wallpaper remove <name>       Remove from the library
  wallpaper start | stop | restart
  wallpaper status              Show state and configuration
  wallpaper logs [N]            Last N lines of the log
  wallpaper test                Visual sanity check
  wallpaper lockscreen          Sync the lock screen manually
  wallpaper lockscreen-restore  Restore the original aerial
  wallpaper lockscreen-status   Show lock screen state
  wallpaper fill <fill|fit|stretch>
  wallpaper battery <on|off>
  wallpaper lowpower <on|off>
  wallpaper powersave <on|off>  Show a still frame to save power
  wallpaper enable              Start automatically at login
  wallpaper disable             Stop starting automatically

Language follows macOS, or the \"language\" key in config.json.
Override for one command with WALLPAPER_LANG=<code>."
