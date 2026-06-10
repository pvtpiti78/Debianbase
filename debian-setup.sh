# ── systemd-boot & Kernel-Automatisierung ─────────────────────────────────────
info "systemd-boot Hooks und Parameter konfigurieren..."

# Lokale machine-id erzwingen, falls noch nicht existent
systemd-machine-id-setup

# Benötigte Pakete für den automatisierten systemd-boot Lifecycle laden
apt install -y systemd-boot systemd-boot-efi

# Kernel-Kommandozeile permanent hinterlegen (rw ist zwingend nötig für systemd-boot)
mkdir -p /etc/kernel
echo "zswap.enabled=0 quiet loglevel=3 rw" > /etc/kernel/cmdline

# Pfade für das TTY auffrischen, damit bootctl sofort bekannt ist
export PATH="/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# Bootloader in die EFI-Partition injizieren (mit Fallback, falls --force zickt)
if command -v bootctl &>/dev/null; then
    bootctl install --force || bootctl install
else
    /lib/systemd/systemd-boot-check install || echo "Nutze manuellen Pfad..."
    /usr/bin/bootctl install --force || /usr/bin/bootctl install
fi

# Globale loader.conf schreiben
cat > /boot/efi/loader/loader.conf << 'EOF'
timeout 5
console-mode auto
editor yes
EOF

# Kernel-Hooks via dpkg triggern, um Einträge und Kopien sauber zu erzeugen
info "Triggere Debian Kernel-Hooks..."
dpkg-reconfigure linux-image-$(uname -r)

log "systemd-boot und Kernel-Hooks erfolgreich konfiguriert"