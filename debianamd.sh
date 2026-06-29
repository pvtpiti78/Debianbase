#!/bin/bash
# =============================================================================
# debian-setup.sh — Debian Sid Base Setup
# =============================================================================
# Ausgangslage: Minimale Debian Sid TTY-Installation (mini.iso)
# Umfang: APT-Tuning, i386, AMD Mesa/RADV (RX 9070 XT), NTSYNC, Fish,
#         Kitty, Starship, Fastfetch, Firefox, Steam, gaming.conf,
#         XanMod-Edge Kernel (x64v3), GRUB + Secure Boot (MOK-Signing),
#         Dual-Boot-Erkennung (os-prober) für Windows 11
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

[[ $EUID -ne 0 ]] && err "Bitte als root ausführen: sudo bash debian-setup.sh"

CURRENT_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo "~$CURRENT_USER")

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
echo -e "  AMD Mesa/RADV (RX 9070 XT) · Fish · Kitty · Starship · Gaming ENV"
echo ""
echo -e "  ${YELLOW}Dieses Script richtet das System neu ein.${NC}"
echo -e "  ${YELLOW}Drücke ENTER zum Starten oder CTRL+C zum Abbrechen.${NC}"
read -r

# ── APT konfigurieren ─────────────────────────────────────────────────────────
info "APT konfigurieren..."
cat > /etc/apt/apt.conf.d/99custom << 'EOF'
APT::Get::Assume-Yes "true";
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
    speech-dispatcher \
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
    firmware-realtek
log "Basis-Pakete installiert"

info "Writing fastfetch config..."
mkdir -p "$USER_HOME/.config/fastfetch"
cat > "$USER_HOME/.config/fastfetch/config.jsonc" <<'EOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "builtin",
        "source": "debian"
    },
    "display": {
        "separator": "  "
    },
    "modules": [
        "title",
        "separator",
        {
            "type": "os",
            "key": "OS"
        },
        {
            "type": "kernel",
            "key": "Kernel"
        },
        {
            "type": "uptime",
            "key": "Uptime"
        },
        {
            "type": "packages",
            "key": "Packages"
        },
        "separator",
        {
            "type": "shell",
            "key": "Shell"
        },
        {
            "type": "terminal",
            "key": "Terminal"
        },
        {
            "type": "de",
            "key": "DE/WM"
        },
        "separator",
        {
            "type": "display",
            "key": "Resolution"
        },
        "separator",
        {
            "type": "cpu",
            "key": "CPU"
        },
        {
            "type": "gpu",
            "key": "GPU",
            "driverSpecific": true,
            "format": "{name} [{driver}]"
        },
        {
            "type": "memory",
            "key": "RAM"
        },
        {
            "type": "disk",
            "key": "Disk",
            "folders": "/"
        },
        "separator",
        {
            "type": "localip",
            "key": "Local IP"
        }
    ]
}
EOF
chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/fastfetch/config.jsonc"


# ── power-profiles-daemon ─────────────────────────────────────────────────────
info "power-profiles-daemon aktivieren..."
systemctl enable --now power-profiles-daemon
log "power-profiles-daemon aktiv"

# ── AMD GPU Stack (Mesa / RADV / VAAPI) ──────────────────────────────────────
info "AMD GPU Treiber-Stack installieren (Mesa/RADV, mainline im Kernel)..."
apt install -y \
    firmware-amd-graphics \
    mesa-vulkan-drivers \
    vulkan-tools \
    mesa-va-drivers \
    vainfo \
    mesa-utils
log "AMD GPU Stack installiert (RADV ist Default-Vulkan-ICD, kein DKMS nötig)"


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

# ── Systemsprache Deutsch ──────────────────────────────────────────────────────
info "Systemsprache Deutsch setzen..."
apt install -y locales
sed -i 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=de_DE.UTF-8
log "Systemsprache gesetzt"

# ── Firefox ───────────────────────────────────────────────────────────────────
info "Firefox installieren..."
apt install -y firefox firefox-l10n-de

info "Firefox policies.json konfigurieren (kein Telemetry, kein Pocket)..."
FIREFOX_POLICIES_DIR="/usr/lib/firefox/distribution"
mkdir -p "$FIREFOX_POLICIES_DIR"
cat > "$FIREFOX_POLICIES_DIR/policies.json" << 'EOF'
{
  "policies": {
    "DisableTelemetry": true,
    "DisablePocket": true,
    "DisableFirefoxStudies": true,
    "DisableFormHistory": false,
    "Preferences": {
      "media.ffmpeg.vaapi.enabled":                  { "Value": true, "Status": "default" },
      "media.rdd-ffmpeg.enabled":                    { "Value": true, "Status": "default" },
      "media.hardware-video-decoding.force-enabled": { "Value": true, "Status": "default" },
      "widget.dmabuf.force-enabled":                 { "Value": true, "Status": "default" },
      "media.av1.enabled":                           { "Value": true, "Status": "default" },
      "gfx.webrender.all":                           { "Value": true, "Status": "default" }
    }
  }
}
EOF
log "Firefox installiert und konfiguriert"

# ── Gaming — Steam via protontricks ──────────────────────────────────────────
info "protontricks installieren (zieht Steam als Abhängigkeit)..."
apt install -y protontricks
log "protontricks + Steam installiert"


# ── Flatpak + ProtonPlus ──────────────────────────────────────────────────────
info "Flatpak installieren..."
apt install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
log "Flatpak installiert"

info "ProtonPlus installieren (Flatpak)..."
flatpak install -y flathub com.vysp3r.ProtonPlus
log "ProtonPlus installiert"

# ── LACT — aktuelle Version von GitHub ───────────────────────────────────────
info "LACT installieren (latest release)..."
LACT_LATEST=$(curl -fsSL "https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest" \
    | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
LACT_URL="https://github.com/ilya-zlobintsev/LACT/releases/download/v${LACT_LATEST}/lact-${LACT_LATEST}-0.amd64.debian-13.deb"
wget -O /tmp/lact.deb "$LACT_URL"
apt install -y /tmp/lact.deb
rm /tmp/lact.deb
systemctl enable --now lactd
log "LACT ${LACT_LATEST} installiert"

# ── Faugus Launcher — aktuelle Version von GitHub ─────────────────────────────
info "Faugus Launcher installieren (latest release)..."
FAUGUS_URL=$(curl -fsSL "https://api.github.com/repos/Faugus/faugus-launcher/releases/latest" \
    | grep '"browser_download_url"' | grep '_all\.deb' | sed 's/.*"\(https[^"]*\)".*/\1/' || true)
if [[ -z "$FAUGUS_URL" ]]; then
    warn "Faugus: Kein .deb Asset gefunden — übersprungen"
else
    wget -O /tmp/faugus.deb "$FAUGUS_URL"
    apt install -y /tmp/faugus.deb
    rm /tmp/faugus.deb
    log "Faugus Launcher installiert"
fi

# ── Heroic Games Launcher — aktuelle Version von GitHub ───────────────────────
info "Heroic Games Launcher installieren (latest release)..."
HEROIC_LATEST=$(curl -fsSL "https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest" \
    | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
HEROIC_URL="https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v${HEROIC_LATEST}/Heroic-${HEROIC_LATEST}-linux-amd64.deb"
wget -O /tmp/heroic.deb "$HEROIC_URL"
apt install -y /tmp/heroic.deb
rm /tmp/heroic.deb
log "Heroic Games Launcher ${HEROIC_LATEST} installiert"


# ── gaming.conf (Environment Variables) ──────────────────────────────────────
info "gaming.conf erstellen..."
mkdir -p /etc/environment.d
cat > /etc/environment.d/gaming.conf << 'EOF'
### Proton / Wayland
PROTON_ENABLE_WAYLAND=1
PROTON_USE_NTSYNC=1
PROTON_USE_OPTISCALER=1
PROTON_XESS_UPGRADE=1
### NTSYNC — kein esync/fsync
WINEFSYNC=0
WINEESYNC=0
### Optiscaler FSR4 Override Prep & Upgrade
PROTON_FSR4_UPGRADE=1
### Mesa Shader Cache
MESA_SHADER_CACHE_MAX_SIZE=12G
### Frame Rate Cap — 237 FPS (VRR-Dropout-Schutz bei 240Hz)
DXVK_FRAME_RATE=237
VKD3D_FRAME_RATE=237
### HDR (Für Wayland Compositor)
DXVK_HDR=1
PROTON_ENABLE_HDR=1
ENABLE_HDR_WSI=1
EOF
log "gaming.conf erstellt (Nvidia-Altlasten entfernt, 1:1 Parität zu Arch)"

# ── amdgpu.conf ENV ───────────────────────────────────────────────────────────
info "amdgpu.conf ENV erstellen..."
cat > /etc/environment.d/amdgpu.conf << 'EOF'
LIBVA_DRIVER_NAME=radeonsi
EOF
log "amdgpu.conf ENV erstellt"

# ── ZRAM ──────────────────────────────────────────────────────────────────────
info "ZRAM konfigurieren..."
apt install -y zram-tools

cat > /etc/default/zramswap << 'EOF'
# ZRAM — 15% von 48GB RAM (~7GB)
ALGO=zstd
PERCENT=15
EOF

systemctl enable zramswap
log "ZRAM konfiguriert"

# ── XanMod-Edge Kernel (x64v3) ────────────────────────────────────────────────
info "XanMod-Repository einrichten..."
curl -fsSL https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' \
    > /etc/apt/sources.list.d/xanmod-release.list
apt update
log "XanMod-Repository eingerichtet"

info "XanMod-Edge Kernel (x64v3) installieren..."
apt install -y linux-xanmod-edge-x64v3
log "XanMod-Edge Kernel installiert (Stock-Debian-Kernel bleibt als Fallback-Bootoption erhalten)"

# ── GRUB & Secure Boot (MOK-Signing für XanMod) ───────────────────────────────
info "GRUB und Secure-Boot-Kette installieren..."

# Lokale machine-id erzwingen, falls noch nicht existent
systemd-machine-id-setup

# shim-signed bringt eine von Microsoft signierte Bootkette mit, grub-efi-amd64-signed
# ist der dazu passende, ebenfalls signierte GRUB. Damit bootet GRUB selbst unter
# aktivem Secure Boot ohne weiteren Aufwand.
apt install -y grub-efi-amd64 grub-efi-amd64-signed shim-signed os-prober mokutil sbsigntool

# os-prober aktivieren, damit GRUB den Windows-11-Bootmanager (bootmgfw.efi) findet
sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grep -q '^GRUB_DISABLE_OS_PROBER=' /etc/default/grub || echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub

# Kernel-Kommandozeile (analog zur bisherigen systemd-boot cmdline)
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="zswap.enabled=0 quiet loglevel=3"/' /etc/default/grub
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub

# GRUB in die EFI-Partition installieren (Bootloader-ID "Debian", neben Windows)
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Debian

# os-prober braucht lesenden Zugriff auf die Windows-ESP/NTFS-Partitionen — bei
# einem klassischen Dual-Boot-Setup (separate Platte/Partition für Win11) ist das
# i.d.R. automatisch der Fall, sobald os-prober installiert ist.
update-grub
log "GRUB installiert, Windows-11-Eintrag wird (falls erkannt) automatisch gelistet"

# ── Secure Boot: MOK-Key erzeugen & XanMod-Kernel signieren ──────────────────
info "MOK-Schlüsselpaar für unsigned XanMod-Kernel erzeugen..."
MOK_DIR="/root/secureboot"
mkdir -p "$MOK_DIR"
if [[ ! -f "$MOK_DIR/MOK.priv" ]]; then
    openssl req -new -x509 -newkey rsa:2048 -keyout "$MOK_DIR/MOK.priv" \
        -outform DER -out "$MOK_DIR/MOK.der" -nodes -days 36500 \
        -subj "/CN=XanMod Secure Boot MOK/"
    chmod 600 "$MOK_DIR/MOK.priv"
    log "MOK-Schlüsselpaar erzeugt unter $MOK_DIR"
else
    warn "MOK-Schlüsselpaar existiert bereits — wird wiederverwendet"
fi

info "Aktuellen XanMod-Kernel signieren..."
for kernel in /boot/vmlinuz-*xanmod*; do
    [[ -f "$kernel" ]] || continue
    sbsign --key "$MOK_DIR/MOK.priv" --cert "$MOK_DIR/MOK.der" --output "$kernel" "$kernel" \
        || warn "Signieren von $kernel fehlgeschlagen"
done
log "XanMod-Kernel signiert"

info "Hook für automatisches Signieren bei künftigen Kernel-Updates anlegen..."
cat > /etc/kernel/postinst.d/zz-sbsign-xanmod << 'HOOKEOF'
#!/bin/bash
# Signiert frisch installierte XanMod-Kernel automatisch mit dem lokalen MOK-Key,
# damit sie unter aktivem Secure Boot weiterhin booten.
set -e
MOK_DIR="/root/secureboot"
KERNEL_VERSION="$1"
KERNEL_IMAGE="/boot/vmlinuz-${KERNEL_VERSION}"
[[ "$KERNEL_VERSION" == *xanmod* ]] || exit 0
[[ -f "$MOK_DIR/MOK.priv" ]] || exit 0
[[ -f "$KERNEL_IMAGE" ]] || exit 0
command -v sbsign >/dev/null 2>&1 || exit 0
sbsign --key "$MOK_DIR/MOK.priv" --cert "$MOK_DIR/MOK.der" --output "$KERNEL_IMAGE" "$KERNEL_IMAGE"
HOOKEOF
chmod +x /etc/kernel/postinst.d/zz-sbsign-xanmod
log "Postinst-Hook angelegt — künftige XanMod-Updates werden automatisch signiert"

info "MOK-Key zum Enrollment im UEFI vormerken..."
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  WICHTIG — Secure Boot ist AN, MOK-Enrollment erforderlich!${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo "  Jetzt: mokutil --import $MOK_DIR/MOK.der ausführen und ein"
echo "  Passwort vergeben. Beim NÄCHSTEN Neustart erscheint der blaue"
echo "  'MokManager' Bildschirm — dort 'Enroll MOK' wählen und das"
echo "  eben vergebene Passwort eingeben. Ohne diesen Schritt bootet"
echo "  der XanMod-Kernel unter Secure Boot NICHT."
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""
mokutil --import "$MOK_DIR/MOK.der"

# ── sysctl — vm.max_map_count (Steam/Wine) ───────────────────────────────────
info "sysctl vm.max_map_count setzen..."
cat > /etc/sysctl.d/99-gaming.conf << 'EOF'
vm.max_map_count=2147483642
vm.swappiness=10
kernel.split_lock_mitigate=0
EOF
sysctl --system > /dev/null
log "sysctl konfiguriert"

# ── Tastatur auf Deutsch ──────────────────────────────────────────────────────
info "Tastaturlayout auf Deutsch setzen..."
cat > /etc/default/keyboard << 'EOF'
XKBMODEL="pc105"
XKBLAYOUT="de"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF
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

# ── NetworkManager ───────────────────────────────────────────────────────────
info "NetworkManager einrichten..."
apt install -y network-manager

INTERFACES_FILE="/etc/network/interfaces"
if [ -f "$INTERFACES_FILE" ]; then
    sed -i '/enp7s0/s/^/#/' "$INTERFACES_FILE"
    log "enp7s0 in $INTERFACES_FILE auskommentiert"
else
    warn "$INTERFACES_FILE nicht gefunden — übersprungen"
fi

systemctl enable NetworkManager
log "NetworkManager aktiviert (übernimmt nach Reboot)"

# ── Aufräumen ─────────────────────────────────────────────────────────────────
info "Aufräumen..."
apt modernize-sources -y
apt update
apt full-upgrade -y
apt autoremove -y
apt clean
log "Aufgeräumt"

# ── Abschluss ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  Base-Setup abgeschlossen!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${RED}${BOLD}WICHTIG vor dem Reboot:${NC}"
echo -e "  ${BOLD}mokutil --import /root/secureboot/MOK.der${NC} (falls noch nicht gelaufen),"
echo -e "  dann beim Neustart im blauen MokManager 'Enroll MOK' bestätigen —"
echo -e "  sonst bootet der XanMod-Kernel unter Secure Boot nicht."
echo ""
echo -e "  ${CYAN}Nächste Schritte:${NC}"
echo -e "  1.  ${BOLD}sudo reboot${NC}  (MOK-Enrollment + GRUB-Menü prüfen, Windows 11 sollte gelistet sein)"
echo -e "  2.  ${BOLD}uname -r${NC}  (sollte ...xanmod... zeigen)"
echo -e "  3.  ${BOLD}cd Debianbase && sudo bash gnome-setup.sh${NC}"
echo ""
echo -e "  ${CYAN}Nach dem Reboot prüfen:${NC}"
echo -e "  • GPU:      ${BOLD}vulkaninfo --summary${NC} / ${BOLD}vainfo${NC}"
echo -e "  • NTSYNC:   ${BOLD}ls /dev/ntsync${NC}"
echo -e "  • Kernel:   ${BOLD}uname -r${NC}"
echo -e "  • SecureBoot: ${BOLD}mokutil --sb-state${NC}"
echo ""
