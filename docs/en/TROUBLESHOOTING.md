🌐 **English** · [Türkçe](../tr/TROUBLESHOOTING.md)

# Troubleshooting

Every problem hit while building this setup is written down as
**symptom → cause → fix**. Most took long because the symptom pointed
somewhere else, so the evidence that settled each one is included too.

**First rule:** when something doesn't work, read the logs before guessing.

```bash
qs -c caelestia log                          # the shell's ring buffer — the most valuable source
cat $XDG_RUNTIME_DIR/baslat-caelestia.log     # the session chain
journalctl --user -b -u <unit>                # services
```

Contents:
[Installation and packaging](#installation-and-packaging) ·
[Session and startup](#session-and-startup) ·
[Display and power](#display-and-power) ·
[Theme and icons](#theme-and-icons) ·
[Apps and hardware](#apps-and-hardware) ·
[Writing scripts](#writing-scripts)

---

## Installation and packaging

### `nothing provides 'qt6qmlimport(qs.modules.bar.components.status)'`

**Cause:** The `home:kaiman` package metadata is incomplete. The content is
all there: `modules/bar/components/status/*.qml` is in the package, but since
the source has no `qmldir`, the RPM `Provides:` generator skips that
subdirectory. The rest of the `qs.*` namespace comes from the `quickshell`
package.

**Fix:** In zypper, choose "break … by ignoring some of its dependencies".
Verified with a QML compile test: not a single import error.

### Hyprland starts, the screen is black, only the cursor shows

**Cause:** `caelestia-cli` hard-codes `qs -c caelestia`, but the package
installs the shell as `caelestia-shell`. `caelestia shell -d` fails silently.

```
$ qs -c caelestia list
Could not find "caelestia" config directory in any valid config path.
```

**Fix:** `ln -sfn /etc/xdg/quickshell/caelestia-shell ~/.config/quickshell/caelestia`

### Text is huge, icons are empty boxes

**Cause:** None of the fonts caelestia expects are installed (Material Symbols
Rounded, Rubik, CaskaydiaCove NF). Qt falls back to a default font, the
metrics don't match and the layout falls apart.

**Fix:** [INSTALL → Fonts](INSTALL.md#b-fonts--huge-text-boxes-instead-of-icons)

### The GTK theme changes nothing

**Cause:** caelestia writes `adw-gtk3-dark`. `adw-gtk3` and `adw-gtk3-dark`
are **separate packages**. With only one installed, the theme name points
at nothing.

---

## Session and startup

### caelestia doesn't come up at login

**Symptom:** `quickshell: Failed to create wl_display (Connection refused)`,
`hyprpolkitagent: unmet condition ConditionEnvironment=WAYLAND_DISPLAY`

**Cause:** `hl.exec_cmd()` runs while the config is being parsed. At that
moment the compositor socket doesn't exist yet, so child processes have no
`WAYLAND_DISPLAY` at all.

**Fix:** `baslat-caelestia.sh` waits for the `wl_socket` **value** in
`hyprctl instances -j` to be filled in and for the socket file to actually
exist. `hyprctl` answering is not enough; the field is empty at first.

### Steam, Java apps, Wine don't open from the launcher

**Symptom:** The window never appears, no error dialog. Launched from a
terminal it works.

**Cause:** Exactly the same race as `WAYLAND_DISPLAY`. Xwayland is set up
after the compositor, so caelestia (started during config parsing) inherits
an empty `DISPLAY`. Every X11 app launched from the launcher inherits that
empty environment and exits with `Unable to open X11 display`.

**Fix:** `baslat-caelestia.sh` makes Hyprland run **the script itself**,
which writes Hyprland's real `DISPLAY` value to a file. The script verifies
the socket, then exports the value to the systemd and D-Bus environments.

> **Don't guess the value.** Scanning `/tmp/.X11-unix` gives the wrong
> address if another X server holds `:0`, and apps then hang instead. A
> `DISPLAY` that is set but dead is worse than an empty one.

### Nautilus is full of portal errors, the file chooser doesn't open

**Cause:** `graphical-session.target` is inactive, and
`xdg-desktop-portal.service` has `Requisite=graphical-session.target`. In
GNOME, gnome-session activates that target; under Hyprland nobody does.

**Fix:** `hyprland-session.target` (`BindsTo=graphical-session.target`).

Missing pieces of the same kind:

| Missing | Symptom |
|---|---|
| `gcr-ssh-agent.socket` + `SSH_AUTH_SOCK` | `git push` / `ssh` with keys fails |
| `gnome-keyring-daemon` | Apps don't remember passwords |
| `gvfs-*-volume-monitor` | USB drives and phones (MTP) don't show up |
| `hypridle` config | The screen never dims or locks |

> Do **not** add `StopWhenUnneeded=yes` to the target. It dies instantly.

### GDM infinite password loop

**Symptom:** After leaving Hyprland and logging into GNOME, the correct
password sends you straight back to the password screen.

```
gnome-session-i: A graphical session is already running!
systemd-coredump: Process (gnome-session-i) dumped core
```

**Cause:** `systemd --user` runs **per user**, not per session. Even after
Hyprland dies, `hyprland-session.target` stays active and keeps
`graphical-session-pre.target` up. GNOME waits for that target to become
inactive and crashes when it doesn't.

```
$ systemctl --user list-dependencies --reverse graphical-session-pre.target
graphical-session-pre.target
● └─hyprland-session.target        ← the only thing keeping it up
```

**Fix:** Three layers, so no single path is trusted:

1. `os-oturum cikis`: stops the target first on a normal logout
2. `hyprland-oturum-bekci.service`: stops it after a crash. It runs in the
   user manager so it isn't killed while the session is torn down.
3. `baslat-caelestia.sh`: stops a stale target before starting a new one

> **Lesson:** When you start a systemd target, write down who stops it at the
> same time.

### The session won't close, stuck in `closing`

**Cause:** caelestia's network module spawns `nmcli monitor`. When the shell
dies, that process is orphaned to PID 1 and **ignores SIGTERM**. A dead
session piles up on every logout.

**Fix:** `os-oturum` runs `pkill -KILL -u "$USER" -x nmcli` before logging
out. caelestia respawns it on its own afterwards.

### "Log out" in the session menu does nothing

**Cause:** `["hyprctl", "dispatch", "exit"]`. In the Lua config, the
`dispatch` argument is evaluated as Lua; `exit` is an undefined variable, so
it's `nil`.

**Fix:** `["hyprctl", "dispatch", "hl.dsp.exit()"]`. Details:
[HYPRLAND-LUA.md](HYPRLAND-LUA.md)

### Three-finger swipe up doesn't open the launcher

**Cause:** caelestia's `launcher` shortcut is the **only** one of its
shortcuts that fires on key release (`onReleased`). `hl.dispatch` only sends
"pressed". `hl.dsp.send_shortcut` sends SPACE to the focused **window** and
types a space into text fields.

**Fix:** The shell's own IPC:
`qs -c caelestia ipc call drawers toggle launcher`. About 400 ms through the
`caelestia` CLI, 130 ms with `qs ipc`.

---

## Display and power

### After closing and opening the lid, the screen never comes back

The **most dangerous** bug in this setup. The machine had to be powered off
with the power button.

**Cause 1:** `hypridle.conf` contained
`hyprctl dispatch 'hl.dsp.dpms("on")'`. `hl.dsp.dpms` expects a **table**,
and its values are `enable`/`disable`. `"on"` is an invalid argument and
falls back to `disable`, so the command **turns the screen off** instead of
on. Because the Lua syntax is valid, `hyprctl` returns `ok`.

**Cause 2:** `misc.key_press_enables_dpms` and `misc.mouse_move_enables_dpms`
were both `false`. Once the screen was off, nothing could bring it back.

**Fix:**

```bash
hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
```

Both safety options are now `true` as well; **don't turn them off**.

### Lid (clamshell) and runtime settings don't work

**Cause:** `hyprctl keyword` doesn't work with the Lua config:
`keyword can't work with non-legacy parsers. Use eval.`

**Fix:** `hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })'`
and `hyprctl eval 'hl.config({ ... })'`

### Where do I set the second monitor's position or mirroring?

caelestia's settings app (Nexus) doesn't have a monitor page upstream yet.
`nwg-displays` and `wdisplays` write their result to `monitors.conf` in the
old `.conf` format, and **the Lua config doesn't read it**. You can use them
to find the layout visually, but the result has to be written into
`hyprland.lua` by hand as `hl.monitor()`. Examples are in the file's
"MONİTÖRLER" (monitors) section.

Mirroring between outputs on different GPUs (e.g. the panel on Intel, HDMI on
NVIDIA) can be slow. Try it live with `hyprctl eval` first.

### Screen recording (`caelestia record`) hangs silently

Three layers:

1. `gsr-kms-server` lacks `cap_sys_admin` → it waits for an invisible polkit
   authentication. The program writes the fix into its own log:
   `sudo setcap cap_sys_admin+ep /usr/bin/gsr-kms-server`
2. A global `LIBVA_DRIVER_NAME=nvidia` → `vaInitialize` fails on the Intel
   render node. **Remove it.**
3. `intel-media-driver` isn't installed → there is no `iHD_drv_video.so`.
   VA-API doesn't work at all; the browser decodes video on the CPU too.

Verify: `vainfo` → `va_openDriver() returns 0`

---

## Theme and icons

### caelestia changes GNOME's theme

**Cause:** The theme engine (`theme.enableGtk`) writes `gtk-theme`,
`icon-theme`, `color-scheme` and `cursor-size` to dconf, which is shared with
GNOME.

**Fix:** Accept it or set `enableGtk: false`. For the icon theme, see the next
entry.

### The icon theme keeps switching to Papirus

**Cause:** `caelestia/utils/theme.py`:

```python
gtk_icon_theme = icon_theme if icon_theme is not None else f"Papirus-{mode.capitalize()}"
```

If not configured, `Papirus-Dark` is written every time a theme is applied.

**Fix:** `cli.json` → `"theme": { "iconTheme": "Adwaita" }` (or any theme you
like).

### The cursor is an empty or transparent box

**Cause:** The theme engine writes `cursor-theme='default'`, and no theme
called `default` exists on the system.

**Fix:** Satisfy the name instead of chasing the symptom:
`~/.icons/default/index.theme` → `Inherits=Adwaita`

### Pink-and-black checkerboard squares in the tray and file chooser

**Root cause:** `QT_QPA_PLATFORMTHEME=qt6ct` was set but the **`qt6ct`
package wasn't installed**. With a nonexistent plugin, Qt has no platform
theme at all, so `QIcon::fromTheme()` returns nothing for every name. Every Qt
app is affected. Qt also falls back to a light palette (`#efefef`
background), so you get white windows on a dark desktop.

**Fix:** `QT_QPA_PLATFORMTHEME=gtk3` (`qt6-platformtheme-gtk3`). It ties Qt
directly to GTK: same icon theme, same colors. If you want qt6ct, **install
it first**.

For the measurement method and Qt's other icon traps:
[EXTENDING → System tray](EXTENDING.md#4-system-tray-sni)

### New terminal windows don't pick up the theme

**Cause:** `theme.enableTerm` only produces OSC escape sequences and writes
them to `/dev/pts/*`, so it changes **open** terminals only.

**Fix:** `os-kitty-tema` generates `~/.config/kitty/caelestia.conf` from the
scheme, `kitty.conf` includes it, and `postHook` regenerates it on every theme
change.

### Window borders don't follow the theme

**Cause:** `theme.enableHypr` writes `~/.config/hypr/scheme/current.lua` on
every theme change, but **`hyprland.lua` never reads it**.

**Fix:** `hyprland.lua` loads the file with `dofile`, and `postHook` ends with
`hyprctl reload`. The cost: a reload resets runtime tweaks made with
`os-pencere`.

### btop generates the theme but doesn't use it

`btop.conf` still says `color_theme = "Default"`. Put caelestia's theme name
there.

---

## Apps and hardware

### Apps don't open from the launcher

**Symptom:** You click and nothing happens. The `.desktop` file is clean,
launching by hand works, and the systemd journal shows **no trace**.

**Evidence:** `qs -c caelestia log` →
`WARN qt.sql.qsqlquery: QSqlQuery::prepare: database not open`

**Cause:** `modules/launcher/services/Apps.qml`:

```qml
function launch(entry: DesktopEntry): void {
    appDb.incrementFrequency(entry.id);   // no SQLite driver → throws
    entry.execute();                       // never reached
}
```

openSUSE packages the Qt SQL drivers separately.

**Fix:** `sudo zypper install qt6-sql-sqlite`, then restart the shell.

### `:ocr` finds nothing in the launcher, but the full name does

**Cause:** Search is fuzzy, but only over the action's **`name`** field;
`description` is never searched (`Actions.qml` doesn't override the
Searcher's `key: "name"` default).

**Fix:** Embed synonyms in the name:
`"Ekrandan metin oku · OCR · yazı tanıma · text"`

### No notifications ever appear

**Cause:** `libnotify-tools` (i.e. `notify-send`) isn't installed. On top of
that, when `notify-send` is a script's last command the exit code becomes 127,
and scripts with `set -e` look like they failed.

**Fix:** Install the package. In scripts, use the `bildir()` wrapper from
`lib/os-tui.sh`.

### Folders open in a terminal

**Cause:** `xdg-mime query default inode/directory` → `kitty-open.desktop`

**Fix:** `xdg-mime default org.gnome.Nautilus.desktop inode/directory`

### LocalSend (flatpak) can't send files

**Cause:** The flatpak only has `xdg-download` permission and can't see files
in `/tmp`.

**Fix:** `os-paylas` first hardlinks everything into `~/Downloads/.os-paylas/`
(no extra space on the same filesystem).

### The Bluetooth toggle bounces back

**Cause:** Not the QML. An `rfkill` soft block:

```
bluetoothctl show         → PowerState: off-blocked
/sys/class/rfkill/rfkill0 → type=bluetooth soft=1
```

**Fix:** `echo 0 | sudo tee /sys/class/rfkill/rfkill0/soft && sudo systemctl restart bluetooth`

> **Lesson:** When a toggle doesn't work, don't blame the QML first. Read the
> real state of the service underneath.

### Wi-Fi sticks to the slow band, or "network could not be found"

**Cause:** caelestia's network module (`services/Nmcli.qml` →
`connectWireless`) **locks the profile to the BSSID** of the access point you
clicked when connecting with a password. With that lock, NetworkManager can't
choose a better AP or band. Forcing the band to `a` by hand conflicts with the
lock and drops the connection.

**Fix:** `os-wifi-durum temizle` removes the `bssid`/`band`/`channel` locks
from the profile. Pinning the band isn't needed: wpa_supplicant already
prefers 5 GHz.

> NetworkManager's `802-11-wireless.band` only accepts `a` and `bg`. A
> "pin to 6 GHz" option can't work.

### `supergfxctl -m Integrated` doesn't apply

**Cause:** A **reboot** follows the command. The reboot stops supergfxd before
it gets to unload the modules.

**Fix:** **Log out and back in** instead of rebooting. Details:
[donanim/nvidia-hibrit](../../donanim/nvidia-hibrit/README.md)

---

## Writing scripts

| Trap | Symptom | Do this instead |
|---|---|---|
| `pkill -f "pattern"` | Kills your own shell (its command line contains the pattern) | `pgrep -x` / `pkill -x` (process name) |
| `set -e` + `[[ cond ]] && { … }` as a function's last line | The script dies silently when the condition is false | An `if` block |
| Associative array + `set -u` | `unbound variable` | A plain array of `"name\|source\|description"` strings |
| `cmd; check "label $(…)" $?` | Every test "passes": `$(…)` runs first and overwrites `$?` | Pass the command as an argument and let the function run it |
| Embedding user input in `bash -c "… '$q' …"` | Quotes in the input break the command | Pass it via the environment: `Q="$q" bash -c '… "$Q" …'` |
| Matching menu choices by text | "Don't start at boot" matches a `*stop*` branch | Match on the leading icon |
| Pasting Nerd Font icons into heredocs | Icons vanish from the source | `$'\U000FXXXX'` escapes |
| `hyprctl getoption general:gaps_out` `.int` | `null` | This option returns `.css`: `"8 8 8 8"` |
| Relying on `PATH` for script names in the launcher | Works in a terminal, not from the launcher | Full paths |
