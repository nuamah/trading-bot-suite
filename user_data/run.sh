#!/usr/bin/env bash
set -euo pipefail

PROFILE="${CONFIG_PROFILE:-demo}"

case "$PROFILE" in
  demo)
    DRY_RUN=true
    SANDBOX=false
    API_KEY="${BINANCE_DEMO_API_KEY:-}"
    API_SECRET="${BINANCE_DEMO_API_SECRET:-}"
    SRC_CONFIG="/freqtrade/user_data/config.json"
    ;;
  live)
    DRY_RUN=false
    SANDBOX=false
    API_KEY="${BINANCE_LIVE_API_KEY:-}"
    API_SECRET="${BINANCE_LIVE_API_SECRET:-}"
    SRC_CONFIG="/freqtrade/user_data/config.json"
    ;;
  testnet)
    DRY_RUN=false
    SANDBOX=true
    API_KEY="${BINANCE_TESTNET_API_KEY:-}"
    API_SECRET="${BINANCE_TESTNET_API_SECRET:-}"
    SRC_CONFIG="/freqtrade/user_data/config.json"
    ;;
  futures)
    DRY_RUN=true
    SANDBOX=false
    API_KEY="${BINANCE_FUTURES_API_KEY:-${BINANCE_LIVE_API_KEY:-}}"
    API_SECRET="${BINANCE_FUTURES_API_SECRET:-${BINANCE_LIVE_API_SECRET:-}}"
    SRC_CONFIG="/freqtrade/user_data/config.futures.json"
    ;;
  *)
    echo "Unknown CONFIG_PROFILE=$PROFILE. Use: demo | live | testnet | futures" >&2
    exit 2
    ;;
esac

export DRY_RUN SANDBOX API_KEY API_SECRET
export SRC_CONFIG

python3 - <<'PY'
import json
import os

src = "/freqtrade/user_data/config.json"
dst = "/tmp/freqtrade-config.json"

src = os.environ.get("SRC_CONFIG", src)
with open(src, "r", encoding="utf-8") as f:
    cfg = json.load(f)

def b(v: str) -> bool:
    return str(v).strip().lower() in ("1", "true", "yes", "y", "on")

dry_run = b(os.environ.get("DRY_RUN", "true"))
sandbox = b(os.environ.get("SANDBOX", "false"))

cfg["dry_run"] = dry_run
cfg.setdefault("exchange", {})
cfg["exchange"]["sandbox"] = sandbox
cfg["exchange"]["key"] = os.environ.get("API_KEY", "")
cfg["exchange"]["secret"] = os.environ.get("API_SECRET", "")

cfg.setdefault("telegram", {})
cfg["telegram"]["enabled"] = True
cfg["telegram"]["token"] = os.environ.get("TELEGRAM_BOT_TOKEN", "")
cfg["telegram"]["chat_id"] = os.environ.get("TELEGRAM_CHAT_ID", "")

with open(dst, "w", encoding="utf-8") as f:
    json.dump(cfg, f, indent=2)

print(f"Wrote {dst} (dry_run={dry_run}, sandbox={sandbox})")
PY

exec freqtrade trade --config /tmp/freqtrade-config.json --strategy TripleGuard

