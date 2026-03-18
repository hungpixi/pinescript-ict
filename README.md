# 📊 ICT SSL Premium & Discount — PineScript v6 + MQL5 EA

> **ICT Sell-Side / Buy-Side Liquidity + Premium & Discount Zones + Entry Signals** cho TradingView & MetaTrader 5.

![PineScript](https://img.shields.io/badge/PineScript-v6-blue?style=flat-square)
![MQL5](https://img.shields.io/badge/MQL5-Expert_Advisor-purple?style=flat-square)
![License](https://img.shields.io/badge/License-MPL%202.0-brightgreen?style=flat-square)
![TradingView](https://img.shields.io/badge/TradingView-Overlay-orange?style=flat-square)
![MT5](https://img.shields.io/badge/MetaTrader_5-Backtest_Ready-red?style=flat-square)

---

## 🧠 Tư Duy Thiết Kế

### Vấn đề

Các indicator ICT trên TradingView thường tách biệt: 1 cái cho liquidity levels, 1 cái cho premium/discount, 1 cái khác cho sweep detection. Trader phải dùng 3-4 indicators cùng lúc, chart rối mắt, chồng chéo không nhìn thấy gì.

**Và quan trọng hơn**: indicator chỉ "nhìn" — không trade được. Muốn backtest hay live trading phải tự code lại từ đầu trên MQL5/Python.

### Giải pháp

**Một hệ thống 2-in-1:**

1. **PineScript Indicator** → Phân tích visual trên TradingView
2. **MQL5 Expert Advisor** → Backtest + Live trading trên MetaTrader 5

Cùng logic, cùng methodology, nhưng MQ5 EA có thêm:
- **DCA (Dollar Cost Averaging)** — Gỡ lệnh lỗ bằng cách trung bình giá
- **Trailing Stop / Break-Even** — Bảo vệ lợi nhuận tự động
- **Time-Based Exit** — Cắt lỗ nhanh nếu trade không chạy
- **ValidateStops** — Kiểm tra SL/TP hợp lệ trước khi gửi lệnh

### Quá trình tư duy PineScript → MQL5

```
📊 PineScript (Visual Analysis)
    ↓ Logic mapping
📋 MQL5 Indicator (OnCalculate)
    ↓ "Indicator không trade được!"
🤖 MQL5 Expert Advisor (OnTick)
    ↓ "Trade rồi nhưng SL/TP bị reject!"
🛡️ + ValidateStops (SYMBOL_TRADE_STOPS_LEVEL)
    ↓ "Time exit đóng position sai!"
⏱️ + iBarShift(posOpenTime) thay vì g_entryBar
    ↓ "Pending fill trên cùng bar sweep!"
🔄 + Require currentBar > pendBar
    ↓ "DCA phá chain!"
📊 + ManageDCA() tách riêng, ManagePositions() skip khi chain active
    ↓ "Nặng quá backtest không nổi!"
⚡ + New-bar-only execution (giảm 99% CPU)
```

### Điểm khác biệt

| Feature | Dự án này | jbondata liquidity-swings | FibAlgo Premium/Discount |
|---------|:---:|:---:|:---:|
| SSL/BSL liquidity lines | ✅ | ✅ | ❌ |
| Sweep detection + labels | ✅ | ❌ | ❌ |
| Premium/Discount zones | ✅ | ❌ | ✅ |
| OTE zone (62%-79%) | ✅ | ❌ | ✅ |
| **Retest entry model** | ✅ | ❌ | ❌ |
| **Fixed R:R target** | ✅ | ❌ | ❌ |
| **MQL5 Expert Advisor** | ✅ | ❌ | ❌ |
| **DCA chain management** | ✅ | ❌ | ❌ |
| **Trailing + Break-Even** | ✅ | ❌ | ❌ |
| **Time-based exit** | ✅ | ❌ | ❌ |
| Dashboard + Win% | ✅ | ❌ | ✅ |
| PineScript v6 | ✅ | ✅ | ❌ |

## ✨ Tính Năng — PineScript Indicator

### 📐 Display Range
- **Show Last N Bars** — Giới hạn indicator trong N bars gần nhất (mặc định 2000)

### 💧 Liquidity Levels (SSL & BSL)
- **BSL** (xanh lá): Swing highs — Buy-Side Liquidity
- **SSL** (đỏ): Swing lows — Sell-Side Liquidity
- Lines **solid** khi chưa bị phá, chuyển **dashed** khi đã bị phá

### ⚡ Sweep Detection
- **SSL Sweep** (▲): Wick xuống dưới swing low nhưng close trên → Bullish
- **BSL Sweep** (▼): Wick lên trên swing high nhưng close dưới → Bearish

### 🎯 Entry Signals (Retest Model)
```
🟢 BUY: SSL Sweep trong Discount → pending buy → pullback → Entry 
🔴 SELL: BSL Sweep trong Premium → pending sell → pullback → Entry
SL = sweep wick, TP = Entry ± Risk × R:R
```

### 📊 Premium & Discount Zones + OTE

## 🤖 Tính Năng — MQL5 Expert Advisor

### 💰 Trading Engine
- **CTrade** order execution + `GetFillingType()` auto-detect
- **ValidateStops()** — Kiểm tra `SYMBOL_TRADE_STOPS_LEVEL` trước khi gửi lệnh
- **Pending → Retest fill** — Chỉ fill trên bar tiếp theo (không fake retest cùng bar)

### 📊 DCA (Dollar Cost Averaging)
- **Max 1-5 lệnh DCA** — Input configurable cho backtest
- **DCA Distance** — Khoảng cách giá giữa các lệnh
- **Lot Multiplier** — 1.0 = same lot, 1.5 = tăng dần (martingale)
- **Chain TP** — Đóng tất cả khi avg entry + profit target
- **Chain SL** — Max loss protection khi đã hết DCA levels
- **DCA isolator** — Khi chain active, ManagePositions skip → tránh phá chain

### ⏱️ Time-Based Exit
- **Max Bars Open** — Đóng trade nếu sau N bar vẫn lỗ
- **Only If Losing** — Giữ trade nếu đang dương
- Dùng `iBarShift(posOpenTime)` — đếm bar chính xác

### 📈 Trailing Stop + Break-Even
- **Trail Start/Step** — Kích hoạt trailing khi đạt profit target
- **Break-Even** — Dời SL về entry + offset khi đạt BE target

## 🚀 Cách Sử Dụng

### PineScript (TradingView)
1. Copy file `ICT_SSL_PremiumDiscount.pine`
2. TradingView → Pine Editor → Paste → Add to chart

### MQL5 Expert Advisor (MetaTrader 5)
1. Copy file `ICT_SSL_PremiumDiscount.mq5` vào `MQL5/Experts/`
2. Compile bằng MetaEditor
3. Kéo EA vào chart hoặc mở Strategy Tester
4. Load file `set1.set` để dùng settings đã optimize

## 🔄 Changelog

### v3.0 — MQL5 Expert Advisor (2026-03-18)
- ✅ **PineScript → MQL5 EA** — Full conversion với CTrade execution
- ✅ **DCA chain** — 1-5 lệnh, distance, lot multiplier, chain TP/SL
- ✅ **ValidateStops** — Fix "Invalid stops" bằng SYMBOL_TRADE_STOPS_LEVEL
- ✅ **Time-based exit** — iBarShift + posOpenTime (không dựa vào global var)
- ✅ **Trailing + Break-Even** — Bảo vệ lợi nhuận tự động
- ✅ **Performance** — New-bar-only execution (giảm 99% CPU backtest)
- ✅ **DCA isolator** — ManagePositions skip khi DCA chain active

### v2.0 (2025-03-17)
- ✅ Display Range Limit, Fixed R:R TP, SL Bug Fix, Clean Style

### v1.0 (2025-03-16)
- Initial release: SSL/BSL, Sweep Detection, Premium/Discount, OTE, Dashboard

## 🗺️ Hướng Phát Triển

- [ ] Multi-timeframe liquidity levels (HTF overlay)
- [ ] Order Block detection kết hợp sweep
- [ ] Fair Value Gap (FVG) integration
- [ ] Kill Zone time-based filter (London/NY)
- [ ] Partial close tại TP1, trailing SL
- [ ] PyPI package cho Python backtesting

## 📚 Nguồn Tham Khảo

- [jbondata/pinescript-indicator-suite](https://github.com/jbondata/pinescript-indicator-suite) — Fractal detection & liquidity swing logic
- [FibAlgo ICT Premium & Discount](https://www.tradingview.com/) — Dealing range concept
- ICT (Inner Circle Trader) methodology — SSL/BSL, Premium/Discount, OTE concepts
- **AI-assisted development** by [hungpixi](https://github.com/hungpixi) × [Comarai](https://comarai.com)

## 📄 License

[Mozilla Public License 2.0](https://mozilla.org/MPL/2.0/)

---

## 🤝 Bạn muốn indicator/bot trading tương tự?

| Bạn cần | Chúng tôi đã làm ✅ |
|---------|---------------------|
| Indicator PineScript tùy chỉnh | ICT SSL Premium & Discount |
| Trading Bot MQL5/Python | ICT SystemEA, CCBSN Bot |
| AI phân tích tín hiệu | Telegram Signal Dashboard |
| Tự động hóa trading workflow | Copy Trade System |

<p align="center">
  <a href="https://comarai.com"><img src="https://img.shields.io/badge/🚀_Yêu_cầu_Demo-comarai.com-blue?style=for-the-badge" alt="Demo"></a>
  <a href="https://zalo.me/0834422439"><img src="https://img.shields.io/badge/💬_Zalo-0834422439-green?style=for-the-badge" alt="Zalo"></a>
  <a href="mailto:hungphamphunguyen@gmail.com"><img src="https://img.shields.io/badge/📧_Email-Contact-red?style=for-the-badge" alt="Email"></a>
</p>

<p align="center">
  <b>Comarai</b> — Companion for Marketing & AI Automation<br/>
  <em>4 nhân viên AI: Em Sale 🤝 Em Content ✍️ Em Marketing 📢 Em Trade 📈</em>
</p>

<p align="center">
  <i>"Mình không bán tool, mình bán thời gian — để bạn tập trung vào việc quan trọng hơn."</i><br/>
  — <a href="https://github.com/hungpixi">hungpixi</a>
</p>
