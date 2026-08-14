# Wallpaper Sync CLI — Español
#
# Cualquier clave que falte acá cae automáticamente al texto en inglés
# (bin/i18n/en.sh), que se sourcea siempre primero. Ver docs/TRANSLATING.md.
#
# shellcheck shell=bash disable=SC2034

# ── Conversión ────────────────────────────────────────────────────────
MSG_need_ffmpeg="ffmpeg no está instalado (brew install ffmpeg)"
MSG_already_hevc="ya es HEVC, reempaquetando a .mov…"
MSG_already_hevc_mov="ya es HEVC .mov, copiando directo…"
MSG_encoding="codificando a HEVC (hardware)…"
MSG_encoded_ok="✓ codificado con HEVC VideoToolbox"
MSG_encode_fallback="fallback: x265 software…"
MSG_unsupported_format="formato no soportado: %s"

# ── Motor ─────────────────────────────────────────────────────────────
MSG_syncing_lockscreen="sincronizando lock screen…"
MSG_binary_missing="binario no encontrado: %s"
MSG_no_active="no hay wallpaper activo. Usá: wallpaper use <nombre>"
MSG_already_running="ya está corriendo (pid %s)"
MSG_start_failed="no arrancó (ver %s)"
MSG_started="encendido (pid %s)"
MSG_stopped="apagado"

# ── Biblioteca ────────────────────────────────────────────────────────
MSG_usage_add="uso: wallpaper add <archivo>"
MSG_usage_use="uso: wallpaper use <nombre>"
MSG_usage_set="uso: wallpaper set <archivo>"
MSG_usage_remove="uso: wallpaper remove <nombre>"
MSG_not_found="no existe: %s"
MSG_not_in_library="no está en la biblioteca: %s (ver 'wallpaper list')"
MSG_added="agregado: %s"
MSG_removed="eliminado: %s"
MSG_active_now="wallpaper activo: %s"
MSG_library_empty="(biblioteca vacía)"
MSG_library_empty_hint="(biblioteca vacía — usá 'wallpaper set <archivo>' para agregar)"

# ── Estado ────────────────────────────────────────────────────────────
# Las claves a la izquierda de los dos puntos son campos literales del config
# y no se traducen. Respetá el padding para no romper la alineación.
MSG_state_running="estado:          ACTIVO (pid %s)"
MSG_state_stopped="estado:          detenido"
MSG_autostart_yes="autoarranque:    sí"
MSG_autostart_no="autoarranque:    no"

# ── Ajustes ───────────────────────────────────────────────────────────
MSG_fill_set="fill=%s"
MSG_usage_fill="uso: wallpaper fill <fill|fit|stretch>"
MSG_battery_pause="pausa en batería: %s"
MSG_usage_battery="uso: wallpaper battery <on|off>"
MSG_lowpower_pause="pausa en low-power: %s"
MSG_usage_lowpower="uso: wallpaper lowpower <on|off>"
MSG_powersave_set="ahorro de energía (modo estático): %s"
MSG_usage_powersave="uso: wallpaper powersave <on|off>"

# ── Autoarranque ──────────────────────────────────────────────────────
MSG_autostart_installed="autoarranque instalado"
MSG_autostart_removed="autoarranque desinstalado"
MSG_autostart_absent="autoarranque no estaba instalado"

# ── Varios ────────────────────────────────────────────────────────────
MSG_no_logs="(sin logs)"
MSG_sanity="sanity-check: ventanita 320x180, se cierra sola en 8s"

MSG_usage="wallpaper — motor de fondos animados para macOS

USO:
  wallpaper set <archivo>       Convierte a HEVC y activa como wallpaper
  wallpaper use <nombre>        Activa un wallpaper de la biblioteca (instantáneo)
  wallpaper add <archivo>       Agrega a la biblioteca sin activar
  wallpaper list                Lista la biblioteca (▶ = activo)
  wallpaper remove <nombre>     Elimina de la biblioteca
  wallpaper start | stop | restart
  wallpaper status              Muestra estado y configuración
  wallpaper logs [N]            Últimas N líneas de log
  wallpaper test                Sanity-check visual
  wallpaper lockscreen          Sincroniza lock screen manualmente
  wallpaper lockscreen-restore  Restaura el aerial original
  wallpaper lockscreen-status   Muestra estado del lock screen
  wallpaper fill <fill|fit|stretch>
  wallpaper battery <on|off>
  wallpaper lowpower <on|off>
  wallpaper powersave <on|off>  Activa un frame estático para ahorrar energía
  wallpaper enable              Autoarranque al iniciar sesión
  wallpaper disable             Quita el autoarranque

El idioma sigue al de macOS, o la clave \"language\" de config.json.
Para un solo comando: WALLPAPER_LANG=<código>."
