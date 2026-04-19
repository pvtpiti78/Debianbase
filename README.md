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
```

Am Ende des Scripts wird gefragt, welche Desktop-Umgebung installiert werden soll.  
Alle DE-Scripts können auch separat ausgeführt werden — **immer zuerst rebooten**.

```bash
sudo reboot
```

Richtet das komplette System ein:
- APT-Tuning, i386 Multiarch
- Nvidia Open (CUDA Repo) + nvidia-vaapi-driver + libnvidia-egl-wayland1
- Nvidia Early Loading in initramfs (verhindert Race Condition bei DM-Start)
- nvidia_drm.modeset=1 + fbdev=1 (modprobe + Kernel cmdline)
- NTSYNC
- Fish + Starship + Kitty (Tokyo Night)
- Fastfetch, Fonts (Noto, JetBrainsMono Nerd Font)
- GStreamer + Codecs + ffmpeg
- Firefox (kein Telemetry, kein Pocket, Hardware-Decoding aktiv)
- Steam (via protontricks), ProtonPlus, LACT, Faugus, Heroic (jeweils latest release)
- gaming.conf + nvidia.conf (environment.d)
- ZRAM (15%, zstd), zswap deaktiviert
- vm.max_map_count, swappiness=10

### 2. Desktop Environment

Wird am Ende von `debian-setup.sh` interaktiv angeboten.  
Alternativ manuell nach dem Reboot:

```bash
# KDE Plasma
wget https://raw.githubusercontent.com/pvtpiti78/Debianbase/main/kde-setup.sh
sudo bash kde-setup.sh

# GNOME
wget https://raw.githubusercontent.com/pvtpiti78/Debianbase/main/gnome-setup.sh
sudo bash gnome-setup.sh

# COSMIC
wget https://raw.githubusercontent.com/pvtpiti78/Debianbase/main/cosmic-setup.sh
sudo bash cosmic-setup.sh
```

## Scripts

| Script | Beschreibung |
|---|---|
| `debian-setup.sh` | Base Setup — muss zuerst ausgeführt werden |
| `kde-setup.sh` | Minimales KDE Plasma + SDDM + Wayland |
| `gnome-setup.sh` | Minimales GNOME + GDM + Wayland |
| `cosmic-setup.sh` | Minimales COSMIC + cosmic-greeter + Wayland (experimentell) |

## Hardware

Optimiert für:
- AMD Ryzen 9800X3D
- Nvidia RTX 5080 (nvidia-open, CUDA Repo)
- 48GB DDR5
- Wayland-only (kein X11 Fallback)

## Nvidia — Änderungen ab Treiber 595

- `modeset=1` ist ab Treiber 595 **driver-seitig default** — wird trotzdem explizit gesetzt
- `fbdev=1` ist noch **nicht** default — wird explizit gesetzt (nötig für stabilen simpledrm-Takeover auf Linux 6.11+)
- Alle Nvidia-Module werden in die initramfs eingetragen (Early Loading) — verhindert Blackscreen/Race Condition bei SDDM/GDM
- `NVreg_EnablePCIeGen3`, `NVreg_UsePageAttributeTable`, `NVreg_RegistryDwords` — entfernt (obsolet)

## Hinweise

- **KDE Blackscreen**: War auf fehlendes Early Loading + fehlendes fbdev zurückzuführen — beides behoben
- **GNOME/Nvidia Cursor-Bug**: Bei Problemen `MUTTER_DEBUG_DISABLE_HW_CURSORS=1` in `/etc/environment.d/nvidia.conf` einkommentieren
- **COSMIC auf Debian Sid**: Script prüft Paketverfügbarkeit vorab und bricht sauber ab falls Core-Pakete fehlen
- Nach Base Setup **immer rebooten** bevor ein DE installiert wird — Nvidia-Module müssen geladen sein
- Alle DE-Scripts prüfen ob `nvidia_drm.modeset` aktiv ist und warnen bei fehlendem Reboot
