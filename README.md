# HyprQuickSnip

A lightweight, native Wayland utility for **Optical Character Recognition (OCR)** and **Visual Search**, built with Quickshell. Designed to fit seamlessly into Hyprland with a polished, animated UI.

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Wayland](https://img.shields.io/badge/Wayland-Native-green.svg)
![Quickshell](https://img.shields.io/badge/Built%20With-Quickshell-cba6f7.svg)

## ✨ Features

* **⚡ Instant OCR:** Select an area to instantly copy text to your clipboard using Tesseract.
* **🔍 Visual Search:** Send a snapshot directly to **Google Lens** to identify objects, translate text, or find shopping links.
* **✨ Polished UI:**
    * **Shader-based Dimming:** The unselected area dims smoothly using a fragment shader.
    * **Spring Animations:** Selection boxes resize with fluid physics.
    * **Smart Guides:** Crosshairs appear for precision alignment before you click.
    * **Control Bar:** A floating "pill" menu allows you to switch modes on the fly.
* **Quickshell** doesn't stay running in the background. It just pops up when you need it, runs the OCR, and then kills itself immediately

 🎥 Demo 
  
  
https://github.com/user-attachments/assets/aafa197b-111f-4b40-aab4-90a7b66a1ef1


## 📦 Requirements

1.  **[Quickshell](https://github.com/outfoxxed/quickshell)**
2.  `grim` (Screenshot utility)
3.  `imagemagick` (Image cropping/processing)
4.  `tesseract` + `tesseract-data-eng` (OCR engine)
5.  `wl-clipboard` (Clipboard management)
6.  `curl` & `jq` (Required for the Lens upload mechanism)
7.  `libnotify` (Desktop notifications)

## 🚀 Installation

### 1. Install System Dependencies
**Arch Linux:**
```bash
sudo pacman -S grim imagemagick tesseract tesseract-data-eng wl-clipboard curl jq libnotify xdg-utils
```
**Install Quickshell (from AUR)**
```bash        
yay -S quickshell-git
```

2.  **Clone the repository:** 
   ```bash
mkdir -p ~/.config/quickshell 
   git clone https://github.com/Ronin-CK/HyprQuickSnip.git ~/.config/quickshell/HyprQuickSnip
```




## ⚙️ Configuration (Hyprland)
Add this to `hyprland.conf`:
```ini
bind = Super Shift, T, exec, quickshell -c HyprQuickSnip -n
```

## ⚡️ Troubleshooting

### Selection area is offset/shifted

**Symptom:** When you capture an area, the resulting image is shifted to the left or in the wrong position.

**Cause:** This happens when Qt scaling environment variables (like `QT_SCALE_FACTOR` or `QT_AUTO_SCREEN_SCALE_FACTOR`) conflict with Hyprland's native scaling.

**Solution:** Disable Qt scaling when launching the tool. Update your keybinding in `hyprland.conf`:

```bash
bind = SUPER SHIFT, T, exec, env QT_SCALE_FACTOR=1 QT_AUTO_SCREEN_SCALE_FACTOR=0 quickshell -c HyprQuickSnip -n
```
