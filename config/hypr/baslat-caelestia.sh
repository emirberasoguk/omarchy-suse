#!/bin/sh
# Hyprland oturum ortamını kurar, sonra polkit ajanı ve caelestia'yı başlatır.
#
# KÖK SORUN: hl.exec_cmd() ile başlatılan çocuklarda WAYLAND_DISPLAY YOK.
# Hyprland onu compositor hazır olduktan sonra kendi ortamına koyuyor; config
# ayrıştırma sırasında spawn edilen çocuklar almıyor. Sonuçları:
#   - quickshell: "Failed to create wl_display (Connection refused)"
#   - hyprpolkitagent.service: "unmet condition ConditionEnvironment=WAYLAND_DISPLAY"
#
# Doğru soket adı `hyprctl instances -j` içindeki wl_socket alanında. AMA bu alan
# compositor soketi oluşturana kadar BOŞ geliyor — hyprctl'in yanıt vermesini
# beklemek yetmez, DEĞERİN DOLMASINI beklemek gerekir.
# (Ölçüm: Hyprland 18:50:35'te başladı, soket 18:50:37.18'de oluştu.)

# --display-yaz: kendini Hyprland'in İÇİNDEN çağırma modu (aşağıda 1b).
# Hyprland'in o anki ortamındaki DISPLAY'i dosyaya yazıp çıkar. LOG'u
# sıfırlayan satırdan ÖNCE dönmeli, yoksa ana oturumun logunu siler.
if [ "$1" = "--display-yaz" ]; then
    printf '%s' "${DISPLAY:-}" > "$2"
    exit 0
fi

LOG="${XDG_RUNTIME_DIR:-/tmp}/baslat-caelestia.log"
: > "$LOG"
kaydet() { echo "[$(date +%H:%M:%S.%2N)] $*" >> "$LOG"; }

kaydet "başladı · WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-yok}"

soketi_bul() {
    hyprctl instances -j 2>/dev/null | jq -r --arg i "${HYPRLAND_INSTANCE_SIGNATURE:-}" '
        (map(select(.instance == $i)) | .[0].wl_socket)   # önce kendi örneğimiz
        // (.[0].wl_socket)                                # yoksa ilk örnek
        // empty' 2>/dev/null
}

# 1) wl_socket DOLANA ve soket dosyası GERÇEKTEN OLUŞANA kadar bekle (≤30 sn)
if [ -z "$WAYLAND_DISPLAY" ]; then
    i=0
    while [ $i -lt 300 ]; do
        W=$(soketi_bul)
        if [ -n "$W" ] && [ -S "$XDG_RUNTIME_DIR/$W" ]; then
            WAYLAND_DISPLAY="$W"; export WAYLAND_DISPLAY
            kaydet "soket $((i))×0.1sn sonra hazır: $WAYLAND_DISPLAY"
            break
        fi
        sleep 0.1; i=$((i + 1))
    done
fi

if [ -z "$WAYLAND_DISPLAY" ]; then
    kaydet "❌ 30 sn'de soket bulunamadı"
    notify-send "Hyprland" "Wayland soketi bulunamadı — $LOG" 2>/dev/null
    kitty & exit 1
fi

# 1b) DISPLAY — X11 uygulamaları için (Steam, TLauncher/Java, Wine, Electron...)
# KÖK SORUN (2026-09-12): WAYLAND_DISPLAY ile BİREBİR aynı yarış. Hyprland
# Xwayland'i compositor ayağa kalktıktan sonra kuruyor; config ayrıştırılırken
# spawn edilen çocuklarda DISPLAY YOK. caelestia o boş ortamı miras alıyor ve
# launcher'dan açılan HER X11 uygulamasına aktarıyor. Sonuç: uygulama
# "Unable to open X11 display, exiting" deyip PENCERE AÇMADAN kapanıyor —
# hata kutusu yok, sadece açılmıyor (Steam ve TLauncher böyle bulundu).
# Xwayland'in kendisi çalışıyordu; eksik olan tek şey adresti.
#
# Değeri TAHMİN ETME: /tmp/.X11-unix taraması, :0'ı tutan başka bir X sunucusu
# varsa yanlış adresi verir ve uygulamalar bu sefer donar. Hyprland'in canlı
# ortamındaki gerçek değeri sor: `hyprctl eval` sadece "ok" döndürdüğü için
# değeri okumanın yolu, Hyprland'e bu scripti --display-yaz ile çalıştırtmak.
if [ -z "$DISPLAY" ]; then
    D_DOSYA="${XDG_RUNTIME_DIR:-/tmp}/hypr-display"
    i=0
    while [ $i -lt 100 ]; do
        rm -f "$D_DOSYA"
        hyprctl eval "hl.exec_cmd(\"$0 --display-yaz $D_DOSYA\")" >/dev/null 2>&1
        sleep 0.1
        D=$(cat "$D_DOSYA" 2>/dev/null)
        # Soketi de doğrula: dolu ama ölü bir DISPLAY, boş DISPLAY'den kötüdür.
        if [ -n "$D" ] && [ -S "/tmp/.X11-unix/X${D#:}" ]; then
            DISPLAY="$D"; export DISPLAY
            kaydet "DISPLAY $((i))x0.1sn sonra hazir: $DISPLAY"
            break
        fi
        sleep 0.1; i=$((i + 1))
    done
    rm -f "$D_DOSYA"
fi

# Bulunamazsa BOŞ BIRAK ve devam et: caelestia'nın kendisi Wayland uygulaması,
# onu X11 yüzünden başlatmamak sorunu büyütür. Sadece uyar.
if [ -z "$DISPLAY" ]; then
    kaydet "! DISPLAY bulunamadi - X11 uygulamalari (Steam, TLauncher) acilmayabilir"
    notify-send "Hyprland" "DISPLAY ayarlanamadi - X11 uygulamalari acilmayabilir" 2>/dev/null
fi

# 2) systemd ve D-Bus kullanıcı oturumuna aktar
systemctl --user import-environment WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP 2>>"$LOG"
dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP 2>>"$LOG"
kaydet "ortam systemd/dbus'a aktarıldı"

# 3) Oturum hedefi — graphical-session.target'i etkinleştirir.
#    GNOME'da bunu gnome-session yapıyor; Hyprland'de (uwsm yokken) kimse yapmıyor.
#    Bu hedef aktif olmadan xdg-desktop-portal başlamıyor
#    (Requisite=graphical-session.target) → ekran paylaşımı, dosya seçici ve
#    Flatpak'lerin koyu tema algısı çalışmıyor.
#    ÖNCE BAYAT HEDEFİ DURDUR: systemd --user oturum başına değil KULLANICI
#    başına çalışıyor, yani önceki oturumdan kalan hedef hâlâ aktif olabilir
#    (Hyprland çökmüşse bekçi de ölmüş olabilir). Bayat hedef
#    graphical-session-pre.target'i ayakta tutar ve GNOME girişini kırar.
systemctl --user stop hyprland-session.target 2>>"$LOG" || true

systemctl --user start hyprland-session.target 2>>"$LOG" \
    && kaydet "oturum hedefi aktif (graphical-session: $(systemctl --user is-active graphical-session.target))"

# 3b) Bekçi: Hyprland ölünce hedefi durdurur.
#     Hedef başlatılıyor ama HİÇBİR ŞEY DURDURMUYORDU — GNOME'a geçişte
#     "A graphical session is already running!" ile sonsuz GDM döngüsü
#     yaşandı (2026-09-08). os-oturum'un menüden çıkış yolu temizliği zaten
#     yapıyor; bu servis ÇÖKME ve başka kapanma yolları için.
systemctl --user restart hyprland-oturum-bekci.service 2>>"$LOG" \
    && kaydet "oturum bekçisi başlatıldı"


# 4b) NOT: portal, hypridle ve gvfs servisleri artık tek tek başlatılmıyor.
#     hyprland-session.target'e `systemctl --user add-wants` ile bağlandılar,
#     hedef başlayınca kendiliğinden geliyorlar:
#       xdg-desktop-portal{,-hyprland} · hypridle · gvfs-{udisks2,mtp,gphoto2}-volume-monitor · gvfs-metadata
#     gcr-ssh-agent.socket ve gnome-keyring-daemon.socket `enable` edildi.


# 5) caelestia — ayağa kalkana kadar dene
# Tepsi ikonlarını kabuktan ÖNCE üret. Qt ikon temasını süreç başlarken
# önbelleğe alıyor; sonradan eklenen dosyaları görmüyor ve kırık kare çiziyor.
if [ -x "$HOME/.local/bin/omarchy-suse/os-kontrol" ]; then
    "$HOME/.local/bin/omarchy-suse/os-kontrol" --ikonlar >>"$LOG" 2>&1 || true
    kaydet "tepsi ikonları hazırlandı"
fi

deneme=1
while [ $deneme -le 15 ]; do
    caelestia shell -d >>"$LOG" 2>&1
    sleep 2
    if pgrep -f "qs -c caelestia" >/dev/null 2>&1; then
        kaydet "✅ caelestia $deneme. denemede başladı"
        exit 0
    fi
    kaydet "$deneme. deneme başarısız"
    deneme=$((deneme + 1))
done

kaydet "❌ caelestia başlamadı"
notify-send "caelestia başlatılamadı" "Log: $LOG" 2>/dev/null
kitty &
