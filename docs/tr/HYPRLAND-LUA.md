🌐 [English](../en/HYPRLAND-LUA.md) · **Türkçe**

# Hyprland 0.56 Lua config'i ve `hyprctl`

Hyprland 0.56 yapılandırmayı `hyprland.conf` yerine **`hyprland.lua`** ile
okuyabiliyor (`hl.*` API). İnternetteki rehberlerin çoğu hâlâ eski sözdizimini
anlatıyor. Lua config'inde o komutların bir kısmı hata veriyor; daha kötüsü,
bir kısmı **"ok" dönüp yanlış işi yapıyor**.

## Altın kural

> `hyprctl`'in `ok` demesi **"çalıştı"** değil, **"ayrıştırıldı"** demektir.

- **Sözdizimi** hatalıysa gürültüyle patlar (çıkış kodu 7).
- **Geçerli Lua ama yanlış argüman** verirsen `ok` (0) döner ve yanlış işi yapar.

Komuttan sonra **durumu ayrıca oku**:

```bash
hyprctl monitors -j | jq '.[] | {name, dpmsStatus, disabled}'
hyprctl getoption decoration:active_opacity -j
```

## Üç komut yolu

| Ne yapacaksın | Doğru komut | Çalışmayan |
|---|---|---|
| Config anahtarı değiştir | `hyprctl eval 'hl.config({ general = { gaps_out = 0 } })'` | `hyprctl keyword general:gaps_out 0` |
| Monitör ekle/değiştir/kapat | `hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })'` | `hyprctl keyword monitor …` |
| Dispatcher çalıştır | `hyprctl dispatch 'hl.dsp.window.float({ action = "toggle" })'` | `hyprctl dispatch togglefloating` |

**Legacy komut yolu yok.** `hyprctl dispatch` argümanını Lua ifadesi olarak
değerlendiriyor:

```
$ hyprctl dispatch dpms on
error: [string "return hl.dispatch(dpms on)"]:1: ')' expected near 'on'
```

`keyword` açıkça reddediyor:

```
keyword can't work with non-legacy parsers. Use eval.
```

## Ekranı kapatan iki tuzak

### 1. `dpms` argümanı tablo ister

```bash
hyprctl dispatch 'hl.dsp.dpms("on")'                     # ✘ geçerli Lua → "ok" → EKRANI KAPATIR
hyprctl dispatch 'hl.dsp.dpms({ action = "enable"  })'   # ✔ aç
hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'   # ✔ kapat
```

`"on"` tanınmayan argüman olduğu için `disable`'a düşüyor. `hypridle.conf`'ta
bu kalıp varsa kapak kapanıp açıldığında ekran bir daha gelmez.

**Güvenlik ağı**, `hyprland.lua` içinde, kapatma:

```lua
misc = {
    key_press_enables_dpms  = true,
    mouse_move_enables_dpms = true,
}
```

### 2. Çıplak dispatcher adı `nil` olur

```bash
hyprctl dispatch exit              # ✘ "exit" tanımsız Lua değişkeni → nil → hiçbir şey
hyprctl dispatch 'hl.dsp.exit()'   # ✔
```

caelestia'nın `shell.json` → `session.commands.logout` için de aynısı geçerli.

## Doğru biçimi nereden öğrenirsin

**Tahmin etme.** İki güvenilir kaynak var:

| Kaynak | İçerik |
|---|---|
| `/usr/share/hypr/hyprland.lua` | Dağıtımın örnek config'i: bind'ler, dispatcher çağrıları |
| `/usr/share/hypr/stubs/hl.meta.lua` | API'nin tip tanımları: her fonksiyonun alanları (`HL.MonitorSpec` vb.) |

Örneğin monitör alanları stub'da şöyle yazıyor:

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

Bir dispatcher adının var olup olmadığını **yan etkisiz** sınamak için, zaten
geçerli olan durumu isteyen bir çağrı yap ve çıkış koduna bak. Örneğin ekran
açıkken `hl.dsp.dpms({ action = "enable" })`.

## Sık kullanılanlar

### Monitörler

```lua
-- Varsayılan
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- İkinci ekran solda
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "-1920x0", scale = 1 })

-- Yansıtma
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", mirror = "eDP-1" })

-- Döndürülmüş (dikey) ekran
hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", transform = 1 })
```

Konum, 0x0 noktasından piksel cinsinden yazılır; fare bitişik kenardan geçer.
Çıkış adları ve desteklenen modlar: `hyprctl monitors all`

### Animasyon eğrileri önce tanımlanmalı

```lua
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("easy",         { type = "spring", mass = 1, stiffness = 238, dampening = 24 })
hl.animation({ leaf = "windows", enabled = true, speed = 4.5, spring = "easy" })
```

Hazır gelen tek ad `default`. Tanımsız bir ad kullanırsan Hyprland config hata
ekranı açar.

### Jestler

0.56'da `gestures.workspace_swipe` kaldırıldı:

```lua
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({
    fingers = 3, direction = "up",
    action = function() hl.dispatch(hl.dsp.exec_cmd("komut")) end,
})
```

### `getoption` alan türleri

```bash
hyprctl getoption decoration:active_opacity -j | jq .float   # 1.000000
hyprctl getoption general:gaps_out -j | jq .css              # "8 8 8 8"  (.int null döner)
```

## Hyprland'in canlı ortamından değer okumak

`hyprctl eval` değer döndürmüyor, yalnızca `ok` diyor. Hyprland'in kendi
ortamındaki bir değişkeni (ör. `DISPLAY`) öğrenmenin yolu, Hyprland'e bir
script çalıştırtıp değeri dosyaya yazdırmak:

```bash
hyprctl eval 'hl.exec_cmd("/tam/yol/script --yaz /run/user/1000/deger")'
```

`hyprctl dispatch exec /yol` çalışmaz: argüman Lua olarak ayrıştırılır ve
`hl.dsp.exec` diye bir dispatcher yok. `baslat-caelestia.sh`'teki
`--display-yaz` modu bu yöntemin çalışan örneği.

## Çalışma anı değişiklikleri kalıcı değil

`hyprctl eval` ile yapılan her şey bir sonraki `hyprctl reload`'da sıfırlanır.
caelestia'nın `postHook`'u her tema değişiminde reload attığı için, kalıcı
olması gerekenleri `hyprland.lua`'ya yaz.
