🌐 **English** · [Türkçe](../tr/INSTALL.md)

# Step-by-step installation

`kurulum.sh` performs every step below and asks before each one. This
document is for people who want to understand what happens without running
the script, or who want to install by hand.

Every step is **user-level** and reversible. GNOME is left untouched;
Hyprland is added as a separate session on the login screen.

> **Language note:** the scripts' menus, notifications and the comments in
> the configuration files are in Turkish. The commands and file paths below
> are the same in every language.

---

## 1. Packages from the official repositories

```bash
sudo zypper install \
  hyprland hyprlock hypridle hyprpolkitagent \
  xdg-desktop-portal-hyprland hyprland-qtutils hyprsunset \
  qt6-platformtheme-gtk3 qt6-sql-sqlite libnotify-tools \
  kitty nautilus jq curl unzip zip brightnessctl wl-clipboard grim slurp zenity iw \
  gum fzf chafa \
  typelib-1_0-AyatanaAppIndicator3-0_1 typelib-1_0-Gtk-3_0 python313-gobject \
  tesseract-ocr tesseract-ocr-traineddata-{tur,eng,osd} zbar \
  gpu-screen-recorder
```

The version in `python313-gobject` must match `python3 --version`. For OCR in
your own language, add the matching `tesseract-ocr-traineddata-<lang>` package.

**If you have an Intel GPU, also install:**

```bash
sudo zypper install intel-media-driver libva-utils
```

### Packages that fail silently

When these three are missing you get no error message; something just
doesn't work:

| Package | Without it |
|---|---|
| `qt6-sql-sqlite` | Clicking an app in the launcher does nothing |
| `libnotify-tools` | No script notification ever appears |
| `intel-media-driver` | VA-API never works: screen recording hangs, the browser decodes video on the CPU |

## 2. caelestia (`home:kaiman`)

caelestia and quickshell are not in the official repositories. The community
repository that packages them for Tumbleweed is `home:kaiman`. Add it with a
**lower priority** than the official repositories:

```bash
sudo zypper addrepo -p 100 -f \
  https://download.opensuse.org/repositories/home:/kaiman/openSUSE_Tumbleweed/home:kaiman.repo
sudo zypper refresh
sudo zypper install caelestia-shell caelestia-cli
```

### ⚠ Known packaging bug

```
Problem: nothing provides 'qt6qmlimport(qs.modules.bar.components.status)'
         needed by caelestia-shell
```

**Nothing is actually missing.** The `modules/bar/components/status/*.qml`
files are inside the package; the RPM's auto-generated `Provides:` list just
skipped that subdirectory. Choose zypper's **"break … by ignoring some of its
dependencies"** solution. The shell runs fine. The same question may come
back on later `zypper dup` runs.

## 3. Packaging fixes

### a) Shell name mismatch → black screen

`caelestia-cli` launches the shell as `qs -c caelestia`, but the package
installs it as `/etc/xdg/quickshell/caelestia-shell`. The shell never starts:
no bar, no wallpaper, a black screen with only a cursor.

```bash
mkdir -p ~/.config/quickshell
ln -sfn /etc/xdg/quickshell/caelestia-shell ~/.config/quickshell/caelestia
```

### b) Fonts → huge text, boxes instead of icons

The package doesn't pull in its font dependencies. The families caelestia
expects (source: `plugin/src/Caelestia/Config/font.hpp`):

| Font | Role | In openSUSE repos |
|---|---|---|
| Material Symbols Rounded | every icon | no |
| Rubik | UI text | no |
| CaskaydiaCove NF | monospace | no |
| Google Sans Flex | ships with the package, but in a directory fontconfig doesn't scan | — |

```bash
mkdir -p ~/.local/share/fonts/caelestia && cd ~/.local/share/fonts/caelestia

curl -L -o MaterialSymbolsRounded.ttf \
  "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
curl -L -o Rubik.ttf \
  "https://github.com/google/fonts/raw/main/ofl/rubik/Rubik%5Bwght%5D.ttf"
curl -L -o /tmp/CascadiaCode.zip \
  "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"
unzip -o /tmp/CascadiaCode.zip -d . -x "*.md" "*.txt" "LICENSE*"
cp /etc/xdg/quickshell/caelestia-shell/assets/google-sans-flex/*.ttf .

fc-cache -f ~/.local/share/fonts
fc-list | grep -E "Material Symbols Rounded|Rubik|CaskaydiaCove NF|Google Sans Flex"
```

## 4. Scripts

```bash
mkdir -p ~/.local/bin/omarchy-suse ~/.local/lib/omarchy-suse
install -m 755 bin/* ~/.local/bin/omarchy-suse/
install -m 644 lib/os-tui.sh ~/.local/lib/omarchy-suse/
```

The launcher and keybindings call the scripts by **full path** and don't
depend on `PATH`. To call them by name from a terminal, add this to your shell
profile:

```bash
export PATH="$HOME/.local/bin/omarchy-suse:$PATH"
```

## 5. Configuration

`shell.json` and `cli.json` contain an `@HOME@` placeholder. caelestia does
not expand `~` inside command arrays, so the real path has to be written at
install time:

```bash
mkdir -p ~/.config/hypr ~/.config/caelestia ~/.config/kitty
cp config/hypr/hyprland.lua config/hypr/hypridle.conf ~/.config/hypr/
install -m 755 config/hypr/baslat-caelestia.sh ~/.config/hypr/
sed "s|@HOME@|$HOME|g" config/caelestia/shell.json > ~/.config/caelestia/shell.json
sed "s|@HOME@|$HOME|g" config/caelestia/cli.json   > ~/.config/caelestia/cli.json
cp config/kitty/kitty.conf ~/.config/kitty/
touch ~/.config/kitty/caelestia.conf
```

Before copying, edit the **KİŞİSEL TERCİHLER** ("personal preferences")
block at the top of `config/hypr/hyprland.lua`: browser, file manager and
keyboard layout (`klavye = "tr"` — change it to `"us"`, `"de"`, …).

## 6. Session services

```bash
cp config/systemd/user/* ~/.config/systemd/user/
systemctl --user daemon-reload

for u in os-kontrol hypridle hyprpolkitagent xdg-desktop-portal xdg-desktop-portal-hyprland \
         gvfs-udisks2-volume-monitor gvfs-mtp-volume-monitor gvfs-gphoto2-volume-monitor gvfs-metadata; do
  systemctl --user add-wants hyprland-session.target "$u.service"
done
systemctl --user enable gcr-ssh-agent.socket gnome-keyring-daemon.socket
```

**Do not enable** `hyprland-session.target`. `baslat-caelestia.sh` starts it.
If it were enabled it would also fire in GNOME sessions. See
[TROUBLESHOOTING → GDM infinite password loop](TROUBLESHOOTING.md#gdm-infinite-password-loop).

## 7. Small fixes

```bash
# Screen recording — without this, caelestia record waits for an invisible polkit prompt
sudo setcap cap_sys_admin+ep /usr/bin/gsr-kms-server

# If the cursor shows up as an empty box
mkdir -p ~/.icons/default
printf '[Icon Theme]\nName=Default\nInherits=Adwaita\n' > ~/.icons/default/index.theme

# If folders open in a terminal
xdg-mime default org.gnome.Nautilus.desktop inode/directory
```

### GTK theme (optional)

caelestia's theme engine writes the `adw-gtk3-dark` theme for GTK apps. That
theme is **not** in the official repositories; it lives in an OBS community
repository. `adw-gtk3` and `adw-gtk3-dark` are **separate packages**;
installing only one is not enough. If you skip them, GTK apps open with plain
Adwaita and nothing else breaks.

```bash
sudo zypper addrepo -p 100 -f \
  https://download.opensuse.org/repositories/home:/soupglasses/openSUSE_Tumbleweed/ home_soupglasses
sudo zypper refresh
sudo zypper install adw-gtk3 adw-gtk3-dark
```

---

## First login

1. Log out. On the login screen click your user name, then choose
   **Hyprland** from the gear icon in the bottom-right corner.
2. The bar and wallpaper should appear. If they don't, look here first:

```bash
cat $XDG_RUNTIME_DIR/baslat-caelestia.log   # which step of the session chain stopped
qs -c caelestia log                         # the shell's own log (the real error is here)
```

3. Checklist:

| Check | Command | Expected |
|---|---|---|
| Session target | `systemctl --user is-active graphical-session.target` | `active` |
| Portal | `systemctl --user is-active xdg-desktop-portal` | `active` |
| SSH agent | `echo $SSH_AUTH_SOCK` | `/run/user/…/gcr/ssh` |
| X11 apps | `echo $DISPLAY` (in a terminal opened from the launcher) | a value like `:0`, not empty |
| VA-API | `vainfo` | `va_openDriver() returns 0` |
| Tray | globe icon in the bar | a menu opens on click |

## Installed files

| Path | Purpose |
|---|---|
| `~/.config/hypr/hyprland.lua` | Hyprland (Lua API) |
| `~/.config/hypr/baslat-caelestia.sh` | session starter |
| `~/.config/hypr/hypridle.conf` | dim at 5 min → lock at 8 → screen off at 10 → suspend at 30 |
| `~/.config/caelestia/shell.json` | launcher actions, session commands, bar |
| `~/.config/caelestia/cli.json` | theme engine + `postHook` |
| `~/.config/kitty/kitty.conf` | terminal (colors from `caelestia.conf`) |
| `~/.config/quickshell/caelestia` | → `/etc/xdg/quickshell/caelestia-shell` |
| `~/.config/systemd/user/hyprland-session.target` | session target |
| `~/.config/systemd/user/os-kontrol.service` | tray menu |
| `~/.config/systemd/user/hyprland-oturum-bekci.service` | crash cleanup |
| `~/.local/bin/omarchy-suse/` | 19 scripts |
| `~/.local/lib/omarchy-suse/os-tui.sh` | shared TUI layer |
| `~/.local/share/fonts/caelestia/` | fonts |
