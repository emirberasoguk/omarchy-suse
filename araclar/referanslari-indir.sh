#!/bin/bash
# Script yazarken incelemeye değer üst kaynak depoları sığ klonlar.
# Hepsi referans içindir; bu depoya dahil edilmez (.gitignore: referanslar/).
#
# Kullanım: araclar/referanslari-indir.sh [hedef-dizin]
set -uo pipefail

BASE="${1:-$(cd "$(dirname "$0")/.." && pwd)/referanslar}"
mkdir -p "$BASE"

clone() { # $1=grup $2=url
    local d="$BASE/$1/$(basename "$2")"
    mkdir -p "$BASE/$1"
    [ -d "$d" ] && { echo "ATLA $1/$(basename "$2")"; return; }
    if git clone --depth 1 --single-branch --quiet "$2" "$d" 2>/dev/null; then
        echo "OK   $1/$(basename "$2")  ($(du -sh "$d" | cut -f1))"
    else
        echo "HATA $1/$(basename "$2")"
    fi
}

# caelestia — kabuk (QML), CLI (Python, tema motoru), dotfile'lar
clone caelestia    https://github.com/caelestia-dots/shell
clone caelestia    https://github.com/caelestia-dots/cli
clone caelestia    https://github.com/caelestia-dots/caelestia

# Omarchy — script'lerin çoğu Arch'a dokunmuyor, taşınabilir fikirlerle dolu
clone omarchy      https://github.com/basecamp/omarchy

# Hyprland — resmi wiki (Lua API örnekleri dahil)
clone hyprland     https://github.com/hyprwm/hyprland-wiki

# openSUSE üzerinde Hyprland
clone opensuse     https://github.com/JaKooLit/openSUSE-Hyprland

# ASUS dizüstüler
clone asus         https://gitlab.com/asus-linux/asusctl
clone asus         https://gitlab.com/asus-linux/supergfxctl

# Diğer quickshell kabukları — karşılaştırma için
clone kabuklar     https://github.com/end-4/dots-hyprland
clone kabuklar     https://github.com/Axenide/Ambxst

echo "=== TOPLAM: $(du -sh "$BASE" | cut -f1) → $BASE ==="
