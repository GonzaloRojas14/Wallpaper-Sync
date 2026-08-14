# Wallpaper Sync CLI — Deutsch
#
# Fehlende Schlüssel fallen automatisch auf Englisch zurück (bin/i18n/en.sh),
# das immer zuerst geladen wird. Siehe docs/TRANSLATING.md.
#
# Erstübersetzung, nicht von Muttersprachlern geprüft — Korrekturen willkommen.
#
# shellcheck shell=bash disable=SC2034

# ── Konvertierung ─────────────────────────────────────────────────────
MSG_need_ffmpeg="ffmpeg ist nicht installiert (brew install ffmpeg)"
MSG_already_hevc="bereits HEVC, wird als .mov neu verpackt…"
MSG_already_hevc_mov="bereits eine HEVC-.mov, wird direkt kopiert…"
MSG_encoding="wird zu HEVC codiert (Hardware)…"
MSG_encoded_ok="✓ mit HEVC VideoToolbox codiert"
MSG_encode_fallback="Rückfall auf Software-x265…"
MSG_unsupported_format="nicht unterstütztes Format: %s"

# ── Engine ────────────────────────────────────────────────────────────
MSG_syncing_lockscreen="Sperrbildschirm wird synchronisiert…"
MSG_binary_missing="Binärdatei nicht gefunden: %s"
MSG_no_active="kein aktives Hintergrundbild. Verwende: wallpaper use <Name>"
MSG_already_running="läuft bereits (pid %s)"
MSG_start_failed="Start fehlgeschlagen (siehe %s)"
MSG_started="gestartet (pid %s)"
MSG_stopped="gestoppt"

# ── Mediathek ─────────────────────────────────────────────────────────
MSG_usage_add="Verwendung: wallpaper add <Datei>"
MSG_usage_use="Verwendung: wallpaper use <Name>"
MSG_usage_set="Verwendung: wallpaper set <Datei>"
MSG_usage_remove="Verwendung: wallpaper remove <Name>"
MSG_not_found="existiert nicht: %s"
MSG_not_in_library="nicht in der Mediathek: %s (siehe 'wallpaper list')"
MSG_added="hinzugefügt: %s"
MSG_removed="entfernt: %s"
MSG_active_now="aktives Hintergrundbild: %s"
MSG_library_empty="(Mediathek leer)"
MSG_library_empty_hint="(Mediathek leer — mit 'wallpaper set <Datei>' eines hinzufügen)"

# ── Status ────────────────────────────────────────────────────────────
# Die Schlüssel links vom Doppelpunkt sind wörtliche Config-Felder und werden
# nicht übersetzt. Abstände beibehalten, damit die Spalte ausgerichtet bleibt.
MSG_state_running="Status:          LÄUFT (pid %s)"
MSG_state_stopped="Status:          gestoppt"
MSG_autostart_yes="Autostart:       ja"
MSG_autostart_no="Autostart:       nein"

# ── Einstellungen ─────────────────────────────────────────────────────
MSG_fill_set="fill=%s"
MSG_usage_fill="Verwendung: wallpaper fill <fill|fit|stretch>"
MSG_battery_pause="Pause im Batteriebetrieb: %s"
MSG_usage_battery="Verwendung: wallpaper battery <on|off>"
MSG_lowpower_pause="Pause im Stromsparmodus: %s"
MSG_usage_lowpower="Verwendung: wallpaper lowpower <on|off>"
MSG_powersave_set="Energiesparen (Standbild): %s"
MSG_usage_powersave="Verwendung: wallpaper powersave <on|off>"

# ── Autostart ─────────────────────────────────────────────────────────
MSG_autostart_installed="Autostart eingerichtet"
MSG_autostart_removed="Autostart entfernt"
MSG_autostart_absent="Autostart war nicht eingerichtet"

# ── Sonstiges ─────────────────────────────────────────────────────────
MSG_no_logs="(keine Protokolle)"
MSG_sanity="Sichtprüfung: kleines 320x180-Fenster, schließt sich nach 8 s"

MSG_usage="wallpaper — Engine für animierte Hintergrundbilder unter macOS

VERWENDUNG:
  wallpaper set <Datei>         In HEVC konvertieren und als Hintergrund aktivieren
  wallpaper use <Name>          Ein Hintergrundbild aus der Mediathek aktivieren (sofort)
  wallpaper add <Datei>         Zur Mediathek hinzufügen, ohne zu aktivieren
  wallpaper list                Mediathek auflisten (▶ = aktiv)
  wallpaper remove <Name>       Aus der Mediathek entfernen
  wallpaper start | stop | restart
  wallpaper status              Status und Konfiguration anzeigen
  wallpaper logs [N]            Letzte N Zeilen des Protokolls
  wallpaper test                Visuelle Sichtprüfung
  wallpaper lockscreen          Sperrbildschirm manuell synchronisieren
  wallpaper lockscreen-restore  Ursprüngliches Aerial wiederherstellen
  wallpaper lockscreen-status   Status des Sperrbildschirms anzeigen
  wallpaper fill <fill|fit|stretch>
  wallpaper battery <on|off>
  wallpaper lowpower <on|off>
  wallpaper powersave <on|off>  Standbild anzeigen, um Energie zu sparen
  wallpaper enable              Bei der Anmeldung automatisch starten
  wallpaper disable             Nicht mehr automatisch starten

Die Sprache folgt macOS oder dem Schlüssel \"language\" in config.json.
Für einen einzelnen Befehl: WALLPAPER_LANG=<Code>."
