# Üçüncü taraf bildirimleri

omarchy-suse, GNU GPL v3 ile lisanslanmıştır (bkz. `LICENSE`). Aşağıdaki
kısımlar başka projelerden uyarlanmıştır ya da onlarla birlikte çalışır.

Bu proje **Basecamp/Omarchy, caelestia-dots veya hyprwm ile bağlantılı değildir**
ve onlar tarafından onaylanmamıştır. "Omarchy" adı yalnızca ilham kaynağını
belirtmek için kullanılmıştır.

## Omarchy — MIT Lisansı

Aşağıdaki script'ler [basecamp/omarchy](https://github.com/basecamp/omarchy)
içindeki karşılıklarının mantığından uyarlanmıştır:

| Script | Omarchy karşılığı |
|---|---|
| `bin/os-webapp` | `omarchy-webapp-install` |
| `bin/os-ac-odaklan` | `omarchy-launch-or-focus` |
| `bin/os-pencere` | `omarchy-toggle-*` |
| `bin/os-gece` | `omarchy-toggle-nightlight` |
| `bin/os-kapak` | `omarchy-system-lid-close` |
| `bin/os-pano-kaydet` | `omarchy-clipboard-paste-file` (ters yönde) |
| `bin/os-paylas` | `omarchy-menu-share` |
| `bin/os-font` | `omarchy-font-list` / `omarchy-font-set` |
| `bin/os-uygulama` | `omarchy-install-*` ailesi (fikir) |

Omarchy'nin lisans metni, MIT lisansının gerektirdiği şekilde aşağıda aynen
yer almaktadır:

```
Copyright (c) David Heinemeier Hansson

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## caelestia

[caelestia-dots/shell](https://github.com/caelestia-dots/shell) ve
[caelestia-dots/cli](https://github.com/caelestia-dots/cli) GPL v3 ile
lisanslanmıştır. Bu depo caelestia'nın **kodunu içermez**. Yalnızca onun
yapılandırma dosyalarını (`shell.json`, `cli.json`) ve belgelenmiş
arayüzlerini (IPC, launcher eylemleri, `theme.postHook`, sistem tepsisi)
kullanır. Kurulum `home:kaiman` OBS deposundaki paketlerle yapılır.

## Fontlar

`kurulum.sh` şu fontları kullanıcının kendi makinesine **indirir**. Bu depoda
dağıtılmazlar:

- Material Symbols Rounded — Google, Apache License 2.0
- Rubik — Google Fonts, SIL Open Font License 1.1
- CaskaydiaCove Nerd Font — Nerd Fonts / Microsoft Cascadia Code, SIL Open Font License 1.1
