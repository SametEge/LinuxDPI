#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LinuxDPI-TR – GTK4
Türkiye internet kısıtlamalarını aşmak için Linux uygulaması
Yapımcı: Samet Ege Derin
https://github.com/sametege/LinuxDPI-TR
v1.0.0
"""

import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk, GLib, Gdk, Pango, Gio

import os
import sys
import subprocess
import threading
import shutil
import re
import tempfile
from pathlib import Path
from typing import Optional, List, Tuple

VERSION     = "1.0.0"
APP_NAME    = "LinuxDPI-TR"
AUTHOR      = "Samet Ege Derin"
GITHUB_URL  = "https://github.com/sametege/LinuxDPI-TR"
APP_ID      = "com.linuxdpi.tr"
CONFIG_DIR  = Path.home() / ".config"  / "linuxdpi-tr"
LOG_DIR     = Path.home() / ".local"   / "share" / "linuxdpi-tr" / "logs"
WG_CONF     = "/etc/wireguard/linuxdpi.conf"

# ── CSS teması ───────────────────────────────────────────────
CSS = b"""
window, .view { background-color: #0d1117; color: #e6edf3; }

.card {
    background-color: #161b22;
    border-radius: 8px;
    padding: 14px 16px;
    margin: 5px 12px;
}
.card-title {
    font-size: 8pt;
    font-weight: bold;
    color: #8b949e;
    margin-bottom: 8px;
}
.section-label {
    font-size: 10pt;
    color: #e6edf3;
}
.muted {
    color: #8b949e;
    font-size: 9pt;
}
.status-ok    { color: #2ea043; font-weight: bold; }
.status-err   { color: #f85149; font-weight: bold; }
.status-warn  { color: #d29922; font-weight: bold; }
.status-off   { color: #8b949e; }

.btn-accent {
    background-color: #1a73e8;
    color: white;
    border-radius: 6px;
    padding: 6px 14px;
    border: none;
    font-size: 10pt;
}
.btn-accent:hover  { background-color: #1557b0; }

.btn-danger {
    background-color: #f85149;
    color: white;
    border-radius: 6px;
    padding: 6px 14px;
    border: none;
    font-size: 10pt;
}
.btn-danger:hover  { background-color: #b91c1c; }

.btn-success {
    background-color: #2ea043;
    color: white;
    border-radius: 6px;
    padding: 6px 14px;
    border: none;
    font-size: 10pt;
}
.btn-success:hover { background-color: #15803d; }

.log-view {
    background-color: #0d1117;
    color: #8b949e;
    font-family: monospace;
    font-size: 9pt;
    border-radius: 4px;
}
entry {
    background-color: #161b22;
    color: #e6edf3;
    border: 1px solid #30363d;
    border-radius: 4px;
    padding: 4px 8px;
}
combobox button {
    background-color: #161b22;
    color: #e6edf3;
    border: 1px solid #30363d;
}
notebook tab {
    background-color: #161b22;
    color: #8b949e;
    padding: 8px 14px;
    border: none;
}
notebook tab:checked {
    background-color: #1a73e8;
    color: white;
}
"""


# ═══════════════════════════════════════════════════════════
# Şifre önbelleği  (oturum boyunca tek seferlik sorar)
# ═══════════════════════════════════════════════════════════

_sudo_password: Optional[str] = None   # oturum şifresi önbelleği
_sudo_lock = threading.Lock()


def _test_sudo(password: str) -> bool:
    """Verilen şifrenin sudo için geçerli olup olmadığını test eder."""
    try:
        r = subprocess.run(
            ["sudo", "-S", "-k", "id"],
            input=password + "\n",
            capture_output=True, text=True, timeout=10,
        )
        return r.returncode == 0
    except Exception:
        return False


def get_sudo_password(parent_win=None) -> Optional[str]:
    """
    Şifreyi önbellekten alır; yoksa GTK diyaloğu gösterir.
    Yanlış şifre girilirse tekrar sorar (en fazla 3 deneme).
    """
    global _sudo_password
    with _sudo_lock:
        if _sudo_password is not None:
            return _sudo_password

    # Ana iş parçacığında çalıştırılması gerekiyor — event kullan
    result: List[Optional[str]] = [None]
    done  = threading.Event()

    def _show():
        _ask_password_dialog(parent_win, result, done)

    GLib.idle_add(_show)
    done.wait(timeout=120)          # kullanıcı 2 dakika içinde girsin
    with _sudo_lock:
        _sudo_password = result[0]
    return _sudo_password


def _ask_password_dialog(parent, result: list, done: threading.Event, attempt: int = 1):
    """GTK4 şifre diyaloğunu gösterir."""
    dlg = Gtk.Dialog(title="Yönetici Şifresi", transient_for=parent, modal=True)
    dlg.set_default_size(380, -1)

    box = dlg.get_content_area()
    box.set_spacing(12)
    box.set_margin_start(20); box.set_margin_end(20)
    box.set_margin_top(16);   box.set_margin_bottom(16)

    icon_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
    icon = Gtk.Image.new_from_icon_name("dialog-password")
    icon.set_pixel_size(32)
    icon_row.append(icon)

    text_col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
    title_lbl = Gtk.Label(label="<b>Yönetici yetkisi gerekiyor</b>", use_markup=True, xalign=0)
    title_lbl.add_css_class("section-label")
    sub_lbl = Gtk.Label(
        label=("Yanlış şifre, tekrar deneyin." if attempt > 1
               else "Sistem şifrenizi girin (sudo şifresi)."),
        xalign=0, wrap=True
    )
    sub_lbl.add_css_class("muted")
    text_col.append(title_lbl); text_col.append(sub_lbl)
    icon_row.append(text_col)
    box.append(icon_row)

    entry = Gtk.Entry()
    entry.set_visibility(False)
    entry.set_input_purpose(Gtk.InputPurpose.PASSWORD)
    entry.set_placeholder_text("Şifre…")
    entry.add_css_class("section-label")
    box.append(entry)

    btn_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
    btn_row.set_halign(Gtk.Align.END)

    cancel_btn = Gtk.Button(label="İptal")
    cancel_btn.add_css_class("btn-danger")
    ok_btn = Gtk.Button(label="Tamam")
    ok_btn.add_css_class("btn-accent")
    ok_btn.get_style_context().add_class("default")
    btn_row.append(cancel_btn); btn_row.append(ok_btn)
    box.append(btn_row)

    def _cancel(_):
        result[0] = None; done.set(); dlg.destroy()

    def _ok(_):
        pw = entry.get_text()
        dlg.destroy()
        # Şifreyi test et (arka planda)
        def verify():
            if not pw:
                GLib.idle_add(lambda: _ask_password_dialog(parent, result, done, attempt + 1))
                return
            if _test_sudo(pw):
                result[0] = pw; done.set()
            elif attempt < 3:
                GLib.idle_add(lambda: _ask_password_dialog(parent, result, done, attempt + 1))
            else:
                result[0] = None; done.set()
        threading.Thread(target=verify, daemon=True).start()

    cancel_btn.connect("clicked", _cancel)
    ok_btn.connect("clicked", _ok)
    entry.connect("activate", _ok)   # Enter tuşu
    dlg.present()


def clear_sudo_cache():
    global _sudo_password
    with _sudo_lock:
        _sudo_password = None


# ═══════════════════════════════════════════════════════════
# Komut çalıştırıcılar
# ═══════════════════════════════════════════════════════════

def _build_sudo_cmd(cmd: List[str]) -> Tuple[List[str], str]:
    """sudo -S komutunu ve stdin'e yazılacak şifreyi döner."""
    pw = get_sudo_password()
    if pw is None:
        return [], ""
    return ["sudo", "-S", "-p", ""] + cmd, pw + "\n"


def run_cmd(cmd: List[str], sudo: bool = False,
            timeout: int = 30) -> Tuple[int, str, str]:
    if sudo and not is_root():
        full_cmd, stdin_data = _build_sudo_cmd(cmd)
        if not full_cmd:
            return -1, "", "Şifre girilmedi."
        try:
            r = subprocess.run(full_cmd, input=stdin_data,
                               capture_output=True, text=True, timeout=timeout)
            return r.returncode, r.stdout, r.stderr
        except subprocess.TimeoutExpired:
            return -1, "", "Zaman aşımı"
        except Exception as e:
            return -1, "", str(e)
    else:
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
            return r.returncode, r.stdout, r.stderr
        except subprocess.TimeoutExpired:
            return -1, "", "Zaman aşımı"
        except FileNotFoundError:
            return -1, "", f"Komut bulunamadı: {cmd[0]}"
        except Exception as e:
            return -1, "", str(e)


def cmd_exists(name: str) -> bool:
    return shutil.which(name) is not None


def is_root() -> bool:
    return os.geteuid() == 0


def write_tmp(content: str, suffix: str = ".conf") -> str:
    with tempfile.NamedTemporaryFile(mode="w", suffix=suffix, delete=False) as f:
        f.write(content)
        return f.name


def run_stream(cmd: List[str], log_fn, sudo: bool = False, timeout: int = 300) -> bool:
    """Komutu çalıştırır; çıktıyı satır satır log_fn'e akıtır."""
    stdin_data = None
    if sudo and not is_root():
        full_cmd, stdin_data = _build_sudo_cmd(cmd)
        if not full_cmd:
            log_fn("HATA: Şifre girilmedi."); return False
        cmd = full_cmd
    try:
        proc = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE if stdin_data else None,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True, bufsize=1,
        )
        if stdin_data:
            proc.stdin.write(stdin_data)
            proc.stdin.flush()
            proc.stdin.close()
        for line in proc.stdout:
            log_fn(line.rstrip())
        proc.wait(timeout=timeout)
        return proc.returncode == 0
    except subprocess.TimeoutExpired:
        proc.kill(); log_fn("HATA: Zaman aşımı."); return False
    except FileNotFoundError:
        log_fn(f"HATA: Komut bulunamadı: {cmd[0]}"); return False
    except Exception as e:
        log_fn(f"HATA: {e}"); return False


def _aur_helper() -> Optional[str]:
    """Sistemde kurulu AUR yardımcısını döner."""
    for h in ["yay", "paru"]:
        if cmd_exists(h):
            return h
    return None


def install_pacman(pkg: str, log_fn) -> bool:
    """pacman ile resmi repo paketi kurar; kurulum çıktısını canlı akıtır."""
    log_fn(f"► sudo pacman -S --noconfirm {pkg}")
    return run_stream(["pacman", "-S", "--noconfirm", "--needed", pkg], log_fn, sudo=True)


def install_aur(pkg: str, log_fn) -> bool:
    """
    yay/paru ile AUR paketi kurar.
    yay kendi içinde sudo çağırdığı için geçici bir NOPASSWD sudoers kuralı
    ekler, kurulumdan sonra siler.
    """
    helper = _aur_helper()
    if not helper:
        log_fn("HATA: AUR yardımcısı bulunamadı (yay/paru).")
        return False

    user = os.environ.get("USER", "sametege")
    rule = f"{user} ALL=(ALL) NOPASSWD: ALL\n"
    sudoers_tmp = f"/etc/sudoers.d/linuxdpi-aur-{os.getpid()}"

    # Geçici NOPASSWD kuralı yaz (sudo -S ile)
    tmp_file = write_tmp(rule, ".sudoers")
    c1, _, _ = run_cmd(["cp", tmp_file, sudoers_tmp], sudo=True)
    run_cmd(["chmod", "440", sudoers_tmp], sudo=True)
    os.unlink(tmp_file)

    if c1 != 0:
        log_fn("⚠ Geçici sudoers kuralı yazılamadı, yine de deneniyor…")

    log_fn(f"► {helper} -S --noconfirm {pkg}")
    try:
        ok = run_stream([helper, "-S", "--noconfirm", "--needed", pkg], log_fn)
    finally:
        # Her durumda geçici kuralı kaldır
        run_cmd(["rm", "-f", sudoers_tmp], sudo=True)

    return ok


def ensure_tool(tool: str, pkg: str, log_fn, aur: bool = False) -> bool:
    """Araç yoksa otomatik kurar, kurulumdan sonra tekrar kontrol eder."""
    if cmd_exists(tool):
        return True
    log_fn(f"'{tool}' bulunamadı → otomatik kuruluyor…")
    ok = install_aur(pkg, log_fn) if aur else install_pacman(pkg, log_fn)
    if ok:
        # PATH'i güncelle
        os.environ["PATH"] = "/usr/bin:/usr/local/bin:" + os.environ.get("PATH", "")
        if cmd_exists(tool):
            log_fn(f"✓ {pkg} başarıyla kuruldu.")
            return True
        log_fn(f"✗ {pkg} kuruldu ama '{tool}' hâlâ bulunamıyor (oturumu yenileyebilirsiniz).")
        return False
    log_fn(f"✗ {pkg} kurulamadı.")
    return False


# ═══════════════════════════════════════════════════════════
# Arka plan servis yöneticisi
# ═══════════════════════════════════════════════════════════

class SvcMgr:
    @staticmethod
    def create(name: str, description: str, exec_start: str,
               after: str = "network.target", user: str = "root") -> bool:
        body = (
            f"[Unit]\nDescription={description}\nAfter={after}\n\n"
            f"[Service]\nType=simple\nUser={user}\n"
            f"ExecStart={exec_start}\nRestart=on-failure\nRestartSec=5\n\n"
            f"[Install]\nWantedBy=multi-user.target\n"
        )
        tmp = write_tmp(body, ".service")
        c, _, _ = run_cmd(["cp", tmp, f"/etc/systemd/system/{name}.service"], sudo=True)
        os.unlink(tmp)
        if c != 0:
            return False
        run_cmd(["systemctl", "daemon-reload"], sudo=True)
        return True

    @staticmethod
    def start(name: str)   -> Tuple[bool, str]:
        c, _, e = run_cmd(["systemctl", "start",   name], sudo=True); return c == 0, e
    @staticmethod
    def stop(name: str)    -> Tuple[bool, str]:
        c, _, e = run_cmd(["systemctl", "stop",    name], sudo=True); return c == 0, e
    @staticmethod
    def enable(name: str)  -> bool:
        c, _, _ = run_cmd(["systemctl", "enable",  name], sudo=True); return c == 0
    @staticmethod
    def disable(name: str) -> bool:
        c, _, _ = run_cmd(["systemctl", "disable", name], sudo=True); return c == 0
    @staticmethod
    def status(name: str)  -> str:
        _, o, _ = run_cmd(["systemctl", "is-active", name]); return o.strip()
    @staticmethod
    def is_active(name: str) -> bool:
        return SvcMgr.status(name) == "active"
    @staticmethod
    def remove(name: str)  -> bool:
        SvcMgr.stop(name); SvcMgr.disable(name)
        run_cmd(["rm", "-f", f"/etc/systemd/system/{name}.service"], sudo=True)
        run_cmd(["systemctl", "daemon-reload"], sudo=True)
        return True


# ═══════════════════════════════════════════════════════════
# WireGuard / WARP
# ═══════════════════════════════════════════════════════════

class WGMgr:
    @staticmethod
    def register() -> Tuple[bool, str]:
        d = CONFIG_DIR / "wgcf"; d.mkdir(parents=True, exist_ok=True)
        prev = os.getcwd(); os.chdir(d)
        c, o, e = run_cmd(["wgcf", "register", "--accept-tos"])
        os.chdir(prev)
        return c == 0, (e or o).strip()

    @staticmethod
    def generate() -> Tuple[bool, str]:
        d = CONFIG_DIR / "wgcf"; prev = os.getcwd(); os.chdir(d)
        c, o, e = run_cmd(["wgcf", "generate"])
        os.chdir(prev)
        return c == 0, (e or o).strip()

    @staticmethod
    def deploy() -> Tuple[bool, str]:
        profile = CONFIG_DIR / "wgcf" / "wgcf-profile.conf"
        if not profile.exists():
            return False, "wgcf-profile.conf bulunamadı – önce kayıt yapın."
        txt = profile.read_text()
        if "DNS" not in txt:
            txt = txt.replace("[Interface]", "[Interface]\nDNS = 8.8.8.8, 9.9.9.9")
        tmp = write_tmp(txt)
        c, _, e = run_cmd(["cp", tmp, WG_CONF], sudo=True)
        os.unlink(tmp)
        if c != 0:
            return False, e
        run_cmd(["chmod", "600", WG_CONF], sudo=True)
        return True, f"Yapılandırma {WG_CONF} konumuna yazıldı."

    @staticmethod
    def up()   -> Tuple[bool, str]:
        c, o, e = run_cmd(["wg-quick", "up",   "linuxdpi"], sudo=True)
        return c == 0, (e or o).strip()
    @staticmethod
    def down() -> Tuple[bool, str]:
        c, o, e = run_cmd(["wg-quick", "down", "linuxdpi"], sudo=True)
        return c == 0, (e or o).strip()
    @staticmethod
    def connected() -> bool:
        c, o, _ = run_cmd(["wg", "show", "linuxdpi"])
        return c == 0 and bool(o.strip())
    @staticmethod
    def enable_autostart() -> bool:
        c, _, _ = run_cmd(["systemctl", "enable", "wg-quick@linuxdpi"], sudo=True)
        return c == 0


# ═══════════════════════════════════════════════════════════
# ByeDPI
# ═══════════════════════════════════════════════════════════

class ByeDPIMgr:
    SVC = "linuxdpi-byedpi"
    @staticmethod
    def bin() -> Optional[str]:
        for p in ["ciadpi", "byedpi"]:
            if cmd_exists(p): return shutil.which(p)
        custom = CONFIG_DIR / "byedpi" / "ciadpi"
        return str(custom) if custom.exists() else None

    @staticmethod
    def install_aur() -> Tuple[bool, str]:
        for h in ["yay", "paru"]:
            if cmd_exists(h):
                c, o, e = run_cmd([h, "-S", "--noconfirm", "byedpi"])
                return c == 0, (e or o).strip()
        return False, "AUR yardımcısı bulunamadı (yay/paru)."

    @staticmethod
    def setup(port: int = 1080, extra: str = "") -> Tuple[bool, str]:
        b = ByeDPIMgr.bin()
        if not b: return False, "ByeDPI ikili dosyası bulunamadı."
        if not SvcMgr.create(ByeDPIMgr.SVC, "ByeDPI DPI Bypass",
                             f"{b} -p {port} {extra}".strip(), user="nobody"):
            return False, "Servis dosyası yazılamadı."
        SvcMgr.enable(ByeDPIMgr.SVC)
        ok, err = SvcMgr.start(ByeDPIMgr.SVC)
        return ok, err or f"ByeDPI başlatıldı → SOCKS5 127.0.0.1:{port}"

    @staticmethod
    def remove()   -> bool: return SvcMgr.remove(ByeDPIMgr.SVC)
    @staticmethod
    def running()  -> bool: return SvcMgr.is_active(ByeDPIMgr.SVC)


# ═══════════════════════════════════════════════════════════
# Zapret
# ═══════════════════════════════════════════════════════════

class ZapretMgr:
    SVC = "linuxdpi-zapret"
    PRESETS = {
        "Türk Telekom": "--dpi-desync=fake,split2 --dpi-desync-ttl=3 --dpi-desync-fooling=md5sig",
        "Turkcell":     "--dpi-desync=fake --dpi-desync-ttl=4 --dpi-desync-fooling=md5sig --wssize 1:6",
        "Vodafone TR":  "--dpi-desync=split2 --dpi-desync-ttl=5 --dpi-desync-fooling=md5sig",
        "Genel":        "--dpi-desync=fake,split2 --dpi-desync-ttl=5 --dpi-desync-fooling=md5sig",
        "Genel 2":      "--dpi-desync=fake,split2 --dpi-desync-ttl=3 --dpi-desync-fooling=badseq",
        "Hassas":       "--dpi-desync=fake --dpi-desync-ttl=2",
    }

    @staticmethod
    def bin() -> Optional[str]:
        for p in ["/usr/bin/nfqws", "/usr/local/bin/nfqws"]:
            if Path(p).exists(): return p
        return shutil.which("nfqws")

    @staticmethod
    def install_aur() -> Tuple[bool, str]:
        for h in ["yay", "paru"]:
            if cmd_exists(h):
                c, o, e = run_cmd([h, "-S", "--noconfirm", "zapret"])
                return c == 0, (e or o).strip()
        return False, "AUR yardımcısı bulunamadı."

    @staticmethod
    def apply_nft():
        rules = ("table inet zapret {\n"
                 "    chain output { type filter hook output priority 0; policy accept;\n"
                 "        tcp dport {80,443} queue num 200 bypass }\n"
                 "}\n")
        if cmd_exists("nft"):
            tmp = write_tmp(rules, ".nft")
            run_cmd(["nft", "-f", tmp], sudo=True); os.unlink(tmp)
        else:
            run_cmd(["iptables", "-I", "OUTPUT", "-p", "tcp", "--dport", "443",
                     "-j", "NFQUEUE", "--queue-num", "200", "--queue-bypass"], sudo=True)

    @staticmethod
    def remove_nft():
        run_cmd(["nft", "delete", "table", "inet", "zapret"], sudo=True)

    @staticmethod
    def setup(params: str) -> Tuple[bool, str]:
        b = ZapretMgr.bin()
        if not b: return False, "nfqws (zapret) bulunamadı."
        ZapretMgr.apply_nft()
        if not SvcMgr.create(ZapretMgr.SVC, "Zapret DPI Bypass", f"{b} --qnum=200 {params}"):
            return False, "Servis dosyası yazılamadı."
        SvcMgr.enable(ZapretMgr.SVC)
        ok, err = SvcMgr.start(ZapretMgr.SVC)
        return ok, err or "Zapret servisi başlatıldı."

    @staticmethod
    def run_once(params: str) -> Optional[subprocess.Popen]:
        b = ZapretMgr.bin()
        if not b: return None
        ZapretMgr.apply_nft()
        prefix = [] if is_root() else ["pkexec"]
        return subprocess.Popen(prefix + [b, "--qnum=200"] + params.split())

    @staticmethod
    def remove() -> bool:
        ZapretMgr.remove_nft(); return SvcMgr.remove(ZapretMgr.SVC)
    @staticmethod
    def running() -> bool:
        return SvcMgr.is_active(ZapretMgr.SVC)


# ═══════════════════════════════════════════════════════════
# DNS
# ═══════════════════════════════════════════════════════════

class DNSMgr:
    SETS = {
        "Google + Quad9":  ("8.8.8.8",       "9.9.9.9"),
        "Cloudflare":      ("1.1.1.1",        "1.0.0.1"),
        "Google":          ("8.8.8.8",        "8.8.4.4"),
        "Quad9":           ("9.9.9.9",        "149.112.112.112"),
        "OpenDNS":         ("208.67.222.222", "208.67.220.220"),
    }

    @staticmethod
    def _iface() -> Optional[str]:
        _, o, _ = run_cmd(["ip", "route", "get", "8.8.8.8"])
        m = re.search(r"dev (\S+)", o); return m.group(1) if m else None

    @staticmethod
    def set(p: str, s: str) -> Tuple[bool, str]:
        if cmd_exists("resolvectl"):
            iface = DNSMgr._iface()
            if iface:
                run_cmd(["resolvectl", "dns", iface, p, s], sudo=True)
                run_cmd(["resolvectl", "dnssec", iface, "no"], sudo=True)
                return True, f"DNS {iface} arayüzüne ayarlandı: {p}, {s}"
        content = f"# SplitWire-Turkey\nnameserver {p}\nnameserver {s}\n"
        run_cmd(["cp", "/etc/resolv.conf", "/etc/resolv.conf.swt.bak"], sudo=True)
        tmp = write_tmp(content)
        c, _, e = run_cmd(["cp", tmp, "/etc/resolv.conf"], sudo=True)
        os.unlink(tmp); return c == 0, e or f"DNS ayarlandı: {p}, {s}"

    @staticmethod
    def reset() -> Tuple[bool, str]:
        bak = Path("/etc/resolv.conf.swt.bak")
        if bak.exists():
            c, _, e = run_cmd(["cp", str(bak), "/etc/resolv.conf"], sudo=True)
            return c == 0, e or "DNS yedekten geri alındı."
        if cmd_exists("resolvectl"):
            iface = DNSMgr._iface()
            if iface:
                run_cmd(["resolvectl", "revert", iface], sudo=True)
                return True, "DNS DHCP'ye döndürüldü."
        return True, "DNS temizlendi."

    @staticmethod
    def current() -> str:
        if cmd_exists("resolvectl"):
            _, o, _ = run_cmd(["resolvectl", "status", "--no-pager"])
            for ln in o.splitlines():
                if "Current DNS" in ln or "DNS Servers" in ln:
                    return ln.strip()
        _, o, _ = run_cmd(["cat", "/etc/resolv.conf"])
        for ln in o.splitlines():
            if ln.startswith("nameserver"):
                return ln.strip()
        return "Bilinmiyor"


# ═══════════════════════════════════════════════════════════
# GTK4 GUI
# ═══════════════════════════════════════════════════════════

def _apply_css():
    provider = Gtk.CssProvider()
    provider.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_display(
        Gdk.Display.get_default(),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )


def card(child_widget=None, title: str = None) -> Gtk.Box:
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
    box.add_css_class("card")
    if title:
        lbl = Gtk.Label(label=title, xalign=0)
        lbl.add_css_class("card-title")
        box.append(lbl)
    if child_widget:
        box.append(child_widget)
    return box


def btn(label: str, style: str = "btn-accent") -> Gtk.Button:
    b = Gtk.Button(label=label)
    b.add_css_class(style)
    return b


def lbl(text: str, css: str = "section-label", halign=Gtk.Align.START) -> Gtk.Label:
    l = Gtk.Label(label=text, xalign=0, halign=halign, wrap=True, wrap_mode=Pango.WrapMode.WORD)
    l.add_css_class(css)
    return l


def row(*widgets) -> Gtk.Box:
    b = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
    b.set_margin_top(0); b.set_margin_bottom(0)
    for w in widgets:
        b.append(w)
    return b


class LogView(Gtk.ScrolledWindow):
    def __init__(self, height: int = 140):
        super().__init__()
        self.set_min_content_height(height)
        self.set_vexpand(True)
        self._buf  = Gtk.TextBuffer()
        self._view = Gtk.TextView(buffer=self._buf, editable=False,
                                  cursor_visible=False, wrap_mode=Gtk.WrapMode.WORD)
        self._view.add_css_class("log-view")
        self._view.set_left_margin(8); self._view.set_right_margin(8)
        self._view.set_top_margin(6);  self._view.set_bottom_margin(6)
        self.set_child(self._view)

    def write(self, msg: str):
        GLib.idle_add(self._append, msg)

    def _append(self, msg: str):
        end = self._buf.get_end_iter()
        self._buf.insert(end, msg + "\n")
        end = self._buf.get_end_iter()
        self._view.scroll_to_iter(end, 0, False, 0, 0)

    def clear(self):
        GLib.idle_add(self._buf.set_text, "")


class StatusRow(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self._dot = Gtk.Label(label="●")
        self._dot.add_css_class("status-off")
        self._lbl = Gtk.Label(label="Çalışmıyor", xalign=0)
        self._lbl.add_css_class("status-off")
        self.append(self._dot)
        self.append(self._lbl)

    def set_state(self, state: str, text: str):
        css_map = {"on": "status-ok", "off": "status-off",
                   "err": "status-err", "warn": "status-warn"}
        for cls in css_map.values():
            self._dot.remove_css_class(cls)
            self._lbl.remove_css_class(cls)
        css = css_map.get(state, "status-off")
        self._dot.add_css_class(css)
        self._lbl.add_css_class(css)
        self._lbl.set_text(text)


# ── Ana pencere ──────────────────────────────────────────────

class LinuxDPIWindow(Gtk.ApplicationWindow):

    def __init__(self, app):
        super().__init__(application=app, title=f"{APP_NAME}  v{VERSION}")
        self.set_default_size(660, 740)
        self.set_resizable(True)
        _apply_css()

        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        self._zapret_proc: Optional[subprocess.Popen] = None

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.set_child(root)

        root.append(self._build_header())

        nb = Gtk.Notebook()
        nb.set_margin_start(10); nb.set_margin_end(10)
        nb.set_margin_bottom(10)
        nb.set_vexpand(True)
        root.append(nb)

        for label, builder in [
            ("WireGuard", self._build_wg_tab),
            ("ByeDPI",    self._build_byedpi_tab),
            ("Zapret",    self._build_zapret_tab),
            ("DNS",       self._build_dns_tab),
            ("Gelişmiş",  self._build_adv_tab),
        ]:
            page = builder()
            tab_lbl = Gtk.Label(label=label)
            nb.append_page(page, tab_lbl)

        GLib.timeout_add(500, self._check_deps)

    # ── Başlık ────────────────────────────────────────────

    def _build_header(self) -> Gtk.Box:
        hdr = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        hdr.set_margin_start(20); hdr.set_margin_end(20)
        hdr.set_margin_top(16);   hdr.set_margin_bottom(8)

        t1 = Gtk.Label(label="LinuxDPI")
        t1.add_css_class("section-label")
        attr = Pango.AttrList()
        attr.insert(Pango.AttrFontDesc.new(
            Pango.FontDescription.from_string("Sans Bold 18")))
        t1.set_attributes(attr)

        t2 = Gtk.Label(label="-TR")
        attr2 = Pango.AttrList()
        attr2.insert(Pango.AttrFontDesc.new(
            Pango.FontDescription.from_string("Sans Bold 18")))
        attr2.insert(Pango.attr_foreground_new(0x1a00, 0x7300, 0xe800))
        t2.set_attributes(attr2)

        t3 = Gtk.Label(label=" Linux")
        t3.add_css_class("muted")

        t4 = Gtk.Label(label=f"  v{VERSION}")
        t4.add_css_class("muted")

        for w in [t1, t2, t3, t4]:
            hdr.append(w)

        spacer = Gtk.Box(); spacer.set_hexpand(True); hdr.append(spacer)

        role_txt = "Yönetici" if is_root() else "Normal Kullanıcı"
        role_css = "status-ok" if is_root() else "status-warn"
        r = Gtk.Label(label=role_txt)
        r.add_css_class("muted"); r.add_css_class(role_css)
        hdr.append(r)

        return hdr

    # ── Ortak sayfa kapsayıcısı ───────────────────────────

    def _scrolled_page(self) -> Tuple[Gtk.ScrolledWindow, Gtk.Box]:
        sw = Gtk.ScrolledWindow()
        sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        sw.set_vexpand(True)
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        vbox.set_margin_top(4)
        sw.set_child(vbox)
        return sw, vbox

    # ── WireGuard sekmesi ─────────────────────────────────

    def _build_wg_tab(self) -> Gtk.ScrolledWindow:
        sw, vbox = self._scrolled_page()

        # Durum kartı
        self._wg_status = StatusRow()
        sc = card(title="DURUM")
        sc.append(self._wg_status)
        self._wg_deps_lbl = lbl("Bağımlılıklar kontrol ediliyor…", "muted")
        sc.append(self._wg_deps_lbl)
        self._deps_install_btn = btn("Eksik Araçları Kur", "btn-accent")
        self._deps_install_btn.set_visible(False)
        self._deps_install_btn.connect("clicked", lambda _: self._install_all_deps())
        sc.append(self._deps_install_btn)
        vbox.append(sc)

        # TEK BUTON
        ac = card()
        self._wg_toggle_btn = btn("Bağlan", "btn-success")
        self._wg_toggle_btn.set_hexpand(True)
        self._wg_toggle_btn.set_size_request(-1, 50)
        self._wg_toggle_btn.connect("clicked", lambda _: self._wg_toggle())
        ac.append(self._wg_toggle_btn)

        self._wg_auto = Gtk.CheckButton(label="Sistem başlangıcında otomatik bağlan")
        self._wg_auto.set_margin_top(10)
        ac.append(self._wg_auto)
        vbox.append(ac)

        # Bilgi
        ic = card()
        ic.append(lbl("Cloudflare WARP üzerinden WireGuard tüneli kurar.\n"
                       "İlk bağlantıda gerekli araçlar otomatik kurulur.", "muted"))
        vbox.append(ic)

        # Log
        self._wg_log = LogView(200)
        lc = card(title="ÇIKTI")
        lc.append(self._wg_log)
        vbox.append(lc)

        self._wg_refresh()
        return sw

    def _wg_refresh(self):
        def _do():
            if WGMgr.connected():
                self._wg_status.set_state("on", "Bağlı (Cloudflare WARP)")
                self._wg_toggle_btn.set_label("Bağlantıyı Kes")
                self._wg_toggle_btn.remove_css_class("btn-success")
                self._wg_toggle_btn.add_css_class("btn-danger")
            else:
                self._wg_status.set_state("off", "Bağlı değil")
                self._wg_toggle_btn.set_label("Bağlan")
                self._wg_toggle_btn.remove_css_class("btn-danger")
                self._wg_toggle_btn.add_css_class("btn-success")
        GLib.idle_add(_do)

    def _wg_toggle(self):
        """Bağlıysa kes, değilse bağlan (hepsini otomatik yap)."""
        if WGMgr.connected():
            self._wg_disconnect()
        else:
            self._wg_connect()

    def _wg_connect(self):
        def t():
            lg = self._wg_log

            # 1) wireguard-tools kontrolü
            if not ensure_tool("wg-quick", "wireguard-tools", lg.write):
                return

            # 2) wgcf kontrolü
            if not ensure_tool("wgcf", "wgcf", lg.write, aur=True):
                return

            # 3) Config dosyası yoksa otomatik oluştur
            if not Path(WG_CONF).exists():
                lg.write(f"⚠ {WG_CONF} bulunamadı → otomatik oluşturuluyor…")

                profile = CONFIG_DIR / "wgcf" / "wgcf-profile.conf"
                if not profile.exists():
                    lg.write("  WARP kaydı yapılıyor…")
                    ok, msg = WGMgr.register()
                    lg.write(("  ✓" if ok else "  ✗") + f" {msg}")
                    if not ok:
                        lg.write("  HATA: Kayıt başarısız.")
                        return
                    lg.write("  Profil oluşturuluyor…")
                    ok2, msg2 = WGMgr.generate()
                    lg.write(("  ✓" if ok2 else "  ✗") + f" {msg2}")
                    if not ok2:
                        lg.write("  HATA: Profil oluşturulamadı.")
                        return

                lg.write("  Yapılandırma /etc/wireguard/ konumuna yazılıyor…")
                ok3, msg3 = WGMgr.deploy()
                lg.write(("  ✓" if ok3 else "  ✗") + f" {msg3}")
                if not ok3:
                    lg.write("  HATA: Yapılandırma yazılamadı.")
                    return

            # 4) Bağlan
            lg.write("Bağlanılıyor…")
            ok, msg = WGMgr.up()
            lg.write(("✓" if ok else "✗") + f" {msg}")
            self._wg_refresh()
        threading.Thread(target=t, daemon=True).start()

    def _wg_disconnect(self):
        def t():
            lg = self._wg_log
            lg.write("Bağlantı kesiliyor…")
            if not ensure_tool("wg-quick", "wireguard-tools", lg.write):
                return
            ok, msg = WGMgr.down()
            lg.write(("✓" if ok else "✗") + f" {msg}")
            self._wg_refresh()
        threading.Thread(target=t, daemon=True).start()

    # ── ByeDPI sekmesi ────────────────────────────────────

    def _build_byedpi_tab(self) -> Gtk.ScrolledWindow:
        sw, vbox = self._scrolled_page()

        self._bd_status = StatusRow()
        sc = card(title="DURUM"); sc.append(self._bd_status); vbox.append(sc)

        pc = card(title="AYARLAR")
        pr = row(lbl("Port:"))
        self._bd_port = Gtk.Entry(); self._bd_port.set_text("1080"); self._bd_port.set_max_width_chars(8)
        pr.append(self._bd_port)
        pc.append(pr)
        pc.append(lbl("Ek parametreler:", "muted"))
        self._bd_args = Gtk.Entry(); self._bd_args.set_hexpand(True)
        pc.append(self._bd_args)
        vbox.append(pc)

        ac = card(title="İŞLEMLER")
        r = row()
        b1 = btn("Servis Kur"); b1.connect("clicked", lambda _: self._bd_install()); r.append(b1)
        b2 = btn("Kaldır", "btn-danger"); b2.connect("clicked", lambda _: self._bd_remove()); r.append(b2)
        ac.append(r); vbox.append(ac)

        ic = card()
        ic.append(lbl("ByeDPI, DPI atlatmak için SOCKS5 proxy olarak çalışır.\n"
                       "Kurulumdan sonra proxy ayarını 127.0.0.1:1080 yapın.\n"
                       "veya: proxychains discord", "muted"))
        vbox.append(ic)

        self._bd_log = LogView(160)
        lc = card(title="ÇIKTI"); lc.append(self._bd_log); vbox.append(lc)
        self._bd_refresh(); return sw

    def _bd_refresh(self):
        def _do():
            if ByeDPIMgr.running():
                self._bd_status.set_state("on",  "Çalışıyor")
            else:
                self._bd_status.set_state("off", "Çalışmıyor")
        GLib.idle_add(_do)

    def _bd_install(self):
        def t():
            lg = self._bd_log; lg.write("ByeDPI servisi kuruluyor…")
            if not ByeDPIMgr.bin():
                if not install_aur("byedpi", lg.write):
                    return
                # ikili yol değişmiş olabilir, önbelleği temizle
                shutil.which.cache_clear() if hasattr(shutil.which, "cache_clear") else None
            if not ByeDPIMgr.bin():
                lg.write("✗ ciadpi hâlâ bulunamıyor."); return
            try:   port = int(self._bd_port.get_text().strip() or "1080")
            except: port = 1080
            ok, msg = ByeDPIMgr.setup(port, self._bd_args.get_text().strip())
            lg.write(("✓" if ok else "✗") + f" {msg}")
            self._bd_refresh()
        threading.Thread(target=t, daemon=True).start()

    def _bd_remove(self):
        def t():
            self._bd_log.write("ByeDPI kaldırılıyor…")
            ByeDPIMgr.remove(); self._bd_log.write("✓ Kaldırıldı.")
            self._bd_refresh()
        threading.Thread(target=t, daemon=True).start()

    # ── Zapret sekmesi ────────────────────────────────────

    def _build_zapret_tab(self) -> Gtk.ScrolledWindow:
        sw, vbox = self._scrolled_page()

        self._zp_status = StatusRow()
        sc = card(title="DURUM"); sc.append(self._zp_status); vbox.append(sc)

        pc = card(title="HAZIR AYAR")
        pr = row(lbl("Servis Sağlayıcı:"))
        self._zp_combo = Gtk.DropDown.new_from_strings(list(ZapretMgr.PRESETS.keys()))
        self._zp_combo.connect("notify::selected", self._zp_on_preset)
        pr.append(self._zp_combo); pc.append(pr)

        pc.append(lbl("Parametreler:", "muted"))
        buf = Gtk.TextBuffer()
        buf.set_text(ZapretMgr.PRESETS["Genel"])
        self._zp_params_buf = buf
        tv = Gtk.TextView(buffer=buf, wrap_mode=Gtk.WrapMode.WORD)
        tv.add_css_class("log-view")
        tv.set_left_margin(8); tv.set_right_margin(8)
        tv.set_top_margin(6); tv.set_bottom_margin(6)
        tv.set_size_request(-1, 64)
        pc.append(tv); vbox.append(pc)

        ac = card(title="İŞLEMLER")
        r1 = row()
        b1 = btn("Hizmet Kur"); b1.connect("clicked", lambda _: self._zp_install()); r1.append(b1)
        b2 = btn("Tek Seferlik"); b2.connect("clicked", lambda _: self._zp_once()); r1.append(b2)
        ac.append(r1)
        r2 = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8); r2.set_margin_top(8)
        b3 = btn("Kaldır", "btn-danger"); b3.connect("clicked", lambda _: self._zp_remove()); r2.append(b3)
        ac.append(r2); vbox.append(ac)

        ic = card()
        ic.append(lbl("Zapret, nfqws ile sistem geneli DPI atlatma sağlar.\n"
                       "nftables/iptables kuralları otomatik eklenir.", "muted"))
        vbox.append(ic)

        self._zp_log = LogView(160)
        lc = card(title="ÇIKTI"); lc.append(self._zp_log); vbox.append(lc)
        self._zp_refresh(); return sw

    def _zp_on_preset(self, dd, _=None):
        keys  = list(ZapretMgr.PRESETS.keys())
        idx   = dd.get_selected()
        if 0 <= idx < len(keys):
            self._zp_params_buf.set_text(ZapretMgr.PRESETS[keys[idx]])

    def _zp_refresh(self):
        def _do():
            if ZapretMgr.running():
                self._zp_status.set_state("on",  "Çalışıyor")
            else:
                self._zp_status.set_state("off", "Çalışmıyor")
        GLib.idle_add(_do)

    def _zp_params(self) -> str:
        s = self._zp_params_buf.get_start_iter()
        e = self._zp_params_buf.get_end_iter()
        return self._zp_params_buf.get_text(s, e, False).strip()

    def _zp_install(self):
        def t():
            lg = self._zp_log; lg.write("Zapret servisi kuruluyor…")
            if not ZapretMgr.bin():
                if not install_aur("zapret", lg.write):
                    return
            if not ZapretMgr.bin():
                lg.write("✗ nfqws hâlâ bulunamıyor."); return
            ok, msg = ZapretMgr.setup(self._zp_params())
            lg.write(("✓" if ok else "✗") + f" {msg}")
            self._zp_refresh()
        threading.Thread(target=t, daemon=True).start()

    def _zp_once(self):
        def t():
            lg = self._zp_log
            if self._zapret_proc and self._zapret_proc.poll() is None:
                self._zapret_proc.terminate(); lg.write("Önceki oturum durduruldu."); return
            if not ZapretMgr.bin():
                if not install_aur("zapret", lg.write):
                    return
            if not ZapretMgr.bin():
                lg.write("✗ nfqws bulunamıyor."); return
            self._zapret_proc = ZapretMgr.run_once(self._zp_params())
            lg.write("Zapret çalışıyor. Durdurmak için tekrar tıklayın.")
        threading.Thread(target=t, daemon=True).start()

    def _zp_remove(self):
        def t():
            self._zp_log.write("Zapret kaldırılıyor…")
            ZapretMgr.remove(); self._zp_log.write("✓ Kaldırıldı.")
            self._zp_refresh()
        threading.Thread(target=t, daemon=True).start()

    # ── DNS sekmesi ───────────────────────────────────────

    def _build_dns_tab(self) -> Gtk.ScrolledWindow:
        sw, vbox = self._scrolled_page()

        sc = card(title="MEVCUT DNS")
        sc.append(lbl(DNSMgr.current(), "muted"))
        vbox.append(sc)

        pc = card(title="DNS SEÇENEĞİ")
        self._dns_btns: List[Gtk.CheckButton] = []
        first = None
        for name, (p, s) in DNSMgr.SETS.items():
            rb = Gtk.CheckButton(label=f"{name}   ({p} / {s})")
            if first is None:
                first = rb; rb.set_active(True)
            else:
                rb.set_group(first)
            self._dns_btns.append(rb)
            pc.append(rb)
        vbox.append(pc)

        ac = card(title="İŞLEMLER")
        r = row()
        b1 = btn("DNS Ayarla"); b1.connect("clicked", lambda _: self._dns_set()); r.append(b1)
        b2 = btn("Sıfırla (DHCP)", "btn-danger"); b2.connect("clicked", lambda _: self._dns_reset()); r.append(b2)
        ac.append(r); vbox.append(ac)

        self._dns_log = LogView(140)
        lc = card(title="ÇIKTI"); lc.append(self._dns_log); vbox.append(lc)
        return sw

    def _selected_dns(self) -> Tuple[str, str]:
        names = list(DNSMgr.SETS.keys())
        for i, rb in enumerate(self._dns_btns):
            if rb.get_active():
                return DNSMgr.SETS[names[i]]
        return DNSMgr.SETS["Google + Quad9"]

    def _dns_set(self):
        def t():
            p, s = self._selected_dns()
            self._dns_log.write(f"DNS ayarlanıyor: {p}, {s}…")
            ok, msg = DNSMgr.set(p, s)
            self._dns_log.write(("✓" if ok else "✗") + f" {msg}")
        threading.Thread(target=t, daemon=True).start()

    def _dns_reset(self):
        def t():
            self._dns_log.write("DNS sıfırlanıyor…")
            ok, msg = DNSMgr.reset()
            self._dns_log.write(("✓" if ok else "✗") + f" {msg}")
        threading.Thread(target=t, daemon=True).start()

    # ── Gelişmiş sekmesi ──────────────────────────────────

    def _build_adv_tab(self) -> Gtk.ScrolledWindow:
        sw, vbox = self._scrolled_page()

        sc = card(title="AKTİF SERVİSLER")
        self._adv_buf = Gtk.TextBuffer(); self._adv_buf.set_text("")
        tv = Gtk.TextView(buffer=self._adv_buf, editable=False)
        tv.add_css_class("log-view")
        tv.set_left_margin(8); tv.set_right_margin(8)
        tv.set_top_margin(6); tv.set_bottom_margin(6)
        tv.set_size_request(-1, 100)
        sc.append(tv)
        ref_btn = btn("Yenile"); ref_btn.set_margin_top(8)
        ref_btn.connect("clicked", lambda _: self._adv_refresh())
        sc.append(ref_btn); vbox.append(sc)

        ac = card(title="İŞLEMLER")
        b1 = btn("Tüm Servisleri Kaldır", "btn-danger"); b1.connect("clicked", lambda _: self._adv_remove_all())
        b1.set_margin_bottom(8); ac.append(b1)
        b2 = btn("DNS Sıfırla", "btn-danger"); b2.connect("clicked", lambda _: self._dns_reset()); ac.append(b2)
        vbox.append(ac)

        ic = card(title="GEREKLİ PAKETLER (Arch Linux)")
        ic.append(lbl("sudo pacman -S wireguard-tools nftables\n"
                       "yay -S wgcf byedpi zapret\n\n"
                       "İsteğe bağlı: sudo pacman -S proxychains-ng", "muted"))
        vbox.append(ic)

        self._adv_log = LogView(140)
        lc = card(title="ÇIKTI"); lc.append(self._adv_log); vbox.append(lc)

        self._adv_refresh(); return sw

    def _adv_refresh(self):
        SVCS = {
            "linuxdpi-byedpi":   "ByeDPI",
            "linuxdpi-zapret":   "Zapret",
            "wg-quick@linuxdpi": "WireGuard WARP",
        }
        lines = []
        for svc, label in SVCS.items():
            st = SvcMgr.status(svc)
            if st in ("active", "inactive", "failed"):
                icon = "●" if st == "active" else "○"
                lines.append(f"  {icon} {label} ({svc}): {st}")
        text = "\n".join(lines) if lines else "  Kayıtlı servis bulunamadı."
        GLib.idle_add(self._adv_buf.set_text, text)

    def _adv_remove_all(self):
        dlg = Gtk.MessageDialog(
            transient_for=self,
            modal=True,
            message_type=Gtk.MessageType.WARNING,
            buttons=Gtk.ButtonsType.YES_NO,
            text="Tüm LinuxDPI-TR servisleri kaldırılsın mı?\n"
                 "WireGuard bağlantısı da kesilecektir."
        )
        dlg.connect("response", self._adv_remove_all_cb)
        dlg.show()

    def _adv_remove_all_cb(self, dlg, response):
        dlg.destroy()
        if response != Gtk.ResponseType.YES:
            return
        def t():
            lg = self._adv_log; lg.write("Tüm servisler kaldırılıyor…")
            WGMgr.down()
            for s in ("linuxdpi-byedpi", "linuxdpi-zapret"):
                SvcMgr.remove(s); lg.write(f"✓ {s} kaldırıldı.")
            run_cmd(["systemctl", "disable", "wg-quick@linuxdpi"], sudo=True)
            lg.write("✓ Tamamlandı.")
            self._adv_refresh(); self._wg_refresh()
            self._bd_refresh();   self._zp_refresh()
        threading.Thread(target=t, daemon=True).start()

    # ── Bağımlılık kontrolü ───────────────────────────────

    def _check_deps(self):
        checks = {
            "wireguard-tools": cmd_exists("wg"),
            "wgcf":            cmd_exists("wgcf"),
            "byedpi (ciadpi)": bool(ByeDPIMgr.bin()),
            "zapret (nfqws)":  bool(ZapretMgr.bin()),
            "nftables":        cmd_exists("nft"),
        }
        missing = [k for k, v in checks.items() if not v]
        if missing:
            GLib.idle_add(self._wg_deps_lbl.set_text,
                          "Eksik: " + ", ".join(missing))
            GLib.idle_add(self._wg_deps_lbl.remove_css_class, "muted")
            GLib.idle_add(self._wg_deps_lbl.remove_css_class, "status-ok")
            GLib.idle_add(self._wg_deps_lbl.add_css_class, "status-warn")
            GLib.idle_add(self._deps_install_btn.set_visible, True)
        else:
            GLib.idle_add(self._wg_deps_lbl.set_text, "Tüm bağımlılıklar mevcut ✓")
            GLib.idle_add(self._wg_deps_lbl.remove_css_class, "muted")
            GLib.idle_add(self._wg_deps_lbl.remove_css_class, "status-warn")
            GLib.idle_add(self._wg_deps_lbl.add_css_class, "status-ok")
            GLib.idle_add(self._deps_install_btn.set_visible, False)
        return GLib.SOURCE_REMOVE

    def _install_all_deps(self):
        """Eksik tüm araçları tek seferde otomatik kurar."""
        def t():
            lg = self._wg_log
            lg.write("═══ Eksik araçlar kuruluyor ═══")

            pacman_pkgs = []
            if not cmd_exists("wg"):  pacman_pkgs.append("wireguard-tools")
            if not cmd_exists("nft"): pacman_pkgs.append("nftables")
            if pacman_pkgs:
                lg.write(f"► pacman: {' '.join(pacman_pkgs)}")
                run_stream(["pacman", "-S", "--noconfirm", "--needed"] + pacman_pkgs,
                           lg.write, sudo=True)

            aur_pkgs = []
            if not cmd_exists("wgcf"):    aur_pkgs.append("wgcf")
            if not ByeDPIMgr.bin():       aur_pkgs.append("byedpi")
            if not ZapretMgr.bin():       aur_pkgs.append("zapret")

            if aur_pkgs:
                helper = _aur_helper()
                if helper:
                    for pkg in aur_pkgs:
                        lg.write(f"► AUR: {pkg}")
                        run_stream([helper, "-S", "--noconfirm", "--needed", pkg], lg.write)
                else:
                    lg.write("⚠ AUR yardımcısı bulunamadı – wgcf/byedpi/zapret atlandı.")
                    lg.write("  Kurmak için: sudo pacman -S --needed base-devel git")
                    lg.write("  git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si")

            os.environ["PATH"] = "/usr/bin:/usr/local/bin:" + os.environ.get("PATH", "")
            lg.write("═══ Kurulum tamamlandı ═══")
            self._check_deps()
        threading.Thread(target=t, daemon=True).start()


# ═══════════════════════════════════════════════════════════
# GTK4 Uygulama
# ═══════════════════════════════════════════════════════════

class LinuxDPIApp(Gtk.Application):
    def __init__(self):
        super().__init__(
            application_id=APP_ID,
            flags=Gio.ApplicationFlags.NON_UNIQUE,
        )

    def do_activate(self):
        win = LinuxDPIWindow(self)
        win.present()


def main():
    app = LinuxDPIApp()
    sys.exit(app.run([]))


if __name__ == "__main__":
    main()
