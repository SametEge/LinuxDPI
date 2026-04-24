<div align="center">

# LinuxDPI-TR

**Linux desktop application to bypass internet restrictions in Turkey**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python 3.8+](https://img.shields.io/badge/Python-3.8%2B-blue?logo=python)](https://python.org)
[![GTK4](https://img.shields.io/badge/GTK-4-green?logo=gnome)](https://gtk.org)
[![Arch Linux](https://img.shields.io/badge/Arch-Linux-1793D1?logo=arch-linux)](https://archlinux.org)
[![Author](https://img.shields.io/badge/Author-Samet%20Ege%20Derin-orange)](https://github.com/sametege)

</div>

---

## What is it?

**LinuxDPI-TR** is an open-source Linux application developed for internet users in Turkey. It lets you manage DPI (Deep Packet Inspection) bypass and VPN tunneling tools from a single GTK4 interface.

It handles the installation and management of popular tools like Cloudflare WARP, Zapret, and ByeDPI **with a single click** — no technical knowledge required.

---

## Features

| Tab | Description |
|---|---|
| **WireGuard** | WireGuard tunnel via Cloudflare WARP — one-button connect/disconnect |
| **ByeDPI** | DPI bypass via SOCKS5 proxy, runs as a systemd service |
| **Zapret** | System-wide DPI bypass based on nfqws, with ISP-specific presets |
| **DNS** | Google, Cloudflare, Quad9, OpenDNS options |
| **Advanced** | Manage, remove all services, monitor logs |

- Missing tools are **installed automatically** (pacman + AUR)
- **Custom password dialog** instead of Polkit (asks once, caches for the session)
- Dark theme
- Autostart as a systemd service

---

## Installation

### Method 1 — One-liner (Fastest)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sametege/LinuxDPI-TR/main/install.sh)
```

That's it. The script will install all required packages and set everything up automatically.

---

### Method 2 — Step by Step

**Step 1 — Install git if you don't have it**
```bash
sudo pacman -S git
```

**Step 2 — Clone the repository**
```bash
git clone https://github.com/sametege/LinuxDPI-TR.git
cd LinuxDPI-TR
```

**Step 3 — Run the installer**
```bash
bash install.sh
```

The installer will automatically:
- Install required packages (`python-gobject`, `gtk4`, `wireguard-tools`, `nftables`)
- Install AUR tools (`wgcf`, `byedpi`, `zapret`) if you have `yay` or `paru`
- Add the app to `/usr/local/bin/linuxdpi-tr`
- Create a desktop shortcut in your application menu

**Step 4 — Launch**
```bash
linuxdpi-tr
```
Or search for **LinuxDPI-TR** in your application menu.

---

### Method 3 — Run Without Installing

If you just want to try it without installing:

```bash
git clone https://github.com/sametege/LinuxDPI-TR.git
cd LinuxDPI-TR
python3 linuxdpi.py
```

> You may need to install dependencies manually first:
> ```bash
> sudo pacman -S python-gobject wireguard-tools nftables
> yay -S wgcf byedpi zapret   # requires yay or paru
> ```

---

## Requirements

| Required | Optional |
|---|---|
| Python 3.8+ | yay or paru (AUR helper) |
| python-gobject (GTK4) | proxychains-ng |
| wireguard-tools | |
| nftables | |

> Without an AUR helper, `wgcf`, `byedpi`, and `zapret` cannot be installed automatically — you can install them manually or through the app later.

---

## Usage

### WireGuard / Cloudflare WARP

1. Switch to the **WireGuard** tab
2. Click **"Connect"**
3. Password is requested on first run (once per session)
4. Missing tools are installed automatically, registration is done, and the connection is established

### ByeDPI (SOCKS5 Proxy)

1. Switch to the **ByeDPI** tab
2. Set the port number (default: `1080`)
3. Click **"Install Service"**
4. Set your browser proxy to `127.0.0.1:1080`

> For Discord: `proxychains discord`

### Zapret (System-wide DPI Bypass)

1. Switch to the **Zapret** tab
2. Select your ISP (Turk Telekom / Turkcell / Vodafone TR / Generic)
3. **"Install Service"** — starts automatically at boot
4. **"Run Once"** — runs only for the current session

### DNS Settings

1. Switch to the **DNS** tab
2. Select a DNS server
3. Click **"Apply DNS"**

---

## Screenshots

> *(Screenshots coming soon)*

---

## Supported Distributions

The primary target is **Arch Linux**, but it works on any distribution with GTK4 and Python:

- Arch Linux / CachyOS / Manjaro
- Fedora (package names may differ)
- Ubuntu 22.04+ / Debian 12+

---

## Tools & Credits

- **[wgcf](https://github.com/ViRb3/wgcf)** — Cloudflare WARP WireGuard profile generator
- **[wireguard-tools](https://git.zx2c4.com/wireguard-tools)** — WireGuard VPN client
- **[byedpi](https://github.com/hufrea/byedpi)** — DPI bypass SOCKS5 proxy
- **[zapret](https://github.com/bol-van/zapret)** — System-wide DPI bypass (nfqws)
- **[nftables](https://netfilter.org/projects/nftables/)** — Linux packet filtering

---

## Disclaimer

This software is intended for **educational and personal use only.**  
The user is solely responsible for any legal consequences arising from its use.

---

## License

MIT License — © 2026 Samet Ege Derin  
See the [LICENSE](LICENSE) file for details.

---

## Contributing

Feel free to open pull requests and issues.  
GitHub: [github.com/sametege/LinuxDPI-TR](https://github.com/sametege/LinuxDPI-TR)
