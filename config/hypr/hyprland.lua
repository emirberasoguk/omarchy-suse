-- ═══════════════════════════════════════════════════════════════════
--  Hyprland yapılandırması — omarchy-suse
--  Hyprland 0.56 (Lua config) · caelestia-shell 2.3 · openSUSE Tumbleweed
--
--  Bu dosya ~/.config/hypr/hyprland.lua olarak kurulur.
--  Lua API'si ve hyprctl tuzakları: docs/HYPRLAND-LUA.md
-- ═══════════════════════════════════════════════════════════════════

-- ═══ KİŞİSEL TERCİHLER — önce burayı düzenle ═══════════════════════
local mainMod         = "SUPER"
local terminal        = "kitty"
local tarayici        = "firefox"      -- Super+B (aç-veya-odaklan)
local tarayici_sinifi = "firefox"      -- pencere class'ında aranacak kelime
local dosya_yoneticisi = "nautilus"
local klavye          = "tr"           -- kb_layout

local HOME   = os.getenv("HOME")
local os_bin = HOME .. "/.local/bin/omarchy-suse"

-- ═══ ORTAM DEĞİŞKENLERİ ═══════════════════════════════════════════
-- Bunlar compositor başlamadan okunur, dosyanın en başında olmalı.

local function var_mi(yol)
    local f = io.open(yol, "r")
    if f then f:close(); return true end
    return false
end

-- HİBRİT GPU (Intel + NVIDIA dizüstüler) — İSTEĞE BAĞLI.
-- donanim/nvidia-hibrit/ altındaki udev kuralı kuruluysa /dev/dri/intel-igpu
-- ve /dev/dri/nvidia-dgpu takma adları oluşur. Kural yoksa bu blok hiçbir şey
-- yapmaz ve Hyprland GPU'yu kendisi seçer.
--
-- Neden takma ad: AQ_DRM_DEVICES yolları ":" ile ayırıyor, /dev/dri/by-path
-- yolları da ":" içeriyor (pci-0000:00:02.0-card). Ham card0/card1 ise
-- açılışlar arasında yer değiştirebiliyor.
--
-- Neden çalışma anında kuruluyor: supergfxctl -m Integrated NVIDIA'yı tamamen
-- kapatınca /dev/dri/nvidia-dgpu YOK OLUR. Sabit yazılsaydı Hyprland olmayan
-- bir cihazı açmaya çalışırdı.
if var_mi("/dev/dri/intel-igpu") then
    local gpular = { "/dev/dri/intel-igpu" }
    if var_mi("/dev/dri/nvidia-dgpu") then
        table.insert(gpular, "/dev/dri/nvidia-dgpu")
    end
    hl.env("AQ_DRM_DEVICES", table.concat(gpular, ":"))
end

-- DİKKAT: GBM_BACKEND ve LIBVA_DRIVER_NAME BİLEREK AYARLANMIYOR.
-- Yaygın rehberler "GBM_BACKEND=nvidia-drm" ve "LIBVA_DRIVER_NAME=nvidia"
-- ekletir. Hibrit sistemde compositor iGPU'da koşarken:
--   - GBM'i NVIDIA'ya zorlamak kırılma sebebidir;
--   - global LIBVA_DRIVER_NAME=nvidia, Intel render düğümü için nvidia arka
--     ucunu yükletmeye çalışıp vaInitialize'ı düşürür → ekran kaydı ve
--     tarayıcıda donanımsal video kod çözme sessizce çalışmaz.
-- Ayarsız bırakınca libva her cihaz için doğru sürücüyü kendi seçer.
-- NVIDIA'da koşması gereken uygulamalar için: prime-run <uygulama>
--
-- __GLX_VENDOR_LIBRARY_NAME=nvidia'yı global koymak da gereksiz: prime-run
-- onu uygulama başına zaten ayarlıyor. İhtiyacın varsa:
-- if var_mi("/dev/dri/nvidia-dgpu") then hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia") end

-- Qt / imleç
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
-- Qt uygulamaları ikon/renk/fontu GTK'den alsın (qt6-platformtheme-gtk3).
-- "qt6ct" yazıp paketi KURMAMAK en sık hatadır: var olmayan eklenti işaret
-- edilince Qt'nin hiç platform teması olmaz, QIcon::fromTheme() her adı boş
-- döndürür → tepside ve dosya seçicide kırık ikon kareleri. qt6ct'yi
-- tercih edersen önce paketi kur, sonra burayı "qt6ct" yap.
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")

-- SSH ajanı — gcr-ssh-agent.socket üzerinden.
-- GNOME'da gnome-session ayarlıyor; Hyprland'de kimse ayarlamazsa
-- SSH_AUTH_SOCK boş kalır ve anahtarla git/ssh çalışmaz.
hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/gcr/ssh")

-- Duvar kağıdı dizini — caelestia hem kabukta hem CLI'da ÖNCE bu değişkene
-- bakıyor, yoksa ~/Pictures/Wallpapers varsayıyor. Başka bir dizin
-- kullanıyorsan aç (launcher'ın :wallpaper listesi boş geliyorsa sebep budur):
-- hl.env("CAELESTIA_WALLPAPERS_DIR", HOME .. "/Resimler/Duvar")

-- ═══ MONİTÖRLER ═══════════════════════════════════════════════════
-- Çıkış adlarını görmek için: hyprctl monitors all
-- Canlı denemek için (dosyayı değiştirmeden):
--   hyprctl eval 'hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto" })'
-- Alanlar: output · mode · position · scale · transform (0-3) · mirror ·
--          disabled · vrr · bitdepth  (tam liste: /usr/share/hypr/stubs/hl.meta.lua)

-- Varsayılan: her çıkış tercih ettiği modda, otomatik yerleşim
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Örnekler — kendi çıkış adlarınla aç:
-- hl.monitor({ output = "eDP-1",    mode = "1920x1080@144", position = "0x0",     scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60",  position = "1920x0",  scale = 1 })  -- sağda
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60",  position = "-1920x0", scale = 1 })  -- solda
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", mirror = "eDP-1" })   -- yansıt
-- hl.monitor({ output = "eDP-1", disabled = true })                                              -- paneli kapat

-- ═══ OTOMATİK BAŞLAYANLAR ═════════════════════════════════════════
-- Tek giriş noktası. Polkit ajanı, portal, hypridle ve caelestia oradan
-- başlıyor — WAYLAND_DISPLAY/DISPLAY hazır olduktan SONRA. Neden ayrı script:
-- docs/TUZAKLAR.md → "caelestia açılışta gelmiyor".
hl.exec_cmd(HOME .. "/.config/hypr/baslat-caelestia.sh")

-- ═══ ŞEMA RENKLERİ ═══════════════════════════════════════════════
-- caelestia'nın theme.enableHypr'ı her tema değişiminde
-- ~/.config/hypr/scheme/current.lua dosyasını üretiyor (M3 renkleri,
-- `return { ad = "rrggbb", ... }`). Dosya üretilir ama hyprland.lua onu
-- kendiliğinden OKUMAZ — kenarlıklar şemaya ancak burada bağlanır.
local sema = {}
do
    local ok, r = pcall(dofile, HOME .. "/.config/hypr/scheme/current.lua")
    if ok and type(r) == "table" then sema = r end
end

-- Şemadan renk al; dosya yoksa/anahtar eksikse yedeğe düş.
local function renk(ad, yedek, alfa)
    local h = sema[ad]
    if type(h) ~= "string" or #h ~= 6 then h = yedek end
    return "rgba(" .. h .. (alfa or "ff") .. ")"
end

-- ═══ GENEL AYARLAR ════════════════════════════════════════════════
hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            -- Odaklı pencere: primary → secondary geçişi (şemadan).
            active_border   = {
                colors = { renk("primary", "a8cbe8", "ee"), renk("secondary", "b7c9d9", "ee") },
                angle  = 45,
            },
            -- Odaksız: yüzey konteyneri, arka planla kaynaşsın diye soluk.
            inactive_border = renk("surfaceContainerHigh", "1b2025", "aa"),
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        blur = {
            enabled = true,
            size    = 6,
            passes  = 3,
            new_optimizations = true,
        },
    },

    input = {
        kb_layout = klavye,
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            tap_to_click = true,
        },
    },

    dwindle = {
        preserve_split = true,
        smart_resizing = true,
    },

    animations = {
        enabled = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        -- caelestia kendi arkaplanını çiziyor
        disable_splash_rendering = true,
        -- GÜVENLİK AĞI — KAPATMA. DPMS kapalıyken tuş/fare ekranı geri getirsin.
        -- İkisi de false iken yanlış bir dpms komutu ekranı kalıcı kapatır ve
        -- geri dönüş yolu yalnızca güç tuşu kalır. Bkz. docs/HYPRLAND-LUA.md
        key_press_enables_dpms = true,
        mouse_move_enables_dpms = true,
    },
})

-- ═══ ANİMASYONLAR ═════════════════════════════════════════════════
-- Bezier/spring adları önce hl.curve() ile TANIMLANMALI. Hazır gelen tek ad
-- "default"; tanımsız bir ad kullanılırsa Hyprland config hata ekranı açar.

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

-- Yay (spring) eğrileri — Android benzeri yaylanma hissinin kaynağı
hl.curve("easy",   { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })
hl.curve("bouncy", { type = "spring", mass = 1, stiffness = 320,      dampening = 20 })

hl.animation({ leaf = "global",        enabled = true, speed = 8,   bezier = "default" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.5, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.0, spring = "bouncy", style = "popin 88%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.6, bezier = "linear", style = "popin 88%" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.4, bezier = "easeOutQuint" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.0, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.8, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4.0, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5, bezier = "linear",       style = "fade" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.0, spring = "easy",         style = "slide" })

-- ═══ TOUCHPAD JESTLERİ ════════════════════════════════════════════
-- Hyprland 0.56'da çıplak `gestures.workspace_swipe` anahtarı kaldırıldı;
-- yerine hl.gesture() geldi.

-- 3 ve 4 parmak yatay → çalışma alanları arası geçiş (GNOME ile aynı)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

-- 3 parmak yukarı → uygulama başlatıcı
--
-- NEDEN caelestia IPC: "launcher" kısayolu caelestia'nın kısayolları içinde
-- TEK istisna olarak tuş BIRAKILINCA tetikleniyor (onReleased). hl.dispatch
-- yalnızca "basıldı" gönderdiği için global kısayol üzerinden toggle hiç
-- çalışmıyor ("ok" döner, bir şey olmaz). hl.dsp.send_shortcut ise SPACE'i
-- odaktaki PENCEREYE gönderip metin alanına boşluk yazıyor — kullanılamaz.
hl.gesture({
    fingers = 3,
    direction = "up",
    action = function()
        hl.dispatch(hl.dsp.exec_cmd("qs -c caelestia ipc call drawers toggle launcher"))
    end,
})

-- 3 parmak aşağı → kenar çubuğu (bildirimler / hızlı ayarlar)
hl.gesture({
    fingers = 3,
    direction = "down",
    action = function() hl.dispatch(hl.dsp.exec_cmd("qs -c caelestia ipc call drawers toggle sidebar")) end,
})

hl.config({
    gestures = {
        workspace_swipe_create_new = true,   -- sondan sonra kaydırınca YENİ alan aç
        workspace_swipe_forever    = true,   -- parmağı kaldırmadan zincirleme geç
        workspace_swipe_distance   = 300,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_direction_lock = true,
        workspace_swipe_min_speed_to_force = 5,
    },
})

-- ═══ KISAYOLLAR ═══════════════════════════════════════════════════
-- GNOME kas hafızası korunuyor: Super+Q kapat, Super+Up tam ekran

-- Pencere
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + Return",    hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(dosya_yoneticisi))
hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Up",        hl.dsp.window.fullscreen({ mode = 1 }))  -- "maximize"
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))

-- Odak
hl.bind(mainMod .. " + left",      hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right",     hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + down",      hl.dsp.focus({ direction = "down" }))

-- Çalışma alanları (1-10) — her monitörde bağımsız
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Çalışma alanları arası hızlı geçiş (jestin klavye karşılığı)
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + CTRL + N",     hl.dsp.focus({ workspace = "empty" }))

-- Monitörler arası taşıma (GNOME'daki Super+Shift+Ok)
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ monitor = "r" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ monitor = "d" }))

-- Fare ile taşı/boyutlandır
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ═══ caelestia KABUK KISAYOLLARI ══════════════════════════════════
-- appid "caelestia" — /etc/xdg/quickshell/caelestia-shell/modules/Shortcuts.qml
hl.bind(mainMod .. " + SPACE",     hl.dsp.global("caelestia:launcher"))
hl.bind(mainMod .. " + D",         hl.dsp.global("caelestia:dashboard"))
hl.bind(mainMod .. " + S",         hl.dsp.global("caelestia:sidebar"))
hl.bind(mainMod .. " + N",         hl.dsp.global("caelestia:nexus"))      -- ayar uygulaması
hl.bind(mainMod .. " + U",         hl.dsp.global("caelestia:utilities"))
hl.bind(mainMod .. " + L",         hl.dsp.global("caelestia:lock"))
hl.bind(mainMod .. " + ESCAPE",    hl.dsp.global("caelestia:session"))
hl.bind(mainMod .. " + TAB",       hl.dsp.global("caelestia:showall"))
hl.bind("Print",                   hl.dsp.global("caelestia:screenshotFreeze"))
hl.bind("SHIFT + Print",           hl.dsp.global("caelestia:screenshotFreezeClip"))

-- GÜVENLİK AĞI: caelestia başlamazsa Super+Escape oturum menüsü açılmaz;
-- bu bind doğrudan Hyprland'i kapatır. Çıplak `exit` DEĞİL, hl.dsp.exit().
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())

-- ═══ DONANIM TUŞLARI ══════════════════════════════════════════════
-- Parlaklık ve medya caelestia üzerinden (OSD göstergesi için)
hl.bind("XF86MonBrightnessUp",   hl.dsp.global("caelestia:brightnessUp"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.global("caelestia:brightnessDown"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay",         hl.dsp.global("caelestia:mediaToggle"),    { locked = true })
hl.bind("XF86AudioPause",        hl.dsp.global("caelestia:mediaToggle"),    { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.global("caelestia:mediaNext"),      { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.global("caelestia:mediaPrev"),      { locked = true })

-- Ses (caelestia'da ses kısayolu yok, doğrudan wpctl)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })

-- Klavye ışığı — cihaz adı üreticiye göre değişir (asus::, tpacpi::, dell:: …),
-- joker hepsini yakalar. Cihazın yoksa komut sessizce başarısız olur.
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -d '*::kbd_backlight' set +1"), { locked = true })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d '*::kbd_backlight' set 1-"), { locked = true })

-- ASUS dizüstülerde "Armoury" tuşu (asusctl kuruluysa):
-- hl.bind("XF86Launch3", hl.dsp.exec_cmd("rog-control-center"))

-- ═══ UYGULAMA KISAYOLLARI (aç-veya-odaklan) ═════════════════════
-- Uygulama açıksa ona odaklanır, değilse başlatır.
local ac = os_bin .. "/os-ac-odaklan"
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(ac .. " " .. tarayici_sinifi .. " " .. tarayici))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(ac .. " " .. terminal .. " " .. terminal))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(ac .. " " .. dosya_yoneticisi .. " " .. dosya_yoneticisi))

-- ═══ ARAÇ KISAYOLLARI ═══════════════════════════════════════════
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd(os_bin .. "/os-gece"))          -- gece ışığı
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd(os_bin .. "/os-pano-kaydet"))  -- panoyu dosyaya
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(os_bin .. "/os-paylas pano"))  -- panoyu paylaş
hl.bind(mainMod .. " + CTRL + O",  hl.dsp.exec_cmd(os_bin .. "/os-pencere seffaflik"))
hl.bind(mainMod .. " + CTRL + G",  hl.dsp.exec_cmd(os_bin .. "/os-pencere bosluk"))

-- ═══ YAKALAMA (OCR / QR) ════════════════════════════════════════
-- Ekrandan alan seçip metin veya QR okur, sonucu panoya koyar.
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(os_bin .. "/os-yakala ocr"))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(os_bin .. "/os-yakala qr"))

-- ═══ KAPAK (LID) ANAHTARI ═══════════════════════════════════════
-- Harici monitör varsa kapak kapanınca kilitlenmez (clamshell).
-- Cihaz adı "Lid Switch" değilse: hyprctl devices → switches
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd(os_bin .. "/os-kapak kapandi"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(os_bin .. "/os-kapak acildi"),  { locked = true })
