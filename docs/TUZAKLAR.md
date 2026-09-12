# Tuzaklar ve çözümleri

Bu kurulumda karşılaşılan her sorun **belirti → sebep → çözüm** olarak
yazıldı. Çoğu, belirtinin sebebi göstermediği için uzun sürdü; hangi kanıtla
çözüldüğü de yazılı.

**İlk kural:** Bir şey çalışmıyorsa tahmin etmeden önce günlüğe bak.

```bash
qs -c caelestia log                          # kabuğun halka tamponu — en değerli kaynak
cat $XDG_RUNTIME_DIR/baslat-caelestia.log     # oturum zinciri
journalctl --user -b -u <birim>               # servisler
```

İçindekiler:
[Kurulum ve paketleme](#kurulum-ve-paketleme) ·
[Oturum ve başlatma](#oturum-ve-başlatma) ·
[Ekran ve güç](#ekran-ve-güç) ·
[Tema ve ikonlar](#tema-ve-ikonlar) ·
[Uygulamalar ve donanım](#uygulamalar-ve-donanım) ·
[Script yazarken](#script-yazarken)

---

## Kurulum ve paketleme

### `nothing provides 'qt6qmlimport(qs.modules.bar.components.status)'`

**Sebep:** `home:kaiman` paketinin meta verisi eksik. İçerik tam:
`modules/bar/components/status/*.qml` pakette var, ama kaynakta `qmldir`
olmadığı için RPM'in `Provides:` üreteci bu alt dizini atlıyor. `qs.*` ad
alanının geri kalanı `quickshell` paketinden geliyor.

**Çözüm:** zypper'da "bağımlılığı yok sayarak kur" seçeneğini seç. QML derleme
testiyle doğrulandı: tek bir import hatası yok.

### Hyprland açılıyor, ekran simsiyah, yalnızca imleç var

**Sebep:** `caelestia-cli` sabit olarak `qs -c caelestia` çağırıyor, paket
kabuğu `caelestia-shell` adıyla kuruyor. `caelestia shell -d` sessizce
başarısız oluyor.

```
$ qs -c caelestia list
Could not find "caelestia" config directory in any valid config path.
```

**Çözüm:** `ln -sfn /etc/xdg/quickshell/caelestia-shell ~/.config/quickshell/caelestia`

### Yazılar dev gibi, ikonların yerinde boş kutular

**Sebep:** caelestia'nın beklediği fontların hiçbiri kurulu değil (Material
Symbols Rounded, Rubik, CaskaydiaCove NF). Qt varsayılana düşünce metrikler
tutmuyor ve yerleşim dağılıyor.

**Çözüm:** [KURULUM → Fontlar](KURULUM.md#b-fontlar--dev-yazılar-kutu-ikonlar)

### GTK teması hiçbir şeyi değiştirmiyor

**Sebep:** caelestia `adw-gtk3-dark` yazıyor. `adw-gtk3` ve `adw-gtk3-dark`
**ayrı paketler**. Yalnızca birini kurunca tema adı hiçbir şeyi işaret etmiyor.

---

## Oturum ve başlatma

### caelestia açılışta gelmiyor

**Belirti:** `quickshell: Failed to create wl_display (Connection refused)`,
`hyprpolkitagent: unmet condition ConditionEnvironment=WAYLAND_DISPLAY`

**Sebep:** `hl.exec_cmd()` config ayrıştırılırken çalışıyor. O anda compositor
soketi henüz yok, çocuk süreçlerde `WAYLAND_DISPLAY` hiç tanımlı değil.

**Çözüm:** `baslat-caelestia.sh`, `hyprctl instances -j` içindeki `wl_socket`
**değerinin dolmasını** ve soket dosyasının gerçekten oluşmasını bekliyor.
`hyprctl`'in cevap vermesi yetmez; alan önce boş geliyor.

### Steam, Java uygulamaları, Wine launcher'dan açılmıyor

**Belirti:** Pencere hiç gelmiyor, hata kutusu yok. Terminalden açınca
çalışıyor.

**Sebep:** `WAYLAND_DISPLAY` ile birebir aynı yarış. Xwayland compositor'dan
sonra kuruluyor, config sırasında başlatılan caelestia'nın ortamında `DISPLAY`
boş kalıyor. Launcher'dan açılan her X11 uygulaması bu boş ortamı miras alıp
`Unable to open X11 display` diyerek kapanıyor.

**Çözüm:** `baslat-caelestia.sh` Hyprland'e **kendisini** çalıştırtıp gerçek
`DISPLAY` değerini dosyaya yazdırıyor, soketi doğruluyor, sonra systemd ve
D-Bus ortamına aktarıyor.

> **Değeri tahmin etme.** `/tmp/.X11-unix` taraması, `:0`'ı tutan başka bir X
> sunucusu varsa yanlış adresi verir ve uygulamalar bu sefer donar. Dolu ama
> ölü bir `DISPLAY`, boş `DISPLAY`'den kötüdür.

### Nautilus portal hatalarıyla dolu, dosya seçici açılmıyor

**Sebep:** `graphical-session.target` inaktif. `xdg-desktop-portal.service`'in
`Requisite=graphical-session.target` satırı var. GNOME'da bu hedefi
gnome-session etkinleştiriyor; Hyprland'de kimse etkinleştirmiyor.

**Çözüm:** `hyprland-session.target` (`BindsTo=graphical-session.target`).

Aynı sınıftan eksikler:

| Eksik | Belirti |
|---|---|
| `gcr-ssh-agent.socket` + `SSH_AUTH_SOCK` | Anahtarla `git push` / `ssh` çalışmıyor |
| `gnome-keyring-daemon` | Uygulamalar parolaları hatırlamıyor |
| `gvfs-*-volume-monitor` | USB bellek, telefon (MTP) görünmüyor |
| `hypridle` yapılandırması | Ekran hiç kararmıyor/kilitlenmiyor |

> Hedefe `StopWhenUnneeded=yes` **ekleme**. Hedef anında ölür.

### GDM sonsuz şifre döngüsü

**Belirti:** Hyprland'den çıkıp GNOME'a girmeye çalışınca doğru şifreden sonra
tekrar şifre ekranı geliyor.

```
gnome-session-i: A graphical session is already running!
systemd-coredump: Process (gnome-session-i) dumped core
```

**Sebep:** `systemd --user` oturum başına değil **kullanıcı başına** çalışıyor.
Hyprland ölse bile `hyprland-session.target` ayakta kalıyor ve
`graphical-session-pre.target`'ı ayakta tutuyor. GNOME o hedefin inaktif
olmasını bekliyor, olmayınca çöküyor.

```
$ systemctl --user list-dependencies --reverse graphical-session-pre.target
graphical-session-pre.target
● └─hyprland-session.target        ← onu ayakta tutan tek şey
```

**Çözüm:** Tek yola güvenmeyen üç katman:

1. `os-oturum cikis`: normal çıkışta önce hedefi durdurur
2. `hyprland-oturum-bekci.service`: çökmede durdurur. Kullanıcı
   yöneticisinde çalışır ki oturum yıkılırken öldürülmesin.
3. `baslat-caelestia.sh`: başlarken bayat hedefi önce durdurur

> **Ders:** Bir systemd hedefini başlatıyorsan, onu kimin durduracağını da aynı
> anda yaz.

### Oturum kapanmıyor, `closing` durumunda asılı kalıyor

**Sebep:** caelestia'nın ağ modülü `nmcli monitor` başlatıyor. Kabuk ölünce
süreç öksüz kalıp PID 1'e devroluyor ve **SIGTERM'i yok sayıyor**. Her çıkışta
bir ölü oturum birikiyor.

**Çözüm:** `os-oturum` çıkıştan önce `pkill -KILL -u "$USER" -x nmcli`
çalıştırıyor. caelestia süreci sonra kendiliğinden yeniden başlatıyor.

### Oturum menüsünde "Çıkış" hiçbir şey yapmıyor

**Sebep:** `["hyprctl", "dispatch", "exit"]`. Lua config'inde `dispatch`
argümanı Lua olarak değerlendiriliyor; `exit` tanımsız değişken, `nil`.

**Çözüm:** `["hyprctl", "dispatch", "hl.dsp.exit()"]`. Ayrıntı:
[HYPRLAND-LUA.md](HYPRLAND-LUA.md)

### 3 parmak yukarı launcher'ı açmıyor

**Sebep:** caelestia'nın `launcher` kısayolu, kısayolları içinde **tek**
istisna olarak tuş bırakılınca (`onReleased`) tetikleniyor. `hl.dispatch`
yalnızca "basıldı" gönderiyor. `hl.dsp.send_shortcut` ise SPACE tuşunu
odaktaki **pencereye** gönderip metin alanına boşluk yazıyor.

**Çözüm:** Kabuğun kendi IPC'si:
`qs -c caelestia ipc call drawers toggle launcher`. `caelestia` CLI üzerinden
400 ms, `qs ipc` ile 130 ms.

---

## Ekran ve güç

### Kapak kapanıp açılınca ekran bir daha gelmiyor

Bu kurulumdaki **en tehlikeli** hata. Makineyi güç tuşuyla kapatmak gerekti.

**Sebep 1:** `hypridle.conf`'ta `hyprctl dispatch 'hl.dsp.dpms("on")'`.
`hl.dsp.dpms` **tablo** bekliyor ve değerleri `enable`/`disable`. `"on"`
geçersiz argüman olduğu için `disable`'a düşüyor. Komut ekranı açacağına
**kapatıyor**. Lua sözdizimi geçerli olduğu için `hyprctl` `ok` dönüyor.

**Sebep 2:** `misc.key_press_enables_dpms` ve `misc.mouse_move_enables_dpms`
ikisi de `false`. Ekran bir kez kapanınca geri getirmenin yolu kalmıyor.

**Çözüm:**

```bash
hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
```

Ek olarak iki güvenlik ayarı da `true` yapıldı; bunları **kapatma**.

### Kapak (clamshell) ve çalışma anı ayarları çalışmıyor

**Sebep:** `hyprctl keyword` Lua config'inde çalışmıyor:
`keyword can't work with non-legacy parsers. Use eval.`

**Çözüm:** `hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })'`
ve `hyprctl eval 'hl.config({ ... })'`

### İkinci monitörün yerini/yansıtmayı nereden ayarlarım?

caelestia'nın ayar uygulamasında (Nexus) monitör sayfası upstream'de henüz yok.
`nwg-displays` ve `wdisplays` ayarı eski `.conf` biçiminde `monitors.conf`'a
yazıyor ve **Lua config onu okumuyor**. Konumu görsel olarak bulmak için
kullanılabilirler, ama sonucu `hyprland.lua`'ya `hl.monitor()` olarak elle
yazmak gerekir. Örnekler dosyanın "MONİTÖRLER" bölümünde.

İki farklı GPU'ya bağlı çıkışlar arasında yansıtma (ör. panel Intel'de, HDMI
NVIDIA'da) yavaş olabilir. Önce `hyprctl eval` ile canlı dene.

### Ekran kaydı (`caelestia record`) sessizce asılı kalıyor

Üç katmanlı:

1. `gsr-kms-server`'da `cap_sys_admin` yok → görünmeyen bir polkit doğrulaması
   bekliyor. Program çözümü kendi günlüğüne yazıyor:
   `sudo setcap cap_sys_admin+ep /usr/bin/gsr-kms-server`
2. Global `LIBVA_DRIVER_NAME=nvidia` → Intel render düğümünde `vaInitialize`
   düşüyor. **Kaldır.**
3. `intel-media-driver` kurulu değil → `iHD_drv_video.so` yok. VA-API hiç
   çalışmıyor; tarayıcı videoları da CPU'da.

Doğrulama: `vainfo` → `va_openDriver() returns 0`

---

## Tema ve ikonlar

### caelestia GNOME'un temasını değiştiriyor

**Sebep:** Tema motoru (`theme.enableGtk`) dconf'a `gtk-theme`, `icon-theme`,
`color-scheme`, `cursor-size` yazıyor. dconf GNOME ile ortak.

**Çözüm:** Kabul et ya da `enableGtk: false`. İkon teması için bir sonraki
maddeye bak.

### İkon teması durup dururken Papirus oluyor

**Sebep:** `caelestia/utils/theme.py`:

```python
gtk_icon_theme = icon_theme if icon_theme is not None else f"Papirus-{mode.capitalize()}"
```

Ayarlanmazsa her tema uygulamasında `Papirus-Dark` yazılıyor.

**Çözüm:** `cli.json` → `"theme": { "iconTheme": "Adwaita" }` (ya da
istediğin tema).

### İmleç boş/şeffaf kutu

**Sebep:** Tema motoru `cursor-theme='default'` yazıyor. `default` teması
sistemde yok.

**Çözüm:** Semptomu kovalamak yerine adı karşıla:
`~/.icons/default/index.theme` → `Inherits=Adwaita`

### Tepside, dosya seçicide pembe-siyah damalı kareler

**Kök neden:** `QT_QPA_PLATFORMTHEME=qt6ct` yazılmış ama **`qt6ct` paketi
kurulu değil**. Var olmayan eklenti işaret edilince Qt'nin hiç platform teması
olmuyor ve `QIcon::fromTheme()` her adı boş döndürüyor. Bütün Qt uygulamaları
etkileniyor. Üstelik Qt açık temaya düşüyor (`#efefef` zemin), yani koyu
masaüstünde beyaz pencereler çıkıyor.

**Çözüm:** `QT_QPA_PLATFORMTHEME=gtk3` (`qt6-platformtheme-gtk3`). Qt'yi
doğrudan GTK'ye bağlıyor: aynı ikon teması, aynı renkler. qt6ct istiyorsan
**önce kur**.

Ölçüm yöntemi ve Qt'nin diğer ikon tuzakları için:
[EKLENTI-YAZMA → Sistem tepsisi](EKLENTI-YAZMA.md#4-sistem-tepsisi-sni)

### Yeni terminal pencereleri temayı almıyor

**Sebep:** `theme.enableTerm` yalnızca OSC kaçış dizileri üretip `/dev/pts/*`'e
yazıyor, yani yalnızca **açık** terminalleri değiştiriyor.

**Çözüm:** `os-kitty-tema` şemadan `~/.config/kitty/caelestia.conf` üretiyor,
`kitty.conf` onu include ediyor, `postHook` her tema değişiminde yeniliyor.

### Pencere kenarlıkları temayla değişmiyor

**Sebep:** `theme.enableHypr` her tema değişiminde
`~/.config/hypr/scheme/current.lua` üretiyor. Ama **`hyprland.lua` onu okumuyor**.

**Çözüm:** `hyprland.lua` dosyayı `dofile` ile yüklüyor. `postHook`'un
sonunda `hyprctl reload` var. Bedeli: reload, `os-pencere` ile yapılmış
çalışma anı ayarlarını sıfırlıyor.

### btop temayı üretiyor ama kullanmıyor

`btop.conf`'ta `color_theme = "Default"` duruyor. caelestia temasının adını
oraya yaz.

---

## Uygulamalar ve donanım

### Launcher'dan uygulama açılmıyor

**Belirti:** Tıklıyorsun, hiçbir şey olmuyor. `.desktop` temiz, elle açınca
çalışıyor, systemd günlüğünde **hiç iz yok**.

**Kanıt:** `qs -c caelestia log` →
`WARN qt.sql.qsqlquery: QSqlQuery::prepare: database not open`

**Sebep:** `modules/launcher/services/Apps.qml`:

```qml
function launch(entry: DesktopEntry): void {
    appDb.incrementFrequency(entry.id);   // SQLite sürücüsü yok → istisna
    entry.execute();                       // buraya hiç gelinmiyor
}
```

openSUSE Qt SQL sürücülerini ayrı paketliyor.

**Çözüm:** `sudo zypper install qt6-sql-sqlite`, sonra kabuğu yeniden başlat.

### Launcher'da `:ocr` sonuç vermiyor, `:metin oku` veriyor

**Sebep:** Arama fuzzy, ama yalnızca eylemin **`name`** alanında yapılıyor;
`description` hiç aranmıyor (`Actions.qml`, Searcher'ın `key: "name"`
varsayılanını değiştirmiyor).

**Çözüm:** Eşanlamlıları ada göm:
`"Ekrandan metin oku · OCR · yazı tanıma · text"`

### Bildirimler hiç görünmüyor

**Sebep:** `libnotify-tools` (yani `notify-send`) kurulu değil. Üstelik
`notify-send` script'in son komutuysa çıkış kodu 127 oluyor ve `set -e`'li
script'ler başarısız görünüyor.

**Çözüm:** Paketi kur. Script'lerde `bildir()` sarmalayıcısını kullan
(`lib/os-tui.sh`).

### Klasörler terminalde açılıyor

**Sebep:** `xdg-mime query default inode/directory` → `kitty-open.desktop`

**Çözüm:** `xdg-mime default org.gnome.Nautilus.desktop inode/directory`

### LocalSend (flatpak) dosya gönderemiyor

**Sebep:** Flatpak izinleri yalnızca `xdg-download`. `/tmp`'deki dosyayı
göremiyor.

**Çözüm:** `os-paylas` her şeyi önce `~/Downloads/.os-paylas/` altına
hardlink'liyor (aynı dosya sisteminde yer kaplamaz).

### Bluetooth düğmesi geri sekiyor

**Sebep:** QML değil. `rfkill` yazılımsal bloğu:

```
bluetoothctl show         → PowerState: off-blocked
/sys/class/rfkill/rfkill0 → type=bluetooth soft=1
```

**Çözüm:** `echo 0 | sudo tee /sys/class/rfkill/rfkill0/soft && sudo systemctl restart bluetooth`

> **Ders:** Bir düğme çalışmıyorsa önce QML'i suçlama. Altındaki servisin
> gerçek durumunu oku.

### Wi-Fi yavaş banda takılıyor ya da "network could not be found"

**Sebep:** caelestia'nın ağ modülü (`services/Nmcli.qml` → `connectWireless`)
şifreyle bağlanırken profili tıkladığın AP'nin **BSSID'sine kilitliyor**. Kilit
varken NetworkManager daha iyi AP'yi/bandı seçemiyor. Bandı elle `a`'ya
sabitlemek de kilitle çelişip bağlantıyı düşürüyor.

**Çözüm:** `os-wifi-durum temizle` profildeki `bssid`/`band`/`channel`
kilitlerini kaldırır. Band sabitlemeye gerek yok: wpa_supplicant 5 GHz'e zaten
öncelik veriyor.

> NM'nin `802-11-wireless.band` alanı yalnızca `a` ve `bg` kabul ediyor.
> "6 GHz sabitle" diye bir seçenek çalışmaz.

### `supergfxctl -m Integrated` uygulanmıyor

**Sebep:** Komuttan sonra **reboot** atılıyor. Reboot, supergfxd modülleri
boşaltmaya fırsat bulamadan servisi durduruyor.

**Çözüm:** Reboot değil **oturumu kapatıp aç**. Ayrıntı:
[donanim/nvidia-hibrit](../donanim/nvidia-hibrit/README.md)

---

## Script yazarken

| Tuzak | Belirti | Doğrusu |
|---|---|---|
| `pkill -f "desen"` | Kendi kabuğunu öldürür (komut satırı deseni içeriyor) | `pgrep -x` / `pkill -x` (süreç adı) |
| `set -e` + `[[ koşul ]] && { … }` fonksiyonun son satırı | Koşul yanlışsa script sessizce ölür | `if` bloğu |
| İlişkisel dizi + `set -u` | `unbound variable` | `"ad\|kaynak\|açıklama"` biçiminde düz dizi |
| `komut; kontrol "etiket $(…)" $?` | Her test "geçti" görünür: `$(…)` önce çalışıp `$?`'i ezer | Komutu fonksiyona argüman ver, çalıştırmayı o yapsın |
| Kullanıcı girdisini `bash -c "… '$q' …"` içine gömmek | Tırnaklı girdi komutu kırar | Ortam değişkeniyle geçir: `Q="$q" bash -c '… "$Q" …'` |
| Menü seçimini metinle eşleştirmek | "Açılışta başlamasın" `*kapat*` dalına girer | Satır başındaki ikonla eşleştir |
| Nerd Font ikonlarını heredoc'a yapıştırmak | İkonlar kaynakta kaybolur | `$'\U000FXXXX'` kaçışları |
| `hyprctl getoption general:gaps_out` `.int` | `null` | Bu alan `.css` döndürür: `"8 8 8 8"` |
| Launcher'da script adını PATH'e güvenerek yazmak | Launcher'dan çalışmaz | Tam yol |
