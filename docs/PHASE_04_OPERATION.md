# PHASE 04 — Operations (Run / Logs / Dry-run → Live)

## Start / Stop

From `trading-bot-suite/`:

```bash
docker compose up -d
docker compose ps
```

## Select execution profile (demo / live / testnet)

This suite selects an execution profile via `.env`:

- `CONFIG_PROFILE=demo`
  - **dry-run** enabled (no real orders)
  - uses `BINANCE_DEMO_API_KEY` / `BINANCE_DEMO_API_SECRET` (keys optional in dry-run)
  - `sandbox` disabled
- `CONFIG_PROFILE=live`
  - **live trading** enabled (real orders)
  - uses `BINANCE_LIVE_API_KEY` / `BINANCE_LIVE_API_SECRET`
  - `sandbox` disabled
- `CONFIG_PROFILE=testnet`
  - **testnet trading** (real orders on sandbox, not real funds)
  - uses `BINANCE_TESTNET_API_KEY` / `BINANCE_TESTNET_API_SECRET`
  - `sandbox` enabled

After changing `CONFIG_PROFILE`, restart the container:

```bash
docker compose down
docker compose up -d
```

Stop:

```bash
docker compose down
```

Restart:

```bash
docker compose restart
```

## Logs

Tail logs:

```bash
docker compose logs -f --tail=200
```

## Shell into the container (optional)

```bash
docker compose exec freqtrade bash
```

## Download market data (recommended for backtesting)

Example:

```bash
docker compose run --rm freqtrade download-data --exchange binance --timeframes 5m --pairs BTC/USDT ETH/USDT
```

Data persists under `user_data/data/`.

## Run backtests (optional but recommended)

```bash
docker compose run --rm freqtrade backtesting --config /freqtrade/user_data/config.json --strategy TripleGuard
```

## Dry-run → Live trading (high risk)

1. Validate in dry-run first:
   - Telegram messages are working
   - Entries/exits look sane
   - Max open trades is respected
   - Stoploss and trailing behavior is understood

2. Switch to live:
   - Edit `.env`
   - Set `CONFIG_PROFILE=live`
   - Ensure Binance keys are **real** and have the correct permissions

3. Restart:

```bash
docker compose down
docker compose up -d
docker compose logs -f --tail=200
```

## Common operational checks

- **Strategy loaded**: look for `TripleGuard` in logs at startup.
- **Permissions**: `user_data/` must be writable by the container.
- **Time sync**: ensure VPS clock is correct (NTP enabled).
- **Security**: keep API server restricted; rotate secrets if exposed.
