//+------------------------------------------------------------------+
//|                                      NextCandleNR.mq4             |
//| Confirmed-bar, non-repainting candle/volume indicator for MT4    |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 clrLimeGreen
#property indicator_color2 clrTomato
#property indicator_width1 1
#property indicator_width2 1
#property indicator_style1 STYLE_SOLID
#property indicator_style2 STYLE_SOLID

input int      VolumeMAPeriod       = 20;
input bool     UseVolumeFilter      = true;
input int      TrendMAPeriod        = 50;
input bool     UseTrendFilter       = true;
input int      ATRPeriod            = 14;
input double   ArrowATRDistance     = 0.25;
input double   MinimumBodyPercent   = 0.0;
input bool     EnableAlerts         = false;
input bool     AlertOnPopup          = true;
input bool     AlertOnSound          = false;
input string   AlertSoundFile       = "alert.wav";

// These buffers are plotted only on confirmed (closed) candles.
double BuyBuffer[];
double SellBuffer[];

datetime LastAlertBar = 0;

int OnInit()
{
   IndicatorBuffers(2);
   SetIndexBuffer(0, BuyBuffer);
   SetIndexStyle(0, DRAW_ARROW, STYLE_SOLID, 1, clrLimeGreen);
   SetIndexArrow(0, 233);
   SetIndexLabel(0, "BUY (confirmed)");
   SetIndexEmptyValue(0, EMPTY_VALUE);

   SetIndexBuffer(1, SellBuffer);
   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 1, clrTomato);
   SetIndexArrow(1, 234);
   SetIndexLabel(1, "SELL (confirmed)");
   SetIndexEmptyValue(1, EMPTY_VALUE);

   ArraySetAsSeries(BuyBuffer, true);
   ArraySetAsSeries(SellBuffer, true);
   IndicatorShortName("Next Candle NR (confirmed bars)");
   return(INIT_SUCCEEDED);
}

// Average tick volume of the current bar and older bars. Tick volume is
// used because it is available consistently in MT4 spot-FX feeds.
double AverageTickVolume(const long &tick_volume[], const int shift, const int period, const int rates_total)
{
   if(period <= 0 || shift + period > rates_total)
      return(0.0);

   double sum = 0.0;
   for(int j = 0; j < period; j++)
      sum += (double)tick_volume[shift + j];
   return(sum / period);
}

bool BodyIsLargeEnough(const int shift, const double &open[], const double &close[], const double &high[], const double &low[])
{
   if(MinimumBodyPercent <= 0.0)
      return(true);

   double range = high[shift] - low[shift];
   if(range <= 0.0)
      return(false);
   return(MathAbs(close[shift] - open[shift]) / range * 100.0 >= MinimumBodyPercent);
}

void ProcessAlert(const datetime bar_time, const bool buy, const bool sell)
{
   if(!EnableAlerts || bar_time == LastAlertBar || (!buy && !sell))
      return;

   LastAlertBar = bar_time;
   string direction = buy ? "BUY" : "SELL";
   string text = Symbol() + " " + IntegerToString(Period()) +
                 ": confirmed " + direction + " signal on closed candle";
   if(AlertOnPopup)
      Alert(text);
   if(AlertOnSound)
      PlaySound(AlertSoundFile);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int minimum_bars = MathMax(VolumeMAPeriod, TrendMAPeriod) + 3;
   if(rates_total <= minimum_bars)
      return(0);

   // Recalculate all eligible historical bars. This is deliberately simple
   // and safe; it does not use future bars or change closed-bar signals.
   int first = rates_total - MathMax(VolumeMAPeriod, TrendMAPeriod) - 2;
   if(first < 1)
      first = 1;

   for(int i = first; i >= 1; i--)
   {
      BuyBuffer[i] = EMPTY_VALUE;
      SellBuffer[i] = EMPTY_VALUE;

      // i is the signal candle; i+1 is the immediately preceding candle.
      bool bullish_reversal = close[i] > open[i] &&
                              close[i + 1] < open[i + 1] &&
                              close[i] > open[i + 1];
      bool bearish_reversal = close[i] < open[i] &&
                              close[i + 1] > open[i + 1] &&
                              close[i] < open[i + 1];

      if(!BodyIsLargeEnough(i, open, close, high, low))
         continue;

      bool volume_ok = true;
      if(UseVolumeFilter)
      {
         double average_volume = AverageTickVolume(tick_volume, i + 1, VolumeMAPeriod, rates_total);
         volume_ok = average_volume > 0.0 && (double)tick_volume[i] > average_volume;
      }

      bool trend_ok_buy = true;
      bool trend_ok_sell = true;
      if(UseTrendFilter)
      {
         double ema = iMA(NULL, 0, TrendMAPeriod, 0, MODE_EMA, PRICE_CLOSE, i);
         trend_ok_buy = close[i] > ema;
         trend_ok_sell = close[i] < ema;
      }

      double atr = iATR(NULL, 0, ATRPeriod, i);
      if(atr <= 0.0)
         atr = high[i] - low[i];
      double distance = MathMax(Point * 2.0, atr * ArrowATRDistance);

      bool buy = bullish_reversal && volume_ok && trend_ok_buy;
      bool sell = bearish_reversal && volume_ok && trend_ok_sell;
      if(buy)
         BuyBuffer[i] = low[i] - distance;
      if(sell)
         SellBuffer[i] = high[i] + distance;

      if(i == 1)
         ProcessAlert(time[i], buy, sell);
   }

   // Never draw a signal on the live, still-forming candle.
   BuyBuffer[0] = EMPTY_VALUE;
   SellBuffer[0] = EMPTY_VALUE;
   return(rates_total);
}
//+------------------------------------------------------------------+
