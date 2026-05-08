# PHASE 03 — Telegram Integration (BotFather + Chat ID)

## Create a Telegram bot

1. Open Telegram and search for **BotFather**.
2. Start a chat with BotFather and run:
   - `/newbot`
3. Choose:
   - Bot name (human-readable)
   - Bot username (must end with `bot`)
4. BotFather will return a **Bot Token** (keep it secret).

Put it into:
- `.env` as `TELEGRAM_BOT_TOKEN=...`
- and/or `user_data/config.json` under `telegram.token`

## Retrieve your Chat ID

Freqtrade needs a chat ID where it can send messages.

### Option A (simple): use `@userinfobot`

1. Search Telegram for `@userinfobot`
2. Start it, and it will show your **user ID** (often usable as `chat_id` for direct messages).

### Option B (for groups): add the bot to a group and get the group ID

1. Create a Telegram group.
2. Add your newly created bot to that group.
3. Send a message in the group.
4. Use one of these methods to fetch the group chat ID:
   - Use a “get updates” method with the Telegram API
   - Or use a helper bot/service that displays group IDs

Common pattern: group IDs are negative numbers (e.g. `-1001234567890`).

## Configure Freqtrade

In `user_data/config.json`:

- `telegram.enabled`: `true`
- `telegram.token`: your bot token
- `telegram.chat_id`: your user ID or group chat ID

## Quick validation checklist

- Bot token is correct
- Chat ID is correct
- The bot has permission to message the chat/group
- You restarted the container after changes:

```bash
docker compose restart
docker compose logs -f --tail=200
```
