🌐 **English** · [Türkçe](../tr/HYPRLAND-LUA.md)

# Hyprland 0.56's Lua config and `hyprctl`

Hyprland 0.56 can read its configuration from **`hyprland.lua`** (the `hl.*`
API) instead of `hyprland.conf`. Most guides online still describe the old
syntax. With the Lua config, some of those commands fail with an error; worse,
some **return "ok" and do the wrong thing**.

## The golden rule

> `hyprctl` saying `ok` does not mean **"it worked"**. It means **"it parsed"**.

- A **syntax** error fails loudly (exit code 7).
- **Valid Lua with a wrong argument** returns `ok` (0) and does the wrong thing.

After a command, **read the state separately**:

```bash
hyprctl monitors -j | jq '.[] | {name, dpmsStatus, disabled}'
hyprctl getoption decoration:active_opacity -j
```

## Three command paths

| What you want | Correct command | Doesn't work |
|---|---|---|
| Change a config option | `hyprctl eval 'hl.config({ general = { gaps_out = 0 } })'` | `hyprctl keyword general:gaps_out 0` |
| Add/change/disable a monitor | `hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })'` | `hyprctl keyword monitor …` |
| Run a dispatcher | `hyprctl dispatch 'hl.dsp.window.float({ action = "toggle" })'` | `hyprctl dispatch togglefloating` |

**There is no legacy command path.** `hyprctl dispatch` evaluates its
argument as a Lua expression:

```
$ hyprctl dispatch dpms on
error: [string "return hl.dispatch(dpms on)"]:1: ')' expected near 'on'
```

`keyword` refuses outright:

```
keyword can't work with non-legacy parsers. Use eval.
```

## Two traps that turn your screen off

### 1. `dpms` takes a table

```bash
hyprctl dispatch 'hl.dsp.dpms("on")'                     # ✘ valid Lua → "ok" → TURNS THE SCREEN OFF
hyprctl dispatch 'hl.dsp.dpms({ action = "enable"  })'   # ✔ on
hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'   # ✔ off
```

`"on"` is an unrecognized argument and falls back to `disable`. If this
pattern is in `hypridle.conf`, the screen won't come back after you close and
open the lid.

**Safety net** in `hyprland.lua` — don't turn it off:

```lua
misc = {
    key_press_enables_dpms  = true,
    mouse_move_enables_dpms = true,
}
```

### 2. A bare dispatcher name becomes `nil`

```bash
hyprctl dispatch exit              # ✘ "exit" is an undefined Lua variable → nil → nothing happens
hyprctl dispatch 'hl.dsp.exit()'   # ✔
```

The same applies to caelestia's `shell.json` → `session.commands.logout`.

## Where to learn the correct form

**Don't guess.** There are two reliable sources:

| Source | Contents |
|---|---|
| `/usr/share/hypr/hyprland.lua` | The distribution's example config: binds, dispatcher calls |
| `/usr/share/hypr/stubs/hl.meta.lua` | Type definitions for the API: every function's fields (`HL.MonitorSpec`, …) |

For example, the monitor fields in the stubs:

```lua
---@class HL.MonitorSpec
---@field output string
---@field mode? string
---@field position? string
---@field scale? string|number
---@field transform? integer|boolean
---@field mirror? string
---@field disabled? boolean
---@field vrr? integer|boolean
---@field bitdepth? integer|boolean
```

To test whether a dispatcher name exists **without side effects**, call it
asking for a state that is already true and check the exit code. For example,
`hl.dsp.dpms({ action = "enable" })` while the screen is already on.

## Common tasks

### Monitors

```lua
-- Default
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Second screen on the left
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "-1920x0", scale = 1 })

-- Mirroring
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", mirror = "eDP-1" })

-- Rotated (portrait) screen
hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", transform = 1 })
```

Positions are in pixels from the 0x0 origin; the cursor crosses at the edges
that touch. Output names and supported modes: `hyprctl monitors all`

### Animation curves must be defined first

```lua
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("easy",         { type = "spring", mass = 1, stiffness = 238, dampening = 24 })
hl.animation({ leaf = "windows", enabled = true, speed = 4.5, spring = "easy" })
```

The only built-in name is `default`. Using an undefined name opens Hyprland's
config error screen.

### Gestures

`gestures.workspace_swipe` was removed in 0.56:

```lua
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({
    fingers = 3, direction = "up",
    action = function() hl.dispatch(hl.dsp.exec_cmd("command")) end,
})
```

### `getoption` field types

```bash
hyprctl getoption decoration:active_opacity -j | jq .float   # 1.000000
hyprctl getoption general:gaps_out -j | jq .css              # "8 8 8 8"  (.int returns null)
```

## Reading a value from Hyprland's live environment

`hyprctl eval` doesn't return values; it only says `ok`. To learn a variable
from Hyprland's own environment (e.g. `DISPLAY`), make Hyprland run a script
that writes the value to a file:

```bash
hyprctl eval 'hl.exec_cmd("/full/path/script --write /run/user/1000/value")'
```

`hyprctl dispatch exec /path` doesn't work: the argument is parsed as Lua and
there is no `hl.dsp.exec` dispatcher. The `--display-yaz` mode in
`baslat-caelestia.sh` is a working example of this technique.

## Runtime changes are not permanent

Everything done with `hyprctl eval` is reset on the next `hyprctl reload`.
caelestia's `postHook` reloads on every theme change, so anything that must
persist belongs in `hyprland.lua`.
