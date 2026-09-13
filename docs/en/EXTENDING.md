🌐 **English** · [Türkçe](../tr/EXTENDING.md)

# Extending caelestia without forking it

Changing caelestia's QML code (forking) is powerful but expensive: you have to
merge on every `caelestia-shell` update. This document shows how to hook your
own features into the shell **without changing its code at all**. All 19
scripts in this repository are wired in this way.

## 0. First: setting or fork?

caelestia's configuration schema lives in a compiled C++ plugin. The **only
reliable source** for which options exist is this file:

```
/usr/lib64/qt6/qml/Caelestia/Config/caelestia-config.qmltypes
```

To read the source code:

| What | Where |
|---|---|
| Shell (QML) | `/etc/xdg/quickshell/caelestia-shell/` |
| CLI + theme engine (Python) | `/usr/lib/python3.*/site-packages/caelestia/` |
| Shortcut names | `…/caelestia-shell/modules/Shortcuts.qml` |

These need a fork (they're not settings): moving the bar to the top, a new
quick-settings toggle (IDs are hard-coded in `Toggles.qml`), searching action
descriptions in the launcher, new Nexus pages, a dock.

## Hook points

| Path | For | Where |
|---|---|---|
| [Launcher action](#1-launcher-action) | Commands you run by searching | `shell.json` |
| [Keybinding](#2-keybinding) | One key | `hyprland.lua` |
| [Theme hook](#3-theme-hook-posthook) | Things to run when the color scheme changes | `cli.json` |
| [System tray](#4-system-tray-sni) | A menu that shows state | separate process + systemd |
| [Session commands](#5-session-commands) | Running something before shutdown/reboot/logout | `shell.json` |
| [IPC](#6-ipc) | Opening the shell's panels from outside | `qs ipc call` |

---

## 1. Launcher action

`~/.config/caelestia/shell.json` → `launcher.actions`. The shell reads this
file **live**; no restart needed.

```json
{
    "name": "Read text from screen · OCR · text recognition · copy",
    "description": "Select a region, copy the text to the clipboard",
    "icon": "document_scanner",
    "command": ["/home/user/.local/bin/omarchy-suse/os-yakala", "ocr"]
}
```

| Field | Note |
|---|---|
| `name` | **Search only looks here.** Embed synonyms in the name |
| `icon` | A [Material Symbols](https://fonts.google.com/icons) name |
| `command` | An array. **Use full paths.** `~` isn't expanded; don't rely on `PATH` |
| `dangerous` | If `true`, hidden unless `launcher.enableDangerousActions` is on |

For a TUI that needs a terminal: `["kitty", "-e", "/full/path/script"]`. If
the script opens an interactive menu, `--hold` isn't needed.

The launcher's action prefix is `launcher.actionPrefix`. The default is `>`;
this repository uses `:` because `>` needs AltGr on a Turkish Q keyboard.

## 2. Keybinding

```lua
local os_bin = os.getenv("HOME") .. "/.local/bin/omarchy-suse"
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(os_bin .. "/os-yakala ocr"))
```

Check for conflicts: `hyprctl binds -j | jq '.[] | select(.key=="T") | .modmask'`

Global shortcuts for caelestia's own panels:
`hl.dsp.global("caelestia:launcher")`. The names are in `Shortcuts.qml`.

## 3. Theme hook (`postHook`)

`~/.config/caelestia/cli.json`:

```json
"theme": {
    "postHook": [
        "/home/user/.local/bin/omarchy-suse/os-kitty-tema",
        "/home/user/.local/bin/omarchy-suse/os-kontrol --ikonlar",
        "hyprctl reload"
    ]
}
```

These run in order every time the wallpaper or scheme changes. **Order
matters:** file generators first, `hyprctl reload` last.

### Reading the scheme colors

The theme engine writes the current scheme in two formats:

| File | Format | Read by |
|---|---|---|
| `~/.local/state/caelestia/scheme.json` | `{ "name", "flavour", "mode", "colours": { "primary": "dcc74d", … } }` | scripts |
| `~/.config/hypr/scheme/current.lua` | `return { primary = "dcc74d", … }` | `hyprland.lua` (`dofile`) |

Commonly used keys: `primary` `onPrimary` `secondary` `tertiary` `surface`
`onSurface` `surfaceContainer` `surfaceContainerHigh` `outline` `error`
`onSurfaceVariant`, plus terminal colors `term0`…`term15`.

```python
import json, pathlib
d = json.loads((pathlib.Path.home() / ".local/state/caelestia/scheme.json").read_text())
c = d.get("colours", d)
primary = "#" + c["primary"]
```

**Always provide a fallback color.** The file may not exist on first login.
In Bash, `lib/os-tui.sh` does this for you (`TUI_PRIMARY` and friends).

## 4. System tray (SNI)

The tray in caelestia's bar speaks the standard **StatusNotifierItem**
protocol, so you can add your own icon and menu without touching QML.
`bin/os-kontrol` is a working, commented example (Python + AyatanaAppIndicator3).

The traps on this path all come from the same fact: **the menu is drawn by
Quickshell (Qt), not GTK.**

| Trap | Result | Fix |
|---|---|---|
| `Gtk.CheckMenuItem` + `toggled` | Clicks do nothing. DBusMenu sends `clicked`, which maps to `activate` | A normal item + `activate` |
| Refreshing the menu on the `show` signal | Labels freeze at their first values. The consumer calls `AboutToShow`; GTK's `show` never fires | Compare a state signature every few seconds and rebuild on change |
| Unsuffixed names like `edit-paste`, `application-exit` | Broken squares. Unlike GTK, Qt doesn't fall back to `-symbolic`; GNOME's Adwaita only ships these names with the suffix | Use the `-symbolic` name |
| Adwaita symbolic icons | Dark icons on a dark menu. GTK recolors them, Quickshell doesn't | Generate the SVG yourself with the scheme color |
| Icon only in `IconThemePath` | Broken square. caelestia does a theme lookup first, and its fallback path adds no extension | Also write the icon to `~/.local/share/icons/hicolor/scalable/apps/` |
| Adding a new icon to hicolor while the shell is running | Invisible. Qt caches the icon theme **at process start** | Restart the shell; for a permanent fix, generate icons before the shell starts (`baslat-caelestia.sh`) |
| Polling state with `hyprctl`/`pgrep`/CLI tools every few seconds | Measurable CPU and battery drain: 6 processes every 3 s used 40 s of CPU in 49 minutes and kept the CPU out of deep sleep | Talk to Hyprland's socket directly, read `/proc` instead of `pgrep`, subscribe to D-Bus signals (e.g. supergfxd `NotifyGfx`), poll the rest rarely. `os-kontrol` went from ~7 200 to ~360 processes per hour |
| Calling `set_icon_full` on every poll | D-Bus traffic every few seconds even when nothing changed | Send the icon only when the state changes |

### Verify by measuring

Instead of guessing, ask Quickshell directly. A throwaway QML file:

```qml
// /tmp/icon-check.qml
import Quickshell
ShellRoot {
    Component.onCompleted: {
        for (const name of ["edit-paste", "edit-paste-symbolic", "os-kontrol-sade"])
            console.log(name, Quickshell.iconPath(name, true) ? "FOUND" : "missing");
        Qt.exit(0);
    }
}
```

```bash
qs -p /tmp/icon-check.qml
```

Use the same method with `SystemPalette` to confirm a platform theme is really
loaded. Without one, Qt falls back to a light palette (`window: #efefef`).

Simulate a menu click over D-Bus instead of looking at the screen:

```bash
busctl --user call <service> /org/ayatana/NotificationItem/<name>/Menu \
       com.canonical.dbusmenu Event isvu <item-id> clicked s "" 0
busctl --user call <service> /org/ayatana/NotificationItem/<name>/Menu \
       com.canonical.dbusmenu GetLayout iias 0 -1 0
```

### Running it as a service

```ini
[Unit]
PartOf=hyprland-session.target
After=hyprland-session.target

[Service]
ExecStart=%h/.local/bin/omarchy-suse/os-kontrol
Restart=on-failure

[Install]
WantedBy=hyprland-session.target
```

Attach it with `systemctl --user add-wants hyprland-session.target os-kontrol.service`.
The service then comes up only in the Hyprland session, not in GNOME.

## 5. Session commands

caelestia's power menu runs its command directly; there's no animation hook in
between. But **the command itself comes from `shell.json`**:

```json
"session": {
    "commands": {
        "shutdown": ["/full/path/os-oturum", "kapat"],
        "reboot":   ["/full/path/os-oturum", "yeniden"],
        "logout":   ["/full/path/os-oturum", "cikis"]
    }
}
```

`bin/os-oturum` first draws a full-screen transition in QML with `qs -p`
(`WlrLayer.Overlay`), waits briefly, then runs the real command. If you write
your own version, don't forget two safety nets:

1. A forced `Qt.exit(0)` timer of a few seconds inside the QML. If the overlay
   gets stuck, it covers the screen for good.
2. If the command fails, kill the overlay process.

`os-oturum dene` shows only the transition without running the real command.

## 6. IPC

Open and close the shell's panels from outside:

```bash
qs -c caelestia ipc call drawers toggle launcher
qs -c caelestia ipc call drawers toggle sidebar
qs -c caelestia ipc call lock lock
qs -c caelestia ipc show        # every target and function
```

The `caelestia` CLI does the same, but it's slow because it starts a Python
process (measured: 400 ms versus 130 ms). Use `qs ipc` in gestures and
keybindings.

---

## Terminal UI: `lib/os-tui.sh`

The shared layer for the Bash scripts. It reads colors from the caelestia
scheme with `jq` (≈3 ms; `python3` as a fallback); if the file is missing it
falls back to defaults and nothing breaks. Without `gum` and `fzf` it falls
back to plain `read` and `select`. Without a terminal (systemd, cron) the
prompting functions never hang: `onay` answers no, `secim`/`ara` return
nothing, `giris_al` returns its default.

The function names are Turkish; the table gives their meaning.

```bash
#!/bin/bash
set -uo pipefail
source ~/.local/lib/omarchy-suse/os-tui.sh

giris "Example" "󰣇" "short description"
if onay "Continue?"; then
    bekle "working" sleep 2
    basari "done"
fi
kapanis
```

| Function | Meaning | Purpose |
|---|---|---|
| `giris name icon subtitle` | intro | Short animation on first run + header |
| `baslik name icon subtitle` | header | Header without animation |
| `bilgi` · `basari` · `uyari` · `hata` | info · success · warning · error | Message line with an icon (`hata` goes to stderr) |
| `baslikcik text` | subheader | Section header |
| `secim "question" option…` | choice | Short menu (gum choose). Prints the chosen line |
| `ara "title" ["preview {}"]` | search | Long, searchable list from stdin (fzf) |
| `onay "question" [evet]` | confirm | Yes/no. Default is **no** |
| `giris_al "hint" [default]` | input | Text input |
| `bekle "message" cmd…` | wait | Run with a spinner |
| `ilerleme current total "label"` | progress | Progress bar |
| `bildir …` | notify | `notify-send` wrapper. Silently skipped if not installed |
| `ayrac` · `kapanis` | divider · closing | Layout |

Variables: `TUI_PRIMARY` `TUI_SURFACE` `TUI_ON_SURFACE` … (hex, without `#`),
`C_ANA` `C_IKI` `C_UC` `C_HATA` `C_SOLUK` (ANSI), `TUI_SIFIR` (reset).

Match menu choices by **icon**, not by text:

```bash
s=$(secim "What do you want to do?" "󰐥  Stop" "󰐊  Start at boot" "󰜺  Don't start at boot")
case "$s" in
    "󰐥"*) stop ;;
    "󰐊"*) enable ;;
    "󰜺"*) disable ;;
esac
```

Nerd Font icons can get lost when passed through heredocs and some editors.
If that happens, write them as escapes like `$'\U000F0425'`.

The full list of Bash traps: [TROUBLESHOOTING → Writing scripts](TROUBLESHOOTING.md#writing-scripts)

## Sources worth studying

```bash
araclar/referanslari-indir.sh
```

Shallow-clones caelestia (shell, cli), Omarchy, the Hyprland wiki and other
quickshell shells into `referanslar/`. Omarchy's `bin/` directory is full of
script ideas that don't depend on the distribution. Nine scripts in this
repository were adapted from there (see [`NOTICE.md`](../../NOTICE.md)).
