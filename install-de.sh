#!/bin/bash
# =============================================================================
# install-de.sh — Desktop Environment Auswahl
# =============================================================================
# Voraussetzung: debian-setup.sh wurde ausgeführt + Reboot
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

[[ $EUID -ne 0 ]] && err "Bitte als root ausführen: sudo bash install-de.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear
echo -e "${BOLD}${CYAN}"
echo "  ██████╗ ███████╗██████╗ ██╗ █████╗ ███╗   ██╗"
echo "  ██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗  ██║"
echo "  ██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║"
echo "  ██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║"
echo "  ██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║"
echo "  ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e "${NC}"
echo -e "  ${BOLD}Debian Sid — Desktop Environment${NC}"
echo ""

# ── Reboot-Check (Nvidia DRM) ─────────────────────────────────────────────────
MODESET=$(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null || echo "N")
if [ "$MODESET" != "Y" ]; then
    warn "nvidia_drm.modeset ist nicht aktiv — wurde nach debian-setup.sh neu gestartet?"
    warn "Installation ohne Reboot kann zu Blackscreen führen."
    echo ""
    echo -ne "  ${YELLOW}Trotzdem fortfahren? [j/N]:${NC} "
    read -r FORCE
    [[ "$FORCE" != "j" && "$FORCE" != "J" ]] && err "Abgebrochen — bitte erst rebooten."
else
    log "nvidia_drm.modeset = Y"
fi

echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}  Desktop Environment wählen${NC}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}[1]${NC}  KDE Plasma  — minimal, SDDM, Wayland"
echo -e "  ${BOLD}[2]${NC}  GNOME       — minimal, GDM, Wayland"
echo -e "  ${BOLD}[3]${NC}  COSMIC      — minimal, cosmic-greeter, Wayland ${YELLOW}(experimentell)${NC}"
echo -e "  ${BOLD}[4]${NC}  Kein DE     — TTY-System, ich weiß was ich tue"
echo ""
echo -ne "  ${YELLOW}Auswahl [1/2/3/4]:${NC} "
read -r DE_CHOICE

case "$DE_CHOICE" in
    1)
        SCRIPT="$SCRIPT_DIR/kde-setup.sh"
        [ -f "$SCRIPT" ] || err "kde-setup.sh nicht gefunden in $SCRIPT_DIR"
        echo ""
        bash "$SCRIPT"
        ;;
    2)
        SCRIPT="$SCRIPT_DIR/gnome-setup.sh"
        [ -f "$SCRIPT" ] || err "gnome-setup.sh nicht gefunden in $SCRIPT_DIR"
        echo ""
        bash "$SCRIPT"
        ;;
    3)
        SCRIPT="$SCRIPT_DIR/cosmic-setup.sh"
        [ -f "$SCRIPT" ] || err "cosmic-setup.sh nicht gefunden in $SCRIPT_DIR"
        echo ""
        bash "$SCRIPT"
        ;;
    4)
        echo ""
        log "Kein DE — TTY-System bleibt wie es ist."
        echo ""
        ;;
    *)
        err "Ungültige Auswahl."
        ;;
esac
