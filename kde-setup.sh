#!/bin/bash
# =============================================================================
# kde-setup.sh — Debian Sid KDE Plasma Setup
# =============================================================================
# Voraussetzung: debian-setup.sh wurde ausgeführt + Reboot
# Umfang: Minimales KDE Plasma, SDDM, Wayland-only
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
info() { echo -e "${CYAN}[→]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; exit 1; }

[[ $EUID -ne 0 ]] && err "Bitte als root ausführen: sudo bash kde-setup.sh"

CURRENT_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo "~$CURRENT_USER")

clear
echo -e "${BOLD}${CYAN}"
echo "  ██╗  ██╗██████╗ ███████╗"
echo "  ██║ ██╔╝██╔══██╗██╔════╝"
echo "  █████╔╝ ██║  ██║█████╗  "
echo "  ██╔═██╗ ██║  ██║██╔══╝  "
echo "  ██║  ██╗██████╔╝███████╗"
echo "  ╚═╝  ╚═╝╚═════╝ ╚══════╝"
echo -e "${NC}"
echo -e "  ${BOLD}Debian Sid — KDE Plasma Setup${NC}"
echo -e "  Minimal · SDDM · Wayland-only"
echo ""
echo -e "  ${YELLOW}ENTER zum Starten, CTRL+C zum Abbrechen.${NC}"
read -r

# ── Nvidia DRM Check ──────────────────────────────────────────────────────────
info "Nvidia DRM modeset prüfen..."
MODESET=$(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null || echo "N")
if [ "$MODESET" != "Y" ]; then
    warn "nvidia_drm.modeset ist nicht aktiv!"
    warn "Hast du nach debian-setup.sh neu gestartet?"
    warn "Fortfahren auf eigene Gefahr — Blackscreen möglich."
    echo -ne "  ${YELLOW}Trotzdem fortfahren? [j/N]:${NC} "
    read -r FORCE
    [[ "$FORCE" != "j" && "$FORCE" != "J" ]] && err "Abgebrochen."
else
    log "nvidia_drm.modeset = Y — alles gut"
fi

# ── KDE Plasma — minimale Pakete ──────────────────────────────────────────────
info "KDE Plasma (minimal) installieren..."
apt install -y \
    plasma-desktop \
    plasma-nm \
    plasma-pa \
    kscreen \
    kde-config-gtk-style \
    libappindicator3-1 \
    qt6-wayland \
    sddm \
    dolphin \
    kate \
    ark \
    breeze-gtk-theme \
    breeze-icon-theme \
    xdg-desktop-portal-kde \
    gvfs \
    gvfs-backends \
    libnvidia-egl-wayland1 \
    plasma-systemmonitor
log "KDE Plasma installiert"

# ── SDDM aktivieren ───────────────────────────────────────────────────────────
info "SDDM als Display Manager aktivieren..."
systemctl enable sddm
systemctl set-default graphical.target
log "SDDM aktiviert"

# ── SDDM Wayland konfigurieren ────────────────────────────────────────────────
# DisplayServer=wayland — SDDM selbst auf Wayland
# CompositorCommand — KWin als Wayland-Compositor für SDDM-Greeter
# QT_WAYLAND_SHELL_INTEGRATION — layer-shell für SDDM-Greeter
info "SDDM Wayland konfigurieren..."
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/wayland.conf << 'EOF'
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --no-lockscreen
EOF
log "SDDM Wayland konfiguriert"


# ── Unerwünschte KDE-Pakete entfernen + pinnen ───────────────────────────────
# plasma-desktop zieht via Recommends einiges mit das wir nicht wollen.
# Pinning auf -1 verhindert dass sie bei Updates wiederkommen.
info "Unerwünschte KDE-Pakete entfernen..."
KDE_UNWANTED=(
    plasma-discover
    plasma-discover-common
    plasma-discover-backend-fwupd
    kdeconnect
    kdeconnect-libs
    qml6-module-org-kde-kdeconnect
    libkdsoapwsdiscoveryclient0
    plasma-welcome
    plasma-firewall
    plasma-vault
    plasma-thunderbolt
    plasma-browser-integration
    alacritty
    partitionmanager
    kwalletmanager
    spectacle
)

# Pinning — kommen nie wieder
cat > /etc/apt/preferences.d/kde-unwanted.pref << 'EOF'
# Unerwünschte KDE-Pakete — via Recommends reingezogen, nicht benötigt
Package: plasma-discover plasma-discover-common plasma-discover-backend-fwupd kdeconnect kdeconnect-libs qml6-module-org-kde-kdeconnect libkdsoapwsdiscoveryclient0 plasma-welcome plasma-firewall plasma-vault plasma-thunderbolt plasma-browser-integration alacritty partitionmanager kwalletmanager spectacle
Pin: release *
Pin-Priority: -1
EOF

# Entfernen falls bereits installiert
apt-mark auto "${KDE_UNWANTED[@]}" 2>/dev/null || true
apt purge -y "${KDE_UNWANTED[@]}" 2>/dev/null || true
log "Unerwünschte KDE-Pakete entfernt und gepinnt"

# ── Aufräumen ─────────────────────────────────────────────────────────────────
info "Aufräumen..."
apt autoremove -y
apt clean
log "Aufgeräumt"

# ── Abschluss ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  KDE Plasma Setup abgeschlossen!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}System neu starten:${NC}  ${BOLD}sudo reboot${NC}"
echo ""
echo -e "  ${CYAN}Nach dem Reboot prüfen:${NC}"
echo -e "  • DRM aktiv:  ${BOLD}cat /sys/module/nvidia_drm/parameters/modeset${NC}  → Y"
echo -e "  • fbdev:      ${BOLD}cat /sys/module/nvidia_drm/parameters/fbdev${NC}     → Y"
echo ""
