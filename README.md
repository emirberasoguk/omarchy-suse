🌐 **English** · [Türkçe](README.tr.md)

# omarchy-suse

A **Hyprland + caelestia** desktop for openSUSE Tumbleweed: an installer,
a working configuration, 19 helper scripts, and a written record of the
pitfalls found along the way.

Inspired by Omarchy: a Hyprland desktop that feels **integrated** rather than
assembled from parts. Omarchy is tied to Arch, and caelestia doesn't officially
support openSUSE. This repository fills that gap.

> **Language note:** All documentation is available in English and Turkish
> ([index](docs/README.md)). The scripts' menus, notifications and the comments
> inside the configuration files are currently in Turkish.

## Who is this for

- People who want to install **Hyprland + caelestia** on openSUSE. Packaging
  bugs, missing fonts, black screens and a launcher that won't launch are all
  written down with their fixes.
- People who want to extend caelestia **without forking it** and hook their
  own scripts into the launcher, the system tray or the theme engine.
- Anyone wondering why `hyprctl` says "ok" and then does the wrong thing with
  Hyprland's new **Lua config**.

## Tested environment

| | |
|---|---|
| Distribution | openSUSE Tumbleweed |
| Compositor | Hyprland 0.56.2 (Lua configuration: `hyprland.lua`) |
| Shell | caelestia-shell 2.3.0 · caelestia-cli 1.1.2 · quickshell 0.3.1 (`home:kaiman`) |
| Login | GDM. **GNOME stays installed alongside**; pick either one on the login screen |
| Hardware | Intel + NVIDIA hybrid laptop. Also works on single-GPU machines |

## Installation

```bash
git clone <this-repository-url> omarchy-suse
cd omarchy-suse
./kurulum.sh
```

`kurulum.sh` ("installation") runs in seven phases. Each phase shows what it
will do and **asks** first. There is no default answer; type `e` (yes) or `h`
(no). zypper's own confirmations are kept as they are. Every file that would
be overwritten is backed up to `~/.local/state/omarchy-suse/yedek/` first.

To understand the steps without running a script:
[`docs/en/INSTALL.md`](docs/en/INSTALL.md)

Before installing, look at the **KİŞİSEL TERCİHLER** ("personal preferences")
block at the top of `config/hypr/hyprland.lua`: browser, file manager and
keyboard layout (defaults to Turkish, `tr`).

## What you get

### Keybindings

| Key | Action |
|---|---|
| `Super+Space` | App launcher (type `:` for actions) |
| `Super+Return` / `Super+T` | Terminal (T: focus it if already open) |
| `Super+B` | Browser (focus it if already open) |
| `Super+E` / `Super+M` | File manager |
| `Super+Q` | Close window |
| `Super+Up` / `Super+F` | Maximize / fullscreen |
| `Super+V` | Floating window |
| `Super+1…0` | Workspaces · with `Shift`, move the window |
| `Super+Ctrl+←/→` | Previous/next workspace |
| `Super+Shift+←/→/↑/↓` | Move the window to another monitor |
| `Super+D` · `S` · `U` · `N` | Dashboard · sidebar · utilities · settings (Nexus) |
| `Super+L` · `Super+Escape` | Lock · session menu |
| `Super+Tab` | All windows |
| `Print` / `Shift+Print` | Screenshot (freeze and select) |
| `Super+Shift+T` · `Super+Shift+Q` | Read text from the screen (OCR) · read a QR code |
| `Super+Shift+N` | Night light |
| `Super+Shift+V` · `Super+Shift+S` | Save clipboard to a file · share clipboard via LocalSend |
| `Super+Ctrl+O` · `Super+Ctrl+G` | Transparency · window gaps |
| `Super+Shift+E` | **Safety net:** exit Hyprland even if the shell has crashed |

Touchpad: 3/4 fingers horizontal → workspaces · 3 fingers up → launcher ·
3 fingers down → sidebar.

### Launcher actions

`Super+Space` → type `:`. There are 29 actions: system update, an app manager
(zypper + flatpak in one list), uninstall, create a web app, install an
AppImage, OCR, QR, night light, transparency, fonts, Wi-Fi status, theme and
wallpaper, and power actions.

caelestia only searches an action's **name**, so synonyms in both Turkish and
English are embedded in the names: `:ocr`, `:metin` and `:text` all find the
same action.

### System tray menu

The tray icon in the bar (`os-kontrol`) puts common tasks one click away:

- OCR and QR reading, night light, save/share clipboard, share files
- Screen refresh rate (the rates your monitor supports)
- GPU mode (if `supergfxctl` is installed), hotspot (if [hotspotd](https://github.com/emirberasoguk/hotspotd) is installed)

The icons are drawn in caelestia's current color scheme and change along with
the theme.

### Scripts

All are installed to `~/.local/bin/omarchy-suse/`. They also work from a
terminal; most open an interactive menu when called without arguments. The
names are Turkish; the table explains each one.

| Script | Purpose |
|---|---|
| `os-uygulama` | Unified zypper + flatpak search and install, with preview |
| `os-kaldir` | Uninstall web apps · packages · flatpaks · AppImages |
| `os-guncelle` | `zypper dup` + flatpak, or your own update function |
| `os-webapp` | Turn a website into a desktop app (finds its icon) |
| `os-appimage` | Install/list/remove AppImages and add them to the menu |
| `os-yakala` | OCR (tesseract) and QR (zbar) from a screen region |
| `os-kontrol` | System tray menu |
| `os-gece` | Night light with hyprsunset |
| `os-pencere` | Transparency · gaps · fullscreen · floating · layout |
| `os-ac-odaklan` | Focus an app if it's open, otherwise launch it |
| `os-pano-kaydet` | Save the clipboard to a file by content type |
| `os-paylas` | Share clipboard/files/folders via LocalSend (flatpak sandbox aware) |
| `os-font` | Pick system fonts (fzf, with preview) |
| `os-wifi-durum` | Wi-Fi band/AP/signal + clear the AP lock caelestia sets |
| `os-hotspot` | Manage hotspotd from the desktop |
| `os-kapak` | Lock on lid close; clamshell mode when an external monitor is connected |
| `os-oturum` | Full-screen transition animation before shutdown/reboot/logout |
| `os-oturum-bekci` | Stops the session target when Hyprland dies (prevents the GDM loop) |
| `os-kitty-tema` | Generates a kitty color theme from the caelestia scheme |

Their shared TUI layer is `lib/os-tui.sh`: gum + fzf, with colors from the
caelestia scheme. API: [`docs/en/EXTENDING.md`](docs/en/EXTENDING.md)

## How it works

```
GDM → Hyprland (hyprland.lua)
        └─ baslat-caelestia.sh
             ├─ wait until WAYLAND_DISPLAY and DISPLAY are REALLY ready
             ├─ export the environment to systemd + D-Bus
             ├─ hyprland-session.target ── portal · hypridle · polkit · gvfs · os-kontrol
             ├─ hyprland-oturum-bekci.service (stops the target after a crash)
             ├─ generate tray icons (BEFORE the shell — Qt icon cache)
             └─ caelestia shell
```

Why so many steps? Each one hides a silent failure. They're all documented in
[`docs/en/TROUBLESHOOTING.md`](docs/en/TROUBLESHOOTING.md).

## Documentation

| Document | Contents |
|---|---|
| [`docs/en/INSTALL.md`](docs/en/INSTALL.md) | Step-by-step installation without the script, and a map of installed files |
| [`docs/en/TROUBLESHOOTING.md`](docs/en/TROUBLESHOOTING.md) | Symptom → cause → fix: packaging, session, theme, display, apps |
| [`docs/en/HYPRLAND-LUA.md`](docs/en/HYPRLAND-LUA.md) | `hyprctl eval`/`dispatch` in Hyprland 0.56's Lua config, and the traps that turn your screen off |
| [`docs/en/EXTENDING.md`](docs/en/EXTENDING.md) | Extending caelestia without a fork: launcher, tray, theme hook, IPC, TUI |
| [`donanim/nvidia-hibrit/`](donanim/nvidia-hibrit/README.md) | Optional GPU settings for Intel + NVIDIA laptops |
| [`docs/README.md`](docs/README.md) | All documents in every language, and how to add a translation |

## Uninstalling

```bash
./kaldir.sh
```

Removes the scripts and services. It doesn't touch packages or configuration
files, and it shows where your backups are.

## Known limitations

These require changing caelestia's QML code (a fork), which this repository
deliberately avoids:

- Moving the bar to the **top** instead of the side
- Adding **new toggles** to the quick-settings panel
- A **monitor settings** page in Nexus (not upstream yet). Monitors are
  configured in `hyprland.lua`; examples are in the file.
- A dock

## Contributing translations

Documentation lives in `docs/<language>/` with the same file names in every
language. See [`docs/README.md`](docs/README.md) for how to add one.

## License

[GPL-3.0](LICENSE). The MIT notice for the parts adapted from Omarchy and
other third-party notes: [`NOTICE.md`](NOTICE.md).

This project is not affiliated with Basecamp/Omarchy, caelestia-dots or hyprwm.
