# Documentation · Belgeler

Every document is available in each language below. The file names are the
same in every language folder, so you can switch by changing only the folder
in the path.

Her belge aşağıdaki dillerin hepsinde var. Dosya adları her dil klasöründe
aynı; dili değiştirmek için yoldaki klasör adını değiştirmen yeterli.

| Document · Belge | English | Türkçe |
|---|---|---|
| Overview · Genel bakış | [README.md](../README.md) | [README.tr.md](../README.tr.md) |
| Installation · Kurulum | [en/INSTALL.md](en/INSTALL.md) | [tr/INSTALL.md](tr/INSTALL.md) |
| Troubleshooting · Tuzaklar | [en/TROUBLESHOOTING.md](en/TROUBLESHOOTING.md) | [tr/TROUBLESHOOTING.md](tr/TROUBLESHOOTING.md) |
| Hyprland Lua config | [en/HYPRLAND-LUA.md](en/HYPRLAND-LUA.md) | [tr/HYPRLAND-LUA.md](tr/HYPRLAND-LUA.md) |
| Extending caelestia · Eklenti yazma | [en/EXTENDING.md](en/EXTENDING.md) | [tr/EXTENDING.md](tr/EXTENDING.md) |
| NVIDIA hybrid · NVIDIA hibrit | [README.md](../donanim/nvidia-hibrit/README.md) | [README.tr.md](../donanim/nvidia-hibrit/README.tr.md) |
| Third-party notices · Bildirimler | [NOTICE.md](../NOTICE.md) | [NOTICE.tr.md](../NOTICE.tr.md) |

## Adding a language · Yeni dil eklemek

1. Copy `docs/en/` to `docs/<code>/` (e.g. `docs/de/`) and translate the files.
   Keep the file names.
2. Translate `README.md` as `README.<code>.md`, and do the same for `NOTICE.md`
   and `donanim/nvidia-hibrit/README.md`.
3. Add your language to the 🌐 line at the top of **every** version of each
   document, and add a column to the table above.
4. Heading anchors change when headings are translated. Check links such as
   `TROUBLESHOOTING.md#…` inside your translation.

English is the reference version. If the English and another translation
disagree, the English text is correct, and the translation should be updated.
