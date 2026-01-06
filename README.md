# HyprQuickOcr

HyprQuickOcr is a lightweight, minimal OCR utility for Hyprland, built with Quickshell.

Modern, minimal UI designed to feel native on Hyprland


https://github.com/user-attachments/assets/041aef81-a955-4c9c-8276-2322cbc23475




![License](https://img.shields.io/badge/License-MIT-blue.svg)

## 📦 Requirements
1.  **[Quickshell](https://github.com/outfoxxed/quickshell)**
2.  `grim`
3.  `imagemagick`
4.  `tesseract` (and language data, e.g., `tesseract-data-eng`)
5.  `wl-clipboard`
6.  `libnotify`

## 🚀 Installation
1. **Install Dependencies**
# Install system tools
```bash
sudo pacman -S grim imagemagick tesseract tesseract-data-eng wl-clipboard libnotify
```

# Install Quickshell (from AUR)
```bash        
yay -S quickshell-git
```

2.  **Clone the repository:** 
   ```bash
mkdir -p ~/.config/quickshell 
   git clone https://github.com/Ronin-CK/HyprQuickOcr.git ~/.config/quickshell/HyprQuickOcr
```




## ⚙️ Configuration (Hyprland)
Add this to `hyprland.conf`:
```ini
bindr = SUPER SHIFT, T, exec, quickshell -p ~/.config/quickshell/HyprQuickOcr/Ocr.qml
