🌐 [English](README.md) · **Türkçe**

# omarchy-suse

openSUSE Tumbleweed için **Hyprland + caelestia** masaüstü: kurulum script'i,
çalışan yapılandırma, 19 yardımcı script ve yolda öğrenilmiş tuzakların
belgesi.

> *English:* A Turkish-language setup for Hyprland 0.56 (Lua config) with the
> caelestia shell on openSUSE Tumbleweed: an interactive installer, working
> configs, 19 helper scripts (tray menu, OCR/QR, web apps, AppImage, updates…)
> and a detailed troubleshooting guide for the pitfalls along the way.

> Belgelerin tamamı İngilizce ve Türkçe mevcut ([dizin](docs/README.md)).

Omarchy'den ilham alındı: parça parça değil, **bütünleşik** hissettiren bir
Hyprland masaüstü. Omarchy Arch'a bağlı, caelestia ise openSUSE'yi resmi olarak
desteklemiyor. Bu depo o boşluğu dolduruyor.

## Kimin için

- openSUSE'ye **Hyprland + caelestia** kurmak isteyenler. Paketleme hataları,
  eksik fontlar, siyah ekran ve çalışmayan launcher gibi sorunların hepsi
  çözümüyle birlikte yazılı.
- caelestia'yı **çatal (fork) açmadan** genişletmek, kendi script'ini
  launcher'a, sistem tepsisine ya da tema motoruna bağlamak isteyenler.
- Hyprland'in yeni **Lua config**'inde `hyprctl`'in neden "ok" deyip yanlış
  işi yaptığını merak edenler.

## Test edilen ortam

| | |
|---|---|
| Dağıtım | openSUSE Tumbleweed |
| Compositor | Hyprland 0.56.2 (Lua yapılandırma: `hyprland.lua`) |
| Kabuk | caelestia-shell 2.3.0 · caelestia-cli 1.1.2 · quickshell 0.3.1 (`home:kaiman`) |
| Giriş | GDM. **GNOME yan yana kurulu kalır**, ikisi arasında giriş ekranından seçilir |
| Donanım | Intel + NVIDIA hibrit dizüstü. Tek GPU'lu makinelerde de çalışır |

## Kurulum

```bash
git clone <bu-deponun-adresi> omarchy-suse
cd omarchy-suse
./kurulum.sh
```

`kurulum.sh` yedi faz halinde ilerler. Her fazda ne yapacağını gösterir ve
**sorar**; varsayılan cevap yoktur, zypper'ın kendi onayları da olduğu gibi
kalır. Üzerine yazılan her dosya önce `~/.local/state/omarchy-suse/yedek/`
altına yedeklenir.

Script çalıştırmadan adım adım anlamak istersen: [`docs/tr/INSTALL.md`](docs/tr/INSTALL.md)

Kurulumdan önce `config/hypr/hyprland.lua`'nın başındaki **KİŞİSEL TERCİHLER**
bölümüne bak (tarayıcı, klavye düzeni).

## Neler geliyor

### Kısayollar

| Tuş | İş |
|---|---|
| `Super+Space` | Uygulama başlatıcı (`:` ile eylemler) |
| `Super+Return` / `Super+T` | Terminal (T: açıksa ona odaklan) |
| `Super+B` | Tarayıcı (açıksa ona odaklan) |
| `Super+E` / `Super+M` | Dosya yöneticisi |
| `Super+Q` | Pencereyi kapat |
| `Super+Up` / `Super+F` | Büyüt / tam ekran |
| `Super+V` | Yüzer pencere |
| `Super+1…0` | Çalışma alanları · `Shift` ile pencereyi taşı |
| `Super+Ctrl+←/→` | Önceki/sonraki çalışma alanı |
| `Super+Shift+←/→/↑/↓` | Pencereyi başka monitöre taşı |
| `Super+D` · `S` · `U` · `N` | Pano · kenar çubuğu · araçlar · ayarlar (Nexus) |
| `Super+L` · `Super+Escape` | Kilitle · oturum menüsü |
| `Super+Tab` | Tüm pencereler |
| `Print` / `Shift+Print` | Ekran görüntüsü (dondurup seç) |
| `Super+Shift+T` · `Super+Shift+Q` | Ekrandan metin oku (OCR) · QR oku |
| `Super+Shift+N` | Gece ışığı |
| `Super+Shift+V` · `Super+Shift+S` | Panoyu dosyaya kaydet · panoyu LocalSend ile paylaş |
| `Super+Ctrl+O` · `Super+Ctrl+G` | Şeffaflık · pencere boşlukları |
| `Super+Shift+E` | **Güvenlik ağı:** kabuk çökse bile Hyprland'den çık |

Touchpad: 3/4 parmak yatay → çalışma alanı · 3 parmak yukarı → başlatıcı ·
3 parmak aşağı → kenar çubuğu.

### Launcher eylemleri

`Super+Space` → `:` yaz. 29 eylem var: sistem güncelleme, uygulama
yöneticisi (zypper + flatpak tek listede), kaldırma, web uygulaması oluşturma,
AppImage kurma, OCR, QR, gece ışığı, şeffaflık, fontlar, Wi-Fi durumu,
tema/duvar kağıdı ve güç eylemleri.

caelestia yalnızca eylemin **adında** arama yapıyor. O yüzden adlara
eşanlamlılar gömülü: `:ocr`, `:metin`, `:text` aynı eylemi bulur.

### Sistem tepsisi menüsü

Bar'daki tepsi ikonu (`os-kontrol`) sık kullanılanları tek tıkta toplar:

- OCR ve QR okuma, gece ışığı, panoyu kaydet/paylaş, dosya paylaş
- Ekran tazeleme hızı (monitörün desteklediği hızlar)
- GPU modu (`supergfxctl` varsa), hotspot ([hotspotd](https://github.com/emirberasoguk/hotspotd) varsa)

İkonlar caelestia'nın o anki renk şemasıyla çizilir. Tema değişince onlar da
değişir.

### Script'ler

Hepsi `~/.local/bin/omarchy-suse/` altına kurulur. Terminalden de
çalışırlar; çoğu argümansız çağrılınca etkileşimli menü açar.

| Script | İş |
|---|---|
| `os-uygulama` | zypper + flatpak birleşik arama/kurulum, önizlemeli |
| `os-kaldir` | web uygulaması · paket · flatpak · AppImage kaldırma |
| `os-guncelle` | `zypper dup` + flatpak; istersen kendi güncelleme fonksiyonun |
| `os-webapp` | bir siteyi masaüstü uygulamasına çevir (ikonu kendisi bulur) |
| `os-appimage` | AppImage kur/listele/kaldır, menüye ekle |
| `os-yakala` | ekrandan OCR (tesseract) ve QR (zbar) |
| `os-kontrol` | sistem tepsisi menüsü |
| `os-gece` | hyprsunset ile gece ışığı |
| `os-pencere` | şeffaflık · boşluk · tam ekran · yüzer · düzen |
| `os-ac-odaklan` | uygulama açıksa odaklan, değilse başlat |
| `os-pano-kaydet` | panodaki içeriği türüne göre dosyaya kaydet |
| `os-paylas` | LocalSend ile pano/dosya/klasör paylaş (flatpak kum havuzu farkında) |
| `os-font` | sistem fontlarını seç (fzf, önizlemeli) |
| `os-wifi-durum` | Wi-Fi bandı/AP/sinyal + caelestia'nın koyduğu AP kilidini temizle |
| `os-hotspot` | hotspotd'yi masaüstünden yönet |
| `os-kapak` | kapak kapanınca kilitle; harici monitör varsa clamshell |
| `os-oturum` | kapat/yeniden başlat/çıkış öncesi tam ekran geçiş animasyonu |
| `os-oturum-bekci` | Hyprland ölünce oturum hedefini durdurur (GDM döngüsünü önler) |
| `os-kitty-tema` | caelestia şemasından kitty renk teması üretir |

Hepsinin ortak TUI katmanı `lib/os-tui.sh`: gum + fzf, renkler caelestia
şemasından. API'si için [`docs/tr/EXTENDING.md`](docs/tr/EXTENDING.md).

## Nasıl çalışır

```
GDM → Hyprland (hyprland.lua)
        └─ baslat-caelestia.sh
             ├─ WAYLAND_DISPLAY ve DISPLAY'in GERÇEKTEN hazır olmasını bekle
             ├─ ortamı systemd + D-Bus'a aktar
             ├─ hyprland-session.target ── portal · hypridle · polkit · gvfs · os-kontrol
             ├─ hyprland-oturum-bekci.service (çökmede hedefi durdurur)
             ├─ tepsi ikonlarını üret (kabuktan ÖNCE — Qt ikon önbelleği)
             └─ caelestia shell
```

Neden bu kadar adım var? Her birinin arkasında sessiz bir hata yatıyor.
Hepsi [`docs/tr/TROUBLESHOOTING.md`](docs/tr/TROUBLESHOOTING.md)'de yazılı.

## Belgeler

| Belge | İçerik |
|---|---|
| [`docs/tr/INSTALL.md`](docs/tr/INSTALL.md) | Script'siz, adım adım kurulum ve kurulan dosyaların haritası |
| [`docs/tr/TROUBLESHOOTING.md`](docs/tr/TROUBLESHOOTING.md) | Belirti → sebep → çözüm: paketleme, oturum, tema, ekran, uygulamalar |
| [`docs/tr/HYPRLAND-LUA.md`](docs/tr/HYPRLAND-LUA.md) | Hyprland 0.56 Lua config'inde `hyprctl eval`/`dispatch` ve ekranı kapatan tuzaklar |
| [`docs/tr/EXTENDING.md`](docs/tr/EXTENDING.md) | caelestia'yı çatal açmadan genişletmek: launcher, tepsi, tema kancası, IPC, TUI |
| [`donanim/nvidia-hibrit/`](donanim/nvidia-hibrit/README.tr.md) | Intel + NVIDIA dizüstüler için isteğe bağlı GPU ayarları |
| [`docs/README.md`](docs/README.md) | Bütün belgeler, her dilde; yeni çeviri nasıl eklenir |

## Kaldırma

```bash
./kaldir.sh
```

Script'leri ve servisleri kaldırır. Paketlere ve yapılandırma dosyalarına
dokunmaz; yedeklerin yerini gösterir.

## Bilinen sınırlar

Bunlar caelestia'nın QML koduna dokunmayı (çatal açmayı) gerektiriyor, bu
depo bilerek yapmıyor:

- Bar'ı sola değil **üste** almak
- Hızlı ayarlar paneline **yeni düğme** eklemek
- Nexus'ta **monitör ayarları** sayfası (upstream'de henüz yok). Monitörler
  `hyprland.lua` içinden ayarlanır; örnekler dosyada.
- Dock

## Çeviri katkısı

Belgeler `docs/<dil>/` altında, her dilde aynı dosya adlarıyla duruyor. Yeni bir dil eklemek için [`docs/README.md`](docs/README.md)'ye bak.

## Lisans

[GPL-3.0](LICENSE). Omarchy'den uyarlanan kısımların MIT bildirimi ve diğer
üçüncü taraf notları: [`NOTICE.tr.md`](NOTICE.tr.md).

Bu proje Basecamp/Omarchy, caelestia-dots veya hyprwm ile bağlantılı değildir.
