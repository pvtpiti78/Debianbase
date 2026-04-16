# Debianbase

Post-install scripts for Debian Sid — minimal, gaming-ready, Wayland-only.

## Voraussetzungen

- Debian Sid — Minimalinstallation via `mini.iso` (Expert Install)
- systemd-boot als Bootloader
- Netzwerk aktiv
- `sudo` installiert und konfiguriert

## Reihenfolge

### 1. Base Setup

```bash
wget https://raw.githubusercontent.com/pvtpiti78/Debianbase/main/debian-setup.sh
sudo bash debian-setup.sh
sudo reboot
```

Richtet das komplette System ein:
- APT-Tuning, i386 Multiarch
- Nvidia Open (CUDA Repo) + nvidia-vaapi-driver
- NTSYNC
- Fish + Starship + Kitty (Tokyo Night)
- Fastfetch, Fonts (Noto, JetBrainsMono Nerd Font)
- GStreamer + Codecs + ffmpeg
- Firefox (kein Telemetry, kein Pocket)
- Steam (via protontricks), ProtonPlus, LACT, Faugus, Heroic
- gaming.conf + nvidia.conf (environment.d)
- ZRAM (15%, zstd), zswap deaktiviert
- vm.max_map_count, swappiness=10

### 2. Desktop Environment

Nach dem Reboot eine DE deiner Wahl:

```bash
# GNOME
wget https://raw.githubusercontent.com/pvtpiti78/Debianbase/main/gnome-setup.sh
sudo bash gnome-setup.sh

# KDE Plasma
wget https://raw.githubusercontent.com/pvtpiti78/Debianbase/main/kde-setup.sh
sudo bash kde-setup.sh

# COSMIC
wget https://raw.githubusercontent.com/pvtpiti78/Debianbase/main/cosmic-setup.sh
sudo bash cosmic-setup.sh
```

## Scripts

| Script | Beschreibung |
|---|---|
| `debian-setup.sh` | Base Setup — muss zuerst ausgeführt werden |
| `gnome-setup.sh` | Minimales GNOME + GDM + Wayland |
| `kde-setup.sh` | Minimales KDE Plasma + SDDM + Wayland |
| `cosmic-setup.sh` | Minimales COSMIC + cosmic-greeter + Wayland |

## Hardware

Optimiert für:
- AMD Ryzen 9800X3D
- Nvidia RTX 5080 (nvidia-open)
- 48GB DDR5
- Wayland-only (kein X11 Fallback)

## Hinweise

- GNOME/Nvidia: Bei Cursor-Bug `MUTTER_DEBUG_DISABLE_HW_CURSORS=1` in `/etc/environment.d/gaming.conf` einkommentieren
- COSMIC auf Debian Sid: Pakete möglicherweise nicht vollständig im Repo verfügbar
- Nach Base Setup immer rebooten bevor DE installiert wird — Nvidia Module müssen geladen sein
