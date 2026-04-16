#!/bin/bash
# =============================================================================
# debian-setup.sh — Debian Sid Base Setup
# =============================================================================
# Ausgangslage: Minimale Debian Sid TTY-Installation (mini.iso)
# Umfang: APT-Tuning, i386, Xanmod Nvidia 595, NTSYNC, Fish, Kitty, Starship,
#         Fastfetch, Firefox, Steam (via protontricks), gaming.conf, nvidia.conf
# =============================================================================

set -euo pipefail

# ── Farben ────────────────────────────────────────────────────────────────────
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

# ── Root-Check ────────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && err "Bitte als root ausführen: sudo bash debian-setup.sh"

# ── User-Variablen ────────────────────────────────────────────────────────────
CURRENT_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo "~$CURRENT_USER")

# ── Banner ────────────────────────────────────────────────────────────────────
clear
echo -e "${BOLD}${CYAN}"
echo "  ██████╗ ███████╗██████╗ ██╗ █████╗ ███╗   ██╗"
echo "  ██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗  ██║"
echo "  ██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║"
echo "  ██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║"
echo "  ██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║"
echo "  ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e "${NC}"
echo -e "  ${BOLD}Debian Sid — Base Setup${NC}"
echo -e "  nvidia-open (CUDA Repo) · Fish · Kitty · Starship · Gaming ENV"
echo ""
echo -e "  ${YELLOW}Dieses Script richtet das System neu ein.${NC}"
echo -e "  ${YELLOW}Drücke ENTER zum Starten oder CTRL+C zum Abbrechen.${NC}"
read -r

# ── APT konfigurieren ─────────────────────────────────────────────────────────
info "APT konfigurieren..."
cat > /etc/apt/apt.conf.d/99custom << 'EOF'
APT::Get::Assume-Yes "true";
APT::Install-Recommends "false";
APT::Install-Suggests "false";
Acquire::Languages "none";
EOF
log "APT konfiguriert"

# ── i386 Multiarch aktivieren ─────────────────────────────────────────────────
info "i386 Multiarch aktivieren..."
dpkg --add-architecture i386
log "i386 aktiviert"

# ── System aktualisieren ──────────────────────────────────────────────────────
info "System aktualisieren..."
apt update
apt full-upgrade -y
log "System aktuell"

# ── Basis-Pakete ──────────────────────────────────────────────────────────────
info "Basis-Pakete installieren..."
apt install -y \
    git \
    curl \
    wget \
    unzip \
    gpg \
    p7zip-full \
    btop \
    fastfetch \
    bash-completion \
    pciutils \
    usbutils \
    lshw \
    rsync \
    vim \
    nano \
    man-db \
    xdg-utils \
    xdg-user-dirs \
    pipewire \
    pipewire-pulse \
    wireplumber \
    power-profiles-daemon \
    hunspell \
    hunspell-de-de \
    hunspell-en-us \
    lsb-release \
    firmware-linux \
    firmware-linux-nonfree
log "Basis-Pakete installiert"

# ── power-profiles-daemon ─────────────────────────────────────────────────────
info "power-profiles-daemon aktivieren..."
systemctl enable --now power-profiles-daemon
log "power-profiles-daemon aktiv"

# ── Kernel Headers (vor Nvidia zwingend) ──────────────────────────────────────
info "Kernel Headers installieren..."
apt install -y \
    linux-headers-$(uname -r) \
    linux-headers-amd64
log "Kernel Headers installiert"

# ── Nvidia (CUDA Repo) ────────────────────────────────────────────────────────
info "Nvidia CUDA Repo einrichten..."
wget -P /tmp https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64/cuda-keyring_1.1-1_all.deb
dpkg -i /tmp/cuda-keyring_1.1-1_all.deb
rm /tmp/cuda-keyring_1.1-1_all.deb
apt update
log "CUDA Repo aktiviert"

info "Nvidia Open + VAAPI installieren..."
apt install -y \
    nvidia-open \
    nvidia-vaapi-driver
log "Nvidia installiert — Reboot erforderlich"

# ── NTSYNC ────────────────────────────────────────────────────────────────────
info "NTSYNC konfigurieren..."
echo "ntsync" | tee /etc/modules-load.d/ntsync.conf
log "NTSYNC aktiviert"

# ── Fish Shell ────────────────────────────────────────────────────────────────
info "Fish Shell installieren..."
apt install -y fish

chsh -s /usr/bin/fish "$CURRENT_USER"

mkdir -p "$USER_HOME/.config/fish"
cat > "$USER_HOME/.config/fish/config.fish" << 'EOF'
# Fish Config — Debian Sid
if status is-interactive
    # Starship prompt
    starship init fish | source

    # Fastfetch beim Start
    fastfetch

    # Aliase
    alias ls='ls --color=auto'
    alias ll='ls -lah --color=auto'
    alias grep='grep --color=auto'
    alias df='df -h'
    alias free='free -h'
    alias ..='cd ..'
    alias ...='cd ../..'

    # APT-Shortcuts
    alias update='sudo apt update && sudo apt full-upgrade -y'
    alias install='sudo apt install -y'
    alias remove='sudo apt remove -y'
    alias purge='sudo apt purge -y'
    alias search='apt search'

    # Cache leeren
    alias clean='sudo apt autoremove -y && sudo apt clean'

    # Systemd
    alias ss='sudo systemctl status'
    alias sr='sudo systemctl restart'
    alias se='sudo systemctl enable'

    # Git
    alias gs='git status'
    alias ga='git add .'
    alias gc='git commit -m'
    alias gp='git push'
end
EOF

chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/fish"
log "Fish Shell konfiguriert"

# ── Starship Prompt ───────────────────────────────────────────────────────────
info "Starship installieren..."
curl -sS https://starship.rs/install.sh | sh -s -- --yes

mkdir -p "$USER_HOME/.config"
cat > "$USER_HOME/.config/starship.toml" << 'EOF'
format = """
$directory\
$git_branch\
$git_status\
$cmd_duration\
$line_break\
$character"""

[directory]
style = "bold #7aa2f7"
truncation_length = 3
truncate_to_repo = true
format = "[$path]($style) "

[git_branch]
symbol = " "
style = "bold #bb9af7"
format = "[$symbol$branch]($style) "

[git_status]
style = "bold #f7768e"
format = "[$all_status$ahead_behind]($style) "
conflicted = "⚡"
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
untracked = "?"
modified = "!"
staged = "+"
deleted = "✘"

[cmd_duration]
min_time = 3_000
style = "bold #e0af68"
format = "[ $duration]($style) "

[character]
success_symbol = "[❯](bold #9ece6a)"
error_symbol = "[❯](bold #f7768e)"

[package]
disabled = true

[python]
disabled = true

[nodejs]
disabled = true

[rust]
disabled = true
EOF
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/starship.toml"
log "Starship konfiguriert"

# ── Kitty Terminal ────────────────────────────────────────────────────────────
info "Kitty installieren..."
apt install -y kitty

mkdir -p "$USER_HOME/.config/kitty"
cat > "$USER_HOME/.config/kitty/kitty.conf" << 'EOF'
# =============================================================================
# Kitty Terminal Configuration
# Theme: Tokyo Night
# =============================================================================

# Font
font_family      JetBrainsMono Nerd Font
bold_font        JetBrainsMono Nerd Font Bold
italic_font      JetBrainsMono Nerd Font Italic
bold_italic_font JetBrainsMono Nerd Font Bold Italic
font_size        13.0

# Tokyo Night Colors
foreground              #c0caf5
background              #1a1b26
selection_foreground    #1a1b26
selection_background    #c0caf5

cursor                  #c0caf5
cursor_text_color       #1a1b26
url_color               #73daca

color0  #15161e
color8  #414868
color1  #f7768e
color9  #f7768e
color2  #9ece6a
color10 #9ece6a
color3  #e0af68
color11 #e0af68
color4  #7aa2f7
color12 #7aa2f7
color5  #bb9af7
color13 #bb9af7
color6  #7dcfff
color14 #7dcfff
color7  #a9b1d6
color15 #c0caf5

# Window
window_padding_width    12
background_opacity      0.95
hide_window_decorations no
remember_window_size    yes

# Cursor
cursor_shape            block
cursor_blink_interval   0

# Performance
sync_to_monitor         yes
confirm_os_window_close 0

# Tab bar
tab_bar_style           powerline
tab_powerline_style     slanted
EOF

chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/kitty"
log "Kitty konfiguriert"

# ── Fonts ─────────────────────────────────────────────────────────────────────
info "System-Fonts installieren (Noto, Liberation, DejaVu, Emoji)..."
apt install -y \
    fonts-noto \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-liberation \
    fonts-dejavu
log "System-Fonts installiert"

info "JetBrainsMono Nerd Font installieren..."
FONT_DIR="/usr/share/fonts/JetBrainsMonoNF"
mkdir -p "$FONT_DIR"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
TMP_FONT=$(mktemp -d)
curl -fsSL "$FONT_URL" -o "$TMP_FONT/JetBrainsMono.zip"
unzip -q "$TMP_FONT/JetBrainsMono.zip" -d "$FONT_DIR"
rm -rf "$TMP_FONT"
fc-cache -fv > /dev/null
log "JetBrainsMono Nerd Font installiert"

# ── GStreamer + Codecs ────────────────────────────────────────────────────────
info "GStreamer-Stack und Codecs installieren..."
apt install -y \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    ffmpeg
log "GStreamer + Codecs installiert"

# ── Firefox (aus Debian repo, policies wie Fedora) ────────────────────────────
info "Systemsprache Deutsch setzen..."
apt install -y locales
sed -i 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=de_DE.UTF-8
log "Systemsprache gesetzt"

info "Firefox installieren..."
apt install -y firefox firefox-l10n-de

info "Firefox policies.json konfigurieren (kein Telemetry, kein Pocket)..."
FIREFOX_POLICIES_DIR="/usr/lib/firefox/distribution"
mkdir -p "$FIREFOX_POLICIES_DIR"
cat > "$FIREFOX_POLICIES_DIR/policies.json" << 'EOF'
{
  "policies": {
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "DisableFirefoxAccounts": false,
    "DisablePocket": true,
    "DisableFormHistory": false,
    "DontCheckDefaultBrowser": true,
    "NoDefaultBookmarks": true,
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": "",

    "FirefoxHome": {
      "Search": true,
      "TopSites": false,
      "SponsoredTopSites": false,
      "Highlights": false,
      "Pocket": false,
      "SponsoredPocket": false,
      "Snippets": false,
      "Locked": false
    },

    "UserMessaging": {
      "WhatsNew": false,
      "ExtensionRecommendations": false,
      "FeatureRecommendations": false,
      "UrlbarInterventions": false,
      "SkipOnboarding": true,
      "MoreFromMozilla": false,
      "Locked": false
    },

    "Preferences": {
      "media.ffmpeg.vaapi.enabled":                        { "Value": true,  "Status": "default" },
      "media.rdd-ffmpeg.enabled":                          { "Value": true,  "Status": "default" },
      "media.hardware-video-decoding.force-enabled":       { "Value": true,  "Status": "default" },
      "widget.dmabuf.force-enabled":                       { "Value": true,  "Status": "default" },
      "media.av1.enabled":                                 { "Value": true,  "Status": "default" },
      "media.ffvpx.enabled":                               { "Value": false, "Status": "default" },
      "gfx.webrender.all":                                 { "Value": true,  "Status": "default" },
      "widget.use-xdg-desktop-portal.file-picker":         { "Value": 1,     "Status": "default" },
      "widget.wayland.opaque-region.enabled":              { "Value": false, "Status": "default" },
      "apz.gtk.kinetic_scroll.enabled":                    { "Value": false, "Status": "default" },
      "intl.locale.requested":                             { "Value": "de,en-US", "Status": "default" },
      "browser.newtabpage.activity-stream.feeds.telemetry":{ "Value": false, "Status": "locked" },
      "browser.newtabpage.activity-stream.telemetry":      { "Value": false, "Status": "locked" },
      "browser.ping-centre.telemetry":                     { "Value": false, "Status": "locked" },
      "toolkit.telemetry.unified":                         { "Value": false, "Status": "locked" },
      "toolkit.telemetry.enabled":                         { "Value": false, "Status": "locked" },
      "datareporting.healthreport.uploadEnabled":          { "Value": false, "Status": "locked" },
      "datareporting.policy.dataSubmissionEnabled":        { "Value": false, "Status": "locked" },
      "browser.crashReports.unsubmittedCheck.autoSubmit2": { "Value": false, "Status": "locked" },
      "browser.tabs.crashReporting.sendReport":            { "Value": false, "Status": "locked" }
    }
  }
}
EOF
log "Firefox installiert und konfiguriert"

# ── Gaming — Steam via protontricks ──────────────────────────────────────────
info "protontricks installieren (zieht Steam als Abhängigkeit)..."
apt install -y protontricks
log "protontricks + Steam installiert"

# ── ProtonPlus (via Pacstall) ─────────────────────────────────────────────────
info "Pacstall installieren..."
bash -c "$(wget -q https://pacstall.dev/q/install -O -)"
log "Pacstall installiert"

info "ProtonPlus installieren..."
sudo -u "$CURRENT_USER" pacstall -I protonplus
log "ProtonPlus installiert"

# ── Gaming Apps ───────────────────────────────────────────────────────────────
info "LACT installieren..."
wget -O /tmp/lact.deb https://github.com/ilya-zlobintsev/LACT/releases/download/v0.8.4/lact-0.8.4-0.amd64.debian-12.deb
apt install -y /tmp/lact.deb
rm /tmp/lact.deb
systemctl enable --now lactd
log "LACT installiert"

info "Faugus Launcher installieren..."
mkdir -p /tmp/faugus-launcher
wget -P /tmp/faugus-launcher https://github.com/Faugus/faugus-launcher/releases/download/1.18.2/faugus-launcher_1.18.2-1_all.deb
apt install -y /tmp/faugus-launcher/*.deb
rm -rf /tmp/faugus-launcher
log "Faugus Launcher installiert"

info "Heroic Games Launcher installieren..."
wget -O /tmp/heroic.deb https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.20.1/Heroic-2.20.1-linux-amd64.deb
apt install -y /tmp/heroic.deb
rm /tmp/heroic.deb
log "Heroic Games Launcher installiert"

# ── nvidia.conf (modprobe) ────────────────────────────────────────────────────
info "nvidia.conf (modprobe) erstellen..."
cat > /etc/modprobe.d/nvidia.conf << 'EOF'
# Nvidia — Debian Sid
options nvidia NVreg_UsePageAttributeTable=1
options nvidia NVreg_EnablePCIeGen3=1
options nvidia NVreg_RegistryDwords="PerfLevelSrc=0x2222"
EOF
log "nvidia.conf erstellt"

# ── gaming.conf (Environment Variables) ──────────────────────────────────────
info "gaming.conf erstellen..."
mkdir -p /etc/environment.d
cat > /etc/environment.d/gaming.conf << 'EOF'
### OpenGL
__GL_SYNC_TO_VBLANK=0
__GL_MaxFramesAllowed=1
__GL_GSYNC_ALLOWED=1
__GL_VRR_ALLOWED=1
__GL_SHADER_DISK_CACHE_SIZE=12000000000

### Proton / Wayland
PROTON_ENABLE_NGX_UPDATER=1
PROTON_ENABLE_WAYLAND=1
PROTON_ENABLE_NVAPI=1
PROTON_VKD3D_HEAP=1
PROTON_USE_NTSYNC=1

### NTSYNC — kein esync/fsync
WINEFSYNC=0
WINEESYNC=0

### DLSS SR — Preset Latest, 50% Skalierung
DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE=on
DXVK_NVAPI_DRS_NGX_DLSS_SR_MODE=custom
DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE_SCALING_RATIO=50
DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE_RENDER_PRESET_SELECTION=render_preset_latest

### DLSS RR
DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE=on
DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE_RENDER_PRESET_SELECTION=render_preset_latest

### Frame Generation — Dynamic MFG
DXVK_NVAPI_DRS_NGX_DLSS_FG_OVERRIDE=on
DXVK_NVAPI_DRS_NGX_DLSS_FG_OVERRIDE_RENDER_PRESET_SELECTION=render_preset_latest
DXVK_NVAPI_DRS_NGX_DLSSG_MODE=dynamic
DXVK_NVAPI_DRS_NGX_DLSSG_DYNAMIC_TARGET_FRAME_RATE=240
DXVK_NVAPI_DRS_NGX_DLSSG_DYNAMIC_MULTI_FRAME_COUNT_MAX=5

### Frame Rate Cap — 237 FPS (VRR-Dropout-Schutz bei 240Hz)
DXVK_FRAME_RATE=237
VKD3D_FRAME_RATE=237

### HDR
DXVK_HDR=1
PROTON_ENABLE_HDR=1
ENABLE_HDR_WSI=1

### Debug (DLSS + DLSSG Indicator)
DXVK_NVAPI_SET_NGX_DEBUG_OPTIONS="DLSSIndicator=1024,DLSSGIndicator=2"
EOF
log "gaming.conf erstellt"

# ── nvidia.conf ENV (Wayland/Vulkan) ─────────────────────────────────────────
info "nvidia.conf ENV erstellen..."
cat > /etc/environment.d/nvidia.conf << 'EOF'
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
LIBVA_DRIVER_NAME=nvidia
NVD_BACKEND=direct
ELECTRON_OZONE_PLATFORM_HINT=auto

# Hardware-Decoding Firefox
MOZ_DISABLE_RDD_SANDBOX=1
EOF
log "nvidia.conf ENV erstellt"

# ── ZRAM ──────────────────────────────────────────────────────────────────────
info "ZRAM konfigurieren..."
apt install -y zram-tools

cat > /etc/default/zramswap << 'EOF'
# ZRAM — 15% von 48GB RAM (~7GB)
ALGO=zstd
PERCENT=15
EOF

systemctl enable --now zramswap

# zswap deaktivieren (kollidiert mit zram) — systemd-boot cmdline
if [ -f /etc/kernel/cmdline ]; then
    if ! grep -q "zswap.enabled=0" /etc/kernel/cmdline; then
        sed -i 's/$/ zswap.enabled=0/' /etc/kernel/cmdline
    fi
else
    echo "zswap.enabled=0" > /etc/kernel/cmdline
fi
# Bootloader-Eintrag neu generieren
if command -v bootctl &>/dev/null; then
    kernel-install add "$(uname -r)" /boot/vmlinuz-"$(uname -r)" 2>/dev/null || true
fi
log "ZRAM konfiguriert, zswap deaktiviert"

# ── sysctl — vm.max_map_count (Steam/Wine) ───────────────────────────────────
info "sysctl vm.max_map_count setzen..."
cat > /etc/sysctl.d/99-gaming.conf << 'EOF'
vm.max_map_count=2147483642
vm.swappiness=10
EOF
sysctl --system > /dev/null
log "sysctl konfiguriert"

# ── Tastatur auf Deutsch ──────────────────────────────────────────────────────
info "Tastaturlayout auf Deutsch setzen..."
apt install -y console-setup
localectl set-keymap de
localectl set-x11-keymap de
log "Tastaturlayout gesetzt"

# ── Vorlagen (Rechtsklick → Neu erstellen) ────────────────────────────────────
info "Vorlagen-Verzeichnis anlegen..."
TEMPLATES_DIR="$USER_HOME/Vorlagen"
mkdir -p "$TEMPLATES_DIR"
touch "$TEMPLATES_DIR/Leere Textdatei.txt"
touch "$TEMPLATES_DIR/Dokument.md"
touch "$TEMPLATES_DIR/Skript.sh"
cat > "$TEMPLATES_DIR/Webseite.html" << 'EOF'
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Titel</title>
</head>
<body>

</body>
</html>
EOF
chown -R "$CURRENT_USER:$CURRENT_USER" "$TEMPLATES_DIR"
log "Vorlagen angelegt"

# ── Berechtigungen Home-Verzeichnis ──────────────────────────────────────────
info "Berechtigungen Home-Verzeichnis setzen..."
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME"
log "Berechtigungen gesetzt"

# ── Abschluss ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  Base-Setup abgeschlossen!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}Nächste Schritte:${NC}"
echo -e "  • Neustart:                 ${BOLD}sudo reboot${NC}"
echo -e "  • Nvidia prüfen:            ${BOLD}nvidia-smi${NC}"
echo -e "  • NTSYNC prüfen:            ${BOLD}ls /dev/ntsync${NC}"
echo -e "  • Desktop-Umgebung:         ${BOLD}bash gnome-setup.sh${NC} / ${BOLD}bash kde-setup.sh${NC}"
echo ""
echo -e "  ${YELLOW}Reboot vor DE-Installation — Nvidia-Module müssen geladen sein${NC}"
echo ""
