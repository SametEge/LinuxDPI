#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# LinuxDPI-TR – Kurulum Betiği
# Yapımcı: Samet Ege Derin
# https://github.com/sametege/LinuxDPI-TR
# ──────────────────────────────────────────────────────────────
set -e

RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
BLU='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'

say()  { echo -e "${BLU}▶${NC} $1"; }
ok()   { echo -e "${GRN}✓${NC} $1"; }
warn() { echo -e "${YLW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }

INSTALL_DIR="/usr/local/share/linuxdpi-tr"
BIN_LINK="/usr/local/bin/linuxdpi-tr"
DESKTOP_SYSTEM="/usr/share/applications/linuxdpi-tr.desktop"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${BOLD}LinuxDPI-TR – Kurulum${NC}"
echo -e "Yapımcı: Samet Ege Derin"
echo "────────────────────────────────────"
echo ""

# ── Root kontrolü ────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    warn "Root yetkisi gerekiyor, sudo ile yeniden çalıştırılıyor…"
    exec sudo bash "$0" "$@"
fi

# ── Python kontrolü ──────────────────────────────────────────
say "Python 3 kontrol ediliyor…"
command -v python3 &>/dev/null || fail "Python 3 bulunamadı! → sudo pacman -S python"
ok "Python 3 mevcut ($(python3 --version))"

# ── GTK4 / PyGObject ─────────────────────────────────────────
say "GTK4 (python-gobject) kontrol ediliyor…"
if ! python3 -c "import gi; gi.require_version('Gtk','4.0'); from gi.repository import Gtk" &>/dev/null; then
    warn "python-gobject eksik, kuruluyor…"
    pacman -S --noconfirm --needed python-gobject gtk4
fi
ok "GTK4 mevcut."

# ── Temel paketler ───────────────────────────────────────────
say "Temel paketler kuruluyor…"
pacman -S --noconfirm --needed wireguard-tools nftables || warn "Bazı paketler atlandı."
ok "Temel paketler tamam."

# ── AUR yardımcısı varsa AUR paketleri ───────────────────────
AUR_HELPER=""
for h in yay paru; do command -v "$h" &>/dev/null && AUR_HELPER="$h" && break; done

if [ -n "$AUR_HELPER" ]; then
    say "AUR paketleri kuruluyor (wgcf byedpi zapret)…"
    sudo -u "${SUDO_USER:-$USER}" "$AUR_HELPER" -S --noconfirm --needed wgcf byedpi zapret 2>/dev/null \
        || warn "Bazı AUR paketleri atlandı — uygulama içinden kurulabilir."
    ok "AUR paketleri işlendi."
else
    warn "AUR yardımcısı bulunamadı. wgcf/byedpi/zapret uygulama içinden kurulabilir."
fi

# ── Uygulama dosyaları ───────────────────────────────────────
say "Uygulama dosyaları kopyalanıyor → $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/linuxdpi.py" "$INSTALL_DIR/linuxdpi.py"
chmod 755 "$INSTALL_DIR/linuxdpi.py"

# ── Başlatıcı ────────────────────────────────────────────────
cat > "$BIN_LINK" << 'LAUNCHER'
#!/usr/bin/env bash
if [ -n "$WAYLAND_DISPLAY" ]; then
    export WAYLAND_DISPLAY
elif [ -z "$DISPLAY" ]; then
    export DISPLAY=:0
fi
exec python3 /usr/local/share/linuxdpi-tr/linuxdpi.py
LAUNCHER
chmod 755 "$BIN_LINK"
ok "Başlatıcı oluşturuldu: $BIN_LINK"

# ── Masaüstü kısayolu ────────────────────────────────────────
cat > "$DESKTOP_SYSTEM" << DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=LinuxDPI-TR
Comment=Türkiye internet kısıtlamalarını aşma aracı
Exec=$BIN_LINK
Icon=network-vpn
Terminal=false
Categories=Network;System;
Keywords=vpn;wireguard;warp;turkey;dpi;bypass;
StartupNotify=true
DESK
ok "Masaüstü kısayolu oluşturuldu."

# ── Polkit kuralı ────────────────────────────────────────────
mkdir -p /usr/share/polkit-1/rules.d
cat > /usr/share/polkit-1/rules.d/50-linuxdpi.rules << 'POLKIT'
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.policykit.exec") === 0
        && subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
POLKIT
ok "Polkit kuralı eklendi."

# ── Bitiş ────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GRN}Kurulum tamamlandı!${NC}"
echo ""
echo -e "  Terminalde çalıştır : ${BOLD}linuxdpi-tr${NC}"
echo -e "  Uygulama menüsünden : ${BOLD}LinuxDPI-TR${NC} ara"
echo ""
echo -e "${YLW}Hızlı başlangıç:${NC}"
echo "  1. WireGuard sekmesi → 'Bağlan' (her şey otomatik yapılır)"
echo "  2. veya Zapret sekmesi → ISP seç → 'Hizmet Kur'"
echo ""
