#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v firebase >/dev/null 2>&1; then
  echo "firebase CLI is not installed. Install with: npm i -g firebase-tools"
  exit 1
fi

if command -v fvm >/dev/null 2>&1; then
  FLUTTER_CMD="fvm flutter"
elif command -v flutter >/dev/null 2>&1; then
  FLUTTER_CMD="flutter"
else
  echo "flutter is not installed or not in PATH."
  exit 1
fi

if [[ ! -f ".env.production" ]]; then
  echo ".env.production not found."
  echo "Copy .env.production.example to .env.production and set real values."
  exit 1
fi

cp .env.production .env
$FLUTTER_CMD pub get
$FLUTTER_CMD build web --release --pwa-strategy=none
firebase deploy --only hosting
