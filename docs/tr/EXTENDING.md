🌐 [English](../en/EXTENDING.md) · **Türkçe**

# caelestia'yı çatal açmadan genişletmek

caelestia'nın QML koduna dokunmak (çatal) güçlüdür ama pahalıdır: her
`caelestia-shell` güncellemesinde birleştirme yapman gerekir. Bu belge, kodu
**hiç değiştirmeden** kabuğa kendi işlevlerini bağlamanın yollarını anlatıyor.
Bu depodaki 19 script'in hepsi bu yollarla bağlandı.

## 0. Önce: ayar mı, çatal mı?

caelestia'nın yapılandırma şeması derlenmiş bir C++ eklentisinde duruyor. Hangi
ayarın var olduğunun **tek doğru kaynağı** şu dosya:

```
/usr/lib64/qt6/qml/Caelestia/Config/caelestia-config.qmltypes
```

Kaynak kodu okumak için:

| Ne | Nerede |
|---|---|
| Kabuk (QML) | `/etc/xdg/quickshell/caelestia-shell/` |
| CLI + tema motoru (Python) | `/usr/lib/python3.*/site-packages/caelestia/` |
| Kısayol adları | `…/caelestia-shell/modules/Shortcuts.qml` |

Çatal gerektirenler (ayar değil): bar'ı üste almak, hızlı ayarlara yeni düğme
(kimlikler `Toggles.qml`'de sabit), launcher'ın açıklamalarda da araması,
Nexus'a yeni sayfa, dock.

## Bağlama noktaları

| Yol | Ne için | Nerede |
|---|---|---|
| [Launcher eylemi](#1-launcher-eylemi) | Arayarak çalıştırılan komutlar | `shell.json` |
| [Kısayol](#2-kısayol) | Tek tuşla | `hyprland.lua` |
| [Tema kancası](#3-tema-kancası-posthook) | Renk şeması değişince çalışanlar | `cli.json` |
| [Sistem tepsisi](#4-sistem-tepsisi-sni) | Durum gösteren menü | ayrı süreç + systemd |
| [Oturum komutları](#5-oturum-komutları) | Kapat/yeniden başlat/çıkış öncesine araya girmek | `shell.json` |
| [IPC](#6-ipc) | Kabuğun panellerini dışarıdan açmak | `qs ipc call` |

---

## 1. Launcher eylemi

`~/.config/caelestia/shell.json` → `launcher.actions`. Kabuk bu dosyayı
**canlı** okuyor, yeniden başlatmaya gerek yok.

```json
{
    "name": "Ekrandan metin oku · OCR · yazı tanıma · text",
    "description": "Bölge seç, metni panoya kopyala",
    "icon": "document_scanner",
    "command": ["/home/kullanici/.local/bin/omarchy-suse/os-yakala", "ocr"]
}
```

| Alan | Not |
|---|---|
| `name` | **Arama yalnızca bu alanda.** Eşanlamlıları buraya göm |
| `icon` | [Material Symbols](https://fonts.google.com/icons) adı |
| `command` | Dizi. **Tam yol yaz.** `~` genişletilmez, PATH'e güvenme |
| `dangerous` | `true` ise `launcher.enableDangerousActions` açık olmadıkça gizlenir |

Terminal isteyen bir TUI için: `["kitty", "-e", "/tam/yol/script"]`. Script
etkileşimli menü açıyorsa `--hold` gerekmez.

Launcher'ın eylem öneki `launcher.actionPrefix`. Varsayılan `>`; Türkçe Q
klavyede AltGr gerektirdiği için bu depoda `:`.

## 2. Kısayol

```lua
local os_bin = os.getenv("HOME") .. "/.local/bin/omarchy-suse"
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(os_bin .. "/os-yakala ocr"))
```

Çakışma kontrolü: `hyprctl binds -j | jq '.[] | select(.key=="T") | .modmask'`

caelestia'nın kendi panelleri için global kısayollar:
`hl.dsp.global("caelestia:launcher")`. Adlar `Shortcuts.qml`'de.

## 3. Tema kancası (`postHook`)

`~/.config/caelestia/cli.json`:

```json
"theme": {
    "postHook": [
        "/home/kullanici/.local/bin/omarchy-suse/os-kitty-tema",
        "/home/kullanici/.local/bin/omarchy-suse/os-kontrol --ikonlar",
        "hyprctl reload"
    ]
}
```

Duvar kağıdı veya şema her değiştiğinde sırayla çalışır. **Sıra önemli:**
dosya üretenler önce, `hyprctl reload` en sonda.

### Şema renklerini okumak

Tema motoru o anki şemayı iki biçimde yazıyor:

| Dosya | Biçim | Kim okur |
|---|---|---|
| `~/.local/state/caelestia/scheme.json` | `{ "name", "flavour", "mode", "colours": { "primary": "dcc74d", … } }` | script'ler |
| `~/.config/hypr/scheme/current.lua` | `return { primary = "dcc74d", … }` | `hyprland.lua` (`dofile`) |

Sık kullanılan anahtarlar: `primary` `onPrimary` `secondary` `tertiary`
`surface` `onSurface` `surfaceContainer` `surfaceContainerHigh` `outline`
`error` `onSurfaceVariant` ve terminal renkleri `term0`…`term15`.

```python
import json, pathlib
d = json.loads((pathlib.Path.home() / ".local/state/caelestia/scheme.json").read_text())
c = d.get("colours", d)
birincil = "#" + c["primary"]
```

**Her zaman yedek renk ver.** Dosya ilk açılışta yok olabilir. Bash'te
`lib/os-tui.sh` bunu senin için yapıyor (`TUI_PRIMARY` vb.).

## 4. Sistem tepsisi (SNI)

caelestia'nın bar'ındaki tepsi standart **StatusNotifierItem** protokolünü
konuşuyor, yani QML'e dokunmadan kendi ikonunu ve menünü koyabilirsin.
`bin/os-kontrol` çalışan, yorumlu bir örnek (Python + AyatanaAppIndicator3).

Bu yolun tuzakları hep aynı sebepten çıkıyor: **menüyü GTK değil, Quickshell
(Qt) çiziyor.**

| Tuzak | Sonuç | Çözüm |
|---|---|---|
| `Gtk.CheckMenuItem` + `toggled` | Tıklama hiçbir şey yapmaz. DBusMenu `clicked` gönderir, bu `activate`'e eşlenir | Normal öğe + `activate` |
| Menüyü `show` sinyalinde tazelemek | Etiketler ilk değerde donar. Tüketici `AboutToShow` çağırır, GTK `show` tetiklenmez | Birkaç saniyede bir durum imzası karşılaştır, değişince yeniden kur |
| `edit-paste`, `application-exit` gibi soneksiz adlar | Kırık kare. Qt, GTK gibi `-symbolic` yedeğine düşmez; GNOME'un Adwaita'sı bu adları yalnızca sonekli taşır | `-symbolic` sonekli adı yaz |
| Adwaita symbolic ikonları | Koyu menüde koyu ikon. GTK renklendirir, Quickshell renklendirmez | SVG'yi şema rengiyle kendin üret |
| İkon yalnızca `IconThemePath`'te | Kırık kare. caelestia önce tema araması yapar, yedek yolda uzantı eklemez | İkonu `~/.local/share/icons/hicolor/scalable/apps/` altına da yaz |
| Kabuk çalışırken hicolor'a yeni ikon eklemek | Görünmez. Qt ikon temasını **süreç başlarken** önbelleğe alır | Kabuğu yeniden başlat; kalıcı çözüm için ikonları kabuktan önce üret (`baslat-caelestia.sh`) |
| Durumu birkaç saniyede bir `hyprctl`/`pgrep`/CLI araçlarıyla yoklamak | Ölçülebilir CPU ve pil kaybı: 3 sn'de bir 6 süreç, 49 dakikada 40 sn CPU yedi ve işlemciyi derin uykudan alıkoydu | Hyprland soketine doğrudan bağlan, `pgrep` yerine `/proc`'u oku, D-Bus sinyallerine abone ol (ör. supergfxd `NotifyGfx`), kalanı seyrek yokla. `os-kontrol` saatte ~7 200 süreçten ~360'a indi |
| Her yoklamada `set_icon_full` çağırmak | Hiçbir şey değişmese de birkaç saniyede bir D-Bus trafiği | İkonu yalnızca durum değişince gönder |

### Ölçerek doğrulamak

Tahmin yerine Quickshell'e doğrudan sor. Tek kullanımlık bir QML dosyası:

```qml
// /tmp/ikon-olc.qml
import Quickshell
ShellRoot {
    Component.onCompleted: {
        for (const ad of ["edit-paste", "edit-paste-symbolic", "os-kontrol-sade"])
            console.log(ad, Quickshell.iconPath(ad, true) ? "VAR" : "yok");
        Qt.exit(0);
    }
}
```

```bash
qs -p /tmp/ikon-olc.qml
```

Platform temasının gerçekten yüklendiğini görmek için aynı yöntemle
`SystemPalette` oku. Tema yoksa Qt açık paletine düşer (`window: #efefef`).

Menü tıklamasını ekrana bakmadan D-Bus'tan taklit et:

```bash
busctl --user call <servis> /org/ayatana/NotificationItem/<ad>/Menu \
       com.canonical.dbusmenu Event isvu <öğe-id> clicked s "" 0
busctl --user call <servis> /org/ayatana/NotificationItem/<ad>/Menu \
       com.canonical.dbusmenu GetLayout iias 0 -1 0
```

### Servis olarak çalıştırmak

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

`systemctl --user add-wants hyprland-session.target os-kontrol.service` ile
bağla. Servis yalnızca Hyprland oturumunda gelir, GNOME'da gelmez.

## 5. Oturum komutları

caelestia'nın kapatma menüsü komutu doğrudan çalıştırıyor; araya animasyon
kancası yok. Ama **komutun kendisi `shell.json`'dan geliyor**:

```json
"session": {
    "commands": {
        "shutdown": ["/tam/yol/os-oturum", "kapat"],
        "reboot":   ["/tam/yol/os-oturum", "yeniden"],
        "logout":   ["/tam/yol/os-oturum", "cikis"]
    }
}
```

`bin/os-oturum` önce `qs -p` ile tam ekran bir geçiş QML'i çiziyor
(`WlrLayer.Overlay`), kısa bir süre bekliyor, sonra gerçek komutu çalıştırıyor.
Kendi versiyonunu yazarsan iki güvenlik ağını unutma:

1. QML içinde birkaç saniyelik zorunlu `Qt.exit(0)` zamanlayıcısı. Kaplama
   takılı kalırsa ekranı kalıcı olarak kaplar.
2. Komut başarısız olursa kaplama sürecini öldür.

`os-oturum dene` gerçek komutu çalıştırmadan yalnızca geçişi gösterir.

## 6. IPC

Kabuğun panellerini dışarıdan aç/kapat:

```bash
qs -c caelestia ipc call drawers toggle launcher
qs -c caelestia ipc call drawers toggle sidebar
qs -c caelestia ipc call lock lock
qs -c caelestia ipc show        # tüm hedefler ve fonksiyonlar
```

`caelestia` CLI'ı da aynı işi yapar ama bir Python süreci başlattığı için
yavaştır (ölçümde 400 ms'ye karşı 130 ms). Jest ve kısayollarda `qs ipc`
kullan.

---

## Terminal arayüzü: `lib/os-tui.sh`

Bash script'lerinin ortak katmanı. Renkleri caelestia şemasından `jq` ile
okur (≈3 ms; yoksa `python3`); dosya yoksa varsayılana düşer, script kırılmaz.
`gum` ve `fzf` yoksa düz `read` ve `select`'e düşer. Terminal yoksa (systemd,
cron) soru soran fonksiyonlar asla askıda kalmaz: `onay` hayır der,
`secim`/`ara` boş döner, `giris_al` varsayılanını verir.

```bash
#!/bin/bash
set -uo pipefail
source ~/.local/lib/omarchy-suse/os-tui.sh

giris "Örnek" "󰣇" "kısa açıklama"
if onay "Devam edilsin mi?"; then
    bekle "çalışıyor" sleep 2
    basari "bitti"
fi
kapanis
```

| Fonksiyon | İş |
|---|---|
| `giris ad ikon altyazi` | İlk açılışta kısa animasyon + başlık |
| `baslik ad ikon altyazi` | Animasyonsuz başlık |
| `bilgi` · `basari` · `uyari` · `hata` | İkonlu mesaj satırı (`hata` stderr'e) |
| `baslikcik metin` | Bölüm başlığı |
| `secim "soru" seçenek…` | Kısa menü (gum choose). Seçilen satırı yazdırır |
| `ara "başlık" ["önizleme {}"]` | stdin'den uzun, aranabilir liste (fzf) |
| `onay "soru" [evet]` | Evet/hayır. Varsayılan **hayır** |
| `giris_al "ipucu" [varsayılan]` | Metin girişi |
| `bekle "mesaj" komut…` | Spinner'la çalıştır |
| `ilerleme şu toplam "etiket"` | İlerleme çubuğu |
| `bildir …` | `notify-send` sarmalayıcısı. Kurulu değilse sessizce geçer |
| `ayrac` · `kapanis` | Düzen |

Değişkenler: `TUI_PRIMARY` `TUI_SURFACE` `TUI_ON_SURFACE` … (hex, `#`'siz),
`C_ANA` `C_IKI` `C_UC` `C_HATA` `C_SOLUK` (ANSI), `TUI_SIFIR`.

Menü seçimini **ikonla** eşleştir, metinle değil:

```bash
s=$(secim "Ne yapmak istiyorsun?" "󰐥  Kapat" "󰐊  Açılışta başlasın" "󰜺  Açılışta başlamasın")
case "$s" in
    "󰐥"*) kapat ;;
    "󰐊"*) etkinlestir ;;
    "󰜺"*) devre_disi ;;
esac
```

Nerd Font ikonları heredoc'lardan ve bazı editörlerden geçerken kaybolabiliyor.
Kaybolursa `$'\U000F0425'` biçiminde kaçışla yaz.

Bash tuzaklarının tam listesi: [TUZAKLAR → Script yazarken](TROUBLESHOOTING.md#script-yazarken)

## İncelemeye değer kaynaklar

```bash
araclar/referanslari-indir.sh
```

caelestia (shell, cli), Omarchy, Hyprland wiki ve diğer quickshell kabuklarını
`referanslar/` altına sığ klonlar. Omarchy'nin `bin/` dizini, dağıtıma
bağlı olmayan script fikirleriyle dolu. Bu depodaki script'lerin dokuzu
oradan uyarlandı (bkz. [`NOTICE.tr.md`](../../NOTICE.tr.md)).
