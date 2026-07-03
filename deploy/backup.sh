#!/usr/bin/env bash
#
# Korshi — nightly backup of the SQLite database and uploaded files.
# Runs ON the server (installed as a cron job by server-setup.sh):
#   30 3 * * * root /opt/korshi/deploy/backup.sh
#
# What it does:
#   1. Takes a consistent snapshot of the live DB with `VACUUM INTO` (safe
#      while the API is running — no downtime, no partial writes).
#   2. Copies the snapshot + a tarball of data/uploads to $BACKUP_DIR.
#   3. Gzips everything and deletes backups older than $KEEP_DAYS days.
#
# Restore (DB): gunzip the snapshot, stop the stack, replace korshi.db inside
# the korshi_data volume, start the stack.

set -euo pipefail

COMPOSE_DIR="${COMPOSE_DIR:-/opt/korshi}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/korshi}"
KEEP_DAYS="${KEEP_DAYS:-30}"

cd "$COMPOSE_DIR"

# Use the same stack deploy.sh chose (HTTPS when .env has a DOMAIN).
COMPOSE_FILE="docker-compose.yml"
if grep -qs '^DOMAIN=' .env; then COMPOSE_FILE="docker-compose.https.yml"; fi

mkdir -p "$BACKUP_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"

# 1) Consistent DB snapshot inside the api container (node:sqlite, VACUUM INTO).
docker compose -f "$COMPOSE_FILE" exec -T api node -e "
  const { DatabaseSync } = require('node:sqlite');
  const fs = require('fs');
  const tmp = '/app/data/.backup-tmp.db';
  if (fs.existsSync(tmp)) fs.unlinkSync(tmp);
  const db = new DatabaseSync('/app/data/korshi.db', { readOnly: true });
  db.exec(\"VACUUM INTO '\" + tmp + \"'\");
  db.close();
"

# 2) Copy the snapshot out of the container, then remove the temp file.
docker compose -f "$COMPOSE_FILE" cp api:/app/data/.backup-tmp.db "$BACKUP_DIR/korshi-$STAMP.db"
docker compose -f "$COMPOSE_FILE" exec -T api rm -f /app/data/.backup-tmp.db
gzip "$BACKUP_DIR/korshi-$STAMP.db"

# 3) Uploaded files (report photos + covers), if any.
if docker compose -f "$COMPOSE_FILE" exec -T api test -d /app/data/uploads; then
  docker compose -f "$COMPOSE_FILE" exec -T api tar -C /app/data -cf - uploads \
    | gzip > "$BACKUP_DIR/uploads-$STAMP.tar.gz"
fi

# 4) Rotate.
find "$BACKUP_DIR" -name '*.gz' -mtime "+$KEEP_DAYS" -delete

echo "[$(date -Is)] backup ok → $BACKUP_DIR/korshi-$STAMP.db.gz"
