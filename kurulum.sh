#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  omarchy-suse kurulumu — openSUSE Tumbleweed + Hyprland + caelestia
#
#  Fazlı ve etkileşimli: her faz ne yapacağını gösterir, sonra SORAR.
#  Varsayılan cevap YOK — "e" ya da "h" yazman gerekir. zypper'ın kendi
#  onayları da olduğu gibi bırakıldı; ne kurulacağını görmeden hiçbir şey
#  kurulmaz.
#
#  GNOME'a dokunmaz. Hyprland giriş ekranında ayrı bir oturum olarak eklenir.
#  Üzerine yazılan her dosya önce yedeklenir:
#    ~/.local/state/omarchy-suse/yedek/<zaman>/
# ═══════════════════════════════════════════════════════════════════
set -uo pipefail

DEPO="$(cd "$(dirname "$0")" && pwd)"
ZAMAN="$(date +%Y%m%d-%H%M%S)"
YEDEK="$HOME/.local/state/omarchy-suse/yedek/$ZAMAN"
BIN="$HOME/.local/bin/omarchy-suse"
LIB="$HOME/.local/lib/omarchy-suse"

K=$'\033[1m'; Y=$'\033[32m'; S=$'\033[33m'; R=$'\033[31m'; D=$'\033[2m'; N=$'\033[0m'

faz()   { printf '\n%s═══ %s ═══%s\n' "$K" "$*" "$N"; }
bilgi() { printf '  %s\n' "$*"; }
iyi()   { printf '  %s✔%s %s\n' "$Y" "$N" "$*"; }
uyar()  { printf '  %s!%s %s\n' "$S" "$N" "$*"; }
kotu()  { printf '  %s✘%s %s\n' "$R" "$N" "$*" >&2; }

# Varsayılansız evet/hayır: Enter'a basmak bir şey seçmez.
sor() {
    local c
    while true; do
        read -r -p "  $* [e/h] " c
        case "$c" in
            e|E|evet) return 0 ;;
            h|H|hayir|hayır) return 1 ;;
            *) printf '  %s"e" ya da "h" yaz%s\n' "$D" "$N" ;;
        esac
    done
}

# Dosyayı kur; hedef varsa ve farklıysa önce yedekle.
# $3 = "sablon" ise @HOME@ → $HOME
kur_dosya() {
    local kaynak="$1" hedef="$2" kip="${3:-}" gecici
    gecici="$(mktemp)"
    if [ "$kip" = "sablon" ]; then
        sed "s|@HOME@|$HOME|g" "$kaynak" > "$gecici"
    else
        cp "$kaynak" "$gecici"
    fi
    if [ -e "$hedef" ] && ! cmp -s "$gecici" "$hedef"; then
        mkdir -p "$YEDEK/$(dirname "${hedef#"$HOME"/}")"
        cp -a "$hedef" "$YEDEK/${hedef#"$HOME"/}"
        uyar "yedeklendi: ${hedef/#$HOME/\~}"
    fi
    mkdir -p "$(dirname "$hedef")"
    install -m "$(stat -c %a "$kaynak")" "$gecici" "$hedef"
    rm -f "$gecici"
    iyi "${hedef/#$HOME/\~}"
}

# ── Ön kontroller ─────────────────────────────────────────────────
[ "$(id -u)" -eq 0 ] && { kotu "root olarak çalıştırma — gerektiğinde sudo sorulacak"; exit 1; }
# shellcheck disable=SC1091
. /etc/os-release 2>/dev/null
if [ "${ID:-}" != "opensuse-tumbleweed" ]; then
    uyar "Bu script openSUSE Tumbleweed için yazıldı (bulunan: ${PRETTY_NAME:-bilinmiyor})"
    sor "Yine de devam edilsin mi?" || exit 1
fi

PY="python$(python3 -c 'import sys; print(f"{sys.version_info[0]}{sys.version_info[1]}")' 2>/dev/null || echo 3)"

cat <<EOF

${K}omarchy-suse${N} — openSUSE için Hyprland + caelestia masaüstü

Fazlar:
  1  Resmi depo paketleri (Hyprland yığını, araçlar)
  2  home:kaiman deposu + caelestia
  3  caelestia paketleme düzeltmeleri + fontlar
  4  Script'ler (~/.local/bin/omarchy-suse)
  5  Yapılandırma dosyaları (yedekleyerek)
  6  Oturum servisleri (systemd --user)
  7  Küçük sistem düzeltmeleri

Her fazı atlayabilirsin. Ayrıntılar: docs/KURULUM.md
EOF

# ── 1. Resmi depo paketleri ───────────────────────────────────────
faz "1 · Resmi depo paketleri"
PAKETLER=(
    # Hyprland yığını
    hyprland hyprlock hypridle hyprpolkitagent
    xdg-desktop-portal-hyprland hyprland-qtutils hyprsunset
    # Olmazsa sessizce kırılanlar — docs/TUZAKLAR.md
    qt6-platformtheme-gtk3   # Qt ikon/renk teması (yoksa kırık ikon kareleri)
    qt6-sql-sqlite           # yoksa launcher uygulama AÇMAZ
    libnotify-tools          # yoksa hiçbir bildirim görünmez
    # Araçlar
    kitty nautilus jq curl unzip zip brightnessctl wl-clipboard grim slurp zenity iw
    gum fzf chafa
    # Tepsi menüsü (os-kontrol)
    typelib-1_0-AyatanaAppIndicator3-0_1 typelib-1_0-Gtk-3_0 "${PY}-gobject"
    # OCR / QR (os-yakala)
    tesseract-ocr tesseract-ocr-traineddata-tur tesseract-ocr-traineddata-eng
    tesseract-ocr-traineddata-osd zbar
    # Ekran kaydı (caelestia record)
    gpu-screen-recorder
)
# Intel GPU var mı? lspci KULLANMIYORUZ — uyuyan dGPU'yu uyandırır.
if grep -qs 0x8086 /sys/class/drm/card*/device/vendor; then
    PAKETLER+=(intel-media-driver libva-utils)
    bilgi "Intel GPU bulundu → intel-media-driver eklendi (yoksa VA-API hiç çalışmaz)"
fi
bilgi "Kurulacaklar:"
printf '%s ' "${PAKETLER[@]}" | fold -s -w 70 | sed 's/^/    /'
echo
if sor "Bu paketler kurulsun mu? (zypper ayrıca onay isteyecek)"; then
    sudo zypper install "${PAKETLER[@]}" || kotu "zypper başarısız — çıktıya bak, sonra scripti yeniden çalıştır"
fi

# ── 2. home:kaiman + caelestia ────────────────────────────────────
faz "2 · home:kaiman deposu + caelestia"
cat <<'EOF'
  caelestia ve quickshell openSUSE'nin resmi depolarında yok; bir topluluk
  OBS deposu olan home:kaiman'dan geliyor. Depo resmi depolardan DÜŞÜK
  öncelikle (100) eklenir, yani resmi paketlerin yerine geçmez.

  ⚠ BİLİNEN PAKETLEME HATASI: zypper şu hatayla durabilir:
      nothing provides 'qt6qmlimport(qs.modules.bar.components.status)'
  İçerik eksik DEĞİL — dosyalar pakette var, yalnızca RPM meta verisi eksik.
  zypper'ın sunduğu çözümlerden "bağımlılığı yok sayarak kur" (break ...
  by ignoring some of its dependencies) seçeneğini seç. Ayrıntı:
  docs/TUZAKLAR.md → "Kurulum ve paketleme".
EOF
if sor "home:kaiman eklensin ve caelestia kurulsun mu?"; then
    if zypper lr 2>/dev/null | grep -qi "kaiman"; then
        bilgi "depo zaten ekli"
    else
        sudo zypper addrepo -p 100 -f \
            https://download.opensuse.org/repositories/home:/kaiman/openSUSE_Tumbleweed/home:kaiman.repo \
            || kotu "depo eklenemedi"
    fi
    sudo zypper refresh
    sudo zypper install caelestia-shell caelestia-cli || kotu "caelestia kurulamadı"
fi

# ── 3. Paketleme düzeltmeleri + fontlar ───────────────────────────
faz "3 · caelestia paketleme düzeltmeleri + fontlar"
cat <<'EOF'
  a) caelestia-cli "qs -c caelestia" çağırıyor ama paket kabuğu
     "caelestia-shell" adıyla kuruyor → kabuk hiç başlamaz, ekran simsiyah.
     Çözüm: ~/.config/quickshell/caelestia bağlantısı (sudo gerekmez).
  b) Paket font bağımlılıklarını getirmiyor → dev yazılar, ikonların yerinde
     kutular. Material Symbols Rounded, Rubik ve CaskaydiaCove Nerd Font
     ~/.local/share/fonts/caelestia altına indirilir (~90 MB, sudo gerekmez).
EOF
if sor "Bu iki düzeltme yapılsın mı?"; then
    if [ -d /etc/xdg/quickshell/caelestia-shell ]; then
        mkdir -p "$HOME/.config/quickshell"
        if [ -e "$HOME/.config/quickshell/caelestia" ] && [ ! -L "$HOME/.config/quickshell/caelestia" ]; then
            uyar "~/.config/quickshell/caelestia gerçek bir dizin (çatal?) — dokunulmadı"
        else
            ln -sfn /etc/xdg/quickshell/caelestia-shell "$HOME/.config/quickshell/caelestia"
            iyi "~/.config/quickshell/caelestia → /etc/xdg/quickshell/caelestia-shell"
        fi
    else
        uyar "/etc/xdg/quickshell/caelestia-shell yok — önce faz 2"
    fi

    FONT="$HOME/.local/share/fonts/caelestia"
    mkdir -p "$FONT"
    indir() { curl -fL --retry 2 --progress-bar -o "$2" "$1" || { kotu "indirilemedi: $1"; return 1; }; }
    [ -s "$FONT/MaterialSymbolsRounded.ttf" ] || indir \
        "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf" \
        "$FONT/MaterialSymbolsRounded.ttf"
    [ -s "$FONT/Rubik.ttf" ] || indir \
        "https://github.com/google/fonts/raw/main/ofl/rubik/Rubik%5Bwght%5D.ttf" \
        "$FONT/Rubik.ttf"
    if ! ls "$FONT"/CaskaydiaCove* >/dev/null 2>&1; then
        ZIP="$(mktemp --suffix=.zip)"
        if indir "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip" "$ZIP"; then
            unzip -oq "$ZIP" -d "$FONT" -x "*.md" "*.txt" "LICENSE*"
            # Yalnız Regular/Bold/Italic ağırlıkları kalsın
            find "$FONT" -name "CaskaydiaCove*" ! -name "*Regular*" ! -name "*Bold*" ! -name "*Italic*" -delete
        fi
        rm -f "$ZIP"
    fi
    # Pakette gelen ama fontconfig'in taramadığı dizinde duran font
    cp -n /etc/xdg/quickshell/caelestia-shell/assets/google-sans-flex/*.ttf "$FONT/" 2>/dev/null || true
    fc-cache -f "$HOME/.local/share/fonts" >/dev/null
    for aile in "Material Symbols Rounded" "Rubik" "CaskaydiaCove NF" "Google Sans Flex"; do
        if fc-list | grep -q "$aile"; then iyi "font: $aile"; else uyar "font eksik: $aile"; fi
    done
fi

# ── 4. Script'ler ─────────────────────────────────────────────────
faz "4 · Script'ler"
bilgi "bin/os-*  → ${BIN/#$HOME/\~}/"
bilgi "lib/os-tui.sh → ${LIB/#$HOME/\~}/"
if sor "Script'ler kurulsun mu?"; then
    for f in "$DEPO"/bin/*; do kur_dosya "$f" "$BIN/$(basename "$f")"; done
    kur_dosya "$DEPO/lib/os-tui.sh" "$LIB/os-tui.sh"
    bilgi "Terminalden adıyla çağırmak için kabuk dosyana ekle:"
    bilgi "  export PATH=\"\$HOME/.local/bin/omarchy-suse:\$PATH\""
fi

# ── 5. Yapılandırma ───────────────────────────────────────────────
faz "5 · Yapılandırma dosyaları"
cat <<EOF
  Kurulacaklar (var olanlar önce yedeklenir):
    ~/.config/hypr/hyprland.lua
    ~/.config/hypr/baslat-caelestia.sh
    ~/.config/hypr/hypridle.conf
    ~/.config/caelestia/shell.json      (launcher eylemleri, oturum komutları)
    ~/.config/caelestia/cli.json        (tema motoru)
    ~/.config/kitty/kitty.conf
  ${S}Önce config/hypr/hyprland.lua'nın başındaki "KİŞİSEL TERCİHLER"
  bölümüne bak (tarayıcı, klavye düzeni).${N}
EOF
if sor "Yapılandırma dosyaları kurulsun mu?"; then
    kur_dosya "$DEPO/config/hypr/hyprland.lua"        "$HOME/.config/hypr/hyprland.lua"
    kur_dosya "$DEPO/config/hypr/baslat-caelestia.sh" "$HOME/.config/hypr/baslat-caelestia.sh"
    kur_dosya "$DEPO/config/hypr/hypridle.conf"       "$HOME/.config/hypr/hypridle.conf"
    kur_dosya "$DEPO/config/caelestia/shell.json"     "$HOME/.config/caelestia/shell.json" sablon
    kur_dosya "$DEPO/config/caelestia/cli.json"       "$HOME/.config/caelestia/cli.json"   sablon
    kur_dosya "$DEPO/config/kitty/kitty.conf"         "$HOME/.config/kitty/kitty.conf"
    # kitty.conf caelestia.conf'u include ediyor; şema henüz yoksa boş kalsın
    [ -e "$HOME/.config/kitty/caelestia.conf" ] || : > "$HOME/.config/kitty/caelestia.conf"
    [ -x "$BIN/os-kitty-tema" ] && "$BIN/os-kitty-tema" >/dev/null 2>&1 || true
fi

# ── 6. Oturum servisleri ──────────────────────────────────────────
faz "6 · Oturum servisleri (systemd --user)"
cat <<'EOF'
  hyprland-session.target: GNOME'da gnome-session'ın yaptığını yapar —
  graphical-session.target'i etkinleştirir. O olmadan xdg-desktop-portal
  başlamaz (dosya seçici, ekran paylaşımı, Flatpak koyu tema).
  Hedef ENABLE EDİLMEZ; yalnız Hyprland içinden başlatılır, böylece GNOME
  oturumu etkilenmez.
EOF
if sor "Servisler kurulsun mu?"; then
    UNIT="$HOME/.config/systemd/user"
    for f in "$DEPO"/config/systemd/user/*; do kur_dosya "$f" "$UNIT/$(basename "$f")"; done
    systemctl --user daemon-reload
    for u in os-kontrol.service hypridle.service hyprpolkitagent.service \
             xdg-desktop-portal.service xdg-desktop-portal-hyprland.service \
             gvfs-udisks2-volume-monitor.service gvfs-mtp-volume-monitor.service \
             gvfs-gphoto2-volume-monitor.service gvfs-metadata.service; do
        if systemctl --user cat "$u" >/dev/null 2>&1; then
            systemctl --user add-wants hyprland-session.target "$u" >/dev/null 2>&1 && iyi "hedefe bağlandı: $u"
        else
            bilgi "${D}yok, atlandı: $u${N}"
        fi
    done
    # SSH ajanı ve anahtarlık — GNOME'da gnome-session başlatıyor
    for s in gcr-ssh-agent.socket gnome-keyring-daemon.socket; do
        if systemctl --user cat "$s" >/dev/null 2>&1; then
            systemctl --user enable "$s" >/dev/null 2>&1 && iyi "etkin: $s"
        fi
    done
fi

# ── 7. Küçük sistem düzeltmeleri ──────────────────────────────────
faz "7 · Küçük sistem düzeltmeleri"

GSR=/usr/bin/gsr-kms-server
if [ -x "$GSR" ] && ! getcap "$GSR" 2>/dev/null | grep -q cap_sys_admin; then
    cat <<'EOF'
  a) Ekran kaydı: gsr-kms-server'da cap_sys_admin yok. Olmadan
     "caelestia record" görünmez bir polkit penceresini bekleyip asılı kalır.
     (Programın kendi günlüğü bu çözümü öneriyor.)
EOF
    sor "sudo setcap cap_sys_admin+ep $GSR çalıştırılsın mı?" && sudo setcap cap_sys_admin+ep "$GSR" && iyi "cap eklendi"
fi

if [ ! -e "$HOME/.icons/default/index.theme" ] && [ ! -d /usr/share/icons/default ]; then
    cat <<'EOF'
  b) İmleç: caelestia'nın tema motoru cursor-theme='default' yazıyor ama
     "default" teması sistemde yok → imleç boş kutu görünür.
     Çözüm: ~/.icons/default → Adwaita'ya yönlendirme.
EOF
    if sor "İmleç yönlendirmesi eklensin mi?"; then
        mkdir -p "$HOME/.icons/default"
        printf '[Icon Theme]\nName=Default\nInherits=Adwaita\n' > "$HOME/.icons/default/index.theme"
        iyi "~/.icons/default/index.theme"
    fi
fi

if [ "$(xdg-mime query default inode/directory 2>/dev/null)" = "kitty-open.desktop" ]; then
    cat <<'EOF'
  c) Klasörler terminalde açılıyor: inode/directory varsayılanı kitty-open.
EOF
    sor "Klasörler Nautilus'ta açılsın mı?" && xdg-mime default org.gnome.Nautilus.desktop inode/directory && iyi "inode/directory → Nautilus"
fi

if ls /sys/class/drm/card*/device/vendor 2>/dev/null | xargs grep -qs 0x10de; then
    cat <<'EOF'
  d) NVIDIA GPU bulundu. Intel + NVIDIA hibrit bir dizüstüysen
     donanim/nvidia-hibrit/README.md'yi oku — udev kuralı ELLE kurulur,
     çünkü PCI adreslerini önce senin doğrulaman gerekiyor.
EOF
fi

# ── Bitti ─────────────────────────────────────────────────────────
faz "Bitti"
[ -d "$YEDEK" ] && bilgi "Yedekler: ${YEDEK/#$HOME/\~}"
cat <<'EOF'
  Sıradaki adım: oturumu kapat, giriş ekranında kullanıcı adına tıkla,
  sağ alttaki dişliden "Hyprland"i seç.

  İlk açılışta bir şey ters giderse ilk bakılacak iki yer:
    cat $XDG_RUNTIME_DIR/baslat-caelestia.log
    qs -c caelestia log

  Kısayollar ve belgeler: README.md · docs/
EOF
