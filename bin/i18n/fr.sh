# Wallpaper Sync CLI — Français
#
# Toute clé absente ici retombe automatiquement sur l'anglais (bin/i18n/en.sh),
# qui est toujours chargé en premier. Voir docs/TRANSLATING.md.
#
# Traduction initiale non relue par un locuteur natif — corrections bienvenues.
#
# shellcheck shell=bash disable=SC2034

# ── Conversion ────────────────────────────────────────────────────────
MSG_need_ffmpeg="ffmpeg n'est pas installé (brew install ffmpeg)"
MSG_already_hevc="déjà en HEVC, remultiplexage en .mov…"
MSG_already_hevc_mov="déjà un .mov HEVC, copie directe…"
MSG_encoding="encodage en HEVC (matériel)…"
MSG_encoded_ok="✓ encodé avec HEVC VideoToolbox"
MSG_encode_fallback="repli sur x265 logiciel…"
MSG_unsupported_format="format non pris en charge : %s"

# ── Moteur ────────────────────────────────────────────────────────────
MSG_syncing_lockscreen="synchronisation de l'écran verrouillé…"
MSG_binary_missing="binaire introuvable : %s"
MSG_no_active="aucun fond d'écran actif. Utilisez : wallpaper use <nom>"
MSG_already_running="déjà en cours d'exécution (pid %s)"
MSG_start_failed="le démarrage a échoué (voir %s)"
MSG_started="démarré (pid %s)"
MSG_stopped="arrêté"

# ── Bibliothèque ──────────────────────────────────────────────────────
MSG_usage_add="utilisation : wallpaper add <fichier>"
MSG_usage_use="utilisation : wallpaper use <nom>"
MSG_usage_set="utilisation : wallpaper set <fichier>"
MSG_usage_remove="utilisation : wallpaper remove <nom>"
MSG_not_found="n'existe pas : %s"
MSG_not_in_library="absent de la bibliothèque : %s (voir 'wallpaper list')"
MSG_added="ajouté : %s"
MSG_removed="supprimé : %s"
MSG_active_now="fond d'écran actif : %s"
MSG_library_empty="(bibliothèque vide)"
MSG_library_empty_hint="(bibliothèque vide — utilisez 'wallpaper set <fichier>' pour en ajouter un)"

# ── État ──────────────────────────────────────────────────────────────
# Les clés à gauche des deux points sont des champs de config littéraux et ne
# se traduisent pas. Conservez l'alignement de la colonne.
MSG_state_running="état :           ACTIF (pid %s)"
MSG_state_stopped="état :           arrêté"
MSG_autostart_yes="démarrage auto : oui"
MSG_autostart_no="démarrage auto : non"

# ── Réglages ──────────────────────────────────────────────────────────
MSG_fill_set="fill=%s"
MSG_usage_fill="utilisation : wallpaper fill <fill|fit|stretch>"
MSG_battery_pause="pause sur batterie : %s"
MSG_usage_battery="utilisation : wallpaper battery <on|off>"
MSG_lowpower_pause="pause en mode économie : %s"
MSG_usage_lowpower="utilisation : wallpaper lowpower <on|off>"
MSG_powersave_set="économie d'énergie (image fixe) : %s"
MSG_usage_powersave="utilisation : wallpaper powersave <on|off>"

# ── Démarrage automatique ─────────────────────────────────────────────
MSG_autostart_installed="démarrage automatique installé"
MSG_autostart_removed="démarrage automatique retiré"
MSG_autostart_absent="le démarrage automatique n'était pas installé"

# ── Divers ────────────────────────────────────────────────────────────
MSG_no_logs="(aucun journal)"
MSG_sanity="test visuel : petite fenêtre 320x180, se ferme après 8 s"

MSG_usage="wallpaper — moteur de fonds d'écran animés pour macOS

UTILISATION :
  wallpaper set <fichier>       Convertit en HEVC et active comme fond d'écran
  wallpaper use <nom>           Active un fond d'écran de la bibliothèque (instantané)
  wallpaper add <fichier>       Ajoute à la bibliothèque sans activer
  wallpaper list                Liste la bibliothèque (▶ = actif)
  wallpaper remove <nom>        Retire de la bibliothèque
  wallpaper start | stop | restart
  wallpaper status              Affiche l'état et la configuration
  wallpaper logs [N]            N dernières lignes du journal
  wallpaper test                Test visuel
  wallpaper lockscreen          Synchronise l'écran verrouillé manuellement
  wallpaper lockscreen-restore  Restaure le fond aérien d'origine
  wallpaper lockscreen-status   Affiche l'état de l'écran verrouillé
  wallpaper fill <fill|fit|stretch>
  wallpaper battery <on|off>
  wallpaper lowpower <on|off>
  wallpaper powersave <on|off>  Affiche une image fixe pour économiser l'énergie
  wallpaper enable              Démarrer automatiquement à l'ouverture de session
  wallpaper disable             Ne plus démarrer automatiquement

La langue suit macOS, ou la clé \"language\" de config.json.
Pour une seule commande : WALLPAPER_LANG=<code>."
