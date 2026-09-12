# Adım adım kurulum

`kurulum.sh` bu adımların hepsini sorarak yapar. Bu belge, script
çalıştırmadan ne olup bittiğini anlamak ya da elle kurmak isteyenler için.

Her adım **kullanıcı düzeyinde** ve geri alınabilir. GNOME'a dokunulmaz;
Hyprland giriş ekranında ayrı bir oturum olarak eklenir.

---

## 1. Resmi depo paketleri

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

`python313-gobject` adındaki sürüm, sistemdeki `python3 --version` ile aynı
olmalı.

**Intel GPU varsa ek olarak:**

```bash
sudo zypper install intel-media-driver libva-utils
```

### Sessizce kırılanlar

Bu üç paket eksik olduğunda hata mesajı görmezsin, sadece bir şey çalışmaz:

| Paket | Yoksa |
|---|---|
| `qt6-sql-sqlite` | Launcher'da uygulamaya tıklarsın, hiçbir şey açılmaz |
| `libnotify-tools` | Hiçbir script bildirimi görünmez |
| `intel-media-driver` | VA-API hiç çalışmaz: ekran kaydı asılı kalır, tarayıcı videoyu CPU'da çözer |

## 2. caelestia (`home:kaiman`)

caelestia ve quickshell resmi depolarda yok. Tumbleweed için paketleyen
topluluk deposu `home:kaiman`. Resmi depolardan **düşük öncelikle** ekle:

```bash
sudo zypper addrepo -p 100 -f \
  https://download.opensuse.org/repositories/home:/kaiman/openSUSE_Tumbleweed/home:kaiman.repo
sudo zypper refresh
sudo zypper install caelestia-shell caelestia-cli
```

### ⚠ Bilinen paketleme hatası

```
Problem: nothing provides 'qt6qmlimport(qs.modules.bar.components.status)'
         needed by caelestia-shell
```

**İçerik eksik değil.** `modules/bar/components/status/*.qml` dosyaları paketin
içinde. RPM'in otomatik ürettiği `Provides:` listesi bu alt dizini atlamış.
zypper'ın sunduğu çözümlerden **"bağımlılığı yok sayarak kur"** seçeneğini seç.
Kabuk sorunsuz çalışır. Sonraki `zypper dup`'larda aynı soru tekrar gelebilir.

## 3. Paketleme düzeltmeleri

### a) Kabuk adı uyuşmazlığı → siyah ekran

`caelestia-cli` kabuğu `qs -c caelestia` diye çağırıyor, ama paket onu
`/etc/xdg/quickshell/caelestia-shell` adıyla kuruyor. Kabuk hiç başlamaz: bar
yok, duvar kağıdı yok, ekran simsiyah, yalnızca imleç görünür.

```bash
mkdir -p ~/.config/quickshell
ln -sfn /etc/xdg/quickshell/caelestia-shell ~/.config/quickshell/caelestia
```

### b) Fontlar → dev yazılar, kutu ikonlar

Paket font bağımlılıklarını getirmiyor. caelestia'nın beklediği aileler
(kaynak: `plugin/src/Caelestia/Config/font.hpp`) şunlar:

| Font | Rolü | openSUSE deposunda |
|---|---|---|
| Material Symbols Rounded | bütün ikonlar | yok |
| Rubik | arayüz yazısı | yok |
| CaskaydiaCove NF | monospace | yok |
| Google Sans Flex | pakette geliyor ama fontconfig'in taramadığı dizinde | — |

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

## 4. Script'ler

```bash
mkdir -p ~/.local/bin/omarchy-suse ~/.local/lib/omarchy-suse
install -m 755 bin/* ~/.local/bin/omarchy-suse/
install -m 644 lib/os-tui.sh ~/.local/lib/omarchy-suse/
```

Launcher ve kısayollar script'leri **tam yolla** çağırır, PATH'e bağımlı
değildir. Terminalden adıyla çağırmak istersen kabuk dosyana şunu ekle:

```bash
export PATH="$HOME/.local/bin/omarchy-suse:$PATH"
```

## 5. Yapılandırma

`shell.json` ve `cli.json` içinde `@HOME@` yer tutucusu var. caelestia komut
dizilerinde `~`'yi genişletmiyor, bu yüzden kurarken gerçek yol yazılmalı:

```bash
mkdir -p ~/.config/hypr ~/.config/caelestia ~/.config/kitty
cp config/hypr/hyprland.lua config/hypr/hypridle.conf ~/.config/hypr/
install -m 755 config/hypr/baslat-caelestia.sh ~/.config/hypr/
sed "s|@HOME@|$HOME|g" config/caelestia/shell.json > ~/.config/caelestia/shell.json
sed "s|@HOME@|$HOME|g" config/caelestia/cli.json   > ~/.config/caelestia/cli.json
cp config/kitty/kitty.conf ~/.config/kitty/
touch ~/.config/kitty/caelestia.conf
```

## 6. Oturum servisleri

```bash
cp config/systemd/user/* ~/.config/systemd/user/
systemctl --user daemon-reload

for u in os-kontrol hypridle hyprpolkitagent xdg-desktop-portal xdg-desktop-portal-hyprland \
         gvfs-udisks2-volume-monitor gvfs-mtp-volume-monitor gvfs-gphoto2-volume-monitor gvfs-metadata; do
  systemctl --user add-wants hyprland-session.target "$u.service"
done
systemctl --user enable gcr-ssh-agent.socket gnome-keyring-daemon.socket
```

`hyprland-session.target`'ı **enable etme.** Onu `baslat-caelestia.sh`
başlatır. Enable edilirse GNOME oturumunda da tetiklenir. Nedeni için bkz.
[TUZAKLAR → GDM sonsuz şifre döngüsü](TUZAKLAR.md#gdm-sonsuz-şifre-döngüsü).

## 7. Küçük düzeltmeler

```bash
# Ekran kaydı — olmadan caelestia record görünmez polkit bekler
sudo setcap cap_sys_admin+ep /usr/bin/gsr-kms-server

# İmleç boş kutu görünüyorsa
mkdir -p ~/.icons/default
printf '[Icon Theme]\nName=Default\nInherits=Adwaita\n' > ~/.icons/default/index.theme

# Klasörler terminalde açılıyorsa
xdg-mime default org.gnome.Nautilus.desktop inode/directory
```

### GTK teması (isteğe bağlı)

caelestia'nın tema motoru GTK uygulamaları için `adw-gtk3-dark` temasını yazar.
Bu tema resmi depolarda **yok**; bir OBS topluluk deposunda. `adw-gtk3` ve
`adw-gtk3-dark` **ayrı paketlerdir**, yalnızca birini kurmak yetmez. Kurmazsan
GTK uygulamaları varsayılan Adwaita ile açılır; başka bir şey bozulmaz.

```bash
sudo zypper addrepo -p 100 -f \
  https://download.opensuse.org/repositories/home:/soupglasses/openSUSE_Tumbleweed/ home_soupglasses
sudo zypper refresh
sudo zypper install adw-gtk3 adw-gtk3-dark
```

---

## İlk açılış

1. Oturumu kapat. Giriş ekranında kullanıcı adına tıkla, sağ alttaki dişliden
   **Hyprland**'i seç.
2. Bar ve duvar kağıdı gelmeli. Gelmezse şu iki yere bak:

```bash
cat $XDG_RUNTIME_DIR/baslat-caelestia.log   # oturum zinciri hangi adımda kaldı
qs -c caelestia log                         # kabuğun kendi günlüğü (asıl hata burada)
```

3. Kontrol listesi:

| Kontrol | Komut | Beklenen |
|---|---|---|
| Oturum hedefi | `systemctl --user is-active graphical-session.target` | `active` |
| Portal | `systemctl --user is-active xdg-desktop-portal` | `active` |
| SSH ajanı | `echo $SSH_AUTH_SOCK` | `/run/user/…/gcr/ssh` |
| X11 uygulamaları | `echo $DISPLAY` (launcher'dan açılan terminalde) | `:0` gibi bir değer, boş değil |
| VA-API | `vainfo` | `va_openDriver() returns 0` |
| Tepsi | bar'da dünya ikonu | tıklayınca menü |

## Kurulan dosyalar

| Yol | İş |
|---|---|
| `~/.config/hypr/hyprland.lua` | Hyprland (Lua API) |
| `~/.config/hypr/baslat-caelestia.sh` | oturum başlatıcı |
| `~/.config/hypr/hypridle.conf` | 5 dk kıs → 8 dk kilit → 10 dk ekran kapat → 30 dk uyku |
| `~/.config/caelestia/shell.json` | launcher eylemleri, oturum komutları, bar |
| `~/.config/caelestia/cli.json` | tema motoru + `postHook` |
| `~/.config/kitty/kitty.conf` | terminal (renkler `caelestia.conf`'tan) |
| `~/.config/quickshell/caelestia` | → `/etc/xdg/quickshell/caelestia-shell` |
| `~/.config/systemd/user/hyprland-session.target` | oturum hedefi |
| `~/.config/systemd/user/os-kontrol.service` | tepsi menüsü |
| `~/.config/systemd/user/hyprland-oturum-bekci.service` | çökme temizliği |
| `~/.local/bin/omarchy-suse/` | 19 script |
| `~/.local/lib/omarchy-suse/os-tui.sh` | ortak TUI katmanı |
| `~/.local/share/fonts/caelestia/` | fontlar |
