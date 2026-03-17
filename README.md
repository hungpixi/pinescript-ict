# 📊 ICT SSL Premium & Discount — PineScript v6

> **Chỉ báo ICT Sell-Side / Buy-Side Liquidity + Premium & Discount Zones + Entry Signals** cho TradingView.

![PineScript](https://img.shields.io/badge/PineScript-v6-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MPL%202.0-brightgreen?style=flat-square)
![TradingView](https://img.shields.io/badge/TradingView-Overlay-orange?style=flat-square)

---

## 🧠 Tư Duy Thiết Kế

### Vấn đề

Các indicator ICT trên TradingView thường tách biệt: 1 cái cho liquidity levels, 1 cái cho premium/discount, 1 cái khác cho sweep detection. Trader phải dùng 3-4 indicators cùng lúc, chart rối mắt, chồng chéo không nhìn thấy gì.

### Giải pháp

**Một indicator duy nhất** kết hợp toàn bộ ICT model:

1. **SSL/BSL Liquidity Levels** — Nơi smart money nhắm tới
2. **Sweep Detection** — Phát hiện khi liquidity bị quét
3. **Premium & Discount Zones** — Vùng giá rẻ vs đắt + OTE entry
4. **Retest Entry Signals** — Entry tự động khi sweep + pullback với SL/TP rõ ràng
5. **Fixed R:R Target** — TP cố định 3R, không phụ thuộc liquidity level

### Điểm khác biệt

| Feature | Indicator này | jbondata liquidity-swings | FibAlgo Premium/Discount |
|---------|:---:|:---:|:---:|
| SSL/BSL liquidity lines | ✅ | ✅ | ❌ |
| Sweep detection + labels | ✅ | ❌ | ❌ |
| Premium/Discount zones | ✅ | ❌ | ✅ |
| OTE zone (62%-79%) | ✅ | ❌ | ✅ |
| **Retest entry model** | ✅ | ❌ | ❌ |
| **Fixed R:R target (3R)** | ✅ | ❌ | ❌ |
| **Display range limit** | ✅ | ❌ | ❌ |
| **SL min/max validation** | ✅ | ❌ | ❌ |
| Dashboard + Win% | ✅ | ❌ | ✅ |
| PineScript v6 | ✅ | ✅ | ❌ |

## ✨ Tính Năng

### 📐 Display Range
- **Show Last N Bars** — Giới hạn indicator trong N bars gần nhất (mặc định 2000)
- Giảm chart clutter, tập trung vào dữ liệu gần nhất
- Adjustable 100–10,000 bars

### 💧 Liquidity Levels (SSL & BSL)
- **BSL** (xanh lá): Swing highs — Buy-Side Liquidity
- **SSL** (đỏ): Swing lows — Sell-Side Liquidity
- Lines **solid** khi chưa bị phá, chuyển **dashed** khi đã bị phá

### ⚡ Sweep Detection
- **SSL Sweep** (▲): Wick xuống dưới swing low nhưng close trên → Bullish
- **BSL Sweep** (▼): Wick lên trên swing high nhưng close dưới → Bearish
- Compact icons + hover tooltip xem chi tiết

### 🎯 Entry Signals (Retest Model)
```
🟢 BUY Setup:
1. SSL Sweep trong Discount zone → tạo pending buy tại SSL level
2. Giá pullback xuống chạm lại SSL level → Entry triggered
3. SL = sweep candle wick (mặc định), clamp min 5 / max 30
4. TP = Entry + Risk × 3R (cố định, adjustable 1-10R)

🔴 SELL Setup:
1. BSL Sweep trong Premium zone → tạo pending sell tại BSL level
2. Giá pullback lên chạm lại BSL level → Entry triggered
3. SL = sweep candle wick, clamp min 5 / max 30
4. TP = Entry - Risk × 3R
```

**Hiển thị trên chart:**
- Entry label compact: `🟢 BUY @ 4998.685`
- SL line + label: `SL 4993.685` (đỏ, dashed)
- TP line + label: `TP 3R 5014.055` (xanh, dashed, dày hơn)
- SL/TP zone fill (subtle background)

### 🛡️ SL Validation
- **Min SL Distance** (mặc định 5) — Không đặt SL quá gần
- **Max SL Distance** (mặc định 30) — Không đặt SL quá xa
- **Sanity check**: SL > 0, risk trong range min–max
- **SL Method**: Sweep Wick (khuyên dùng) / Structure / Both

### 📊 Premium & Discount Zones
- Box zones với high transparency — không che price action
- **Equilibrium (EQ)** line mỏng tại 50%
- **OTE Buy/Sell** zones (62%–79% retracement)
- Labels nhỏ gọn đẩy ra phải chart

### 📋 Dashboard
- Zone hiện tại (PREMIUM/DISCOUNT)
- OTE status, EQ price
- Sweep counts (SSL & BSL)
- Trade stats: Signals, Results, Win%

## 🚀 Cách Sử Dụng

1. Copy nội dung file `ICT_SSL_PremiumDiscount.pine`
2. Mở TradingView → Pine Editor
3. Paste code → Add to chart
4. Tùy chỉnh settings:
   - **Display Range**: 500–2000 bars tùy nhu cầu
   - **Risk:Reward**: 3R mặc định (3R là đã win)
   - **SL Method**: Sweep Wick cho ICT chuẩn

## 🔄 Changelog

### v2.0 (2025-03-17)
- ✅ **Display Range Limit** — Show Last N Bars input (mặc định 2000)
- ✅ **Fixed R:R TP** — TP = 3R cố định, không phụ thuộc liquidity
- ✅ **SL Bug Fix** — Fix SL=0 bug, thêm min/max SL distance validation
- ✅ **Clean Style** — Bỏ bgcolor overlay, compact labels, subtle box fills
- ✅ **TP/SL Labels** — Hiện rõ target price + R:R trên chart
- ✅ **Default SL Method** — Đổi sang Sweep Wick (đúng ICT hơn)

### v1.0 (2025-03-16)
- Initial release: SSL/BSL, Sweep Detection, Premium/Discount, OTE, Dashboard

## 🗺️ Hướng Phát Triển

- [ ] Multi-timeframe liquidity levels (HTF overlay)
- [ ] Order Block detection kết hợp sweep
- [ ] Fair Value Gap (FVG) integration
- [ ] Kill Zone time-based filter (London/NY)
- [ ] Partial close tại TP1, trailing SL

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
