# Wallpaper Sync CLI — 简体中文
#
# 此处缺失的键会自动回退到英文 (bin/i18n/en.sh)，英文目录总是先被加载。
# 参见 docs/TRANSLATING.md。
#
# 初版翻译，未经母语者校对 — 欢迎修正。
#
# shellcheck shell=bash disable=SC2034

# ── 转换 ──────────────────────────────────────────────────────────────
MSG_need_ffmpeg="未安装 ffmpeg (brew install ffmpeg)"
MSG_already_hevc="已是 HEVC，正在重新封装为 .mov…"
MSG_already_hevc_mov="已是 HEVC 的 .mov，直接复制…"
MSG_encoding="正在编码为 HEVC（硬件）…"
MSG_encoded_ok="✓ 已使用 HEVC VideoToolbox 编码"
MSG_encode_fallback="回退到软件 x265…"
MSG_unsupported_format="不支持的格式：%s"

# ── 引擎 ──────────────────────────────────────────────────────────────
MSG_syncing_lockscreen="正在同步锁定屏幕…"
MSG_binary_missing="找不到可执行文件：%s"
MSG_no_active="没有活动的壁纸。请使用：wallpaper use <名称>"
MSG_already_running="已在运行 (pid %s)"
MSG_start_failed="启动失败（请查看 %s）"
MSG_started="已启动 (pid %s)"
MSG_stopped="已停止"

# ── 媒体库 ────────────────────────────────────────────────────────────
MSG_usage_add="用法：wallpaper add <文件>"
MSG_usage_use="用法：wallpaper use <名称>"
MSG_usage_set="用法：wallpaper set <文件>"
MSG_usage_remove="用法：wallpaper remove <名称>"
MSG_not_found="不存在：%s"
MSG_not_in_library="不在媒体库中：%s（请查看 'wallpaper list'）"
MSG_added="已添加：%s"
MSG_removed="已删除：%s"
MSG_active_now="当前壁纸：%s"
MSG_library_empty="（媒体库为空）"
MSG_library_empty_hint="（媒体库为空 — 使用 'wallpaper set <文件>' 添加一个）"

# ── 状态 ──────────────────────────────────────────────────────────────
# 冒号左侧是配置文件中的字段名，不要翻译。
# 请保留空格，以便各列对齐。
MSG_state_running="状态:            运行中 (pid %s)"
MSG_state_stopped="状态:            已停止"
MSG_autostart_yes="开机自启:        是"
MSG_autostart_no="开机自启:        否"

# ── 设置 ──────────────────────────────────────────────────────────────
MSG_fill_set="fill=%s"
MSG_usage_fill="用法：wallpaper fill <fill|fit|stretch>"
MSG_battery_pause="使用电池时暂停：%s"
MSG_usage_battery="用法：wallpaper battery <on|off>"
MSG_lowpower_pause="低电量模式时暂停：%s"
MSG_usage_lowpower="用法：wallpaper lowpower <on|off>"
MSG_powersave_set="节能（静止画面）：%s"
MSG_usage_powersave="用法：wallpaper powersave <on|off>"

# ── 开机自启 ──────────────────────────────────────────────────────────
MSG_autostart_installed="已设置开机自启"
MSG_autostart_removed="已取消开机自启"
MSG_autostart_absent="未设置过开机自启"

# ── 其他 ──────────────────────────────────────────────────────────────
MSG_no_logs="（无日志）"
MSG_sanity="显示自检：320x180 小窗口，8 秒后自动关闭"

MSG_usage="wallpaper — macOS 动态壁纸引擎

用法：
  wallpaper set <文件>          转换为 HEVC 并设为壁纸
  wallpaper use <名称>          切换到媒体库中的壁纸（即时）
  wallpaper add <文件>          仅添加到媒体库，不启用
  wallpaper list                列出媒体库（▶ = 使用中）
  wallpaper remove <名称>       从媒体库中删除
  wallpaper start | stop | restart
  wallpaper status              显示状态和配置
  wallpaper logs [N]            日志的最后 N 行
  wallpaper test                显示自检
  wallpaper lockscreen          手动同步锁定屏幕
  wallpaper lockscreen-restore  恢复原始航拍壁纸
  wallpaper lockscreen-status   显示锁定屏幕状态
  wallpaper fill <fill|fit|stretch>
  wallpaper battery <on|off>
  wallpaper lowpower <on|off>
  wallpaper powersave <on|off>  显示静止画面以节省电量
  wallpaper enable              登录时自动启动
  wallpaper disable             取消自动启动

语言跟随 macOS 设置，或 config.json 中的 \"language\" 键。
仅对单条命令生效：WALLPAPER_LANG=<代码>"
