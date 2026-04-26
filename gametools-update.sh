#!/bin/bash
# =============================================================================
# gametools-update.sh — LACT · Heroic · Faugus Updater
# =============================================================================
# Kompatibel mit Ubuntu 24.04/26.04 und Debian-basierten Systemen
# Prüft installierte Version gegen GitHub latest — fragt vor jedem Update
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${GREEN}[✓]${NC} $*"; }
info()    { echo -e "${CYAN}[→]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
err()     { echo -e "${RED}[✗]${NC} $*"; }
updated() { echo -e "${GREEN}[↑]${NC} $*"; }
skipped() { echo -e "${YELLOW}[–]${NC} $*"; }

[[ $EUID -ne 0 ]] && err "Bitte als root ausführen: sudo bash gametools-update.sh" && exit 1

clear
echo -e "${BOLD}${CYAN}"
echo "  ██████╗  █████╗ ███╗   ███╗███████╗"
echo "  ██╔════╝ ██╔══██╗████╗ ████║██╔════╝"
echo "  ██║  ███╗███████║██╔████╔██║█████╗  "
echo "  ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  "
echo "  ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗"
echo "   ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝"
echo -e "${NC}"
echo -e "  ${BOLD}Gaming Tools Updater${NC}"
echo -e "  LACT · Heroic · Faugus"
echo ""

# ── Hilfsfunktion: GitHub latest tag holen ────────────────────────────────────
gh_latest() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
        | grep '"tag_name"' \
        | sed 's/.*"\([^"]*\)".*/\1/'
}

# ── Hilfsfunktion: installierte dpkg-Version holen ───────────────────────────
dpkg_version() {
    dpkg -s "$1" 2>/dev/null | grep '^Version:' | awk '{print $2}' || echo "nicht installiert"
}

# ── Hilfsfunktion: Update-Frage ───────────────────────────────────────────────
ask_update() {
    local name="$1"
    local installed="$2"
    local latest="$3"
    echo ""
    echo -e "  ${BOLD}$name${NC}"
    echo -e "  Installiert : ${YELLOW}$installed${NC}"
    echo -e "  Verfügbar   : ${GREEN}$latest${NC}"
    echo -ne "  Updaten? [y/N] "
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# ── Hilfsfunktion: kein Update nötig ─────────────────────────────────────────
up_to_date() {
    echo ""
    echo -e "  ${BOLD}$1${NC}"
    echo -e "  $(skipped "Aktuell ($2) — kein Update nötig")"
}

# =============================================================================
# LACT
# =============================================================================
info "Prüfe LACT..."

LACT_INSTALLED=$(dpkg_version "lact")
LACT_LATEST_TAG=$(gh_latest "ilya-zlobintsev/LACT")
LACT_LATEST="${LACT_LATEST_TAG#v}"

if grep -qi "ubuntu" /etc/os-release; then
    LACT_SUFFIX="ubuntu-2404"
else
    LACT_SUFFIX="debian-13"
fi

LACT_URL="https://github.com/ilya-zlobintsev/LACT/releases/download/${LACT_LATEST_TAG}/lact-${LACT_LATEST}-0.amd64.${LACT_SUFFIX}.deb"

if [[ "$LACT_INSTALLED" == *"$LACT_LATEST"* ]]; then
    up_to_date "LACT" "$LACT_INSTALLED"
else
    if ask_update "LACT" "$LACT_INSTALLED" "$LACT_LATEST"; then
        info "Lade LACT ${LACT_LATEST}..."
        wget -q --show-progress -O /tmp/lact.deb "$LACT_URL"
        apt install -y /tmp/lact.deb
        rm /tmp/lact.deb
        systemctl enable --now lactd 2>/dev/null || true
        updated "LACT auf ${LACT_LATEST} aktualisiert"
    else
        skipped "LACT übersprungen"
    fi
fi

# =============================================================================
# Heroic Games Launcher
# =============================================================================
info "Prüfe Heroic Games Launcher..."

HEROIC_INSTALLED=$(dpkg_version "heroic")
HEROIC_LATEST_TAG=$(gh_latest "Heroic-Games-Launcher/HeroicGamesLauncher")
HEROIC_LATEST="${HEROIC_LATEST_TAG#v}"
HEROIC_URL="https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/${HEROIC_LATEST_TAG}/Heroic-${HEROIC_LATEST}-linux-amd64.deb"

if [[ "$HEROIC_INSTALLED" == *"$HEROIC_LATEST"* ]]; then
    up_to_date "Heroic Games Launcher" "$HEROIC_INSTALLED"
else
    if ask_update "Heroic Games Launcher" "$HEROIC_INSTALLED" "$HEROIC_LATEST"; then
        info "Lade Heroic ${HEROIC_LATEST}..."
        wget -q --show-progress -O /tmp/heroic.deb "$HEROIC_URL"
        apt install -y /tmp/heroic.deb
        rm /tmp/heroic.deb
        updated "Heroic auf ${HEROIC_LATEST} aktualisiert"
    else
        skipped "Heroic übersprungen"
    fi
fi

# =============================================================================
# Faugus Launcher
# =============================================================================
info "Prüfe Faugus Launcher..."

FAUGUS_INSTALLED=$(dpkg_version "faugus-launcher")
FAUGUS_LATEST_TAG=$(gh_latest "Faugus/faugus-launcher")
FAUGUS_LATEST="${FAUGUS_LATEST_TAG#v}"
FAUGUS_URL="https://github.com/Faugus/faugus-launcher/releases/download/${FAUGUS_LATEST_TAG}/faugus-launcher_${FAUGUS_LATEST}-1_all.deb"

if [[ "$FAUGUS_INSTALLED" == *"$FAUGUS_LATEST"* ]]; then
    up_to_date "Faugus Launcher" "$FAUGUS_INSTALLED"
else
    if ask_update "Faugus Launcher" "$FAUGUS_INSTALLED" "$FAUGUS_LATEST"; then
        info "Lade Faugus ${FAUGUS_LATEST}..."
        wget -q --show-progress -O /tmp/faugus.deb "$FAUGUS_URL"
        apt install -y /tmp/faugus.deb
        rm /tmp/faugus.deb
        updated "Faugus auf ${FAUGUS_LATEST} aktualisiert"
    else
        skipped "Faugus übersprungen"
    fi
fi

# =============================================================================
# Abschluss
# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  Update-Check abgeschlossen!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo ""
