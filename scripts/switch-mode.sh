#!/usr/bin/env bash
set -euo pipefail

# Switch modes with one command.
#
# Usage:
#   bash scripts/switch-mode.sh demo
#   bash scripts/switch-mode.sh testnet
#   bash scripts/switch-mode.sh live
#
# Optional:
#   --no-restart   Only write .env + .env.runtime (do not restart containers)

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${APP_DIR}/.env"

PROFILE="${1:-}"
NO_RESTART="${2:-}"

if [[ -z "$PROFILE" ]]; then
  echo "Usage: $0 <demo|testnet|live> [--no-restart]" >&2
  exit 2
fi

case "$PROFILE" in
  demo|testnet|live) ;;
  *)
    echo "ERROR: Invalid profile: $PROFILE (expected demo|testnet|live)" >&2
    exit 2
    ;;
esac

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: Missing $ENV_FILE" >&2
  exit 1
fi

# Normalize CRLF -> LF in-place (harmless if already LF).
sed -i 's/\r$//' "$ENV_FILE"

# Update (or append) CONFIG_PROFILE in .env.
if grep -qE '^[[:space:]]*CONFIG_PROFILE=' "$ENV_FILE"; then
  sed -i "s/^[[:space:]]*CONFIG_PROFILE=.*/CONFIG_PROFILE=${PROFILE}/" "$ENV_FILE"
else
  printf "\nCONFIG_PROFILE=%s\n" "$PROFILE" >>"$ENV_FILE"
fi

echo "==> CONFIG_PROFILE set to: ${PROFILE}"

echo "==> Generating .env.runtime"
bash "${APP_DIR}/scripts/sync-runtime-env.sh"

if [[ "$NO_RESTART" == "--no-restart" ]]; then
  echo "==> Skipping restart (--no-restart)"
  exit 0
fi

echo "==> Restarting containers"
cd "$APP_DIR"
docker compose down
docker compose up -d --build

echo "==> Done. Verify:"
echo "    cat .env.runtime"
echo "    docker compose logs -f --tail=50"

