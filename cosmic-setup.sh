#!/bin/bash
# =============================================================================
# cosmic-setup.sh — Debian Sid COSMIC Desktop Setup
# =============================================================================
# Voraussetzung: debian-setup.sh wurde ausgeführt + Reboot
# Umfang: Minimales COSMIC, cosmic-greeter, Wayland-only
# Kein cosmic-terminal, kein cosmic-store
#
# HINWEIS: COSMIC auf Debian Sid ist experimentell. Die Pakete werden aktiv
# entwickelt und können im Repo fehlen, unvollständig oder instabil sein.
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
warn "COSMIC auf Debian Sid ist experimentell!"
warn "Pakete können fehlen oder instabil sein — auf eigene Gefahr."
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

# ── COSMIC Pakete verfügbarkeit prüfen ───────────────────────────────────────
info "COSMIC Pakete im Repo prüfen..."
COSMIC_CORE_PACKAGES=(
    cosmic-session
    cosmic-comp
    cosmic-panel
    cosmic-greeter
)
MISSING_CORE=()
for pkg in "${COSMIC_CORE_PACKAGES[@]}"; do
    if ! apt-cache show "$pkg" &>/dev/null; then
        MISSING_CORE+=("$pkg")
    fi
done

if [ ${#MISSING_CORE[@]} -gt 0 ]; then
    echo ""
    err "Kritische COSMIC-Pakete fehlen im Repo: ${MISSING_CORE[*]}"
    echo -e "  ${YELLOW}COSMIC ist auf diesem System/Repo noch nicht verfügbar.${NC}"
    echo -e "  ${YELLOW}Abbruch — kein kaputtes System.${NC}"
    exit 1
fi
log "COSMIC Core-Pakete verfügbar"

# ── COSMIC — minimale Pakete ──────────────────────────────────────────────────
# Optionale Pakete mit Fallback — nicht alle sind immer in Sid vorhanden
info "COSMIC Desktop (minimal) installieren..."
COSMIC_REQUIRED=(
    cosmic-session
    cosmic-comp
    cosmic-panel
    cosmic-applets
    cosmic-app-library
    cosmic-launcher
    cosmic-workspaces
    cosmic-bg
    cosmic-settings
    cosmic-settings-daemon
    cosmic-notifications
    cosmic-osd
    cosmic-greeter
    xdg-desktop-portal-cosmic
    libnvidia-egl-wayland1
)
COSMIC_OPTIONAL=(
    cosmic-wallpapers
    cosmic-screenshot
    cosmic-randr
    cosmic-files
    cosmic-text-editor
)

apt install -y "${COSMIC_REQUIRED[@]}"

# Optionale Pakete einzeln — kein Abbruch bei Fehler
for pkg in "${COSMIC_OPTIONAL[@]}"; do
    apt install -y "$pkg" 2>/dev/null || warn "$pkg nicht verfügbar — wird übersprungen"
done

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
