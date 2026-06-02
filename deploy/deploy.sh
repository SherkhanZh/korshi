#!/usr/bin/env bash
#
# Korshi — one-command deploy to a single Ubuntu host.
# Syncs the deployable sources to the server and (re)builds the Docker stack.
#
# Usage:
#   ./deploy/deploy.sh <server-ip> [ssh-user]
#   SERVER_IP=1.2.3.4 SSH_USER=root ./deploy/deploy.sh
#
# Requires on your machine: bash, rsync, ssh.
# Requires on the server:   Docker + Compose plugin (run deploy/server-setup.sh once).

set -euo pipefail

SERVER_IP="${1:-${SERVER_IP:-}}"
SSH_USER="${2:-${SSH_USER:-root}}"
REMOTE_DIR="${REMOTE_DIR:-/opt/korshi}"

if [[ -z "$SERVER_IP" ]]; then
  echo "Usage: ./deploy/deploy.sh <server-ip> [ssh-user]" >&2
  exit 1
fi

# Repo root = parent of this script's dir.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "▶ Deploying Korshi to ${SSH_USER}@${SERVER_IP}:${REMOTE_DIR}"

# 1) Ensure the remote dir exists.
ssh "${SSH_USER}@${SERVER_IP}" "mkdir -p '${REMOTE_DIR}'"

# 2) Sync only what the server needs (panel + backend + compose + deploy).
#    Build artifacts and deps are excluded — Docker rebuilds them on the host.
rsync -az --delete \
  --exclude '.git' \
  --exclude 'node_modules' \
  --exclude 'dist' \
  --exclude 'dist_check' \
  --exclude 'build' \
  --exclude '.dart_tool' \
  --exclude 'apps' \
  --exclude 'packages' \
  docker-compose.yml \
  server \
  web \
  deploy \
  "${SSH_USER}@${SERVER_IP}:${REMOTE_DIR}/"

# 3) Build & (re)start the stack on the server.
ssh "${SSH_USER}@${SERVER_IP}" "cd '${REMOTE_DIR}' && docker compose up -d --build && docker compose ps"

echo "✓ Done. Open:  http://${SERVER_IP}/"
echo "  API health:  http://${SERVER_IP}/api/health"
