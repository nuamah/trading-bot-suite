#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/vps-deploy.sh /opt/trading-bot-suite
#
# Assumptions:
# - This repo is cloned on the VPS at the given path
# - A real .env exists on the VPS (never commit it)
# - Docker Engine + docker compose plugin are installed

APP_DIR="${1:-/opt/trading-bot-suite}"

if [[ ! -d "$APP_DIR" ]]; then
  echo "ERROR: directory does not exist: $APP_DIR" >&2
  exit 1
fi

cd "$APP_DIR"

echo "==> Updating repo"
git fetch --prune
git pull --ff-only

if [[ ! -f ".env" ]]; then
  echo "ERROR: missing .env in $APP_DIR" >&2
  echo "Copy .env.example to .env on the VPS and fill real values." >&2
  exit 1
fi

echo "==> Syncing runtime environment (.env.runtime)"
bash "./scripts/sync-runtime-env.sh"

echo "==> Pull/build/restart containers"
docker compose pull || true
docker compose up -d --build

echo "==> Done. Recent logs:"
docker compose logs -f --tail=50

