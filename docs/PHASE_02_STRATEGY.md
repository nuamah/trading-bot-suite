# PHASE 02 — Strategy (Triple-Guard)

## Overview

`TripleGuard` is a conservative, rules-based long-only strategy designed to reduce impulsive over-trading by combining:

- **Mean-reversion trigger** (Bollinger Bands)
- **Momentum confirmation** (MACD histogram > 0)
- **Oversold filter** (RSI < 30)
- **Post-loss cooldown** (StoplossGuard protection)

Timeframe is `5m` by default.

## Indicators

### RSI (14)

- Computation: RSI with period 14
- Purpose: detect oversold (<30) / overbought (>70)

### MACD (12, 26, 9)

- fast: 12
- slow: 26
- signal: 9
- We use **MACD histogram** (`macdhist`) and require **> 0** for buys.

Interpretation:
- `macdhist > 0` implies MACD line is above signal (bullish momentum bias).

### Bollinger Bands (20, 2σ)

- period: 20
- deviations: 2
- Uses:
  - Lower band for buy trigger (price “overshoot”)
  - Upper band for sell trigger (price “overextension”)

## Entry rule (Buy)

A buy is triggered when **all** of the following are true on the same candle:

- `close < bb_lower`
- `rsi < 30`
- `macdhist > 0`

Intent:
- Price is temporarily below its statistical envelope (BB lower),
- RSI suggests oversold,
- MACD histogram ensures you’re not catching a falling knife without a momentum turn.

## Exit rule (Sell)

An exit is triggered when **either** is true:

- `close > bb_upper` **OR**
- `rsi > 70`

Intent:
- Take profit into strength / overextension.

## Safeguard: “Cooldown after loss”

This strategy activates Freqtrade protections:

- **StoplossGuard**: if a losing trade occurred recently, block new trades for a cooldown window.
  - lookback: 48 candles
  - trade_limit: 1 losing trade
  - stop_duration: 24 candles (no new entries)
- **CooldownPeriod**: short general cooldown between trades (3 candles).

Why it matters:
- Helps avoid rapid re-entry after a stoploss / losing trade (“revenge trading” behavior).
- Adds time for market regime to stabilize before the next attempt.

## Expected behavior

- In ranging markets: should find “snapback” opportunities off the lower band, but will avoid entries when momentum is still negative.
- In strong downtrends: fewer entries due to `macdhist > 0` requirement; losses should trigger cooldown and reduce churn.
- In strong uptrends: exits may happen frequently on BB upper / RSI > 70; consider tuning ROI/exit logic if you want trend-following behavior.

## Tuning knobs (most impactful)

- **Timeframe**: `5m` → less noise at `15m`, more signals at `1m`.
- **StoplossGuard** durations: longer for higher protection, shorter for higher activity.
- **BB period/dev**: tighter bands increase signals, wider bands reduce signals.
