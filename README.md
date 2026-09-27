# Next Candle NR for MT4

`NextCandleNR.mq4` is a confirmed-bar rewrite of the candle/volume idea shown in the supplied image.

## Important limitation

No indicator can guarantee a high-accuracy prediction of the next candle. This version is designed to prevent historical signal changes (repainting), not to guarantee profitable trades.

## Why it does not repaint

- It never plots on bar `0`, which is the live candle.
- Signals are evaluated on bar `1`, the most recently closed candle.
- It uses only the signal candle and older candles (`i` and `i+1`).
- It does not use ZigZag, centered indicators, future bars, or negative shifts.
- Alerts are generated once, when a new closed-bar signal is detected.

A signal can appear only after the candle has closed. That is the trade-off for non-repainting behavior.

## Filters

- **VolumeMAPeriod / UseVolumeFilter:** compares closed-candle tick volume with an older volume average.
- **TrendMAPeriod / UseTrendFilter:** optional EMA direction filter.
- **MinimumBodyPercent:** rejects candles whose body is too small relative to their full range. Set to `0` to disable.
- **ATRPeriod / ArrowATRDistance:** controls arrow spacing only; ATR does not predict direction.

MT4 spot-FX usually provides tick volume rather than centralized exchange volume, so the volume filter should be tested separately for each broker and symbol.

## Installation

1. In MT4, select **File → Open Data Folder**.
2. Open `MQL4/Indicators`.
3. Copy `NextCandleNR.mq4` there.
4. Open MetaEditor, compile the file, and check the **Errors** tab.
5. Restart or refresh the Navigator and attach the indicator to a chart.

Backtest with visual mode and compare signals after refreshing the chart. Always test on demo data first; historical non-repainting behavior does not remove market risk.
