#!/usr/bin/env bash
# ============================================================================
#  Debian Sid Post-Install — mini.iso Netinstall (kein DE, GRUB)
#  Usecase: Gaming + Browsing
#  Hardware: Ryzen 7 9800X3D | RX 9070 XT | MSI X870E Tomahawk Max WiFi
#
#  Voraussetzung: Basissystem via mini.iso, Secure Boot AUS (kein MOK noetig)
#  Start: als normaler User im tty (sudo-Rechte vorausgesetzt)
#  Aufruf: bash debiansid-gaming.sh
# ============================================================================
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# ---------- Logging ----------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[OK]${NC}   $*"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }

APT="sudo apt-get -y"

# ---------- Vorab-Checks ----------
[[ $EUID -eq 0 ]] && die "Nicht als root starten — als User mit sudo."
command -v sudo >/dev/null || die "sudo fehlt (apt install sudo als root, User in Gruppe sudo)."
ping -c1 -W3 deb.debian.org >/dev/null 2>&1 || die "Keine Internetverbindung."
source /etc/os-release
[[ "${VERSION_CODENAME:-}${DEBIAN_VERSION:-}" == *sid* || "$(apt-cache policy 2>/dev/null | grep -c 'unstable')" -gt 0 || -e /etc/debian_version && "$(cat /etc/debian_version)" == *sid* ]] \
  || warn "Sid nicht eindeutig erkannt — Script schreibt die Sources gleich sowieso auf sid um."
info "Debian erkannt ($(cat /etc/debian_version)). Los geht's."

# ============================================================================
# 1. APT-Sources (deb822) + Multiarch + apt-Tuning
# ============================================================================
info "Schreibe sid-Sources (deb822, alle Komponenten)..."
sudo rm -f /etc/apt/sources.list
sudo tee /etc/apt/sources.list.d/debian.sources >/dev/null <<'EOF'
Types: deb
URIs: https://deb.debian.org/debian
Suites: sid
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

# 32-bit fuer Steam/Proton — MUSS vor dem ersten apt update rein
sudo dpkg --add-architecture i386

# Kein Recommends-Wildwuchs (Aequivalent zu install_weak_deps=False)
sudo tee /etc/apt/apt.conf.d/99-no-recommends >/dev/null <<'EOF'
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF
log "Sources + i386 + apt.conf gesetzt."

# Locales — analog zum Fedora-Fix: ohne en_US/de_DE bricht die Steam Runtime
# beim ersten Proton-Start mit "character map file 'UTF-8' not found" ab.
info "Installiere Locales (en_US, de_DE)..."
$APT install locales || warn "locales-Paket uebersprungen."
sudo sed -i -e 's/^# *\(en_US\.UTF-8 UTF-8\)/\1/' -e 's/^# *\(de_DE\.UTF-8 UTF-8\)/\1/' /etc/locale.gen 2>/dev/null || true
sudo locale-gen || warn "locale-gen fehlgeschlagen — Locales manuell pruefen."

# ============================================================================
# 2. System-Update
# ============================================================================
info "Vollstaendiges System-Update (full-upgrade auf sid)..."
$APT update
$APT full-upgrade
log "System aktuell."

# ============================================================================
# 3. Firmware + Microcode (mini.iso installiert das nicht immer vollstaendig)
# ============================================================================
info "Installiere Firmware + AMD-Microcode..."
$APT install \
  firmware-linux \
  firmware-amd-graphics \
  firmware-realtek \
  amd64-microcode || warn "Einzelne Firmware-Pakete fehlgeschlagen."
# RTL8126 5GbE laeuft ueber r8169 mainline. MT7927-WiFi: weiterhin kein
# Mainline-Support — bleibt deaktiviert, kein Paket noetig.
log "Firmware bereit."

# ============================================================================
# 4. GRUB/os-prober (Kernel: Stock Sid — kein Custom-Kernel)
# ============================================================================
info "Konfiguriere GRUB (os-prober fuer Windows-Dual-Boot)..."
$APT install wget gpg curl
# GRUB: Windows 11 auf zweiter Platte finden (os-prober ist default aus)
$APT install os-prober
if ! grep -q '^GRUB_DISABLE_OS_PROBER=false' /etc/default/grub; then
  echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a /etc/default/grub >/dev/null
fi
sudo update-grub
log "GRUB/os-prober eingerichtet — Stock-Sid-Kernel bleibt."

# ============================================================================
# 5. Minimal KDE Plasma (Wayland) + SDDM
# ============================================================================
# Hinweis: Plasma Login Manager ist in Debian (Stand 07/2026) NICHT paketiert
# — es bleibt bei SDDM. Sobald plasma-login-manager in sid landet:
# apt install plasma-login-manager && systemctl disable sddm && enable plasmalogin
info "Installiere minimales KDE Plasma (Wayland)..."
$APT install \
  plasma-desktop \
  plasma-workspace \
  kwin-wayland \
  plasma-nm \
  plasma-pa \
  systemsettings \
  plasma-systemmonitor \
  ksystemstats \
  powerdevil \
  power-profiles-daemon \
  upower \
  udisks2 \
  kscreen \
  libpam-kwallet5 \
  bluedevil \
  bluez \
  sddm \
  sddm-theme-breeze \
  konsole \
  dolphin \
  kate \
  kio-extras \
  ark \
  kde-spectacle \
  kcalc \
  kde-cli-tools \
  xdg-desktop-portal-kde \
  xdg-desktop-portal-gtk \
  polkit-kde-agent-1 \
  network-manager \
  pipewire \
  pipewire-audio \
  pipewire-pulse \
  pipewire-alsa \
  wireplumber \
  fonts-noto-core \
  fonts-noto-mono \
  fonts-hack

sudo systemctl enable sddm.service
sudo systemctl enable power-profiles-daemon.service || warn "power-profiles-daemon nicht aktivierbar."
sudo systemctl enable upower.service || warn "upower nicht aktivierbar."
sudo systemctl set-default graphical.target
log "Plasma minimal + SDDM installiert, graphical.target gesetzt."

# ============================================================================
# 5b. Archiv-Backends + CLI-Basics
# ============================================================================
info "Installiere Archiv-Tools + CLI-Basics..."
$APT install \
  unzip zip \
  p7zip-full \
  tar bzip2 xz-utils zstd \
  curl wget \
  btop || warn "Einzelne Utility-Pakete fehlgeschlagen."
# unrar (proprietaer) aus non-free:
$APT install unrar || warn "unrar uebersprungen — non-free-Komponente pruefen."
log "Archiv-Backends bereit."

# ============================================================================
# 6. Multimedia: ffmpeg + GStreamer + VA-API
# ============================================================================
# Debian-Vorteil: Mesa ist MIT allen Codecs gebaut (kein Freeworld-Swap),
# ffmpeg in main ist das volle Paket. Der komplette Fedora-Block entfaellt.
info "Installiere Multimedia-Stack..."
$APT install \
  ffmpeg \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-libav \
  gstreamer1.0-vaapi \
  mesa-va-drivers \
  mesa-va-drivers:i386 \
  mesa-vdpau-drivers \
  libva-utils || warn "Einzelne Multimedia-Pakete fehlgeschlagen."
log "Codecs + Hardware-Decode (H.264/H.265 out-of-the-box) eingerichtet."

# ============================================================================
# 7. AMD Gaming-Grundlage (Vulkan 64+32 bit)
# ============================================================================
info "Installiere Vulkan-Stack..."
$APT install \
  mesa-vulkan-drivers \
  mesa-vulkan-drivers:i386 \
  libvulkan1 \
  libvulkan1:i386 \
  vulkan-tools
log "RADV 64/32-bit bereit. (RX 9070 XT laeuft in sid out-of-the-box ueber Mesa.)"

# ============================================================================
# 8. Flatpak + Flathub
# ============================================================================
info "Richte Flatpak/Flathub ein..."
$APT install flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
log "Flathub aktiv."

# ============================================================================
# 9. Gaming-Software: Steam, Protontricks, ProtonPlus
# ============================================================================
info "Installiere Steam + Gaming-Tools..."
$APT install \
  steam-installer \
  steam-devices \
  protontricks || warn "Einzelne Gaming-Pakete fehlgeschlagen."

# gamescope optional — bei Bedarf einkommentieren:
# $APT install gamescope

info "Installiere ProtonPlus (Flathub, offizieller Weg)..."
sudo flatpak install -y flathub com.vysp3r.ProtonPlus || warn "ProtonPlus-Flatpak fehlgeschlagen."
log "Steam, Protontricks, ProtonPlus installiert."

# ============================================================================
# 9b. Heroic + Faugus Launcher (kein Debian-Repo -> .deb von GitHub)
# ============================================================================
gh_latest_deb() {  # $1=repo  $2=asset-regex  -> URL oder leer
  curl -s "https://api.github.com/repos/$1/releases/latest" \
    | grep -oP '"browser_download_url":\s*"\K[^"]*' | grep -P "$2" | head -n1
}

info "Installiere Heroic Games Launcher (GitHub .deb)..."
HEROIC_URL=$(gh_latest_deb "Heroic-Games-Launcher/HeroicGamesLauncher" 'amd64\.deb$')
if [[ -n "${HEROIC_URL:-}" ]]; then
  wget -qO /tmp/heroic.deb "$HEROIC_URL" && $APT install /tmp/heroic.deb \
    && log "Heroic installiert." || warn "Heroic-Installation fehlgeschlagen."
else
  warn "Heroic-.deb nicht gefunden — manuell nachinstallieren."
fi

info "Installiere GLES-Support (Faugus/GTK-Abhaengigkeit)..."
# Analog zum Fedora-Fix: ohne libGLESv2.so.2 crasht Faugus beim GUI-Start
# mit "Couldn't open libGLESv2.so.2" -> SIGABRT. Debian-Paketname: libgles2.
$APT install libgles2 libgles2:i386 || warn "libgles2 uebersprungen."

info "Installiere umu-launcher + Faugus Launcher..."
# umu-launcher zuerst aus sid versuchen, sonst GitHub-Fallback
if ! $APT install umu-launcher 2>/dev/null; then
  warn "umu-launcher nicht in sid — versuche GitHub-.deb..."
  UMU_URL=$(gh_latest_deb "Open-Wine-Components/umu-launcher" '_all.*\.deb$|amd64.*\.deb$')
  [[ -n "${UMU_URL:-}" ]] && wget -qO /tmp/umu.deb "$UMU_URL" && $APT install /tmp/umu.deb \
    || warn "umu-launcher manuell nachinstallieren."
fi
FAUGUS_URL=$(gh_latest_deb "Faugus/faugus-launcher" '_all\.deb$')
if [[ -n "${FAUGUS_URL:-}" ]]; then
  wget -qO /tmp/faugus.deb "$FAUGUS_URL" && $APT install /tmp/faugus.deb \
    && log "Faugus installiert." || warn "Faugus-Installation fehlgeschlagen."
else
  warn "Faugus-.deb nicht gefunden — Fallback: flatpak install flathub io.github.Faugus.faugus-launcher"
fi
# Runner-Pfad: ~/.local/share/Steam/compatibilitytools.d/ (Proton-GE via
# ProtonPlus wird von Faugus direkt gefunden).
log "Launcher-Sektion abgeschlossen."

# ============================================================================
# 10. Google Chrome (das .deb registriert Googles apt-Repo selbst)
# ============================================================================
info "Installiere Google Chrome..."
wget -qO /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
$APT install /tmp/chrome.deb && log "Chrome installiert (Updates via apt)." \
  || warn "Chrome fehlgeschlagen."

# ============================================================================
# 11. LACT (GPU-Kontrolle: Undervolt/Powerlimit fuer die 9070 XT)
# ============================================================================
# Nicht in den Debian-Repos — offizieller Weg ist das .deb vom Release.
# Wir nehmen dynamisch das neueste debian-XX-Build (laeuft auf sid).
info "Installiere LACT (latest release)..."
# Achtung sid: Das debian-13-.deb ist gegen Trixie gebaut. Wenn sid gerade
# eine Library-Transition durch hat (z.B. libdisplay-info2 weg), schlaegt
# die Installation fehl -> dann Fallback auf den offiziellen Flatpak.
LACT_OK=0
LACT_LATEST=$(curl -fsSL "https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest" \
    | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
if [[ -n "${LACT_LATEST:-}" ]]; then
  LACT_URL="https://github.com/ilya-zlobintsev/LACT/releases/download/v${LACT_LATEST}/lact-${LACT_LATEST}-0.amd64.debian-13.deb"
  if wget -qO /tmp/lact.deb "$LACT_URL" && $APT install /tmp/lact.deb; then
    sudo systemctl enable --now lactd || warn "lactd nach Reboot pruefen."
    LACT_OK=1
    log "LACT ${LACT_LATEST} (nativ) installiert."
  fi
fi
if [[ $LACT_OK -eq 0 ]]; then
  warn "Natives .deb nicht installierbar (sid-Transition?) — Fallback: Flatpak."
  sudo flatpak install -y flathub io.github.ilya_zlobintsev.LACT \
    && log "LACT (Flatpak) installiert. Beim ersten GUI-Start den Daemon-Setup-Prompt bestaetigen (legt lactd als Systemdienst an)." \
    || warn "LACT komplett fehlgeschlagen — manuell nachziehen."
fi
# Dein Setting zur Erinnerung: -70 mV / -25% Powerlimit

# ============================================================================
# 12. Firewall (ufw — Debian-Analogon zu firewalld)
# ============================================================================
info "Richte ufw ein..."
$APT install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
# Steam Local Network Game Transfer — bei Bedarf einkommentieren:
# sudo ufw allow 27036/udp
# sudo ufw allow 27040/tcp
sudo ufw --force enable || warn "ufw nicht aktivierbar — nach Reboot pruefen."
log "ufw aktiv (deny incoming, allow outgoing)."

# ============================================================================
# 13. System-Tuning
# ============================================================================
info "Schreibe Tuning-Configs..."

# split_lock: bestaetigter Gaming-Gewinn (dein primaerer Tuning-Hebel)
sudo tee /etc/sysctl.d/99-gaming.conf >/dev/null <<'EOF'
kernel.split_lock_mitigate=0
vm.max_map_count=2147483642
EOF

# ZRAM: 15% RAM, zstd (dein Standard)
$APT install systemd-zram-generator
sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = ram * 0.15
compression-algorithm = zstd
EOF

# Gaming-Env (dein settled Setup)
sudo tee /etc/profile.d/gaming.sh >/dev/null <<'EOF'
export MESA_SHADER_CACHE_MAX_SIZE=12G
export PROTON_ENABLE_HDR=1
export PROTON_USE_OPTISCALER=1
export PROTON_FSR4_UPGRADE=1
export PROTON_XESS_UPGRADE=1
export PROTON_ENABLE_WAYLAND=1
EOF

sudo systemctl enable fstrim.timer || warn "fstrim.timer nicht aktivierbar."
log "sysctl, ZRAM, Env-Variablen, fstrim gesetzt."

# ============================================================================
# 14. Fish Shell + Abbreviations (apt + Flatpak)
# ============================================================================
info "Installiere Fish Shell..."
$APT install fish
sudo chsh -s /usr/bin/fish "$USER" || warn "Default-Shell nicht gesetzt — manuell: chsh -s /usr/bin/fish"

mkdir -p "$HOME/.config/fish"
tee "$HOME/.config/fish/config.fish" >/dev/null <<'EOF'
# ---------------------------------------------------------------
# Fish-Konfiguration — Debian Sid Gaming
# Abbreviations statt Aliase: expandieren sichtbar in der Zeile,
# bleiben editierbar und landen sauber in der History.
# ---------------------------------------------------------------
if status is-interactive
    set -g fish_greeting  # Begruessung aus

    # --- Update: apt + Flatpak in einem Rutsch ---
    abbr -a up   'sudo apt update; and sudo apt full-upgrade; and flatpak update -y'

    # --- apt-Basics ---
    abbr -a in   'sudo apt install'
    abbr -a rem  'sudo apt remove'
    abbr -a se   'apt search'
    abbr -a inf  'apt show'
    abbr -a li   'apt list --installed'
    abbr -a hist 'cat /var/log/apt/history.log'
    abbr -a wp   'apt-file search'          # welches Paket liefert Datei X (apt-file noetig)

    # --- Aufraeumen: apt + Flatpak ---
    abbr -a clean 'sudo apt autoremove --purge -y; and sudo apt clean; and flatpak uninstall --unused -y'

    # --- Flatpak ---
    abbr -a fin  'flatpak install flathub'
    abbr -a fse  'flatpak search'
    abbr -a frem 'flatpak uninstall'
    abbr -a fli  'flatpak list --app'
end
EOF
log "Fish installiert, als Default-Shell gesetzt, Abbreviations geschrieben."

# ============================================================================
# 15. scx/falcond: bewusst weggelassen
# ============================================================================
# Auf apt-Basis unverhaeltnismaessig komplex (kein sauberes Packaging), und
# dein Fazit steht: High-End-Hardware profitiert vom Scheduler-Stack nicht
# messbar. split_lock_mitigate=0 ist der Hebel, der zaehlt — ist gesetzt.

# ============================================================================
# 16. Aufraeumen + Abschluss
# ============================================================================
$APT autoremove || true
sudo apt-get clean || true
rm -f /tmp/{heroic,umu,faugus,chrome,lact}.deb

echo
log "============================================="
log " Fertig. Naechste Schritte:"
log "   1. reboot  ->  GRUB (Stock-Kernel + Windows-Eintrag) -> SDDM"
log "   2. vainfo  ->  H264/HEVC unter VAEntrypointVLD pruefen"
log "   3. Steam starten, Proton-GE via ProtonPlus ziehen"
log "   4. LACT: -70 mV / PL -25% setzen"
log "   5. Neues Terminal = Fish. 'up' tippen -> expandiert zum Update-Befehl"
log "============================================="
