#!/usr/bin/env bash
set -euo pipefail

echo "=== GEEKOM A9 Mega: Never-Sleep + Recovery Fix ==="

echo "[1] Suspend/Hibernate/Sleep blockieren"
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

echo "[2] systemd logind: keine Schlafreaktion"
sudo mkdir -p /etc/systemd/logind.conf.d
sudo tee /etc/systemd/logind.conf.d/99-never-sleep.conf >/dev/null <<'CONF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
CONF

echo "[3] Kernel Panic Auto-Reboot"
sudo tee /etc/sysctl.d/99-auto-reboot.conf >/dev/null <<'CONF'
kernel.panic = 10
kernel.panic_on_oops = 1
# vm.panic_on_oom bleibt 0 — OOM-Killer erledigt das schonender als sofortiger Reboot
CONF
sudo sysctl --system >/dev/null

echo "[4] tailscaled Auto-Restart härten"
sudo mkdir -p /etc/systemd/system/tailscaled.service.d
sudo tee /etc/systemd/system/tailscaled.service.d/override.conf >/dev/null <<'CONF'
[Service]
Restart=always
RestartSec=5
StartLimitIntervalSec=0
CONF

echo "[5] SSH Auto-Restart härten"
sudo mkdir -p /etc/systemd/system/ssh.service.d
sudo tee /etc/systemd/system/ssh.service.d/override.conf >/dev/null <<'CONF'
[Service]
Restart=always
RestartSec=5
StartLimitIntervalSec=0
CONF

echo "[6] systemd reload + Dienste neu starten"
sudo systemctl daemon-reload
sudo systemctl restart systemd-logind || true
sudo systemctl restart tailscaled
sudo systemctl restart ssh

echo "[7] Status"
systemctl is-enabled sleep.target suspend.target hibernate.target hybrid-sleep.target || true
systemctl is-active tailscaled ssh
tailscale ip -4 || true

echo "DONE: GEEKOM schläft nicht mehr; Tailscale/SSH starten automatisch neu."
