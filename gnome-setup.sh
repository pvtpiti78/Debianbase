#!/bin/bash
# =============================================================================
# gnome-setup.sh — Debian Sid GNOME Setup
# =============================================================================
# Voraussetzung: debian-setup.sh wurde ausgeführt + Reboot
# Umfang: Minimales GNOME, GDM, Wayland-only
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
echo -e "  Minimal · GDM · Wayland-only"
echo ""
warn "Hinweis: GNOME + Nvidia 595 — bekannter Mutter/Cursor-Bug möglich."
warn "Workaround falls nötig: MUTTER_DEBUG_DISABLE_HW_CURSORS=1 in nvidia.conf einkommentieren"
echo ""
echo -e "  ${YELLOW}ENTER zum Starten, CTRL+C zum Abbrechen.${NC}"
read -r


# ── Experimental Repo — nur für gnome-shell 50 ───────────────────────────────
info "Experimental Repo einrichten (nur gnome-shell)..."
cat > /etc/apt/sources.list.d/experimental.list << 'EOF'
deb http://deb.debian.org/debian experimental main
EOF

cat > /etc/apt/preferences.d/experimental.pref << 'EOF'
# Experimental generell sperren
Package: *
Pin: release a=experimental
Pin-Priority: 1

# Nur gnome-shell aus Experimental erlauben
Package: gnome-shell
Pin: release a=experimental
Pin-Priority: 990
EOF

apt update
info "gnome-shell 50 aus Experimental installieren..."
apt install -t experimental gnome-shell
log "gnome-shell 50 installiert"


info "GNOME (minimal) installieren..."
apt install -y \
    gnome-shell \
    gnome-session \
    gnome-control-center \
    gnome-text-editor \
    gnome-disk-utility \
    gnome-tweaks \
    gnome-shell-extension-prefs \
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
    gnome-shell-extension-appindicator 2>/dev/null || \
    warn "Einige Extensions nicht verfügbar — nach GNOME-Start via Extension Manager installieren"
# dashtodock separat mit Fallback — Verfügbarkeit in Sid schwankend
apt install -y gnome-shell-extension-dashtodock 2>/dev/null || \
    warn "dashtodock nicht verfügbar — nach Start via extensions.gnome.org installieren"
log "Extensions installiert (soweit verfügbar)"

# ── Flatpak für Resources (System Monitor) ────────────────────────────────────
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
echo -e "  ${YELLOW}Falls Cursor-Bug auftritt:${NC}"
echo -e "  /etc/environment.d/nvidia.conf → MUTTER_DEBUG_DISABLE_HW_CURSORS=1 einkommentieren"
echo ""
