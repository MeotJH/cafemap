#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults (override via env vars if needed)
BACKEND_HOST="${BACKEND_HOST:-3.36.208.227}"
BACKEND_USER="${BACKEND_USER:-ec2-user}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$ROOT_DIR/../chickenmap/LightsailDefaultKey-ap-northeast-2.pem}"
BACKEND_REMOTE_DIR="${BACKEND_REMOTE_DIR:-/home/ec2-user/cafemap-back}"
BACKEND_CONTAINER_NAME="${BACKEND_CONTAINER_NAME:-cafemap-back}"
BACKEND_IMAGE_NAME="${BACKEND_IMAGE_NAME:-cafemap-back:latest}"
BACKEND_PORT_BIND="${BACKEND_PORT_BIND:-2027:8000}"
BACKEND_PUBLIC_URL="${BACKEND_PUBLIC_URL:-https://cafemap.${BACKEND_HOST}.nip.io}"
UPLOAD_BACKEND_ENV="${UPLOAD_BACKEND_ENV:-false}"

DEPLOY_FRONT=false
DEPLOY_BACK=false

print_usage() {
  cat <<EOF
Usage: ./deploy.sh [--all | --front | --back]

Options:
  --all    Deploy frontend + backend (default)
  --front  Deploy frontend only (Firebase Hosting)
  --back   Deploy backend only (EC2 via SSH)
  -h, --help

Env overrides:
  BACKEND_HOST
  BACKEND_USER
  SSH_KEY_PATH
  BACKEND_REMOTE_DIR
  BACKEND_CONTAINER_NAME
  BACKEND_IMAGE_NAME
  BACKEND_PORT_BIND
  BACKEND_PUBLIC_URL
  UPLOAD_BACKEND_ENV=true  Upload local back/.env to the remote directory
EOF
}

if [[ $# -eq 0 ]]; then
  DEPLOY_FRONT=true
  DEPLOY_BACK=true
else
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        DEPLOY_FRONT=true
        DEPLOY_BACK=true
        shift
        ;;
      --front)
        DEPLOY_FRONT=true
        shift
        ;;
      --back)
        DEPLOY_BACK=true
        shift
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        print_usage
        exit 1
        ;;
    esac
  done
fi

if [[ "$DEPLOY_FRONT" == false && "$DEPLOY_BACK" == false ]]; then
  echo "Nothing to deploy."
  print_usage
  exit 1
fi

deploy_frontend() {
  echo "[deploy] Frontend (Firebase) start"
  cd "$ROOT_DIR/front"
  ./scripts/deploy_web.sh
  echo "[deploy] Frontend done: https://cafemap.web.app"
}

deploy_backend() {
  echo "[deploy] Backend (EC2) start"

  if [[ ! -f "$SSH_KEY_PATH" ]]; then
    echo "SSH key not found: $SSH_KEY_PATH"
    exit 1
  fi

  ssh -i "$SSH_KEY_PATH" "${BACKEND_USER}@${BACKEND_HOST}" \
    "mkdir -p '${BACKEND_REMOTE_DIR}'"

  # 1) Sync code (do not overwrite remote .env and data dir)
  rsync -az --delete \
    -e "ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no" \
    --exclude '.env' \
    --exclude '.venv' \
    --exclude '__pycache__' \
    --exclude '.git' \
    --exclude 'data' \
    --exclude '*.pyc' \
    "$ROOT_DIR/back/" \
    "${BACKEND_USER}@${BACKEND_HOST}:${BACKEND_REMOTE_DIR}/"

  if [[ "$UPLOAD_BACKEND_ENV" == true ]]; then
    if [[ ! -f "$ROOT_DIR/back/.env" ]]; then
      echo "Local backend .env not found: $ROOT_DIR/back/.env"
      exit 1
    fi
    scp -i "$SSH_KEY_PATH" "$ROOT_DIR/back/.env" \
      "${BACKEND_USER}@${BACKEND_HOST}:${BACKEND_REMOTE_DIR}/.env"
  fi

  # 2) Build + restart container
  ssh -i "$SSH_KEY_PATH" "${BACKEND_USER}@${BACKEND_HOST}" "
    set -euo pipefail
    cd '${BACKEND_REMOTE_DIR}'
    if [ ! -f .env ]; then
      echo '[deploy] Missing remote .env. Re-run with UPLOAD_BACKEND_ENV=true or create ${BACKEND_REMOTE_DIR}/.env on the server.'
      exit 1
    fi
    HOST_PORT='${BACKEND_PORT_BIND%%:*}'
    if [ \"\$HOST_PORT\" = \"${BACKEND_PORT_BIND}\" ]; then
      HOST_PORT='${BACKEND_PORT_BIND}'
    fi
    docker build -t '${BACKEND_IMAGE_NAME}' .
    docker rm -f '${BACKEND_CONTAINER_NAME}' || true
    docker run -d \
      --name '${BACKEND_CONTAINER_NAME}' \
      --restart unless-stopped \
      -p '${BACKEND_PORT_BIND}' \
      --env-file .env \
      -v '${BACKEND_REMOTE_DIR}/data:/app/data' \
      '${BACKEND_IMAGE_NAME}'
    HEALTH_URL=\"http://127.0.0.1:\${HOST_PORT}/api/cafemap/rankings\"
    ok=0
    for i in \$(seq 1 20); do
      if curl -fsS \"\${HEALTH_URL}\" >/dev/null; then
        ok=1
        break
      fi
      sleep 1
    done
    if [ \"\$ok\" -ne 1 ]; then
      echo \"[deploy] Health check failed: \${HEALTH_URL}\"
      docker logs --tail 120 '${BACKEND_CONTAINER_NAME}' || true
      exit 1
    fi
    docker ps --filter name='${BACKEND_CONTAINER_NAME}' --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
  "

  echo "[deploy] Backend done: ${BACKEND_PUBLIC_URL}/api/cafemap/rankings"
}

if [[ "$DEPLOY_FRONT" == true ]]; then
  deploy_frontend
fi

if [[ "$DEPLOY_BACK" == true ]]; then
  deploy_backend
fi

echo "[deploy] Completed."
