#!/bin/bash
# =============================================================================
# gnome-setup.sh — Debian Sid GNOME Setup
# =============================================================================
# Voraussetzung: debian-setup.sh / debianp-setup.sh wurde ausgeführt + Reboot
# Umfang: Minimales GNOME, GDM, Wayland-only, Input Remapper
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

[[ $EUID -ne 0 ]] && err "Bitte als root ausführen: sudo bash gnome-setup.sh"

CURRENT_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo "~$CURRENT_USER")

clear
echo -e "${BOLD}${CYAN}"
echo "  ██████╗ ███╗   ██╗ ██████╗ ███╗   ███╗███████╗"
echo "  ██╔════╝████╗  ██║██╔═══██╗████╗ ████║██╔════╝"
echo "  ██║  ███╗██╔██╗ ██║██║   ██║██╔████╔██║█████╗  "
echo "  ██║   ██║██║╚██╗██║██║   ██║██║╚██╔╝██║██╔══╝  "
echo "  ╚██████╔╝██║ ╚████║╚██████╔╝██║ ╚═╝ ██║███████╗"
echo "   ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝"
echo -e "${NC}"
echo -e "  ${BOLD}Debian Sid — GNOME Setup${NC}"
echo -e "  Minimal · GDM · Wayland-only · Input Remapper"
echo ""
warn "Hinweis: GNOME + Nvidia 610+ — Mutter/Cursor-Bug seit Mutter 50.0.2 gefixt."
warn "Workaround falls doch nötig: MUTTER_DEBUG_DISABLE_HW_CURSORS=1 in nvidia.conf einkommentieren"
echo ""
echo -e "  ${YELLOW}ENTER zum Starten, CTRL+C zum Abbrechen.${NC}"
read -r

apt update

# ── GNOME (minimal) installieren ─────────────────────────────────────────────
info "GNOME (minimal) installieren..."
apt install -y \
    gnome-shell \
    gnome-session \
    gnome-control-center \
    gnome-text-editor \
    gnome-tweaks \
    gnome-shell-extension-manager \
    nautilus \
    gdm3 \
    xdg-desktop-portal-gnome \
    gvfs \
    gvfs-backends \
    file-roller \
    adwaita-icon-theme \
    gnome-backgrounds \
    libnvidia-egl-wayland1
log "GNOME installiert"

# ── Unerwünschte Pakete entfernen ─────────────────────────────────────────────
info "Unerwünschte Pakete entfernen..."
UNWANTED=(
    yelp            # GNOME Hilfe
    xterm           # xterm + uxterm
    vim             # Vim
    vim-common
    vim-tiny
    alacritty       # Alacritty Terminal
    malcontent      # Kindersicherung
)
for pkg in "${UNWANTED[@]}"; do
    if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
        apt purge -y "$pkg" && log "  Entfernt: $pkg" || warn "  Konnte nicht entfernen: $pkg"
    else
        info "  Nicht installiert (übersprungen): $pkg"
    fi
done
apt autoremove -y
log "Aufgeräumt"

# ── GDM aktivieren ────────────────────────────────────────────────────────────
info "GDM als Display Manager aktivieren..."
systemctl enable gdm
systemctl set-default graphical.target
log "GDM aktiviert"

# ── Wayland für Nvidia explizit erlauben ──────────────────────────────────────
info "Wayland-only sicherstellen (GDM)..."
sed -i 's/#WaylandEnable=false/WaylandEnable=true/' /etc/gdm3/daemon.conf 2>/dev/null || true
log "Wayland konfiguriert"

# ── GNOME Shell Extensions ────────────────────────────────────────────────────
info "Extensions installieren..."
apt install -y \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-dash-to-panel || \
    warn "Einige Extensions nicht verfügbar — nach GNOME-Start via Extension Manager installieren"
log "Extensions installiert"

# ── Input Remapper ────────────────────────────────────────────────────────────
info "Input Remapper installieren..."
apt install -y input-remapper
systemctl enable --force input-remapper-daemon
log "Input Remapper installiert und aktiviert"

# ── Flatpak + Resources (System Monitor) ─────────────────────────────────────
info "Flatpak + Resources installieren..."
apt install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub net.nokyan.Resources || \
    warn "Resources konnte nicht installiert werden — nach Reboot manuell: flatpak install flathub net.nokyan.Resources"
log "Flatpak + Resources installiert"

# ── Aufräumen ─────────────────────────────────────────────────────────────────
info "Aufräumen..."
apt autoremove -y
apt clean
log "Aufgeräumt"

# ── Abschluss ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  GNOME Setup abgeschlossen!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}System neu starten:${NC}  ${BOLD}sudo reboot${NC}"
echo ""
echo -e "  ${CYAN}Nach dem Reboot prüfen:${NC}"
echo -e "  • Input Remapper:  ${BOLD}systemctl status input-remapper${NC}"
echo ""
echo -e "  ${YELLOW}Falls Cursor-Bug auftritt:${NC}"
echo -e "  /etc/environment.d/nvidia.conf → MUTTER_DEBUG_DISABLE_HW_CURSORS=1 einkommentieren"
echo ""
