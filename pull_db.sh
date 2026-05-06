#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BACKEND_HOST="${BACKEND_HOST:-13.124.77.254}"
BACKEND_USER="${BACKEND_USER:-ec2-user}"
BACKEND_REMOTE_DIR="${BACKEND_REMOTE_DIR:-/home/ec2-user/cafemap-back}"
REMOTE_DB_FILE="${REMOTE_DB_FILE:-cafemap.db}"
LOCAL_DB_PATH="${LOCAL_DB_PATH:-$ROOT_DIR/back/data/cafemap.db}"

DEFAULT_KEY_IN_REPO="$ROOT_DIR/LightsailDefaultKey-ap-northeast-2.pem"
DEFAULT_KEY_LEGACY="$ROOT_DIR/../chickenmap/LightsailDefaultKey-ap-northeast-2.pem"
if [[ -f "$DEFAULT_KEY_IN_REPO" ]]; then
  SSH_KEY_PATH_DEFAULT="$DEFAULT_KEY_IN_REPO"
else
  SSH_KEY_PATH_DEFAULT="$DEFAULT_KEY_LEGACY"
fi
SSH_KEY_PATH="${SSH_KEY_PATH:-$SSH_KEY_PATH_DEFAULT}"

print_usage() {
  cat <<EOF
Usage: ./pull_db.sh

Downloads server DB into local back/data/cafemap.db.
Before overwrite, creates local backup:
  back/data/cafemap.db.localbak_YYYYmmddHHMMSS

Env overrides:
  BACKEND_HOST
  BACKEND_USER
  SSH_KEY_PATH
  BACKEND_REMOTE_DIR
  REMOTE_DB_FILE
  LOCAL_DB_PATH
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_usage
  exit 0
fi

if [[ ! -f "$SSH_KEY_PATH" ]]; then
  echo "[pull-db] SSH key not found: $SSH_KEY_PATH"
  exit 1
fi

mkdir -p "$(dirname "$LOCAL_DB_PATH")"

if [[ -f "$LOCAL_DB_PATH" ]]; then
  ts="$(date +%Y%m%d%H%M%S)"
  backup_path="${LOCAL_DB_PATH}.localbak_${ts}"
  cp "$LOCAL_DB_PATH" "$backup_path"
  echo "[pull-db] Backup created: $backup_path"
else
  echo "[pull-db] Local DB does not exist yet. A new file will be created."
fi

remote_db_path="${BACKEND_REMOTE_DIR}/data/${REMOTE_DB_FILE}"
echo "[pull-db] Pulling: ${BACKEND_USER}@${BACKEND_HOST}:${remote_db_path}"

scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no \
  "${BACKEND_USER}@${BACKEND_HOST}:${remote_db_path}" \
  "$LOCAL_DB_PATH"

echo "[pull-db] Download complete: $LOCAL_DB_PATH"

if command -v sqlite3 >/dev/null 2>&1; then
  integrity="$(sqlite3 "$LOCAL_DB_PATH" 'PRAGMA integrity_check;' || true)"
  echo "[pull-db] sqlite integrity_check: ${integrity:-unknown}"
elif command -v python3 >/dev/null 2>&1; then
  python3 - "$LOCAL_DB_PATH" <<'PY'
import sqlite3
import sys
p = sys.argv[1]
con = sqlite3.connect(p)
try:
    row = con.execute("PRAGMA integrity_check").fetchone()
    print(f"[pull-db] sqlite integrity_check: {row[0] if row else 'unknown'}")
finally:
    con.close()
PY
elif command -v python >/dev/null 2>&1; then
  python - "$LOCAL_DB_PATH" <<'PY'
import sqlite3
import sys
p = sys.argv[1]
con = sqlite3.connect(p)
try:
    row = con.execute("PRAGMA integrity_check").fetchone()
    print(f"[pull-db] sqlite integrity_check: {row[0] if row else 'unknown'}")
finally:
    con.close()
PY
else
  echo "[pull-db] sqlite integrity check skipped (sqlite3/python not found)."
fi

echo "[pull-db] Done."
