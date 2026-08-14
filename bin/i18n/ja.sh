# Wallpaper Sync CLI — 日本語
#
# ここにないキーは自動的に英語 (bin/i18n/en.sh) にフォールバックします。
# 英語カタログは常に先に読み込まれます。docs/TRANSLATING.md を参照。
#
# 初回翻訳（ネイティブ未校正）— 修正歓迎です。
#
# shellcheck shell=bash disable=SC2034

# ── 変換 ──────────────────────────────────────────────────────────────
MSG_need_ffmpeg="ffmpeg がインストールされていません (brew install ffmpeg)"
MSG_already_hevc="すでに HEVC です。.mov に再多重化しています…"
MSG_already_hevc_mov="すでに HEVC の .mov です。そのままコピーします…"
MSG_encoding="HEVC にエンコード中（ハードウェア）…"
MSG_encoded_ok="✓ HEVC VideoToolbox でエンコードしました"
MSG_encode_fallback="ソフトウェア x265 にフォールバックします…"
MSG_unsupported_format="対応していない形式です: %s"

# ── エンジン ──────────────────────────────────────────────────────────
MSG_syncing_lockscreen="ロック画面を同期中…"
MSG_binary_missing="バイナリが見つかりません: %s"
MSG_no_active="アクティブな壁紙がありません。次を実行してください: wallpaper use <名前>"
MSG_already_running="すでに実行中です (pid %s)"
MSG_start_failed="起動できませんでした (%s を確認してください)"
MSG_started="起動しました (pid %s)"
MSG_stopped="停止しました"

# ── ライブラリ ────────────────────────────────────────────────────────
MSG_usage_add="使い方: wallpaper add <ファイル>"
MSG_usage_use="使い方: wallpaper use <名前>"
MSG_usage_set="使い方: wallpaper set <ファイル>"
MSG_usage_remove="使い方: wallpaper remove <名前>"
MSG_not_found="存在しません: %s"
MSG_not_in_library="ライブラリにありません: %s ('wallpaper list' を参照)"
MSG_added="追加しました: %s"
MSG_removed="削除しました: %s"
MSG_active_now="アクティブな壁紙: %s"
MSG_library_empty="(ライブラリは空です)"
MSG_library_empty_hint="(ライブラリは空です — 'wallpaper set <ファイル>' で追加してください)"

# ── 状態 ──────────────────────────────────────────────────────────────
# コロンの左側は設定ファイルのフィールド名そのものなので翻訳しません。
# 列が揃うようにスペースを調整してください。
MSG_state_running="状態:            実行中 (pid %s)"
MSG_state_stopped="状態:            停止中"
MSG_autostart_yes="自動起動:        はい"
MSG_autostart_no="自動起動:        いいえ"

# ── 設定 ──────────────────────────────────────────────────────────────
MSG_fill_set="fill=%s"
MSG_usage_fill="使い方: wallpaper fill <fill|fit|stretch>"
MSG_battery_pause="バッテリー駆動時に一時停止: %s"
MSG_usage_battery="使い方: wallpaper battery <on|off>"
MSG_lowpower_pause="低電力モード時に一時停止: %s"
MSG_usage_lowpower="使い方: wallpaper lowpower <on|off>"
MSG_powersave_set="省エネ（静止画モード）: %s"
MSG_usage_powersave="使い方: wallpaper powersave <on|off>"

# ── 自動起動 ──────────────────────────────────────────────────────────
MSG_autostart_installed="自動起動を設定しました"
MSG_autostart_removed="自動起動を解除しました"
MSG_autostart_absent="自動起動は設定されていませんでした"

# ── その他 ────────────────────────────────────────────────────────────
MSG_no_logs="(ログなし)"
MSG_sanity="動作確認: 320x180 の小さいウインドウ、8 秒後に自動で閉じます"

MSG_usage="wallpaper — macOS 用のアニメーション壁紙エンジン

使い方:
  wallpaper set <ファイル>      HEVC に変換して壁紙として設定
  wallpaper use <名前>          ライブラリの壁紙に切り替え（即時）
  wallpaper add <ファイル>      設定せずにライブラリへ追加
  wallpaper list                ライブラリを一覧表示（▶ = 使用中）
  wallpaper remove <名前>       ライブラリから削除
  wallpaper start | stop | restart
  wallpaper status              状態と設定を表示
  wallpaper logs [N]            ログの末尾 N 行
  wallpaper test                表示の動作確認
  wallpaper lockscreen          ロック画面を手動で同期
  wallpaper lockscreen-restore  元の空撮壁紙に戻す
  wallpaper lockscreen-status   ロック画面の状態を表示
  wallpaper fill <fill|fit|stretch>
  wallpaper battery <on|off>
  wallpaper lowpower <on|off>
  wallpaper powersave <on|off>  静止画を表示して省電力
  wallpaper enable              ログイン時に自動起動
  wallpaper disable             自動起動を解除

言語は macOS の設定、または config.json の \"language\" キーに従います。
コマンド単位で切り替えるには: WALLPAPER_LANG=<コード>"
