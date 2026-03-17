# 📊 ICT SSL Premium & Discount — PineScript v6

> **Chỉ báo ICT Sell-Side / Buy-Side Liquidity + Premium & Discount Zones** cho TradingView.

![PineScript](https://img.shields.io/badge/PineScript-v6-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MPL%202.0-brightgreen?style=flat-square)
![TradingView](https://img.shields.io/badge/TradingView-Overlay-orange?style=flat-square)

---

## 🧠 Tư Duy Thiết Kế

### Vấn đề

Các indicator ICT trên TradingView thường tách biệt: 1 cái cho liquidity levels, 1 cái cho premium/discount, 1 cái khác cho sweep detection. Trader phải dùng 3-4 indicators cùng lúc, chart rối mắt.

### Giải pháp

**Một indicator duy nhất** kết hợp 3 concepts cốt lõi của ICT:

1. **SSL/BSL Liquidity Levels** — Nơi smart money nhắm tới
2. **Sweep Detection** — Phát hiện khi liquidity bị quét
3. **Premium & Discount Zones** — Vùng giá rẻ vs đắt + OTE entry

### Điểm khác biệt so với indicators có sẵn

| Feature | Indicator này | jbondata liquidity-swings | FibAlgo Premium/Discount |
|---------|:---:|:---:|:---:|
| SSL/BSL liquidity lines | ✅ | ✅ | ❌ |
| Sweep detection + labels | ✅ | ❌ | ❌ |
| Premium/Discount zones | ✅ | ❌ | ✅ |
| OTE zone (62%-79%) | ✅ | ❌ | ✅ |
| Dashboard table | ✅ | ❌ | ✅ |
| All-in-one | ✅ | ❌ | ❌ |
| PineScript v6 | ✅ | ✅ | ❌ |

## ✨ Tính Năng

### 💧 Liquidity Levels (SSL & BSL)
- **BSL** (xanh lá): Swing highs — Buy-Side Liquidity, nơi sell stops tập trung
- **SSL** (đỏ): Swing lows — Sell-Side Liquidity, nơi buy stops tập trung
- Lines **solid** khi chưa bị phá, chuyển **dashed** khi đã bị phá
- Fractal sensitivity tùy chỉnh (3 = 7-bar fractal)

### ⚡ Sweep Detection
- **SSL Sweep** (▲): Wick xuống dưới swing low nhưng close trên → Bullish signal
- **BSL Sweep** (▼): Wick lên trên swing high nhưng close dưới → Bearish signal
- Labels hiện ngay tại điểm sweep

### 📊 Premium & Discount Zones
- **Dealing Range** tự động từ highest high / lowest low qua lookback period
- **Equilibrium (EQ)** line tại 50% — ranh giới Premium/Discount
- **Premium zone** (trên EQ): Background đỏ nhạt — vùng giá đắt, tìm sell
- **Discount zone** (dưới EQ): Background xanh nhạt — vùng giá rẻ, tìm buy

### 🎯 OTE Zone (Optimal Trade Entry)
- **OTE Buy**: 62%-79% retracement từ đỉnh (discount OTE)
- **OTE Sell**: 62%-79% retracement từ đáy (premium OTE)
- Fibonacci-based entry zones cho xác suất cao

### 📋 Dashboard
- Hiển thị real-time: Zone hiện tại (PREMIUM/DISCOUNT)
- OTE status
- EQ price
- Tổng số sweeps (SSL & BSL)

## 🚀 Cách Sử Dụng

1. Copy nội dung file `ICT_SSL_PremiumDiscount.pine`
2. Mở TradingView → Pine Editor
3. Paste code → Add to chart
4. Tùy chỉnh settings theo khung thời gian:
   - **Scalping (M5-M15)**: leftBars=2, lookback=30
   - **Intraday (H1-H4)**: leftBars=3, lookback=50
   - **Swing (D1)**: leftBars=5, lookback=100

## 📈 Cách Giao Dịch Với Indicator

```
🟢 BUY Setup:
1. Giá đang ở DISCOUNT zone
2. SSL Sweep xảy ra (▲ label xuất hiện)
3. Giá nằm trong OTE Buy zone
4. → Entry buy, SL dưới swing low, TP tại EQ hoặc Premium

🔴 SELL Setup:
1. Giá đang ở PREMIUM zone
2. BSL Sweep xảy ra (▼ label xuất hiện)
3. Giá nằm trong OTE Sell zone
4. → Entry sell, SL trên swing high, TP tại EQ hoặc Discount
```

## 🗺️ Hướng Phát Triển

- [ ] Multi-timeframe liquidity levels (HTF overlay)
- [ ] Order Block detection kết hợp sweep
- [ ] Fair Value Gap (FVG) integration
- [ ] Alert system cho sweep events
- [ ] Kill Zone time-based filter (London/NY)

## 📚 Nguồn Tham Khảo

- [jbondata/pinescript-indicator-suite](https://github.com/jbondata/pinescript-indicator-suite) — Fractal detection & liquidity swing logic
- [FibAlgo ICT Premium & Discount](https://www.tradingview.com/) — Real-time zigzag & dealing range concept
- ICT (Inner Circle Trader) methodology — SSL/BSL, Premium/Discount, OTE concepts

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
