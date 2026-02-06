# HyprQuickSnip

A Wayland utility for OCR and Google Lens search, built for Hyprland using Quickshell. It's meant to be fast, minimal, and stay out of your way.

## What it does

* **OCR**: Drag a box, get the text in your clipboard. It uses Tesseract under the hood and cleans up the whitespace so you don't get 20 weird newlines.
* **Google Lens**: Uploads a cropped region to Lens. Since Lens doesn't have a public API, it fakes a multipart form POST by injecting a base64'd JPEG into a temporary HTML file and opening it. It's faster than using an image host.
* **UI**: Uses fragment shaders for background dimming and spring physics for the selection box. It looks nice but doesn't eat your CPU.
* **Lifecycle**: Quickshell only runs while you're selecting. Once the action is done, it kills itself.

## Demo

<details>
<summary>Click to view demo</summary>
<video>src="https://github.com/user-attachments/assets/fb451e91-b39c-4a63-b9ed-f6064a765c8f" controls width="100%"
</video>
</details>

## Shortcuts

* `Tab`: Toggle modes (OCR / Lens)
* `t`: Switch to OCR
* `g`: Switch to Lens
* `Escape`: Quit (cleans up temp files)
* `Left Mouse`: Select region

## Setup

You'll need `quickshell`, `grim`, `imagemagick`, `tesseract` (with English data), `wl-clipboard`, `curl`, and `libnotify`.

On Arch:
```bash
sudo pacman -S grim imagemagick tesseract tesseract-data-eng wl-clipboard curl libnotify xdg-utils
# Get quickshell from AUR
yay -S quickshell-git
```

Clone it into your config:
```bash
mkdir -p ~/.config/quickshell 
git clone https://github.com/Ronin-CK/HyprQuickSnip.git ~/.config/quickshell/HyprQuickSnip
```

## Hyprland Config

Add a bind to launch it:
```ini
bind = $mainMod SHIFT, T, exec, quickshell -c HyprQuickSnip -n
```

**Note on Scaling**: If the selection area looks shifted or wrong, it's probably Qt scaling fighting with Hyprland. You can force it to 1 like this:
```bash
bind = $mainMod SHIFT, T, exec, env QT_SCALE_FACTOR=1 QT_AUTO_SCREEN_SCALE_FACTOR=0 quickshell -c HyprQuickSnip -n
```
