#!/bin/bash
# =============================================================================
# cosmic-setup.sh — Debian Sid COSMIC Desktop Setup
# =============================================================================
# Voraussetzung: debian-setup.sh wurde ausgeführt
# Umfang: Minimales COSMIC, cosmic-greeter, Wayland-only
# Kein cosmic-terminal, kein cosmic-store
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

[[ $EUID -ne 0 ]] && err "Bitte als root ausführen: sudo bash cosmic-setup.sh"

CURRENT_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo "~$CURRENT_USER")

clear
echo -e "${BOLD}${CYAN}"
echo "  ██████╗ ██████╗ ███████╗███╗   ███╗██╗ ██████╗"
echo "  ██╔════╝██╔═══██╗██╔════╝████╗ ████║██║██╔════╝"
echo "  ██║     ██║   ██║███████╗██╔████╔██║██║██║     "
echo "  ██║     ██║   ██║╚════██║██║╚██╔╝██║██║██║     "
echo "  ╚██████╗╚██████╔╝███████║██║ ╚═╝ ██║██║╚██████╗"
echo "   ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝ ╚═════╝"
echo -e "${NC}"
echo -e "  ${BOLD}Debian Sid — COSMIC Desktop Setup${NC}"
echo -e "  Minimal · cosmic-greeter · Wayland-only"
echo ""
warn "Hinweis: COSMIC auf Debian Sid — Pakete möglicherweise nicht vollständig verfügbar."
echo ""
echo -e "  ${YELLOW}ENTER zum Starten, CTRL+C zum Abbrechen.${NC}"
read -r

# ── COSMIC — minimale Pakete ──────────────────────────────────────────────────
info "COSMIC Desktop (minimal) installieren..."
apt install -y \
    cosmic-session \
    cosmic-comp \
    cosmic-panel \
    cosmic-applets \
    cosmic-app-library \
    cosmic-launcher \
    cosmic-workspaces \
    cosmic-bg \
    cosmic-wallpapers \
    cosmic-settings \
    cosmic-settings-daemon \
    cosmic-notifications \
    cosmic-osd \
    cosmic-screenshot \
    cosmic-randr \
    cosmic-greeter \
    cosmic-files \
    cosmic-text-editor \
    xdg-desktop-portal-cosmic
log "COSMIC Desktop installiert"

# ── cosmic-greeter aktivieren ─────────────────────────────────────────────────
info "cosmic-greeter aktivieren..."
systemctl enable cosmic-greeter
systemctl set-default graphical.target
log "cosmic-greeter aktiviert"

# ── Fastfetch COSMIC-Variante ─────────────────────────────────────────────────
info "Fastfetch für COSMIC konfigurieren..."
mkdir -p "$USER_HOME/.config/fastfetch"
cat > "$USER_HOME/.config/fastfetch/config.jsonc" << 'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "source": "debian",
    "padding": { "right": 2 }
  },
  "modules": [
    "title", "separator",
    { "type": "os",      "key": "OS      " },
    { "type": "kernel",  "key": "Kernel  " },
    { "type": "de",      "key": "DE      " },
    { "type": "wm",      "key": "WM      " },
    { "type": "shell",   "key": "Shell   " },
    { "type": "cpu",     "key": "CPU     " },
    { "type": "gpu",     "key": "GPU     " },
    { "type": "memory",  "key": "RAM     " },
    { "type": "disk",    "key": "Disk    " },
    { "type": "uptime",  "key": "Uptime  " }
  ]
}
EOF
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/fastfetch"
log "Fastfetch konfiguriert"

# ── Aufräumen ─────────────────────────────────────────────────────────────────
info "Aufräumen..."
apt autoremove -y
apt clean
log "Aufgeräumt"

# ── Abschluss ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  COSMIC Setup abgeschlossen!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}System neu starten:${NC}  ${BOLD}sudo reboot${NC}"
echo ""
