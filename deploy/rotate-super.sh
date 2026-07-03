#!/usr/bin/env bash
#
# Korshi — rotate the super admin's email and/or password on a running server.
# Run ON the server (from the compose dir), or via SSH from your machine.
#
# Usage:
#   ./deploy/rotate-super.sh                      # prompts for a new password
#   NEW_PW='strong-pass' ./deploy/rotate-super.sh # non-interactive
#   NEW_EMAIL='me@korshi.kz' NEW_PW='...' ./deploy/rotate-super.sh
#
# Notes:
#   • Password must be at least 8 characters.
#   • If no super admin row exists yet, one is created.
#   • Takes effect immediately; existing super-admin tokens stay valid until
#     they expire (there is no server-side revocation), so rotate when you
#     suspect the old password leaked and consider restarting the API too.

set -euo pipefail

COMPOSE_DIR="${COMPOSE_DIR:-/opt/korshi}"
cd "$COMPOSE_DIR"

# Match the stack deploy.sh uses (HTTPS when .env declares a DOMAIN).
COMPOSE_FILE="docker-compose.yml"
if grep -qs '^DOMAIN=' .env 2>/dev/null; then COMPOSE_FILE="docker-compose.https.yml"; fi

NEW_EMAIL="${NEW_EMAIL:-}"
NEW_PW="${NEW_PW:-}"

if [[ -z "$NEW_PW" ]]; then
  read -rs -p "New super admin password (min 8 chars): " NEW_PW; echo
  read -rs -p "Repeat password: " NEW_PW2; echo
  if [[ "$NEW_PW" != "$NEW_PW2" ]]; then
    echo "Passwords do not match." >&2; exit 1
  fi
fi

if [[ "${#NEW_PW}" -lt 8 ]]; then
  echo "Password must be at least 8 characters." >&2; exit 1
fi

# Run the update inside the api container (has node:sqlite + bcryptjs).
NEW_EMAIL="$NEW_EMAIL" NEW_PW="$NEW_PW" \
docker compose -f "$COMPOSE_FILE" exec -T \
  -e NEW_EMAIL="$NEW_EMAIL" -e NEW_PW="$NEW_PW" \
  api node -e '
    const { DatabaseSync } = require("node:sqlite");
    const bcrypt = require("bcryptjs");
    const db = new DatabaseSync("/app/data/korshi.db");
    const hash = bcrypt.hashSync(process.env.NEW_PW, 10);
    const email = (process.env.NEW_EMAIL || "").trim().toLowerCase();
    const existing = db.prepare("SELECT id, email FROM admins WHERE role=\x27super\x27").get();
    if (existing) {
      if (email) {
        db.prepare("UPDATE admins SET password_hash=?, email=? WHERE id=?").run(hash, email, existing.id);
      } else {
        db.prepare("UPDATE admins SET password_hash=? WHERE id=?").run(hash, existing.id);
      }
      console.log("Super admin updated:", email || existing.email);
    } else {
      const e = email || "superadmin@korshi.kz";
      db.prepare("INSERT INTO admins (email,password_hash,role,neighborhood_id) VALUES (?,?,?,?)")
        .run(e, hash, "super", null);
      console.log("Super admin created:", e);
    }
    db.close();
  '

echo "✓ Done. Log in with the new credentials."
