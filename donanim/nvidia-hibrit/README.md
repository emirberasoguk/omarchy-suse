🌐 **English** · [Türkçe](README.tr.md)

# Intel + NVIDIA hybrid laptops

This folder is **optional**. On a single-GPU machine (Intel-only or AMD-only)
you don't need to install anything. If `hyprland.lua` doesn't find the aliases,
it leaves GPU selection to Hyprland.

(`donanim` means "hardware"; `nvidia-hibrit` means "NVIDIA hybrid".)

## What it does

`AQ_DRM_DEVICES` decides which GPUs Hyprland works with. The first card in the
list becomes the primary renderer. On hybrid laptops:

- The compositor should run on the **Intel** GPU for battery life.
- On some models the HDMI/USB-C port is physically wired to the **NVIDIA** GPU.
  If NVIDIA isn't in the list, the external monitor shows nothing.

`61-gpu-alias.rules` creates two stable aliases: `/dev/dri/intel-igpu` and
`/dev/dri/nvidia-dgpu`. When `hyprland.lua` sees them, it builds the list **at
runtime**.

## Installing the rule

Verify the PCI addresses first:

```bash
ls -l /dev/dri/by-path/
```

The Intel iGPU is almost always `0000:00:02.0`; the NVIDIA dGPU is
`0000:01:00.0` on most laptops, but it can differ. Edit the rule if needed,
then:

```bash
sudo install -m 0644 61-gpu-alias.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=drm
ls -l /dev/dri/intel-igpu /dev/dri/nvidia-dgpu
```

## Lessons learned

| Don't | Why |
|---|---|
| Set `GBM_BACKEND=nvidia-drm` | Forcing GBM onto NVIDIA while the compositor runs on the iGPU breaks the session |
| Set a global `LIBVA_DRIVER_NAME=nvidia` | It tries to load the nvidia backend for the Intel render node and `vaInitialize` fails. Screen recording and hardware video decoding in the browser silently stop working |
| Hard-code `AQ_DRM_DEVICES` | After `supergfxctl -m Integrated`, `nvidia-dgpu` disappears and Hyprland tries to open a device that doesn't exist |
| Use `lspci` to detect GPUs | It wakes a sleeping dGPU and can freeze on reload. Use `/dev/dri/by-path/` |
| **Reboot** after `supergfxctl -m <mode>` | A reboot stops supergfxd before it unloads the modules, so the mode isn't applied. **Log out and back in** instead, or set `always_reboot: true` in supergfxd |

## The cost of Integrated mode

`supergfxctl -m Integrated` turns the NVIDIA GPU off completely. Ports wired to
NVIDIA (usually HDMI) **stop working**. When you need an external monitor, run
`supergfxctl -m Hybrid`, then log out and back in.

The GPU submenu in the tray menu (`os-kontrol`) only appears when `supergfxctl`
is installed.

## Intel hardware video

openSUSE may not ship the Intel VA-API driver by default:

```bash
sudo zypper install intel-media-driver libva-utils
vainfo    # you should see "va_openDriver() returns 0"
```

Without it, `caelestia record` hangs with:
`neither h264, hevc nor av1 are supported`.
