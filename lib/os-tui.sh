#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  os-tui.sh — omarchy-suse ortak TUI katmanı
#
#  Kullanım:  source ~/.local/lib/omarchy-suse/os-tui.sh
#
#  Renkler ~/.local/state/caelestia/scheme.json'dan okunur; duvar kağıdı
#  veya şema değişince TUI'ler de birlikte değişir. Dosya yoksa makul
#  varsayılanlara düşer, hiçbir script kırılmaz.
# ═══════════════════════════════════════════════════════════════════

# ── Palet ─────────────────────────────────────────────────────────
_tui_varsayilan() {
    TUI_PRIMARY=dcc74d;  TUI_ON_PRIMARY=383000
    TUI_SURFACE=131313;  TUI_ON_SURFACE=e2e2e2
    TUI_CONTAINER=1f1f1f
    TUI_SECONDARY=d0c7a2; TUI_TERTIARY=a8d0b5
    TUI_ERROR=ffb4ab;    TUI_OUTLINE=919191
    TUI_VARIANT=c6c6c6
}
_tui_varsayilan

_tui_palet_yukle() {
    local s="$HOME/.local/state/caelestia/scheme.json"
    [ -r "$s" ] || return 0
    local out
    out=$(python3 - "$s" <<'PY' 2>/dev/null
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
c = d.get("colours", d)
eş = {
    "TUI_PRIMARY": "primary",       "TUI_ON_PRIMARY": "onPrimary",
    "TUI_SURFACE": "surface",       "TUI_ON_SURFACE": "onSurface",
    "TUI_CONTAINER": "surfaceContainer",
    "TUI_SECONDARY": "secondary",   "TUI_TERTIARY": "tertiary",
    "TUI_ERROR": "error",           "TUI_OUTLINE": "outline",
    "TUI_VARIANT": "onSurfaceVariant",
}
for k, v in eş.items():
    r = c.get(v)
    if isinstance(r, str) and len(r.lstrip("#")) == 6:
        print(f'{k}={r.lstrip("#")}')
PY
    ) || return 0
    [ -n "$out" ] && eval "$out"
    return 0
}
_tui_palet_yukle

# hex → ANSI truecolor
_tui_fg() { printf '\033[38;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
_tui_bg() { printf '\033[48;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
TUI_SIFIR=$'\033[0m'; TUI_KALIN=$'\033[1m'; TUI_SOLUK=$'\033[2m'

C_ANA=$(_tui_fg "$TUI_PRIMARY")
C_IKI=$(_tui_fg "$TUI_SECONDARY")
C_UC=$(_tui_fg "$TUI_TERTIARY")
C_HATA=$(_tui_fg "$TUI_ERROR")
C_CIZGI=$(_tui_fg "$TUI_OUTLINE")
C_SOLUK=$(_tui_fg "$TUI_VARIANT")
C_METIN=$(_tui_fg "$TUI_ON_SURFACE")

# gum bu değişkenleri kendiliğinden okur
export GUM_CHOOSE_CURSOR_FOREGROUND="#$TUI_PRIMARY"
export GUM_CHOOSE_SELECTED_FOREGROUND="#$TUI_PRIMARY"
export GUM_CHOOSE_ITEM_FOREGROUND="#$TUI_ON_SURFACE"
export GUM_CHOOSE_CURSOR="❯ "
export GUM_CONFIRM_PROMPT_FOREGROUND="#$TUI_ON_SURFACE"
export GUM_CONFIRM_SELECTED_BACKGROUND="#$TUI_PRIMARY"
export GUM_CONFIRM_SELECTED_FOREGROUND="#$TUI_ON_PRIMARY"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="#$TUI_VARIANT"
export GUM_INPUT_CURSOR_FOREGROUND="#$TUI_PRIMARY"
export GUM_INPUT_PROMPT_FOREGROUND="#$TUI_PRIMARY"
export GUM_SPIN_SPINNER_FOREGROUND="#$TUI_PRIMARY"
export GUM_FILTER_INDICATOR_FOREGROUND="#$TUI_PRIMARY"
export GUM_FILTER_MATCH_FOREGROUND="#$TUI_PRIMARY"

export FZF_DEFAULT_OPTS="\
--color=fg:#$TUI_ON_SURFACE,bg:-1,hl:#$TUI_PRIMARY \
--color=fg+:#$TUI_ON_SURFACE,bg+:#$TUI_CONTAINER,hl+:#$TUI_PRIMARY \
--color=info:#$TUI_SECONDARY,prompt:#$TUI_PRIMARY,pointer:#$TUI_PRIMARY \
--color=marker:#$TUI_TERTIARY,spinner:#$TUI_PRIMARY,header:#$TUI_VARIANT \
--color=border:#$TUI_OUTLINE \
--pointer='❯' --marker='✓' --border=rounded --layout=reverse"

# ── Yardımcılar ───────────────────────────────────────────────────
_tui_var() { command -v "$1" >/dev/null 2>&1; }
_tui_genislik() { local w=${COLUMNS:-0}; [ "$w" -gt 0 ] || w=$(tput cols 2>/dev/null || echo 80); [ "$w" -gt 100 ] && w=100; echo "$w"; }
# görünen karakter sayısı (ANSI ve emoji/ikon dışı)
_tui_uzunluk() { local s=${1//$'\033'\[*([0-9;])m/}; printf '%s' "$s" | wc -m; }

# ── Başlık: ince çerçeve + ikon ───────────────────────────────────
# baslik "Uygulama Yöneticisi" "󰏖" "zypper + flatpak birleşik arama"
baslik() {
    local ad="$1" ikon="${2:-󰣇}" altyazi="${3:-}"
    local w; w=$(_tui_genislik); local ic=$((w - 2))
    local etiket="  $ikon  $ad"
    # Nerd Font ikonu terminalde 2 hücre kaplar ama ${#} 1 sayar
    local gorunen=$(( ${#etiket} + 1 ))
    local dolgu=$((ic - gorunen)); [ "$dolgu" -lt 0 ] && dolgu=0

    printf '%s╭%s╮%s\n' "$C_CIZGI" "$(printf '─%.0s' $(seq 1 $ic))" "$TUI_SIFIR"
    printf '%s│%s%s%s%*s%s│%s\n' \
        "$C_CIZGI" "$C_ANA$TUI_KALIN" "$etiket" "$TUI_SIFIR" "$dolgu" "" "$C_CIZGI" "$TUI_SIFIR"
    printf '%s╰%s╯%s\n' "$C_CIZGI" "$(printf '─%.0s' $(seq 1 $ic))" "$TUI_SIFIR"
    printf '%s%s%s\n' "$C_SOLUK$TUI_SOLUK" "$(printf '─%.0s' $(seq 1 $w))" "$TUI_SIFIR"
    [ -n "$altyazi" ] && printf '\n %s%s%s\n' "$C_SOLUK" "$altyazi" "$TUI_SIFIR"
    echo
}

# ── Giriş animasyonu (yalnız ilk açılışta) ────────────────────────
# Aynı script aynı terminalde tekrar menüye dönerse oynatılmaz.
giris() {
    local ad="$1" ikon="${2:-󰣇}" altyazi="${3:-}"
    if [ -n "${_TUI_GIRIS_OYNADI:-}" ] || [ ! -t 1 ] || [ -n "${OS_TUI_SESSIZ:-}" ]; then
        baslik "$ad" "$ikon" "$altyazi"; return
    fi
    _TUI_GIRIS_OYNADI=1
    local w; w=$(_tui_genislik)
    printf '\033[?25l'                      # imleci gizle
    # ince çizgi ortadan dışa doğru açılsın
    local orta=$((w / 2)) i
    for ((i = 2; i <= orta; i += 3)); do
        printf '\r%*s%s%s%s' $((orta - i)) "" "$C_ANA" "$(printf '─%.0s' $(seq 1 $((i * 2))))" "$TUI_SIFIR"
        sleep 0.012
    done
    printf '\r%s%s%s\n' "$C_ANA" "$(printf '─%.0s' $(seq 1 $w))" "$TUI_SIFIR"
    sleep 0.05
    printf '\033[1A\033[2K'                 # o çizgiyi sil
    printf '\033[?25h'                      # imleci geri getir
    baslik "$ad" "$ikon" "$altyazi"
}

# ── Masaüstü bildirimi (notify-send yoksa sessizce geç) ───────────
bildir() { command -v notify-send >/dev/null 2>&1 && notify-send "$@" >/dev/null 2>&1; return 0; }

# ── Mesajlar ──────────────────────────────────────────────────────
bilgi()  { printf ' %s%s%s %s\n' "$C_UC"   "󰋼"  "$TUI_SIFIR" "$*"; }
basari() { printf ' %s%s%s %s\n' "$C_UC"   "󰗠"  "$TUI_SIFIR" "$*"; }
uyari()  { printf ' %s%s%s %s\n' "$C_IKI"  "󰀦"  "$TUI_SIFIR" "$*"; }
hata()   { printf ' %s%s%s %s\n' "$C_HATA" "󰅙"  "$TUI_SIFIR" "$*" >&2; }
ayrac()  { printf '%s%s%s\n' "$C_SOLUK$TUI_SOLUK" "$(printf '─%.0s' $(seq 1 $(_tui_genislik)))" "$TUI_SIFIR"; }
baslikcik() { printf '\n %s%s%s%s\n' "$C_ANA$TUI_KALIN" "$*" "$TUI_SIFIR" ""; }

# ── Kısa menü (gum choose, yoksa select) ──────────────────────────
# secim "Ne yapmak istiyorsun?" "󰍉  Ara" "󰏔  Kur" "󰩹  Kaldır"
secim() {
    local soru="$1"; shift
    if _tui_var gum; then
        gum choose --header "$soru" --header.foreground "#$TUI_VARIANT" \
                   --cursor.foreground "#$TUI_PRIMARY" "$@"
    else
        printf ' %s%s%s\n' "$C_SOLUK" "$soru" "$TUI_SIFIR" >&2
        local o; select o in "$@"; do [ -n "$o" ] && { printf '%s\n' "$o"; return; }; done
    fi
}

# ── Uzun/aranabilir liste (fzf, önizlemeli) ───────────────────────
# stdin'den satır alır. ara "Paket ara" "önizleme komutu {}"
ara() {
    local baslik_="${1:-Ara}" onizleme="${2:-}"
    if ! _tui_var fzf; then cat; return; fi
    if [ -n "$onizleme" ]; then
        fzf --prompt "❯ " --header "$baslik_" --preview "$onizleme" \
            --preview-window 'right:45%:wrap:border-left' --height 80%
    else
        fzf --prompt "❯ " --header "$baslik_" --height 60%
    fi
}

# ── Onay ──────────────────────────────────────────────────────────
onay() {
    local soru="$1" varsayilan="${2:-hayir}"
    if _tui_var gum; then
        if [ "$varsayilan" = "evet" ]; then
            gum confirm --affirmative "Evet" --negative "Hayır" "$soru"
        else
            gum confirm --default=false --affirmative "Evet" --negative "Hayır" "$soru"
        fi
    else
        local c; read -r -p " $soru [e/H] " c
        [[ "$c" =~ ^[eEyY] ]]
    fi
}

# ── Metin girişi ──────────────────────────────────────────────────
giris_al() {
    local ipucu="$1" varsayilan="${2:-}"
    if _tui_var gum; then
        gum input --placeholder "$ipucu" --value "$varsayilan" --prompt "❯ "
    else
        local c; read -r -p "❯ " c; printf '%s\n' "${c:-$varsayilan}"
    fi
}

# ── Bekleme göstergesi ────────────────────────────────────────────
# bekle "Depolar taranıyor" komut arg...
bekle() {
    local mesaj="$1"; shift
    if _tui_var gum; then
        gum spin --spinner dot --title "$mesaj" --show-error -- "$@"
    else
        printf ' %s%s…%s\n' "$C_SOLUK" "$mesaj" "$TUI_SIFIR"; "$@"
    fi
}

# ── İlerleme çubuğu ───────────────────────────────────────────────
# ilerleme 7 20 "Paketler kuruluyor"
ilerleme() {
    local su=$1 top=$2 etiket="${3:-}"
    local w=30 dolu
    dolu=$(( top > 0 ? su * w / top : 0 ))
    printf '\r %s%s%s%s%s %s%d/%d%s %s' \
        "$C_ANA" "$(printf '━%.0s' $(seq 1 $dolu))" \
        "$C_SOLUK$TUI_SOLUK" "$(printf '━%.0s' $(seq 1 $((w - dolu))))" "$TUI_SIFIR" \
        "$C_SOLUK" "$su" "$top" "$TUI_SIFIR" "$etiket"
    [ "$su" -ge "$top" ] && echo
}

# ── Kapanış ───────────────────────────────────────────────────────
kapanis() { printf '\n%s%s%s\n' "$C_SOLUK$TUI_SOLUK" "$(printf '─%.0s' $(seq 1 $(_tui_genislik)))" "$TUI_SIFIR"; }
