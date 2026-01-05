# HyprQuickOcr

A stylish, interactive OCR (Optical Character Recognition) tool for Hyprland, built with **Quickshell**. 

It allows you to "freeze" your screen, select a region with a smooth animated overlay, and instantly copy the text within that region to your clipboard.

![License](https://img.shields.io/badge/License-MIT-blue.svg)

## 📦 Requirements
1.  **[Quickshell](https://github.com/outfoxxed/quickshell)**
2.  `grim`
3.  `imagemagick`
4.  `tesseract` (and language data, e.g., `tesseract-data-eng`)
5.  `wl-clipboard`
6.  `libnotify`

## 🚀 Installation
1.  **Clone the repository:**
    ```bash
    mkdir -p ~/.config/quickshell
    git clone [https://github.com/YOUR_USERNAME/HyprQuickOcr.git](https://github.com/YOUR_USERNAME/HyprQuickOcr.git) ~/.config/quickshell/HyprQuickOcr
    ```

2.  **Verify Files:**
    Ensure `Ocr.qml` and `dimming.frag.qsb` are in the folder.

## ⚙️ Configuration (Hyprland)
Add this to `hyprland.conf`:
```ini
bindr = SUPER SHIFT, T, exec, quickshell -p ~/.config/quickshell/HyprQuickOcr/Ocr.qml
