🌐 [English](README.md) · **Türkçe**

# Intel + NVIDIA hibrit dizüstüler

Bu klasör **isteğe bağlıdır**. Tek GPU'lu (yalnız Intel veya yalnız AMD)
bir makinede hiçbir şey kurman gerekmez. `hyprland.lua` takma adları
bulamazsa GPU seçimini Hyprland'e bırakır.

## Ne işe yarar

Hyprland'in hangi GPU'larla çalışacağını `AQ_DRM_DEVICES` belirler. İlk sıradaki
kart birincil renderer olur. Hibrit dizüstülerde:

- Compositor pil ömrü için **Intel**'de koşmalı.
- Bazı modellerde HDMI/USB-C portu fiziksel olarak **NVIDIA**'ya bağlıdır.
  NVIDIA listede yoksa harici monitör görüntü vermez.

`61-gpu-alias.rules` iki kararlı takma ad oluşturur: `/dev/dri/intel-igpu` ve
`/dev/dri/nvidia-dgpu`. `hyprland.lua` bunları görürse listeyi **çalışma
anında** kurar.

## Kuralı kurmak

Önce PCI adreslerini doğrula:

```bash
ls -l /dev/dri/by-path/
```

Intel iGPU neredeyse her zaman `0000:00:02.0`'dır. NVIDIA dGPU çoğu dizüstüde
`0000:01:00.0`'dır ama farklı olabilir. Gerekirse kuralı düzenle, sonra:

```bash
sudo install -m 0644 61-gpu-alias.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=drm
ls -l /dev/dri/intel-igpu /dev/dri/nvidia-dgpu
```

## Öğrenilmiş dersler

| Yapma | Neden |
|---|---|
| `GBM_BACKEND=nvidia-drm` koymak | Compositor iGPU'dayken GBM'i NVIDIA'ya zorlamak oturumu kırar |
| Global `LIBVA_DRIVER_NAME=nvidia` | Intel render düğümü için nvidia arka ucunu yükletmeye çalışır, `vaInitialize` düşer. Ekran kaydı ve tarayıcıda donanımsal video çözme sessizce çalışmaz |
| `AQ_DRM_DEVICES`'ı sabit yazmak | `supergfxctl -m Integrated` sonrası `nvidia-dgpu` yok olur, Hyprland olmayan cihazı açmaya çalışır |
| GPU tespitinde `lspci` | Uyuyan dGPU'yu uyandırır, reload'da donmaya yol açabilir. `/dev/dri/by-path/` kullan |
| `supergfxctl -m <mod>` sonrası **reboot** | Reboot, supergfxd modülleri boşaltmadan servisi durdurur, mod uygulanmaz. Doğrusu **oturumu kapatıp açmak** (logout) ya da supergfxd'de `always_reboot: true` |

## Integrated modun bedeli

`supergfxctl -m Integrated` NVIDIA'yı tamamen kapatır. NVIDIA'ya bağlı portlar
(genelde HDMI) **ölür**. Harici monitör gerektiğinde `supergfxctl -m Hybrid`
ve ardından oturumu kapatıp aç.

Tepsi menüsündeki (`os-kontrol`) GPU alt menüsü yalnızca `supergfxctl` kuruluysa
görünür.

## Intel donanımsal video

openSUSE'de Intel VA-API sürücüsü varsayılan gelmeyebilir:

```bash
sudo zypper install intel-media-driver libva-utils
vainfo    # "va_openDriver() returns 0" görmelisin
```

Bu olmadan `caelestia record` şu hatayla asılı kalır:
`neither h264, hevc nor av1 are supported`.
