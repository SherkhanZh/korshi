#!/usr/bin/env bash
#
# Korshi — one-time server bootstrap for Ubuntu 22.04.
# Installs Docker Engine + Compose plugin and opens HTTP.
#
# Run ON the server (as root or with sudo):
#   curl -fsSL <repo>/deploy/server-setup.sh | bash
#   # or copy it over and:  bash server-setup.sh

set -euo pipefail

echo "▶ Installing Docker Engine on Ubuntu 22.04…"

sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg ufw

# Docker's official GPG key + repo
sudo install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
fi

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable --now docker

# Firewall: allow SSH + HTTP + HTTPS (skip if ufw inactive / not desired)
sudo ufw allow OpenSSH || true
sudo ufw allow 80/tcp || true
sudo ufw allow 443/tcp || true

# Nightly database backup (03:30 server time). The script lives in the deployed
# tree, so this becomes active after the first deploy/deploy.sh run.
sudo tee /etc/cron.d/korshi-backup > /dev/null <<'CRON'
30 3 * * * root /opt/korshi/deploy/backup.sh >> /var/log/korshi-backup.log 2>&1
CRON
sudo chmod 644 /etc/cron.d/korshi-backup

echo "✓ Docker installed:"
docker --version
docker compose version
echo "✓ Nightly backup cron installed (/etc/cron.d/korshi-backup → /var/backups/korshi)."
echo "✓ Server ready. Now run deploy/deploy.sh from your machine."
