# Translating Wallpaper Sync

Wallpaper Sync ships in **English** (the development language) and **Spanish**.
Adding another one takes two files and no code changes.

## The short version

Say you want French (`fr`). Copy the English catalogs, translate the values, done:

```bash
cp -R resources/en.lproj resources/fr.lproj   # the menu-bar app
cp bin/i18n/en.sh bin/i18n/fr.sh              # the command line tool
./install.sh
```

The app finds `fr.lproj` on its own and adds **Français** to the globe menu in the
header — the language list is built by scanning the bundle, so there is no list of
languages to register anywhere.

Use the [ISO 639-1 code](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes)
for the language (`fr`, `de`, `pt`, `ja`). Codes are per language, not per region:
a Mac set to `pt-BR` loads `pt`.

## What goes where

| File | Covers |
|---|---|
| `resources/<code>.lproj/Localizable.strings` | Everything in the menu-bar app window |
| `resources/<code>.lproj/InfoPlist.strings` | The app name and copyright line in Finder |
| `bin/i18n/<code>.sh` | Everything the `wallpaper` command prints |

## Rules that matter

**Translate the values, never the keys.** In `Localizable.strings` the key is on the
left, the text on the right:

```
"header.title" = "Bibliothèque";
```

In `bin/i18n/<code>.sh` the key is the variable name:

```bash
MSG_added="ajouté : %s"
```

**Keep the placeholders.** `%@` (app) and `%s` (CLI) are replaced at runtime with a
filename, a wallpaper name, a PID. `%d` is a number. They must all survive, in the
same order as the English original.

**Don't translate command names or config fields.** `wallpaper set`, `fill`,
`pauseOnBattery`, `on`, `off` are things the user types or the program reads — they
stay as they are, in every language.

**Partial translations are fine.** Both layers fall back to English key by key, so a
catalog missing half its entries shows the other half in English rather than breaking.
That also means you can ship a language early and fill it in later.

**Watch the padding in `wallpaper status`.** Four keys (`MSG_state_running`,
`MSG_state_stopped`, `MSG_autostart_yes`, `MSG_autostart_no`) include the spaces that
line the output up into a column. Adjust the spacing so your text still lines up.

## Testing without changing your system language

The CLI takes an override:

```bash
WALLPAPER_LANG=fr bin/wallpaper help
```

The app has the globe menu in the header. Your choice is written to the `language` key
in `~/Library/Application Support/WallpaperSync/config.json` and the CLI reads the same
file, so the two always agree. An empty value means "follow macOS".

## Before opening a pull request

- [ ] `./install.sh` runs clean
- [ ] `WALLPAPER_LANG=<code> bin/wallpaper help` and `status` read correctly
- [ ] Your language shows up in the globe menu and switches the whole window
- [ ] No key is left untranslated by accident — compare against `en.lproj` / `en.sh`
- [ ] Long strings don't overflow their buttons (check the header and the setup card)
