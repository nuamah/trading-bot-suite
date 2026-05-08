from __future__ import annotations

from functools import reduce
from typing import Any

import talib.abstract as ta
from freqtrade.strategy import IStrategy, informative
from pandas import DataFrame


class TripleGuard(IStrategy):
    """
    Triple-Guard Strategy
    - Buy (frequency-tuned): close <= BB lower * 1.003 AND RSI(14) < 33 AND MACD histogram > 0
    - Sell: close > BB upper OR RSI(14) > 70
    - Safeguard: post-loss cooldown via StoplossGuard protection
    """

    timeframe = "5m"

    can_short = False
    process_only_new_candles = True
    startup_candle_count = 50

    # Risk management (bot-level config can override these)
    stoploss = -0.01
    trailing_stop = True
    trailing_stop_positive = 0.005
    trailing_stop_positive_offset = 0.01
    trailing_only_offset_is_reached = True

    minimal_roi: dict[str, float] = {"0": 0.005}

    # Cooldown after a loss to reduce "revenge trading"
    # This is enforced by Freqtrade's protection system.
    @property
    def protections(self) -> list[dict[str, Any]]:
        return [
            # After any losing trade, pause trading for this duration (global)
            {
                "method": "StoplossGuard",
                "lookback_period_candles": 48,
                "trade_limit": 1,
                "stop_duration_candles": 24,
                "only_per_pair": False
            },
            # General cooldown between trades (helps reduce churn)
            {
                "method": "CooldownPeriod",
                "stop_duration_candles": 3
            }
        ]

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe["rsi"] = ta.RSI(dataframe, timeperiod=14)

        macd = ta.MACD(dataframe, fastperiod=12, slowperiod=26, signalperiod=9)
        dataframe["macd"] = macd["macd"]
        dataframe["macdsignal"] = macd["macdsignal"]
        dataframe["macdhist"] = macd["macdhist"]

        bb = ta.BBANDS(dataframe, timeperiod=20, nbdevup=2.0, nbdevdn=2.0, matype=0)
        dataframe["bb_upper"] = bb["upperband"]
        dataframe["bb_middle"] = bb["middleband"]
        dataframe["bb_lower"] = bb["lowerband"]

        return dataframe

    @informative("1h")
    def populate_indicators_1h(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe["ema200"] = ta.EMA(dataframe, timeperiod=200)
        dataframe["rsi"] = ta.RSI(dataframe, timeperiod=14)
        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        conditions = []

        # Regime filter: avoid catching falling knives.
        # Only take mean-reversion entries when 1h trend is not bearish.
        conditions.append(dataframe["close_1h"] > dataframe["ema200_1h"])
        conditions.append(dataframe["rsi_1h"] > 40)

        conditions.append(dataframe["close"] <= (dataframe["bb_lower"] * 1.003))
        conditions.append(dataframe["rsi"] < 33)
        conditions.append(dataframe["macdhist"] > 0)

        if conditions:
            dataframe.loc[
                reduce(lambda x, y: x & y, conditions),
                "enter_long",
            ] = 1

        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        sell_condition = (
            (dataframe["close"] > dataframe["bb_upper"])
            | (dataframe["rsi"] > 70)
        )

        dataframe.loc[sell_condition, "exit_long"] = 1
        return dataframe
