# Trading Bot Suite (Freqtrade on VPS)

Professional, containerized trading-bot environment for an Ubuntu VPS using **Freqtrade** + **Binance** + **Telegram** with a sample strategy: `TripleGuard`.

## Quick Start (Dry-run)

### 1) Create environment file

From `trading-bot-suite/`:

```bash
cp .env.example .env
```

Edit `.env` with your Binance + Telegram values.

### 2) Choose environment (demo / live / testnet)

Set `CONFIG_PROFILE` in `.env`:
- `demo` (recommended): dry-run on real market data
- `live`: real trading (high risk)
- `testnet`: Binance sandbox (paper environment using testnet keys)

Also change:
- `api_server.jwt_secret_key`
- `api_server.ws_token`

### 3) Start the bot

```bash
docker compose up -d
```

### 4) View logs

```bash
docker compose logs -f --tail=200
```

### 5) Verify strategy is loaded

The container is started with:
- `--strategy TripleGuard`
- config at `user_data/config.json` (with environment overrides based on `CONFIG_PROFILE`)

You should see the strategy name in startup output.

## Persistence

All persistent state is stored under `user_data/` and mounted into the container:
- `user_data/strategies`: strategies
- `user_data/data`: OHLCV / downloaded market data
- `user_data/logs`: bot logs
- `user_data/notebooks`: research notebooks

## Documentation (Required Phases)

- `docs/PHASE_01_INFRA.md`
- `docs/PHASE_02_STRATEGY.md`
- `docs/PHASE_03_TELEGRAM_BOT.md`
- `docs/PHASE_04_OPERATION.md`

## Safety

This suite starts in **dry-run** by default (`"dry_run": true`).
Do not enable live trading until you’ve validated behavior in dry-run, and you understand exchange/API/strategy risks.
