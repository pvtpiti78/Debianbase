#!/usr/bin/env bash
# =============================================================================
# gametools-update.sh — LACT · Heroic · Faugus Updater
# =============================================================================
# Kompatibel mit Debian Sid / Trixie / Ubuntu-Basis
# Prueft installierte Version gegen GitHub latest — fragt vor jedem Update
# LACT: erkennt automatisch Flatpak- vs. Nativ-Installation
# Fehlertolerant: ein fehlgeschlagenes Update bricht die anderen nicht ab
# Start: als normaler User (sudo wird intern genutzt)
# =============================================================================

set -uo pipefail   # bewusst KEIN -e: ein Fehlschlag soll den Rest nicht killen

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

[[ $EUID -eq 0 ]] && { err "Nicht als root — als User starten, sudo kommt von allein."; exit 1; }

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
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
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

# ── Hilfsfunktion: kein Update noetig ────────────────────────────────────────
up_to_date() {
    echo ""
    echo -e "  ${BOLD}$1${NC}"
    echo -e "  $(skipped "Aktuell ($2) — kein Update nötig")"
}

# ── Hilfsfunktion: .deb laden + installieren (fehlertolerant) ────────────────
install_deb() {  # $1=name  $2=url
    local tmp="/tmp/${1,,}.deb"
    if wget -q --show-progress -O "$tmp" "$2" && sudo apt install -y "$tmp"; then
        rm -f "$tmp"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

# =============================================================================
# LACT (Flatpak- oder Nativ-Installation)
# =============================================================================
info "Prüfe LACT..."

LACT_FLATPAK_ID="io.github.ilya_zlobintsev.LACT"

if flatpak info "$LACT_FLATPAK_ID" &>/dev/null; then
    # ── Flatpak-Installation (aktueller Stand auf Sid wg. libdisplay-info) ──
    echo ""
    echo -e "  ${BOLD}LACT${NC} (Flatpak)"
    if flatpak update -y "$LACT_FLATPAK_ID" 2>/dev/null | grep -q "Nothing to do\|Nichts zu tun"; then
        skipped "Aktuell ($(flatpak info "$LACT_FLATPAK_ID" 2>/dev/null | grep -i version | awk '{print $2}')) — kein Update nötig"
    else
        updated "LACT (Flatpak) aktualisiert bzw. geprüft"
    fi
elif [[ "$(dpkg_version lact)" != "nicht installiert" ]]; then
    # ── Native .deb-Installation ─────────────────────────────────────────────
    LACT_INSTALLED=$(dpkg_version "lact")
    LACT_LATEST_TAG=$(gh_latest "ilya-zlobintsev/LACT")
    LACT_LATEST="${LACT_LATEST_TAG#v}"

    if grep -qi "ubuntu" /etc/os-release; then
        LACT_SUFFIX="ubuntu-2404"
    else
        LACT_SUFFIX="debian-13"
    fi
    LACT_URL="https://github.com/ilya-zlobintsev/LACT/releases/download/${LACT_LATEST_TAG}/lact-${LACT_LATEST}-0.amd64.${LACT_SUFFIX}.deb"

    if [[ -z "$LACT_LATEST" ]]; then
        warn "LACT: GitHub-Version nicht ermittelbar — übersprungen."
    elif [[ "$LACT_INSTALLED" == *"$LACT_LATEST"* ]]; then
        up_to_date "LACT" "$LACT_INSTALLED"
    elif ask_update "LACT" "$LACT_INSTALLED" "$LACT_LATEST"; then
        info "Lade LACT ${LACT_LATEST}..."
        if install_deb "lact" "$LACT_URL"; then
            sudo systemctl enable --now lactd 2>/dev/null || true
            updated "LACT auf ${LACT_LATEST} aktualisiert"
        else
            err "LACT-Update fehlgeschlagen (sid-Transition? -> Flatpak-Wechsel erwägen). Weiter mit den anderen Tools."
        fi
    else
        skipped "LACT übersprungen"
    fi
else
    skipped "LACT nicht installiert — übersprungen."
fi

# =============================================================================
# Heroic Games Launcher
# =============================================================================
info "Prüfe Heroic Games Launcher..."

HEROIC_INSTALLED=$(dpkg_version "heroic")
HEROIC_LATEST_TAG=$(gh_latest "Heroic-Games-Launcher/HeroicGamesLauncher")
HEROIC_LATEST="${HEROIC_LATEST_TAG#v}"
HEROIC_URL="https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/${HEROIC_LATEST_TAG}/Heroic-${HEROIC_LATEST}-linux-amd64.deb"

if [[ -z "$HEROIC_LATEST" ]]; then
    warn "Heroic: GitHub-Version nicht ermittelbar — übersprungen."
elif [[ "$HEROIC_INSTALLED" == *"$HEROIC_LATEST"* ]]; then
    up_to_date "Heroic Games Launcher" "$HEROIC_INSTALLED"
elif ask_update "Heroic Games Launcher" "$HEROIC_INSTALLED" "$HEROIC_LATEST"; then
    info "Lade Heroic ${HEROIC_LATEST}..."
    if install_deb "heroic" "$HEROIC_URL"; then
        updated "Heroic auf ${HEROIC_LATEST} aktualisiert"
    else
        err "Heroic-Update fehlgeschlagen. Weiter mit den anderen Tools."
    fi
else
    skipped "Heroic übersprungen"
fi

# =============================================================================
# Faugus Launcher
# =============================================================================
info "Prüfe Faugus Launcher..."

FAUGUS_INSTALLED=$(dpkg_version "faugus-launcher")
FAUGUS_LATEST_TAG=$(gh_latest "Faugus/faugus-launcher")
FAUGUS_LATEST="${FAUGUS_LATEST_TAG#v}"
FAUGUS_URL="https://github.com/Faugus/faugus-launcher/releases/download/${FAUGUS_LATEST_TAG}/faugus-launcher_${FAUGUS_LATEST}-1_all.deb"

if [[ -z "$FAUGUS_LATEST" ]]; then
    warn "Faugus: GitHub-Version nicht ermittelbar — übersprungen."
elif [[ "$FAUGUS_INSTALLED" == *"$FAUGUS_LATEST"* ]]; then
    up_to_date "Faugus Launcher" "$FAUGUS_INSTALLED"
elif ask_update "Faugus Launcher" "$FAUGUS_INSTALLED" "$FAUGUS_LATEST"; then
    info "Lade Faugus ${FAUGUS_LATEST}..."
    if install_deb "faugus" "$FAUGUS_URL"; then
        updated "Faugus auf ${FAUGUS_LATEST} aktualisiert"
    else
        err "Faugus-Update fehlgeschlagen. Weiter mit den anderen Tools."
    fi
else
    skipped "Faugus übersprungen"
fi

# =============================================================================
# Abschluss
# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  Update-Check abgeschlossen!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo ""
