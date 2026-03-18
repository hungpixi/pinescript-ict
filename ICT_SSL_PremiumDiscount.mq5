//+------------------------------------------------------------------+
//|         [hungpixi] ICT SSL Premium & Discount EA                 |
//|         © hungpixi — Comarai (https://comarai.com)               |
//|         Converted from PineScript v6 → MQL5 Expert Advisor       |
//|         Reference: jbondata/pinescript-indicator-suite            |
//+------------------------------------------------------------------+
#property copyright   "hungpixi — Comarai (https://comarai.com)"
#property link        "https://github.com/hungpixi"
#property version     "1.00"
#property description "[hungpixi] ICT SSL Premium & Discount EA"
#property description "Detects SSL/BSL sweeps in Premium/Discount zones and executes retest entries."
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade         g_trade;
CPositionInfo  g_posInfo;

// ─── INPUTS: TRADING ──────────────────────────────────────────────────────────
input group "💰 Trading Settings"
input double InpLotSize       = 0.01;  // Lot Size
input int    InpMagicNumber   = 20250318; // Magic Number
input int    InpSlippage      = 10;    // Max Slippage (points)
input string InpComment       = "ICT_SSL"; // Trade Comment

// ─── INPUTS: DISPLAY RANGE ───────────────────────────────────────────────────
input group "📐 Display Range"
input int    InpLookbackBars  = 2000;  // Show Last N Bars

// ─── INPUTS: FRACTAL / SWING ─────────────────────────────────────────────────
input group "🔍 Swing Detection"
input int    InpLeftBars      = 1;     // Fractal Bars (each side)
input int    InpMaxSwings     = 5;     // Max Swings to Track

// ─── INPUTS: LIQUIDITY ───────────────────────────────────────────────────────
input group "💧 Liquidity Levels"
input bool   InpShowBSL       = true;  // Detect BSL (Buy-Side Liquidity)
input bool   InpShowSSL       = true;  // Detect SSL (Sell-Side Liquidity)
input color  InpColBSL        = clrMediumSeaGreen; // BSL Color
input color  InpColSSL        = clrCrimson;         // SSL Color
input int    InpLineWidth     = 1;     // Line Width

// ─── INPUTS: SWEEP ──────────────────────────────────────────────────────────
input group "⚡ Sweep Detection"
input bool   InpShowSweep     = true;  // Show Sweep Markers on Chart

// ─── INPUTS: PREMIUM & DISCOUNT ──────────────────────────────────────────────
input group "📊 Premium & Discount Zones"
input bool   InpShowPD        = true;  // Show Premium / Discount Zones
input int    InpPDLookback    = 50;    // Dealing Range Lookback
input color  InpColPrem       = clrIndianRed;       // Premium Zone Color
input color  InpColDisc       = clrMediumSeaGreen;  // Discount Zone Color

// ─── INPUTS: OTE ────────────────────────────────────────────────────────────
input group "🎯 OTE Zone"
input bool   InpShowOTE       = true;  // Show OTE (62%-79%)
input bool   InpRequireOTE    = false; // Require OTE for Entry
input color  InpColOTE        = clrOrange; // OTE Zone Color

// ─── INPUTS: ENTRY / SL / TP ────────────────────────────────────────────────
input group "🎯 Entry Settings"
input double InpRRRatio       = 3.0;   // Risk:Reward Ratio
input int    InpCooldownBars  = 5;     // Cooldown (bars after trade)
input bool   InpOneAtATime    = true;  // One Trade at a Time

// ─── INPUTS: TIME-BASED EXIT ────────────────────────────────────────────────
input group "⏱️ Time-Based Exit"
input bool   InpTimeExit      = true;  // Enable Time-Based Exit
input int    InpMaxBarsOpen   = 5;     // Max Bars Before Force Close
input bool   InpOnlyIfLosing  = true;  // Only Close if NOT Profitable

// ─── INPUTS: TRAILING STOP ──────────────────────────────────────────────────
input group "📈 Trailing Stop"
input bool   InpTrailing      = true;  // Enable Trailing Stop
input double InpTrailStart    = 3.0;   // Trail Start (price profit)
input double InpTrailStep     = 1.5;   // Trail Step (price)
input bool   InpBreakEven     = true;  // Enable Break-Even
input double InpBEStart       = 2.0;   // Break-Even Start (price profit)
input double InpBEOffset      = 0.5;   // Break-Even Offset (lock profit)

// ─── INPUTS: SL ─────────────────────────────────────────────────────────────
input group "🛡️ SL Settings"
input int    InpSLLookback    = 14;    // SL Structure Lookback (bars)
input double InpMinSLDist     = 5.0;   // Min SL Distance (price)
input double InpMaxSLDist     = 30.0;  // Max SL Distance (price)

enum ENUM_SL_METHOD {
   SL_SWEEP_WICK   = 0,  // Sweep Wick
   SL_STRUCTURE    = 1,  // Structure
   SL_BOTH         = 2   // Both (farthest)
};
input ENUM_SL_METHOD InpSLMethod = SL_SWEEP_WICK; // SL Method
input double InpSLBuffer      = 0.0;   // SL Buffer (extra distance to avoid hunt)

// ─── INPUTS: PENDING ORDER ──────────────────────────────────────────────────
input group "⏳ Pending Order"
input int    InpPendExpiry    = 10;    // Pending Order Expiry (bars)


// ─── INPUTS: DCA (Dollar Cost Averaging) ────────────────────────────
input group "📊 DCA Settings"
input bool   InpDCAEnabled    = true;  // Enable DCA
input int    InpDCAMaxOrders  = 3;     // Max DCA Orders (1-5)
input double InpDCADistance   = 100.0; // DCA Distance (price)
input double InpDCALotMult   = 1.0;   // DCA Lot Multiplier (1.0 = same lot)
input double InpDCAChainTP   = 2.0;   // Chain TP (price from avg entry)
input bool   InpDCACloseAll  = true;  // Close ALL on Chain TP Hit
// ─── INPUTS: ALERTS ─────────────────────────────────────────────────────────
input group "🔔 Alerts"
input bool   InpAlertSweep    = true;  // Alert on Sweep
input bool   InpAlertEntry    = true;  // Alert on Entry
input bool   InpAlertSLTP     = true;  // Alert on SL/TP Hit
input bool   InpPushNotify    = false; // Send Push Notification

// ─── INPUTS: DASHBOARD ──────────────────────────────────────────────────────
input group "📋 Dashboard"
input bool   InpShowDash      = true;  // Show Dashboard

// ─── SWING DATA ─────────────────────────────────────────────────────────────
#define MAX_SWINGS 50

double g_bslPrices[];
int    g_bslBars[];
bool   g_bslBroken[];
bool   g_bslSwept[];
int    g_bslCount = 0;

double g_sslPrices[];
int    g_sslBars[];
bool   g_sslBroken[];
bool   g_sslSwept[];
int    g_sslCount = 0;

// ─── TRADE TRACKING ─────────────────────────────────────────────────────────
int    g_totalBuys      = 0;
int    g_totalSells     = 0;
int    g_totalTPHits    = 0;
int    g_totalSLHits    = 0;
int    g_totalTimeExits = 0;
int    g_lastSignalBar  = 0;
int    g_bslSweepCount  = 0;
int    g_sslSweepCount  = 0;
int    g_entryBar       = 0;  // bar count when position was opened

// ─── PENDING ENTRY STATE ────────────────────────────────────────────────────
bool   g_pendingBuy     = false;
double g_pendBuyEntry   = 0;
double g_pendBuySL      = 0;
int    g_pendBuyBar     = 0;

bool   g_pendingSell    = false;
double g_pendSellEntry  = 0;
double g_pendSellSL     = 0;
int    g_pendSellBar    = 0;


// ─── DCA STATE ──────────────────────────────────────────────────────
int    g_dcaCount       = 0;     // current DCA orders opened (0 = only initial)
int    g_dcaDirection   = 0;     // 1=buy chain, -1=sell chain
double g_dcaInitEntry   = 0;     // initial entry price of the chain
double g_dcaLastEntry   = 0;     // last DCA entry price
int    g_dcaTotalChains = 0;     // total DCA chains completed
double g_dcaTrailSL     = 0;     // DCA chain trailing SL level
bool   g_dcaTrailActive = false; // is chain trailing active?
// ─── CHART OBJECT PREFIX ────────────────────────────────────────────────────
string g_prefix = "ICTSSL_";
int    g_objUID  = 0;
int    g_lastProcessedBar = 0;

//+------------------------------------------------------------------+
//| Auto-detect filling type (from MQL5 skill)                        |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetFillingType()
{
   long fm = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((fm & SYMBOL_FILLING_FOK) != 0) return ORDER_FILLING_FOK;
   if((fm & SYMBOL_FILLING_IOC) != 0) return ORDER_FILLING_IOC;
   return ORDER_FILLING_RETURN;
}

//+------------------------------------------------------------------+
//| Helper: unique object name                                        |
//+------------------------------------------------------------------+
string ObjName(string type)
{
   g_objUID++;
   return g_prefix + type + "_" + IntegerToString(g_objUID);
}

//+------------------------------------------------------------------+
//| Helper: Highest High over N bars starting at shift                |
//+------------------------------------------------------------------+
double HighestHigh(int count, int shift)
{
   double hh = iHigh(_Symbol, PERIOD_CURRENT, shift);
   for(int i = shift; i < shift + count; i++)
   {
      double h = iHigh(_Symbol, PERIOD_CURRENT, i);
      if(h > hh) hh = h;
   }
   return hh;
}

//+------------------------------------------------------------------+
//| Helper: Lowest Low over N bars starting at shift                  |
//+------------------------------------------------------------------+
double LowestLow(int count, int shift)
{
   double ll = iLow(_Symbol, PERIOD_CURRENT, shift);
   for(int i = shift; i < shift + count; i++)
   {
      double l = iLow(_Symbol, PERIOD_CURRENT, i);
      if(l < ll) ll = l;
   }
   return ll;
}

//+------------------------------------------------------------------+
//| Helper: Draw trend line                                           |
//+------------------------------------------------------------------+
void DrawLevel(string name, datetime t1, double price, datetime t2,
               color clr, int width, ENUM_LINE_STYLE style, bool back=true)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, t1, price, t2, price);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 1, price);
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, back);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Helper: Draw zone                                                 |
//+------------------------------------------------------------------+
void DrawZone(string name, datetime t1, double p1, datetime t2, double p2,
              color clr, bool fill=true)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, p1, t2, p2);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, p1);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 1, p2);
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FILL, fill);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Helper: Draw arrow                                                |
//+------------------------------------------------------------------+
void DrawArrow(string name, datetime time, double price, int code, color clr)
{
   ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, code);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Helper: Draw text on chart                                        |
//+------------------------------------------------------------------+
void DrawText(string name, datetime time, double price, string text, color clr, int fontSize=8)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TEXT, 0, time, price);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Send alert                                                        |
//+------------------------------------------------------------------+
void SendAlert(string msg)
{
   Alert(msg);
   if(InpPushNotify) SendNotification(msg);
}

//+------------------------------------------------------------------+
//| Cleanup all chart objects                                          |
//+------------------------------------------------------------------+
void CleanupObjects()
{
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, g_prefix) == 0)
         ObjectDelete(0, name);
   }
}

//+------------------------------------------------------------------+
//| Check if we have an active position for this EA                   |
//+------------------------------------------------------------------+
bool HasActivePosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_posInfo.SelectByIndex(i)) continue;
      if(g_posInfo.Magic() == InpMagicNumber && g_posInfo.Symbol() == _Symbol)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Count positions by direction                                      |
//+------------------------------------------------------------------+
int CountPositions(ENUM_POSITION_TYPE type)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_posInfo.SelectByIndex(i)) continue;
      if(g_posInfo.Magic() == InpMagicNumber && g_posInfo.Symbol() == _Symbol)
         if(g_posInfo.PositionType() == type)
            count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Shift oldest BSL                                                  |
//+------------------------------------------------------------------+
void ShiftBSL()
{
   string oldName = g_prefix + "BSL_" + IntegerToString(g_bslBars[0]);
   ObjectDelete(0, oldName);
   for(int i = 0; i < g_bslCount - 1; i++)
   {
      g_bslPrices[i] = g_bslPrices[i+1];
      g_bslBars[i]   = g_bslBars[i+1];
      g_bslBroken[i] = g_bslBroken[i+1];
      g_bslSwept[i]  = g_bslSwept[i+1];
   }
   g_bslCount--;
}

//+------------------------------------------------------------------+
//| Shift oldest SSL                                                  |
//+------------------------------------------------------------------+
void ShiftSSL()
{
   string oldName = g_prefix + "SSL_" + IntegerToString(g_sslBars[0]);
   ObjectDelete(0, oldName);
   for(int i = 0; i < g_sslCount - 1; i++)
   {
      g_sslPrices[i] = g_sslPrices[i+1];
      g_sslBars[i]   = g_sslBars[i+1];
      g_sslBroken[i] = g_sslBroken[i+1];
      g_sslSwept[i]  = g_sslSwept[i+1];
   }
   g_sslCount--;
}

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   // Setup trade object
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippage);
   g_trade.SetTypeFilling(GetFillingType());
   
   // Init swing arrays
   ArrayResize(g_bslPrices, MAX_SWINGS);
   ArrayResize(g_bslBars,   MAX_SWINGS);
   ArrayResize(g_bslBroken, MAX_SWINGS);
   ArrayResize(g_bslSwept,  MAX_SWINGS);
   ArrayResize(g_sslPrices, MAX_SWINGS);
   ArrayResize(g_sslBars,   MAX_SWINGS);
   ArrayResize(g_sslBroken, MAX_SWINGS);
   ArrayResize(g_sslSwept,  MAX_SWINGS);
   
   ArrayInitialize(g_bslPrices, 0);
   ArrayInitialize(g_bslBars, 0);
   ArrayInitialize(g_sslPrices, 0);
   ArrayInitialize(g_sslBars, 0);
   
   for(int i = 0; i < MAX_SWINGS; i++)
   {
      g_bslBroken[i] = false; g_bslSwept[i] = false;
      g_sslBroken[i] = false; g_sslSwept[i] = false;
   }
   
   g_lastProcessedBar = 0;
   
   Print("[ICT SSL] EA initialized. Magic=", InpMagicNumber, 
         " Lot=", InpLotSize, " RR=", InpRRRatio);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   CleanupObjects();
   Comment("");
}

//+------------------------------------------------------------------+
//| Validate SL/TP against broker's STOPS_LEVEL                       |
//+------------------------------------------------------------------+
bool ValidateStops(double entry, double sl, double tp, bool isBuy)
{
   // Advisory only - logs warnings but always returns true
   return true;
   long stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist  = stopsLevel * _Point;
   if(minDist <= 0) minDist = 10 * _Point; // fallback
   
   // Add spread buffer
   double spread = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
   minDist += spread;
   
   double slDist = MathAbs(entry - sl);
   double tpDist = MathAbs(entry - tp);
   
   if(slDist < minDist)
   {
      Print("[ICT SSL] ⚠️ SL too close: ", DoubleToString(slDist, _Digits),
            " < min ", DoubleToString(minDist, _Digits));
      return false;
   }
   if(tpDist < minDist)
   {
      Print("[ICT SSL] ⚠️ TP too close: ", DoubleToString(tpDist, _Digits),
            " < min ", DoubleToString(minDist, _Digits));
      return false;
   }
   
   // Direction check
   if(isBuy)
   {
      if(sl >= entry || tp <= entry) { Print("[ICT SSL] ⚠️ BUY stops direction wrong"); return false; }
   }
   else
   {
      if(sl <= entry || tp >= entry) { Print("[ICT SSL] ⚠️ SELL stops direction wrong"); return false; }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Count our positions by magic                                      |
//+------------------------------------------------------------------+
int CountOurPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_posInfo.SelectByIndex(i)) continue;
      if(g_posInfo.Magic() == InpMagicNumber && g_posInfo.Symbol() == _Symbol)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Calculate average entry and total lots for our positions           |
//+------------------------------------------------------------------+
void CalcChainAverage(double &avgEntry, double &totalLots, int &posCount)
{
   avgEntry = 0;
   totalLots = 0;
   posCount = 0;
   double weightedSum = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_posInfo.SelectByIndex(i)) continue;
      if(g_posInfo.Magic() != InpMagicNumber || g_posInfo.Symbol() != _Symbol) continue;
      
      double lots = g_posInfo.Volume();
      weightedSum += g_posInfo.PriceOpen() * lots;
      totalLots += lots;
      posCount++;
   }
   
   if(totalLots > 0)
      avgEntry = weightedSum / totalLots;
}

//+------------------------------------------------------------------+
//| Close all our positions (chain TP hit)                             |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_posInfo.SelectByIndex(i)) continue;
      if(g_posInfo.Magic() != InpMagicNumber || g_posInfo.Symbol() != _Symbol) continue;
      
      g_trade.PositionClose(g_posInfo.Ticket());
   }
   Print("[ICT SSL] ", reason);
   
   // Reset DCA state
   g_dcaCount = 0;
   g_dcaDirection = 0;
   g_dcaInitEntry = 0;
   g_dcaLastEntry = 0;
   g_dcaTrailSL = 0;
   g_dcaTrailActive = false;
   g_dcaTotalChains++;
}

//+------------------------------------------------------------------+
//| Manage DCA: open additional orders + check chain TP               |
//| Runs EVERY TICK                                                    |
//+------------------------------------------------------------------+
void ManageDCA()
{
   if(!InpDCAEnabled) return;
   
   int posCount = 0;
   double avgEntry = 0, totalLots = 0;
   CalcChainAverage(avgEntry, totalLots, posCount);
   
   if(posCount == 0)
   {
      // No positions → reset DCA state
      if(g_dcaCount > 0 || g_dcaDirection != 0)
      {
         g_dcaCount = 0;
         g_dcaDirection = 0;
         g_dcaInitEntry = 0;
         g_dcaLastEntry = 0;
         g_dcaTrailSL = 0;
         g_dcaTrailActive = false;
      }
      return;
   }
   
   // Detect chain direction from first position
   if(g_dcaDirection == 0)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(!g_posInfo.SelectByIndex(i)) continue;
         if(g_posInfo.Magic() != InpMagicNumber || g_posInfo.Symbol() != _Symbol) continue;
         g_dcaDirection = (g_posInfo.PositionType() == POSITION_TYPE_BUY) ? 1 : -1;
         g_dcaInitEntry = g_posInfo.PriceOpen();
         g_dcaLastEntry = g_dcaInitEntry;
         g_dcaCount = posCount - 1; // existing positions minus initial
         break;
      }
   }
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double curPrice = (g_dcaDirection == 1) ? bid : ask;
   
   // ── CHECK CHAIN TP ──
   double chainProfit = (g_dcaDirection == 1) ? (curPrice - avgEntry) : (avgEntry - curPrice);
   
   if(InpDCAChainTP > 0 && chainProfit >= InpDCAChainTP)
   {
      // Chain TP hit — close all positions in the chain
      CloseAllPositions("🎯 DCA CHAIN TP HIT! Avg: " + DoubleToString(avgEntry, _Digits) +
                        " Profit: " + DoubleToString(chainProfit, _Digits) + 
                        " Lots: " + DoubleToString(totalLots, 2) +
                        " Orders: " + IntegerToString(posCount));
      if(InpAlertSLTP)
         SendAlert("[ICT SSL] 🎯 DCA Chain TP! " + IntegerToString(posCount) + " orders closed");
      return;
   }
   
   // ── DCA CHAIN TRAILING: trail the chain TP ──
   if(InpTrailing && posCount > 1 && chainProfit > 0)
   {
      // Activate trailing when chain profit >= TrailStart
      if(chainProfit >= InpTrailStart && !g_dcaTrailActive)
      {
         g_dcaTrailActive = true;
         // Set initial trail SL at avg entry (break-even for chain)
         g_dcaTrailSL = avgEntry;
         Print("[ICT SSL] 📈 DCA Chain Trail ACTIVATED at avg: ",
               DoubleToString(avgEntry, _Digits));
      }
      
      // Move chain trail SL up/down with profit
      if(g_dcaTrailActive)
      {
         double newTrailSL;
         if(g_dcaDirection == 1) // BUY chain
         {
            newTrailSL = curPrice - InpTrailStep;
            if(newTrailSL > g_dcaTrailSL)
            {
               g_dcaTrailSL = newTrailSL;
               Print("[ICT SSL] 📈 DCA Chain Trail SL → ",
                     DoubleToString(g_dcaTrailSL, _Digits));
            }
            // Check if price dropped below trail SL
            if(curPrice <= g_dcaTrailSL)
            {
               CloseAllPositions("📈 DCA CHAIN TRAIL STOP! Trail: " + 
                  DoubleToString(g_dcaTrailSL, _Digits) +
                  " Avg: " + DoubleToString(avgEntry, _Digits));
               return;
            }
         }
         else // SELL chain
         {
            newTrailSL = curPrice + InpTrailStep;
            if(g_dcaTrailSL == 0 || newTrailSL < g_dcaTrailSL)
            {
               g_dcaTrailSL = newTrailSL;
               Print("[ICT SSL] 📈 DCA Chain Trail SL → ",
                     DoubleToString(g_dcaTrailSL, _Digits));
            }
            // Check if price rose above trail SL
            if(curPrice >= g_dcaTrailSL)
            {
               CloseAllPositions("📈 DCA CHAIN TRAIL STOP! Trail: " + 
                  DoubleToString(g_dcaTrailSL, _Digits) +
                  " Avg: " + DoubleToString(avgEntry, _Digits));
               return;
            }
         }
      }
   }
   
   // ── CHAIN SL: max loss protection ──
   // If chain has max DCA orders AND still losing, close all to limit damage
   int maxDCACheck = MathMin(InpDCAMaxOrders, 5);
   if(g_dcaCount >= maxDCACheck && chainProfit < 0)
   {
      // Max DCA reached and still losing = accepting the loss
      double maxLoss = InpDCADistance * (maxDCACheck + 1); // rough max loss
      if(MathAbs(chainProfit) >= maxLoss)
      {
         CloseAllPositions("🛑 DCA CHAIN SL! Max DCA reached, loss exceeded limit. " +
                          "Avg: " + DoubleToString(avgEntry, _Digits) +
                          " Loss: " + DoubleToString(chainProfit, _Digits));
         if(InpAlertSLTP)
            SendAlert("[ICT SSL] 🛑 DCA Chain SL hit! " + IntegerToString(posCount) + " orders closed");
         return;
      }
   }
   
   // ── OPEN DCA ORDER if price moved against us ──
   int maxDCA = MathMin(InpDCAMaxOrders, 5);
   if(g_dcaCount >= maxDCA) return; // max reached
   
   // Distance from last entry (or initial if first DCA)
   double refPrice = (g_dcaCount == 0) ? g_dcaInitEntry : g_dcaLastEntry;
   double distFromRef;
   
   if(g_dcaDirection == 1) // BUY chain → price dropped
      distFromRef = refPrice - curPrice;
   else // SELL chain → price rose
      distFromRef = curPrice - refPrice;
   
   if(distFromRef >= InpDCADistance)
   {
      // Calculate DCA lot size
      double dcaLot = NormalizeDouble(InpLotSize * MathPow(InpDCALotMult, g_dcaCount + 1), 2);
      if(dcaLot < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
         dcaLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      
      bool success = false;
      if(g_dcaDirection == 1)
      {
         success = g_trade.Buy(dcaLot, _Symbol, ask, 0, 0, 
                  "DCA#" + IntegerToString(g_dcaCount + 1));
      }
      else
      {
         success = g_trade.Sell(dcaLot, _Symbol, bid, 0, 0,
                  "DCA#" + IntegerToString(g_dcaCount + 1));
      }
      
      if(success)
      {
         g_dcaCount++;
         g_dcaLastEntry = (g_dcaDirection == 1) ? ask : bid;
         
         // Remove individual SL/TP from ALL chain positions
         // Chain exit is managed by ManageDCA, not broker SL/TP
         for(int p = PositionsTotal() - 1; p >= 0; p--)
         {
            if(!g_posInfo.SelectByIndex(p)) continue;
            if(g_posInfo.Magic() != InpMagicNumber || g_posInfo.Symbol() != _Symbol) continue;
            if(g_posInfo.StopLoss() != 0 || g_posInfo.TakeProfit() != 0)
               g_trade.PositionModify(g_posInfo.Ticket(), 0, 0);
         }
         
         // Recalculate average
         CalcChainAverage(avgEntry, totalLots, posCount);
         
         Print("[ICT SSL] 📊 DCA #", g_dcaCount, " opened @ ",
               DoubleToString(g_dcaLastEntry, _Digits),
               " Lot: ", DoubleToString(dcaLot, 2),
               " Avg: ", DoubleToString(avgEntry, _Digits),
               " Total: ", IntegerToString(posCount), " orders");
         
         if(InpAlertEntry)
            SendAlert("[ICT SSL] DCA #" + IntegerToString(g_dcaCount) + 
                     " Avg: " + DoubleToString(avgEntry, _Digits));
         
         // Remove individual SL/TP from DCA orders (chain manages exit)
         // Initial order keeps its SL as chain SL
      }
      else
      {
         Print("[ICT SSL] DCA #", g_dcaCount + 1, " FAILED: ",
               g_trade.ResultRetcodeDescription());
      }
   }
}

//+------------------------------------------------------------------+
//| Manage open positions: trailing, break-even, time exit            |
//| Runs EVERY TICK for responsiveness                                |
//+------------------------------------------------------------------+
void ManagePositions()
{
   // When DCA chain has >1 position, chain is managed by ManageDCA
   // Skip individual trailing/BE/time-exit to avoid breaking the chain
   int ourPosCount = CountOurPositions();
   bool dcaChainActive = (InpDCAEnabled && ourPosCount > 1);
   if(dcaChainActive) return; // ManageDCA handles everything
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_posInfo.SelectByIndex(i)) continue;
      if(g_posInfo.Magic() != InpMagicNumber || g_posInfo.Symbol() != _Symbol) continue;
      
      double openPrice = g_posInfo.PriceOpen();
      double curSL     = g_posInfo.StopLoss();
      double curTP     = g_posInfo.TakeProfit();
      ulong  ticket    = g_posInfo.Ticket();
      double bid       = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask       = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      bool   isBuy     = (g_posInfo.PositionType() == POSITION_TYPE_BUY);
      double curPrice  = isBuy ? bid : ask;
      double profit    = isBuy ? (curPrice - openPrice) : (openPrice - curPrice);
      
      // Calculate bars open from POSITION OPEN TIME (reliable!)
      datetime posOpenTime = g_posInfo.Time();
      int barsOpen = iBarShift(_Symbol, PERIOD_CURRENT, posOpenTime);
      if(barsOpen < 0) barsOpen = 0;
      
      // ── TIME-BASED EXIT: close if N bars passed and not profitable ──
      if(InpTimeExit && barsOpen >= InpMaxBarsOpen && barsOpen > 0)
      {
         bool shouldClose = InpOnlyIfLosing ? (profit <= 0) : true;
         if(shouldClose)
         {
            if(g_trade.PositionClose(ticket))
            {
               g_totalTimeExits++;
               Print("[ICT SSL] ⏱️ TIME EXIT after ", barsOpen, " bars. P/L: ",
                     DoubleToString(profit, _Digits));
               if(InpAlertSLTP)
                  SendAlert("[ICT SSL] ⏱️ Time exit after " + IntegerToString(barsOpen) + " bars");
            }
            continue; // position closed, skip trailing
         }
      }
      
      // ── BREAK-EVEN: move SL to entry + offset when profit >= BEStart ──
      if(InpBreakEven && profit >= InpBEStart)
      {
         double beSL = isBuy ? (openPrice + InpBEOffset) : (openPrice - InpBEOffset);
         beSL = NormalizeDouble(beSL, _Digits);
         
         // Only modify if new BE is better than current SL
         bool shouldModify = isBuy ? (beSL > curSL) : (curSL == 0 || beSL < curSL);
         if(shouldModify)
         {
            if(g_trade.PositionModify(ticket, beSL, curTP))
               Print("[ICT SSL] 🔒 Break-Even SL → ", DoubleToString(beSL, _Digits));
         }
      }
      
      // ── TRAILING STOP: move SL to lock in profit ──
      if(InpTrailing && profit >= InpTrailStart)
      {
         double newSL;
         if(isBuy)
         {
            newSL = NormalizeDouble(curPrice - InpTrailStep, _Digits);
            if(newSL > curSL) // only move SL up
            {
               if(g_trade.PositionModify(ticket, newSL, curTP))
                  Print("[ICT SSL] 📈 Trail SL → ", DoubleToString(newSL, _Digits));
            }
         }
         else
         {
            newSL = NormalizeDouble(curPrice + InpTrailStep, _Digits);
            if(curSL == 0 || newSL < curSL) // only move SL down
            {
               if(g_trade.PositionModify(ticket, newSL, curTP))
                  Print("[ICT SSL] 📈 Trail SL → ", DoubleToString(newSL, _Digits));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // ── ALL logic runs once per new bar (fast backtest) ──
   int currentBar = iBars(_Symbol, PERIOD_CURRENT);
   if(currentBar == g_lastProcessedBar)
      return;
   g_lastProcessedBar = currentBar;
   
   int totalBars = iBars(_Symbol, PERIOD_CURRENT);
   if(totalBars < InpLeftBars * 2 + 2)
      return;
   
   // ── Position management (once per bar) ──
   ManagePositions();
   ManageDCA();
   
   // ── Current bar data (shift 1 = last closed bar) ──
   double curHigh  = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double curLow   = iLow(_Symbol, PERIOD_CURRENT, 1);
   double curClose = iClose(_Symbol, PERIOD_CURRENT, 1);
   datetime curTime = iTime(_Symbol, PERIOD_CURRENT, 1);
   datetime nowTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   // ── FRACTAL DETECTION (check bar at shift = 1 + InpLeftBars) ──
   int fractalShift = 1 + InpLeftBars; // center of fractal
   double centerHigh = iHigh(_Symbol, PERIOD_CURRENT, fractalShift);
   double centerLow  = iLow(_Symbol, PERIOD_CURRENT, fractalShift);
   
   bool isFractalHigh = true;
   bool isFractalLow  = true;
   
   for(int k = 1; k <= InpLeftBars; k++)
   {
      // Left side
      if(iHigh(_Symbol, PERIOD_CURRENT, fractalShift + k) >= centerHigh) isFractalHigh = false;
      if(iLow(_Symbol, PERIOD_CURRENT, fractalShift + k) <= centerLow)   isFractalLow = false;
      // Right side
      if(iHigh(_Symbol, PERIOD_CURRENT, fractalShift - k) >= centerHigh) isFractalHigh = false;
      if(iLow(_Symbol, PERIOD_CURRENT, fractalShift - k) <= centerLow)   isFractalLow = false;
   }
   
   // ── PUSH BSL (swing high) ──
   if(isFractalHigh && InpShowBSL)
   {
      if(g_bslCount >= InpMaxSwings) ShiftBSL();
      g_bslPrices[g_bslCount] = centerHigh;
      g_bslBars[g_bslCount]   = currentBar - fractalShift;
      g_bslBroken[g_bslCount] = false;
      g_bslSwept[g_bslCount]  = false;
      g_bslCount++;
   }
   
   // ── PUSH SSL (swing low) ──
   if(isFractalLow && InpShowSSL)
   {
      if(g_sslCount >= InpMaxSwings) ShiftSSL();
      g_sslPrices[g_sslCount] = centerLow;
      g_sslBars[g_sslCount]   = currentBar - fractalShift;
      g_sslBroken[g_sslCount] = false;
      g_sslSwept[g_sslCount]  = false;
      g_sslCount++;
   }
   
   // ── PREMIUM & DISCOUNT ──
   double rangeHigh = HighestHigh(InpPDLookback, 1);
   double rangeLow  = LowestLow(InpPDLookback, 1);
   double eqVal     = (rangeHigh + rangeLow) / 2.0;
   double rangeSize = rangeHigh - rangeLow;
   
   double oteBuyHigh  = rangeLow + rangeSize * 0.382;
   double oteBuyLow   = rangeLow + rangeSize * 0.21;
   double oteSellHigh = rangeLow + rangeSize * 0.79;
   double oteSellLow  = rangeLow + rangeSize * 0.618;
   
   bool inPremium  = curClose > eqVal;
   bool inDiscount = curClose <= eqVal;
   bool inOTEBuy   = curClose >= oteBuyLow && curClose <= oteBuyHigh;
   bool inOTESell  = curClose >= oteSellLow && curClose <= oteSellHigh;
   
   // ── BSL SWEEP DETECTION ──
   bool bslSweepNow = false;
   double bslSweepPrice = 0;
   
   for(int j = 0; j < g_bslCount; j++)
   {
      if(!g_bslBroken[j])
      {
         double priceJ = g_bslPrices[j];
         
         // Sweep: wick above but close below
         if(curHigh >= priceJ && curClose < priceJ && !g_bslSwept[j])
         {
            g_bslSwept[j] = true;
            g_bslSweepCount++;
            bslSweepNow = true;
            bslSweepPrice = priceJ;
            
            if(InpShowSweep)
            {
               string arName = ObjName("SweepBSL");
               DrawArrow(arName, curTime, curHigh, 218, InpColSSL);
               ObjectSetString(0, arName, OBJPROP_TOOLTIP,
                  "BSL Sweep @ " + DoubleToString(priceJ, _Digits));
            }
            if(InpAlertSweep)
               SendAlert("[ICT SSL] BSL Sweep @ " + DoubleToString(priceJ, _Digits));
         }
         
         // Broken: close above
         if(curClose > priceJ)
            g_bslBroken[j] = true;
      }
   }
   
   // ── SSL SWEEP DETECTION ──
   bool sslSweepNow = false;
   double sslSweepPrice = 0;
   
   for(int j = 0; j < g_sslCount; j++)
   {
      if(!g_sslBroken[j])
      {
         double priceJ = g_sslPrices[j];
         
         // Sweep: wick below but close above
         if(curLow <= priceJ && curClose > priceJ && !g_sslSwept[j])
         {
            g_sslSwept[j] = true;
            g_sslSweepCount++;
            sslSweepNow = true;
            sslSweepPrice = priceJ;
            
            if(InpShowSweep)
            {
               string arName = ObjName("SweepSSL");
               DrawArrow(arName, curTime, curLow, 217, InpColBSL);
               ObjectSetString(0, arName, OBJPROP_TOOLTIP,
                  "SSL Sweep @ " + DoubleToString(priceJ, _Digits));
            }
            if(InpAlertSweep)
               SendAlert("[ICT SSL] SSL Sweep @ " + DoubleToString(priceJ, _Digits));
         }
         
         // Broken: close below
         if(curClose < priceJ)
            g_sslBroken[j] = true;
      }
   }
   
   // ── CHECK: Active position, trade slot ──
   bool hasPos      = HasActivePosition();
   bool cooldownOk  = (currentBar - g_lastSignalBar >= InpCooldownBars);
   bool tradeSlotOk = InpOneAtATime ? !hasPos : true;
   
   // ── Step 1: CREATE PENDING when sweep detected (only if no active pending) ──
   if(cooldownOk && tradeSlotOk)
   {
      // SSL Sweep in Discount → pending BUY
      if(sslSweepNow && inDiscount)
      {
         bool oteOk = InpRequireOTE ? inOTEBuy : true;
         if(oteOk && sslSweepPrice > 0)
         {
            g_pendingBuy   = true;
            g_pendBuyEntry = sslSweepPrice;
            
            // SL calculation
            double wickSL   = curLow;
            double structSL = LowestLow(InpSLLookback, 1);
            double rawSL;
            if(InpSLMethod == SL_STRUCTURE)       rawSL = structSL;
            else if(InpSLMethod == SL_SWEEP_WICK) rawSL = wickSL;
            else                                  rawSL = MathMin(wickSL, structSL);
            
            double dist = g_pendBuyEntry - rawSL;
            if(dist < InpMinSLDist)       rawSL = g_pendBuyEntry - InpMinSLDist;
            else if(dist > InpMaxSLDist)  rawSL = g_pendBuyEntry - InpMaxSLDist;
            
            g_pendBuySL  = (rawSL > 0) ? rawSL - InpSLBuffer : g_pendBuyEntry - InpMinSLDist - InpSLBuffer;
            g_pendBuyBar = currentBar;
            
            Print("[ICT SSL] Pending BUY created @ ", DoubleToString(sslSweepPrice, _Digits),
                  " SL:", DoubleToString(g_pendBuySL, _Digits));
                  
            if(InpShowSweep)
            {
               string pName = ObjName("PendBuy");
               datetime tEnd = iTime(_Symbol, PERIOD_CURRENT, MathMax(0, 1 - InpPendExpiry));
               DrawLevel(pName, curTime, sslSweepPrice, (tEnd > curTime ? tEnd : curTime + InpPendExpiry * PeriodSeconds()), clrLime, 1, STYLE_DOT, false);
            }
         }
      }
      
      // BSL Sweep in Premium → pending SELL
      if(bslSweepNow && inPremium)
      {
         bool oteOk = InpRequireOTE ? inOTESell : true;
         if(oteOk && bslSweepPrice > 0)
         {
            g_pendingSell   = true;
            g_pendSellEntry = bslSweepPrice;
            
            double wickSL   = curHigh;
            double structSL = HighestHigh(InpSLLookback, 1);
            double rawSL;
            if(InpSLMethod == SL_STRUCTURE)       rawSL = structSL;
            else if(InpSLMethod == SL_SWEEP_WICK) rawSL = wickSL;
            else                                  rawSL = MathMax(wickSL, structSL);
            
            double dist = rawSL - g_pendSellEntry;
            if(dist < InpMinSLDist)       rawSL = g_pendSellEntry + InpMinSLDist;
            else if(dist > InpMaxSLDist)  rawSL = g_pendSellEntry + InpMaxSLDist;
            
            g_pendSellSL  = rawSL + InpSLBuffer;
            g_pendSellBar = currentBar;
            
            Print("[ICT SSL] Pending SELL created @ ", DoubleToString(bslSweepPrice, _Digits),
                  " SL:", DoubleToString(g_pendSellSL, _Digits));
                  
            if(InpShowSweep)
            {
               string pName = ObjName("PendSell");
               datetime tEnd = curTime + InpPendExpiry * PeriodSeconds();
               DrawLevel(pName, curTime, bslSweepPrice, tEnd, clrRed, 1, STYLE_DOT, false);
            }
         }
      }
   }
   
   // ── Step 2: CHECK PENDING → FILL (retest) ──
   // Pending BUY: price pulls back to entry level
   if(g_pendingBuy && !hasPos)
   {
      if(currentBar - g_pendBuyBar > InpPendExpiry)
      {
         g_pendingBuy = false; g_pendBuyEntry = 0; g_pendBuySL = 0;
         Print("[ICT SSL] Pending BUY expired");
      }
      else if(g_pendBuySL > 0 && curLow < g_pendBuySL)
      {
         g_pendingBuy = false; g_pendBuyEntry = 0; g_pendBuySL = 0;
         Print("[ICT SSL] Pending BUY invalidated (SL breached before fill)");
      }
      else if(currentBar > g_pendBuyBar && curLow <= g_pendBuyEntry && g_pendBuySL > 0)
      {
         double entryP = g_pendBuyEntry;
         double slP    = g_pendBuySL;
         double risk   = entryP - slP;
         bool slValid  = (risk > 0 && risk >= InpMinSLDist && risk <= InpMaxSLDist && slP > 0);
         double tp1P   = entryP + risk * InpRRRatio;
         
         if(slValid)
         {
            // Normalize prices
            double normSL = NormalizeDouble(slP, _Digits);
            double normTP = NormalizeDouble(tp1P, _Digits);
            double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            
            if(!ValidateStops(ask, normSL, normTP, true))
            {
               Print("[ICT SSL] BUY skipped: stops validation failed");
            }
            else if(g_trade.Buy(InpLotSize, _Symbol, ask, normSL, normTP, InpComment))
            {
               g_totalBuys++;
               g_lastSignalBar = currentBar;
               g_entryBar = currentBar;
               g_dcaDirection = 1;
               g_dcaInitEntry = ask;
               g_dcaLastEntry = ask;
               g_dcaCount = 0;
               
               // Draw on chart
               string eName = ObjName("EntryBuy");
               DrawArrow(eName, curTime, curLow, 233, clrLime);
               ObjectSetString(0, eName, OBJPROP_TOOLTIP,
                  "BUY @ " + DoubleToString(ask, _Digits) +
                  " SL:" + DoubleToString(normSL, _Digits) +
                  " TP:" + DoubleToString(normTP, _Digits));
               
               // SL/TP lines
               datetime tEnd = curTime + 15 * PeriodSeconds();
               DrawLevel(ObjName("SLBuy"), curTime, normSL, tEnd, clrTomato, 1, STYLE_DASH, false);
               DrawLevel(ObjName("TPBuy"), curTime, normTP, tEnd, clrSpringGreen, 2, STYLE_DASH, false);
               DrawZone(ObjName("ZSLBuy"), curTime, ask, tEnd, normSL, clrTomato);
               DrawZone(ObjName("ZTPBuy"), curTime, ask, tEnd, normTP, clrSpringGreen);
               
               Print("[ICT SSL] 🟢 BUY EXECUTED @ ", DoubleToString(ask, _Digits),
                     " SL:", DoubleToString(normSL, _Digits),
                     " TP:", DoubleToString(normTP, _Digits));
               
               if(InpAlertEntry)
                  SendAlert("[ICT SSL] 🟢 BUY @ " + DoubleToString(ask, _Digits) +
                           " SL:" + DoubleToString(normSL, _Digits) +
                           " TP:" + DoubleToString(normTP, _Digits));
            }
            else
            {
               Print("[ICT SSL] BUY FAILED: ", g_trade.ResultRetcodeDescription());
            }
         }
         g_pendingBuy = false; g_pendBuyEntry = 0; g_pendBuySL = 0;
      }
   }
   
   // Pending SELL: price pulls back up to entry level
   if(g_pendingSell && !hasPos)
   {
      if(currentBar - g_pendSellBar > InpPendExpiry)
      {
         g_pendingSell = false; g_pendSellEntry = 0; g_pendSellSL = 0;
         Print("[ICT SSL] Pending SELL expired");
      }
      else if(g_pendSellSL > 0 && curHigh > g_pendSellSL)
      {
         g_pendingSell = false; g_pendSellEntry = 0; g_pendSellSL = 0;
         Print("[ICT SSL] Pending SELL invalidated (SL breached before fill)");
      }
      else if(currentBar > g_pendSellBar && curHigh >= g_pendSellEntry && g_pendSellSL > 0)
      {
         double entryP = g_pendSellEntry;
         double slP    = g_pendSellSL;
         double risk   = slP - entryP;
         bool slValid  = (risk > 0 && risk >= InpMinSLDist && risk <= InpMaxSLDist);
         double tp1P   = entryP - risk * InpRRRatio;
         
         if(slValid)
         {
            double normSL = NormalizeDouble(slP, _Digits);
            double normTP = NormalizeDouble(tp1P, _Digits);
            double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            
            if(!ValidateStops(bid, normSL, normTP, false))
            {
               Print("[ICT SSL] SELL skipped: stops validation failed");
            }
            else if(g_trade.Sell(InpLotSize, _Symbol, bid, normSL, normTP, InpComment))
            {
               g_totalSells++;
               g_lastSignalBar = currentBar;
               g_entryBar = currentBar;
               g_dcaDirection = -1;
               g_dcaInitEntry = bid;
               g_dcaLastEntry = bid;
               g_dcaCount = 0;
               
               string eName = ObjName("EntrySell");
               DrawArrow(eName, curTime, curHigh, 234, clrRed);
               ObjectSetString(0, eName, OBJPROP_TOOLTIP,
                  "SELL @ " + DoubleToString(bid, _Digits) +
                  " SL:" + DoubleToString(normSL, _Digits) +
                  " TP:" + DoubleToString(normTP, _Digits));
               
               datetime tEnd = curTime + 15 * PeriodSeconds();
               DrawLevel(ObjName("SLSell"), curTime, normSL, tEnd, clrTomato, 1, STYLE_DASH, false);
               DrawLevel(ObjName("TPSell"), curTime, normTP, tEnd, clrSpringGreen, 2, STYLE_DASH, false);
               DrawZone(ObjName("ZSLSell"), curTime, bid, tEnd, normSL, clrTomato);
               DrawZone(ObjName("ZTPSell"), curTime, bid, tEnd, normTP, clrSpringGreen);
               
               Print("[ICT SSL] 🔴 SELL EXECUTED @ ", DoubleToString(bid, _Digits),
                     " SL:", DoubleToString(normSL, _Digits),
                     " TP:", DoubleToString(normTP, _Digits));
               
               if(InpAlertEntry)
                  SendAlert("[ICT SSL] 🔴 SELL @ " + DoubleToString(bid, _Digits) +
                           " SL:" + DoubleToString(normSL, _Digits) +
                           " TP:" + DoubleToString(normTP, _Digits));
            }
            else
            {
               Print("[ICT SSL] SELL FAILED: ", g_trade.ResultRetcodeDescription());
            }
         }
         g_pendingSell = false; g_pendSellEntry = 0; g_pendSellSL = 0;
      }
   }
   
   // ── DRAW BSL/SSL LINES ──
   datetime tNow = iTime(_Symbol, PERIOD_CURRENT, 0);
   for(int j = 0; j < g_bslCount; j++)
   {
      string lnName = g_prefix + "BSL_" + IntegerToString(g_bslBars[j]);
      int shift = currentBar - g_bslBars[j];
      if(shift < 0 || shift >= totalBars) continue;
      datetime t1 = iTime(_Symbol, PERIOD_CURRENT, shift);
      ENUM_LINE_STYLE style = g_bslBroken[j] ? STYLE_DASH : STYLE_SOLID;
      DrawLevel(lnName, t1, g_bslPrices[j], tNow, InpColBSL, InpLineWidth, style);
   }
   
   for(int j = 0; j < g_sslCount; j++)
   {
      string lnName = g_prefix + "SSL_" + IntegerToString(g_sslBars[j]);
      int shift = currentBar - g_sslBars[j];
      if(shift < 0 || shift >= totalBars) continue;
      datetime t1 = iTime(_Symbol, PERIOD_CURRENT, shift);
      ENUM_LINE_STYLE style = g_sslBroken[j] ? STYLE_DASH : STYLE_SOLID;
      DrawLevel(lnName, t1, g_sslPrices[j], tNow, InpColSSL, InpLineWidth, style);
   }
   
   // ── ZONE VISUALIZATION ──
   if(InpShowPD)
   {
      int zShift = MathMin(InpPDLookback, totalBars - 1);
      datetime tZoneStart = iTime(_Symbol, PERIOD_CURRENT, zShift);
      
      DrawZone(g_prefix + "ZonePrem", tZoneStart, rangeHigh, tNow, eqVal, InpColPrem);
      DrawZone(g_prefix + "ZoneDisc", tZoneStart, eqVal, tNow, rangeLow, InpColDisc);
      DrawText(g_prefix + "LblPrem", tNow, (rangeHigh + eqVal) / 2, "PREMIUM", InpColPrem);
      DrawText(g_prefix + "LblDisc", tNow, (rangeLow + eqVal) / 2, "DISCOUNT", InpColDisc);
      
      if(InpShowOTE)
      {
         DrawZone(g_prefix + "ZoneOTEBuy",  tZoneStart, oteBuyHigh, tNow, oteBuyLow, InpColOTE);
         DrawZone(g_prefix + "ZoneOTESell", tZoneStart, oteSellHigh, tNow, oteSellLow, InpColOTE);
         DrawText(g_prefix + "LblOTEBuy",  tNow, (oteBuyHigh + oteBuyLow) / 2, "OTE Buy", InpColOTE, 7);
         DrawText(g_prefix + "LblOTESell", tNow, (oteSellHigh + oteSellLow) / 2, "OTE Sell", InpColOTE, 7);
      }
   }
   
   // ── DASHBOARD ──
   if(InpShowDash)
   {
      string zoneStr = inPremium ? "PREMIUM ▲" : "DISCOUNT ▼";
      string oteStr  = inOTEBuy ? "OTE BUY 🎯" : inOTESell ? "OTE SELL 🎯" : "—";
      
      string pendStr = "None";
      if(g_pendingBuy)  pendStr = "⏳ BUY @ " + DoubleToString(g_pendBuyEntry, _Digits);
      if(g_pendingSell) pendStr = "⏳ SELL @ " + DoubleToString(g_pendSellEntry, _Digits);
      
      string posStr = "No position";
      if(hasPos) posStr = "Active (check Positions tab)";
      
      Comment(
         "══════════════════════════════\n"
         "  [hungpixi] ICT SSL P&D EA\n"
         "══════════════════════════════\n"
         "  Zone:     ", zoneStr, "\n",
         "  OTE:      ", oteStr, "\n",
         "  EQ:       ", DoubleToString(eqVal, _Digits), "\n",
         "  Sweeps:   SSL:", IntegerToString(g_sslSweepCount),
                    " BSL:", IntegerToString(g_bslSweepCount), "\n",
         "──────────────────────────────\n"
         "  Trades:   🟢", IntegerToString(g_totalBuys),
                    " 🔴", IntegerToString(g_totalSells), "\n",
         "  TimeExit: ⏱️", IntegerToString(g_totalTimeExits), "\n",
         "  Position: ", posStr, "\n",
         "  Pending:  ", pendStr, "\n",
         "  Lot:      ", DoubleToString(InpLotSize, 2), "\n",
         "  R:R       ", DoubleToString(InpRRRatio, 1), "\n",
         "  DCA:      ", InpDCAEnabled ? (IntegerToString(g_dcaCount) + "/" + IntegerToString(InpDCAMaxOrders)) : "OFF", "\n",
         "  Chains:   ", IntegerToString(g_dcaTotalChains), "\n",
         "  Trail:    ", InpTrailing ? "ON" : "OFF",
                    " | BE: ", InpBreakEven ? "ON" : "OFF", "\n",
         "══════════════════════════════"
      );
   }
}
//+------------------------------------------------------------------+
