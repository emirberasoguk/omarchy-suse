#!/bin/bash
# omarchy-suse'nin kurduğu script'leri ve servisleri kaldırır.
#
# Paketlere (hyprland, caelestia…) ve yapılandırma dosyalarına DOKUNMAZ —
# onları sen kaldırırsın/geri yüklersin; yedeklerin yeri sonda gösterilir.
# Her adım ayrı sorulur, varsayılan cevap yoktur.
set -uo pipefail

sor() {
    local c
    while true; do
        read -r -p "  $* [e/h] " c
        case "$c" in
            e|E) return 0 ;;
            h|H) return 1 ;;
            *) echo "  \"e\" ya da \"h\" yaz" ;;
        esac
    done
}

UNIT="$HOME/.config/systemd/user"

echo "═══ Servisler ═══"
echo "  os-kontrol.service · hyprland-oturum-bekci.service · hyprland-session.target"
if sor "Servisler durdurulup kaldırılsın mı?"; then
    systemctl --user disable --now os-kontrol.service 2>/dev/null
    systemctl --user stop hyprland-oturum-bekci.service 2>/dev/null
    rm -f "$UNIT/os-kontrol.service" "$UNIT/hyprland-oturum-bekci.service" "$UNIT/hyprland-session.target"
    rm -rf "$UNIT/hyprland-session.target.wants"
    systemctl --user daemon-reload
    echo "  ✔ kaldırıldı"
fi

echo "═══ Script'ler ═══"
echo "  ~/.local/bin/omarchy-suse/ · ~/.local/lib/omarchy-suse/"
if sor "Script dizinleri silinsin mi?"; then
    rm -rf "$HOME/.local/bin/omarchy-suse" "$HOME/.local/lib/omarchy-suse"
    rm -f "$HOME"/.local/share/icons/hicolor/scalable/apps/os-kontrol-*.svg
    rm -rf "$HOME/.local/share/omarchy-suse"
    echo "  ✔ silindi"
fi

echo "═══ Yapılandırma ═══"
echo "  ~/.config/hypr · ~/.config/caelestia · ~/.config/kitty — dokunulmadı."
if [ -d "$HOME/.local/state/omarchy-suse/yedek" ]; then
    echo "  Kurulumdan önceki hâller burada:"
    ls -1d "$HOME"/.local/state/omarchy-suse/yedek/* | sed "s|^$HOME|    ~|"
fi
echo
echo "  Hyprland oturumu hyprland.lua'daki script yollarını çağırmaya devam eder;"
echo "  yapılandırmayı da geri almadıysan GDM'de GNOME'u seç."
